/**
 * Metro underpass — the jar on flattened cardboard: grimy celadon tiles, dark
 * corridor arches, EXIT/TRAINS signs, an "M" roundel, tiled columns, granite
 * floor and humming fluorescent fixtures under a low ceiling.
 */
import * as THREE from '../../vendor/three.module.min.js';
import { mulberry32 } from '../../shared/ui.js';
import { ROOM_R, canvasTexture, roomWall, floorDisc } from './lib.js';

// Metro underpass: the wall is short (10 wu) so 1 wu ≈ 51 px vertically —
// signage actually resolves. Layout: arches → signs → posters between them.
function paintMetroWall(g, w, h) {
  const r = mulberry32(83);
  const Y = (wu) => h - (wu + 0.065) / 10.065 * h; // wall-y (wu) → canvas y
  // this wall is 16× wider than tall → horizontal px are ~4× wider than
  // vertical ones. Anything that must stay round (roundel, arches, posters)
  // is drawn inside a scale(SX, 1) transform to compensate.
  const SX = (w / (Math.PI * 2 * ROOM_R)) / (h / 10.065);
  // grimy celadon tile field
  g.fillStyle = '#93a294';
  g.fillRect(0, 0, w, h);
  const t = 15;
  for (let ty = 0; ty < h; ty += t) {
    for (let tx = 0; tx < w; tx += t) {
      const v = (r() - 0.5) * 26;
      g.fillStyle = v > 0 ? `rgba(255,255,250,${v / 255})` : `rgba(30,40,32,${-v / 255})`;
      g.fillRect(tx, ty, t - 1, t - 1);
    }
  }
  g.fillStyle = 'rgba(20,26,20,0.35)'; // grout
  for (let ty = t - 1; ty < h; ty += t) g.fillRect(0, ty, w, 1);
  for (let tx = t - 1; tx < w; tx += t) g.fillRect(tx, 0, 1, h);
  // ceiling shadow + rising damp
  let gr = g.createLinearGradient(0, 0, 0, h * 0.45);
  gr.addColorStop(0, 'rgba(8,11,9,0.75)');
  gr.addColorStop(1, 'rgba(8,11,9,0)');
  g.fillStyle = gr;
  g.fillRect(0, 0, w, h * 0.45);
  gr = g.createLinearGradient(0, h, 0, h - 90);
  gr.addColorStop(0, 'rgba(28,24,14,0.5)');
  gr.addColorStop(1, 'rgba(28,24,14,0)');
  g.fillStyle = gr;
  g.fillRect(0, h - 90, w, 90);
  // vertical grime streaks
  for (let i = 0; i < 46; i++) {
    const x = r() * w, sw = 3 + r() * 12, sy = r() * h * 0.5;
    g.fillStyle = `rgba(24,30,24,${0.03 + r() * 0.06})`;
    g.fillRect(x, sy, sw, h - sy);
  }
  // dark green accent band
  g.fillStyle = '#2c3f33';
  g.fillRect(0, Y(1.95), w, Y(1.5) - Y(1.95));
  g.fillStyle = 'rgba(255,255,255,0.1)';
  g.fillRect(0, Y(1.95), w, 2);
  // dark corridor arches leading away (aspect-corrected)
  for (const ux of [0.1, 0.42, 0.78]) {
    g.save();
    g.translate(w * ux, h);
    g.scale(SX, 1);
    const aw = 145, top = Y(3.2) - h;
    g.fillStyle = '#0a0d0b';
    g.beginPath();
    g.moveTo(-aw / 2, 0);
    g.lineTo(-aw / 2, top + aw / 2);
    g.arc(0, top + aw / 2, aw / 2, Math.PI, 0);
    g.lineTo(aw / 2, 0);
    g.fill();
    g.strokeStyle = 'rgba(200,215,200,0.22)'; // tiled reveal edge
    g.lineWidth = 5;
    g.stroke();
    g.restore();
  }
  // navy direction signs
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  for (const [ux, txt] of [[0.24, 'EXIT  →'], [0.64, '←  TRAINS']]) {
    const cx = w * ux, cy = Y(2.35);
    g.fillStyle = '#16337a';
    g.fillRect(cx - 92, cy - 22, 184, 44);
    g.strokeStyle = '#e8edf4';
    g.lineWidth = 2.5;
    g.strokeRect(cx - 87, cy - 17, 174, 34);
    g.fillStyle = '#f2f5fa';
    g.font = '700 23px Arial, sans-serif';
    g.fillText(txt, cx, cy + 1);
  }
  // metro roundel (aspect-corrected circle)
  g.save();
  g.translate(w * 0.52, Y(2.5));
  g.scale(SX, 1);
  g.fillStyle = '#1d4ea3';
  g.beginPath(); g.arc(0, 0, 58, 0, 7); g.fill();
  g.strokeStyle = '#eef2f8';
  g.lineWidth = 6;
  g.beginPath(); g.arc(0, 0, 50, 0, 7); g.stroke();
  g.fillStyle = '#f4f7fb';
  g.font = '800 64px Georgia, serif';
  g.fillText('M', 0, 4);
  g.restore();
  // taped-up posters (aspect-corrected)
  for (const [ux, txt, tilt] of [[0.33, 'LIVE', -0.06], [0.71, 'GIG', 0.05], [0.88, 'SALE', -0.04]]) {
    g.save();
    g.translate(w * ux, Y(1.25));
    g.scale(SX, 1);
    g.rotate(tilt);
    g.fillStyle = '#cfc8b6';
    g.fillRect(-34, -46, 68, 92);
    g.fillStyle = '#2a2420';
    g.font = '800 21px Georgia, serif';
    g.fillText(txt, 0, -14);
    g.font = '700 12px Georgia, serif';
    g.fillText('TONIGHT', 0, 14);
    g.restore();
  }
}

