// B1 checks: each fixed bug gets a scripted proof. Run from the repo root: node contrib/opus/tools/b1_tests.js
// Loads the rules files the way sim3d.js does (data.js, core.js, battle.js), with a fake localStorage.
global.window = {}; global.document = undefined; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function fxText(){} function fxShield(){} function fxFlash(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get META(){ return META; }, get SAVED_RUN(){ return SAVED_RUN; }, Persist, migrateRun, migrateMeta, defaultMeta, fleetCP, derive, newShip, ensureFlagship, RELICS, ADMIRALS, HULLS, STORE_KEY };
`);
const base = () => ({ fac: 'voidsworn', admiral: 'vex', credits: 50, cpCap: 10, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] },
  fleet: [{ uid: 1, tpl: 'warden', name: 'Warden', hp: 50, mods: [], mk: 1, cap: { fac: 'voidsworn', name: 'Ada Vey', xp: 0, rank: 0, perks: [], pending: 0 } }] });

// ---- B-1 save-brick class (FINDINGS B-1; evidence rows 1a to 1f) ----
check('B-1a renamed hull: fleetCP and derive no longer throw, ship dropped and counted', () => {
  const r = base(); r.fleet.push({ uid: 2, tpl: 'warden_renamed', name: 'Ghost', hp: 10, mods: [], cap: { name: 'X' } });
  T.RUN = T.migrateRun(r); T.fleetCP(); T.RUN.fleet.forEach(s => T.derive(s));
  return T.RUN.fleet.length === 1 && T.RUN._shipsDropped === 1 && T.RUN._repairs.some(x => /warden_renamed/.test(x));
});
check('B-1c unknown relic id is removed (map screen reads RELICS[r].d)', () => {
  const r = base(); r.relics = [Object.keys(T.RELICS)[0], 'relic_gone']; T.RUN = T.migrateRun(r);
  return T.RUN.relics.length === 1 && T.RUN.relics.every(id => T.RELICS[id].d !== undefined);
});
check('B-1d captain with no name: newShip-style name use works', () => {
  const r = base(); r.fleet[0].cap = {}; T.RUN = T.migrateRun(r); const c = T.RUN.fleet[0].cap;
  return typeof c.name === 'string' && c.name.split(' ')[0].length > 0 && Array.isArray(c.perks);
});
check('B-1e stale admiral id is reset (run summary reads ADMIRALS[RUN.admiral].n)', () => {
  const r = base(); r.admiral = 'adm_renamed'; T.RUN = T.migrateRun(r); return typeof T.ADMIRALS[T.RUN.admiral].n === 'string';
});
check('B-1f meta with stats:null gets real stats (title reads META.stats.best)', () => {
  const m = T.migrateMeta(Object.assign(T.defaultMeta(), { stats: null, opts: null })); return typeof m.stats.best === 'number' && typeof m.opts === 'object';
});
check('B-1f old v1 meta still runs its v2 migration (version is not pre-filled)', () => {
  const m = T.migrateMeta({ renown: 3 }); return m.v === 2 && Array.isArray(m.tel);
});
check('B-1 full load path: a save with every bad id loads, and a raw copy is kept', () => {
  const r = base(); r.admiral = 'nobody'; r.relics = ['gone']; r.fleet.push({ uid: 3, tpl: 'old_hull', cap: null }); r.fleet[0].cap = { name: 7, perks: ['gone'] };
  r.boons = [{ id: 'gone_boon', r: 0 }, null]; r.aspect = 'gone'; r.flagUid = 3;
  localStorage.setItem(T.STORE_KEY, JSON.stringify({ meta: T.defaultMeta(), run: r })); delete STORE[T.STORE_KEY + '.repaired'];
  T.Persist.loadLocal(); const s = T.SAVED_RUN;
  return !!s && s.fleet.length === 1 && s.flagUid === null && s.aspect === null && s.boons.length === 0 && s.fleet[0].cap.name === 'Captain' && s.fleet[0].cap.perks.length === 0 && !!STORE[T.STORE_KEY + '.repaired'];
});
check('B-1 a clean save is left alone (no repairs listed)', () => {
  const r = T.migrateRun(base()); return !r._repairs && r.fleet.length === 1;
});

module.exports = { check, T: global.T, STORE };
if (require.main === module) process.on('exit', () => { console.log(`\nB1 tests: ${pass} ok, ${fail} FAIL`); if (fail) process.exitCode = 1; });
