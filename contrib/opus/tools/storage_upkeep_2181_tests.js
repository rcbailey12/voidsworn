'use strict';
// Exercise the storage tools on tiny temp repos. No network or live PC cleanup.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const shell = process.platform === 'win32' ? 'powershell.exe' : 'pwsh';
if (spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).error) {
  if (process.env.CI) throw new Error(shell + ' is required in CI');
  console.log('SKIP storage_upkeep_2181_tests: needs PowerShell');
  process.exit(0);
}
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'storage-2181-'));
const root = path.join(temp, 'Downloads', 'voidsworn_test');
const mirror = path.join(root, 'repo-mirror.git');
const gitDir = path.join(root, 'board_f', 'repo', '.git');
const scratch = path.join(temp, 'scratch');
const env = {
  ...process.env, USERPROFILE: temp, TEMP: scratch, TMP: scratch, TMPDIR: scratch,
  PC_RUNNER_TEST: '1', PC_TEST_MIRROR: mirror, PC_TEST_GIT: '', PC_TEST_COMMAND_LINES: 'fixture',
  PC_TEST_JANITOR_NOW: '2026-11-25T09:30:00Z', PC_JANITOR_CAP_SECONDS: '0', PC_2181_TOOLS: pc,
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
  GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid',
};
function run(exe, ...args) {
  const r = spawnSync(exe, args, { env, cwd: temp, encoding: 'utf8', windowsHide: true, timeout: 30000 });
  assert.equal(r.status, 0, r.error || (r.stdout + r.stderr));
  return r.stdout.trim();
}
const ps = (script, ...args) => run(shell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, script), ...args);
try {
  fs.mkdirSync(scratch);
  const seed = path.join(temp, 'seed');
  run('git', 'init', '-q', '-b', 'main', seed);
  fs.writeFileSync(path.join(seed, 'done.txt'), 'PASS\n');
  fs.writeFileSync(path.join(seed, 'proof.png'), 'relayed picture');
  run('git', '-C', seed, 'add', 'done.txt', 'proof.png');
  run('git', '-C', seed, 'commit', '-q', '-m', 'seed');
  const tip = run('git', '-C', seed, 'rev-parse', 'HEAD');
  fs.mkdirSync(root, { recursive: true });
  run('git', 'clone', '-q', '--mirror', seed, mirror);
  run('git', '--git-dir', mirror, 'update-ref', 'refs/pull/9/head', tip);
  run('git', '--git-dir', mirror, 'update-ref', 'refs/heads/board/pc-out-cached', tip);
  fs.mkdirSync(path.dirname(gitDir), { recursive: true });
  run('git', 'clone', '-q', seed, path.dirname(gitDir));
  run('git', '--git-dir', gitDir, 'update-ref', 'refs/remotes/origin/board/pc-out-cached', tip);
  const refs = dir => run('git', '--git-dir', dir, 'show-ref');
  const originalRefs = [refs(mirror), refs(gitDir)];
  const before = ps('compact_repos.ps1', '-Root', root);
  assert.match(before, /DRY RUN: nothing will change/);
  assert.match(before, /1 cached PR refs to drop, 1 legacy heads \(live drops only upstream-pruned, proven copies\)/);
  assert.match(before, /board_f\/repo : 1 copied legacy refs/);
  assert.deepEqual([refs(mirror), refs(gitDir)], originalRefs);

  const old = 'janitor_20261001-0330.txt', kept = 'janitor_20261002-0330.txt';
  const fresh = 'janitor_20261120-0330.txt', unrelated = 'janitor_notes.txt';
  for (const [name, date] of [[old, '2026-10-01'], [kept, '2026-10-02'], [fresh, '2026-11-20'], [unrelated, '2026-10-01']]) {
    const file = path.join(root, name);
    fs.writeFileSync(file, name);
    fs.utimesSync(file, new Date(date), new Date(date));
  }
  fs.writeFileSync(path.join(root, 'janitor_keep.txt'), path.join(root, kept) + '\n');
  const log = ps('janitor.ps1', '--dry-run');
  assert.match(log, /would remove old janitor log: janitor_20261001-0330\.txt/);
  assert.doesNotMatch(log, /would remove old janitor log: (?:janitor_20261002|janitor_20261120|janitor_notes)/);
  assert.match(log, /would run nightly git gc under the mirror lock: .*repo-mirror\.git/);
  for (const name of [old, kept, fresh, unrelated]) assert.equal(fs.readFileSync(path.join(root, name), 'utf8'), name);
  assert(!fs.existsSync(mirror + '.lock'), 'previews never take the mirror lock');
  assert.deepEqual([refs(mirror), refs(gitDir)], originalRefs);

  // Use the seed as the confirmed origin. The relay ref exists in both temp repos, with no push.
  const ref = 'refs/heads/board/pc-out-fixture';
  run('git', '-C', seed, 'update-ref', ref, tip);
  run('git', '--git-dir', mirror, 'update-ref', ref, tip);
  const helper = path.join(root, 'opus2181');
  const out = path.join(helper, 'out');
  fs.mkdirSync(out, { recursive: true });
  fs.copyFileSync(path.join(seed, 'done.txt'), path.join(helper, 'done.txt'));
  fs.copyFileSync(path.join(seed, 'proof.png'), path.join(out, 'proof.png'));
  const harness = path.join(temp, 'helper-race.ps1');
  fs.writeFileSync(harness, `
$source = [IO.File]::ReadAllText((Join-Path $env:PC_2181_TOOLS 'janitor.ps1'))
$definitions = $source.Substring(0, $source.IndexOf([string][char]10 + '$trigger = $args[0]')).Replace('$PSScriptRoot', '$env:PC_2181_TOOLS')
. ([scriptblock]::Create($definitions))
$env:PC_TEST_SOURCE = Join-Path $env:USERPROFILE 'seed'
$root = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'
$script:commandLines = Get-CommandLines
$originalProof = (Get-Command Test-RelayedResults -CommandType Function).ScriptBlock
function Test-RelayedResults($dir, $mirror, $finishedHelper, $dryRun) {
  if (-not $finishedHelper) { throw 'fixture must take the finished helper path' }
  & $originalProof $dir $mirror $finishedHelper $dryRun
  $out = Get-Item -LiteralPath (Join-Path $dir.FullName 'out')
  $stamp = $out.LastWriteTimeUtc
  $added = Join-Path $out.FullName 'late.png'
  [IO.File]::WriteAllText($added, 'unrelayed picture')
  [IO.File]::SetLastWriteTimeUtc($added, $stamp.AddDays(-1))
  [IO.Directory]::SetLastWriteTimeUtc($out.FullName, $stamp)
}
$dir = Get-Item -LiteralPath (Join-Path $root 'opus2181')
Clear-ScratchFolder $dir '' 'helper folder with its results relayed' 24 $env:TEMP ([DateTime]::UtcNow) $false @() -Helper -Mirror $env:PC_TEST_MIRROR
`);
  const race = run(shell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', harness);
  assert.match(race, /kept .*opus2181 \(.*results changed during relay proof\)/);
  assert.equal(fs.readFileSync(path.join(out, 'late.png'), 'utf8'), 'unrelayed picture');
  assert.equal(fs.readFileSync(path.join(out, 'proof.png'), 'utf8'), 'relayed picture');

  console.log('PASS: storage previews keep refs and protected logs, and a late file keeps a finished helper folder');
} finally {
  fs.rmSync(temp, { recursive: true, force: true, maxRetries: 3 });
}
