#!/usr/bin/env node
/**
 * Reads every colour key an IDE actually registers, straight out of its bytecode.
 *
 * The key table used to be written by hand, and hand-written tables are wrong in
 * a way that is invisible: a key nobody named does not error, it silently takes
 * its colour from `parent_scheme` — `Default` under the light theme and
 * `Darcula` under the dark one. That is how Go structs ended up teal in dark and
 * black in light while both schemes "passed" every check we had.
 *
 * Usage: node extract-keys.mjs [/path/to/IDE.app] > keys.txt
 */
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const app = process.argv[2] ?? '/Users/islom/Applications/GoLand.app';
const jars = [];
(function walk(dir) {
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.jar') && statSync(p).size < 200e6) jars.push(p);
  }
})(join(app, 'Contents'));

const work = mkdtempSync(join(tmpdir(), 'saff-keys-'));
const keys = new Map(); // name -> 'attributes' | 'colors'
for (const jar of jars) {
  const out = join(work, 'x');
  try { execFileSync('unzip', ['-qo', jar, '-d', out], { stdio: 'ignore' }); } catch { continue; }
  // Only classes that actually build keys are worth decompiling.
  let cand = '';
  try {
    cand = execFileSync('grep', ['-rla', '-e', 'createTextAttributesKey', '-e', 'createColorKey', out],
      { encoding: 'utf8', maxBuffer: 64e6 });
  } catch { /* no match */ }
  for (const cls of cand.split('\n').filter((f) => f.endsWith('.class'))) {
    let dis = '';
    try { dis = execFileSync('javap', ['-p', '-c', cls], { encoding: 'utf8', maxBuffer: 64e6 }); } catch { continue; }
    // Kotlin and Java both ldc the external name, then the factory marker or call.
    let pending = null;
    for (const line of dis.split('\n')) {
      const s = /\/\/ String ([A-Za-z][A-Za-z0-9_.]*)$/.exec(line.trim());
      if (s) {
        const n = s[1];
        if (/^[A-Z][A-Z0-9_.]{2,}$/.test(n) && !n.endsWith('_')) { pending = n; continue; }
        if (n === 'createColorKey' && pending) { keys.set(pending, 'colors'); pending = null; continue; }
        if (n === 'createTextAttributesKey' && pending) { keys.set(pending, 'attributes'); pending = null; continue; }
      }
      if (/createColorKey:/.test(line) && pending) { keys.set(pending, 'colors'); pending = null; }
      else if (/createTextAttributesKey:/.test(line) && pending) { keys.set(pending, 'attributes'); pending = null; }
    }
  }
  rmSync(out, { recursive: true, force: true });
}
rmSync(work, { recursive: true, force: true });
for (const [k, kind] of [...keys].sort()) console.log(`${kind}\t${k}`);
console.error(`${keys.size} keys from ${jars.length} jars`);
