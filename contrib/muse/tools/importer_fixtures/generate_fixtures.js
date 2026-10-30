// generate_fixtures.js - builds cutover importer test fixtures for the
// Voidsworn Godot migration (savings pass wave 5, phase 1).
//
// Every fixture is produced with the browser game's own constructors and
// persistence code (data.js + core.js + battle.js, loaded headlessly through
// the wave 1 harness loader), never hand-written JSON. A fixture file holds:
//   store:    the exact localStorage contents (raw strings) under STORE_KEY
//             ('voidsworn.v1') and its '.bak' sibling, as a browser would hold
//   envelope: the parsed primary envelope, when it parses
//   loaded:   what the game's own Persist.loadLocal() produces from that
//             store in a fresh runtime (the state an importer would receive
//             after the browser's own migrate/repair pass)
// Fixtures 4 and 5 are pairs: <name>_input.json is the store as found,
// <name>_output.json is the loaded state plus what the repair pass did.
//
// Run: node generate_fixtures.js
// The script finishes with a verification pass that re-reads every file it
// wrote and loads it through a fresh game instance's loadLocal.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { loadGame } = require(path.join(__dirname, '..', '..', 'voidsworn-harness', 'game_loader.js'));

const REPO = path.join(__dirname, '..', '..', 'voidsworn-fresh');
const OUT = __dirname;
const T0 = 1793200000000; // fixed stamp so fixtures stay reproducible

const deep = x => (x == null ? x : JSON.parse(JSON.stringify(x)));
const evalIn = (G, expr) => vm.runInContext(expr, G._sandbox);
const stable = x => {
  if (x == null || typeof x !== 'object') return JSON.stringify(x);
  if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
  return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
};
function writeJson(name, obj) {
  fs.writeFileSync(path.join(OUT, name), JSON.stringify(obj, null, 2) + '\n');
  console.log('wrote ' + name);
}
function storeSnapshot(G) {
  const o = {};
  for (const [k, v] of G.store) o[k] = v;
  return o;
}
// Simulate a cold boot: fresh runtime state, store as given, loadLocal.
function bootLoad(store) {
  const G = loadGame(REPO);
  G.store.clear();
  for (const k in store) G.store.set(k, store[k]);
  let threw = null;
  try { G.Persist.loadLocal(); } catch (e) { threw = e; }
  return { G, threw, meta: deep(G.META), run: deep(G.SAVED_RUN), recovered: !!G.Persist.recovered };
}
// Build a fixture file from a sandbox whose store holds the finished save.
function finalize(fixtureName, G, fileName) {
  const store = storeSnapshot(G);
  let envelope = null;
  try { envelope = JSON.parse(store[G.STORE_KEY]); } catch (e) { /* corrupt fixture */ }
  const boot = bootLoad(store);
  if (boot.threw) throw new Error(fixtureName + ': loadLocal threw during finalize: ' + boot.threw);
  const obj = { fixture: fixtureName, store, envelope, loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered } };
  writeJson(fileName, obj);
  return obj;
}

// --------------------------------------------------------------- fixture 1
// fresh: a brand-new meta and no run (what a first launch saves).
function buildFresh() {
  const G = loadGame(REPO);
  G.rndSeed(101);
  G.META = G.defaultMeta();
  G.SAVED_RUN = null;
  G.Persist.saveLocal();
  return finalize('fresh', G, 'fresh.json');
}

