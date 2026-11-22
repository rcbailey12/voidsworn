// Issue 1479 (independent game audit Nov 21, F-01 and F-03): battle endings when a boarding overruns a special enemy, when
// a carrier is captured, and when an Eclipse wreck is about to rise, on the browser rules (battle.js). Run from the repo root:
//   node contrib/opus/tools/rules_1479_tests.js
// The Godot twin godot/rules/test/rules_1479_test.gd checks the same cases on rules.gd with the same names. Every case fails
// on main 6aca4f9e except two guards: an ordinary hull is still captured, and a wreck with no room lets the fight end.
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
  B.cp0 = null; // no rout check: these cases are about who is left
  return { B, P, E: En };
}
const near = (a, b) => Math.abs(a - b) < 1e-9;
const wpn = (id, arc) => Object.assign(E('mkWeapon')(id, arc, {}), { fired: false, cdLeft: 0, off: 0 });


// u boards t from the next hex with a crew t cannot hold
async function board(u, t) { u.q = t.q - 1; u.r = t.r; u.crew = 9999; u.boarded = false; u.mp = 4; t.crew = 1; t.repel = false; return E('boardUnit')(u, t); }
const legion = (B, side) => { B.legion[side].max = 1; B.legion[side].used = 0; };

const CASES = [
  ['1: overrunning the Nemesis flagship destroys it', async () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const t = En[0]; t.nemFlag = true;
    await board(P[0], t);
    return [!!t.dead && t.side === 'enemy' && !t.captured && t.killCause === 'dark', 'dead ' + t.dead + ', side ' + t.side + ', captured ' + t.captured]; }],
  ['1: overrunning a hunt target ends the fight as its kill does', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const t = En[0]; t.flagship = true; B.obj = { type: 'hunt' };
    await board(P[0], t);
    return [B.over === 'win' && !!B.routed && !!t.dead && t.side === 'enemy', 'over ' + B.over + ', dead ' + t.dead + ', side ' + t.side]; }],
  ['1: overrunning a convoy transport counts as a transport destroyed', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket', 'h_picket']); const t = En[0]; t.transport = true; En[1].transport = true;
    B.obj = { type: 'intercept', need: 2, total: 2 };
    await board(P[0], t);
    return [!!t.dead && !t.fled && t.side === 'enemy' && B.obj.kill === 1 && !B.over, 'dead ' + t.dead + ', side ' + t.side + ', kill ' + B.obj.kill + ', over ' + B.over]; }],
  ['1: an ordinary hull is still captured (guard)', async () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const t = En[0];
    await board(P[0], t);
    return [t.side === 'player' && !!t.captured && !t.dead, 'side ' + t.side + ', captured ' + t.captured]; }],
  ["2: a captured carrier's wings lose their carrier", async () => {
    const { P, E: En } = fresh(['penitent'], 'corsair', ['c_hulk', 'c_hulk']); const c = En[0];
    const w = E('makeWing')(c, E('launchHexes')(c)[0], E('wingKind')(c));
    await board(P[0], c);
    return [c.side === 'player' && w.side === 'enemy' && w.parent == null, 'carrier ' + c.side + ', wing ' + w.side + ', wing parent ' + w.parent]; }],
  ['3: the last Eclipse ship of yours reassembling keeps the fight open, and it rises', async () => {
    const { B, P, E: En } = fresh(['d_jackal'], 'hegemony', ['h_picket'], { pfac: 'deathless' }); const u = P[0]; u.pflag = false; legion(B, 'player');
    u.hp = 0; await E('killUnit')(u, En[0]);
    const open = !B.over && u.riseAt != null;
    B.round = u.riseAt; E('legionTurn')('player');
    return [open && !u.dead && !B.over, 'open ' + open + ', over ' + B.over + ', dead ' + u.dead]; }],
  ['3: the last enemy Eclipse ship reassembling is not a win yet', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'deathless', ['d_jackal']); const t = En[0]; legion(B, 'enemy');
    t.hp = 0; await E('killUnit')(t, P[0]);
    return [!B.over && t.riseAt != null, 'over ' + B.over + ', riseAt ' + t.riseAt]; }],
  ['3: a wreck with no room to rise lets the fight end', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'deathless', ['d_jackal']); const t = En[0]; legion(B, 'enemy');
    t.hp = 0; await E('killUnit')(t, P[0]);
    for (const h of E('boardHexes')()) B.terrain[h.q + ',' + h.r] = 'rock';
    B.round = t.riseAt; E('legionTurn')('enemy');
    return [B.over === 'win' && !!t.dead, 'over ' + B.over + ', dead ' + t.dead]; }],
  ['3: a ship rising next round counts toward a breakthrough', async () => {
    const { B, P, E: En } = fresh(['d_jackal', 'd_jackal'], 'hegemony', ['h_picket'], { pfac: 'deathless' }); const a = P[0], b = P[1]; b.pflag = false; legion(B, 'player');
    B.obj = { type: 'break', need: 2 }; a.exited = true; a.dead = true; a.fled = true;
    b.hp = 0; await E('killUnit')(b, En[0]);
    return [!B.over && b.riseAt != null, 'over ' + B.over + ', riseAt ' + b.riseAt]; }],
];

(async () => {
  let pass = 0, fail = 0;
  for (const [name, fn] of CASES) {
    try { const [ok, info] = await fn(); if (ok) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + ': ' + info); } }
    catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); }
  }
  console.log('\nIssue 1479 rules tests (battle.js): ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
})();
