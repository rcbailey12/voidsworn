'use strict';

const { harness, setupBattle, encounters, sources, huntSettings } =
  require('../../../../contrib/codex/map_eval_1118/sim.js');

// Use the recommended arm with the confirmed Hunt values. Generate bosses at
// battle start, as the live campaign does, with the same JS trial placements.
const rules = 'current';
const trial = harness({ rules, revision: sources[rules] });
const huntTuning = { ...huntSettings[0], approachTurns: 6, exitLane: 0.15 };
const factions = Object.keys(trial.FACTIONS);
const fixtures = [];
for (const enc of encounters) {
  for (let i = 0; i < 24; i++) {
    const seed = 1000 + i;
    const pf = factions[i % factions.length];
    const ef = factions[(i + Math.floor(i / factions.length)) % factions.length];
    const { B, config, run } = setupBattle(trial, {
      group: 'encounter', enc, sector: 1 + i % 3, setup: 'recommended', pf, ef, huntTuning,
      generateBossInBattle: true,
    }, seed);
    // Godot rolls the shape from the seed itself, including the strip override.
    const { shape, arena, trialPlacement, trialTempo, huntTuning: tuning, ...cfg } = config;
    fixtures.push({
      enc, seed, cfg, run,
      expected: {
        shape: B.shape, arena: B.arena, map: B.map.map,
        bearing: B.trialExitHex ?? null,
        units: B.units.map(u => [
          u.side, u.tpl, u.q, u.r, u.facing, u.speed, u.weapons.map(w => [w.id, w.r]),
        ]),
      },
    });
  }
}
process.stdout.write(JSON.stringify(fixtures));
