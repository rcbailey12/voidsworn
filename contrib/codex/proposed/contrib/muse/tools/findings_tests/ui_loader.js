'use strict';
// ui_loader.js - headless UI-state extension of the findings-tests harness.
//
// ui3d.js holds the battle screen's state machine (B.sel, B.wingSel,
// B.armed, B.reach, the hint line) but is written against the DOM and the
// Babylon shell, so the rules harness could not load it. This loader runs
// ui3d.js in the campaign loader's context (campaign_meta.js and
// campaign_run.js first, because ui3d extends their ACT table) behind two
// stubs:
//
//   - a registry DOM: getElementById returns an element only for ids a
//     screen actually created, null otherwise. The distinction is load
//     bearing: onKey routes Escape to the modal branch whenever a #modal
//     element exists, so the campaign stub's auto-creating getElementById
//     would invent a modal and swallow the key. createElement elements are
//     inert property bags in the campaign stub's makeEl shape.
//   - a minimal G shell object (camera control, quality flags, the command
//     confirm window) with no-op camera methods, plus uWorld, the scene
//     coordinate helper ACT.rosterPick calls. Both are presentation: the
//     state transitions under test (selectUnit, cancelAction, onKey,
//     ACT.arm, ACT.rosterPick, actionStrip, bestFacingReach, updateReach)
//     are the game's own functions, unmodified.
//
// bRefresh, ui3d's render fan-out into the DOM and the 3D overlays, is
// replaced after load with a counting no-op: the state functions call it
// purely as a repaint notification, and nothing in the UI rows asserts
// pixels. The busy watchdog's setInterval is unref'd so the suite can exit.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { loadCampaign } = require(path.join(__dirname, 'campaign_loader.js'));

function makeEl() {
  return {
    innerHTML: '', textContent: '', className: '', id: '', style: {}, dataset: {},
    children: [], disabled: false, offsetParent: null,
    appendChild(c) { this.children.push(c); return c; },
    remove() {}, focus() {}, addEventListener() {},
    setAttribute() {}, getAttribute() { return null; },
    querySelector() { return null; }, querySelectorAll() { return []; },
    getBoundingClientRect() { return { width: 0, height: 0, top: 0, left: 0, bottom: 0, x: 0, y: 0 }; },
    classList: { add() {}, remove() {}, toggle() { return false; }, contains: () => false },
    closest() { return null; },
  };
}

function loadUI(repoDir) {
  const out = loadCampaign(repoDir);
  const sandbox = out._sandbox;
  const runIn = (code) => vm.runInContext(code, sandbox);

  const els = {};
  sandbox.document = {
    getElementById(id) { return els[id] || null; },
    createElement() { return makeEl(); },
    body: makeEl(),
    addEventListener() {},
    querySelector() { return null; },
    querySelectorAll() { return []; },
    visibilityState: 'visible',
  };
  sandbox.addEventListener = () => {};
  const rawSetInterval = sandbox.setInterval;
  sandbox.setInterval = (fn, ms) => { const t = rawSetInterval(fn, ms); if (t && t.unref) t.unref(); return t; };
  sandbox.innerWidth = 1280;
  sandbox.innerHeight = 800;
  sandbox.G = {
    mobile: false, quality: 'high', aiHulls: true, cine: false, cineMode: 'off', follow: false,
    taaOn: false, sfxOn: false, shakeRed: false, fxReduced: false, skipTurn: false, legendOpen: false,
    cmdConfirmMs: 6000, views: new Map(),
    ctl: { focus() {}, reset() {}, toggleTop() {}, release() {}, establish() {}, attract: false, r: 120, t: null, a: 0, b: 0 },
  };

  const src = fs.readFileSync(path.join(repoDir, 'ui3d.js'), 'utf8');
  vm.runInContext(src, sandbox, { filename: 'ui3d.js' });

  // Scene-coordinate helper from the 3D shell (fx3d.js): rosterPick calls it
  // only to aim the camera, so a coordinate echo is an honest stub.
  runIn('function uWorld(u){ return { x: u.q, z: u.r }; }');
  // The render fan-out becomes a counter; see the header note.
  runIn('bRefresh = function(){ bRefresh.calls = (bRefresh.calls || 0) + 1; };');

  out.runInUI = runIn;
  out.uiEls = els;
  return out;
}

module.exports = { loadUI };
