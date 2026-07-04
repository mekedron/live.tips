/**
 * Stage themes matched to live.tips PublicPageThemePreset (dark-mode tokens).
 * `?theme=<key>` picks one on load; the 🎨 pill cycles them live.
 */
export const THEMES = [
  { key: 'golden-hour',   label: 'Golden Hour',   accent: '#fbbf24', accent2: '#fdba74', bg0: '#050816', bg1: '#221a44', beam: '255,214,150', confetti: ['#fbbf24', '#fdba74', '#fff3d6', '#ffd700', '#a7bedd'] },
  { key: 'nord-sky',      label: 'Nord Sky',      accent: '#38bdf8', accent2: '#7dd3fc', bg0: '#030712', bg1: '#12234a', beam: '150,210,255', confetti: ['#38bdf8', '#7dd3fc', '#e8f7ff', '#ffd700', '#ffffff'] },
  { key: 'forest-signal', label: 'Forest Signal', accent: '#4ade80', accent2: '#86efac', bg0: '#03110b', bg1: '#0a2e20', beam: '150,240,190', confetti: ['#4ade80', '#86efac', '#eafff2', '#ffd700', '#baf7d0'] },
  { key: 'rose-pulse',    label: 'Rose Pulse',    accent: '#fb7185', accent2: '#fda4af', bg0: '#0d0710', bg1: '#341423', beam: '255,165,185', confetti: ['#fb7185', '#fda4af', '#fff0f2', '#ffd700', '#ffc2cb'] },
  { key: 'cobalt-stage',  label: 'Cobalt Stage',  accent: '#818cf8', accent2: '#93c5fd', bg0: '#050816', bg1: '#1b2150', beam: '165,175,255', confetti: ['#818cf8', '#93c5fd', '#eef1ff', '#ffd700', '#c7d2fe'] },
  { key: 'graphite-lime', label: 'Graphite Lime', accent: '#a3e635', accent2: '#d9f99d', bg0: '#080a08', bg1: '#1d240f', beam: '205,240,140', confetti: ['#a3e635', '#d9f99d', '#f8ffe8', '#ffd700', '#e2f8b0'] },
];

export function initialTheme() {
  const key = new URLSearchParams(location.search).get('theme');
  return THEMES.find(t => t.key === key) || THEMES[0];
}

export function applyCssTheme(t) {
  const s = document.documentElement.style;
  s.setProperty('--accent', t.accent);
  s.setProperty('--accent-2', t.accent2);
  s.setProperty('--bg0', t.bg0);
  s.setProperty('--bg1', t.bg1);
}

/** '255,214,150' → [1.0, 0.84, 0.59] for shader uniforms */
export function beamGl(t) {
  return t.beam.split(',').map(v => parseInt(v, 10) / 255);
}

/** '#fbbf24' → [r, g, b] floats */
export function hexGl(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
}
