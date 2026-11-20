// Issue 41 (R78 Q9): from run 3 the Crusade keeps captured Hegemony and Eclipse hulls, links ripped out, at Crusade
// prices, via the Cinder Line yards. Run from the repo root: node contrib/opus/tools/cinder_prizes_tests.js
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', textContent: '', className: '', id: '', disabled: false, offsetParent: null,
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  focus() {}, addEventListener() {}, setAttribute() {}, getAttribute() { return null; }, querySelector() { return el(tag); }, querySelectorAll() { return []; },
  getBoundingClientRect() { return { width: 0, height: 0, top: 0, left: 0 }; },
  classList: { add() {}, remove() {}, toggle() {}, contains: () => false } });
const APP = el('div'); APP.id = 'app'; IDS.app = APP;
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el('div')), querySelector: () => null, querySelectorAll: () => [], body: el('body'), documentElement: el('html'), addEventListener() {} };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900;
global.setTimeout = f => { Promise.resolve().then(() => { try { f(); } catch (e) {} }); return 0; }; global.clearTimeout = () => {}; global.setInterval = () => 0; global.clearInterval = () => {};
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `function log(){} function tel(){} function battleScreen(){} function nodeSeeds(){ return 0; }
globalThis.T = {
  get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get META(){ return META; }, set META(v){ META=v; }, get B(){ return B; },
  get SAVED_RUN(){ return SAVED_RUN; },
  runDefaults, newShip, derive, shipyardStock, shipyardScreen, capturedHullPrice, cinderOpen, cinderPool, fleetCP, priceMult,
  startBattle, inSync, legionCan, syncAnchor, factionTraitLines, prizePlan, ACT, saveRun, migrateRun, genSector, HULLS, CINDER_PRIZES, CINDER_FIRST_RUN, FAC_PRICE
};`);
function setup(fac, runs) {
  // a fresh meta at the given launched-run count, and a plain run standing at a shipyard
  const meta = JSON.parse(JSON.stringify(T.META));
  meta.stats.runs = runs;
  T.META = meta;
  const r = T.runDefaults();
  r.fac = fac; r.credits = 1000; r.map = { cols: [], edges: [], biome: null, cond: null };
  r.fleet = []; r.flagUid = null; r.lineage = null;
  T.RUN = r;
  return r;
}
check('the gate is closed before run 3 and for other factions', () => {
  setup('voidsworn', 2); if (T.cinderOpen()) return false;
  const st = T.shipyardStock({ id: 'y1', type: 'shipyard' });
  if ((st.cap || []).length !== 0) return false;
  setup('hegemony', 5); if (T.cinderOpen()) return false;
  return (T.shipyardStock({ id: 'y2', type: 'shipyard' }).cap || []).length === 0;
});
check('from run 3 a Crusade yard stocks two captured Hegemony or Eclipse hulls', () => {
  setup('voidsworn', 3); if (!T.cinderOpen()) return false;
  const st = T.shipyardStock({ id: 'y3', type: 'shipyard' });
  return st.cap.length === 2 && st.cap.every(h => T.CINDER_PRIZES.includes(h));
});
check('captured hulls sell at Crusade prices, not at the owners faction prices', () => {
  setup('voidsworn', 3);
  const warden = T.HULLS.warden, mote = T.HULLS.d_scythe, picket = T.HULLS.h_picket;
  if (T.capturedHullPrice(mote) !== warden.cost) return false; // a 1 CP frigate costs what a Warden costs (70), not the Eclipse 110
  if (T.capturedHullPrice(picket) !== picket.cost) return false; // Hegemony is already the 1.0 baseline
  const corsair = T.HULLS.c_raider;
  return T.capturedHullPrice(T.HULLS.c_reaver) === Math.round(Math.round((T.HULLS.c_reaver.cost0 != null ? T.HULLS.c_reaver.cost0 : T.HULLS.c_reaver.cost) / 5) * 5); // corsair destroyer base 130, no voidsworn destroyer markup
});
check('buying a captured hull charges the captured price and rips its links', () => {
  const r = setup('voidsworn', 3);
  T.shipyardScreen({ id: 'y4', type: 'shipyard', stock: { hulls: ['warden'], mods: [], sold: [], cap: ['d_scythe'] } });
  const before = r.credits;
  T.ACT.buyHull('d_scythe');
  const s = r.fleet[r.fleet.length - 1];
  if (!s || s.tpl !== 'd_scythe' || s.ripped !== true) return false;
  if (r.credits !== before - T.capturedHullPrice(T.HULLS.d_scythe)) return false;
  T.ACT.buyHull('warden');
  const w = r.fleet[r.fleet.length - 1];
  return w.tpl === 'warden' && !w.ripped;
});
check('a ripped Hegemony hull is no part of the synchronized fire net', () => {
  const r = setup('voidsworn', 3);
  const ripped = T.newShip('h_interdictor'); ripped.ripped = true;
  const plain = T.newShip('h_interdictor');
  r.fleet = [ripped, plain];
  T.startBattle({ kind: 'battle', fac: 'corsair', col: 3, enemies: [{ tpl: 'c_raider' }], seed: 11 });
  const us = T.B.units.filter(u => u.side === 'player');
  const ru = us.find(u => u.ripped), pu = us.find(u => !u.ripped);
  if (!ru || !pu) return false;
  const a = T.syncAnchor('player');
  if (!a || a !== pu) return false; // the plain hull anchors, the ripped one is never a candidate
  ru.q = pu.q; ru.r = pu.r; // even parked on the anchor: no sync
  if (T.inSync(ru)) return false;
  return T.factionTraitLines(ru).some(l => l.includes('Links ripped out'));
});
check('a lone ripped Hegemony hull gives the fleet no anchor at all', () => {
  const r = setup('voidsworn', 3);
  const ripped = T.newShip('h_interdictor'); ripped.ripped = true;
  r.fleet = [ripped];
  T.startBattle({ kind: 'battle', fac: 'corsair', col: 3, enemies: [{ tpl: 'c_raider' }], seed: 12 });
  return T.syncAnchor('player') === null;
});
check('a ripped Eclipse hull neither restores nor feeds the Archive count', () => {
  const r = setup('voidsworn', 3);
  const ripped = T.newShip('d_scythe'); ripped.ripped = true;
  r.fleet = [ripped];
  T.startBattle({ kind: 'battle', fac: 'corsair', col: 3, enemies: [{ tpl: 'c_raider' }], seed: 13 });
  const u = T.B.units.find(x => x.side === 'player');
  if (T.B.legion.player.max !== 0) return false;
  if (T.legionCan(u)) return false;
  if (!T.factionTraitLines(u).some(l => l.includes('the Archive does not answer'))) return false;
  const r2 = setup('voidsworn', 3); // control: a captured-not-ripped Eclipse mote would still be on the net
  r2.fleet = [T.newShip('d_scythe')];
  T.startBattle({ kind: 'battle', fac: 'corsair', col: 3, enemies: [{ tpl: 'c_raider' }], seed: 14 });
  return T.B.legion.player.max === 1;
});
check('the prize screen keep/strip/ransom choice is unchanged', () => {
  const r = setup('voidsworn', 3);
  r.cpCap = 10; r.fleet = [T.newShip('warden')];
  const prize = { tpl: 'h_picket', name: 'HNS Test', cp: 1, hpf: .7, wk: ['laser'], ab: null, regen: 0, sh: 10 };
  const rows = T.prizePlan({ prizes: [prize], prizeSel: null });
  if (!rows.length || rows[0].k !== 'add' || !rows[0].room) return false;
  const sel = rows[0].o;
  return sel.ransom > 0 && sel.strip.cred > 0 && T.CINDER_FIRST_RUN === 3;
});
check('before run 3 the Crusade cannot keep a Hegemony or Eclipse prize', () => {
  const r = setup('voidsworn', 2);
  r.cpCap = 10; r.fleet = [];
  const prize = { tpl: 'h_picket', name: 'HNS Early', cp: 1, hpf: .7, wk: ['laser'], ab: null, regen: 0, sh: 10 };
  let rows = T.prizePlan({ prizes: [prize], prizeSel: null });
  if (rows[0].room || !rows[0].cinder || rows[0].rip !== true || rows[0].k === 'add') return false; // strip and ransom only
  if (!(rows[0].o.ransom > 0 && rows[0].o.strip.cred > 0)) return false;
  rows = T.prizePlan({ prizes: [prize], prizeSel: ['add'] }); // even a saved Add pick falls back before run 3
  if (rows[0].k === 'add') return false;
  const prize2 = { tpl: 'd_scythe', name: 'EDV Early', cp: 1, hpf: .7, wk: ['laser'], ab: null, regen: 0, sh: 10 };
  rows = T.prizePlan({ prizes: [prize2], prizeSel: null });
  return !rows[0].room && rows[0].cinder && rows[0].k !== 'add';
});
check('from run 3 a kept Hegemony or Eclipse prize joins with its links ripped out', () => {
  const r = setup('voidsworn', 3);
  r.cpCap = 10; r.fleet = [];
  r.map = T.genSector(1); r.pos = r.map.cols[0][0].id; r.curNode = r.pos; // a real map, so the confirm chain can walk on to the map screen
  const prize = { tpl: 'h_interdictor', name: 'HNS Kept', cp: 2, hpf: .6, wk: ['battery'], ab: null, regen: 0, sh: 12 };
  r.reward = { kind: 'elite', stage: 'prize', prizes: [prize], prizeSel: ['add'], wrecks: [] };
  let rows = T.prizePlan(r.reward);
  if (!rows[0].room || rows[0].cinder || rows[0].rip !== true) return false;
  T.ACT.prizeConfirm();
  const kept = r.fleet.find(x => x.tpl === 'h_interdictor');
  if (!kept || kept.ripped !== true || kept.name !== 'HNS Kept') return false;
  const prize2 = { tpl: 'c_raider', name: 'RVD Plain', cp: 1, hpf: .7, wk: ['autocannon'], ab: null, regen: 0, sh: 8 };
  r.reward = { kind: 'elite', stage: 'prize', prizes: [prize2], prizeSel: ['add'], wrecks: [] };
  rows = T.prizePlan(r.reward);
  if (rows[0].cinder || rows[0].rip !== false) return false; // only Hegemony and Eclipse prizes rip
  T.ACT.prizeConfirm();
  const kept2 = r.fleet.find(x => x.tpl === 'c_raider');
  return !!kept2 && kept2.ripped !== true;
});
check('the captured yard draw waits for the class unlocks like normal stock', () => {
  const r = setup('voidsworn', 3);
  T.META.unlocked = {};
  let pool = T.cinderPool();
  if (pool.includes('h_dominion')) return false; // the captured battleship waits for u_battleship
  if (!pool.includes('h_picket') || !pool.includes('d_scythe')) return false; // frigates are always in the draw
  T.META.unlocked.u_battleship = true;
  pool = T.cinderPool();
  if (!pool.includes('h_dominion')) return false;
  const st = T.shipyardStock({ id: 'y6', type: 'shipyard' });
  return st.cap.length === 2 && st.cap.every(h => pool.includes(h));
});
check('a ripped hull survives a save and a load', () => {
  const r = setup('voidsworn', 3);
  T.shipyardScreen({ id: 'y7', type: 'shipyard', stock: { hulls: [], mods: [], sold: [], cap: ['d_scythe'] } });
  T.ACT.buyHull('d_scythe');
  T.saveRun();
  const onDisk = JSON.parse(STORE['voidsworn.v1']); // the registry the game actually writes
  if (!onDisk.run.fleet.some(s => s.ripped === true)) return false;
  const back = T.migrateRun(JSON.parse(JSON.stringify(T.SAVED_RUN)));
  const s = (back.fleet || []).find(x => x.tpl === 'd_scythe');
  return !!s && s.ripped === true;
});
(async () => { let pass = 0, fail = 0;
  for (const [name, fn] of tests) { let ok = false, err = ''; try { ok = await fn(); } catch (e) { err = ' (' + e.message + ')'; }
    if (ok === true) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + err); } }
  console.log('\nCinder prize tests: ' + pass + ' ok, ' + fail + ' FAIL');
  process.exitCode = fail ? 1 : 0;
})();
