'use strict';
// Issue 1657: tools/pc/relay_push.ps1 sends one attempt's results to the relay repo (a local bare stand-in here) on branch
// pc-out-<job> under <attempt folder name>/: out_* files and top text files only, files over 10 MB listed in
// skipped_over_10MB.txt in the form opus_job_head.ps1 proves, a resend replaces the folder, dry sends nothing, and a folder
// outside voidsworn_test is refused. Needs pwsh (Linux CI has it); skipped without it.
const assert = require('assert');
const fs = require('fs'), os = require('os'), path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../..', '..');
const shell = ['pwsh', 'powershell'].find(s => !spawnSync(s, ['-NoProfile', '-Command', 'exit 0']).error);
if (!shell) { console.log('SKIP relay_push fixtures: they need pwsh (Linux CI runs them)'); process.exit(0); }
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'relay-push-'));
const vt = path.join(tmp, 'vt'), relaySource = path.join(tmp, 'relay.git');
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_RELAY_SOURCE: relaySource };
const write = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
const git = (args) => { const r = spawnSync('git', args, { encoding: 'utf8' }); assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`); return r.stdout.trim(); };
const run = (...a) => { const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(ROOT, 'tools', 'pc', 'relay_push.ps1'), ...a], { env, encoding: 'utf8', timeout: 120000 }); return { status: r.status, out: `${r.stdout}\n${r.stderr}` }; };
try {
  git(['init', '-q', '--bare', relaySource]);
  const at = path.join(vt, 'opus1657', 'out_20261122_140000_1');
  write(path.join(at, 'status.txt'), 'status\n');
  write(path.join(at, 'done.txt'), 'PASS\r\n');
  write(path.join(at, 'out_new', 'shot.png'), 'png bytes');
  write(path.join(at, 'out_new', 'deep', 'clip.mp4'), 'mp4 bytes');
  write(path.join(at, 'new', 'godot', 'project.godot'), 'a checkout never goes\n');
  write(path.join(at, 'out_new', 'big.bin'), Buffer.alloc(11 * 1024 * 1024, 1));
  let r = run('opus1657', at, 'dry');
  assert.equal(r.status, 0, r.out);
  assert(/would send out_20261122_140000_1\/out_new\/shot\.png/.test(r.out) && /dry run: nothing sent/.test(r.out), 'dry lists: ' + r.out);
  assert(!fs.existsSync(path.join(vt, 'relay-mirror.git')) && git(['--git-dir', relaySource, 'for-each-ref']) === '', 'dry sends nothing');
  r = run('opus1657', at);
  assert.equal(r.status, 0, r.out);
  const ls = git(['--git-dir', relaySource, 'ls-tree', '-r', '--name-only', 'refs/heads/pc-out-opus1657']).split('\n').sort();
  assert.deepEqual(ls, ['out_20261122_140000_1/done.txt', 'out_20261122_140000_1/out_new/deep/clip.mp4', 'out_20261122_140000_1/out_new/shot.png',
    'out_20261122_140000_1/skipped_over_10MB.txt', 'out_20261122_140000_1/status.txt'], 'tree: ' + ls.join(', '));
  const skipped = git(['--git-dir', relaySource, 'show', 'refs/heads/pc-out-opus1657:out_20261122_140000_1/skipped_over_10MB.txt']);
  assert(/^out_new[\\/]big\.bin 11\.0 MB$/.test(skipped.trim()) && skipped.includes('out_new\\big.bin'), 'skip list in the proof form: ' + skipped);
  assert.equal(git(['--git-dir', relaySource, 'show', 'refs/heads/pc-out-opus1657:out_20261122_140000_1/out_new/shot.png']), 'png bytes');
  assert(/receipt place: relay\/pc-out-opus1657 out_20261122_140000_1/.test(r.out) && /picture link: https:\/\/github\.com\/rcbailey12\/voidsworn-relay\/blob\/[0-9a-f]{40}\/out_20261122_140000_1\/out_new\/shot\.png/.test(r.out), 'links: ' + r.out);
  // a second attempt adds to the branch; a resend of the first replaces its folder whole
  const at2 = path.join(vt, 'opus1657', 'out_20261122_150000_2');
  write(path.join(at2, 'out_new', 'shot.png'), 'second');
  assert.equal(run('opus1657', at2).status, 0);
  fs.rmSync(path.join(at, 'out_new', 'deep'), { recursive: true });
  assert.equal(run('opus1657', at).status, 0);
  const ls2 = git(['--git-dir', relaySource, 'ls-tree', '-r', '--name-only', 'refs/heads/pc-out-opus1657']);
  assert(ls2.includes('out_20261122_150000_2/out_new/shot.png') && !ls2.includes('deep/clip.mp4'), 'resend replaces, other attempts stay: ' + ls2);
  // refusals
  const outside = path.join(tmp, 'elsewhere', 'out_1'); write(path.join(outside, 'out_x', 'a.txt'), 'x');
  assert.notEqual(run('opus1657', outside).status, 0, 'a folder outside voidsworn_test is refused');
  assert.notEqual(run('bad name', at).status, 0, 'a bad job name is refused');
  assert.notEqual(run('opus1657', at, 'live').status, 0, 'only dry is a mode');
  // Artoo on PR 1672: a link as an out_* folder, or on the way to the attempt, is refused before anything is read
  const before = git(['--git-dir', relaySource, 'rev-parse', 'refs/heads/pc-out-opus1657']);
  const harmless = path.join(tmp, 'harmless'); write(path.join(harmless, 'note.txt'), 'outside the attempt');
  const at3 = path.join(vt, 'opus1657', 'out_20261122_160000_3'); write(path.join(at3, 'status.txt'), 'status\n');
  fs.symlinkSync(harmless, path.join(at3, 'out_link'), 'junction');
  r = run('opus1657', at3);
  assert(r.status !== 0 && /a link in the results: .*out_link/.test(r.out), 'an out_* link is refused: ' + r.out);
  fs.mkdirSync(path.join(harmless, 'out_20261122_170000_4', 'out_new'), { recursive: true });
  write(path.join(harmless, 'out_20261122_170000_4', 'out_new', 'shot.png'), 'x');
  fs.symlinkSync(harmless, path.join(vt, 'linkedjob'), 'junction');
  r = run('opus1657', path.join(vt, 'linkedjob', 'out_20261122_170000_4'));
  assert(r.status !== 0 && /a link on the way to the attempt: .*linkedjob/.test(r.out), 'an attempt under a link is refused: ' + r.out);
  assert.equal(git(['--git-dir', relaySource, 'rev-parse', 'refs/heads/pc-out-opus1657']), before, 'a refusal sends nothing');
  console.log('PASS: relay_push sends out_* and top text files to pc-out-<job>, lists files over 10 MB, resends replace, dry sends nothing, links refused');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
