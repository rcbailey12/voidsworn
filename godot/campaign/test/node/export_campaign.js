// G3 campaign: writes every data table the campaign uses, from the pinned oracle files, to godot/campaign/data/campaign_tables.json.
// Same encoding as G1's godot/rules/test/node/export_data.js: non-integer numbers as "#d:" + IEEE hex, a SHA-256 of the canonical form.
// Tables that hold code are evaluated here, once per rarity, so Godot gets plain data with nothing copied by hand:
//   BOON_FX[id][r] = BOONS[id].fx(RARITY[r].m), BOON_D[id][r] = BOONS[id].d(RARITY[r].m)
//   CMD_TEXT[cmd id][faction] = cmdDesc(cmd, 0, faction)   (the admiral screen's Command line)
//   node export_campaign.js [out.json]
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const env = require('./env.js');
env.load('globalThis.__E={cmdDesc,altCommand,RUN_FACTIONS};');
const out = {}, skipped = [], dropped = [];
const STATE = ['RNG_S', 'SPEED', 'UID', 'SAVED_RUN', 'RUN', 'B', 'ARENA', 'CUT', 'SOLID', 'TERRAIN_META', 'META', 'ACT', 'ERRS', 'PERF', 'AI_LEVEL', 'UNKNOWN_IDS'];
const names = [];
for (const f of env.FILES) { const s = fs.readFileSync(path.join(env.ORACLE, f), 'utf8'); const re = /^(?:const|let)\s+([A-Z_][A-Z0-9_]*)\s*=/gm; let m; while ((m = re.exec(s))) if (!names.includes(m[1])) names.push(m[1]); }
for (const extra of ['FNAMES', 'TIPS', 'ENC_SPECIAL', 'SEC_NAME', 'HEX_W', 'CX', 'BH', 'BOSS_DMG', 'WELL_PULL', 'WELL_ASSIST', 'WELL_DMG']) if (!names.includes(extra)) names.push(extra);
const get = n => { try { return vm_get(n); } catch (e) { return undefined; } };
function vm_get(n) { return require('vm').runInThisContext('typeof ' + n + "!=='undefined'?" + n + ':undefined'); }
const enc = (v, p) => {
  if (typeof v === 'function') { dropped.push(p); return undefined; }
  if (typeof v === 'number') { if (Number.isInteger(v)) return v; const b = Buffer.alloc(8); b.writeDoubleBE(v); return '#d:' + b.toString('hex'); }
  if (Array.isArray(v)) return v.map((x, i) => { const e = enc(x, p + '[' + i + ']'); return e === undefined ? null : e; });
  if (v && typeof v === 'object') { if (v instanceof Set || v instanceof Map) return undefined; const o = {}; for (const k of Object.keys(v)) { const e = enc(v[k], p + '.' + k); if (e !== undefined) o[k] = e; } return o; }
  return v;
};
for (const n of names) { const v = get(n); if (STATE.includes(n) || v === undefined || typeof v === 'function' || v instanceof Set || v instanceof Map) { skipped.push(n); continue; } out[n] = enc(v, n); }
const BOONS = get('BOONS'), RARITY = get('RARITY'), ADMIRALS = get('ADMIRALS');
out.BOON_FX = {}; out.BOON_D = {};
for (const id of Object.keys(BOONS)) { out.BOON_FX[id] = RARITY.map(R => enc(BOONS[id].fx(R.m), 'BOON_FX')); out.BOON_D[id] = RARITY.map(R => BOONS[id].d(R.m)); }
out.CMD_TEXT = {};
for (const id of Object.keys(ADMIRALS)) { const cs = [ADMIRALS[id].cmd, __E.altCommand(id)].filter(Boolean); for (const c of cs) { out.CMD_TEXT[c.id] = out.CMD_TEXT[c.id] || {}; for (const f of __E.RUN_FACTIONS) out.CMD_TEXT[c.id][f] = __E.cmdDesc(c, 0, f); } }
const canon = v => { if (v === null || v === undefined) return 'null'; if (typeof v === 'boolean') return String(v); if (typeof v === 'number') return Number.isInteger(v) ? String(v) : '"d:' + (b => (b.writeDoubleBE(v), b.toString('hex')))(Buffer.alloc(8)) + '"';
  if (typeof v === 'string') return v.startsWith('#d:') ? '"d:' + v.slice(3) + '"' : JSON.stringify(v); if (Array.isArray(v)) return '[' + v.map(canon).join(',') + ']';
  return '{' + Object.keys(v).filter(k => v[k] !== null && v[k] !== undefined).sort().map(k => JSON.stringify(k) + ':' + canon(v[k])).join(',') + '}'; };
// Fail loudly when a table the campaign reads is missing: the campaign's own REQUIRED_TABLES list plus every TB table its scripts read.
const G = path.resolve(__dirname, '..', '..', '..'), need = new Set();
const gdFiles = ['campaign', 'ui/campaign', 'scenes/campaign'].flatMap(d => { const dir = path.join(G, d); return fs.existsSync(dir) ? fs.readdirSync(dir).filter(f => f.endsWith('.gd')).map(f => path.join(dir, f)) : []; });
for (const f of gdFiles) { const s = fs.readFileSync(f, 'utf8'); let m; const re = /\bTB(?:\.|\[")([A-Z_][A-Z0-9_]*)/g; while ((m = re.exec(s))) need.add(m[1]);
  const rq = /const REQUIRED_TABLES = \[([^\]]*)\]/.exec(s); if (rq) for (const q of rq[1].matchAll(/"([A-Z_][A-Z0-9_]*)"/g)) need.add(q[1]); }
if (!need.size) { console.error('export_campaign: found no campaign scripts under ' + G + ' to check the tables against'); process.exit(2); }
const missing = [...need].filter(n => out[n] === undefined).sort();
if (missing.length) { console.error('export_campaign: FAIL, the oracle has no table for: ' + missing.join(', ') + ' (the campaign reads them; nothing written)'); process.exit(1); }
const sum = crypto.createHash('sha256').update(canon(out)).digest('hex');
const dest = process.argv[2] || path.resolve(__dirname, '..', '..', 'data', 'campaign_tables.json');
fs.writeFileSync(dest, JSON.stringify({ sha256: sum, oracle: 'godot/campaign/test/oracle', tables: out }));
const fnFields = [...new Set(dropped.map(p => p.replace(/\[\d+\]/g, '[]').replace(/^(\w+)\.\w+\./, '$1.*.')))];
console.log('exported', Object.keys(out).length, 'tables, sha256', sum.slice(0, 16));
console.log('  skipped (state or code):', skipped.join(' '));
console.log('  code fields left out (carried as evaluated tables or as GDScript):', fnFields.join(' '));
