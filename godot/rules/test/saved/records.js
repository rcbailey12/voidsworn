'use strict';
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const zlib = require('node:zlib');
const HOME = __dirname;
const SCENARIOS = path.resolve(HOME, '../scenarios.json');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const stable = value => JSON.stringify(value && typeof value === 'object' ?
  Array.isArray(value) ? value.map(v => JSON.parse(stable(v))) :
    Object.fromEntries(Object.keys(value).sort().map(k => [k, JSON.parse(stable(value[k]))])) : value);
const present = file => fs.existsSync(file) && fs.statSync(file).size > 0;
function read(file) {
  if (!present(file)) throw Error('missing or empty file: ' + path.basename(file));
  return fs.readFileSync(file);
}
function records(bytes) {
  const rows = bytes.toString('utf8').trim().split('\n').map(JSON.parse);
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    if (r.turn !== i || !Number.isInteger(r.round) || typeof r.actor !== 'string' ||
        !Number.isInteger(r.rng) || r.rng < 0 || r.rng > 0xffffffff ||
        typeof r.state !== 'string' || sha(r.state) !== r.hash) throw Error('invalid record at turn ' + i);
    const s = JSON.parse(r.state);
    if (!Array.isArray(s.units) || !s.b || !s.g) throw Error('invalid state at turn ' + i);
  }
  if (!rows.at(-1).actor.startsWith('end ')) throw Error('incomplete battle: no end record');
  return rows;
}
function manifest(dir = HOME) {
  const m = json(path.join(dir, 'results.json'));
  if (m.version !== 1 || m.compression !== 'brotli-5-window24' || !m.battles || !m.files)
    throw Error('unsupported saved results format');
  return m;
}
function unpack(dir, entry) {
  if (!entry || !/^[a-zA-Z0-9_.-]+\.br$/.test(entry.archive)) throw Error('invalid archive name');
  const bytes = zlib.brotliDecompressSync(read(path.join(dir, 'records', entry.archive)));
  if (sha(bytes) !== entry.sha256 || bytes.length !== entry.bytes) throw Error('saved archive hash/size differs');
  return bytes;
}
function pack(dir, name, bytes) {
  const archive = name + '.br', target = path.join(dir, 'records', archive);
  const entry = { sha256: sha(bytes), bytes: bytes.length, archive };
  // Keep byte-identical archives untouched, including their Git history.
  if (present(target)) {
    try { if (zlib.brotliDecompressSync(fs.readFileSync(target)).equals(bytes)) return entry; } catch { /* replace a damaged archive */ }
  }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, zlib.brotliCompressSync(bytes, { params: {
    [zlib.constants.BROTLI_PARAM_QUALITY]: 5, [zlib.constants.BROTLI_PARAM_LGWIN]: 24
  } }));
  return entry;
}
// Require the original batch evidence, not a diagnostic retry or an old loose file.
function evidence(root, names, scenarios) {
  const batch = json(path.join(root, 'batches.json'));
  if (!Array.isArray(batch.names) || stable([...batch.names].sort()) !== stable([...names].sort()))
    throw Error('run battle list differs from the requested list');
  const seen = new Set(), errors = {};
  for (const w of batch.workers) {
    const log = fs.readFileSync(w.log, 'utf8').replace(/\r\n/g, '\n');
    const part = json(w.file);
    const ok = w.godot?.code === 0 && !w.godot.timeout && !w.godot.error && !w.godot.signal &&
      log.split('\n').includes(`batch ${w.names.length} battles -> ${path.join(root, 'out')}`) &&
      !/SCRIPT ERROR|Parse Error|NOT PORTED:|^ERROR:(?! Failed to read the root certificate store\.\r?$)/m.test(log);
    if (stable(Object.keys(part).sort()) !== stable([...w.names].sort())) throw Error('worker partition differs from its manifest');
    for (const name of w.names) {
      if (!names.includes(name) || seen.has(name)) throw Error('unknown or duplicate battle in workers: ' + name);
      seen.add(name);
      if (stable(part[name]) !== stable(scenarios[name])) errors[name] = 'run used a different scenario; run again';
      else if (!ok || !log.split('\n').includes(`batch result ${name} exit 0`)) errors[name] = 'original Godot batch failed or did not finish';
    }
  }
  for (const name of names) if (!seen.has(name)) errors[name] = 'not assigned to a Godot worker';
  return errors;
}
const FILES = ['prng_1001.txt', 'prng_7.txt', 'prng_4242424242.txt', 'math.txt',
  'math_verdict.txt', 'threat_s4.json', 'threat_s19.json', 'threat_s23.json'];
