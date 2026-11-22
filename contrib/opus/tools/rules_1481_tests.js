// Issue 1481 (independent game audit Nov 21, F-08 to F-11, F-14): the state half of the shield and ability fixes, on the
// browser rules (battle.js). Run from the repo root:
//   node contrib/opus/tools/rules_1481_tests.js
// The Godot twin godot/rules/test/rules_1481_test.gd checks these cases on rules.gd with the same names, plus the scene events. Every case fails on
// main before the fix (main 1a000813) except the good blink, which guards the refusal from going too far.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.resolve(__dirname, '..', '..', '..');
Date.now = () => 0; global.require = require; global.window = {}; global.document = undefined; global.performance = { now: () => 0 };
const STUB = String.raw`
function hook(){} function log(m,c){ if(B&&B.log) B.log.push({m,c}); } function fxText(){} function fxShield(){} function fxFlash(){}
async function animPath(u,path,opt){ if(opt&&opt.onLate) await opt.onLate(); }
async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; } async function animRotate(){} async function animWeapon(){} async function animExplode(){} async function animNova(){} async function animBlink(){}
async function fxRam(){} async function fxBoard(){} function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){} function fxCrit(){} function fxSectionDown(){} function tel(){} SPEED=0;
function mkRun(S){ UID=1; rndSeed(S.seed||7); AI_LEVEL='veteran';
 RUN={admiral:'vex',fac:S.pfac||'voidsworn',credits:0,cpCap:40,sector:1,relics:[],inventory:[],fleet:[],boons:[],patrons:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
 for(const t of S.fleet) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid; }
`;
const files = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8'));
console.debug = () => {};
vm.runInThisContext(files.join('\n') + '\n' + STUB + '\nglobalThis.__R={ get B(){ return B; }, set B(v){ B=v; }, set treeSkillOverride(v){}, run:(s)=>eval(s) };', { filename: 'bundle.js' });
const R = globalThis.__R, E = s => R.run(s);

// a fresh battle: the player fleet and the enemy hulls, open board, no terrain, no wings; units[] in fleet order then enemies
function fresh(fleet, fac, enemies, extra) {
  E(`mkRun(${JSON.stringify({ fleet, seed: 7, pfac: (extra && extra.pfac) || 'voidsworn' })});
     startBattle(${JSON.stringify(Object.assign({ kind: 'battle', fac, col: 3, seed: 7, obj: 'rout', shape: 'open', map: 'open', dep: 'line', enemies: enemies.map(tpl => ({ tpl })) }, (extra && extra.cfg) || {}))});
     B.terrain={}; for(const u of B.units) if(u.isSq) u.dead=true; B.log=[];`);
  const B = R.B, P = B.units.filter(u => u.side === 'player' && !u.isSq), En = B.units.filter(u => u.side === 'enemy' && !u.isSq);
  // spread them out so nothing is next to anything unless a case puts it there
  P.forEach((u, i) => { u.q = 8; u.r = 6 + 3 * i; u.facing = 0; });
  En.forEach((u, i) => { u.q = 16; u.r = 6 + 3 * i; u.facing = 3; });
  return { B, P, E: En };
}
const near = (a, b) => Math.abs(a - b) < 1e-9;
const wpn = (id, arc) => Object.assign(E('mkWeapon')(id, arc, {}), { fired: false, cdLeft: 0, off: 0 });

const CASES = [
  ['1: an ion storm that leaves under 1 point empties the pool', () => {
    const { B, P } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0];
    B.terrain[u.q + ',' + u.r] = 'storm'; u.st.shieldOff = 1; u.shp = 10.5; E('syncShields')(u);
    E('startSideTurn')('player');
    return [u.shp === 0, 'shp ' + u.shp]; }],
  ['2: a ram spends the shield through the shared spend (routing loss)', async () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const u = P[0], t = En[0];
    u.q = 5; u.r = 5; u.facing = 0; u.mp = 4; u.turnsLeft = 2; t.q = 8; t.r = 5; t.facing = 3; t.hp = 99999; t.maxHp = 99999;
    t.shp = 200; t.route = [0, 0, 0, 0]; const qd = E('shieldQuad')(t, u); t.route[qd] = 1; E('syncShields')(t);
    const info = E('ramInfo')(u), e = E('ramEstimate')(u, t, info.path.length);
    const want = Math.max(0, 200 - e.soak * 1.5 * (1 + E('SHIELD_ROUTE_LOSS')));
    await E('ramUnit')(u);
    return [e.soak > 0 && Math.abs(t.shp - want) < 1e-9, 'soak ' + e.soak + ', shp ' + t.shp + ', want ' + want]; }],
  ['5: a blink to a bad hex is refused before it counts or plays', async () => {
    const { B, P } = fresh(['i_blade'], 'hegemony', ['h_picket'], { pfac: 'ithar' }); const u = P[0]; u.abCd = 0;
    B.usage = { ab: {} }; E('UNDO={spent:false,stack:[1]}'); const q0 = u.q;
    const ok = await E('useAbility')(u, { hex: { q: q0 + 9, r: u.r } }); const counted = B.usage.ab.blink || 0, spent = E('UNDO.spent');
    E('UNDO=null');
    return [!ok && counted === 0 && !spent && u.q === q0, 'used ' + ok + ', counted ' + counted + ', undo spent ' + spent]; }],
  ['5: a good blink still jumps', async () => {
    const { B, P } = fresh(['i_blade'], 'hegemony', ['h_picket'], { pfac: 'ithar' }); const u = P[0]; u.abCd = 0; B.usage = { ab: {} };
    const h = E('blinkHexes')(u)[0]; const ok = await E('useAbility')(u, { hex: { q: h.q, r: h.r } });
    return [ok && u.q === h.q && u.r === h.r && B.usage.ab.blink === 1, 'used ' + ok + ' at ' + u.q + ',' + u.r]; }],
  ['5: a nova with no hex is refused, nothing counted', async () => {
    const { B, P } = fresh(['ascendant'], 'hegemony', ['h_picket']); const u = P[0]; u.abCd = 0; B.usage = { ab: {} };
    const ok = await E('useAbility')(u, null); const counted = B.usage.ab.nova || 0;
    return [!ok && counted === 0 && u.abCd === 0, 'used ' + ok + ', counted ' + counted]; }],
];

(async () => {
  let pass = 0, fail = 0;
  for (const [name, fn] of CASES) {
    try { const [ok, info] = await fn(); if (ok) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + ': ' + info); } }
    catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); }
  }
  console.log('\nIssue 1481 rules tests (battle.js): ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
})();
