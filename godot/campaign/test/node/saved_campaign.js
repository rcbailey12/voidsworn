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
let changed = 0;
for (const name of items) {
  const file = path.join(out, name);
  if (!fs.existsSync(file) || !fs.statSync(file).size) { fail(name + ': Godot wrote nothing'); continue; }
  const bytes = fs.readFileSync(file), entry = manifest.files[name];
  if (mode === 'update') {
    if (!g1.ok || !g2.ok) continue;
    if (!entry || entry.sha256 !== sha(bytes)) { fs.writeFileSync(path.join(HOME, name + '.br'), pack(bytes)); changed++; }
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
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 1) + '\n');
  console.log(`PASS: saved campaign results updated (${changed} of ${items.length} files changed). Commit godot/campaign/test/saved/ with the rules change and say in the pull request why each changed run moved.`);
  process.exit(0);
}
console.log(fails ? `FAIL: ${fails} campaign check(s) differ (${changed} changed). If the change is intended, run: node godot/campaign/test/node/saved_campaign.js update ${a} ${z}`
  : `PASS: all ${seeds.length} seeded runs and the Nemesis scenarios match the saved results.`);
process.exit(fails ? 1 : 0);
