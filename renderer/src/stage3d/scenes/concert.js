/**
 * Concert stage — flight-case riser, red velvet curtain, festoon bulbs and
 * two colored side spots. The main beam stays theme-colored: the "stage
 * lighting" matches the artist's page theme.
 */
import * as THREE from '../../vendor/three.module.min.js';
import {
  ROOM_R, ROOM_TOP, canvasTexture, paintPlanks, roomWall, floorDisc, addSideSpot,
} from './lib.js';

function paintCurtain(g, w, h) {
  g.fillStyle = '#5a1020';
  g.fillRect(0, 0, w, h);
  // vertical velvet folds
  for (let x = 0; x < w; x++) {
    const l = 0.5 + 0.5 * Math.sin(x * 0.085 + Math.sin(x * 0.011) * 2.2);
    g.fillStyle = `rgb(${34 + l * 148 | 0},${4 + l * 26 | 0},${12 + l * 34 | 0})`;
    g.fillRect(x, 0, 1, h);
  }
  // broad stage-light hotspots, low — that's the band visible behind the jar
  for (const [ux, uy, a] of [[0.2, 0.66, 0.2], [0.5, 0.6, 0.26], [0.82, 0.68, 0.2]]) {
    const gl = g.createRadialGradient(w * ux, h * uy, 20, w * ux, h * uy, 300);
    gl.addColorStop(0, `rgba(255,178,150,${a})`);
    gl.addColorStop(1, 'rgba(255,178,150,0)');
    g.fillStyle = gl;
    g.fillRect(w * ux - 300, h * uy - 300, 600, 600);
  }
  // valance + gold trim
  g.fillStyle = 'rgba(0,0,0,0.4)';
  g.fillRect(0, 0, w, h * 0.11);
  g.fillStyle = '#c9a44a';
  g.fillRect(0, h * 0.11, w, 4);
  const sh = g.createLinearGradient(0, h * 0.82, 0, h);
  sh.addColorStop(0, 'rgba(0,0,0,0)');
  sh.addColorStop(1, 'rgba(0,0,0,0.6)');
  g.fillStyle = sh;
  g.fillRect(0, h * 0.82, w, h * 0.18);
}

function paintFlightCase(g, w, h) {
  // matte black case, slim dark-aluminum trim — bright wide trim read as a
  // white plastic frame under the stage lights
  g.fillStyle = '#111013';
  g.fillRect(0, 0, w, h);
  g.fillStyle = '#1b191e';
  g.fillRect(10, 10, w - 20, h - 20);
  g.strokeStyle = '#43464d';
  g.lineWidth = 4;
  g.strokeRect(5, 5, w - 10, h - 10);
  g.strokeStyle = 'rgba(0,0,0,0.7)';
  g.lineWidth = 2;
  g.strokeRect(11, 11, w - 22, h - 22);
  g.fillStyle = '#565a62';
  g.fillRect(w / 2 - 20, h / 2 - 26, 40, 52); // latch plate
  g.fillStyle = '#2d3036';
  g.fillRect(w / 2 - 10, h / 2 - 15, 20, 30);
}

export default {
  key: 'concert', label: 'Concert stage',
  dome: ['#140a0e', '#371420', '#6d2331', '#e6b160'],
  hemi: [0xd890a8, 0x200a14, 0.55],
  keyL: [0xffe2c4, 1.45], rimL: [0xff5a8c, 0.9],
  beamInt: 0.17, beamColor: 'theme', dustColor: 'theme', poolColor: 'theme',
  bg: ['#1c060d', '#0d0308', '#040104'], glassEnv: 1,
  spillR: (spec) => Math.max(2.6, spec.R * 2 + 0.7) / 2 - 0.12, // riser top (inscribed)
  archY: -1.92, // stage boards below the riser

  build(gr, spec) {
    const rw = Math.max(2.6, spec.R * 2 + 0.7), rh = 1.9; // riser flight case
    const riser = new THREE.Mesh(
      new THREE.BoxGeometry(rw, rh, rw),
      new THREE.MeshStandardMaterial({
        map: canvasTexture(256, 256, paintFlightCase),
        roughness: 0.55, metalness: 0.25, envMapIntensity: 0.5,
      })
    );
    riser.position.y = -0.02 - rh / 2;
    gr.add(riser);
    const floorY = -0.02 - rh;
    gr.add(floorDisc(ROOM_R + 0.6, floorY - 0.01,
      (g, w, h) => paintPlanks(g, w, h, { base: '#0e0a08', planks: 20, horizontal: true, light: 9, seed: 43 }),
      { rough: 0.5, env: 0.22 })); // dark stage boards with a hint of sheen
    gr.add(roomWall(ROOM_R, floorY, ROOM_TOP, paintCurtain));
    // festoon of warm bulbs circling low above the stage (in the default frame)
    const N = 26;
    const festoon = new THREE.InstancedMesh(
      new THREE.SphereGeometry(0.2, 8, 6),
      new THREE.MeshBasicMaterial({ color: new THREE.Color(0xffbe6e).multiplyScalar(2.6) }),
      N
    );
    const M = new THREE.Matrix4();
    for (let i = 0; i < N; i++) {
      const a = (i / N) * Math.PI * 2;
      M.setPosition(Math.cos(a) * 8.5, 5.0 + Math.sin(a * 3) * 0.4, Math.sin(a) * 8.5);
      festoon.setMatrixAt(i, M);
    }
    gr.add(festoon);
    addSideSpot(gr, new THREE.Vector3(-5.5, 7.4, -2.8), [1.0, 0.55, 0.2], 0.17, spec);
    addSideSpot(gr, new THREE.Vector3(5.5, 7.4, -2.4), [0.85, 0.25, 0.55], 0.17, spec);
  },
};
