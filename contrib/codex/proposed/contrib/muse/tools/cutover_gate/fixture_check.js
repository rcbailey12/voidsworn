'use strict';
// fixture_check.js - gate-side loader check for the cutover importer fixtures.
//
// Re-runs the verification the fixture generator performed when the fixtures
// were built (savings pass wave 5): every fixture store is loaded through a
// FRESH game instance's own Persist.loadLocal, the loaded state must pass the
// game's own saneSave, and it must equal the loaded state recorded inside
// the fixture file. Single-file fixtures carry their own recorded state;
// the three input/output pairs check the input store against the output
// file's recorded state.
//
// This script only reads. It writes nothing.
//
// Usage: node fixture_check.js <repoDir> <fixturesDir> <gameLoaderPath>
// Output: one "PASS fixture <label>" or "FAIL fixture <label>: <reason>"
// line per case, then a summary line. Exit 1 when any case fails.

const fs = require('fs');
const path = require('path');

const repoDir = process.argv[2];
const fixturesDir = process.argv[3];
const loaderPath = process.argv[4];
if (!repoDir || !fixturesDir || !loaderPath) {
  console.error('fixture_check: usage: node fixture_check.js <repoDir> <fixturesDir> <gameLoaderPath>');
  process.exit(2);
}
const { loadGame } = require(loaderPath);

const deep = x => (x == null ? x : JSON.parse(JSON.stringify(x)));
const stable = x => {
  if (x == null || typeof x !== 'object') return JSON.stringify(x);
  if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
  return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
};
const read = n => JSON.parse(fs.readFileSync(path.join(fixturesDir, n), 'utf8'));

function bootLoad(store) {
  const G = loadGame(repoDir);
  G.store.clear();
  for (const k in store) G.store.set(k, store[k]);
  let threw = null;
  try { G.Persist.loadLocal(); } catch (e) { threw = e; }
  return { G, threw, meta: deep(G.META), run: deep(G.SAVED_RUN), recovered: !!G.Persist.recovered };
}

const SINGLES = ['fresh.json', 'midrun.json', 'unlocked.json', 'partial_grant.json',
  'longlived_meta.json', 'early_run.json', 'reward_mod.json', 'reward_prize.json',
  'reward_salvage.json', 'reward_promo.json', 'meta_junk.json', 'nemesis_late.json',
  'fleet_edges.json', 'sector3_run.json', 'settled_run.json', 'half_meta.json',
  'half_run.json', 'absent_store.json'];
const PAIRS = [['repaired', 'repaired_input.json', 'repaired_output.json'],
  ['corrupt', 'corrupt_input.json', 'corrupt_output.json'],
  ['corrupt2', 'corrupt2_input.json', 'corrupt2_output.json']];

let passed = 0, total = 0;
function check(label, storeObj, expectedLoaded) {
  total++;
  let boot;
  try { boot = bootLoad(storeObj); } catch (e) {
    console.log('FAIL fixture ' + label + ': loader threw: ' + e.message);
    return;
  }
  if (boot.threw) { console.log('FAIL fixture ' + label + ': loadLocal threw: ' + boot.threw.message); return; }
  if (!boot.G.saneSave({ meta: boot.G.META, run: boot.G.SAVED_RUN })) {
    console.log('FAIL fixture ' + label + ': loaded state fails saneSave');
    return;
  }
  const got = { meta: boot.meta, run: boot.run, recovered: boot.recovered };
  if (expectedLoaded && stable(got) !== stable(expectedLoaded)) {
    console.log('FAIL fixture ' + label + ': loaded state differs from the recorded loaded state');
    return;
  }
  passed++;
  console.log('PASS fixture ' + label);
}

for (const n of SINGLES) {
  const f = read(n);
  check(n, f.store, f.loaded);
}
for (const [label, inp, outp] of PAIRS) {
  const i = read(inp), o = read(outp);
  check(label + ' pair', i.store, o.loaded);
}

console.log('fixture_check: ' + passed + '/' + total + ' cases passing');
process.exit(passed === total ? 0 : 1);
