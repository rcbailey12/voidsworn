// summarize.js - issue 1086. Reads the raw per-setup JSON files and writes
// results.csv (one row per setup) plus results_sectors.csv (fleet and hull after
// each sector), then prints one short table per faction for the README.
// Paired deltas are against that faction's "today" setup on the same seeds.
// Usage: node summarize.js file1.json file2.json ...
'use strict';
const fs = require('fs');
const path = require('path');

const files = process.argv.slice(2);
const Z = 1.96;
const mean = xs => xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0;
const sd = xs => { if (xs.length < 2) return 0; const m = mean(xs); return Math.sqrt(xs.reduce((a, b) => a + (b - m) * (b - m), 0) / (xs.length - 1)); };
const pct = (xs, p) => { if (!xs.length) return 0; const s = [...xs].sort((a, b) => a - b); const i = (s.length - 1) * p; const lo = Math.floor(i), hi = Math.ceil(i); return lo === hi ? s[lo] : s[lo] + (s[hi] - s[lo]) * (i - lo); };
const f2 = x => Math.round(x * 100) / 100;
const pct1 = x => (x * 100).toFixed(1) + '%';
function wilson(k, n) { if (!n) return [0, 0, 0]; const p = k / n, d = 1 + Z * Z / n, c = p + Z * Z / (2 * n), m = Z * Math.sqrt(p * (1 - p) / n + Z * Z / (4 * n * n)); return [p, Math.max(0, (c - m) / d), Math.min(1, (c + m) / d)]; }
function meanCI(xs) { const m = mean(xs); if (xs.length < 2) return [m, m, m]; const e = Z * sd(xs) / Math.sqrt(xs.length); return [m, m - e, m + e]; }

function sectorEnds(run) {
  const out = {};
  for (const e of run.econ) if (e.at === 'postbattle') {
    out[e.s] = { ships: e.ships, hull: e.hull, maxHull: e.maxHull, frac: e.maxHull ? e.hull / e.maxHull : 0 };
  }
  return out;
}

const setups = [];
for (const f of files) {
  const d = JSON.parse(fs.readFileSync(f, 'utf8'));
  const runs = d.runs.filter(r => r.errors.length === 0);
  const n = runs.length;
  const wins = runs.filter(r => r.won).length;
  const [wr, wrLo, wrHi] = wilson(wins, n);
  const sectors = runs.map(r => r.sectorReached);
  const reach2 = runs.filter(r => r.sectorReached >= 2).length / n;
  const reach3 = runs.filter(r => r.sectorReached >= 3).length / n;
  const spirals = runs.filter(r => r.spiral).length;
  const starves = runs.filter(r => r.starve).length;
  const twoLoss = runs.filter(r => r.twoLosses).length;
  const twoSet = runs.filter(r => r.twoSetbacks).length;
  const incomes = runs.flatMap(r => r.incomes || []);
  const sum = k => runs.reduce((a, r) => a + (r[k] || 0), 0);
  const secRows = {};
  for (const s of [1, 2, 3]) {
    const vals = runs.map(r => sectorEnds(r)[s]).filter(Boolean);
    secRows[s] = { n: vals.length, ships: mean(vals.map(v => v.ships)), hull: mean(vals.map(v => v.hull)), maxHull: mean(vals.map(v => v.maxHull)), frac: mean(vals.map(v => v.frac)) };
  }
  setups.push({
    setup: d.meta.setup, fac: d.meta.fac, ge: d.meta.ge || {}, meta: d.meta, n, wins, wr, wrLo, wrHi,
    meanSector: mean(sectors), reach2, reach3,
    spiral: spirals / n, starve: starves / n, twoLoss: twoLoss / n, twoSet: twoSet / n,
    spiralN: spirals, starveN: starves, twoLossN: twoLoss, twoSetN: twoSet,
    incomeN: incomes.length, incomeMean: mean(incomes), incomeSD: sd(incomes),
    incomeP10: pct(incomes, .1), incomeP50: pct(incomes, .5), incomeP90: pct(incomes, .9),
    errors: d.runs.length - n, timeouts: runs.reduce((a, r) => a + (r.timeouts || 0), 0),
    cullet: sum('culletEarned'), slotsBought: sum('slotsBought'), slotQueued: sum('slotRestoresQueued'), slotRestored: sum('slotRestored'),
    cores: sum('coresEarned'), coreRestored: sum('coreRestored'), commissions: sum('commissionsStarted'),
    secRows, runs,
  });
}

const bases = {};
for (const f of ['ithar', 'deathless']) bases[f] = setups.find(s => s.fac === f && s.setup === f + '_today');
function pairedDelta(sel, base, field) {
  if (!base) return null;
  const bm = new Map(base.runs.map(r => [r.seed, r]));
  const deltas = [];
  for (const r of sel.runs) { const b = bm.get(r.seed); if (!b) continue; deltas.push(field(r) - field(b)); }
  return { n: deltas.length, mean: mean(deltas), ci: meanCI(deltas) };
}

