/**
 * live.tips stage — 3D renderer (three.js), embedded-library edition.
 *
 * Ported from the tip-jar-5 prototype. Gamedev approach — no physics engine:
 *  - The full pile (100%) is precomputed once as a deterministic, layered packing.
 *  - Pouring animates only the delta: items fall with parametric gravity + tumble,
 *    get funneled through the neck so they never clip the glass, land on their
 *    precomputed spot and do a small fake bounce. Cost is O(airborne) per frame.
 *  - All coins are ONE InstancedMesh per denomination → ~7 draw calls for money.
 *  - Glass jar = lathe geometry rendered twice (back faces, then front faces).
 *
 * Library rules (differences from the prototype):
 *  - No DOM chrome, no URL params, no localStorage — the HOST owns all state and
 *    drives everything through the bridge (see ../main.js and PROTOCOL.md).
 *  - The host speaks jar fractions (0..2 of the goal); this file converts them to
 *    item counts internally. Money truth lives in the host — we are spectacle.
 *  - Rollovers are COMMANDED: a tip message says how many jars retire. We never
 *    decide that ourselves; we only choreograph the moment.
 */
import * as THREE from '../vendor/three.module.min.js';
import { mulberry32 } from '../shared/ui.js';
import { THEMES, applyCssTheme, beamGl, hexGl } from '../shared/themes.js';
import { createSound } from '../shared/sound.js';
import { SCENES } from './scenes/index.js';
import { BEAM_VS, BEAM_FS } from './scenes/lib.js';
import { CONTAINERS, DEFAULT_CONTAINER, containerSpec, vesselProfile } from './vessels.js';
import { createMoneyAssets } from './money.js';
import { createBloom } from './bloom.js';
import { canvasTexture } from './tex.js';

const CFG = {
  coinR: 0.105,
  billW: 0.50, billH: 0.26,
  billRatio: 0.10,
  gravity: 14,
  dprMax: 1.75,
};

