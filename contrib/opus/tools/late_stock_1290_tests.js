// Issue 1290: a shipyard stocked before the late market's skip list (an older save) never sells a skipped relic, and its
// purchase history and command point state stay as saved. Fixture: godot/campaign/test/fixtures/issue_1290/old_yard.json (the
// Godot twin reads the same file in godot/campaign/test/late_fixes_1290.gd). Run from the repo root.
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
const FX = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/campaign/test/fixtures/issue_1290/old_yard.json'), 'utf8'));
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function tel(){} function toast(){} function shipyardScreen(n){ yardNode=n; }
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, setYard(n){ yardNode=n; }, newRun, lateShopOffers, ACT, LATE_SHOP };
`);
T.newRun('vex', 'voidsworn', {});
Object.assign(T.RUN, JSON.parse(JSON.stringify(FX.run)));
const yard = { id: 'y', col: 2, type: 'shipyard', stock: JSON.parse(JSON.stringify(FX.stock)) };
T.setYard(yard);
const offers = () => T.lateShopOffers();
check('the saved ledger is not offered', () => !offers().some(o => FX.expect.hidden.includes(o.r)));
check('the bought logbook stays listed as bought', () => offers().filter(o => o.kind === 'relic' && o.done).map(o => o.r).join() === FX.expect.boughtShown.join());
check('only the martyr is for sale', () => offers().filter(o => o.kind === 'relic' && o.ok).map(o => o.r).join() === FX.expect.forSale.join());
check('the command point stays taken', () => offers().find(o => o.kind === 'cp').done === FX.expect.cpDone && T.RUN.lateCp === 1);
check('buying the ledger by id does nothing', () => { T.ACT.lateBuy('relic:ledger'); return T.RUN.credits === FX.expect.creditsAfterLedgerTry && !T.RUN.relics.includes('ledger'); });
check('buying the martyr still works at the offer price', () => { const c = offers().find(o => o.r === 'martyr').cost; T.ACT.lateBuy('relic:martyr'); return T.RUN.credits === 500 - c && T.RUN.relics.includes('martyr'); });
check('the saved stock is not rewritten', () => JSON.stringify(yard.stock.late.relics) === JSON.stringify(FX.stock.late.relics) && yard.stock.late.bought.join() === 'logbook,martyr');
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
