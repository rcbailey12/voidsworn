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
  // Pinned to the variant the README names (it was the first non-arc key in
  // table order) so the fixture cannot drift if table order changes.
  const variantId = 'vs_harrow_t';
  if (!G.HULL_VARIANTS[variantId] || G.HULL_VARIANTS[variantId].arc) throw new Error('midrun: pinned variant changed');
  meta.variants[variantId] = true;
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

  // The Nemesis, assembled field by field in this generator because
  // newNemesis lives in campaign_run.js, outside the harness loader's
  // files (so it is replicated here from the data.js tables: nemesis
  // faction is RUN.foes[3], weaknesses filtered so none cancels a trait).
  // Traits, weaknesses and the name are pinned to the values the README
  // names; the draws below still run in the original order so the seeded
  // stream (and with it the title, persona and portrait picks) is
  // unchanged, then the pinned values replace the drawn ones.
  const nemFac = run.foes[3];
  const F = evalIn(G, 'NEM_FAC[' + JSON.stringify(nemFac) + ']');
  G.shuffle(F.traits.slice());
  const traits = ['deadeye', 'regrowth'];
  if (!traits.every(t => F.traits.includes(t))) throw new Error('midrun: pinned traits changed');
  const clash = { slow: 'swift', board: 'boarders', ion: 'shielded' };
  const weakPool = evalIn(G, 'Object.keys(NEM_WEAK)').filter(k =>
    !(k === 'anchor' && F.beh && (F.beh.noFlee || F.beh.revive)) && !traits.includes(clash[k]));
  G.shuffle(weakPool.slice());
  const weak = ['slow', 'flank'];
  if (!weak.every(w => weakPool.includes(w))) throw new Error('midrun: pinned weaknesses changed');
  if (Array.isArray(F.pre)) { G.pick(F.pre); if (Array.isArray(F.post)) G.pick(F.post); }
  if (!(F.pre.includes('Thrumming') && F.post.includes('Throat'))) throw new Error('midrun: pinned nemesis name changed');
  const nemName = 'Thrumming Throat';
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
  // The raw input itself passes saneSave (checked here with the game's own
  // function, and re-checked in the verification pass): the load therefore
  // takes the repair path, not the backup-fallback path.
  const inputPassesSaneSave = G.saneSave(envelope);
  if (!inputPassesSaneSave) throw new Error('repaired: raw input no longer passes saneSave');
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
    inputPassesSaneSave,
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
  const storeAfterLoad = storeSnapshot(boot.G); // the load itself rewrites nothing
  // Second-save assertion: save once more from the recovered state and
  // observe the backup slot. saveLocal rotates the previous primary into
  // '.bak' only when that value parses, so the truncated primary must not
  // displace the good backup; the new primary must hold the recovered
  // state. (Asserted here and re-derived in the verification pass.)
  boot.G.Persist.saveLocal();
  const bakAfterSecondSave = boot.G.store.get(boot.G.STORE_KEY + '.bak');
  let newPrimaryParses = true;
  try { JSON.parse(boot.G.store.get(boot.G.STORE_KEY)); } catch (e) { newPrimaryParses = false; }
  const secondSave = {
    performed: 'one saveLocal from the recovered state',
    bakUnchanged: bakAfterSecondSave === bak,
    newPrimaryParses,
    storeAfterSecondSave: storeSnapshot(boot.G),
  };
  if (!secondSave.bakUnchanged || !secondSave.newPrimaryParses) throw new Error('corrupt: second-save rotation behavior changed');
  writeJson('corrupt_output.json', {
    fixture: 'corrupt_output',
    loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered },
    recoveredFrom: 'voidsworn.v1.bak',
    secondSave,
    storeAfter: storeAfterLoad,
  });
}

// =============================================================== extension
// Fixtures 6 onward answer the two gap-check legs on the original set
// (DeepSeek filed; Qwen's list merged into the same pass).

// Build a fixture file from a raw store object instead of a live sandbox.
function finalizeStore(fixtureName, store, fileName, extra) {
  const key = Object.keys(store).find(k => !k.endsWith('.bak') && !k.endsWith('.repaired'));
  let envelope = null;
  if (key) { try { envelope = JSON.parse(store[key]); } catch (e) { /* unparseable primary */ } }
  const boot = bootLoad(store);
  if (boot.threw) throw new Error(fixtureName + ': loadLocal threw during finalize: ' + boot.threw);
  const obj = { fixture: fixtureName, store, envelope, loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered } };
  if (extra) Object.assign(obj, extra);
  writeJson(fileName, obj);
  return obj;
}

// Extract one top-level function from a campaign file the harness loader
// does not load, so the generator can run the game's own code for it.
function extractFn(file, sig) {
  const src = fs.readFileSync(file, 'utf8');
  const i = src.indexOf(sig);
  if (i < 0) throw new Error('extractFn: not found: ' + sig);
  let depth = 0, j = src.indexOf('){', i) + 1;
  for (; j < src.length; j++) {
    if (src[j] === '{') depth++;
    else if (src[j] === '}') { depth--; if (!depth) return src.slice(i, j + 1); }
  }
  throw new Error('extractFn: unbalanced: ' + sig);
}

// A brand-new Nemesis, replicated from campaign_run.js newNemesis the same
// way fixture 2 replicates it (that function sits outside the harness's
// loaded files). Values are drawn from the data.js tables, seeded.
function freshNemesis(G, run) {
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
  return {
    fac: nemFac, name: nemName, g: nemG, title: G.pick(F.titles), persona: G.pick(F.personas),
    traits, portrait: 'nem_' + nemFac + '_' + (1 + Math.floor(G.rnd() * 6)),
    weak, revealed: [], adapt: [], clock: 0, met: 0, beaten: 0, scars: 0, scarKinds: [],
    epithets: [], epithet: null, last_beat: null, fed: 0, riches: 0, loot: 0, held: null,
    gloat: null, honed: 0, revived: false, dead: false, strike: false, seen: {}, signatures: [],
  };
}

