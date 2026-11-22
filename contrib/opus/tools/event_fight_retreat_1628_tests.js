// Issue 1628, browser twin: after a retreat from a fight that an event choice started, entering the event stop again goes
// straight back to that fight, with no second pick. Fixture: godot/campaign/test/fixtures/issue_1628/event_fight_retreat.json
// (the Godot twin reads the same file in godot/campaign/test/event_fight_retreat_1628.gd). Run from the repo root.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { this.children.push(c); return c; }, remove() {}, querySelector() { return null; }, querySelectorAll() { return []; },
  addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: () => el(), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const FX = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/campaign/test/fixtures/issue_1628/event_fight_retreat.json'), 'utf8'));
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
global.SEEN = { cfg: null, modal: 0 };
eval(src + `
function log(){} function tel(){} function toast(){} function saveRun(){} function show(){} function mapScreen(){}
modal = function(){ SEEN.modal++; }; closeModal = function(){};
battleScreen = function(cfg){ SEEN.cfg = cfg; };
global.T = { get RUN(){ return RUN; }, newRun, rndSeed, eventScreen, ACT, findNode, retreatBack: typeof retreatBack === 'function' ? retreatBack : null };
`);
for (const cs of FX.cases) {
  T.rndSeed(FX.seed); T.newRun(FX.admiral, FX.fac, {});
  const n = T.RUN.map.cols[0][0]; n.type = 'event'; n.evId = cs.event; for (const k of ['enc', 'shape', 'arch', 'mod', 'rw']) delete n[k];
  T.RUN.pos = n.id; T.RUN.curNode = n.id; SEEN.cfg = null; SEEN.modal = 0;
  T.eventScreen(n); T.ACT.eventChoice(String(cs.pick));
  check(cs.name + ': the choice starts the fight', () => !!SEEN.cfg && SEEN.cfg.fac === cs.expect.firstFight && SEEN.cfg.node === n.id && SEEN.cfg.eventRelic === true);
  check(cs.name + ': the stop remembers the choice', () => n.evFight === cs.expect.evFight);
  if (T.retreatBack) T.retreatBack(); else { T.RUN.pos = null; T.RUN.curNode = null; }
  T.RUN.pos = n.id; T.RUN.curNode = n.id; SEEN.cfg = null; SEEN.modal = 0;
  T.eventScreen(n);
  check(cs.name + ': entering again goes straight to the same fight, no second pick', () => !!SEEN.cfg && SEEN.cfg.fac === cs.expect.againFight && SEEN.cfg.node === n.id && (SEEN.modal > 0) === cs.expect.againModal);
}
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
