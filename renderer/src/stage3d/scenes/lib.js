/**
 * Scenery toolkit — shared building blocks for the dressed sets.
 *
 * Conventions every scene relies on:
 *  - The vessel sits at the origin with its base at y = 0; a scene's support
 *    (stool / crate / riser / table) puts its top surface at y ≈ -0.02.
 *  - The room shell is a big low-detail cylinder (DoubleSide — a zoomed-out
 *    camera that pokes through still sees the set, not a hole).
 *  - At the default camera only wall-y ≈ 0–2 wu of the far wall shows behind
 *    the vessel, so readable dressing lives LOW on wall canvases and in
 *    mid-ground 3D props (candle tables, pendants, festoons at y 3–6).
 *  - Supports size themselves from the vessel spec so nothing overhangs.
 */
import * as THREE from '../../vendor/three.module.min.js';
import { mulberry32 } from '../../shared/ui.js';
import { canvasTexture } from '../tex.js';

export { canvasTexture };

export const ROOM_R = 26, ROOM_TOP = 17;
const UP = new THREE.Vector3(0, 1, 0);

// Fake-volumetric spotlight cone: additive gradient, brightest along its
// axis. Shared by the app's main beam and the concert side spots.
export const BEAM_VS = `
  varying vec2 vUv; varying vec3 vN; varying vec3 vV;
  void main() {
    vUv = uv;
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vN = normalize(mat3(modelMatrix) * normal);
    vV = normalize(cameraPosition - wp.xyz);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }`;
export const BEAM_FS = `
  varying vec2 vUv; varying vec3 vN; varying vec3 vV;
  uniform float uInt; uniform vec3 uColor;
  void main() {
    float axis = pow(abs(dot(normalize(vN), normalize(vV))), 1.3);
    float grad = pow(vUv.y, 1.7);
    gl_FragColor = vec4(uColor, uInt * grad * axis);
  }`;

// Painted wood planks — the workhorse texture for floors, seats and crates.
export function paintPlanks(g, w, h, o = {}) {
  const r = mulberry32(o.seed || 3);
  const n = o.planks || 9;
  g.fillStyle = o.base || '#3f2a18';
  g.fillRect(0, 0, w, h);
  for (let i = 0; i < n; i++) {
    const v = (r() - 0.5) * (o.light || 24);
    g.fillStyle = v > 0 ? `rgba(255,214,160,${v / 255})` : `rgba(0,0,0,${-v / 255})`;
    const x = o.horizontal ? 0 : (w / n) * i, y = o.horizontal ? (h / n) * i : 0;
    g.fillRect(x, y, o.horizontal ? w : w / n + 1, o.horizontal ? h / n + 1 : h);
    g.strokeStyle = 'rgba(16,8,3,0.3)';
    g.lineWidth = 1;
    for (let k = 0; k < 3; k++) {
      const off = r();
      g.beginPath();
      for (let s = 0; s <= 6; s++) {
        const t = s / 6;
        const gx = o.horizontal ? w * t : x + (w / n) * off + Math.sin(t * 6 + off * 9) * 2;
        const gy = o.horizontal ? y + (h / n) * off + Math.sin(t * 6 + off * 9) * 2 : h * t;
        if (s) g.lineTo(gx, gy); else g.moveTo(gx, gy);
      }
      g.stroke();
    }
  }
  g.fillStyle = 'rgba(0,0,0,0.5)';
  for (let i = 1; i < n; i++) {
    if (o.horizontal) g.fillRect(0, (h / n) * i - 1, w, 2);
    else g.fillRect((w / n) * i - 1, 0, 2, h);
  }
}

export function roomWall(radius, y0, y1, paint, arc) {
  const tex = canvasTexture(2048, 512, paint);
  tex.wrapS = THREE.RepeatWrapping;
  tex.repeat.x = -1; // seen from inside → un-mirror so painted text reads
  const geo = new THREE.CylinderGeometry(radius, radius, y1 - y0, 48, 1, true,
    arc ? Math.PI - arc / 2 : 0, arc || Math.PI * 2);
  const m = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    map: tex, roughness: 0.95, metalness: 0, envMapIntensity: 0.2, side: THREE.DoubleSide,
  }));
  m.position.y = (y0 + y1) / 2;
  return m;
}

