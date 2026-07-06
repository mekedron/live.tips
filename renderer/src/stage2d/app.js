/**
 * live.tips stage — 2D renderer (Canvas 2D), embedded-library edition.
 *
 * Ported from the tip-jar-5 prototype. Ultra-light variant for old tablets:
 *  - Pile layout precomputed in normalized "jar units" (jar height = 1).
 *  - Money sprites pre-rendered once per resize to offscreen canvases.
 *  - Settled money is BAKED into an offscreen pile layer → a frame costs
 *    3 drawImage calls + the handful of currently-falling sprites.
 *  - rAF loop fully stops when nothing animates (0% CPU while idle).
 *
 * Library rules match the 3D renderer (see ../stage3d/app.js): no chrome, no
 * persistence, host-commanded rollovers, jar fractions in, events out.
 */
import { mulberry32 } from '../shared/ui.js';
import { THEMES, applyCssTheme } from '../shared/themes.js';
import { createSound } from '../shared/sound.js';

const CFG = {
  jarW: 0.54,          // of jar height
  wall: 0.022,
  bodyTop: 0.78,       // shoulder start — short squat neck, like a real jar
  shoulderEnd: 0.88,   // neck start
  neckTop: 0.965,
  coinR: 0.036,
  fillTop: 0.82,
  billRatio: 0.12,
  edgeRatio: 0.08,
  gravity: 20,         // jar-units / s²
  dprMax: 2,
};

// Euro money, minus the € glyph — bimetallic €1/€2, Nordic-gold and copper cents,
// note colors matched to real denominations.
const METAL = {
  copper: { base: '#c07a45', dark: '#8a4f24', lite: '#e6a670', ink: 'rgba(74,40,14,0.8)' },
  gold:   { base: '#d9a94e', dark: '#997026', lite: '#f2d183', ink: 'rgba(90,62,16,0.8)' },
  silver: { base: '#cdd2d7', dark: '#868f98', lite: '#f0f3f6', ink: 'rgba(62,70,78,0.8)' },
};
const COIN_TYPES = [
  { numeral: '5',  ring: 'copper', center: null,     scale: 0.82 }, // 5 cent
  { numeral: '50', ring: 'gold',   center: null,     scale: 0.94 }, // 50 cent
  { numeral: '1',  ring: 'gold',   center: 'silver', scale: 0.92 }, // €1
  { numeral: '2',  ring: 'silver', center: 'gold',   scale: 1.0 },  // €2
];
const EDGE_METALS = ['copper', 'gold', 'silver'];
const BILL_SPECS = [
  { n: '5',  bg: '#bcc0c5', dk: '#565b61', band: '#dfe2e6' }, // €5  grey
  { n: '10', bg: '#d89b94', dk: '#8a4a44', band: '#eecfcb' }, // €10 red
  { n: '20', bg: '#92aed6', dk: '#40608c', band: '#d3e0f0' }, // €20 blue
  { n: '50', bg: '#e0a95e', dk: '#8f6222', band: '#f2ddb4' }, // €50 orange
];