function paintMetroFloor(g, w, h) {
  const r = mulberry32(89);
  g.fillStyle = '#26292c';
  g.fillRect(0, 0, w, h);
  const s = 60;
  for (let ty = 0; ty < h; ty += s) {
    for (let tx = 0; tx < w; tx += s) {
      const v = (r() - 0.5) * 16;
      g.fillStyle = v > 0 ? `rgba(210,220,226,${v / 255})` : `rgba(4,6,8,${-v / 255})`;
      g.fillRect(tx + 1, ty + 1, s - 2, s - 2);
    }
  }
  for (let i = 0; i < 14; i++) { // stains and scuffs
    g.fillStyle = `rgba(12,14,12,${0.04 + r() * 0.05})`;
    g.beginPath();
    g.ellipse(r() * w, r() * h, 24 + r() * 90, 16 + r() * 60, r() * 3, 0, 7);
    g.fill();
  }
  const wear = g.createRadialGradient(512, 512, 60, 512, 512, 520);
  wear.addColorStop(0, 'rgba(255,255,255,0.04)'); // polished by foot traffic
  wear.addColorStop(0.6, 'rgba(255,255,255,0)');
  wear.addColorStop(1, 'rgba(0,0,0,0.55)');
  g.fillStyle = wear;
  g.fillRect(0, 0, w, h);
}

function paintMetroCeiling(g, w, h) {
  const r = mulberry32(97);
  g.fillStyle = '#1c201d';
  g.fillRect(0, 0, w, h);
  for (let i = 0; i < 30; i++) {
    g.fillStyle = `rgba(0,0,0,${0.05 + r() * 0.08})`;
    g.beginPath();
    g.ellipse(r() * w, r() * h, 30 + r() * 80, 20 + r() * 50, r() * 3, 0, 7);
    g.fill();
  }
  for (const y of [86, 200, 314, 428]) { // fluorescent strip rows
    const halo = g.createLinearGradient(0, y - 34, 0, y + 34);
    halo.addColorStop(0, 'rgba(210,235,220,0)');
    halo.addColorStop(0.5, 'rgba(210,235,220,0.22)');
    halo.addColorStop(1, 'rgba(210,235,220,0)');
    g.fillStyle = halo;
    g.fillRect(0, y - 34, w, 68);
    g.fillStyle = '#dfe8e2';
    g.fillRect(0, y - 6, w, 12);
  }
}

function paintMetroColumn(g, w, h) {
  const r = mulberry32(101);
  g.fillStyle = '#8b998c';
  g.fillRect(0, 0, w, h);
  const t = 26;
  for (let ty = 0; ty < h; ty += t) {
    for (let tx = 0; tx < w; tx += t) {
      const v = (r() - 0.5) * 24;
      g.fillStyle = v > 0 ? `rgba(255,255,250,${v / 255})` : `rgba(30,40,32,${-v / 255})`;
      g.fillRect(tx, ty, t - 1, t - 1);
    }
  }
  g.fillStyle = 'rgba(20,26,20,0.35)';
  for (let ty = t - 1; ty < h; ty += t) g.fillRect(0, ty, w, 1);
  for (let tx = t - 1; tx < w; tx += t) g.fillRect(tx, 0, 1, h);
  g.fillStyle = '#23262a'; // skirting
  g.fillRect(0, h - 40, w, 40);
  const gr = g.createLinearGradient(0, 0, 0, 60);
  gr.addColorStop(0, 'rgba(10,14,11,0.5)');
  gr.addColorStop(1, 'rgba(10,14,11,0)');
  g.fillStyle = gr;
  g.fillRect(0, 0, w, 60);
  for (let i = 0; i < 10; i++) {
    const x = r() * w;
    g.fillStyle = `rgba(24,30,24,${0.04 + r() * 0.05})`;
    g.fillRect(x, r() * h * 0.4, 4 + r() * 8, h);
  }
}

