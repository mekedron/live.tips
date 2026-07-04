/**
 * Night street — busking: a wooden crate on dark cobbles, brick wall with lit
 * windows and gig posters, a street lamp; the open wall side shows a painted
 * starry-sky background (the scene's own bg painter).
 */
import * as THREE from '../../vendor/three.module.min.js';
import { mulberry32 } from '../../shared/ui.js';
import {
  ROOM_R, ROOM_TOP, canvasTexture, paintPlanks, roomWall, floorDisc,
  bulb, glowDisc, tube,
} from './lib.js';

// Painted night sky for the scene background (visible through the open arc).
function streetSky(g) {
  const grad = g.createLinearGradient(0, 0, 0, 512);
  grad.addColorStop(0, '#04060d');
  grad.addColorStop(0.55, '#0a1120');
  grad.addColorStop(1, '#18243c');
  g.fillStyle = grad;
  g.fillRect(0, 0, 512, 512);
  const r = mulberry32(77);
  g.fillStyle = '#fff';
  for (let i = 0; i < 110; i++) {
    const x = r() * 512, y = r() * 300, s = r();
    g.globalAlpha = 0.12 + s * 0.5;
    g.fillRect(x, y, s > 0.85 ? 2 : 1, s > 0.85 ? 2 : 1);
  }
  g.globalAlpha = 1;
  const mg = g.createRadialGradient(392, 86, 4, 392, 86, 60);
  mg.addColorStop(0, 'rgba(234,240,255,0.95)');
  mg.addColorStop(0.16, 'rgba(215,226,255,0.85)');
  mg.addColorStop(0.2, 'rgba(190,205,240,0.25)');
  mg.addColorStop(1, 'rgba(190,205,240,0)');
  g.fillStyle = mg;
  g.fillRect(0, 0, 512, 512);
}

function paintBrickWall(g, w, h) {
  const r = mulberry32(41);
  g.fillStyle = '#221c19';
  g.fillRect(0, 0, w, h);
  const bw = 46, bh = 20;
  for (let row = 0; row * bh < h; row++) {
    for (let col = -1; col * bw < w; col++) {
      const x = col * bw + (row % 2 ? bw / 2 : 0), v = r();
      g.fillStyle = `rgb(${52 + v * 26 | 0},${34 + v * 16 | 0},${27 + v * 10 | 0})`;
      g.fillRect(x + 1, row * bh + 1, bw - 2, bh - 2);
    }
  }
  let gr = g.createLinearGradient(0, h, 0, h - 160);
  gr.addColorStop(0, 'rgba(0,0,0,0.7)');
  gr.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = gr;
  g.fillRect(0, h - 160, w, 160);
  gr = g.createLinearGradient(0, 0, 0, 140);
  gr.addColorStop(0, 'rgba(0,0,0,0.75)');
  gr.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = gr;
  g.fillRect(0, 0, w, 140);
  // lit windows up the wall
  for (const [ux, uy, s] of [[0.3, 0.34, 1], [0.6, 0.28, 0.85], [0.74, 0.42, 0.7]]) {
    const x = w * ux, y = h * uy, ww = 46 * s, wh = 60 * s;
    const halo = g.createRadialGradient(x + ww / 2, y + wh / 2, 5, x + ww / 2, y + wh / 2, 120 * s);
    halo.addColorStop(0, 'rgba(255,190,110,0.4)');
    halo.addColorStop(1, 'rgba(255,190,110,0)');
    g.fillStyle = halo;
    g.fillRect(x - 120, y - 120, ww + 240, wh + 240);
    g.fillStyle = '#ffca82';
    g.fillRect(x, y, ww, wh);
    g.fillStyle = 'rgba(60,30,10,0.8)';
    g.fillRect(x + ww / 2 - 2, y, 4, wh);
    g.fillRect(x, y + wh / 2 - 2, ww, 4);
  }
  // gig posters at street level
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  for (const [ux, txt, tilt] of [[0.42, 'LIVE', -0.05], [0.55, 'GIG', 0.07], [0.68, 'SHOW', -0.08]]) {
    g.save();
    g.translate(w * ux, h * 0.72);
    g.rotate(tilt);
    g.fillStyle = '#cfc4ae';
    g.fillRect(-34, -46, 68, 92);
    g.fillStyle = '#2a2118';
    g.font = '800 24px Georgia, serif';
    g.fillText(txt, 0, -14);
    g.font = '700 13px Georgia, serif';
    g.fillText('TONIGHT', 0, 16);
    g.restore();
  }
}

