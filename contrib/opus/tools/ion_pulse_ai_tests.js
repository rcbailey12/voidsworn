// Issue 1447: when the enemy AI fires the Cordon's ion pulse, on the browser rules (battle.js). Run from the repo root:
//   node contrib/opus/tools/ion_pulse_ai_tests.js
// The cases and their fixed expectations are in godot/rules/test/ion_pulse_ai_cases.json; the Godot twin
// godot/rules/test/ion_pulse_ai_test.gd checks the same cases on rules.gd. Both fail on main before the fix.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = (f) => { f(); return 0; };
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const CASES = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/rules/test/ion_pulse_ai_cases.json'), 'utf8')).cases;
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
SPEED=0;
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, set B(v){ B=v; }, migrateRun, newShip, startBattle, syncShields, aiAbilities, hdist };
`);
const DIRS = [[1, 0], [0, 1], [-1, 0], [0, -1], [1, -1], [-1, 1]];
const base = (o) => Object.assign({ fac: 'voidsworn', admiral: 'vex', credits: 500, cpCap: 30, sector: 1, relics: [], inventory: [], boons: [], map: { cols: [] }, fleet: [] }, o || {});
async function run(c) {
  T.RUN = T.migrateRun(base({ fleet: c.targets.map(t => T.newShip(t.tpl)) })); T.RUN.flagUid = T.RUN.fleet[0].uid;
  T.startBattle({ kind: 'battle', fac: 'hegemony', col: 3, enemies: [{ tpl: 'h_interdictor' }], shape: 'open', map: 'open', obj: 'rout', seed: 7, dep: 'line' });
  const B = T.B; B.terrain = {}; for (const u of B.units.filter(x => x.isSq)) u.dead = true;
  const cordon = B.units.find(u => u.side === 'enemy' && !u.isSq), ps = B.units.filter(u => u.side === 'player' && !u.isSq);
  if (!cordon || cordon.ab !== 'ionpulse' || ps.length !== c.targets.length) throw new Error('setup');
  cordon.q = 10; cordon.r = 10;
  c.targets.forEach((t, i) => { const u = ps[i], d = DIRS[i]; u.q = 10 + d[0] * t.dist; u.r = 10 + d[1] * t.dist; u.shp = t.shp; T.syncShields(u); });
  if (c.moveTo != null) { const d = DIRS[0], t0 = ps[0]; cordon.q = t0.q - d[0] * c.moveTo; cordon.r = t0.r - d[1] * c.moveTo; }
  B.log = []; B.side = 'enemy';
  await T.aiAbilities(cordon, () => true, c.mode);
  const line = B.log.map(x => x.m).find(m => / fires an ion pulse: /.test(m));
  const n = line ? Number(line.match(/ion pulse: (\d+) /)[1]) : null;
  return { pulse: !!line, n, line };
}
(async () => { let pass = 0, fail = 0;
  for (const c of CASES) { try { const r = await run(c);
      const ok = r.pulse === c.pulse && (!c.pulse || c.logN == null || r.n === c.logN);
      if (ok) { pass++; console.log('ok    ' + c.name); } else { fail++; console.log('FAIL  ' + c.name + ': pulse ' + r.pulse + (r.line ? ' (' + r.line + ')' : '') + ', wanted pulse ' + c.pulse + (c.logN != null ? ' with ' + c.logN + ' in the log' : '')); }
    } catch (e) { fail++; console.log('FAIL  ' + c.name + ': ' + (e && e.message)); } }
  console.log('\nIon pulse AI tests (battle.js): ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0; })();