// A modest in-progress run to hang a banked reward on. The rewarding node
// is banked and done, pos and curNode sit on it, as rewardFlow leaves them.
function rewardBaseRun(G, fac, admiral, sector, hulls) {
  const run = G.runDefaults();
  run.fac = fac;
  run.admiral = admiral;
  run.sector = sector;
  run.cpCap = sector === 1 ? 10 : sector === 2 ? 13 : 16;
  run.foes = evalIn(G, 'shuffle(RUN_FACTIONS.filter(f=>f!==' + JSON.stringify(fac) + '))');
  run.t0 = T0 - 2 * 86400000;
  run.fleet = hulls.map(t => G.newShip(t));
  run.flagUid = run.fleet[0].uid;
  G.RUN = run; // genSector() reads the live run
  run.map = G.genSector(sector);
  run.map.cols[0][0].done = true;
  const posNode = run.map.cols[1].find(n => n.type === 'battle') || run.map.cols[1][0];
  posNode.done = true;
  run.pos = posNode.id;
  run.curNode = posNode.id;
  return { run, posNode };
}

// A captured-ship record, field for field as campaign3d.js builds it into
// the battle summary (wk is the deduped list of weapon kinds).
function prizeRecord(G, tpl, hpf) {
  const H = G.HULLS[tpl];
  return {
    tpl, name: G.newShip(tpl).name, hpf, fac: H.fac,
    wk: [...new Set((H.w || []).map(p => G.W[p[0]].k))],
    ab: H.ab || null, regen: !!H.regen, sh: H.sh || 0, cp: H.cp || 1,
  };
}

// A wreck record, field for field as campaign3d.js builds it, with the
// yield attached by the game's own salvageYield (extracted from
// campaign_run.js, which the harness loader does not load). G.RUN must be
// the fixture's run: the tow rule reads it.
function wreckRecord(G, tpl, cause, by) {
  const H = G.HULLS[tpl];
  const w = {
    name: G.newShip(tpl).name, tpl, cls: H.cls, fac: H.fac, cp: H.cp || 1,
    wk: [...new Set((H.w || []).map(p => G.W[p[0]].k))],
    ab: H.ab || null, regen: !!H.regen, sh: H.sh || 0, cause, by: by || null,
  };
  w.yield = evalIn(G, 'salvageYield(' + JSON.stringify(w) + ')');
  return w;
}
function loadSalvageYield(G) {
  evalIn(G, extractFn(path.join(REPO, 'campaign_run.js'), 'function salvageYield('));
}

// --------------------------------------------------------------- fixture 6
// partial_grant: fixture 3's boot grant on top of a profile that also has
// genuinely earned unlocks, variants, a win and an in-progress run, so
// grant detection can be tested against a mixed profile. The '.bak' slot
// holds the earned envelope from before the granting boot.
function buildPartialGrant() {
  const G = loadGame(REPO);
  G.rndSeed(606);
  const meta = G.defaultMeta();
  meta.renown = 210;
  meta.unlocked = { chest1: true, vets: true, u_carrier: true };
  meta.admirals = { vex: true, kassar: true, sable: true };
  meta.variants = { vs_harrow_t: true, c_reaver_t: true };
  meta.mastery = { kassar: 23, sable: 9 };
  meta.favour = { iron: 5, storm: 2 };
  meta.stats = { runs: 7, best: 3, wins: 1, wonFacs: ['hegemony'] };
  meta.fallen = [
    { name: 'Captain Ruth Calloway', rank: 1, fac: 'voidsworn', ship: 'Ledger of Ash', sector: 2 },
    { name: 'Captain Ines Vidal', rank: 0, fac: 'hegemony', ship: 'Patient Verdict', sector: 1 },
  ];
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.sector = 1;
  run.credits = 150;
  run.foes = ['hegemony', 'corsair', 'chorus', 'ithar'];
  run.stats = { battles: 2, elites: 0, bosses: 0, kills: 9, lost: 0 };
  run.t0 = T0 - 3600000;
  run.patrons = ['iron', 'storm'];
  run.fleet = [G.newShip('penitent'), G.newShip('harrow'), G.newShip('warden')];
  run.flagUid = run.fleet[0].uid;
  run.cpCap = Math.max(10, run.fleet.reduce((s, sh) => s + (G.HULLS[sh.tpl].cp || 1), 0) + 3);
  G.RUN = run;
  run.map = G.genSector(1);
  run.map.cols[0][0].done = true;
  const posNode = run.map.cols[1].find(n => n.type === 'battle') || run.map.cols[1][0];
  posNode.done = true;
  run.pos = posNode.id;
  run.curNode = posNode.id;
  run.nem = freshNemesis(G, run);

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal(); // the earned profile, as saved before the boot
  G.Persist.loadLocal(); // boot step 1: load (and migrate)
  for (const k of evalIn(G, 'Object.keys(LEGACY)')) G.META.unlocked[k] = true;
  for (const k of Object.keys(G.ADMIRALS)) G.META.admirals[k] = true;
  G.Persist.saveLocal(); // boot step 2: the first ordinary save bakes the grant in
  return finalize('partial_grant', G, 'partial_grant.json');
}

