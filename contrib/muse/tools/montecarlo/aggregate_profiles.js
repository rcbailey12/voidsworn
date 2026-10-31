// aggregate_profiles.js - statistics for the policy-sensitivity extension.
// Reads the paired pol_<policy>_<fac>.json shards plus the first program's
// Veteran baseline shards (for the per-admiral table) and writes
// profiles_aggregate.json with everything the report cites.
'use strict';
const fs = require('fs');
const path = require('path');
const RAW = path.join(__dirname, 'raw');
const Z = 1.96;
function wilson(k, n) { if (!n) return [0, 0, 0]; const p = k / n, d = 1 + Z * Z / n, c = p + Z * Z / (2 * n), m = Z * Math.sqrt(p * (1 - p) / n + Z * Z / (4 * n * n)); return [p, Math.max(0, (c - m) / d), Math.min(1, (c + m) / d)]; }
function meanCI(xs) { xs = xs.filter(x => typeof x === 'number' && isFinite(x)); if (!xs.length) return [0, 0, 0, 0]; const m = xs.reduce((a, b) => a + b, 0) / xs.length; if (xs.length < 2) return [m, m, m, xs.length]; const sd = Math.sqrt(xs.reduce((a, b) => a + (b - m) * (b - m), 0) / (xs.length - 1)); const e = Z * sd / Math.sqrt(xs.length); return [m, m - e, m + e, xs.length]; }
const f2 = x => +x.toFixed(4);
function winBlock(list) { const n = list.length, w = list.filter(r => r.won).length, [p, lo, hi] = wilson(w, n); return { n, wins: w, rate: f2(p), ci: [f2(lo), f2(hi)] }; }
function loadPol(pol, fac) { const f = path.join(RAW, `pol_${pol}_${fac}.json`); if (!fs.existsSync(f)) return null; const d = JSON.parse(fs.readFileSync(f, 'utf8')); return d.runs.map((r, i) => ({ ...r, seed: d.meta.seed0 + i })); }

const FACS = ['voidsworn', 'corsair', 'deathless', 'hegemony', 'ithar', 'chorus'];
const POLS = ['baseline', 'rusher', 'turtle', 'hunter'];
const out = { cells: {}, paired: {}, reach: {}, nemesis: {}, regroup: {}, boons: {}, admirals: {}, errors: 0, timeouts: 0, totalRuns: 0 };
const cells = {}; // cells[pol][fac] = runs (with seed)
for (const pol of POLS) { cells[pol] = {}; for (const fac of FACS) { const rs = loadPol(pol, fac); if (rs) { cells[pol][fac] = rs; out.totalRuns += rs.length; out.errors += rs.filter(r => r.errors.length).length; out.timeouts += rs.reduce((a, r) => a + r.timeouts, 0); } } }

