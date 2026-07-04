/** Irish pub — the jar on a bar stool; back-bar bottles, pendants, candle tables. */
import { mulberry32 } from '../../shared/ui.js';
import {
  ROOM_R, ROOM_TOP, paintPlanks, roomWall, floorDisc, ceilingDisc,
  addStool, addPendant, addTableProp,
} from './lib.js';

// NOTE for all wall painters: canvas bottom = floor. At the default camera
// the band that actually shows behind the vessel is wall-y ≈ 0–8 wu, i.e.
// canvas y ≈ 0.55h…h — so all the readable dressing goes LOW on the canvas.
function paintPubWall(g, w, h) {
  const r = mulberry32(31);
  const grad = g.createLinearGradient(0, 0, 0, h);
  grad.addColorStop(0, '#040a07');
  grad.addColorStop(0.55, '#0d2018');
  grad.addColorStop(1, '#1a3d30');
  g.fillStyle = grad;
  g.fillRect(0, 0, w, h);
  const wainY = h * 0.71; // wainscot top ≈ 2.3 wu above the pub floor
  // warm sconce pools along the wall
  for (let i = 0; i < 7; i++) {
    const x = w * (0.02 + i * 0.145 + r() * 0.03);
    const gl = g.createRadialGradient(x, wainY - 68, 6, x, wainY - 68, 120);
    gl.addColorStop(0, 'rgba(255,190,105,0.55)');
    gl.addColorStop(1, 'rgba(255,190,105,0)');
    g.fillStyle = gl;
    g.fillRect(x - 120, wainY - 188, 240, 240);
    g.fillStyle = '#ffdba0';
    g.fillRect(x - 3, wainY - 74, 6, 12);
  }
  // gold-framed pictures between the sconces
  for (let i = 0; i < 6; i++) {
    const x = w * (0.09 + i * 0.15) + r() * 40;
    const fw = 54 + r() * 46, fh = 60 + r() * 36, y = wainY - 118 - r() * 46;
    g.fillStyle = '#8a6a2c';
    g.fillRect(x - 4, y - 4, fw + 8, fh + 8);
    g.fillStyle = `rgb(${30 + r() * 30 | 0},${26 + r() * 20 | 0},${20 + r() * 16 | 0})`;
    g.fillRect(x, y, fw, fh);
  }
  // back bar behind the stool: warm glow, hutch, backlit bottle silhouettes
  const bx = w * 0.5, bw = w * 0.17, hutchTop = wainY - 175;
  const bg = g.createRadialGradient(bx, wainY - 70, 20, bx, wainY - 70, bw);
  bg.addColorStop(0, 'rgba(255,176,84,0.6)');
  bg.addColorStop(1, 'rgba(255,176,84,0)');
  g.fillStyle = bg;
  g.fillRect(bx - bw, wainY - 70 - bw, bw * 2, bw * 2);
  g.fillStyle = '#241408';
  g.fillRect(bx - bw * 0.72, hutchTop, bw * 1.44, wainY - hutchTop);
  for (const sy of [wainY - 18, wainY - 95]) {
    g.fillStyle = '#3a2410';
    g.fillRect(bx - bw * 0.66, sy, bw * 1.32, 8);
    let x = bx - bw * 0.6;
    while (x < bx + bw * 0.58) {
      const bh = 34 + r() * 24, bwd = 9 + r() * 6;
      g.fillStyle = ['#1a3a20', '#4a2408', '#28160a', '#183048'][(r() * 4) | 0];
      g.fillRect(x, sy - bh, bwd, bh);
      g.fillRect(x + bwd * 0.32, sy - bh - 8, bwd * 0.36, 9);
      g.fillStyle = 'rgba(255,210,130,0.85)';
      g.fillRect(x + 1.5, sy - bh + 4, 2.5, bh * 0.55);
      x += bwd + 5 + r() * 7;
    }
  }
  // pub mirror sign
  const mx = w * 0.77, my = wainY - 168;
  g.strokeStyle = '#a8842f';
  g.lineWidth = 6;
  g.strokeRect(mx, my, 130, 96);
  g.fillStyle = '#101c14';
  g.fillRect(mx + 3, my + 3, 124, 90);
  g.fillStyle = '#c9a44a';
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.font = '700 26px Georgia, serif';
  g.fillText('LIVE', mx + 65, my + 34);
  g.fillText('TIPS', mx + 65, my + 66);
  // wood wainscot — narrow boards (wide ones read as giant planks up close)
  g.fillStyle = '#2c1b0d';
  g.fillRect(0, wainY, w, h - wainY);
  for (let x = 0; x < w; x += 13) {
    g.fillStyle = `rgba(255,205,150,${0.02 + r() * 0.05})`;
    g.fillRect(x, wainY, 11, h - wainY);
    g.fillStyle = 'rgba(0,0,0,0.45)';
    g.fillRect(x + 11, wainY, 2, h - wainY);
  }
  g.fillStyle = '#54351a';
  g.fillRect(0, wainY, w, 6);
  g.fillStyle = 'rgba(0,0,0,0.5)';
  g.fillRect(0, wainY + 6, w, 4);
  const fs = g.createLinearGradient(0, h - 40, 0, h);
  fs.addColorStop(0, 'rgba(0,0,0,0)');
  fs.addColorStop(1, 'rgba(0,0,0,0.5)');
  g.fillStyle = fs;
  g.fillRect(0, h - 40, w, 40); // floor contact shadow
}

export default {
  key: 'pub', label: 'Irish pub',
  dome: ['#170e07', '#3c2513', '#77491e', '#dfa04b'],
  hemi: [0xffc98a, 0x2a1408, 0.62],
  keyL: [0xffdcae, 1.35], rimL: [0xff9a4d, 0.6],
  beamInt: 0.11, beamColor: [1.0, 0.73, 0.38], dustColor: [1.0, 0.73, 0.38], poolColor: '255,196,120',
  bg: ['#241206', '#120a04', '#070402'], glassEnv: 0.7,
  spillR: (spec) => Math.max(1.35, spec.R + 0.3) - 0.08, // stool seat edge
  archY: -3.65, // pub floor (stool height) — retired jars stand around it

  build(gr, spec) {
    const floorY = addStool(gr, spec);
    gr.add(floorDisc(ROOM_R + 0.6, floorY - 0.01,
      (g, w, h) => paintPlanks(g, w, h, { base: '#221507', planks: 22, horizontal: true, light: 20, seed: 21 })));
    gr.add(roomWall(ROOM_R, floorY, ROOM_TOP, paintPubWall));
    gr.add(ceilingDisc(ROOM_R, ROOM_TOP, 0x0b0604));
    // the "spot" over the jar — its bulb sits right at the beam's apex
    addPendant(gr, 0, spec.topY + 1.95, 0, { glow: 3 });
    // ambient pendants, mostly behind the jar so the default view catches them
    addPendant(gr, -3.4, 3.1, -4.6, { glow: 2.2 });
    addPendant(gr, 3.8, 2.9, -5.2, { glow: 2.2 });
    addPendant(gr, -4.6, 3.3, 3.6, { glow: 2.2 });
    // mid-ground pub tables with candles
    addTableProp(gr, -7.5, -10.5, floorY, 1.7);
    addTableProp(gr, 6.8, -12, floorY, 1.7);
    addTableProp(gr, 12, -4.5, floorY, 1.6);
    addTableProp(gr, -12.5, 3.5, floorY, 1.6);
  },
};
