// save_fuzz.js - mutation fuzzer for the browser save layer (Persist).
//
// Builds one valid baseline save through the game's own constructors, writes
// it through Persist.saveLocal into an in-memory localStorage stub, then
// applies seeded mutations to the stored envelope and reloads through
// Persist.loadLocal. After every mutation it asserts the load path's own
// contract (core.js, the B1 save-brick fixes):
//
//   1. loadLocal never throws, whatever bytes are in the store.
//   2. The loaded META passes the game's own saneMeta check.
//   3. The loaded SAVED_RUN is null, or passes saneRun, and every ship left
//      in its fleet names a hull that exists in HULLS (repairRunIds drops
//      unknown ids instead of crashing later screens).
//   4. Every relic, module, boon, perk, patron and heat id left in the
//      loaded run exists in its table.
//   5. Credits in the loaded run are finite (the B1 NaN-credits repair).
//   6. Round-trip: a save written by saveLocal reloads to a sane state.
//
// Mutations are driven by the game's own seeded RNG (rndSeed/rnd), so a
// failing seed reproduces exactly. Usage:
//   node save_fuzz.js [repoDir] [rounds] [seedBase]
// Exit code 0 = contract held for every round; 1 = failures printed.
'use strict';
const { loadGame } = require('./game_loader');
const path = require('path');

const repoDir = process.argv[2] || require('path').resolve(__dirname, '..', '..', '..', '..');
const ROUNDS = parseInt(process.argv[3] || '300', 10);
const SEED = parseInt(process.argv[4] || '4242', 10);
const G = loadGame(repoDir);
const { HULLS, RELICS, MODULES, BOONS, PERKS, PATRONS, HEAT } = G;

let failures = [];
function fail(round, msg) { failures.push('round ' + round + ': ' + msg); }

// Baseline save, built with the game's own constructors.
function baseline() {
  G.META = G.defaultMeta();
  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.map = { cols: [[], [], []] };
  run.credits = 120;
  const ship = G.newShip('warden', false);
  ship.hp = 40;
  run.fleet = [ship];
  run.flagUid = ship.uid;
  G.SAVED_RUN = G.normalizeRun(run);
  G.Persist.saveLocal();
  return G.store.get(G.STORE_KEY);
}

const VALID = baseline();
if (!VALID) { console.log('FAIL: baseline save was not written'); process.exit(1); }

const JUNK_IDS = ['zzz_unknown', 'cogitator', '', 'WARDEN', 42, null, {}, []];
const MUTATORS = [
  // Truncate the JSON text at a random point.
  (s, R) => s.slice(0, Math.floor(R() * s.length)),
  // Corrupt one character.
  (s, R) => { const i = Math.floor(R() * s.length); return s.slice(0, i) + String.fromCharCode(33 + Math.floor(R() * 90)) + s.slice(i + 1); },
  // Structural mutations on the parsed envelope.
  (s, R) => { const o = JSON.parse(s); o.meta = R() < 0.5 ? [] : 42; return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); o.run = R() < 0.5 ? 'x' : [1, 2]; return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run) o.run.fleet = R() < 0.5 ? 'nope' : [null, 7, { tpl: 'zzz_unknown' }]; return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run) { o.run.relics = [JUNK_IDS[Math.floor(R() * JUNK_IDS.length)]]; o.run.inventory = ['zzz_unknown']; } return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run) { o.run.credits = [null, 'NaN', 1e999, -5][Math.floor(R() * 4)]; } return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run) { o.run.admiral = 'zzz_unknown'; o.run.fac = 'zzz_unknown'; o.run.boons = [{ id: 'zzz_unknown', r: 0 }, null]; o.run.patrons = ['zzz_unknown']; o.run.heat = ['zzz_unknown']; } return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.meta) { o.meta.stats = 42; o.meta.renown = 'lots'; } return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run && o.run.fleet && o.run.fleet[0]) { o.run.fleet[0].cap = { perks: ['zzz_unknown', 9], xp: 'x' }; o.run.fleet[0].mods = ['zzz_unknown']; o.run.fleet[0].hp = -3; } return JSON.stringify(o); },
  (s, R) => { const o = JSON.parse(s); if (o.run) { o.run.reward = { stage: 'bogus', prizes: [{ tpl: 'zzz_unknown' }], relics: ['zzz_unknown'], wrecks: [{ tpl: 'zzz_unknown', yield: { mod: 'zzz_unknown' } }] }; } return JSON.stringify(o); },
  // Whole-envelope garbage.
  (s, R) => ['', 'null', '[]', '{}', '"x"', '123', '{"meta":null,"run":null}'][Math.floor(R() * 7)],
];

function checkLoaded(round) {
  const meta = G.META, run = G.SAVED_RUN;
  if (!G.saneMeta(meta)) fail(round, 'loaded META fails saneMeta');
  if (run != null) {
    if (!G.saneRun(run)) fail(round, 'loaded run fails saneRun');
    for (const s of run.fleet || []) if (!HULLS[s.tpl]) fail(round, 'fleet keeps unknown hull ' + s.tpl);
    for (const id of run.relics || []) if (!RELICS[id]) fail(round, 'run keeps unknown relic ' + id);
    for (const id of run.inventory || []) if (!MODULES[id]) fail(round, 'run keeps unknown module ' + id);
    for (const b of run.boons || []) if (!BOONS[b.id]) fail(round, 'run keeps unknown boon ' + b.id);
    for (const id of run.patrons || []) if (!PATRONS[id]) fail(round, 'run keeps unknown patron ' + id);
    for (const id of run.heat || []) if (!HEAT[id]) fail(round, 'run keeps unknown heat ' + id);
    for (const s of run.fleet || []) for (const p of (s.cap && s.cap.perks) || []) if (!PERKS[p]) fail(round, 'captain keeps unknown perk ' + p);
    if (!Number.isFinite(run.credits)) fail(round, 'credits not finite: ' + run.credits);
  }
}

for (let round = 0; round < ROUNDS; round++) {
  G.rndSeed(SEED + round);
  const R = G.rnd;
  const mut = MUTATORS[Math.floor(R() * (MUTATORS.length - 1))]; // seeded mutators only in the loop
  let text;
  try { text = mut(VALID, R); } catch (e) { continue; } // a mutator that cannot parse the baseline skips
  G.store.clear();
  G.store.set(G.STORE_KEY, text);
  try { G.Persist.loadLocal(); } catch (e) { fail(round, 'loadLocal threw: ' + e.message); continue; }
  checkLoaded(round);
}
// Enumerate every fixed garbage envelope once, without replacement.
for (let i = 0; i < 7; i++) {
  G.store.clear();
  G.store.set(G.STORE_KEY, ['', 'null', '[]', '{}', '"x"', '123', '{"meta":null,"run":null}'][i]);
  try { G.Persist.loadLocal(); } catch (e) { fail('garbage ' + i, 'loadLocal threw: ' + e.message); continue; }
  checkLoaded('garbage ' + i);
}
// Round-trip.
{
  baseline();
  try { G.Persist.loadLocal(); checkLoaded('roundtrip'); }
  catch (e) { fail('roundtrip', 'loadLocal threw: ' + e.message); }
}

console.log('save_fuzz: ' + ROUNDS + ' seeded rounds + garbage + round-trip, ' + failures.length + ' failures');
for (const f of failures.slice(0, 40)) console.log('FAIL ' + f);
if (failures.length > 40) console.log('... and ' + (failures.length - 40) + ' more');
process.exit(failures.length ? 1 : 0);
