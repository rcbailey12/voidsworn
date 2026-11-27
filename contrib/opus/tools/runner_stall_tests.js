'use strict';
// Issue 1194: test this checkout's tmo.bat, never the PC's installed tools_live copy.
process.env.TMO_OWN_COPY = '1';
// Issues 818 and 1192: portable runner checks and real Windows watchdog, process-tree and GPU claim probes.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
const { Slots } = require(path.join(pc, 'gpu_slots.js'));
const source = fs.readFileSync(path.join(pc, 'run_timeout.ps1'), 'utf8');

// Run the actual small PowerShell decision on every CI host. Only its arithmetic and variable syntax need translation.
const body = source.match(/function Get-StopReason\([^\n]+\) \{([\s\S]*?)\n\}/)[1];
const defaultStall = Number(source.match(/\$stall = (\d+(?:\.\d+)?)/)[1]);
assert.equal(defaultStall, 30);
const decide = new Function('Elapsed', 'Idle', 'Ceiling', 'StallMinutes', body
  .replace(/\$(Elapsed|Idle|Ceiling|StallMinutes)\b/g, '$1').replace(/ -ge /g, ' >= ')
  .replace('"STALLED after StallMinutes min"', '`STALLED after ${StallMinutes} min`'));
let passed = 0;
function pass(name) { passed++; console.log('PASS ' + name); }
function fakeRun(progressEvery, ceiling = 21600, stallMinutes = defaultStall) {
  let last = 0;
  for (let now = 0; now <= ceiling; now += 60) {
    if (progressEvery && now % progressEvery === 0) last = now;
    const reason = decide(now, now - last, ceiling, stallMinutes);
    if (reason) return { now, reason };
    if (now === 7260) assert.equal(reason, '', 'a busy run past two hours must continue');
  }
  throw new Error('no stop at ceiling');
}
assert.deepEqual(fakeRun(60), { now: 21600, reason: 'CEILING' });
pass('busy fake run passes two hours and stops only at six-hour ceiling');
assert.deepEqual(fakeRun(0), { now: 1800, reason: 'STALLED after 30 min' });
pass('silent fake run stops at the stall window');
assert.deepEqual(fakeRun(60, 10800), { now: 10800, reason: 'CEILING' });
assert.deepEqual(fakeRun(0, 21600, 10), { now: 600, reason: 'STALLED after 10 min' });
assert.equal(decide(21600, 1800, 21600, 30), 'CEILING');
assert.equal(decide(1799, 1799, 21600, 30), '');
pass('ceiling and stall overrides, exact boundaries, ceiling takes priority');
assert(source.includes("if ($gpuMode -eq 'solo' -and $env:PC_GPU_SOLO_MAX_S)"));

for (const [runner, cap] of [['codex_issue', 'CODEX_CAP'], ['work_issue', 'WORK_CAP']]) {
  const bat = fs.readFileSync(path.join(pc, runner + '.bat'), 'utf8');
  assert(bat.includes(`if not defined ${cap} set "${cap}=21600"`));
  assert(bat.includes('if not defined PC_GPU_WAIT_SECONDS set "PC_GPU_WAIT_SECONDS=1500"'));
  assert(1500 < defaultStall * 60);
  for (const name of ['TMO_REPO', 'TMO_OUT', 'TMO_LOG']) {
    assert(bat.includes(`set "${name}=`), runner + ' must set ' + name);
    assert(bat.includes(`set "${name}="`), runner + ' must clear ' + name);
  }
  assert(bat.indexOf('set "TMO_FATAL_PATTERN="') < bat.indexOf('contrib\\opus\\tools\\run_all_checks.js'));
  assert(bat.includes('set "TMO_FATAL_PATTERN="'));
  assert(bat.includes('stop_reason.txt'));
  assert(bat.includes('if defined PARTIAL goto :haschange'));
}
pass('both launchers bound admission below the stall limit and clear step settings before checks');

