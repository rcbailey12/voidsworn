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
  # --low-space and --after-job share one hourly allowance.
  if ($trigger -ne '--nightly' -and $last -gt $now.AddHours(-1).Ticks) { return $false }
  if ($trigger -eq '--nightly') { $lastNight = $night } else { $last = $now.Ticks }
  if (-not $lastNight) { $lastNight = '00000000' }
  $lock.Position = 0
  $buffer = $utf8.GetBytes("$last $lastNight")
  $lock.Write($buffer, 0, $buffer.Length)
  $lock.SetLength($buffer.Length)
  $lock.Flush()
  return $true
}
function Test-GpuClaimed($root) {
  # A non-empty gpu_slot_N or gpu_solo file is a live GPU claim (gpu_slots.js empties it on release). The after-job run
  # stays out of every GPU job so it never skews a timing; a file that cannot be read counts as claimed.
  try {
    foreach ($file in (Get-Item -LiteralPath $root -Force).EnumerateFiles()) {
      if ($file.Name -notmatch '^(gpu_slot_[1-9][0-9]*|gpu_solo)$') { continue }
      if ([IO.File]::ReadAllText($file.FullName).Trim()) { return $true }
    }
    return $false
  } catch { return $true }
}
function Assert-GpuQuiet {
  if ($trigger -eq '--after-job' -and (Test-GpuClaimed $root)) { throw 'a GPU claim started; the after-job cleanup stops until a later job ends' }
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
function Get-CommandLines {
  # Every running process's command line, read once per janitor run. $null means the list could not be read: callers keep.
  # Command lines stay internal: only a process ID and name ever reach the log, which may be relayed (Artoo, PR 1266).
  if ($test -and $null -ne $env:PC_TEST_COMMAND_LINES) {
    return ,@($env:PC_TEST_COMMAND_LINES -split "`n" | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Id = 0; Name = 'fixture'; Line = $_ } })
  }
  try {
    return ,@(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.CommandLine } |
      ForEach-Object { [pscustomobject]@{ Id = $_.ProcessId; Name = $_.Name; Line = $_.CommandLine } })
  }
  catch { return $null }
}
function Assert-NoProcessUses($dir) {
  if ($null -eq $script:commandLines) { throw 'running processes could not be checked' }
  # The whole folder name only: opus121 must not match a command line that names opus1211 (R8 dry run).
  $needle = [regex]::Escape($dir.FullName.TrimEnd('\','/')) + '(?=$|[\\/"''\s])'
  foreach ($process in $script:commandLines) {
    if ($process.Line -match $needle) { throw "a running process names this folder (process $($process.Id) $($process.Name))" }
  }
}
# Issue 1180 run 8 (Board, Nov 20): names only our tools create. A runner GUID, run_parity.js mkdtemp (6 characters) and
# manifest_merge.py mkdtemp (8 characters). Agent-chosen names never match; they go to Ryan as a one-off list.
$legacyScratch = '\A(?:voidsworn-run-(?:(?<issue>[1-9][0-9]*)-)?[0-9a-f]{32}|voidsworn-parity-[A-Za-z0-9]{6}|stage7-checked-[A-Za-z0-9_][A-Za-z0-9_-]*-[a-z0-9_]{8})\z'
function Get-RelayReceipts($mirror) {
  # Objects reachable from the relay branches (board/pc-out-*): a committed receipt, not a loose blob (Artoo, PR 1266).
  if ($script:relayReceipts) { return $script:relayReceipts }
  $set = New-Object 'Collections.Generic.HashSet[string]'
  $refs = @(Read-CleanupGit @('--git-dir',$mirror,'for-each-ref','--format=%(objectname)','refs/heads/board/pc-out-*'))
  if ($gitExit -ne 0) { throw 'relay branches could not be read' }
  if ($refs.Count) {
    foreach ($line in @(Read-CleanupGit @('--git-dir',$mirror,'rev-list','--objects','--glob=refs/heads/board/pc-out-*'))) {
      $null = $set.Add(($line -split ' ', 2)[0])
    }
    if ($gitExit -ne 0) { throw 'relay branches could not be read' }
  }
  $script:relayReceipts = $set
  return $set
}
# helper_clone.ps1's own small files at the top of a helper folder (lease, attempt ID, commit, ship copy record): they
# describe the folder and hold no results, so they never keep it (issue 1180, PR 1275).
$helperBookkeeping = @('.voidsworn-run-active', 'attempt.txt', 'repo_commit.txt', 'ships_copied.txt')
function Remove-HelperFolder($dir, $lease) {
  # Everything but the lease goes while the janitor still holds it. Then the lease file and the empty folder go without
  # recursion: if a new run took the lease or wrote anything in that moment, the delete fails and the folder is kept.
  $leasePath = Join-Path $dir.FullName '.voidsworn-run-active'
  foreach ($item in @($dir.EnumerateFileSystemInfos())) {
    if ($item.FullName -eq $leasePath) { continue }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if ($item -is [IO.DirectoryInfo]) { Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop }
    else { Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop }
  }
  if ($lease) { $lease.Dispose(); [IO.File]::Delete($leasePath) }
  [IO.Directory]::Delete($dir.FullName, $false)
}
function Test-RelayedResults($dir, $mirror) {
  # A helper folder goes only when (1) every file in its out folders is a blob committed on a board/pc-out relay branch
  # and (2) everything else in it is a checkout Git shows as rebuildable with all history pushed. Anything else keeps the
  # folder and is listed for the Board.
  $receipts = Get-RelayReceipts $mirror
  $whole = $dir.Name -match '^opus[1-9][0-9]*out'
  $outFiles = @(); $other = @(); $checkouts = @()
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  if ($whole) { $outFiles = @($dir.EnumerateFiles('*', [IO.SearchOption]::AllDirectories)) }
  else {
    foreach ($item in $dir.EnumerateFileSystemInfos()) {
      if ($item -is [IO.DirectoryInfo] -and $item.Name -like 'out*') { $outFiles += @($item.EnumerateFiles('*', [IO.SearchOption]::AllDirectories)) }
      elseif ($item -is [IO.DirectoryInfo]) { $pending.Push($item) }
      elseif ($helperBookkeeping -contains $item.Name) { continue }
      else { $other += $item }
    }
    while ($pending.Count) {
      $sub = $pending.Pop()
      if (Test-Path -LiteralPath (Join-Path $sub.FullName '.git') -PathType Container) { $checkouts += $sub; continue }
      foreach ($item in $sub.EnumerateFileSystemInfos()) {
        if ($item -is [IO.DirectoryInfo]) { $pending.Push($item) } else { $other += $item }
      }
    }
  }
  if (-not $outFiles.Count) { throw 'no out folder to prove the results were relayed' }
  $hashes = @(Salvage-Git @('--git-dir',$mirror,'hash-object','--no-filters','--stdin-paths') @($outFiles | ForEach-Object { $_.FullName }))
  if ($hashes.Count -ne $outFiles.Count) { throw 'result hashes could not be read' }
  $missing = 0
  for ($i = 0; $i -lt $outFiles.Count; $i++) {
    if (-not $receipts.Contains($hashes[$i])) {
      $missing++
      Log "helper file not on a relay branch: $($outFiles[$i].FullName) ($($outFiles[$i].Length) bytes)"
    }
  }
  if ($missing) { throw "results not all relayed: $missing of $($outFiles.Count) out files are not on a relay branch" }
  foreach ($file in ($other | Select-Object -First 20)) { Log "helper file outside out and outside a checkout: $($file.FullName) ($($file.Length) bytes)" }
  if ($other.Count) { throw "$($other.Count) files outside out are not in a rebuildable checkout" }
  foreach ($checkout in $checkouts) {
    try { Assert-NoGitLocalState $checkout.FullName; Assert-NoLiveWorktree $checkout.FullName; $state = Get-RepoCleanupState $checkout.FullName $mirror '' $false $true }
    catch { throw "checkout $($checkout.FullName) is not rebuildable: $($_.Exception.Message)" }
    # Superseded ship or gen files are only candidates; this path has no checked archive, so they keep the folder (Artoo).
    if ($state.Superseded.Count) { throw "checkout $($checkout.FullName) holds $($state.Superseded.Count) ship or gen files that differ from the shared build" }
  }
}
function Assert-HelperScratchInactive($dir) {
  try { $lease = Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $true }
  catch { throw 'helper scratch lock is held or could not be verified' }
  if ($lease) { $lease.Dispose() }
}
function Clear-ScratchFolder($dir, $issue, $why, $hours, $temp, $now, $dryRun, $activeLegacy, [switch]$tempScratch, $records, $hasOwner, [switch]$legacy, [switch]$helper, $mirror) {
  $size = 'size unavailable'; $issueLock = $null; $helperLease = $null; $leaseBusy = $false
  try {
    if ($helper) {
      # Taken first and held through the decision and the deletion, so helper_clone cannot start a run here meanwhile
      # (Artoo, PR 1275). A held lease keeps the folder once its size is logged.
      try { $helperLease = Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $true }
      catch { $leaseBusy = $true }
    }
    $busy = ''
    if ($issue -and $activeLegacy -contains $issue) { $busy = "issue #$issue has an active older runner" }
    elseif ($issue) {
      try { $issueLock = Open-CleanupLock (Issue-LockPath $issue $temp) $dryRun }
      catch { $busy = "issue #$issue lock is held or could not be verified" }
    }
    # TEMP scratch (owned or legacy) may hold selftest junctions to shared ships: each is removed as a link, never
    # followed, so its target does not matter (Board, R8 dry run). Helper folders still keep on any link.
    $scratchKind = $legacy -or $tempScratch
    $stats = Measure-CleanupDirectory $dir -AllowLinks:$scratchKind -AllowUnreadable:$scratchKind
    $size = "$($stats.Bytes) bytes"
    if ($stats.Links.Count) { $size += ", $($stats.Links.Count) links not followed" }
    if ($stats.Unreadable.Count) { $size += ", $($stats.Unreadable.Count) folders another account owns left in place" }
    $listed = Get-BoardKeepReason $dir.FullName
    if ($listed) { throw $listed }
    foreach ($link in ($stats.Links | Select-Object -First 5)) { Log "link not followed: $($link.FullName) -> $(Get-LinkTarget $link)" }
    foreach ($u in ($stats.Unreadable | Select-Object -First 5)) { Log "folder not readable by this account, left in place: $($u.FullName)" }
    if ($leaseBusy) { throw 'a helper run holds this folder''s lease' }
    if ($dir.FullName -eq $env:PC_RUN_SCRATCH) { throw 'current runner scratch' }
    if ($busy) { throw $busy }
    if ($legacy -or $helper) { Assert-NoProcessUses $dir }
    if ($helper) { Test-RelayedResults $dir $mirror }
    if ($legacy) {
      Assert-HelperScratchInactive $dir
    } elseif ($tempScratch) {
      if (-not $hasOwner -and -not $records) { throw 'name match without owner record' }
      $token = if ($hasOwner) { Read-ScratchOwner $dir.FullName }
      foreach ($run in $records) {
        if ($run.Issue -ne $issue) { throw 'runner status records disagree on the owning issue' }
        $record = $run.State.scratch
        # A record is proof only with the identity the runner writes (token and creation time) and a folder that still
        # carries that token: an old record must never authorize a new folder that later took its path (Artoo, PR 1252).
        if ($record.token -isnot [string] -or -not $record.token -or $record.created -isnot [string] -or -not $record.created) {
          throw 'runner status record lacks token or creation time'
        }
        if (-not $token) { throw 'runner status record names a folder without its ownership token' }
        if ($token -cne $record.token) { throw 'ownership token differs from runner status' }
        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and
            [string]$dir.CreationTimeUtc.Ticks -ne $record.created) { throw 'recorded directory was replaced' }
      }
      Assert-HelperScratchInactive $dir
      $retry = Get-FailedScratchMarker $dir
      if ($retry -and $retry.LastWriteTimeUtc -gt $now.AddDays(-1)) { throw 'newest failed scratch kept for a retry for one day' }
    }
    if ($stats.Latest -gt $now.AddHours(-$hours)) { throw "touched in the last $hours hours" }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if ($dryRun) { $action = 'would remove' }
    else {
      if ($stats.Links.Count) {
        Remove-CleanupLinks $stats.Links
        # Removing a link updates its parent folder's time, so only files and new links count as a change (CI on 3483c7cf).
        $after = Measure-CleanupDirectory $dir -AllowLinks -AllowUnreadable
        if ($after.Links.Count -or $after.FileLatest -gt $now.AddHours(-$hours)) { throw 'folder changed while its links were removed' }
      }
      if ($stats.Unreadable.Count) {
        Remove-CleanupReadable $dir $stats.Unreadable
        $action = "removed all but $($stats.Unreadable.Count) folders another account owns:"
      } elseif ($helper) { Remove-HelperFolder $dir $helperLease; $helperLease = $null; $action = 'removed' }
      else { Remove-CleanupDirectory $dir; $action = 'removed' }
    }
    Log "$action $($dir.FullName) ($size; $why, untouched for at least $hours hours)"
    if ($helper) { $script:helperGone = $true }
  } catch {
    $action = if ($dryRun) { 'would keep' } else { 'kept' }
    Log "$action $($dir.FullName) ($size; $($_.Exception.Message))"
  }
  finally {
    if ($issueLock) { $issueLock.Dispose() }
    if ($helperLease) { $helperLease.Dispose() }
  }
}

# Issue 1396 (Ryan's typed OK in the Board thread, Nov 20; Artoo on #1396, Nov 22): job folder names. opus<N> with any
# suffix (opus1369b, opus1211_run6, opus1373probe2, opus1434o) and playtest folders pt<MMDD><letters> (pt1120c).
$helperJobName = '\Aopus(?<issue>[1-9][0-9]*)(?:[A-Za-z_-][A-Za-z0-9_-]*)?\z'
$playtestJobName = '\Apt[0-9]{4}[a-z]*\z'
$checkoutIdleHours = 6
function Find-JobCheckouts($dir) {
  # Every standalone Git checkout inside a job folder, at any depth (job_head attempts keep theirs inside out_*). Links
  # are never followed, and the search stops at a checkout, so a repository nested inside one is not a candidate.
  $found = @()
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push($dir)
  while ($pending.Count) {
    $next = $pending.Pop()
    try { $subs = @($next.EnumerateDirectories()) } catch { continue }
    foreach ($sub in $subs) {
      if ($sub.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      $git = Get-Item -LiteralPath (Join-Path $sub.FullName '.git') -Force -ErrorAction SilentlyContinue
      if ($git -is [IO.DirectoryInfo] -and -not ($git.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $found += $sub; continue }
      $pending.Push($sub)
    }
  }
  return $found
}
function Clear-JobCheckouts($dir, $issue, $temp, $now, $dryRun, $activeLegacy, $mirror) {
  # A job folder the whole-folder rule keeps (results not all relayed, pictures or logs beside them) can still hold big
  # repo checkouts. Only those go, and only when Git shows nothing in them beyond rebuildable install outputs (the import
  # cache, .import and .uid sidecars, ship and gen copies matching the shared build) with every local commit in the
  # mirror. out folders' results, pictures, glbs, logs and every file outside a checkout stay. The whole job folder must
  # be untouched for 6 hours, its lease and issue lock free and no running process naming it. HEAD and the Git status
  # of each checkout are logged before it is removed.
  $issueLock = $null; $lease = $null
  try {
    $checkouts = @(Find-JobCheckouts $dir)
    if (-not $checkouts.Count) { return }
    $listed = Get-BoardKeepReason $dir.FullName
    if ($listed) { throw $listed }
    # Measured before the lease is taken: creating a lease file must not count as a touch. Each checkout is measured again
    # just before its removal (Clear-KeptCheckout).
    $stats = Measure-CleanupDirectory $dir -AllowLinks -AllowUnreadable
    if ($stats.Latest -gt $now.AddHours(-$checkoutIdleHours)) { throw "job folder touched in the last $checkoutIdleHours hours" }
    # A live run takes the lease even when the folder has none yet (created, never deleted, so helper_clone's own
    # OpenOrCreate meets it held) and holds it through every removal: a helper run cannot start here meanwhile, which a
    # missing lease and an earlier process scan alone would not prove (Artoo on PR 1592). A dry run never creates it.
    try { $lease = Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $dryRun }
    catch { throw 'a helper run holds this folder''s lease' }
    if (-not $dryRun -and -not $lease) { throw 'job folder lease could not be taken' }
    if ($issue -and $activeLegacy -contains $issue) { throw "issue #$issue has an active older runner" }
    if ($issue) {
      try { $issueLock = Open-CleanupLock (Issue-LockPath $issue $temp) $dryRun }
      catch { throw "issue #$issue lock is held or could not be verified" }
    }
    Assert-NoProcessUses $dir
    if (Cleanup-Paused) { throw 'PC pause is active' }
    foreach ($checkout in $checkouts) {
      Assert-GpuQuiet
      $head = @(Read-CleanupGit @('-C',$checkout.FullName,'rev-parse','HEAD'))
      $headText = if ($gitExit -eq 0 -and $head.Count) { $head[0] } else { 'unreadable' }
      $status = @(Read-CleanupGit @('-C',$checkout.FullName,'-c','core.quotePath=false','status','--porcelain=v1','--untracked-files=all','--ignored','--ignore-submodules=none'))
      $statusText = if ($gitExit -eq 0) { "$($status.Count) status lines" } else { 'status unreadable' }
      Log "job checkout record: $($checkout.FullName) HEAD $headText, $statusText"
      foreach ($line in ($status | Where-Object { $_ -notmatch '^!! "?godot/\.godot/' } | Select-Object -First 20)) { Log "job checkout status: $($checkout.FullName): $line" }
      # The strict rule: no salvage root, so local work, superseded ship files or anything not rebuildable keeps it.
      Clear-KeptCheckout $checkout $mirror $dryRun $now '' ''
    }
  } catch {
    $action = if ($dryRun) { 'would keep' } else { 'kept' }
    Log "job checkouts $action in $($dir.FullName) ($($_.Exception.Message))"
  } finally {
    if ($issueLock) { $issueLock.Dispose() }
    if ($lease) { $lease.Dispose() }
  }
}

function Invoke-JobRelayCleanup($dryRun) {
  # Issue 1396 (Board, Nov 22): a job's results are relayed after its tail has run, and no session runs dropcheckouts by
  # hand, so the janitor runs the job head's own proof (opus_job_head.ps1 dropjobs, the same installed version) over
  # every PASS attempt that still lists checkouts. It removes only what that proof clears (origin's relay branch holds
  # every out file byte for byte, PR 1600) and logs the rest as kept. A dry run passes --dry-run: nothing removed or
  # fetched. Its output lines go to this log; a failure only logs.
  $head = Join-Path (Join-Path $PSScriptRoot 'jobs') 'opus_job_head.ps1'
  if (-not (Test-Path -LiteralPath $head -PathType Leaf)) { Log "job relay check skipped: no $head"; return }
  if (Cleanup-Paused) { Log 'job relay check skipped: PC pause is active'; return }
  $exe = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { 'powershell.exe' } else { 'pwsh' }
  $words = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $head, 'dropjobs')
  if ($dryRun) { $words += '--dry-run' }
  $ErrorActionPreference = 'Continue'
  $out = @(& $exe @words 2>&1 | ForEach-Object { "$_" })
  $code = $LASTEXITCODE
  foreach ($line in $out) { if ($line.Trim()) { Log "job relay: $line" } }
  Log "job relay check exit $code"
}

$trigger = $args[0]
if ($args.Count -gt 1 -or $trigger -notin @($null,'--dry-run','--nightly','--low-space','--after-job')) {
  Write-Host 'usage: janitor.bat [--dry-run | --nightly | --low-space | --after-job]'
  exit 2
}
$dryRun = $trigger -eq '--dry-run'
$automatic = $trigger -in @('--nightly','--low-space','--after-job')
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
    catch {
      # After a job, a busy lock means another cleanup is already running: skip without a word.
      if ($trigger -ne '--after-job') { Write-Host "janitor lock in use or unavailable: $($_.Exception.Message)" }
      exit 0
    }
    # Checked before the hourly allowance is spent, so a GPU job only delays the next after-job run.
    if ($trigger -eq '--after-job' -and (Test-GpuClaimed $root)) { exit 0 }
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
  $script:boardKeep = Read-BoardKeepList (Join-Path $root 'janitor_keep.txt')
  Log "Board keep list: $($script:boardKeep.Count) paths"
  $mirror = Repo-Mirror
  # Issue 1186: each Workhorse arm's slot folder keeps its set-aside copies beside its one checkout, like a board lane.
  $slots = @()
  $workRoot = Join-Path $root 'work217'
  if (Test-Path -LiteralPath $workRoot -PathType Container) {
    $slots = @((Get-Item -LiteralPath $workRoot -Force).EnumerateDirectories('slot_*') |
      Where-Object { $_.Name -cmatch '\Aslot_(deepseek|deepseekpro|kimi|kimicode|sonnet|opus|openai)\z' -and
        -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } | ForEach-Object { "work217\$($_.Name)" })
  }
  foreach ($lane in (@('board','board_b','board_c','board_d') + $slots)) {
    $board = Join-Path $root $lane
    if (-not (Test-Path -LiteralPath $board -PathType Container)) { continue }
    Assert-GpuQuiet
    try { Remove-OlderKeptRepos $board $mirror $dryRun $now $salvageRoot }
    catch { Log "kept lane $board (scan unavailable: $($_.Exception.Message))" }
  }
  $runs = @(Get-CleanupRuns $root)
  $recordedScratch = Get-RecordedTempScratch $runs $temp
  # Check old runners once, and take each current issue lock again immediately before making its decision.
  $activeLegacy = @(Get-ActiveLegacyIssues $runs)
  $script:commandLines = Get-CommandLines
  Assert-GpuQuiet
  Clear-WorkRunRepos @($runs | Where-Object { $_.Lane -eq 'work217' }) $mirror $dryRun $now $temp $salvageRoot $activeLegacy
  foreach ($dir in (Get-Item -LiteralPath $temp -Force).EnumerateDirectories()) {
    Assert-GpuQuiet
    $records = $recordedScratch[$dir.FullName]
    $hasOwner = -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
      (Test-Path -LiteralPath (Join-Path $dir.FullName $scratchOwnerFile))
    if (-not $hasOwner -and -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $dir.Name -match $legacyScratch) {
      # Older scratch from before ownership tokens: our exact tool names, a day untouched, no process naming it.
      Clear-ScratchFolder $dir $Matches['issue'] 'scratch named by our tools' 24 $temp $now $dryRun $activeLegacy -Legacy
      continue
    }
    if (-not $records -and -not $hasOwner -and $dir.Name -notmatch '^(voidsworn|issue|tune2-|stage7-checked-)') { continue }
    $issue = if ($records) { $records[0].Issue } elseif ($hasOwner -and
        $dir.Name -match '\Avoidsworn-run-([1-9][0-9]*)-[0-9a-f]{32}\z') { $Matches[1] }
    Clear-ScratchFolder $dir $issue 'owned TEMP scratch' 3 $temp $now $dryRun $activeLegacy -TempScratch -Records $records -HasOwner $hasOwner
  }
  Assert-GpuQuiet
  Invoke-JobRelayCleanup $dryRun
  foreach ($dir in (Get-Item -LiteralPath $root -Force).EnumerateDirectories()) {
    # Issue 1396: suffixed job folders (opus1369b, opus1211_run6, opus1373probe2) and playtest folders (pt1120c) too.
    $issue = ''
    if ($dir.Name -match $helperJobName) { $issue = $Matches['issue'] }
    elseif ($dir.Name -notmatch $playtestJobName) { continue }
    Assert-GpuQuiet
    $script:helperGone = $false
    Clear-ScratchFolder $dir $issue 'helper folder with its results relayed' 24 $temp $now $dryRun $activeLegacy -Helper -Mirror $mirror
    if (-not $script:helperGone) { Clear-JobCheckouts $dir $issue $temp $now $dryRun $activeLegacy $mirror }
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
