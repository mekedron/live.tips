/** Tiny canvas→texture helpers shared by the money and scenery painters. */
import * as THREE from '../vendor/three.module.min.js';

export function makeCanvas(w, h) {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  return [c, c.getContext('2d')];
}

export function toTexture(c) {
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 4;
  return t;
}

export function canvasTexture(w, h, paint) {
  const [c, g] = makeCanvas(w, h);
  paint(g, w, h);
  return toTexture(c);
}