const ship = fs.readFileSync(path.join(pc, 'jobs', 'ship_job.bat'), 'utf8');
const recipe = path.resolve(pc, '../recipe');
const limits = fs.readFileSync(path.join(recipe, 'env.bat'), 'utf8');
for (const [file, settings] of [[ship, ship], ...fs.readdirSync(recipe)
  .filter(name => /^[1-7]_.*\.bat$|^install_godot\.bat$/.test(name))
  .map(name => [fs.readFileSync(path.join(recipe, name), 'utf8'), limits])]) {
  for (const line of file.split(/\r?\n/).filter(line => /\bcall\b.*tmo\.bat/i.test(line))) {
    const cap = line.match(/tmo\.bat" %([A-Z_]+_CAP)% /i);
    assert(cap, 'give the step a named cap: ' + line);
    const seconds = settings.match(new RegExp('set "' + cap[1] + '=(\\d+)"', 'ig'));
    assert.equal(seconds?.length, 1, 'define the cap once: ' + cap[1]);
    assert(Number(seconds[0].match(/=(\d+)/)[1]) <= 3600, 'oversized step: ' + line);
  }
}
assert(ship.includes('if not defined PC_GPU_WAIT_SECONDS set PC_GPU_WAIT_SECONDS=3600'));
assert(Number(ship.match(/set "SHIP_IMPORT_CAP=(\d+)"/)[1]) >= 2 * 1150, 'allow twice the measured cold Godot import');
pass('ship and recipe watchdog calls use named step caps and ship GPU admission keeps its 3600 s default');

if (process.platform !== 'win32') {
  console.log('SKIP Windows process and file probes: Windows standing checks run them');
  console.log(`PASS runner stall checks (${passed} groups)`);
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner818 '));
const pidFiles = [], helpers = [];
function alive(pid) {
  try { process.kill(pid, 0); return true; }
  catch (e) { if (e.code === 'ESRCH') return false; throw e; }
}
function agentPids() {
  return pidFiles.flatMap(file => fs.existsSync(file) ? fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).filter(Boolean).map(Number) : []);
}
// A failing assertion or a timed-out PowerShell must not leave the very processes this check is testing.
try {
const script = path.join(root, 'probes.ps1');
fs.writeFileSync(script, `
$ErrorActionPreference = 'Stop'
. (Join-Path $args[0] 'run_timeout.ps1') -LibraryOnly
function Assert($ok, $label) { if (-not $ok) { throw $label } }
$repo = Join-Path $args[1] 'repo'
$out = Join-Path $args[1] 'out'
$null = New-Item -ItemType Directory -Force -Path $repo,$out
& git.exe init -q $repo
# No commits: point HEAD at an empty tree's fixture object, just like runner_selftest.js.
$env:GIT_AUTHOR_NAME = 'Fixture'; $env:GIT_AUTHOR_EMAIL = 'fixture@example.invalid'
$env:GIT_COMMITTER_NAME = 'Fixture'; $env:GIT_COMMITTER_EMAIL = 'fixture@example.invalid'
$empty = Join-Path $args[1] 'empty'; [IO.File]::WriteAllBytes($empty, [byte[]]@())
$tree = & git.exe -C $repo hash-object -w -t tree $empty
$text = "tree $tree\nauthor Fixture <fixture@example.invalid> 1700000000 +0000\ncommitter Fixture <fixture@example.invalid> 1700000000 +0000\n\nFixture\n"
$head = $text | & git.exe -C $repo hash-object -w -t commit --stdin
[IO.File]::WriteAllText((Join-Path $repo '.git\\refs\\heads\\master'), "$head\n")
& git.exe -C $repo symbolic-ref HEAD refs/heads/master
$log = Join-Path $out 'log.txt'; [IO.File]::WriteAllText($log, '')
$before = Get-RunProgress $repo @($log)
$f = Join-Path $repo 'old-time.txt'; [IO.File]::WriteAllText($f, 'work')
(Get-Item $f).LastWriteTimeUtc = [DateTime]::UtcNow.AddYears(-1)
$after = Get-RunProgress $repo @($log)
Assert (Test-RunProgress $before $after) 'new file with old mtime must count'
$before = $after
(Get-Item $f).LastWriteTimeUtc = [DateTime]::UtcNow.AddYears(-2)
$after = Get-RunProgress $repo @($log)
Assert (Test-RunProgress $before $after) 'changed mtime below previous max must count'
$before = $after
[IO.File]::WriteAllText($log, 'last action: writing tests Z:/private fake-api-secret-818')
$after = Get-RunProgress $repo @($log)
Assert (Test-RunProgress $before $after) 'new log bytes must count'
$before = $after
[IO.File]::WriteAllText((Join-Path $repo '.git\\index.lock'), 'housekeeping')
$after = Get-RunProgress $repo @($log)
Assert (-not (Test-RunProgress $before $after)) 'git housekeeping must not count'
$before = $after
$text = "tree $tree\nparent $head\nauthor Fixture <fixture@example.invalid> 1700000001 +0000\ncommitter Fixture <fixture@example.invalid> 1700000001 +0000\n\nNew fixture\n"
$next = $text | & git.exe -C $repo hash-object -w -t commit --stdin
[IO.File]::WriteAllText((Join-Path $repo '.git\\refs\\heads\\master'), "$next\n")
$after = Get-RunProgress $repo @($log)
Assert (Test-RunProgress $before $after) 'new commit with unchanged files must count'
Save-RunResume $repo $out @($log) 'STALLED after 30 min' $head
$note = [IO.File]::ReadAllText((Join-Path $out 'resume.txt'))
Assert ($note.Contains('old-time.txt') -and $note.Contains('last action: writing tests') -and $note.Contains('STALLED after 30 min')) 'resume note needs files, tail and reason'
# Exercise each message writer without committing. runner_selftest.js checks recovery through the real checkout helper.
[IO.File]::WriteAllText((Join-Path $out 'title.txt'), 'Fixture title')
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $args[0] 'codex_issue.ps1') msg 818 $repo $out
Assert ($LASTEXITCODE -eq 0) 'codex message helper'
function Assert-SafeMessage($message) {
  Assert ($message.Contains('STALLED after 30 min')) 'public message needs the fixed stop reason'
  Assert (-not ($message -match 'Z:/private|old-time\.txt|fake-api-secret-818')) 'public message leaked private stop details'
}
Assert-SafeMessage ([IO.File]::ReadAllText((Join-Path $out 'commit.txt')))
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $args[0] 'work_issue.ps1') msg 818 deepseek $out
Assert ($LASTEXITCODE -eq 0) 'work message helper'
Assert-SafeMessage ([IO.File]::ReadAllText((Join-Path $out 'commit.txt')))
& git.exe -C $repo remote add origin $repo
[IO.File]::WriteAllText((Join-Path $out 'base_commit.txt'), $head)
[IO.File]::WriteAllText((Join-Path $out 'partial.txt'), 'STALLED after 30 min')
[IO.File]::WriteAllText((Join-Path $out 'guard_dir.txt'), $out)
[IO.File]::WriteAllText((Join-Path $out 'guard.md'), 'Guard detail: Z:/private fake-api-secret-818')
# The empty fixture tree is unchanged. skipcommit exercises the publisher without creating any commit or pushing.
$env:WORK_TEST_FAULT = 'skipcommit'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $args[0] 'work_issue.ps1') commit $repo $out fixture/issue-818-partial dry
Assert ($LASTEXITCODE -eq 0) 'stopped run with no staged changes must keep its partial message'
Assert ((& git.exe -C $repo rev-parse HEAD) -eq $next) 'test must not commit'
$message = [IO.File]::ReadAllText((Join-Path $out 'commit.txt'))
Assert ($message.StartsWith('PARTIAL RUN')) 'partial publisher must label the message'
Assert-SafeMessage $message
Assert ([IO.File]::ReadAllText((Join-Path $out 'resume.txt')) -ceq $note) 'public write must leave full local resume note intact'
Write-Output 'PASS Windows partial publisher keeps the stop reason and leaves raw details in the local resume note'
# Model Win32_Process records without querying or touching real Godot processes.
function Get-CimInstance($class, $Filter) { $script:playRecords }
$script:playRecords = @(
  [pscustomobject]@{ Name = 'Godot_fixture.exe'; ThreadCount = 0; CommandLine = $null }
  [pscustomobject]@{ Name = 'Godot_fixture.exe'; ThreadCount = 4; CommandLine = 'Godot_fixture.exe --headless' }
)
Assert (-not (Test-RyanPlaying)) 'exited Godot child and headless job must not hold the lane'
$script:playRecords += [pscustomobject]@{ Name = 'Godot_fixture.exe'; ThreadCount = 4; CommandLine = 'Godot_fixture.exe --path "game path" --rendering-method gl_compatibility' }
Assert (Test-RyanPlaying) 'live windowed editor play must still hold the lane'
$script:playRecords = @([pscustomobject]@{ Name = 'Voidsworn.exe'; ThreadCount = 4; CommandLine = $null })
Assert (Test-RyanPlaying) 'an unreadable command line on a running game must still hold the lane'
`);
const p = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, pc, root], {
  encoding: 'utf8', windowsHide: true, timeout: 60000
});
helpers.push(p.pid);
assert.equal(p.status, 0, p.stdout + p.stderr + String(p.error || ''));
pass('Windows real file timestamps, commit-only progress, log bytes, housekeeping exclusion and resume note');

