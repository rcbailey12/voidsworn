// R246 shield pool checks (issue 371): one pool per ship, per-side coverage, lossy routing toward the
// side under fire, and the pool dropping everywhere at once. Run from the repo root:
//   node contrib/opus/tools/shield_pool_tests.js [fixtures.json]
// With a path it also writes the browser results for the Godot twin, godot/rules/test/shield_pool_test.gd:
// the coverage of every shielded hull and scripted hit and turn sequences with the pool, catches and routing after each step.
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
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, set B(v){ B=v; }, migrateRun, newShip, startBattle, makeUnit, HULLS, applyHit, startSideTurn, SHIELD_POOL_MULT, SHIELD_ROUTE_LOSS, SHIELD_ROUTE_BOOST, SHIELD_COV, SHIELD_COV_FAC, syncShields, shieldCov };
`);
const base = (o) => Object.assign({ fac: 'voidsworn', admiral: 'vex', credits: 500, cpCap: 30, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] }, fleet: [] }, o || {});
function battle(fac, ptpls, efac, etpls) { T.RUN = T.migrateRun(base({ fac, fleet: ptpls.map(t => T.newShip(t)) })); T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.startBattle({ kind: 'battle', fac: efac, col: 3, enemies: etpls.map(tpl => ({ tpl })), shape: 'open', map: 'open', obj: 'rout', seed: 7, dep: 'line' });
  T.B.terrain = {}; for (const u of T.B.units.filter(x => x.isSq)) u.dead = true; return T.B; }
const P = () => T.B.units.filter(u => u.side === 'player' && !u.isSq), E = () => T.B.units.filter(u => u.side === 'enemy' && !u.isSq);
const put = (u, q, r, f) => { u.q = q; u.r = r; if (f != null) u.facing = f; };

check('the pool is shMax = sh x SHIELD_POOL_MULT and the four catches derive from pool x coverage', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_picket']); const u = P()[0];
  const cov = T.shieldCov(u.fac, u.cls);
  return u.shp === u.shMax && u.shMax === Math.round(T.B.units.find(x => x.tpl === 'penitent').t.sh * T.SHIELD_POOL_MULT)
    && u.sh.every((v, i) => v === Math.round(u.shp * cov[i])) && cov[2] < cov[0]; });
check('a hit drains the pool, not one facing: every side catch drops at once', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const t = P()[0], h = E()[0]; put(t, 8, 10, 0); put(h, 11, 10, 3);
  const before = t.sh.slice(), p0 = t.shp; const w = h.weapons.find(x => x.k !== 'flak');
  T.applyHit(h, w, t, 6, 0);
  return t.shp < p0 && t.sh.every((v, i) => v <= before[i]) && t.sh.some((v, i) => v < before[i]); });
check('routing toward the side under fire is lossy: the same hit drains more pool once the side is routed', () => {
  const two = () => { battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const t = P()[0], h = E()[0]; put(t, 8, 10, 0); put(h, 11, 10, 3);
    const w = h.weapons.find(x => x.k !== 'flak'); T.applyHit(h, w, t, 6, 0); return { t, h, w }; };
  const a = two(); const aBefore = a.t.shp; T.applyHit(a.h, a.w, a.t, 6, 0); const aDrain = aBefore - a.t.shp;   // second hit, side routed
  const b = two(); const bBefore = b.t.shp; b.t.route = [0, 0, 0, 0]; T.applyHit(b.h, b.w, b.t, 6, 0); const bDrain = bBefore - b.t.shp; // same hit, routing cleared
  const extra = aDrain - bDrain; // the routing loss on top of the damage stopped
  const ratio = extra / bDrain;  // equals SHIELD_ROUTE_LOSS: bDrain is the damage stopped, extra is the loss
  return a.t.shp < b.t.shp && ratio > T.SHIELD_ROUTE_LOSS - 0.05 && ratio < T.SHIELD_ROUTE_LOSS + 0.05; });
check('when the pool empties, every side reads 0 at once', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const t = P()[0], h = E()[0]; put(t, 8, 10, 0); put(h, 11, 10, 3);
  t.shp = 3; T.syncShields(t); const w = h.weapons.find(x => x.k !== 'flak');
  for (let i = 0; i < 4 && t.shp > 0; i++) { w.fired = false; T.applyHit(h, w, t, 10, 0); }
  return t.shp === 0 && t.sh.every(x => x === 0); });
check('the pool regens as one number at turn start and routing resets', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const u = P()[0]; u.shp = 2; u.route = [1, 0, 0, 0]; T.syncShields(u);
  T.startSideTurn('player');
  return u.shp === Math.min(u.shMax, 2 + u.regen) && u.route.every(x => !x); });
check('Chorus and Eclipse hulls carry no shield pool at all', () => {
  battle('chorus', ['b_razor'], 'hegemony', ['h_picket']);
  if (P()[0].shMax !== 0) return false;
  T.RUN = T.migrateRun(base({ fac: 'deathless', fleet: [T.newShip('d_jackal')] })); T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, enemies: [{ tpl: 'h_picket' }], shape: 'open', map: 'open', obj: 'rout', seed: 7, dep: 'line' });
  return T.B.units.find(x => x.tpl === 'd_jackal').shMax === 0; });
check('a pool under 1 point is empty: the last hit on an unrouted side drops every side at once', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const t = P()[0], h = E()[0];
  t.shp = 1.4; t.route = [0, 0, 0, 0]; T.syncShields(t); const w = h.weapons.find(x => x.k !== 'flak');
  T.applyHit(h, w, t, 20, 0);
  return t.shp === 0 && t.sh.every(x => x === 0); });
check('Chain Lightning on a broken pool cuts the next recharge, once', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const u = P()[0]; u.shp = 0; u.regen = 9; u.chainCut = 1 / 3; T.syncShields(u);
  T.startSideTurn('player'); const first = u.shp; T.startSideTurn('player');
  return first === 6 && u.shp === 15 && u.chainCut === 0; });
check('a Hegemony ion hit reports the lock and stops the pool recharging for one turn start', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const t = P()[0], h = E()[0]; const w = h.weapons.find(x => x.ion && x.k !== 'flak');
  const ionHit = T.applyHit(h, w, t, 4, 0);
  const plainHit = T.applyHit(h, { ...w, ion: false }, t, 4, 0);
  const p1 = t.shp; T.startSideTurn('player'); const locked = t.shp === p1; T.startSideTurn('player');
  return ionHit.regenLock === true && !('regenLock' in plainHit) && locked && t.shp === Math.min(t.shMax, p1 + t.regen); });
check('an ion lock still re-derives the catches when routing clears at turn start (pool 20, routed starboard)', () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); const u = P()[0]; u.shp = 20; u.route = [0, 1, 0, 0]; T.syncShields(u);
  const routed = u.sh.slice(); u.regenLock = 1; T.startSideTurn('player');
  u.route = [0, 0, 0, 0]; const fresh = u.sh.slice(); T.syncShields(u);
  return u.shp === 20 && routed[1] > fresh[1] && u.sh.every((v, i) => v === fresh[i]); });
// ---- Godot twin fixtures (shield_pool_test.gd replays these sequences on rules.gd and compares every step) ----
const SEQS = [
  { note: 'Sunward cruiser: three prow hits (the second and third routed at a loss), a rear hit, a turn start, then hits until the pool empties',
    pfac: 'voidsworn', p: 'penitent', efac: 'hegemony', e: 'h_dominion',
    ops: [['hit', 6, 0, 0], ['hit', 6, 0, 0], ['hit', 6, 0, 0], ['hit', 5, 2, 0], ['turn', 'player'], ['hit', 9, 2, 0], ['hit', 9, 2, 0], ['hit', 9, 0, 0], ['hit', 9, 0, 0], ['hit', 9, 0, 0], ['turn', 'player']] },
  { note: 'Hegemony ion on a Sunward cruiser: the pool regen is locked for one turn start',
    pfac: 'voidsworn', p: 'penitent', efac: 'hegemony', e: 'h_dominion',
    ops: [['hit', 7, 0, 2], ['hit', 3, 2, 2], ['turn', 'player'], ['turn', 'player']] },
  { note: 'Hegemony ion on a routed side: the regen is locked, but the catches are re-derived as the route clears',
    pfac: 'voidsworn', p: 'penitent', efac: 'hegemony', e: 'h_dominion',
    ops: [['hit', 6, 1, 0], ['hit', 6, 1, 2], ['turn', 'player'], ['turn', 'player']] },
  { note: 'Glasswright sliver: a struck prism recharges twice, an untouched one snaps to full',
    pfac: 'ithar', p: 'i_wisp', efac: 'corsair', e: 'c_raider',
    ops: [['hit', 5, 0, 0], ['hit', 5, 0, 0], ['turn', 'player'], ['set', 3], ['turn', 'player']] }
];
async function runSeq(q) {
  battle(q.pfac, [q.p], q.efac, [q.e]); const t = P()[0], a = E()[0];
  const snap = () => ({ shp: t.shp, sh: t.sh.slice(), route: (t.route || [0, 0, 0, 0]).slice() }); const steps = [snap()];
  for (const op of q.ops) {
    if (op[0] === 'hit') T.applyHit(a, a.weapons[op[3]], t, op[1], op[2]);
    else if (op[0] === 'turn') await T.startSideTurn(op[1]);
    else if (op[0] === 'set') { t.shp = op[1]; T.syncShields(t); }
    steps.push(snap());
  }
  return { start: { shMax: t.shMax, regen: t.regen, cov: t.cov.slice() }, steps };
}
check('the twin fixture sequences run and end with an empty, then refilled, pool', async () => {
  const r = await runSeq(SEQS[0]); const st = r.steps; return st[st.length - 2].shp === 0 && st[st.length - 1].shp > 0; });
(async () => { for (const [name, fn] of tests) { try { const r = await fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
  if (process.argv[2]) {
    const cov = []; for (const [tpl, h] of Object.entries(T.HULLS)) if (h.sh > 0 && h.fac && h.cls) cov.push({ tpl, fac: h.fac, cls: h.cls, cov: T.shieldCov(h.fac, h.cls) });
    const seqs = []; for (const q of SEQS) seqs.push(Object.assign({}, q, await runSeq(q)));
    // non-integers go as exact IEEE hex (#d:...), as effect_caps_tests.js does, so the Godot side reads the same doubles
    const encode = v => typeof v === 'number' && !Number.isInteger(v) ? (b => (b.writeDoubleBE(v), '#d:' + b.toString('hex')))(Buffer.alloc(8))
      : Array.isArray(v) ? v.map(encode) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encode(x)])) : v;
    fs.writeFileSync(process.argv[2], JSON.stringify(encode({ cov, seqs }))); console.log('wrote ' + cov.length + ' coverage rows and ' + seqs.length + ' sequences to ' + process.argv[2]);
  }
  console.log('\nShield pool tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0; })();
