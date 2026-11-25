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
  (Get-Item -LiteralPath $Path).LastWriteTimeUtc = $script:now.ToUniversalTime()
}
function Set-Activity($Out, $Time) {
  foreach ($file in Get-ChildItem -LiteralPath $Out -File) { $file.LastWriteTimeUtc = $Time.ToUniversalTime() }
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
  Set-Activity $out ([datetime]::Parse($Started))
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
  $script:now = [datetime]::SpecifyKind([datetime]'2026-11-17T01:00:00', [DateTimeKind]::Utc)
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
$e = New-Job board_e 6 running a
$f = New-Job board_f 7 partial b
# Old successful history must not be mistaken for this lane's current job.
$old = New-Job board 99 checked_push f '2026-11-16T00:00:00Z'
$script:hook = {
  if ($script:now -ge [datetime]'2026-11-17T01:03:20') { Set-Status $ds checked_push }
  if ($script:now -ge [datetime]'2026-11-17T01:03:25') { Set-Status $e checked_push }
}
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
Assert ($log -match 'board_e/issue-6: done' -and $log -match 'board_f/issue-7: checkpoint verified') 'E or F missing'
Assert ($log -match 'work217/issue-5-deepseek: done') 'DeepSeek final checks not awaited'
Assert (-not $log.Contains('issue-99')) 'old terminal history reported as current'
Assert ($script:now -ge [datetime]'2026-11-17T01:03:25') 'quiet process list skipped runner checks'
Assert ($log.TrimEnd().EndsWith('safe to restart') -and -not $log.Contains('NOT safe')) 'verified pause not safe'
Assert (($script:killed | Sort-Object) -join ',' -eq '101,102,105') 'ended unrelated process or active window'
Assert ($script:queries.Count -eq 7 -and $script:queries.Contains('refs/heads/codex/issue-2-partial') -and $script:queries.Contains('refs/heads/codex/issue-7-partial')) 'wrong branch verified'
Assert ((Read-PauseText (Join-Path $script:case 'gpu_go.txt')) -like 'GPU not cleared*') 'GPU go not withdrawn'
Write-Host 'PASS finished jobs, partial checkpoints, all six Codex lanes and DeepSeek, narrow kills and waiting windows'

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

Begin-Case 'leftovers-with-newer-finished-jobs'
$main = New-Job board 80 checked_push
$old = New-Job board 79 running b '2026-11-16T00:00:00Z'
$ds = New-Job work217 933 checked_push c
$oldDs = New-Job work217 932 running d '2026-11-16T18:48:00Z'
$before = @(Get-ChildItem -LiteralPath $old,$oldDs -File | ForEach-Object {
  $_.FullName + ':' + $_.LastWriteTimeUtc.Ticks + ':' + [IO.File]::ReadAllText($_.FullName)
}) -join '|'
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log.Contains('leftover record (not counted): board/issue-79, last activity 2026-11-16 00:00:00 UTC')) 'stale Codex record not listed with activity'
Assert ($log.Contains('leftover record (not counted): work217/issue-932-deepseek, last activity 2026-11-16 18:48:00 UTC')) 'stale DeepSeek record not listed'
Assert ($log -match 'board/issue-80: done' -and $log -match 'work217/issue-933-deepseek: done') 'newer finished jobs not verified'
Assert ($log.TrimEnd().EndsWith('safe to restart') -and -not $log.Contains('NOT safe')) 'leftovers held pause or counted as unresolved'
Assert ($script:now -lt [datetime]'2026-11-17T01:04:00') 'leftovers held pause until deadline'
Assert ($script:queries.Count -eq 2) 'leftover remote branch was queried'
$after = @(Get-ChildItem -LiteralPath $old,$oldDs -File | ForEach-Object {
  $_.FullName + ':' + $_.LastWriteTimeUtc.Ticks + ':' + [IO.File]::ReadAllText($_.FullName)
}) -join '|'
Assert ($before -eq $after) 'leftover files changed or disappeared'
Write-Host 'PASS stale Codex and DeepSeek running records are listed, untouched and do not block safe restart'