// Actual command launch, process-tree termination, stop reason and resume note. All output stays in TEMP.
for (const scenario of ['silent', 'idle-helper', 'completed-linger', 'unfinished-linger', 'busy', 'lying-killer', 'launcher-exit']) {
  const busy = scenario === 'busy';
  const completedLinger = scenario === 'completed-linger';
  const unfinishedLinger = scenario === 'unfinished-linger';
  const idleHelper = scenario === 'idle-helper';
  const folder = path.join(root, scenario);
  fs.mkdirSync(folder);
  const fake = path.join(folder, 'agent.js');
  const pidFile = path.join(folder, 'pids.txt'); pidFiles.push(pidFile);
  const cleanChild = "if (['TMO_REPO','TMO_OUT','TMO_LOG','TMO_ERR_LOG','TMO_COMPLETE_FILE'].some(k=>process.env[k])) throw Error('watch settings leaked to child'); ";
  const recordPid = `require('fs').appendFileSync(${JSON.stringify(pidFile)}, process.pid+'\\n'); `;
  // Busy, idle-helper, linger and early-exit launchers also own a child and a grandchild, not merely a single sleeping process.
  const leaf = path.join(folder, 'leaf.js'), child = path.join(folder, 'child.js');
  // idle-helper simulates a background MCP/helper doing tiny periodic timer wakeups without real work.
  fs.writeFileSync(leaf, recordPid + (idleHelper ? 'setInterval(()=>{ let s=0; for(let i=0;i<500;i++) s+=i; }, 50);' : 'setInterval(()=>{},100);'));
  fs.writeFileSync(child, recordPid + `require('child_process').spawn(process.execPath,[${JSON.stringify(leaf)}],{stdio:'inherit',windowsHide:true}); setInterval(()=>{},100);`);
  const nested = ['busy', 'idle-helper', 'completed-linger', 'unfinished-linger', 'launcher-exit'].includes(scenario)
    ? `require('child_process').spawn(process.execPath,[${JSON.stringify(child)}],{stdio:'inherit',windowsHide:true,detached:true}); ` : '';
  const lastFile = path.join(folder, 'last.md');
  let body = "console.log('last action: waiting'); setInterval(()=>{},100);";
  if (busy) body = "console.log('working'); setInterval(()=>console.log('still working'),100);";
  else if (completedLinger) body = `console.log('exec\\n  succeeded in 5ms:\\nOK\\ncodex\\nFinished task.\\ntokens used\\n1,234\\nFinished task.'); require('fs').writeFileSync(${JSON.stringify(lastFile)}, 'Finished task.\\n'); setInterval(()=>{},100);`;
  else if (unfinishedLinger) body = `console.log('codex\\nI will read CODEX_TASK.md now.'); require('fs').writeFileSync(${JSON.stringify(lastFile)}, 'I will read CODEX_TASK.md now.\\n'); setInterval(()=>{},100);`;
  fs.writeFileSync(fake, cleanChild + recordPid + nested + body +
    (scenario === 'launcher-exit' ? 'setTimeout(()=>process.exit(7),1500);' : ''));
  const killer = path.join(folder, 'taskkill.bat');
  fs.writeFileSync(killer, '@echo off\r\necho stub taskkill ' + (busy ? 'Access denied' : 'false success') + '\r\nexit /b ' + (busy ? '5' : '0') + '\r\n');
  const log = path.join(folder, 'log.txt');
  const fd = fs.openSync(log, 'w');
  const reason = busy ? 'CEILING' : 'STALLED after 0.02 min';
  let run;
  try { run = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
    cwd: folder, env: { ...process.env, TMO_ARGS: `4 "${process.execPath}" "${fake}"`,
      TMO_REPO: path.join(root, 'repo'), TMO_OUT: folder, TMO_LOG: log, TMO_ERR_LOG: '',
      TMO_COMPLETE_FILE: (completedLinger || unfinishedLinger) ? lastFile : '',
      TMO_EXIT_GRACE_S: (completedLinger || unfinishedLinger) ? '0.4' : '',
      STALL_MIN: scenario === 'launcher-exit' ? '1' : '0.02', PC_RUNNER_TEST: '1', PC_TEST_POLL_MS: '100', PC_TEST_SCAN_S: '0.1', PC_TEST_TIMEOUT_LOG: path.join(root, 'timeouts.log'),
      PC_TEST_TASKKILL: ['busy', 'lying-killer'].includes(scenario) ? killer : '' },
    stdio: ['ignore', fd, fd], windowsHide: true, timeout: 30000
  }); } finally { fs.closeSync(fd); }
  helpers.push(run.pid);
  const output = fs.readFileSync(log, 'utf8');
  const expectedCode = scenario === 'launcher-exit' ? 7 : completedLinger ? 0 : 124;
  assert.equal(run.status, expectedCode, output + String(run.error || ''));
  const pids = fs.readFileSync(pidFile, 'utf8').trim().split(/\r?\n/).map(Number);
  assert.equal(pids.length, ['busy', 'idle-helper', 'completed-linger', 'unfinished-linger', 'launcher-exit'].includes(scenario) ? 3 : 1);
  if (scenario === 'launcher-exit') {
    assert(!alive(pids[0]) && pids.slice(1).every(alive), 'ordinary queue launchers must be able to leave background work running');
    for (const pid of pids.slice(1).reverse()) process.kill(pid, 'SIGKILL');
    const deadline = Date.now() + 5000;
    while (pids.some(alive) && Date.now() < deadline) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);
    assert(pids.every(pid => !alive(pid)), 'background fixture cleanup failed');
    pass('normal launcher keeps exit 7 and background jobs; the test reaps its child and grandchild'); continue;
  }
  assert(pids.every(pid => !alive(pid)), scenario + ': fake agents survived: ' + pids);
  const verified = output.match(/kill verified: all (\d+) processes gone \(PIDs ([\d, ]+)\)/);
  assert(verified && Number(verified[1]) >= pids.length && pids.every(pid => verified[2].split(', ').map(Number).includes(pid)), output);
  if (completedLinger) {
    assert(!fs.existsSync(path.join(folder, 'stop_reason.txt')), 'completed linger must not write stop_reason.txt');
    assert(output.includes('COMPLETED_REAPED'), output);
    assert.equal(fs.readFileSync(lastFile, 'utf8').trim(), 'Finished task.');
    pass('Windows completed-linger: preserves completed result (last.md + tokens used), reaps hung tree and exits 0');
    continue;
  }
  if (busy) assert(/taskkill PID \d+ exit 5:/.test(output) && output.includes('Access denied'), output);
  if (scenario === 'lying-killer') assert(/taskkill PID \d+ exit 0:/.test(output), output);
  assert.equal(fs.readFileSync(path.join(folder, 'stop_reason.txt'), 'utf8'), reason);
  const note = fs.readFileSync(path.join(folder, 'resume.txt'), 'utf8');
  assert(note.includes(reason) && note.includes(busy ? 'still working' : unfinishedLinger ? 'I will read CODEX_TASK.md now.' : 'last action: waiting'));
  pass(`Windows ${scenario}: verifies every agent is gone, saves reason and tail, logs taskkill and fallback result`);
}
const timeoutLog = fs.readFileSync(path.join(root, 'timeouts.log'), 'utf8');
assert(timeoutLog.includes('CEILING') && timeoutLog.includes('STALLED after 0.02 min'));
const ordinary = path.join(root, 'ordinary.js');
fs.writeFileSync(ordinary, 'setTimeout(()=>process.exit(7),500);');
const normal = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
  env: { ...process.env, TMO_ARGS: `4 "${process.execPath}" "${ordinary}"`, TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '',
    STALL_MIN: '0.001', PC_RUNNER_TEST: '1', PC_TEST_POLL_MS: '100', PC_TEST_SCAN_S: '0.1', PC_TEST_TIMEOUT_LOG: path.join(root, 'timeouts.log') },
  encoding: 'utf8', windowsHide: true, timeout: 15000
});
assert.equal(normal.status, 7, normal.stdout + normal.stderr);
helpers.push(normal.pid);
pass('ordinary commands keep their exit code and explicit limit, child commands cannot inherit the agent watch');

