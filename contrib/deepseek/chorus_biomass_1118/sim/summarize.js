// summarize.js - issue 1085. Reads the raw shard JSON files and writes
// results.csv (one row per setup) plus results_sectors.csv (fleet and hull
// after each sector) and prints a short table for the README.
// Usage: node summarize.js baseline.json biomass.json biomass_kill.json
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

// Last post-battle state in each sector the run fought in.
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
  const allRuns = d.runs;
  const n = runs.length;
  const wins = runs.filter(r => r.won).length;
  const [wr, wrLo, wrHi] = wilson(wins, n);
  const sectors = runs.map(r => r.sectorReached);
  const reach2 = runs.filter(r => r.sectorReached >= 2).length / n;
  const reach3 = runs.filter(r => r.sectorReached >= 3).length / n;
  const spirals = runs.filter(r => r.spiral).length;
  const starves = runs.filter(r => r.starve).length;
  const spiralsFull = runs.filter(r => r.spiralFull).length;
  const starvesFull = runs.filter(r => r.starveFull).length;
  const twoLoss = runs.filter(r => r.twoLosses).length;
  const twoSet = runs.filter(r => r.twoSetbacks).length;
  const incomes = runs.flatMap(r => r.incomes || []);
  const im = mean(incomes), isd = sd(incomes);
  const secRows = {};
  for (const s of [1, 2, 3]) {
    const vals = runs.map(r => sectorEnds(r)[s]).filter(Boolean);
    secRows[s] = {
      n: vals.length,
      ships: mean(vals.map(v => v.ships)),
      hull: mean(vals.map(v => v.hull)),
      maxHull: mean(vals.map(v => v.maxHull)),
      frac: mean(vals.map(v => v.frac)),
    };
  }
  setups.push({
    setup: d.meta.setup, meta: d.meta, n, wins, wr, wrLo, wrHi,
    meanSector: mean(sectors), reach2, reach3,
    spiral: spirals / n, starve: starves / n, twoLoss: twoLoss / n, twoSet: twoSet / n,
    spiralFull: spiralsFull / n, starveFull: starvesFull / n,
    spiralN: spirals, starveN: starves, spiralsFullN: spiralsFull, starvesFullN: starvesFull, twoLossN: twoLoss, twoSetN: twoSet,
    incomeN: incomes.length, incomeMean: im, incomeSD: isd, incomeMin: incomes.length ? Math.min(...incomes) : 0, incomeMax: incomes.length ? Math.max(...incomes) : 0,
    incomeP10: pct(incomes, .1), incomeP50: pct(incomes, .5), incomeP90: pct(incomes, .9),
    errors: allRuns.length - n, timeouts: allRuns.reduce((a, r) => a + (r.timeouts || 0), 0),
    secRows, runs,
  });
}

// Paired deltas against the baseline setup, same seeds.
const base = setups.find(s => s.setup === 'baseline');
function pairedDelta(sel, field) {
  if (!base) return null;
  const bm = new Map(base.runs.map(r => [r.seed, r]));
  const deltas = [];
  for (const r of sel.runs) {
    const b = bm.get(r.seed); if (!b) continue;
    deltas.push(field(r) - field(b));
  }
  return { n: deltas.length, mean: mean(deltas), ci: meanCI(deltas) };
}

const rows = [['setup', 'runs', 'wins', 'winRate', 'winCIlo', 'winCIhi', 'pairedWinDelta', 'pairedWinLo', 'pairedWinHi', 'pairedSectorDelta', 'pairedSectorLo', 'pairedSectorHi', 'pairedS3Delta', 'pairedS3Lo', 'pairedS3Hi', 'meanSector', 'reachS2', 'reachS3',
  'shipsS1', 'hullPctS1', 'shipsS2', 'hullPctS2', 'shipsS3', 'hullPctS3',
  'spiralShare', 'spiralCount', 'starveShare', 'starveCount', 'spiralFullShare', 'spiralFullCount', 'starveFullShare', 'starveFullCount', 'twoLossShare', 'twoLossCount', 'twoSetbackShare', 'twoSetbackCount', 'battles', 'incomeMean', 'incomeSD', 'incomeMin', 'incomeP10', 'incomeP50', 'incomeP90', 'incomeMax', 'errors', 'timeouts']];
for (const s of setups) {
  const pw = pairedDelta(s, r => r.won ? 1 : 0);
  const ps = pairedDelta(s, r => r.sectorReached);
  const p3 = pairedDelta(s, r => r.sectorReached >= 3 ? 1 : 0);
  rows.push([s.setup, s.n, s.wins, f2(s.wr), f2(s.wrLo), f2(s.wrHi),
    pw ? f2(pw.mean) : '', pw ? f2(pw.ci[1]) : '', pw ? f2(pw.ci[2]) : '',
    ps ? f2(ps.mean) : '', ps ? f2(ps.ci[1]) : '', ps ? f2(ps.ci[2]) : '',
    p3 ? f2(p3.mean) : '', p3 ? f2(p3.ci[1]) : '', p3 ? f2(p3.ci[2]) : '',
    f2(s.meanSector), f2(s.reach2), f2(s.reach3),
    f2(s.secRows[1].ships), f2(s.secRows[1].frac), f2(s.secRows[2].ships), f2(s.secRows[2].frac), f2(s.secRows[3].ships), f2(s.secRows[3].frac),
    f2(s.spiral), s.spiralN, f2(s.starve), s.starveN, f2(s.spiralFull), s.spiralsFullN, f2(s.starveFull), s.starvesFullN, f2(s.twoLoss), s.twoLossN, f2(s.twoSet), s.twoSetN, s.incomeN, f2(s.incomeMean), f2(s.incomeSD), f2(s.incomeMin), f2(s.incomeP10), f2(s.incomeP50), f2(s.incomeP90), f2(s.incomeMax), s.errors, s.timeouts]);
}

