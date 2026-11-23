// Issue 1641: Eclipse has no green anywhere (Ryan, Nov 21). Both rule copies print the Eclipse revive, reclaim and phase
// callouts in Eclipse violet, the sRGB form of godot/fx/faction_looks.json deathless.weapon, and keep green for every other
// faction. Checks the browser function itself, the Godot twin's matching code, and the battle.gd "Risen" float. Run from the
// repo root (or anywhere: paths are relative to this file).
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { this.children.push(c); return c; }, remove() {}, querySelector() { return null; }, querySelectorAll() { return []; },
  addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: () => el(), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const JS = read('battle.js'), GD = read('godot/rules/rules.gd'), BGD = read('godot/scenes/battle/battle.gd');
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(['data.js', 'core.js', 'battle.js'].map(read).join('\n') + '\nglobal.T = { eclCol, ECL_VIOLET };');

const looks = JSON.parse(read('godot/fx/faction_looks.json'));
const srgb = c => (c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055);
const want = '#' + looks.deathless.weapon.map(c => Math.round(srgb(c) * 255).toString(16).padStart(2, '0')).join('');
const CALLOUTS = ['Reassembled', 'Rebuilding', 'Reassembling: rises next round', 'Phase shift'];
// issue 1649: Godot replaced Phase shift with Fold skip; the frozen browser copy keeps Phase shift
const GD_CALLOUTS = ['Reassembled', 'Rebuilding', 'Reassembling: rises next round', 'Fold skip'];

check('ECL_VIOLET is faction_looks deathless.weapon in sRGB (' + want + ')', () => T.ECL_VIOLET === want);
check('eclCol: Eclipse ships get violet', () => T.eclCol({ fac: 'deathless' }) === want);
check('eclCol: other factions keep green', () => ['voidsworn', 'corsair', 'ithar', 'chorus', 'hegemony'].every(f => T.eclCol({ fac: f }) === '#7dff9b'));
check('Godot twin uses the same violet', () => new RegExp('const ECL_VIOLET := "' + want + '"').test(GD));
check('Godot eclCol matches the browser rule', () => /func eclCol\(u\) -> String: return ECL_VIOLET if u != null and String\(u\.get\("fac", ""\)\) == "deathless" else "#7dff9b"/.test(GD));
for (const w of CALLOUTS) {
  check('browser: "' + w.trim() + '" uses eclCol, never a fixed green', () => {
    const lines = JS.split('\n').filter(l => l.includes("'" + w + "'"));
    return lines.length > 0 && lines.every(l => /eclCol\(/.test(l) && !new RegExp("'" + w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "','#7dff9b'").test(l));
  });
}
for (const w of GD_CALLOUTS) {
  check('Godot: "' + w.trim() + '" uses eclCol, never a fixed green', () => {
    const lines = GD.split('\n').filter(l => l.includes('"' + w + '"'));
    return lines.length > 0 && lines.every(l => /eclCol\(/.test(l));
  });
}
check('reclaim "+N hull" uses eclCol in both copies', () => /a==='reclaim'.*fxText\(t,'\+'\+h\+' hull',eclCol\(t\)/.test(JS) && /flt\(t, "\+" \+ ns\(h\) \+ " hull", eclCol\(t\), -24\)/.test(GD));
check('"Restarts" (generic revive) stays green in both copies', () => /'Restarts','#7dff9b'/.test(JS) && /"Restarts", "#7dff9b"/.test(GD));
check('battle.gd "Risen" float is Eclipse violet', () => BGD.includes('_float(e["unit"], "Risen", Color("' + want + '")'));
console.log(`\neclipse violet 1641: ${pass} ok, ${fail} failed`);
process.exit(fail ? 1 : 0);
