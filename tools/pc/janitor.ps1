# R336 PC cleanup. PowerShell 5.1. The Board reads --dry-run before the first live run.
. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library

function Log($line) {
  $script:log.WriteLine($line)
  Write-Host $line
}
function Get-LegacyRuns($root) {
  # Runners deployed before R336 recorded the scratch path in status.json but did not name it by issue.
  foreach ($lane in @('board','board_b','board_c','board_d','work217')) {
    $base = Join-Path $root $lane
    if (-not (Test-Path -LiteralPath $base -PathType Container)) { continue }
    $laneDir = Get-Item -LiteralPath $base -Force
    Assert-PlainDirectory $laneDir
    foreach ($job in $laneDir.EnumerateDirectories('issue-*')) {
      if ($job.Name -notmatch '^issue-([1-9][0-9]*)(?:-[a-z0-9]+)?$' -or
          ($job.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
      $issue = $Matches[1]
      $runs = if ($lane -eq 'work217') {
        $job.EnumerateDirectories() | Where-Object { $_.Name -match '^\d{8}_\d{6}$' -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }
      } else { $job }
      foreach ($run in $runs) {
        $out = if ($lane -eq 'work217') { Join-Path $run.FullName 'out' } else { $run.FullName }
        $state = Join-Path $out 'status.json'
        if (-not (Test-Path -LiteralPath $state -PathType Leaf)) { continue }
        try { $s = [IO.File]::ReadAllText($state) | ConvertFrom-Json } catch { continue }
        if ($s.scratch.path -notmatch '[\\/]voidsworn-run-[0-9a-f]{32}$') { continue }
        $repo = if ($lane -eq 'work217') { Join-Path $run.FullName 'repo' } else { Join-Path $base 'repo' }
        [pscustomobject]@{ Issue = $issue; State = $s; Out = $out; Repo = $repo; Lane = $lane }
      }
    }
  }
}
function Get-ActiveLegacyIssues($runs) {
  $running = @($runs | Where-Object { $_.State.status -eq 'running' })
  if (-not $running.Count) { return }
  try {
    $commands = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.CommandLine } | ForEach-Object { $_.CommandLine })
  } catch {
    # Keep scratch reported as running when this PC cannot verify the old runner processes.
    $running.Issue
    return
  }
  foreach ($run in $running) {
    $paths = @($run.Out, $run.Repo, $run.State.scratch.path) | ForEach-Object { [regex]::Escape($_) }
    if (@($commands -match (('(?:' + ($paths -join '|') + ')(?=[\\/"\s]|$)'))).Count) { $run.Issue; continue }
    if ($run.Lane -ne 'work217') {
      $laneLock = $null
      try { $laneLock = Open-CleanupLock ($run.Repo + '.checkout.lock') $true }
      catch { $run.Issue }
      finally { if ($laneLock) { $laneLock.Dispose() } }
    }
  }
}
function Reserve-AutomaticRun($lock, $trigger, $now, $night) {
  # Both triggers serialize across lanes. Record admission before cleaning so a killed run cannot be retried in a loop.
  $reader = New-Object IO.StreamReader($lock, $utf8, $false, 1024, $true)
  try { $line = $reader.ReadLine() } finally { $reader.Dispose() }
  $last = 0L; $lastNight = ''
  if ($line -match '^([0-9]{1,19}) (\d{8})$') { $last = [long]$Matches[1]; $lastNight = $Matches[2] }
  if ($trigger -eq '--nightly' -and $lastNight -eq $night) { return $false }
  if ($trigger -eq '--low-space' -and $last -gt $now.AddHours(-1).Ticks) { return $false }
  if ($trigger -eq '--nightly') { $lastNight = $night } else { $last = $now.Ticks }
  if (-not $lastNight) { $lastNight = '00000000' }
  $lock.Position = 0
  $buffer = $utf8.GetBytes("$last $lastNight")
  $lock.Write($buffer, 0, $buffer.Length)
  $lock.SetLength($buffer.Length)
  $lock.Flush()
  return $true
}
function Open-JanitorLock($path, $wait) {
  $deadline = [DateTime]::UtcNow.AddMinutes(10)
  while ($true) {
    try { return Open-CleanupLock $path }
    catch [IO.IOException] {
      if (-not $wait -or -not (Test-Path -LiteralPath $path -PathType Leaf) -or [DateTime]::UtcNow -ge $deadline) { throw }
      Start-Sleep -Seconds 1
    }
  }
}
function Clear-ScratchFolder($dir, $issue, $why, $hours, $temp, $now, $dryRun, $activeLegacy, $owned) {
  $size = 'size unavailable'; $issueLock = $null
  try {
    $busy = ''
    if ($issue -and $activeLegacy -contains $issue) { $busy = "issue #$issue has an active older runner" }
    elseif ($issue) {
      try { $issueLock = Open-CleanupLock (Issue-LockPath $issue $temp) $dryRun }
      catch { $busy = "issue #$issue lock is held or could not be verified" }
    }
    $stats = Measure-CleanupDirectory $dir
    $size = "$($stats.Bytes) bytes"
    if ($dir.FullName -eq $env:PC_RUN_SCRATCH) { throw 'current runner scratch' }
    if ($busy) { throw $busy }
    if ($owned) {
      $null = Read-ScratchOwner $dir.FullName
      $retry = Get-FailedScratchMarker $dir
      if ($retry -and $retry.LastWriteTimeUtc -gt $now.AddDays(-1)) { throw 'newest failed scratch kept for a retry for one day' }
    }
    if ($stats.Latest -gt $now.AddHours(-$hours)) { throw "touched in the last $hours hours" }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if ($dryRun) { $action = 'would remove' }
    else { Remove-CleanupDirectory $dir; $action = 'removed' }
    Log "$action $($dir.FullName) ($size; $why, untouched for at least $hours hours)"
  } catch { Log "kept $($dir.FullName) ($size; $($_.Exception.Message))" }
  finally { if ($issueLock) { $issueLock.Dispose() } }
}