function paintCardboard(g, w, h) {
  const r = mulberry32(103);
  g.fillStyle = '#6e5330';
  g.fillRect(0, 0, w, h);
  for (let i = 0; i < 24; i++) { // scuffs
    g.fillStyle = `rgba(${r() > 0.5 ? '40,26,10' : '190,165,120'},${0.03 + r() * 0.04})`;
    g.beginPath();
    g.ellipse(r() * w, r() * h, 12 + r() * 40, 8 + r() * 24, r() * 3, 0, 7);
    g.fill();
  }
  g.strokeStyle = 'rgba(46,30,12,0.55)'; // fold crease
  g.lineWidth = 3;
  g.beginPath();
  g.moveTo(0, h * 0.52);
  g.lineTo(w, h * 0.5);
  g.stroke();
  g.fillStyle = 'rgba(200,188,160,0.3)'; // packing tape
  g.fillRect(w * 0.62, 0, 26, h);
  g.strokeStyle = 'rgba(46,30,12,0.65)'; // worn edges
  g.lineWidth = 8;
  g.strokeRect(2, 2, w - 4, h - 4);
}

export default {
  key: 'metro', label: 'Metro underpass',
  dome: ['#101211', '#242a26', '#47524b', '#9fb3a7'],
  hemi: [0xcfe8dc, 0x14171a, 0.5],
  keyL: [0xe8fff2, 1.05], rimL: [0x8fa8ff, 0.55],
  beamInt: 0.09, beamColor: [0.72, 0.85, 0.78], dustColor: [0.72, 0.85, 0.78], poolColor: '190,215,200',
  bg: ['#202622', '#121613', '#070908'], glassEnv: 1,
  spillR: (spec) => Math.max(2.7, spec.R * 2 + 0.8) * 0.41 - 0.05, // cardboard sheet
  archY: -0.065, // granite floor around the cardboard

  build(gr, spec) {
    const floorY = -0.065, ceilY = 10; // wide low hall — underpass proportions
    // flattened cardboard under the vessel, busker style
    const cw = Math.max(2.7, spec.R * 2 + 0.8);
    const card = new THREE.Mesh(
      new THREE.BoxGeometry(cw, 0.045, cw * 0.82),
      new THREE.MeshStandardMaterial({
        map: canvasTexture(256, 192, paintCardboard),
        roughness: 0.94, envMapIntensity: 0.1,
      })
    );
    card.position.y = -0.0425; // top at -0.02, flush under the vessel
    card.rotation.y = 0.16;
    gr.add(card);
    gr.add(floorDisc(ROOM_R + 0.6, floorY, paintMetroFloor, { rough: 0.55, env: 0.35 }));
    gr.add(roomWall(ROOM_R, floorY, ceilY, paintMetroWall));
    // low concrete ceiling with painted strip lights
    const ceil = new THREE.Mesh(
      new THREE.CircleGeometry(ROOM_R, 40),
      new THREE.MeshBasicMaterial({ map: canvasTexture(512, 512, paintMetroCeiling), side: THREE.DoubleSide })
    );
    ceil.rotation.x = Math.PI / 2;
    ceil.position.y = ceilY;
    gr.add(ceil);
    // tiled columns holding the ceiling up
    const colMat = new THREE.MeshStandardMaterial({
      map: canvasTexture(256, 512, paintMetroColumn),
      roughness: 0.6, envMapIntensity: 0.3,
    });
    for (const [x, z] of [[-7, -7.5], [7.5, -8], [-9.5, 3.5], [8.5, 6]]) {
      const col = new THREE.Mesh(new THREE.BoxGeometry(1.35, ceilY - floorY, 1.35), colMat);
      col.position.set(x, (ceilY + floorY) / 2, z);
      gr.add(col);
    }
    // humming fluorescent fixtures
    for (const [x, y, z, ry] of [[0, 6.9, -4.2, 0.4], [-5, 6.7, -0.5, 1.25], [4.6, 7.1, 2.8, -0.5]]) {
      const fix = new THREE.Group();
      const housing = new THREE.Mesh(
        new THREE.BoxGeometry(2.6, 0.09, 0.24),
        new THREE.MeshStandardMaterial({ color: 0x2a2e2c, roughness: 0.7 })
      );
      const tubeMesh = new THREE.Mesh(
        new THREE.BoxGeometry(2.4, 0.055, 0.1),
        new THREE.MeshBasicMaterial({ color: new THREE.Color(0xe4ffe9).multiplyScalar(2.3) })
      );
      tubeMesh.position.y = -0.06;
      fix.add(housing, tubeMesh);
      fix.position.set(x, y, z);
      fix.rotation.y = ry;
      gr.add(fix);
    }
  },
};