// --------------------------------------------------------------- fixture 7
// longlived_meta: a post-win profile with a deep history.
function buildLonglivedMeta() {
  const G = loadGame(REPO);
  G.rndSeed(707);
  const meta = G.defaultMeta();
  meta.renown = 460;
  meta.unlocked = { u_carrier: true, u_battleship: true, chest1: true, chest2: true, cmd1: true, vets: true, founder: true, wrights: true };
  meta.admirals = { vex: true, kassar: true, vorn: true, thale: true, grax: true, sable: true, aelith: true, matriarch: true, nekhet: true };
  for (const v of ['vs_harrow_t', 'c_reaver_t', 'h_vanguard_g', 'b_spitter_s', 'i_wisp_l']) {
    if (!G.HULL_VARIANTS[v]) throw new Error('longlived_meta: variant missing: ' + v);
    meta.variants[v] = true;
  }
  meta.mastery = { vex: 64, kassar: 41, vorn: 52, sable: 33, aelith: 27, matriarch: 19, grax: 12, nekhet: 8 };
  meta.favour = { iron: 12, storm: 7, hunger: 15, star: 4, ember: 9, rook: 2 };
  meta.stats = { runs: 16, best: 3, wins: 3, wonFacs: ['voidsworn', 'corsair', 'chorus'] };
  meta.heatBest = { voidsworn: 2, corsair: 1 };
  meta.fallen = [
    { name: 'Captain Ruth Calloway', rank: 1, fac: 'voidsworn', ship: 'Ledger of Ash', sector: 2 },
    { name: 'Captain Pavel Ostrov', rank: 2, fac: 'hegemony', ship: 'Patient Verdict', sector: 3 },
    { name: 'Captain Ivo Brandt', rank: 1, fac: 'corsair', ship: 'Last Wager', sector: 3 },
    { name: 'Captain Saye Lindqvist', rank: 0, fac: 'voidsworn', ship: 'Quiet Tithe', sector: 1 },
    { name: 'Captain Miren Okafor', rank: 1, fac: 'chorus', ship: 'Long Throat', sector: 2 },
    { name: 'Captain Hadleigh Vane', rank: 3, fac: 'hegemony', ship: 'Granite Psalm', sector: 3 },
  ];
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = null;
  G.Persist.saveLocal();
  return finalize('longlived_meta', G, 'longlived_meta.json');
}

// --------------------------------------------------------------- fixture 8
// early_run: a sector 1 run at its first moment. reward is null (the value
// the reward chain itself leaves behind) and nem is null (the runDefaults
// value; see the README for the construction note).
function buildEarlyRun() {
  const G = loadGame(REPO);
  G.rndSeed(808);
  const meta = G.defaultMeta();
  meta.stats = { runs: 1, best: 0, wins: 0 };
  meta.updated = T0;
  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.sector = 1;
  run.credits = 120;
  run.foes = evalIn(G, "shuffle(RUN_FACTIONS.filter(f=>f!=='voidsworn'))");
  run.t0 = T0;
  run.fleet = [];
  G.RUN = run; // newShip dedupes names against the live fleet
  for (const tpl of G.ADMIRALS.vex.start) run.fleet.push(G.newShip(tpl));
  run.flagUid = run.fleet[0].uid;
  run.cpCap = Math.max(10, run.fleet.reduce((s, sh) => s + (G.HULLS[sh.tpl].cp || 1), 0) + 3);
  run.map = G.genSector(1);
  run.pos = run.map.cols[0][0].id;
  run.reward = null;
  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('early_run', G, 'early_run.json');
}

// --------------------------------------------------------------- fixture 9
// reward_mod: a banked refit offer. There is no 'mod' stage value in the
// game: the offer lives at stage 'pick' with rw.k 'mod' and the three
// module ids banked in modOffer (repairRunIds resets any other stage
// string to 'promo', as fixture 4 shows).
function buildRewardMod() {
  const G = loadGame(REPO);
  G.rndSeed(909);
  const { run, posNode } = rewardBaseRun(G, 'hegemony', 'kassar', 2, ['h_vanguard', 'h_interdictor', 'h_picket']);
  run.credits = 190;
  run.stats = { battles: 7, elites: 1, bosses: 1, kills: 33, lost: 0 };
  const modOffer = evalIn(G, 'modulePool()').slice(0, 3);
  if (modOffer.length !== 3) throw new Error('reward_mod: modulePool offered fewer than 3 modules');
  run.reward = {
    kind: 'event', node: posNode.id, rw: { k: 'mod' },
    relics: [], wrecks: [], prizes: [], stage: 'pick', boonOffer: null, modOffer,
  };
  const meta = G.defaultMeta();
  meta.renown = 90;
  meta.admirals = { vex: true, kassar: true };
  meta.stats = { runs: 3, best: 2, wins: 0 };
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('reward_mod', G, 'reward_mod.json');
}

// -------------------------------------------------------------- fixture 10
// reward_prize: a banked prize choice, two captured ships with hull
// fractions, one of them already marked for stripping (prizeSel rides in
// the reward), plus one wreck waiting behind the prize stage.
function buildRewardPrize() {
  const G = loadGame(REPO);
  G.rndSeed(1010);
  loadSalvageYield(G);
  const { run, posNode } = rewardBaseRun(G, 'corsair', 'sable', 2, ['c_hulk', 'c_reaver', 'c_raider', 'c_raider']);
  run.credits = 275;
  run.stats = { battles: 8, elites: 2, bosses: 1, kills: 41, lost: 1 };
  run.patrons = ['ember'];
  const prizes = [prizeRecord(G, 'c_reaver', 0.72), prizeRecord(G, 'h_interdictor', 0.35)];
  const wrecks = [wreckRecord(G, 'c_raider', 'blast', run.fleet[0].name)];
  run.reward = {
    kind: 'battle', node: posNode.id, rw: { k: 'boon', p: 'ember' },
    relics: [], wrecks, prizes, stage: 'prize', boonOffer: null, modOffer: null,
    prizeSel: ['strip'],
  };
  const meta = G.defaultMeta();
  meta.renown = 110;
  meta.admirals = { vex: true, sable: true };
  meta.stats = { runs: 4, best: 2, wins: 0 };
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('reward_prize', G, 'reward_prize.json');
}

