'use strict';
// Issue 1657: tools/pc/relay_push.ps1 sends one attempt's results to the relay repo (a local bare stand-in here) on branch
// pc-out-<job> under <attempt folder name>/: out_* files and top text files only, files over 10 MB listed in
// skipped_over_10MB.txt in the form opus_job_head.ps1 proves, a resend replaces the folder, dry sends nothing, and a folder
// outside voidsworn_test is refused. Uses Windows PowerShell 5.1 locally and pwsh in Linux CI.
const assert = require('assert');
const fs = require('fs'), os = require('os'), path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../..', '..');
const shell = (process.platform === 'win32' ? ['powershell.exe'] : ['pwsh']).find(s => !spawnSync(s, ['-NoProfile', '-Command', 'exit 0']).error);
if (!shell) { console.log('SKIP relay_push fixtures: PowerShell is unavailable'); process.exit(0); }
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'relay-push-'));
const profile = path.join(tmp, 'profile'), vt = path.join(profile, 'Downloads', 'voidsworn_test');
const relaySource = path.join(tmp, 'relay.git');
const env = { ...process.env, PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: vt, PC_TEST_RELAY_SOURCE: relaySource };
const write = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
const git = (args) => { const r = spawnSync('git', args, { encoding: 'utf8' }); assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr}`); return r.stdout.trim(); };
const runScript = (script, ...args) => {
  const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(ROOT, 'tools', 'pc', script), ...args], { env, encoding: 'utf8', timeout: 120000 });
  if (r.error) throw r.error;
  return { status: r.status, out: `${r.stdout}\n${r.stderr}` };
};
const run = (...args) => runScript('relay_push.ps1', ...args);
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
    'out_20261122_140000_1/skipped_over_10MB.txt', 'out_20261122_140000_1/status.txt'], 'tree: ' + ls.join(', ') + '\nrelay_push said: ' + r.out + '\nbranch log: ' + git(['--git-dir', relaySource, 'log', '--format=%H %s', '-3', 'refs/heads/pc-out-opus1657']) + '\nshell: ' + shell);
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
  // Artoo on PR 1672: pushes go in bounded batches (here 20 bytes, so one file each); a batch refused midway leaves an
  // incomplete tree that proves nothing, and a rerun sends the attempt whole
  const at5 = path.join(vt, 'opus1657b', 'out_20261122_180000_5');
  for (const n of ['a', 'b', 'c', 'd']) write(path.join(at5, 'out_new', n + '.txt'), n.repeat(15));
  const benv = { ...env, PC_TEST_RELAY_BATCH_BYTES: '20' };
  const runB = (...a) => { const x = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(ROOT, 'tools', 'pc', 'relay_push.ps1'), ...a], { env: benv, encoding: 'utf8', timeout: 120000 }); return { status: x.status, out: `${x.stdout}\n${x.stderr}` }; };
  const hook = path.join(relaySource, 'hooks', 'pre-receive');
  fs.writeFileSync(hook, '#!/bin/sh\nwhile read o n r; do git log -1 --format=%s "$n" | grep -q "part 3 of" && { echo refused part 3 >&2; exit 1; }; done\nexit 0\n');
  fs.chmodSync(hook, 0o755);
  r = runB('opus1657b', at5);
  assert(r.status !== 0 && /part[\s\S]{0,40}3[\s\S]{0,40}of[\s\S]{0,40}4/.test(r.out), 'a refused batch stops the relay: ' + r.out);
  const half = git(['--git-dir', relaySource, 'ls-tree', '-r', '--name-only', 'refs/heads/pc-out-opus1657b']).split('\n');
  assert(half.length === 2 && !half.some(f => f.endsWith('d.txt')), 'only the first two parts are there: ' + half);
  fs.rmSync(hook);
  r = runB('opus1657b', at5);
  assert.equal(r.status, 0, r.out);
  assert(/sent part 4 of 4/.test(r.out), 'four bounded pushes, one per file: ' + r.out);
  const whole = git(['--git-dir', relaySource, 'ls-tree', '-r', '--name-only', 'refs/heads/pc-out-opus1657b']).split('\n').sort();
  assert.deepEqual(whole, ['a', 'b', 'c', 'd'].map(n => `out_20261122_180000_5/out_new/${n}.txt`), 'the rerun sends everything: ' + whole);
  // Issue 1739: Windows PowerShell 5.1 changed what reached git's stdin (CRLF lines, then a byte order mark before the first
  // path), so relay_push never feeds git stdin; paths go as arguments in bounded calls. Many long names (several calls),
  // a space and a non-ASCII letter, and the first path in path order must all land.
  const src = fs.readFileSync(path.join(ROOT, 'tools', 'pc', 'relay_push.ps1'), 'utf8');
  assert(!/--stdin-paths|--index-info|RedirectStandardInput|\|\s*&\s*\$gitExe/.test(src), 'relay_push.ps1 feeds nothing to git on stdin');
  const at6 = path.join(vt, 'opus1739', 'out_20261122_200000_6');
  const names = Array.from({ length: 120 }, (_, i) => `out_new/frame_${String(i).padStart(3, '0')}_${'x'.repeat(60)}.png`).concat(['out_new/a first file.txt', 'out_new/caf\u00e9.txt']);
  for (const n of names) write(path.join(at6, n), n);
  r = run('opus1739', at6);
  assert.equal(r.status, 0, r.out);
  const many = git(['--git-dir', relaySource, '-c', 'core.quotepath=false', 'ls-tree', '-r', '--name-only', 'refs/heads/pc-out-opus1739']).split('\n').sort();
  assert.deepEqual(many, names.map(n => 'out_20261122_200000_6/' + n).sort(), 'every file lands, the first one too: ' + many.slice(0, 3).join(', '));
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
  assert(r.status !== 0 && /a link in the results:[\s\S]*out_link/.test(r.out), 'an out_* link is refused: ' + r.out);
  fs.mkdirSync(path.join(harmless, 'out_20261122_170000_4', 'out_new'), { recursive: true });
  write(path.join(harmless, 'out_20261122_170000_4', 'out_new', 'shot.png'), 'x');
  fs.symlinkSync(harmless, path.join(vt, 'linkedjob'), 'junction');
  r = run('opus1657', path.join(vt, 'linkedjob', 'out_20261122_170000_4'));
  assert(r.status !== 0 && /a link on the way to the attempt:[\s\S]*linkedjob/.test(r.out), 'an attempt under a link is refused: ' + r.out);
  assert.equal(git(['--git-dir', relaySource, 'rev-parse', 'refs/heads/pc-out-opus1657']), before, 'a refusal sends nothing');

  // Issue 1839: the whole-folder janitor uses the same saved-work rule before and after the additive relay.
  const attemptName = 'out_20261120_120000_1';
  const attemptFor = name => path.join(vt, name, attemptName);
  const leftPath = path.join('out_new', 'checkout_leftovers');
  const savedFile = path.join(leftPath, 'files', 'work.txt');
  const relayTip = name => git(['--git-dir', relaySource, 'rev-parse', `refs/heads/pc-out-${name}`]);
  const relayFile = (name, file) => git(['--git-dir', relaySource, 'show', `refs/heads/pc-out-${name}:${attemptName}/${file.split(path.sep).join('/')}`]);
  const testTemp = path.join(tmp, 'janitor-temp');
  fs.mkdirSync(testTemp);
  const mirror = path.join(vt, 'repo-mirror.git');
  const seed = path.join(tmp, 'seed');
  git(['init', '-q', seed]);
  write(path.join(seed, 'tracked.txt'), 'initial\n');
  git(['-C', seed, 'add', 'tracked.txt']);
  git(['-C', seed, '-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture']);
  git(['clone', '-q', '--mirror', seed, mirror]);
  Object.assign(env, { USERPROFILE: profile, PC_RUNNER_TEST: '1', PC_TEST_MIRROR: mirror, PC_TEST_SOURCE: seed,
    PC_RUN_TEMP: testTemp, PC_TEST_COMMAND_LINES: 'fixture', PC_TEST_JANITOR_NOW: '2030-01-03T00:00:00Z' });
  const backfill = 'opus1839backfill', unrelayed = 'opus1839unrelayed', newest = 'opus1839new';
  for (const name of [backfill, unrelayed]) {
    const attempt = attemptFor(name);
    write(path.join(attempt, 'done.txt'), 'PASS\r\n');
    write(path.join(attempt, 'out_new', 'result.txt'), `result for ${name}`);
    r = run(name, attempt);
    assert.equal(r.status, 0, r.out);
    write(path.join(attempt, leftPath, 'leftovers.txt'), `manifest from ${name}`);
    write(path.join(attempt, savedFile), `work from ${name}`);
  }
  write(path.join(attemptFor(unrelayed), 'out_new', 'missing-result.txt'), 'a real result that has never been relayed');
  const oldDate = new Date('2029-12-30T00:00:00Z');
  function dateTree(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const file = path.join(dir, entry.name);
      if (entry.isDirectory()) dateTree(file);
      else fs.utimesSync(file, oldDate, oldDate);
    }
    fs.utimesSync(dir, oldDate, oldDate);
  }
  function dryJanitor() {
    const dry = runScript('janitor.ps1', '--dry-run');
    assert.equal(dry.status, 0, dry.out);
    return dry.out;
  }
  function decision(report, name) {
    const job = path.dirname(attemptFor(name));
    const line = report.split(/\r?\n/).find(row => row.startsWith(`would keep ${job} (`) || row.startsWith(`would remove ${job} (`));
    assert(line, report);
    return line;
  }
  dateTree(path.dirname(attemptFor(backfill)));
  dateTree(path.dirname(attemptFor(unrelayed)));
  let dryReport = dryJanitor();
  assert.match(decision(dryReport, backfill), /would keep.*2 of 4 out files are not on a relay branch/);
  const beforeBackfill = relayTip(backfill);
  r = run(backfill, attemptFor(backfill), 'leftovers');
  assert.equal(r.status, 0, r.out);
  assert.equal(git(['--git-dir', relaySource, 'rev-parse', `${relayTip(backfill)}^`]), beforeBackfill, 'backfill keeps the existing branch history');
  assert.equal(relayFile(backfill, path.join(leftPath, 'leftovers.txt')), `manifest from ${backfill}`);
  assert.equal(relayFile(backfill, savedFile), `work from ${backfill}`);
  assert.equal(relayFile(backfill, path.join('out_new', 'result.txt')), `result for ${backfill}`);
  const afterBackfill = relayTip(backfill);
  r = run(backfill, attemptFor(backfill), 'leftovers');
  assert.equal(r.status, 0, r.out);
  assert.equal(relayTip(backfill), afterBackfill, 'a retry adds no redundant commit');
  const beforeRefusal = relayTip(unrelayed);
  r = run(unrelayed, attemptFor(unrelayed), 'leftovers');
  assert.notEqual(r.status, 0, r.out);
  assert.match(r.out, /original result missing or different[\s\S]*missing-result\.txt/);
  assert.equal(relayTip(unrelayed), beforeRefusal, 'an unrelayed result prevents any backfill push');
  dryReport = dryJanitor();
  assert.match(decision(dryReport, backfill), /would remove.*helper folder with its results relayed/);
  assert.match(decision(dryReport, unrelayed), /would keep.*3 of 5 out files are not on a relay branch/);
  assert(fs.existsSync(path.join(attemptFor(backfill), savedFile)), 'backfill and dry run keep the existing files on disk');

  // A normal relay happens first, then the existing head cleanup saves checkout work and relays it before its receipt.
  const newAttempt = attemptFor(newest);
  const pin = git(['-C', seed, 'rev-parse', 'HEAD']);
  r = runScript('jobs/opus_job_head.ps1', 'checkout', newAttempt, 'new', pin);
  assert.equal(r.status, 0, r.out);
  write(path.join(newAttempt, 'new', 'work.txt'), 'new job work');
  write(path.join(newAttempt, 'new', 'tracked.txt'), 'a tracked edit\n');
  write(path.join(newAttempt, 'done.txt'), 'PASS\r\n');
  write(path.join(newAttempt, 'relay_branch.txt'), `relay/pc-out-${newest} ${attemptName}\r\n`);
  write(path.join(newAttempt, 'out_new', 'result.txt'), 'new job result');
  r = run(newest, newAttempt);
  assert.equal(r.status, 0, r.out);
  const firstTip = relayTip(newest);
  assert(!fs.existsSync(path.join(newAttempt, 'relay_receipt.txt')));
  r = runScript('jobs/opus_job_head.ps1', 'dropcheckouts', newAttempt);
  assert.equal(r.status, 0, r.out);
  assert.match(r.out, /saved 1 changed and 1 new file[\s\S]*relay receipt written/);
  assert.equal(git(['--git-dir', relaySource, 'rev-parse', `${relayTip(newest)}^`]), firstTip);
  assert.match(relayFile(newest, path.join(leftPath, 'leftovers.txt')), /copied .*work\.txt/);
  assert.match(relayFile(newest, path.join(leftPath, 'changes.patch')), /\+a tracked edit/);
  assert.equal(relayFile(newest, savedFile), 'new job work');
  assert.equal(relayFile(newest, 'relay_receipt.txt'), fs.readFileSync(path.join(newAttempt, 'relay_receipt.txt'), 'utf8').trim());
  dateTree(path.dirname(newAttempt));
  assert.match(decision(dryJanitor(), newest), /would remove.*helper folder with its results relayed/);
  console.log('PASS: new checkout leftovers and receipt relayed, backfilled job saved by janitor dry run, unrelayed result kept');
  console.log('PASS: relay_push sends out_* and top text files to pc-out-<job>, lists files over 10 MB, resends replace, dry sends nothing, links refused, bounded batches');
} finally { fs.rmSync(tmp, { recursive: true, force: true }); }