export function floorDisc(radius, y, paint, o = {}) {
  const m = new THREE.Mesh(
    new THREE.CircleGeometry(radius, 48),
    new THREE.MeshStandardMaterial({
      map: canvasTexture(1024, 1024, paint),
      roughness: o.rough !== undefined ? o.rough : 0.9,
      metalness: 0, envMapIntensity: o.env !== undefined ? o.env : 0.25,
    })
  );
  m.rotation.x = -Math.PI / 2;
  m.position.y = y;
  return m;
}

export function ceilingDisc(radius, y, color) {
  const m = new THREE.Mesh(new THREE.CircleGeometry(radius, 32), new THREE.MeshBasicMaterial({ color }));
  m.rotation.x = Math.PI / 2;
  m.position.y = y;
  return m;
}

// >1 color values → survives the bright-pass → the bulb blooms
export function bulb(r, hex, intensity) {
  return new THREE.Mesh(
    new THREE.SphereGeometry(r, 10, 8),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(hex).multiplyScalar(intensity) })
  );
}

export function glowDisc(radius, rgbStr, alpha) {
  const m = new THREE.Mesh(
    new THREE.PlaneGeometry(radius * 2, radius * 2),
    new THREE.MeshBasicMaterial({
      map: canvasTexture(128, 128, (g) => {
        const grad = g.createRadialGradient(64, 64, 4, 64, 64, 62);
        grad.addColorStop(0, `rgba(${rgbStr},${alpha})`);
        grad.addColorStop(1, `rgba(${rgbStr},0)`);
        g.fillStyle = grad;
        g.fillRect(0, 0, 128, 128);
      }),
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    })
  );
  m.rotation.x = -Math.PI / 2;
  return m;
}

export function tube(a, b, r, mat) {
  const d = new THREE.Vector3().subVectors(b, a);
  const m = new THREE.Mesh(new THREE.CylinderGeometry(r, r, d.length(), 8), mat);
  m.position.copy(a).add(b).multiplyScalar(0.5);
  m.quaternion.setFromUnitVectors(UP, d.normalize());
  return m;
}

// Bar stool (~45 cm) — the vessel sits on the seat, legs run down to the floor.
export function addStool(gr, spec) {
  const seatR = Math.max(1.35, spec.R + 0.3);
  const H = 3.55;
  const seat = new THREE.Mesh(
    new THREE.CylinderGeometry(seatR, seatR * 0.94, 0.16, 36),
    new THREE.MeshStandardMaterial({
      map: canvasTexture(256, 256, (g, w, h) => paintPlanks(g, w, h, { base: '#38200e', planks: 6, seed: 11 })),
      roughness: 0.7, envMapIntensity: 0.3,
    })
  );
  seat.position.y = -0.1;
  gr.add(seat);
  const legMat = new THREE.MeshStandardMaterial({ color: 0x2e1c10, roughness: 0.8 });
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * Math.PI * 2 + Math.PI / 4;
    gr.add(tube(
      new THREE.Vector3(Math.cos(a) * seatR * 0.55, -0.14, Math.sin(a) * seatR * 0.55),
      new THREE.Vector3(Math.cos(a) * seatR * 0.92, -0.1 - H, Math.sin(a) * seatR * 0.92),
      0.07, legMat
    ));
  }
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(seatR * 0.8, 0.028, 8, 32),
    new THREE.MeshStandardMaterial({ color: 0xa07a35, metalness: 0.8, roughness: 0.4 })
  );
  ring.rotation.x = Math.PI / 2;
  ring.position.y = -0.1 - H * 0.62;
  gr.add(ring);
  return -0.1 - H; // floor level
}