// -------------------------------------------------------------- fixture 11
// reward_salvage: a banked salvage choice, two wrecks: one intact (blast,
// carries a module yield) and one scrap (flay, credits only at the scrap
// rate, no module).
function buildRewardSalvage() {
  const G = loadGame(REPO);
  G.rndSeed(1111);
  loadSalvageYield(G);
  const { run, posNode } = rewardBaseRun(G, 'corsair', 'sable', 1, ['c_reaver', 'c_raider', 'c_raider']);
  run.credits = 160;
  run.stats = { battles: 3, elites: 0, bosses: 0, kills: 15, lost: 0 };
  run.patrons = ['hunger'];
  const wrecks = [
    wreckRecord(G, 'h_interdictor', 'blast', run.fleet[0].name),
    wreckRecord(G, 'c_raider', 'flay', run.fleet[1].name),
  ];
  run.reward = {
    kind: 'battle', node: posNode.id, rw: { k: 'boon', p: 'hunger' },
    relics: [], wrecks, prizes: [], stage: 'salvage', boonOffer: null, modOffer: null,
  };
  const meta = G.defaultMeta();
  meta.renown = 45;
  meta.admirals = { vex: true, sable: true };
  meta.stats = { runs: 2, best: 1, wins: 0 };
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('reward_salvage', G, 'reward_salvage.json');
}

// -------------------------------------------------------------- fixture 12
// reward_promo: the last stage of an elite reward chain. The relic was
// taken (it sits in run.relics), prizes and wrecks are settled, and the
// chain is parked at promotions with a captain holding a pending point.
function buildRewardPromo() {
  const G = loadGame(REPO);
  G.rndSeed(1212);
  const { run, posNode } = rewardBaseRun(G, 'hegemony', 'kassar', 2, ['h_vanguard', 'h_interdictor', 'h_picket']);
  run.credits = 230;
  run.stats = { battles: 8, elites: 2, bosses: 1, kills: 39, lost: 1 };
  run.patrons = ['storm'];
  run.relics = ['ledger'];
  run.fleet[0].cap.xp = 55;
  run.fleet[0].cap.rank = 1;
  run.fleet[0].cap.perks = ['gunnery'];
  run.fleet[0].cap.pending = 1;
  run.reward = {
    kind: 'elite', node: posNode.id, rw: { k: 'boon', p: 'storm' },
    relics: [], wrecks: [], prizes: [], stage: 'promo', boonOffer: null, modOffer: null,
  };
  const meta = G.defaultMeta();
  meta.renown = 95;
  meta.admirals = { vex: true, kassar: true };
  meta.stats = { runs: 3, best: 2, wins: 0 };
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('reward_promo', G, 'reward_promo.json');
}

// -------------------------------------------------------------- fixture 13
// meta_junk: unknown or retired ids inside META. Meta ids get no repair
// pass on either side, so every junk id survives the load untouched; only
// run ids are validated (fixture 4).
function buildMetaJunk() {
  const G = loadGame(REPO);
  G.rndSeed(1313);
  const meta = G.defaultMeta();
  meta.renown = 95;
  meta.unlocked = { chest1: true, zzz_legacy: true };
  meta.admirals = { vex: true, zzz_admiral: true };
  meta.variants = { vs_harrow_t: true, zzz_variant: true };
  meta.mastery = { vex: 11, zzz_admiral: 40 };
  meta.favour = { iron: 4, zzz_patron: 9 };
  meta.heatBest = { voidsworn: 1, zzz_heat: 2 };
  meta.stats = { runs: 3, best: 2, wins: 0 };
  meta.fallen = [{ name: 'Captain Ana Ruiz', rank: 0, fac: 'voidsworn', ship: 'Quiet Ledger', sector: 1 }];
  meta.updated = T0;
  G.META = meta;
  G.SAVED_RUN = null;
  G.Persist.saveLocal();
  return finalize('meta_junk', G, 'meta_junk.json');
}

