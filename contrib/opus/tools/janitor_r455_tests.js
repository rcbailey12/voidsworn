'use strict';
// Exercise all three R455 kinds through the real janitor against isolated TEMP and local Git remotes.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { spawnSync } = require('node:child_process');
const win = process.platform === 'win32';
const shell = win ? 'powershell.exe' : 'pwsh';
if (!win && spawnSync(shell, ['-NoProfile', '-Command', 'exit 0']).status !== 0) {
  console.log('SKIP janitor_r455_tests: PowerShell is unavailable');
  process.exit(0);
}
const sqliteArgs = ['--no-warnings', '--experimental-sqlite'];
if (spawnSync(process.execPath, [...sqliteArgs, '-e', "require('node:sqlite')"]).status !== 0) {
  console.log('SKIP janitor_r455_tests: Node SQLite is unavailable');
  process.exit(0);
}
const tools = path.resolve(__dirname, '../../../tools/pc');
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'janitor-r455-proof-'));
const profile = path.join(fixture, 'profile');
const root = path.join(profile, 'Downloads', 'voidsworn_test');
const temp = path.join(fixture, 'temp');
const source = path.join(fixture, 'origin.git');
const relay = path.join(fixture, 'relay.git');
const mirror = path.join(root, 'repo-mirror.git');
const t3 = path.join(profile, '.t3');
const workspace = path.join(root, 't3_neon');
const db = path.join(t3, 'userdata', 'statev2.sqlite');
const now = '2026-11-25T09:30:00Z';
const old = '2026-11-23T09:29:00Z';
const recent = '2026-11-25T08:30:00Z';
const sha = '0123456789abcdef';
const env = { ...process.env, USERPROFILE: profile, PC_RUNNER_TEST: '1', PC_TEST_MIRROR: mirror,
  PC_RUN_TEMP: temp, PC_RUN_SCRATCH: '', PC_TEST_JANITOR_NOW: now, PC_TEST_COMMAND_LINES: 'fixture',
  PC_TEST_HELPER: '1', PC_TEST_HELPER_VT: root, PC_TEST_SOURCE: source, PC_TEST_RELAY_SOURCE: relay, PC_TEST_GIT: '',
  GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'f@example.invalid',
  GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'f@example.invalid' };
