'use strict';
// Issue 2059: live PowerShell and Git against a tiny local mirror, with an explicit gate on fetch.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');

const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI) throw new Error(`${shell} is required in CI`);
  console.log('SKIP mirror lock fixtures: PowerShell not installed');
  process.exit(0);
}
const pc = path.resolve(__dirname, '../../../tools/pc');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'mirror2059-'));
const source = path.join(tmp, 'source.git');
const mirror = path.join(tmp, 'repo-mirror.git');
const bench = path.join(tmp, 'LB home');
const pins = path.join(tmp, 'bench-pins.txt');
const gitExe = spawnSync(windows ? 'where.exe' : 'which', [windows ? 'git.exe' : 'git'], { encoding: 'utf8' }).stdout.trim().split(/\r?\n/)[0];
const env = {
  ...process.env, TEMP: tmp, TMP: tmp, TMPDIR: tmp, PC_RUNNER_TEST: '1', PC_TEST_MIRROR: mirror, PC_TEST_SOURCE: source,
  PC_TEST_GIT: gitExe, PC_TEST_RETRY_SECONDS: '0', PC_MIRROR_LOCK_WAIT_SECONDS: '15', PC_REAL_GIT: gitExe,
  LB_HOME: bench, LB_TOOL_REF: 'refs/tags/bench-tools', AFTER: 'origin/main', BEFORE: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
  GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid',
};
const write = (file, data = '') => fs.writeFileSync(file, data);
const read = file => fs.readFileSync(file, 'utf8').trim();
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
function git(...args) {
  const r = spawnSync(gitExe, args, { env, cwd: tmp, encoding: 'utf8', windowsHide: true, timeout: 15000 });
  assert.equal(r.status, 0, `git ${args.join(' ')}: ${r.stderr || r.error}`);
  return r.stdout.trim();
}
function ps(script, args, extra = {}, timeout = 60000) {
  const p = spawn(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, script), ...args], {
    env: { ...env, ...extra }, cwd: tmp, windowsHide: true, timeout,
  });
  const state = { text: '', finished: false };
  p.stdout.on('data', b => state.text += b);
  p.stderr.on('data', b => state.text += b);
  state.done = new Promise((resolve, reject) => {
    p.on('error', reject);
    p.on('close', code => { state.finished = true; resolve({ code, text: state.text }); });
  });
  return state;
}
function lane(name, extra, timeout) {
  const folder = path.join(tmp, name);
  const out = path.join(folder, 'out');
  fs.mkdirSync(out, { recursive: true });
  return ps('runner_common.ps1', ['checkout', path.join(folder, 'repo'), out, 'fixture/' + name], extra, timeout);
}
function helper(name, extra) {
  return ps('helper_clone.ps1', ['-JobDir', path.join(tmp, name), '-Branch', 'main'],
    { PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: tmp, ...extra });
}
async function waitFor(file, child) {
  for (let i = 0; i < 300 && !child.finished; i++) {
    if (fs.existsSync(file)) return;
    await sleep(50);
  }
  assert.fail(`fetch never reached gate ${file}: ${child.text}`);
}
function pass(result) { assert.equal(result.code, 0, result.text); }

function batchProof(after, before) {
  const tools = path.join(tmp, 'fixture tools');
  const jobs = path.join(tools, 'jobs');
  const batchHome = path.join(tmp, 'batch bench');
  fs.mkdirSync(jobs, { recursive: true });
  fs.copyFileSync(path.join(pc, 'runner_common.ps1'), path.join(tools, 'runner_common.ps1'));
  fs.copyFileSync(path.join(pc, 'run_timeout.ps1'), path.join(tools, 'run_timeout.ps1'));
  fs.copyFileSync(path.join(pc, 'jobs/look_bench.bat'), path.join(jobs, 'look_bench.bat'));
  // Run the real cmd launcher and all its Git steps, with no Godot, Python or GPU claims.
  write(path.join(tools, 'job_wrap.bat'), [
    '@echo off',
    'if /i "%~1"=="fail" exit /b 1',
    'if /i "%~1"=="run" if "%JW_STEP:~0,6%"=="bench " echo LOOK_BENCH_DONE',
    'exit /b 0',
  ].join('\r\n') + '\r\n');
  const result = spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/s', '/c', `""${path.join(jobs, 'look_bench.bat')}" origin/main"`], {
    env: { ...env, LB_HOME: batchHome, LB_QUIET: '1', LB_SHIPS: path.join(tmp, 'no-ships') },
    cwd: tmp, windowsHide: true, windowsVerbatimArguments: true, encoding: 'utf8', timeout: 60000,
  });
  assert.equal(result.status, 0, result.error || result.stderr || result.stdout);
  for (const sha of [after, before]) {
    assert.equal(read(path.join(batchHome, 'runs', sha.slice(0, 8), 'commit.txt')), sha);
    assert.equal(read(path.join(batchHome, 'runs', sha.slice(0, 8), 'DONE.txt')), sha.slice(0, 8));
  }
  console.log('PASS Windows launcher consumes the prepared AFTER and default BEFORE pins without starting GPU tools');
}

