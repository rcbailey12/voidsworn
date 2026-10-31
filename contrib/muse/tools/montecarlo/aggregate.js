// aggregate.js - merges shard JSON files and computes the reported statistics
// with confidence intervals. Usage: node aggregate.js raw/main_*.json > out.txt
// Also writes aggregate.json next to this script for the report builder.
'use strict';
const fs = require('fs');
const path = require('path');

const files = process.argv.slice(2);
const runs = [];
for (const f of files) { const d = JSON.parse(fs.readFileSync(f, 'utf8')); for (const r of d.runs) runs.push(r); }

const Z = 1.96;
function wilson(k, n) { if (!n) return [0, 0, 0]; const p = k / n, d = 1 + Z * Z / n, c = p + Z * Z / (2 * n), m = Z * Math.sqrt(p * (1 - p) / n + Z * Z / (4 * n * n)); return [p, Math.max(0, (c - m) / d), Math.min(1, (c + m) / d)]; }
function meanCI(xs) { xs = xs.filter(x => typeof x === 'number' && isFinite(x)); if (!xs.length) return [0, 0, 0, 0]; const m = xs.reduce((a, b) => a + b, 0) / xs.length; if (xs.length < 2) return [m, m, m, xs.length]; const sd = Math.sqrt(xs.reduce((a, b) => a + (b - m) * (b - m), 0) / (xs.length - 1)); const e = Z * sd / Math.sqrt(xs.length); return [m, m - e, m + e, xs.length]; }
function median(xs) { if (!xs.length) return 0; const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; }
const pc = (x, d = 1) => (x * 100).toFixed(d) + '%';
const f2 = x => +x.toFixed(2);

const out = { totalRuns: runs.length, errors: runs.filter(r => r.errors.length).length, timeouts: runs.reduce((a, r) => a + r.timeouts, 0) };

function winBlock(list) { const n = list.length, w = list.filter(r => r.won).length, [p, lo, hi] = wilson(w, n); return { n, wins: w, rate: f2(p), ci: [f2(lo), f2(hi)] }; }
out.overall = winBlock(runs);
out.byFaction = {}; out.byAI = {};
for (const r of runs) { (out.byFaction[r.fac] = out.byFaction[r.fac] || []).push(r); (out.byAI[r.ai] = out.byAI[r.ai] || []).push(r); }
for (const k in out.byFaction) out.byFaction[k] = winBlock(out.byFaction[k]);
for (const k in out.byAI) out.byAI[k] = winBlock(out.byAI[k]);

out.reach = {};
for (const s of [2, 3]) { const k = runs.filter(r => r.sectorReached >= s).length, [p, lo, hi] = wilson(k, runs.length); out.reach['S' + s] = { n: k, rate: f2(p), ci: [f2(lo), f2(hi)] }; }

const bmap = new Map();
for (const r of runs) for (const b of r.battles) { const key = b.s + ':' + b.kind + (b.nem ? ':nem' : ''); if (!bmap.has(key)) bmap.set(key, []); bmap.get(key).push(b); }
out.battleClasses = {};
for (const [key, bs] of [...bmap.entries()].sort()) {
  const w = bs.filter(b => b.res === 'win').length, [p, lo, hi] = wilson(w, bs.length);
  const [lm, llo, lhi] = meanCI(bs.map(b => b.lost)); const [rm, rlo, rhi] = meanCI(bs.map(b => b.rounds));
  out.battleClasses[key] = { n: bs.length, winRate: f2(p), winCI: [f2(lo), f2(hi)], lostMean: f2(lm), lostCI: [f2(llo), f2(lhi)], roundsMean: f2(rm), roundsCI: [f2(rlo), f2(rhi)], timeouts: bs.filter(b => b.res === 'timeout').length };
}

const nmap = new Map();
for (const r of runs) for (const m of r.nem) { if (!nmap.has(m.meeting)) nmap.set(m.meeting, []); nmap.get(m.meeting).push(m); }
out.nemesis = {};
for (const [mt, ms] of [...nmap.entries()].sort()) {
  const w = ms.filter(m => m.res === 'win').length, [p, lo, hi] = wilson(w, ms.length);
  out.nemesis['meeting' + mt] = { n: ms.length, winRate: f2(p), winCI: [f2(lo), f2(hi)], adaptB: f2(meanCI(ms.map(m => m.adaptB))[0]), adaptA: f2(meanCI(ms.map(m => m.adaptA))[0]), revGain: f2(meanCI(ms.map(m => (m.revA ?? m.revB) - m.revB))[0]), fedB: f2(meanCI(ms.map(m => m.fedB))[0]) };
}
const nemBattles = runs.flatMap(r => r.battles.filter(b => b.nem).map(b => ({ b, m: r.nem.find(x => x.s === b.s) })));
out.nemesis.byAdapt = {}; out.nemesis.byRev = {};
for (const [g, label] of [[0, 'adapt0'], [1, 'adapt1'], [2, 'adapt2+']]) {
  const sel = nemBattles.filter(x => x.m && (g === 2 ? x.m.adaptB >= 2 : x.m.adaptB === g));
  const w = sel.filter(x => x.b.res === 'win').length, [p, lo, hi] = wilson(w, sel.length);
  out.nemesis.byAdapt[label] = { n: sel.length, winRate: f2(p), winCI: [f2(lo), f2(hi)] };
}
for (const [g, label] of [[0, 'rev0'], [1, 'rev1'], [2, 'rev2']]) {
  const sel = nemBattles.filter(x => x.m && x.m.revB === g);
  const w = sel.filter(x => x.b.res === 'win').length, [p, lo, hi] = wilson(w, sel.length);
  out.nemesis.byRev[label] = { n: sel.length, winRate: f2(p), winCI: [f2(lo), f2(hi)] };
}

