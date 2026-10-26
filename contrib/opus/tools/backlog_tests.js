// Game backlog checks (stream B step 3, Oct 26): v54 doctrines, boon decline and reroll, rule-changing and legendary boons, rarity clauses,
// the class refit track, AI hysteresis. Run from the repo root: node contrib/opus/tools/backlog_tests.js
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0; const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, migrateRun, newShip, startBattle, HULLS, BOONS, fireWeapon, computeReach, giveOrder, braceMul, applyHit, startSideTurn, turnStart, killUnit,
  CHORUS_BITE, FEED_CAP, rollBoonOffer, boonReroll, boonDecline, boonRerollCost, boonDeclineCred, derive, buyClassTrack, classTrack, aiPickPrimary, dmgMult, hitChance, canFire, useCommand, runCommand, landVolley };
`);
const base = (o) => Object.assign({ fac: 'voidsworn', admiral: 'vex', credits: 500, cpCap: 30, sector: 1, relics: [], inventory: [], boons: [], patrons: ['iron', 'storm', 'star', 'rook'], map: { cols: [] }, fleet: [] }, o || {});
function battle(fac, ptpls, efac, etpls, boons) { T.RUN = T.migrateRun(base({ fac, fleet: ptpls.map(t => T.newShip(t)), boons: (boons || []).map(id => ({ id, r: 0 })) })); T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.startBattle({ kind: 'battle', fac: efac, col: 3, enemies: etpls.map(tpl => ({ tpl })), shape: 'open', map: 'storm', obj: 'rout', seed: 11, dep: 'line' });
  const B = T.B; B.terrain = {}; for (const u of B.units.filter(x => x.isSq)) u.dead = true; return B; }
const P = () => T.B.units.filter(u => u.side === 'player' && !u.isSq), E = () => T.B.units.filter(u => u.side === 'enemy' && !u.isSq);
const put = (u, q, r, f) => { u.q = q; u.r = r; if (f != null) u.facing = f; };
const gun = (u, t) => u.weapons.findIndex(w => w.k !== 'flak' && T.canFire(u, w, t));

check('v54: after firing a ship cannot move on; an Ithar hull may fade with half its movement, never over rocks or ships', async () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const u = P()[0], t = E()[0]; put(u, 8, 10, 0); put(t, 11, 10, 3); u.mp = 4;
  const before = T.computeReach(u).map.size; await T.fireWeapon(u, gun(u, t), t); const after = T.computeReach(u).map.size;
  battle('ithar', ['i_song'], 'hegemony', ['h_dominion']); const i = P()[0], t2 = E()[0]; put(i, 8, 10, 0); put(t2, 11, 10, 3); i.mp = 6;
  await T.fireWeapon(i, gun(i, t2), t2); const reach = T.computeReach(i), far = Math.max(...[...reach.map.values()].map(s => s.cost)), over = [...reach.map.values()].some(s => s.overs);
  return before > 0 && after === 0 && i.postMp === 3 && far <= 3 && !over; });
check('v54: a Command barrage (free volley) leaves movement as it was', async () => {
  battle('voidsworn', ['penitent', 'harrow'], 'hegemony', ['h_dominion']); const [u] = P(), t = E()[0]; put(u, 8, 10, 0); put(t, 11, 10, 3); T.B.round = 3;
  await T.runCommand('player', { id: 'barrage', n: 'Fire for effect' }, 2); return !u.postFire && T.computeReach(u).map.size > 0; });
check('v54: Chorus hulls regrow a share of the hull damage they deal at 1 to 2 hexes, inside the feed cap', async () => {
  battle('chorus', ['b_razor'], 'hegemony', ['h_dominion']); const u = P()[0], t = E()[0]; put(u, 8, 10, 0); put(t, 10, 10, 3); u.hp = 40; t.sh = [0, 0, 0, 0];
  const res = { shield: 0, hull: 0, crits: 0, hits: 0, misses: 0 }; await T.landVolley(u, u.weapons[0], t, { quad: 0, shBefore: 0, shots: [true, true], called: null, res });
  return res.hull > 0 && u.hp === 40 + Math.min(Math.round(res.hull * T.CHORUS_BITE), Math.round(u.maxHp * T.FEED_CAP)); });
check('v54: a bracing Voidsworn hull covers one adjacent ally facing the same way; Shield Wall covers every neighbour', () => {
  battle('voidsworn', ['penitent', 'harrow', 'warden'], 'hegemony', ['h_dominion']); const [a, b, c] = P(); put(a, 8, 10, 0); put(b, 9, 10, 0); put(c, 8, 11, 3);
  T.giveOrder(a, 'brace'); const one = T.braceMul(b) < 1 && T.braceMul(c) === 1;
  battle('hegemony', ['h_vanguard', 'h_picket', 'h_picket'], 'corsair', ['c_hulk'], ['i_wall']); const [x, y, z] = P(); put(x, 8, 10, 0); put(y, 9, 10, 0); put(z, 8, 11, 3);
  T.giveOrder(x, 'brace'); const all = T.braceMul(y) < 1 && T.braceMul(z) < 1; return one && all; });
check('v54: a Hegemony ion hit stops that facing regenerating at the next turn start', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_interdictor']); const t = P()[0], h = E()[0]; const ion = h.weapons.find(w => w.ion); t.sh = [1, 1, 1, 1]; t.regen = 5;
  T.applyHit(h, ion, t, 5, 0); const s0 = t.sh.slice(); T.startSideTurn('player'); return t.sh[0] === s0[0] && t.sh[1] === Math.min(t.shMax, s0[1] + 5); });
check('boons: decline pays credits; reroll costs credits, once per reward, and the price grows', () => {
  T.RUN = T.migrateRun(base({ credits: 100 })); T.RUN.reward = { boonOffer: T.rollBoonOffer('iron', 0) }; const c0 = T.boonRerollCost(); const r1 = T.boonReroll('iron', 0), r2 = T.boonReroll('iron', 0);
  const paid = T.RUN.credits === 100 - c0, grew = T.boonRerollCost() > c0; const cr = T.boonDecline(); return !!r1 && r2 === null && paid && grew && cr === T.boonDeclineCred(); });
check('legendaries: offered only at elite or flagship rewards, once two boons of that patron are held; never in normal pools', () => {
  T.RUN = T.migrateRun(base({ boons: [{ id: 'i_broad', r: 0 }] })); const a = T.rollBoonOffer('iron', 1).some(o => T.BOONS[o.id].leg);
  T.RUN.boons.push({ id: 'i_plate', r: 0 }); const b = T.rollBoonOffer('iron', 1).find(o => T.BOONS[o.id].leg), c = T.rollBoonOffer('iron', 0).some(o => T.BOONS[o.id].leg);
  let normal = 0; for (let k = 0; k < 40; k++) normal += T.rollBoonOffer('storm', 0).filter(o => T.BOONS[o.id].leg).length;
  return !a && b && b.id === 'L_iron' && b.r === 3 && !c && normal === 0; });
check('rule boons: Chain Lightning, Marked for Death, Slip the Net, Spread Pattern, Brood Tithe all do what they say', async () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion'], ['s_chain']); let u = P()[0], t = E()[0]; t.sh = [1, 30, 30, 30]; const res = { shield: 0, hull: 0, crits: 0, hits: 0, misses: 0 };
  await T.landVolley(u, u.weapons[0], t, { quad: 0, shBefore: 1, shots: [true], called: null, res }); const chain = t.sh[1] === 20 && t.sh[3] === 20 && t.sh[2] === 30;
  battle('voidsworn', ['penitent', 'harrow'], 'hegemony', ['h_dominion'], ['a_mark']); u = P()[0]; t = E()[0]; const w = u.weapons.find(x => x.k === 'lance'); const h0 = T.hitChance(P()[1], P()[1].weapons[1], t);
  await T.landVolley(u, w, t, { quad: 0, shBefore: 0, shots: [true], called: null, res: { shield: 0, hull: 0, crits: 0, hits: 0, misses: 0 } }); const h1 = T.hitChance(P()[1], P()[1].weapons[1], t); const mark = h1 - h0 === 10 || h1 === 95;
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion'], ['r_slip']); u = P()[0]; t = E()[0]; put(u, 8, 10, 0); put(t, 11, 10, 3); u.mp = 4; await T.fireWeapon(u, gun(u, t), t); const slip = u.postMp === 2 && T.computeReach(u).map.size > 0;
  battle('voidsworn', ['harrow'], 'hegemony', ['h_dominion', 'h_picket'], ['e_spread']); u = P()[0]; const [d, pk] = E(); put(u, 8, 10, 0); put(d, 12, 10, 3); put(pk, 13, 10, 3);
  await T.fireWeapon(u, u.weapons.findIndex(x => x.k === 'torp'), d); put(d, 12, 14); const p0 = pk.hp + pk.sh.reduce((a, b) => a + b, 0); T.B.round++; await T.turnStart('player'); const spread = pk.hp + pk.sh.reduce((a, b) => a + b, 0) < p0;
  battle('voidsworn', ['reliquary', 'penitent'], 'hegemony', ['h_picket', 'h_picket', 'h_picket', 'h_picket'], ['h_brood']); const car = P()[0]; put(car, 8, 10); const n0 = T.B.units.filter(x => x.isSq && !x.dead).length; await T.killUnit(E()[0], P()[1]);
  const brood = T.B.units.filter(x => x.isSq && !x.dead).length === n0 + 1;
  if (!(chain && mark && slip && spread && brood)) throw new Error(JSON.stringify({ chain, mark, slip, spread, brood })); return true; });
check('rarity changes the effect: Epic Long Silence adds lance range, Epic Unbroken Line adds evasion, Epic Chain Reaction burns', () => {
  const R = T.BOONS; const c = R.a_long.fx(1), e = R.a_long.fx(2), l = R.i_line.fx(2), x = R.e_chain.fx(2);
  return !c.lanceRange && e.lanceRange === 1 && l.lineEv === 5 && x.chainFire === 1 && /Epic/.test(R.a_long.d(2)) && !/Epic/.test(R.a_long.d(1.5)); });
check('class refit track: every ship of that class gains 6% hull and damage per level, bought at the yard, at most 3', () => {
  T.RUN = T.migrateRun(base({ credits: 1000, fleet: [T.newShip('warden'), T.newShip('warden'), T.newShip('penitent')] })); const h0 = T.derive(T.RUN.fleet[0]).maxHp, p0 = T.derive(T.RUN.fleet[2]).maxHp;
  for (let k = 0; k < 5; k++) T.buyClassTrack('Frigate'); const d = T.derive(T.RUN.fleet[0]);
  return T.classTrack('Frigate') === 3 && d.maxHp === Math.round(T.HULLS.warden.hp * 1.18) && Math.abs(d.dmg - 1.18) < 1e-9 && T.derive(T.RUN.fleet[2]).maxHp === p0 && h0 === T.HULLS.warden.hp; });
check('AI hysteresis: a ship keeps its last primary target while it is worth 85% of the best', () => {
  battle('voidsworn', ['penitent', 'penitent'], 'hegemony', ['h_dominion']); const [a, b] = P(), e = E()[0]; put(e, 12, 10, 3); put(a, 9, 10, 0); put(b, 9, 11, 0);
  const ws = e.weapons.filter(w => w.k !== 'flak'); const p1 = T.aiPickPrimary(e, ws, null); const other = p1 === a ? b : a; e.aiLastT = other;
  const p2 = T.aiPickPrimary(e, ws, null); return p2 === other; });
(async () => { for (const [name, fn] of tests) { try { const r = await fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
  console.log('\nBacklog tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0; })();
