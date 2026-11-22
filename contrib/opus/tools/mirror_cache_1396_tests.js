'use strict';
// Issue 1396 (Artoo on PR 1592): the janitor reuses the mirror's commit list within a run, but a fetch or prune in
// between can drop the ref that made a checkout's commit safe to lose. The reuse must end when the mirror's refs change.
// Real Git, the real Get-RepoCleanupState from tools/pc/runner_common.ps1, a mirror whose side branch is deleted between
// two checks of the same checkout.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '../../..');
const windows = process.platform === 'win32';
const shell = windows ? 'powershell.exe' : 'pwsh';
const probe = spawnSync(shell, ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.Major'], { encoding: 'utf8' });
if (probe.error || probe.status !== 0) {
  if (process.env.CI && !windows) throw new Error(`${shell} is required in CI`);
  console.log(`SKIP mirror_cache_1396_tests: ${shell} not found`);
  process.exit(0);
}

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'mirror1396-'));
const git = (cwd, ...words) => {
  const r = spawnSync('git', words, { cwd, encoding: 'utf8', env: { ...process.env, GIT_AUTHOR_NAME: 't', GIT_AUTHOR_EMAIL: 't@example.invalid', GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@example.invalid' } });
  assert.equal(r.status, 0, `git ${words.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
};
const mirror = path.join(tmp, 'mirror.git');
const work = path.join(tmp, 'work');
const co = path.join(tmp, 'co');
git(tmp, 'init', '-q', '--bare', mirror);
git(tmp, 'init', '-q', '-b', 'main', work);
fs.writeFileSync(path.join(work, 'a.txt'), 'a\n');
git(work, 'add', 'a.txt'); git(work, 'commit', '-q', '-m', 'A');
git(work, 'push', '-q', mirror, 'main');
git(work, 'checkout', '-q', '-b', 'side');
fs.writeFileSync(path.join(work, 'b.txt'), 'b\n');
git(work, 'add', 'b.txt'); git(work, 'commit', '-q', '-m', 'B');
const sideCommit = git(work, 'rev-parse', 'HEAD');
git(work, 'push', '-q', mirror, 'side');
git(tmp, 'clone', '-q', '--branch', 'side', mirror, co);

const script = path.join(tmp, 'probe.ps1');
fs.writeFileSync(script, [
  'function Log($line) { }',
  `. '${path.join(ROOT, 'tools', 'pc', 'runner_common.ps1').replace(/'/g, "''")}' cleanup-library`,
  '$co = $env:M1396_CO; $mirror = $env:M1396_MIRROR',
  '$script:cacheMirrorCommits = $true',
  'function Check($label) {',
  '  try { $null = Get-RepoCleanupState $co $mirror \'\' $false $true; Write-Output "$label ok" }',
  '  catch { Write-Output "$label refused: $($_.Exception.Message)" }',
  '}',
  'Check first',
  'Check same-refs',
  '$null = Git @(\'--git-dir\', $mirror, \'update-ref\', \'-d\', \'refs/heads/side\')',
  'Check after-prune',
  '$script:cacheMirrorCommits = $false; $script:mirrorCommitCache = $null',
  'Check uncached',
].join('\r\n'));
const r = spawnSync(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script], {
  encoding: 'utf8', env: { ...process.env, M1396_CO: co, M1396_MIRROR: mirror, PC_RUNNER_TEST: '' }, timeout: 120000,
});
const out = (r.stdout || '') + (r.stderr || '');
assert.equal(r.status, 0, out);
assert.match(out, /^first ok$/m, out);
assert.match(out, /^same-refs ok$/m, out);
assert.match(out, new RegExp(`^after-prune refused: local history not in fetched mirror: ${sideCommit}`, 'm'), 'a pruned ref ends the reuse: ' + out);
assert.match(out, new RegExp(`^uncached refused: local history not in fetched mirror: ${sideCommit}`, 'm'), 'the uncached path agrees: ' + out);
fs.rmSync(tmp, { recursive: true, force: true });
console.log('PASS mirror_cache_1396_tests: the reused mirror commit list ends when a ref is pruned, so a commit only the pruned ref held keeps its checkout');
