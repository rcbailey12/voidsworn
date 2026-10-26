// G3 campaign parity: compares the Node (oracle) and Godot records of one seeded run, step by step.
//   node compare_campaign.js <golden.jsonl> <godot.jsonl>
// Exit 0 and one summary line when every step matches; otherwise names the first step, what differs (the click, the buttons on
// screen, the PRNG state, or a part of the state: run, map, meta, t = screen transients, saved = the saved copy) and, for a state
// part, the first field that differs with both values. No tolerance anywhere: numbers compare as exact doubles (canonical form).
'use strict';
const fs = require('fs');
const read = p => fs.readFileSync(p, 'utf8').trim().split('\n').filter(Boolean).map(l => JSON.parse(l));
const [ga, gb] = [read(process.argv[2]), read(process.argv[3])];
const PARTS = ['run', 'map', 'meta', 't', 'saved'];
const latest = (recs, upto, k) => { for (let i = upto; i >= 0; i--) if (recs[i][k] !== undefined) return recs[i][k]; return null; };
function firstDiff(a, b, path) {
  if (JSON.stringify(a) === JSON.stringify(b)) return null;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    const ks = Array.isArray(a) ? [...Array(Math.max(a.length, b.length)).keys()] : [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
    for (const k of ks) { const d = firstDiff(a[k], b[k], path + (Array.isArray(a) ? '[' + k + ']' : '.' + k)); if (d) return d; }
  }
  return { path, a, b };
}
const show = v => { const s = JSON.stringify(v); return s === undefined ? 'missing' : s.length > 300 ? s.slice(0, 300) + '...' : s; };
const ctx = (recs, i) => recs.slice(Math.max(0, i - 6), i + 1).map(r => r.act + (r.arg ? ':' + r.arg : '')).join(' ');
const n = Math.max(ga.length, gb.length);
for (let i = 0; i < n; i++) {
  const A = ga[i], B = gb[i];
  if (!A || !B) { console.log('FAIL: the runs have different lengths (JS ' + ga.length + ' records, Godot ' + gb.length + '); first missing record ' + i); process.exit(1); }
  const fail = (what, a, b) => { console.log('FAIL at step ' + A.i + ' (after ' + ctx(ga, i) + '): ' + what + '\n  JS:    ' + show(a) + '\n  Godot: ' + show(b)); process.exit(1); };
  if (A.act !== B.act || A.arg !== B.arg) fail('the bot clicked something else', A.act + ':' + A.arg, B.act + ':' + B.arg);
  if (A.act === 'end' || A.act === 'cap' || A.act === 'stuck' || A.act === 'noact') continue;
  if (A.acts !== B.acts) { const xa = A.acts.split('|'), xb = B.acts.split('|'); let j = 0; while (j < xa.length && xa[j] === xb[j]) j++; fail('the buttons on screen differ (button ' + j + ')', xa.slice(j, j + 4).join(' | '), xb.slice(j, j + 4).join(' | ')); }
  for (const k of PARTS) if (A.h[k] !== B.h[k]) { const ta = latest(ga, i, k), tb = latest(gb, i, k); const d = firstDiff(JSON.parse(ta), JSON.parse(tb), k); fail('state "' + k + '" differs at ' + (d ? d.path : '?'), d && d.a, d && d.b); }
  if (A.rng !== B.rng) fail('the PRNG state differs', A.rng, B.rng);
}
const last = ga[ga.length - 1];
console.log('PASS: ' + ga.length + ' steps identical, ended with "' + last.act + '"');