// -------------------------------------------------------------- fixture 14
// nemesis_late: a Nemesis deep into a run: beaten twice, scarred twice,
// both weaknesses revealed, adaptations and signature moves on record.
// The run carrying him is a hegemony sector 3 run.
function buildNemesisLate() {
  const G = loadGame(REPO);
  G.rndSeed(1414);
  const meta = G.defaultMeta();
  meta.renown = 240;
  meta.unlocked = { chest1: true, cmd1: true };
  meta.admirals = { vex: true, kassar: true };
  meta.mastery = { kassar: 31 };
  meta.stats = { runs: 6, best: 3, wins: 1, wonFacs: ['voidsworn'] };
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'hegemony';
  run.admiral = 'kassar';
  run.sector = 3;
  run.cpCap = 16;
  run.credits = 210;
  run.foes = ['corsair', 'ithar', 'chorus', 'deathless'];
  run.stats = { battles: 12, elites: 3, bosses: 2, kills: 74, lost: 2 };
  run.t0 = T0 - 3 * 86400000;
  run.patrons = ['iron'];
  run.heat = ['h_flag', 'h_elite'];
  run.relics = ['martyr'];
  run.boons = [{ id: 'i_broad', r: 2 }];
  run.fallen = [{ name: 'Captain Pavel Ostrov', rank: 2, fac: 'hegemony', ship: 'Patient Verdict', sector: 3 }];
  const flagship = G.newShip('h_vanguard');
  flagship.mods = ['capacitor'];
  flagship.cap.xp = 70; flagship.cap.rank = 2; flagship.cap.perks = ['gunnery', 'ironhull'];
  run.fleet = [flagship, G.newShip('h_interdictor'), G.newShip('h_picket'), G.newShip('h_dominion')];
  run.flagUid = flagship.uid;
  G.RUN = run;
  run.map = G.genSector(3);
  run.map.cols[0][0].done = true;
  const posNode = run.map.cols[2].find(n => n.type === 'battle') || run.map.cols[2][0];
  posNode.done = true;
  run.pos = posNode.id;
  run.curNode = posNode.id;

  // The late Nemesis, assembled field by field like fixture 2 (newNemesis
  // sits outside the harness's loaded files), with the late-state fields
  // set to values the game's own Nemesis machinery produces: epithets from
  // the faction scarBy pools for the recorded scar causes, adaptations
  // within the sector cap, signature kinds from nemSignature.
  const F = evalIn(G, 'NEM_FAC.deathless');
  const traits = ['undying', 'armored'];
  if (!traits.every(t => F.traits.includes(t))) throw new Error('nemesis_late: pinned traits changed');
  const clash = { slow: 'swift', board: 'boarders', ion: 'shielded' };
  const weakPool = evalIn(G, 'Object.keys(NEM_WEAK)').filter(k =>
    !(k === 'anchor' && F.beh && (F.beh.noFlee || F.beh.revive)) && !traits.includes(clash[k]));
  const weak = ['flank', 'ion'];
  if (!weak.every(w => weakPool.includes(w))) throw new Error('nemesis_late: pinned weaknesses changed');
  const special = evalIn(G, 'NEM_ADAPT_FAC.deathless.special.id');
  if (!(F.scarBy.wound.includes('the Twice-Dead') && F.scarBy.burn.includes('Hollow-Eye'))) throw new Error('nemesis_late: scar pools changed');
  const nemName = G.pick(F.pre) + (Array.isArray(F.post) ? ' ' + G.pick(F.post) : '');
  const nemG = F.g || ((F.fem || []).some(p => nemName.startsWith(p)) ? 'f' : 'm');
  run.nem = {
    fac: 'deathless', name: nemName, g: nemG, title: G.pick(F.titles), persona: G.pick(F.personas),
    traits, portrait: 'nem_deathless_' + (1 + Math.floor(G.rnd() * 6)),
    weak, revealed: weak.slice(), adapt: ['pd', special], clock: 2, met: 3, beaten: 2,
    scars: 2, scarKinds: ['blast', 'flay'], epithets: ['the Twice-Dead', 'Hollow-Eye'],
    epithet: 'Hollow-Eye', last_beat: 'torp', fed: 0, riches: 0, loot: 0, held: null,
    gloat: null, honed: 0, revived: true, dead: false, strike: false, seen: {},
    signatures: ['tithe', 'revive', 'tithe'],
  };

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('nemesis_late', G, 'nemesis_late.json');
}

// -------------------------------------------------------------- fixture 15
// fleet_edges: the fleet array at its practical maximum and its corners.
// There is no ship-count cap in the code; command points are the only
// bound, so a sector 3 run (cpCap 16) filled with cp 1 hulls holds 16
// ships. One ship is stored at 0 hp, the flagship is not the first ship,
// and one captain holds pending promotion points.
function buildFleetEdges() {
  const G = loadGame(REPO);
  G.rndSeed(1515);
  const meta = G.defaultMeta();
  meta.renown = 175;
  meta.admirals = { vex: true };
  meta.mastery = { vex: 22 };
  meta.stats = { runs: 5, best: 3, wins: 0 };
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.sector = 3;
  run.cpCap = 16;
  run.credits = 95;
  run.foes = evalIn(G, "shuffle(RUN_FACTIONS.filter(f=>f!=='voidsworn'))");
  run.stats = { battles: 10, elites: 2, bosses: 2, kills: 61, lost: 4 };
  run.t0 = T0 - 3 * 86400000;
  run.patrons = ['iron'];
  // Mostly wardens (the home cp 1 hull) with captured cp 1 hulls from four
  // other factions mixed in, the way prizes join a fleet.
  const cycle = ['warden', 'c_raider', 'warden', 'b_drone', 'warden', 'i_wisp', 'warden', 'd_scythe',
    'warden', 'h_picket', 'warden', 'c_raider', 'warden', 'b_drone', 'warden', 'warden'];
  run.fleet = [];
  G.RUN = run; // newShip dedupes names against the live fleet
  for (const tpl of cycle) run.fleet.push(G.newShip(tpl));
  const fleetCp = run.fleet.reduce((s, sh) => s + (G.HULLS[sh.tpl].cp || 1), 0);
  if (fleetCp !== run.cpCap) throw new Error('fleet_edges: fleet cp ' + fleetCp + ' does not fill cpCap ' + run.cpCap);
  run.flagUid = run.fleet[3].uid; // the flagship is the fourth ship, not the first
  run.fleet[1].cap.xp = 30;
  run.fleet[1].cap.pending = 2; // promotion points earned and unspent
  run.fleet[7].hp = Math.round(G.derive(run.fleet[7]).maxHp * 0.4);
  run.fleet[5].hp = 0; // stored at 0; repairRunIds clamps a non-positive hp to 1 on load
  run.map = G.genSector(3);
  run.map.cols[0][0].done = true;
  run.pos = run.map.cols[0][0].id;
  run.curNode = run.map.cols[0][0].id;
  run.nem = freshNemesis(G, run);

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('fleet_edges', G, 'fleet_edges.json');
}

