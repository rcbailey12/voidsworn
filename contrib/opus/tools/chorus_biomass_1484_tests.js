// Issue 1484 (R382, RULEBOOK 11.9): Chorus biomass pays for refits, class refit tracks, protocol rerolls and the Sector 3 late
// market, as credits do for every other fleet. A Chorus run with biomass and no credits buys each one; with credits and no
// biomass it buys none; a Crusade run still pays in credits. Godot twin: godot/campaign/test/chorus_biomass_1484.gd. Run from
// the repo root.
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
function log(){} function tel(){} function toast(){} function shipyardScreen(n){ yardNode=n; }
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, setYard(n){ yardNode=n; }, get yard(){ return yardNode; }, newRun, shipyardStock, lateShopOffers, ACT,
  MODULES, HULLS, priceMult, classTrack, classTrackCost, rollBoonOffer, boonReroll, boonRerollOk, boonRerollCost, rndSeed, buyClassTrack };
`);
// a run at a Sector 3 shipyard with the given purse
function start(admiral, fac, bio, cred) {
  T.rndSeed(1484); T.newRun(admiral, fac, {}); const R = T.RUN; R.sector = 3; R.map.cond = null; R.bio = bio; R.credits = cred;
  const n = { id: 'y', col: 0, type: 'shipyard' }; T.setYard(n); T.shipyardStock(n); return R;
}
// tries every purchase once; returns what each cost and whether it took effect
function buyAll() {
  const R = T.RUN, st = T.yard.stock, got = {};
  const m = st.mods[0], mc = Math.round(T.MODULES[m].cost * T.priceMult()), inv = R.inventory.length;
  T.ACT.buyMod(0); got.mod = { cost: mc, ok: R.inventory.length === inv + 1 && st.sold.includes(0) };
  const cls = T.HULLS[R.fleet[0].tpl].cls, lv = T.classTrack(cls), tc = T.classTrackCost(cls);
  T.ACT.buyTrack(cls); got.track = { cost: tc, ok: T.classTrack(cls) === lv + 1 };
  const relic = T.lateShopOffers().find(o => o.kind === 'relic' && !o.done), rl = R.relics.length;
  if (relic) { T.ACT.lateBuy(relic.id); got.relic = { cost: relic.cost, ok: R.relics.length === rl + 1 }; }
  const cpo = T.lateShopOffers().find(o => o.kind === 'cp'), cap = R.cpCap;
  T.ACT.lateBuy('cp'); got.cp = { cost: cpo.cost, ok: R.cpCap === cap + 1 };
  const p = R.patrons[0], rc = T.boonRerollCost();
  R.reward = { kind: 'story', rw: { k: 'boon', p }, stage: 'pick', relics: [], wrecks: [], prizes: [], boonOffer: T.rollBoonOffer(p, 0), modOffer: null };
  const off = T.boonReroll(p, 0); got.reroll = { cost: rc, ok: off != null && R.reward.rerolled === true };
  return got;
}
const kinds = ['mod', 'track', 'relic', 'cp', 'reroll'];
const sum = g => kinds.reduce((a, k) => a + (g[k] ? g[k].cost : 0), 0);

let R = start('matriarch', 'chorus', 5000, 0); let g = buyAll();
for (const k of kinds) check(`Chorus with biomass buys the ${k}`, () => !!g[k] && g[k].ok);
check('Chorus biomass pays the whole bill (' + R.bio + ')', () => R.bio === 5000 - sum(g));
check('Chorus credits are untouched', () => R.credits === 0);

R = start('matriarch', 'chorus', 0, 5000); g = buyAll();
for (const k of kinds) check(`Chorus with credits only cannot buy the ${k}`, () => !!g[k] && !g[k].ok);
check('Chorus credits stay whole', () => R.credits === 5000 && R.bio === 0);

R = start('vex', 'voidsworn', 0, 5000); g = buyAll();
for (const k of kinds) check(`Crusade with credits buys the ${k}`, () => !!g[k] && g[k].ok);
check('Crusade credits pay the whole bill (' + R.credits + ')', () => R.credits === 5000 - sum(g));
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
