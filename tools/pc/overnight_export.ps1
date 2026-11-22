# Issue 1663 (Ryan, Nov 22 2026, owner decision 4): build\export refreshes by itself overnight. The root watcher.bat runs
# this from its idle branch about every 10 minutes. It changes nothing unless every gate holds, and then it only drops one
# queue job (queue\OVERNIGHT_EXPORT_<sha12>.bat) that runs tools_live's jobs\overnight_export_job.bat; the queue runs it
# like any other job. Gates, each logged when it stops the run:
#   1. 1:00 to 5:00 AM Central time, one try per night (state in voidsworn_test\overnight_export\state.txt);
#   2. gpu_go.txt's first line says GPU cleared;
#   3. C: has at least 75 GB free (the job floor, Board Nov 22);
#   4. the PC is idle: no job waiting or running in queue or queue_b, no live GPU claim (gpu_slot_N, gpu_solo), and no
#      Voidsworn, Godot or Blender process (Ryan playing, or a job still closing);
#   5. main changed game files: the godot/ tree at origin/main (shared repo-mirror.git, fetched under its writers' lock)
#      differs from the last commit exported this way.
# It deletes nothing. Test settings: PC_TEST_HELPER=1, PC_TEST_HELPER_VT, PC_TEST_SOURCE, PC_TEST_NOW (an ISO time),
# PC_TEST_PROCS (process names, comma separated), PC_TEST_FREE_GB.
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($test) { $source = $env:PC_TEST_SOURCE }
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
$home1663 = Join-Path $vt 'overnight_export'
$stateFile = Join-Path $home1663 'state.txt'
function Say($t) { Write-Output ("[{0}] overnight export: {1}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm'), $t) }
function Run-Git {
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }

# 1. the night window, one try a night
$now = [DateTime]::UtcNow
if ($test -and $env:PC_TEST_NOW) { $now = [DateTimeOffset]::Parse($env:PC_TEST_NOW).UtcDateTime }
$zone = if ($unix) { 'America/Chicago' } else { 'Central Standard Time' }
$central = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($now, $zone)
if ($central.Hour -lt 1 -or $central.Hour -ge 5) { exit 0 }
$night = $central.ToString('yyyyMMdd')
$state = @{}
if (Test-Path -LiteralPath $stateFile -PathType Leaf) { foreach ($l in [IO.File]::ReadAllLines($stateFile)) { if ($l -match '\A(exported|tried) (\S+)') { $state[$Matches[1]] = $Matches[2] } } }
if ($state.tried -eq $night) { exit 0 }
# 2. the Board's GPU switch
$go = Join-Path $vt 'gpu_go.txt'
$goLine = if (Test-Path -LiteralPath $go -PathType Leaf) { [IO.File]::ReadAllLines($go) | Select-Object -First 1 } else { '' }
if ("$goLine" -notmatch '\AGPU cleared(\s*:.*)?\z') { Say "waiting: gpu_go.txt does not say GPU cleared"; exit 0 }
# 3. disk
$freeGb = if ($test -and $env:PC_TEST_FREE_GB) { [double]$env:PC_TEST_FREE_GB } else { (New-Object IO.DriveInfo([IO.Path]::GetPathRoot($vt))).AvailableFreeSpace / 1GB }
if ($freeGb -lt 75) { Say ("waiting: C: has {0:N0} GB free, under the 75 GB job floor" -f $freeGb); exit 0 }
# 4. idle
foreach ($q in @('queue', 'queue_b')) {
  foreach ($sub in @('', 'running')) {
    $d = Join-Path (Join-Path $vt $q) $sub
    if ((Test-Path -LiteralPath $d -PathType Container) -and @(Get-ChildItem -LiteralPath $d -File -Filter '*.bat' -Force).Count) { Say "waiting: $q$(if ($sub) { '\' + $sub }) has a job"; exit 0 }
  }
}
foreach ($f in @(Get-ChildItem -LiteralPath $vt -File -Force | Where-Object { $_.Name -match '\A(gpu_slot_[1-9][0-9]*|gpu_solo)\z' })) {
  $claimed = $true
  try { $claimed = [bool]([IO.File]::ReadAllText($f.FullName).Trim()) } catch { $claimed = $true }
  if ($claimed) { Say "waiting: a GPU claim is live ($($f.Name))"; exit 0 }
}
$procs = if ($test) { @("$env:PC_TEST_PROCS".Split(',') | Where-Object { $_ }) } else { @(Get-Process | ForEach-Object { $_.ProcessName }) }
$busy = @($procs | Where-Object { $_ -match '\A(Voidsworn(\.console)?|Godot.*|godot.*|blender.*)\z' })
if ($busy.Count) { Say "waiting: $($busy[0]) is running"; exit 0 }
# 5. main changed game files since the last overnight export
$lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(5)
while (-not $lock) {
  try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
  catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { Say 'waiting: the shared repo copy stayed locked'; exit 0 }; Start-Sleep -Milliseconds 500 }
}
try {
  if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Say 'waiting: no shared repo copy yet (a job makes it)'; exit 0 }
  if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin' }
  Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
  $main = (Run-Git --git-dir $mirror rev-parse 'refs/heads/main^{commit}') | Select-Object -Last 1
  $changed = $true
  if ($state.exported -match '\A[0-9a-f]{40}\z') {
    if ($state.exported -eq $main) { $changed = $false }
    else {
      $ErrorActionPreference = 'Continue'
      $a = & $gitExe --git-dir $mirror rev-parse "$($state.exported):godot" 2>$null
      $okA = $LASTEXITCODE -eq 0
      $b = & $gitExe --git-dir $mirror rev-parse "$($main):godot" 2>$null
      $ErrorActionPreference = 'Stop'
      if ($okA -and "$a" -eq "$b") { $changed = $false }
    }
  }
  if (-not $changed) { Say "nothing to do: main $($main.Substring(0, 12)) has the same game files as the last overnight export"; exit 0 }
  $date = (Run-Git --git-dir $mirror log -1 '--format=%cI' $main) | Select-Object -Last 1
} finally { $lock.Dispose() }

# Every gate holds: one queue job, and tonight's try is used.
$null = [IO.Directory]::CreateDirectory($home1663)
$lines = @("tried $night")
if ($state.exported) { $lines += "exported $($state.exported)" }
[IO.File]::WriteAllLines($stateFile, [string[]]$lines)
$job = Join-Path (Join-Path $vt 'queue') ("OVERNIGHT_EXPORT_{0}.bat" -f $main.Substring(0, 12))
$bat = @(
  '@echo off',
  'rem Made by tools\pc\overnight_export.ps1 (issue 1663): refresh build\export from main overnight. Never edited.',
  'setlocal',
  "set `"ON_PIN=$main`"",
  "set `"ON_DATE=$date`"",
  'set "VT=%USERPROFILE%\Downloads\voidsworn_test"',
  'set "TLV="',
  'if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"',
  'if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)',
  'call "%VT%\tools_live\%TLV%\pc\jobs\overnight_export_job.bat"',
  'exit /b %ERRORLEVEL%')
$null = [IO.Directory]::CreateDirectory((Split-Path -Parent $job))
[IO.File]::WriteAllText($job, (($bat -join "`r`n") + "`r`n"))
Say "queued $job for main $main ($date)"
