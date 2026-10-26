// A3 rules parity: writes the game's data tables as JSON for the Godot port (no hand copying).
// Every top-level const/let table in data.js, core.js and battle.js that holds plain data is exported, as the game itself evaluates it.
// Functions inside tables (weapon traits, boon effects) are dropped; the port carries those as code.
// JSON float trap: Godot parses every JSON number as a double through its own parser, so a non-integer value is written as the string
// "#d:" + the 16 hex digits of its IEEE 754 double (big-endian) and the loader rebuilds the exact double. Integers stay plain numbers.
// The file also carries a SHA-256 of the canonical form of the tables, which the Godot loader recomputes before any battle runs.
//   node export_data.js <out.json>
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm'), crypto = require('crypto');
// the rules oracle: the pinned copy in ../oracle (VS_ORACLE overrides, for example the live repo root when catching up a rules change)
const ROOT = process.env.VS_ORACLE ? path.resolve(process.env.VS_ORACLE) : path.resolve(__dirname, '..', 'oracle');
global.window = {}; global.document = undefined; global.performance = { now: () => 0 };
// the browser also defines FNAMES (ui3d.js), which core.js shipName reads: pinned as oracle/fnames.js (or taken from ui3d.js beside a VS_ORACLE checkout)
const fnamesSrc = () => { const f = path.join(ROOT, 'fnames.js'); if (fs.existsSync(f)) return fs.readFileSync(f, 'utf8'); const u = path.join(ROOT, 'ui3d.js'); if (fs.existsSync(u)) { const m = fs.readFileSync(u, 'utf8').match(/^const FNAMES=[\s\S]*?\};/m); if (m) return m[0]; } return ''; };
const srcs = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).concat([fnamesSrc()]);
const names = [];
for (const s of srcs) { const re = /^(?:const|let)\s+([A-Z_][A-Z0-9_]*)\s*=/gm; let m; while ((m = re.exec(s))) if (!names.includes(m[1])) names.push(m[1]); }
// a few tables are declared later on the same line as another (const A=..., B=...)
for (const extra of ['ENC_SPECIAL', 'SEC_NAME', 'HEX_W', 'CX', 'BH', 'BOSS_DMG', 'WELL_PULL', 'WELL_ASSIST', 'WELL_DMG', 'SYNC_DMG', 'SYNC_AIM', 'FEED_NEAR', 'FEED_R', 'FEED_CAP', 'TORP_STRAY', 'WING_HUNT_LEASH', 'WING_SCREEN_TORP', 'TORP_WARHEAD']) if (!names.includes(extra)) names.push(extra);
vm.runInThisContext(srcs.join('\n') + '\nglobalThis.__T={' + names.map(n => JSON.stringify(n) + ':(typeof ' + n + "!=='undefined'?" + n + ':undefined)').join(',') + '};', { filename: 'export_bundle.js' });
// live game state, not tables (the port starts these itself)
const STATE = ['RNG_S', 'SPEED', 'UID', 'SAVED_RUN', 'RUN', 'B', 'ARENA', 'CUT', 'SOLID', 'TERRAIN_META'];
const out = {}, skipped = [];
const enc = v => {
  if (typeof v === 'function') return undefined;
  if (typeof v === 'number') { if (Number.isInteger(v)) return v; const b = Buffer.alloc(8); b.writeDoubleBE(v); return '#d:' + b.toString('hex'); }
  if (Array.isArray(v)) return v.map(x => { const e = enc(x); return e === undefined ? null : e; });
  if (v && typeof v === 'object') { if (v instanceof Set || v instanceof Map) return undefined; const o = {}; for (const k of Object.keys(v)) { const e = enc(v[k]); if (e !== undefined) o[k] = e; } return o; }
  return v;
};
for (const n of names) { const v = __T[n]; if (STATE.includes(n) || v === undefined || typeof v === 'function' || v instanceof Set || v instanceof Map) { skipped.push(n); continue; } out[n] = enc(v); }
// Fail hard (X20, Oct 26 verifier): every table the GDScript port reads (TB.NAME, TB["NAME"], TB.get("NAME") in godot/rules/*.gd) must be
// exported. A table renamed, removed or turned into a function in the JS would otherwise vanish from the file and only show up later
// as a null deep inside a battle. FNAMES is optional (the browser defines it in ui3d.js; the port falls back to {} like a missing FNAMES).
const OPTIONAL = ['FNAMES'];
const gdDir = path.resolve(__dirname, '..', '..');
const required = [];
for (const f of fs.readdirSync(gdDir).filter(f => f.endsWith('.gd'))) {
  const src = fs.readFileSync(path.join(gdDir, f), 'utf8'), re = /\bTB(?:\.([A-Z_][A-Z0-9_]*)\b|\[\s*"([A-Z_][A-Z0-9_]*)"\s*\]|\.get\(\s*"([A-Z_][A-Z0-9_]*)")/g; let m;
  while ((m = re.exec(src))) { const n = m[1] || m[2] || m[3]; if (!required.includes(n)) required.push(n); }
}
required.sort();
const missing = required.filter(n => !(n in out) && !OPTIONAL.includes(n));
const extraMissing = ['ENC_SPECIAL', 'SEC_NAME', 'HEX_W', 'CX', 'BH', 'BOSS_DMG', 'WELL_PULL', 'WELL_ASSIST', 'WELL_DMG', 'SYNC_DMG', 'SYNC_AIM', 'FEED_NEAR', 'FEED_R', 'FEED_CAP', 'TORP_STRAY', 'WING_HUNT_LEASH', 'WING_SCREEN_TORP', 'TORP_WARHEAD'].filter(n => !(n in out));
if (missing.length || extraMissing.length) {
  console.error('FAIL: tables the Godot port reads are missing from the JS oracle (' + ROOT + '): ' + missing.concat(extraMissing.filter(n => !missing.includes(n))).join(' '));
  console.error('Nothing written. Rename the table in godot/rules/*.gd too, or bring it back in the JS.');
  process.exit(1);
}
// canonical text of the tables, the same rules as the golden state (sorted keys, integers plain, other numbers as their hex double)
const canon = v => { if (v === null || v === undefined) return 'null'; if (typeof v === 'boolean') return String(v); if (typeof v === 'number') return Number.isInteger(v) ? String(v) : '"d:' + (b => (b.writeDoubleBE(v), b.toString('hex')))(Buffer.alloc(8)) + '"';
  if (typeof v === 'string') return v.startsWith('#d:') ? '"d:' + v.slice(3) + '"' : JSON.stringify(v); if (Array.isArray(v)) return '[' + v.map(canon).join(',') + ']';
  return '{' + Object.keys(v).filter(k => v[k] !== null && v[k] !== undefined).sort().map(k => JSON.stringify(k) + ':' + canon(v[k])).join(',') + '}'; };
const sum = crypto.createHash('sha256').update(canon(out)).digest('hex');
fs.writeFileSync(process.argv[2], JSON.stringify({ sha256: sum, required: required.filter(n => !OPTIONAL.includes(n)), tables: out }));
console.log('exported', Object.keys(out).length, 'tables (' + required.length + ' read by the port, all present), sha256', sum.slice(0, 16), '| skipped (code, not data):', skipped.join(' '));
