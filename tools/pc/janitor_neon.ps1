# R455. Only registered, published Neon worktrees and their exact per-thread artifacts.
function Assert-NeonClosed {
  # The SQLite projection is read-only. Do not race the app or a headless T3 server re-opening a thread.
  $processes = Get-CommandLines
  if ($null -eq $processes) { throw 'T3 processes could not be checked' }
  if (@($processes | Where-Object { $_.Name -match '^(T3 Code\b|t3(?:\.exe|\.cmd|$))' -or
      $_.Line -match '(?i)([\\/]t3code[\\/]|[\\/]\.t3[\\/]|[\\/]t3\.cmd\b|[\\/]server\.asar[\\/])' }).Count) {
    throw 'T3 is open'
  }
}
function Get-NeonCandidates($workspace, $db, $now) {
  $node = Join-Path $root 'node/node.exe'
  if (-not (Test-Path -LiteralPath $node -PathType Leaf)) { $node = 'node' }
  $lines = @(& $node --no-warnings --experimental-sqlite (Join-Path $PSScriptRoot 'neon_idle_threads.js') $db.FullName $workspace.FullName ($now.AddDays(-1).ToString('o')))
  if ($LASTEXITCODE -ne 0) { throw 'could not read finished T3 threads' }
  foreach ($line in $lines) { $line | ConvertFrom-Json }
}
function Get-NeonRemote($workspace) {
  $origin = @(Read-CleanupGit @('-C',$workspace.FullName,'remote','get-url','origin'))
  if ($gitExit -ne 0 -or $origin.Count -ne 1 -or (-not $test -and
      $origin[0] -notmatch '\A(?:https://github\.com/|git@github\.com:)rcbailey12/voidsworn(?:\.git)?\z')) {
    throw 'Neon checkout has an unrecognized origin'
  }
  $result = Invoke-BoundedMirrorGit @('-C',$workspace.FullName,'ls-remote','--heads','origin','main','neon/issue-*') 60 'Neon published branches' -NativeGit
  if ($result.Code -ne 0) { throw 'Neon origin refs could not be verified' }
  $refs = @{}
  foreach ($line in ("$($result.Lines -join "`n")" -split "`r?`n")) {
    if ($line -match '\A([0-9a-f]{40})\trefs/heads/(.+)\z') { $refs[$Matches[2]] = $Matches[1] }
  }
  return $refs
}
function Clear-NeonThreadData($thread, $data, $now, $dryRun) {
  # The Board can relay a staged copy with relay_push.ps1 <neon-issue-N> <thread UUID folder> results.
  # Use the thread's delivery branch name (slash changed to hyphen), including any run suffix.
  $relayBranch = $thread.branch.Replace('/', '-')
  $relayMirror = Join-Path $root 'relay-mirror.git'
  foreach ($id in $thread.ids) {
    if ($id -notmatch '\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z') { continue }
    foreach ($rel in @("attachments/$id", "logs/provider/events.$id.log")) {
      $relayLock = $null
      try {
        $attachment = $rel -ceq "attachments/$id"
        $parentPath = Join-Path $data.FullName (Split-Path -Parent $rel)
        $parent = Get-Item -LiteralPath $parentPath -Force -ErrorAction SilentlyContinue
        if (-not $parent) { continue }
        Assert-PlainDirectory $parent
        Assert-PlainDirectory $parent.Parent
        $item = Get-Item -LiteralPath (Join-Path $data.FullName $rel) -Force -ErrorAction SilentlyContinue
        if (-not $item) { continue }
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Get-BoardKeepReason $item.FullName)) { continue }
        if ($attachment) { Assert-PlainDirectory $item }
        elseif ($item -isnot [IO.FileInfo]) { throw 'provider log is not a plain file' }
        Assert-NoProcessUses $parent
        if ($attachment) { $stats = Measure-CleanupDirectory $item }
        else {
          $tally = New-FreeTally
          Add-FreeTally $tally $item
          $stats = @{ Latest = $item.LastWriteTimeUtc; FreeBytes = (Complete-FreeTally $tally).Free; FreeTally = $tally }
        }
        if ($stats.Latest -ge $now.AddDays(-1)) { continue }
        if ($attachment) {
          if (-not $dryRun) { $relayLock = Open-CleanupLock ($relayMirror + '.lock') }
          # A published code branch does not back up T3 attachments. Require an exact copy of every file.
          Assert-DirectRelayProof $item $relayBranch $relayMirror -RequireAllFiles
        }
        Assert-GpuQuiet -SoloOnly
        if (Cleanup-Paused) { throw 'PC pause is active' }
        if (-not $dryRun) {
          Assert-NeonClosed
          if (Cleanup-Paused) { throw 'PC pause is active' }
          if ($attachment) {
            $current = Measure-CleanupDirectory (Get-Item -LiteralPath $item.FullName -Force)
            if ($current.Latest -ne $stats.Latest -or $current.Bytes -ne $stats.Bytes) { throw 'attachments changed during relay proof' }
            Remove-CleanupDirectory $item
          } else { Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop }
        }
        Add-WouldFree $stats
        Log "Neon thread data $(if ($dryRun) { 'would remove' } else { 'removed' }): $($item.FullName)"
      } catch { Log "Neon thread data kept: $rel ($($_.Exception.Message))" }
      finally { if ($relayLock) { $relayLock.Dispose() } }
    }
  }
}
function Clear-NeonThreads($now, $dryRun, $start, $limit) {
  $homeDir = Get-Item -LiteralPath (Join-Path $env:USERPROFILE '.t3') -Force -ErrorAction SilentlyContinue
  $workspace = Get-Item -LiteralPath (Join-Path $root 't3_neon') -Force -ErrorAction SilentlyContinue
  if (-not $homeDir -or -not $workspace) { return }
  $stateRead = $null
  try {
    foreach ($dir in @($homeDir, $workspace)) { Assert-PlainDirectory $dir }
    Assert-NeonClosed
    $data = Get-Item -LiteralPath (Join-Path $homeDir.FullName 'userdata') -Force
    Assert-PlainDirectory $data
    $managed = Join-Path $homeDir.FullName 'worktrees'
    Assert-PlainDirectory (Get-Item -LiteralPath $managed -Force)
    $worktreeRoot = Get-Item -LiteralPath (Join-Path $managed 't3_neon') -Force
    Assert-PlainDirectory $worktreeRoot
    $db = Get-Item -LiteralPath (Join-Path $data.FullName 'statev2.sqlite') -Force
    if ($db -isnot [IO.FileInfo] -or ($db.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'T3 state is not a plain file' }
    # On Windows, an existing T3 writer blocks this open and a new T3 server cannot open the DB for writing while
    # the read lease is held. Inspect with SQLite read-only. Neither the database nor shared settings are removed.
    if (-not $dryRun -and [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
      $stateRead = [IO.File]::Open($db.FullName, 'Open', 'Read', 'Read')
    }
    $threads = @(Get-NeonCandidates $workspace $db $now)
    if (-not $threads.Count) { return }
    $worktrees = @(Read-CleanupGit @('-C',$workspace.FullName,'-c','core.quotePath=false','worktree','list','--porcelain'))
    if ($gitExit -ne 0) { throw 'Git worktrees could not be read' }
    $registered = @{}
    foreach ($record in ((($worktrees -join "`n") + "`n") -split "`n`n")) {
      if ($record.TrimEnd("`r", "`n") -match '\Aworktree (.+)\nHEAD ([0-9a-f]{40})\nbranch refs/heads/(.+)\z') {
        $registered[[IO.Path]::GetFullPath($Matches[1])] = @{ Head = $Matches[2]; Branch = $Matches[3] }
      }
    }
    $remote = $null
    foreach ($thread in (Get-Rotated $threads @($threads | ForEach-Object { $_.path }) $start)) {
      if (Test-JanitorCap 'neon' $thread.path $limit) { break }
      Assert-GpuQuiet -SoloOnly
      try {
        $full = [IO.Path]::GetFullPath($thread.path)
        if ((Split-Path -Parent $full) -ne $worktreeRoot.FullName -or
            (Split-Path -Leaf $full) -notmatch '\Aneon-issue-[1-9][0-9]*-[0-9a-f]{16}\z' -or (Get-BoardKeepReason $full)) { continue }
        $dir = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
        if ($dir) {
          Assert-PlainDirectory $dir
          Assert-NoProcessUses $dir
          $git = $registered[$full]
          if (-not $git -or $git.Branch -cne $thread.branch) { throw 'not the registered Neon branch or worktree is locked' }
          $status = @(Read-CleanupGit @('-C',$full,'status','--porcelain=v1','--untracked-files=all','--ignored','--ignore-submodules=none'))
          if ($gitExit -ne 0 -or $status.Count) { throw 'worktree is not clean, including ignored files' }
          if ($null -eq $remote) { $remote = Get-NeonRemote $workspace }
          $reflog = @(Read-CleanupGit @('-C',$full,'reflog','show','--format=%H','HEAD'))
          if ($gitExit -ne 0 -or @($reflog | Where-Object { $_ -notmatch '\A[0-9a-f]{40}\z' }).Count) { throw 'worktree history could not be read' }
          foreach ($commit in @($git.Head; $reflog) | Select-Object -Unique) {
            $pushed = $false
            foreach ($tip in @($remote[$thread.branch], $remote['main']) | Where-Object { $_ }) {
              if ($commit -eq $tip) { $pushed = $true; break }
              $null = Read-CleanupGit @('-C',$workspace.FullName,'merge-base','--is-ancestor',$commit,$tip)
              if ($gitExit -eq 0) { $pushed = $true; break }
            }
            if (-not $pushed) { throw 'worktree HEAD or reflog is not proven on origin' }
          }
          $stats = Measure-CleanupDirectory $dir -Checkout
          if ($stats.WorktreeLatest -ge $now.AddDays(-1)) { throw 'worktree files changed in the last day' }
          if (Cleanup-Paused) { throw 'PC pause is active' }
          if (-not $dryRun) {
            Assert-NeonClosed
            $head = @(Read-CleanupGit @('-C',$full,'rev-parse','HEAD'))
            if ($gitExit -ne 0 -or $head.Count -ne 1 -or $head[0] -ne $git.Head) { throw 'worktree HEAD changed' }
            Assert-GpuQuiet -SoloOnly
            if (Cleanup-Paused) { throw 'PC pause is active' }
            # Never --force: Git checks for new edits and removes its own worktree registration.
            $null = Read-CleanupGit @('-C',$workspace.FullName,'worktree','remove','--',$full)
            if ($gitExit -ne 0 -or (Test-Path -LiteralPath $full)) { throw 'Git did not remove the worktree' }
          }
          Add-WouldFree $stats
          Log "Neon worktree $(if ($dryRun) { 'would remove' } else { 'removed' }): $full ($(Format-CleanupSize $stats))"
        }
        Clear-NeonThreadData $thread $data $now $dryRun
      } catch { Log "Neon kept: $($thread.path) ($($_.Exception.Message))" }
    }
  } catch { Log "Neon pass kept: $($_.Exception.Message)" }
  finally { if ($stateRead) { $stateRead.Dispose() } }
}
