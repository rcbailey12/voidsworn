'use strict';
// Issue 529: the parity fixtures for the last seven tree rows and the "you may" prompts.
// Every fixture's lineage is made by the game's own campaign functions (lineagePick, then newRun), never typed by hand:
// this file holds the picks a player would make, and builds RUN.lineage from them.
//   node tree_last_rows_fixtures.js write   rebuild the fixtures in godot/rules/test/scenarios.json (searches each seed until the row fires)
//   node tree_last_rows_fixtures.js check   fail if a fixture's lineage differs from what the real functions build now
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const SCEN = path.join(ROOT, 'godot/rules/test/scenarios.json');
const GOLDEN = path.join(ROOT, 'godot/rules/test/node/golden.js');

const BASE = { sector: 1, obj: 'rout', shape: 'open', map: 'open', dep: 'line', kind: 'battle', bot: 'full' };
// key: the row the fixture proves (it must fire, treeStats[key] >= 1); fire: false when the fixture proves the skill stays quiet
const FIX = {
  t529_roles_strike: { key: 'matriarch:B:0:0', admiral: 'matriarch', fac_player: 'chorus', picks: ['matriarch:B:0:0'], fleet: ['b_brood', 'b_drone'], fac: 'hegemony', enemies: ['h_interdictor', 'h_picket'], rounds: 4, seed: 52901,
    note: 'Issue 529: Matriarch Roles Assigned at Hatching (matriarch:B:0:0), the default strike role: +10 aim on every shot' },
  t529_roles_screen: { key: 'razormaw:B:0:0', admiral: 'razormaw', fac_player: 'chorus', picks: ['razormaw:B:0:0'], fleet: ['b_razor', 'b_spitter'], fac: 'hegemony', enemies: ['h_dominion', 'h_picket'], rounds: 4, seed: 52911,
    treeRoles: { x03: 'screen', x04: 'screen' }, note: 'Issue 529: Razormaw Roles Assigned at Hatching (razormaw:B:0:0), both ships answer screen: +10 evasion' },
  t529_roles_mend: { key: 'mending:B:0:0', admiral: 'mending', fac_player: 'chorus', picks: ['mending:B:0:0'], fleet: ['b_razor', 'b_drone'], fac: 'hegemony', enemies: ['h_dominion'], rounds: 5, cmdRound: 2, seed: 52921,
    treeRoles: { x03: 'mend', x04: 'mend' }, note: 'Issue 529: Mending Roles Assigned at Hatching (mending:B:0:0), both ships answer mend: regrowth and the Regrowth tide 10% stronger' },
  t529_roles_change: { key: 'voice:B:0:0', admiral: 'voice', fac_player: 'chorus', picks: ['voice:B:0:0'], fleet: ['b_razor', 'b_spitter', 'b_drone'], fac: 'hegemony', enemies: ['h_dominion', 'h_picket'], rounds: 4, seed: 52931,
    treeRoleChange: { round: 2, id: 'x03', role: 'screen' }, note: 'Issue 529: Voice Roles Assigned at Hatching (voice:B:0:0), strike by default, then the change-role action makes x03 a screen in round 2' },
  t529_spawned: { key: 'matriarch:A:1:1', admiral: 'matriarch', fac_player: 'chorus', picks: ['matriarch:A:0:0', 'matriarch:A:1:1'], fleet: ['b_brood', 'b_drone'], fac: 'hegemony', enemies: ['h_interdictor'], rounds: 5, cmdRound: 1, cmdAfterMove: true, seed: 52941,
    note: 'Issue 529: Matriarch Spawned Before the Strike (matriarch:A:1:1): the brood moves, then Spawning surge; its extra swarms strike at +15%' },
  t529_nostop: { key: 'matriarch:cap:1', admiral: 'matriarch', fac_player: 'chorus', picks: ['matriarch:A:0:0', 'matriarch:B:0:0', 'matriarch:C:0:0', 'matriarch:cap:1'], fleet: ['b_brood', 'b_drone', 'b_drone'], fac: 'hegemony', enemies: ['h_picket', 'h_picket', 'h_picket'], rounds: 6, cmdRound: 2, seed: 52951,
    note: 'Issue 529: Matriarch The Brood Does Not Stop (matriarch:cap:1): an extra swarm that destroys its target strikes another enemy at half damage' },
  t529_scent: { key: 'razormaw:A:1:1', admiral: 'razormaw', fac_player: 'chorus', picks: ['razormaw:A:0:0', 'razormaw:A:1:1'], fleet: ['b_razor', 'b_razor', 'b_spitter'], fac: 'hegemony', enemies: ['h_picket', 'h_picket', 'h_picket'], rounds: 6, cmdRound: 2, seed: 52961,
    note: 'Issue 529: Razormaw Scent in the Dark (razormaw:A:1:1): after a kill in the frenzy the ship\'s next shot at a new target gains +10 aim' },
  t529_may_debt_no: { key: 'vex:A:2:1', fire: false, admiral: 'vex', fac_player: 'voidsworn', picks: ['vex:A:0:0', 'vex:A:1:0', 'vex:A:2:1'], fleet: ['penitent', 'harrow'], fac: 'hegemony', enemies: ['h_picket', 'h_picket'], rounds: 5, cmdRound: 3, seed: 52971,
    treeMay: { 'vex:A:2:1': false }, note: 'Issue 529: Vex Debt Comes Due (vex:A:2:1) answered no at the prompt: the volley fires at once, nothing is delayed' },
  t529_may_grow_no: { key: 'mending:A:0:0', fire: false, admiral: 'mending', fac_player: 'chorus', picks: ['mending:A:0:0'], fleet: ['b_razor', 'b_spitter'], fac: 'hegemony', enemies: ['h_dominion'], rounds: 6, cmdRound: 3, seed: 52981,
    treeMay: { 'mending:A:0:0': false }, note: 'Issue 529: Mending Grow Where It Hurts (mending:A:0:0) answered no: the regrowth is spread as normal' }
};

