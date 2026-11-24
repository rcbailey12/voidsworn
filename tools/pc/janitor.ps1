# R336 PC cleanup. PowerShell 5.1. The Board reads --dry-run before the first live run.
. (Join-Path $PSScriptRoot 'runner_common.ps1') cleanup-library
. (Join-Path $PSScriptRoot 'janitor_salvage.ps1')

function Log($line) {
  if ($script:log) { $script:log.WriteLine($line) }
  Write-Host $line
}
function Install-JanitorTask([bool]$preview) {
  if ((Get-TimeZone).Id -ne 'Central Standard Time') { throw 'The PC must be on Central Time for the 3:30 AM schedule.' }
  $name = 'Voidsworn Janitor'
  $launch = {
    $ErrorActionPreference = 'Stop'
    $env:GIT_TERMINAL_PROMPT = '0'
    $env:GCM_INTERACTIVE = 'never'
    $live = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test/tools_live'
    $version = (Get-Content -LiteralPath (Join-Path $live 'current.txt') -Raw).Trim()
    if ($version -notmatch '\A[0-9a-f]{12}\z') { throw 'tools_live/current.txt does not name a tools version' }
    $janitor = Join-Path (Join-Path $live $version) 'pc/janitor.bat'
    & $janitor --nightly
    exit $LASTEXITCODE
  }
  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($launch.ToString().Trim()))
  $execute = Join-Path $PSHOME 'powershell.exe'
  $arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -EncodedCommand $encoded"
  $at = [DateTime]::Today.AddHours(3).AddMinutes(30)
  # A boundary without a UTC offset tracks Central clock time across daylight saving changes.
  $boundary = $at.ToString("yyyy-MM-dd'T'HH:mm:ss", [Globalization.CultureInfo]::InvariantCulture)
  $interval = New-TimeSpan -Minutes 15
  $duration = New-TimeSpan -Hours 2
  $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  if ($preview) {
    Write-Host "Task dry run: $name, $boundary, daily, retries $([Xml.XmlConvert]::ToString($interval)) for $([Xml.XmlConvert]::ToString($duration))"
    Write-Host "Account: $user (Interactive, Limited)"
    Write-Host "Action: $execute $arguments"
    return
  }
  $action = New-ScheduledTaskAction -Execute $execute -Argument $arguments
  $daily = New-ScheduledTaskTrigger -Daily -At $at
  $daily.StartBoundary = $boundary
  # Retry inside the nightly window after a GPU solo claim, a pause or another cleanup at 3:30.
  $retry = New-ScheduledTaskTrigger -Once -At $at -RepetitionInterval $interval -RepetitionDuration $duration
  $daily.Repetition = $retry.Repetition
  # Use Ryan's signed-in session so Git can use its existing credentials for private relay checks.
  $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -MultipleInstances IgnoreNew
  Register-ScheduledTask -TaskName $name -Action $action -Trigger $daily -Principal $principal -Settings $settings -Force | Out-Null
  Write-Host "Installed $name for 3:30 AM Central each day. Keep this Windows account signed in overnight."
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
  # Automatic runs serialize across lanes. Record admission before cleaning so a killed run cannot be retried in a loop.
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
function Test-JanitorGpuClaim([switch]$SoloOnly) {
  if (-not $automatic) { return $false }
  # gpu_slots.js empties claims on release. An unreadable claim is treated as active.
  try {
    $names = if ($SoloOnly -or $trigger -ne '--after-job') { '^gpu_solo$' } else { '^(gpu_slot_[1-9][0-9]*|gpu_solo)$' }
    foreach ($file in (Get-Item -LiteralPath $root -Force).EnumerateFiles('gpu_*')) {
      if ($file.Name -notmatch $names) { continue }
      if ([IO.File]::ReadAllText($file.FullName).Trim()) { return $true }
    }
    return $false
  } catch { return $true }
}
function Assert-GpuQuiet([switch]$SoloOnly) {
  if (Test-JanitorGpuClaim -SoloOnly:$SoloOnly) { throw "a GPU claim started; deferred the remaining $($trigger.Substring(2)) cleanup in this pass" }
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
  # Objects reachable from the relay branches (board/pc-out-* here, pc-out-* in the relay repo's mirror): a committed receipt, not a loose blob (Artoo, PR 1266).
  # Read again whenever the relay refs differ from the last read (review of PR 1592: the relay sweep's child or another
  # runner can fetch and prune the mirror between two folders).
  $refs = @(Read-CleanupGit @('--git-dir',$mirror,'for-each-ref','--format=%(objectname) %(refname)','refs/heads/board/pc-out-*'))
  if ($gitExit -ne 0) { throw 'relay branches could not be read' }
  # Issue 1657: the private relay repo's own mirror (relay-mirror.git beside the shared one), branches pc-out-*.
  $relayMirror = Join-Path (Split-Path -Parent $mirror) 'relay-mirror.git'
  $relayRefs = @()
  if (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD')) {
    $relayRefs = @(Read-CleanupGit @('--git-dir',$relayMirror,'for-each-ref','--format=%(objectname) %(refname)','refs/heads/pc-out-*'))
    if ($gitExit -ne 0) { throw 'relay repo branches could not be read' }
  }
  $key = ($refs + @('relay') + $relayRefs) -join "`n"
  if ($script:relayReceipts -and $script:relayReceiptsKey -ceq $key) { return $script:relayReceipts }
  $set = New-Object 'Collections.Generic.HashSet[string]'
  if ($refs.Count) {
    foreach ($line in @(Read-CleanupGit @('--git-dir',$mirror,'rev-list','--objects','--glob=refs/heads/board/pc-out-*'))) {
      $null = $set.Add(($line -split ' ', 2)[0])
    }
    if ($gitExit -ne 0) { throw 'relay branches could not be read' }
  }
  if ($relayRefs.Count) {
    foreach ($line in @(Read-CleanupGit @('--git-dir',$relayMirror,'rev-list','--objects','--glob=refs/heads/pc-out-*'))) {
      $null = $set.Add(($line -split ' ', 2)[0])
    }
    if ($gitExit -ne 0) { throw 'relay repo branches could not be read' }
  }
  $script:relayReceipts = $set; $script:relayReceiptsKey = $key
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
function Get-ShipCloneReason($jobDir, $checkout) {
  # Issue 1396 (review of PR 1592): a ship job's clone <job>\repo stays until its publish: publish_ship.bat installs with
  # that clone's tools and removes it itself (droprepo) after a published PASS. ship_job.bat's receipt out\result.txt
  # starts with "start <ship> <code> <branch>". The janitor never removes such a clone; an abandoned one goes to the Board.
  if (-not $checkout.FullName.Equals((Join-Path $jobDir.FullName 'repo'), [StringComparison]::OrdinalIgnoreCase)) { return '' }
  $receipt = Join-Path (Join-Path $jobDir.FullName 'out') 'result.txt'
  $item = Get-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
  if (-not ($item -is [IO.FileInfo]) -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return '' }
  $first = ''
  try { $first = [string](Get-Content -LiteralPath $receipt -TotalCount 1) } catch { return 'ship receipt unreadable, so the clone may still be needed for its publish' }
  if ($first -match '\Astart \S+ \S+ \S+') { return 'a ship clone waits for its publish (publish_ship.bat removes it; the janitor never does)' }
  return ''
}
function Test-RelayedResults($dir, $mirror) {
  # A helper folder goes only when (1) every file in its out folders is a blob committed on a board/pc-out relay branch
  # and (2) everything else in it is a checkout Git shows as rebuildable with all history pushed. Anything else keeps the
  # folder and is listed for the Board.
  $receipts = Get-RelayReceipts $mirror
  $whole = $dir.Name -match '^opus[1-9][0-9]*out'
  $outFiles = @(); $other = @(); $checkouts = @()
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  # A Git checkout inside an out folder (job_head attempts keep theirs in out_*) is not a result: it gets the same Git
  # proof as a checkout beside out, and its files and pack are never hashed as output (DRY2 on the PC hashed a 16.25 GB
  # pack under opus1235\out_*\new\.git; Artoo on PR 1592).
  $collectOut = {
    param($top)
    $files = @(); $walk = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'; $walk.Push($top)
    while ($walk.Count) {
      $d = $walk.Pop()
      foreach ($item in $d.EnumerateFileSystemInfos()) {
        if ($item -is [IO.DirectoryInfo]) {
          if (Test-Path -LiteralPath (Join-Path $item.FullName '.git') -PathType Container) { $script:outCheckouts += $item }
          else { $walk.Push($item) }
        } elseif ($d.FullName -eq $dir.FullName -and $item.Name -eq '.voidsworn-run-active') {
          # The lease a live run holds on a whole out folder is the janitor's own, not a result (CI on 5ff6f4ab).
          continue
        } else { $files += $item }
      }
    }
    return $files
  }
  $script:outCheckouts = @()
  if ($whole) { $outFiles = @(& $collectOut $dir) }
  else {
    foreach ($item in $dir.EnumerateFileSystemInfos()) {
      if ($item -is [IO.DirectoryInfo] -and $item.Name -like 'out*') { $outFiles += @(& $collectOut $item) }
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
  $checkouts += $script:outCheckouts
  if (-not $outFiles.Count) { throw 'no out folder to prove the results were relayed' }
  # A file over GitHub's 100 MB limit can never be a blob on a relay branch, so it counts as not relayed without being read
  # (DRY3 on the PC spent about 250 s per opus1434 folder hashing 2 GB videos that keep the folder anyway).
  $missing = 0; $all = $outFiles.Count
  foreach ($file in @($outFiles | Where-Object { $_.Length -gt 100MB })) {
    $missing++
    Log "helper file not on a relay branch: $($file.FullName) ($($file.Length) bytes; over GitHub's 100 MB file limit, not read)"
  }
  $outFiles = @($outFiles | Where-Object { $_.Length -le 100MB })
  $hashes = @()
  if ($outFiles.Count) { $hashes = @(Salvage-Git @('--git-dir',$mirror,'hash-object','--no-filters','--stdin-paths') @($outFiles | ForEach-Object { $_.FullName })) }
  if ($hashes.Count -ne $outFiles.Count) { throw 'result hashes could not be read' }
  for ($i = 0; $i -lt $outFiles.Count; $i++) {
    if (-not $receipts.Contains($hashes[$i])) {
      $missing++
      Log "helper file not on a relay branch: $($outFiles[$i].FullName) ($($outFiles[$i].Length) bytes)"
    }
  }
  if ($missing) { throw "results not all relayed: $missing of $all out files are not on a relay branch" }
  foreach ($file in ($other | Select-Object -First 20)) { Log "helper file outside out and outside a checkout: $($file.FullName) ($($file.Length) bytes)" }
  if ($other.Count) { throw "$($other.Count) files outside out are not in a rebuildable checkout" }
  foreach ($checkout in $checkouts) {
    $ship = Get-ShipCloneReason $dir $checkout
    if ($ship) { throw "checkout $($checkout.FullName): $ship" }
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
  $size = 'size unavailable'; $issueLock = $null; $helperLease = $null; $leaseBusy = $false; $mirrorLock = $null
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
    if ($helper) {
      $script:folderStats = @{ Dir = $dir.FullName; Stats = $stats }
      # A live run holds the lease even when the folder had none (review of PR 1592: an existing-only open returns no
      # handle, and a helper run could start while the folder is removed). Taken after the measure, so the new file is
      # not a touch; the process check below still runs after it is held.
      if (-not $dryRun -and -not $helperLease -and -not $leaseBusy) {
        try { $helperLease = Open-CleanupLock (Join-Path $dir.FullName '.voidsworn-run-active') $false }
        catch { $leaseBusy = $true }
      }
    }
    $size = Format-CleanupSize $stats
    if ($stats.Links.Count) { $size += ", $($stats.Links.Count) links not followed" }
    if ($stats.Unreadable.Count) { $size += ", $($stats.Unreadable.Count) folders another account owns cannot be removed and are not counted" }
    $listed = Get-BoardKeepReason $dir.FullName
    if ($listed) { throw $listed }
    foreach ($link in ($stats.Links | Select-Object -First 5)) { Log "link not followed: $($link.FullName) -> $(Get-LinkTarget $link)" }
    foreach ($u in ($stats.Unreadable | Select-Object -First 5)) { Log "cannot remove: $($u.FullName) (another account owns it or it cannot be read; left in place)" }
    $script:cannotRemoveCount += $stats.Unreadable.Count
    if ($leaseBusy) { throw 'a helper run holds this folder''s lease' }
    if ($dir.FullName -eq $env:PC_RUN_SCRATCH) { throw 'current runner scratch' }
    if ($busy) { throw $busy }
    if ($legacy -or $helper) { Assert-NoProcessUses $dir }
    if ($helper) {
      # A live run holds the mirror writers' lock from the relay and history proof through the removal, so no lane's
      # fetch or prune changes the refs that proof read (Artoo on PR 1592, 905a8504).
      if (-not $dryRun) { $mirrorLock = Open-MirrorWriterLock $mirror }
      Test-RelayedResults $dir $mirror
    }
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
    Add-WouldFree $stats
    Log "$action $($dir.FullName) ($size; $why, untouched for at least $hours hours)"
    if ($helper) { $script:helperGone = $true }
  } catch {
    $action = if ($dryRun) { 'would keep' } else { 'kept' }
    Log "$action $($dir.FullName) ($size; $($_.Exception.Message))"
  }
  finally {
    if ($mirrorLock) { $mirrorLock.Dispose() }
    if ($issueLock) { $issueLock.Dispose() }
    if ($helperLease) { $helperLease.Dispose() }
  }
}

# Issue 1396 (Ryan's typed OK in the Board thread, Nov 20; Artoo on #1396, Nov 22): job folder names. opus<N> with any
# suffix (opus1369b, opus1211_run6, opus1373probe2, opus1434o) and playtest folders pt<MMDD><letters> (pt1120c).
$helperJobName = '\Aopus(?<issue>[1-9][0-9]*)(?:[A-Za-z_-][A-Za-z0-9_-]*)?\z'
$playtestJobName = '\Apt[0-9]{4}[a-z]*\z'
$checkoutIdleHours = 6
function Write-LegacyJobRepos($root) {
  # Inventory only. The older layout never enters the attempt relay proof.
  foreach ($job in (Get-Item -LiteralPath $root -Force).EnumerateDirectories()) {
    if (($job.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
        ($job.Name -notmatch $helperJobName -and $job.Name -notmatch $playtestJobName)) { continue }
    $out = Get-Item -LiteralPath (Join-Path $job.FullName 'out') -Force -ErrorAction SilentlyContinue
    $parents = @($job)
    if ($out -is [IO.DirectoryInfo] -and -not ($out.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      try { $parents += @($out.EnumerateDirectories('run_*') | Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }) }
      catch { Log "legacy job inventory unavailable in $($out.FullName): $($_.Exception.Message)" }
    }
    foreach ($parent in $parents) {
      $repo = Get-Item -LiteralPath (Join-Path $parent.FullName 'repo') -Force -ErrorAction SilentlyContinue
      if ($repo -is [IO.DirectoryInfo] -and -not ($repo.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Log "legacy job repo (inventory only): $($repo.FullName)"
      }
    }
  }
}
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
    # The helper rule's measure of this folder in this run, taken before any lease was created, is reused (issue 1396:
    # one walk of each job folder, not two).
    if ($script:folderStats -and $script:folderStats.Dir -eq $dir.FullName) { $stats = $script:folderStats.Stats }
    else { $stats = Measure-CleanupDirectory $dir -AllowLinks -AllowUnreadable }
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
      $ship = Get-ShipCloneReason $dir $checkout
      if ($ship) { Log "kept checkout retained: $($checkout.FullName) (0 bytes counted, not sized; $ship)"; continue }
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

function Test-ListsCheckouts($dir) {
  # Any attempt <job>\out_* with a checkouts.txt: the only folders the job head's relay proof can act on.
  try {
    foreach ($att in $dir.EnumerateDirectories('out_*')) {
      if (-not ($att.Attributes -band [IO.FileAttributes]::ReparsePoint) -and (Test-Path -LiteralPath (Join-Path $att.FullName 'checkouts.txt') -PathType Leaf)) { return $true }
    }
  } catch { }
  return $false
}
function Invoke-JobRelayCleanup($dir, $issue, $temp, $dryRun, $activeLegacy) {
  # Issue 1396 (Board, Nov 22): a job's results are relayed after its tail has run, and no session runs dropcheckouts by
  # hand, so the janitor runs the job head's own proof (opus_job_head.ps1 dropjobs <job>, the same installed version)
  # for each job folder whose PASS attempts still list checkouts. It removes only what that proof clears (origin's relay
  # branch holds every out file byte for byte, PR 1600) and logs the rest as kept. The same checks as every other janitor
  # removal come first and hold through the call, a resumed removal included (Artoo on PR 1592): the Board keep list, the
  # job lease (taken even when missing, never created on a dry run), the issue lock, no running process naming the
  # folder, and the PC pause. A dry run passes dry: nothing removed or fetched.
  if (-not (Test-ListsCheckouts $dir)) { return }
  $head = Join-Path (Join-Path $PSScriptRoot 'jobs') 'opus_job_head.ps1'
  $issueLock = $null; $lease = $null
  try {
    if (-not (Test-Path -LiteralPath $head -PathType Leaf)) { throw "no job head at $head" }
    $listed = Get-BoardKeepReason $dir.FullName
    if ($listed) { throw $listed }
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
    $exe = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { 'powershell.exe' } else { 'pwsh' }
    $words = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $head, 'dropjobs', $dir.FullName)
    if ($dryRun) { $words += 'dry' }   # a bare word: -File reads a leading -- as a parameter name
    $ErrorActionPreference = 'Continue'
    $out = @(& $exe @words 2>&1 | ForEach-Object { "$_" })
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    foreach ($line in $out) { if ($line.Trim()) { Log "job relay: $line" } }
    Log "job relay check exit $code in $($dir.FullName)"
  } catch {
    $action = if ($dryRun) { 'would keep' } else { 'kept' }
    Log "job relay checkouts $action in $($dir.FullName) ($($_.Exception.Message))"
  } finally {
    if ($issueLock) { $issueLock.Dispose() }
    if ($lease) { $lease.Dispose() }
  }
}

# Issue 1396 (Board, Nov 22: the first dry run ran 1 h 47 min without finishing). Each run has a time budget checked
# between items, not a hard timeout (PC_JANITOR_CAP_SECONDS, 2700 s): the board lanes and Workhorse runs until a quarter,
# the TEMP folders until half, the job folders until the end. A run past its budget starts no new folder, which only keeps things, and says where it stopped; a live run writes that name to
# janitor_resume.txt so the next run starts there and wraps around, and every folder is reached in turn. A dry run reads
# the file and never writes it. Folders that take 10 s or more get a "folder time" line.
function Test-PlainResumeFile($path) {
  # Missing is fine; anything else than a plain file (a link, a folder) is refused (review of PR 1592).
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return $true }
  return ($item -is [IO.FileInfo]) -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}
function Read-JanitorResume($path) {
  $resume = @{ lane = ''; temp = ''; root = '' }
  if (-not (Test-PlainResumeFile $path)) { Log "resume file ignored: $path is not a plain file"; return $resume }
  try {
    foreach ($line in [IO.File]::ReadAllLines($path)) {
      if ($line -match '\A(lane|temp|root) (.+)\z') { $resume[$Matches[1]] = $Matches[2] }
    }
  } catch {}
  return $resume
}
function Write-JanitorResume($path, [string[]]$lines) {
  # A fresh sibling file, then one replace, so a link or a half-written file never takes the place of the resume file.
  if (-not (Test-PlainResumeFile $path)) { Log "resume file not written: $path is not a plain file"; return }
  if (-not $lines.Count) { if (Test-Path -LiteralPath $path -PathType Leaf) { [IO.File]::Delete($path) }; return }
  $fresh = "$path.new"
  if (Test-Path -LiteralPath $fresh) {
    if (-not (Test-PlainResumeFile $fresh)) { Log "resume file not written: $fresh is not a plain file"; return }
    [IO.File]::Delete($fresh)
  }
  [IO.File]::WriteAllLines($fresh, $lines)
  if (Test-Path -LiteralPath $path -PathType Leaf) { [IO.File]::Replace($fresh, $path, $null) } else { [IO.File]::Move($fresh, $path) }
}
function Get-Rotated($items, [string[]]$names, $start) {
  # One ordering for the walk and the lookup (ordinal, case blind), and an exact name wins (review of PR 1592: Sort-Object
  # and an ordinal lookup disagreed on opus1211_run6 and opus12110).
  # Sorted as positions: given an object[] of folders, PowerShell can pick the generic Array.Sort and sort a converted copy,
  # leaving the folders in their old order beside sorted names (CI on 311fd83c).
  $items = @($items); $keys = [string[]]@($names).Clone()
  if (-not $items.Count) { return @() }
  $order = [int[]](0..($items.Count - 1))
  [Array]::Sort($keys, $order, [StringComparer]::OrdinalIgnoreCase)
  $all = @(foreach ($i in $order) { $items[$i] })
  if (-not $start) { return $all }
  $at = -1
  for ($i = 0; $i -lt $keys.Count; $i++) { if ([string]::Equals($keys[$i], $start, [StringComparison]::OrdinalIgnoreCase)) { $at = $i; break } }
  if ($at -lt 0) {
    $at = 0
    while ($at -lt $keys.Count -and [StringComparer]::OrdinalIgnoreCase.Compare($keys[$at], $start) -lt 0) { $at++ }
    if ($at -ge $keys.Count) { return $all }
  }
  return @($all[$at..($all.Count - 1)]) + @(if ($at) { $all[0..($at - 1)] })
}
function Get-RotatedFolders($parent, $start) {
  $all = @((Get-Item -LiteralPath $parent -Force).EnumerateDirectories())
  return Get-Rotated $all @($all | ForEach-Object { $_.Name }) $start
}
function Test-JanitorCap($kind, $name, $limit) {
  if ($script:clock.Elapsed.TotalSeconds -lt $limit) { return $false }
  Log "time cap: stopped the $kind folders at $name after $([int]$script:clock.Elapsed.TotalSeconds) s (cap $limit s); the next run starts there"
  $script:resume[$kind] = $name
  return $true
}
function Write-FolderTime($dir, $since) {
  $s = [int]($script:clock.Elapsed.TotalSeconds - $since)
  if ($s -ge 10 -or $test) { Log "folder time: $($dir.FullName) $s s" }
}

$trigger = $args[0]
if ($trigger -eq '--install-task') {
  if ($args.Count -gt 2 -or ($args.Count -eq 2 -and $args[1] -ne '--dry-run')) {
    Write-Host 'usage: janitor_task.bat [--dry-run]'
    exit 2
  }
  try { Install-JanitorTask ($args.Count -eq 2) }
  catch { Write-Host "janitor task setup failed: $($_.Exception.Message)"; exit 1 }
  exit 0
}
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
$soloClaim = $false
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
    $soloClaim = Test-JanitorGpuClaim -SoloOnly
    # A solo deferral leaves the nightly date or hourly allowance available for a later run.
    if ($automatic -and -not $soloClaim -and -not (Reserve-AutomaticRun $lock $trigger $now $night)) { exit 0 }
    $logPath = Join-Path $root "janitor_$((Get-Date).ToString('yyyyMMdd-HHmm')).txt"
    $logItem = Get-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
    if ($logItem -and ($logItem -isnot [IO.FileInfo] -or ($logItem.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
      throw 'janitor log is not a plain file'
    }
    $script:log = New-Object IO.StreamWriter($logPath, $true, $utf8)
    $script:log.AutoFlush = $true
  }
  if ($soloClaim -and $trigger -eq '--nightly') {
    Log 'deferred nightly: a GPU solo claim is active'
    exit 0
  }
  $mode = if ($dryRun) { 'dry run' } elseif ($automatic) { $trigger } else { 'manual' }
  Log "janitor $mode at $($now.ToString('o'))"
  if ($soloClaim) {
    Log "deferred $($trigger.Substring(2)) disk scans: a GPU solo claim is active"
    exit 0
  }
  $deferJobs = $trigger -eq '--after-job' -and (Test-JanitorGpuClaim)
  if ($deferJobs) { Log 'deferred after-job job-folder pass: a GPU claim is active' }
  $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($root))
  $script:wouldFreeBytes = 0L; $script:wouldFreeCount = 0; $script:cannotRemoveCount = 0
  $script:plannedFreeTally = if ($dryRun) { New-FreeTally }
  $script:clock = [Diagnostics.Stopwatch]::StartNew()
  # Dry runs only (Artoo on PR 1592): a live removal reads the mirror's history fresh for each checkout, as before.
  $script:cacheMirrorCommits = $dryRun
  $capSeconds = 2700
  if ($env:PC_JANITOR_CAP_SECONDS -match '\A[0-9]{1,6}\z') { $capSeconds = [int]$env:PC_JANITOR_CAP_SECONDS }
  $resumePath = Join-Path $root 'janitor_resume.txt'
  $script:resume = Read-JanitorResume $resumePath
  $resumeAt = @{ lane = $script:resume.lane; temp = $script:resume.temp; root = $script:resume.root }
  $script:resume.lane = ''; $script:resume.temp = ''; $script:resume.root = ''
  Log "free space before: $($drive.AvailableFreeSpace) bytes"
  if ($dryRun) { Write-LegacyJobRepos $root }
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
  $runs = @(Get-CleanupRuns $root)
  $recordedScratch = Get-RecordedTempScratch $runs $temp
  # Check old runners once, and take each current issue lock again immediately before making its decision.
  $activeLegacy = @(Get-ActiveLegacyIssues $runs)
  $script:commandLines = Get-CommandLines
  # The board lanes and the recorded Workhorse runs share the first quarter of the budget, one lane at a time, in turn
  # from where the last capped run stopped (review of PR 1592: they ran before any cap check).
  $lanes = @(@('board','board_b','board_c','board_d') + $slots + @('work217-runs'))
  foreach ($lane in (Get-Rotated $lanes $lanes $resumeAt.lane)) {
    if (Test-JanitorCap 'lane' $lane ([int]($capSeconds / 4))) { break }
    Assert-GpuQuiet -SoloOnly
    if ($lane -eq 'work217-runs') {
      Clear-WorkRunRepos @($runs | Where-Object { $_.Lane -eq 'work217' }) $mirror $dryRun $now $temp $salvageRoot $activeLegacy
      continue
    }
    $board = Join-Path $root $lane
    if (-not (Test-Path -LiteralPath $board -PathType Container)) { continue }
    try { Remove-OlderKeptRepos $board $mirror $dryRun $now $salvageRoot }
    catch { Log "kept lane $board (scan unavailable: $($_.Exception.Message))" }
  }
  Log "time: lanes and runner records done at $([int]$script:clock.Elapsed.TotalSeconds) s"
  foreach ($dir in (Get-RotatedFolders $temp $resumeAt.temp)) {
    if (Test-JanitorCap 'temp' $dir.Name ([int]($capSeconds / 2))) { break }
    $since = $script:clock.Elapsed.TotalSeconds
    Assert-GpuQuiet -SoloOnly
    $records = $recordedScratch[$dir.FullName]
    $hasOwner = -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
      (Test-Path -LiteralPath (Join-Path $dir.FullName $scratchOwnerFile))
    if (-not $hasOwner -and -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $dir.Name -match $legacyScratch) {
      # Older scratch from before ownership tokens: our exact tool names, a day untouched, no process naming it.
      Clear-ScratchFolder $dir $Matches['issue'] 'scratch named by our tools' 24 $temp $now $dryRun $activeLegacy -Legacy
      Write-FolderTime $dir $since
      continue
    }
    if (-not $records -and -not $hasOwner -and $dir.Name -notmatch '^(voidsworn|issue|tune2-|stage7-checked-)') { continue }
    $issue = if ($records) { $records[0].Issue } elseif ($hasOwner -and
        $dir.Name -match '\Avoidsworn-run-([1-9][0-9]*)-[0-9a-f]{32}\z') { $Matches[1] }
    Clear-ScratchFolder $dir $issue 'owned TEMP scratch' 3 $temp $now $dryRun $activeLegacy -TempScratch -Records $records -HasOwner $hasOwner
    Write-FolderTime $dir $since
  }
  Log "time: TEMP folders done at $([int]$script:clock.Elapsed.TotalSeconds) s"
  $jobFolders = if (-not $deferJobs) { Get-RotatedFolders $root $resumeAt.root }
  if ($deferJobs) { $script:resume.root = $resumeAt.root }
  foreach ($dir in $jobFolders) {
    # Issue 1396: suffixed job folders (opus1369b, opus1211_run6, opus1373probe2) and playtest folders (pt1120c) too.
    $issue = ''
    if ($dir.Name -match $helperJobName) { $issue = $Matches['issue'] }
    elseif ($dir.Name -notmatch $playtestJobName) { continue }
    # A linked job folder is never entered: no lease or file inside it is opened (review of PR 1592).
    if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { Log "$(if ($dryRun) { 'would keep' } else { 'kept' }) $($dir.FullName) (a linked job folder is never entered)"; continue }
    if (Test-JanitorCap 'root' $dir.Name $capSeconds) { break }
    $since = $script:clock.Elapsed.TotalSeconds
    if (Test-JanitorGpuClaim) {
      Log "deferred $($trigger.Substring(2)) job-folder pass: a GPU claim is active"
      $deferJobs = $true
      $script:resume.root = $dir.Name
      break
    }
    $script:helperGone = $false
    Clear-ScratchFolder $dir $issue 'helper folder with its results relayed' 24 $temp $now $dryRun $activeLegacy -Helper -Mirror $mirror
    if (-not $script:helperGone) {
      Invoke-JobRelayCleanup $dir $issue $temp $dryRun $activeLegacy
      Clear-JobCheckouts $dir $issue $temp $now $dryRun $activeLegacy $mirror
    }
    Write-FolderTime $dir $since
  }
  if (-not $deferJobs) { Log "time: job folders done at $([int]$script:clock.Elapsed.TotalSeconds) s" }
  if (-not $dryRun) {
    $lines = @(foreach ($k in @('lane','temp','root')) { if ($script:resume[$k]) { "$k $($script:resume[$k])" } })
    Write-JanitorResume $resumePath ([string[]]$lines)
  }
} catch {
  if ($script:log) { Log "janitor stopped: $($_.Exception.Message)" }
  else { Write-Host "janitor could not start: $($_.Exception.Message)" }
  exit 1
} finally {
  if ($drive) {
    if ($script:plannedFreeTally) { $script:wouldFreeBytes += (Complete-FreeTally $script:plannedFreeTally).Free }
    $verb = if ($dryRun) { 'would be freed' } else { 'freed' }
    Log ("space ${verb}: $($script:wouldFreeBytes) bytes ({0:N1} GB) by $($script:wouldFreeCount) removals; hard links shared outside the removal set are not counted; $($script:cannotRemoveCount) folders another account owns cannot be removed and are not counted" -f ($script:wouldFreeBytes / 1GB))
    Log "free space after: $($drive.AvailableFreeSpace) bytes"
    Log 'all done'
  }
  if ($script:log) { $script:log.Dispose() }
  if ($lock) { $lock.Dispose() }
}
exit 0