function paintCobbles(g, w, h) {
  const r = mulberry32(29);
  g.fillStyle = '#0b0d11';
  g.fillRect(0, 0, w, h);
  const s = 38;
  for (let row = 0; row * s < h + s; row++) {
    for (let col = -1; col * s < w + s; col++) {
      const x = col * s + (row % 2 ? s / 2 : 0) + (r() - 0.5) * 5;
      const y = row * s + (r() - 0.5) * 5;
      const v = r();
      g.fillStyle = `rgb(${22 + v * 14 | 0},${24 + v * 14 | 0},${30 + v * 16 | 0})`;
      g.beginPath();
      g.roundRect(x + 2, y + 2, s - 4, s - 4, 10);
      g.fill();
      g.fillStyle = `rgba(180,200,235,${0.02 + v * 0.035})`; // moon sheen
      g.beginPath();
      g.roundRect(x + 5, y + 4, s - 10, 7, 4);
      g.fill();
    }
  }
  const vg = g.createRadialGradient(512, 512, 120, 512, 512, 512);
  vg.addColorStop(0, 'rgba(0,0,0,0)');
  vg.addColorStop(1, 'rgba(0,0,0,0.65)');
  g.fillStyle = vg;
  g.fillRect(0, 0, w, h);
}

export default {
  key: 'street', label: 'Night street',
  dome: ['#0a0d15', '#1b2434', '#3c4d69', '#96abd0'],
  hemi: [0x9db4e8, 0x11141f, 0.55],
  keyL: [0xcdd9ff, 1.3], rimL: [0xffc37a, 0.75],
  beamInt: 0.07, beamColor: [0.62, 0.74, 1.0], dustColor: [0.62, 0.74, 1.0], poolColor: '170,195,255',
  bg: streetSky, glassEnv: 1,
  spillR: (spec) => Math.max(2.7, spec.R * 2 + 0.6) / 2 - 0.12, // crate top (inscribed)
  archY: -2.52, // cobbles below the crate

  build(gr, spec) {
    const cw = Math.max(2.7, spec.R * 2 + 0.6), ch = 2.5; // wooden crate
    const crate = new THREE.Mesh(
      new THREE.BoxGeometry(cw, ch, cw),
      new THREE.MeshStandardMaterial({
        map: canvasTexture(256, 256, (g, w, h) => {
          paintPlanks(g, w, h, { base: '#5a4023', planks: 5, light: 34, seed: 17 });
          g.strokeStyle = 'rgba(30,18,8,0.8)';
          g.lineWidth = 10;
          g.strokeRect(8, 8, w - 16, h - 16);
          g.fillStyle = 'rgba(20,12,5,0.55)';
          g.font = '700 44px Georgia, serif';
          g.textAlign = 'center';
          g.textBaseline = 'middle';
          g.fillText('TIPS', w / 2, h / 2);
        }),
        roughness: 0.85, envMapIntensity: 0.25,
      })
    );
    crate.position.y = -0.02 - ch / 2;
    gr.add(crate);
    const floorY = -0.02 - ch;
    gr.add(floorDisc(ROOM_R + 0.6, floorY - 0.01, paintCobbles, { rough: 0.72, env: 0.3 }));
    gr.add(roomWall(ROOM_R, floorY, ROOM_TOP, paintBrickWall, Math.PI * 1.34)); // open side → night sky
    // street lamp — close enough to share the frame with the crate
    const lampMat = new THREE.MeshStandardMaterial({ color: 0x14161c, roughness: 0.6, metalness: 0.5 });
    const px = -4.0, pz = -3.1, poleH = 9.6;
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.13, poleH, 10), lampMat);
    pole.position.set(px, floorY + poleH / 2, pz);
    gr.add(pole);
    const dir = new THREE.Vector3(-px, 0, -pz).normalize();
    const headPos = new THREE.Vector3(px, floorY + poleH, pz).addScaledVector(dir, 1.7);
    gr.add(tube(new THREE.Vector3(px, floorY + poleH, pz), headPos.clone(), 0.055, lampMat));
    const shade = new THREE.Mesh(
      new THREE.CylinderGeometry(0.16, 0.5, 0.35, 12, 1, true),
      new THREE.MeshStandardMaterial({ color: 0x14161c, roughness: 0.5, metalness: 0.5, side: THREE.DoubleSide })
    );
    shade.position.copy(headPos);
    gr.add(shade);
    const lampBulb = bulb(0.2, 0xffd9a2, 3);
    lampBulb.position.copy(headPos).y -= 0.14;
    gr.add(lampBulb);
    const pool = glowDisc(2.8, '255,205,130', 0.34);
    pool.position.set(headPos.x, floorY + 0.02, headPos.z);
    gr.add(pool);
  },
};
