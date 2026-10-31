// converter.js - REFERENCE importer for the Voidsworn Godot cutover.
//
// This is a reference implementation, not the shipping importer. It exists
// so the shipping importer (Opus's, on the Godot side) can be ported from
// tested behavior instead of from a spec, and so every conversion decision
// is exercised against the fixtures in ../importer_fixtures/.
//
// What it does: takes a browser save store (the localStorage contents under
// 'voidsworn.v1', its '.bak' backup and its '.repaired' audit copy, as raw
// strings) and produces two things:
//   1. a portable desktop save (shape documented in README.md), and
//   2. an import drop report naming EVERY ship, captain, refit, unlock,
//      setting or value that conversion dropped, repaired, stripped or
//      altered, each with a reason. Silent drops are the failure mode this
//      file exists to prevent: if the converter drops it, the report
//      names it.
//
// Method: the converter does not reimplement the browser's load policy.
// It loads the game's own data.js and core.js headlessly (Node vm, no
// dependencies) and runs the game's own Persist.loadLocal against the
// supplied store, exactly as the fixture generator did, so migration and
// repair behavior cannot drift from the browser's. On top of that loaded
// state it applies the converter's own policy layer (boot-grant handling,
// meta unknown-id policy, reward safe point), and it builds the report
// from an explicit diff of the selected source envelope against the final
// output, so changes the game's own repair pass makes silently (it makes
// several) are still named.
//
// Usage as a library:
//   const { convert } = require('./converter');
//   const { save, report } = convert(store, { grant: 'strip' });
// Usage as a CLI:
//   node converter.js <store-or-fixture.json> [--grant=keep]
//        [--meta-unknown=carry] [--game-dir=/path/to/voidsworn]
//        [--out-prefix=name]   (writes name.save.json, name.report.json;
//                               without it, prints {save, report} as JSON)
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