// Economy: credits at run start / each transit / run end (last postbattle snap)
out.economy = {};
for (const at of ['start']) { const xs = runs.map(r => (r.econ.find(e => e.at === at) || {}).credits).filter(x => x != null); out.economy[at] = meanCI(xs).map(f2); }
for (const s of [1, 2]) { const xs = runs.map(r => { const e = [...r.econ].reverse().find(e => e.at === 'postbattle' && e.s === s); return e ? e.credits : null; }).filter(x => x != null); out.economy['endOfSector' + s] = meanCI(xs).map(f2); }
const yards = runs.flatMap(r => r.regroups.filter(g => g.type === 'shipyard'));
const totalSpend = yards.reduce((a, g) => a + g.spendRepair + g.spendHull + g.spendMod + g.spendMk, 0);
out.regroup = { shipyardVisits: yards.length,
  repairShare: totalSpend ? f2(yards.reduce((a, g) => a + g.spendRepair, 0) / totalSpend) : 0,
  hullShare: totalSpend ? f2(yards.reduce((a, g) => a + g.spendHull, 0) / totalSpend) : 0,
  modShare: totalSpend ? f2(yards.reduce((a, g) => a + g.spendMod, 0) / totalSpend) : 0,
  mkShare: totalSpend ? f2(yards.reduce((a, g) => a + g.spendMk, 0) / totalSpend) : 0,
  binds: yards.filter(g => g.missingFrac >= 0.25 && g.creditsIn < g.repairCost + g.cheapest).length,
  bindRate: yards.length ? f2(yards.filter(g => g.missingFrac >= 0.25 && g.creditsIn < g.repairCost + g.cheapest).length / yards.length) : 0,
  medianWorstMissing: median(yards.map(g => g.worstMissing || 0)), medianPurse: median(yards.map(g => g.creditsIn)),
  medianMissingFrac: f2(median(yards.map(g => g.missingFrac))) };
const transits = runs.flatMap(r => r.regroups.filter(g => g.type === 'transit'));
out.regroup.transits = transits.length;
out.regroup.transitShortfall = transits.length ? f2(transits.filter(g => g.missingOut > 0).length / transits.length) : 0;

// Utilization
function util(offersOf, picksOf, keyOf) {
  const offered = new Map(), picked = new Map(), runsWith = new Map();
  runs.forEach((r, ri) => { for (const id of offersOf(r)) offered.set(keyOf(id), (offered.get(keyOf(id)) || 0) + 1);
    const ps = new Set(); for (const id of picksOf(r)) { picked.set(keyOf(id), (picked.get(keyOf(id)) || 0) + 1); ps.add(keyOf(id)); }
    for (const id of ps) { if (!runsWith.has(id)) runsWith.set(id, []); runsWith.get(id).push(ri); } });
  const rows = [];
  for (const id of new Set([...offered.keys(), ...picked.keys()])) {
    const off = offered.get(id) || 0, pk = picked.get(id) || 0;
    const wr = runsWith.get(id) || [];
    const winWith = wr.length ? wr.filter(i => runs[i].won).length / wr.length : null;
    rows.push({ id, offered: off, picked: pk, pickRate: off ? f2(pk / off) : null, runsWithPick: wr.length, winRateWithPick: winWith == null ? null : f2(winWith) });
  }
  return rows.sort((a, b) => b.offered - a.offered);
}
out.boons = util(r => r.boonOffers.flatMap(o => o.offer.map(x => x.id)), r => r.boonPicks.map(x => x.id), x => x);
out.modules = util(r => r.modOffers.flatMap(o => o.offer), r => r.modPicks.map(x => x.id), x => x);
out.relics = util(r => r.relicOffers.flatMap(o => o.offer), r => r.relicPicks.map(x => x.id), x => x);
out.hulls = util(r => r.hullOffers.flatMap(o => o.offer), r => r.hullPicks.map(x => x.id), x => x);
out.events = (() => { const seen = new Map(); for (const r of runs) for (const e of r.events) { const cur = seen.get(e.id) || { times: 0, noEnabled: 0 }; cur.times++; if (!e.enabled) cur.noEnabled++; seen.set(e.id, cur); } return [...seen.entries()].map(([id, v]) => ({ id, ...v })).sort((a, b) => b.times - a.times); })();
out.shipsFielded = (() => { const c = new Map(); for (const r of runs) for (const b of r.battles) for (const t of b.tpl) c.set(t, (c.get(t) || 0) + 1); return [...c.entries()].map(([id, n]) => ({ id, battles: n })).sort((a, b) => b.battles - a.battles); })();
out.prizes = runs.flatMap(r => r.prizePicks).reduce((a, p) => { a[p.k] = (a[p.k] || 0) + 1; return a; }, {});
out.salvage = runs.flatMap(r => r.salvagePicks).reduce((a, p) => { a[p.k] = (a[p.k] || 0) + 1; return a; }, {});
out.boonDeclines = runs.reduce((a, r) => a + r.boonDeclines, 0);
out.verbUses = runs.reduce((a, r) => a + r.verbUses, 0);

fs.writeFileSync(path.join(__dirname, 'aggregate.json'), JSON.stringify(out, null, 1));
console.log(JSON.stringify({ totalRuns: out.totalRuns, errors: out.errors, timeouts: out.timeouts, overall: out.overall, byFaction: out.byFaction, reach: out.reach }, null, 1));
