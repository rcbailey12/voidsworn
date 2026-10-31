// game_loader.js - shared headless loader for the Voidsworn browser rules files.
//
// Loads data.js, core.js and battle.js from a repo checkout into a Node vm
// context with the minimal browser stubs they touch at load and call time
// (window, localStorage, performance). The rules files are plain scripts with
// top-level function declarations, so the loader concatenates them with an
// export hook and runs the whole string in one context; the named functions
// and tables are then reachable as properties of the returned object.
//
// Usage:
//   const { loadGame } = require('./game_loader');
//   const G = loadGame('/path/to/voidsworn');   // dir containing data.js etc.
//   G.rndSeed(123); const fleet = G.genEnemyFleet('hegemony', 2, 3, 'elite', null, null);
//
// The localStorage stub is in-memory and inspectable: G.store is the backing
// Map, and G.localStorage is the stub object the game code sees.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const EXPORTS = [
  // rng + helpers (core.js)
  'rndSeed', 'rnd', 'ri', 'pick', 'shuffle', 'clamp',
  // tables (data.js)
  'HULLS', 'FACTIONS', 'ADMIRALS', 'RELICS', 'MODULES', 'BOONS', 'PATRONS',
  'ASPECTS', 'PERKS', 'HEAT', 'RARITY', 'CAPTAINS',
  'W', 'HULL_VARIANTS', 'FAC_PRICE', 'RELIC_NAMES', 'BOON_NEED', 'ARC_NAME',
  'FAC_GATES', 'ENCOUNTERS', 'SHAPES',
  // fleet generation + ramp (battle.js / core.js)
  'genEnemyFleet', 'effArch', 'RAMP', 'fleetPower',
  'genSector', 'startBattle', 'terrainConnected', 'onBoard', 'alive',
  // persistence (core.js)
  'Persist', 'STORE_KEY', 'SAVE_VERSION', 'defaultMeta', 'migrateMeta',
  'migrateRun', 'runDefaults', 'normalizeRun', 'repairRunIds',
  'saneMeta', 'saneRun', 'saneSave',
  // run/ship constructors (core.js)
  'newShip', 'newCaptain', 'derive', 'sumFx', 'fleetFxList', 'runFx',
];

function loadGame(repoDir) {
  const files = ['data.js', 'core.js', 'battle.js'];
  let src = '';
  for (const f of files) {
    const p = path.join(repoDir, f);
    if (!fs.existsSync(p)) throw new Error('missing rules file: ' + p);
    src += '\n;// ===== ' + f + ' =====\n' + fs.readFileSync(p, 'utf8');
  }
  // Presentation hooks the rules files call but the harness does not need.
  src += '\nfunction log(m){ if(typeof B!=="undefined"&&B&&B.log) B.log.push({m}); }' +
    ' function fxText(){} function fxShield(){} function fxFlash(){} function fxShieldBreak(){}' +
    ' function fxRam(){} function fxBoard(){} function fxWithdraw(){} function onCapture(){}';

  const store = new Map();
  const localStorage = {
    getItem: k => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => { store.set(k, String(v)); },
    removeItem: k => { store.delete(k); },
  };
  const sandbox = {
    console,
    setTimeout, clearTimeout, setInterval, clearInterval,
    window: {},
    localStorage,
    performance: { now: () => Date.now() },
    process_env: () => null,
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(src, sandbox, { filename: 'voidsworn-rules.js' });

  const out = { _sandbox: sandbox, store, localStorage };
  for (const name of EXPORTS) {
    out[name] = vm.runInContext('typeof ' + name + '!=="undefined" ? ' + name + ' : undefined', sandbox);
  }
  // META and SAVED_RUN are `let` bindings: read/write them through accessors.
  Object.defineProperty(out, 'META', {
    get: () => vm.runInContext('META', sandbox),
    set: v => { sandbox.__v = v; vm.runInContext('META = __v', sandbox); },
  });
  Object.defineProperty(out, 'SAVED_RUN', {
    get: () => vm.runInContext('SAVED_RUN', sandbox),
    set: v => { sandbox.__v = v; vm.runInContext('SAVED_RUN = __v', sandbox); },
  });
  Object.defineProperty(out, 'RUN', {
    get: () => vm.runInContext('RUN', sandbox),
    set: v => { sandbox.__v = v; vm.runInContext('RUN = __v', sandbox); },
  });
  Object.defineProperty(out, 'B', {
    get: () => vm.runInContext('B', sandbox),
  });
  return out;
}

module.exports = { loadGame, EXPORTS };
