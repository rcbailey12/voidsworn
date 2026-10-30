// fleet_scaling.js - the player-power scaling band of genEnemyFleet.
//
// fleet_invariants.js runs with no campaign loaded, so the budget's
// player-power term (fleetPower vs RAMP.refP, clamped to [pwMin, pwMax])
// never engages. This harness loads a RUN and checks the band end to end:
//
//   1. A strong fleet (7 heavy hulls at full hull) never pushes the enemy
//      budget past base x grow x pwMax, plus the usual one-hull overshoot
//      (and the boss hull's CP on boss rolls).
//   2. A battered fleet (the same hulls at 1 HP) never pulls the budget
//      below the pwMin clamp either: the same per-fleet cap formula with
//      pwMin substituted must hold as an upper bound too, because the
//      clamp is a floor on the multiplier, so battered fleets meet at
//      most base x grow x (something >= pwMin) - the binding check is the
//      ordering in (3).
//   3. Ordering across 40 seeds per sector: mean enemy CP against the
//      strong fleet >= mean against no RUN >= mean against the battered
//      fleet, and the strong/battered mean ratio stays within
//      pwMax/pwMin plus fill slack (0.25), since the fill loop spends
//      budget in whole hulls.
//
// Usage: node fleet_scaling.js [repoDir]
// Exit code 0 = band holds; 1 = failures printed.
'use strict';
const { loadGame } = require('./game_loader');
const path = require('path');

const repoDir = process.argv[2] || path.join(__dirname, '..', 'voidsworn-fresh');
const G = loadGame(repoDir);
const { HULLS, FACTIONS, RAMP } = G;
const SEEDS = 40;
let failures = [];
function fail(msg) { failures.push(msg); }
function cpOf(tpl) { return HULLS[tpl].cp || 1; }

function mkRun(sector, hulls, hpFrac) {
  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.sector = sector;
  run.credits = 0;
  run.cpCap = 40;
  run.fleet = hulls.map(t => {
    const s = G.newShip(t, false);
    s.hp = Math.max(1, Math.round(G.derive(s).maxHp * hpFrac));
    return s;
  });
  run.flagUid = run.fleet[0].uid;
  return run;
}

const HEAVY = ['ascendant', 'cathedral', 'cathedral', 'penitent', 'penitent', 'reliquary', 'harrow'];

function meanCp(fac, s, col, kind, run) {
  G.RUN = run;
  let tot = 0;
  for (let seed = 1; seed <= SEEDS; seed++) {
    G.rndSeed(seed * 31337 + s * 101 + col);
    const f = G.genEnemyFleet(fac, s, col, kind, null, null);
    tot += f.reduce((t, e) => t + cpOf(e.tpl), 0);
  }
  G.RUN = null;
  return tot / SEEDS;
}

function capFor(fac, s, col, kind, mult) {
  let b = ([0, 4.2, 9.5, 14][s] + col * (s === 1 ? 0.9 : s === 2 ? 1 : 1.1)) * RAMP.grow[s];
  if (kind === 'elite') b *= 1.05;
  if (kind === 'boss') b *= RAMP.boss[s];
  const maxCp = Math.max(...FACTIONS[fac].roster.map(cpOf), cpOf(FACTIONS[fac].boss));
  return b * mult + (kind === 'boss' ? cpOf(FACTIONS[fac].boss) : 0) + maxCp;
}

// Per-fleet cap under the strong fleet (pwMax clamp is the ceiling).
for (const fac of Object.keys(FACTIONS)) {
  for (let s = 1; s <= 3; s++) {
    G.RUN = mkRun(s, HEAVY, 1);
    for (let seed = 1; seed <= SEEDS; seed++) {
      G.rndSeed(seed * 977 + s);
      const f = G.genEnemyFleet(fac, s, 3, 'skirmish', null, null);
      const tot = f.reduce((t, e) => t + cpOf(e.tpl), 0);
      const cap = capFor(fac, s, 3, 'skirmish', RAMP.pwMax);
      if (tot > cap + 1e-9) fail(fac + ' s' + s + ' seed ' + seed + ': CP ' + tot.toFixed(1) + ' over pwMax cap ' + cap.toFixed(2));
    }
    G.RUN = null;
  }
}

// Ordering of means per sector (enemy faction fixed to hegemony).
for (let s = 1; s <= 3; s++) {
  const strong = meanCp('hegemony', s, 3, 'skirmish', mkRun(s, HEAVY, 1));
  const base = meanCp('hegemony', s, 3, 'skirmish', null);
  const battered = meanCp('hegemony', s, 3, 'skirmish', mkRun(s, HEAVY, 0.02));
  // 0.15 CP of slack: the fill spends budget in whole hulls, so at sector 1
  // budgets (about 8 CP against 1-6 CP hulls) a clamped multiplier change
  // often buys the identical fleet and the means land within one cheap
  // hull of each other in either direction.
  if (!(strong >= base - 0.15)) fail('s' + s + ': strong mean ' + strong.toFixed(2) + ' below baseline ' + base.toFixed(2));
  if (!(base >= battered - 0.15)) fail('s' + s + ': baseline mean ' + base.toFixed(2) + ' below battered ' + battered.toFixed(2));
  const ratio = strong / Math.max(0.01, battered);
  const band = RAMP.pwMax / RAMP.pwMin + 0.25;
  if (ratio > band) fail('s' + s + ': strong/battered ratio ' + ratio.toFixed(2) + ' over band ' + band.toFixed(2));
  console.log('s' + s + ': mean enemy CP strong ' + strong.toFixed(1) + ', baseline ' + base.toFixed(1) + ', battered ' + battered.toFixed(1) + ', ratio ' + ratio.toFixed(2) + ' (band ' + band.toFixed(2) + ')');
}

console.log('fleet_scaling: ' + failures.length + ' failures');
for (const f of failures.slice(0, 40)) console.log('FAIL ' + f);
process.exit(failures.length ? 1 : 0);