// -------------------------------------------------------------- fixture 16
// sector3_run: a chorus run in sector 3, mid-map, with a Nemesis who has
// been beaten and scarred once and has begun to adapt.
function buildSector3Run() {
  const G = loadGame(REPO);
  G.rndSeed(1616);
  const meta = G.defaultMeta();
  meta.renown = 305;
  meta.unlocked = { chest1: true, u_carrier: true };
  meta.admirals = { vex: true, matriarch: true };
  meta.mastery = { matriarch: 26 };
  meta.favour = { hunger: 8 };
  meta.stats = { runs: 8, best: 3, wins: 1, wonFacs: ['voidsworn'] };
  meta.fallen = [{ name: 'Captain Miren Okafor', rank: 1, fac: 'chorus', ship: 'Long Throat', sector: 2 }];
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'chorus';
  run.admiral = 'matriarch';
  run.sector = 3;
  run.cpCap = 16;
  run.credits = 260;
  run.foes = ['voidsworn', 'hegemony', 'corsair', 'deathless'];
  run.stats = { battles: 11, elites: 3, bosses: 2, kills: 70, lost: 3 };
  run.t0 = T0 - 3 * 86400000;
  run.patrons = ['hunger'];
  run.heat = ['h_flag'];
  run.relics = ['spore'];
  run.inventory = ['regen'];
  run.fleet = [G.newShip('b_brood'), G.newShip('b_spitter'), G.newShip('b_razor'), G.newShip('b_drone'), G.newShip('b_drone')];
  run.flagUid = run.fleet[0].uid;
  G.RUN = run;
  run.map = G.genSector(3);
  run.map.cols[0][0].done = true;
  const midNode = run.map.cols[1].find(n => n.type === 'battle') || run.map.cols[1][0];
  midNode.done = true;
  const posNode = run.map.cols[2].find(n => n.type === 'battle') || run.map.cols[2][0];
  posNode.done = true;
  run.pos = posNode.id;
  run.curNode = posNode.id;

  run.nem = freshNemesis(G, run);
  const nemFac = run.foes[3]; // the Nemesis's own faction drives his pools
  const special = evalIn(G, 'NEM_ADAPT_FAC[' + JSON.stringify(nemFac) + '].special.id');
  const scarEpithet = evalIn(G, 'NEM_FAC[' + JSON.stringify(nemFac) + '].scarBy.wound[0]');
  run.nem.beaten = 1;
  run.nem.scars = 1;
  run.nem.scarKinds = ['cut'];
  run.nem.epithets = [scarEpithet];
  run.nem.epithet = scarEpithet;
  run.nem.met = 2;
  run.nem.clock = 1;
  run.nem.revealed = [run.nem.weak[0]];
  run.nem.adapt = [special];
  run.nem.signatures = ['tithe'];

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal();
  return finalize('sector3_run', G, 'sector3_run.json');
}

// -------------------------------------------------------------- fixture 17
// settled_run: a run that has just ended in victory. The state the game
// actually stores at that boundary is the folded one, so this fixture is
// produced by calling the game's own endRun (campaign_meta.js, loaded
// here with DOM stubs, the tel and runRenown helpers extracted from
// campaign3d.js, and a pinned clock): meta already holds the folded
// results, the run is null, and the '.bak' slot holds the pre-end save.
// The pre-end run is included as preEndRun for context. A stored envelope
// holding an over run with results not yet folded is not constructible:
// endRun folds and nulls the run in the same call, and saveRun refuses to
// snapshot an over run.
function buildSettledRun() {
  const G = loadGame(REPO);
  G.rndSeed(1717);
  evalIn(G, `function __el(){ return { innerHTML:'', textContent:'', className:'', id:'', style:{}, dataset:{},
    classList:{ add:function(){}, remove:function(){}, toggle:function(){} },
    addEventListener:function(){}, removeEventListener:function(){}, remove:function(){},
    appendChild:function(){}, querySelector:function(){ return null; }, querySelectorAll:function(){ return []; },
    closest:function(){ return null; }, setAttribute:function(){}, focus:function(){} }; }
  var document = { getElementById: function(id){ return __el(); }, createElement: function(){ return __el(); },
    body: __el(), addEventListener: function(){} };
  Date.now = function(){ return ${T0}; };`);
  evalIn(G, extractFn(path.join(REPO, 'campaign3d.js'), 'function tel('));
  evalIn(G, extractFn(path.join(REPO, 'campaign3d.js'), 'function runRenown('));
  vm.runInContext(fs.readFileSync(path.join(REPO, 'campaign_meta.js'), 'utf8'), G._sandbox, { filename: 'campaign_meta.js' });
  if (evalIn(G, 'typeof endRun') !== 'function') throw new Error('settled_run: endRun did not load');

  const meta = G.defaultMeta();
  meta.renown = 200;
  meta.unlocked = { chest1: true };
  meta.admirals = { vex: true, sable: true };
  meta.stats = { runs: 5, best: 3, wins: 1, wonFacs: ['hegemony'] };
  meta.mastery = { sable: 20 };
  meta.updated = T0;

  const run = G.runDefaults();
  run.fac = 'corsair';
  run.admiral = 'sable';
  run.sector = 3;
  run.cpCap = 16;
  run.credits = 340;
  run.heat = ['h_flag'];
  run.foes = ['voidsworn', 'hegemony', 'ithar', 'chorus'];
  run.stats = { battles: 14, elites: 4, bosses: 3, kills: 88, lost: 2 };
  run.t0 = T0 - 4 * 86400000;
  run.fallen = [{ name: 'Captain Ivo Brandt', rank: 1, fac: 'corsair', ship: 'Last Wager', sector: 3 }];
  run.fleet = [G.newShip('c_hulk'), G.newShip('c_reaver'), G.newShip('c_raider')];
  run.flagUid = run.fleet[0].uid;
  G.RUN = run;
  run.map = G.genSector(3);
  run.nem = freshNemesis(G, run);
  run.nem.beaten = 2;
  run.nem.met = 2;

  G.META = meta;
  G.SAVED_RUN = deep(run);
  G.RUN = null;
  G.Persist.saveLocal(); // the last save before the run ended
  const preEndRun = deep(run);
  G.RUN = deep(run);
  evalIn(G, 'endRun(true)');
  if (evalIn(G, 'RUN') !== null) throw new Error('settled_run: endRun did not clear RUN');
  return finalizeStore('settled_run', storeSnapshot(G), 'settled_run.json', {
    preEndRun,
    settledBy: 'campaign_meta.js endRun(true), run inside this generator with DOM stubs and a pinned clock; renown, wins, wonFacs, fallen, mastery and heatBest in the primary envelope are its fold',
  });
}

