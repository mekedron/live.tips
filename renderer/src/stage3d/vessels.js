/**
 * Vessels — real-world containers and their derived geometry.
 *
 * Scale anchor: a €2 coin is Ø25.75 mm and renders at world Ø0.21 → MM u/mm.
 * Capacity math (COINS ONLY — notes are a future overflow mechanic):
 * loose-poured coins pack at ~0.55, the euro mix averages ≈0.99 cm³/coin
 * → ≈556 coins per litre; the mix (20% ×5c, 55% ×50c, 25% ×€2) is worth
 * ≈€0.785 per coin → a vessel's goal is what physically fits inside it.
 *
 * These lathe profiles are placeholders for future real 3D models — swapping
 * them means replacing vesselProfile()/the glass build, while the spec's
 * packing fields (rIn, fillBottom/fillTop, mouthR…) keep driving the pour.
 */
import * as THREE from '../vendor/three.module.min.js';

export const MM = 0.21 / 25.75;
export const COINS_PER_LITER = 556;
export const AVG_COIN_VALUE = 0.785;

// Sorted by capacity — artists pick a vessel as a goal, so the picker reads
// as a clean € ladder: 20 / 50 / 100 / 125 / 250 / 500 / 1,000 / 1,500 /
// 3,000 / 6,000. `target` is the exact goal the pile is trimmed to (see
// buildPile); dims/fill are padded so the raw sim lands a few % above it.
export const CONTAINERS = [
  { key: 'caviar', kind: 'jar',    label: 'Caviar jar — 95 ml',  liters: 0.095, bodyD: 71,  bodyH: 52,  neckD: 56,  target: 20 },
  { key: 'tin',    kind: 'mug',    label: 'Tin can — 0.3 L',     liters: 0.3,   bodyD: 78,  bodyH: 84,  fill: 0.92, target: 50 },
  { key: 'mug',    kind: 'mug',    label: 'Beer mug — 0.5 L',    liters: 0.5,   bodyD: 82,  bodyH: 98,  fill: 0.97, target: 100, handle: true },
  { key: 'jar05',  kind: 'jar',    label: 'Jar — 0.5 L',         liters: 0.5,   bodyD: 86,  bodyH: 130, neckD: 66,  target: 125 },
  { key: 'jar1',   kind: 'jar',    label: 'Jar — 1 L',           liters: 1,     bodyD: 106, bodyH: 166, neckD: 76,  target: 250 },
  { key: 'jar2',   kind: 'jar',    label: 'Jar — 2 L',           liters: 2,     bodyD: 122, bodyH: 214, neckD: 82,  target: 500 },
  { key: 'stage',  kind: 'stage',  label: 'Stage jar — stylized 2 L', target: 500 },
  { key: 'jar3',   kind: 'jar',    label: 'Jar — 3 L',           liters: 3,     bodyD: 153, bodyH: 242, neckD: 84,  target: 1000 },
  { key: 'jar5',   kind: 'jar',    label: 'Pickle jar — 5 L',    liters: 5,     bodyD: 170, bodyH: 290, neckD: 110, target: 1500 },
  { key: 'bucket', kind: 'bucket', label: 'Bucket — 10 L',       liters: 10,    bodyD: 260, bodyH: 230, botD: 220, fill: 0.96, target: 3000 },
  { key: 'bowl',   kind: 'sphere', label: 'Fishbowl — 20 L',     liters: 20,    bodyD: 340, bodyH: 330, neckD: 180, fill: 0.64, target: 6000 },
];
export const DEFAULT_CONTAINER = 'stage';

export function containerLabel(c) {
  const L = c.liters || 2;
  return `${c.label} · ~€${Math.round(L * COINS_PER_LITER * AVG_COIN_VALUE).toLocaleString('en')}`;
}

