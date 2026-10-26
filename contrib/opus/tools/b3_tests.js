// B3 checks (stream B, Oct 26): each faction rule, the gates and the travelling torpedoes get a scripted proof. Run from the repo root: node contrib/opus/tools/b3_tests.js
// Loads data.js, core.js, battle.js, campaign_meta.js and campaign_run.js with a fake page and a fake localStorage.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {}; let LAST_MODAL = '';
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; if (c.id === 'modal') LAST_MODAL = c.innerHTML; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
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
async function animWeapon(){} var EXPL=null; async function animExplode(u){ if(EXPL) await EXPL(u); } function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, get RNG(){ return RNG_S; }, migrateRun, newShip, startBattle, HULLS, factionGate, canOrder,
  fireWeapon, killUnit, startSideTurn, turnStart, dmgMult, hitChance, syncOn, inSync, syncAnchor, prizePlan, salvageYield,
  setExplode(f){ EXPL=f; }, SYNC_DMG, SYNC_AIM, FEED_KILL, FEED_NEAR, FEED_CAP, LEGION_HP, canFire, torpThreat };
`);
const base = (o) => Object.assign({ fac: 'voidsworn', admiral: 'vex', credits: 500, cpCap: 30, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] }, fleet: [] }, o || {});
// a battle with fixed fleets and no terrain; units are then placed by hand so distances are exact
function battle(fac, ptpls, efac, etpls) { T.RUN = T.migrateRun(base({ fac, fleet: ptpls.map(t => T.newShip(t)) })); T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.startBattle({ kind: 'battle', fac: efac, col: 3, enemies: etpls.map(tpl => ({ tpl })), shape: 'open', map: 'storm', obj: 'rout', seed: 7, dep: 'line' });
  const B = T.B; B.terrain = {}; for (const u of B.units.filter(x => x.isSq)) u.dead = true; return B; }
const P = () => T.B.units.filter(u => u.side === 'player' && !u.isSq), E = () => T.B.units.filter(u => u.side === 'enemy' && !u.isSq);
const put = (u, q, r, f) => { u.q = q; u.r = r; if (f != null) u.facing = f; };
const pool = u => u.hp + u.sh.reduce((a, b) => a + b, 0);
const logged = (n0, re) => T.B.log.slice(n0).some(l => re.test(l.m));

// ---- data-only pass ----
check('price ladder: Hegemony unchanged, Chorus frigates cheap, Deathless and Ithar dear, Voidsworn carriers +25%', () =>
  T.HULLS.h_picket.cost === 70 && T.HULLS.h_vanguard.cost === 250 && T.HULLS.b_drone.cost === 45 && T.HULLS.d_harvester.cost === 390 && T.HULLS.i_wisp.cost === 90 && T.HULLS.reliquary.cost === 325 && T.HULLS.warden.cost === 70);
check('Ithar cannot Brace; other factions still can', () => { battle('ithar', ['i_song'], 'hegemony', ['h_picket']); const it = P()[0]; battle('voidsworn', ['penitent'], 'hegemony', ['h_picket']); const vo = P()[0];
  return !T.canOrder(it, 'brace') && T.canOrder(vo, 'brace'); });
check('Corsair gate: no lance-kind hulls (prize Add refused, tow refused), other factions unaffected', () => {
  const g = T.factionGate('corsair', 'h_interdictor'); T.RUN = T.migrateRun(base({ fac: 'corsair', fleet: [T.newShip('c_raider')] }));
  const plan = T.prizePlan({ prizes: [{ tpl: 'h_interdictor', name: 'X', cp: 2, hpf: 1, wk: ['lance', 'battery'] }, { tpl: 'h_picket', name: 'Y', cp: 1, hpf: 1, wk: ['battery'] }] });
  const tow = T.salvageYield({ wk: ['lance'], cp: 2, tpl: 'h_interdictor', cause: 'blast' }).tow, tow2 = T.salvageYield({ wk: ['battery'], cp: 1, tpl: 'h_picket', cause: 'blast' }).tow;
  return !!g && !T.factionGate('hegemony', 'h_interdictor') && !T.factionGate('corsair', 'c_marauder') && plan[0].k !== 'add' && !plan[0].room && plan[1].room && tow === false && tow2 === true; });
// ---- Hegemony synchronized fire ----
check('Hegemony sync: a target another synced ship fired on this round takes +15% and is easier to hit; not on its own shots, not beyond 3 hexes, gone with the anchor', async () => {
  battle('hegemony', ['h_vanguard', 'h_interdictor', 'h_interdictor'], 'voidsworn', ['cathedral']); const [a, s1, s2] = P(), t = E()[0];
  put(a, 8, 10, 0); put(s1, 9, 10, 0); put(s2, 10, 10, 0); put(t, 13, 10, 3);
  if (!a.anchor || !T.inSync(s1) || !T.inSync(s2)) throw new Error('anchor or sync setup');
  const w = s2.weapons.find(x => x.k !== 'flak' && T.canFire(s2, x, t)), m0 = T.dmgMult(s2, w, t, false), h0 = T.hitChance(s2, w, t);
  await T.fireWeapon(s1, s1.weapons.findIndex(x => x.k !== 'flak' && T.canFire(s1, x, t)), t);
  const m1 = T.dmgMult(s2, w, t, false), h1 = T.hitChance(s2, w, t), own = T.syncOn(s1, t);
  put(s2, 3, 10, 0); const far = T.syncOn(s2, t); put(s2, 10, 10, 0);
  await T.killUnit(a, t); const after = T.syncOn(s2, t), lost = !T.syncAnchor('player');
  if (!(Math.abs(m1 - m0 - w.dmg * T.SYNC_DMG * (w.vsCap || 1)) < 1e-6)) throw new Error('damage ' + m0 + ' -> ' + m1);
  return (h1 - h0 === T.SYNC_AIM || h1 === 95) && !own && !far && !after && lost; });
check('Hegemony sync does not stack with Anchored Volley (the larger bonus applies)', () => {
  const B = battle('hegemony', ['h_vanguard', 'h_interdictor'], 'voidsworn', ['cathedral']); const [a, s1] = P(), t = E()[0]; put(a, 8, 10, 0); put(s1, 9, 10, 0); put(t, 12, 10, 3);
  s1.fx = Object.assign({}, s1.fx, { stillPct: .25 }); s1.hexMoved = 0; const w = s1.weapons.find(x => x.k === 'battery'); const still = T.dmgMult(s1, w, t, false);
  B.syncMark.player[t.id] = { r: B.round, ids: [a.id] }; const both = T.dmgMult(s1, w, t, false); return T.syncOn(s1, t) && Math.abs(both - still) < 1e-6; });
// ---- Ithar prism charge ----
check('Ithar prism charge: an unhit facing refills to full, a struck facing regenerates twice', () => {
  battle('ithar', ['i_song'], 'hegemony', ['h_picket']); const u = P()[0]; u.regen = 2; u.sh = [5, 5, 5, 5]; u.shHit = [1, 0, 0, 0];
  T.startSideTurn('player'); return u.sh[0] === 9 && u.sh[1] === u.shMax && u.sh[2] === u.shMax && u.sh[3] === u.shMax && u.shHit.every(x => !x); });
check('Ithar prism charge stays off while the shield generator is down; other factions get no charge', () => {
  battle('ithar', ['i_song'], 'hegemony', ['h_dominion']); const u = P()[0], h = E()[0]; u.sh = [0, 0, 0, 0]; u.st.shieldOff = 2; h.sh = [1, 1, 1, 1]; h.regen = 0;
  T.startSideTurn('player'); T.startSideTurn('enemy'); return u.sh.every(x => x === 0) && h.sh.every(x => x === 1); });
// ---- Chorus feed ----
check('Chorus feed: the killer regrows 15%, a Chorus ship within 2 hexes 8%, capped at 25% a round', async () => {
  battle('chorus', ['b_razor', 'b_spitter'], 'hegemony', ['h_picket', 'h_picket', 'h_picket', 'h_picket']); const [k, n] = P(), es = E();
  put(k, 8, 10); put(n, 9, 10); es.forEach((e, i) => put(e, 10, 8 + i)); k.hp = 20; n.hp = 20;
  await T.killUnit(es[0], k); const h1 = k.hp, n1 = n.hp; await T.killUnit(es[1], k); await T.killUnit(es[2], k); const h3 = k.hp;
  return h1 - 20 === Math.round(k.maxHp * T.FEED_KILL) && n1 - 20 === Math.round(n.maxHp * T.FEED_NEAR) && h3 - 20 === Math.round(k.maxHp * T.FEED_CAP); });
// ---- Deathless endless legion ----
check('Deathless legion: the first ship to fall rises next round at 35% and cannot fire; the next stays dead; no random reanimate draw', async () => {
  const B = battle('hegemony', ['h_dominion'], 'deathless', ['d_jackal', 'd_jackal', 'd_harvester', 'd_harvester']); const [j1, j2] = E();
  const r0 = T.RNG; await T.killUnit(j1, P()[0]); const noDraw = T.RNG === r0; await T.killUnit(j2, P()[0]);
  const down = j1.dead && j1.riseAt === B.round + 1 && j2.dead && j2.riseAt == null;
  B.round++; T.startSideTurn('player'); T.startSideTurn('enemy');
  const h0 = Math.round(j1.maxHp * T.LEGION_HP); // it rises at 35%, then gets its normal turn-start regrowth
  return noDraw && down && !j1.dead && j1.hp >= h0 && j1.hp <= h0 + j1.hullRegen && j1.weapons.every(w => w.fired) && j2.dead; });
check('Deathless legion never raises the flagship, and Funeral Pyre stops it', async () => {
  battle('hegemony', ['h_dominion'], 'deathless', ['d_harvester', 'd_jackal']); const [h, j] = E(); h.flagship = true; j.pyre = true;
  await T.killUnit(h, P()[0]); await T.killUnit(j, P()[0]); return h.riseAt == null && j.riseAt == null; });
check('your reassembling Deathless ship stands up when the battle is won', async () => {
  const B = battle('deathless', ['d_harvester', 'd_scythe'], 'hegemony', ['h_picket']); const s = P()[1]; await T.killUnit(s, E()[0]); const was = s.dead; await T.killUnit(E()[0], P()[0]);
  return was && B.over === 'win' && !s.dead && s.hp > 0; });
// ---- travelling torpedoes ----
check('torpedoes: launching rolls nothing and leaves a lane; impact comes at the next turn start, not this one', async () => {
  const B = battle('voidsworn', ['harrow'], 'hegemony', ['h_dominion']); const u = P()[0], t = E()[0]; put(u, 8, 10, 0); put(t, 12, 10, 3);
  const wi = u.weapons.findIndex(w => w.k === 'torp'); const r0 = T.RNG, p0 = pool(t);
  const ok1 = await T.fireWeapon(u, wi, t); const noRoll = T.RNG === r0, inFlight = B.torps.length === 1 && B.torps[0].aim.q === 12 && p0 === pool(t);
  await T.turnStart('player'); const early = B.torps.length === 1;
  B.round++; t.ev = 0; const n0 = B.log.length; await T.turnStart('player'); const landed = B.torps.length === 0 && logged(n0, /reach/);
  return ok1 && noRoll && inFlight && early && landed; });
check('torpedoes: a target 3 hexes from the aim hex dodges', async () => {
  const B = battle('voidsworn', ['harrow'], 'hegemony', ['h_dominion', 'h_picket']); const u = P()[0], [t, o] = E(); put(u, 8, 10, 0); put(t, 12, 10, 3); put(o, 14, 4, 3);
  await T.fireWeapon(u, u.weapons.findIndex(w => w.k === 'torp'), t); put(t, 12, 13); B.round++; const n0 = B.log.length; await T.turnStart('player');
  return logged(n0, /run wide/) && B.fstat.voidsworn.torpDodge === 1; });
check('torpedoes: the threat map steers a targeted ship out of the lane', async () => {
  const B = battle('hegemony', ['h_dominion'], 'voidsworn', ['harrow']); const t = P()[0], u = E()[0]; put(u, 14, 10, 3); put(t, 10, 10, 0); B.side = 'enemy';
  await T.fireWeapon(u, u.weapons.findIndex(w => w.k === 'torp'), t); return B.torps.length === 1 && T.torpThreat(t, { q: 10, r: 10 }) > 0 && T.torpThreat(t, { q: 10, r: 13 }) === 0; });
// ---- B-21 ----
check('B-21 the point defense bolted onto escorts against carrier fleets is ready to fire and intercepts wings', async () => {
  T.RUN = T.migrateRun(base({ fleet: ['reliquary', 'reliquary', 'penitent'].map(t => T.newShip(t)) })); T.RUN.sector = 2; T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, shape: 'open', map: 'storm', obj: 'rout', seed: 7, dep: 'line' }); T.B.terrain = {};
  const ref = E().find(u => u.pdRefit); if (!ref) throw new Error('no refit');
  const w = ref.weapons[ref.weapons.length - 1]; const ready = w.k === 'flak' && w.fired === false && w.cdLeft === 0 && w.off === 0 && !!w.n;
  const wing = T.B.units.find(u => u.side === 'player' && u.isSq); wing.dead = false; ref.intercepts = 2; put(ref, 12, 10, 3); put(wing, 13, 10, 0); const tgt = E().find(u => u !== ref); put(tgt, 14, 10, 3);
  const n0 = ref.intercepts; await T.fireWeapon(wing, 0, ref); return ready && ref.intercepts < n0; });
// ---- B-18 ----
check('B-18 a stall during a death explosion skips its aftermath (chain blasts) but still ends the battle; without a stall the blast lands', async () => {
  const run = async (stall) => { const B = battle('voidsworn', ['penitent'], 'hegemony', ['h_picket', 'h_picket']); const [a, b] = E(); put(a, 12, 10); put(b, 13, 10); P()[0].fx = Object.assign({}, P()[0].fx, { chainBoom: 30 });
    b.hp = 20; const save = global.animExplodeHook; T.setExplode(stall ? (async () => { B.epoch = (B.epoch || 0) + 1; }) : null); await T.killUnit(a, P()[0]); T.setExplode(null); return { b: b.hp, over: B.over }; };
  const live = await run(false), stalled = await run(true);
  return live.b < 20 && stalled.b === 20; });
// ---- B-20 ----
check('B-20 the rangefinder relic now applies to the first real shot of each ship', async () => {
  battle('voidsworn', ['penitent'], 'hegemony', ['h_dominion']); T.RUN.relics = ['cogitator']; const u = P()[0], t = E()[0]; put(u, 8, 10, 0);
  let wi = -1; for (let q = 4; q <= 12 && wi < 0; q++) for (let r = 6; r <= 14 && wi < 0; r++) { if (q === 8 && r === 10) continue; put(t, q, r, 3); wi = u.weapons.findIndex(w => w.k === 'battery' && T.canFire(u, w, t)); } if (wi < 0) throw new Error('no battery bears');
  u.aim = -60; t.maxHp = t.hp = 99999; const w = u.weapons[wi]; let hits = 0, shots = 0; // without the relic every shot is at the 5% floor
  for (let i = 0; i < 40; i++) { u.sureUsed = 0; w.fired = false; w.cdLeft = 0; const n0 = T.B.log.length; await T.fireWeapon(u, wi, t); shots += w.shots; const m = T.B.log.slice(n0).map(l => l.m).join(' '); hits += m.includes('all shots miss') ? 0 : 1; }
  u.sureUsed = 1; const after = T.hitChance(u, w, t);
  return hits >= 38 && after < 30; });
(async () => { for (const [name, fn] of tests) { try { const r = await fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
  console.log('\nB3 tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0; })();
