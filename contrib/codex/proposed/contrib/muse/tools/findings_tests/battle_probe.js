'use strict';
// battle_probe.js - battle-probe driver for the findings-tests harness.
//
// The data harness (game_loader.js) loads the rules files but cannot run a
// battle turn: battle.js's action functions (aiUnit, aiVolley, moveUnit,
// fireWeapon) are async and call animation hooks (animPath, animMove,
// animRotate, animWeapon, animExplode, animNova) that the browser shell
// normally supplies. sim3d.js, the shipped headless driver, solves the same
// problem by defining those hooks as instant state commits: animMove and
// animRotate write the unit's hex and facing directly, and animPath invokes
// the move's onLate callback (the mid-move volley point) instead of drawing
// the burn. This module installs the same hooks into an already-loaded
// game_loader context, plus SPEED = 0 so wait() resolves immediately, and
// provides the fixture helpers the AI tests use (probeBattle builds a battle
// through the game's own startBattle with explicit fleets; place and
// clearTerrain then arrange the exact tactical state, the way sim3d's
// ruleCheck setup does with its at() and clearT() helpers).
//
// Install it AFTER any tests that must see the pristine context: the hooks
// only add globals, but a context with animPath defined takes moveUnit's
// animated path instead of its step loop, so the round 1 tests run first.
const vm = require('vm');

function installBattleProbe(G) {
  const runIn = (code) => vm.runInContext(code, G._sandbox);
  runIn(
    'async function animPath(u, path, opt){ if(opt && opt.onLate) await opt.onLate(); }\n' +
    'async function animMove(u, q, r, f){ u.q = q; u.r = r; u.facing = f; }\n' +
    'async function animRotate(u, f){ u.facing = f; }\n' +
    'async function animWeapon(){}\n' +
    'async function animExplode(){}\n' +
    'async function animNova(){}\n' +
    'async function animBlink(){}\n' +
    'function fxGravPull(){}\n' +
    'SPEED = 0;'
  );
  return runIn;
}

function setAiLevel(G, level) {
  G._sandbox.__lvl = level;
  vm.runInContext('AI_LEVEL = __lvl;', G._sandbox);
}

// Build a battle through startBattle with explicit fleets (the sim3d sim()
// pattern): opts {player:[tpl], enemies:[tpl], fac, sector, kind, obj,
// shape, map, dep, arena, col, seed}. Returns B.
function probeBattle(G, opts) {
  const o = opts || {};
  const run = G.runDefaults();
  run.fac = 'voidsworn'; run.admiral = 'vex'; run.sector = o.sector || 1; run.foes = null;
  run.fleet = (o.player || ['warden']).map(t => G.newShip(t));
  run.flagUid = run.fleet.length ? run.fleet[0].uid : null;
  G.RUN = run;
  G._sandbox.__cfg = {
    kind: o.kind || 'battle', fac: o.fac || 'hegemony', col: o.col || 3,
    obj: o.obj || 'rout', shape: o.shape || 'open',
    map: o.map === undefined ? 'storm' : o.map, dep: o.dep || 'line',
    arena: o.arena, seed: o.seed == null ? 777 : o.seed,
    enemies: (o.enemies || ['h_picket']).map(tpl => ({ tpl })),
  };
  vm.runInContext('startBattle(__cfg);', G._sandbox);
  return G.B;
}

function place(u, q, r, f) { u.q = q; u.r = r; if (f != null) u.facing = f; }
function clearTerrain(G) { G.B.terrain = {}; }

// One enemy activation the way sim3d's classic loop runs it: the enemy turn
// start first (it is what refreshes movement points, turns and cooldowns),
// then aiUnit for the one ship under test.
async function activateEnemy(G, u) {
  G._sandbox.__u = u;
  await vm.runInContext('(async () => { B.side = "enemy"; await turnStart("enemy"); await aiUnit(__u); })()', G._sandbox);
}

module.exports = { installBattleProbe, setAiLevel, probeBattle, place, clearTerrain, activateEnemy };
