/**
 * Money assets — the LOOK of the euros (textures, tints, geometry buckets).
 * Euro-like, minus the € glyph — colors, relative sizes and numerals do the
 * talking. Coins: copper cents / "Nordic gold" 10–50c / bimetallic €2.
 *
 * The pour/pile simulation in app.js only consumes the BUCKETS array —
 * replacing these procedural looks with real 3D coin/bill models later means
 * swapping what createMoneyAssets() returns, nothing else.
 */
import * as THREE from '../vendor/three.module.min.js';
import { makeCanvas, toTexture } from './tex.js';

const GOLD_TINTS = [0xf0c25e, 0xf6cc6c, 0xe2af4c];
const COPPER_TINTS = [0xd18a50, 0xc47c42, 0xdd9c64];
const BI_TINTS = [0xffffff, 0xf1f1f1, 0xe9e9e9];       // baked-color caps, brightness only
const BILL_TINTS = [0xffffff, 0xf6f2ea, 0xefefef];
const BILL_SPECS = {
  b5:  { n: '5',  bg: '#bcc0c5', dk: '#565b61', band: '#dfe2e6' }, // €5  grey
  b10: { n: '10', bg: '#d89b94', dk: '#8a4a44', band: '#eecfcb' }, // €10 red
  b20: { n: '20', bg: '#92aed6', dk: '#40608c', band: '#d3e0f0' }, // €20 blue
  b50: { n: '50', bg: '#e0a95e', dk: '#8f6222', band: '#f2ddb4' }, // €50 orange
};

// Coin face. Plain caps are near-white (per-instance color tints them into
// gold/copper); the bimetallic €2 cap is baked in real colors.
function coinCapTexture(numeral, bimetal) {
  const [c, g] = makeCanvas(128, 128);
  const grad = g.createRadialGradient(50, 46, 10, 64, 64, 86);
  if (bimetal) {
    grad.addColorStop(0, '#eef0f3'); grad.addColorStop(0.72, '#d6dade'); grad.addColorStop(1, '#a9afb7');
  } else {
    grad.addColorStop(0, '#ffffff'); grad.addColorStop(0.72, '#efefef'); grad.addColorStop(1, '#c8c8c8');
  }
  g.fillStyle = grad;
  g.fillRect(0, 0, 128, 128);
  if (bimetal) {
    const cg = g.createRadialGradient(56, 54, 6, 64, 64, 40);
    cg.addColorStop(0, '#f4d98c'); cg.addColorStop(0.8, '#e2b04f'); cg.addColorStop(1, '#bb8d33');
    g.fillStyle = cg;
    g.beginPath(); g.arc(64, 64, 38, 0, 7); g.fill();
    g.strokeStyle = 'rgba(96,82,48,0.5)';
    g.lineWidth = 2;
    g.beginPath(); g.arc(64, 64, 38, 0, 7); g.stroke();
  }
  g.strokeStyle = 'rgba(84,84,88,0.5)';
  g.lineWidth = 4;
  g.beginPath(); g.arc(64, 64, 58, 0, 7); g.stroke();
  // ring of 12 dots — the EU stars, abstracted (no € anywhere)
  g.fillStyle = 'rgba(88,88,92,0.5)';
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    g.beginPath(); g.arc(64 + Math.cos(a) * 49, 64 + Math.sin(a) * 49, 2.6, 0, 7); g.fill();
  }
  // engraved numeral: light offset below, ink on top
  g.font = '800 46px Georgia, serif';
  g.textAlign = 'center'; g.textBaseline = 'middle';
  g.fillStyle = 'rgba(255,255,255,0.5)';
  g.fillText(numeral, 65.5, 67.5);
  g.fillStyle = bimetal ? 'rgba(80,60,22,0.72)' : 'rgba(70,70,72,0.6)';
  g.fillText(numeral, 64, 66);
  return toTexture(c);
}

// Euro-note look: tinted paper, light central band, arch motif, big numeral.
function billTexture(bs) {
  const [c, g] = makeCanvas(256, 128);
  g.fillStyle = bs.bg;
  g.fillRect(0, 0, 256, 128);
  g.fillStyle = bs.band;
  g.fillRect(150, 8, 62, 112);
  g.strokeStyle = bs.dk;
  g.globalAlpha = 0.55; g.lineWidth = 3;
  g.strokeRect(7, 7, 242, 114);
  g.globalAlpha = 0.35; g.lineWidth = 1.5;
  g.strokeRect(13, 13, 230, 102);
  // arch / window motif on the left half
  g.globalAlpha = 0.5; g.lineWidth = 4;
  g.beginPath(); g.moveTo(42, 102); g.lineTo(42, 62); g.arc(70, 62, 28, Math.PI, 0); g.lineTo(98, 102); g.stroke();
  g.globalAlpha = 0.3; g.lineWidth = 2.5;
  g.beginPath(); g.moveTo(52, 102); g.lineTo(52, 64); g.arc(70, 64, 18, Math.PI, 0); g.lineTo(88, 102); g.stroke();
  g.globalAlpha = 1;
  g.fillStyle = bs.dk;
  g.textAlign = 'center'; g.textBaseline = 'middle';
  g.font = '900 46px Georgia, serif';
  g.fillText(bs.n, 222, 94);
  g.font = '900 26px Georgia, serif';
  g.fillText(bs.n, 28, 27);
  return toTexture(c);
}

// Bill: plane with a baked-in gentle crumple so instances don't look laser-flat.
function billGeometry(CFG) {
  const g = new THREE.PlaneGeometry(CFG.billW, CFG.billH, 12, 5);
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i);
    const n = Math.sin(x * 91.7 + y * 57.3) * 43758.5453;
    const z =
      0.02 * Math.sin(x * 12.0) +
      0.016 * Math.sin(y * 16.0 + x * 6.0) +
      (n - Math.floor(n) - 0.5) * 0.014;
    pos.setZ(i, z);
  }
  g.computeVertexNormals();
  return g;
}

/**
 * One entry per denomination bucket; each becomes ONE InstancedMesh. Coins
 * carry per-denomination relative sizes (real euro proportions); tints add
 * per-instance variation. `value` is what a landed item adds to the HUD.
 */
export function createMoneyAssets(CFG) {
  const BUCKETS = [
    { key: 'gold',   kind: 'coin', value: 0.5,  map: coinCapTexture('50', false), side: 0xdedede, tints: GOLD_TINTS,   scale: [0.88, 0.97] },
    { key: 'copper', kind: 'coin', value: 0.05, map: coinCapTexture('5', false),  side: 0xdedede, tints: COPPER_TINTS, scale: [0.78, 0.86] },
    { key: 'bi',     kind: 'coin', value: 2,    map: coinCapTexture('2', true),   side: 0xd6dade, tints: BI_TINTS,     scale: [0.98, 1.06] },
    { key: 'b5',  kind: 'bill', value: 5,  map: billTexture(BILL_SPECS.b5),  tints: BILL_TINTS },
    { key: 'b10', kind: 'bill', value: 10, map: billTexture(BILL_SPECS.b10), tints: BILL_TINTS },
    { key: 'b20', kind: 'bill', value: 20, map: billTexture(BILL_SPECS.b20), tints: BILL_TINTS },
    { key: 'b50', kind: 'bill', value: 50, map: billTexture(BILL_SPECS.b50), tints: BILL_TINTS },
  ];
  return { BUCKETS, billGeo: billGeometry(CFG) };
}
