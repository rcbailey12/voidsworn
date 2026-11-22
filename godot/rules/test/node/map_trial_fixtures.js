'use strict';

const fs = require('fs');

const { harness, setupBattle, encounters, sources, huntSettings } =
  require('../../../../contrib/codex/map_eval_1118/sim.js');

// Use the recommended arm with the confirmed Hunt values. Generate bosses at
// battle start, as the live campaign does, with the same JS trial placements.
const rules = 'current';
const revision = require('child_process').execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
// R405 froze the browser rules, so the JS twin takes the fleet budget levers from the Godot table (R414 changed them).
const decode = v => typeof v === 'string' && v.startsWith('#d:') ? Buffer.from(v.slice(3), 'hex').readDoubleBE(0) : v;
const godotRamp = JSON.parse(fs.readFileSync(require('path').join(__dirname, '../../data/tables.json'), 'utf8')).tables.RAMP;
const ramp = { std: decode(godotRamp.std), vet: decode(godotRamp.vet) };
const trial = harness({ rules, revision, ramp });
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
// Two checks: Godot against the JS twin at HEAD (above), and both against the pinned fleets in
// map_trial_pinned.json, so a change that moves both twins' fleets together still fails. A deliberate
// fleet change refreshes the pin: node godot/rules/test/node/map_trial_fixtures.js --pin (issue 1160).
const pinFile = require('path').join(__dirname, 'map_trial_pinned.json');
if (process.argv.includes('--pin')) {
  const cases = {};
  for (const f of fixtures) cases[f.enc + '|' + f.seed] = { shape: f.expected.shape, arena: f.expected.arena, units: f.expected.units };
  fs.writeFileSync(pinFile, JSON.stringify({ revision, note: 'Fleets the map trial expects. A deliberate fleet change refreshes this pin with --pin.', cases }) + '\n');
  console.error('pinned ' + fixtures.length + ' map trial fleets at ' + revision);
} else {
  const pin = JSON.parse(fs.readFileSync(pinFile, 'utf8'));
  for (const f of fixtures) f.pinned = Object.assign({ revision: pin.revision }, pin.cases[f.enc + '|' + f.seed] || {});
  process.stdout.write(JSON.stringify(fixtures));
}
