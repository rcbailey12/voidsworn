// Issue 1484: compare sim_1484.js records, before (main) and after (this branch), same seeds.
// Usage: node tools/late_run_1484/summarize_1484.js <label> <before.json> <after.json> [<label> <before.json> <after.json> ...]
'use strict';
const pct = (a, b) => b ? (100 * a / b).toFixed(1) + '%' : 'n/a';
const mean = xs => xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0;
const KINDS = ['mod', 'track', 'late', 'reroll'];
const args = process.argv.slice(2);
for (let i = 0; i + 2 < args.length + 0 && i < args.length; i += 3) {
  const [label, fa, fb] = args.slice(i, i + 3);
  const A = require(require('path').resolve(fa)), B = require(require('path').resolve(fb));
  const bm = new Map(B.map(r => [r.fac + ':' + r.seed, r]));
  const pairs = A.filter(r => bm.has(r.fac + ':' + r.seed)).map(r => [r, bm.get(r.fac + ':' + r.seed)]);
  const wa = A.filter(r => r.won).length, wb = B.filter(r => r.won).length;
  const up = pairs.filter(([a, b]) => !a.won && b.won).length, down = pairs.filter(([a, b]) => a.won && !b.won).length;
  const errs = [...A, ...B].filter(r => r.errors && r.errors.length).length;
  const ls = R => [1, 2, 3].map(s => R.filter(r => !r.won && r.lossSector === s).length).join('/');
  console.log(`${label}: runs ${A.length} / ${B.length}, win ${pct(wa, A.length)} -> ${pct(wb, B.length)} (paired: ${up} lost->won, ${down} won->lost), losses S1/S2/S3 ${ls(A)} -> ${ls(B)}, runs with errors ${errs}`);
  console.log(`  pays: before ${JSON.stringify(A[0] && A[0].pays)}, after ${JSON.stringify(B[0] && B[0].pays)}`);
  for (const [name, R] of [['before', A], ['after', B]]) {
    const row = KINDS.map(k => { const t = { opp: 0, try: 0, ok: 0, bio: 0, cred: 0, fit: 0 };
      for (const r of R) { const x = (r.buys || {})[k]; if (x) for (const f in t) t[f] += x[f] || 0; }
      return `${k} opp ${(t.opp / R.length).toFixed(2)} try ${(t.try / R.length).toFixed(2)} ok ${(t.ok / R.length).toFixed(2)}${k === 'mod' ? ` fitted ${(t.fit / R.length).toFixed(2)}` : ''} debit bio ${(t.bio / R.length).toFixed(1)} cred ${(t.cred / R.length).toFixed(1)}`; });
    console.log(`  ${name} per run: ` + row.join('; '));
    const boss = R.filter(r => r.bossBio != null);
    console.log(`  ${name}: reach S3 ${pct(R.filter(r => r.sector >= 3).length, R.length)}, at final boss biomass ${mean(boss.map(r => r.bossBio)).toFixed(1)} credits ${mean(boss.map(r => r.bossCredits)).toFixed(1)} (n ${boss.length}), biomass earned ${mean(R.map(r => r.bio)).toFixed(0)}/run`);
  }
}
