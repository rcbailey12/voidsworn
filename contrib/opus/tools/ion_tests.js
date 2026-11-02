// Ion pulse eligibility checks. Run from the repo root: node contrib/opus/tools/ion_tests.js
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
const APP = el('div'); APP.id = 'app'; IDS.app = APP;
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = f => { Promise.resolve().then(() => { try { f(); } catch (e) {} }); return 0; }; global.clearTimeout = () => {}; global.setInterval = () => 0; global.clearInterval = () => {};
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `function log(){} function tel(){} function nodeSeeds(){ return 0; } global.T = { runDefaults, newShip, startBattle, canAbility, get B(){ return B; }, set RUN(v){ RUN=v; } };`);
function setup(tpl, fac) {
  const R = T.runDefaults(); R.fac = 'hegemony'; R.admiral = 'kassar';
  R.fleet = [T.newShip('h_interdictor')]; R.flagUid = R.fleet[0].uid; T.RUN = R;
  T.startBattle({ kind: 'battle', fac, col: 3, enemies: [{ tpl }] });
  const u = T.B.units.find(x => x.side === 'player' && x.ab === 'ionpulse');
  const t = T.B.units.find(x => x.side === 'enemy');
  T.B.units = [u, t]; u.abCd = 0; u.braced = false; t.q = u.q + 1; t.r = u.r;
  return { u, t };
}
check('Cordon next to a shieldless Chorus ship cannot use ion pulse', () => {
  const { u, t } = setup('b_drone', 'chorus'); return t.sh.every(x => x === 0) && !T.canAbility(u);
});
check('Cordon next to a shielded Hegemony ship can use ion pulse', () => {
  const { u, t } = setup('h_picket', 'hegemony'); return t.sh.some(x => x > 0) && T.canAbility(u);
});
check('a squadron alone does not count even with shields', () => {
  const { u, t } = setup('fighter', 'hegemony'); t.isSq = true; t.sh = [10, 0, 0, 0]; return !T.canAbility(u);
});
check('depleted shields do not count; one positive facing at range four does; range five does not', () => {
  const { u, t } = setup('h_picket', 'hegemony'); t.sh = [0, 0, 0, 0];
  if (T.canAbility(u)) return false;
  t.sh[3] = 1; t.q = u.q + 4; if (!T.canAbility(u)) return false;
  t.q = u.q + 5; return !T.canAbility(u);
});
(async () => { let pass = 0, fail = 0;
  for (const [name, fn] of tests) { let ok = false, err = ''; try { ok = await fn(); } catch (e) { err = ' (' + e.message + ')'; }
    if (ok === true) { pass++; console.log('ok    ' + name); } else { fail++; console.log('FAIL  ' + name + err); } }
  console.log('\nIon tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
})();