async function main() {
  const seed = path.join(tmp, 'seed');
  git('init', '-q', '-b', 'main', seed);
  git('-C', seed, 'commit', '-q', '--allow-empty', '-m', 'before');
  const before = git('-C', seed, 'rev-parse', 'HEAD');
  const baseline = path.join(seed, 'docs/shots/look_bench/BASELINE.txt');
  fs.mkdirSync(path.dirname(baseline), { recursive: true });
  write(baseline, before + '\n');
  for (const file of ['godot/bench/look_bench.gd', 'godot/bench/look_bench.tscn',
    'godot/bench/look_moments.json', 'godot/tools/picture_provenance.gd']) {
    const fixture = path.join(seed, file);
    fs.mkdirSync(path.dirname(fixture), { recursive: true });
    write(fixture, 'fixture\n');
  }
  git('-C', seed, 'add', 'docs', 'godot');
  git('-C', seed, 'commit', '-q', '-m', 'bench tools');
  const tool = git('-C', seed, 'rev-parse', 'HEAD');
  git('-C', seed, 'tag', '-a', '-m', 'annotated tools', 'bench-tools');
  git('-C', seed, 'commit', '-q', '--allow-empty', '-m', 'after');
  const after = git('-C', seed, 'rev-parse', 'HEAD');
  git('-C', seed, 'branch', 'unrelated', after);
  git('-C', seed, 'checkout', '-q', '-b', 'bench-prunable');
  write(path.join(seed, 'prune-proof.txt'), 'before\n');
  git('-C', seed, 'add', 'prune-proof.txt');
  git('-C', seed, 'commit', '-q', '-m', 'prunable before');
  const prunableBefore = git('-C', seed, 'rev-parse', 'HEAD');
  write(path.join(seed, 'prune-proof.txt'), 'after\n');
  git('-C', seed, 'commit', '-qam', 'prunable after');
  const prunableAfter = git('-C', seed, 'rev-parse', 'HEAD');
  git('-C', seed, 'checkout', '-q', 'main');
  git('clone', '-q', '--bare', seed, source);
  git('clone', '-q', '--mirror', source, mirror);
  git('--git-dir', mirror, 'repack', '-ad');

  const hook = path.join(tmp, 'git-hook.js');
  const shim = path.join(tmp, windows ? 'fixture-git.cmd' : 'fixture-git');
  write(shim, windows ? `@echo off\r\n"${process.execPath}" "${hook}" %*\r\nexit /b %ERRORLEVEL%\r\n`
    : `#!/bin/sh\nexec "${process.execPath}" "${hook}" "$@"\n`);
  if (!windows) fs.chmodSync(shim, 0o700);
  // cmd consumes the caret in annotated tag lookups. Use a PowerShell shim for the bench's native argv.
  const benchShim = windows ? path.join(tmp, 'bench-git.ps1') : shim;
  if (windows) write(benchShim, `& '${process.execPath}' '${hook}' @args\nexit $LASTEXITCODE\n`);
  write(hook, `
const fs = require('node:fs');
const { spawnSync } = require('node:child_process');
const args = process.argv.slice(2);
const gate = process.env.FETCH_GATE;
if (args.includes('fetch') && (process.env.FETCH_KIND === 'writer' ? args[0] === '--git-dir' : args.some(x => x.endsWith(':refs/look-bench/after')))) {
  fs.writeFileSync(gate + '.entering', JSON.stringify({ args, pid: process.pid }));
  fs.renameSync(gate + '.entering', gate + '.entered');
  const deadline = Date.now() + 40000;
  while (!fs.existsSync(gate + '.release')) {
    if (!process.env.FETCH_HOLD_UNTIL_RELEASE && Date.now() >= deadline) process.exit(55);
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 25);
  }
}
const result = spawnSync(process.env.PC_REAL_GIT, args, { stdio: 'inherit', windowsHide: true });
process.exit(result.status ?? 99);
`);

  const benchGate = path.join(tmp, 'bench');
  const reader = ps('runner_common.ps1', ['look-bench-checkout', pins], { PC_TEST_GIT: benchShim, FETCH_GATE: benchGate, FETCH_KIND: 'bench' });
  try {
    await waitFor(benchGate + '.entered', reader);
    const { args } = JSON.parse(read(benchGate + '.entered'));
    assert(args.includes(mirror), 'fixture delayed a fetch FROM the shared mirror');
    assert.deepEqual(args.slice(args.indexOf(mirror) + 1), [`+${after}:refs/look-bench/after`]);
    pass(await lane('during-bench-fetch', { PC_MIRROR_LOCK_WAIT_SECONDS: '2' }).done);
    assert(!reader.finished && !fs.existsSync(pins), 'lane checkout completed before the bench fetch was unblocked');
  } finally {
    write(benchGate + '.release');
    pass(await reader.done);
  }
  assert.equal(read(pins), `${after} ${before}`);
  assert.equal(git('-C', path.join(bench, 'tool'), 'rev-parse', 'HEAD'), tool);
  for (const [folder, refs] of [['tool', ['refs/look-bench/tool']], ['repo', ['refs/look-bench/after', 'refs/look-bench/before']]]) {
    const checkout = path.join(bench, folder);
    assert(!fs.existsSync(path.join(checkout, '.git/objects/info/alternates')), 'bench does not borrow objects');
    assert.deepEqual(git('-C', checkout, 'for-each-ref', '--format=%(refname)').split(/\r?\n/), refs);
    const pack = fs.readdirSync(path.join(mirror, 'objects/pack')).find(file => file.endsWith('.pack'));
    const shared = fs.statSync(path.join(mirror, 'objects/pack', pack), { bigint: true });
    const local = fs.statSync(path.join(checkout, '.git/objects/pack', pack), { bigint: true });
    assert.equal(local.ino, shared.ino, 'the checkout hardlinks the mirror pack');
    assert(local.nlink > 1n, 'pack is linked, not copied');
  }
  console.log('PASS lane checkout finished while the look bench fetch was still gated, with only three pins and hardlinked packs');
  if (windows) batchProof(after, before);

  const legacyBench = path.join(tmp, 'legacy bench');
  for (const folder of ['tool', 'repo']) {
    const checkout = path.join(legacyBench, folder);
    git('init', '-q', checkout);
    write(path.join(checkout, '.git/objects/info/alternates'), path.join(mirror, 'objects').replaceAll('\\', '/') + '\n');
  }
  const pruneEnv = { LB_HOME: legacyBench, LB_TOOL_REF: prunableBefore, AFTER: 'bench-prunable', BEFORE: prunableBefore };
  pass(await ps('runner_common.ps1', ['look-bench-checkout', pins], pruneEnv).done);
  assert.equal(read(pins), `${prunableAfter} ${prunableBefore}`);

  git('--git-dir', source, 'update-ref', '-d', 'refs/heads/bench-prunable');
  git('--git-dir', mirror, 'fetch', '-q', '--prune', '--no-auto-maintenance', 'origin');
  git('--git-dir', mirror, 'gc', '--prune=now');
  const mirrorObjects = git('--git-dir', mirror, 'cat-file', '--batch-check=%(objectname)', '--batch-all-objects').split(/\r?\n/);
  for (const sha of [prunableAfter, prunableBefore]) {
    assert(!mirrorObjects.includes(sha), 'mirror GC really removed the pin');
  }
  const prunedRepo = path.join(legacyBench, 'repo');
  for (const [slot, sha] of [['after', prunableAfter], ['before', prunableBefore]]) {
    assert.equal(git('-C', prunedRepo, 'rev-parse', `refs/look-bench/${slot}`), sha);
    git('-C', prunedRepo, 'checkout', '-q', '-f', '--detach', sha);
    assert.equal(read(path.join(prunedRepo, 'prune-proof.txt')), slot);
  }
  const prunedTool = path.join(legacyBench, 'tool');
  git('-C', prunedTool, 'checkout', '-q', '-f', '--detach', prunableBefore);
  assert.equal(read(path.join(prunedTool, 'prune-proof.txt')), 'before');
  console.log('PASS tool, AFTER and BEFORE still check out after the source branch is deleted and the mirror prunes and runs GC');

  git('-C', seed, 'commit', '-q', '--allow-empty', '-m', 'not in mirror');
  const ahead = git('-C', seed, 'rev-parse', 'HEAD');
  git('-C', seed, 'push', '-q', source, 'HEAD:refs/heads/bench-ahead');
  pass(await ps('runner_common.ps1', ['look-bench-checkout', pins], { AFTER: 'bench-ahead', BEFORE: 'none', LB_TOOL_REF: tool }).done);
  assert.equal(read(pins), `${ahead} none`);
  assert.equal(git('--git-dir', mirror, 'for-each-ref', '--format=%(refname)', 'refs/heads/bench-ahead'), '');
  assert.equal(git('-C', path.join(bench, 'repo'), 'rev-parse', 'refs/look-bench/after'), ahead);
  console.log('PASS a mirror miss fetches only the selected pin from origin into the bench checkout');

  const writerGate = path.join(tmp, 'writer');
  // The writer reaches the gate only after recording its owner. Keep it there until both waiters finish.
  // Give the holder more time than gate discovery plus the two concurrently started waiters.
  const writer = lane('held-writer', {
    PC_TEST_GIT: shim, FETCH_GATE: writerGate, FETCH_KIND: 'writer', FETCH_HOLD_UNTIL_RELEASE: '1',
  }, 120000);
  try {
    await waitFor(writerGate + '.entered', writer);
    const owner = JSON.parse(read(mirror + '.lock.owner'));
    const waiting = { PC_MIRROR_LOCK_WAIT_SECONDS: '0' };
    const results = await Promise.all([lane('blocked-waiter', waiting).done, helper('blocked-helper', waiting).done]);
    assert(!writer.finished, 'writer has not exited before the waiters read its owner');
    assert.deepEqual(JSON.parse(read(mirror + '.lock.owner')), owner, 'writer still holds the recorded lock');
    for (const result of results) {
      assert.notEqual(result.code, 0, result.text);
      assert(result.text.includes(`PID ${owner.pid}, job fixture/held-writer, command git fetch --prune origin, since ${owner.since}`), result.text);
    }
  } finally {
    write(writerGate + '.release');
    pass(await writer.done);
  }
  const cappedGate = path.join(tmp, 'capped');
  const capped = await helper('capped-helper', {
    PC_TEST_GIT: shim, FETCH_GATE: cappedGate, FETCH_KIND: 'writer', PC_TEST_MIRROR_FETCH_SECONDS: '3',
  }).done;
  assert.notEqual(capped.code, 0, capped.text);
  assert.match(capped.text, /mirror fetch failed \(timed out after 3 s\)/);
  const killed = JSON.parse(read(cappedGate + '.entered')).pid;
  assert.throws(() => process.kill(killed, 0), e => e.code === 'ESRCH', 'timed-out fetch process is gone');
  assert.equal(read(mirror + '.lock.owner'), '', 'a released lock does not leave a live owner record');
  pass(await helper('after-capped-helper').done);
  console.log('PASS both waiters name the actual lock holder, and a capped fetch stops before another helper takes the lock');
}

main().then(() => fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 4 }))
  .catch(error => { console.error(error); console.error(`Evidence kept in ${tmp}`); process.exitCode = 1; });