const rows = [['fac', 'setup', 'runs', 'wins', 'winRate', 'winCIlo', 'winCIhi', 'pairedWinDelta', 'pairedWinLo', 'pairedWinHi', 'pairedSectorDelta', 'pairedSectorLo', 'pairedSectorHi', 'pairedS3Delta', 'pairedS3Lo', 'pairedS3Hi', 'meanSector', 'reachS2', 'reachS3',
  'shipsS1', 'hullPctS1', 'shipsS2', 'hullPctS2', 'shipsS3', 'hullPctS3',
  'spiralShare', 'spiralCount', 'starveShare', 'starveCount', 'twoLossShare', 'twoLossCount', 'twoSetbackShare', 'twoSetbackCount',
  'battles', 'incomeMean', 'incomeSD', 'incomeP10', 'incomeP50', 'incomeP90',
  'culletEarned', 'slotsBought', 'slotRestoresQueued', 'slotRestored', 'coresEarned', 'coreRestored', 'commissionsStarted', 'errors', 'timeouts']];
for (const s of setups) {
  const base = bases[s.fac];
  const pw = pairedDelta(s, base, r => r.won ? 1 : 0);
  const ps = pairedDelta(s, base, r => r.sectorReached);
  const p3 = pairedDelta(s, base, r => r.sectorReached >= 3 ? 1 : 0);
  rows.push([s.fac, s.setup, s.n, s.wins, f2(s.wr), f2(s.wrLo), f2(s.wrHi),
    pw ? f2(pw.mean) : '', pw ? f2(pw.ci[1]) : '', pw ? f2(pw.ci[2]) : '',
    ps ? f2(ps.mean) : '', ps ? f2(ps.ci[1]) : '', ps ? f2(ps.ci[2]) : '',
    p3 ? f2(p3.mean) : '', p3 ? f2(p3.ci[1]) : '', p3 ? f2(p3.ci[2]) : '',
    f2(s.meanSector), f2(s.reach2), f2(s.reach3),
    f2(s.secRows[1].ships), f2(s.secRows[1].frac), f2(s.secRows[2].ships), f2(s.secRows[2].frac), f2(s.secRows[3].ships), f2(s.secRows[3].frac),
    f2(s.spiral), s.spiralN, f2(s.starve), s.starveN, f2(s.twoLoss), s.twoLossN, f2(s.twoSet), s.twoSetN,
    s.incomeN, f2(s.incomeMean), f2(s.incomeSD), f2(s.incomeP10), f2(s.incomeP50), f2(s.incomeP90),
    s.cullet, s.slotsBought, s.slotQueued, s.slotRestored, s.cores, s.coreRestored, s.commissions, s.errors, s.timeouts]);
}
const outDir = path.join(__dirname, '..');
fs.writeFileSync(path.join(outDir, 'results.csv'), rows.map(r => r.join(',')).join('\n') + '\n');

const secRows = [['fac', 'setup', 'sector', 'runs', 'fleet', 'hullMean', 'maxHullMean', 'hullPct']];
for (const s of setups) for (const k of [1, 2, 3]) {
  const v = s.secRows[k]; secRows.push([s.fac, s.setup, k, v.n, f2(v.ships), f2(v.hull), f2(v.maxHull), f2(v.frac)]);
}
fs.writeFileSync(path.join(outDir, 'results_sectors.csv'), secRows.map(r => r.join(',')).join('\n') + '\n');

function printGroup(fac, label) {
  const group = setups.filter(s => s.fac === fac);
  const base = bases[fac];
  console.log('\n=== ' + label + ' (' + fac + ') ===');
  console.log('setup'.padEnd(20) + 'n   win% (95%)        paired win (95%)        sector  paired sector        reachS3  spiral  starve  income mean+-sd [p10..p90]');
  for (const s of group) {
    const pw = pairedDelta(s, base, r => r.won ? 1 : 0);
    const ps = pairedDelta(s, base, r => r.sectorReached);
    console.log(
      s.setup.padEnd(20) + String(s.n).padStart(4) + '  ' + pct1(s.wr).padStart(6) + ' [' + pct1(s.wrLo) + ',' + pct1(s.wrHi) + ']' +
      '  ' + (pw ? (pw.mean >= 0 ? '+' : '') + (pw.mean * 100).toFixed(1) + ' [' + (pw.ci[1] * 100).toFixed(1) + ',' + (pw.ci[2] * 100).toFixed(1) + ']' : '-').padStart(22) +
      '  ' + f2(s.meanSector).toFixed(2).padStart(6) + '  ' + (ps ? (ps.mean >= 0 ? '+' : '') + ps.mean.toFixed(2) + ' [' + ps.ci[1].toFixed(2) + ',' + ps.ci[2].toFixed(2) + ']' : '-').padStart(20) +
      '  ' + pct1(s.reach3).padStart(6) + '  ' + pct1(s.spiral).padStart(6) + '  ' + pct1(s.starve).padStart(6) + '  ' + f2(s.incomeMean).toFixed(0).padStart(5) + '+-' + f2(s.incomeSD).toFixed(0).padEnd(4) +
      ' [' + f2(s.incomeP10).toFixed(0) + '..' + f2(s.incomeP90).toFixed(0) + ']');
  }
  console.log('sector ends (last post-battle state in that sector):');
  for (const s of group) for (const k of [1, 2, 3]) {
    const v = s.secRows[k];
    console.log('  ' + (s.setup + ' S' + k).padEnd(26) + ' n ' + String(v.n).padStart(4) + '  fleet ' + f2(v.ships).toFixed(2) + '  hull ' + f2(v.hull).toFixed(0) + '/' + f2(v.maxHull).toFixed(0) + ' (' + pct1(v.frac) + ')');
  }
}
printGroup('ithar', 'Glasswrights');
printGroup('deathless', 'Eclipse');
console.log('\nwrote', path.join(outDir, 'results.csv'));
