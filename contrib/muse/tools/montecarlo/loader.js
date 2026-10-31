// loader.js - headless loader for the FULL Voidsworn campaign stack.
//
// Loads the shipped campaign files in build.py order (data.js, core.js,
// battle.js, campaign_meta.js, campaign_run.js, campaign3d.js) into a Node vm
// context with DOM/localStorage stubs, plus no-op stubs for the 3D and HUD
// functions those files call (all presentation only). The result is the real
// campaign loop: newRun, genSector, startBattle, finishBattle, rewardFlow,
// the ACT reward chain, shipyard handlers, events, and the Nemesis system.
//
// opts.replace: { '<file>': [[pattern, replacement], ...] } applies exact-once
// source replacements to the in-memory copy only (tuning grids). The files on
// disk are never touched; a pattern that does not occur exactly once throws.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const FILES = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js', 'campaign3d.js'];

// Presentation and engine stubs. Function declarations are hoisted across the
// whole concatenated script, so these are visible to the game files above them.
// animMove/animRotate commit position/facing exactly as sim3d.js's stubs do;
// animPath forwards onLate, which is the only rules-relevant part of it.
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

  const store = new Map();
  const localStorage = {
    getItem: k => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => { store.set(k, String(v)); },
    removeItem: k => { store.delete(k); },
  };
  const documentStub = {
    getElementById: () => makeEl(),
    createElement: () => makeEl(),
    querySelector: () => null,
    querySelectorAll: () => [],
    addEventListener() {}, removeEventListener() {},
    body: makeEl(), documentElement: makeEl(),
    visibilityState: 'visible',
  };
  const quietConsole = Object.assign({}, console, { debug() {} });
  // Zero-delay timers resolve as microtasks: the game's wait() multiplies by
  // SPEED (set to 0 by the driver), and Node's 1ms setTimeout floor would
  // otherwise dominate wall time (thousands of waits per run). Positive
  // delays keep real timers. Semantics of game rules are unaffected.
  const fastSetTimeout = (fn, ms, ...rest) => {
    if (!ms) { queueMicrotask(() => fn(...rest)); return 0; }
    return setTimeout(fn, ms, ...rest);
  };
  const sandbox = {
    console: quietConsole, setTimeout: fastSetTimeout, clearTimeout, setInterval, clearInterval,
    window: { addEventListener() {}, removeEventListener() {} },
    document: documentStub,
    localStorage,
    performance: { now: () => Date.now() },
    navigator: { userAgent: 'voidsworn-montecarlo' },
    process: { env: {} },
    innerWidth: 1280, innerHeight: 800,
    requestAnimationFrame: fn => setTimeout(fn, 0),
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(src, sandbox, { filename: 'voidsworn-campaign.js' });

  const out = { _sandbox: sandbox, store, localStorage };
  out.get = name => vm.runInContext('typeof ' + name + '!=="undefined" ? ' + name + ' : undefined', sandbox);
  out.set = (name, v) => { sandbox.__v = v; vm.runInContext(name + ' = __v', sandbox); };
  out.eval = code => vm.runInContext(code, sandbox);
  for (const prop of ['RUN', 'META', 'B']) {
    Object.defineProperty(out, prop, {
      get: () => vm.runInContext(prop, sandbox),
      set: v => { sandbox.__v = v; vm.runInContext(prop + ' = __v', sandbox); },
    });
  }
  return out;
}

module.exports = { loadGame };
