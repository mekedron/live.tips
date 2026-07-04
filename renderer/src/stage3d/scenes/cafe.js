/** Cozy café — pedestal table, fairy-light strands, chalkboard menu wall. */
import * as THREE from '../../vendor/three.module.min.js';
import { mulberry32 } from '../../shared/ui.js';
import {
  ROOM_R, ROOM_TOP, canvasTexture, paintPlanks, roomWall, floorDisc, ceilingDisc,
  addFairyLights, addTableProp,
} from './lib.js';

function paintCafeWall(g, w, h) {
  const r = mulberry32(53);
  const grad = g.createLinearGradient(0, 0, 0, h);
  grad.addColorStop(0, '#150c06');
  grad.addColorStop(0.55, '#2e1e10');
  grad.addColorStop(1, '#402c18');
  g.fillStyle = grad;
  g.fillRect(0, 0, w, h);
  for (let i = 0; i < 60; i++) { // plaster blotches
    g.fillStyle = `rgba(${r() > 0.5 ? '255,220,180' : '0,0,0'},${0.02 + r() * 0.04})`;
    g.beginPath();
    g.ellipse(r() * w, r() * h, 30 + r() * 90, 20 + r() * 60, r() * 3, 0, 7);
    g.fill();
  }
  const eye = h * 0.75;
  for (let i = 0; i < 6; i++) { // warm sconces
    const x = w * (0.06 + i * 0.16 + r() * 0.03);
    const gl = g.createRadialGradient(x, eye - 60, 8, x, eye - 60, 150);
    gl.addColorStop(0, 'rgba(255,196,120,0.5)');
    gl.addColorStop(1, 'rgba(255,196,120,0)');
    g.fillStyle = gl;
    g.fillRect(x - 150, eye - 210, 300, 300);
    g.fillStyle = '#ffe2b0';
    g.fillRect(x - 3, eye - 66, 6, 12);
  }
  // chalkboard menu
  const cx = w * 0.5 - 110, cy = eye - 205;
  g.fillStyle = '#4a3018';
  g.fillRect(cx - 10, cy - 10, 240, 180);
  g.fillStyle = '#141a14';
  g.fillRect(cx, cy, 220, 160);
  g.fillStyle = 'rgba(226,238,226,0.85)';
  g.font = '700 34px Georgia, serif';
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.fillText('MENU', cx + 110, cy + 36);
  g.strokeStyle = 'rgba(226,238,226,0.5)';
  g.lineWidth = 3;
  for (let i = 0; i < 4; i++) {
    g.beginPath();
    g.moveTo(cx + 26, cy + 70 + i * 22);
    g.lineTo(cx + 194 - r() * 40, cy + 70 + i * 22);
    g.stroke();
  }
  // shelves with potted plants
  for (const ux of [0.2, 0.78]) {
    const sx = w * ux - 130, sy = eye - 130;
    g.fillStyle = '#5a3a1c';
    g.fillRect(sx, sy, 260, 9);
    for (let i = 0; i < 4; i++) {
      const x = sx + 20 + i * 62, s = 0.7 + r() * 0.5;
      g.fillStyle = '#7a4a22';
      g.fillRect(x, sy - 22 * s, 26 * s, 22 * s);
      g.fillStyle = '#2e5424';
      g.beginPath(); g.arc(x + 13 * s, sy - 30 * s, 16 * s, 0, 7); g.fill();
      g.beginPath(); g.arc(x + 4 * s, sy - 24 * s, 10 * s, 0, 7); g.fill();
      g.beginPath(); g.arc(x + 23 * s, sy - 24 * s, 10 * s, 0, 7); g.fill();
    }
  }
}

export default {
  key: 'cafe', label: 'Cozy café',
  dome: ['#1b120a', '#40301c', '#775833', '#e7c184'],
  hemi: [0xffd9a8, 0x2c1a0e, 0.78],
  keyL: [0xffe3bd, 1.3], rimL: [0xffb060, 0.5],
  beamInt: 0, beamColor: [1, 0.8, 0.5], dustColor: [1, 0.8, 0.5], poolColor: '255,200,130',
  bg: ['#211308', '#140b04', '#080401'], glassEnv: 0.7,
  spillR: (spec) => Math.max(2.0, spec.R + 0.55) - 0.12, // café table top
  archY: -3.32, // café floor below the pedestal table

  build(gr, spec) {
    const tR = Math.max(2.0, spec.R + 0.55), tH = 3.3; // pedestal table
    const top = new THREE.Mesh(
      new THREE.CylinderGeometry(tR, tR * 0.97, 0.14, 40),
      new THREE.MeshStandardMaterial({
        map: canvasTexture(512, 512, (g, w, h) => paintPlanks(g, w, h, { base: '#5a3a1c', planks: 8, light: 26, seed: 71 })),
        roughness: 0.55, envMapIntensity: 0.45,
      })
    );
    top.position.y = -0.09;
    gr.add(top);
    const metal = new THREE.MeshStandardMaterial({ color: 0x1c1a19, roughness: 0.5, metalness: 0.6 });
    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.14, tH - 0.3, 12), metal);
    stem.position.y = -0.16 - (tH - 0.3) / 2;
    gr.add(stem);
    const floorY = -0.02 - tH;
    const base = new THREE.Mesh(new THREE.CylinderGeometry(1.0, 1.15, 0.12, 24), metal);
    base.position.y = floorY + 0.06;
    gr.add(base);
    gr.add(floorDisc(ROOM_R + 0.6, floorY - 0.01,
      (g, w, h) => paintPlanks(g, w, h, { base: '#2c1c0e', planks: 13, horizontal: true, light: 22, seed: 77 })));
    gr.add(roomWall(ROOM_R, floorY, ROOM_TOP, paintCafeWall));
    gr.add(ceilingDisc(ROOM_R, ROOM_TOP, 0x120a05));
    // fairy-light strands low behind the table — the cozy carry of this scene
    addFairyLights(gr, new THREE.Vector3(-6.5, 5.2, -3.8), new THREE.Vector3(7, 4.6, -3.0), 1.6, 30);
    addFairyLights(gr, new THREE.Vector3(-5.5, 4.2, -5.6), new THREE.Vector3(6.5, 5.0, -5.2), 1.4, 26);
    addFairyLights(gr, new THREE.Vector3(-7, 4.4, 2.8), new THREE.Vector3(7.5, 5.2, 1.6), 1.8, 32);
    // mid-ground café tables with candles
    addTableProp(gr, -6.5, -9.5, floorY, 1.5);
    addTableProp(gr, 7.2, -10.5, floorY, 1.5);
    addTableProp(gr, 11.5, -2.5, floorY, 1.4);
  },
};