$trigger = $args[0]
if ($args.Count -gt 1 -or $trigger -notin @($null,'--dry-run','--nightly','--low-space')) {
  Write-Host 'usage: janitor.bat [--dry-run | --nightly | --low-space]'
  exit 2
}
$dryRun = $trigger -eq '--dry-run'
$automatic = $trigger -in @('--nightly','--low-space')
$root = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'
$temp = [IO.Path]::GetFullPath((Runner-Temp)).TrimEnd('\','/')
$now = [DateTime]::UtcNow
$lock = $null; $script:log = $null
try {
  Assert-PlainDirectory (Get-Item -LiteralPath $root -Force)
  Assert-PlainDirectory (Get-Item -LiteralPath $temp -Force)
  $night = ''
  if ($trigger -eq '--nightly') {
    $central = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($now, 'Central Standard Time')
    if ($central.Hour -lt 3) { exit 0 }
    $night = $central.ToString('yyyyMMdd')
  }
  if (-not $dryRun) {
    if (Cleanup-Paused) {
      if ($trigger -ne '--nightly') { Write-Host 'janitor skipped during the PC pause' }
      exit 0
    }
    try { $lock = Open-JanitorLock (Join-Path $root 'janitor.lock') ($trigger -eq '--low-space') }
    catch { Write-Host "janitor lock in use or unavailable: $($_.Exception.Message)"; exit 0 }
    $now = [DateTime]::UtcNow
    if ($automatic -and -not (Reserve-AutomaticRun $lock $trigger $now $night)) { exit 0 }
  }
  $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($root))
  $logPath = Join-Path $root "janitor_$((Get-Date).ToString('yyyyMMdd-HHmm')).txt"
  $logItem = Get-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
  if ($logItem -and ($logItem -isnot [IO.FileInfo] -or ($logItem.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
    throw 'janitor log is not a plain file'
  }
  $script:log = New-Object IO.StreamWriter($logPath, $true, $utf8)
  $script:log.AutoFlush = $true
  $mode = if ($dryRun) { 'dry run' } elseif ($automatic) { $trigger } else { 'manual' }
  Log "janitor $mode at $($now.ToString('o'))"
  Log "free space before: $($drive.AvailableFreeSpace) bytes"
  $mirror = Repo-Mirror
  foreach ($lane in @('board','board_b','board_c','board_d')) {
    $board = Join-Path $root $lane
    if (-not (Test-Path -LiteralPath $board -PathType Container)) { continue }
    try { Remove-OlderKeptRepos $board $mirror $dryRun }
    catch { Log "kept lane $board (scan unavailable: $($_.Exception.Message))" }
  }
  $legacy = @{}
  $legacyRuns = @(Get-LegacyRuns $root)
  foreach ($run in $legacyRuns) { $legacy[[string]$run.State.scratch.path] = $run.Issue }
  # Check old runners once, and take each current issue lock again immediately before making its decision.
  $activeLegacy = @(Get-ActiveLegacyIssues $legacyRuns)
  foreach ($dir in (Get-Item -LiteralPath $temp -Force).EnumerateDirectories()) {
    if ($dir.Name -notmatch '^(voidsworn|issue|tune2-)') { continue }
    $owned = $dir.Name -like 'voidsworn-run-*'
    $issue = $legacy[$dir.FullName]
    if (-not $issue -and ($dir.Name -match '^(?:issue|voidsworn(?:[-_](?:issue|parity|run))?|tune2)[-_]*([1-9][0-9]{0,9})(?=[-_.]|$)' -or
        $dir.Name -match '[-_]issue[-_]*([1-9][0-9]{0,9})(?=[-_.]|$)')) { $issue = $Matches[1] }
    $why = if ($owned) { 'runner scratch' } elseif ($dir.Name -like 'voidsworn-parity-*') { 'parity scratch' } else { 'job scratch' }
    Clear-ScratchFolder $dir $issue $why 3 $temp $now $dryRun $activeLegacy $owned
  }
  foreach ($dir in (Get-Item -LiteralPath $root -Force).EnumerateDirectories('opus*')) {
    if ($dir.Name -notmatch '^opus([1-9][0-9]*)(?:out.*)?$') { continue }
    Clear-ScratchFolder $dir $Matches[1] 'helper folder' 24 $temp $now $dryRun $activeLegacy $false
  }
} catch {
  if ($script:log) { Log "janitor stopped: $($_.Exception.Message)" }
  else { Write-Host "janitor could not start: $($_.Exception.Message)" }
  exit 1
} finally {
  if ($script:log) {
    Log "free space after: $($drive.AvailableFreeSpace) bytes"
    Log 'all done'
    $script:log.Dispose()
  }
  if ($lock) { $lock.Dispose() }
}
exit 0
