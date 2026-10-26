// G3 campaign parity: loads the pinned JS game files (../oracle) headless, unchanged, with no-op presentation calls,
// the same way godot/rules/test/node/golden.js and sim3d.js do. The browser page is replaced by small stubs; show() and
// modal() record the HTML they are given so the harness can read the buttons a player would see.
//
// What the harness replaces (presentation, not rules):
// - every 3D call (views, overlays, camera, banners, effects): no-ops;
// - the title and map "showcase" battles (setupShowcase, setupFleetShowcase): no-ops. In the browser these build a decorative
//   battle that draws from the rules PRNG; the Godot port does not, so both sides leave them out (see README, finding 1);
// - startBattle: the stub battle below (identical in GDScript, godot/campaign/battle_stub.gd), until real battles are hooked in;
// - Date.now() is 0 (ship ids x01, x02 ...), setTimeout runs nothing (toasts only), storage is empty.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const ORACLE = process.env.VS_ORACLE ? path.resolve(process.env.VS_ORACLE) : path.resolve(__dirname, '..', 'oracle');
const FILES = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js', 'campaign3d.js'];

// ui3d.js is presentation, but two of its tables reach the rules: FNAMES (ship names for non-Voidsworn fleets, read by
// core.js shipName when it exists, as it does in the browser) and TIPS (the battle onboarding tips, exported for the battle UI).
// Only those two blocks are evaluated, verbatim.
function uiTables() {
  const s = fs.readFileSync(path.join(ORACLE, 'ui3d.js'), 'utf8');
  const grab = n => { const i = s.indexOf('const ' + n + '='); if (i < 0) throw new Error('ui3d.js: no ' + n); const j = s.indexOf(';\n', i); return s.slice(i, j + 1); };
  return grab('FNAMES') + '\n' + grab('TIPS');
}
function load(extra) {
  Date.now = () => 0;
  global.require = require; global.Buffer = Buffer;
  const stub = new Proxy(function () {}, { get: (t, k) => (k === Symbol.toPrimitive ? () => '' : k === Symbol.iterator ? undefined : k === 'length' ? 0 : stub), apply: () => stub, set: () => true, construct: () => stub });
  const el = () => stub;
  global.window = { addEventListener() {} };
  global.document = { getElementById: el, querySelector: el, querySelectorAll: () => [], createElement: el, addEventListener() {}, body: stub, execCommand() { return false; } };
  global.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
  try { Object.defineProperty(global, "navigator", { value: {}, configurable: true, writable: true }); } catch (e) {}
  global.innerWidth = 1920; global.innerHeight = 1080;
  global.performance = { now: () => 0 };
  global.setTimeout = () => 0; global.setInterval = () => 0; global.clearInterval = () => {};
  const src = FILES.map(f => fs.readFileSync(path.join(ORACLE, f), 'utf8') + (f === 'battle.js' ? '\n' + uiTables() : '')).join('\n');
  const PRE = String.raw`
var G=new Proxy({mobile:false,quality:'high',fxReduced:false,shakeRed:false,sfxOn:true,cine:false,follow:true},{get:(o,k)=>k in o?o[k]:__stub});
function disposeAllViews(){} function clearOverlays(){} function hideEnd(){} function showIntro(){} function selectUnit(){} function banner(){} function prepBattle(){}
function refreshTop(){} function saveOpts(){} function setupBattle(){} function bRefresh(){} function buildBattleEnv(){} function hullMapPrefetch(){} function fxMark(){}
function survivorsP(){ return B?B.units.filter(u=>u.side==='player'&&!u.dead&&!u.isSq).length:0; }
var FRAMES={reset(){},summary(){ return null; }}, SFX={init(){},getVol(){ return 1; },setVol(){}}, SETUP={alt:true}, PLAYABLE=['voidsworn'];
function log(){} function fxText(){} function fxShield(){} function fxFlash(){}
`;
  global.__stub = stub;
  const POST = String.raw`
setupShowcase=function(){}; setupFleetShowcase=function(){};
`;
  vm.runInThisContext(PRE + src + '\n' + POST + '\n' + (extra || ''), { filename: 'campaign_bundle.js' });
}
module.exports = { load, ORACLE, FILES };