// Derive world-space geometry + packing parameters from real dimensions.
export function containerSpec(c) {
  if (c.kind === 'stage') {
    // The original stylized look with its loose theatrical packing, scaled so
    // the simulated capacity matches a REAL 2 L jar (≈€485): the unscaled body
    // held €947 — nearly the 3 L jar — which broke the picker's honest ladder.
    // Scaled so the raw capacity lands a touch above the €500 target (the
    // pile is then trimmed to exactly €500); fill reaches into the shoulder.
    const S = 0.84;
    return {
      key: c.key, kind: 'jar', stage: true, liters: 2, target: c.target,
      R: 0.84 * S, wall: 0.06 * S, coinH: 0.032, layerStep: 0.052, density: 0.66,
      wallTop: 2.55 * S, shoulderEnd: 2.90 * S, neckR: 0.554 * S, topY: 3.28 * S,
      fillBottom: 0.16 * S, fillTop: 2.88 * S, mouthR: 0.49 * S,
      centerY: 1.66 * S, camSpan: 3.95 * S + 0.35,
      rIn(y) {
        if (y <= 2.55 * S) return 0.78 * S;
        if (y >= 2.90 * S) return 0.505 * S;
        const k = (y - 2.55 * S) / (0.35 * S), s = k * k * (3 - 2 * k);
        return (0.78 + (0.505 - 0.78) * s) * S;
      },
    };
  }
  const R = (c.bodyD / 2) * MM;
  const H = c.bodyH * MM;
  const wall = Math.max(0.02, Math.min(0.04, R * 0.07));
  const spec = {
    key: c.key, kind: c.kind, liters: c.liters, target: c.target, handle: c.handle,
    R, H, wall,
    coinH: 0.018,               // real €2 thickness (2.2 mm)
    layerStep: 0.018 * 1.42,    // settled layer pitch incl. tilts
    density: 0.86,              // coins per layer ≈ (rIn/coinR)² × density
    fillBottom: wall + 0.05,
  };
  if (c.kind === 'jar') {
    const neckR = (c.neckD / 2) * MM;
    const shoulderH = Math.max(0.06, Math.min(H * 0.18, (R - neckR) * 1.2 + 0.04));
    const neckH = Math.max(0.05, Math.min(15 * MM, H * 0.2));
    spec.wallTop = H - shoulderH - neckH;
    spec.shoulderEnd = spec.wallTop + shoulderH;
    spec.neckR = neckR;
    spec.topY = H;
    spec.fillTop = Math.max(spec.wallTop * 0.9, spec.shoulderEnd - shoulderH * 0.35);
    spec.mouthR = neckR - wall * 0.8;
    spec.rIn = (y) => {
      const rb = R - wall, rn = neckR - wall * 0.8;
      if (y <= spec.wallTop) return rb;
      if (y >= spec.shoulderEnd) return rn;
      const k = (y - spec.wallTop) / (spec.shoulderEnd - spec.wallTop);
      const s = k * k * (3 - 2 * k);
      return rb + (rn - rb) * s;
    };
  } else if (c.kind === 'mug') {
    spec.topY = H;
    spec.fillTop = H * (c.fill || 0.88);
    spec.mouthR = R - wall;
    spec.rIn = () => R - wall;
  } else if (c.kind === 'bucket') {
    const rBot = (c.botD / 2) * MM;
    spec.rBot = rBot;
    spec.topY = H;
    spec.fillTop = H * (c.fill || 0.9);
    spec.mouthR = R - wall;
    spec.rIn = (y) => rBot + (R - rBot) * Math.min(1, Math.max(0, y / H)) - wall;
  } else { // sphere fishbowl
    const mouthR = (c.neckD / 2) * MM;
    const cy = R * 0.92;
    spec.cy = cy;
    spec.mouthR = mouthR;
    spec.topY = cy + Math.sqrt(Math.max(0.01, R * R - mouthR * mouthR));
    spec.fillTop = cy + R * (c.fill || 0.5); // he's right: there IS room up top
    spec.rIn = (y) => Math.sqrt(Math.max(0.0004, R * R - (y - cy) * (y - cy))) - wall;
  }
  spec.centerY = spec.topY * 0.5;
  spec.camSpan = spec.topY + 1.1;
  return spec;
}

// Lathe profile for a container spec — the glass silhouette.
export function vesselProfile(spec) {
  const pts = [];
  const P = (r, y) => pts.push(new THREE.Vector2(Math.max(0.001, r), y));
  if (spec.kind === 'jar') {
    const { R, wallTop, shoulderEnd, neckR, topY } = spec;
    const rimH = Math.min(0.05, (topY - shoulderEnd) * 0.45);
    P(0.001, 0); P(R * 0.8, 0); P(R * 0.95, R * 0.06); P(R, R * 0.2);
    P(R, wallTop);
    P(R * 0.96, wallTop + (shoulderEnd - wallTop) * 0.4);
    P((R + neckR) * 0.5, wallTop + (shoulderEnd - wallTop) * 0.8);
    P(neckR * 1.02, shoulderEnd);
    P(neckR, shoulderEnd + 0.01);
    P(neckR, topY - rimH);
    P(neckR * 1.09, topY - rimH * 0.6);
    P(neckR * 1.09, topY - rimH * 0.15);
    P(neckR, topY);
    P(neckR * 0.88, topY);
  } else if (spec.kind === 'mug') {
    const { R, topY } = spec;
    P(0.001, 0); P(R * 0.85, 0); P(R, R * 0.15);
    P(R, topY - 0.02); P(R * 1.04, topY - 0.01); P(R * 1.04, topY); P(R * 0.9, topY);
  } else if (spec.kind === 'bucket') {
    const { R, rBot, topY } = spec;
    P(0.001, 0); P(rBot * 0.9, 0); P(rBot, 0.04);
    P(R, topY - 0.03);
    P(R * 1.06, topY - 0.015); P(R * 1.06, topY); P(R * 0.93, topY);
  } else { // sphere fishbowl
    const { R, cy, mouthR, topY } = spec;
    const a0 = Math.asin(Math.max(-1, (0 - cy) / R));
    const a1 = Math.asin(Math.min(1, (topY - cy) / R));
    P(0.001, 0);
    for (let i = 0; i <= 22; i++) {
      const a = a0 + (a1 - a0) * (i / 22);
      P(Math.cos(a) * R, cy + Math.sin(a) * R);
    }
    P(mouthR * 0.9, topY);
  }
  return pts;
}
