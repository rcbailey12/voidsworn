// run_tests.js - executes the reference converter against every fixture
// in ../importer_fixtures/ and checks, per fixture:
//   1. conversion does not throw;
//   2. the portable output passes the game's own saneSave;
//   3. the output matches the fixture's recorded loaded state, adjusted
//      only where a documented converter policy (grant strip, meta
//      unknown-id drop) is expected to change it; the opposite policy
//      mode must then match the loaded state exactly;
//   4. ACCOUNTING: an independent inventory of the source envelope's ids
//      and tracked scalar values is diffed against the output, and every
//      disappearance, addition or change must be covered by a drop
//      report entry. Any unreported disappearance fails the case.
//   5. fixture-specific report assertions (recovery source, skipped
//      reward stages, grant strip counts, half drops, the hp clamp).
//
// Run: node run_tests.js [--game-dir=/path/to/voidsworn]
'use strict';
const fs = require('fs');
const path = require('path');
const { convert, loadGameCore, selectSource, defaultGameDir } = require('./converter');

const FIX = path.join(__dirname, '..', 'importer_fixtures');
const gameDir = (process.argv.find(a => a.startsWith('--game-dir=')) || '').split('=')[1] || defaultGameDir();
const G = loadGameCore(gameDir);
const T = G.tables;

const deep = x => (x == null ? x : JSON.parse(JSON.stringify(x)));
const stable = x => {
  if (x == null || typeof x !== 'object') return JSON.stringify(x);
  if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
  return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
};
const eq = (a, b) => stable(a) === stable(b);
const rd = f => JSON.parse(fs.readFileSync(path.join(FIX, f), 'utf8'));