// --------------------------------------------------------------- fixture 2
// midrun: a hegemony run in sector 2, rewards banked mid-choice.
function buildMidrun() {
  const G = loadGame(REPO);
  G.rndSeed(202);

  const meta = G.defaultMeta();
  meta.renown = 130;
  meta.unlocked = { u_carrier: true, chest1: true, vets: true };
  meta.admirals = { vex: true, kassar: true };
  meta.stats = { runs: 4, best: 2, wins: 1 };
  meta.mastery = { kassar: 17, vex: 6 };
  meta.favour = { iron: 3 };
  const variantId = Object.keys(G.HULL_VARIANTS).find(k => !G.HULL_VARIANTS[k].arc);
  if (variantId) meta.variants[variantId] = true;
  meta.fallen = [{ name: 'Captain Ruth Calloway', rank: 1, fac: 'voidsworn', ship: 'Ledger of Ash', sector: 2 }];
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'hegemony';
  run.admiral = 'kassar';
  run.sector = 2;
  run.credits = 265;
  run.cpCap = 13; // 10 + 3 granted when sector 1 was cleared (campaign_run.js)
  run.foes = ['corsair', 'ithar', 'deathless', 'chorus'];
  run.stats = { battles: 9, elites: 2, bosses: 1, kills: 47, lost: 1 };
  run.t0 = T0 - 86400000;
  run.patrons = ['iron', 'storm'];
  run.aspect = 'bulwark';
  run.heat = ['h_flag'];
  run.inventory = ['regen', 'auspex'];
  run.relics = ['martyr', 'ledger'];
  run.boons = [{ id: 'i_broad', r: 1 }, { id: 'i_plate', r: 0 }];
  run.fallen = [{ name: 'Captain Tomas Rhee', rank: 0, fac: 'hegemony', ship: 'Patient Verdict', sector: 2 }];

  // Fleet built with the game's own constructor, then fitted and damaged.
  const flagship = G.newShip('h_vanguard');
  flagship.mods = ['capacitor', 'gyro'];
  flagship.cap.xp = 40; flagship.cap.rank = 1; flagship.cap.perks = ['gunnery', 'ironhull'];
  const interdictorA = G.newShip('h_interdictor');
  const interdictorB = G.newShip('h_interdictor');
  interdictorB.cap.perks = ['steady'];
  const picket = G.newShip('h_picket');
  picket.mods = ['prow'];
  const dominion = G.newShip('h_dominion');
  run.fleet = [flagship, interdictorA, interdictorB, picket, dominion];
  run.flagUid = flagship.uid;

  G.RUN = run; // derive() and genSector() read the live run
  run.map = G.genSector(2);
  flagship.hp = Math.round(G.derive(flagship).maxHp * 0.6);
  interdictorB.hp = 12;
  picket.hp = Math.round(G.derive(picket).maxHp * 0.85);

  // Progress on the map: the dock and the current node are done.
  const startNode = run.map.cols[0][0];
  startNode.done = true;
  const posNode = run.map.cols[1].find(n => n.type === 'battle') || run.map.cols[1][0];
  posNode.done = true;
  run.pos = posNode.id;
  run.curNode = posNode.id;

  // Banked reward chain after an elite win: the node paid out and completed,
  // the relic choice (1 of 2) and the patron boon offer (1 of 3) are fixed
  // into the save and still unmade.
  run.reward = {
    kind: 'elite', node: posNode.id, rw: { k: 'boon', p: 'iron' },
    relics: ['cogitator', 'spore'], wrecks: [], prizes: [], stage: 'relic',
    boonOffer: [{ id: 'i_still', r: 1 }, { id: 'i_brace', r: 0 }, { id: 'i_line', r: 2 }],
    modOffer: null,
  };

  // The Nemesis, replicated field for field from campaign_run.js newNemesis
  // (outside the harness's loaded files) with values drawn from the data.js
  // tables: nemesis faction is RUN.foes[3], weaknesses filtered so none
  // cancels a trait.
  const nemFac = run.foes[3];
  const F = evalIn(G, 'NEM_FAC[' + JSON.stringify(nemFac) + ']');
  const traits = G.shuffle(F.traits.slice()).slice(0, 2);
  const clash = { slow: 'swift', board: 'boarders', ion: 'shielded' };
  const weakPool = evalIn(G, 'Object.keys(NEM_WEAK)').filter(k =>
    !(k === 'anchor' && F.beh && (F.beh.noFlee || F.beh.revive)) && !traits.includes(clash[k]));
  const weak = G.shuffle(weakPool.slice()).slice(0, 2);
  const nemName = Array.isArray(F.pre)
    ? G.pick(F.pre) + (Array.isArray(F.post) ? ' ' + G.pick(F.post) : '')
    : String(F.pre);
  const nemG = F.g || ((F.fem || []).some(p => nemName.startsWith(p)) ? 'f' : 'm');
  run.nem = {
    fac: nemFac, name: nemName, g: nemG, title: G.pick(F.titles), persona: G.pick(F.personas),
    traits, portrait: 'nem_' + nemFac + '_' + (1 + Math.floor(G.rnd() * 6)),
    weak, revealed: [weak[0]], adapt: [], clock: 3, met: 1, beaten: 0, scars: 0, scarKinds: [],
    epithets: [], epithet: null, last_beat: null, fed: 0, riches: 0, loot: 0, held: null,
    gloat: null, honed: 0, revived: false, dead: false, strike: false, seen: {}, signatures: [],
  };

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('midrun', G, 'midrun.json');
}