export function createStage(ctx) {
  const { host, emit } = ctx;
  const config = ctx.config || {};
  const REDUCED = !!ctx.reduced;
  const rng = mulberry32(20260703);

  let theme = THEMES.find(t => t.key === config.theme) || THEMES[0];
  applyCssTheme(theme);
  const sound = createSound();
  sound.setCoins(!!config.sound);
  sound.setFanfare(!!config.tipSound);
  let billsOn = config.notes === undefined ? true : !!config.notes;
  let insets = { top: 0, bottom: 0, ...(config.insets || {}) };

  // trophies already earned; sprites are fabricated lazily (see ensureArchives)
  let bankedJars = Math.max(0, Math.floor((ctx.state && ctx.state.bankedJars) || 0));
  const archives = [];   // shelf sprites {c, w, h, k, t} — newest last

  // host-commanded rollover choreography
  let pendingRollovers = 0;
  let afterPct = -1;     // 0..200 target once the queue drains; -1 = none
  let rolloverT = -1;    // performance.now() when the pending retire fires

  // ---------------------------------------------------------------- pile precompute
  // Positions in jar units: x from center, y up from jar outer bottom.

  const BIW = CFG.jarW / 2 - CFG.wall;      // body inner half-width
  const NIW = BIW * 0.66;                   // neck inner half-width
  const CORNER = 0.055;

  function halfW(u) {
    const yB = CFG.wall;
    if (u < yB + CORNER) {
      const dy = (yB + CORNER - u) / CORNER;
      return BIW - CORNER * (1 - Math.sqrt(Math.max(0, 1 - dy * dy)));
    }
    if (u <= CFG.bodyTop) return BIW;
    if (u >= CFG.shoulderEnd) return NIW;
    const k = (u - CFG.bodyTop) / (CFG.shoulderEnd - CFG.bodyTop);
    const s = k * k * (3 - 2 * k);
    return BIW + (NIW - BIW) * s;
  }

  function buildPile() {
    const items = [];
    const R = CFG.coinR;
    const billRatio = billsOn ? CFG.billRatio : 0;
    // per-config deterministic stream → identical layout every session
    const prand = mulberry32(20260703 + (billsOn ? 0 : 5));
    let u = CFG.wall + R * 1.05;
    let row = 0;
    while (u < CFG.fillTop) {
      const hw = halfW(u + R * 0.4) - R * 1.05;
      const spacing = R * 1.58; // coins overlap → no background peeking through
      const n = Math.max(1, Math.floor((hw * 2) / spacing) + 1);
      const brick = (row % 2) * R * 0.8 - R * 0.4;
      for (let k = 0; k < n; k++) {
        // center-out slot order → partial rows cluster in the middle (mound)
        const slot = (k % 2 === 1 ? 1 : -1) * Math.ceil(k / 2);
        let x = slot * spacing + brick + (prand() - 0.5) * R * 0.45;
        x = Math.max(-hw, Math.min(hw, x));
        const y = u + (prand() - 0.5) * R * 0.35;
        const tr = prand();
        const type = tr < billRatio ? 'bill' : tr < billRatio + CFG.edgeRatio ? 'edge' : 'coin';
        if (type === 'bill') {
          // bills are ~2.3 coin radii wide — keep them off the glass wall
          const bx = Math.max(0, hw - R * 1.5);
          x = Math.max(-bx, Math.min(bx, x));
        }
        let v;
        if (type === 'bill') {
          const r2 = prand();
          v = r2 < 0.35 ? 0 : r2 < 0.65 ? 1 : r2 < 0.85 ? 2 : 3; // €5/€10/€20/€50
        } else if (type === 'edge') {
          const r2 = prand();
          v = r2 < 0.25 ? 0 : r2 < 0.7 ? 1 : 2; // copper / gold / silver
        } else {
          const r2 = prand();
          v = r2 < 0.15 ? 0 : r2 < 0.45 ? 1 : r2 < 0.72 ? 3 : 2; // 5c / 50c / €2 / €1
        }
        items.push({
          type, v, x, y,
          rot: type === 'coin' ? prand() * Math.PI * 2
             : type === 'edge' ? (prand() - 0.5) * 0.7
             : (prand() - 0.5) * 0.55,
          s: 0.94 + prand() * 0.12,
        });
      }
      u += R * 1.28 * (0.95 + prand() * 0.1);
      row++;
    }
    // last items: bills standing up in the neck, poking out of the mouth
    if (billsOn) {
      for (let k = 0; k < 4; k++) {
        items.push({
          type: 'billup',
          x: (prand() - 0.5) * NIW * 1.1,
          y: CFG.neckTop - 0.065 + prand() * 0.04,
          rot: (prand() - 0.5) * 0.35,
          v: Math.floor(prand() * BILL_SPECS.length),
          s: 0.95 + prand() * 0.1,
        });
      }
    }

    // ---- overflow mounds (100–200%): money spills OUTSIDE, flanking the jar ----
    // Rows stack bottom-up against the glass with a talus slope; push order =
    // growth order, so pours raise the mounds exactly the way they fell.
    const nIn = items.length;
    const OW = CFG.jarW / 2 + 0.012;              // outer wall + a whisker of air
    const spillW = 0.46;                          // how far the carpet reaches
    for (let orow = 0; orow < 12; orow++) {
      const oy = CFG.coinR * 0.62 + orow * CFG.coinR * 1.12;
      const inner = OW + CFG.coinR * 0.7 + (orow > 0 ? CFG.coinR * 0.12 : 0);
      const outer = OW + spillW - orow * CFG.coinR * 1.5; // higher rows are shorter
      if (outer - inner < CFG.coinR * 1.2) break;
      const spacing = CFG.coinR * 1.55;
      const n = Math.max(1, Math.floor((outer - inner) / spacing));
      for (let k = 0; k < n; k++) {
        for (const side of [-1, 1]) {             // both mounds grow together
          const y = oy + (prand() - 0.5) * CFG.coinR * 0.3;
          let x = inner + k * spacing + (prand() - 0.5) * CFG.coinR * 0.4;
          if (billsOn && prand() < 0.22 && outer - inner > CFG.coinR * 2.2) { // notes among the spill
            x = Math.max(inner + CFG.coinR * 1.6, Math.min(outer - CFG.coinR * 0.4, x));
            const r2 = prand();
            items.push({
              type: 'bill', out: true, x: side * x, y,
              v: r2 < 0.35 ? 0 : r2 < 0.65 ? 1 : r2 < 0.85 ? 2 : 3,
              rot: side * (0.06 + prand() * 0.24),  // tilted down the slope
              s: 0.94 + prand() * 0.12,
            });
          } else {
            const r2 = prand();
            items.push({
              type: 'coin', out: true, x: side * x, y,
              v: r2 < 0.15 ? 0 : r2 < 0.45 ? 1 : r2 < 0.72 ? 3 : 2,
              rot: prand() * Math.PI * 2,
              s: 0.94 + prand() * 0.12,
            });
          }
        }
      }
    }
    return { items, nIn };
  }

  let pile = buildPile();
  let items = pile.items;

  // The 0–200% scale: 0–100 fills the jar (nIn items), 100–200 the mounds
  // outside (the remaining items). Both mappings are linear in item count.
  function countFromPct(pct) {
    pct = Math.min(200, Math.max(0, pct));
    const nIn = pile.nIn, nOut = items.length - nIn;
    if (pct <= 100 || !nOut) return Math.round(nIn * Math.min(pct, 100) / 100);
    return nIn + Math.round(nOut * (pct - 100) / 100);
  }

  function pctFromCount(c) {
    const nIn = pile.nIn, nOut = items.length - nIn;
    if (c <= nIn || !nOut) return nIn ? (c / nIn) * 100 : 0;
    return 100 + ((c - nIn) / nOut) * 100;
  }

  // ---------------------------------------------------------------- canvas + geometry (px)

  const canvas = document.createElement('canvas');
  host.appendChild(canvas);
  // any gesture revives an autoplay-suspended AudioContext (parity with 3D)
  canvas.addEventListener('pointerdown', () => sound.unlock());
  const ctx2 = canvas.getContext('2d');
  const pileC = document.createElement('canvas');
  const outC = document.createElement('canvas');   // overflow mounds — never clipped
  const backC = document.createElement('canvas');
  const frontC = document.createElement('canvas');

  let W = 0, H = 0, dpr = 1;
  let JH = 0, cx = 0, jarBot = 0;   // jar height px, center x, jar bottom y (px)
  let interiorPath = null;          // with chimney — clips money
  let jarInnerPath = null;          // body only — clips the glass tint
  let sprites = null;

  const X = (xu) => cx + xu * JH;
  const Y = (u) => jarBot - u * JH;
  const S = (v) => v * JH;

  function roundRect(g, x, y, w, h, r) {
    g.beginPath();
    g.moveTo(x + r, y);
    g.arcTo(x + w, y, x + w, y + h, r);
    g.arcTo(x + w, y + h, x, y + h, r);
    g.arcTo(x, y + h, x, y, r);
    g.arcTo(x, y, x + w, y, r);
    g.closePath();
  }

  // ---- sprites -------------------------------------------------------------

  function makeSprite(w, h, draw) {
    const c = document.createElement('canvas');
    c.width = Math.max(2, Math.ceil(w * dpr));
    c.height = Math.max(2, Math.ceil(h * dpr));
    const g = c.getContext('2d');
    g.scale(dpr, dpr);
    draw(g, w, h);
    return { c, w, h };
  }

  function buildSprites() {
    const R = S(CFG.coinR);

    // realistic euro faces: soft metal shading, thin rim, 12-dot ring, engraved
    // numeral; €1/€2 get the bimetallic second disc. No € glyph anywhere.
    const coin = COIN_TYPES.map(T => {
      const r = R * T.scale;
      return makeSprite(r * 2 + 4, r * 2 + 4, (g, w, h) => {
        const ccx = w / 2, ccy = h / 2;
        const ring = METAL[T.ring];
        // flat coin face: mostly base metal, darkening only at the very edge
        let grad = g.createRadialGradient(ccx - r * 0.25, ccy - r * 0.3, r * 0.1, ccx, ccy, r * 1.02);
        grad.addColorStop(0, ring.lite);
        grad.addColorStop(0.38, ring.base);
        grad.addColorStop(0.85, ring.base);
        grad.addColorStop(1, ring.dark);
        g.fillStyle = grad;
        g.beginPath(); g.arc(ccx, ccy, r, 0, 7); g.fill();
        g.strokeStyle = ring.dark;
        g.globalAlpha = 0.55;
        g.lineWidth = Math.max(1, r * 0.06);
        g.beginPath(); g.arc(ccx, ccy, r * 0.95, 0, 7); g.stroke();
        g.globalAlpha = 1;
        let ink = ring.ink;
        if (T.center) {
          const cm = METAL[T.center];
          grad = g.createRadialGradient(ccx - r * 0.14, ccy - r * 0.18, r * 0.05, ccx, ccy, r * 0.6);
          grad.addColorStop(0, cm.lite);
          grad.addColorStop(0.4, cm.base);
          grad.addColorStop(0.85, cm.base);
          grad.addColorStop(1, cm.dark);
          g.fillStyle = grad;
          g.beginPath(); g.arc(ccx, ccy, r * 0.56, 0, 7); g.fill();
          g.strokeStyle = cm.dark;
          g.globalAlpha = 0.5;
          g.lineWidth = Math.max(1, r * 0.045);
          g.beginPath(); g.arc(ccx, ccy, r * 0.56, 0, 7); g.stroke();
          g.globalAlpha = 1;
          ink = cm.ink;
        }
        // 12 dots — the EU stars, abstracted
        g.fillStyle = ring.dark;
        g.globalAlpha = 0.45;
        for (let i = 0; i < 12; i++) {
          const a = (i / 12) * Math.PI * 2;
          g.beginPath();
          g.arc(ccx + Math.cos(a) * r * 0.77, ccy + Math.sin(a) * r * 0.77, r * 0.05, 0, 7);
          g.fill();
        }
        g.globalAlpha = 1;
        // engraved numeral: light offset under the ink
        const fs = r * (T.numeral.length > 1 ? 0.62 : 0.88);
        g.font = `800 ${fs}px Georgia, serif`;
        g.textAlign = 'center'; g.textBaseline = 'middle';
        g.fillStyle = 'rgba(255,255,255,0.4)';
        g.fillText(T.numeral, ccx + r * 0.03, ccy + r * 0.085);
        g.fillStyle = ink;
        g.fillText(T.numeral, ccx, ccy + r * 0.04);
        // soft diagonal sheen (not a cartoon gloss arc)
        const sg = g.createLinearGradient(ccx - r, ccy - r, ccx + r * 0.6, ccy + r * 0.6);
        sg.addColorStop(0, 'rgba(255,255,255,0.2)');
        sg.addColorStop(0.45, 'rgba(255,255,255,0)');
        g.fillStyle = sg;
        g.beginPath(); g.arc(ccx, ccy, r * 0.98, 0, 7); g.fill();
      });
    });

    const edge = EDGE_METALS.map(key => {
      const st = METAL[key];
      return makeSprite(R * 2 + 4, R * 0.7 + 4, (g, w, h) => {
        const ew = R * 1.9, eh = R * 0.34;
        const x0 = (w - ew) / 2, y0 = (h - eh) / 2;
        const grad = g.createLinearGradient(0, y0, 0, y0 + eh);
        grad.addColorStop(0, st.lite);
        grad.addColorStop(0.45, st.base);
        grad.addColorStop(1, st.dark);
        g.fillStyle = grad;
        roundRect(g, x0, y0, ew, eh, eh * 0.35);
        g.fill();
        g.strokeStyle = 'rgba(0,0,0,0.28)';
        g.lineWidth = Math.max(1, eh * 0.06);
        g.strokeRect(x0 + eh * 0.2, y0 + eh * 0.18, ew - eh * 0.4, eh * 0.64);
      });
    });

    // euro-note look: tinted paper, light band, arch motif, denomination numerals
    const BW = R * 4.6, BH = R * 2.4;
    const bill = BILL_SPECS.map(spec => makeSprite(BW + 4, BH + 4, (g) => {
      const x0 = 2, y0 = 2;
      g.fillStyle = spec.bg;
      roundRect(g, x0, y0, BW, BH, R * 0.16);
      g.fill();
      g.fillStyle = spec.band;
      g.fillRect(x0 + BW * 0.60, y0 + BH * 0.06, BW * 0.22, BH * 0.88);
      g.strokeStyle = spec.dk;
      g.globalAlpha = 0.55;
      g.lineWidth = Math.max(1, R * 0.05);
      roundRect(g, x0 + BW * 0.03, y0 + BH * 0.06, BW * 0.94, BH * 0.88, R * 0.12);
      g.stroke();
      // arch / window motif
      g.globalAlpha = 0.5;
      g.lineWidth = Math.max(1, R * 0.07);
      g.beginPath();
      g.moveTo(x0 + BW * 0.16, y0 + BH * 0.8);
      g.lineTo(x0 + BW * 0.16, y0 + BH * 0.46);
      g.arc(x0 + BW * 0.27, y0 + BH * 0.46, BW * 0.11, Math.PI, 0);
      g.lineTo(x0 + BW * 0.38, y0 + BH * 0.8);
      g.stroke();
      g.globalAlpha = 1;
      g.fillStyle = spec.dk;
      g.textAlign = 'center'; g.textBaseline = 'middle';
      g.font = `900 ${Math.max(8, BH * 0.4)}px Georgia, serif`;
      g.fillText(spec.n, x0 + BW * 0.88, y0 + BH * 0.7);
      g.font = `900 ${Math.max(6, BH * 0.2)}px Georgia, serif`;
      g.fillText(spec.n, x0 + BW * 0.1, y0 + BH * 0.18);
      // fold shade
      g.fillStyle = 'rgba(0,0,0,0.07)';
      g.beginPath();
      g.moveTo(x0 + BW * 0.48, y0);
      g.lineTo(x0 + BW * 0.55, y0);
      g.lineTo(x0 + BW * 0.50, y0 + BH);
      g.lineTo(x0 + BW * 0.44, y0 + BH);
      g.closePath(); g.fill();
    }));

    // soft dark disc drawn under every baked item: neighbouring halos merge, so
    // gaps between coins read as pile shadow instead of the page background
    const halo = makeSprite(R * 3, R * 3, (g, w, h) => {
      const grad = g.createRadialGradient(w / 2, h / 2, R * 0.2, w / 2, h / 2, R * 1.45);
      grad.addColorStop(0, 'rgba(26,17,10,0.5)');
      grad.addColorStop(1, 'rgba(26,17,10,0)');
      g.fillStyle = grad;
      g.fillRect(0, 0, w, h);
    });

    return { coin, edge, bill, halo };
  }

  function spriteFor(it) {
    if (it.type === 'coin') return sprites.coin[it.v];
    if (it.type === 'edge') return sprites.edge[it.v];
    return sprites.bill[it.v];
  }

  function drawItem(g, it, xPx, yPx, rot, sx, sy, alpha) {
    const sp = spriteFor(it);
    g.save();
    g.globalAlpha = alpha;
    g.translate(xPx, yPx);
    g.rotate(it.type === 'billup' ? rot + Math.PI / 2 : rot);
    g.scale(sx * it.s, sy * it.s);
    g.drawImage(sp.c, -sp.w / 2, -sp.h / 2, sp.w, sp.h);
    g.restore();
  }

  // ---- jar layers ----------------------------------------------------------

  // withChimney=true extends the path above the open mouth so falling money is
  // visible through the neck; false = jar interior only (for the glass tint).
  function buildInteriorPath(withChimney) {
    const p = new Path2D();
    const yb = Y(CFG.wall);
    const cr = S(CORNER);
    const topY = withChimney ? 0 : Y(CFG.neckTop);
    p.moveTo(X(-NIW), topY);
    p.lineTo(X(-NIW), Y(CFG.shoulderEnd));
    p.quadraticCurveTo(X(-BIW * 0.98), Y((CFG.bodyTop + CFG.shoulderEnd) / 2), X(-BIW), Y(CFG.bodyTop));
    p.lineTo(X(-BIW), yb - cr);
    p.quadraticCurveTo(X(-BIW), yb, X(-BIW) + cr, yb);
    p.lineTo(X(BIW) - cr, yb);
    p.quadraticCurveTo(X(BIW), yb, X(BIW), yb - cr);
    p.lineTo(X(BIW), Y(CFG.bodyTop));
    p.quadraticCurveTo(X(BIW * 0.98), Y((CFG.bodyTop + CFG.shoulderEnd) / 2), X(NIW), Y(CFG.shoulderEnd));
    p.lineTo(X(NIW), topY);
    p.closePath();
    return p;
  }

  function outerGlassPath(g) {
    const t = S(CFG.wall);
    const yb = jarBot;
    const cr = S(CORNER + CFG.wall);
    const OW = S(BIW) + t, NW = S(NIW) + t;
    const lip = S(0.012);
    g.beginPath();
    g.moveTo(cx - NW - lip, Y(1.0));
    g.lineTo(cx - NW, Y(CFG.neckTop));
    g.lineTo(cx - NW, Y(CFG.shoulderEnd));
    g.quadraticCurveTo(cx - OW * 0.99, Y((CFG.bodyTop + CFG.shoulderEnd) / 2), cx - OW, Y(CFG.bodyTop));
    g.lineTo(cx - OW, yb - cr);
    g.quadraticCurveTo(cx - OW, yb, cx - OW + cr, yb);
    g.lineTo(cx + OW - cr, yb);
    g.quadraticCurveTo(cx + OW, yb, cx + OW, yb - cr);
    g.lineTo(cx + OW, Y(CFG.bodyTop));
    g.quadraticCurveTo(cx + OW * 0.99, Y((CFG.bodyTop + CFG.shoulderEnd) / 2), cx + NW, Y(CFG.shoulderEnd));
    g.lineTo(cx + NW, Y(CFG.neckTop));
    g.lineTo(cx + NW + lip, Y(1.0));
  }

  function bakeBack() {
    const g = backC.getContext('2d');
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, W, H);
    // stage spotlight beam behind the jar (theme-tinted)
    const beam = g.createLinearGradient(0, 0, 0, jarBot);
    beam.addColorStop(0, `rgba(${theme.beam},0.13)`);
    beam.addColorStop(0.75, `rgba(${theme.beam},0.05)`);
    beam.addColorStop(1, `rgba(${theme.beam},0)`);
    g.fillStyle = beam;
    g.beginPath();
    g.moveTo(cx - S(NIW) * 1.6, 0);
    g.lineTo(cx + S(NIW) * 1.6, 0);
    g.lineTo(cx + S(BIW) * 1.8, jarBot + S(0.03));
    g.lineTo(cx - S(BIW) * 1.8, jarBot + S(0.03));
    g.closePath();
    g.fill();
    // warm light pool on the floor
    g.save();
    g.translate(cx, jarBot + S(0.012));
    g.scale(1, 0.18);
    const pool = g.createRadialGradient(0, 0, S(0.05), 0, 0, S(0.56));
    pool.addColorStop(0, `rgba(${theme.beam},0.22)`);
    pool.addColorStop(1, `rgba(${theme.beam},0)`);
    g.fillStyle = pool;
    g.beginPath(); g.arc(0, 0, S(0.56), 0, 7); g.fill();
    g.restore();
    // floor shadow (gradient built in local coords — canvas gradients live in user space)
    g.save();
    g.translate(cx, jarBot + S(0.012));
    g.scale(1, 0.16);
    const sh = g.createRadialGradient(0, 0, S(0.02), 0, 0, S(0.36));
    sh.addColorStop(0, 'rgba(0,0,0,0.45)');
    sh.addColorStop(1, 'rgba(0,0,0,0)');
    g.fillStyle = sh;
    g.beginPath(); g.arc(0, 0, S(0.36), 0, 7); g.fill();
    g.restore();
    // glass interior tint
    g.save();
    g.clip(jarInnerPath);
    const grad = g.createLinearGradient(0, Y(1), 0, jarBot);
    grad.addColorStop(0, 'rgba(175,205,240,0.12)');
    grad.addColorStop(0.7, 'rgba(150,180,220,0.06)');
    grad.addColorStop(1, 'rgba(120,150,200,0.10)');
    g.fillStyle = grad;
    g.fillRect(0, 0, W, H);
    // inner bottom shade
    const bs = g.createLinearGradient(0, Y(CFG.wall + 0.06), 0, Y(CFG.wall));
    bs.addColorStop(0, 'rgba(10,15,40,0)');
    bs.addColorStop(1, 'rgba(10,15,40,0.30)');
    g.fillStyle = bs;
    g.fillRect(0, Y(CFG.wall + 0.06), W, S(0.06));
    g.restore();
  }

  function bakeFront() {
    const g = frontC.getContext('2d');
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, W, H);
    // outline
    outerGlassPath(g);
    g.strokeStyle = 'rgba(205,232,255,0.55)';
    g.lineWidth = Math.max(1.5, S(0.007));
    g.stroke();
    // inner wall hint
    g.strokeStyle = 'rgba(255,255,255,0.10)';
    g.lineWidth = Math.max(1, S(0.004));
    g.stroke(jarInnerPath);
    // tall left streak
    let lg = g.createLinearGradient(0, Y(0.70), 0, Y(0.08));
    lg.addColorStop(0, 'rgba(255,255,255,0.16)');
    lg.addColorStop(1, 'rgba(255,255,255,0.02)');
    g.fillStyle = lg;
    roundRect(g, X(-BIW * 0.72), Y(0.70), S(0.055), S(0.62), S(0.027));
    g.fill();
    // small right streak
    lg = g.createLinearGradient(0, Y(0.62), 0, Y(0.16));
    lg.addColorStop(0, 'rgba(255,255,255,0.09)');
    lg.addColorStop(1, 'rgba(255,255,255,0.01)');
    g.fillStyle = lg;
    roundRect(g, X(BIW * 0.66), Y(0.62), S(0.028), S(0.46), S(0.014));
    g.fill();
    // shoulder gloss
    g.strokeStyle = 'rgba(255,255,255,0.14)';
    g.lineWidth = S(0.016);
    g.beginPath();
    g.moveTo(X(-BIW * 0.9), Y(CFG.bodyTop + 0.01));
    g.quadraticCurveTo(X(-BIW * 0.8), Y(CFG.shoulderEnd - 0.005), X(-NIW * 1.15), Y(CFG.shoulderEnd + 0.015));
    g.stroke();
    // rim band
    const t = S(CFG.wall);
    g.fillStyle = 'rgba(255,255,255,0.07)';
    g.strokeStyle = 'rgba(215,240,255,0.6)';
    g.lineWidth = Math.max(1, S(0.005));
    roundRect(g, cx - S(NIW) - t * 1.5, Y(1.0), (S(NIW) + t * 1.5) * 2, S(0.03), S(0.008));
    g.fill();
    g.stroke();
    // mouth ellipse hint
    g.strokeStyle = 'rgba(215,240,255,0.35)';
    g.beginPath();
    g.ellipse(cx, Y(0.995), S(NIW) * 0.92, S(0.012), 0, 0, Math.PI, false);
    g.stroke();
    // vignette — pulls the eye to the lit jar
    const vg = g.createRadialGradient(W / 2, H * 0.42, Math.min(W, H) * 0.35, W / 2, H * 0.5, Math.max(W, H) * 0.75);
    vg.addColorStop(0, 'rgba(4,6,20,0)');
    vg.addColorStop(1, 'rgba(2,3,12,0.42)');
    g.fillStyle = vg;
    g.fillRect(0, 0, W, H);
  }

  // ---------------------------------------------------------------- state

  const landed = new Set();   // item indices settled & baked
  let targetN = 0;
  const queue = [];           // indices waiting to spawn
  const air = [];             // {i, t, dur, fromX, fromY, spin, rot0}
  const ghosts = [];          // {i, t}
  const parts = [];           // sparkle particles
  let spawnAcc = 0, spawnInterval = 0.03;

  function bakeItem(i) {
    const it = items[i];
    // overflow items live on their own layer, outside the glass clip
    const g = (it.out ? outC : pileC).getContext('2d');
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    const sp = spriteFor(it);
    const x = X(it.x), y = Y(it.y);
    // contact-shadow halo under the sprite (see buildSprites)
    g.drawImage(sprites.halo.c, x - sp.w * 0.72, y - sp.h * 0.72, sp.w * 1.44, sp.h * 1.44);
    drawItem(g, it, x, y, it.rot, 1, 1, 1);
  }

  function rebake() {
    if (!sprites) return; // not laid out yet — layout() will rebake
    for (const c of [pileC, outC]) {
      const g = c.getContext('2d');
      g.setTransform(dpr, 0, 0, dpr, 0, 0);
      g.clearRect(0, 0, W, H);
    }
    [...landed].sort((a, b) => a - b).forEach(bakeItem);
  }

  // pour/drain to an exact item count
  function pourToCount(n) {
    targetN = Math.max(0, Math.min(items.length, n));
    queue.length = 0;

    // remove extra settled items → ghosts fly out
    const toRemove = [...landed].filter(i => i >= targetN).sort((a, b) => b - a);
    if (toRemove.length) {
      for (let k = 0; k < toRemove.length; k++) {
        ghosts.push({ i: toRemove[k], t: -k * 0.02 });
        landed.delete(toRemove[k]);
      }
      rebake();
    }

    // spawn everything below target that isn't landed or airborne
    const airSet = new Set(air.map(a => a.i));
    for (let i = 0; i < targetN; i++) {
      if (!landed.has(i) && !airSet.has(i)) queue.push(i);
    }
    if (queue.length) {
      const dur = Math.min(4.2, Math.max(0.7, 0.4 + queue.length * 0.055));
      spawnInterval = Math.max(0.02, dur / queue.length);
      spawnAcc = spawnInterval;
    }
    wake();
  }

  function spawnNext() {
    const i = queue.shift();
    const it = items[i];
    // overflow money drops OUTSIDE the glass, straight onto its mound spot
    const out = !!it.out;
    const fromY = (out ? 1.04 : 1.10) + rng() * 0.12;
    const span = Math.max(0.02, NIW - CFG.coinR * 1.2);
    air.push({
      i, t: 0,
      dur: Math.sqrt((2 * Math.max(0.15, fromY - it.y)) / CFG.gravity),
      fromX: out ? it.x + (rng() - 0.5) * 0.05 : (rng() - 0.5) * 2 * span,
      fromY,
      spin: (rng() - 0.5) * (out ? 7 : 9),
      rot0: rng() * Math.PI * 2,
    });
  }

  // ---- host-commanded rollover: the full jar retires to a background shelf --
  // The jar region of the baked layers is snapshotted into a sprite that slides
  // to a shelf spot; the real jar clears instantly (its money left with it).
  function snapshotJar() {
    const pad = S(0.06);
    const x0 = cx - S(CFG.jarW / 2) - pad;
    const y0 = Y(1.03) - pad;
    const w = (S(CFG.jarW / 2) + pad) * 2;
    const h = jarBot + S(0.02) - y0;
    const c = document.createElement('canvas');
    c.width = Math.max(2, Math.ceil(w * dpr));
    c.height = Math.max(2, Math.ceil(h * dpr));
    const g = c.getContext('2d');
    g.drawImage(pileC, x0 * dpr, y0 * dpr, w * dpr, h * dpr, 0, 0, c.width, c.height);
    g.drawImage(frontC, x0 * dpr, y0 * dpr, w * dpr, h * dpr, 0, 0, c.width, c.height);
    return { c, w, h };
  }

  // Fabricate the shelf for trophies we never saw being earned (init/syncState
  // restore): bake a FULL jar into the pile layer, snapshot it, put it back.
  function ensureArchives() {
    if (!sprites) return; // not laid out yet — layout() re-runs this
    const want = Math.min(4, bankedJars);
    if (archives.length === want) return;
    archives.length = 0;
    if (want > 0) {
      const g = pileC.getContext('2d');
      g.setTransform(dpr, 0, 0, dpr, 0, 0);
      g.clearRect(0, 0, W, H);
      for (let i = 0; i < pile.nIn; i++) bakeItem(i);
      const snap = snapshotJar();
      for (let k = 0; k < want; k++) {
        const jarIndex = bankedJars - want + k;
        archives.push({ ...snap, k: jarIndex % 4, t: 1 }); // t:1 → already parked
      }
      rebake(); // restore the real landed state
    }
  }

  function retire2d() {
    const snap = snapshotJar();
    bankedJars++;
    if (archives.length >= 4) archives.shift(); // the shelf shows the last four
    archives.push({ ...snap, k: (bankedJars - 1) % 4, t: 0 });
    targetN = 0;
    queue.length = 0; air.length = 0; ghosts.length = 0;
    landed.clear();
    rebake();
    milestonesFired.clear();
    celebrated = false; celebrated200 = false;
    sound.blip();
    emit({ type: 'event', kind: 'rolloverDone', jarPct: 0 });

    // more jars owed (a giant tip) → fill the fresh jar right back up;
    // otherwise pour whatever remainder the last tip left us
    pendingRollovers = Math.max(0, pendingRollovers - 1);
    if (pendingRollovers > 0) {
      setInstant(200);
    } else if (afterPct >= 0) {
      const p = afterPct;
      afterPct = -1;
      pourToCount(countFromPct(p));
    }
    wake();
  }

  function confettiBurst(n = 90) {
    if (REDUCED) return;
    const colors = theme.confetti;
    for (let k = 0; k < n; k++) {
      const a = -Math.PI / 2 + (rng() - 0.5) * 1.6;
      const sp = S(0.55) * (0.5 + rng());
      parts.push({
        x: X((rng() - 0.5) * NIW * 1.6),
        y: Y(CFG.neckTop) + (rng() - 0.5) * S(0.04),
        vx: Math.cos(a) * sp,
        vy: Math.sin(a) * sp,
        life: 1.5 + rng() * 0.5,
        decay: 0.32,
        gravMul: 0.4, // paper flutters, it doesn't drop like a coin
        rot: rng() * Math.PI,
        spin: (rng() - 0.5) * 10,
        size: S(0.009) + rng() * S(0.011),
        color: colors[k % colors.length],
      });
    }
    wake();
  }

  function sparkle(xPx, yPx, count = 4) {
    if (REDUCED) return;
    for (let k = 0; k < count && parts.length < 240; k++) {
      const a = -Math.PI / 2 + (rng() - 0.5) * 2.2;
      const sp = S(0.25) * (0.4 + rng() * 0.8);
      parts.push({
        x: xPx, y: yPx,
        vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
        life: 1, rot: rng() * Math.PI, size: S(0.008) + rng() * S(0.008),
      });
    }
  }

  const BOUNCE = 0.24;

  function tick(dt) {
    let busy = false;

    if (queue.length) {
      spawnAcc += dt;
      while (spawnAcc >= spawnInterval && queue.length) {
        spawnAcc -= spawnInterval;
        spawnNext();
      }
      busy = true;
    }

    for (let k = air.length - 1; k >= 0; k--) {
      const f = air[k];
      f.t += dt;
      busy = true;
      if (f.t >= f.dur + BOUNCE) {
        air.splice(k, 1);
        if (f.i >= targetN) ghosts.push({ i: f.i, t: 0 });
        else {
          landed.add(f.i);
          bakeItem(f.i);
          sound.clink();
          const it = items[f.i];
          // near-goal escalation: livelier glints past 75% of the jar goal
          const heat = Math.max(0, Math.min(1, (pctFromCount(landed.size) - 75) / 25));
          sparkle(X(it.x), Y(it.y), 4 + Math.round(heat * 4));
        }
      }
    }

    for (let k = ghosts.length - 1; k >= 0; k--) {
      ghosts[k].t += dt;
      busy = true;
      if (ghosts[k].t > 0.45) ghosts.splice(k, 1);
    }

    for (const A of archives) {
      if (A.t < 0.9) { A.t += dt; busy = true; } // retiring sprite still sliding
    }

    const grav = S(2.2);
    for (let k = parts.length - 1; k >= 0; k--) {
      const p = parts[k];
      p.life -= dt * (p.decay !== undefined ? p.decay : 2.4);
      busy = true;
      if (p.life <= 0) { parts.splice(k, 1); continue; }
      p.vy += grav * (p.gravMul !== undefined ? p.gravMul : 1) * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += dt * (p.spin !== undefined ? p.spin : 6);
    }

    return busy;
  }

  // airborne + departing items; out=false draws the inside set (call it inside
  // the glass clip), out=true the overflow set (call it unclipped)
  function drawFlying(out) {
    for (const f of air) {
      const it = items[f.i];
      if (!!it.out !== out) continue;
      let xu, yu, rot, sx = 1, sy = 1;
      if (f.t < f.dur) {
        const k = Math.min(1, f.t / f.dur);
        const ke = k * k * (3 - 2 * k);
        xu = f.fromX + (it.x - f.fromX) * Math.min(1, ke / 0.9);
        yu = Math.max(it.y, f.fromY - 0.5 * CFG.gravity * f.t * f.t);
        if (!out) {
          // funnel: stay inside the glass silhouette on the way down
          const ext = it.type === 'bill' || it.type === 'billup' ? 0.088 : 0.038;
          const hwY = halfW(Math.min(0.97, yu)) - ext - 0.004;
          if (hwY > 0) xu = Math.max(-hwY, Math.min(hwY, xu));
        }
        rot = f.rot0 + f.spin * f.t + (it.rot - f.rot0 - f.spin * f.dur) * (k > 0.6 ? (k - 0.6) / 0.4 : 0);
      } else {
        const bt = f.t - f.dur;
        xu = it.x;
        yu = it.y + 0.028 * Math.exp(-bt * 9) * Math.abs(Math.sin(bt * 22));
        rot = it.rot;
        const sq = 0.2 * Math.exp(-bt * 13);
        sx = 1 + sq; sy = 1 - sq;
      }
      drawItem(ctx2, it, X(xu), Y(yu), rot, sx, sy, 1);
    }

    for (const gh of ghosts) {
      const it = items[gh.i];
      if (!!it.out !== out) continue;
      if (gh.t < 0) { drawItem(ctx2, it, X(it.x), Y(it.y), it.rot, 1, 1, 1); continue; }
      const k = gh.t / 0.45;
      drawItem(ctx2, it, X(it.x), Y(it.y + k * k * 0.5), it.rot + k, 1, 1, 1 - k);
    }
  }

  function render() {
    if (!sprites) return; // not laid out yet
    ctx2.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx2.clearRect(0, 0, W, H);
    ctx2.drawImage(backC, 0, 0, W, H);

    // retired mini-jars on the background shelf (smaller + higher = further)
    for (const A of archives) {
      const k = REDUCED ? 1 : Math.min(1, A.t / 0.9);
      const e = k * k * (3 - 2 * k);
      const side = A.k % 2 ? 1 : -1, col = A.k >> 1;
      const tx = cx + side * JH * (0.56 + col * 0.16);
      const tb = jarBot - JH * (0.40 + col * 0.045);
      const ts = 0.38 - col * 0.03;
      const x = cx + (tx - cx) * e;
      const b = jarBot + (tb - jarBot) * e;
      const s = 1 + (ts - 1) * e;
      const w = A.w * s, h = A.h * s;
      ctx2.save();
      ctx2.globalAlpha = 0.94;
      ctx2.fillStyle = 'rgba(0,0,0,0.32)'; // contact shadow on the "far floor"
      ctx2.beginPath();
      ctx2.ellipse(x, b, w * 0.42, h * 0.045, 0, 0, 7);
      ctx2.fill();
      ctx2.drawImage(A.c, x - w / 2, b - h, w, h);
      ctx2.restore();
    }

    ctx2.save();
    ctx2.clip(interiorPath);
    ctx2.drawImage(pileC, 0, 0, W, H);
    drawFlying(false);
    ctx2.restore();

    // overflow layer: outside the glass, so outside the clip too
    ctx2.drawImage(outC, 0, 0, W, H);
    drawFlying(true);

    for (const p of parts) {
      ctx2.save();
      ctx2.globalAlpha = Math.max(0, Math.min(1, p.life));
      ctx2.translate(p.x, p.y);
      ctx2.rotate(p.rot);
      if (p.color) { // confetti flake
        ctx2.fillStyle = p.color;
        ctx2.fillRect(-p.size, -p.size * 0.6, p.size * 2, p.size * 1.2);
      } else { // landing glint cross
        ctx2.fillStyle = '#ffe9a8';
        const s = p.size * (1.6 - p.life * 0.6);
        ctx2.fillRect(-s, -s / 3, s * 2, s / 1.5);
        ctx2.fillRect(-s / 3, -s, s / 1.5, s * 2);
      }
      ctx2.restore();
    }

    ctx2.drawImage(frontC, 0, 0, W, H);
  }

  // ---------------------------------------------------------------- loop (stops when idle)

  let raf = 0, lastT = 0;
  let paused = false;
  let emaDt = 1 / 60;
  let celebrated = false, celebrated200 = false;
  const MILESTONES = [25, 50, 75, 125, 150, 175];
  const milestonesFired = new Set();
  let announcedReady = false;

  function frame(now) {
    raf = 0;
    if (paused) return;
    const dt = Math.min(0.05, (now - lastT) / 1000) || 0.016;
    lastT = now;
    emaDt += (dt - emaDt) * 0.05;
    const busy = tick(dt);
    render();
    const pctNow = pctFromCount(landed.size);
    // milestone mini-bursts on the way up (and past the goal, into overflow)
    for (const m of MILESTONES) {
      if (pctNow >= m && pctNow < (m < 100 ? 99.9 : 199.9) && !milestonesFired.has(m)) {
        milestonesFired.add(m);
        confettiBurst(28);
        sound.blip();
        emit({ type: 'event', kind: 'milestone', jarPct: m / 100 });
      } else if (pctNow < m - 8) {
        milestonesFired.delete(m);
      }
    }
    // goal reached (100%) → confetti (re-arms below 95%)
    if (landed.size >= pile.nIn && pile.nIn > 0 && air.length === 0 && !celebrated) {
      celebrated = true;
      confettiBurst();
      sound.chime();
      emit({ type: 'event', kind: 'goalReached', jarPct: 1 });
    } else if (landed.size < pile.nIn * 0.95) {
      celebrated = false;
    }
    // both mounds visually full AND the host owes us a rollover → the second,
    // bigger moment… then the full jar retires to the background shelf
    if (landed.size === items.length && items.length > pile.nIn && air.length === 0
        && pendingRollovers > 0 && !celebrated200) {
      celebrated200 = true;
      confettiBurst();
      sound.chime();
      emit({ type: 'event', kind: 'zoneFull', jarPct: 2 });
      rolloverT = now + (REDUCED ? 1000 : 2300); // let the moment land first
    } else if (pctNow < 190) {
      celebrated200 = false;
      if (pendingRollovers === 0) rolloverT = -1; // drained back below — keep the jar
    }
    if (rolloverT > 0 && now >= rolloverT) {
      rolloverT = -1;
      retire2d();
    }
    if (!announcedReady) {
      announcedReady = true;
      ctx.ready();
    }
    raf = (busy || rolloverT > 0) ? requestAnimationFrame(frame) : 0;
  }

  function wake() {
    if (!raf && !paused) {
      lastT = performance.now();
      raf = requestAnimationFrame(frame);
    }
  }

  // ---------------------------------------------------------------- resize

  function layout() {
    W = host.clientWidth;
    H = host.clientHeight;
    if (!W || !H) return;
    dpr = Math.min(devicePixelRatio || 1, CFG.dprMax);
    for (const c of [canvas, pileC, outC, backC, frontC]) {
      c.width = Math.ceil(W * dpr);
      c.height = Math.ceil(H * dpr);
    }
    canvas.style.width = W + 'px';
    canvas.style.height = H + 'px';

    // frame the jar into the free band the host left us between its native
    // HUD (insets.top), bottom chrome (insets.bottom) and — on wide stages —
    // the QR rail (insets.right): the jar centres in the working area to the
    // left of the rail instead of hiding behind it.
    const topPad = insets.top + 8;
    const botPad = insets.bottom + 26;
    const band = Math.max(160, H - topPad - botPad);
    JH = Math.min(band * 0.96, W * 1.55);
    cx = ((insets.left || 0) + (W - (insets.right || 0))) / 2;
    jarBot = H - botPad - band * 0.02;
    interiorPath = buildInteriorPath(true);
    jarInnerPath = buildInteriorPath(false);
    sprites = buildSprites();
    bakeBack();
    bakeFront();
    rebake();
    const hadArchives = archives.length;
    archives.length = 0; // snapshots are resolution-bound — refabricate
    if (hadArchives || bankedJars > 0) ensureArchives();
    render();
  }

  let rsTimer = 0;
  addEventListener('resize', () => {
    clearTimeout(rsTimer);
    rsTimer = setTimeout(layout, 120);
  });

  // ---------------------------------------------------------------- controller

  // fill instantly (restore / style switch) — no pour animation
  function setInstant(pct) {
    pct = Math.min(200, Math.max(0, Math.round(pct || 0)));
    targetN = countFromPct(pct);
    queue.length = 0; air.length = 0; ghosts.length = 0;
    landed.clear();
    for (let i = 0; i < targetN; i++) landed.add(i);
    rebake();
    celebrated = targetN >= pile.nIn && targetN > 0;
    celebrated200 = targetN === items.length && items.length > pile.nIn;
    rolloverT = (celebrated200 && pendingRollovers > 0) ? performance.now() + 2500 : -1;
    milestonesFired.clear();
    for (const m of MILESTONES) if (pct >= m) milestonesFired.add(m);
    render();
    if (rolloverT > 0) wake();
  }

  function flushPendingRollovers() {
    if (pendingRollovers > 0) {
      bankedJars += pendingRollovers;
      pendingRollovers = 0;
      const p = afterPct >= 0 ? afterPct : 0;
      afterPct = -1;
      rolloverT = -1;
      return p;
    }
    return null;
  }

  function currentPct() {
    return Math.round(pctFromCount(targetN));
  }

  function applyTip(m) {
    // announce the tip itself: ta-da (if enabled) + a small confetti pop,
    // bigger when the tip is ≥10% of the goal (confettiBurst no-ops REDUCED)
    sound.tada();
    confettiBurst((+m.deltaPct || 0) >= 0.1 ? 44 : 18);
    const after = Math.min(2, Math.max(0, +m.jarPctAfter || 0)) * 100;
    const rolls = Math.max(0, Math.floor(m.rollovers || 0));
    if (rolls > 0) {
      pendingRollovers += rolls;
      afterPct = after;
      pourToCount(items.length);
    } else if (pendingRollovers > 0) {
      afterPct = after;
    } else {
      pourToCount(countFromPct(after));
    }
  }

  function syncState(state, instant) {
    pendingRollovers = 0;
    afterPct = -1;
    rolloverT = -1;
    bankedJars = Math.max(0, Math.floor(state.bankedJars || 0));
    ensureArchives();
    const pct = Math.min(2, Math.max(0, +state.jarPct || 0)) * 100;
    if (instant) setInstant(pct);
    else pourToCount(countFromPct(pct));
  }

  function setConfig(cfg) {
    if (cfg.insets) { insets = { top: 0, bottom: 0, ...cfg.insets }; layout(); }
    if (cfg.theme !== undefined) {
      const t = THEMES.find(x => x.key === cfg.theme);
      if (t) {
        theme = t;
        applyCssTheme(t);
        if (JH > 0) { bakeBack(); bakeFront(); render(); }
      }
    }
    if (cfg.sound !== undefined) sound.setCoins(!!cfg.sound);
    if (cfg.tipSound !== undefined) sound.setFanfare(!!cfg.tipSound);
    if (cfg.notes !== undefined && !!cfg.notes !== billsOn) {
      billsOn = !!cfg.notes;
      const flushed = flushPendingRollovers();
      const keepPct = flushed !== null ? flushed : currentPct();
      pile = buildPile();
      items = pile.items;
      setInstant(keepPct);
      ensureArchives();
    }
    // vessel / scene / quality: 3D-only concepts — ignored by contract
  }

  function setPaused(v) {
    v = !!v;
    if (v === paused) return;
    paused = v;
    if (paused) {
      if (raf) { cancelAnimationFrame(raf); raf = 0; }
    } else {
      wake();
      render(); // repaint immediately in case nothing animates
    }
  }

  // ---------------------------------------------------------------- boot

  const restorePct = Math.min(2, Math.max(0, (ctx.state && ctx.state.jarPct) || 0)) * 100;
  layout();
  ensureArchives();
  setInstant(restorePct);
  if (!announcedReady) {
    announcedReady = true;
    ctx.ready(); // idle boot: no frame() may ever run, announce from here
  }

  return {
    applyTip,
    syncState,
    setConfig,
    setPaused,
    jarPct: () => Math.min(2, Math.max(0, pctFromCount(targetN) / 100)),
    perf: () => ({
      fps: paused ? 0 : raf ? Math.round(1 / emaDt) : 60,
      quality: raf ? '2d' : 'idle',
    }),
  };
}
