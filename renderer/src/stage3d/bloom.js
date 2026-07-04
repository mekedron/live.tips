/**
 * Bloom (quality tier) — hand-rolled post: scene → target, bright-pass,
 * 2× separable blur at half res, composite with the missing gamma.
 * ~1.3 ms on capable GPUs; the app toggles it and falls back to a plain
 * render when off or degraded.
 *
 * Trap notes (hard-won):
 *  - 8-bit targets: MSAA + blending on LDR is supported everywhere
 *    (half-float + samples broke alpha blending on some drivers).
 *  - Render targets skip the renderer's sRGB encode, so the target holds
 *    tone-mapped LINEAR values → the composite applies pow(1/2.2) itself.
 */
import * as THREE from '../vendor/three.module.min.js';

export function createBloom(renderer) {
  const bloom = { ready: false };

  function init() {
    const mk = (fs, uniforms) => new THREE.ShaderMaterial({
      depthTest: false,
      depthWrite: false,
      blending: THREE.NoBlending,
      uniforms,
      vertexShader: 'varying vec2 vUv; void main() { vUv = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }',
      fragmentShader: fs,
    });
    bloom.rtScene = new THREE.WebGLRenderTarget(2, 2, { samples: 4 });
    bloom.rtA = new THREE.WebGLRenderTarget(2, 2);
    bloom.rtB = new THREE.WebGLRenderTarget(2, 2);
    bloom.bright = mk(`varying vec2 vUv; uniform sampler2D tex;
      void main() {
        vec3 c = texture2D(tex, vUv).rgb;
        float l = dot(c, vec3(0.299, 0.587, 0.114));
        gl_FragColor = vec4(c * smoothstep(0.68, 0.98, l), 1.0);
      }`, { tex: { value: null } });
    bloom.blur = mk(`varying vec2 vUv; uniform sampler2D tex; uniform vec2 uDir;
      void main() {
        vec3 s = texture2D(tex, vUv).rgb * 0.227027;
        vec2 o1 = uDir * 1.3846, o2 = uDir * 3.2308;
        s += (texture2D(tex, vUv + o1).rgb + texture2D(tex, vUv - o1).rgb) * 0.316216;
        s += (texture2D(tex, vUv + o2).rgb + texture2D(tex, vUv - o2).rgb) * 0.070270;
        gl_FragColor = vec4(s, 1.0);
      }`, { tex: { value: null }, uDir: { value: new THREE.Vector2() } });
    bloom.comp = mk(`varying vec2 vUv;
      uniform sampler2D tScene; uniform sampler2D tBloom; uniform float uStr;
      void main() {
        vec3 c = texture2D(tScene, vUv).rgb + texture2D(tBloom, vUv).rgb * uStr;
        gl_FragColor = vec4(pow(c, vec3(0.4545)), 1.0);
      }`, { tScene: { value: null }, tBloom: { value: null }, uStr: { value: 0.45 } });
    bloom.quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), bloom.bright);
    bloom.scene = new THREE.Scene();
    bloom.scene.add(bloom.quad);
    bloom.cam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    bloom.ready = true;
  }

  function resize() {
    if (!bloom.ready) return;
    const s = renderer.getDrawingBufferSize(new THREE.Vector2());
    bloom.rtScene.setSize(s.x, s.y);
    bloom.rtA.setSize(Math.max(2, s.x >> 1), Math.max(2, s.y >> 1));
    bloom.rtB.setSize(Math.max(2, s.x >> 1), Math.max(2, s.y >> 1));
  }

  function fsPass(mat, target) {
    bloom.quad.material = mat;
    renderer.setRenderTarget(target);
    renderer.render(bloom.scene, bloom.cam);
  }

  function render(scene, camera) {
    if (!bloom.ready) { init(); resize(); }
    renderer.setRenderTarget(bloom.rtScene);
    renderer.render(scene, camera);
    bloom.bright.uniforms.tex.value = bloom.rtScene.texture;
    fsPass(bloom.bright, bloom.rtA);
    const px = 1 / bloom.rtA.width, py = 1 / bloom.rtA.height;
    for (let i = 1; i <= 2; i++) {
      bloom.blur.uniforms.tex.value = bloom.rtA.texture;
      bloom.blur.uniforms.uDir.value.set(px * i, 0);
      fsPass(bloom.blur, bloom.rtB);
      bloom.blur.uniforms.tex.value = bloom.rtB.texture;
      bloom.blur.uniforms.uDir.value.set(0, py * i);
      fsPass(bloom.blur, bloom.rtA);
    }
    bloom.comp.uniforms.tScene.value = bloom.rtScene.texture;
    bloom.comp.uniforms.tBloom.value = bloom.rtA.texture;
    fsPass(bloom.comp, null);
  }

  return { render, resize };
}