// A fake Godot executable uses Windows processes and the real claim helper. Its GPU go file and claims live in TEMP.
const game = path.join(root, 'Godot_stall_fixture_console.exe');
const gameSource = path.join(root, 'FakeGodot.cs');
fs.writeFileSync(gameSource, String.raw`
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
public static class FakeGodot {
  static void StartChild(string exe, string role, string output) {
    Process.Start(new ProcessStartInfo(exe, role + " \"" + output + "\"") {
      UseShellExecute = false, CreateNoWindow = true
    });
  }
  public static int Main(string[] args) {
    string mode = args[0], output = args[1];
    string exe = typeof(FakeGodot).Assembly.Location;
    if (!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("TMO_FATAL_PATTERN"))) return 10;
    File.WriteAllText(Path.Combine(output, "pid-" + mode), Process.GetCurrentProcess().Id + "\n");
    if (mode == "leaf") { Thread.Sleep(Timeout.Infinite); return 0; }
    if (mode == "branch") {
      StartChild(exe, "leaf", output);
      Thread.Sleep(Timeout.Infinite);
      return 0;
    }
    if (mode == "new-files" || mode == "cpu") {
      var clock = Stopwatch.StartNew();
      int file = 0;
      while (clock.ElapsedMilliseconds < 1800) {
        if (mode == "cpu") Thread.SpinWait(10000);
        else {
          File.WriteAllText(Path.Combine(output, "work-" + file++), "progress");
          Thread.Sleep(150);
        }
      }
      return 7;
    }
    if (mode == "noisy") {
      Console.Error.WriteLine("Out of memory");
      Console.WriteLine("Assertion failed");
      for (int i = 0; i < 60; i++) {
        Console.Error.WriteLine("ERROR: fixture retry");
      }
      return 7;
    }
    StartChild(exe, "branch", output);
    if (!SpinWait.SpinUntil(() => File.Exists(Path.Combine(output, "pid-leaf")), 5000)) return 9;
    string claim = Path.Combine(output, "gpu", "gpu_slot_1");
    if (mode == "idle" || mode.StartsWith("solo")) {
      if (!File.Exists(claim) || !File.ReadAllText(claim).Contains("1192")) return 8;
      Console.WriteLine("fixture saw held GPU claim");
    }
    if (mode == "idle") Console.Error.Write("last output before the hang");
    if (mode == "jolt" || mode == "failed-kill") Console.Error.Write("Jolt Physics job system exceeded the maximum number of jobs");
    if (mode == "opt-in") Console.WriteLine("Assertion failed");
    if (mode.StartsWith("solo")) {
      Console.WriteLine("launcher exited while descendants were still running");
      return 7;
    }
    Thread.Sleep(Timeout.Infinite);
    return 0;
  }
}
`);
const compile = path.join(root, 'fake-godot.ps1');
fs.writeFileSync(compile, '$ErrorActionPreference = "Stop"\nAdd-Type -Path $args[0] -OutputAssembly $args[1] -OutputType ConsoleApplication\n');
const built = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', compile, gameSource, game], {
  encoding: 'utf8', windowsHide: true, timeout: 15000
});
assert.equal(built.status, 0, built.stdout + built.stderr + String(built.error || ''));
const tmo = path.join(pc, 'tmo.bat');
// A solo cap starts at claim acquisition. A loaded lane spent nearly the entire old 2 s cap
// getting to the launch, so the test child had too little time to create its process tree.
const soloCap = 8;
for (const [mode, reason] of [
  ['idle', 'IDLE after 1 s'], ['jolt', 'FATAL Jolt Physics job system exceeded'],
  ['opt-in', 'FATAL Assertion failed'], ['solo-default', 'CEILING'], ['solo-override', `SOLO CAP after ${soloCap} s`],
  ['new-files', ''], ['cpu', ''], ['noisy', '']
]) {
  const folder = path.join(root, 'step-' + mode);
  const gpu = path.join(folder, 'gpu');
  fs.mkdirSync(gpu, { recursive: true });
  fs.writeFileSync(path.join(gpu, 'gpu_go.txt'), 'GPU cleared');
  for (const role of [mode, 'branch', 'leaf']) pidFiles.push(path.join(folder, 'pid-' + role));
  const stepLog = path.join(folder, 'timeouts.log');
  const solo = mode.startsWith('solo-');
  const claimed = mode === 'idle' || solo;
  const flags = claimed ? '--bench' : '--headless';
  const ceiling = mode === 'solo-default' ? 4 : 12;
  const run = spawnSync(process.env.ComSpec || 'cmd.exe', ['/d', '/s', '/c',
    `""${tmo}" ${ceiling} "${game}" ${mode} "${folder}" ${flags}"`], {
    cwd: folder, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: true, timeout: 60000,
    env: { ...process.env, TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '', TMO_STEP: 'fake Godot ' + mode,
      TMO_STEP_OUT: folder, TMO_IDLE_S: solo ? '10' : '1',
      TMO_FATAL_PATTERN: mode === 'opt-in' ? 'assertion failed' : '',
      PC_GPU_SOLO_MAX_S: mode === 'solo-override' ? String(soloCap) : '',
      PC_GPU_LANE: '', PC_GPU_ISSUE: '1192', PC_GPU_WAIT_SECONDS: '5', PC_GPU_MODE: '', PC_GPU_WEIGHT: '',
      PC_RUNNER_TEST: '1', PC_TEST_GPU_ROOT: gpu, PC_TEST_TIMEOUT_LOG: stepLog }
  });
  helpers.push(run.pid);
  const diagnostic = run.stdout + run.stderr + String(run.error || '');
  assert.equal(run.status, reason ? 124 : 7, diagnostic);
  if (!reason) {
    if (mode === 'noisy') {
      assert(run.stdout.includes('Assertion failed') && run.stderr.includes('Out of memory'), diagnostic);
      assert.equal(run.stderr.match(/ERROR: fixture retry/g)?.length, 60);
      assert(!fs.existsSync(stepLog), diagnostic);
    }
    pass('fake Godot ' + mode + ' preserves normal completion');
    continue;
  }
  const details = fs.readFileSync(stepLog, 'utf8');
  const stopped = details.match(new RegExp(' at (\\d+(?:\\.\\d+)?) s \\(ceiling ' + ceiling + ' s\\)'));
  assert(stopped && details.includes('TIMEOUT fake Godot ' + mode) && details.includes(reason), details);
  assert(Number(details.match(/kill verified: all (\d+) processes gone/)?.[1]) >= 3, details);
  const pids = [mode, 'branch', 'leaf'].map(role => Number(fs.readFileSync(path.join(folder, 'pid-' + role), 'utf8')));
  assert(pids.every(pid => pid > 0 && !alive(pid)), 'fake Godot tree survived: ' + pids);
  if (reason.startsWith('FATAL')) assert(Number(stopped[1]) < ceiling, details);
  if (mode === 'solo-default') assert(Number(stopped[1]) >= ceiling && Number(stopped[1]) < ceiling + 1, details);
  if (claimed) {
    assert(run.stdout.includes('fixture saw held GPU claim'), diagnostic);
    const verifiedAt = run.stdout.indexOf('kill verified:');
    assert(verifiedAt >= 0 && run.stdout.indexOf('GPU: released solo claim') > verifiedAt, diagnostic);
    for (const name of ['gpu_solo', 'gpu_slot_1']) assert.equal(fs.readFileSync(path.join(gpu, name), 'utf8'), '');
  }
  if (mode === 'idle') {
    const quietFor = Number(details.match(/\(([\d.]+) s since last progress\)/)?.[1]);
    assert(quietFor >= 1 && quietFor < 2, details);
    assert(run.stderr.includes('last output before the hang'), diagnostic);
    const spool = details.match(/Child logs: ([^\r\n]+)/)[1];
    assert(fs.readFileSync(path.join(spool, 'stderr.log'), 'utf8').includes('last output before the hang'));
  }
  pass(`fake Godot ${mode} stopped at ${stopped[1]} s, tree gone${claimed ? ', then GPU claim released' : ''}`);
}

