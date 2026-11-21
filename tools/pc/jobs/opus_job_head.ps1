# Issue 1303: the PowerShell half of opus_job_head.bat (one shared head for helper PC proof bats). Actions:
#   live <folder>                              exit 0 only when the folder is tools_live\<current.txt>\pc\jobs: the
#                                              head must be the installed current main copy, never an older version
#   bundle <head folder> <JW_TOOLS> <JW_HASHES> <premerge 0|1>
#                                              after job_wrap init: JW_TOOLS and JW_HASHES must be the current
#                                              version's pc folder and hashes.txt, and hashes.txt must match tmo.bat,
#                                              run_timeout.ps1 and (unless premerge) this head's .bat and .ps1
#   watchdog <tools pc folder>                 tmo.bat and run_timeout.ps1 must both exist; prints each path and sha256
#   checkout <attempt folder> <name> <sha>     a fresh checkout of one exact commit in <attempt>\<name>, never reused:
#                                              the shared repo-mirror.git (same lock as helper_clone.ps1 and the runners)
#                                              is fetched only when the commit is missing, then `git clone --local` and a
#                                              detached checkout; HEAD must equal the pin
#   tracked <repo>                             fails when any tracked file differs from the pinned commit
#   shipcheck <repo> <out file> [codes]        after the ships copy: every gen\manifest.json ship whose glb was copied
#                                              must name a cached scene that exists and a source stamp ("src": time and
#                                              size of the ship, damage and wreck glb, as build_assets.gd source_stamp)
#                                              equal to the copied files. A publish between the two copies fails here.
#                                              Writes the measured hull identity (code, stamp, scene; sorted) to <out
#                                              file>. Every code in [codes] (spaces or commas) must be a matching ship.
#   shiprecord <repo> <out file> <ships source> right after the ships copy: sha256, size and path of every untracked file
#                                              under godot\gen and godot\assets\ships that has the same bytes in the source, so the tail can prove a copy unchanged even
#                                              after a later publish moves the shared build on (issue 1497)
#   hashes <out file>                          sha256 of Ryan's real battle_opts.json and board_look.cfg
#   dropcheckouts <attempt folder>             the tail, and the Board right after it relays the results: removes the
#                                              pinned checkouts of this attempt and of the same job's earlier attempts
#                                              (voidsworn_test\<job>\out_* beside it), each only when its done.txt says
#                                              PASS and every file in its out_* folders is a blob on a board/pc-out relay
#                                              branch of the shared mirror (fetched when one is missing). A failed or
#                                              unfinished attempt is never touched here (the janitor's rules cover it).
#                                              Only folders listed in that attempt's checkouts.txt by this head's checkout
#                                              step, directly in an attempt folder voidsworn_test\<job>\out_*, that are
#                                              plain folders whose .git\HEAD still names the listed pin, whose local
#                                              branches are all in the mirror, with no stash and nothing staged. Files that
#                                              are not proven rebuildable (Get-KeptWork: the import cache, a ships copy
#                                              matching its copy-time record or the shared build, a byte copy of a tracked
#                                              file, or a sidecar of one of those) are saved first (Save-Leftovers:
#                                              working-file changes as changes.patch, other files copied and read back by
#                                              sha256) into <attempt>\out_<name>\checkout_leftovers, at most 200 MB; more
#                                              than that, a staged change or a nested repo keeps the checkout. Links are
#                                              removed as links, never followed. out_*, the logs and every other file stay.
#                                              The Board's PC pause (gpu_go.txt) removes nothing. A refusal is logged and
#                                              never fails the job. Ends with the GB freed and C: free.
#   dropcache <ship job folder>                ship_job.bat after a PASS: removes only <job>\repo\godot\.godot, Godot's
#                                              import cache (rebuilt by the next import); the clone stays for the publish
#   droprepo <ship job folder> <commit> <code> publish_ship.bat after a published PASS: removes the job's own clone
#                                              <job>\repo when HEAD is <commit>, every file in <job>\out is relayed,
#                                              every local branch and HEAD is in the shared mirror (or is a merge of
#                                              commits that are), there is no stash or staged change, and
#                                              its files are rebuildable or saved first as above into
#                                              <job>\out\checkout_leftovers_repo (installed files under
#                                              godot\assets\ships\<code> that match the job's collected export count as
#                                              rebuildable). The job's out\, the publish folder and build\godot stay.
#   survey                                     read only: every job attempt and ship clone under voidsworn_test with its
#                                              size and what the rules above would do with it. Deletes nothing.
# Nothing else is deleted. Test settings (helper_clone's): PC_TEST_HELPER=1, PC_TEST_HELPER_VT, PC_TEST_SOURCE, PC_TEST_REALU.
param([Parameter(Mandatory)][ValidateSet('live', 'bundle', 'watchdog', 'checkout', 'tracked', 'shipcheck', 'hashes', 'shiprecord', 'dropcheckouts', 'dropcache', 'droprepo', 'survey')][string]$Action,
      [string]$A = '', [string]$B = '', [string]$C = '', [string]$D = '')
