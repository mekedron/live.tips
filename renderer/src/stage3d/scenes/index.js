/**
 * Scene registry — the backdrop sets the vessel can stand in.
 *
 * A scene is a plain object:
 *   key/label      — identity for the picker, ?scene= URL param and the API
 *   dome           — 4 gradient stops (floor→zenith) for the PMREM reflection
 *                    dome; re-baked on scene switch so coin/glass reflections
 *                    match the set (amber in the pub, moonlit blue outside)
 *   hemi           — [skyColor, groundColor, intensity] hemisphere light
 *   keyL, rimL     — [color, intensity] for the camera-following key/rim rig
 *   beamInt        — main spotlight cone base intensity; 0 hides beam + dust
 *   beamColor      — [r,g,b] 0..1, or 'theme' to follow the active theme
 *   dustColor      — same, for the dust motes drifting in the beam
 *   poolColor      — 'r,g,b' 0..255 string for the light pool, or 'theme'
 *   bg             — background: [3 gradient stops], 'theme', or a
 *                    (ctx2d) => {} painter over a 512×512 canvas
 *   glassEnv       — vessel-glass envMapIntensity multiplier (warm domes
 *                    reflect across the whole glass and read as frosting)
 *   spillR(spec)   — usable flat radius around the vessel on the support:
 *                    the 100–200% overflow coins pile inside this circle
 *   archY          — floor level (world y) where retired 200% jars stand in
 *                    the background; archPedestal: true gives each one a small
 *                    floating disc (for sets with no floor, e.g. abstract)
 *   build(gr, spec)— add meshes to the THREE.Group `gr`. The vessel sits at
 *                    the origin with its base at y = 0; put the support's top
 *                    surface at y ≈ -0.02. `spec` is the vessel spec (R, topY,
 *                    mouthR…) so supports can size themselves. Everything in
 *                    the group is auto-disposed on scene switch — geometries,
 *                    materials, canvas maps, instance buffers.
 *
 * Adding a scene = drop a file here, import it below, add it to the array.
 * A future glTF-based scene needs no new plumbing: load the model inside
 * build() and add it to the group (mind the y≈-0.02 support convention).
 */
import abstract from './abstract.js';
import pub from './pub.js';
import concert from './concert.js';
import street from './street.js';
import metro from './metro.js';
import cafe from './cafe.js';

export const SCENES = [abstract, pub, concert, street, metro, cafe];
