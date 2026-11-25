'use strict';
// Preview the two storage tools on tiny temp repos. No network or live PC cleanup.
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
  PC_TEST_JANITOR_NOW: '2026-11-25T09:30:00Z', PC_JANITOR_CAP_SECONDS: '0',
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
  run('git', '-C', seed, 'commit', '-q', '--allow-empty', '-m', 'seed');
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
  console.log('PASS: compact and janitor preview count cached refs, preserve all refs and logs, and respect the Board keep list');
} finally {
  fs.rmSync(temp, { recursive: true, force: true, maxRetries: 3 });
}