foreach ($finish in @($false,$true)) {
  Begin-Case "main-lane-stale-newer-start-$finish"
  $live = New-Job board 928 running a '2026-11-16T21:00:00Z'
  $old944 = New-Job board 944 running b '2026-11-16T21:58:00Z'
  $old945 = New-Job board 945 running c '2026-11-16T21:58:00Z'
  Write-Fixture (Join-Path $live 'checks_node.txt') 'checks still running'
  $inventory = @(Get-PauseJobs $script:case)
  Assert (@($inventory | Where-Object { $_.Leftover }).Count -eq 2) 'newer start time hid live checks activity'
  if ($finish) {
    $script:hook = { if ($script:now -ge [datetime]'2026-11-17T01:03:20') { Set-Status $live checked_push } }
  }
  $limit = if ($finish) { 5 } else { 1 }
  Invoke-Pause $script:case '' $limit
  $log = Read-Log
  foreach ($issue in @(944,945)) {
    Assert ($log.Contains("leftover record (not counted): board/issue-$issue,")) "main lane leftover $issue missing"
    Assert (-not $log.Contains('board/issue-' + $issue + ': unresolved')) 'main lane leftover counted unresolved'
  }
  if ($finish) {
    Assert ($log -match 'board/issue-928: done' -and -not $log.Contains('NOT safe')) 'live job failed to settle with leftovers'
    Assert ($script:now -ge [datetime]'2026-11-17T01:03:20') 'did not await live checks'
  } else {
    Assert ($log -match 'board/issue-928: unresolved.*runner still running') 'fresh checks job did not stay pending'
    Assert ($log.TrimEnd() -match 'NOT safe to restart: board/issue-928, pause$') 'wrong unresolved jobs in main lane timeout'
  }
}
Write-Host 'PASS main lane ignores stale 944/945 despite later starts and awaits 928 checks through finish or timeout'

foreach ($name in @('status.json','log.txt','result.txt','checks_node.txt','checks_parity.txt')) {
  Begin-Case "activity-$name"
  $live = New-Job board 90 running a '2026-11-16T00:00:00Z'
  $latest = New-Job board 91 checked_push b
  Set-Activity $latest $script:now
  $file = Join-Path $live $name
  if (-not (Test-Path -LiteralPath $file)) { Write-Fixture $file 'fresh activity' }
  # Not newest, but just inside the activity window, including the exact 30-minute boundary.
  (Get-Item -LiteralPath $file).LastWriteTimeUtc = $script:now.AddMinutes(-30)
  $j = @(Get-PauseJobs $script:case | Where-Object { $_.Job -eq 'issue-90' })[0]
  Assert (-not $j.Leftover) "$name activity did not keep runner live"
  (Get-Item -LiteralPath $file).LastWriteTimeUtc = $script:now.AddMinutes(-30).AddSeconds(-1)
  $j = @(Get-PauseJobs $script:case | Where-Object { $_.Job -eq 'issue-90' })[0]
  Assert $j.Leftover "$name stale activity kept runner live"
}
Write-Host 'PASS all five activity files keep an older running record live at the 30-minute boundary'

Begin-Case 'process-names-old-job'
$live = New-Job board 100 running a '2026-11-16T00:00:00Z'
$latest = New-Job board 101 checked_push b
$script:agents = @([pscustomobject]@{Name='powershell.exe'; CommandLine=('runner "' + $live + '\result.txt"'); ProcessId=201})
$j = @(Get-PauseJobs $script:case | Where-Object { $_.Job -eq 'issue-100' })[0]
Assert (-not $j.Leftover) 'process folder reference did not keep older runner live'
Invoke-Pause $script:case '' 1
$log = Read-Log
Assert ($log -match 'board/issue-100: unresolved.*runner still running') 'live runner process ignored during pause'
Assert ($script:killed.Count -eq 0) 'killed runner window while classifying'
$script:agents[0].CommandLine = 'runner "' + $live + '-other\result.txt"'
$j = @(Get-PauseJobs $script:case | Where-Object { $_.Job -eq 'issue-100' })[0]
Assert $j.Leftover 'folder prefix collision kept stale record live'
$ds = New-Job work217 102 running c '2026-11-16T00:00:00Z'
$dsLatest = New-Job work217 103 checked_push d
$script:agents[0].CommandLine = 'runner "' + (Join-Path (Split-Path -Parent $ds) 'repo') + '"'
$j = @(Get-PauseJobs $script:case | Where-Object { $_.Job -eq 'issue-102-deepseek' })[0]
Assert (-not $j.Leftover) 'DeepSeek sibling repo process was not recognized'
Write-Host 'PASS process paths keep older runners live, preserve windows and avoid folder prefix collisions'

Begin-Case 'newest-stale-running'
$latest = New-Job board 110 running a '2026-11-16T00:00:00Z'
Invoke-Pause $script:case '' 1
$log = Read-Log
Assert ($log -match 'board/issue-110: unresolved.*runner still running') 'newest record was discarded for age alone'
Assert (-not $log.Contains('leftover record')) 'newest record listed as leftover'
Write-Host 'PASS newest lane record stays live even with stale files and no process'

Begin-Case 'leftover-becomes-active'
$old = New-Job board 120 running a '2026-11-16T00:00:00Z'
$latest = New-Job board 121 checked_push b
$script:hook = { Write-Fixture (Join-Path $old 'checks_parity.txt') 'resumed checks' }
Invoke-Pause $script:case '' 5
$log = Read-Log
Assert ($log -match 'board/issue-120: unresolved.*runner still running') 'leftover activity during pause was ignored'
Assert (-not $log.Contains('leftover record (not counted): board/issue-120,')) 'reactivated job still listed as leftover'
Write-Host 'PASS fresh activity promotes a leftover into the pending job inventory'

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
