// campaign_loader.js - campaign-layer extension of the shared headless loader.
//
// game_loader.js loads data.js, core.js and battle.js. The campaign layer
// (campaign_meta.js: shell, title, progression, run end; campaign_run.js:
// map, shipyard, events, Nemesis, verbs, rewards) is plain script in the same
// style but touches the DOM at load time (document.getElementById('app')) and
// at call time (show/modal/toast write into elements). This loader runs the
// two campaign files in the SAME vm context the base loader built, after
// installing a minimal document stub whose elements record what the screens
// render (the #app element's innerHTML is the assertion surface for the
// shipyard tests). Presentation-only hooks the campaign files call but the
// harness does not need (tel, battleScreen) are stubbed the way game_loader
// stubs the fx hooks.
//
// Usage:
//   const { loadCampaign } = require('./campaign_loader');
//   const GC = loadCampaign('/path/to/voidsworn');  // dir containing the js files
//   GC.RUN = {...}; GC.ensureNemesis(); GC.nemAdapt();
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

// game_loader.js lives in the harness folder; resolve it from either home of
// this file (the wave 5 working folder or the staged tools tree).
const LOADER_CANDIDATES = [
  path.join(__dirname, '..', '..', 'voidsworn-harness', 'game_loader.js'),
  path.join(__dirname, 'game_loader.js'),
  path.join(process.env.HOME || '', 'workspace', 'voidsworn-harness', 'game_loader.js'),
];
const loaderPath = LOADER_CANDIDATES.find(p => fs.existsSync(p));
if (!loaderPath) throw new Error('game_loader.js not found in any candidate path');
const { loadGame } = require(loaderPath);

const CAMPAIGN_EXPORTS = [
  // shell + progression (campaign_meta.js)
  'ACT', 'touchWords', 'endRun', 'runRecap', 'legacyScreen', 'admiralScreen',
  // events + verbs (campaign_run.js)
  'needMet', 'needText', 'eventOptOk', 'eventFlags', 'nextEvent',
  'verbFor', 'verbFree', 'verbCanUse', 'useVerb', 'applyOutcome',
  // Nemesis (campaign_run.js)
  'ensureNemesis', 'newNemesis', 'nemReveal', 'nemWarnLine', 'nemStrike',
  'nemClockAdd', 'nemAdapt', 'nemAdaptName', 'nemAfterBattle', 'nemFoundMerge',
  'nemBeh', 'nemBattleCfg',
  // rewards, prizes, salvage (campaign_run.js)
  'rewardFlow', 'salvageYield', 'prizeRansom', 'prizeOffer', 'prizePlan',
  'boonDeclineCred', 'boonRerollCost', 'boonRerollOk', 'boonReroll', 'boonDecline',
  'resumeReward',
  // screens used as render surfaces
  'shipyardScreen', 'shipyardStock', 'fleetScreen', 'mapScreen',
  // tables the campaign tests read directly
  'EVENTS', 'FAC_VERBS', 'LEGACY',
];

function makeEl() {
  return {
    innerHTML: '', textContent: '', className: '', id: '', style: {}, dataset: {},
    children: [], disabled: false, offsetParent: null,
    appendChild(c) { this.children.push(c); return c; },
    remove() {}, focus() {}, addEventListener() {},
    setAttribute() {}, getAttribute() { return null; },
    querySelector() { return makeEl(); }, querySelectorAll() { return []; },
    getBoundingClientRect() { return { width: 0, height: 0, top: 0, left: 0 }; },
    classList: { add() {}, remove() {}, toggle() {}, contains: () => false },
    closest() { return null; },
  };
}

function loadCampaign(repoDir) {
  const out = loadGame(repoDir);
  const sandbox = out._sandbox;
  const runIn = (code) => vm.runInContext(code, sandbox);

  // DOM stub: getElementById returns one stable element per id, so a test can
  // read what show() last rendered into #app (or a modal into #modal).
  const els = {};
  sandbox.document = {
    getElementById(id) { return els[id] || (els[id] = makeEl()); },
    createElement() { return makeEl(); },
    body: makeEl(),
    addEventListener() {},
    querySelector() { return null; },
    querySelectorAll() { return []; },
  };
  sandbox.innerWidth = 1280;
  sandbox.innerHeight = 800;

  let src = '';
  for (const f of ['campaign_meta.js', 'campaign_run.js']) {
    const p = path.join(repoDir, f);
    if (!fs.existsSync(p)) throw new Error('missing campaign file: ' + p);
    src += '\n;// ===== ' + f + ' =====\n' + fs.readFileSync(p, 'utf8');
  }
  // Hooks the campaign layer calls but the harness does not need: tel lives in
  // campaign3d.js (telemetry sink), battleScreen in the 3D shell. The battle
  // stub records the cfg so a test could see a fight an event tried to start.
  src += '\nfunction tel(){} function battleScreen(cfg){ window.__lastBattleCfg = cfg; }';
  vm.runInContext(src, sandbox, { filename: 'voidsworn-campaign.js' });

  for (const name of CAMPAIGN_EXPORTS) {
    try { out[name] = runIn('typeof ' + name + '!=="undefined" ? ' + name + ' : undefined'); }
    catch (e) { out[name] = undefined; }
  }
  out.runIn = runIn;
  out.els = els;
  out.appEl = () => els.app;
  out.setGlobal = (name, value) => { sandbox[name] = value; };
  return out;
}

module.exports = { loadCampaign, CAMPAIGN_EXPORTS };