// ------------------------------------------------------- independent audit
// A second, deliberately simple implementation: inventories of ids per
// container plus a set of tracked scalars. It shares no code with the
// converter's recursive diff, so a converter diff bug cannot hide here.
function inventory(env) {
  const inv = new Map();
  const scalars = new Map();
  const add = (c, id) => { if (!inv.has(c)) inv.set(c, new Set()); inv.get(c).add(String(id)); };
  if (!env || typeof env !== 'object') return { inv, scalars };
  const m = env.meta, r = env.run;
  if (m && typeof m === 'object') {
    for (const c of ['unlocked', 'admirals', 'variants', 'mastery', 'favour', 'heatBest']) {
      if (m[c] && typeof m[c] === 'object') for (const k of Object.keys(m[c])) add('meta.' + c, k);
    }
    if (m.stats && Array.isArray(m.stats.wonFacs)) for (const f of m.stats.wonFacs) add('meta.stats.wonFacs', f);
    if (typeof m.renown === 'number') scalars.set('meta.renown', m.renown);
  }
  if (r && typeof r === 'object' && !r.none) {
    for (const c of ['relics', 'inventory', 'heat', 'patrons']) {
      if (Array.isArray(r[c])) for (const id of r[c]) add('run.' + c, id);
    }
    if (Array.isArray(r.boons)) for (const b of r.boons) if (b && b.id) add('run.boons', b.id);
    if (Array.isArray(r.fleet)) for (const s of r.fleet) {
      if (s.uid) { add('run.fleet', s.uid); scalars.set('hp|' + s.uid, s.hp); }
      if (s.tpl) add('run.fleet.tpl', s.tpl);
      if (s.uid && Array.isArray(s.mods)) for (const md of s.mods) add('run.fleet.mods', s.uid + '|' + md);
      if (s.uid && s.cap && Array.isArray(s.cap.perks)) for (const pk of s.cap.perks) add('run.fleet.perks', s.uid + '|' + pk);
    }
    if (Array.isArray(r.reserve)) for (const s of r.reserve) if (s.uid) add('run.reserve', s.uid);
    if (r.reward && typeof r.reward === 'object') {
      if (Array.isArray(r.reward.relics)) for (const id of r.reward.relics) add('run.reward.relics', id);
      if (Array.isArray(r.reward.prizes)) for (const p of r.reward.prizes) { add('run.reward.prizes', p.name || p.tpl); if (p.tpl) add('run.reward.prizes', p.tpl); }
      if (Array.isArray(r.reward.wrecks)) for (const w of r.reward.wrecks) { add('run.reward.wrecks', w.name || w.tpl); if (w.tpl) add('run.reward.wrecks', w.tpl); }
      if (Array.isArray(r.reward.boonOffer)) for (const o of r.reward.boonOffer) if (o && o.id) add('run.reward.boonOffer', o.id);
      if (Array.isArray(r.reward.modOffer)) for (const id of r.reward.modOffer) add('run.reward.modOffer', id);
      scalars.set('run.reward.stage', r.reward.stage);
    }
    for (const k of ['credits', 'admiral', 'fac', 'aspect', 'giftBoon', 'flagUid']) scalars.set('run.' + k, r[k]);
  }
  return { inv, scalars };
}
function entryCoversId(entries, id) {
  return entries.some(e =>
    e.id === id ||
    (e.detail && Array.isArray(e.detail.ids) && e.detail.ids.includes(id)) ||
    (e.detail && e.detail.tpl === id) ||
    (typeof e.path === 'string' && e.path.includes(id)));
}
function accounting(store, save, report) {
  const sel = selectSource(G, store);
  if (!sel.envelope) return []; // nothing parseable to account against
  const entries = report.entries;
  const halfDropped = h => entries.some(e => e.action === 'dropped-half' && e.path === h);
  const a = inventory(sel.envelope);
  const b = inventory({ meta: save.meta, run: save.run });
  const problems = [];
  for (const [c, set] of a.inv) {
    if (c.startsWith('run.') && halfDropped('run')) continue;
    if (c.startsWith('meta.') && halfDropped('meta')) continue;
    for (const id of set) {
      if (b.inv.get(c) && b.inv.get(c).has(id)) continue;
      // composite ids (uid|mod, uid|perk): the report names the bare id
      // at a path containing the uid.
      if (id.includes('|')) {
        const [uid, bare] = id.split('|');
        if (entries.some(e => e.id === bare && typeof e.path === 'string' && e.path.includes(uid))) continue;
      }
      if (!entryCoversId(entries, id)) problems.push('unreported disappearance: ' + c + ' lost ' + id);
    }
  }
  for (const [c, set] of b.inv) {
    if (c.startsWith('run.') && halfDropped('run')) continue;
    if (c.startsWith('meta.') && halfDropped('meta')) continue;
    for (const id of set) {
      if (a.inv.get(c) && a.inv.get(c).has(id)) continue;
      if (!entryCoversId(entries, id)) problems.push('unreported addition: ' + c + ' gained ' + id);
    }
  }
  for (const [k, v] of a.scalars) {
    if (k.startsWith('run.') && halfDropped('run')) continue;
    if (k.startsWith('meta.') && halfDropped('meta')) continue;
    const now = b.scalars.get(k);
    if (stable(now) === stable(v)) continue;
    let covered;
    if (k.startsWith('hp|')) {
      const uid = k.slice(3);
      // A ship dropped whole has no hp in the output; its disappearance is
      // accounted by the fleet drop entry, checked in the id inventory.
      if (!(b.inv.get('run.fleet') && b.inv.get('run.fleet').has(uid))) continue;
      covered = entries.some(e => typeof e.path === 'string' && e.path.includes(uid) && /\.hp$/.test(e.path));
    } else {
      covered = entries.some(e => e.path === k);
    }
    if (!covered) problems.push('unreported change: ' + k + ' ' + JSON.stringify(v) + ' -> ' + JSON.stringify(now));
  }
  return problems;
}

// ------------------------------------------------------------ expectations
function grantStripExpected(loaded, store) {
  const out = deep(loaded);
  const bak = JSON.parse(store['voidsworn.v1.bak']);
  for (const k of Object.keys(out.meta.unlocked)) if (!(k in bak.meta.unlocked)) delete out.meta.unlocked[k];
  for (const k of Object.keys(out.meta.admirals)) if (!(k in bak.meta.admirals)) delete out.meta.admirals[k];
  return out;
}
function metaDropExpected(loaded) {
  const out = deep(loaded);
  const keep = {
    unlocked: T.LEGACY, admirals: T.ADMIRALS, mastery: T.ADMIRALS, favour: T.PATRONS, heatBest: T.FACTIONS,
  };
  for (const c of Object.keys(keep)) {
    for (const k of Object.keys(out.meta[c] || {})) {
      if (!Object.prototype.hasOwnProperty.call(keep[c], k)) delete out.meta[c][k];
    }
  }
  for (const k of Object.keys(out.meta.variants || {})) {
    if (!Object.prototype.hasOwnProperty.call(T.HULL_VARIANTS, k) && !Object.prototype.hasOwnProperty.call(T.HULLS, k)) {
      delete out.meta.variants[k];
    }
  }
  return out;
}

