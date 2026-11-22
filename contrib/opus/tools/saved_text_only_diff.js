// Issue 1551: compares a pinned saved Godot baseline with a parity run folder and fails on any difference that is not a
// changed string (numbers, keys, record counts, RNG, actor, round), or when any baseline battle is missing from the run.
// Usage: node contrib/opus/tools/saved_text_only_diff.js --base-rev <git revision> <parity run folder>
// The baseline is read from that revision's godot/rules/test/saved (never the checkout), so a refreshed branch cannot
// compare its new results with themselves.
'use strict';
const fs = require('fs'), path = require('path'), os = require('os'), cp = require('child_process');
const R = require(path.join(__dirname, '../../../godot/rules/test/saved/records.js'));
const args = process.argv.slice(2);
const at = args.indexOf('--base-rev');
if (at < 0 || !args[at + 1] || args.length !== 3) {
  console.error('usage: saved_text_only_diff.js --base-rev <git revision> <parity run folder>');
  process.exit(2);
}
const rev = args[at + 1], run = args.filter((_, i) => i !== at && i !== at + 1)[0];
const repo = path.join(__dirname, '../../..');
const git = (...a) => cp.execFileSync('git', a, { cwd: repo, maxBuffer: 1 << 28 });
const sha = git('rev-parse', '--verify', rev + '^{commit}').toString().trim();
const base = fs.mkdtempSync(path.join(os.tmpdir(), 'saved-base-'));
fs.mkdirSync(path.join(base, 'records'));
fs.writeFileSync(path.join(base, 'results.json'), git('show', sha + ':godot/rules/test/saved/results.json'));
const m = R.manifest(base);
for (const e of Object.values(m.battles)) fs.writeFileSync(path.join(base, 'records', e.archive), git('show', sha + ':godot/rules/test/saved/records/' + e.archive));
let bad = 0, n = 0, usageDiff = 0;
const missing = [], strings = new Map();
const note = (...a) => { if (bad++ < 20) console.log(...a); };
function cmp(a, b, p, name) {
  if (typeof a === 'string' && typeof b === 'string') {
    if (a !== b) { const k = a.slice(0, 60) + ' -> ' + b.slice(0, 60); strings.set(k, (strings.get(k) || 0) + 1); }
    return;
  }
  if (typeof a !== typeof b || Array.isArray(a) !== Array.isArray(b) || (a === null) !== (b === null)) return note('TYPE', name, p);
  if (a && typeof a === 'object') {
    if (Array.isArray(a)) { if (a.length !== b.length) return note('LENGTH', name, p); a.forEach((x, i) => cmp(x, b[i], p + '[' + i + ']', name)); return; }
    const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
    if (ka.join('\n') !== kb.join('\n')) { if (/usage/.test(p)) usageDiff++; return note('KEYS', name, p, ka.filter(k => !kb.includes(k)), kb.filter(k => !ka.includes(k))); }
    for (const k of ka) cmp(a[k], b[k], p + '.' + k, name);
    return;
  }
  if (a !== b) note('VALUE', name, p, a, b);
}
const names = Object.keys(m.battles);
for (const name of names) {
  const f = path.join(run, 'out', name + '.jsonl');
  if (!fs.existsSync(f)) { missing.push(name); continue; }
  const A = R.records(R.unpack(base, m.battles[name])), B = R.records(fs.readFileSync(f));
  n++;
  if (A.length !== B.length) { note('RECORDS', name, A.length, B.length); continue; }
  for (let i = 0; i < A.length; i++) {
    if (A[i].rng !== B[i].rng || A[i].round !== B[i].round || A[i].actor !== B[i].actor) { note('META', name, 'turn', i); break; }
    cmp(JSON.parse(A[i].state), JSON.parse(B[i].state), '', name);
  }
}
fs.rmSync(base, { recursive: true, force: true });
console.log(`baseline ${rev} = ${sha}, manifest ${R.sha(Buffer.from(JSON.stringify(m)))}`);
console.log(`battles in baseline ${names.length}, checked ${n}, missing ${missing.length}${missing.length ? ': ' + missing.join(' ') : ''}`);
console.log(`non-text differences ${bad}, usage key differences ${usageDiff}, distinct string changes ${strings.size}`);
[...strings.entries()].sort((a, b) => b[1] - a[1]).slice(0, 25).forEach(([k, v]) => console.log(' ', v, k));
const ok = bad === 0 && missing.length === 0 && n === names.length;
console.log(ok ? 'PASS: text-only against ' + sha : 'FAIL');
process.exitCode = ok ? 0 : 1;