// -------------------------------------------------------------- fixture 18
// corrupt2: both copies unusable. The primary and the '.bak' are both
// truncated; loadLocal finds nothing sane and the boot state is a fresh
// default meta with no run and recovered false.
function buildCorrupt2() {
  const G = loadGame(REPO);
  G.rndSeed(1818);
  const metaA = G.defaultMeta();
  metaA.renown = 55;
  metaA.stats = { runs: 1, best: 1, wins: 0 };
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

  const metaB = deep(metaA); metaB.renown = 90; metaB.updated = T0 + 3600000;
  const runB = deep(runA); runB.credits = 260; runB.stats.battles = 2;
  G.META = metaB;
  G.SAVED_RUN = runB;
  G.Persist.saveLocal();
  const primaryB = G.store.get(G.STORE_KEY);
  const bak = G.store.get(G.STORE_KEY + '.bak');
  if (bak !== primaryA) throw new Error('corrupt2: backup rotation did not hold state A');

  const store = {};
  store[G.STORE_KEY] = primaryB.slice(0, Math.floor(primaryB.length * 0.45));
  store[G.STORE_KEY + '.bak'] = bak.slice(0, Math.floor(bak.length * 0.3));
  writeJson('corrupt2_input.json', {
    fixture: 'corrupt2_input', store,
    primaryTruncatedAt: store[G.STORE_KEY].length, primaryFullLength: primaryB.length,
    bakTruncatedAt: store[G.STORE_KEY + '.bak'].length, bakFullLength: bak.length,
  });

  const boot = bootLoad(store);
  if (boot.threw) throw new Error('corrupt2: loadLocal threw: ' + boot.threw);
  if (boot.run !== null || boot.recovered) throw new Error('corrupt2: load recovered something from two unusable copies');
  writeJson('corrupt2_output.json', {
    fixture: 'corrupt2_output',
    loaded: { meta: boot.meta, run: boot.run, recovered: boot.recovered },
    recoveredFrom: null,
    storeAfter: storeSnapshot(boot.G),
  });
}

// -------------------------------------------------------------- fixture 19
// half_meta: the envelope parses but the run half is not a sane run, and
// there is no backup. loadLocal drops the run and keeps the meta.
function buildHalfMeta() {
  const G = loadGame(REPO);
  G.rndSeed(1919);
  const meta = G.defaultMeta();
  meta.renown = 175;
  meta.admirals = { vex: true, kassar: true };
  meta.mastery = { vex: 20 };
  meta.stats = { runs: 5, best: 2, wins: 1, wonFacs: ['hegemony'] };
  meta.updated = T0;
  const envelope = { meta, run: { fleet: 'broken', map: null } };
  if (G.saneSave(envelope)) throw new Error('half_meta: envelope unexpectedly sane');
  if (!G.saneMeta(meta)) throw new Error('half_meta: meta half is not sane');
  const store = {};
  store[G.STORE_KEY] = JSON.stringify(envelope);
  return finalizeStore('half_meta', store, 'half_meta.json');
}

// -------------------------------------------------------------- fixture 20
// half_run: the envelope parses but the meta half is not a sane meta (its
// unlocked container is an array), and there is no backup. loadLocal
// keeps the run and leaves the boot default meta in place.
function buildHalfRun() {
  const G = loadGame(REPO);
  G.rndSeed(2020);
  const run = G.runDefaults();
  run.fac = 'voidsworn';
  run.admiral = 'vex';
  run.sector = 1;
  run.credits = 140;
  run.fleet = [G.newShip('warden'), G.newShip('harrow')];
  run.flagUid = run.fleet[0].uid;
  G.RUN = run;
  run.map = G.genSector(1);
  G.RUN = null;
  const envelope = { meta: { unlocked: [] }, run: deep(run) };
  if (G.saneSave(envelope)) throw new Error('half_run: envelope unexpectedly sane');
  if (!G.saneRun(envelope.run)) throw new Error('half_run: run half is not sane');
  const store = {};
  store[G.STORE_KEY] = JSON.stringify(envelope);
  return finalizeStore('half_run', store, 'half_run.json');
}

// -------------------------------------------------------------- fixture 21
// absent_store: no voidsworn.v1 and no '.bak' at all. The store is empty;
// loadLocal is a no-op and the boot state is the untouched default meta
// (note: not migrated, so no first-load markers) with no run.
function buildAbsentStore() {
  return finalizeStore('absent_store', {}, 'absent_store.json', {
    note: 'Empty store: the key voidsworn.v1 and its .bak sibling are both absent, as on a first launch or after storage was cleared.',
  });
}

