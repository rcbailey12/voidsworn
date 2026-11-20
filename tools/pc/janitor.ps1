# R336 PC cleanup. PowerShell 5.1. The Board reads --dry-run before the first live run.
. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
. (Join-Path $PSScriptRoot 'janitor_salvage.ps1')

function Log($line) {
  if ($script:log) { $script:log.WriteLine($line) }
  Write-Host $line
}
function Get-CleanupRuns($root) {
  # Runner status records supply the exact scratch path and its issue.
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
        $s = $null
        try {
          Assert-PlainDirectory (Get-Item -LiteralPath $out -Force)
          $file = Get-Item -LiteralPath (Join-Path $out 'status.json') -Force
          if ($file -is [IO.FileInfo] -and -not ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            $s = [IO.File]::ReadAllText($file.FullName) | ConvertFrom-Json
          }
        } catch { }
        $repo = if ($lane -eq 'work217') { Join-Path $run.FullName 'repo' } else { Join-Path $base 'repo' }
        if ($lane -eq 'work217' -or $s.scratch.path -is [string]) {
          [pscustomobject]@{ Issue = $issue; State = $s; Out = $out; Repo = $repo; Lane = $lane; Name = "$($job.Name)_$($run.Name)" }
        }
      }
    }
  }
}
function Get-RecordedTempScratch($runs, $temp) {
  $records = @{}
  foreach ($run in $runs) {
    $path = $run.State.scratch.path
    if ($path -isnot [string] -or -not $path) { continue }
    try {
      if ([IO.Path]::GetFullPath($path) -ne $path -or (Split-Path -Parent $path) -ne $temp) { continue }
    } catch { continue }
    $records[$path] += @($run)
  }
  return $records
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
    $paths = @($run.Out, $run.Repo, $run.State.scratch.path) | Where-Object { $_ } | ForEach-Object { [regex]::Escape($_) }
    if (@($commands -match (('(?:' + ($paths -join '|') + ')(?=[\\/"\s]|$)'))).Count) { $run.Issue; continue }
    if ($run.Lane -ne 'work217') {
      $laneLock = $null
      try { $laneLock = Open-CleanupLock ($run.Repo + '.checkout.lock') $true }
      catch { $run.Issue }
      finally { if ($laneLock) { $laneLock.Dispose() } }
    }
  }
}
function Clear-WorkRunRepos($runs, $mirror, $dryRun, $now, $temp, $salvageRoot, $activeLegacy) {
  foreach ($run in $runs) {
    $repo = Get-Item -LiteralPath $run.Repo -Force -ErrorAction SilentlyContinue
    if (-not $repo) { continue }
    $issueLock = $null; $checkoutLock = $null; $reason = ''
    try {
      Assert-PlainDirectory $repo.Parent
      $issueLock = Open-CleanupLock (Issue-LockPath $run.Issue $temp) $dryRun
      $checkoutLock = Open-CleanupLock ($run.Repo + '.checkout.lock') $true
    } catch { $reason = 'run lock is held or could not be verified' }
    try {
      if (-not $reason -and ($activeLegacy -contains $run.Issue -or
          -not $run.State.finished -or $run.State.status -notin @('checked_push','unverified','partial','failed','no_changes'))) {
        $reason = 'run ending could not be verified or issue is active'
      }
      Clear-KeptCheckout $repo $mirror $dryRun $now $salvageRoot "work217_$($run.Name)" $reason
    } finally {
      if ($checkoutLock) { $checkoutLock.Dispose() }
      if ($issueLock) { $issueLock.Dispose() }
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
function Assert-HelperScratchInactive($dir) {
  try { $lease = Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $true }
  catch { throw 'helper scratch lock is held or could not be verified' }
  if ($lease) { $lease.Dispose() }
}
function Clear-ScratchFolder($dir, $issue, $why, $hours, $temp, $now, $dryRun, $activeLegacy, [switch]$tempScratch, $records, $hasOwner) {
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
    if ($tempScratch) {
      if (-not $hasOwner -and -not $records) { throw 'name match without owner record' }
      $token = if ($hasOwner) { Read-ScratchOwner $dir.FullName }
      foreach ($run in $records) {
        if ($run.Issue -ne $issue) { throw 'runner status records disagree on the owning issue' }
        $record = $run.State.scratch
        if ($token -and $record.token -and $token -cne $record.token) { throw 'ownership token differs from runner status' }
        if ($record.created -and [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and
            [string]$dir.CreationTimeUtc.Ticks -ne $record.created) { throw 'recorded directory was replaced' }
      }
      Assert-HelperScratchInactive $dir
      $retry = Get-FailedScratchMarker $dir
      if ($retry -and $retry.LastWriteTimeUtc -gt $now.AddDays(-1)) { throw 'newest failed scratch kept for a retry for one day' }
    }
    if ($stats.Latest -gt $now.AddHours(-$hours)) { throw "touched in the last $hours hours" }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if ($dryRun) { $action = 'would remove' }
    else { Remove-CleanupDirectory $dir; $action = 'removed' }
    Log "$action $($dir.FullName) ($size; $why, untouched for at least $hours hours)"
  } catch {
    $action = if ($dryRun) { 'would keep' } else { 'kept' }
    Log "$action $($dir.FullName) ($size; $($_.Exception.Message))"
  }
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
$salvageRoot = Join-Path $root 'salvage'
$lock = $null; $drive = $null; $script:log = $null
try {
  if ($test -and $env:PC_TEST_JANITOR_NOW) { $now = [DateTimeOffset]::Parse($env:PC_TEST_JANITOR_NOW).UtcDateTime }
  $night = ''
  if ($trigger -eq '--nightly') {
    $central = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($now, 'Central Standard Time')
    if ($central.Hour -lt 3 -or $central.Hour -ge 6) { exit 0 }
    $night = $central.ToString('yyyyMMdd')
  }
  Assert-PlainDirectory (Get-Item -LiteralPath $root -Force)
  Assert-PlainDirectory (Get-Item -LiteralPath $temp -Force)
  if (-not $dryRun) {
    if (Cleanup-Paused) {
      if ($trigger -ne '--nightly') { Write-Host 'janitor skipped during the PC pause' }
      exit 0
    }
    try { $lock = Open-JanitorLock (Join-Path $root 'janitor.lock') ($trigger -eq '--low-space') }
    catch { Write-Host "janitor lock in use or unavailable: $($_.Exception.Message)"; exit 0 }
    if ($automatic -and -not (Reserve-AutomaticRun $lock $trigger $now $night)) { exit 0 }
    $logPath = Join-Path $root "janitor_$((Get-Date).ToString('yyyyMMdd-HHmm')).txt"
    $logItem = Get-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
    if ($logItem -and ($logItem -isnot [IO.FileInfo] -or ($logItem.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
      throw 'janitor log is not a plain file'
    }
    $script:log = New-Object IO.StreamWriter($logPath, $true, $utf8)
    $script:log.AutoFlush = $true
  }
  $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($root))
  $mode = if ($dryRun) { 'dry run' } elseif ($automatic) { $trigger } else { 'manual' }
  Log "janitor $mode at $($now.ToString('o'))"
  Log "free space before: $($drive.AvailableFreeSpace) bytes"
  $mirror = Repo-Mirror
  foreach ($lane in @('board','board_b','board_c','board_d')) {
    $board = Join-Path $root $lane
    if (-not (Test-Path -LiteralPath $board -PathType Container)) { continue }
    try { Remove-OlderKeptRepos $board $mirror $dryRun $now $salvageRoot }
    catch { Log "kept lane $board (scan unavailable: $($_.Exception.Message))" }
  }
  $runs = @(Get-CleanupRuns $root)
  $recordedScratch = Get-RecordedTempScratch $runs $temp
  # Check old runners once, and take each current issue lock again immediately before making its decision.
  $activeLegacy = @(Get-ActiveLegacyIssues $runs)
  Clear-WorkRunRepos @($runs | Where-Object { $_.Lane -eq 'work217' }) $mirror $dryRun $now $temp $salvageRoot $activeLegacy
  foreach ($dir in (Get-Item -LiteralPath $temp -Force).EnumerateDirectories()) {
    $records = $recordedScratch[$dir.FullName]
    $hasOwner = -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
      (Test-Path -LiteralPath (Join-Path $dir.FullName $scratchOwnerFile))
    if (-not $records -and -not $hasOwner -and $dir.Name -notmatch '^(voidsworn|issue|tune2-|stage7-checked-)') { continue }
    $issue = if ($records) { $records[0].Issue } elseif ($hasOwner -and
        $dir.Name -match '\Avoidsworn-run-([1-9][0-9]*)-[0-9a-f]{32}\z') { $Matches[1] }
    Clear-ScratchFolder $dir $issue 'owned TEMP scratch' 3 $temp $now $dryRun $activeLegacy -TempScratch -Records $records -HasOwner $hasOwner
  }
  foreach ($dir in (Get-Item -LiteralPath $root -Force).EnumerateDirectories('opus*')) {
    if ($dir.Name -notmatch '^opus([1-9][0-9]*)(?:out.*)?$') { continue }
    Clear-ScratchFolder $dir $Matches[1] 'helper folder' 72 $temp $now $dryRun $activeLegacy
  }
} catch {
  if ($script:log) { Log "janitor stopped: $($_.Exception.Message)" }
  else { Write-Host "janitor could not start: $($_.Exception.Message)" }
  exit 1
} finally {
  if ($drive) {
    Log "free space after: $($drive.AvailableFreeSpace) bytes"
    Log 'all done'
  }
  if ($script:log) { $script:log.Dispose() }
  if ($lock) { $lock.Dispose() }
}
exit 0