$ErrorActionPreference = 'Stop'
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
$sep = [IO.Path]::DirectorySeparatorChar
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($test) { $source = $env:PC_TEST_SOURCE }
$gitExe = 'git.exe'; if ($unix) { $gitExe = @(Get-Command git -CommandType Application)[0].Source }
function Run-Git {
  # PowerShell 5.1 turns native stderr into errors under 'Stop'; read it as text instead.
  $ErrorActionPreference = 'Continue'
  $out = & $gitExe @args 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ') + ': ' + ($out -join ' ')) }; $out }
function Hash($path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() }
function Current-Pc {
  $live = Join-Path $vt 'tools_live'
  $file = Join-Path $live 'current.txt'
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "no $file" }
  $version = ([IO.File]::ReadAllText($file)).Trim()
  if ($version -notmatch '\A[A-Za-z0-9._-]+\z') { throw "tools_live\current.txt is not a version name: $version" }
  return [IO.Path]::GetFullPath((Join-Path (Join-Path $live $version) 'pc')).TrimEnd('\', '/')
}

function Test-Paused {
  # The Board's PC pause line (RULEBOOK 3.11), as scratch_done.ps1 reads it. Tests point PC_CLEANUP_PAUSE_FILE at a fixture.
  $flag = if ($test -and $env:PC_CLEANUP_PAUSE_FILE) { $env:PC_CLEANUP_PAUSE_FILE } else { Join-Path $vt 'gpu_go.txt' }
  if (-not (Test-Path -LiteralPath $flag -PathType Leaf)) { return $false }
  return [string](Get-Content -LiteralPath $flag -TotalCount 1) -match '^GPU not cleared: paused by the Board\b'
}
function Get-KeptWork($repo, $src, $rec, $codeDir, $export) {
  # Every tracked change (staged or not) and every untracked or ignored path that is not proven rebuildable:
  #  - godot/.godot/ (Godot's import cache and editor state);
  #  - a file under godot/gen/ or godot/assets/ships/ whose sha256 matches the ships step's copy-time record ($rec,
  #    issue 1497: a publish later in the night moves the shared build on, and 70 copied ship files then failed the
  #    old live-source check in opus1457main1) or its ships source copy now ($src, the LB_SHIPS the ships step recorded);
  #  - a file under $codeDir (godot/assets/ships/<code>/, ship clones only) byte for byte the same as the file of that
  #    name in the job's collected export ($export), tracked or not;
  #  - a byte copy of a file the pin tracks (the probe copies in godot/bench);
  #  - a .import or .uid sidecar whose own file is tracked or proven above.
  # Anything else, such as a new or changed ship file a job wrote, is listed (Artoo, PR 1326); the caller saves it
  # before any removal (Save-Leftovers) or keeps the checkout.
  $ErrorActionPreference = 'Continue'
  if ($null -eq $rec) { $rec = @{} }
  $raw = (& $gitExe -C $repo -c core.quotepath=false status --porcelain=v1 -z --untracked-files=all --ignored=traditional 2>$null) -join "`n"
  if ($LASTEXITCODE -ne 0) { return @('git status failed') }
  $keep = @(); $copies = @(); $sidecars = @(); $proven = @{}
  foreach ($e in ($raw -split "`0")) {
    if ($e.Length -lt 4) { continue }
    $code = $e.Substring(0, 2); $rel = $e.Substring(3)
    # A staged change is never saved and removed: the index can hold bytes no patch of the working files shows (Artoo on
    # PR 1498: MM after restoring only the file). Save-Leftovers refuses it, so the checkout stays.
    if ($code[0] -ne ' ' -and $code -ne '??' -and $code -ne '!!') { $keep += "staged: $rel"; continue }
    $mineFile = { $m = Get-Item -LiteralPath (Join-Path $repo $rel.Replace('/', $sep)) -Force -ErrorAction SilentlyContinue
      if ($m -is [IO.FileInfo] -and -not ($m.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $m } else { $null } }
    if ($codeDir -and $export -and $rel.StartsWith($codeDir, [StringComparison]::Ordinal) -and -not $rel.Substring($codeDir.Length).Contains('/')) {
      # an installed file of this ship: proven when the job's collected export holds the same bytes
      $mine = & $mineFile
      $theirs = Get-Item -LiteralPath (Join-Path $export $rel.Substring($codeDir.Length)) -Force -ErrorAction SilentlyContinue
      if ($mine -and $theirs -is [IO.FileInfo] -and $mine.Length -eq $theirs.Length) {
        $same = $false
        try { $same = (Hash $mine.FullName) -eq (Hash $theirs.FullName) } catch { $same = $false }
        if ($same) { $proven[$rel] = $true; continue }
      }
    }
    if ($code -ne '??' -and $code -ne '!!') { $keep += "changed: $rel"; continue }
    if ($rel.StartsWith('godot/.godot/', [StringComparison]::Ordinal)) { continue }
    if ($rel.EndsWith('/')) { $keep += "new: $rel"; continue }
    if ($rel.EndsWith('.import', [StringComparison]::Ordinal) -or $rel.EndsWith('.uid', [StringComparison]::Ordinal)) { $sidecars += $rel; continue }
    $from = $null; $shipCopy = $false
    foreach ($pre in 'gen/', 'assets/ships/') {
      if ($rel.StartsWith('godot/' + $pre, [StringComparison]::Ordinal)) {
        $shipCopy = $true
        if ($src) { $from = Join-Path $src ($rel.Substring(6).Replace('/', $sep)) }
      }
    }
    if ($shipCopy) {
      $mine = & $mineFile
      if ($mine) {
        # Size alone never proves it: the bytes must match (a same-size, same-time replacement is work). A hash that
        # cannot be read proves nothing.
        $h = $null
        try { $h = Hash $mine.FullName } catch { $h = $null }
        if ($h -and $rec.ContainsKey($rel) -and $rec[$rel] -eq $h) { $proven[$rel] = $true; continue }
        if ($h -and $from) {
          $theirs = Get-Item -LiteralPath $from -Force -ErrorAction SilentlyContinue
          $same = $false
          if ($theirs -is [IO.FileInfo] -and $mine.Length -eq $theirs.Length) { try { $same = (Hash $theirs.FullName) -eq $h } catch { $same = $false } }
          if ($same) { $proven[$rel] = $true; continue }
        }
      }
    }
    if ($code -eq '??') { $copies += $rel } else { $keep += "new: $rel" }
  }
  $tracked = @{}; $paths = @{}
  foreach ($l in (& $gitExe -C $repo -c core.quotepath=false ls-files -s 2>$null)) {
    if ("$l" -match '\A\d+ ([0-9a-f]{40}) \d+\t(.+)\z') { $tracked[$Matches[1]] = $true; $paths[$Matches[2]] = $true }
  }
  if ($copies.Count) {
    $sums = @($copies | & $gitExe -C $repo hash-object --no-filters --stdin-paths 2>$null)
    for ($i = 0; $i -lt $copies.Count; $i++) {
      if ($i -lt $sums.Count -and $tracked.ContainsKey("$($sums[$i])".Trim())) { $proven[$copies[$i]] = $true } else { $keep += "new: $($copies[$i])" }
    }
  }
  foreach ($rel in $sidecars) {
    $own = $rel -replace '\.(import|uid)\z', ''
    if (-not ($paths.ContainsKey($own) -or $proven.ContainsKey($own))) { $keep += "new: $rel" }
  }
  return $keep
}
function Read-ShipRecord($file) {
  # shiprecord's lines: "<sha256> <bytes> <path>"; a missing file is an empty record (jobs from before issue 1497)
  $rec = @{}
  if ($file -and (Test-Path -LiteralPath $file -PathType Leaf)) {
    foreach ($line in [IO.File]::ReadAllLines($file)) { if ($line -match '\A([0-9a-f]{64}) \d+ (.+)\z') { $rec[$Matches[2]] = $Matches[1] } }
  }
  return $rec
}
function Get-LeftoverCap {
  if ($test -and $env:PC_TEST_LEFTOVER_CAP) { return [long]$env:PC_TEST_LEFTOVER_CAP }
  return [long]200MB
}
function Save-Leftovers($repo, [string[]]$work, $dest) {
  # Issue 1497: a passing job nearly always leaves a few small files of its own in the checkout (build_info.json, Godot
  # .import sidecars of ship files, probe copies), and keeping 20 GB for them filled C: on Nov 21. Save them with the
  # results, read every copy back, then the checkout can go. Throws (and the checkout stays) on anything it cannot save.
  $changed = @(); $new = @()
  foreach ($w in $work) {
    if ($w.StartsWith('changed: ')) { $changed += $w.Substring(9) }
    elseif ($w.StartsWith('new: ')) {
      $rel = $w.Substring(5)
      if ($rel.EndsWith('/') -or $rel.Contains('..')) { throw "a folder of its own (a nested repo?) or odd path: $rel" }
      $new += $rel
    } else { throw $w }
  }
  $cap = Get-LeftoverCap
  $bytes = [long]0; $files = @()
  foreach ($rel in $new) {
    $f = Get-Item -LiteralPath (Join-Path $repo $rel.Replace('/', $sep)) -Force -ErrorAction SilentlyContinue
    if ($f -isnot [IO.FileInfo] -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "not a plain file: $rel" }
    $bytes += $f.Length; $files += $f
  }
  if ($bytes -gt $cap) { throw ("{0} new file(s) of {1:N0} MB are more than the {2:N0} MB the results may take" -f $new.Count, ($bytes / 1MB), ($cap / 1MB)) }
  if (Test-Path -LiteralPath $dest) { throw "$dest already exists" }
  Assert-NoLinks $dest
  $null = [IO.Directory]::CreateDirectory($dest)
  Assert-NoLinks $dest
  $list = @("checkout $repo", "HEAD $((Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1)")
  if ($changed.Count) {
    $patch = Join-Path $dest 'changes.patch'
    Run-Git -C $repo -c core.quotepath=false diff --binary ('--output=' + $patch) HEAD | Out-Null
    if (-not (Test-Path -LiteralPath $patch -PathType Leaf)) { throw 'no changes.patch was written' }
    $bytes += (Get-Item -LiteralPath $patch).Length
    if ($bytes -gt $cap) { throw ("changes.patch brings the saved files to {0:N0} MB, more than {1:N0} MB" -f ($bytes / 1MB), ($cap / 1MB)) }
    foreach ($rel in $changed) { $list += "changed (in changes.patch): $rel" }
  }
  for ($i = 0; $i -lt $new.Count; $i++) {
    $to = Join-Path (Join-Path $dest 'files') $new[$i].Replace('/', $sep)
    $null = [IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy($files[$i].FullName, $to, $false)
    $h = Hash $files[$i].FullName
    if ((Hash $to) -ne $h) { throw "the saved copy of $($new[$i]) does not read back the same" }
    $list += "copied $h $($files[$i].Length) $($new[$i])"
  }
  [IO.File]::WriteAllLines((Join-Path $dest 'leftovers.txt'), [string[]]$list)
  return ("saved {0} changed and {1} new file(s), {2:N1} MB, to {3}" -f $changed.Count, $new.Count, ($bytes / 1MB), $dest)
}
function Remove-LinkSafeTree($root) {
  # scratch_done.ps1's walk: a link is removed as a link and never followed; read-only files (git packs) are cleared first.
  $bytes = [long]0
  $dirs = New-Object 'Collections.Generic.List[string]'
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push((Get-Item -LiteralPath $root -Force))
  while ($pending.Count) {
    $next = $pending.Pop(); $dirs.Add($next.FullName)
    foreach ($entry in @($next.EnumerateFileSystemInfos())) {
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($entry -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($entry.FullName, $false) } else { [IO.File]::Delete($entry.FullName) }
      } elseif ($entry -is [IO.DirectoryInfo]) { $pending.Push($entry) }
      else { $bytes += $entry.Length; $entry.Attributes = [IO.FileAttributes]::Normal; [IO.File]::Delete($entry.FullName) }
    }
  }
  for ($i = $dirs.Count - 1; $i -ge 0; $i--) { [IO.Directory]::Delete($dirs[$i], $false) }
  return $bytes
}

function Remove-Owned($path) {
  # The one place this file removes anything: a folder the callers have checked is the job's own leftover.
  if (Test-Paused) { throw 'the Board PC pause is active' }
  return (Remove-LinkSafeTree $path)
}
function Assert-NoLinks($path) {
  # Every folder from voidsworn_test down to $path (each one that exists) is a plain folder, never a link or junction
  # (Artoo on PR 1498: checking only the last folder misses a junction above it).
  $full = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
  if (-not $full.StartsWith($vt + $sep, [StringComparison]::OrdinalIgnoreCase)) { throw "$full is not under $vt" }
  $at = $vt
  foreach ($part in ($full.Substring($vt.Length + 1) -split '[\\/]')) {
    $at = Join-Path $at $part
    $i = Get-Item -LiteralPath $at -Force -ErrorAction SilentlyContinue
    if ($null -eq $i) { return }
    if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "$at is a link or junction" }
  }
}
function Test-PlainDir($item) { return ($item -is [IO.DirectoryInfo]) -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) }
function Get-AttemptProblem($attempt) {
  # $null when $attempt is a plain voidsworn_test\<job>\out_* folder; else why not
  $item = Get-Item -LiteralPath $attempt -Force -ErrorAction SilentlyContinue
  $jobDir = Split-Path -Parent $attempt
  $job = Get-Item -LiteralPath $jobDir -Force -ErrorAction SilentlyContinue
  if (-not (Test-PlainDir $item) -or $item.Name -notmatch '\Aout_[A-Za-z0-9_-]+\z' -or -not (Test-PlainDir $job) -or
      -not (Split-Path -Parent $jobDir).Equals($vt, [StringComparison]::OrdinalIgnoreCase) -or $job.Name -notmatch '\A[A-Za-z0-9_-]+\z') {
    return "$attempt is not a job attempt folder voidsworn_test\<job>\out_*"
  }
  return $null
}
function Get-BlobSha($path) {
  # Git's blob id of a file's bytes (sha1 of "blob <size>\0" and the bytes), computed here so no path is piped to git
  # (PowerShell 5.1 pipes CRLF to native commands, issue 1335).
  $sha = [Security.Cryptography.SHA1]::Create()
  $f = [IO.File]::OpenRead($path)
  try {
    $h = [Text.Encoding]::ASCII.GetBytes("blob $($f.Length)`0")
    $null = $sha.TransformBlock($h, 0, $h.Length, $null, 0)
    $buf = New-Object byte[] 1048576
    while (($n = $f.Read($buf, 0, $buf.Length)) -gt 0) { $null = $sha.TransformBlock($buf, 0, $n, $null, 0) }
    $null = $sha.TransformFinalBlock($buf, 0, 0)
    return (($sha.Hash | ForEach-Object { $_.ToString('x2') }) -join '')
  } finally { $f.Dispose(); $sha.Dispose() }
}
function Update-Mirror {
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  while (-not $lock) {
    try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
  }
  try {
    if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin' }
    Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
  } finally { $lock.Dispose() }
}
function Find-RelayReceipt($want) {
  # The first relay branch (board/pc-out-*) whose current tree holds every wanted path ("<job>_<out folder>/<file>")
  # with exactly that blob; $null when none does. One branch must hold them all, so bytes that happen to sit in another
  # relay or another job's folder prove nothing (Artoo on PR 1498).
  $prefixes = @($want.Keys | ForEach-Object { ($_ -split '/', 2)[0] } | Sort-Object -Unique)
  $tips = @(Run-Git --git-dir $mirror for-each-ref '--format=%(objectname) %(refname)' 'refs/heads/board/pc-out-*' | Where-Object { $_ })
  foreach ($tip in $tips) {
    $sha, $ref = "$tip" -split ' ', 2
    $have = @{}
    foreach ($l in (Run-Git --git-dir $mirror -c core.quotepath=false ls-tree -r $sha @prefixes)) {
      if ("$l" -match '\A\d+ blob ([0-9a-f]{40})\t(.+)\z') { $have[$Matches[2]] = $Matches[1] }
    }
    $ok = $true
    foreach ($k in $want.Keys) { if ($have[$k] -ne $want[$k]) { $ok = $false; break } }
    if ($ok) { return $ref }
  }
  return $null
}
function Assert-Relayed($root, [string[]]$dirs, $skip) {
  # Issue 1497 (Artoo on PR 1498): a checkout goes only once the results are relayed. The Board's relay commits each out
  # folder <vt>\<job>\...\<out> as <job>_<out>/ on a board/pc-out branch; every file under each of $dirs ($skip names
  # leftovers folders this file writes after the relay) must be there, at its own path, with the same bytes.
  $want = @{}
  foreach ($d in $dirs) {
    $full = [IO.Path]::GetFullPath($d).TrimEnd('\', '/')
    $job = ($full.Substring($vt.Length + 1) -split '[\\/]')[0]
    $prefix = $job + '_' + (Split-Path -Leaf $full)
    $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
    $pending.Push((Get-Item -LiteralPath $full -Force))
    while ($pending.Count) {
      foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
        if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
        if ($e -is [IO.DirectoryInfo]) { if ($skip -notcontains $e.Name) { $pending.Push($e) }; continue }
        $want[$prefix + '/' + $e.FullName.Substring($full.Length + 1).Replace('\', '/')] = Get-BlobSha $e.FullName
      }
    }
  }
  if (-not $want.Count) { throw "no result files under $root to prove the relay" }
  $ref = Find-RelayReceipt $want
  if (-not $ref) { Update-Mirror; $ref = Find-RelayReceipt $want }
  if (-not $ref) { throw ("results not relayed yet: no board/pc-out branch holds all {0} result file(s) at their paths, e.g. {1}" -f $want.Count, @($want.Keys | Sort-Object)[0]) }
  Write-Output "results relayed: all $($want.Count) result file(s) are on $ref"
}
function Drop-Attempt($attempt) {
  # The listed pinned checkouts of one attempt folder, once the attempt passed and its results are relayed; adds the
  # bytes removed to $script:freed. Every refusal is logged, never thrown.
  $state = Get-AttemptState $attempt
  if ($state -ne 'PASS') { Write-Output "checkouts kept: $attempt $(if ($state) { 'failed' } else { 'has no result yet' }) (the janitor handles old failures)"; return }
  $list = Join-Path $attempt 'checkouts.txt'
  if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { Write-Output "no checkouts listed in $attempt"; return }
  $present = @(foreach ($line in [IO.File]::ReadAllLines($list)) { if ($line -match '\A([A-Za-z0-9_-]{1,40}) [0-9a-f]{40}\z' -and (Test-Path -LiteralPath (Join-Path $attempt $Matches[1]))) { $Matches[1] } })
  if (-not $present.Count) { Write-Output "no listed checkout left in $attempt"; return }
  $outs = @((Get-Item -LiteralPath $attempt -Force).EnumerateDirectories('out_*') | ForEach-Object { $_.FullName })
  try { Assert-Relayed $attempt $outs @('checkout_leftovers') }
  catch { Write-Output "checkouts kept: $attempt ($($_.Exception.Message))"; return }
  $src = $null
  $srcFile = Join-Path $attempt 'ships_source.txt'
  if (Test-Path -LiteralPath $srcFile -PathType Leaf) { $src = ([IO.File]::ReadAllText($srcFile)).Trim() }
  foreach ($line in [IO.File]::ReadAllLines($list)) {
    if ($line -notmatch '\A([A-Za-z0-9_-]{1,40}) ([0-9a-f]{40})\z') { if ($line.Trim()) { Write-Output "checkouts.txt line not accepted, ignored: $line" }; continue }
    $name = $Matches[1]; $pin = $Matches[2]
    $repo = Join-Path $attempt $name
    try {
      $r = Get-Item -LiteralPath $repo -Force -ErrorAction SilentlyContinue
      if ($null -eq $r) { Write-Output "checkout $name already gone: $repo"; continue }
      if (-not (Test-PlainDir $r)) { throw 'not a plain folder' }
      Assert-NoLinks $repo
      $git = Get-Item -LiteralPath (Join-Path $repo '.git') -Force -ErrorAction SilentlyContinue
      if (-not (Test-PlainDir $git)) { throw 'no .git folder of its own' }
      $headFile = Join-Path $git.FullName 'HEAD'
      if (-not (Test-Path -LiteralPath $headFile -PathType Leaf) -or ([IO.File]::ReadAllText($headFile)).Trim() -ne $pin) { throw "HEAD is no longer the pin $pin" }
      Assert-Rebuildable $repo
      $rec = Read-ShipRecord ($repo + '_ships_copied.txt')
      $work = @(Get-KeptWork $repo $src $rec $null $null)
      if (Test-Paused) { throw 'the Board PC pause is active' }
      if ($work.Count) {
        $dest = Join-Path (Join-Path $attempt "out_$name") 'checkout_leftovers'
        try { Write-Output (Save-Leftovers $repo $work $dest) }
        catch { throw ("it holds {0} path(s) that are not rebuildable leftovers and could not be saved ({1}), e.g. {2}" -f $work.Count, $_.Exception.Message, (($work | Select-Object -First 5) -join '; ')) }
      }
      $gone = Remove-Owned $repo
      $script:freed += $gone
      Write-Output ("checkout {0} removed after the job ({1:N1} GB): {2}" -f $name, ($gone / 1GB), $repo)
    } catch { Write-Output "checkout $name kept: $repo ($($_.Exception.Message))" }
  }
}
function Get-AttemptState($attempt) {
  # PASS or FAILED from job_wrap's done.txt; '' when the attempt never finished (killed, timed out or still running)
  $done = Join-Path $attempt 'done.txt'
  if (-not (Test-Path -LiteralPath $done -PathType Leaf)) { return '' }
  $first = [string](Get-Content -LiteralPath $done -TotalCount 1)
  if ($first -match '\APASS\b') { return 'PASS' }
  return 'FAILED'
}
function Test-ShipClone($jobDir) {
  # The ship job's own clone <job>\repo: a plain folder with its own .git, in a plain voidsworn_test\<job> folder
  $j = Get-Item -LiteralPath $jobDir -Force -ErrorAction SilentlyContinue
  if (-not (Test-PlainDir $j) -or $j.Name -notmatch '\A[A-Za-z0-9_-]+\z' -or -not (Split-Path -Parent $j.FullName).Equals($vt, [StringComparison]::OrdinalIgnoreCase)) {
    throw "$jobDir is not a job folder voidsworn_test\<job>"
  }
  $repo = Join-Path $j.FullName 'repo'
  if (-not (Test-PlainDir (Get-Item -LiteralPath $repo -Force -ErrorAction SilentlyContinue))) { throw "no plain clone folder $repo" }
  Assert-NoLinks $repo
  if (-not (Test-PlainDir (Get-Item -LiteralPath (Join-Path $repo '.git') -Force -ErrorAction SilentlyContinue))) { throw "$repo has no .git folder of its own" }
  return $repo
}
function Test-InMirror($sha) {
  $ErrorActionPreference = 'Continue'
  & $gitExe --git-dir $mirror cat-file -e "$sha^{commit}" 2>$null
  return $LASTEXITCODE -eq 0
}
function Assert-Rebuildable($repo) {
  # Every local branch and HEAD is a commit the shared mirror holds, or a two-parent merge (PAINT_BASE) of mirror commits
  # that git merges again to exactly the same tree (Artoo on PR 1498: a merge with its own conflict edits is work).
  $tips = @((Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1)
  $tips += @(Run-Git -C $repo for-each-ref '--format=%(objectname)' refs/heads | Where-Object { $_ })
  $stash = @(Run-Git -C $repo for-each-ref '--format=%(objectname)' refs/stash | Where-Object { $_ })
  if ($stash.Count) { throw 'it has a stash' }
  foreach ($t in ($tips | Sort-Object -Unique)) {
    if (Test-InMirror $t) { continue }
    $parents = @(((Run-Git -C $repo rev-list --parents -n 1 $t) | Select-Object -Last 1) -split ' ' | Select-Object -Skip 1)
    if ($parents.Count -ne 2) { throw "commit $t is not in the shared mirror" }
    foreach ($p in $parents) { if (-not (Test-InMirror $p)) { throw "commit $p (a parent of $t) is not in the shared mirror" } }
    $tree = (Run-Git -C $repo rev-parse "$t^{tree}") | Select-Object -Last 1
    $again = $null
    try { $again = (Run-Git -C $repo merge-tree --write-tree $parents[0] $parents[1]) | Select-Object -First 1 } catch { $again = $null }
    if ("$again".Trim() -ne $tree) { throw "merge $t is not in the shared mirror and git does not rebuild its exact tree from its parents" }
  }
}
function Get-TreeBytes($path) {
  # read only, links not followed
  $bytes = [long]0
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push((Get-Item -LiteralPath $path -Force))
  while ($pending.Count) {
    foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
      if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($e -is [IO.DirectoryInfo]) { $pending.Push($e) } else { $bytes += $e.Length }
    }
  }
  return $bytes
}
function Write-Free($freed) {
  $root = [IO.Path]::GetPathRoot($vt)
  $free = ''
  try { $free = ', C: {0:N1} GB free' -f ((New-Object IO.DriveInfo($root)).AvailableFreeSpace / 1GB) } catch { }
  Write-Output ("disk: checkouts freed {0:N1} GB in all{1}" -f ($freed / 1GB), $free)
}

switch ($Action) {
  'live' {
    $here = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    $want = Current-Pc
    if (-not $here.Equals((Join-Path $want 'jobs'), [StringComparison]::OrdinalIgnoreCase)) { throw "not the current tools_live head: $here (current is $want)" }
    Write-Output "head runs from the current tools_live copy: $here"
  }
  'bundle' {
    $pc = Current-Pc
    $version = Split-Path -Parent $pc
    $tools = [IO.Path]::GetFullPath($B).TrimEnd('\', '/')
    $hashFile = [IO.Path]::GetFullPath($C)
    if (-not $tools.Equals($pc, [StringComparison]::OrdinalIgnoreCase)) { throw "job_wrap tools are $tools, not the current $pc" }
    if (-not $hashFile.Equals((Join-Path $version 'hashes.txt'), [StringComparison]::OrdinalIgnoreCase)) { throw "job_wrap hashes are $hashFile, not the current version's hashes.txt" }
    $listed = @{}
    foreach ($line in [IO.File]::ReadAllLines($hashFile)) { if ($line -match '\A([0-9a-f]{64})  (\S+)\z') { $listed[$Matches[2].Replace('/', '\')] = $Matches[1] } }
    $names = @('tmo.bat', 'run_timeout.ps1')
    if ($D -ne '1') { $names += @('jobs\opus_job_head.bat', 'jobs\opus_job_head.ps1') }
    foreach ($name in $names) {
      $file = Join-Path $pc $name.Replace('\', $sep)
      if (-not $listed.ContainsKey($name)) { throw "hashes.txt does not list $name" }
      if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "missing $file" }
      if ((Hash $file) -ne $listed[$name]) { throw "$file differs from hashes.txt" }
      Write-Output "verified $($listed[$name]) $file"
    }
  }
  'watchdog' {
    foreach ($name in @('tmo.bat', 'run_timeout.ps1')) {
      $path = Join-Path $A $name
      if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "no watchdog file $path" }
      Write-Output "watchdog $(Hash $path) $path"
    }
  }
  'checkout' {
    if ($C -notmatch '\A[0-9a-f]{40}\z') { throw "a pin must be a full 40-character commit, got: $C" }
    if ($B -notmatch '\A[A-Za-z0-9_-]{1,40}\z') { throw "checkout name not accepted: $B" }
    $attempt = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    if (-not $attempt.StartsWith($vt + $sep, [StringComparison]::OrdinalIgnoreCase)) { throw "attempt folder must be under $vt" }
    $repo = Join-Path $attempt $B
    if (Test-Path -LiteralPath $repo) { throw "checkout $repo already exists; every attempt gets a new folder" }
    $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
    while (-not $lock) {
      try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
      catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
    }
    try {
      if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init -q --bare $mirror | Out-Null; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source | Out-Null }
      if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
      $ErrorActionPreference = 'Continue'
      & $gitExe --git-dir $mirror cat-file -e "$C^{commit}" 2>$null
      $have = $LASTEXITCODE -eq 0
      $ErrorActionPreference = 'Stop'
      if (-not $have) {
        Write-Output "fetching the shared mirror for $C"
        Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
        Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main | Out-Null
      }
      Run-Git --git-dir $mirror cat-file -e "$C^{commit}" | Out-Null
      Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null
    } finally { $lock.Dispose() }
    Run-Git -C $repo -c core.autocrlf=false -c advice.detachedHead=false checkout -q --detach $C | Out-Null
    $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
    if ($head -ne $C) { throw "checkout $repo is at $head, not the pin $C" }
    [IO.File]::AppendAllText((Join-Path $attempt 'checkouts.txt'), "$B $C`r`n")
    Write-Output "checkout $B $C $repo"
  }
  'tracked' {
    $changed = @(Run-Git -C $A status --porcelain --untracked-files=no | Where-Object { $_ })
    if ($changed.Count) { $changed | ForEach-Object { Write-Output "tracked change: $_" }; throw "$($changed.Count) tracked file(s) differ from the pin in $A" }
    Write-Output "tracked files match the pin: $A"
  }
  'shipcheck' {
    $godot = Join-Path $A 'godot'
    $manPath = Join-Path (Join-Path $godot 'gen') 'manifest.json'
    if (-not (Test-Path -LiteralPath $manPath -PathType Leaf)) { throw "no $manPath" }
    $man = [IO.File]::ReadAllText($manPath) | ConvertFrom-Json
    if (-not $man.ships) { throw "$manPath lists no ships" }
    $shipsDir = Join-Path (Join-Path $godot 'assets') 'ships'
    $bad = @(); $lines = @(); $matched = @{}; $noGlb = 0
    foreach ($prop in $man.ships.PSObject.Properties) {
      $code = $prop.Name; $e = $prop.Value
      $dir = Join-Path $shipsDir $code
      $res = [string]$e.res
      $resFile = ''
      if ($res.StartsWith('res://')) { $resFile = Join-Path $godot $res.Substring(6).Replace('/', $sep) }
      $hasRes = $resFile -and (Test-Path -LiteralPath $resFile -PathType Leaf)
      if (-not (Test-Path -LiteralPath (Join-Path $dir "$code.glb") -PathType Leaf)) {
        # an older cache entry with no ship folder: not checked, but listed, so two checkouts must still agree on it
        $noGlb++; $lines += "$code no-glb $res scene=$([int][bool]$hasRes)"; continue
      }
      $stamp = ''
      foreach ($suf in '', '_damage', '_wreck') {
        $f = Join-Path $dir "$code$suf.glb"
        if (Test-Path -LiteralPath $f -PathType Leaf) {
          $i = Get-Item -LiteralPath $f
          $stamp += '{0}:{1};' -f ([DateTimeOffset]$i.LastWriteTimeUtc).ToUnixTimeSeconds(), $i.Length
        }
      }
      if (-not $hasRes) { $bad += "$code cached scene missing: $res" }
      elseif ([string]$e.src -ne $stamp) { $bad += "$code cache was built from other files (stamp $($e.src), copied files $stamp)" }
      else { $matched[$code] = $true }
      $lines += "$code $stamp $res"
    }
    foreach ($need in @($C -split '[\s,]+' | Where-Object { $_ })) {
      if (-not $matched.ContainsKey($need)) { $bad += "$need is needed by this job but is not a copied ship matching its cache" }
    }
    [IO.File]::WriteAllLines($B, [string[]]($lines | Sort-Object))
    if ($bad.Count) { $bad | ForEach-Object { Write-Output "ship mismatch: $_" }; throw "$($bad.Count) ship problem(s); was a ship published during the copy?" }
    if (-not $matched.Count) { throw "no ship in $manPath has a copied glb that matches its cache" }
    Write-Output "ships match their cache: $($matched.Count) hull(s), $noGlb older entr(ies) with no ship folder listed unchecked; identity in $B"
  }
  'dropcheckouts' {
    # The tail and, after the Board relays the results, the Board itself: this attempt and the same job's earlier ones,
    # each only once it passed and every result file is on a relay branch (Drop-Attempt).
    $attempt = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    $problem = Get-AttemptProblem $attempt
    if ($problem) { Write-Output "checkouts kept: $problem"; break }
    $script:freed = [long]0
    Drop-Attempt $attempt
    $jobDir = Split-Path -Parent $attempt
    foreach ($sib in @((Get-Item -LiteralPath $jobDir -Force).EnumerateDirectories('out_*'))) {
      if ($sib.FullName.Equals($attempt, [StringComparison]::OrdinalIgnoreCase)) { continue }
      if (Get-AttemptProblem $sib.FullName) { continue }
      if (-not (Test-Path -LiteralPath (Join-Path $sib.FullName 'checkouts.txt') -PathType Leaf)) { continue }
      Drop-Attempt $sib.FullName
    }
    Write-Free $script:freed
  }
  'dropcache' {
    try {
      $repo = Test-ShipClone ([IO.Path]::GetFullPath($A).TrimEnd('\', '/'))
      $cache = Join-Path (Join-Path $repo 'godot') '.godot'
      # (not $c: PowerShell names are case-blind, and $C is the [string] parameter)
      $cacheDir = Get-Item -LiteralPath $cache -Force -ErrorAction SilentlyContinue
      if ($null -eq $cacheDir) { Write-Output "no import cache in $repo"; break }
      if (-not (Test-PlainDir $cacheDir)) { throw "$cache is not a plain folder" }
      Assert-NoLinks $cache
      $gone = Remove-Owned $cache
      Write-Output ("import cache removed after the PASS ({0:N1} GB): {1}; the clone stays for the publish" -f ($gone / 1GB), $cache)
      Write-Free $gone
    } catch { Write-Output "import cache kept: $($_.Exception.Message)" }
  }
  'droprepo' {
    try {
      if ($B -notmatch '\A[0-9a-f]{40}\z') { throw "a commit must be a full 40-character commit, got: $B" }
      if ($C -notmatch '\A[A-Za-z0-9_]+\z') { throw "not a hull code: $C" }
      $jobDir = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
      $repo = Test-ShipClone $jobDir
      $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
      if ($head -ne $B) { throw "HEAD is $head, not the published commit $B" }
      Assert-Rebuildable $repo
      $export = Join-Path (Join-Path (Join-Path (Join-Path $jobDir 'out') 'recipe') 'export') $C
      if (-not (Test-Path -LiteralPath $export -PathType Container)) { throw "no collected export $export" }
      Assert-Relayed $jobDir @((Join-Path $jobDir 'out')) @('checkout_leftovers_repo')
      $work = @(Get-KeptWork $repo $null @{} "godot/assets/ships/$C/" $export)
      if (Test-Paused) { throw 'the Board PC pause is active' }
      if ($work.Count) {
        $dest = Join-Path (Join-Path $jobDir 'out') 'checkout_leftovers_repo'
        try { Write-Output (Save-Leftovers $repo $work $dest) }
        catch { throw ("it holds {0} path(s) that are not rebuildable leftovers and could not be saved ({1}), e.g. {2}" -f $work.Count, $_.Exception.Message, (($work | Select-Object -First 5) -join '; ')) }
      }
      $gone = Remove-Owned $repo
      Write-Output ("ship clone removed after the publish ({0:N1} GB): {1}" -f ($gone / 1GB), $repo)
      Write-Free $gone
    } catch { Write-Output "ship clone kept: $($_.Exception.Message)" }
  }
  'survey' {
    # Read only. What the job rules would do with every attempt and ship clone already on the PC (for a Board one-off).
    $total = [long]0
    foreach ($job in @((Get-Item -LiteralPath $vt -Force).EnumerateDirectories())) {
      if (-not (Test-PlainDir $job) -or $job.Name -notmatch '\A[A-Za-z0-9_-]+\z') { continue }
      foreach ($att in @($job.EnumerateDirectories('out_*'))) {
        if (Get-AttemptProblem $att.FullName) { continue }
        $list = Join-Path $att.FullName 'checkouts.txt'
        if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { continue }
        $state = Get-AttemptState $att.FullName; if (-not $state) { $state = 'unfinished' }
        foreach ($line in [IO.File]::ReadAllLines($list)) {
          if ($line -notmatch '\A([A-Za-z0-9_-]{1,40}) ([0-9a-f]{40})\z') { continue }
          $repo = Join-Path $att.FullName $Matches[1]
          if (-not (Test-Path -LiteralPath $repo -PathType Container)) { continue }
          $gb = (Get-TreeBytes $repo) / 1GB; $total += [long]($gb * 1GB)
          Write-Output ("attempt checkout {0:N1} GB {1} {2}" -f $gb, $state, $repo)
        }
      }
      $repo = Join-Path $job.FullName 'repo'
      if ((Test-Path -LiteralPath (Join-Path $repo '.git') -PathType Container)) {
        $gb = (Get-TreeBytes $repo) / 1GB; $total += [long]($gb * 1GB)
        $cache = Join-Path (Join-Path $repo 'godot') '.godot'
        $cgb = 0; if (Test-Path -LiteralPath $cache -PathType Container) { $cgb = (Get-TreeBytes $cache) / 1GB }
        $res = Join-Path (Join-Path $job.FullName 'out') 'result.txt'
        $state = 'no result'
        if (Test-Path -LiteralPath $res -PathType Leaf) { $state = if (Select-String -LiteralPath $res -SimpleMatch 'done PASS' -Quiet) { 'PASS' } else { 'FAILED or unfinished' } }
        Write-Output ("ship clone {0:N1} GB (import cache {1:N1} GB) {2} {3}" -f $gb, $cgb, $state, $repo)
      }
    }
    Write-Output ("survey: {0:N1} GB in job checkouts and ship clones (hard links to the mirror count in full); nothing was removed" -f ($total / 1GB))
  }
  'shiprecord' {
    # sha256 of every untracked file the ships step put under godot\gen and godot\assets\ships, as copied
    $ErrorActionPreference = 'Continue'
    $tracked = @{}
    foreach ($l in (& $gitExe -C $A -c core.quotepath=false ls-files 2>$null)) { $tracked["$l"] = $true }
    $ErrorActionPreference = 'Stop'
    $lines = New-Object 'Collections.Generic.List[string]'
    $skipped = 0
    $root = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    foreach ($sub in 'gen', 'assets\ships') {
      $dir = Join-Path (Join-Path $root 'godot') $sub.Replace('\', $sep)
      if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
      $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
      $pending.Push((Get-Item -LiteralPath $dir -Force))
      while ($pending.Count) {
        foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
          if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
          if ($e -is [IO.DirectoryInfo]) { $pending.Push($e); continue }
          $rel = $e.FullName.Substring($root.Length + 1).Replace('\', '/')
          if ($tracked.ContainsKey($rel)) { continue }
          # Only a file the copy brought: the same bytes at the same path in the ships source (Artoo on PR 1498; robocopy
          # skips some files, and a file only in the checkout is never a copy).
          if (-not $C) { $skipped++; continue }
          $from = Get-Item -LiteralPath (Join-Path $C ($rel.Substring(6).Replace('/', $sep))) -Force -ErrorAction SilentlyContinue
          if ($from -isnot [IO.FileInfo] -or ($from.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $from.Length -ne $e.Length) { $skipped++; continue }
          $h = Hash $e.FullName
          if ((Hash $from.FullName) -ne $h) { $skipped++; continue }
          $lines.Add(('{0} {1} {2}' -f $h, $e.Length, $rel))
        }
      }
    }
    [IO.File]::WriteAllLines($B, [string[]]$lines)
    Write-Output "ships copy recorded: $($lines.Count) file(s) matching $C in $B; $skipped untracked file(s) there did not match the source and are not recorded"
  }
  'hashes' {
    if ($test) { $realu = $env:PC_TEST_REALU } else { $realu = Join-Path $env:APPDATA 'Godot\app_userdata\Voidsworn' }
    $lines = foreach ($f in 'battle_opts.json', 'board_look.cfg') {
      $p = Join-Path $realu $f
      if (Test-Path -LiteralPath $p) { (Hash $p) + ' ' + $f } else { 'absent ' + $f }
    }
    [IO.File]::WriteAllLines($A, [string[]]$lines)
  }
}
