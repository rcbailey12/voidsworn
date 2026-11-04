'use strict';
// R88: real battle rules, no manual launch or wing activation commands.
const fs = require('fs'), path = require('path'), vm = require('vm'), assert = require('assert');
const root = path.resolve(__dirname, '../../..');
const ctx = vm.createContext({ console: { ...console, debug() {} }, setInterval, clearInterval, setTimeout, performance: { now: () => 0 } });
vm.runInContext(['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(root, f), 'utf8')).join('\n') + `
function log(m,c){ if(B) B.log.push({m,c}); }
function fxText(){} function fxShield(){} function fxFlash(){}
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){}
async function animPath(){} async function animRotate(){}
globalThis.T={
  start(){ UID=1; rndSeed(134); RUN={admiral:'vex',fac:'voidsworn',sector:1,fleet:[newShip('reliquary'),newShip('harrow')],relics:[],boons:[],stats:{},fallen:[]};
    startBattle({kind:'battle',fac:'hegemony',seed:134,obj:'rout',shape:'open',map:'open',dep:'line',enemies:[{tpl:'h_picket'},{tpl:'h_interdictor'}]});
    for(const u of B.units) u.activated=false; return alive('player').find(u=>u.ab==='launch'); },
  wings:squadronsOf, startSideTurn, swarmPhase, canAbility, useAbility, sqOrder, sqPlan, launchHexes, replaceWings,
  round(){ B.round++; startSideTurn('player'); },
  block(c){ for(const h of launchHexes(c)){ const x=makeUnit('player','warden'); x.q=h.q; x.r=h.r; B.units.push(x); } },
  foe(){ return alive('enemy')[0]; }
};`, ctx);
const T = ctx.T;
async function main() {
  let c = T.start(), wings = T.wings(c);
  assert.strictEqual(wings.length, c.hangar, 'full opening flight without clicks');
  const opening = wings.map(w => [w.q,w.r]);
  await T.swarmPhase('player');
  assert(wings.every(w => w.activated), 'all opening wings act');
  assert(wings.some((w,i) => w.q !== opening[i][0] || w.r !== opening[i][1]), 'opening wings pursue enemies');
  const once = wings.map(w => [w.q,w.r]);
  await T.swarmPhase('player');
  assert.strictEqual(JSON.stringify(wings.map(w => [w.q,w.r])), JSON.stringify(once), 'no duplicate wing activation');
  wings[0].dead = true;
  const spare = c.spare;
  T.round();
  const replacement = T.wings(c).find(w => !wings.includes(w));
  assert(replacement, 'loss replaced automatically at round start');
  assert.strictEqual(c.spare, spare - 1);
  assert.strictEqual(c.abCd, 1);
  assert.strictEqual(replacement.mp, 0);
  assert(replacement.weapons.every(w => w.fired), 'replacement waits until next round');
  assert(!T.canAbility(c)); assert.strictEqual(await T.useAbility(c), false, 'no manual launch');
  T.replaceWings('player'); assert.strictEqual(c.spare, spare - 1, 'cooldown prevents another replacement');
  await T.swarmPhase('player');
  T.round(); assert(!replacement.activated, 'Classic mode resets wing activation each turn');
  assert(replacement.mp > 0 && replacement.weapons.every(w => !w.fired));
  await T.swarmPhase('player'); assert(replacement.activated);
  replacement.wingOrder = {kind:'guard',id:c.id};
  assert.strictEqual(T.sqOrder(replacement).t, c, 'friendly guard order survives');
  const enemy = T.foe(); replacement.wingOrder = {kind:'strike',id:enemy.id};
  assert.strictEqual(T.sqOrder(replacement).t, enemy, 'optional strike target survives');
  enemy.dead = true; assert.strictEqual(T.sqOrder(replacement), null, 'dead target clears order');
  c = T.start(); T.wings(c).forEach(w => { w.dead=true; });
  T.round(); assert.strictEqual(T.wings(c).length, 1, 'one replacement per round');
  c = T.start(); T.wings(c)[0].dead = true; c.spare = 0;
  T.round(); assert.strictEqual(T.wings(c).length, c.hangar - 1, 'empty reserves stay empty');
  c = T.start(); T.wings(c)[0].dead = true; c.abCd = 2;
  T.round(); assert.strictEqual(T.wings(c).length, c.hangar - 1, 'cooldown respected');
  c = T.start(); T.wings(c)[0].dead = true; const held = c.spare; T.block(c);
  T.round(); assert.strictEqual(c.spare, held, 'blocked launch does not spend reserves');
  c = T.start(); T.wings(c)[0].dead = true; c.dead = true;
  T.round(); assert.strictEqual(T.wings(c).length, c.hangar - 1, 'dead carrier cannot launch');
  console.log('PASS: automatic opening flight, shared AI, Classic rounds, replacements, reserves, cooldown, blocked hexes, dead carriers and optional orders.');
}
main().catch(e => { console.error(e); process.exitCode = 1; });
