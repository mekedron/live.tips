/**
 * Tiny synthesized sound design — no audio assets.
 * Two independent channels, each gated by the HOST (bridge `setConfig`):
 *   coins   — clinks while money lands, milestone blips, goal chimes
 *   fanfare — the "ta-da!" that announces a NEW TIP, loud enough for the
 *             artist to hear it mid-song and thank the fan
 * Nothing persists here; the host owns both toggles.
 * Coin clinks = two inharmonic sine partials with a fast exponential decay.
 */
export function createSound() {
  let ctx = null;
  let coins = false;
  let fanfare = false;
  let lastClink = 0;
  let lastTada = 0;

  const ac = () => {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    return ctx;
  };
  const resume = () => { try { ac().resume(); } catch { /* next gesture */ } };

  function tone(freq, type, peak, decay, delay = 0) {
    const c = ac();
    const t0 = c.currentTime + delay;
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type;
    o.frequency.value = freq;
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(peak, t0 + 0.004);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + decay);
    o.connect(g).connect(c.destination);
    o.start(t0);
    o.stop(t0 + decay + 0.05);
  }

  // Brass-ish stab for the fanfare: two detuned saws through a closing
  // lowpass with a fast attack and a two-stage decay — reads as "trumpet",
  // not "buzzer", and carries over stage noise better than pure sines.
  function stab(freq, peak, dur, delay = 0) {
    const c = ac();
    const t0 = c.currentTime + delay;
    const f = c.createBiquadFilter();
    f.type = 'lowpass';
    f.Q.value = 0.8;
    f.frequency.setValueAtTime(freq * 5, t0);
    f.frequency.exponentialRampToValueAtTime(freq * 2.1, t0 + dur);
    const g = c.createGain();
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(peak, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(peak * 0.45, t0 + dur * 0.45);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    f.connect(g).connect(c.destination);
    for (const det of [1, 1.006]) {
      const o = c.createOscillator();
      o.type = 'sawtooth';
      o.frequency.value = freq * det;
      o.connect(f);
      o.start(t0);
      o.stop(t0 + dur + 0.05);
    }
  }

  return {
    setCoins(v) {
      coins = !!v;
      if (coins) resume();
    },
    setFanfare(v) {
      fanfare = !!v;
      if (fanfare) resume();
    },
    /** call from any user gesture — autoplay-suspended contexts need one */
    unlock() { if (coins || fanfare) resume(); },
    clink() {
      if (!coins) return;
      const now = performance.now();
      if (now - lastClink < 45) return; // dense pours → sparse clinks
      lastClink = now;
      const f = 1700 + Math.random() * 1600;
      tone(f, 'sine', 0.045, 0.09);
      tone(f * 2.756, 'sine', 0.018, 0.05);
    },
    blip() { // milestone
      if (!coins) return;
      tone(660, 'triangle', 0.06, 0.25);
      tone(990, 'triangle', 0.045, 0.3, 0.06);
    },
    chime() { // goal
      if (!coins) return;
      [523.25, 659.25, 783.99, 1046.5].forEach((f, i) => tone(f, 'triangle', 0.07, 0.7, i * 0.09));
    },
    tada() { // a new tip landed — "ta-da-DAA!" (G4, C5, then a C-major blaze)
      if (!fanfare) return;
      const now = performance.now();
      if (now - lastTada < 1300) return; // resume backfills → one ta-da, not ten
      lastTada = now;
      resume();
      stab(392.0, 0.075, 0.16);
      stab(523.25, 0.075, 0.16, 0.17);
      stab(659.25, 0.08, 0.85, 0.34);
      stab(783.99, 0.065, 0.85, 0.34);
      stab(1046.5, 0.05, 0.85, 0.34);
      tone(2093, 'sine', 0.04, 0.6, 0.4); // sparkle on top
    },
  };
}
