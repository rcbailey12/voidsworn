// Issue 1178: summarise sim_1178.js records. Usage: node summarize_1178.js <label>=<a.json,b.json> [<label>=...]
'use strict';
const pct = (a, b) => b ? (100 * a / b).toFixed(1) + '%' : 'n/a';
const mean = xs => xs.length ? (xs.reduce((a, b) => a + b, 0) / xs.length) : NaN;
for (const arg of process.argv.slice(2)) {
  const [label, files] = arg.split('=');
  const R = files.split(',').flatMap(f => require(require('path').resolve(f)));
  const n = R.length, w = R.filter(r => r.won).length, L = R.filter(r => !r.won);
  const ls = [1, 2, 3].map(s => L.filter(r => r.lossSector === s).length);
  const boss = R.filter(r => r.bossCredits != null);
  console.log(`${label}: runs ${n}, win ${pct(w, n)}, losses S1/S2/S3 ${ls.join('/')} (share ${ls.map(x => pct(x, L.length)).join(' / ')}), lose rate per run S1/S2/S3 ${ls.map(x => pct(x, n)).join(' / ')}`);
  const reach3 = R.filter(r => r.sector >= 3).length;
  console.log(`  reach S3 ${pct(reach3, n)}, win given S3 ${pct(w, reach3)}, credits at final boss ${mean(boss.map(r => r.bossCredits)).toFixed(1)} (n ${boss.length}), late buys ${mean(R.map(r => r.lateBuys)).toFixed(2)}/run, late spend ${mean(R.map(r => r.lateSpent)).toFixed(1)}/run, timeouts ${R.reduce((a, r) => a + r.timeouts, 0)}, errors ${R.filter(r => r.errors.length).length}`);
  const facs = [...new Set(R.map(r => r.fac))];
  console.log('  by faction: ' + facs.map(f => { const F = R.filter(r => r.fac === f); return `${f} ${pct(F.filter(r => r.won).length, F.length)}`; }).join(', '));
  const ch = R.filter(r => r.fac === 'chorus'), it = R.filter(r => r.fac === 'ithar'), de = R.filter(r => r.fac === 'deathless');
  if (R.some(r => r.bio || r.cullet || r.cores)) console.log(`  economies: chorus biomass earned ${mean(ch.map(r => r.bio)).toFixed(0)}/run; ithar cullet ${mean(it.map(r => r.cullet)).toFixed(1)}/run; deathless cores ${mean(de.map(r => r.cores)).toFixed(2)}/run, regrown ${mean(de.map(r => r.coreRestores)).toFixed(2)}/run`);
}