function run(exe, args, input, extra = {}) {
  const r = spawnSync(exe, args, { input, cwd: fixture, env: { ...env, ...extra }, encoding: 'utf8', timeout: 180000, windowsHide: true });
  assert.equal(r.status, 0, `${exe} ${args.join(' ')}: ${r.error || ''}\n${r.stderr}\n${r.stdout}`);
  return r.stdout.trim();
}
const git = (...args) => run('git', args);
const ps = (file, ...args) => run(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(tools, file), ...args]);
function put(file, content) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
  return file;
}
function dateTree(file, time) {
  if (fs.statSync(file).isDirectory()) for (const leaf of fs.readdirSync(file)) dateTree(path.join(file, leaf), time);
  fs.utimesSync(file, time, time);
}
function attempt(issue, suffix, shot = 'saved picture') {
  const dir = path.join(root, `opus${issue}`, `out_20261125_032000_${suffix}`);
  put(path.join(dir, 'done.txt'), 'PASS\n');
  put(path.join(dir, 'proof.png'), shot);
  // Keep the attempt younger than a day relative to the synthetic 03:30 run.
  dateTree(dir, new Date(recent));
  return dir;
}
function publish(branch, dir) {
  assert.match(ps('relay_push.ps1', branch, dir, 'results'), /relayed:/);
}
function publishAttachment(t) {
  const stage = path.join(root, 'neon-relay-stage', t.id);
  put(path.join(stage, path.basename(t.attachment)), fs.readFileSync(t.attachment));
  publish(t.branch.replace('/', '-'), stage);
}
function thread(issue, state, finished, pushed = true) {
  const branch = `neon/issue-${issue}`;
  const local = path.join(t3, 'worktrees', 't3_neon', `neon-issue-${issue}-${sha}`);
  git('-C', workspace, 'worktree', 'add', '-qb', branch, local, 'HEAD');
  if (pushed) git('-C', workspace, 'push', '-q', 'origin', branch);
  else {
    put(path.join(local, 'not-on-origin.txt'), 'local work');
    git('-C', local, 'add', '.');
    git('-C', local, 'commit', '-qm', 'local only');
  }
  dateTree(local, new Date(old));
  const id = `12345678-1234-4567-89ab-${String(issue).padStart(12, '0')}`;
  const attachment = put(path.join(t3, 'userdata', 'attachments', id, 'attachment.png'), `thread ${issue} picture`);
  dateTree(path.dirname(attachment), new Date(old));
  const log = put(path.join(t3, 'userdata', 'logs', 'provider', `events.${id}.log`), 'thread log');
  dateTree(log, new Date(old));
  return { local, branch, id, state, finished, attachment, log };
}
try {
  fs.mkdirSync(root, { recursive: true });
  fs.mkdirSync(temp);
  git('init', '-q', '--bare', relay);
  git('init', '-q', '--bare', source);
  git('init', '-q', '-b', 'main', workspace);
  put(path.join(workspace, 'tracked.txt'), 'tracked');
  put(path.join(workspace, '.gitignore'), 'godot/gen/\ngodot/assets/ships/*/\n');
  git('-C', workspace, 'add', '.');
  git('-C', workspace, 'commit', '-qm', 'fixture');
  git('-C', workspace, 'remote', 'add', 'origin', source);
  git('-C', workspace, 'push', '-q', 'origin', 'main');
  git('--git-dir', source, 'symbolic-ref', 'HEAD', 'refs/heads/main');
  git('clone', '-q', '--mirror', source, mirror);

  const saved = attempt(455, 1);
  put(path.join(saved, 'out_scene', 'shader_cache', 'generated.bin'), Buffer.alloc(4096));
  publish('opus455', saved);
  const big = attempt(455, 2);
  put(path.join(big, 'out_scene', 'large.png'), Buffer.alloc(11 * 1024 * 1024));
  publish('opus455', big);
  const changed = attempt(456, 1);
  publish('opus456', changed);
  put(path.join(changed, 'proof.png'), 'new local bytes');
  const activeJob = attempt(457, 1);
  publish('opus457', activeJob);
  const keptJob = attempt(458, 1);
  publish('opus458', keptJob);
  const wholeJob = path.join(root, 'opus460');
  put(path.join(wholeJob, 'done.txt'), 'PASS\n');
  put(path.join(wholeJob, 'out', 'picture.png'), 'finished job picture');
  publish('opus460', wholeJob);
  const staleWholeJob = path.join(root, 'opus464');
  put(path.join(staleWholeJob, 'done.txt'), 'PASS\n');
  put(path.join(staleWholeJob, 'out', 'picture.png'), 'only on the stale relay tip');
  publish('opus464', staleWholeJob);
  git('--git-dir', relay, 'update-ref', '-d', 'refs/heads/pc-out-opus464');
  const takes = attempt(461, 1);
  put(path.join(takes, 'out_audio', 'manifest.jsonl'), '{}\n');
  put(path.join(takes, 'out_audio', 'receipts.jsonl'), '{}\n');
  put(path.join(takes, 'out_audio', 'take_01.mp3'), 'paid take');
  publish('opus461', takes);
  const codexOut = path.join(root, 'board_f', 'issue-2144');
  const codexShots = path.join(codexOut, 'shots');
  put(path.join(codexShots, 'review.png'), 'Codex review picture');
  const runnerStatus = put(path.join(codexOut, 'status.json'), JSON.stringify({
    status: 'checked_push', finished: recent, scratch: { path: path.join(temp, 'missing') }
  }));
  publish('codex-board_f-2144', codexShots);
  const bench = path.join(root, 'look_bench', 'runs', '01234567');
  put(path.join(bench, 'DONE.txt'), '01234567\n');
  put(path.join(bench, 'capture.png'), 'bench picture');
  publish('look-bench-runs', bench);

  function heldSlot(n, unique) {
    const slot = path.join(root, 'slots', `slot_gpu_${n}`);
    const repo = path.join(slot, 'repo');
    fs.mkdirSync(slot, { recursive: true });
    git('clone', '-q', mirror, repo);
    const use = attempt(468, n);
    const ship = 'assets/ships/proof/proof.glb';
    const shipSource = path.join(root, 'build', 'godot');
    const bytes = Buffer.alloc(4096, 23);
    put(path.join(shipSource, ship), bytes);
    put(path.join(repo, 'godot', ship), bytes);
    // Old held slots have the issue 1497 receipt in the attempt, but no receipt in the slot itself.
    put(path.join(use, 'new_ships_copied.txt'), `${createHash('sha256').update(bytes).digest('hex')} ${bytes.length} godot/${ship}\n`);
    put(path.join(repo, 'godot', ship + '.uid'), 'uid://fixture');
    put(path.join(repo, 'godot', ship + '.import'), 'generated import sidecar');
    put(path.join(repo, 'godot', 'assets', 'ships', 'proof', 'proof.scn'), 'generated scene');
    put(path.join(repo, 'godot', 'gen', 'proof.res'), 'generated cache');
    if (unique) put(path.join(repo, 'godot', 'unique.res'), 'not a cache');
    put(path.join(slot, 'last_use.txt'), `attempt ${use}\nname new\n`);
    return put(path.join(slot, 'hold.txt'), `the last job's leftovers in ${repo} could not be saved (over the cap); the slot is kept as it is\nlast use: ${use} new\nThe Board removes this file once it has looked.\n`);
  }
  const safeHold = heldSlot(1, false);
  const uniqueHold = heldSlot(2, true);
  put(path.join(root, 'build', 'godot', 'assets', 'ships', 'proof', 'proof.glb'), 'shared build changed');

  const eligible = thread(455, 'completed', old);
  publishAttachment(eligible);
  const busy = thread(456, 'running', old);
  const fresh = thread(457, 'completed', recent);
  const unpushed = thread(458, 'completed', old, false);
  const dirty = thread(459, 'completed', old);
  put(path.join(dirty.local, 'untracked.txt'), 'keep');
  const notRelayed = thread(460, 'completed', old);
  const changedAttachment = thread(461, 'completed', old);
  publishAttachment(changedAttachment);
  put(changedAttachment.attachment, 'different local picture');
  dateTree(path.dirname(changedAttachment.attachment), new Date(old));
  const partialAttachment = thread(462, 'completed', old);
  publishAttachment(partialAttachment);
  const extraPicture = put(path.join(path.dirname(partialAttachment.attachment), 'nested', 'extra.png'), 'local only');
  dateTree(path.dirname(partialAttachment.attachment), new Date(old));
  const staleAttachment = thread(463, 'completed', old);
  publishAttachment(staleAttachment);
  git('--git-dir', relay, 'update-ref', '-d', 'refs/heads/pc-out-neon-issue-463');
  git('--git-dir', path.join(root, 'relay-mirror.git'), 'rev-parse', '--verify', 'refs/heads/pc-out-neon-issue-463');
  const threads = [eligible, busy, fresh, unpushed, dirty, notRelayed, changedAttachment, partialAttachment, staleAttachment];
  const settings = put(path.join(t3, 'userdata', 'settings.json'), 'settings stay');
  const signIn = put(path.join(t3, 'userdata', 'secrets', 'fixture'), 'sign-in stays');
  run(process.execPath, [...sqliteArgs, '-e', `
    const { DatabaseSync } = require('node:sqlite');
    const fs = require('node:fs');
    const d = new DatabaseSync(process.argv[1]);
    const f = JSON.parse(fs.readFileSync(0, 'utf8'));
    d.exec(\`
      CREATE TABLE projection_projects (project_id TEXT, workspace_root TEXT);
      CREATE TABLE orchestration_v2_projection_threads (thread_id TEXT, project_id TEXT, payload_json TEXT, archived_at TEXT, deleted_at TEXT, updated_at TEXT);
      CREATE TABLE orchestration_v2_projection_runs (thread_id TEXT, status TEXT, completed_at TEXT);
      CREATE TABLE orchestration_v2_projection_provider_turns (thread_id TEXT, status TEXT, completed_at TEXT);
      CREATE TABLE orchestration_v2_projection_provider_threads (thread_id TEXT, status TEXT);
      CREATE TABLE orchestration_v2_thread_launch_workflows (thread_id TEXT, status TEXT);
      CREATE TABLE projection_thread_sessions (thread_id TEXT, status TEXT, active_turn_id TEXT);
    \`);
    d.prepare("INSERT INTO projection_projects VALUES ('neon', ?)").run(f.workspace);
    for (const t of f.threads) {
      d.prepare("INSERT INTO orchestration_v2_projection_threads VALUES (?,'neon',?,?,NULL,?)").run(t.id,
        JSON.stringify({ worktreePath: t.local, branch: t.branch }), t.finished, t.finished);
      d.prepare("INSERT INTO orchestration_v2_projection_runs VALUES (?,?,?)").run(t.id, t.state,
        t.state === 'running' ? null : t.finished);
    }
    d.close();
  `, db], JSON.stringify({ workspace, threads }));

  const scratch = path.join(temp, 'voidsworn-run-2144-' + 'c'.repeat(32));
  put(path.join(scratch, '.voidsworn-run-owner'), 'a'.repeat(32));
  put(path.join(scratch, 'nested', 'run.bin'), Buffer.alloc(4096));
  dateTree(scratch, new Date(old));
  put(path.join(root, 'janitor_keep.txt'), keptJob + '\n');
  const active = { PC_TEST_COMMAND_LINES: `code "${path.dirname(activeJob)}"\ncmd.exe /c "${path.join(workspace, 'tools', 'pc', 'jobs', 'look_bench.bat')}"\nT3 Code (Beta).exe C:/fixture/t3code/server.asar/app` };
  const janitorArgs = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(tools, 'janitor.ps1')];
  let log = run(shell, [...janitorArgs, '--low-space'], undefined, active);
  assert.match(log, /Neon pass kept: T3 is open/);
  for (const removed of [saved, scratch, codexShots, wholeJob, safeHold]) assert(!fs.existsSync(removed), `expected low-space removal ${removed}\n${log}`);
  for (const kept of [bench, big, changed, activeJob, keptJob, takes, eligible.local, staleWholeJob, uniqueHold]) assert(fs.existsSync(kept), `expected low-space keep ${kept}\n${log}`);
  assert.match(log, /GPU slot hold released: slot_gpu_1/);
  assert.match(log, /GPU slot hold kept: slot_gpu_2 .*not proven rebuildable/);
  assert.match(log, /ElevenLabs take folder is kept/);

  const resetAttempt = attempt(469, 1);
  const slotHead = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(tools, 'jobs/opus_job_head.ps1')];
  const pin = git('--git-dir', mirror, 'rev-parse', 'HEAD');
  const slotEnv = { PC_TEST_SLOT_OWNER_PID: String(process.pid), PC_TEST_LEFTOVER_CAP: '100', OJ_SLOT_WAIT_MINUTES: '0' };
  try {
    const checkout = run(shell, [...slotHead, 'slot', resetAttempt, 'new', pin], undefined, slotEnv);
    assert.match(checkout, /slot slot_gpu_1 taken/);
    const slotRepo = path.join(path.dirname(safeHold), 'repo');
    const slotGodot = path.join(slotRepo, 'godot');
    assert(!fs.existsSync(path.join(slotGodot, 'assets', 'ships', 'proof')), 'the next reset clears the old copied hull');
    assert(!fs.existsSync(path.join(slotGodot, 'gen', 'proof.res')), 'the next reset clears generated resources');

    const shipSource = path.join(root, 'build', 'godot');
    const newGlb = path.join('assets', 'ships', 'next', 'next.glb');
    put(path.join(shipSource, newGlb), Buffer.alloc(4096, 54));
    const installed = put(path.join(slotGodot, newGlb), fs.readFileSync(path.join(shipSource, newGlb)));
    const attemptRecord = path.join(resetAttempt, 'new_ships_copied.txt');
    ps('jobs/opus_job_head.ps1', 'shiprecord', slotRepo, attemptRecord, shipSource);
    assert.match(fs.readFileSync(path.join(path.dirname(slotRepo), 'ships_copied.txt'), 'utf8'), /^last use [0-9a-f]{64}/);
    fs.unlinkSync(attemptRecord); // The per-attempt copy can go with relayed results while the warm slot stays.
    put(path.join(shipSource, newGlb), 'repainted after the install');
    run(shell, [...slotHead, 'slot', resetAttempt, 'next', pin], undefined, slotEnv);
    assert(!fs.existsSync(installed), 'the slot receipt proves the old copy after the attempt receipt is gone');
  } finally {
    if (fs.existsSync(path.join(resetAttempt, 'slot.txt'))) run(shell, [...slotHead, 'slotrelease', resetAttempt]);
  }

  log = run(shell, [...janitorArgs, '--nightly']);
  for (const removed of [bench, path.dirname(eligible.attachment), ...[eligible, notRelayed, changedAttachment, partialAttachment, staleAttachment]
    .map(t => t.local)]) assert(!fs.existsSync(removed), `expected nightly removal ${removed}\n${log}`);
  for (const kept of [busy.local, fresh.local, unpushed.local, dirty.local, settings, signIn, db, workspace, mirror, runnerStatus,
    notRelayed.attachment, changedAttachment.attachment, partialAttachment.attachment, extraPicture, staleAttachment.attachment]) {
    assert(fs.existsSync(kept), `expected nightly keep ${kept}\n${log}`);
  }
  for (const t of threads) assert.equal(fs.readFileSync(t.log, 'utf8'), 'thread log', `unproved provider log stays for ${t.id}`);
  assert.match(log, /Neon thread data kept: attachments\/.*no matching relay branch/);
  assert.match(log, /Neon thread data kept: attachments\/.*result differs on the relay/);
  assert.match(log, /Neon thread data kept: attachments\/.*unproven result stays local/);
  assert.match(log, /Neon thread data kept: attachments\/.*origin does not confirm this relay tip/);

  // Call the real cleanup path, injecting a filesystem or process change precisely after its relay proof.
  const raceGuard = path.join(root, 'race-fixture');
  const raceResult = path.join(raceGuard, 'result');
  put(path.join(raceResult, 'done.txt'), 'PASS\n');
  put(path.join(raceResult, 'proof.png'), 'race picture');
  publish('race-fixture', raceResult);
  const harness = put(path.join(fixture, 'relay-races.ps1'), `
$source = [IO.File]::ReadAllText((Join-Path $env:R455_TOOLS 'janitor.ps1'))
$definitions = $source.Substring(0, $source.IndexOf("\`n" + '$trigger = $args[0]')).Replace('$PSScriptRoot', '$env:R455_TOOLS')
. ([scriptblock]::Create($definitions))
$root = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'
$trigger = '--low-space'
$guard = Get-Item -LiteralPath (Join-Path $root 'race-fixture')
$dir = Get-Item -LiteralPath (Join-Path $guard.FullName 'result')
$relayMirror = Join-Path $root 'relay-mirror.git'
$script:commandLines = Get-CommandLines
$originalProof = (Get-Command Assert-DirectRelayProof -CommandType Function).ScriptBlock
function Assert-DirectRelayProof($dir, $branch, $relayMirror, $dryRun) {
  & $originalProof $dir $branch $relayMirror $dryRun
  if ($script:race -eq 'entry') {
    $stamp = $dir.LastWriteTimeUtc
    $added = Join-Path $dir.FullName 'unproved-empty.png'
    [IO.File]::WriteAllBytes($added, [byte[]]@())
    [IO.File]::SetLastWriteTimeUtc($added, $stamp.AddDays(-1))
    [IO.Directory]::SetLastWriteTimeUtc($dir.FullName, $stamp)
  } elseif ($script:race -eq 'process') { $env:PC_TEST_COMMAND_LINES = $dir.FullName }
}
$script:race = 'entry'
Clear-DirectRelayResult $dir $guard 'race-fixture' '\\APASS\\z' '' $false @() $env:PC_RUN_TEMP
[IO.File]::Delete((Join-Path $dir.FullName 'unproved-empty.png'))
$script:race = 'process'
Clear-DirectRelayResult $dir $guard 'race-fixture' '\\APASS\\z' '' $false @() $env:PC_RUN_TEMP
$env:PC_TEST_COMMAND_LINES = 'fixture'; $script:race = ''
# Warm the dry cache, then delete the ref on origin without touching the mirror.
$null = Get-DirectRelayTree 'race-fixture' 'result' $relayMirror $true
$gitExe = (Get-Command git -CommandType Application | Select-Object -First 1).Source
& $gitExe --git-dir $env:PC_TEST_RELAY_SOURCE update-ref -d refs/heads/pc-out-race-fixture
if ($LASTEXITCODE -ne 0) { throw 'could not remove fixture ref' }
Clear-DirectRelayResult $dir $guard 'race-fixture' '\\APASS\\z' '' $false @() $env:PC_RUN_TEMP
`);
  const races = run(shell, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', harness], undefined, { R455_TOOLS: tools });
  assert.match(races, /relayed results kept: .*results changed during relay proof/);
  assert.match(races, /relayed results kept: .*a running process names this folder/);
  assert.match(races, /relayed results kept: .*origin does not confirm this relay tip/);
  assert(fs.existsSync(path.join(raceResult, 'proof.png')), races);

  const totals = fs.readFileSync(path.join(root, 'board1119', 'janitor_log.txt'), 'utf8');
  for (const kind of ['relayed jobs and pictures', 'Neon T3', 'Codex sandbox']) {
    assert.match(totals, new RegExp(`cleanup freed - ${kind} - .+ GB \\([1-9][0-9]* bytes\\)`));
  }
  assert.match(totals, /--low-space/);
  assert.match(totals, /--nightly/);
  console.log('PASS janitor_r455_tests: schedules, fresh relays, entry/process races, Neon attachment proof and log retention, scratch, slots and per-kind totals');
} finally {
  // Only the isolated fixture from mkdtemp. Windows Git worktree roots here are plain directories.
  assert.equal(path.dirname(fixture), os.tmpdir());
  fs.rmSync(fixture, { recursive: true, force: true, maxRetries: 3 });
}
