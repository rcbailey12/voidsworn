'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const windows = process.platform === 'win32';
const common = path.resolve(__dirname, '../../../tools/pc/runner_common.ps1');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner-cleanup-proof-'));
const temp = path.join(root, 'temp'), board = path.join(root, 'board');
const mirror = path.join(root, 'mirror.git'), repo = path.join(board, 'repo');
const profile = path.join(root, 'profile'), flag = path.join(profile, 'Downloads', 'voidsworn_test', 'gpu_go.txt');
const env = { ...process.env, USERPROFILE: profile, PC_RUNNER_TEST: '1', PC_RUN_TEMP: temp, PC_TEST_MIRROR: mirror, PC_TEST_GIT: '' };
function write(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, value);
}
function read(file) { return fs.readFileSync(file, 'utf8'); }
function execute(exe, args, input, extra = {}) {
  const r = spawnSync(exe, args, { input, cwd: root, env: { ...env, ...extra }, encoding: 'utf8', windowsHide: true, timeout: 30000 });
  if (r.error) throw r.error;
  assert.equal(r.status, 0, `${exe} ${args.join(' ')}: ${r.stdout}\n${r.stderr}`);
  return r.stdout.trim();
}
const git = (args, input) => execute('git', args, input);
function shared(args, scratch = '') {
  const scratchEnv = scratch ? { TEMP: scratch, TMP: scratch, TMPDIR: scratch } : {};
  execute(windows ? 'powershell.exe' : 'pwsh', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', common, ...args], undefined,
    { ...scratchEnv, PC_RUN_SCRATCH: scratch });
}
function start(name) {
  const out = path.join(root, name);
  fs.mkdirSync(out);
  shared(['init', out, 'fixture/cleanup']);
  shared(['scratch', out]);
  const scratch = read(path.join(out, 'scratch_path.txt')).trim();
  assert.equal(path.dirname(scratch), temp);
  assert.equal(JSON.parse(read(path.join(out, 'status.json'))).scratch.path, scratch);
  write(path.join(scratch, 'nested', 'proof.txt'), name);
  return { out, scratch };
}
function finish(run, { partial = '', push = 'real', checks = '1', confirmed = true, selected = run.scratch, checkout = '' } = {}) {
  write(path.join(run.out, 'run_commit.txt'), 'a'.repeat(40));
  if (confirmed) write(path.join(run.out, 'confirmed_commit.txt'), 'a'.repeat(40));
  shared(['finish', run.out, '0', partial, push, checks, checkout], selected);
  return read(path.join(run.out, 'result.txt'));
}
const keep = run => assert(fs.existsSync(path.join(run.scratch, 'nested', 'proof.txt')), run.out);
function makeCopy(name, age) {
  const dir = path.join(board, name);
  git(['clone', '-q', '-c', 'core.autocrlf=false', mirror, dir]);
  const date = new Date(Date.UTC(2026, 0, age));
  fs.utimesSync(dir, date, date);
  return dir;
}
try {
  fs.mkdirSync(temp);
  const other = path.join(temp, 'voidsworn-run-other');
  write(path.join(other, 'proof.txt'), 'unrelated scratch');
  const real = start('checked');
  const insufficient = [
    ['dry', { push: 'dry' }], ['test-push', { push: 'test' }],
    ['partial', { partial: 'agent interrupted' }], ['failed-checks', { checks: '0' }],
    ['unconfirmed', { confirmed: false }], ['mismatched-path', { selected: other }]
  ];
  for (const [name, options] of insufficient) {
    const run = start(name);
    finish(run, options);
    keep(run);
  }
  fs.mkdirSync(board);
  git(['init', '--bare', '-q', mirror]);
  const tree = git(['--git-dir', mirror, 'mktree'], '');
  const author = 'author Fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Fixture <fixture@example.invalid> 1700000000 +0000';
  const commit = (dir, message, parent = '') => git(['--git-dir', dir, 'hash-object', '-t', 'commit', '-w', '--stdin'],
    `tree ${tree}\n${parent ? `parent ${parent}\n` : ''}${author}\n\n${message}\n`);
  const main = commit(mirror, 'shared history');
  git(['--git-dir', mirror, 'update-ref', 'refs/heads/main', main]);
  git(['--git-dir', mirror, 'symbolic-ref', 'HEAD', 'refs/heads/main']);
  makeCopy('repo', 1);
  const rebuildable = makeCopy('repo-kept-caches', 1);
  write(path.join(rebuildable, '.git', 'info', 'exclude'), '/godot/.godot/\n');
  write(path.join(rebuildable, 'godot', '.godot', 'test.cache'), 'rebuildable');
  const clean = makeCopy('repo-kept-clean', 2);
  const dirty = makeCopy('repo-kept-untracked', 3);
  write(path.join(dirty, 'work.txt'), 'local work');
  const staged = makeCopy('repo-kept-staged', 4);
  write(path.join(staged, 'staged.txt'), 'staged work');
  git(['-C', staged, 'add', 'staged.txt']);
  const history = makeCopy('repo-kept-history', 4);
  const local = commit(path.join(history, '.git'), 'local work in a commit', main);
  git(['-C', history, 'update-ref', 'refs/heads/main', local]);
  const invalid = path.join(board, 'repo-kept-invalid');
  write(path.join(invalid, 'proof.txt'), 'same name, no Git checkout');
  fs.utimesSync(invalid, new Date(2020, 0, 1), new Date(2020, 0, 1));
  const linked = makeCopy('repo-kept-linked', 5);
  fs.symlinkSync(other, path.join(linked, 'external'), windows ? 'junction' : 'dir');
  const newest = makeCopy('repo-kept-newest', 28);
  const noncandidate = makeCopy('repo-clone-failed-older', 1);
  // Files created at the top of a kept checkout also change its directory timestamp.
  fs.utimesSync(newest, new Date(2030, 0, 1), new Date(2030, 0, 1));
  const boardPaused = start('board-paused');
  write(flag, 'GPU not cleared: paused by the Board at 12:30');
  assert.match(finish(boardPaused, { checkout: repo }), /cleanup skipped during the PC pause/);
  assert(fs.existsSync(rebuildable) && fs.existsSync(clean));
  keep(boardPaused);
  write(flag, 'GPU cleared');
  const log = finish(real, { checkout: repo });
  assert.match(log, /run scratch removed/);
  assert(!fs.existsSync(real.scratch));
  assert(!fs.existsSync(rebuildable) && !fs.existsSync(clean), log);
  assert.match(log, /kept checkout removed \(rebuildable\): .*repo-kept-caches/);
  assert.match(log, /kept checkout removed \(rebuildable\): .*repo-kept-clean/);
  assert.match(log, /kept checkout retained \(newest\): .*repo-kept-newest/);
  assert.match(log, /repo-kept-history.*local history not in fetched mirror/);
  assert.match(log, /repo-kept-untracked.*working tree needs keeping/);
  assert.match(log, /repo-kept-staged.*working tree needs keeping/);
  assert.match(log, /repo-kept-invalid.*not a standalone checkout/);
  assert.match(log, /repo-kept-linked.*linked path/);
  assert.equal(git(['-C', history, 'rev-parse', 'HEAD']), local);
  assert.equal(read(path.join(dirty, 'work.txt')), 'local work');
  assert.equal(read(path.join(staged, 'staged.txt')), 'staged work');
  assert.equal(read(path.join(invalid, 'proof.txt')), 'same name, no Git checkout');
  assert.equal(read(path.join(other, 'proof.txt')), 'unrelated scratch');
  for (const dir of [repo, newest, noncandidate, linked]) assert(fs.existsSync(dir), dir);
  console.log('PASS runner cleanup: checked push only, private scratch, pause, and kept checkouts with rebuildable files only');
} finally {
  fs.rmSync(root, { recursive: true, force: true, maxRetries: 3 });
}
