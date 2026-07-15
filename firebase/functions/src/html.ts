/// A tiny auto-escaping HTML tagged template. Every interpolated value is
/// HTML-escaped by construction; the ONLY way to emit unescaped markup is to
/// wrap it in raw() — so "did this value get escaped?" is answered by reading
/// for the word `raw`, not by remembering to call escapeHtml at each hole.
///
/// This is the whole XSS story for the tip page: page data reaches the markup
/// through ${...} (escaped), CSS/JS constants through raw() (never fan input),
/// and the one inline <script> stays a static constant so its CSP hash holds.

import { escapeHtml } from "./validate";

/** Markup already known to be safe — a nested html`` result, or a raw() string. */
export class SafeHtml {
  constructor(readonly value: string) {}
  toString(): string {
    return this.value;
  }
}

/** Opt a trusted string out of escaping (static CSS/JS, pre-escaped fragments). */
export function raw(value: string): SafeHtml {
  return new SafeHtml(value);
}

type Interpolation = string | number | boolean | null | undefined | SafeHtml | Interpolation[];

function render(value: Interpolation): string {
  // false/null/undefined render to nothing so `${cond && html`...`}` is clean.
  if (value === null || value === undefined || value === false || value === true) return "";
  if (value instanceof SafeHtml) return value.value;
  if (Array.isArray(value)) return value.map(render).join("");
  if (typeof value === "number") return String(value);
  return escapeHtml(value);
}

export function html(strings: TemplateStringsArray, ...values: Interpolation[]): SafeHtml {
  let out = strings[0]!;
  for (let i = 0; i < values.length; i++) {
    out += render(values[i]!) + strings[i + 1]!;
  }
  return new SafeHtml(out);
}
