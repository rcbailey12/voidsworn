// Issue 1449: a relic trade lets the player pick which piece of salvage they give up (browser twin). With one piece the
// choice names it; with two or more a pick opens before the outcome applies. Fixture: godot/campaign/test/fixtures/
// issue_1449/relic_trade.json (the Godot twin reads the same file in godot/campaign/test/relic_trade_1449.gd). Run from the repo root.
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
const FX = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/campaign/test/fixtures/issue_1449/relic_trade.json'), 'utf8'));
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function tel(){} function toast(){} function mapScreen(){} function completeNode(){} function saveRun(){}
let LAST_MODAL=''; function modal(h){ LAST_MODAL=h; } function closeModal(){ LAST_MODAL=''; }
global.T = { get RUN(){ return RUN; }, newRun, ACT, EVENTS, relicName, relicTradeNote, get modal(){ return LAST_MODAL; },
  open(id){ const ev=EVENTS.find(e=>e.id===id); curEvent=Object.assign({},ev,(ev.v&&ev.v[RUN.fac])||{}); eventModal(); return curEvent; } };
`);
const acts = html => { const out = [], re = /<(?:button|g|div|a|span)\b([^>]*)>/g; let m;
  while ((m = re.exec(html))) { const at = m[1], a = at.match(/data-act="([^"]*)"/); if (!a) continue; const g = at.match(/data-arg="([^"]*)"/);
    out.push([a[1], g ? g[1] : '', /(^|\s)disabled(\s|$|=)/.test(at) ? 0 : 1].join(':')); } return out; };
const fill = t => t.replace(/%(\w+)%/g, (_, r) => T.relicName(r));
for (const cs of FX.cases) {
  T.newRun(FX.admiral, FX.fac, {});
  T.RUN.relics = cs.relics.slice(); T.RUN.flags = {};
  const ev = T.open(cs.event);
  check(cs.name + ': the trade choice says what it takes', () => T.relicTradeNote(ev.o[cs.opt]) === fill(cs.expect.note) && T.modal.includes(fill(cs.expect.note).trim()));
  T.ACT.eventChoice(String(cs.opt));
  if (cs.expect.pickActs.length) {
    check(cs.name + ': the pick opens with one button per relic and Back', () => JSON.stringify(acts(T.modal)) === JSON.stringify(cs.expect.pickActs));
    check(cs.name + ': nothing is spent before the pick', () => JSON.stringify(T.RUN.relics) === JSON.stringify(cs.relics) && !T.RUN.flags[cs.event]);
    T.ACT.eventBack();
    check(cs.name + ': Back returns to the event untouched', () => acts(T.modal)[cs.opt].startsWith('eventChoice:' + cs.opt + ':') && JSON.stringify(T.RUN.relics) === JSON.stringify(cs.relics));
    T.ACT.eventChoice(String(cs.opt)); T.ACT.eventChoice(cs.opt + ':' + cs.pick);
  }
  check(cs.name + ': gives up the chosen relic', () => JSON.stringify(T.RUN.relics) === JSON.stringify(cs.expect.relics));
  check(cs.name + ': the result names it', () => T.modal.includes('You give up ' + T.relicName(cs.expect.gaveUp) + '.'));
}
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