// --------------------------------------------------------------- fixture 3
// unlocked: the boot grant (main3d.js) applies the full unlock to META in
// memory whenever opts.unlockAll is not false; the next ordinary save
// serializes it. This fixture replays that exact sequence, so its store
// also holds the pre-grant envelope as '.bak'.
function buildUnlocked() {
  const G = loadGame(REPO);
  G.rndSeed(303);
  const meta = G.defaultMeta();
  meta.renown = 60;
  meta.stats = { runs: 3, best: 1, wins: 0 };
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = null;
  G.Persist.saveLocal(); // the save as it stood before the boot in question

  G.Persist.loadLocal(); // boot step 1: load (and migrate)
  // boot step 2: the grant itself, main3d.js line 11, same loops, same tables
  for (const k of evalIn(G, 'Object.keys(LEGACY)')) G.META.unlocked[k] = true;
  for (const k of Object.keys(G.ADMIRALS)) G.META.admirals[k] = true;
  G.Persist.saveLocal(); // boot step 3: the first ordinary save bakes it in
  return finalize('unlocked', G, 'unlocked.json');
}

// --------------------------------------------------------------- fixture 4
// repaired: a structurally sound envelope full of unknown ids, written to
// the store raw. loadLocal's repairRunIds drops or resets each one and
// lists the repairs on the loaded run.
function buildRepaired() {
  const G = loadGame(REPO);
  G.rndSeed(404);
  const meta = G.defaultMeta();
  meta.renown = 85;
  meta.stats = { runs: 2, best: 1, wins: 0 };
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'zzz_admiral';
  run.sector = 1;
  run.credits = 'lots'; // type corruption: repairRunIds resets it to 0
  run.relics = ['martyr', 'zzz_relic'];
  run.boons = [{ id: 'i_broad', r: 0 }, { id: 'zzz_boon', r: 2 }];
  run.patrons = ['iron', 'zzz_patron'];
  run.inventory = ['prow', 'zzz_mod'];
  run.heat = ['h_flag', 'zzz_heat'];
  run.aspect = 'zzz_aspect';
  run.giftBoon = 'zzz_gift';

  const warden = G.newShip('warden');
  warden.mods = ['capacitor', 'zzz_mod2'];
  warden.cap.perks = ['gunnery', 'zzz_perk'];
  const harrow = G.newShip('harrow');
  run.fleet = [warden, harrow,
    { uid: 'junkship1', tpl: 'zzz_hull', name: 'Ghost', mk: 1, hp: 10, mods: [], cap: { fac: 'voidsworn', name: 'Captain Nobody', xp: 0, rank: 0, perks: [], pending: 0 } }];
  run.reward = {
    kind: 'battle', node: null, rw: { k: 'boon', p: 'iron' },
    relics: ['cogitator', 'zzz_relic2'], wrecks: [], prizes: [{ tpl: 'zzz_prize' }],
    stage: 'banana', boonOffer: null, modOffer: null,
  };
  G.RUN = run;
  run.map = G.genSector(1);
  G.RUN = null;

  // Written raw, the way a save from an older or renamed build would sit in
  // storage; saveLocal is deliberately not used so the junk survives.
  const envelope = { meta, run: deep(run) };
  G.store.clear();
  G.store.set(G.STORE_KEY, JSON.stringify(envelope));
  writeJson('repaired_input.json', { fixture: 'repaired_input', store: storeSnapshot(G), envelope });

  const boot = bootLoad(storeSnapshot(G));
  if (boot.threw) throw new Error('repaired: loadLocal threw: ' + boot.threw);
  const out = boot.run || {};
  const collect = (arr, get) => (arr || []).map(get).filter(x => x != null);
  const idDiff = (before, after, kind, get) => {
    const afterSet = new Set(collect(after, get));
    return collect(before, get).filter(id => !afterSet.has(id)).map(id => ({ kind, id }));
  };
  const droppedIds = [
    ...idDiff(envelope.run.relics, out.relics, 'relic', x => x),
    ...idDiff(envelope.run.boons, out.boons, 'boon', b => b.id),
    ...idDiff(envelope.run.patrons, out.patrons, 'patron', x => x),
    ...idDiff(envelope.run.inventory, out.inventory, 'refit (inventory)', x => x),
    ...idDiff(envelope.run.heat, out.heat, 'heat', x => x),
    ...idDiff(envelope.run.fleet, out.fleet, 'ship hull', s => s.tpl),
    ...idDiff(envelope.run.fleet[0].mods, (out.fleet[0] || {}).mods, 'refit (ship mods)', x => x),
    ...idDiff(envelope.run.fleet[0].cap.perks, ((out.fleet[0] || {}).cap || {}).perks, 'perk', x => x),
    ...idDiff(envelope.run.reward.relics, (out.reward || {}).relics, 'relic (reward offer)', x => x),
    ...idDiff(envelope.run.reward.prizes, ((out.reward || {}).prizes || []), 'prize hull (reward)', p => p.tpl),
  ];
  writeJson('repaired_output.json', {
    fixture: 'repaired_output',
    loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered },
    repairsListed: out._repairs || [],
    shipsDropped: out._shipsDropped || 0,
    droppedIds,
    silentlyChanged: [
      'run.admiral zzz_admiral was reset to ' + JSON.stringify(out.admiral) + ' (listed in repairs)',
      'run.aspect zzz_aspect was set to null (listed in repairs)',
      'run.giftBoon zzz_gift was set to null (NOT listed in repairs; unknownId logs it only)',
      'run.reward.stage banana was reset to ' + JSON.stringify((out.reward || {}).stage) + ' (not listed in repairs)',
      'run.credits (the string "lots") was reset to 0 (listed in repairs as "credits")',
    ],
    storeAfter: storeSnapshot(boot.G),
  });
}

