'use strict';
// Issue 1654 (Codex review and Artoo on PR 1669): saved_campaign.js update must refuse a truncated Godot run and leave every
// saved archive and the manifest unchanged. A stand-in Godot writes a two-record seed 1 run (start, end) and a good Nemesis
// file; update must fail and nothing under godot/campaign/test/saved/ may change. Also runs the shape self-test.
const assert = require('assert');
const fs = require('fs'), os = require('os'), path = require('path'), crypto = require('crypto');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const SAVED = path.join(ROOT, 'godot/campaign/test/saved'), TOOL = path.join(ROOT, 'godot/campaign/test/node/saved_campaign.js');
const snap = () => Object.fromEntries(fs.readdirSync(SAVED).sort().map(f => [f, crypto.createHash('sha256').update(fs.readFileSync(path.join(SAVED, f))).digest('hex')]));
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'saved-campaign-'));
try {
  let r = spawnSync(process.execPath, [TOOL], { env: { ...process.env, SAVED_CAMPAIGN_SELFTEST: '1' }, encoding: 'utf8' });
  assert.equal(r.status, 0, 'self-test: ' + r.stdout + r.stderr);
  const fake = path.join(tmp, 'godot');
  fs.writeFileSync(fake, `#!${process.execPath}
const fs = require('fs'), zlib = require('zlib'), a = process.argv.slice(2), at = a.indexOf('--');
if (a.some(x => x.includes('parity_campaign.gd'))) fs.writeFileSync(require('path').join(a[at + 1], 'c1.jsonl'),
  '{"act":"start","acts":"","arg":"","h":{},"i":0}\\n{"act":"end","arg":"","i":1}\\n');
if (a.some(x => x.includes('nem_scenarios.gd'))) fs.writeFileSync(a[at + 1], zlib.brotliDecompressSync(fs.readFileSync(${JSON.stringify(path.join(SAVED, 'nem.txt.br'))})));
`);
  fs.chmodSync(fake, 0o755);
  const before = snap();
  r = spawnSync(process.execPath, [TOOL, 'update', '1', '1'], { env: { ...process.env, GODOT: fake, RUNNER_TEMP: tmp }, encoding: 'utf8' });
  assert.notEqual(r.status, 0, 'update accepted a truncated run: ' + r.stdout);
  assert(/c1\.jsonl: Godot wrote a broken result/.test(r.stdout) && /not updated/.test(r.stdout), r.stdout);
  assert.deepEqual(snap(), before, 'a refused update changes no saved archive and not the manifest');
  r = spawnSync(process.execPath, [TOOL, 'check', '1', '1'], { env: { ...process.env, GODOT: fake, RUNNER_TEMP: tmp }, encoding: 'utf8' });
  assert.notEqual(r.status, 0, 'check passed a truncated run: ' + r.stdout);
  // Artoo on 3ca8bd98: a Nemesis file cut to its first valid line is refused by update, every saved file unchanged
  const nemFirst = path.join(tmp, 'godot_nem');
  fs.writeFileSync(nemFirst, `#!${process.execPath}
const fs = require('fs'), zlib = require('zlib'), a = process.argv.slice(2), at = a.indexOf('--');
if (a.some(x => x.includes('parity_campaign.gd'))) fs.writeFileSync(require('path').join(a[at + 1], 'c1.jsonl'), zlib.brotliDecompressSync(fs.readFileSync(${JSON.stringify(path.join(SAVED, 'c1.jsonl.br'))})));
if (a.some(x => x.includes('nem_scenarios.gd'))) fs.writeFileSync(a[at + 1], zlib.brotliDecompressSync(fs.readFileSync(${JSON.stringify(path.join(SAVED, 'nem.txt.br'))})).toString().split('\\n')[0] + '\\n');
`);
  fs.chmodSync(nemFirst, 0o755);
  r = spawnSync(process.execPath, [TOOL, 'update', '1', '1'], { env: { ...process.env, GODOT: nemFirst, RUNNER_TEMP: tmp }, encoding: 'utf8' });
  assert.notEqual(r.status, 0, 'update accepted a one-line Nemesis file: ' + r.stdout);
  assert(/nem\.txt: the scenario lines differ from the saved list/.test(r.stdout), r.stdout);
  assert.deepEqual(snap(), before, 'a refused Nemesis update changes no saved file');
  console.log('PASS saved_campaign update: the shape self-test passes, and a truncated run or a one-line Nemesis file fails update with every saved file unchanged');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