// ------------------------------------------------------------------- cases
const SINGLES = ['fresh', 'midrun', 'unlocked', 'partial_grant', 'longlived_meta', 'early_run',
  'reward_mod', 'reward_prize', 'reward_salvage', 'reward_promo', 'meta_junk', 'nemesis_late',
  'fleet_edges', 'sector3_run', 'settled_run', 'half_meta', 'half_run', 'absent_store'];
const PAIRS = ['repaired', 'corrupt', 'corrupt2'];

const results = [];
function runCase(name, store, loaded, optsList, assertFn) {
  const problems = [];
  let first = null;
  for (const { opts, expected, label } of optsList) {
    let out;
    try { out = convert(store, Object.assign({ gameDir }, opts)); }
    catch (e) { problems.push(label + ': conversion threw: ' + e.message); continue; }
    if (!first && !opts) first = out;
    if (!first) first = out;
    if (!G.saneSave({ meta: out.save.meta, run: out.save.run })) problems.push(label + ': output fails saneSave');
    if (!eq({ meta: out.save.meta, run: out.save.run }, { meta: expected.meta, run: expected.run })) {
      problems.push(label + ': output differs from expected state');
    }
    const acc = accounting(store, out.save, out.report);
    for (const p of acc) problems.push(label + ': accounting: ' + p);
    if (assertFn) assertFn(out, label, problems);
  }
  results.push({ name, problems });
  return first;
}

for (const name of SINGLES) {
  const fix = rd(name + '.json');
  const optsList = [{ opts: null, expected: fix.loaded, label: 'default' }];
  if (name === 'unlocked' || name === 'partial_grant') {
    optsList[0].expected = grantStripExpected(fix.loaded, fix.store);
    optsList.push({ opts: { grant: 'keep' }, expected: fix.loaded, label: 'grant=keep' });
  }
  if (name === 'meta_junk') {
    optsList[0].expected = metaDropExpected(fix.loaded);
    optsList.push({ opts: { metaUnknown: 'carry' }, expected: fix.loaded, label: 'metaUnknown=carry' });
  }
  runCase(name, fix.store, fix.loaded, optsList, (out, label, problems) => {
    if (label !== 'default') return;
    const rep = out.report, save = out.save;
    if (name === 'absent_store' && rep.header.source.kind !== 'none') problems.push('absent_store: source kind is ' + rep.header.source.kind);
    if (name === 'fresh' && rep.header.source.kind !== 'primary') problems.push('fresh: source kind is ' + rep.header.source.kind);
    if (name === 'midrun' && (save.run.reward.stage !== 'relic' || rep.header.safePoint.skipped.length)) {
      problems.push('midrun: reward safe point moved (stage ' + save.run.reward.stage + ', skipped ' + JSON.stringify(rep.header.safePoint.skipped) + ')');
    }
    if (name === 'settled_run') {
      if (save.run !== null) problems.push('settled_run: run should be null');
      if (!rep.header.source.backupPresent || rep.header.source.kind !== 'primary') problems.push('settled_run: expected primary source with an unused backup present');
    }
    if (name === 'half_meta') {
      if (!rep.entries.some(e => e.action === 'dropped-half' && e.path === 'run')) problems.push('half_meta: no dropped-half entry for the run');
      if (save.run !== null || save.meta.renown !== 175) problems.push('half_meta: meta not carried or run not dropped');
    }
    if (name === 'half_run') {
      if (!rep.entries.some(e => e.action === 'dropped-half' && e.path === 'meta')) problems.push('half_run: no dropped-half entry for the meta');
      if ('backfilled' in save.meta) problems.push('half_run: output meta should be the unmigrated boot default');
      if (!save.run) problems.push('half_run: run was not carried');
    }
    if (name === 'fleet_edges') {
      if (save.run.fleet.length !== 16) problems.push('fleet_edges: fleet has ' + save.run.fleet.length + ' ships, expected 16');
      if (!rep.entries.some(e => typeof e.path === 'string' && e.path.includes('xmvuhwgj56') && /\.hp$/.test(e.path))) {
        problems.push('fleet_edges: no report entry for the 0 hp clamp');
      }
    }
    if (name === 'unlocked' && rep.header.grant.strippedIds.length !== 35) {
      problems.push('unlocked: stripped ' + rep.header.grant.strippedIds.length + ' grant keys, expected 35 (12 LEGACY + 23 admirals)');
    }
    if (name === 'partial_grant' && rep.header.grant.strippedIds.length !== 30) {
      problems.push('partial_grant: stripped ' + rep.header.grant.strippedIds.length + ' grant keys, expected 30 (9 LEGACY + 21 admirals)');
    }
    if (name === 'meta_junk') {
      for (const id of ['zzz_legacy', 'zzz_admiral', 'zzz_variant', 'zzz_patron', 'zzz_heat']) {
        if (!rep.entries.some(e => e.action === 'dropped' && e.id === id)) problems.push('meta_junk: junk id ' + id + ' not named in the report');
      }
    }
  });
}

