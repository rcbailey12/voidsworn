'use strict';
// #944: run the real pause functions with fake lane folders, a virtual clock, fake processes and git ls-remote.
// No agents, live lanes, network, commits, pushes or deletions. Fixtures and logs stay in TEMP.
const fs = require('fs');
const os = require('os');
const path = require('path');
const assert = require('assert');
const { spawnSync } = require('child_process');
const source = path.join(__dirname, 'pause_all.ps1');
const text = fs.readFileSync(source, 'utf8');
assert(text.includes("$_.Name -match '^(codex|opencode)(\\.exe)?$'"));
assert(text.includes("$_.CommandLine -match 'voidsworn_test'"));
assert(text.includes('ls-remote --exit-code https://github.com/rcbailey12/voidsworn.git'));
assert(text.includes("$p.WaitForExit($ms)"));
assert(!/Remove-Item|\.Kill\(|git (?:push|commit|reset|clean)/i.test(text));
assert(!text.includes('partial work pushed by each runner'));
console.log('PASS pause retains narrow process matching and read-only bounded GitHub verification');
if (process.platform !== 'win32') {
  console.log('SKIP Windows pause fixtures: run node tools/pc/pause_all_selftest.js on the PC');
  process.exit(0);
}
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pause944 proof '));
const harness = path.join(root, 'fixture.ps1');
fs.writeFileSync(harness, String.raw`
param($Source, $Root)
$ErrorActionPreference = 'Stop'
. $Source
$realGit = ${'${function:Invoke-PauseGit}'}
function Assert($Ok, $Message) { if (-not $Ok) { throw $Message } }
function Write-Fixture($Path, $Text) {
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  [IO.File]::WriteAllText($Path, $Text)
}
function New-Job($Lane, $Issue, $Status, $Char = 'a', $Started = '2026-11-17T00:00:00Z') {
  $job = "issue-$Issue"; $branch = "codex/issue-$Issue"
  if ($Lane -eq 'work217') { $job += '-deepseek'; $branch = "work/issue-$Issue-deepseek" }
  $out = Join-Path $script:case "$Lane\$job"
  if ($Lane -eq 'work217') { $out = Join-Path $out '20261117_000000\out' }
  $commit = $Char * 40
  $s = @{ run = "run-$Issue"; started = $Started; status = $Status; branch = $branch; commit = $commit }
  Write-Fixture (Join-Path $out 'status.json') ($s | ConvertTo-Json)
  Write-Fixture (Join-Path $out 'run_commit.txt') $commit
  Write-Fixture (Join-Path $out 'confirmed_commit.txt') $commit
  $ref = "refs/heads/$branch"; if ($Status -eq 'partial') { $ref += '-partial' }
  $script:remote[$ref] = $commit
  return $out
}
function Set-Status($Out, $Status) {
  $p = Join-Path $Out 'status.json'
  $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json; $s.status = $Status
  Write-Fixture $p ($s | ConvertTo-Json)
}
function Begin-Case($Name) {
  $script:case = Join-Path $Root $Name
  $null = New-Item -ItemType Directory -Force -Path $script:case
  $script:now = [datetime]'2026-11-17T01:00:00'
  $script:remote = @{}; $script:queries = @(); $script:killed = @()
  $script:agents = @(); $script:hook = {}; $script:gitError = ''; $script:queryHook = {}
}
function Get-Date { return $script:now }
function Start-Sleep([int]$Seconds) {
  $script:now = $script:now.AddSeconds($Seconds)
  & $script:hook
}
function Get-CimInstance($ClassName, $Filter) {
  if ($Filter -eq "Name='cmd.exe'") { return $script:agents | Where-Object { $_.Name -eq 'cmd.exe' } }
  if ($Filter -eq "Name='git.exe'") { return @() }
  return $script:agents
}
function taskkill {
  $target = [int]$args[-1]; $script:killed += $target
  $script:agents = @($script:agents | Where-Object { $_.ProcessId -ne $target })
}
function Invoke-PauseGit($Ref, $Deadline) {
  Assert ($Ref -match '^refs/heads/(codex|work)/issue-') 'unexpected ls-remote ref'
  $script:queries += $Ref
  if ((Get-Date) -ge $Deadline) { throw 'time limit reached before GitHub verification' }
  if ($script:gitError) { throw $script:gitError }
  & $script:queryHook
  if (-not $script:remote.ContainsKey($Ref)) { throw 'git ls-remote failed (exit 2)' }
  return "$($script:remote[$Ref])" + [char]9 + "$Ref" + [char]10
}
function Read-Log { return [IO.File]::ReadAllText((Join-Path $script:case 'pc_pause.txt')) }

Begin-Case 'finished-and-checkpoint'
$main = New-Job board 1 checked_push
$b = New-Job board_b 2 partial b
$c = New-Job board_c 3 checked_push c
$d = New-Job board_d 4 checked_push d
$ds = New-Job work217 5 running e
# Old successful history must not be mistaken for this lane's current job.
$old = New-Job board 99 checked_push f '2026-11-16T00:00:00Z'
$script:hook = { if ($script:now -ge [datetime]'2026-11-17T01:03:20') { Set-Status $ds checked_push } }
$script:agents = @(
  [pscustomobject]@{Name='codex.exe'; CommandLine='codex voidsworn_test\board'; ProcessId=101},
  [pscustomobject]@{Name='opencode.exe'; CommandLine='opencode voidsworn_test\work217'; ProcessId=102},
  [pscustomobject]@{Name='codex.exe'; CommandLine='Ryan own app'; ProcessId=103},
  [pscustomobject]@{Name='blender.exe'; CommandLine='voidsworn_test'; ProcessId=104},
  [pscustomobject]@{Name='cmd.exe'; CommandLine='DS_WAIT.bat'; ProcessId=105},
  [pscustomobject]@{Name='cmd.exe'; CommandLine='CODEX_LANE_ACTIVE.bat'; ProcessId=106}
)
Write-Fixture (Join-Path $script:case 'ds_wait.txt') 'waiting for predecessor'
Write-Fixture (Join-Path $script:case 'codex_lane_active.txt') 'running issue 1'
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board/issue-1: done') 'finished job not done'
Assert ($log -match 'board_b/issue-2: checkpoint verified') 'partial checkpoint not verified'
Assert ($log -match 'board_c/issue-3: done' -and $log -match 'board_d/issue-4: done') 'C or D missing'
Assert ($log -match 'work217/issue-5-deepseek: done') 'DeepSeek final checks not awaited'
Assert (-not $log.Contains('issue-99')) 'old terminal history reported as current'
Assert ($script:now -ge [datetime]'2026-11-17T01:03:20') 'quiet process list skipped runner checks'
Assert ($log.TrimEnd().EndsWith('safe to restart') -and -not $log.Contains('NOT safe')) 'verified pause not safe'
Assert (($script:killed | Sort-Object) -join ',' -eq '101,102,105') 'ended unrelated process or active window'
Assert ($script:queries.Count -eq 5 -and $script:queries.Contains('refs/heads/codex/issue-2-partial')) 'wrong branch verified'
Assert ((Read-PauseText (Join-Path $script:case 'gpu_go.txt')) -like 'GPU not cleared*') 'GPU go not withdrawn'
Write-Host 'PASS finished job, partial checkpoint, all five lanes, wait through DeepSeek checks, narrow kills and waiting windows'

Begin-Case 'mid-checks-timeout'
$ds = New-Job work217 10 running
Invoke-Pause $script:case '' 1
$log = Read-Log
Assert ($log -match 'work217/issue-10-deepseek: unresolved.*runner still running') 'mid-checks timeout not unresolved'
Assert ($log.TrimEnd() -match 'NOT safe to restart: work217/issue-10-deepseek, pause$') 'timeout declared safe'
Assert ($script:queries.Count -eq 0) 'tried to verify running job'
Write-Host 'PASS runner mid-checks and pause timeout stay unresolved with no agent process'

Begin-Case 'mismatches'
$main = New-Job board 20 checked_push
$script:remote['refs/heads/codex/issue-20'] = 'f' * 40
$b = New-Job board_b 21 partial b
Write-Fixture (Join-Path $b 'confirmed_commit.txt') ''
$c = New-Job board_c 22 no_changes c
$d = New-Job board_d 23 partial d
$script:remote.Remove('refs/heads/codex/issue-23-partial')
Invoke-Pause $script:case '' 5
$log = Read-Log
foreach ($name in @('board/issue-20','board_b/issue-21','board_c/issue-22','board_d/issue-23')) {
  Assert ($log.Contains($name + ': unresolved')) "missing unresolved $name"
}
Assert ($log -match 'board/issue-20: unresolved.*GitHub branch does not hold') 'remote mismatch not checked'
Assert ($log -match 'board_b/issue-21: unresolved.*do not agree') 'missing confirmation not checked'
Assert ($log -match 'board_c/issue-22: unresolved.*no_changes') 'no_changes not checked'
Assert ($log -match 'board_d/issue-23: unresolved.*exit 2') 'missing partial ref not checked'
Assert ($log.TrimEnd() -match 'NOT safe to restart:') 'bad metadata or remote declared safe'
Write-Host 'PASS remote mismatch, missing confirmation, no changes and missing partial ref fail closed'

Begin-Case 'malformed-state'
$ds = New-Job work217 24 checked_push e
Write-Fixture (Join-Path $ds 'status.json') '{broken'
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'work217/issue-24-deepseek: unresolved.*status.json missing or unreadable') 'malformed status not unresolved'
Assert ($log.TrimEnd() -match 'NOT safe to restart:') 'malformed status declared safe'
Write-Host 'PASS malformed status cannot fall back to a successful text log or remote ref'

Begin-Case 'remote-timeout'
$main = New-Job board 30 partial
$script:gitError = 'git ls-remote timed out; checkpoint unverified'
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board/issue-30: unresolved.*ls-remote timed out') 'network timeout not unresolved'
Assert ($log.TrimEnd() -match 'NOT safe to restart: board/issue-30$') 'network timeout declared safe'
Write-Host 'PASS fake git ls-remote timeout is unresolved'

Begin-Case 'runner-race'
$main = New-Job board 40 checked_push
$script:queryHook = { Set-Status $main running }
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board/issue-40: unresolved.*runner changed') 'runner race not caught'
Write-Host 'PASS runner metadata change during verification cannot reuse an old confirmation'

Begin-Case 'new-job-during-pause'
$main = New-Job board 50 checked_push
$script:created = $false
$script:hook = {
  if (-not $script:created) {
    $script:created = $true
    $null = New-Job board_b 51 running b
  }
}
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board_b/issue-51: unresolved') 'new queued run escaped pause inventory'
Write-Host 'PASS jobs that start while waiting are included'

Begin-Case 'new-job-during-verification'
$main = New-Job board 60 checked_push
$script:queryHook = { $null = New-Job board_d 61 running b }
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board_d/issue-61: unresolved.*appeared during GitHub verification') 'new job during verification escaped inventory'
Assert ($log.TrimEnd() -match 'NOT safe to restart: board_d/issue-61$') 'new job during verification declared safe'
Write-Host 'PASS final inventory catches jobs that start during GitHub verification'

# Exercise the production process wrapper too, with a tiny fake git.exe in TEMP. It exits on its own, even after timeout.
$fakeGit = Join-Path $Root 'fake git.exe'
Add-Type -OutputAssembly $fakeGit -OutputType ConsoleApplication -TypeDefinition @'
using System;
using System.Threading;
public static class PauseFakeGit {
  public static void Main(string[] args) {
    if (args.Length != 4 || args[0] != "ls-remote" || args[1] != "--exit-code" ||
        args[2] != "https://github.com/rcbailey12/voidsworn.git") Environment.Exit(9);
    if (args[3].EndsWith("71")) { Thread.Sleep(300); return; }
    if (args[3].EndsWith("72")) Environment.Exit(2);
    Console.WriteLine(new String('a', 40) + "\t" + args[3]);
  }
}
'@
$reply = & $realGit 'refs/heads/codex/issue-70' ((Get-Date).AddMinutes(1)) $fakeGit
Assert ($reply.Trim() -eq (('a' * 40) + [char]9 + 'refs/heads/codex/issue-70')) 'real ls-remote wrapper lost stdout'
$timedOut = $false
try { $null = & $realGit 'refs/heads/codex/issue-71' ((Get-Date).AddMilliseconds(50)) $fakeGit }
catch { $timedOut = $_.Exception.Message -like '*timed out*' }
Assert $timedOut 'real ls-remote wrapper did not enforce deadline'
$failed = $false
try { $null = & $realGit 'refs/heads/codex/issue-72' ((Get-Date).AddMinutes(1)) $fakeGit }
catch { $failed = $_.Exception.Message -like '*exit 2*' }
Assert $failed 'real ls-remote wrapper ignored failure'
Write-Host 'PASS production git process wrapper reads fake ls-remote output, enforces its deadline and rejects failure'
Write-Host 'PASS pause_all Windows fixture matrix'
`, 'utf8');
const run = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', harness, source, root], {
  encoding: 'utf8', windowsHide: true, timeout: 60000,
});
fs.writeFileSync(path.join(root, 'selftest.log'), (run.stdout || '') + (run.stderr || ''));
console.log('Evidence: ' + root);
process.stdout.write((run.stdout || '') + (run.stderr || ''));
if (run.error) throw run.error;
assert.equal(run.status, 0, 'pause fixture matrix failed');
