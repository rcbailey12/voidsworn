// Issue 1654 (R405, Ryan Nov 22 2026): the browser rules twin is retired, so the Godot campaign is checked against its own
// reviewed results in the repo (godot/campaign/test/saved/), not against a fresh JS run.
//   GODOT=... node godot/campaign/test/node/saved_campaign.js check  [first_seed last_seed]   (default 1 30)
//   GODOT=... node godot/campaign/test/node/saved_campaign.js update [first_seed last_seed]   (after a reviewed change)
// It plays the seeded bot runs (parity_campaign.gd) and the Nemesis scenarios (nem_scenarios.gd) in Godot and compares the
// exact bytes with the saved copies. A changed run names its first changed step and field (compare_campaign.js), so a
// pull request that changes campaign rules shows what moved; update rewrites the saved copies for that same pull request.
'use strict';
const fs = require('fs'), os = require('os'), path = require('path'), crypto = require('crypto'), zlib = require('zlib');
const { spawnSync } = require('child_process');
const T = path.resolve(__dirname, '..'), P = path.resolve(T, '../..'), HOME = path.join(T, 'saved');
const G = process.env.GODOT || 'godot';
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const pack = b => zlib.brotliCompressSync(b, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 5, [zlib.constants.BROTLI_PARAM_LGWIN]: 24 } });
const [mode = 'check', a = '1', z = '30'] = process.argv.slice(2);
if (!['check', 'update'].includes(mode) || !/^\d+$/.test(a) || !/^\d+$/.test(z) || +a > +z) {
  console.log('usage: saved_campaign.js check|update [first_seed last_seed]'); process.exit(2);
}
const seeds = []; for (let s = +a; s <= +z; s++) seeds.push(s);
const out = fs.mkdtempSync(path.join(process.env.RUNNER_TEMP || os.tmpdir(), 'voidsworn-campaign-'));
const godot = (args, log) => {
  const r = spawnSync(G, ['--headless', '--path', P, '--script', ...args], { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, timeout: 1500 * 1000 });
  fs.writeFileSync(path.join(out, log), (r.stdout || '') + (r.stderr || ''));
  const errs = ((r.stdout || '') + (r.stderr || '')).split('\n').filter(l => /SCRIPT ERROR|^ERROR:/.test(l)).slice(0, 5);
  return { ok: r.status === 0 && !errs.length, errs, status: r.status };
};
// Codex review of PR 1669: a short or broken run must never pass or become the saved result. A seeded run is whole when every
// line is a record numbered in order from 0, opens with start, reaches startRun, resolves at least one battle (win, loss or
// partial), and ends with a single end record. Nemesis lines are "<scenario words> <JSON>".
function problem(name, bytes) {
  const lines = bytes.toString('utf8').replace(/\n$/, '').split('\n');
  if (name.startsWith('c')) {
    let rows;
    try { rows = lines.map(l => JSON.parse(l)); } catch (e) { return 'a line is not JSON (' + e.message + ')'; }
    const bad = rows.findIndex((r, j) => !r || typeof r !== 'object' || r.i !== j || typeof r.act !== 'string');
    if (bad >= 0) return `record ${bad} is out of order or has no act`;
    if (rows[0].act !== 'start') return 'the run does not open with start';
    const end = rows.at(-1);
    if (end.act !== 'end' || end.arg !== '' || rows.slice(0, -1).some(r => r.act === 'end')) return 'the run does not finish with one end record';
    if (rows.slice(0, -1).some(r => !r.h || typeof r.h !== 'object' || typeof r.acts !== 'string')) return 'a step has no state hashes or action list';
    if (!rows.some(r => r.act === 'startRun')) return 'the run never reaches startRun';
    if (!rows.some(r => r.act === 'battle' && ['win', 'loss', 'partial'].includes(r.arg))) return 'the run resolves no battle';
    return null;
  }
  if (!lines.length || !lines[0]) return 'no Nemesis scenario lines';
  for (let j = 0; j < lines.length; j++) {
    // "<scenario words> <JSON value>": some split after a word must leave a JSON value
    const w = lines[j].split(' ');
    const ok = w.length > 1 && w.slice(1).some((_, k) => { try { JSON.parse(w.slice(k + 1).join(' ')); return true; } catch { return false; } });
    if (!ok) return `Nemesis line ${j + 1} is not "<scenario> <JSON>"`;
  }
  return null;
}
if (process.env.SAVED_CAMPAIGN_SELFTEST) {
  // node saved_campaign.js with SAVED_CAMPAIGN_SELFTEST=1: every saved archive passes; a truncated or reordered run fails.
  const m = JSON.parse(fs.readFileSync(path.join(HOME, 'results.json'), 'utf8'));
  let n = 0;
  for (const [name, e] of Object.entries(m.files)) {
    const b = zlib.brotliDecompressSync(fs.readFileSync(path.join(HOME, e.archive)));
    const p = problem(name, b); if (p) { console.log(`FAIL saved ${name}: ${p}`); process.exit(1); }
    n++;
  }
  const c2 = zlib.brotliDecompressSync(fs.readFileSync(path.join(HOME, m.files['c2.jsonl'].archive))).toString().trim().split('\n');
  const cases = {
    'start and end only (the Codex case)': [JSON.stringify({ ...JSON.parse(c2[0]), i: 0 }), JSON.stringify({ act: 'end', arg: '', i: 1 })],
    'cut before the end': c2.slice(0, -5),
    'records out of order': [c2[0], c2[2], c2[1], ...c2.slice(3)],
    'not JSON': [...c2.slice(0, -1), 'oops', c2.at(-1)],
  };
  for (const [k, v] of Object.entries(cases)) if (!problem('c2.jsonl', Buffer.from(v.join('\n') + '\n'))) { console.log('FAIL selftest: accepted ' + k); process.exit(1); }
  if (!problem('nem.txt', Buffer.from('a1 not json\n'))) { console.log('FAIL selftest: accepted a broken Nemesis line'); process.exit(1); }
  console.log(`PASS saved_campaign selftest: ${n} saved files are whole; ${Object.keys(cases).length + 1} broken shapes refused`);
  process.exit(0);
}
let fails = 0;
const fail = m => { fails++; console.log('  FAIL ' + m); };
console.log(`Campaign check (Godot only, against the saved results): seeds ${a} to ${z}; run folder ${out}`);
const g1 = godot(['res://campaign/test/parity_campaign.gd', '--', out, ...seeds.map(String)], 'campaign_godot.log');
if (!g1.ok) fail(`Godot campaign runs exited ${g1.status}${g1.errs.length ? ': ' + g1.errs.join(' | ') : ''} (see ${out}/campaign_godot.log)`);
const g2 = godot(['res://campaign/test/nem_scenarios.gd', '--', path.join(out, 'nem.txt')], 'nem_godot.log');
if (!g2.ok) fail(`Godot Nemesis scenarios exited ${g2.status}${g2.errs.length ? ': ' + g2.errs.join(' | ') : ''} (see ${out}/nem_godot.log)`);
const items = [...seeds.map(s => `c${s}.jsonl`), 'nem.txt'];
const manifestPath = path.join(HOME, 'results.json');
const manifest = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, 'utf8')) : { version: 1, compression: 'brotli-5-window24', files: {} };
let changed = 0; const writes = [];
for (const name of items) {
  const file = path.join(out, name);
  if (!fs.existsSync(file) || !fs.statSync(file).size) { fail(name + ': Godot wrote nothing'); continue; }
  const bytes = fs.readFileSync(file), entry = manifest.files[name];
  const broken = problem(name, bytes);
  if (broken) { fail(`${name}: Godot wrote a broken result: ${broken} (see ${file})`); continue; }
  if (mode === 'update') {
    if (!g1.ok || !g2.ok) continue;
    if (!entry || entry.sha256 !== sha(bytes)) { writes.push([path.join(HOME, name + '.br'), bytes]); changed++; }
    manifest.files[name] = { sha256: sha(bytes), bytes: bytes.length, archive: name + '.br' };
    continue;
  }
  if (!entry) { fail(name + ': no saved result (run update in this pull request)'); continue; }
  const before = zlib.brotliDecompressSync(fs.readFileSync(path.join(HOME, entry.archive)));
  if (sha(before) !== entry.sha256) { fail(name + ': saved archive is damaged'); continue; }
  if (sha(bytes) === entry.sha256) { console.log(`  ${name}: PASS (${bytes.toString().trim().split('\n').length} records, identical)`); continue; }
  changed++;
  const old = path.join(out, 'saved_' + name); fs.writeFileSync(old, before);
  if (name.startsWith('c')) {
    const r = spawnSync(process.execPath, [path.join(__dirname, 'compare_campaign.js'), old, file], { encoding: 'utf8' });
    fail(name + ' changed: ' + (r.stdout || '').trim().replace(/\n  JS:    /, '\n    saved: ').replace(/\n  Godot: /, '\n    now:   '));
  } else {
    const x = before.toString().split('\n'), y = bytes.toString().split('\n');
    const i = Array.from({ length: Math.max(x.length, y.length) }, (_, j) => j).find(j => x[j] !== y[j]);
    fail(`${name} changed at line ${i + 1}:\n    saved: ${(x[i] || 'missing').slice(0, 300)}\n    now:   ${(y[i] || 'missing').slice(0, 300)}`);
  }
}
if (mode === 'update') {
  if (fails) { console.log(`FAIL: not updated; ${fails} problem(s)`); process.exit(1); }
  for (const [f, b] of writes) fs.writeFileSync(f, pack(b)); // only once every file checked whole
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 1) + '\n');
  console.log(`PASS: saved campaign results updated (${changed} of ${items.length} files changed). Commit godot/campaign/test/saved/ with the rules change and say in the pull request why each changed run moved.`);
  process.exit(0);
}
console.log(fails ? `FAIL: ${fails} campaign check(s) differ (${changed} changed). If the change is intended, run: node godot/campaign/test/node/saved_campaign.js update ${a} ${z}`
  : `PASS: all ${seeds.length} seeded runs and the Nemesis scenarios match the saved results.`);
process.exit(fails ? 1 : 0);
