// A3 rules parity: compares the Node oracle's records with the Godot port's, turn by turn.
//   node compare.js scenario <node.jsonl> <godot.jsonl>   per-turn hash; on the first difference, the first field that differs
//   node compare.js same <a.txt> <b.txt>                   files must be identical (PRNG draws)
// Prints PASS or FAIL on the last line. Integers must match exactly; any other number is compared as its 64-bit double (the canonical
// state already carries those as exact hex), so there is no tolerance anywhere.
'use strict';
const fs = require('fs');
const [mode, a, b] = process.argv.slice(2);
const fail = m => { console.log(m); console.log('FAIL'); process.exit(1); };
if (mode === 'same') {
  const A = fs.readFileSync(a, 'utf8').split('\n'), Bv = fs.readFileSync(b, 'utf8').split('\n');
  for (let i = 0; i < Math.max(A.length, Bv.length); i++) if (A[i] !== Bv[i]) fail(`line ${i + 1} differs:\n  node:  ${A[i]}\n  godot: ${Bv[i]}`);
  console.log(`${A.length - 1} lines identical`); console.log('PASS'); process.exit(0);
}
if (mode !== 'scenario') { console.log('usage: node compare.js scenario <node.jsonl> <godot.jsonl> | same <a> <b>'); process.exit(2); }
const read = f => fs.readFileSync(f, 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
const N = read(a), G = read(b);
// first differing field, walking both states in sorted-key order
function diff(x, y, p) {
  if (typeof x !== typeof y || Array.isArray(x) !== Array.isArray(y) || (x === null) !== (y === null)) return { p, x, y };
  if (x && typeof x === 'object') {
    if (Array.isArray(x)) { for (let i = 0; i < Math.max(x.length, y.length); i++) { const d = diff(x[i], y[i], p + '[' + i + ']'); if (d) return d; } return null; }
    const ks = [...new Set([...Object.keys(x), ...Object.keys(y)])].sort();
    for (const k of ks) { const d = diff(x[k], y[k], p + '.' + k); if (d) return d; } return null;
  }
  return x === y ? null : { p, x, y };
}
const show = v => { if (typeof v === 'string' && /^d:[0-9a-f]{16}$/.test(v)) { const d = Buffer.from(v.slice(2), 'hex').readDoubleBE(); return v + ' (' + d + ')'; } return JSON.stringify(v); };
for (let i = 0; i < Math.max(N.length, G.length); i++) {
  const n = N[i], g = G[i];
  if (!n || !g) fail(`record count differs: node ${N.length}, godot ${G.length} (first missing at record ${i})`);
  const name = id => { const u = JSON.parse(n.state).units.find(x => x.id === id); return u ? `${id} (${u.side} ${u.tpl})` : id; };
  if (n.turn != g.turn || n.actor !== g.actor) fail(`turn ${n.turn}: order differs: node says ${n.actor}, godot says ${g.actor}`);
  if (n.hash !== g.hash || Number(n.rng) !== Number(g.rng)) {
    const d = diff(JSON.parse(n.state), JSON.parse(g.state), 'state');
    const units = JSON.parse(n.state).units; let where = d ? d.p : '(no field differs; only the PRNG state)';
    const m = d && d.p.match(/^state\.units\[(\d+)\]/); if (m && units[+m[1]]) where += `  = ${units[+m[1]].id} (${units[+m[1]].side} ${units[+m[1]].tpl})`;
    fail(`turn ${n.turn} (round ${n.round}, after ${name(n.actor)}): first difference\n  field: ${where}\n  node:  ${d ? show(d.x) : ''}\n  godot: ${d ? show(d.y) : ''}\n  PRNG state: node ${n.rng}, godot ${g.rng}${n.rng != g.rng ? ' (the random stream has diverged)' : ''}`);
  }
}
const last = N[N.length - 1];
console.log(`${N.length} records identical (state hash and PRNG state after every action, activation and round), result: ${last.actor}`);
console.log('PASS');
