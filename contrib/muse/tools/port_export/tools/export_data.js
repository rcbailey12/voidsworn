// Voidsworn port spec: data.js export tool.
// Loads the browser data.js in a vm context (read-only), serializes every
// top-level table to JSON in ../export/, and records function-valued fields
// (which JSON cannot represent) plus undefined drops as export notes.
// Usage: node export_data.js [cloneDir] [outDir]
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const cloneDir = process.argv[2] || path.join(process.env.HOME, 'workspace/voidsworn-fresh');
const outDir = process.argv[3] || path.join(__dirname, '..', 'export');
fs.mkdirSync(outDir, { recursive: true });

const src = fs.readFileSync(path.join(cloneDir, 'data.js'), 'utf8');

// Tables to export: every top-level const in data.js that is data (objects,
// arrays, scalars). Helper functions are listed separately and skipped.
const TABLES = [
  'W', 'ARC_NAME', 'KIND_NAME', 'FAC_WNAMES', 'WTRAITS', 'CLS_NAME', 'HULLS',
  'MOVE_RULES', 'FACTIONS', 'SECTOR_POOL', 'ABILITIES', 'ORDERS', 'MODULES',
  'PERKS', 'RANKS', 'RANK_XP', 'RELICS', 'ADMIRALS', 'LEGACY', 'SHIP_NAMES',
  'CAP_FIRST', 'CAP_LAST', 'MOD_NEED', 'MOD_NAMES', 'RELIC_NAMES', 'RUN_WORD',
  'EVENTS', 'EVENT_FALLBACK', 'NEM_CLOCK', 'NEM_WEAK', 'NEM_ADAPT', 'NEM_TRAITS',
  'NEM_PERSONA', 'NEM_FAC', 'NEM_ADAPT_FAC', 'NEM_LINES', 'NEM_BEAT_WORD',
  'FAC_VERBS', 'WING_STANCES', 'WING_PERKS', 'WING_XP', 'CAPTAINS',
  'MORE_SHIP_NAMES', 'FAC_PRICE', 'FAC_GATES', 'HULL_VARIANTS', 'ARC_VARIANT',
  'FIT_SLOTS', 'FAC_WPOOL', 'MASTERY_XP', 'MASTERY_PERKS', 'FAVOUR_TIERS',
  'ARCHETYPES', 'NODE_MODS', 'SECTOR_CONDS', 'HEAT', 'RARITY', 'PATRONS',
  'BOONS', 'BOON_NEED', 'ASPECTS', 'FAC_WTRAIT',
];

const extract = `
;(function(){
  const out = {};
  const names = ${JSON.stringify(TABLES)};
  for (const n of names) {
    try { out[n] = eval(n); } catch (e) { out[n] = undefined; }
  }
  return out;
})()`;

const sandbox = { console, process: { env: {} } };
vm.createContext(sandbox);
const data = vm.runInContext(src + extract, sandbox, { filename: 'data.js' });

const fnPaths = [];
function walkFns(v, p) {
  if (typeof v === 'function') { fnPaths.push(p); return; }
  if (Array.isArray(v)) { v.forEach((x, i) => walkFns(x, p + '[' + i + ']')); return; }
  if (v && typeof v === 'object') for (const k of Object.keys(v)) walkFns(v[k], p + '.' + k);
}
function replacerFactory() {
  return function (key, value) {
    if (typeof value === 'function') return '__FUNCTION__';
    if (value === undefined) return '__UNDEFINED__';
    return value;
  };
}

const manifest = { source: 'data.js @ pin 264f441d43a54e3679950dcc4457133b40811807', tables: {} };
for (const name of TABLES) {
  const v = data[name];
  if (v === undefined) { manifest.tables[name] = { missing: true }; continue; }
  const file = name.toLowerCase() + '.json';
  walkFns(v, name);
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(v, replacerFactory(), 1) + '\n');
  let count = null;
  if (Array.isArray(v)) count = v.length;
  else if (v && typeof v === 'object') count = Object.keys(v).length;
  manifest.tables[name] = { file, count, bytes: fs.statSync(path.join(outDir, file)).size };
}
// Evaluated boons: BOONS[id].d and .fx are functions of the rarity multiplier
// m = RARITY[r].m (core.js fleetFxList calls fx(RARITY[b.r||0].m)). Evaluate
// all four rarity tiers so the port gets concrete numbers, not just markers.
try {
  const RARITY = data.RARITY, BOONS = data.BOONS;
  const ev = {};
  for (const id of Object.keys(BOONS)) {
    const b = BOONS[id];
    ev[id] = { p: b.p || null, duo: b.duo || null, leg: !!b.leg, n: b.n || null, tiers: [] };
    for (let r = 0; r < RARITY.length; r++) {
      const m = RARITY[r].m;
      const row = { r, rarity: RARITY[r].n, m };
      try { row.fx = typeof b.fx === 'function' ? b.fx(m) : b.fx; } catch (e) { row.fx = '__ERROR__: ' + e.message; }
      try { row.d = typeof b.d === 'function' ? b.d(m) : b.d; } catch (e) { row.d = '__ERROR__: ' + e.message; }
      ev[id].tiers.push(row);
    }
  }
  fs.writeFileSync(path.join(outDir, 'boons_evaluated.json'), JSON.stringify(ev, null, 1) + '\n');
  manifest.tables.BOONS_EVALUATED = { file: 'boons_evaluated.json', count: Object.keys(ev).length, bytes: fs.statSync(path.join(outDir, 'boons_evaluated.json')).size };
} catch (e) { console.error('boons_evaluated failed:', e.message); }

// WTRAITS mutators: only 10, and they are code, not data. Export their source
// verbatim so the port can reimplement them exactly.
try {
  const WT = data.WTRAITS, srcs = {};
  for (const id of Object.keys(WT)) srcs[id] = { n: WT[id].n || null, d: WT[id].d || null, f_source: String(WT[id].f) };
  fs.writeFileSync(path.join(outDir, 'wtraits_source.json'), JSON.stringify(srcs, null, 1) + '\n');
  manifest.tables.WTRAITS_SOURCE = { file: 'wtraits_source.json', count: Object.keys(srcs).length, bytes: fs.statSync(path.join(outDir, 'wtraits_source.json')).size };
} catch (e) { console.error('wtraits_source failed:', e.message); }

manifest.functionValuedFields = fnPaths;
fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(manifest, null, 1) + '\n');
console.log('Exported', Object.keys(manifest.tables).length, 'tables to', outDir);
console.log('Function-valued fields:', fnPaths.length);
for (const f of fnPaths) console.log('  FN', f);