// --------------------------------------------------------------- fixture 5
// corrupt: the primary envelope is truncated mid-string; the '.bak' copy
// one save behind is intact, and loadLocal recovers from it.
function buildCorrupt() {
  const G = loadGame(REPO);
  G.rndSeed(505);
  // State A: the older, good save that ends up as '.bak'.
  const metaA = G.defaultMeta();
  metaA.renown = 75;
  metaA.stats = { runs: 2, best: 1, wins: 0 };
  metaA.updated = T0;
  const runA = G.runDefaults();
  runA.fac = 'voidsworn';
  runA.admiral = 'vex';
  runA.sector = 1;
  runA.credits = 120;
  runA.fleet = [G.newShip('warden'), G.newShip('harrow')];
  G.RUN = runA;
  runA.map = G.genSector(1);
  G.RUN = null;
  G.META = metaA;
  G.SAVED_RUN = deep(runA);
  G.Persist.saveLocal();
  const primaryA = G.store.get(G.STORE_KEY);

  // State B: a later save. Writing it rotates A into '.bak'.
  const metaB = deep(metaA); metaB.renown = 140; metaB.updated = T0 + 3600000;
  const runB = deep(runA); runB.credits = 480; runB.stats.battles = 3;
  G.META = metaB;
  G.SAVED_RUN = runB;
  G.Persist.saveLocal();
  const primaryB = G.store.get(G.STORE_KEY);
  const bak = G.store.get(G.STORE_KEY + '.bak');
  if (bak !== primaryA) throw new Error('corrupt: backup rotation did not hold state A');

  const truncated = primaryB.slice(0, Math.floor(primaryB.length * 0.55));
  const store = {};
  store[G.STORE_KEY] = truncated;
  store[G.STORE_KEY + '.bak'] = bak;
  writeJson('corrupt_input.json', {
    fixture: 'corrupt_input', store,
    primaryTruncatedAt: truncated.length, primaryFullLength: primaryB.length,
    bakEnvelope: JSON.parse(bak),
  });

  const boot = bootLoad(store);
  if (boot.threw) throw new Error('corrupt: loadLocal threw: ' + boot.threw);
  writeJson('corrupt_output.json', {
    fixture: 'corrupt_output',
    loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered },
    recoveredFrom: 'voidsworn.v1.bak',
    storeAfter: storeSnapshot(boot.G),
  });
}

// ------------------------------------------------------------------- main
const built = {};
built.fresh = buildFresh();
built.midrun = buildMidrun();
built.unlocked = buildUnlocked();
buildRepaired();
buildCorrupt();

// ----------------------------------------------------------- verification
// Re-read every fixture file from disk and load it through a fresh game
// instance's own loadLocal. Pairs check input store against output state.
function verify() {
  const read = n => JSON.parse(fs.readFileSync(path.join(OUT, n), 'utf8'));
  const failures = [];
  const check = (label, fileObj, expectedLoaded) => {
    const boot = bootLoad(fileObj.store);
    if (boot.threw) { failures.push(label + ': loadLocal threw: ' + boot.threw); return; }
    const got = { meta: boot.meta, run: boot.run, recovered: boot.recovered };
    if (!boot.G.saneSave({ meta: boot.G.META, run: boot.G.SAVED_RUN })) failures.push(label + ': loaded state fails saneSave');
    if (expectedLoaded && stable(got) !== stable(expectedLoaded)) failures.push(label + ': loaded state differs from the recorded loaded state');
    console.log('verify ' + label + ': loadLocal ok, sane, recovered=' + boot.recovered);
  };
  for (const n of ['fresh.json', 'midrun.json', 'unlocked.json']) {
    const f = read(n);
    check(n, f, f.loaded);
  }
  check('repaired pair', read('repaired_input.json'), read('repaired_output.json').loaded);
  check('corrupt pair', read('corrupt_input.json'), read('corrupt_output.json').loaded);
  if (failures.length) { console.error('FAILURES:\n' + failures.join('\n')); process.exit(1); }
  console.log('All fixtures verified: every store loads through loadLocal without throwing.');
}
verify();
