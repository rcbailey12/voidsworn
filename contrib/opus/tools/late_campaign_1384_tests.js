// Issue 1384: the real bugs from Neon's late campaign review (PR 1380). Run from the repo root:
//   node contrib/opus/tools/late_campaign_1384_tests.js
// 1. Selling the flagship at a shipyard hands the flagship (and its Aspect) to another ship at once.
// 2. A ship regrown from an Eclipse core never decommissions for more than its regrow cost, even after it has fought.
// 3. The Crusade's Daybreak dreadnought (ascendant) carries the issue 1354 Crusade shop discount like the rest of the Crusade.
// 4. A captured Cinder Line hull costs what the matching Crusade hull costs in the shop (R78 Q9 "Crusade prices").
// The Godot twin is godot/campaign/test/late_fixes_1384.gd (it also covers the Sector 3 eaten-core remap, a Godot-only miss).
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() {}, querySelector() { return null; }, querySelectorAll() { return []; },
  addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || el(), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function tel(){} function toast(){} function shipyardScreen(n){ yardNode=n; } function closeModal(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, setYard(n){ yardNode=n; }, newRun, ACT, HULLS, SHOP_DISCOUNT, ASPECTS,
  flagshipOf, derive, sellValue, prizeScrap, coreCost, capturedHullPrice, META };
`);
const yard = () => { const n = { id: 'y', col: 0, type: 'shipyard' }; T.setYard(n); return n; };

check('selling the flagship hands the flagship to a ship still in the fleet', () => {
  T.newRun('vex', 'voidsworn', {}); yard();
  T.RUN.aspect = Object.keys(T.ASPECTS)[0];
  const f = T.flagshipOf(); if (!f) throw new Error('no flagship at the start');
  T.ACT.sellConfirm(f.uid);
  const nf = T.flagshipOf();
  if (!nf) throw new Error('flagUid ' + T.RUN.flagUid + ' points at no ship');
  return T.RUN.fleet.includes(nf) && nf.uid !== f.uid;
});
check('the new flagship gets the Aspect hull at once, its hull bar moves with it', () => {
  T.newRun('vex', 'voidsworn', {}); yard();
  const hpAsp = Object.keys(T.ASPECTS).find(k => { T.RUN.aspect = k; const s = T.RUN.fleet[0]; const a = T.derive(s).maxHp; T.RUN.flagUid = null; const b = T.derive(s).maxHp; T.RUN.flagUid = s.uid; return a !== b; });
  if (!hpAsp) return true; // no Aspect changes hull: nothing to check
  T.RUN.aspect = hpAsp; T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.RUN.fleet.forEach(s => { s.hp = T.derive(s).maxHp; });
  T.ACT.sellConfirm(T.RUN.fleet[0].uid);
  const nf = T.flagshipOf(); return !!nf && nf.hp === T.derive(nf).maxHp;
});
check('a regrown Eclipse ship never decommissions for more than its regrow cost', () => {
  T.newRun('nekhet', 'deathless', {}); yard();
  const tpl = T.RUN.fleet[T.RUN.fleet.length - 1].tpl;
  T.RUN.cores = [tpl]; T.RUN.credits = 2000; T.RUN.cpCap = 99;
  const c = T.coreCost(tpl);
  T.ACT.restoreCore('0');
  const g = T.RUN.fleet[T.RUN.fleet.length - 1];
  if (!g.regrown || g.corePaid !== c) throw new Error('regrow did not record its cost: ' + g.corePaid + ' vs ' + c);
  if (T.sellValue(g) !== 0) throw new Error('before a fight it sells for ' + T.sellValue(g));
  delete g.regrown; // what rewardFlow does after a battle
  if (T.sellValue(g) > c) throw new Error('after a fight it sells for ' + T.sellValue(g) + ', the regrow cost ' + c);
  const c0 = T.RUN.credits; T.ACT.sellConfirm(g.uid);
  return T.RUN.credits - c0 <= c && T.sellValue({ tpl }) === T.prizeScrap(tpl);
});
check('the Daybreak dreadnought carries the Crusade shop discount, its ladder value stays', () => {
  const h = T.HULLS.ascendant;
  return h.val === 520 && h.cost === Math.round(520 * T.SHOP_DISCOUNT.voidsworn / 5) * 5;
});
check('a captured Eclipse frigate costs what a Warden costs in a Crusade shop', () => {
  T.newRun('vex', 'voidsworn', {}); T.RUN.map.cond = null;
  return T.capturedHullPrice(T.HULLS.d_scythe) === T.HULLS.warden.cost && T.HULLS.d_scythe.cost > T.HULLS.warden.cost;
});
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