function auxiliary(root, name) {
  if (name === 'math.txt') return read(path.join(root, 'golden', name));
  if (name === 'math_verdict.txt') {
    const lines = read(path.join(root, 'out/math.txt')).toString().replace(/\r/g, '').split('\n');
    const verdict = lines.filter(l => /^math \d+ values, differences from Node: /.test(l));
    const count = read(path.join(root, 'golden/math.txt')).toString().trim().split('\n').length;
    if (verdict.length !== 1 || verdict[0] !== `math ${count} values, differences from Node: none`)
      throw Error('Godot did not verify every math value');
    return Buffer.from(verdict[0] + '\n');
  }
  const bytes = read(path.join(root, 'out', name));
  if (name.startsWith('prng_') && bytes.toString().trim().split('\n').length !== 10000)
    throw Error('incomplete PRNG file');
  if (name.startsWith('threat_')) {
    const value = JSON.parse(bytes);
    if (stable(Object.keys(value)) !== stable(['1', '2', '3']) || Object.values(value).some(v => !Object.keys(v).length))
      throw Error('incomplete threat map');
  }
  return bytes;
}
function diff(a, b, field = 'state') {
  if (Object.is(a, b)) return null;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    const keys = Array.isArray(a) ? Array.from({ length: Math.max(a.length, b.length) }, (_, i) => i) :
      [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
    for (const k of keys) {
      const d = diff(a[k], b[k], field + (Array.isArray(a) ? `[${k}]` : '.' + k));
      if (d) return d;
    }
    return null;
  }
  return { field, before: a, after: b };
}
function value(v) {
  if (v === undefined) return '<missing>';
  if (typeof v === 'string' && /^d:[0-9a-f]{16}$/.test(v)) return `${Buffer.from(v.slice(2), 'hex').readDoubleBE()} [${v}]`;
  const s = JSON.stringify(v);
  return s.length > 180 ? s.slice(0, 177) + '...' : s;
}
function battleDiff(beforeBytes, afterBytes) {
  const a = records(beforeBytes), b = records(afterBytes);
  const changed = [];
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const x = a[i], y = b[i];
    if (!x || !y || ['hash', 'rng', 'turn', 'round', 'actor'].some(k => x[k] !== y[k])) changed.push(i);
  }
  if (!changed.length) return ['record bytes/format changed; battle values identical; later changed records: 0'];
  const i = changed[0], x = a[i], y = b[i], r = y || x;
  let d, unit = 'none (battle state)';
  if (!x || !y) d = { field: 'record', before: x ? 'present' : undefined, after: y ? 'present' : undefined };
  else {
    const xs = JSON.parse(x.state), ys = JSON.parse(y.state);
    // Units first: a hull value is more useful than its downstream battle-log message.
    d = diff(xs.units, ys.units, 'state.units') || diff(xs.b, ys.b, 'state.b') || diff(xs.g, ys.g, 'state.g');
    if (!d) d = diff(Object.fromEntries(Object.entries(x).filter(([k]) => !['hash', 'state'].includes(k))),
      Object.fromEntries(Object.entries(y).filter(([k]) => !['hash', 'state'].includes(k))), 'record');
    d ||= { field: 'record.state encoding (SHA-256)', before: x.hash, after: y.hash };
    const m = d?.field.match(/^state\.units\[(\d+)\]/);
    const u = m && (ys.units[+m[1]] || xs.units[+m[1]]);
    if (u) unit = `${u.id} (${u.side} ${u.tpl})`;
  }
  return [`turn ${r.turn}, round ${r.round}, after ${r.actor}; unit ${unit}`,
    `${d.field}: ${value(d.before)} -> ${value(d.after)}`,
    `later changed records: ${changed.length - 1}; total records: ${a.length} -> ${b.length}`];
}
module.exports = { HOME, SCENARIOS, FILES, sha, json, stable, read, records, manifest, unpack, pack, evidence, auxiliary, diff, value, battleDiff };
