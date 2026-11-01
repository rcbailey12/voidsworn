// Campaign battle start smoke test (stream B, Oct 31). Run from the repo root: node contrib/opus/tools/campaign_start_test.js
// Loads the real campaign3d.js on top of the rules files with the browser parts stubbed, then drives battleScreen() for a battle, an elite,
// a Hegemony Nemesis fight and a boss, and checks that prepBattle ran and the start telemetry carried setupMs. Codex found (Oct 31) that a
// line comment in battleScreen swallowed `prepBattle(); const setupMs=...`, so every browser campaign battle threw a ReferenceError at start.
// The second check scans every top-level JS file for a // comment that is followed by code on the same line, so that cannot hide again.
global.window = { addEventListener() {} }; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', textContent: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { this.children.push(c); return c; }, remove() {}, querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: () => el(), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
let pass = 0, fail = 0; const out = [];
const ok = (name, c, note) => { (c ? pass++ : fail++); out.push((c ? 'ok    ' : 'FAIL  ') + name + (note ? ': ' + note : '')); };
// browser-only functions campaign3d.js calls; each one is a no-op except prepBattle and tel, which record that they ran
const STUBS = `
var PREP=0, TELS=[]; function prepBattle(){ PREP++; } function tel(k,o){ TELS.push([k,o]); }
function closeModal(){} function hideEnd(){ return null; } function hideTip(){} function disposeAllViews(){} function clearOverlays(){} function toast(){} function banner(){} function selectUnit(){}
function show(){} function mapScreen(){} function titleScreen(){} function fxMark(){} function hullMapPrefetch(){} function log(m){ if(B&&B.log) B.log.push({m}); }
function fxText(){} function fxShield(){} function fxFlash(){} async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){}
var FRAMES={reset(){}}; var G={ctl:{attract:false,establish(){}},scene:{getActiveMeshes(){ return {length:0,data:[]}; }}};
`;
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(read).join('\n');
let c3 = read('campaign3d.js');
// campaign3d.js redefines tel(); keep the recording stub instead
c3 = c3.replace(/^function tel\(/m, 'function _telReal(');
let loadErr = null;
try {
  eval(STUBS + src + '\n' + c3 + `
  global.T = { battleScreen, newRun, genSector, newNemesis, META, ADMIRALS, RUN_FACTIONS, get RUN(){ return RUN; }, get B(){ return B; }, get PREP(){ return PREP; }, get TELS(){ return TELS; }, set PREP(v){ PREP=v; } };`);
} catch (e) { loadErr = e; }
ok('campaign3d.js loads on top of the rules files', !loadErr, loadErr && loadErr.message);
if (!loadErr) {
  const cases = [['battle', 'corsair', null], ['elite', 'chorus', null], ['elite', 'hegemony', 'nemesis'], ['boss', 'ithar', null]];
  for (const [kind, fac, nem] of cases) {
    let err = null;
    try {
      T.META.unlocked = {}; T.newRun('vex', 'voidsworn'); T.PREP = 0; T.TELS.length = 0;
      const cfg = { kind, fac, col: kind === 'boss' ? 6 : 2 };
      if (nem) { const N = T.newNemesis(); N.fac = 'hegemony'; cfg.nemesis = Object.assign({}, N, { weak: [], adapt: [] }); }
      T.battleScreen(cfg);
    } catch (e) { err = e; }
    const st = T.TELS.find(x => x[0] === 'battle_start');
    ok('battleScreen starts a campaign ' + kind + (nem ? ' (Hegemony Nemesis)' : '') + ' against ' + fac + ': no throw, prepBattle ran, start telemetry has setupMs',
      !err && T.PREP === 1 && st && Number.isFinite(st[1].setupMs) && T.B && T.B.campaign, err ? err.message : ('prep ' + T.PREP + ', setupMs ' + (st && st[1].setupMs)));
  }
}
// static scan: a // comment followed by statements on the same line (prose with "f(); a" is allowed only in this short list)
{
  const files = fs.readdirSync(ROOT).filter(f => f.endsWith('.js'));
  const bad = [];
  for (const f of files) { read(f).split('\n').forEach((l, i) => {
    const t = l.replace(/'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|`(?:\\.|[^`\\])*`/g, 'S').replace(/https?:\/\/\S+/g, 'U');
    const m = /(?<![:\\/*])\/\/(?!\/)/.exec(t); if (!m) return; const com = t.slice(m.index + 2);
    if (/\b[a-zA-Z_]\w*\([^)]*\);\s*(const|let|var|if|for|return|await)\b/.test(com) || /;\s*(const|let|var)\s+\w+\s*=/.test(com)) bad.push(f + ':' + (i + 1));
  }); }
  ok('no // comment swallows code on the same line (' + files.length + ' JS files)', !bad.length, bad.slice(0, 6).join(', '));
}
console.log(out.join('\n')); console.log('\nCampaign start tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
