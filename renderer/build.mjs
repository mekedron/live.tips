/**
 * Builds the stage library into the Flutter app's assets:
 *   renderer/src/main.js  →  app/assets/stage/stage.js  (single-file IIFE)
 *
 * The artifact is COMMITTED so `flutter build` never needs node. Re-run
 * `npm run build` after changing anything under src/ and commit both.
 * `npm run watch` rebuilds on save (pair with a static server + dev.html).
 */
import * as esbuild from 'esbuild';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const outfile = join(here, '..', 'app', 'assets', 'stage', 'stage.js');

const options = {
  entryPoints: [join(here, 'src', 'main.js')],
  bundle: true,
  format: 'iife',
  target: ['es2018', 'safari13'], // old Android WebViews & WKWebView floors
  minify: true,
  sourcemap: false,
  legalComments: 'inline', // keep the three.js MIT notice in the artifact
  outfile,
  logLevel: 'info',
};

if (process.argv.includes('--watch')) {
  const ctx = await esbuild.context(options);
  await ctx.watch();
  console.log('watching src/ → rebuilding', outfile);
} else {
  await esbuild.build(options);
}