// ---------------------------------------------------------------- game load
// Loads data.js + core.js from a game checkout into a fresh vm context.
// A fresh context per conversion matters: Persist.loadLocal mutates the
// META and SAVED_RUN globals and the Persist.recovered flag.
function loadGameCore(gameDir) {
  let src = '';
  for (const f of ['data.js', 'core.js']) {
    const p = path.join(gameDir, f);
    if (!fs.existsSync(p)) throw new Error('missing game file: ' + p);
    src += '\n;// ===== ' + f + ' =====\n' + fs.readFileSync(p, 'utf8');
  }
  const store = new Map();
  const localStorage = {
    getItem: k => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => { store.set(k, String(v)); },
    removeItem: k => { store.delete(k); },
  };
  const warnings = [];
  const quietConsole = {
    log() {}, warn(...a) { warnings.push(a.map(String).join(' ')); }, error() {},
  };
  const sandbox = {
    console: quietConsole,
    setTimeout, clearTimeout, setInterval, clearInterval,
    window: {},
    localStorage,
    performance: { now: () => Date.now() },
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(src, sandbox, { filename: 'voidsworn-core.js' });
  const grab = expr => vm.runInContext(expr, sandbox);
  const G = {
    _sandbox: sandbox,
    store,
    warnings,
    STORE_KEY: grab('STORE_KEY'),
    SAVE_VERSION: grab('SAVE_VERSION'),
    Persist: grab('Persist'),
    saneSave: grab('saneSave'),
    saneMeta: grab('saneMeta'),
    saneRun: grab('saneRun'),
    defaultMeta: grab('defaultMeta'),
    migrateMeta: grab('migrateMeta'),
    migrateRun: grab('migrateRun'),
    tables: {
      LEGACY: grab('LEGACY'), ADMIRALS: grab('ADMIRALS'), HULLS: grab('HULLS'),
      HULL_VARIANTS: grab('HULL_VARIANTS'), MODULES: grab('MODULES'),
      RELICS: grab('RELICS'), BOONS: grab('BOONS'), PATRONS: grab('PATRONS'),
      ASPECTS: grab('ASPECTS'), PERKS: grab('PERKS'), HEAT: grab('HEAT'),
      FACTIONS: grab('FACTIONS'),
    },
    get META() { return grab('META'); },
    get SAVED_RUN() { return grab('SAVED_RUN'); },
  };
  return G;
}

function defaultGameDir() {
  if (process.env.VOIDSWORN_GAME_DIR) return process.env.VOIDSWORN_GAME_DIR;
  return path.join(process.env.HOME || '', 'workspace', 'voidsworn-fresh');
}

// ------------------------------------------------------------------ helpers
const deep = x => (x == null ? x : JSON.parse(JSON.stringify(x)));
const isObj = x => !!x && typeof x === 'object' && !Array.isArray(x);
function stable(x) {
  if (x == null || typeof x !== 'object') return JSON.stringify(x);
  if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
  return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
}
const deepEqual = (a, b) => stable(a) === stable(b);

// Ids carried by one half of an envelope, for report detail lists.
function collectIds(half, which) {
  const ids = [];
  if (!half || typeof half !== 'object') return ids;
  if (which === 'meta') {
    for (const c of ['unlocked', 'admirals', 'variants', 'mastery', 'favour', 'heatBest']) {
      if (isObj(half[c])) for (const k of Object.keys(half[c])) ids.push(k);
    }
    if (half.stats && Array.isArray(half.stats.wonFacs)) ids.push(...half.stats.wonFacs);
  } else {
    for (const c of ['relics', 'inventory', 'heat', 'patrons']) {
      if (Array.isArray(half[c])) ids.push(...half[c].map(String));
    }
    if (Array.isArray(half.boons)) for (const b of half.boons) if (b && b.id) ids.push(b.id);
    if (Array.isArray(half.fleet)) for (const s of half.fleet) {
      if (s.uid) ids.push(s.uid); if (s.tpl) ids.push(s.tpl);
      if (Array.isArray(s.mods)) ids.push(...s.mods.map(String));
      if (s.cap && Array.isArray(s.cap.perks)) ids.push(...s.cap.perks.map(String));
    }
    if (isObj(half.reward)) {
      if (Array.isArray(half.reward.relics)) ids.push(...half.reward.relics.map(String));
      if (Array.isArray(half.reward.prizes)) for (const p of half.reward.prizes) if (p.tpl) ids.push(p.tpl);
      if (Array.isArray(half.reward.wrecks)) for (const w of half.reward.wrecks) if (w.tpl) ids.push(w.tpl);
    }
  }
  return ids;
}

// --------------------------------------------------------- source selection
// Mirrors Persist.loadLocal's choice of what to load, so the report can
// say where the imported state came from. The state itself always comes
// from running loadLocal (see convert), except on the repaired-copy path,
// which loadLocal never takes; that path migrates manually and the report
// says so loudly.
function selectSource(G, store) {
  const key = G.STORE_KEY;
  const raw = store[key];
  const bakRaw = store[key + '.bak'];
  const repRaw = store[key + '.repaired'];
  const parse = s => {
    if (s == null) return { ok: false, why: 'absent' };
    try { return { ok: true, val: JSON.parse(s) }; }
    catch (e) { return { ok: false, why: 'unparseable' }; }
  };
  const info = {
    kind: 'none', envelope: null, recovered: false, salvaged: false,
    primaryPresent: raw != null, backupPresent: bakRaw != null,
    repairedPresent: repRaw != null, notes: [],
  };
  if (raw == null && bakRaw == null && repRaw == null) { info.kind = 'none'; return info; }
  const p = parse(raw);
  if (p.ok && G.saneSave(p.val)) { info.kind = 'primary'; info.envelope = p.val; return info; }
  const b = parse(bakRaw);
  if (b.ok && G.saneSave(b.val)) {
    info.kind = 'backup'; info.envelope = b.val; info.recovered = true;
    info.notes.push('primary copy was ' + (p.ok ? 'present but failed the sanity checks' : p.why) +
      '; fell back to the backup one save behind, the same fallback the browser makes');
    return info;
  }
  if (p.ok && isObj(p.val)) {
    info.kind = 'primary-salvaged'; info.envelope = p.val; info.salvaged = true;
    info.notes.push('no usable backup; the browser keeps whichever half of the primary passes its sanity check and drops the other');
    return info;
  }
  const r = parse(repRaw);
  if (r.ok && G.saneSave(r.val)) {
    info.kind = 'repaired-copy'; info.envelope = r.val; info.recovered = true;
    info.notes.push('primary and backup are both unusable; recovered from the write-once audit copy at ' +
      key + '.repaired. The browser itself never loads this copy; using it is a converter policy, flagged here and in the README');
    return info;
  }
  if (raw == null && bakRaw == null) { info.kind = 'none'; return info; }
  info.kind = 'none-total-loss';
  info.notes.push('every stored copy failed to parse or failed the sanity checks; nothing could be carried');
  return info;
}

// -------------------------------------------------------------------- diff
// Recursive diff of the selected source envelope against a later state.
// Produces one entry per dropped, added or altered leaf, container id or
// array element. Object-array elements are matched by stable content
// first, then paired by identity (uid, else name, else boon id) so field
// changes inside a surviving ship or prize are reported as alterations,
// not as a drop plus an add.
const ID_MAP_TABLE = {
  'meta.unlocked': 'LEGACY', 'meta.admirals': 'ADMIRALS', 'meta.mastery': 'ADMIRALS',
  'meta.favour': 'PATRONS', 'meta.heatBest': 'FACTIONS',
};
function identityOf(el) {
  if (!el || typeof el !== 'object') return null;
  if (el.uid != null) return 'uid:' + el.uid;
  if (el.name != null) return 'name:' + el.name;
  if (el.id != null) return 'id:' + el.id;
  return null;
}
function elementLabel(el) {
  if (!el || typeof el !== 'object') return String(el);
  return el.uid || el.id || el.name || el.tpl || '(object)';
}
function diffInto(before, after, p, entries, G) {
  if (deepEqual(before, after)) return;
  if (isObj(before) && isObj(after)) {
    for (const k of Object.keys(before)) {
      if (!(k in after)) {
        const e = { action: 'dropped', path: p ? p + '.' + k : k, stage: 'load' };
        if (ID_MAP_TABLE[p]) e.id = k;
        entries.push(e);
      }
    }
    for (const k of Object.keys(after)) {
      if (!(k in before)) {
        const e = { action: 'added', path: p ? p + '.' + k : k, stage: 'load' };
        if (ID_MAP_TABLE[p]) e.id = k;
        entries.push(e);
      }
    }
    for (const k of Object.keys(before)) {
      if (k in after) diffInto(before[k], after[k], p ? p + '.' + k : k, entries, G);
    }
    return;
  }
  if (Array.isArray(before) && Array.isArray(after)) {
    const prim = before.every(x => x == null || typeof x !== 'object') && after.every(x => x == null || typeof x !== 'object');
    if (prim) {
      const count = arr => arr.reduce((m, x) => (m.set(stable(x), (m.get(stable(x)) || 0) + 1), m), new Map());
      const cb = count(before), ca = count(after);
      for (const [k, n] of cb) {
        const missing = n - (ca.get(k) || 0);
        for (let i = 0; i < missing; i++) entries.push({ action: 'dropped', path: p, id: JSON.parse(k), stage: 'load' });
      }
      for (const [k, n] of ca) {
        const extra = n - (cb.get(k) || 0);
        for (let i = 0; i < extra; i++) entries.push({ action: 'added', path: p, id: JSON.parse(k), stage: 'load' });
      }
      return;
    }
    // Object arrays: stable-match first.
    const bLeft = before.slice(), aLeft = after.slice();
    for (let i = bLeft.length - 1; i >= 0; i--) {
      const j = aLeft.findIndex(x => stable(x) === stable(bLeft[i]));
      if (j >= 0) { bLeft.splice(i, 1); aLeft.splice(j, 1); }
    }
    // Pair leftovers by identity and recurse.
    const paired = new Set();
    for (let i = bLeft.length - 1; i >= 0; i--) {
      const idn = identityOf(bLeft[i]);
      if (!idn) continue;
      const j = aLeft.findIndex(x => identityOf(x) === idn);
      if (j >= 0) {
        paired.add(bLeft[i]);
        diffInto(bLeft[i], aLeft[j], p + '[' + idn.split(':')[1] + ']', entries, G);
        bLeft.splice(i, 1); aLeft.splice(j, 1);
      }
    }
    for (const el of bLeft) {
      const e = { action: 'dropped', path: p, id: elementLabel(el), stage: 'load' };
      if (el && typeof el === 'object' && el.tpl) e.detail = { tpl: el.tpl };
      entries.push(e);
    }
    for (const el of aLeft) entries.push({ action: 'added', path: p, id: elementLabel(el), stage: 'load' });
    return;
  }
  entries.push({
    action: 'altered', path: p, stage: 'load',
    from: (before != null && typeof before === 'object') ? '(object)' : before,
    to: (after != null && typeof after === 'object') ? '(object)' : after,
  });
}

// Reason classification for load-stage diff entries. Where the exact
// cause is knowable from the path and the tables, the reason names it;
// otherwise the reason names the game pass that made the change.
function classifyLoad(e, G) {
  const T = G.tables;
  const p = e.path || '';
  const inTable = (table, id) => id != null && Object.prototype.hasOwnProperty.call(table, id);
  const unknownId = table => 'unknown id: not present in ' + table + ' in data.js; removed by repairRunIds (core.js) so the desktop build never receives an id its own tables lack';
  if (e.action === 'dropped' || e.action === 'added') {
    if (e.action === 'added' && (p === 'meta.backfilled' || p === 'meta.wonFix41')) {
      return 'version migration marker written by migrateMeta on first load';
    }
    if (e.action === 'added' && (p === 'run._repairs' || p === 'run._shipsDropped')) {
      return 'the load repair record written by repairRunIds itself; carried so the player can be shown what was repaired';
    }
    if (e.action === 'added' && p === 'run.v') return 'version migration: migrateRun stamps the run at save version 2 (a stored run carries no v field)';
    const containerTable = {
      'run.relics': 'RELICS', 'run.inventory': 'MODULES', 'run.heat': 'HEAT',
      'run.patrons': 'PATRONS', 'run.reward.relics': 'RELICS', 'run.reward.modOffer': 'MODULES',
      'run.boons': 'BOONS', 'run.reward.boonOffer': 'BOONS',
      'meta.stats.wonFacs': 'FACTIONS',
    }[p];
    if (e.action === 'dropped' && containerTable && !inTable(T[containerTable], e.id)) return unknownId(containerTable);
    if (e.action === 'dropped' && /\.mods$/.test(p) && !inTable(T.MODULES, e.id)) return unknownId('MODULES');
    if (e.action === 'dropped' && /\.perks$/.test(p) && !inTable(T.PERKS, e.id)) return unknownId('PERKS');
    if (e.action === 'dropped' && p === 'run.fleet') return 'ship dropped by repairRunIds: hull id ' + (e.detail && e.detail.tpl) + ' is not in HULLS';
    if (e.action === 'dropped' && p === 'run.reward.prizes') return 'prize dropped by repairRunIds: hull id ' + (e.detail && e.detail.tpl) + ' is not in HULLS';
    if (e.action === 'added' && p === 'meta.stats.wonFacs') return 'version migration: migrateMeta rebuilds stats.wonFacs from the run log on first load (the wonFix41 pass)';
    if (e.action === 'added' && /^meta\.(mastery|favour)\./.test(p)) return 'version migration: migrateMeta backfills mastery and favour from the run log on first load';
    if (e.action === 'added' && p.startsWith('meta.')) return 'filled from defaultMeta by migrateMeta during the version migration';
    if (e.action === 'added' && p.startsWith('run.')) return 'filled from runDefaults by normalizeRun during the version migration';
  }
  if (e.action === 'altered') {
    if (/\.hp$/.test(p)) return 'hp was ' + JSON.stringify(e.from) + ' (not a positive number); repairRunIds clamps it to 1 instead of dropping the ship';
    if (p === 'run.credits') return 'credits was ' + JSON.stringify(e.from) + ' (not a finite number); repairRunIds resets it to 0';
    if (p === 'run.admiral') return 'admiral id ' + JSON.stringify(e.from) + ' is not in ADMIRALS; repairRunIds resets it to the first admiral of the run faction';
    if (p === 'run.fac') return 'faction id ' + JSON.stringify(e.from) + ' is not in FACTIONS; repairRunIds resets it to voidsworn';
    if (p === 'run.aspect') return 'aspect id ' + JSON.stringify(e.from) + ' is not in ASPECTS; repairRunIds clears it to null';
    if (p === 'run.giftBoon') return 'gift boon id ' + JSON.stringify(e.from) + ' is not in BOONS; repairRunIds clears it to null (the game does not list this one in its own repair list; this report does)';
    if (p === 'run.reward.stage') return 'stored reward stage ' + JSON.stringify(e.from) + ' is not a valid stage; repairRunIds resets it to promo (the game does not list this one in its own repair list; this report does)';
    if (p === 'run.reward.boonOffer' || p === 'run.reward.modOffer') return 'the banked offer contained an id the tables no longer know; repairRunIds discards the whole offer rather than part of it';
    if (/\.yield\.mod$/.test(p)) return 'the wreck yield module id is not in MODULES; the module part of the yield is cleared, credits and tow kept';
    if (/\.yield\.tow$/.test(p)) return 'the wreck hull id is not in HULLS; the tow offer on its yield is withdrawn';
    if (p === 'meta.renown') return 'version migration: migrateMeta adjusts renown by the capped first-load backfill credit computed from the run log';
    if (p === 'run.v') return 'version migration: migrateRun stamps the run at save version 2';
    if (p === 'run.flagUid') return 'flagUid pointed at a ship that did not survive the load; cleared so the flagship link cannot dangle';
  }
  if (e.action === 'added' && (p === 'meta.backfilled' || p === 'meta.wonFix41')) {
    return 'version migration marker written by migrateMeta on first load';
  }
  if (e.action === 'added' && (p === 'run._repairs' || p === 'run._shipsDropped')) {
    return 'the load repair record written by repairRunIds itself; carried so the player can be shown what was repaired';
  }
  return 'changed by the browser migration and repair pass (migrateMeta, migrateRun, repairRunIds in core.js), which this converter reuses rather than reimplements';
}

// ------------------------------------------------------------ policy layer
// The unlockAll boot grant (main3d.js, the boot sequence): unless
// opts.unlockAll is false, every boot fills meta.unlocked with all LEGACY
// keys and meta.admirals with the whole roster, in memory; the next save
// serializes the filled maps. Detection signature: full coverage of both
// maps. Earned baseline: the store's .bak meta, which predates the
// granting save (the fixtures pin this as the ground truth).
function grantDetect(G, meta, store) {
  const T = G.tables;
  const legacyKeys = Object.keys(T.LEGACY);
  const admiralKeys = Object.keys(T.ADMIRALS);
  const has = (obj, k) => !!obj && Object.prototype.hasOwnProperty.call(obj, k);
  const signature = !!meta &&
    legacyKeys.every(k => has(meta.unlocked, k)) &&
    admiralKeys.every(k => has(meta.admirals, k));
  let baseline = null;
  const bakRaw = store[G.STORE_KEY + '.bak'];
  if (bakRaw != null) {
    try {
      const bak = JSON.parse(bakRaw);
      if (bak && isObj(bak.meta) && G.saneMeta(bak.meta)) baseline = bak.meta;
    } catch (e) { /* baseline stays null */ }
  }
  return { signature, baseline };
}

// Meta containers whose keys are ids in a data table. migrateMeta never
// validates these; the browser and the Godot port both keep unknown ids.
const META_ID_CONTAINERS = [
  ['unlocked', 'LEGACY'], ['admirals', 'ADMIRALS'], ['mastery', 'ADMIRALS'],
  ['favour', 'PATRONS'], ['heatBest', 'FACTIONS'],
];

// Reward stages in chain order, and what each stage needs in the bank to
// be presentable on resume. repairRunIds accepts exactly these stage
// values and resets anything else to promo.
const STAGE_ORDER = ['relic', 'prize', 'salvage', 'pick', 'promo'];
function stageHasPayload(stage, R) {
  switch (stage) {
    case 'relic': return Array.isArray(R.relics) && R.relics.length > 0;
    case 'prize': return Array.isArray(R.prizes) && R.prizes.length > 0;
    case 'salvage': return Array.isArray(R.wrecks) && R.wrecks.length > 0;
    case 'pick': return R.boonOffer != null || R.modOffer != null;
    case 'promo': return true; // terminal stage; promotions need no bank
    default: return false;
  }
}

// ----------------------------------------------------------------- convert
function convert(store, options) {
  const opts = Object.assign({ grant: 'strip', metaUnknown: 'drop', gameDir: defaultGameDir() }, options || {});
  if (!store || typeof store !== 'object') throw new Error('convert: store must be an object of raw localStorage strings');
  const G = loadGameCore(opts.gameDir);
  const key = G.STORE_KEY;
  const entries = [];

  const sel = selectSource(G, store);
  const header = {
    converter: 'importer_reference/converter.js (reference implementation, not the shipping importer)',
    source: {
      kind: sel.kind, recovered: sel.recovered,
      primaryPresent: sel.primaryPresent, backupPresent: sel.backupPresent,
      repairedPresent: sel.repairedPresent, notes: sel.notes,
    },
    grant: { signatureDetected: false, mode: opts.grant, strippedIds: [], baseline: 'none' },
    metaUnknownIds: { mode: opts.metaUnknown, droppedIds: [] },
    safePoint: { inputStage: null, emittedStage: null, skipped: [] },
  };
  for (const n of sel.notes) entries.push({ action: 'source-note', stage: 'load', path: key, reason: n });

  // ---- state: the game's own load, or manual migration on the one path
  // loadLocal never takes (the repaired-copy recovery).
  let meta, run;
  if (sel.kind === 'repaired-copy') {
    const env = sel.envelope;
    meta = env.meta != null ? G.migrateMeta(Object.assign(G.defaultMeta(), deep(env.meta))) : deep(G.defaultMeta());
    run = env.run && !env.run.none ? G.migrateRun(deep(env.run)) : null;
    meta = deep(meta); run = deep(run);
  } else {
    for (const k of Object.keys(store)) G.store.set(k, store[k]);
    G.Persist.loadLocal();
    meta = deep(G.META); run = deep(G.SAVED_RUN);
    if (G.store.has(key + '.repaired') && store[key + '.repaired'] == null) {
      entries.push({
        action: 'source-note', stage: 'load', path: key + '.repaired',
        reason: 'the load preserved the raw pre-repair save at ' + key + '.repaired (the browser write-once audit copy); the converter keeps that behavior visible',
      });
    }
    if (sel.kind === 'none-total-loss') {
      entries.push({
        action: 'total-loss', stage: 'load', path: key,
        reason: 'primary and backup copies are both unusable; the profile is a total loss, exactly the outcome the browser player would face. Reported here instead of being presented as a fresh start',
      });
    }
    if (sel.kind === 'none') {
      entries.push({
        action: 'source-note', stage: 'load', path: key,
        reason: 'no save was stored (first launch, or storage cleared); the output is a new-player profile',
      });
    }
  }

  // ---- diff: selected source envelope vs loaded state. Halves the
  // browser drops wholesale get one entry each (with their id inventory)
  // instead of a field-by-field diff of a half that no longer exists.
  if (sel.envelope) {
    const before = deep(sel.envelope);
    const skip = new Set();
    if (sel.salvaged) {
      if (before.meta != null && !G.saneMeta(before.meta)) {
        entries.push({
          action: 'dropped-half', stage: 'load', path: 'meta',
          detail: { ids: collectIds(before.meta, 'meta') },
          reason: 'the meta half fails saneMeta (a container has the wrong shape); the browser drops the whole half and boots the default meta. Every id it held is listed in detail.ids',
        });
        skip.add('meta');
      }
      if (!G.saneRun(before.run)) {
        entries.push({
          action: 'dropped-half', stage: 'load', path: 'run',
          detail: { ids: collectIds(before.run, 'run') },
          reason: 'the run half fails saneRun (no fleet array or no map); the browser drops the whole run and keeps the meta. Every id it held is listed in detail.ids',
        });
        skip.add('run');
      }
    }
    if (before.run && before.run.none) skip.add('run');
    const loadDiff = [];
    const beforeForDiff = deep(before);
    if (skip.has('meta')) delete beforeForDiff.meta;
    if (skip.has('run')) delete beforeForDiff.run;
    const afterForDiff = deep({ meta, run });
    if (skip.has('meta')) delete afterForDiff.meta;
    if (skip.has('run')) delete afterForDiff.run;
    diffInto(beforeForDiff, afterForDiff, '', loadDiff, G);
    for (const e of loadDiff) { e.reason = classifyLoad(e, G); entries.push(e); }
    if (before.run && before.run.none) {
      entries.push({
        action: 'source-note', stage: 'load', path: 'run',
        reason: 'the stored run was the {none: true} placeholder the cloud writer uses for "no run"; nothing was carried',
      });
    }
  }

  // ---- policy: meta unknown ids.
  if (meta) {
    const variantTables = [G.tables.HULL_VARIANTS, G.tables.HULLS];
    const check = (container, tableName) => {
      const obj = meta[container];
      if (!isObj(obj)) return;
      for (const k of Object.keys(obj)) {
        const known = tableName === 'VARIANTS'
          ? variantTables.some(t => Object.prototype.hasOwnProperty.call(t, k))
          : Object.prototype.hasOwnProperty.call(G.tables[tableName], k);
        if (known) continue;
        if (opts.metaUnknown === 'drop') {
          delete obj[k];
          header.metaUnknownIds.droppedIds.push(k);
          entries.push({
            action: 'dropped', stage: 'policy', path: 'meta.' + container, id: k,
            reason: 'unknown id in a meta container: not present in ' + (tableName === 'VARIANTS' ? 'HULL_VARIANTS or HULLS' : tableName) +
              '. The browser keeps these (migrateMeta never validates meta ids); the reference converter drops them so a reused id in a future build cannot resurrect stale progression. Switch with metaUnknown: carry',
          });
        } else {
          entries.push({
            action: 'source-note', stage: 'policy', path: 'meta.' + container, id: k,
            reason: 'unknown id in a meta container, carried under metaUnknown: carry. It is inert while no table uses the id, and would resurrect if a future build reused it',
          });
        }
      }
    };
    for (const [container, table] of META_ID_CONTAINERS) check(container, table);
    check('variants', 'VARIANTS');
  }

  // ---- policy: the boot grant.
  if (meta) {
    const det = grantDetect(G, meta, store);
    header.grant.signatureDetected = det.signature;
    header.grant.baseline = det.baseline ? 'backup meta in the same store' : 'none';
    if (det.signature) {
      if (opts.grant === 'keep') {
        entries.push({
          action: 'source-note', stage: 'policy', path: 'meta',
          reason: 'unlockAll boot grant signature detected (full LEGACY unlocks and full admiral roster) and KEPT under grant: keep. The profile arrives fully unlocked; whether that stands is the open strip-vs-ratify decision in the README',
        });
      } else {
        const earnedUnlocked = det.baseline ? (det.baseline.unlocked || {}) : {};
        const earnedAdmirals = det.baseline ? (det.baseline.admirals || {}) : { vex: true };
        const baselineFull = det.baseline &&
          Object.keys(G.tables.LEGACY).every(k => k in earnedUnlocked) &&
          Object.keys(G.tables.ADMIRALS).every(k => k in earnedAdmirals);
        if (baselineFull) {
          entries.push({
            action: 'source-note', stage: 'policy', path: 'meta',
            reason: 'full unlock coverage is already present in the backup copy, so it predates any granting save this store can show; treated as earned, nothing stripped',
          });
        } else {
          const stripFrom = (obj, earned, container) => {
            for (const k of Object.keys(obj || {})) {
              if (k in earned) continue;
              delete obj[k];
              header.grant.strippedIds.push(k);
              entries.push({
                action: 'stripped', stage: 'policy', path: 'meta.' + container, id: k,
                reason: 'unlockAll boot grant (main3d.js fills this map in memory on every boot; the next save serializes it). ' +
                  (det.baseline
                    ? 'The backup copy in this store predates the grant and does not contain this key, so it was granted, not earned'
                    : 'No backup baseline exists in this store; with the full-coverage signature present, the key is treated as granted and stripped back to the default profile'),
              });
            }
          };
          stripFrom(meta.unlocked, earnedUnlocked, 'unlocked');
          stripFrom(meta.admirals, earnedAdmirals, 'admirals');
        }
      }
    }
  }

  // ---- policy: reward safe point. The emitted save is the post-load
  // banked state; offers are carried verbatim and never re-rolled. If the
  // stage repair emptied (or the converter's own policy emptied) has no
  // surviving payload, the reward advances to the next stage that does,
  // and every skipped stage is named.
  if (run && isObj(run.reward)) {
    const R = run.reward;
    const inputEnv = sel.envelope && sel.envelope.run ? sel.envelope.run : null;
    header.safePoint.inputStage = inputEnv && isObj(inputEnv.reward) ? (inputEnv.reward.stage != null ? inputEnv.reward.stage : null) : R.stage;
    if (typeof header.safePoint.inputStage === 'string' && !STAGE_ORDER.includes(header.safePoint.inputStage)) {
      header.safePoint.skipped.push(header.safePoint.inputStage);
      entries.push({
        action: 'skipped-stage', stage: 'policy', path: 'run.reward.stage', stage_name: header.safePoint.inputStage,
        reason: 'the stored reward stage ' + JSON.stringify(header.safePoint.inputStage) + ' is not a valid stage, so it has no defined resume point; the repair pass reset it to promo and the banked stage the player was actually on is skipped at resume. Any contents that stage held and did not survive are named as drops in this report',
      });
    }
    let guard = 0;
    while (STAGE_ORDER.includes(R.stage) && R.stage !== 'promo' && !stageHasPayload(R.stage, R) && guard++ < STAGE_ORDER.length) {
      const from = R.stage;
      const to = STAGE_ORDER[STAGE_ORDER.indexOf(from) + 1];
      header.safePoint.skipped.push(from);
      entries.push({
        action: 'skipped-stage', stage: 'policy', path: 'run.reward.stage', stage_name: from,
        reason: 'the banked ' + from + ' stage has no surviving contents after conversion, so a resumed game could not present it; the save is emitted at the next stage with contents (' + to + ') and the skipped stage is named here rather than passed over silently',
      });
      R.stage = to;
    }
    header.safePoint.emittedStage = R.stage;
  } else if (run) {
    header.safePoint.emittedStage = null;
  }

  const counts = { dropped: 0, altered: 0, added: 0, stripped: 0, skippedStages: header.safePoint.skipped.length, halvesDropped: 0, notes: 0 };
  for (const e of entries) {
    if (e.action === 'dropped') counts.dropped++;
    else if (e.action === 'altered') counts.altered++;
    else if (e.action === 'added') counts.added++;
    else if (e.action === 'stripped') counts.stripped++;
    else if (e.action === 'dropped-half') counts.halvesDropped++;
    else if (e.action === 'source-note' || e.action === 'total-loss') counts.notes++;
  }

  const save = {
    format: 'voidsworn-desktop-save',
    formatVersion: 1,
    sourceSaveVersion: G.SAVE_VERSION,
    meta,
    run,
    provenance: {
      convertedBy: 'contrib/muse/tools/importer_reference/converter.js',
      referenceImplementation: true,
      source: sel.kind,
      recoveredFromBackup: sel.recovered,
      grantMode: opts.grant,
      metaUnknownMode: opts.metaUnknown,
    },
  };
  const report = { header, counts, entries };
  return { save, report };
}

// --------------------------------------------------------------------- CLI
function main(argv) {
  const args = argv.slice(2);
  const file = args.find(a => !a.startsWith('--'));
  if (!file) { console.error('usage: node converter.js <store-or-fixture.json> [--grant=keep] [--meta-unknown=carry] [--game-dir=PATH] [--out-prefix=name]'); return 2; }
  const opt = {};
  for (const a of args) {
    if (a.startsWith('--grant=')) opt.grant = a.split('=')[1];
    if (a.startsWith('--meta-unknown=')) opt.metaUnknown = a.split('=')[1];
    if (a.startsWith('--game-dir=')) opt.gameDir = a.split('=')[1];
  }
  const outPrefix = (args.find(a => a.startsWith('--out-prefix=')) || '').split('=')[1];
  const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
  const store = parsed.store || parsed;
  const { save, report } = convert(store, opt);
  if (outPrefix) {
    fs.writeFileSync(outPrefix + '.save.json', JSON.stringify(save, null, 2) + '\n');
    fs.writeFileSync(outPrefix + '.report.json', JSON.stringify(report, null, 2) + '\n');
    console.log('wrote ' + outPrefix + '.save.json and ' + outPrefix + '.report.json');
  } else {
    console.log(JSON.stringify({ save, report }, null, 2));
  }
  return 0;
}
if (require.main === module) process.exit(main(process.argv));

module.exports = { convert, loadGameCore, selectSource, diffInto, classifyLoad, STAGE_ORDER, defaultGameDir };
