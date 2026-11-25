# R455 current-result proof. A skipped media entry is an inventory item, never a copy.
function Assert-NotPaidTakes($dir) {
  # elevenlabs_gen.js writes both files beside the raw paid takes, even if a later relay carries the whole wave.
  if ((Test-Path -LiteralPath (Join-Path $dir.FullName 'receipts.jsonl') -PathType Leaf) -and
      (Test-Path -LiteralPath (Join-Path $dir.FullName 'manifest.jsonl') -PathType Leaf)) {
    throw "ElevenLabs take folder is kept: $($dir.FullName)"
  }
}
function Read-OriginRelayRefs($pattern) {
  $url = 'https://github.com/rcbailey12/voidsworn-relay'
  if ($test -and $env:PC_TEST_RELAY_SOURCE) { $url = $env:PC_TEST_RELAY_SOURCE }
  $refs = Invoke-BoundedMirrorGit @('ls-remote','--heads',$url,$pattern) 60 'current relay branches' -NativeGit
  if ($refs.Code -ne 0) { throw 'relay branches could not be checked on origin' }
  $tips = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  foreach ($line in (($refs.Lines -join "`n") -split "`r?`n")) {
    if ($line -cmatch '\A([0-9a-f]{40})\t(refs/heads/pc-out-.+)\z') { $tips[$Matches[2]] = $Matches[1] }
  }
  return ,$tips
}
function Get-DirectRelayTree($branch, $leaf, $relayMirror, $dryRun) {
  if (-not (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD') -PathType Leaf)) { throw 'relay mirror is not present' }
  Assert-PlainDirectory (Get-Item -LiteralPath $relayMirror -Force)
  $ref = "refs/heads/pc-out-$branch"
  $local = @(Read-CleanupGit @('--git-dir',$relayMirror,'rev-parse','--verify',$ref))
  if ($gitExit -ne 0 -or $local.Count -ne 1 -or $local[0] -notmatch '\A[0-9a-f]{40}\z') { throw 'no matching relay branch in the mirror' }
  # Live callers hold the relay writers' lock through proof and removal. Never reuse a remote answer for a live delete.
  $tips = if ($dryRun) {
    if ($null -eq $script:directRelayRefs) { $script:directRelayRefs = Read-OriginRelayRefs 'refs/heads/pc-out-*' }
    ,$script:directRelayRefs
  } else { ,(Read-OriginRelayRefs $ref) }
  if ($tips[$ref] -cne $local[0]) { throw 'origin does not confirm this relay tip' }
  $tree = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  $lines = @(Read-CleanupGit @('--git-dir',$relayMirror,'-c','core.quotepath=false','ls-tree','-r','-t',$local[0],'--',"$leaf/"))
  if ($gitExit -ne 0 -or -not $lines.Count) { throw 'no result tree in the confirmed relay' }
  foreach ($line in $lines) {
    if ($line -notmatch '\A(100644|100755|040000|120000|160000) (blob|tree|commit) ([0-9a-f]{40})\t(.+)\z') { throw 'unrecognized relay tree entry' }
    $tree[$Matches[4]] = if ($Matches[1] -in @('100644','100755')) { $Matches[3] } else { '' }
  }
  return ,$tree
}
function Assert-DirectRelayProof($dir, $branch, $relayMirror, $dryRun, [switch]$RequireAllFiles) {
  $leaf = $dir.Name
  $tree = Get-DirectRelayTree $branch $leaf $relayMirror $dryRun
  $listed = @()
  $key = "$leaf/relay_manifest/skipped_cache_folders.txt"
  if (-not $RequireAllFiles -and $tree.ContainsKey($key) -and $tree[$key]) {
    $listed = @(Read-CleanupGit @('--git-dir',$relayMirror,'cat-file','blob',$tree[$key]))
    if ($gitExit -ne 0) { throw 'cache manifest could not be read' }
  }
  $need = New-Object 'Collections.Generic.List[IO.FileInfo]'
  $todo = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $todo.Push($dir)
  while ($todo.Count) {
    $parent = $todo.Pop()
    Assert-NotPaidTakes $parent
    foreach ($item in $parent.EnumerateFileSystemInfos()) {
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'result contains a link' }
      if ($item.Name -eq '.git') { throw 'result still contains a Git checkout' }
      $rel = $item.FullName.Substring($dir.FullName.Length + 1).Replace('\','/')
      if ($item -is [IO.DirectoryInfo]) { $todo.Push($item); continue }
      $path = "$leaf/$rel"
      if (-not $tree.ContainsKey($path)) {
        # Known generated caches can be absent only under the exact manifest path. Do not waive pictures, movies,
        # profile data, or even a differing relay entry. The over-10-MB list explicitly says the bytes stayed local.
        $cache = @($listed | Where-Object { $_ -cmatch '(?:^|/)(?:\.godot|shader_cache)\z' -and
          -not $tree.ContainsKey("$leaf/$_") -and $rel.StartsWith("$_/", [StringComparison]::Ordinal) })
        if ($cache.Count -and $item.Extension -notmatch '(?i)^\.(png|jpe?g|gif|webp|bmp|tiff?|exr|avif|heic|svg|mp4|m4v|webm|mov|avi|mkv)$') { continue }
        throw "unproven result stays local: $rel"
      }
      if ($item.Length -gt 100MB) { throw "result is larger than any relay blob: $rel" }
      $need.Add($item)
    }
  }
  if (-not $need.Count) { throw 'no result files to prove on the relay' }
  $hashes = @(Salvage-Git @('--git-dir',$relayMirror,'hash-object','--no-filters','--stdin-paths') @($need | ForEach-Object { $_.FullName }))
  if ($hashes.Count -ne $need.Count) { throw 'result hashes could not be read' }
  for ($i = 0; $i -lt $need.Count; $i++) {
    $key = "$leaf/" + $need[$i].FullName.Substring($dir.FullName.Length + 1).Replace('\','/')
    if ($tree[$key] -ne $hashes[$i]) { throw "result differs on the relay: $key" }
  }
}
function Assert-CleanupSnapshot($dir, $stats) {
  $current = Measure-CleanupDirectory (Get-Item -LiteralPath $dir.FullName -Force) -Snapshot
  if ($current.EntriesByPath.Count -ne $stats.EntriesByPath.Count) { throw 'results changed during relay proof' }
  foreach ($rel in $stats.EntriesByPath.Keys) {
    if ($current.EntriesByPath[$rel] -cne $stats.EntriesByPath[$rel]) { throw 'results changed during relay proof' }
  }
}
function Clear-DirectRelayResult($dir, $guard, $branch, $donePattern, $issue, $dryRun, $activeLegacy, $temp, [switch]$recordedRunner, $doneName = 'done.txt') {
  $lease = $null; $issueLock = $null; $relayLock = $null
  try {
    Assert-PlainDirectory $dir
    Assert-PlainDirectory $guard
    if ((Get-BoardKeepReason $dir.FullName)) { throw 'on the Board keep list' }
    if ($issue) {
      if ($activeLegacy -contains $issue) { throw 'an older runner holds this issue' }
      $issueLock = Open-CleanupLock (Issue-LockPath $issue $temp) $dryRun
    }
    # Hold the shared guard through removal, including when no earlier helper had made a lease file.
    $lease = Open-CleanupLock (Join-Path $guard.FullName '.voidsworn-run-active') $dryRun
    if ($recordedRunner) {
      $status = Get-Item -LiteralPath (Join-Path $guard.FullName 'status.json') -Force
      if ($status -isnot [IO.FileInfo] -or ($status.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'runner status is not a plain file' }
      $state = [IO.File]::ReadAllText($status.FullName) | ConvertFrom-Json
      if (-not $state.finished -or $state.status -notin @('checked_push','unverified','no_changes')) { return }
    } else {
      $done = Get-Item -LiteralPath (Join-Path $dir.FullName $doneName) -Force -ErrorAction SilentlyContinue
      if ($done -isnot [IO.FileInfo] -or ($done.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
          [IO.File]::ReadAllText($done.FullName).Trim() -notmatch $donePattern) { return }
    }
    Assert-NoProcessUses $guard
    Assert-NoProcessUses $dir
    $relayMirror = Join-Path $root 'relay-mirror.git'
    if (-not (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD') -PathType Leaf)) { return }
    if (-not $dryRun) { $relayLock = Open-CleanupLock ($relayMirror + '.lock') }
    $stats = Measure-CleanupDirectory $dir -Snapshot:(-not $dryRun)
    Assert-DirectRelayProof $dir $branch $relayMirror $dryRun
    Assert-GpuQuiet
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if (-not $dryRun) {
      Assert-CleanupSnapshot $dir $stats
      Assert-GpuQuiet
      $processes = Get-CommandLines
      Assert-NoProcessUses $guard $processes
      Assert-NoProcessUses $dir $processes
      if (Cleanup-Paused) { throw 'PC pause is active' }
      Remove-CleanupDirectory $dir
    }
    Add-WouldFree $stats
    Log "relayed results $(if ($dryRun) { 'would remove' } else { 'removed' }): $($dir.FullName) ($(Format-CleanupSize $stats))"
  } catch { Log "relayed results kept: $($dir.FullName) ($($_.Exception.Message))" }
  finally {
    if ($relayLock) { $relayLock.Dispose() }
    if ($lease) { $lease.Dispose() }
    if ($issueLock) { $issueLock.Dispose() }
  }
}
