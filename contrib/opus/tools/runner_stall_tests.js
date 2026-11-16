'use strict';
// Issue 818: fake clocks run on Linux CI; Windows also exercises the real watchdog and resume path for free.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');
const pc = path.resolve(__dirname, '../../../tools/pc');
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

for (const [runner, cap] of [['codex_issue', 'CODEX_CAP'], ['work_issue', 'WORK_CAP']]) {
  const bat = fs.readFileSync(path.join(pc, runner + '.bat'), 'utf8');
  assert(bat.includes(`if not defined ${cap} set "${cap}=21600"`));
  for (const name of ['TMO_REPO', 'TMO_OUT', 'TMO_LOG']) {
    assert(bat.includes(`set "${name}=`), runner + ' must set ' + name);
    assert(bat.includes(`set "${name}="`), runner + ' must clear ' + name);
  }
  assert(bat.includes('stop_reason.txt'));
  assert(bat.includes('if defined PARTIAL goto :haschange'));
}
pass('both launchers set agent progress paths, preserve ceiling overrides and publish stopped notes with no file changes');

if (process.platform !== 'win32') {
  console.log('SKIP Windows process and file probes: Windows standing checks run them');
  console.log(`PASS runner stall checks (${passed} groups)`);
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'runner818 '));
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
[IO.File]::WriteAllText($log, 'last action: writing tests')
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
Assert ([IO.File]::ReadAllText((Join-Path $out 'commit.txt')).Contains($note)) 'codex commit message needs full stop note'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $args[0] 'work_issue.ps1') msg 818 deepseek $out
Assert ($LASTEXITCODE -eq 0) 'work message helper'
Assert ([IO.File]::ReadAllText((Join-Path $out 'commit.txt')).Contains($note.Trim())) 'work commit message needs full stop note'
& git.exe -C $repo remote add origin $repo
[IO.File]::WriteAllText((Join-Path $out 'base_commit.txt'), $head)
[IO.File]::WriteAllText((Join-Path $out 'partial.txt'), 'STALLED after 30 min')
# The empty fixture tree is unchanged. skipcommit exercises the publisher without creating any commit or pushing.
$env:WORK_TEST_FAULT = 'skipcommit'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $args[0] 'work_issue.ps1') commit $repo $out fixture/issue-818-partial dry
Assert ($LASTEXITCODE -eq 0) 'stopped run with no staged changes must keep its partial message'
Assert ((& git.exe -C $repo rev-parse HEAD) -eq $next) 'test must not commit'
$message = [IO.File]::ReadAllText((Join-Path $out 'commit.txt'))
Assert ($message.StartsWith('PARTIAL RUN') -and $message.Contains($note.Trim())) 'partial publisher must retain the full stop note'
Write-Output 'PASS Windows file, commit, log and resume probes'
`);
const p = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, pc, root], {
  encoding: 'utf8', windowsHide: true, timeout: 60000
});
assert.equal(p.status, 0, p.stdout + p.stderr + String(p.error || ''));
pass('Windows real file timestamps, commit-only progress, log bytes, housekeeping exclusion and resume note');

// Actual command launch, process-tree termination, stop reason and resume note. All output stays in TEMP.
for (const busy of [false, true]) {
  const folder = path.join(root, busy ? 'busy' : 'silent');
  fs.mkdirSync(folder);
  const fake = path.join(folder, 'agent.js');
  const cleanChild = "if (['TMO_REPO','TMO_OUT','TMO_LOG','TMO_ERR_LOG'].some(k=>process.env[k])) throw Error('watch settings leaked to child'); ";
  fs.writeFileSync(fake, cleanChild + (busy ? "console.log('working'); setInterval(()=>console.log('still working'),100);" : "console.log('last action: waiting'); setInterval(()=>{},100);"));
  const log = path.join(folder, 'log.txt');
  const fd = fs.openSync(log, 'w');
  const reason = busy ? 'CEILING' : 'STALLED after 0.02 min';
  const run = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, 'run_timeout.ps1')], {
    cwd: folder, env: { ...process.env, TMO_ARGS: `4 "${process.execPath}" "${fake}"`,
      TMO_REPO: path.join(root, 'repo'), TMO_OUT: folder, TMO_LOG: log, TMO_ERR_LOG: '',
      STALL_MIN: '0.02', PC_RUNNER_TEST: '1', PC_TEST_POLL_MS: '100', PC_TEST_SCAN_S: '0.1', PC_TEST_TIMEOUT_LOG: path.join(root, 'timeouts.log') },
    stdio: ['ignore', fd, fd], windowsHide: true, timeout: 20000
  });
  fs.closeSync(fd);
  assert.equal(run.status, 124, fs.readFileSync(log, 'utf8') + String(run.error || ''));
  assert.equal(fs.readFileSync(path.join(folder, 'stop_reason.txt'), 'utf8'), reason);
  const note = fs.readFileSync(path.join(folder, 'resume.txt'), 'utf8');
  assert(note.includes(reason) && note.includes(busy ? 'still working' : 'last action: waiting'));
  pass(`Windows ${busy ? 'busy ceiling' : 'silent stall'} stops real fake process and saves reason and tail`);
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
pass('ordinary commands keep their exit code and explicit limit, child commands cannot inherit the agent watch');
console.log('Evidence: ' + root);
console.log(`PASS runner stall checks (${passed} groups)`);