// RUN.lineage from the real campaign functions: picks are made between runs on a fresh profile, then a run starts
let built = null;
function lineages() {
  if (built) return built;
  process.env.VS_ORACLE = ROOT;
  require('../../../godot/campaign/test/node/env.js').load(`
globalThis.__lin529 = (id, fac, picks) => {
  RUN = null; SAVED_RUN = null; META = migrateMeta(defaultMeta());
  META.admirals[id] = true; META.mastery[id] = 230;
  for (const k of picks) if (lineagePick(k) !== true) throw new Error('lineagePick(' + k + ') was refused');
  newRun(id, fac);
  return JSON.parse(JSON.stringify(RUN.lineage));
};`);
  built = {};
  for (const [name, f] of Object.entries(FIX)) built[name] = global.__lin529(f.admiral, f.fac_player, f.picks);
  return built;
}

function scenarioOf(name) {
  const f = FIX[name];
  const s = Object.assign({}, BASE);
  for (const k of Object.keys(f)) if (!['key', 'fire', 'picks'].includes(k)) s[k] = f[k];
  s.lineage = lineages()[name];
  return s;
}

function stats(scen, name) {
  const tmp = path.join(require('os').tmpdir(), 'fx529_' + name + '.json');
  const out = tmp + '.jsonl';
  fs.writeFileSync(tmp, JSON.stringify({ [name]: scen }));
  const r = spawnSync(process.execPath, [GOLDEN, 'scenario', name, out, '-1', tmp], { cwd: ROOT, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(name + ': golden failed: ' + (r.stderr || r.stdout).slice(0, 300));
  const lines = fs.readFileSync(out, 'utf8').trim().split('\n');
  return JSON.parse(JSON.parse(lines[lines.length - 1]).state).b.treeStats || {};
}

function write() {
  const all = JSON.parse(fs.readFileSync(SCEN, 'utf8'));
  for (const name of Object.keys(FIX)) {
    const f = FIX[name]; const want = f.fire !== false;
    let s = scenarioOf(name), tries = 0;
    for (;;) {
      const st = stats(s, name);
      if (((st[f.key] || 0) >= 1) === want) break;
      if (++tries > 60) throw new Error(name + ': no seed in 60 made ' + f.key + (want ? ' fire' : ' stay quiet'));
      s.seed += 1;
    }
    all[name] = s;
    console.log(name + ': seed ' + s.seed + ' (' + tries + ' tries)');
  }
  fs.writeFileSync(SCEN, JSON.stringify(all, null, 1) + '\n');
}

function check() {
  const all = JSON.parse(fs.readFileSync(SCEN, 'utf8'));
  const fails = [];
  for (const name of Object.keys(FIX)) {
    const s = all[name];
    if (!s) { fails.push(name + ': missing from scenarios.json'); continue; }
    if (JSON.stringify(s.lineage) !== JSON.stringify(lineages()[name])) fails.push(name + ': lineage ' + JSON.stringify(s.lineage) + ' is not what lineagePick and newRun build (' + JSON.stringify(lineages()[name]) + ')');
  }
  return fails;
}

module.exports = { FIX, lineages, check };
if (require.main === module) {
  if (process.argv[2] === 'write') write();
  else { const f = check(); if (f.length) { f.forEach(x => console.log('FAIL ' + x)); process.exit(1); } console.log('PASS: ' + Object.keys(FIX).length + ' issue 529 fixtures carry the lineage lineagePick and newRun build'); }
}
