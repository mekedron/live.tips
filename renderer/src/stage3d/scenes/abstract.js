/** Abstract glow — the original dark stage. The only fully theme-reactive set. */
import * as THREE from '../../vendor/three.module.min.js';

export default {
  key: 'abstract', label: 'Abstract glow',
  dome: ['#26232e', '#55525f', '#8a8896', '#cfc6b8'],
  hemi: [0x8b93c4, 0x1e1830, 0.65],
  keyL: [0xfff1e0, 1.5], rimL: [0x8fb4ff, 0.8],
  beamInt: 0.14, beamColor: 'theme', dustColor: 'theme', poolColor: 'theme',
  bg: 'theme', glassEnv: 1,
  spillR: (spec) => spec.R + 0.34, // overflow coins stay on the table disc
  archY: -0.02, archPedestal: true, // retired jars float on their own discs

  build(gr, spec) {
    const tr = spec.R + 0.42;
    const table = new THREE.Mesh(
      new THREE.CylinderGeometry(tr - 0.1, tr, 0.1, 40),
      new THREE.MeshStandardMaterial({ color: 0x141026, roughness: 0.95, metalness: 0, envMapIntensity: 0.18 })
    );
    table.position.y = -0.07; // top sits 0.02 below the vessel → no z-fight
    gr.add(table);
  },
};