for (const name of PAIRS) {
  const input = rd(name + '_input.json');
  const output = rd(name + '_output.json');
  runCase(name, input.store, output.loaded, [{ opts: null, expected: output.loaded, label: 'default' }], (out, label, problems) => {
    const rep = out.report, save = out.save;
    if (name === 'repaired') {
      const dropEntries = rep.entries.filter(e => e.action === 'dropped');
      for (const d of output.droppedIds) {
        const named = dropEntries.some(e => e.id === d.id || (e.detail && e.detail.tpl === d.id) ||
          (typeof e.reason === 'string' && e.reason.includes(d.id)));
        if (!named) problems.push('repaired: dropped id ' + d.id + ' (' + d.kind + ') not named in the report');
      }
      if (!rep.entries.some(e => e.action === 'skipped-stage' && e.stage_name === 'banana')) {
        problems.push('repaired: no skipped-stage entry naming the invalid banana stage');
      }
      if (save.run.reward.stage !== 'promo') problems.push('repaired: reward stage is ' + save.run.reward.stage + ', expected promo');
    }
    if (name === 'corrupt') {
      if (rep.header.source.kind !== 'backup' || !rep.header.source.recovered) problems.push('corrupt: expected backup recovery, got ' + rep.header.source.kind);
    }
    if (name === 'corrupt2') {
      if (rep.header.source.kind !== 'none-total-loss') problems.push('corrupt2: source kind is ' + rep.header.source.kind);
      if (!rep.entries.some(e => e.action === 'total-loss')) problems.push('corrupt2: no total-loss entry');
      if (save.run !== null) problems.push('corrupt2: run should be null');
    }
  });
}

// Synthetic check (not a fixture): the repaired-copy fallback. Primary and
// backup are garbage; only the write-once audit copy holds a valid
// envelope. The browser would boot a new profile; the converter recovers
// and says so.
{
  const problems = [];
  const fresh = rd('fresh.json');
  const store = {
    'voidsworn.v1': 'truncated{"meta":',
    'voidsworn.v1.bak': 'also broken',
    'voidsworn.v1.repaired': fresh.store['voidsworn.v1'],
  };
  try {
    const out = convert(store, { gameDir });
    if (out.report.header.source.kind !== 'repaired-copy') problems.push('synthetic repaired-fallback: source kind is ' + out.report.header.source.kind);
    if (!eq({ meta: out.save.meta, run: out.save.run }, { meta: fresh.loaded.meta, run: fresh.loaded.run })) {
      problems.push('synthetic repaired-fallback: recovered state differs from the audit copy loaded state');
    }
  } catch (e) { problems.push('synthetic repaired-fallback: threw: ' + e.message); }
  results.push({ name: 'synthetic:repaired-copy-fallback', problems });
}

// ------------------------------------------------------------------ report
let passed = 0;
for (const r of results) {
  if (r.problems.length === 0) { passed++; console.log('PASS ' + r.name); }
  else {
    console.log('FAIL ' + r.name);
    for (const p of r.problems) console.log('     - ' + p);
  }
}
const fixtureResults = results.filter(r => !r.name.startsWith('synthetic'));
const fixturePassed = fixtureResults.filter(r => r.problems.length === 0).length;
console.log('');
console.log('Fixtures: ' + fixturePassed + '/' + fixtureResults.length + ' cases passing (' +
  SINGLES.length + ' single-file cases, ' + PAIRS.length + ' input/output pair cases; ' +
  '24 fixture JSON files, 26 files in the fixtures directory including README and generator)');
console.log('All checks (fixtures + synthetic): ' + passed + '/' + results.length + ' passing');
process.exit(passed === results.length ? 0 : 1);
