// fleet_invariants.js - seeded invariant sweep over genEnemyFleet.
//
// For every faction x sector x column x kind x archetype cell, generates
// fleets under fixed seeds and asserts the invariants the design rulings and
// the generator's own budget math imply:
//
//   1. Determinism: the same seed regenerates the identical fleet.
//   2. Every generated hull id exists in HULLS and belongs to the faction's
//      roster (or is the faction boss on a boss roll).
//   3. A boss roll leads with the faction boss hull.
//   4. Eclipse (data id deathless) never fields a launch hull, on any
//      archetype including 'carrier' (the no-carrier ruling, Oct 29 Q2;
//      effArch remaps the archetype, the roster has no launch hull).
//   5. Total CP stays within the budget the formula allows: base budget
//      (sector base + column step) times RAMP.grow, times 1.05 for elites,
//      with the boss hull's CP added on boss rolls (the boss is pushed
//      before the budget is scaled by RAMP.boss and its CP is not
//      deducted), plus one max-CP hull of overshoot (a pick may cost up to
//      budget + 0.3, so the last pick can overshoot by less than its CP).
//      The player-power scaling is inactive here because RUN is null,
//      matching a fresh campaign with no fleet loaded.
//   6. Fleet size respects the soft ceiling: at most max(4, RAMP.ceil[s]-4)
//      hulls (the ceiling subtracts the default 4-ship player fleet when
//      no RUN is loaded).
//   7. Seed sensitivity: across 50 seeds in a probe cell, at least 5
//      distinct fleets appear (guards against a silently frozen RNG).
//
// Usage: node fleet_invariants.js [repoDir] [seedsPerCell]
// Exit code 0 = all invariants hold; 1 = at least one failure (printed).
'use strict';
const { loadGame } = require('./game_loader');

const repoDir = process.argv[2] || require('path').join(__dirname, '..', 'voidsworn-fresh');
const SEEDS = parseInt(process.argv[3] || '12', 10);
const G = loadGame(repoDir);
const { HULLS, FACTIONS, RAMP } = G;

let checks = 0, failures = [];
function fail(cell, msg) { failures.push(cell + ': ' + msg); }
function cpOf(tpl) { return HULLS[tpl].cp || 1; }

function baseBudget(fac, s, col, kind) {
  let b = ([0, 4.2, 9.5, 14][s] + col * (s === 1 ? 0.9 : s === 2 ? 1 : 1.1)) * RAMP.grow[s];
  if (kind === 'elite') b *= 1.05;
  if (kind === 'boss') b *= RAMP.boss[s];
  return b;
}

const kinds = ['skirmish', 'elite', 'boss'];
const archs = [null, 'swarm', 'heavy', 'carrier'];
let fleets = 0;

for (const fac of Object.keys(FACTIONS)) {
  const F = FACTIONS[fac];
  const roster = new Set(F.roster);
  const maxCp = Math.max(...F.roster.map(cpOf), cpOf(F.boss));
  for (let s = 1; s <= 3; s++) {
    for (let col = 0; col <= 6; col++) {
      for (const kind of kinds) {
        for (const arch of archs) {
          const cell = fac + ' s' + s + ' c' + col + ' ' + kind + '/' + (arch || 'none');
          for (let seed = 1; seed <= SEEDS; seed++) {
            G.rndSeed(seed * 7919 + s * 131 + col * 17);
            const a = G.genEnemyFleet(fac, s, col, kind, arch, null);
            G.rndSeed(seed * 7919 + s * 131 + col * 17);
            const b = G.genEnemyFleet(fac, s, col, kind, arch, null);
            fleets++;
            checks++;
            if (JSON.stringify(a) !== JSON.stringify(b)) { fail(cell, 'nondeterministic at seed ' + seed); continue; }
            for (const e of a) {
              if (!HULLS[e.tpl]) { fail(cell, 'unknown hull ' + e.tpl); break; }
              if (!roster.has(e.tpl) && e.tpl !== F.boss) { fail(cell, 'off-roster hull ' + e.tpl); break; }
              if (fac === 'deathless' && HULLS[e.tpl].ab === 'launch') { fail(cell, 'Eclipse fielded launch hull ' + e.tpl); break; }
            }
            if (kind === 'boss' && (!a.length || a[0].tpl !== F.boss)) fail(cell, 'boss roll does not lead with ' + F.boss);
            const totalCp = a.reduce((t, e) => t + cpOf(e.tpl), 0);
            const cap = baseBudget(fac, s, col, kind) + (kind === 'boss' ? cpOf(F.boss) : 0) + maxCp;
            if (totalCp > cap + 1e-9) fail(cell, 'CP ' + totalCp.toFixed(1) + ' over cap ' + cap.toFixed(2));
            const sizeCap = Math.max(4, RAMP.ceil[s] - 4);
            if (a.length > sizeCap) fail(cell, 'fleet size ' + a.length + ' over ceiling ' + sizeCap);
          }
        }
      }
    }
  }
}

// Seed sensitivity probe.
{
  const seen = new Set();
  for (let seed = 1; seed <= 50; seed++) {
    G.rndSeed(seed * 104729);
    seen.add(JSON.stringify(G.genEnemyFleet('hegemony', 2, 3, 'skirmish', null, null)));
  }
  checks++;
  if (seen.size < 5) fail('probe', 'only ' + seen.size + ' distinct fleets across 50 seeds');
}

console.log('fleet_invariants: ' + fleets + ' fleets generated, ' + checks + ' checks, ' + failures.length + ' failures');
for (const f of failures.slice(0, 40)) console.log('FAIL ' + f);
if (failures.length > 40) console.log('... and ' + (failures.length - 40) + ' more');
process.exit(failures.length ? 1 : 0);