// ------------------------------------------------------------------- main
const built = {};
built.fresh = buildFresh();
built.midrun = buildMidrun();
built.unlocked = buildUnlocked();
buildRepaired();
buildCorrupt();
built.partial_grant = buildPartialGrant();
built.longlived_meta = buildLonglivedMeta();
built.early_run = buildEarlyRun();
built.reward_mod = buildRewardMod();
built.reward_prize = buildRewardPrize();
built.reward_salvage = buildRewardSalvage();
built.reward_promo = buildRewardPromo();
built.meta_junk = buildMetaJunk();
built.nemesis_late = buildNemesisLate();
built.fleet_edges = buildFleetEdges();
built.sector3_run = buildSector3Run();
built.settled_run = buildSettledRun();
buildCorrupt2();
built.half_meta = buildHalfMeta();
built.half_run = buildHalfRun();
built.absent_store = buildAbsentStore();

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
  for (const n of ['fresh.json', 'midrun.json', 'unlocked.json', 'partial_grant.json',
    'longlived_meta.json', 'early_run.json', 'reward_mod.json', 'reward_prize.json',
    'reward_salvage.json', 'reward_promo.json', 'meta_junk.json', 'nemesis_late.json',
    'fleet_edges.json', 'sector3_run.json', 'settled_run.json', 'half_meta.json',
    'half_run.json', 'absent_store.json']) {
    const f = read(n);
    check(n, f, f.loaded);
  }
  check('repaired pair', read('repaired_input.json'), read('repaired_output.json').loaded);
  check('corrupt pair', read('corrupt_input.json'), read('corrupt_output.json').loaded);
  check('corrupt2 pair', read('corrupt2_input.json'), read('corrupt2_output.json').loaded);

  // Fixture-specific assertions the gap-check legs asked for.
  const probe = loadGame(REPO);
  const KEY = probe.STORE_KEY;
  // repaired: the raw input passes saneSave (so the load took the repair
  // path), matching what the output file records.
  const repIn = read('repaired_input.json'), repOut = read('repaired_output.json');
  if (!probe.saneSave(repIn.envelope)) failures.push('repaired: raw input envelope fails saneSave');
  if (repOut.inputPassesSaneSave !== true) failures.push('repaired: output does not record inputPassesSaneSave');
  // corrupt: re-derive the second-save behavior from the input store.
  const corIn = read('corrupt_input.json'), corOut = read('corrupt_output.json');
  {
    const b = bootLoad(corIn.store);
    b.G.Persist.saveLocal();
    const bakAfter = b.G.store.get(KEY + '.bak');
    let parses = true;
    try { JSON.parse(b.G.store.get(KEY)); } catch (e) { parses = false; }
    if (bakAfter !== corIn.store[KEY + '.bak']) failures.push('corrupt: second save displaced the good backup');
    if (!parses) failures.push('corrupt: primary after the second save does not parse');
    if (!corOut.secondSave || corOut.secondSave.bakUnchanged !== true || corOut.secondSave.newPrimaryParses !== true) {
      failures.push('corrupt: output does not record the second-save observation');
    }
    console.log('verify corrupt second save: backup preserved, new primary parses');
  }
  // corrupt2: nothing recoverable from two unusable copies.
  const c2out = read('corrupt2_output.json');
  if (c2out.loaded.run !== null || c2out.loaded.recovered !== false) failures.push('corrupt2: loaded state is not the empty boot state');
  // partial_grant: the grant is fully applied and the earned content is
  // still beside it (variants, a win, an in-progress run).
  const pg = read('partial_grant.json');
  if (Object.keys(pg.loaded.meta.unlocked).length !== 12) failures.push('partial_grant: grant not fully applied');
  if (!Object.keys(pg.loaded.meta.variants).length) failures.push('partial_grant: earned variants missing');
  if (!pg.loaded.run) failures.push('partial_grant: in-progress run missing');
  const pgBak = JSON.parse(pg.store[KEY + '.bak']);
  if (Object.keys(pgBak.meta.unlocked).length !== 3) failures.push('partial_grant: backup does not hold the earned (pre-grant) unlocks');
  // early_run: both nulls survive the load.
  const er = read('early_run.json');
  if (!er.loaded.run || er.loaded.run.nem !== null || er.loaded.run.reward !== null) failures.push('early_run: nem and reward are not both null after load');
  // meta_junk: meta ids get no repair pass, so the junk survives.
  const mj = read('meta_junk.json');
  if (mj.loaded.meta.unlocked.zzz_legacy !== true || mj.loaded.meta.mastery.zzz_admiral !== 40) failures.push('meta_junk: junk meta ids did not survive the load');
  // nemesis_late: the late-state fields survive.
  const nl = read('nemesis_late.json');
  if (!nl.loaded.run || !nl.loaded.run.nem || nl.loaded.run.nem.beaten < 1 ||
    nl.loaded.run.nem.revealed.length !== 2 || nl.loaded.run.nem.adapt.length < 1 ||
    nl.loaded.run.nem.scars < 1 || !nl.loaded.run.nem.epithets.length) {
    failures.push('nemesis_late: late Nemesis state did not survive the load');
  }
  // fleet_edges: 16 ships, the stored 0 hp clamps to 1 on load, the
  // flagship reference and the pending points survive.
  const fe = read('fleet_edges.json');
  if (fe.envelope.run.fleet.length !== 16) failures.push('fleet_edges: stored fleet is not 16 ships');
  if (fe.envelope.run.fleet[5].hp !== 0) failures.push('fleet_edges: stored ship 5 is not at 0 hp');
  if (!fe.loaded.run || fe.loaded.run.fleet[5].hp !== 1) failures.push('fleet_edges: loaded ship 5 was not clamped to 1 hp');
  if (fe.loaded.run.flagUid !== fe.envelope.run.flagUid || fe.envelope.run.flagUid === fe.envelope.run.fleet[0].uid) {
    failures.push('fleet_edges: flagUid does not point at a non-first ship');
  }
  if (fe.envelope.run.fleet[1].cap.pending !== 2) failures.push('fleet_edges: pending captain points missing');
  // settled_run: the fold is in the meta and the run is gone.
  const sr = read('settled_run.json');
  if (sr.loaded.run !== null) failures.push('settled_run: loaded run is not null');
  if (sr.loaded.meta.stats.wins !== 2 || !sr.loaded.meta.stats.wonFacs.includes('corsair')) failures.push('settled_run: the win was not folded into meta');
  if (!(sr.loaded.meta.renown > 200)) failures.push('settled_run: renown was not folded into meta');
  // half fixtures: the sound half is kept, the unsound half dropped.
  const hm = read('half_meta.json'), hr = read('half_run.json');
  if (hm.loaded.run !== null || hm.loaded.meta.renown !== 175) failures.push('half_meta: sound meta not kept with run dropped');
  if (!hr.loaded.run) failures.push('half_run: sound run not kept');
  if (hr.loaded.meta.mastery && Object.keys(hr.loaded.meta.mastery).length) failures.push('half_run: meta was not reset to defaults');

  if (failures.length) { console.error('FAILURES:\n' + failures.join('\n')); process.exit(1); }
  console.log('All fixtures verified: every store loads through loadLocal without throwing.');
}
verify();
