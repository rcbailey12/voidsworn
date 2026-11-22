// Issue 1560 (battle rules audit, Nov 21 2026) and R396 (Ryan, Nov 22 2026: firing ends a non-Glasswright ship's movement), on the
// browser rules (battle.js). Run from the repo root:
//   node contrib/opus/tools/rules_1560_tests.js
// The Godot twin godot/rules/test/rules_1560_test.gd checks the same cases on rules.gd, with the same names. Every case fails on
// main before the fix (main 8de3af33).
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
  // ---------- R396 ----------
  ['R396: a Sunward ship that has fired cannot turn in place', () => {
    const { P } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0];
    u.mp = 4; u.turnsLeft = 2; u.postFire = true; u.postMp = 0;
    return [E('canRotate')(u) === false, 'canRotate ' + E('canRotate')(u)]; }],
  ['R396: a Glasswright turn after firing spends its post-fire move', async () => {
    const { P } = fresh(['i_blade'], 'hegemony', ['h_picket'], { pfac: 'ithar' }); const u = P[0];
    u.mp = 4; u.turnsLeft = 2; u.postFire = true; u.postMp = 2; u.pivotUsed = true;
    await E('rotateUnit')(u, 1); await E('rotateUnit')(u, 1);
    return [u.postMp === 0 && E('postFireMp')(u) === 0, 'postMp ' + u.postMp + ', postFireMp ' + E('postFireMp')(u)]; }],
  ['R396: no ram after firing (non-Glasswright)', () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0], t = En[0];
    u.q = 5; u.r = 5; u.facing = 0; t.q = 8; t.r = 5; u.mp = 4;
    const before = !!E('ramInfo')(u); u.postFire = true; u.postMp = 0; const after = E('ramInfo')(u);
    return [before && after === null, 'ram before firing ' + before + ', after ' + !!after]; }],
  // ---------- group A ----------
  ['1: a hit never heals a shieldless ship (damage taken stays at least 5%)', () => {
    const { P } = fresh(['penitent'], 'hegemony', ['h_picket']); const t = P[0];
    t.shMax = 0; t.ironCarry = .95; const m = E('cmdTaken')(t);
    return [near(m, .05), 'cmdTaken ' + m]; }],
  ['2: a torpedo rear hit gives the real ship its Cut and Turn free turn', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'deathless', ['d_harvester']); const u = P[0], t = En[0];
    for (const x of En) x.weapons = [];
    u.q = 5; u.r = 5; u.facing = 0; t.q = 8; t.r = 5; t.facing = 0; t.hp = t.maxHp = 9999;
    u.weapons = [wpn('torp', 'F')]; B.tree = [{ k: 'cutTurn', key: 't1560:cutTurn' }]; u.treeFreeTurn = 0;
    for (let i = 0; i < 20 && u.treeFreeTurn !== 1; i++) { u.weapons[0].fired = false; u.weapons[0].cdLeft = 0; u.postFire = false; await E('fireWeapon')(u, 0, t); }
    return [u.treeFreeTurn === 1, 'treeFreeTurn on the real ship ' + u.treeFreeTurn]; }],
  ['3: escorts that flee are not raised again by the legion', () => {
    const { B, E: En } = fresh(['penitent'], 'deathless', ['d_harvester', 'd_jackal', 'd_scythe']);
    B.cfg.kind = 'boss'; const boss = En[0]; boss.boss = true; boss.hp = Math.floor(boss.maxHp * .4);
    const wreck = En[1]; wreck.dead = true; wreck.riseAt = B.round; wreck.fled = false;
    E('escortsBreak')(); const risen = E('legionTurn')('enemy');
    return [wreck.dead === true && wreck.riseAt == null && risen.length === 0, 'wreck dead ' + wreck.dead + ', riseAt ' + wreck.riseAt + ', risen ' + risen.length]; }],
  ['4: the rout line is checked as soon as the escorts flee', () => {
    const { B, E: En } = fresh(['penitent'], 'deathless', ['d_scythe', 'd_harvester', 'd_harvester']);
    B.cfg.kind = 'boss'; const boss = En[0]; boss.boss = true; boss.hp = Math.floor(boss.maxHp * .4);
    E('escortsBreak')();
    return [B.over === 'win', 'over ' + B.over]; }],
  ['5: Fleet drill keeps a wider tree sync radius', () => {
    const { B } = fresh(['penitent'], 'hegemony', ['h_picket']);
    B.syncR = { player: 8 }; E('applyVerb')('drill');
    return [E('syncR')('player') === 8 && E('syncDmg')('player') >= .2, 'syncR ' + E('syncR')('player') + ', syncDmg ' + E('syncDmg')('player')]; }],
  ['6: a ship that broke through does not charge the Command as a loss', () => {
    const { B, P } = fresh(['penitent', 'harrow'], 'hegemony', ['h_picket']);
    B.round = 1; P[1].dead = true; P[1].exited = true; P[1].fled = true;
    return [E('cmdTier')() === 0, 'cmdTier ' + E('cmdTier')()]; }],
  // ---------- group B ----------
  ['7: point defence adds no attack value against ships', () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0], t = En[0];
    u.q = 5; u.r = 5; t.q = 7; t.r = 5; const flak = wpn('flak', 'T');
    const v = E('evalOffense')(u, [flak], [t]), vv = E('evalOffenseVet')(u, [flak], [t], null);
    return [v === 0 && vv === 0, 'evalOffense ' + v + ', evalOffenseVet ' + vv]; }],
  ['8: a captured carrier stops leading its old side\'s wings', () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const c = P[0], w = En[1];
    w.isSq = true; w.parent = c.id; c.stance = 'screen';
    const n = E('squadronsOf')(c).length, st = E('wingStance')(w);
    return [n === 0 && st === 'strike', 'wings counted ' + n + ', wing stance ' + st]; }],
  ['9: the forecast meets the same armour as the hit (gauss, shred)', () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0], t = En[0];
    u.q = 5; u.r = 5; u.facing = 0; t.q = 7; t.r = 5; t.facing = 3; t.shp = 0; E('syncShields')(t); t.armor = .4; t.shredded = 0;
    const w = Object.assign(wpn('gauss', 'F'), { armorPierce: .5, pierce: 0 });
    const e = E('expectedVs')(u, w, t), want = e.raw * (1 - .2) * E('braceMul')(t) * E('cmdTaken')(t) * E('guardMul')(t);
    return [near(e.hull, want), 'hull ' + e.hull + ', want ' + want]; }],
  ['10: a planned position never counts the ship itself as an escort', () => {
    const { P } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0];
    u.q = 6; u.r = 6; u.fx = Object.assign({}, u.fx, { lineGuard: .3 });
    const v = E('stateView')(u, { q: 7, r: 6, f: 0 }); const m = E('guardMul')(v);
    return [m === 1, 'guardMul ' + m]; }],
  ['11: fleet focus reads the shield pool, not the four side catches', () => {
    const { P } = fresh(['penitent'], 'hegemony', ['h_picket']); const t = P[0], sh = E('aiShooters')();
    t.sh = [0, 0, 0, 0]; const a = E('aiFocusVal')(t, sh); t.sh = [999, 999, 999, 999]; const b = E('aiFocusVal')(t, sh);
    return [a === b, 'with no side catches ' + a + ', with 999 each ' + b]; }],
  ['12: in alternating play a ship that has acted, or a cooling gun, is no threat this round', () => {
    const { B, P } = fresh(['penitent'], 'hegemony', ['h_picket']); const p = P[0]; B.alt = true;
    const w = p.weapons.find(x => x.k !== 'flak'); w.fired = false; w.cdLeft = 0; p.braced = false;
    p.activated = true; const a = E('aiGunLive')(p, w); p.activated = false; w.cdLeft = 1; const b = E('aiGunLive')(p, w);
    return [a === false && b === false, 'activated ' + a + ', cooling ' + b]; }],
  // ---------- group C ----------
  ['13: a turn in place does not give back the free dive (Vell T2a)', () => {
    const { B, P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const u = P[0];
    u.q = 8; u.r = 8; u.facing = 0; u.mp = 4; u.turnsLeft = 2; En[0].q = 9; En[0].r = 8; En[1].q = 9; En[1].r = 9;
    B.tree = [{ k: 'mirrorAside', key: 't1560:mirrorAside' }]; B.cmd = { id: 'surge', side: 'player', round: B.round, tier: 0 };
    const two = E('computeReach')(u).states.filter(s => s.path.filter(p => p.dived).length >= 2);
    return [two.length === 0, 'states that dive twice for free ' + two.length]; }],
  ['15: no ram after firing, from the move overlay either', () => {
    const { P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0], t = En[0];
    u.q = 4; u.r = 5; u.facing = 0; t.q = 8; t.r = 5; u.mp = 4; u.postFire = true; u.postMp = 0;
    const r = E('ramFrom')(u, { q: 5, r: 5, f: 0, cost: 1 });
    return [r === null, 'ram from the overlay ' + !!r]; }],
  ['16: the corona splash hits only a ship next to the target', async () => {
    const { B, P, E: En } = fresh(['penitent'], 'hegemony', ['h_picket', 'h_picket']); const u = P[0], t = En[0], far = En[1];
    u.q = 5; u.r = 5; u.facing = 0; t.q = 8; t.r = 5; far.q = 8; far.r = 12; const hp0 = far.hp;
    const w = wpn('doom', 'F'); u.weapons = [w];
    B.tree = [{ k: 'arcsWarm', key: 't1560:arcsWarm', n: .25 }]; B.volleyMul = { side: 'player', m: 1 };
    const res = { shield: 0, hull: 0, crits: 0, hits: 0, misses: 0, sys: null };
    await E('landVolley')(u, w, t, { quad: E('shieldQuad')(t, u), shBefore: t.shp || 0, shots: [true], called: null, res });
    return [far.hp === hp0, 'ship 7 hexes away lost ' + (hp0 - far.hp)]; }],
  ['17: Full ahead opens again on the next turn', () => {
    const { P } = fresh(['penitent'], 'hegemony', ['h_picket']); const u = P[0];
    u.moved = true; E('startSideTurn')('player');
    return [u.moved === false && E('canOrder')(u, 'full') === true, 'moved ' + u.moved + ', full ' + E('canOrder')(u, 'full')]; }],
  ['18: the Garrison ally never turns a loss into a retreat', () => {
    const { P } = fresh(['penitent', 'harrow'], 'hegemony', ['h_picket']);
    P[0].dead = true; P[1].reinf = true;
    return [E('survivorsP')() === 0, 'survivors ' + E('survivorsP')()]; }],
  ['18: the Chorus free pivot is offered with no movement left', () => {
    const { P } = fresh(['b_spitter'], 'hegemony', ['h_picket'], { pfac: 'chorus' }); const u = P[0];
    u.mp = 0; u.turnsLeft = 1; u.pivotUsed = false; u.postFire = false;
    const turned = E('computeReach')(u).states.filter(s => s.q === u.q && s.r === u.r && s.f !== u.facing);
    return [turned.length > 0, 'turned states ' + turned.length]; }],
];

(async () => {
  let pass = 0, fail = 0;
  for (const [name, fn] of CASES) {
    try { const [ok, info] = await fn(); if (ok) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + ': ' + info); } }
    catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); }
  }
  console.log('\nIssue 1560 rules tests (battle.js): ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
})();