for (const pol of POLS) {
  out.cells[pol] = {}; out.reach[pol] = {}; out.nemesis[pol] = {}; out.regroup[pol] = {}; out.boons[pol] = {};
  const allRuns = FACS.flatMap(f => cells[pol][f] || []);
  out.cells[pol].ALL = winBlock(allRuns);
  for (const fac of FACS) {
    const rs = cells[pol][fac] || [];
    out.cells[pol][fac] = winBlock(rs);
    out.reach[pol][fac] = {};
    for (const s of [2, 3]) { const k = rs.filter(r => r.sectorReached >= s).length, [p, lo, hi] = wilson(k, rs.length); out.reach[pol][fac]['S' + s] = { n: k, rate: f2(p), ci: [f2(lo), f2(hi)] }; }
    // nemesis per faction: meetings per run, nem fight win rate
    const nems = rs.flatMap(r => r.nem);
    const nw = nems.filter(m => m.res === 'win').length, [np, nlo, nhi] = wilson(nw, nems.length);
    out.nemesis[pol][fac] = { meetings: nems.length, perRun: f2(meanCI(rs.map(r => r.nem.length))[0]), fightWinRate: f2(np), fightWinCI: [f2(nlo), f2(nhi)] };
    // regroup per faction
    const yards = rs.flatMap(r => r.regroups.filter(g => g.type === 'shipyard'));
    const binds = yards.filter(g => g.missingFrac >= 0.25 && g.creditsIn < g.repairCost + g.cheapest).length;
    out.regroup[pol][fac] = { visits: yards.length, binds, bindRate: yards.length ? f2(binds / yards.length) : 0 };
  }
  // nemesis pooled per policy: by meeting number and by adaptations carried in
  const byMeeting = {};
  for (const r of allRuns) for (const m of r.nem) { (byMeeting[m.meeting] = byMeeting[m.meeting] || []).push(m); }
  out.nemesis[pol].byMeeting = {};
  for (const mt of Object.keys(byMeeting).sort()) { const ms = byMeeting[mt]; const w = ms.filter(m => m.res === 'win').length, [p, lo, hi] = wilson(w, ms.length);
    out.nemesis[pol].byMeeting['m' + mt] = { n: ms.length, winRate: f2(p), winCI: [f2(lo), f2(hi)], adaptB: f2(meanCI(ms.map(m => m.adaptB))[0]), revGain: f2(meanCI(ms.map(m => (m.revA != null ? m.revA : m.revB) - m.revB))[0]) }; }
  const byAdapt = {};
  for (const r of allRuns) for (const b of r.battles.filter(x => x.nem)) { const m = r.nem.find(x => x.s === b.s); if (!m) continue; const g = m.adaptB >= 2 ? 'adapt2+' : 'adapt' + m.adaptB; (byAdapt[g] = byAdapt[g] || []).push(b); }
  out.nemesis[pol].byAdapt = {};
  for (const g of Object.keys(byAdapt).sort()) { const bs = byAdapt[g]; const w = bs.filter(b => b.res === 'win').length, [p, lo, hi] = wilson(w, bs.length); out.nemesis[pol].byAdapt[g] = { n: bs.length, winRate: f2(p), winCI: [f2(lo), f2(hi)] }; }
  // regroup pooled
  const yards = allRuns.flatMap(r => r.regroups.filter(g => g.type === 'shipyard'));
  const binds = yards.filter(g => g.missingFrac >= 0.25 && g.creditsIn < g.repairCost + g.cheapest).length;
  const totSpend = yards.reduce((a, g) => a + g.spendRepair + g.spendHull + g.spendMod + g.spendMk, 0);
  const med = xs => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : 0; };
  out.regroup[pol].ALL = { visits: yards.length, binds, bindRate: yards.length ? f2(binds / yards.length) : 0,
    repairShare: totSpend ? f2(yards.reduce((a, g) => a + g.spendRepair, 0) / totSpend) : 0,
    hullShare: totSpend ? f2(yards.reduce((a, g) => a + g.spendHull, 0) / totSpend) : 0,
    modShare: totSpend ? f2(yards.reduce((a, g) => a + g.spendMod, 0) / totSpend) : 0,
    mkShare: totSpend ? f2(yards.reduce((a, g) => a + g.spendMk, 0) / totSpend) : 0,
    medianWorstMissing: med(yards.map(g => g.worstMissing || 0)), medianPurse: med(yards.map(g => g.creditsIn)) };
  // boon utilization per policy (pooled)
  const offered = new Map(), picked = new Map();
  for (const r of allRuns) { for (const o of r.boonOffers) for (const x of o.offer) offered.set(x.id, (offered.get(x.id) || 0) + 1); for (const p of r.boonPicks) picked.set(p.id, (picked.get(p.id) || 0) + 1); }
  out.boons[pol] = [...new Set([...offered.keys(), ...picked.keys()])].map(id => ({ id, offered: offered.get(id) || 0, picked: picked.get(id) || 0, pickRate: offered.get(id) ? f2((picked.get(id) || 0) / offered.get(id)) : null })).sort((a, b) => b.offered - a.offered);
  out.boons[pol].declines = allRuns.reduce((a, r) => a + r.boonDeclines, 0);
}