// In one real tmo run, a fatal line triggers a kill that fails. The next admission must wait for the entire tree.
const failedKill = path.join(root, 'failed-kill');
fs.mkdirSync(failedKill);
const failedKillPids = ['failed-kill', 'branch', 'leaf'].map(role => path.join(failedKill, 'pid-' + role));
pidFiles.push(...failedKillPids);
const brokenKiller = path.join(failedKill, 'taskkill.cmd');
fs.writeFileSync(brokenKiller, '@echo off\r\nexit /b 5\r\n');
fs.writeFileSync(path.join(failedKill, 'gpu_go.txt'), 'GPU cleared');
fs.writeFileSync(path.join(failedKill, 'gpu_slots.json'), '{"sharedSlots":1}');
const failedKillLog = path.join(failedKill, 'timeouts.log');
const run = spawnSync(process.env.ComSpec, ['/d', '/s', '/c',
  '""' + tmo + '" 12 "' + game + '" failed-kill "' + failedKill + '""'], {
  cwd: failedKill, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: true, timeout: 60000,
  env: { ...process.env, TMO_REPO: '', TMO_OUT: '', TMO_LOG: '', TMO_ERR_LOG: '', TMO_STEP: 'fake Godot failed kill',
    TMO_STEP_OUT: '', TMO_IDLE_S: '8', TMO_FATAL_PATTERN: '', PC_GPU_SOLO_MAX_S: '', PC_GPU_LANE: '',
    PC_GPU_ISSUE: '1192', PC_GPU_WAIT_SECONDS: '5', PC_GPU_MODE: '', PC_GPU_WEIGHT: '',
    PC_RUNNER_TEST: '1', PC_TEST_GPU_ROOT: failedKill, PC_TEST_TIMEOUT_LOG: failedKillLog,
    PC_TEST_TASKKILL: brokenKiller, PC_TEST_FAIL_KILL: '1' }
});
helpers.push(run.pid);
assert.equal(run.status, 124, run.stdout + run.stderr + String(run.error || ''));
const livePids = failedKillPids.map(file => Number(fs.readFileSync(file, 'utf8')));
assert(livePids.every(alive), 'the first kill must leave the fixture tree alive');
const details = fs.readFileSync(failedKillLog, 'utf8');
assert.match(details, /TIMEOUT fake Godot failed kill .*FATAL Jolt Physics job system exceeded/);
const reported = details.match(/KILL FAILED: surviving PIDs ([\d, ]+) for fake Godot failed kill/);
const reportedPids = reported?.[1].split(', ').map(Number) || [];
assert(livePids.every(pid => reportedPids.includes(pid)), details);
const slots = new Slots(failedKill);
const held = slots.read('gpu_slot_1');
assert.equal(held?.state, 'orphaned_child', details);
const heldPids = held.survivors.map(child => child.pid);
// Windows can add console hosts to the job. They can exit between the kill report and claim update.
assert(livePids.every(pid => heldPids.includes(pid)), details);
assert(heldPids.every(pid => reportedPids.includes(pid)), details);
assert.doesNotMatch(run.stdout, /GPU: released/, run.stdout);
function claimCommand(args, wait = '1') {
  return spawnSync(process.execPath, [path.join(pc, 'gpu_slots.js'), ...args], {
    cwd: failedKill, encoding: 'utf8', windowsHide: true, timeout: 15000,
    env: { ...process.env, PC_GPU_LANE: '', PC_GPU_WAIT_SECONDS: wait }
  });
}
function stopFixture(pid) {
  process.kill(pid, 'SIGKILL');
  const deadline = Date.now() + 5000;
  while (alive(pid) && Date.now() < deadline) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 25);
  assert(!alive(pid), 'fixture PID did not exit: ' + pid);
}
const acquire = ['acquire', failedKill, 'next fixture', String(process.pid), 'shared', '1'];
const prematureRelease = claimCommand(['release', failedKill, held.token]);
assert.notEqual(prematureRelease.status, 0, prematureRelease.stdout);
assert.match(prematureRelease.stderr, /live child/);
stopFixture(livePids[0]);
stopFixture(livePids[1]);
assert(alive(livePids[2]), 'the leaf must still hold the claim after the root and branch exit');
const blocked = claimCommand(acquire);
assert.notEqual(blocked.status, 0, blocked.stdout);
assert.match(blocked.stderr, /admission timed out/);
assert.equal(slots.read('gpu_slot_1').token, held.token);
stopFixture(livePids[2]);
const next = claimCommand(acquire, '5');
assert.equal(next.status, 0, next.stderr + String(next.error || ''));
const nextToken = next.stdout.trim().split(/\r?\n/).at(-1);
assert.notEqual(nextToken, held.token);
assert.equal(claimCommand(['release', failedKill, nextToken]).status, 0);
assert.equal(slots.read('gpu_slot_1'), null);
pass('fake Godot fatal timeout logs every surviving PID and holds its GPU claim until the last child exits');
} finally {
  for (const pid of [...agentPids().reverse(), ...helpers].filter(Boolean)) {
    if (alive(pid)) process.kill(pid, 'SIGKILL');
  }
  // Wait for forced cleanup on failure too. Never trust a kill's return value alone.
  const deadline = Date.now() + 5000;
  while (agentPids().some(alive) && Date.now() < deadline) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);
  assert(agentPids().every(pid => !alive(pid)), 'test cleanup leaked fake agents');
}
pass('final cleanup asserts none of this test run\'s fake agents is alive');
console.log('Evidence: ' + root);
console.log(`PASS runner stall checks (${passed} groups)`);
