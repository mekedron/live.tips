/**
 * live.tips stage library — entry point.
 *
 * Boot handshake (see PROTOCOL.md):
 *   page load → JS sends `hello{protocol}` → host sends `init{renderer,…}` →
 *   renderer builds & renders its first frame → JS sends `ready` → messages flow.
 *
 * Both renderers implement the same controller contract:
 *   { applyTip(msg), syncState(state, instant), setConfig(partial),
 *     setPaused(bool), jarPct() → 0..2, perf() → {fps, quality} }
 */
import { createBridge, PROTOCOL } from './bridge.js';
import { createStage as createStage3d } from './stage3d/app.js';
import { createStage as createStage2d } from './stage2d/app.js';

const bridge = createBridge();

let controller = null;
let queued = [];           // messages that arrived between init and ready
let hostPaused = false;    // host-driven (app background / route covered)
// Deliberately NOT seeded from document.hidden: embedded WKWebViews report
// hidden while the platform view attaches and never dispatch the change —
// trusting it froze the renderer forever. We only react to real transitions;
// the host's setPaused stays authoritative.
let docHidden = false;

function applyPaused() {
  if (controller) controller.setPaused(hostPaused || docHidden);
}

// Preview screens ask the stage to invent a small tip so the artist can see
// their look react without a running session.
const pulseRnd = () => 0.01 + Math.random() * 0.035;
function demoPulse() {
  if (!controller) return;
  const cur = controller.jarPct();
  const delta = pulseRnd();
  let after = cur + delta;
  let rollovers = 0;
  if (after >= 2) { rollovers = 1; after -= 2; }
  controller.applyTip({ deltaPct: delta, jarPctAfter: after, rollovers });
}

function handle(msg) {
  switch (msg.type) {
    case 'init': {
      if (controller) return; // re-init needs a page reload (host reloads on crash)
      const config = msg.config || {};
      const state = msg.state || {};
      const reduced = !!config.reducedMotion
        || (matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
      const ctx = {
        host: document.getElementById('stage'),
        config,
        state,
        reduced,
        emit: bridge.emit,
        ready: () => {
          bridge.markReady();
          const backlog = queued;
          queued = [];
          for (const m of backlog) handle(m);
        },
      };
      controller = (msg.renderer === '2d' ? createStage2d : createStage3d)(ctx);
      applyPaused();
      break;
    }
    case 'tip':
      if (!bridge.isReady) { queued.push(msg); break; }
      controller.applyTip(msg);
      break;
    case 'syncState':
      if (!bridge.isReady) { queued.push(msg); break; }
      controller.syncState(msg.state || {}, !!msg.instant);
      break;
    case 'setConfig':
      if (!bridge.isReady) { queued.push(msg); break; }
      controller.setConfig(msg.config || {});
      break;
    case 'setPaused':
      hostPaused = !!msg.paused;
      applyPaused();
      break;
    case 'demoPulse':
      if (bridge.isReady) demoPulse();
      break;
    default:
      // Unknown types are ignored by contract — forward compatibility.
      break;
  }
}

bridge.onMessage = handle;

// Belt-and-braces alongside the host's setPaused: a hidden page stops burning
// the battery even if the host forgot to pause us.
document.addEventListener('visibilitychange', () => {
  docHidden = document.hidden;
  applyPaused();
});

// Heartbeat: perf telemetry doubles as the host watchdog's liveness signal,
// so it must tick even while the render loop idles or is paused.
setInterval(() => {
  if (controller && bridge.isReady) bridge.emit({ type: 'perf', ...controller.perf() });
}, 5000);

bridge.emit({ type: 'hello', protocol: PROTOCOL });
