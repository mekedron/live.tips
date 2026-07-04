/**
 * Host bridge — the ONLY doorway between the stage library and its host.
 *
 * JS → host: `window.LiveTips.postMessage(json)` — a webview_flutter
 * JavaScriptChannel in the app; the dev harness installs the same global.
 * Host → JS: `window.__stage.dispatch(jsonOrObject)` — the app calls it via
 * runJavaScript(); the harness calls it directly.
 *
 * Every outgoing message carries `v: 1` (protocol version). Malformed input
 * never throws into the host — it answers with a non-fatal `error` message.
 */
export const PROTOCOL = 1;

export function createBridge() {
  let ready = false;

  const emit = (m) => {
    const s = JSON.stringify({ v: PROTOCOL, ...m });
    if (window.LiveTips && window.LiveTips.postMessage) {
      window.LiveTips.postMessage(s);
    } else {
      console.log('[stage→host]', s); // headless dev — visible in devtools
    }
  };

  const api = {
    emit,
    onMessage: null,
    markReady() {
      if (ready) return;
      ready = true;
      emit({ type: 'ready' });
    },
    get isReady() { return ready; },
  };

  window.__stage = {
    dispatch(raw) {
      let msg = null;
      try {
        msg = typeof raw === 'string' ? JSON.parse(raw) : raw;
      } catch (e) {
        emit({ type: 'error', message: 'unparseable message: ' + e, fatal: false });
        return;
      }
      if (!msg || typeof msg.type !== 'string') {
        emit({ type: 'error', message: 'message without type', fatal: false });
        return;
      }
      try {
        if (api.onMessage) api.onMessage(msg);
      } catch (e) {
        // a handler bug must surface to the host, not vanish in the console
        emit({ type: 'error', message: `handling '${msg.type}': ${e && e.stack || e}`, fatal: false });
      }
    },
  };

  // Uncaught errors before `ready` are fatal (the host falls back to another
  // stage style); after `ready` they are reported but the show goes on.
  addEventListener('error', (e) => {
    emit({ type: 'error', message: String(e.message || e), fatal: !ready });
  });
  addEventListener('unhandledrejection', (e) => {
    const r = e.reason;
    emit({ type: 'error', message: 'rejection: ' + String(r && r.message || r), fatal: false });
  });

  return api;
}
