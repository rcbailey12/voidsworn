// Issue 120 check 120-1/120-2/120-3: seed enumeration of the hunter assignment.
// Runs full run starts through the pinned campaign oracle, the same way the chair enumeration was produced.
//   node nem_assign_enum.js            quick gate: exact constraints only (6 player factions x 500 seeds)
//   node nem_assign_enum.js --full     recorded verification: 6 x 20000 seeds (120,000 run starts), marginals and return rate
'use strict';
const env = require('./env.js');
env.load(String.raw`
toast=function(){}; show=function(){}; modal=function(){}; closeModal=function(){};
globalThis.__ENUM={
  run(seed,fac){
    UID=1; rndSeed(seed); META=defaultMeta(); META.backfilled=1; META.wonFix41=1; SAVED_RUN=null; RUN=null; B=null;
    newRun('vex',fac);
    return {assign:RUN.nemAssign.slice(), foes:RUN.foes.slice()};
  }
};
`);
const args = process.argv.slice(2);
const full = args.includes('--full');
let runs = full ? 20000 : 500;
const ri = args.indexOf('--runs');
if (ri >= 0 && args[ri + 1]) runs = parseInt(args[ri + 1], 10);
const FACS = Array.from(RUN_FACTIONS);
let fails = 0;
const ok = (name, pass, detail) => { console.log((pass ? 'PASS ' : 'FAIL ') + name + (detail ? ' ' + detail : '')); if (!pass) fails++; };
const cell = {}, pooled = {}, ret = {}, two = {}, three = {};
for (const f of FACS) { cell[f] = [{}, {}, {}]; ret[f] = 0; two[f] = 0; three[f] = 0; }
let own = 0, rep12 = 0, rep23 = 0, totalSlots = 0, badLen = 0;
for (const pf of FACS) {
  for (let seed = 1; seed <= runs; seed++) {
    const r = __ENUM.run(seed, pf);
    const a = r.assign;
    if (!Array.isArray(a) || a.length !== 3) { badLen++; continue; }
    for (let i = 0; i < 3; i++) {
      const h = a[i];
      if (h === pf) own++;
      if (!r.foes.includes(h)) badLen++;
      cell[pf][i][h] = (cell[pf][i][h] || 0) + 1;
      pooled[h] = (pooled[h] || 0) + 1;
      totalSlots++;
    }
    if (a[1] === a[0]) rep12++;
    if (a[2] === a[1]) rep23++;
    if (a[2] === a[0]) ret[pf]++;
    const distinct = new Set(a).size;
    if (distinct === 2) two[pf]++;
    if (distinct === 3) three[pf]++;
  }
}
console.log('issue 120 enumeration: ' + runs + ' starts per player faction, ' + (runs * FACS.length) + ' runs, ' + totalSlots + ' story point slots');
ok('120-2 assignment length', badLen === 0, 'bad=' + badLen);
ok('120-2 no own-faction hunter', own === 0, 'own=' + own);
ok('120-2 no H2=H1 repeat', rep12 === 0, 'count=' + rep12);
ok('120-2 no H3=H2 repeat', rep23 === 0, 'count=' + rep23);
if (full) {
  const N = runs;
  const cellTol = Math.ceil(3.2 * Math.sqrt(N * 0.2 * 0.8));
  const poolTol = Math.ceil(3.4 * Math.sqrt((N * FACS.length * 3) * (1 / 6) * (5 / 6)));
  const retTol = Math.ceil(3.3 * Math.sqrt(N * 0.25 * 0.75));
  let worstCell = 0, worstPool = 0, retBad = [], cellBad = [], poolBad = [];
  for (const pf of FACS) for (let sp = 0; sp < 3; sp++) for (const h of FACS) {
    if (h === pf) continue;
    const n = cell[pf][sp][h] || 0, dev = Math.abs(n - N / 5);
    worstCell = Math.max(worstCell, dev);
    if (dev > cellTol) cellBad.push(pf + ' SP' + (sp + 1) + ' ' + h + '=' + n);
  }
  for (const h of FACS) { const n = pooled[h] || 0, dev = Math.abs(n - totalSlots / 6); worstPool = Math.max(worstPool, dev); if (dev > poolTol) poolBad.push(h + '=' + n); }
  for (const pf of FACS) if (Math.abs(ret[pf] - N / 4) > retTol) retBad.push(pf + '=' + ret[pf]);
  ok('120-1 per-cell marginal 1/5', cellBad.length === 0, 'worst dev=' + worstCell + ' tol=' + cellTol + (cellBad.length ? ' bad: ' + cellBad.slice(0, 4).join(', ') : ''));
  ok('120-1 pooled hunter marginal 1/6 over slots', poolBad.length === 0, 'worst dev=' + worstPool + ' tol=' + poolTol + (poolBad.length ? ' bad: ' + poolBad.join(', ') : ''));
  ok('120-3 SP1 returns at SP3 about 1/4', retBad.length === 0, 'tol=' + retTol + (retBad.length ? ' bad: ' + retBad.join(', ') : ''));
  const f = FACS[0];
  ok('120-3 distinct-hunter split 25/75', Math.abs((two[f] + three[f]) - N) === 0 && Math.abs(two[f] - N / 4) <= retTol, 'two=' + two[f] + ' three=' + three[f]);
  for (const pf of FACS) console.log('  marginal ' + pf + ': ' + [0, 1, 2].map(sp => FACS.filter(h => h !== pf).map(h => h + '=' + (cell[pf][sp][h] || 0)).join(' ')).join(' | '));
  console.log('  return at SP3 per faction: ' + FACS.map(pf => pf + '=' + ret[pf]).join(' '));
  console.log('  pooled hunts: ' + FACS.map(h => h + '=' + (pooled[h] || 0)).join(' ') + ' (expected ' + (totalSlots / 6) + ' each)');
}
console.log(fails === 0 ? 'PASS: all issue 120 enumeration checks' : 'FAIL: ' + fails + ' issue 120 enumeration check(s)');
process.exit(fails ? 1 : 0);