export function createStage(ctx) {
  const { host, emit } = ctx;
  const config = ctx.config || {};
  const REDUCED = !!ctx.reduced;
  const rng = mulberry32(20260703);

  // ---------------------------------------------------------------- state

  let theme = THEMES.find(t => t.key === config.theme) || THEMES[0];
  applyCssTheme(theme);
  let confPalette = theme.confetti.map(hexGl);
  const sound = createSound();
  sound.setCoins(!!config.sound);
  sound.setFanfare(!!config.tipSound);

  let container = CONTAINERS.find(c => c.key === config.vessel)
    || CONTAINERS.find(c => c.key === DEFAULT_CONTAINER);
  let spec = containerSpec(container);
  let SCENE = SCENES.find(s => s.key === config.scene) || SCENES[0];
  let billsOn = !!config.notes;
  let insets = { top: 0, bottom: 0, ...(config.insets || {}) };

  // trophies already earned (host-authoritative count restores the shelf)
  let bankedJars = Math.max(0, Math.floor((ctx.state && ctx.state.bankedJars) || 0));

  // host-commanded rollover choreography (see applyTip)
  let pendingRollovers = 0;
  let afterPct = -1; // 0..200 target once the queue drains; -1 = none

  function setTheme(t) {
    theme = t;
    applyCssTheme(t);
    applySceneTints();
    confPalette = t.confetti.map(hexGl);
  }

  // beam / dust / light-pool / background follow the theme on scenes that ask
  // for it ('theme'); dressed sets keep their own fixed atmosphere colors
  function sceneRGB(v) { return v === 'theme' ? beamGl(theme) : v; }

  function applySceneTints() {
    const bc = sceneRGB(SCENE.beamColor);
    if (beamMat) beamMat.uniforms.uColor.value.set(bc[0], bc[1], bc[2]);
    if (dustMat) {
      const dc = sceneRGB(SCENE.dustColor);
      dustMat.uniforms.uColor.value.set(dc[0], dc[1], dc[2]);
    }
    if (poolTex) paintPool();
    paintBackdrop();
  }

  // ---------------------------------------------------------------- renderer

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(devicePixelRatio || 1, CFG.dprMax));
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.06;
  host.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(36, 1, 0.1, 50);
  const camTarget = new THREE.Vector3(0, 1.55, 0);

  // Cheap studio environment for metal/glass reflections: a few emissive planes
  // baked through PMREM. No HDR download, ~1 ms. Re-baked on scene switch with
  // the scene's dome palette so coin reflections match the set (amber in the
  // pub, moonlit blue on the street…).
  function buildEnvironment(stops) {
    const es = new THREE.Scene();
    // full-coverage gradient dome: metals reflect their environment, and with
    // only a few bright planes in blackness coins went dark from many camera
    // angles — the dome guarantees there is always *something* to reflect
    const domeCanvas = document.createElement('canvas');
    domeCanvas.width = 4;
    domeCanvas.height = 256;
    const dg = domeCanvas.getContext('2d');
    const dgrad = dg.createLinearGradient(0, 256, 0, 0);
    dgrad.addColorStop(0, stops[0]);    // floor
    dgrad.addColorStop(0.45, stops[1]); // walls
    dgrad.addColorStop(0.8, stops[2]);
    dgrad.addColorStop(1, stops[3]);    // zenith
    dg.fillStyle = dgrad;
    dg.fillRect(0, 0, 4, 256);
    const domeTex = new THREE.CanvasTexture(domeCanvas);
    domeTex.colorSpace = THREE.SRGBColorSpace;
    es.add(new THREE.Mesh(
      new THREE.SphereGeometry(20, 16, 12),
      new THREE.MeshBasicMaterial({ map: domeTex, side: THREE.BackSide })
    ));
    const put = (hex, intensity, w, h, x, y, z) => {
      const m = new THREE.Mesh(
        new THREE.PlaneGeometry(w, h),
        new THREE.MeshBasicMaterial({ color: new THREE.Color(hex).multiplyScalar(intensity), side: THREE.DoubleSide })
      );
      m.position.set(x, y, z);
      m.lookAt(0, 0, 0);
      es.add(m);
    };
    put(0xfff2dd, 12, 7, 4, 0, 8, 0);      // warm key overhead
    put(0xfff8ee, 7, 4, 1.4, 2.5, 4, 6);   // front strip → tall glass highlight
    put(0xcfe0ff, 4, 3, 7, -8, 2, 2);      // cool left fill
    put(0xffd0e8, 3.5, 3, 7, 8, 1, -2);    // rose right (brand)
    put(0x333344, 1.5, 14, 14, 0, -6, 0);  // dim floor bounce
    const pmrem = new THREE.PMREMGenerator(renderer);
    const tex = pmrem.fromScene(es, 0).texture; // sharp env → crisp glints on coins/glass
    pmrem.dispose();
    return tex;
  }
  scene.environment = buildEnvironment(SCENE.dome);

  // Backdrop drawn inside the scene (not CSS) so post-processing composites a
  // fully-opaque frame — premultiplied-alpha clamping would band otherwise.
  // Scenes bring their own painter (street = night sky) or gradient stops.
  let bgCanvas = null, bgTex = null;
  function paintBackdrop() {
    if (!bgCanvas) {
      bgCanvas = document.createElement('canvas');
      bgCanvas.width = bgCanvas.height = 512;
      bgTex = new THREE.CanvasTexture(bgCanvas);
      bgTex.colorSpace = THREE.SRGBColorSpace;
    }
    const g = bgCanvas.getContext('2d');
    if (typeof SCENE.bg === 'function') {
      SCENE.bg(g);
    } else {
      const stops = SCENE.bg === 'theme' ? [theme.bg1, '#14101f', theme.bg0] : SCENE.bg;
      const grad = g.createRadialGradient(256, 118, 30, 256, 180, 520);
      grad.addColorStop(0, stops[0]);
      grad.addColorStop(0.52, stops[1]);
      grad.addColorStop(1, stops[2]);
      g.fillStyle = grad;
      g.fillRect(0, 0, 512, 512);
    }
    bgTex.needsUpdate = true;
    scene.background = bgTex;
  }
  paintBackdrop();

  const hemi = new THREE.HemisphereLight(SCENE.hemi[0], SCENE.hemi[1], SCENE.hemi[2]);
  scene.add(hemi);
  // key + rim FOLLOW the camera azimuth (see updateCamera) — the lit side of
  // the money always faces the viewer, like a product-shot light rig
  const key = new THREE.DirectionalLight(SCENE.keyL[0], SCENE.keyL[1]);
  key.position.set(3, 6, 2.5);
  scene.add(key);
  const rim = new THREE.DirectionalLight(SCENE.rimL[0], SCENE.rimL[1]);
  rim.position.set(-3, 3.5, -4);
  scene.add(rim);

  // scene switch re-bakes the reflection env + relights the rig
  function applySceneAtmosphere() {
    if (scene.environment) scene.environment.dispose();
    scene.environment = buildEnvironment(SCENE.dome);
    hemi.color.setHex(SCENE.hemi[0]);
    hemi.groundColor.setHex(SCENE.hemi[1]);
    hemi.intensity = SCENE.hemi[2];
    key.color.setHex(SCENE.keyL[0]);
    key.intensity = SCENE.keyL[1];
    rim.color.setHex(SCENE.rimL[0]);
    rim.intensity = SCENE.rimL[1];
    applySceneTints();
  }

  // ---------------------------------------------------------------- vessel

  let vesselMeshes = [];
  function buildVessel() {
    for (const m of vesselMeshes) {
      scene.remove(m);
      m.geometry.dispose();
      m.material.dispose();
    }
    // warm scene domes reflect across the whole glass and read as frosting —
    // scenes tune the glass reflectivity down via glassEnv
    const ge = SCENE.glassEnv;
    const geo = new THREE.LatheGeometry(vesselProfile(spec), 48);
    const back = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
      color: 0xbfd9e8, roughness: 0.06, metalness: 0,
      transparent: true, opacity: 0.055, side: THREE.BackSide,
      depthWrite: false, envMapIntensity: 0.5 * ge,
    }));
    back.renderOrder = 1;
    const front = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
      color: 0xdceef8, roughness: 0.05, metalness: 0,
      transparent: true, opacity: 0.09, side: THREE.FrontSide,
      depthWrite: false, envMapIntensity: 1.55 * ge,
    }));
    front.renderOrder = 2;
    vesselMeshes = [back, front];
    scene.add(back, front);
    if (spec.handle) {
      const hs = buildMugHandle(ge);
      vesselMeshes.push(...hs);
      scene.add(...hs);
    }
  }

  // D-shaped glass handle for the beer mug — a C-arc torus whose open ends bury
  // themselves in the wall. Rendered back-then-front like the vessel body, with
  // the same transparent-glass materials, so it reads as one piece of glass.
  function buildMugHandle(ge) {
    const rH = spec.topY * 0.3;
    const arc = 2.8; // ~160° — the ends turn INTO the wall, not along it
    const geo = new THREE.TorusGeometry(rH, 0.042, 12, 32, arc);
    const make = (side, color, op, env) => {
      const m = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
        color, roughness: 0.05, metalness: 0,
        transparent: true, opacity: op, side,
        depthWrite: false, envMapIntensity: env * ge,
      }));
      m.position.set(spec.R - rH * Math.cos(arc / 2) - 0.02, spec.topY * 0.5, 0);
      m.rotation.z = -arc / 2; // center the C on +X — the default camera's profile
      return m;
    };
    const back = make(THREE.BackSide, 0xbfd9e8, 0.07, 0.5);
    back.renderOrder = 1;
    const front = make(THREE.FrontSide, 0xdceef8, 0.16, 1.55);
    front.renderOrder = 2;
    return [back, front];
  }

  // ------------------------------------------------------- retired-jar trophies
  // At a rollover the full vessel "retires" to a shelf spot in the background
  // and a fresh one takes its place. A trophy is CHEAP — glass lathe + one solid
  // "money mass" lathe wearing a painted coin-heap texture, not live instances.

  function paintCoinHeap(g, w, h) {
    const r = mulberry32(9);
    g.fillStyle = '#4a350f';
    g.fillRect(0, 0, w, h);
    const tints = ['#b98c33', '#a87e2e', '#93702a', '#9c6432', '#a9adb3', '#c29b3f'];
    for (let i = 0; i < 150; i++) {
      const x = r() * w, y = r() * h, cr = 10 + r() * 10;
      g.fillStyle = tints[(r() * tints.length) | 0];
      g.beginPath(); g.arc(x, y, cr, 0, 7); g.fill();
      g.strokeStyle = 'rgba(40,24,4,0.7)';
      g.lineWidth = 2.5;
      g.stroke();
      g.fillStyle = 'rgba(255,236,190,0.16)';
      g.beginPath(); g.arc(x - cr * 0.3, y - cr * 0.3, cr * 0.4, 0, 7); g.fill();
    }
  }

  function makeArchiveJar() {
    const gr = new THREE.Group();
    const ge = SCENE.glassEnv;
    const geo = new THREE.LatheGeometry(vesselProfile(spec), 32);
    const back = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
      color: 0xbfd9e8, roughness: 0.06, metalness: 0,
      transparent: true, opacity: 0.055, side: THREE.BackSide,
      depthWrite: false, envMapIntensity: 0.5 * ge,
    }));
    back.renderOrder = 1;
    const front = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
      color: 0xdceef8, roughness: 0.05, metalness: 0,
      transparent: true, opacity: 0.09, side: THREE.FrontSide,
      depthWrite: false, envMapIntensity: 1.55 * ge,
    }));
    front.renderOrder = 2;
    // solid fill following the inner profile, domed like a heaped pour
    const pts = [new THREE.Vector2(0.001, 0.03)];
    for (let i = 0; i <= 12; i++) {
      const y = 0.03 + (spec.fillTop - 0.03) * (i / 12);
      pts.push(new THREE.Vector2(Math.max(0.01, spec.rIn(y) - 0.012), y));
    }
    const domeR = Math.max(0.02, spec.rIn(spec.fillTop) - 0.012);
    pts.push(new THREE.Vector2(domeR * 0.66, spec.fillTop + domeR * 0.08));
    pts.push(new THREE.Vector2(0.001, spec.fillTop + domeR * 0.12));
    const heapTex = canvasTexture(256, 256, paintCoinHeap);
    heapTex.wrapS = heapTex.wrapT = THREE.RepeatWrapping;
    heapTex.repeat.set(3, Math.max(1, Math.round(spec.fillTop * 1.2)));
    const fill = new THREE.Mesh(
      new THREE.LatheGeometry(pts, 24),
      new THREE.MeshStandardMaterial({
        map: heapTex, color: 0xcfa552, roughness: 0.5, metalness: 0.42, envMapIntensity: 0.45,
      })
    );
    // soft contact shadow so the trophy sits on the floor instead of floating
    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(spec.R * 2.9, spec.R * 2.9),
      new THREE.MeshBasicMaterial({
        map: canvasTexture(64, 64, (g) => {
          const grad = g.createRadialGradient(32, 32, 4, 32, 32, 31);
          grad.addColorStop(0, 'rgba(0,0,10,0.5)');
          grad.addColorStop(1, 'rgba(0,0,10,0)');
          g.fillStyle = grad;
          g.fillRect(0, 0, 64, 64);
        }),
        transparent: true, depthWrite: false,
      })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.015;
    gr.add(shadow, fill, back, front);
    if (spec.handle) gr.add(...buildMugHandle(ge)); // retired mugs keep the handle
    gr.scale.setScalar(0.85); // a touch smaller — perspective humility
    return gr;
  }

  // shelf spots fan out BEHIND the vessel (default camera looks from +Z) —
  // far enough back that the trophies read as set dressing, not foreground
  const ARCH_MAX = 5;
  function archSpot(k) {
    const a = [4.05, 5.37, 3.52, 5.9, 4.71][k % ARCH_MAX];
    const r = Math.max(7.0, spec.R * 2 + 5.2) + (k % 3) * 0.6;
    const y = SCENE.archY !== undefined ? SCENE.archY : -0.02;
    return new THREE.Vector3(Math.cos(a) * r, y, Math.sin(a) * r);
  }

  let archGroup = null, archAnim = null;
  function buildArchives(excludeSlot) {
    if (archGroup) disposeGroup(archGroup);
    archAnim = null;
    archGroup = new THREE.Group();
    const n = Math.min(ARCH_MAX, bankedJars);
    for (let k = 0; k < n; k++) {
      if (k === excludeSlot) continue;
      const jar = makeArchiveJar();
      jar.position.copy(archSpot(k));
      jar.rotation.y = (k * 1.7) % (Math.PI * 2);
      archGroup.add(jar);
      if (SCENE.archPedestal) archGroup.add(archPedestal(jar.position));
    }
    scene.add(archGroup);
  }

  // the abstract set floats in a void — retired jars get their own little discs
  function archPedestal(p) {
    const disc = new THREE.Mesh(
      new THREE.CylinderGeometry(spec.R * 0.9 + 0.22, spec.R + 0.28, 0.09, 28),
      new THREE.MeshStandardMaterial({ color: 0x141026, roughness: 0.95, metalness: 0, envMapIntensity: 0.18 })
    );
    disc.position.set(p.x, p.y - 0.065, p.z);
    return disc;
  }

  // ---------------------------------------------------------------- scenery

  let poolCanvas = null, poolTex = null, poolMesh = null;
  function paintPool() {
    const col = SCENE.poolColor === 'theme' ? theme.beam : SCENE.poolColor;
    const g = poolCanvas.getContext('2d');
    g.clearRect(0, 0, 256, 256);
    if (SCENE.beamInt > 0) {
      const grad = g.createRadialGradient(128, 128, 10, 128, 128, 126);
      grad.addColorStop(0, `rgba(${col},0.30)`);
      grad.addColorStop(0.55, `rgba(${col},0.10)`);
      grad.addColorStop(1, `rgba(${col},0)`);
      g.fillStyle = grad;
      g.fillRect(0, 0, 256, 256);
    }
    const sh = g.createRadialGradient(128, 128, 8, 128, 128, 52);
    sh.addColorStop(0, 'rgba(0,0,12,0.55)');
    sh.addColorStop(1, 'rgba(0,0,12,0)');
    g.fillStyle = sh;
    g.fillRect(0, 0, 256, 256);
    poolTex.needsUpdate = true;
  }

  // Dispose a prop group fully — geometries, materials, canvas maps, instances.
  function disposeGroup(gr) {
    scene.remove(gr);
    gr.traverse((o) => {
      if (o.isInstancedMesh) o.dispose();
      if (o.geometry) o.geometry.dispose();
      if (o.material) {
        for (const m of (Array.isArray(o.material) ? o.material : [o.material])) {
          if (m.map) m.map.dispose();
          m.dispose();
        }
      }
    });
  }

  // Swap the whole set: dispose the previous group, build the new one sized to
  // the vessel; the retired-jar trophies re-dress themselves for the new set.
  let sceneryGroup = null;
  function buildScenery() {
    if (sceneryGroup) disposeGroup(sceneryGroup);
    sceneryGroup = new THREE.Group();
    SCENE.build(sceneryGroup, spec);
    scene.add(sceneryGroup);
    buildArchives();

    if (!poolMesh) {
      // one texture: spotlight pool on the support + contact shadow under the vessel
      poolCanvas = document.createElement('canvas');
      poolCanvas.width = poolCanvas.height = 256;
      poolTex = new THREE.CanvasTexture(poolCanvas);
      paintPool();
      poolMesh = new THREE.Mesh(
        new THREE.PlaneGeometry(3.4, 3.4),
        new THREE.MeshBasicMaterial({ map: poolTex, transparent: true, depthWrite: false })
      );
      poolMesh.rotation.x = -Math.PI / 2;
      poolMesh.position.y = 0.012;
      scene.add(poolMesh);
    }
    poolMesh.scale.setScalar(Math.max(0.55, (spec.R + 1.0) / 1.85));
    if (beamMesh) beamMesh.visible = SCENE.beamInt > 0;
    if (dustPts) dustPts.visible = SCENE.beamInt > 0; // the dust lives in the beam
  }

  // ---------------------------------------------------------------- beam + dust

  let beamMat = null, beamMesh = null;
  function sizeBeam() {
    const h = spec.topY + 2.1;
    const geo = new THREE.CylinderGeometry(
      Math.max(0.3, spec.mouthR + 0.25),
      THREE.MathUtils.clamp(spec.R * 2.4, 1.5, 3.2),
      h, 40, 1, true
    );
    if (beamMesh) {
      beamMesh.geometry.dispose();
      beamMesh.geometry = geo;
    } else {
      beamMesh = new THREE.Mesh(geo, beamMat);
      beamMesh.frustumCulled = false;
      scene.add(beamMesh);
    }
    beamMesh.position.y = h / 2 + 0.05;
    beamMesh.visible = SCENE.beamInt > 0;
  }

  function buildBeam() {
    const c = sceneRGB(SCENE.beamColor);
    beamMat = new THREE.ShaderMaterial({
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
      uniforms: {
        uInt: { value: SCENE.beamInt },
        uColor: { value: new THREE.Vector3(c[0], c[1], c[2]) },
      },
      vertexShader: BEAM_VS,
      fragmentShader: BEAM_FS,
    });
  }
  buildBeam();

  // Dust motes drifting down through the beam — fully shader-animated, zero CPU.
  let dustMat = null, dustPts = null;
  function buildDust() {
    const N = 110;
    const pos = new Float32Array(N * 3);
    const seed = new Float32Array(N);
    const size = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const r = Math.sqrt(rng()) * 2.0, th = rng() * Math.PI * 2;
      pos[i * 3] = Math.cos(th) * r;
      pos[i * 3 + 1] = rng() * 4.6;
      pos[i * 3 + 2] = Math.sin(th) * r;
      seed[i] = rng();
      size[i] = 0.02 + rng() * 0.035;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));
    geo.setAttribute('aSize', new THREE.BufferAttribute(size, 1));
    const dc = sceneRGB(SCENE.dustColor);
    dustMat = new THREE.ShaderMaterial({
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      uniforms: {
        uTime: { value: 0 },
        uScale: { value: 600 },
        uColor: { value: new THREE.Vector3(dc[0], dc[1], dc[2]) },
      },
      vertexShader: `
        attribute float aSeed; attribute float aSize;
        uniform float uTime; uniform float uScale;
        varying float vA;
        void main() {
          vec3 p = position;
          p.y = mod(p.y - uTime * (0.05 + aSeed * 0.1), 4.6);
          p.x += sin(uTime * 0.25 + aSeed * 40.0) * 0.1;
          float hFade = smoothstep(0.0, 0.5, p.y) * (1.0 - smoothstep(3.6, 4.6, p.y));
          float rFade = 1.0 - smoothstep(1.1, 2.1, length(p.xz));
          vA = (0.22 + aSeed * 0.3) * hFade * rFade;
          vec4 mv = modelViewMatrix * vec4(p, 1.0);
          gl_PointSize = aSize * uScale / max(0.1, -mv.z);
          gl_Position = projectionMatrix * mv;
        }`,
      fragmentShader: `
        varying float vA; uniform vec3 uColor;
        void main() {
          float r = length(gl_PointCoord * 2.0 - 1.0);
          gl_FragColor = vec4(uColor, vA * pow(max(0.0, 1.0 - r), 2.0));
        }`,
    });
    dustPts = new THREE.Points(geo, dustMat);
    dustPts.frustumCulled = false;
    scene.add(dustPts);
  }
  if (!REDUCED) buildDust();

  // ---------------------------------------------------------------- pile precompute

  const { BUCKETS, billGeo } = createMoneyAssets(CFG);

  function buildPile() {
    const items = [];
    const eul = new THREE.Euler();
    const qYaw = new THREE.Quaternion(), qTilt = new THREE.Quaternion(), qFlat = new THREE.Quaternion();
    qFlat.setFromEuler(new THREE.Euler(-Math.PI / 2, 0, 0));

    // per-vessel deterministic stream → a vessel's pile is identical every
    // session, independent of build order
    const rng = mulberry32(9000 + [...spec.key].reduce((a, ch) => a + ch.charCodeAt(0), 0) + (billsOn ? 7 : 0));

    // notes only when enabled, and never in vessels narrower than a folded bill
    const billRatio = (billsOn && spec.rIn(spec.fillBottom + 0.05) > 0.32) ? CFG.billRatio : 0;

    const cr = CFG.coinR;
    let y = spec.fillBottom;
    while (y <= spec.fillTop) {
      const rl = spec.rIn(y);
      const mr = Math.max(0.02, rl - 0.02 - cr);
      const rlcr = rl / cr;
      // narrow vessels leave no room to tilt — coins lie nearly flat, like real
      // coins in a tiny jar; wide vessels get a gently tumbled look
      const tiltMax = spec.stage ? 0.35 : THREE.MathUtils.clamp((rlcr - 2.2) * 0.2, 0.03, 0.24);
      const slots = [];
      if (spec.stage) {
        // the stylized jar keeps its original Vogel-spiral pile
        const n = Math.max(3, Math.floor((mr * mr) / (cr * cr) * spec.density));
        const rot0 = rng() * Math.PI * 2;
        for (let i = 0; i < n; i++) {
          slots.push({
            rad: mr * Math.sqrt((i + 0.5) / n) * (0.94 + rng() * 0.1),
            th: i * 2.399963 + rot0 + (rng() - 0.5) * 0.6,
          });
        }
      } else {
        // exact concentric-ring packing for ALL real vessels: coins in a layer
        // can never overlap sideways (inner rings first — mound stays central)
        const rings = [];
        for (let r = mr; r > cr * 0.55; r -= cr * 2.02) rings.push(r);
        if (!rings.length || rings[rings.length - 1] >= cr * 2.0) rings.push(0);
        rings.reverse();
        for (const rr of rings) {
          const cnt = rr < cr * 1.02
            ? 1
            : Math.max(1, Math.floor(Math.PI / Math.asin(Math.min(1, cr / rr))));
          const phase = rng() * Math.PI * 2;
          for (let j = 0; j < cnt; j++) {
            slots.push({
              rad: Math.min(mr, rr * (1 + (rng() - 0.5) * 0.05)),
              th: phase + ((j + (rng() - 0.5) * 0.14) / cnt) * Math.PI * 2,
            });
          }
        }
      }
      for (const slot of slots) {
        let rad = slot.rad;
        const th = slot.th;
        const quat = new THREE.Quaternion();
        const isBill = rng() < billRatio;
        // bills are wide — keep them off the glass wall
        if (isBill) rad = Math.min(rad, Math.max(0.03, spec.rIn(y) - 0.04 - 0.27));
        const yJit = spec.stage ? 0.03 : spec.coinH;
        const pos = new THREE.Vector3(Math.cos(th) * rad, y + (rng() - 0.5) * yJit, Math.sin(th) * rad);
        if (isBill) {
          qYaw.setFromEuler(eul.set(0, rng() * Math.PI * 2, 0));
          qTilt.setFromEuler(eul.set((rng() - 0.5) * 0.5, 0, (rng() - 0.5) * 0.5));
          quat.multiplyQuaternions(qYaw, qTilt).multiply(qFlat);
        } else {
          quat.setFromEuler(eul.set((rng() - 0.5) * 2 * tiltMax, rng() * Math.PI * 2, (rng() - 0.5) * 2 * tiltMax));
        }
        let bucket;
        if (isBill) {
          const r = rng();
          bucket = r < 0.35 ? 3 : r < 0.65 ? 4 : r < 0.85 ? 5 : 6; // €5/€10/€20/€50
        } else {
          const r = rng();
          bucket = r < 0.2 ? 1 : r < 0.75 ? 0 : 2; // copper / gold / bimetallic
        }
        const B = BUCKETS[bucket];
        items.push({
          kind: B.kind, bucket, pos, quat,
          tint: Math.floor(rng() * B.tints.length),
          s: isBill ? 0.93 + rng() * 0.14 : B.scale[0] + rng() * (B.scale[1] - B.scale[0]),
          slot: 0,
        });
      }
      // flatter coins stack tighter (real small-jar behaviour)
      const stepF = spec.stage ? 1 : (1.16 + tiltMax) / 1.42;
      y += spec.layerStep * stepF * (0.94 + rng() * 0.12);
    }

    // The last few bills stand up in the neck, poking out of the mouth —
    // the iconic full-tip-jar look. Only for jars with a real neck.
    const poked = [];
    if (spec.kind === 'jar' && spec.mouthR > 0.17) {
      const pokeY = Math.min(spec.topY - 0.1, spec.fillTop + 0.16);
      for (let i = items.length - 1; i >= Math.floor(items.length * 0.86) && poked.length < 6; i--) {
        const it = items[i];
        if (it.kind !== 'bill') continue;
        poked.push(i);
        const a = rng() * Math.PI * 2, rr = rng() * Math.min(0.14, spec.mouthR * 0.35);
        it.pos.set(Math.cos(a) * rr, pokeY + rng() * 0.16, Math.sin(a) * rr);
        qYaw.setFromEuler(eul.set(0, rng() * Math.PI * 2, 0));
        qTilt.setFromEuler(eul.set((rng() - 0.5) * 0.35, 0, Math.PI / 2 + (rng() - 0.5) * 0.3));
        it.quat.copy(qYaw).multiply(qTilt);
      }
    }

    // ---- clean pile top: trim the raw sim to the vessel's round target so the
    // 100% moment looks intentional (the host never sees these euros — fill is
    // commanded in goal fractions — but the trim keeps piles tidy and stable).
    if (spec.target && !billRatio) {
      let total = 0;
      for (const it of items) total += BUCKETS[it.bucket].value;
      while (items.length > 1 && total - BUCKETS[items[items.length - 1].bucket].value >= spec.target) {
        total -= BUCKETS[items.pop().bucket].value;
      }
      for (let i = items.length - 1; i >= 0 && total - spec.target >= 0.5; i--) {
        const it = items[i];
        if (it.kind !== 'coin') continue;
        const v = BUCKETS[it.bucket].value;
        if (v === 2 && total - spec.target >= 1.5) { it.bucket = 0; total -= 1.5; }
        else if (v === 0.5) { it.bucket = 1; total -= 0.45; }
      }
    }

    // ---- overflow (100–200%): when tips exceed the goal, coins land AROUND
    // the vessel on the scene's support — a growing ring mound. Same
    // deterministic ring packing, on an annulus from the vessel foot out to
    // the scene's spill radius. Coins only; capped at ~the inside value or a
    // sane mound height, whichever comes first.
    const nIn = items.length;
    let vIn = 0;
    for (const it of items) vIn += BUCKETS[it.bucket].value;
    const footR = spec.kind === 'bucket' ? spec.rBot : spec.R; // sphere: start beyond the bulge
    const r0 = footR + cr + 0.06;
    const r1 = Math.max(SCENE.spillR ? SCENE.spillR(spec) : spec.R + 0.34, r0 + 0.23);
    const oy0 = -0.02 + spec.coinH * 0.5 + 0.004; // resting on the support top
    const oyMax = oy0 + Math.max(0.28, Math.min(0.9, spec.topY * 0.3));
    let oy = oy0, vOut = 0;
    while (vOut < vIn && oy < oyMax) {
      const rTop = Math.max(r0 + 0.09, r1 - (oy - oy0) * 0.7); // talus slope — the mound tapers
      const tilt = 0.05 + Math.min(0.1, (rTop - r0) * 0.1);
      for (let rr = r0; rr <= rTop + 0.001; rr += cr * 2.02) {
        const cnt = Math.max(1, Math.floor(Math.PI / Math.asin(Math.min(1, cr / Math.max(rr, cr * 1.02)))));
        const phase = rng() * Math.PI * 2;
        for (let j = 0; j < cnt; j++) {
          const th = phase + ((j + (rng() - 0.5) * 0.14) / cnt) * Math.PI * 2;
          const rad = rr + (rng() - 0.5) * 0.02;
          const quat = new THREE.Quaternion().setFromEuler(
            eul.set((rng() - 0.5) * 2 * tilt, rng() * Math.PI * 2, (rng() - 0.5) * 2 * tilt));
          const r = rng();
          const bucket = r < 0.2 ? 1 : r < 0.75 ? 0 : 2; // copper / gold / bimetallic
          const B = BUCKETS[bucket];
          items.push({
            kind: 'coin', bucket, out: true,
            pos: new THREE.Vector3(Math.cos(th) * rad, oy + (rng() - 0.5) * spec.coinH * 0.6, Math.sin(th) * rad),
            quat, tint: Math.floor(rng() * B.tints.length),
            s: B.scale[0] + rng() * (B.scale[1] - B.scale[0]),
            slot: 0,
          });
          vOut += B.value;
        }
      }
      oy += spec.layerStep * 0.86 * (0.94 + rng() * 0.12);
    }

    // per-bucket slots + prefix counts (sequence prefix → InstancedMesh.count)
    const bucketCounts = BUCKETS.map(() => 0);
    const prefs = BUCKETS.map(() => [0]);
    for (const it of items) {
      it.slot = bucketCounts[it.bucket]++;
      for (let b = 0; b < BUCKETS.length; b++) prefs[b].push(bucketCounts[b]);
    }
    return { items, bucketCounts, prefs, poked, nIn };
  }

  let pile = { items: [], bucketCounts: [], prefs: [], poked: [], nIn: 0 };
  let items = [];
  let meshes = [];
  let coinGeo = null;

  function buildMoney() {
    for (const m of meshes) {
      scene.remove(m);
      const mats = Array.isArray(m.material) ? m.material : [m.material];
      for (const mat of mats) mat.dispose();
      m.dispose(); // frees instance buffers
    }
    if (coinGeo) coinGeo.dispose();
    coinGeo = new THREE.CylinderGeometry(CFG.coinR, CFG.coinR, spec.coinH, 16);

    pile = buildPile();
    items = pile.items;

    meshes = BUCKETS.map((B, b) => {
      const cap = Math.max(1, pile.bucketCounts[b]);
      let mesh;
      if (B.kind === 'coin') {
        // cylinder groups: [side, top, bottom] — caps get the face, side stays clean metal
        // metalness < 1 leaves a diffuse floor so coins never go fully black
        const capMat = new THREE.MeshStandardMaterial({ map: B.map, metalness: 0.82, roughness: 0.34, envMapIntensity: 1.25 });
        const sideMat = new THREE.MeshStandardMaterial({ color: B.side, metalness: 0.85, roughness: 0.36, envMapIntensity: 1.2 });
        mesh = new THREE.InstancedMesh(coinGeo, [sideMat, capMat, capMat], cap);
      } else {
        mesh = new THREE.InstancedMesh(billGeo, new THREE.MeshStandardMaterial({
          map: B.map, metalness: 0, roughness: 0.8, side: THREE.DoubleSide, envMapIntensity: 0.4,
        }), cap);
      }
      mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      mesh.frustumCulled = false; // matrices stream in; geometry-based culling would be wrong
      scene.add(mesh);
      return mesh;
    });

    const col = new THREE.Color();
    const M = new THREE.Matrix4();
    for (const it of items) {
      const mesh = meshes[it.bucket];
      col.setHex(BUCKETS[it.bucket].tints[it.tint]);
      mesh.setColorAt(it.slot, col);
      M.compose(it.pos, it.quat, new THREE.Vector3(it.s, it.s, it.s));
      mesh.setMatrixAt(it.slot, M);
    }
    for (const m of meshes) {
      if (m.instanceColor) m.instanceColor.needsUpdate = true;
      m.count = 0;
    }
  }

  // ---------------------------------------------------------------- sparkles

  const SPARKS = 96;
  const sparkGeo = new THREE.BufferGeometry();
  const sparkPos = new Float32Array(SPARKS * 3);
  const sparkLife = new Float32Array(SPARKS);
  const sparkSize = new Float32Array(SPARKS);
  sparkGeo.setAttribute('position', new THREE.BufferAttribute(sparkPos, 3));
  sparkGeo.setAttribute('aLife', new THREE.BufferAttribute(sparkLife, 1));
  sparkGeo.setAttribute('aSize', new THREE.BufferAttribute(sparkSize, 1));
  const sparkMat = new THREE.ShaderMaterial({
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    uniforms: { uScale: { value: 600 } },
    vertexShader: `
      attribute float aLife; attribute float aSize;
      uniform float uScale; varying float vLife;
      void main() {
        vLife = aLife;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        float s = aSize * (1.7 - aLife * 0.7) * step(0.001, aLife);
        gl_PointSize = s * uScale / max(0.1, -mv.z);
        gl_Position = projectionMatrix * mv;
      }`,
    fragmentShader: `
      varying float vLife;
      void main() {
        vec2 p = gl_PointCoord * 2.0 - 1.0;
        float r = length(p);
        float star = max(0.0, 1.0 - abs(p.x * p.y) * 6.0);
        float a = vLife * (pow(max(0.0, 1.0 - r), 1.6) + pow(star, 4.0) * 0.6);
        gl_FragColor = vec4(1.0, 0.88, 0.55, a);
      }`,
  });
  const sparks = new THREE.Points(sparkGeo, sparkMat);
  sparks.frustumCulled = false;
  scene.add(sparks);
  let sparkCursor = 0, sparksAlive = 0;

  function sparkleAt(p, s) {
    const i = sparkCursor;
    sparkCursor = (sparkCursor + 1) % SPARKS;
    sparkPos[i * 3] = p.x; sparkPos[i * 3 + 1] = p.y + 0.05; sparkPos[i * 3 + 2] = p.z;
    sparkLife[i] = 1;
    sparkSize[i] = s !== undefined ? s : 0.06 + rng() * 0.06;
    sparksAlive++;
    sparkGeo.attributes.position.needsUpdate = true;
  }

  function updateSparks(dt) {
    if (!sparksAlive) return;
    sparksAlive = 0;
    for (let i = 0; i < SPARKS; i++) {
      if (sparkLife[i] > 0) {
        sparkLife[i] = Math.max(0, sparkLife[i] - dt * 2.6);
        if (sparkLife[i] > 0) sparksAlive++;
      }
    }
    sparkGeo.attributes.aLife.needsUpdate = true;
  }

  // ---------------------------------------------------------------- star glints
  // The proper "✨": now and then a coin catches the light with a slow 4-ray
  // star flash — bigger and hotter than the landing dust above, colors >1 so
  // the bloom pass flares it. Each star gets a random ray orientation.

  const STARS = 10;
  const starGeo = new THREE.BufferGeometry();
  const starPos = new Float32Array(STARS * 3);
  const starLife = new Float32Array(STARS);
  const starSizeA = new Float32Array(STARS);
  const starRot = new Float32Array(STARS);
  starGeo.setAttribute('position', new THREE.BufferAttribute(starPos, 3));
  starGeo.setAttribute('aLife', new THREE.BufferAttribute(starLife, 1));
  starGeo.setAttribute('aSize', new THREE.BufferAttribute(starSizeA, 1));
  starGeo.setAttribute('aRot', new THREE.BufferAttribute(starRot, 1));
  const starMat = new THREE.ShaderMaterial({
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    uniforms: { uScale: { value: 600 } },
    vertexShader: `
      attribute float aLife; attribute float aSize; attribute float aRot;
      uniform float uScale; varying float vLife; varying float vRot;
      void main() {
        vLife = aLife; vRot = aRot;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        float k = 1.0 - aLife;
        float pop = sin(3.14159 * min(1.0, k * 1.15)); // quick bloom, soft fade
        gl_PointSize = aSize * (0.35 + pop) * uScale / max(0.1, -mv.z) * step(0.001, aLife);
        gl_Position = projectionMatrix * mv;
      }`,
    fragmentShader: `
      varying float vLife; varying float vRot;
      void main() {
        float c = cos(vRot), s = sin(vRot);
        vec2 p = gl_PointCoord * 2.0 - 1.0;
        p = mat2(c, -s, s, c) * p;
        float r = length(p);
        // 4 long rays on the rotated axes + 4 short diagonals + a hot core;
        // the ray term fades with radius so the cross tapers like a real glint
        float rays = max(0.0, 1.0 - abs(p.x * p.y) * 7.0) * max(0.0, 1.0 - r * 0.8);
        vec2 d = mat2(0.7071, -0.7071, 0.7071, 0.7071) * p;
        float diag = max(0.0, 1.0 - abs(d.x * d.y) * 26.0) * max(0.0, 1.0 - r * 1.15);
        float core = pow(max(0.0, 1.0 - r * 1.6), 2.2);
        float k = 1.0 - vLife;
        float glow = sin(3.14159 * min(1.0, k * 1.15));
        float a = glow * (pow(rays, 4.0) + pow(diag, 5.0) * 0.4 + core);
        vec3 col = vec3(1.35, 1.18, 0.85) * (0.7 + 0.6 * glow); // >1 → blooms
        gl_FragColor = vec4(col, a);
      }`,
  });
  const stars = new THREE.Points(starGeo, starMat);
  stars.frustumCulled = false;
  scene.add(stars);
  let starCursor = 0, starsAlive = 0;
  const STAR_V = new THREE.Vector3();

  function starAt(p, s) {
    const i = starCursor;
    starCursor = (starCursor + 1) % STARS;
    // nudge toward the camera so neighbouring coins don't clip the rays
    STAR_V.copy(camera.position).sub(p).normalize().multiplyScalar(0.09);
    starPos[i * 3] = p.x + STAR_V.x;
    starPos[i * 3 + 1] = p.y + 0.03 + STAR_V.y;
    starPos[i * 3 + 2] = p.z + STAR_V.z;
    starLife[i] = 1;
    starSizeA[i] = s !== undefined ? s : 0.26 + rng() * 0.2;
    starRot[i] = rng() * Math.PI;
    starsAlive++;
    starGeo.attributes.position.needsUpdate = true;
    starGeo.attributes.aRot.needsUpdate = true;
    starGeo.attributes.aSize.needsUpdate = true;
  }

  function updateStars(dt) {
    if (!starsAlive) return;
    starsAlive = 0;
    for (let i = 0; i < STARS; i++) {
      if (starLife[i] > 0) {
        starLife[i] = Math.max(0, starLife[i] - dt * 1.15);
        if (starLife[i] > 0) starsAlive++;
      }
    }
    starGeo.attributes.aLife.needsUpdate = true;
  }

  // ------------------------------------------------------------ confetti (goal!)

  const CONF = 160;
  const confGeo = new THREE.BufferGeometry();
  const confPos = new Float32Array(CONF * 3);
  const confLife = new Float32Array(CONF);
  const confSize = new Float32Array(CONF);
  const confCol = new Float32Array(CONF * 3);
  const confVel = new Float32Array(CONF * 3);
  confGeo.setAttribute('position', new THREE.BufferAttribute(confPos, 3));
  confGeo.setAttribute('aLife', new THREE.BufferAttribute(confLife, 1));
  confGeo.setAttribute('aSize', new THREE.BufferAttribute(confSize, 1));
  confGeo.setAttribute('aCol', new THREE.BufferAttribute(confCol, 3));
  // normal blending, not additive — flakes must read as paper against the
  // bright beam the burst flies through
  const confMat = new THREE.ShaderMaterial({
    transparent: true,
    depthWrite: false,
    blending: THREE.NormalBlending,
    uniforms: { uScale: { value: 600 } },
    vertexShader: `
      attribute float aLife; attribute float aSize; attribute vec3 aCol;
      uniform float uScale;
      varying float vLife; varying vec3 vCol;
      void main() {
        vLife = aLife; vCol = aCol;
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        gl_PointSize = aSize * uScale * step(0.001, aLife) / max(0.1, -mv.z);
        gl_Position = projectionMatrix * mv;
      }`,
    fragmentShader: `
      varying float vLife; varying vec3 vCol;
      void main() {
        float r = length(gl_PointCoord * 2.0 - 1.0);
        float a = smoothstep(1.0, 0.72, r) * min(1.0, vLife * 2.2);
        gl_FragColor = vec4(vCol, a);
      }`,
  });
  const confetti = new THREE.Points(confGeo, confMat);
  confetti.frustumCulled = false;
  scene.add(confetti);
  let confAlive = 0;

  let confCursor = 0;

  // rotating pool → goal bursts and milestone mini-bursts can overlap freely
  function spawnConfetti(n, sizeMul = 1) {
    for (let k = 0; k < n; k++) {
      const i = confCursor;
      confCursor = (confCursor + 1) % CONF;
      confPos[i * 3] = (rng() - 0.5) * 0.6;
      confPos[i * 3 + 1] = spec.topY + 0.15 + rng() * 0.2;
      confPos[i * 3 + 2] = (rng() - 0.5) * 0.6;
      confVel[i * 3] = (rng() - 0.5) * 3.6;
      confVel[i * 3 + 1] = 2.0 + rng() * 2.6;
      confVel[i * 3 + 2] = (rng() - 0.5) * 3.6;
      confLife[i] = 1;
      confSize[i] = (0.1 + rng() * 0.12) * sizeMul;
      const c = confPalette[k % confPalette.length];
      confCol[i * 3] = c[0]; confCol[i * 3 + 1] = c[1]; confCol[i * 3 + 2] = c[2];
    }
    confAlive = Math.min(CONF, confAlive + n);
    confGeo.attributes.aCol.needsUpdate = true;
  }

  function updateConfetti(dt) {
    if (!confAlive) return;
    confAlive = 0;
    // paper physics: pop up, heavy drag, then flutter down past the jar
    const drag = 1 - 1.1 * dt;
    for (let i = 0; i < CONF; i++) {
      if (confLife[i] <= 0) continue;
      confLife[i] = Math.max(0, confLife[i] - dt * 0.22);
      if (confLife[i] > 0) confAlive++;
      confVel[i * 3 + 1] -= 2.4 * dt;
      confVel[i * 3] *= drag; confVel[i * 3 + 1] *= drag; confVel[i * 3 + 2] *= drag;
      confPos[i * 3] += confVel[i * 3] * dt + Math.sin((1 - confLife[i]) * 9 + i) * dt * 0.35;
      confPos[i * 3 + 1] += confVel[i * 3 + 1] * dt;
      confPos[i * 3 + 2] += confVel[i * 3 + 2] * dt;
    }
    confGeo.attributes.position.needsUpdate = true;
    confGeo.attributes.aLife.needsUpdate = true;
  }

  // ---------------------------------------------------------------- pour / drain state

  let spawnedN = 0;           // items spawned (airborne + settled + draining)
  let targetN = 0;
  let spawnAcc = 0, spawnInterval = 0.03;
  const air = [];             // {i, t, dur, from, q0, axis, w, sparked}
  const drains = [];          // {i, t}  t<0 → stagger delay
  const drainedDone = new Set();

  const M4 = new THREE.Matrix4();
  const V3 = new THREE.Vector3();
  const SC = new THREE.Vector3();
  const Q1 = new THREE.Quaternion();

  function setTransform(it, x, y, z, q, s) {
    V3.set(x, y, z);
    SC.setScalar(Math.max(0.0001, s));
    M4.compose(V3, q, SC);
    meshes[it.bucket].setMatrixAt(it.slot, M4);
  }

  function restoreItem(i) {
    const it = items[i];
    setTransform(it, it.pos.x, it.pos.y, it.pos.z, it.quat, it.s);
  }

  function updateCounts() {
    for (let b = 0; b < meshes.length; b++) meshes[b].count = pile.prefs[b][spawnedN];
  }

  function randomQuat() {
    return new THREE.Quaternion().setFromEuler(
      new THREE.Euler(rng() * Math.PI * 2, rng() * Math.PI * 2, rng() * Math.PI * 2)
    );
  }

  let spawnSeq = 0;
  function spawnItem(i) {
    const it = items[i];
    let from;
    if (it.out) {
      // overflow coins rain down OUTSIDE the glass: spawn on a ring just past
      // the widest radius, roughly above the landing angle (a short chord never
      // crosses the vessel)
      const a = Math.atan2(it.pos.z, it.pos.x) + (rng() - 0.5) * 0.5;
      const sr = spec.R + 0.24 + rng() * 0.15;
      from = new THREE.Vector3(
        Math.cos(a) * sr,
        spec.topY + 0.25 + rng() * 0.35,
        Math.sin(a) * sr
      );
    } else {
      // golden-angle sequence over the mouth → consecutive coins never share a
      // column, so they don't visibly overlap each other mid-air
      const sr = Math.max(0.03, spec.mouthR * 0.42);
      const ga = spawnSeq * 2.39996;
      const gr = Math.sqrt(((spawnSeq % 9) + 0.5) / 9) * sr;
      spawnSeq++;
      from = new THREE.Vector3(
        Math.cos(ga) * gr,
        spec.topY + 0.2 + rng() * 0.32,
        Math.sin(ga) * gr
      );
    }
    const dur = Math.sqrt((2 * Math.max(0.15, from.y - it.pos.y)) / CFG.gravity);
    const axis = new THREE.Vector3(rng() - 0.5, rng() - 0.5, rng() - 0.5).normalize();
    air.push({ i, t: 0, dur, from, q0: randomQuat(), axis, w: 4 + rng() * 7, sparked: false });
    setTransform(it, from.x, from.y, from.z, Q1.copy(it.quat), it.s * 0.9);
  }

  // The 0–200% scale: 0–100 fills the vessel (nIn items), 100–200 fills the
  // overflow zone around it (the remaining items). Both mappings are linear.
  function countFromPct(pct) {
    pct = THREE.MathUtils.clamp(pct, 0, 200);
    const nIn = pile.nIn, nOut = items.length - nIn;
    if (pct <= 100 || !nOut) return Math.round(nIn * Math.min(pct, 100) / 100);
    return nIn + Math.round(nOut * (pct - 100) / 100);
  }

  function pctFromCount(c) {
    const nIn = pile.nIn, nOut = items.length - nIn;
    if (c <= nIn || !nOut) return nIn ? (c / nIn) * 100 : 0;
    return 100 + ((c - nIn) / nOut) * 100;
  }

  // Host-commanded rollover: bank the trophy, send the full jar to its shelf
  // spot in the background, and put a fresh empty vessel in its place. The
  // HOST already did the accounting — we only perform the theater and report
  // `rolloverDone` for haptics.
  function retireVessel() {
    bankedJars++;
    const slot = (bankedJars - 1) % ARCH_MAX;
    buildArchives(slot); // re-dress older trophies, keep the landing spot free
    const jar = makeArchiveJar();
    archGroup.add(jar);
    if (SCENE.archPedestal) archGroup.add(archPedestal(archSpot(slot)));
    archAnim = { jar, from: new THREE.Vector3(0, 0, 0), to: archSpot(slot), t: 0, dur: REDUCED ? 0.001 : 1.35 };
    // the vessel empties INSTANTLY — the money visibly left with the trophy
    targetN = 0; spawnedN = 0;
    air.length = 0; drains.length = 0; drainedDone.clear(); spawnAcc = 0;
    updateCounts();
    for (const m of meshes) m.instanceMatrix.needsUpdate = true;
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
  }

  function pourToCount(n) {
    targetN = Math.max(0, Math.min(items.length, n));

    // items mid-drain that must live again → snap back to settled
    for (let d = drains.length - 1; d >= 0; d--) {
      if (drains[d].i < targetN) { restoreItem(drains[d].i); drains.splice(d, 1); }
    }
    for (const i of Array.from(drainedDone)) {
      if (i < targetN) { drainedDone.delete(i); restoreItem(i); }
    }
    for (const m of meshes) m.instanceMatrix.needsUpdate = true;

    if (targetN > spawnedN) {
      const delta = targetN - spawnedN;
      // big vessels pour longer (a bucket holds thousands of coins)
      const durCap = THREE.MathUtils.clamp(2.2 + (spec.liters || 2) * 0.55, 4.4, 9);
      const dur = THREE.MathUtils.clamp(0.4 + delta * 0.028, 0.7, durCap);
      spawnInterval = Math.max(0.0015, dur / delta);
      spawnAcc = spawnInterval; // first one drops immediately
    } else if (targetN < spawnedN) {
      const airSet = new Set(air.map(a => a.i));
      const inDrain = new Set(drains.map(d => d.i));
      // whole drain finishes in ~1.4s no matter how many items leave
      const step = Math.min(0.022, 1.4 / Math.max(1, spawnedN - targetN));
      let st = 0;
      for (let i = spawnedN - 1; i >= targetN; i--) {
        if (airSet.has(i) || inDrain.has(i) || drainedDone.has(i)) continue;
        drains.push({ i, t: -st });
        st += step;
      }
    }
  }

  const easeSm = (k) => k <= 0 ? 0 : k >= 1 ? 1 : k * k * (3 - 2 * k);
  const BOUNCE_DUR = 0.26;

  function tickMoney(dt) {
    let touched = false;

    // spawner
    if (spawnedN < targetN) {
      spawnAcc += dt;
      while (spawnAcc >= spawnInterval && spawnedN < targetN) {
        spawnAcc -= spawnInterval;
        spawnItem(spawnedN++);
      }
      updateCounts();
      touched = true;
    } else {
      spawnAcc = 0;
    }

    // airborne
    for (let a = air.length - 1; a >= 0; a--) {
      const f = air[a];
      const it = items[f.i];
      f.t += dt;
      touched = true;
      if (f.t < f.dur) {
        const k = f.t / f.dur;
        const y = Math.max(it.pos.y, f.from.y - 0.5 * CFG.gravity * f.t * f.t);
        const ke = easeSm(Math.min(1, k / 0.85));
        let x = f.from.x + (it.pos.x - f.from.x) * ke;
        let z = f.from.z + (it.pos.z - f.from.z) * ke;
        // funnel: never let a falling item poke through the neck/shoulder glass
        // (overflow items fall OUTSIDE the glass — no funnel for them)
        if (!it.out) {
          const ext = it.kind === 'coin' ? 0.115 : 0.27;
          const rr = Math.hypot(x, z);
          const rMax = Math.max(0.02, spec.rIn(y) - 0.03 - ext);
          if (rr > rMax) { const c = rMax / rr; x *= c; z *= c; }
        }
        Q1.setFromAxisAngle(f.axis, f.w * f.t).premultiply(f.q0);
        Q1.slerp(it.quat, easeSm((k - 0.5) / 0.45));
        setTransform(it, x, y, z, Q1, it.s);
      } else {
        if (!f.sparked) { f.sparked = true; sparkleAt(it.pos); sound.clink(); }
        const bt = f.t - f.dur;
        if (bt < BOUNCE_DUR) {
          const y = it.pos.y + 0.04 * Math.exp(-bt * 10) * Math.abs(Math.sin(bt * 24));
          setTransform(it, it.pos.x, y, it.pos.z, it.quat, it.s);
        } else {
          restoreItem(f.i);
          air.splice(a, 1);
          if (f.i >= targetN) drains.push({ i: f.i, t: 0 }); // landed but no longer wanted
        }
      }
    }

    // draining (fly up + shrink)
    for (let d = drains.length - 1; d >= 0; d--) {
      const dr = drains[d];
      dr.t += dt;
      if (dr.t < 0) continue;
      touched = true;
      const it = items[dr.i];
      const k = Math.min(1, dr.t / 0.38);
      const y = it.pos.y + k * k * (spec.topY * 0.3 + 0.35);
      // same funnel on the way out (items shrink, so allowance shrinks too);
      // overflow items rise outside the glass — no funnel
      let dx = it.pos.x, dz = it.pos.z;
      if (!it.out) {
        const ext = (it.kind === 'coin' ? 0.115 : 0.27) * (1 - k);
        const rr = Math.hypot(dx, dz);
        const rMax = Math.max(0.02, spec.rIn(Math.min(spec.topY - 0.05, y)) - 0.02 - ext);
        if (rr > rMax) { const c = rMax / rr; dx *= c; dz *= c; }
      }
      setTransform(it, dx, y, dz, it.quat, it.s * (1 - k));
      if (k >= 1) {
        drains.splice(d, 1);
        drainedDone.add(dr.i);
      }
    }
    // pop fully-drained items off the top so counts shrink contiguously
    let popped = false;
    while (spawnedN > 0 && drainedDone.has(spawnedN - 1)) {
      drainedDone.delete(spawnedN - 1);
      spawnedN--;
      popped = true;
    }
    if (popped) { updateCounts(); touched = true; }

    if (touched) {
      for (const m of meshes) m.instanceMatrix.needsUpdate = true;
    }
    return touched;
  }

  // ---------------------------------------------------------------- camera controls

  let theta = 0.0, phi = 1.22;
  let zoomK = 1, autoRadius = 8.0; // base distance comes from resize() framing
  let lastInteract = -10, swayAmp = 1;
  const pointers = new Map();
  let pinchDist = 0;

  const el = renderer.domElement;
  el.addEventListener('pointerdown', (e) => {
    el.setPointerCapture(e.pointerId);
    pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.size === 2) {
      const [p1, p2] = [...pointers.values()];
      pinchDist = Math.hypot(p1.x - p2.x, p1.y - p2.y);
    }
    sound.unlock(); // any gesture revives an autoplay-suspended AudioContext
  });
  el.addEventListener('pointermove', (e) => {
    const p = pointers.get(e.pointerId);
    if (!p) return;
    lastInteract = clockTime;
    if (pointers.size === 1) {
      theta -= (e.clientX - p.x) * 0.005;
      phi = THREE.MathUtils.clamp(phi - (e.clientY - p.y) * 0.004, 0.92, 1.42);
    }
    p.x = e.clientX; p.y = e.clientY;
    if (pointers.size === 2) {
      const [p1, p2] = [...pointers.values()];
      const d = Math.hypot(p1.x - p2.x, p1.y - p2.y);
      if (pinchDist > 0) zoomK = THREE.MathUtils.clamp(zoomK * pinchDist / d, 0.5, 1.5);
      pinchDist = d;
    }
  });
  const endPointer = (e) => { pointers.delete(e.pointerId); pinchDist = 0; };
  el.addEventListener('pointerup', endPointer);
  el.addEventListener('pointercancel', endPointer);
  el.addEventListener('wheel', (e) => {
    e.preventDefault();
    lastInteract = clockTime;
    zoomK = THREE.MathUtils.clamp(zoomK * (1 + e.deltaY * 0.0012), 0.5, 1.5);
  }, { passive: false });

  function updateCamera(t) {
    const idle = (t - lastInteract) > 3 && pointers.size === 0;
    swayAmp += (((idle && !REDUCED) ? 1 : 0) - swayAmp) * 0.02;
    // dolly-in intro on load
    const ik = REDUCED ? 1 : easeSm(Math.min(1, t / 1.7));
    const th = theta - 0.7 * (1 - ik) + Math.sin(t * 0.3) * 0.055 * swayAmp;
    const ph = phi + Math.sin(t * 0.21) * 0.012 * swayAmp;
    const radius = autoRadius * zoomK * (1 + 0.45 * (1 - ik));
    camera.position.set(
      camTarget.x + radius * Math.sin(ph) * Math.sin(th),
      camTarget.y + radius * Math.cos(ph),
      camTarget.z + radius * Math.sin(ph) * Math.cos(th)
    );
    camera.lookAt(camTarget);
    // light rig tracks the camera: key ~30° to the right, rim from behind-left
    key.position.set(Math.sin(th + 0.55) * 4, 5.5, Math.cos(th + 0.55) * 4);
    rim.position.set(Math.sin(th + Math.PI - 0.5) * 4, 3.5, Math.cos(th + Math.PI - 0.5) * 4);
  }

  // ---------------------------------------------------------------- bloom + render

  // quality: 'high' forces bloom, 'low' disables, 'auto' sniffs the device;
  // the fps monitor may still drop it later — spectacle never beats smoothness
  function bloomFromQuality(q) {
    if (q === 'high') return true;
    if (q === 'low') return false;
    return (devicePixelRatio || 1) >= 1.5 && (navigator.hardwareConcurrency || 4) >= 4;
  }
  let quality = config.quality || 'auto';
  let bloomOn = bloomFromQuality(quality);

  const bloomFx = createBloom(renderer);

  function renderFrame() {
    if (!bloomOn) {
      renderer.setRenderTarget(null);
      renderer.render(scene, camera);
      return;
    }
    bloomFx.render(scene, camera);
  }

  // ---------------------------------------------------------------- resize + loop

  function resize() {
    const w = host.clientWidth, h = host.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h);
    camera.aspect = w / h;
    camera.fov = w < h * 0.75 ? 42 : 36;
    camera.updateProjectionMatrix();
    const pScale = (h * renderer.getPixelRatio() * 0.5) / Math.tan((camera.fov * Math.PI) / 360);
    sparkMat.uniforms.uScale.value = pScale;
    starMat.uniforms.uScale.value = pScale;
    confMat.uniforms.uScale.value = pScale;
    if (dustMat) dustMat.uniforms.uScale.value = pScale;

    // frame the jar into the free band the host left us between its native
    // HUD (insets.top) and bottom chrome (insets.bottom)
    const topPad = insets.top + 6;
    const botPad = insets.bottom + 24;
    const bandFrac = Math.max(0.3, (h - topPad - botPad) / h);
    const span = Math.min(14, spec.camSpan / bandFrac); // world units visible vertically
    autoRadius = span / (2 * Math.tan((camera.fov * Math.PI) / 360));
    const bandCenterFrac = (topPad + (h - topPad - botPad) / 2) / h;
    camTarget.y = spec.centerY + (bandCenterFrac - 0.5) * span;
    // horizontal safety: the vessel (+ sway margin) must fit the width too
    const needHalf = spec.R * 2.1 + 0.4;
    const halfW = Math.tan((camera.fov * Math.PI) / 360) * camera.aspect * autoRadius;
    if (halfW < needHalf) autoRadius *= needHalf / halfW;
    bloomFx.resize();
  }
  addEventListener('resize', resize);

  let clockTime = 0, lastT = performance.now();
  let emaDt = 1 / 60, degraded = false;
  let twinkleAcc = 0, twinkleNext = 0.5;
  let settle = null, settleAcc = 0, settleNext = 6; // overflow-mound micro-settle
  let celebrated = false, celebrated200 = false;
  let rolloverAt = -1;    // clockTime when the pending rollover's retire fires
  const MILESTONES = [25, 50, 75, 125, 150, 175];
  const milestonesFired = new Set();
  const E1 = new THREE.Euler();

  function hudCount() {
    let started = 0;
    for (const d of drains) if (d.t >= 0) started++;
    return Math.max(0, spawnedN - air.length - started - drainedDone.size);
  }

  const loop = () => {
    const now = performance.now();
    const dt = Math.min(0.05, (now - lastT) / 1000);
    lastT = now;
    clockTime += dt;

    tickMoney(dt);
    updateSparks(dt);
    updateStars(dt);
    updateConfetti(dt);
    if (dustMat) dustMat.uniforms.uTime.value = clockTime;

    const hn = hudCount();
    const pctNow = pctFromCount(hn);

    // near-goal escalation: brighter beam + livelier glints past 75%
    const heat = Math.max(0, Math.min(1, (pctNow - 75) / 25));
    beamMat.uniforms.uInt.value = SCENE.beamInt + heat * 0.08;

    twinkleAcc += dt;
    if (twinkleAcc > twinkleNext && !REDUCED) {
      twinkleAcc = 0;
      twinkleNext = (0.25 + rng() * 0.6) * (1 - 0.62 * heat);
      if (hn > 8) {
        // the overflow mound is the freshest thing on screen — favour it a bit
        const outN = hn - pile.nIn;
        const gi = outN > 5 && rng() < 0.35
          ? pile.nIn + Math.floor(rng() * outN)
          : Math.floor(rng() * hn);
        // most twinkles are a proper 4-ray star flash, the rest stay tiny dust
        if (rng() < 0.6) starAt(items[gi].pos);
        else sparkleAt(items[gi].pos, 0.045 + rng() * 0.05);
      }
    }

    // gentle flutter on the bills poking out of the mouth
    if (!REDUCED) for (const pi of pile.poked) {
      if (pi >= spawnedN || drainedDone.has(pi)) continue;
      let busy = false;
      for (const a of air) if (a.i === pi) { busy = true; break; }
      if (!busy) for (const d of drains) if (d.i === pi) { busy = true; break; }
      if (busy) continue;
      const it = items[pi];
      Q1.setFromEuler(E1.set(Math.sin(clockTime * 1.1 + pi) * 0.05, 0, Math.sin(clockTime * 0.8 + pi * 2.1) * 0.06));
      Q1.multiply(it.quat);
      setTransform(it, it.pos.x, it.pos.y, it.pos.z, Q1, it.s);
      meshes[it.bucket].instanceMatrix.needsUpdate = true;
    }

    // overflow-mound life: while the jar is idle, now and then a coin near the
    // top of the mound rocks under the pile's weight and re-seats itself
    const simIdle = air.length === 0 && drains.length === 0;
    if (!REDUCED && simIdle && hn > pile.nIn + 8) {
      settleAcc += dt;
      if (!settle && settleAcc > settleNext) {
        settleAcc = 0;
        settleNext = 3 + rng() * 5;
        const outN = hn - pile.nIn;
        // the last-poured coins sit highest — they're the precarious ones
        const i = pile.nIn + Math.min(outN - 1, Math.floor(outN * (0.55 + rng() * 0.45)));
        settle = { i, t: 0, dur: 0.5, ax: rng() - 0.5, az: rng() - 0.5 };
      }
    }
    if (settle) {
      const it = items[settle.i];
      if (!simIdle || settle.i >= Math.min(targetN, spawnedN)) {
        // the sim reclaimed this item (pour/drain started) → hand it back untouched
        restoreItem(settle.i);
        meshes[it.bucket].instanceMatrix.needsUpdate = true;
        settle = null;
      } else {
        settle.t += dt;
        const k = Math.min(1, settle.t / settle.dur);
        const e = Math.sin(Math.PI * k); // lift … drop back
        Q1.setFromEuler(E1.set(settle.ax * 0.34 * e, 0, settle.az * 0.34 * e));
        Q1.multiply(it.quat);
        setTransform(it, it.pos.x, it.pos.y + e * 0.016, it.pos.z, Q1, it.s);
        meshes[it.bucket].instanceMatrix.needsUpdate = true;
        if (k >= 1) {
          restoreItem(settle.i);
          starAt(it.pos, 0.24); // the re-seated coin catches the light
          if (rng() < 0.4) sound.clink();
          settle = null;
        }
      }
    }

    // milestone mini-bursts on the way up (and past the goal, into overflow)
    for (const m of MILESTONES) {
      if (pctNow >= m && pctNow < (m < 100 ? 99.9 : 199.9) && !milestonesFired.has(m)) {
        milestonesFired.add(m);
        if (!REDUCED) spawnConfetti(45, 0.7);
        sound.blip();
        emit({ type: 'event', kind: 'milestone', jarPct: m / 100 });
      } else if (pctNow < m - 8) {
        milestonesFired.delete(m);
      }
    }

    // goal reached (100%) → confetti burst (re-arms below 95%)
    if (hn >= pile.nIn && pile.nIn > 0 && !celebrated) {
      celebrated = true;
      if (!REDUCED) spawnConfetti(CONF);
      sound.chime();
      emit({ type: 'event', kind: 'goalReached', jarPct: 1 });
    } else if (hn < pile.nIn * 0.95) {
      celebrated = false;
    }
    // overflow zone visually full AND the host owes us a rollover → the second,
    // bigger moment… then the full jar RETIRES to the background shelf. Without
    // a commanded rollover the jar simply stays brim-full (the host's eager
    // accounting means this only happens transiently).
    if (hn === items.length && items.length > pile.nIn && pendingRollovers > 0 && !celebrated200) {
      celebrated200 = true;
      if (!REDUCED) { spawnConfetti(CONF); }
      sound.chime();
      emit({ type: 'event', kind: 'zoneFull', jarPct: 2 });
      rolloverAt = clockTime + (REDUCED ? 1.0 : 2.3); // let the moment land first
    } else if (pctNow < 190) {
      celebrated200 = false;
      if (pendingRollovers === 0) rolloverAt = -1; // drained back below — keep the jar
    }
    if (rolloverAt > 0 && clockTime >= rolloverAt) {
      rolloverAt = -1;
      retireVessel();
    }

    // the retiring trophy flies to its shelf spot on a gentle arc
    if (archAnim) {
      archAnim.t += dt;
      const k = Math.min(1, archAnim.t / archAnim.dur);
      const e = easeSm(k);
      archAnim.jar.position.lerpVectors(archAnim.from, archAnim.to, e);
      archAnim.jar.position.y += Math.sin(Math.PI * e) * (1.1 + spec.topY * 0.18);
      archAnim.jar.rotation.y = e * 2.2;
      if (k >= 1) {
        sparkleAt(V3.set(archAnim.to.x, archAnim.to.y + spec.topY * 0.7, archAnim.to.z), 0.09);
        archAnim = null;
        sound.clink();
        buildArchives(); // absorb the flyer into the static row
      }
    }

    updateCamera(clockTime);
    renderFrame();

    // auto-degrade for weak tablets: drop below native DPR if we can't hold ~36fps
    emaDt += (dt - emaDt) * 0.05;
    if (!degraded && clockTime > 5 && emaDt > 0.028) {
      degraded = true;
      bloomOn = false; // quality tier is the first thing to go
      renderer.setPixelRatio(1);
      resize();
      emit({ type: 'perf', fps: Math.round(1 / emaDt), quality: 'degraded' });
    }
  };

  // ------------------------------------------------------------ container / scene switch

  // fill the vessel instantly (restore / vessel switch) — no pour animation
  function setInstant(pct) {
    pct = THREE.MathUtils.clamp(Math.round(pct || 0), 0, 200);
    targetN = countFromPct(pct);
    spawnedN = targetN;
    updateCounts();
    for (const m of meshes) m.instanceMatrix.needsUpdate = true;
    celebrated = targetN >= pile.nIn && targetN > 0;
    celebrated200 = targetN === items.length && items.length > pile.nIn;
    // instant-full with jars still owed → schedule the retire theater
    rolloverAt = (celebrated200 && pendingRollovers > 0) ? clockTime + 2.5 : -1;
    milestonesFired.clear();
    for (const m of MILESTONES) if (pct >= m) milestonesFired.add(m);
  }

  // Settings changed mid-rollover-storm: the host has already banked those
  // jars, so fold the pending theater into the shelf and land on the remainder.
  function flushPendingRollovers() {
    if (pendingRollovers > 0) {
      bankedJars += pendingRollovers;
      pendingRollovers = 0;
      const p = afterPct >= 0 ? afterPct : 0;
      afterPct = -1;
      rolloverAt = -1;
      return p;
    }
    return null;
  }

  function currentPct() {
    return items.length ? Math.round(pctFromCount(targetN)) : 0;
  }

  function setContainer(key, opts = {}) {
    const c = CONTAINERS.find(x => x.key === key);
    if (!c) return;
    const flushed = flushPendingRollovers();
    const keepPct = opts.pct !== undefined ? opts.pct
      : flushed !== null ? flushed
      : currentPct();
    container = c;
    spec = containerSpec(c);
    air.length = 0;
    drains.length = 0;
    drainedDone.clear();
    spawnedN = 0; targetN = 0; spawnAcc = 0;
    buildVessel();
    buildScenery();
    sizeBeam();
    if (dustPts) {
      const k = Math.max(0.5, spec.R / 0.84);
      dustPts.scale.set(k, Math.max(0.45, (spec.topY + 1.3) / 4.8), k);
    }
    buildMoney();
    resize();
    setInstant(keepPct);
  }

  // swap the backdrop set: rebuild the scenery around the same vessel + pile,
  // re-bake reflections and retint beam/dust/pool/background
  function setScene(key) {
    const s = SCENES.find(x => x.key === key);
    if (!s) return;
    const flushed = flushPendingRollovers();
    const keepPct = flushed !== null ? flushed : currentPct();
    SCENE = s;
    air.length = 0;
    drains.length = 0;
    drainedDone.clear();
    spawnedN = 0; targetN = 0; spawnAcc = 0;
    buildVessel();  // per-scene glass reflectivity
    buildScenery();
    buildMoney();   // per-scene overflow spill zone
    applySceneAtmosphere();
    setInstant(keepPct);
  }

  // ---------------------------------------------------------------- controller

  let paused = false;

  function applyTip(m) {
    // the moment the artist must not miss: ta-da (if enabled) + a small
    // in-scene confetti pop, a bigger one when the tip is ≥10% of the goal
    sound.tada();
    if (!REDUCED) spawnConfetti((+m.deltaPct || 0) >= 0.1 ? 70 : 30, 0.7);
    const after = THREE.MathUtils.clamp((+m.jarPctAfter || 0), 0, 2) * 100;
    const rolls = Math.max(0, Math.floor(m.rollovers || 0));
    if (rolls > 0) {
      pendingRollovers += rolls;
      afterPct = after;
      pourToCount(items.length); // drive to the brim; the loop takes it from there
    } else if (pendingRollovers > 0) {
      afterPct = after; // tip landed mid-theater — update the final remainder
    } else {
      pourToCount(countFromPct(after));
    }
  }

  function syncState(state, instant) {
    pendingRollovers = 0;
    afterPct = -1;
    rolloverAt = -1;
    bankedJars = Math.max(0, Math.floor(state.bankedJars || 0));
    buildArchives();
    const pct = THREE.MathUtils.clamp((+state.jarPct || 0), 0, 2) * 100;
    if (instant) setInstant(pct);
    else pourToCount(countFromPct(pct));
  }

  function setConfig(cfg) {
    if (cfg.insets) { insets = { top: 0, bottom: 0, ...cfg.insets }; resize(); }
    if (cfg.theme !== undefined) {
      const t = THEMES.find(x => x.key === cfg.theme);
      if (t) setTheme(t);
    }
    if (cfg.sound !== undefined) sound.setCoins(!!cfg.sound);
    if (cfg.tipSound !== undefined) sound.setFanfare(!!cfg.tipSound);
    if (cfg.quality !== undefined) {
      quality = cfg.quality;
      bloomOn = degraded ? false : bloomFromQuality(quality);
    }
    if (cfg.notes !== undefined && !!cfg.notes !== billsOn) {
      billsOn = !!cfg.notes;
      setContainer(container.key); // rebuild the pile with/without bills
    }
    if (cfg.vessel !== undefined && cfg.vessel !== container.key) setContainer(cfg.vessel);
    if (cfg.scene !== undefined && cfg.scene !== SCENE.key) setScene(cfg.scene);
  }

  function setPaused(v) {
    v = !!v;
    if (v === paused) return;
    paused = v;
    if (paused) {
      renderer.setAnimationLoop(null);
    } else {
      lastT = performance.now();
      renderer.setAnimationLoop(loop);
    }
  }

  // ---------------------------------------------------------------- boot

  const restorePct = THREE.MathUtils.clamp(((ctx.state && ctx.state.jarPct) || 0), 0, 2) * 100;
  setContainer(container.key, { pct: restorePct });
  renderer.setAnimationLoop(loop);
  // Announce from boot, not from the render loop: an embedded WebView can
  // sit paused/invisible at init and the first frame may be far away — the
  // host only needs the handshake to complete.
  ctx.ready();

  return {
    applyTip,
    syncState,
    setConfig,
    setPaused,
    jarPct: () => THREE.MathUtils.clamp(pctFromCount(targetN) / 100, 0, 2),
    perf: () => ({
      fps: paused ? 0 : Math.round(1 / emaDt),
      quality: degraded ? 'degraded' : bloomOn ? 'high' : 'low',
    }),
  };
}