export function addPendant(gr, x, y, z, o = {}) {
  const lamp = new THREE.Group();
  const shade = new THREE.Mesh(
    new THREE.CylinderGeometry(0.09, 0.55, 0.5, 20, 1, true),
    new THREE.MeshStandardMaterial({ color: o.shade || 0x1f3a2c, roughness: 0.5, metalness: 0.3, side: THREE.DoubleSide })
  );
  const b = bulb(0.14, 0xffc37a, o.glow !== undefined ? o.glow : 2.6);
  b.position.y = -0.16;
  const cordLen = (o.toCeil !== undefined ? o.toCeil : ROOM_TOP) - y - 0.25;
  const cord = new THREE.Mesh(
    new THREE.CylinderGeometry(0.018, 0.018, cordLen, 6),
    new THREE.MeshStandardMaterial({ color: 0x0d0a08, roughness: 0.9 })
  );
  cord.position.y = cordLen / 2 + 0.25;
  lamp.add(shade, b, cord);
  lamp.position.set(x, y, z);
  gr.add(lamp);
}

// A sagging string of warm bulbs (one InstancedMesh per strand).
export function addFairyLights(gr, a, b, sag, n, glow) {
  const mesh = new THREE.InstancedMesh(
    new THREE.SphereGeometry(0.085, 8, 6),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(0xffd08a).multiplyScalar(glow || 2.4) }),
    n
  );
  const M = new THREE.Matrix4(), p = new THREE.Vector3();
  for (let i = 0; i < n; i++) {
    const t = (i + 0.5) / n;
    p.lerpVectors(a, b, t);
    p.y -= Math.sin(t * Math.PI) * sag;
    M.setPosition(p);
    mesh.setMatrixAt(i, M);
  }
  gr.add(mesh);
}

// Distant table silhouette with a candle — the default camera sees only the
// lowest couple of meters of the far wall, so mid-ground furniture is what
// sells "there is a room back there".
export function addTableProp(gr, x, z, floorY, r) {
  const wood = new THREE.MeshStandardMaterial({ color: 0x1c1006, roughness: 0.9 });
  const tH = 2.6, tR = r || 1.5;
  const top = new THREE.Mesh(new THREE.CylinderGeometry(tR, tR * 0.96, 0.12, 20), wood);
  top.position.set(x, floorY + tH, z);
  const leg = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.16, tH, 8), wood);
  leg.position.set(x, floorY + tH / 2, z);
  gr.add(top, leg);
  const candle = bulb(0.09, 0xffb45e, 2.2);
  candle.position.set(x, floorY + tH + 0.2, z);
  gr.add(candle);
  const halo = glowDisc(1.0, '255,180,94', 0.5);
  halo.position.set(x, floorY + tH + 0.08, z);
  gr.add(halo);
}

// Colored side spot: same fake-volumetric shader as the main beam, aimed at
// the vessel from a truss position, plus a glowing lamp head.
export function addSideSpot(gr, from, color, intensity, spec) {
  const target = new THREE.Vector3(0, spec.topY * 0.5, 0);
  const dir = target.clone().sub(from);
  const len = dir.length();
  const cone = new THREE.Mesh(
    new THREE.CylinderGeometry(0.24, 1.6, len, 24, 1, true),
    new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide,
      uniforms: {
        uInt: { value: intensity },
        uColor: { value: new THREE.Vector3(color[0], color[1], color[2]) },
      },
      vertexShader: BEAM_VS, fragmentShader: BEAM_FS,
    })
  );
  cone.quaternion.setFromUnitVectors(new THREE.Vector3(0, -1, 0), dir.clone().normalize());
  cone.position.copy(from).add(target).multiplyScalar(0.5);
  cone.frustumCulled = false;
  gr.add(cone);
  const head = bulb(0.22, new THREE.Color(color[0], color[1], color[2]).getHex(), 2.4);
  head.position.copy(from);
  gr.add(head);
}