// Paired per-seed deltas vs the baseline control arm (same seed sets).
for (const pol of ['rusher', 'turtle', 'hunter']) {
  out.paired[pol] = {};
  for (const fac of FACS) {
    const base = new Map((cells.baseline[fac] || []).map(r => [r.seed, r]));
    const mine = cells[pol][fac] || [];
    let both = 0, bothL = 0, onlyP = 0, onlyB = 0, n = 0;
    for (const r of mine) { const b = base.get(r.seed); if (!b) continue; n++; if (r.won && b.won) both++; else if (!r.won && !b.won) bothL++; else if (r.won) onlyP++; else onlyB++; }
    const delta = n ? (onlyP - onlyB) / n : 0, se = n ? Math.sqrt(Math.max(onlyP + onlyB, 0)) / n : 0;
    out.paired[pol][fac] = { n, bothWin: both, bothLoss: bothL, polOnlyWin: onlyP, baseOnlyWin: onlyB, delta: f2(delta), deltaCI: [f2(delta - Z * se), f2(delta + Z * se)] };
  }
}

// Per-admiral under the baseline policy: first program Veteran shards pooled
// with this extension's baseline control arm (identical policy, trace-verified
// harness, disjoint seed sets). Also reported first-program-only for a
// consistency check.
function loadFirstVet(fac) {
  const files = { chorus: ['main_vet_chorus.json'], corsair: ['main_vet_corsair.json'], deathless: ['main_vet_deathless.json'], hegemony: ['main_vet_hegemony.json'], ithar: ['main_vet_ithar.json', 'main_vet_ithar2.json'], voidsworn: ['main_vet_voidsworn.json', 'main_vet_voidsworn2.json'] }[fac] || [];
  const runs = [];
  for (const f of files) { const d = JSON.parse(fs.readFileSync(path.join(RAW, f), 'utf8')); for (const r of d.runs) if (r.ai === 'veteran') runs.push(r); }
  return runs;
}
function admiralBlock(rs) {
  const nems = rs.flatMap(r => r.nem); const nw = nems.filter(m => m.res === 'win').length, [np, nlo, nhi] = wilson(nw, nems.length);
  const s3 = rs.filter(r => r.sectorReached >= 3).length, [sp, slo, shi] = wilson(s3, rs.length);
  return { ...winBlock(rs), reachS3: f2(sp), reachS3CI: [f2(slo), f2(shi)],
    battlesPerRun: f2(meanCI(rs.map(r => r.battles.length))[0]),
    shipsLostPerRun: f2(meanCI(rs.map(r => r.battles.reduce((a, b) => a + b.lost, 0)))[0]),
    shipsLostPerBattle: f2(meanCI(rs.flatMap(r => r.battles.map(b => b.lost)))[0]),
    nemMeetingsPerRun: f2(meanCI(rs.map(r => r.nem.length))[0]),
    nemWinRate: f2(np), nemWinCI: [f2(nlo), f2(nhi)], nemFights: nems.length,
    timeouts: rs.reduce((a, r) => a + r.timeouts, 0), errors: rs.filter(r => r.errors.length).length };
}
for (const fac of FACS) {
  const first = loadFirstVet(fac);
  const pooled = [...first, ...(cells.baseline[fac] || [])];
  out.admirals[fac] = { pooled: {}, firstOnly: {} };
  for (const r of pooled) { (out.admirals[fac].pooled[r.admiral] = out.admirals[fac].pooled[r.admiral] || []).push(r); }
  for (const r of first) { (out.admirals[fac].firstOnly[r.admiral] = out.admirals[fac].firstOnly[r.admiral] || []).push(r); }
  for (const a of Object.keys(out.admirals[fac].pooled)) out.admirals[fac].pooled[a] = admiralBlock(out.admirals[fac].pooled[a]);
  for (const a of Object.keys(out.admirals[fac].firstOnly)) out.admirals[fac].firstOnly[a] = admiralBlock(out.admirals[fac].firstOnly[a]);
}

fs.writeFileSync(path.join(__dirname, 'profiles_aggregate.json'), JSON.stringify(out, null, 1));
console.log(JSON.stringify({ totalRuns: out.totalRuns, errors: out.errors, timeouts: out.timeouts, cells: out.cells }, null, 1));
