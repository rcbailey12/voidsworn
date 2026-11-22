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
  const fake = path.join(tmp, 'godot.js');
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
  const nemFirst = path.join(tmp, 'godot_nem.js');
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
  // Artoo on ec1ba036: the same line count with one faction row copied over another ("g corsair" over "g hegemony") is refused
  const nemText = require('zlib').brotliDecompressSync(fs.readFileSync(path.join(SAVED, 'nem.txt.br'))).toString().split('\n');
  const gi = nemText.findIndex(l => l.startsWith('g ')), gj = nemText.findIndex((l, j) => j > gi && l.startsWith('g ') && l.split(' ')[1] !== nemText[gi].split(' ')[1]);
  assert(gi >= 0 && gj > gi, 'two g faction rows in the saved Nemesis file');
  const swapped = path.join(tmp, 'nem_swapped.txt');
  fs.writeFileSync(swapped, nemText.map((l, j) => j === gj ? nemText[gi] : l).join('\n'));
  const nemSwap = path.join(tmp, 'godot_swap.js');
  fs.writeFileSync(nemSwap, fs.readFileSync(nemFirst, 'utf8').replace(/fs\.writeFileSync\(a\[at \+ 1\], zlib[^\n]*/, `fs.writeFileSync(a[at + 1], fs.readFileSync(${JSON.stringify(swapped)}));`));
  fs.chmodSync(nemSwap, 0o755);
  r = spawnSync(process.execPath, [TOOL, 'update', '1', '1'], { env: { ...process.env, GODOT: nemSwap, RUNNER_TEMP: tmp }, encoding: 'utf8' });
  assert.notEqual(r.status, 0, 'update accepted a faction row copied over another: ' + r.stdout);
  assert(new RegExp(`differ from the saved list at line ${gj + 1} \\(saved g `).test(r.stdout), r.stdout);
  assert.deepEqual(snap(), before, 'a refused swap changes no saved file');
  console.log('PASS saved_campaign update: the shape self-test passes, and a truncated run, a one-line Nemesis file or a swapped faction row fails update with every saved file unchanged');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
