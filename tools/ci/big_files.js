'use strict';
// Issue 1491 (audit GH-01): the repo is 10.8 GiB and docs/shots alone is 1.12 GB. This warns, and never fails, when the
// current branch adds or changes a file over 2 MB outside godot/ and assets/ compared with origin/main.
// Usage: node tools/ci/big_files.js            prints "WARN big file: <path> <MB> MB" per file; always exits 0
//        node tools/ci/big_files.js --self-test   checks the filter on a fake list; exits 1 if any case is wrong
// Node 22, no dependencies. Run from anywhere: git runs in the repository root.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '../..');
const LIMIT_BYTES = 2 * 1024 * 1024;
const EXEMPT_PREFIXES = ['godot/', 'assets/'];

function isExempt(p) {
  const norm = String(p).replace(/\\/g, '/').replace(/^\.\//, '');
  return EXEMPT_PREFIXES.some(prefix => norm.startsWith(prefix));
}

// entries: [{ path, bytes }]. Returns the ones that deserve a warning.
function findBig(entries) {
  return entries.filter(e => !isExempt(e.path) && e.bytes > LIMIT_BYTES);
}

function warnLine(e) {
  return 'WARN big file: ' + String(e.path).replace(/[^\x20-\x7e]/g, '?') + ' ' + (e.bytes / (1024 * 1024)).toFixed(2) + ' MB';
}

function git(args) {
  return spawnSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, windowsHide: true });
}

function sizeOf(p) {
  try { return fs.statSync(path.join(ROOT, p)).size; } catch (e) { /* not in the working tree: ask git */ }
  const r = git(['cat-file', '-s', 'HEAD:' + p]);
  const n = r.status === 0 ? parseInt(r.stdout, 10) : NaN;
  return Number.isFinite(n) ? n : 0;
}

function selfTest() {
  const MB = 1024 * 1024;
  const cases = [
    ['3 MB docs/shots/x.png is flagged', [{ path: 'docs/shots/x.png', bytes: 3 * MB }], ['docs/shots/x.png']],
    ['3 MB godot/ships/x.glb is not flagged', [{ path: 'godot/ships/x.glb', bytes: 3 * MB }], []],
    ['3 MB assets/x.png is not flagged', [{ path: 'assets/x.png', bytes: 3 * MB }], []],
    ['1 MB docs/shots/y.png is not flagged', [{ path: 'docs/shots/y.png', bytes: 1 * MB }], []],
    ['exactly 2 MB is not flagged', [{ path: 'docs/z.bin', bytes: 2 * MB }], []],
    ['a path that only starts like godot is flagged', [{ path: 'godotx/a.bin', bytes: 3 * MB }], ['godotx/a.bin']],
    ['mixed list keeps only the right one', [
      { path: 'docs/shots/x.png', bytes: 3 * MB }, { path: 'godot/ships/x.glb', bytes: 3 * MB }, { path: 'docs/small.md', bytes: 1 * MB },
    ], ['docs/shots/x.png']],
  ];
  let bad = 0;
  for (const [name, entries, want] of cases) {
    const got = findBig(entries).map(e => e.path);
    if (JSON.stringify(got) !== JSON.stringify(want)) { bad++; console.log('FAIL ' + name + ': got ' + JSON.stringify(got) + ', want ' + JSON.stringify(want)); }
  }
  const line = warnLine({ path: 'docs/shots/x.png', bytes: 3 * MB });
  if (line !== 'WARN big file: docs/shots/x.png 3.00 MB') { bad++; console.log('FAIL warn line: ' + line); }
  if (bad) { console.log('FAIL big_files self-test: ' + bad + ' wrong of ' + (cases.length + 1)); return 1; }
  console.log('PASS big_files self-test: ' + (cases.length + 1) + ' cases');
  return 0;
}

function main() {
  const base = git(['rev-parse', '--verify', '--quiet', 'origin/main']);
  if (base.status !== 0) { console.log('SKIP big_files: origin/main is missing, nothing to compare'); return; }
  const diff = git(['diff', '--name-only', '-z', '--diff-filter=AM', 'origin/main...HEAD']);
  if (diff.status !== 0) { console.log('SKIP big_files: could not compare with origin/main (' + String(diff.stderr || '').trim().split(/\r?\n/)[0] + ')'); return; }
  const files = diff.stdout.split('\0').filter(Boolean).filter(p => !isExempt(p));
  const big = findBig(files.map(p => ({ path: p, bytes: sizeOf(p) })));
  for (const e of big) console.log(warnLine(e));
}

if (require.main === module) {
  if (process.argv.includes('--self-test')) process.exitCode = selfTest();
  else {
    try { main(); } catch (e) { console.log('SKIP big_files: ' + String(e && e.message).replace(/[\r\n]+/g, ' ')); }
    process.exitCode = 0;
  }
}

module.exports = { isExempt, findBig, warnLine, LIMIT_BYTES };
