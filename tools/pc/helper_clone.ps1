# Issue 1180 (Board, Nov 20): one shared base for helper PC jobs, so a helper no longer downloads its own copy.
# Usage (from helper_clone.bat):
#   helper_clone.ps1 <job folder> <branch> [ships] [job steps .bat]
#   helper_clone.ps1 <job folder> -Release        (helper_clone.bat <job folder> release)
# Run mode:
#   - Holds a lease on <job folder>\.voidsworn-run-active for the whole run, the job steps included, so a second run (or
#     a release, or the janitor) cannot switch or clear this checkout while it is in use (Artoo on PR 1275).
#   - Refreshes the shared repo-mirror.git under the same lock as runner_common.ps1 and ship_job.bat.
#   - Makes <job folder>\repo once with `git clone --local` (Git objects are hardlinked from the mirror, near zero bytes),
#     then reuses it on later runs: fetch the branch and switch to it. A clone with local changes or local-only commits
#     is never reset; the run stops and says so.
#   - With "ships": first checks every ship or gen file the copy would replace. A file that differs from the shared build
#     and from this folder's own last copy (ships_copied.txt) is local work: nothing is copied and the run stops (Artoo
#     on PR 1275). Then get_ship_files.bat copies from build\godot and checks the manifest. Ship files are copied, not
#     hardlinked, because stage 7 and other tools rewrite those files in place. ships_copied.txt records what was copied.
#   - Runs the job steps (cmd /c "<steps>" steps) inside the lease and exits with their exit code.
# Release mode (the Board runs it after relaying the results; R326, a job's own leftovers):
#   - Only when the latest attempt (attempt.txt) ran its job steps and they exited 0 (out\attempt_result.txt reads
#     "<id> steps exit 0"; a setup-only call never qualifies), out\result.txt says PASS
#     and no FAILED, and every file in the out folders is committed on a
#     board/pc-out-* relay branch in the mirror. Then removes the ship and gen copies this folder made (only files whose
#     bytes still match ships_copied.txt; any other file is listed and kept) and repo\godot\.godot (the import cache).
#     The clone itself stays for reuse. On FAILED nothing is removed, so the Board can read it.
# Writes and removes only under <job folder>, plus the mirror refresh.
param([Parameter(Mandatory)][string]$JobDir, [string]$Branch = '', [string]$Ships = '', [string]$Steps = '', [switch]$Release)
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$sep = [IO.Path]::DirectorySeparatorChar
$unix = $PSVersionTable.Platform -eq 'Unix'
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($test) { $source = $env:PC_TEST_SOURCE }
$build = Join-Path (Join-Path $vt 'build') 'godot'
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
$release = [bool]$Release
if (-not $release -and ($Branch -notmatch '\A[A-Za-z0-9._/][A-Za-z0-9._/-]*\z' -or $Branch.Contains('..'))) { throw "branch name not accepted: $Branch" }
$job = [IO.Path]::GetFullPath($JobDir).TrimEnd('\', '/')
if (-not $job.StartsWith($vt + $sep, [StringComparison]::OrdinalIgnoreCase)) { throw "job folder must be under $vt" }
$repo = Join-Path $job 'repo'
$godot = Join-Path $repo 'godot'
$record = Join-Path $job 'ships_copied.txt'
function Run-Git {
  # PowerShell 5.1 turns native stderr into errors under 'Stop'; read it as text instead.
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
function Hash($path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() }
function Assert-NotLinked($path) {
  for ($item = Get-Item -LiteralPath $path -Force; $item; $item = $item.Parent) {
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "linked path, kept as is: $($item.FullName)" }
    if ($item.FullName.TrimEnd('\', '/') -eq $vt) { break }
  }
}
function Find-Link($dir) {
  # The first link inside $dir, found without following any link (PowerShell 5.1 recursion can follow a junction).
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push((Get-Item -LiteralPath $dir -Force))
  while ($pending.Count) {
    foreach ($item in $pending.Pop().EnumerateFileSystemInfos()) {
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $item.FullName }
      if ($item -is [IO.DirectoryInfo]) { $pending.Push($item) }
    }
  }
  return $null
}
function Refresh-Mirror {
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  while (-not $lock) {
    try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
  }
  try {
    if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init -q --bare $mirror | Out-Null; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source | Out-Null }
    if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
    Write-Output "refreshing shared mirror $mirror"
    Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
    Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main | Out-Null
    & $args[0]
  } finally { $lock.Dispose() }
}
function Get-ShipSources {
  # Exactly what get_ship_files.bat copies: all of gen, and assets\ships without manifest.json, README.md, a4_props.gd,
  # *.uid and the test and previews folders (its robocopy /XF and /XD lists).
  $list = @()
  foreach ($part in @('gen', ('assets' + $sep + 'ships'))) {
    $root = Join-Path $build $part
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    foreach ($file in [IO.Directory]::EnumerateFiles($root, '*', [IO.SearchOption]::AllDirectories)) {
      $rel = $file.Substring($root.Length + 1)
      $names = $rel.Split([char[]]@('\', '/'))
      if ($part -ne 'gen') {
        if ($names[-1] -in @('manifest.json', 'README.md', 'a4_props.gd') -or $names[-1] -like '*.uid') { continue }
        if ($names.Count -gt 1 -and @($names[0..($names.Count - 2)] | Where-Object { $_ -in @('test', 'previews') }).Count) { continue }
      }
      $list += ,[pscustomobject]@{ Rel = (Join-Path $part $rel); Source = $file }
    }
  }
  return $list
}
function Read-Record {
  $map = @{}
  if (Test-Path -LiteralPath $record) {
    foreach ($line in [IO.File]::ReadAllLines($record)) { if ($line -match '\A([0-9a-f]{64})  (.+)\z') { $map[$Matches[2]] = $Matches[1] } }
  }
  return $map
}
function Copy-Ships {
  $sources = @(Get-ShipSources)
  $recorded = Read-Record
  $unique = @()
  foreach ($s in $sources) {
    $dest = Join-Path $godot $s.Rel
    $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    if ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $unique += "$($s.Rel) (not a plain file)"; continue }
    $hash = Hash $dest
    if ($recorded[$s.Rel] -eq $hash) { continue }
    if ($item.Length -eq (Get-Item -LiteralPath $s.Source).Length -and $hash -eq (Hash $s.Source)) { continue }
    $unique += $s.Rel
  }
  if ($unique.Count) {
    foreach ($u in ($unique | Select-Object -First 20)) { Write-Output "local ship or gen file kept: $u" }
    throw "$($unique.Count) ship or gen files in the clone differ from the shared build and from this folder's last copy (local work); nothing copied"
  }
  if ($test) {
    foreach ($s in $sources) {
      $dest = Join-Path $godot $s.Rel
      $null = [IO.Directory]::CreateDirectory((Split-Path -Parent $dest))
      Copy-Item -LiteralPath $s.Source -Destination $dest -Force
    }
  } else {
    & cmd.exe /d /c "`"$repo\tools\pc\get_ship_files.bat`" `"$build`" `"$repo`""
    if ($LASTEXITCODE -ne 0) { throw "get_ship_files.bat failed (exit $LASTEXITCODE)" }
  }
  $lines = foreach ($s in $sources) { $dest = Join-Path $godot $s.Rel; if (Test-Path -LiteralPath $dest) { "$(Hash $dest)  $($s.Rel)" } }
  [IO.File]::WriteAllLines($record, [string[]]@($lines))
  Write-Output "ship and gen copies recorded: $(@($lines).Count) files in $record"
}
function Assert-Relayed {
  $outDirs = @(Get-ChildItem -LiteralPath $job -Directory -Force | Where-Object { $_.Name -like 'out*' })
  # Bound to the latest attempt (Artoo on PR 1275): attempt.txt names it, and out\attempt_result.txt must carry that ID
  # with "steps exit 0", written by this script after that attempt's own steps. A retry that failed early, or a
  # setup-only call (no steps), has a new ID without it, so an older PASS never counts.
  $attemptFile = Join-Path $job 'attempt.txt'
  $attempt = if (Test-Path -LiteralPath $attemptFile) { [IO.File]::ReadAllText($attemptFile).Trim() } else { '' }
  if ($attempt -notmatch '\A[0-9a-f]{32}\z') { throw 'no attempt.txt from helper_clone; nothing removed' }
  $attemptResult = Join-Path (Join-Path $job 'out') 'attempt_result.txt'
  $last = if (Test-Path -LiteralPath $attemptResult) { [IO.File]::ReadAllText($attemptResult).Trim() } else { '' }
  if ($last -cne "$attempt steps exit 0") { throw "the latest attempt $attempt did not pass its job steps (out\attempt_result.txt: '$last'); nothing removed" }
  $result = Join-Path (Join-Path $job 'out') 'result.txt'
  if (-not (Test-Path -LiteralPath $result)) { throw 'no out\result.txt; nothing removed' }
  $text = [IO.File]::ReadAllLines($result)
  if (@($text | Where-Object { $_ -match '\AFAILED' }).Count -or -not @($text | Where-Object { $_ -match '\APASS' }).Count) {
    throw 'result.txt does not say PASS (or says FAILED); kept for the Board to read'
  }
  $files = @($outDirs | ForEach-Object { Assert-NotLinked $_.FullName; $_.EnumerateFiles('*', [IO.SearchOption]::AllDirectories) })
  $receipts = New-Object 'Collections.Generic.HashSet[string]'
  if (@(Run-Git --git-dir $mirror for-each-ref '--format=%(objectname)' 'refs/heads/board/pc-out-*').Count) {
    foreach ($line in @(Run-Git --git-dir $mirror rev-list --objects '--glob=refs/heads/board/pc-out-*')) { $null = $receipts.Add(($line -split ' ', 2)[0]) }
  }
  # Issue 1657: blobs on the private relay repo (its own mirror, branches pc-out-*) count the same way.
  $relayMirror = Join-Path (Split-Path -Parent $mirror) 'relay-mirror.git'
  if ((Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD')) -and @(Run-Git --git-dir $relayMirror for-each-ref '--format=%(objectname)' 'refs/heads/pc-out-*').Count) {
    foreach ($line in @(Run-Git --git-dir $relayMirror rev-list --objects '--glob=refs/heads/pc-out-*')) { $null = $receipts.Add(($line -split ' ', 2)[0]) }
  }
  $missing = @()
  foreach ($f in $files) { if (-not $receipts.Contains((Run-Git --git-dir $mirror hash-object --no-filters -- $f.FullName))) { $missing += $f.FullName } }
  if ($missing.Count) {
    foreach ($m in ($missing | Select-Object -First 20)) { Write-Output "not on a relay branch yet: $m" }
    throw "$($missing.Count) of $($files.Count) out files are not on a relay branch (board/pc-out or the relay repo); nothing removed"
  }
  Write-Output "results relayed: all $($files.Count) out files are on a board/pc-out branch"
}
function Release-Copies {
  $recorded = Read-Record
  $removed = 0; $bytes = 0L; $kept = @()
  foreach ($rel in @($recorded.Keys)) {
    $dest = Join-Path $godot $rel
    $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    if ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Hash $dest) -ne $recorded[$rel]) { $kept += $rel; continue }
    $bytes += $item.Length
    [IO.File]::Delete($dest); $removed++
  }
  foreach ($k in ($kept | Select-Object -First 20)) { Write-Output "kept (changed since it was copied): $k" }
  if ($kept.Count) { [IO.File]::WriteAllLines($record, [string[]]@($kept | ForEach-Object { "$($recorded[$_])  $_" })) }
  elseif (Test-Path -LiteralPath $record) { [IO.File]::Delete($record) }
  Write-Output "released $removed ship and gen copies ($bytes bytes); $($kept.Count) kept"
  $cache = Join-Path $godot '.godot'
  if (Test-Path -LiteralPath $cache) {
    Assert-NotLinked $cache
    $link = Find-Link $cache
    if ($link) { Write-Output "import cache kept: it holds a link ($link)" }
    else { Remove-Item -LiteralPath $cache -Recurse -Force; Write-Output "import cache removed: $cache" }
  }
}

$null = [IO.Directory]::CreateDirectory($job)
Assert-NotLinked $job
try { $lease = [IO.File]::Open((Join-Path $job '.voidsworn-run-active'), 'OpenOrCreate', 'ReadWrite', 'None') }
catch [IO.IOException] { Write-Output "STOP: another run is using $job right now; nothing changed"; exit 1 }
$attempt = $null; $code = 1; $stepsRan = $false
try {
  if ($release) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) { throw "no clone in $job; nothing to release" }
    Refresh-Mirror { Assert-Relayed }
    Release-Copies
    Write-Output "release done; the clone stays for reuse: $repo"
    exit 0
  }
  # Each run is one attempt with its own ID; release accepts only the latest attempt's exit 0, relayed exactly.
  $attempt = [guid]::NewGuid().ToString('N')
  $null = [IO.Directory]::CreateDirectory((Join-Path $job 'out'))
  $attemptResult = Join-Path (Join-Path $job 'out') 'attempt_result.txt'
  if (Test-Path -LiteralPath $attemptResult) { [IO.File]::Delete($attemptResult) }
  [IO.File]::WriteAllText((Join-Path $job 'attempt.txt'), "$attempt`n")
  Write-Output "attempt $attempt"
  $script:fresh = $false
  Refresh-Mirror {
    $script:fresh = -not (Test-Path -LiteralPath (Join-Path $repo '.git'))
    if ($script:fresh) {
      Write-Output "local clone $repo (objects shared with the mirror)"
      Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null
    }
    $depth = @(); if ((Run-Git -C $repo rev-parse --is-shallow-repository) -eq 'true') { $depth = @('--unshallow') }
    Run-Git -C $repo fetch -q --no-tags @depth $mirror "+refs/heads/${Branch}:refs/remotes/origin/$Branch" | Out-Null
  }
  # Never reset someone's work: stop if the clone has tracked edits, staged changes or commits not on any mirror branch.
  if (-not $script:fresh) {
    $dirty = @(Run-Git -C $repo status --porcelain --untracked-files=no)
    if ($dirty.Count) { throw "clone has local changes, kept as is: $($dirty -join '; ')" }
    $local = @(Run-Git -C $repo rev-list HEAD --not --remotes=origin)
    if ($local.Count) { throw "clone has $($local.Count) commits not on any mirror branch, kept as is" }
  }
  Run-Git -C $repo checkout -q --detach "refs/remotes/origin/$Branch" | Out-Null
  $commit = (Run-Git -C $repo rev-parse HEAD) | Select-Object -First 1
  [IO.File]::WriteAllText((Join-Path $job 'repo_commit.txt'), "$commit`n")
  Write-Output "helper clone $repo at $commit ($Branch)"
  if ($Ships -eq 'ships') { Copy-Ships }
  if ($Steps) {
    Write-Output "job steps: $Steps (the lease is held until they end)"
    if ($unix) { & sh $Steps steps } else { & cmd.exe /d /c "`"$Steps`" steps" }
    $code = $LASTEXITCODE; $stepsRan = $true
    Write-Output "job steps exit $code"
    exit $code
  }
  $code = 0
} catch {
  # One plain line the caller's log (and the Board) can read; PowerShell's own error view wraps and truncates it.
  Write-Output "STOP: $($_.Exception.Message)"
  $code = 1
  exit 1
} finally {
  # "steps exit N" only when this attempt ran its job steps; a setup-only call or an early stop is never releasable.
  $line = if ($stepsRan) { "$attempt steps exit $code" } elseif ($code -eq 0) { "$attempt setup only" } else { "$attempt stopped exit $code" }
  if ($attempt) { [IO.File]::WriteAllText((Join-Path (Join-Path $job 'out') 'attempt_result.txt'), "$line`n") }
  $lease.Dispose()
}
