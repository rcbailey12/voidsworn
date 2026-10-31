// loader_main.js - same contract as loader.js, but the game runs in the Node
// main context (indirect eval, like sim3d.js) instead of a vm context.
// Contextified vm globals carry a heavy access penalty for this global-heavy
// code; process isolation (one shard process per copy) replaces vm isolation.
// Determinism vs the vm loader is verified on fixed seeds before use.
'use strict';
const fs = require('fs');
const path = require('path');

const FILES = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js', 'campaign3d.js'];
const STUBS = `
function log(m,c){ if(typeof B!=='undefined'&&B&&B.log) B.log.push({m,c}); }
function fxText(){} function fxShield(){} function fxFlash(){} function fxShieldBreak(){}
function fxRam(){} function fxBoard(){} function fxWithdraw(){} function onCapture(){}
async function animPath(u,path,opt){ if(opt&&opt.onLate) await opt.onLate(); }
async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; }
async function animRotate(u,f){ u.facing=f; }
async function animWeapon(){} async function animExplode(){} async function animNova(){}
async function roundStart(){ await roundStartBoth(); }
function disposeAllViews(){} function clearOverlays(){} function hideEnd(){}
function setupFleetShowcase(){} function buildBattleEnv(){} function buildBeacon(){}
function bRefresh(){} function hexWorld(q,r){ return {x:q,y:r}; }
async function banner(){}
function selectUnit(u){ if(typeof B!=='undefined'&&B) B.sel=u; }
var G={mobile:false,quality:'high',sfxOn:false,fxReduced:false,shakeRed:false,cine:false,cineMode:'off',follow:false,taaOn:false,aiHulls:false,time:0,jumpUntil:0,logRaf:0,actLog:null,scene:null,ctl:{attract:false,topdown:false,establish(){},reset(){}}};
`;

function makeEl() {
  const el = {
    children: [], style: {}, dataset: {}, textContent: '', innerHTML: '', className: '', id: '',
    disabled: false, offsetParent: null,
    classList: { add() {}, remove() {}, toggle() {} },
    addEventListener() {}, removeEventListener() {},
    appendChild(c) { el.children.push(c); return c; },
    remove() {}, focus() {}, select() {},
    querySelector: () => null, querySelectorAll: () => [],
    closest: () => null,
    getBoundingClientRect: () => ({ top: 0, left: 0, height: 0, width: 0 }),
    insertAdjacentHTML() {},
  };
  return el;
}

const geval = (0, eval);

function loadGame(repoDir, opts = {}) {
  let src = '';
  for (const f of FILES) {
    const p = path.join(repoDir, f);
    if (!fs.existsSync(p)) throw new Error('missing game file: ' + p);
    let s = fs.readFileSync(p, 'utf8');
    for (const [pat, rep] of (opts.replace && opts.replace[f]) || []) {
      const n = s.split(pat).length - 1;
      if (n !== 1) throw new Error('replace pattern found ' + n + 'x in ' + f + ': ' + pat.slice(0, 70));
      s = s.replace(pat, rep);
    }
    src += '\n;// ===== ' + f + ' =====\n' + s;
  }
  src += '\n;// ===== harness stubs =====\n' + STUBS;
  for (const extra of opts.extra || []) src += '\n;// ===== harness extra =====\n' + extra;
  // The epilogue's closures capture this script's lexical scope (const/let
  // bindings from the game files), which is the only way to reach them after
  // an indirect eval returns.
  src += '\n;globalThis.__api={ runOne:(c)=>MC.runOne(c), sampleBoons:(c)=>MC.sampleBoons(c), get:(n)=>eval(n) };';

  const store = new Map();
  globalThis.localStorage = {
    getItem: k => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => { store.set(k, String(v)); },
    removeItem: k => { store.delete(k); },
  };
  globalThis.document = {
    getElementById: () => makeEl(),
    createElement: () => makeEl(),
    querySelector: () => null,
    querySelectorAll: () => [],
    addEventListener() {}, removeEventListener() {},
    body: makeEl(), documentElement: makeEl(),
    visibilityState: 'visible',
  };
  globalThis.window = { addEventListener() {}, removeEventListener() {} };
  try { Object.defineProperty(globalThis, 'navigator', { value: { userAgent: 'voidsworn-montecarlo' }, configurable: true }); } catch (e) {}
  globalThis.innerWidth = 1280; globalThis.innerHeight = 800;
  globalThis.requestAnimationFrame = fn => setTimeout(fn, 0);
  const realST = globalThis.setTimeout;
  globalThis.setTimeout = (fn, ms, ...rest) => { if (!ms) { queueMicrotask(() => fn(...rest)); return 0; } return realST(fn, ms, ...rest); };
  const realDebug = console.debug; console.debug = () => {};

  geval(src);

  const out = { _main: true, store, api: globalThis.__api };
  out.get = name => globalThis.__api.get(name);
  out.eval = () => { throw new Error('loader_main: use api.get / api.runOne; bare eval cannot see game lexical bindings'); };
  return out;
}

module.exports = { loadGame };
