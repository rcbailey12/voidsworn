// Issue 1178: summarise sim_1178.js records. Usage: node summarize_1178.js <label>=<a.json,b.json> [<label>=...]
'use strict';
const pct = (a, b) => b ? (100 * a / b).toFixed(1) + '%' : 'n/a';
const mean = xs => xs.length ? (xs.reduce((a, b) => a + b, 0) / xs.length) : NaN;
for (const arg of (process.argv[2] === "--paired" ? [] : process.argv.slice(2))) {
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
// Paired mode: node summarize_1178.js --paired <before a.json,b.json> <after a.json,b.json>
// Seeds reaching the final boss in both arms: credits on entering it, before and after, and the paired difference.
if (process.argv[2] === '--paired') {
  const load = f => f.split(',').flatMap(x => require(require('path').resolve(x)));
  const A = load(process.argv[3]), B = load(process.argv[4]), key = r => r.fac + ':' + r.seed;
  const bm = new Map(B.map(r => [key(r), r]));
  const both = A.filter(r => r.bossCredits != null && bm.get(key(r)) && bm.get(key(r)).bossCredits != null);
  const d = both.map(r => bm.get(key(r)).bossCredits - r.bossCredits), m = mean(d);
  const sd = Math.sqrt(mean(d.map(x => (x - m) ** 2))), se = sd / Math.sqrt(d.length || 1);
  const mb = mean(both.map(r => r.bossCredits)), ma = mean(both.map(r => bm.get(key(r)).bossCredits));
  console.log(`  paired (seeds reaching the boss in both arms, n ${both.length}): before ${mb.toFixed(1)}, after ${ma.toFixed(1)}, change ${m.toFixed(1)} (95% ${(m - 1.96 * se).toFixed(1)} to ${(m + 1.96 * se).toFixed(1)}), ${(100 * m / mb).toFixed(1)}%`);
  console.log(`  boss reached: before ${A.filter(r => r.bossCredits != null).length}, after ${B.filter(r => r.bossCredits != null).length}; late spend on those paired seeds after ${mean(both.map(r => bm.get(key(r)).lateSpent)).toFixed(1)}/run`);
}