const outCsv = rows.map(r => r.join(',')).join('\n') + '\n';
const csvPath = path.join(__dirname, '..', 'results.csv');
fs.writeFileSync(csvPath, outCsv);

const secRows = [['setup', 'sector', 'runs', 'fleet', 'hullMean', 'maxHullMean', 'hullPct']];
for (const s of setups) for (const k of [1, 2, 3]) {
  const v = s.secRows[k]; secRows.push([s.setup, k, v.n, f2(v.ships), f2(v.hull), f2(v.maxHull), f2(v.frac)]);
}
fs.writeFileSync(path.join(__dirname, '..', 'results_sectors.csv'), secRows.map(r => r.join(',')).join('\n') + '\n');

// One row per run and setup, so anyone can recount the spiral, starvation and
// winner counts. spiralFull and starveFull are run 1's full repair pricing on
// the same runs, for comparison. recoveryTrace is one entry per battle:
// sector:result:lostShips:worstMissing/worstMax:money:priceMult:repairHull:repairCost:fullCost:cheapestHull:unrecoverable:unrecoverableFull
const runRows = [['setup', 'seed', 'admiral', 'won', 'sectorReached', 'battles', 'wins', 'losses', 'retreats', 'timeouts',
  'spiral', 'starve', 'spiralFull', 'starveFull', 'twoLosses', 'twoSetbacks', 'incomeN', 'incomeMean', 'incomeSD', 'incomeMin', 'incomeMax',
  'creditsFinal', 'biomassFinal', 'finalFleet', 'recoveryTrace']];
const r2 = x => Math.round(x * 100) / 100;
for (const s of setups) for (const r of s.runs) {
  const bs = r.battles || [];
  const wins = bs.filter(b => b.result === 'win').length;
  const losses = bs.filter(b => b.result === 'loss').length;
  const retreats = bs.filter(b => b.result === 'retreat').length;
  const inc = r.incomes || [];
  const trace = (r.recovery || []).map(e => [e.s, e.res, e.lost, e.worst + '/' + e.worstMax, e.money, e.pm, e.repairHull, e.repairCost, e.fullCost, e.cheapest, e.unrec, e.unrecFull].join(':')).join(';');
  runRows.push([s.setup, r.seed, r.admiral || '', r.won ? 1 : 0, r.sectorReached, bs.length, wins, losses, retreats, r.timeouts || 0,
    r.spiral ? 1 : 0, r.starve ? 1 : 0, r.spiralFull ? 1 : 0, r.starveFull ? 1 : 0, r.twoLosses ? 1 : 0, r.twoSetbacks ? 1 : 0,
    inc.length, inc.length ? r2(mean(inc)) : '', inc.length > 1 ? r2(sd(inc)) : '', inc.length ? Math.min(...inc) : '', inc.length ? Math.max(...inc) : '',
    r.creditsFinal == null ? '' : r.creditsFinal, r.biomassFinal == null ? '' : r.biomassFinal, (r.finalFleet || []).join(' '), trace]);
}
fs.writeFileSync(path.join(__dirname, '..', 'results_runs.csv'), runRows.map(r => r.join(',')).join('\n') + '\n');

console.log('setup            n   win% (95%)       paired win delta (95%)      sector  paired sector          reachS3  sp1  sp2  st1  st2  twoLoss  income mean+-sd  [p10..p90]  errors');
for (const s of setups) {
  const pw = pairedDelta(s, r => r.won ? 1 : 0);
  const ps = pairedDelta(s, r => r.sectorReached);
  console.log(
    s.setup.padEnd(14) + String(s.n).padStart(4) + '  ' + pct1(s.wr).padStart(6) + ' [' + pct1(s.wrLo) + ',' + pct1(s.wrHi) + ']' +
    '  ' + (pw ? (pw.mean >= 0 ? '+' : '') + (pw.mean * 100).toFixed(1) + ' [' + (pw.ci[1] * 100).toFixed(1) + ',' + (pw.ci[2] * 100).toFixed(1) + ']' : '  -').padStart(22) +
    '  ' + f2(s.meanSector).toFixed(2).padStart(6) + '  ' + (ps ? (ps.mean >= 0 ? '+' : '') + ps.mean.toFixed(2) + ' [' + ps.ci[1].toFixed(2) + ',' + ps.ci[2].toFixed(2) + ']' : '-').padStart(20) +
    '  ' + pct1(s.reach3).padStart(6) + '  ' + pct1(s.spiralFull).padStart(6) + '  ' + pct1(s.spiral).padStart(6) + '  ' + pct1(s.starveFull).padStart(6) + '  ' + pct1(s.starve).padStart(6) + '  ' + pct1(s.twoLoss).padStart(6) + '  ' + f2(s.incomeMean).toFixed(0).padStart(5) + '+-' + f2(s.incomeSD).toFixed(0).padEnd(4) +
    ' [' + f2(s.incomeP10).toFixed(0) + '..' + f2(s.incomeP90).toFixed(0) + ']' + '  ' + s.errors);
}
console.log('sector ends (last post-battle state in that sector):');
for (const s of setups) for (const k of [1, 2, 3]) {
  const v = s.secRows[k];
  console.log('  ' + (s.setup + ' S' + k).padEnd(16) + ' n ' + String(v.n).padStart(4) + '  fleet ' + f2(v.ships).toFixed(2) + '  hull ' + f2(v.hull).toFixed(0) + '/' + f2(v.maxHull).toFixed(0) + ' (' + pct1(v.frac) + ')');
}
console.log('wrote', csvPath);
