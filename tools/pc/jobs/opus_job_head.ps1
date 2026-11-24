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
#   dropwait [<attempt folder>] [dry]          the tail starts it in a hidden window (issue 1396), the attempt in
#                                              OJ_DROPWAIT_ATTEMPT: for a passed attempt, asks origin for its relay branch
#                                              every 5 minutes for up to 12 hours, then under the job lease, the issue lock
#                                              and the janitor's checks runs dropcheckouts' proof and drop for this attempt
#                                              only; dry looks once and takes, writes, fetches and removes nothing
#   dropcheckouts <attempt folder> [<relay branch> <tree folder>]
#                                              the tail, and the Board right after it relays the results (with the branch
#                                              and the tree folder that holds the attempt, written to the attempt's
#                                              relay_receipt.txt): removes the
#                                              pinned checkouts of this attempt only (earlier attempts go through their
#                                              own relay waiter or the janitor; review of PR 1644), only when its done.txt says
#                                              PASS and a board/pc-out branch on origin (issue 1535: relay_receipt.txt,
#                                              else relay_found.txt, else the attempt's relay_branch.txt, else
#                                              board/pc-out-<job>) whose tree holds
#                                              every file of its out_* folders at <tree folder>/out_<name>/<path> with the
#                                              same bytes (the mirror is fetched when it does not). A failed or
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
#   droprepo <ship job folder> <commit> <code> [<relay branch> <tree folder>]
#                                              publish_ship.bat after a published PASS, or the Board: removes the job's own clone
#                                              <job>\repo when HEAD is <commit>, every file in <job>\out is relayed
#                                              (<job>\out\relay_receipt.txt, as above, the tree folder holding out's files),
#                                              every local branch and HEAD is in the shared mirror (or is a merge of
#                                              commits that are), there is no stash or staged change, and
#                                              its files are rebuildable or saved first as above into
#                                              <job>\out\checkout_leftovers_repo (installed files under
#                                              godot\assets\ships\<code> that match the job's collected export count as
#                                              rebuildable). The job's out\, the publish folder and build\godot stay.
#   relayfind <attempt folder>|all [dry]       issue 1695: for a passed attempt that still lists checkouts and whose own
#                                              relay place does not prove, with no relay_receipt.txt or relay_found.txt,
#                                              finds the board/pc-out-* folder in the shared mirror that holds all its
#                                              result files byte for byte and writes it as a new relay_found.txt (issue
#                                              1739: beside a relay_branch.txt the head wrote at init, never over it). Writes
#                                              nothing else, removes nothing; dry writes and fetches nothing
#   survey                                     read only: every job attempt and ship clone under voidsworn_test with its
#                                              size and what the rules above would do with it. Deletes nothing.
# Nothing else is deleted. Test settings (helper_clone's): PC_TEST_HELPER=1, PC_TEST_HELPER_VT, PC_TEST_SOURCE, PC_TEST_REALU.
param([Parameter(Mandatory)][ValidateSet('live', 'bundle', 'watchdog', 'checkout', 'tracked', 'shipcheck', 'hashes', 'shiprecord', 'dropcheckouts', 'dropwait', 'dropjobs', 'relayfind', 'dropcache', 'droprepo', 'survey', 'slot', 'slothold', 'slotrelease', 'slotcheck')][string]$Action,
      [string]$A = '', [string]$B = '', [string]$C = '', [string]$D = '', [string]$Folder = '')
$ErrorActionPreference = 'Stop'
# Git emits the relay tree paths and manifest as UTF-8, even under Windows PowerShell 5.1.
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }
# Issue 1739: sizes say what removal really frees (a hard link shared outside a checkout frees nothing). Optional.
$diskSpaceHelpers = Join-Path (Split-Path -Parent $PSScriptRoot) 'disk_space.ps1'
if (Test-Path -LiteralPath $diskSpaceHelpers) { . $diskSpaceHelpers }
$test = [bool]$env:PC_TEST_HELPER
$unix = $PSVersionTable.Platform -eq 'Unix'
$sep = [IO.Path]::DirectorySeparatorChar
if ($test) { $vt = $env:PC_TEST_HELPER_VT } else { $vt = Join-Path (Join-Path $env:USERPROFILE 'Downloads') 'voidsworn_test' }
$vt = [IO.Path]::GetFullPath($vt).TrimEnd('\', '/')
$mirror = Join-Path $vt 'repo-mirror.git'
$source = 'https://github.com/rcbailey12/voidsworn'
if ($test) { $source = $env:PC_TEST_SOURCE }
# Issue 1657 (Ryan, Nov 22 2026): PC results go to the private relay repo, not the main repo. Its own bare mirror (a
# mirror fetch of one remote prunes every ref the other lacks, so the two cannot share one). A receipt names it as
# relay/pc-out-<job>: branch pc-out-<job> of voidsworn-relay. Older board/pc-out-* receipts on the main repo still count.
$relayMirror = Join-Path $vt 'relay-mirror.git'
$relaySource = 'https://github.com/rcbailey12/voidsworn-relay'
if ($test) { $relaySource = $env:PC_TEST_RELAY_SOURCE }
$relayPattern = '(?:board|relay)/pc-out-[A-Za-z0-9._-]+'
function Get-RelayRepo($ref) {
  # Which repo and mirror hold a receipt's branch: @{ Mirror; Source; Ref (the branch name in that repo) }.
  if ($ref -like 'relay/*') { return @{ Mirror = $relayMirror; Source = $relaySource; Ref = $ref.Substring(6); Lock = $relayMirror + '.lock' } }
  return @{ Mirror = $mirror; Source = $source; Ref = $ref; Lock = $mirror + '.lock' }
}
function Lock-RelayMirror {
  # The relay mirror's writers' lock, held with Lock-Mirror from a removal's proof through its delete (Artoo on PR 1592).
  # A caller with its own end (the relay waiter, PR 1644) waits no longer than that.
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  if ($script:waitUntil -and $script:waitUntil -lt $deadline) { $deadline = $script:waitUntil }
  while (-not $lock) {
    try { $lock = [IO.File]::Open($relayMirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'relay repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
  }
  return $lock
}
function Update-RelayMirror {
  # The relay repo's own mirror: made on first use, fetched under its own lock. Never touches the shared repo mirror.
  if (-not $relaySource) { return }
  # A removal already holds the lock ($script:relayLock): make and fetch the mirror under it (the first relay proof of a
  # PC happens inside a removal, so the mirror must be made there too). Otherwise take the lock for this fetch only.
  $lock = $null
  if (-not $script:relayLock) { $lock = Lock-RelayMirror }
  try {
    if (-not (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD'))) {
      Run-Git init -q --bare $relayMirror | Out-Null
      Run-Git --git-dir $relayMirror remote add --mirror=fetch origin $relaySource | Out-Null
    }
    if ((Run-Git --git-dir $relayMirror config --get remote.origin.url) -ne $relaySource) { throw 'relay repo copy has an unexpected origin' }
    Run-Git --git-dir $relayMirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
  } finally { if ($lock) { $lock.Dispose() } }
}
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
      else {
        $f = $entry.FullName; $len = $entry.Length
        # Only the last link to a file frees its bytes (issue 1739: checkouts share files with the mirror).
        if (Get-Command Get-FileIdentity -ErrorAction SilentlyContinue) { $id = Get-FileIdentity $f; if ($id -and $id.Links -gt 1) { $len = 0 } }
        Invoke-Retry { if ([IO.File]::Exists($f)) { [IO.File]::SetAttributes($f, [IO.FileAttributes]::Normal); [IO.File]::Delete($f) } } $f; $bytes += $len
      }
    }
  }
  for ($i = $dirs.Count - 1; $i -ge 0; $i--) { $d = $dirs[$i]; Invoke-Retry { $di = New-Object IO.DirectoryInfo $d; if ($di.Exists) { if ($di.Attributes -band [IO.FileAttributes]::ReadOnly) { $di.Attributes = $di.Attributes -bxor [IO.FileAttributes]::ReadOnly }; $di.Delete($false) } } $d }
  return $bytes
}
function Invoke-Retry([scriptblock]$act, $what) {
  # A file Defender, the indexer or a read-only survey holds for a moment (Board, AFTERRELAY2 on Nov 21: a pack .idx
  # was denied, then free a minute later): try again with growing waits, about 30 s in all, before giving up.
  $waits = @(250, 500, 1000, 2000, 4000, 8000, 15000)
  if ($env:PC_TEST_HELPER -eq '1' -and $env:PC_TEST_RETRY_MS) { $waits = @($waits | ForEach-Object { [int]$env:PC_TEST_RETRY_MS }) }
  for ($i = 0; ; $i++) {
    try { & $act; return }
    catch {
      if ($i -ge $waits.Count) { throw "$what is still locked after $($waits.Count) retries: $($_.Exception.Message)" }
      [Console]::Error.WriteLine(('still locked, trying again in {0} ms: {1} ({2})' -f $waits[$i], $what, $_.Exception.Message))
      Start-Sleep -Milliseconds $waits[$i]
    }
  }
}
function Remove-Owned($path, [switch]$InPlace, [string]$Commit = '') {
  # The one place this file removes anything: a folder the callers have checked is the job's own leftover. A checkout or
  # ship clone (-Commit: the pin or published commit its checks proved) is first recorded in its parent's removing.txt
  # ("<name>.removing <commit>"), then renamed whole to <name>.removing (one step; a lock there keeps it whole and the
  # next run checks it again), then removed. If a file stays locked past the retries, that recorded folder is what is
  # left, and the next run of the same step finishes it (Complete-Removing). -InPlace (the import cache) skips the
  # rename: a cache may go part way.
  if (Test-Paused) { throw 'the Board PC pause is active' }
  if ($InPlace) { return (Remove-LinkSafeTree $path) }
  if ($Commit -notmatch '\A[0-9a-f]{40}\z') { throw 'a removal needs the commit its checks proved' }
  $full = $path.TrimEnd('\', '/')
  $tomb = $full + '.removing'
  if (Test-Path -LiteralPath $tomb) { throw "$tomb already exists" }
  $record = Join-Path (Split-Path -Parent $full) 'removing.txt'
  [IO.File]::AppendAllText($record, ('{0}.removing {1}' -f (Split-Path -Leaf $full), $Commit) + "`r`n")
  try { Invoke-Retry { [IO.Directory]::Move($full, $tomb) } $full }
  catch { throw "nothing removed: $($_.Exception.Message)" }
  try { $bytes = Remove-LinkSafeTree $tomb }
  catch { throw "partly removed; the rest is $tomb, which the next run finishes ($($_.Exception.Message))" }
  Set-RemovingRecord $record (Split-Path -Leaf $tomb)
  return $bytes
}
function Set-RemovingRecord($record, $done) {
  # Drop the finished name from removing.txt (and the file when nothing is left in it).
  if (-not (Test-Path -LiteralPath $record -PathType Leaf)) { return }
  $keep = @([IO.File]::ReadAllLines($record) | Where-Object { $_.Trim() -and ($_ -split ' ')[0] -cne $done })
  if ($keep.Count) { [IO.File]::WriteAllLines($record, [string[]]$keep) } else { [IO.File]::Delete($record) }
}
function Complete-Removing($folder, [string[]]$names, $pins = $null) {
  # Finish only removals this file recorded itself (Artoo on PR 1498: a .removing suffix alone is no proof): a
  # removing.txt line "<name>.removing <commit>" in $folder whose <name> is one of $names (the attempt's listed
  # checkouts, or repo for a ship job), for a plain folder of exactly that name with no link above it, whose .git\HEAD,
  # while it is still there, is that commit. Anything else is reported and left alone.
  $bytes = [long]0
  $record = Join-Path $folder 'removing.txt'
  if (-not (Test-Path -LiteralPath $record -PathType Leaf)) { return $bytes }
  foreach ($line in @([IO.File]::ReadAllLines($record))) {
    if (-not $line.Trim()) { continue }
    if ($line -notmatch '\A([A-Za-z0-9_-]{1,40})\.removing ([0-9a-f]{40})\z' -or $names -cnotcontains $Matches[1]) { Write-Output "removing.txt line not accepted, left alone: $line"; continue }
    $name = $Matches[1]; $commit = $Matches[2]
    # The record must name the listed pin (review of PR 1644), when the caller knows the pins.
    if ($pins -and $pins[$name] -ne $commit) { Write-Output "removing.txt line does not name the listed pin, left alone: $line"; continue }
    $tomb = Join-Path $folder "$name.removing"
    try {
      $t = Get-Item -LiteralPath $tomb -Force -ErrorAction SilentlyContinue
      if ($null -eq $t) { Set-RemovingRecord $record "$name.removing"; continue }
      if (-not (Test-PlainDir $t)) { throw 'not a plain folder' }
      Assert-NoLinks $tomb
      $headFile = Join-Path (Join-Path $tomb '.git') 'HEAD'
      if ((Test-Path -LiteralPath $headFile -PathType Leaf) -and ([IO.File]::ReadAllText($headFile)).Trim() -ne $commit) { throw "its HEAD is not the recorded commit $commit" }
      if (Test-Paused) { throw 'the Board PC pause is active' }
      # The waiter's own checks once more, right before the tomb goes, as for a fresh checkout (Artoo on PR 1644).
      if ($script:beforeRemove) { & $script:beforeRemove }
      $gone = Remove-LinkSafeTree $tomb
      Set-RemovingRecord $record "$name.removing"
      $bytes += $gone
      Write-Output ("finished an earlier removal ({0:N1} GB): {1}" -f ($gone / 1GB), $tomb)
    } catch { Write-Output "earlier removal still unfinished: $tomb ($($_.Exception.Message))" }
  }
  return $bytes
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
function Lock-Mirror {
  # The mirror writers' lock (the same <mirror>.lock every fetch takes). A removal holds it from its relay and history
  # proof through the delete, so no fetch or prune between them can drop a ref the proof relied on (Artoo on PR 1592).
  # A caller with its own end (the relay waiter) waits no longer than that (review of PR 1644).
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  if ($script:waitUntil -and $script:waitUntil -lt $deadline) { $deadline = $script:waitUntil }
  while (-not $lock) {
    try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked past the wait limit' }; Start-Sleep -Milliseconds 500 }
  }
  return $lock
}
function Update-Mirror {
  # Under a removal's held lock (Lock-Mirror), fetch in it rather than wait on our own handle.
  if ($script:mirrorLock) {
    if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin' }
    Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
    return
  }
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
function Read-RelayReceipt($folder, $name = 'relay_receipt.txt') {
  # One line "<branch> <tree path>": the board/pc-out branch and the folder in its tree that holds this folder's results,
  # e.g. "board/pc-out-1211r6 out_20261120_223320_23241". $null when there is none or it is not well formed. Read from
  # relay_receipt.txt (older relays, written by dropcheckouts or droprepo from the Board's arguments) or relay_branch.txt
  # (issue 1535: the head writes it at init, before any result exists, naming where the Board relays this attempt).
  $file = Join-Path $folder $name
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $null }
  $line = [string](Get-Content -LiteralPath $file -TotalCount 1)
  if ($line -notmatch ('\A(' + $relayPattern + ') ([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*)\s*\z') -or $line.Contains('..')) { return $null }
  return @{ Ref = $Matches[1]; Path = $Matches[2]; From = $name }
}
function Get-RelayPlace($base, $job, $tree) {
  # Issue 1535 (Board, Nov 22): the PC session will not write relay_receipt.txt by hand (that file unlocks deletes), so
  # since PR 1498 no job cleared its checkouts. Where to look comes from the job itself: a receipt from an older relay,
  # else the relay_branch.txt the head wrote at init, else the job's own name (board/pc-out-<job>, the attempt at
  # <tree>). Only a place to look: the proof is origin's branch holding every result file's exact bytes there.
  $r = Read-RelayReceipt $base
  if ($r) { return $r }
  # Issue 1739 (Board, Nov 22): since PR 1672 the head writes relay_branch.txt (relay/pc-out-<job>) at init, so an attempt
  # the Board relayed to a board/pc-out-* branch instead never proved. relayfind writes the place it proved byte for byte
  # as relay_found.txt, which wins over the init guess; the drop and the janitor prove the bytes there again.
  $r = Read-RelayReceipt $base 'relay_found.txt'
  if ($r) { return $r }
  $r = Read-RelayReceipt $base 'relay_branch.txt'
  if ($r) { return $r }
  if ("board/pc-out-$job $tree" -notmatch '\Aboard/pc-out-[A-Za-z0-9._-]+ [A-Za-z0-9._-]+\z' -or "$job$tree".Contains('..')) { return $null }
  # Issue 1657: the relay repo first when its mirror holds pc-out-<job>, else the main repo's board/pc-out-<job>.
  if (Test-Path -LiteralPath (Join-Path $relayMirror 'HEAD')) {
    $ErrorActionPreference = 'Continue'
    $null = & $gitExe --git-dir $relayMirror rev-parse --verify -q "refs/heads/pc-out-$job^{commit}" 2>$null
    $found = $LASTEXITCODE -eq 0; $ErrorActionPreference = 'Stop'
    if ($found) { return @{ Ref = "relay/pc-out-$job"; Path = $tree; From = 'the job name' } }
  }
  return @{ Ref = "board/pc-out-$job"; Path = $tree; From = 'the job name' }
}
function Write-RelayReceipt($folder, $ref, $path) {
  if (-not $ref) { return }
  if ("$ref $path" -notmatch ('\A' + $relayPattern + ' [A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*\z') -or $path.Contains('..')) { throw "relay receipt not accepted: $ref $path" }
  [IO.File]::WriteAllText((Join-Path $folder 'relay_receipt.txt'), "$ref $path`r`n")
  Write-Output "relay receipt written: $ref $path"
}
function Test-ReceiptTree($receipt, $base, [string[]]$dirs, $skip, $got = $null) {
  # Read the relay's exclusions at the verified tip before walking local results. Descending into a listed cache
  # can fail at MAX_PATH even before we can compare its files. $null when the branch is not in the mirror.
  $repo = Get-RelayRepo $receipt.Ref
  if (-not $repo.Source -or -not (Test-Path -LiteralPath (Join-Path $repo.Mirror 'HEAD'))) { return $null }
  $ErrorActionPreference = 'Continue'
  $sha = (& $gitExe --git-dir $repo.Mirror rev-parse --verify -q "refs/heads/$($repo.Ref)^{commit}" 2>$null) | Select-Object -Last 1
  if ($LASTEXITCODE -ne 0 -or -not $sha) { return $null }
  $ErrorActionPreference = 'Stop'
  # Origin itself must hold the branch at this commit (git ls-remote), so a branch deleted or moved on GitHub since the
  # last fetch proves nothing; a different commit refetches once (issue 1535). A failed ls-remote throws: kept.
  $remote = @(Run-Git ls-remote $repo.Source "refs/heads/$($repo.Ref)") | Where-Object { "$_" -match '\A[0-9a-f]{40}\t' } | Select-Object -First 1
  if (-not $remote -or "$remote".Substring(0, 40) -ne $sha) { return $null }
  $have = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  $cacheManifest = $null
  $cacheManifestPath = $receipt.Path + '/relay_manifest/skipped_cache_folders.txt'
  foreach ($l in (Run-Git --git-dir $repo.Mirror -c core.quotepath=false ls-tree -r -t $sha -- "$($receipt.Path)/")) {
    if ("$l" -notmatch '\A(\d+) (blob|tree|commit) ([0-9a-f]{40})\t(.+)\z') { continue }
    $have[$Matches[4]] = if ($Matches[2] -eq 'blob') { $Matches[3] } else { '' }
    if ($Matches[4] -ceq $cacheManifestPath -and $Matches[1] -in @('100644', '100755')) { $cacheManifest = $Matches[3] }
  }
  $cacheFolders = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  if ($cacheManifest) {
    foreach ($k in (Run-Git --git-dir $repo.Mirror cat-file -p $cacheManifest)) {
      if (-not $have.ContainsKey($receipt.Path + '/' + $k)) { $null = $cacheFolders.Add($k) }
    }
  }
  if (-not $got -or $cacheFolders.Count) { $got = Get-ResultWant $base $dirs $skip $cacheFolders }
  $skipped = @()
  $bigManifest = $have[$receipt.Path + '/skipped_over_10MB.txt']
  if ($bigManifest) {
    $skipped = @(Run-Git --git-dir $repo.Mirror cat-file -p $bigManifest)
  }
  $miss = @(foreach ($k in $got.Want.Keys) {
    $at = $receipt.Path + '/' + $k
    if ($have[$at] -ne $got.Want[$k]) { @{ Key = $k; Absent = -not $have.ContainsKey($at) } }
  })
  return @{ Missing = $miss; Skipped = $skipped; Tip = $sha; Got = $got }
}
function Test-RelaySkipped($skipped, $key, $file) {
  # The relay leaves out files over 10 MB and lists each in skipped_over_10MB.txt as "<path with \> <size> MB" (Artoo on
  # PR 1498: board/pc-out da39c826, opus1415d_GL1_out). Such a file counts as accounted for only when it is absent from
  # the tree (never a different copy), is listed under its exact path, is over 10 MB here, and the listed size matches
  # its size in MB to 0.1. It stays on the PC: out folders are never removed here, only the rebuildable checkout.
  $len = (Get-Item -LiteralPath $file -Force).Length
  if ($len -le 10MB -and $len -le 10000000) { return $false }
  $want = $key.Replace('/', '\')
  foreach ($line in $skipped) {
    if ("$line".Trim() -notmatch '\A(.+) ([0-9]+(?:\.[0-9]+)?) MB\z') { continue }
    if ($Matches[1] -cne $want) { continue }
    $mb = [double]::Parse($Matches[2], [Globalization.CultureInfo]::InvariantCulture)
    if ([math]::Abs($mb - $len / 1MB) -le 0.1 -or [math]::Abs($mb - $len / 1000000) -le 0.1) { return $true }
  }
  return $false
}
function Get-ResultWant($base, [string[]]$dirs, $skip, $cacheFolders = $null) {
  # Key files by their paths under $base with /. Keep the paths of any listed cache folders we leave on the PC.
  $baseFull = [IO.Path]::GetFullPath($base).TrimEnd('\', '/')
  $receiptFile = Join-Path $baseFull 'relay_receipt.txt'
  $want = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  $files = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  $caches = @()
  foreach ($d in $dirs) {
    # Each result root must be a plain folder: $base itself (a ship job's out) or one inside it, never a link to another
    # folder's bytes (review of PR 1644).
    $root = Get-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue
    $rootFull = if ($root) { [IO.Path]::GetFullPath($root.FullName).TrimEnd('\', '/') } else { '' }
    if (-not (Test-PlainDir $root) -or -not ($rootFull.Equals($baseFull, [StringComparison]::OrdinalIgnoreCase) -or $rootFull.StartsWith($baseFull + $sep, [StringComparison]::OrdinalIgnoreCase))) { throw "a result folder is not a plain folder in $base`: $d" }
    $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
    $pending.Push($root)
    while ($pending.Count) {
      foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
        if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link in the results: $($e.FullName)" }
        $k = $e.FullName.Substring($baseFull.Length + 1).Replace('\', '/')
        if ($e -is [IO.DirectoryInfo]) {
          if ($skip -contains $e.Name) { continue }
          if ($cacheFolders -and $cacheFolders.Contains($k)) { $caches += $k } else { $pending.Push($e) }
          continue
        }
        if ($e.FullName -eq $receiptFile) { continue }
        $want[$k] = Get-BlobSha $e.FullName; $files[$k] = $e.FullName
      }
    }
  }
  return @{ Want = $want; Files = $files; Caches = $caches }
}
function Test-PlaceProof($place, $base, [string[]]$dirs, $skip, $got = $null) {
  # The same proof as Assert-Relayed without a fetch, for the relay search (issue 1695).
  try { $r = Test-ReceiptTree $place $base $dirs $skip $got } catch { return "relay proof failed: $($_.Exception.Message)" }
  if ($null -eq $r) { return "branch $($place.Ref) is not on origin at the shared mirror's commit" }
  if (-not $r.Got.Want.Count) { return "no result files under $base to prove the relay" }
  $bad = @(foreach ($m in $r.Missing) {
    if ($m.Absent -and (Test-RelaySkipped $r.Skipped $m.Key $r.Got.Files[$m.Key])) { continue }
    if ($m.Absent) { "$($m.Key) is not on the relay" } else { "$($m.Key) differs on the relay" }
  })
  if (-not $bad.Count) { return '' }
  $more = if ($bad.Count -gt 3) { "; and $($bad.Count - 3) more" } else { '' }
  return ((($bad | Select-Object -First 3) -join '; ') + $more)
}
function Assert-Relayed($base, [string[]]$dirs, $skip, $job = '', $tree = '', $receipt = $null, [ref]$proof) {
  # Issue 1497 (Artoo on PR 1498): a checkout goes only once this folder's own results are relayed. $base names its
  # receipt (relay_receipt.txt: the branch and the tree folder that holds $base's results). Every file under each of
  # $dirs ($skip names leftovers folders this file writes after the relay) must be in that branch's tree at the
  # receipt's folder plus its path under $base, with the same bytes, or be a file over 10 MB the relay left out and
  # listed in skipped_over_10MB.txt. Cache folders listed in relay_manifest/skipped_cache_folders.txt also stay on the
  # PC when absent from the relay tree. No receipt, no branch or any other difference keeps the checkout.
  if (-not $receipt) { $receipt = Get-RelayPlace $base $job $tree }
  if (-not $receipt) { throw "results not relayed yet: no relay branch named for $base" }
  $bad = $null; $big = @()
  for ($try = 0; $try -lt 2; $try++) {
    if ($try) { if ($script:dropDry) { break }; if ($receipt.Ref -like 'relay/*') { Update-RelayMirror } else { Update-Mirror } }
    $r = Test-ReceiptTree $receipt $base $dirs $skip
    if ($null -eq $r) { $bad = @("branch $($receipt.Ref) (from $($receipt.From)) is not on origin at the shared mirror's commit"); continue }
    $want = $r.Got.Want
    if (-not $want.Count) { throw "no result files under $base to prove the relay" }
    $big = @(); $bad = @()
    foreach ($m in $r.Missing) {
      if ($m.Absent -and (Test-RelaySkipped $r.Skipped $m.Key $r.Got.Files[$m.Key])) { $big += $m.Key }
      elseif ($m.Absent) { $bad += "$($m.Key) is not on the relay" }
      else { $bad += "$($m.Key) differs on the relay" }
    }
    if (-not $bad.Count) { break }
  }
  if ($bad.Count) {
    $more = if ($bad.Count -gt 3) { "; and $($bad.Count - 3) more" } else { '' }
    throw ("results not relayed yet: {0}:{1}: {2}{3}" -f $receipt.Ref, $receipt.Path, (($bad | Select-Object -First 3) -join '; '), $more)
  }
  if ($proof) { $proof.Value = @{ Place = $receipt; Tip = $r.Tip } }
  foreach ($k in $big) { Write-Output "result kept on the PC only: $k (the relay listed it in skipped_over_10MB.txt)" }
  foreach ($k in $r.Got.Caches) { Write-Output "cache folder kept on the PC only: $k (the relay listed it in relay_manifest/skipped_cache_folders.txt)" }
  Write-Output "results relayed: $($want.Count - $big.Count) of $($want.Count) result file(s) are on $($receipt.Ref) under $($receipt.Path), $($big.Count) over 10 MB listed as skipped"
}
function Drop-Attempt($attempt, $place = $null) {
  # The listed pinned checkouts of one attempt folder, once the attempt passed and its results are relayed; adds the
  # bytes removed to $script:freed. Every refusal is logged, never thrown. A live run takes the mirror writers' lock
  # first and holds it through the relay proof, any earlier unfinished removal (review of PR 1644: a tomb is finished
  # only after the same fresh proof) and every removal.
  $state = Get-AttemptState $attempt
  if ($state -ne 'PASS') { Write-Output "checkouts kept: $attempt $(if ($state) { 'failed' } else { 'has no result yet' }) (the janitor handles old failures)"; return }
  $list = Join-Path $attempt 'checkouts.txt'
  if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { Write-Output "no checkouts listed in $attempt"; return }
  $pins = @{}
  foreach ($l in [IO.File]::ReadAllLines($list)) { if ($l -match '\A([A-Za-z0-9_-]{1,40}) ([0-9a-f]{40})\z') { $pins[$Matches[1]] = $Matches[2] } }
  if ($script:dropDry) { foreach ($n in $pins.Keys) { if (Test-Path -LiteralPath (Join-Path $attempt "$n.removing")) { Write-Output "earlier removal would be finished after the relay proof if removing.txt recorded it: $(Join-Path $attempt "$n.removing")" } } }
  if (-not @(Get-ListedLeft $attempt).Count) { Write-Output "no listed checkout left in $attempt"; return }
  $outs = @((Get-Item -LiteralPath $attempt -Force).EnumerateDirectories('out_*') | ForEach-Object { $_.FullName })
  if (-not $script:dropDry) {
    try { $script:mirrorLock = Lock-Mirror; $script:relayLock = Lock-RelayMirror }
    catch { if ($script:mirrorLock) { $script:mirrorLock.Dispose(); $script:mirrorLock = $null }; Write-Output "checkouts kept: $attempt ($($_.Exception.Message))"; return }
  }
  $followUp = $null
  try { Drop-Proven $attempt $list $outs $pins $place ([ref]$followUp) } finally {
    if ($script:relayLock) { $script:relayLock.Dispose(); $script:relayLock = $null }
    if ($script:mirrorLock) { $script:mirrorLock.Dispose(); $script:mirrorLock = $null } }
  if ($followUp) {
    $relayPush = Join-Path (Split-Path -Parent $PSScriptRoot) 'relay_push.ps1'
    $shell = if ($unix) { 'pwsh' } else { 'powershell.exe' }
    $argsForRelay = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $relayPush, $followUp.Place.Ref.Substring('relay/pc-out-'.Length),
      $attempt, 'leftovers', '-TreePath', $followUp.Place.Path, '-ProvenTip', $followUp.Tip)
    $ErrorActionPreference = 'Continue'
    & $shell @argsForRelay 2>&1 | ForEach-Object { "$_" }
    $sent = $LASTEXITCODE -eq 0
    $ErrorActionPreference = 'Stop'
    if (-not $sent) { Write-Output "checkout leftovers kept locally in $attempt. Retry with relay_push leftovers." }
  }
}
function Drop-Proven($attempt, $list, $outs, $pins, $place, [ref]$followUp) {
  # Drop-Attempt's proof and removals, under the held mirror lock on a live run.
  $present = @(foreach ($n in $pins.Keys) { if (Test-Path -LiteralPath (Join-Path $attempt $n)) { $n } })
  $proof = $null
  try { Assert-Relayed $attempt $outs @('checkout_leftovers') (Split-Path -Leaf (Split-Path -Parent $attempt)) (Split-Path -Leaf $attempt) $place ([ref]$proof) }
  catch { Write-Output "checkouts kept: $attempt ($($_.Exception.Message))"; return }
  if ($script:dropDry) {
    foreach ($n in $present) { Write-Output "checkout $n would be checked and removed after the relay: $(Join-Path $attempt $n)" }
    return
  }
  foreach ($o in @(Complete-Removing $attempt @($pins.Keys) $pins)) { if ($o -is [long]) { $script:freed += $o } else { Write-Output $o } }
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
      # The waiter's own checks once more, right before anything is saved or renamed (review of PR 1644).
      if ($script:beforeRemove) { & $script:beforeRemove }
      if ($work.Count) {
        $dest = Join-Path (Join-Path $attempt "out_$name") 'checkout_leftovers'
        try { Write-Output (Save-Leftovers $repo $work $dest) }
        catch { throw ("it holds {0} path(s) that are not rebuildable leftovers and could not be saved ({1}), e.g. {2}" -f $work.Count, $_.Exception.Message, (($work | Select-Object -First 5) -join '; ')) }
      }
      if ($work.Count -and $proof.Place.Ref -like 'relay/*') { $followUp.Value = $proof }
      $gone = Remove-Owned $repo -Commit $pin
      $script:freed += $gone
      Write-Output ("checkout {0} removed after the job ({1:N1} GB): {2}" -f $name, ($gone / 1GB), $repo)
    } catch { Write-Output "checkout $name kept: $repo ($($_.Exception.Message))" }
  }
}
function Get-ListedLeft($attempt) {
  # Listed checkouts of an attempt still on disk, or left as a recorded <name>.removing (review of PR 1592).
  $list = Join-Path $attempt 'checkouts.txt'
  if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { return @() }
  return @(foreach ($l in [IO.File]::ReadAllLines($list)) { if ($l -match '\A([A-Za-z0-9_-]{1,40}) [0-9a-f]{40}\z' -and ((Test-Path -LiteralPath (Join-Path $attempt $Matches[1])) -or (Test-Path -LiteralPath (Join-Path $attempt "$($Matches[1]).removing")))) { $Matches[1] } })
}
function Open-PlainLock($path) {
  # An exclusive lock on a plain file: an existing link, folder or anything else is refused, never followed (review of
  # PR 1644, as the janitor's Open-CleanupLock).
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($item -and ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) { throw "lock is not a plain file: $path" }
  return [IO.File]::Open($path, 'OpenOrCreate', 'ReadWrite', 'None')
}
function Get-WaitGuard($attempt) {
  # The janitor's checks before it removes anything from a job folder (Artoo and review of PR 1644): the Board keep list,
  # read fresh each time, no running process naming the job folder (the janitor's own whole-folder match; the waiter
  # names its attempt only in its environment, so it never matches itself), and no Board PC pause. '' when clear, else
  # why: the waiter keeps everything and tries again at its next look. The caller holds the job lease and the issue lock.
  $jobDir = Split-Path -Parent $attempt
  $keepFile = Join-Path $vt 'janitor_keep.txt'
  $keepItem = Get-Item -LiteralPath $keepFile -Force -ErrorAction SilentlyContinue
  if ($keepItem) {
    if ($keepItem -isnot [IO.FileInfo] -or ($keepItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return "the Board keep list is not a plain file: $keepFile" }
    foreach ($line in [IO.File]::ReadAllLines($keepFile)) {
      $p = $line.Trim().TrimStart([char]0xFEFF)
      if (-not $p -or $p.StartsWith('#')) { continue }
      $keep = [IO.Path]::GetFullPath($p).TrimEnd('\', '/')
      foreach ($mine in @($jobDir, $attempt)) {
        if ($keep.Equals($mine, [StringComparison]::OrdinalIgnoreCase) -or $keep.StartsWith($mine + $sep, [StringComparison]::OrdinalIgnoreCase) -or
            $mine.StartsWith($keep + $sep, [StringComparison]::OrdinalIgnoreCase)) { return "on the Board keep list ($keep)" }
      }
    }
  }
  $lines = $null
  if ($test -and $null -ne $env:PC_TEST_COMMAND_LINES) { $lines = @($env:PC_TEST_COMMAND_LINES -split "`n" | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Id = 0; Line = $_ } }) }
  else {
    try { $lines = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.CommandLine -and $_.ProcessId -ne $PID } | ForEach-Object { [pscustomobject]@{ Id = $_.ProcessId; Line = $_.CommandLine } }) }
    catch { return 'running processes could not be checked' }
  }
  $needle = [regex]::Escape($jobDir) + '(?=$|[\\/"''\s])'
  foreach ($proc in $lines) { if ($proc.Line -match $needle) { return "a running process names this job folder (process $($proc.Id))" } }
  if (Test-Paused) { return 'the Board PC pause is active' }
  return ''
}
function Invoke-LsRemote($ref, $seconds) {
  # git ls-remote with a time limit and no prompts (review of PR 1644): the tip's 40 hex, '' when the branch is not on
  # origin; throws when Git fails or runs past the limit (then killed).
  $psi = New-Object Diagnostics.ProcessStartInfo
  $psi.FileName = $gitExe; $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
  # A relay/pc-out-<job> place is branch pc-out-<job> of the relay repo (issue 1657); board/pc-out-* is the main repo.
  $repo = Get-RelayRepo $ref
  if (-not $repo.Source) { throw "no relay repo address for $ref" }
  $psi.Arguments = "ls-remote `"$($repo.Source)`" `"refs/heads/$($repo.Ref)`""
  $psi.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'; $psi.EnvironmentVariables['GCM_INTERACTIVE'] = 'never'
  $p = [Diagnostics.Process]::Start($psi)
  $out = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
  if (-not $p.WaitForExit([int]([Math]::Max(1, $seconds) * 1000))) { try { $p.Kill() } catch { }; throw "git ls-remote ran past $seconds s" }
  if ($p.ExitCode -ne 0) { throw "git ls-remote failed (exit $($p.ExitCode))" }
  $line = @($out.Result -split "`n" | Where-Object { $_ -match '\A[0-9a-f]{40}\t' }) | Select-Object -First 1
  if ($line) { return "$line".Substring(0, 40) }
  return ''
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
  # The commit is on a branch or tag the shared mirror keeps, not merely an object in it: an object no ref reaches is
  # pruned in time (Artoo on PR 1498).
  $ErrorActionPreference = 'Continue'
  $refs = @(& $gitExe --git-dir $mirror for-each-ref --contains $sha '--format=%(refname)' --count=1 2>$null)
  return ($LASTEXITCODE -eq 0 -and $refs.Count -gt 0 -and "$($refs[0])".Trim())
}
function Assert-Rebuildable($repo) {
  # Every local branch and HEAD is a commit the shared mirror holds, or a two-parent merge (PAINT_BASE) of mirror commits
  # that git merges again to exactly the same tree (Artoo on PR 1498: a merge with its own conflict edits is work).
  # Every ref the checkout has (branches, tags, notes, any other; HEAD too) is checked, peeled to its commit. Only
  # refs/remotes/ is left out: those are copies of the mirror's own refs, never local work. A ref that is not a branch
  # (a tag, notes, anything else) carries its own name and object (an annotated tag's message), so the mirror must hold
  # that same ref name with that exact object, or the checkout stays (Artoo on PR 1498).
  $stash = @(Run-Git -C $repo for-each-ref '--format=%(objectname)' refs/stash | Where-Object { $_ })
  if ($stash.Count) { throw 'it has a stash' }
  $tips = @((Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1)
  # Issue 1396 (review of PR 1592): a detached checkout can go back to its pin and look clean while its reflog still holds
  # a commit made there, and a linked worktree can hold work under this .git. Every commit in the reflog of HEAD and of
  # each local branch counts as a tip (remote-tracking reflogs are copies of the mirror's history), and a second
  # worktree keeps the checkout.
  $worktrees = @(Run-Git -C $repo worktree list --porcelain | Where-Object { "$_".StartsWith('worktree ') })
  if ($worktrees.Count -ne 1) { throw "it has $($worktrees.Count) worktrees, not 1" }
  $logged = @('HEAD') + @(Run-Git -C $repo for-each-ref '--format=%(refname)' refs/heads/ | Where-Object { $_ })
  foreach ($ref in $logged) {
    if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $repo '.git') (Join-Path 'logs' $ref)) -PathType Leaf)) { continue }
    $tips += @(Run-Git -C $repo reflog show '--format=%H' $ref -- | Where-Object { "$_" -match '\A[0-9a-f]{40}\z' })
  }
  foreach ($line in @(Run-Git -C $repo for-each-ref '--format=%(objectname) %(refname)' | Where-Object { $_ })) {
    $own, $name = "$line".Trim() -split ' ', 2
    if ($name.StartsWith('refs/remotes/') -or $name.StartsWith('refs/heads/')) { continue }
    $ErrorActionPreference = 'Continue'
    $theirs = @(& $gitExe --git-dir $mirror show-ref --verify $name 2>$null)
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0 -or -not $theirs.Count -or "$($theirs[0])".Trim() -ne "$own $name") { throw "ref $name is not in the shared mirror with the same object" }
  }
  foreach ($ref in @(Run-Git -C $repo for-each-ref '--format=%(refname)' | Where-Object { $_ -and -not "$_".StartsWith('refs/remotes/') })) {
    $peeled = $null
    try { $peeled = (Run-Git -C $repo rev-parse --verify -q "$ref^{commit}") | Select-Object -Last 1 } catch { $peeled = $null }
    if (-not $peeled) { throw "ref $ref does not name a commit" }
    $tips += $peeled
  }
  foreach ($t in ($tips | Sort-Object -Unique)) {
    if (Test-InMirror $t) { continue }
    # not on a mirror ref: only a two-parent merge git rebuilds exactly (below) may go
    $parents = @(((Run-Git -C $repo rev-list --parents -n 1 $t) | Select-Object -Last 1) -split ' ' | Select-Object -Skip 1)
    if ($parents.Count -ne 2) { throw "commit $t is on no branch or tag of the shared mirror" }
    foreach ($p in $parents) { if (-not (Test-InMirror $p)) { throw "commit $p (a parent of $t) is on no branch or tag of the shared mirror" } }
    $tree = (Run-Git -C $repo rev-parse "$t^{tree}") | Select-Object -Last 1
    $again = $null
    try { $again = (Run-Git -C $repo merge-tree --write-tree $parents[0] $parents[1]) | Select-Object -First 1 } catch { $again = $null }
    if ("$again".Trim() -ne $tree) { throw "merge $t is on no branch or tag of the shared mirror and git does not rebuild its exact tree from its parents" }
  }
}
function Get-TreeBytes($path) {
  # read only, links not followed. Issue 1739: with disk_space.ps1, the bytes removal would really free (a hard link
  # shared with a file outside the tree counts nothing).
  $tally = $null; if (Get-Command New-FreeTally -ErrorAction SilentlyContinue) { $tally = New-FreeTally }
  $bytes = [long]0
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push((Get-Item -LiteralPath $path -Force))
  while ($pending.Count) {
    foreach ($e in @($pending.Pop().EnumerateFileSystemInfos())) {
      if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($e -is [IO.DirectoryInfo]) { $pending.Push($e) } else { $bytes += $e.Length; if ($tally) { Add-FreeTally $tally $e } }
    }
  }
  if ($tally) { return (Complete-FreeTally $tally).Free }
  return $bytes
}
function Invoke-WithPinnedMirror($pin, [scriptblock]$then) {
  # Under the mirror writers' lock: make the shared mirror on first use, fetch it only when the pin is missing, then run
  # $then (a clone or a slot fetch from the mirror) while the lock is still held.
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  while (-not $lock) {
    try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 }
  }
  try {
    if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init -q --bare $mirror | Out-Null; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source | Out-Null }
    if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
    $ErrorActionPreference = 'Continue'
    & $gitExe --git-dir $mirror cat-file -e "$pin^{commit}" 2>$null
    $have = $LASTEXITCODE -eq 0
    $ErrorActionPreference = 'Stop'
    if (-not $have) {
      Write-Output "fetching the shared mirror for $pin"
      Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch -q --prune origin | Out-Null
      Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main | Out-Null
    }
    Run-Git --git-dir $mirror cat-file -e "$pin^{commit}" | Out-Null
    & $then
  } finally { $lock.Dispose() }
}

# ---------------------------------------------------------------------------------------------- warm slots (issue 1659)
# Ryan, Nov 22 2026 (Wave 2.1): a job resets a warm slot to its pin instead of making a fresh checkout per attempt (about
# 10 GB real each: the ships copy and the import cache). Three slots under voidsworn_test\slots: slot_gpu_1, slot_gpu_2
# (OJ_SLOT_KIND=gpu, the default) and slot_cpu (cpu). Each holds one reused `clone --local` of repo-mirror.git in repo\,
# so git objects stay hardlinked and the mirror's locking is unchanged. A slot's lease (.slot-lease) is held open by a
# hidden holder process for the whole job; it lets go when the job's cmd exits or the tail asks (slotrelease). Before a
# reset, anything the last job left in the slot that is not proven rebuildable is saved into that job's attempt
# (Get-KeptWork and Save-Leftovers, as dropcheckouts does); when that cannot be done the slot is set aside with hold.txt
# for the Board and another slot is used. The reset is a forced checkout of the pin and `git clean -ffdx` that keeps only
# godot\.godot (the warm import cache) and *.import sidecars; it deletes only inside voidsworn_test\slots.
$slotsRoot = Join-Path $vt 'slots'
function Get-SlotNames($kind) {
  if ($kind -eq 'gpu') { return @('slot_gpu_1', 'slot_gpu_2') }
  if ($kind -eq 'cpu') { return @('slot_cpu') }
  throw "OJ_SLOT_KIND must be gpu or cpu, got: $kind"
}
function Get-OwnerProcess {
  # The cmd.exe running the job bat is this script's parent; its exit ends the lease.
  if ($test -and $env:PC_TEST_SLOT_OWNER_PID) { return [int]$env:PC_TEST_SLOT_OWNER_PID }
  if ($unix) { return (Get-Process -Id $PID).Parent.Id }
  return [int](Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
}
function Get-ProcStart($id) {
  # tests (Linux): a killed process nobody has reaped yet still lists; it has ended all the same
  if ($unix -and (Test-Path -LiteralPath "/proc/$id/status") -and ([IO.File]::ReadAllText("/proc/$id/status") -match '(?m)^State:\s+Z')) { return [long]0 }
  try { return (Get-Process -Id $id -ErrorAction Stop).StartTime.ToUniversalTime().Ticks } catch { return [long]0 }
}
function Test-SameProcess($id, $start) {
  # still the job's own process, not a later one given the same id (Linux reads start times to about a second)
  $now = Get-ProcStart $id
  return $now -and [Math]::Abs($now - $start) -lt 20000000
}
function Assert-SlotDir($dir) {
  # The slots folder and the slot itself are plain folders (a link would send the reset's deletes elsewhere).
  foreach ($p in @($slotsRoot, $dir)) {
    $i = Get-Item -LiteralPath $p -Force
    if (-not ($i -is [IO.DirectoryInfo]) -or ($i.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "not a plain folder: $p" }
  }
}
function Start-SlotHolder($dir, $owner, $ownerStart, $token, $attempt) {
  $env:OJ_SLOT_DIR = $dir; $env:OJ_SLOT_OWNER = "$owner"; $env:OJ_SLOT_OWNER_START = "$ownerStart"; $env:OJ_SLOT_TOKEN = $token
  $env:OJ_SLOT_ATTEMPT = $attempt
  $exe = (Get-Process -Id $PID).Path
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, 'slothold')
  # tests (Linux): the holder must not keep the caller's output pipes open
  if ($unix) { $null = Start-Process -FilePath $exe -ArgumentList $argList -RedirectStandardOutput '/dev/null' -RedirectStandardError (Join-Path $dir "holder_$token.err") }
  else { $null = Start-Process -WindowStyle Hidden -FilePath $exe -ArgumentList ($argList | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) }
}
function Get-SlotWaitMinutes { if ($env:OJ_SLOT_WAIT_MINUTES -match '\A[0-9]{1,4}\z') { return [int]$env:OJ_SLOT_WAIT_MINUTES }; return 360 }
function Enter-Slot($attempt) {
  # Takes a free slot of OJ_SLOT_KIND for this attempt (waits up to OJ_SLOT_WAIT_MINUTES, 360) and records it in the
  # attempt's slot.txt: "<slot folder>|<token>". Returns the slot folder.
  $kind = if ($env:OJ_SLOT_KIND) { $env:OJ_SLOT_KIND } else { 'gpu' }
  $names = Get-SlotNames $kind
  if (-not (Test-Path -LiteralPath $slotsRoot)) { $null = New-Item -ItemType Directory -Path $slotsRoot }
  $owner = Get-OwnerProcess; $ownerStart = Get-ProcStart $owner
  if (-not $ownerStart) { throw "cannot read the job's own process ($owner)" }
  $deadline = [DateTime]::UtcNow.AddMinutes((Get-SlotWaitMinutes)); $said = $false
  while ($true) {
    foreach ($n in $names) {
      $dir = Join-Path $slotsRoot $n
      if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir }
      Assert-SlotDir $dir
      if (Test-SlotHold $dir) { continue }
      try { ([IO.File]::Open((Join-Path $dir '.slot-lease'), 'OpenOrCreate', 'ReadWrite', 'None')).Dispose() } catch [IO.IOException] { continue }
      $token = [guid]::NewGuid().ToString('N')
      Start-SlotHolder $dir $owner $ownerStart $token $attempt
      $ready = Join-Path $dir "holder_$token.txt"; $until = [DateTime]::UtcNow.AddSeconds(60); $got = ''
      while ([DateTime]::UtcNow -lt $until) {
        if (Test-Path -LiteralPath $ready) { $got = [IO.File]::ReadAllText($ready).Trim(); if ($got) { break } }
        Start-Sleep -Milliseconds 200
      }
      # Holds are read again under the new lease (Astra run 5 on PR 1835): a hold the PC daemon restored while this
      # claimant was between its two looks is seen here, and the slot is let go untouched.
      if ($got -like 'held *' -and (Test-SlotHeld $dir $token) -and (Test-SlotHold $dir)) {
        [IO.File]::WriteAllText((Join-Path $dir "release_$token"), 'held by hold.txt'); continue
      }
      if ($got -like 'held *' -and (Test-SlotHeld $dir $token)) {
        [IO.File]::WriteAllText((Join-Path $attempt 'slot.txt'), "$dir|$token`r`n")
        Write-Output "slot $n taken for $attempt (holder $($got.Substring(5)), job process $owner)"
        return $dir
      }
      if (-not $got) { [IO.File]::WriteAllText((Join-Path $dir "release_$token"), 'no answer') }
    }
    if ([DateTime]::UtcNow -ge $deadline) { throw "no free $kind slot after $(Get-SlotWaitMinutes) minutes ($($names -join ', '))" }
    if (-not $said) { Write-Output "waiting for a free $kind slot ($($names -join ', '))"; $said = $true }
    Start-Sleep -Seconds $(if ($test) { 1 } else { 15 })
  }
}
function Test-SlotHold($dir) {
  # The slot is set aside for the Board: hold.txt, or the PC daemon's in-flight marker while it is being cleared
  # (pc_daemon.js clearInFlight renames it to hold.txt.<token>.clearing for a moment).
  if (Test-Path -LiteralPath (Join-Path $dir 'hold.txt')) { return $true }
  return [bool]@(Get-ChildItem -LiteralPath $dir -Force -File -Filter 'hold.txt.*.clearing' -ErrorAction SilentlyContinue).Count
}
function Test-SlotHeld($dir, $token) {
  # Artoo on PR 1728: a holder stopped abruptly leaves its marker behind, so the marker alone proves nothing. All three
  # must hold: the marker names a holder process that still runs (same start time), owner.txt names this token (a later
  # holder rewrites it), and the lease file is locked right now.
  $ready = Join-Path $dir "holder_$token.txt"
  if (-not (Test-Path -LiteralPath $ready -PathType Leaf)) { return $false }
  if ([IO.File]::ReadAllText($ready).Trim() -notmatch '\Aheld ([0-9]+) ([0-9]+)\z') { return $false }
  if (-not (Test-SameProcess ([int]$Matches[1]) ([long]$Matches[2]))) { return $false }
  $own = Join-Path $dir 'owner.txt'
  if (-not (Test-Path -LiteralPath $own -PathType Leaf) -or -not ([IO.File]::ReadAllText($own) -match "(?m)^token $token\r?$")) { return $false }
  try { ([IO.File]::Open((Join-Path $dir '.slot-lease'), 'OpenOrCreate', 'ReadWrite', 'None')).Dispose(); return $false } catch [IO.IOException] { return $true }
}
function Get-HeldSlot($attempt) {
  # The slot this attempt holds, checked: its holder still answers for the token in slot.txt.
  $f = Join-Path $attempt 'slot.txt'
  if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { return $null }
  $parts = [IO.File]::ReadAllText($f).Trim().Split('|')
  if ($parts.Count -ne 2) { throw "slot.txt not readable in $attempt" }
  if (-not (Test-SlotHeld $parts[0] $parts[1])) { throw "the lease on $($parts[0]) is no longer held for this attempt; nothing in it was touched" }
  return @{ Dir = $parts[0]; Token = $parts[1] }
}
function Set-SlotHold($dir, $why, $u) {
  # The slot is set aside for the Board (Enter-Slot skips it) and the caller moves on or fails; nothing in it is changed.
  [IO.File]::WriteAllText((Join-Path $dir 'hold.txt'), "$why`r`nlast use: $($u.attempt) $($u.name)`r`nThe Board removes this file once it has looked.`r`n")
  throw "slot held: $why"
}
function Exit-Slot($attempt, $expect = $null) {
  $f = Join-Path $attempt 'slot.txt'
  if (-not (Test-Path -LiteralPath $f -PathType Leaf)) {
    # a caller that was given a lease (the PC daemon) never takes a missing receipt as a release (Artoo on 7fd738f2)
    if ($expect) { throw "slot kept: no slot.txt in $attempt for the lease it was given ($expect); nothing was released" }
    Write-Output "no slot held by $attempt"; return
  }
  $receipt = [IO.File]::ReadAllText($f).Trim()
  $parts = $receipt.Split('|')
  # Artoo on PR 1835 (Astra run 6): a release only ever touches the slot this attempt holds. The receipt must be one slot
  # and one token, match the lease the caller was given (the PC daemon passes it), and owner.txt must name exactly this
  # attempt and this token; anything else keeps the slot as it is and fails, so a stale or edited receipt can never
  # release another job's slot.
  if ($parts.Count -ne 2 -or $parts[1] -notmatch '\A[0-9a-f]{32}\z' -or -not [IO.Path]::IsPathRooted($parts[0])) { throw "slot kept: slot.txt not readable in $attempt" }
  if ($expect -and $receipt -ne $expect) { throw "slot kept: slot.txt in $attempt no longer matches the lease it was given ($expect); nothing was released" }
  $ready = Join-Path $parts[0] "holder_$($parts[1]).txt"
  # Artoo on PR 1728: on the PC the recorded job process is the long-lived watcher shell, so a dead holder would keep the
  # slot busy until the watcher ends. The tail therefore marks its own token released itself, only while owner.txt still
  # names that attempt and token (a later job's owner.txt is never touched); the holder, when alive, ends on the release file.
  $ownerTxt = Join-Path $parts[0] 'owner.txt'
  $txt = if (Test-Path -LiteralPath $ownerTxt -PathType Leaf) { [IO.File]::ReadAllText($ownerTxt) } else { '' }
  $mine = ($txt -match ('(?m)^attempt ' + [regex]::Escape($attempt) + '\r?$')) -and ($txt -match ('(?m)^token ' + [regex]::Escape($parts[1]) + '\r?$'))
  if (-not $mine) {
    if ($expect) { throw "slot kept: owner.txt in $($parts[0]) does not name this attempt and token; nothing was released" }
    Write-Output "slot $($parts[0]) already let go (owner.txt names another attempt or token; it was left alone)"; return
  }
  if ($txt -notmatch '(?m)^released') { [IO.File]::AppendAllText($ownerTxt, "released $([DateTime]::UtcNow.ToString('o'))`r`n") }
  if (-not (Test-Path -LiteralPath $ready)) { Write-Output "slot $($parts[0]) already let go"; return }
  [IO.File]::WriteAllText((Join-Path $parts[0] "release_$($parts[1])"), "release`r`n")
  $until = [DateTime]::UtcNow.AddSeconds(30)
  while ((Test-Path -LiteralPath $ready) -and [DateTime]::UtcNow -lt $until) { Start-Sleep -Milliseconds 250 }
  if (Test-Path -LiteralPath $ready) { Write-Output "slot $($parts[0]): the holder did not end within 30 s; it ends with the job's process" }
  else { Write-Output "slot $($parts[0]) let go" }
}
function Reset-Slot($dir, $attempt, $name, $pin) {
  # Artoo on PR 1728: the lease is held by the holder process, so a holder that dies mid-reset would free the slot while
  # this process is still checking out and cleaning. Every reset therefore also holds the slot's own reset lock
  # (.slot-reset) from before its first check to after its last write, and proves the lease is still this attempt's both
  # after taking that lock and before letting it go. A claimant that got the lease in between waits on the reset lock;
  # this reset then fails at its last check, and the claimant starts from the state this reset left.
  $token = ([IO.File]::ReadAllText((Join-Path $attempt 'slot.txt')).Trim().Split('|'))[1]
  $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30)
  while (-not $lock) {
    try { $lock = [IO.File]::Open((Join-Path $dir '.slot-reset'), 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw "the reset lock of $dir stayed held for 30 minutes" }; Start-Sleep -Milliseconds 500 }
  }
  try {
    if (-not (Test-SlotHeld $dir $token)) { throw "the lease on $dir is no longer held for this attempt; nothing in it was touched" }
    if ($test -and $env:PC_TEST_SLOT_RESET_DELAY) { [IO.File]::WriteAllText((Join-Path $dir 'test_reset_in_flight'), ''); Start-Sleep -Seconds ([int]$env:PC_TEST_SLOT_RESET_DELAY) }
    # and once more under the lease and the reset lock, right before anything in the slot is touched
    if (Test-SlotHold $dir) { throw "slot held: $dir was set aside (hold.txt) after this attempt took it; nothing in it was touched" }
    Reset-SlotInner $dir $attempt $name $pin
    if (-not (Test-SlotHeld $dir $token)) { throw "the lease on $dir was lost during the reset; this checkout is not used" }
  } finally { $lock.Dispose() }
}
function Reset-SlotInner($dir, $attempt, $name, $pin) {
  # The slot's repo at exactly $pin, the last job's own leftovers saved first, ready for the ships step.
  Assert-SlotDir $dir
  $repo = Join-Path $dir 'repo'
  $last = Join-Path $dir 'last_use.txt'
  if (Test-Path -LiteralPath $repo) {
    $u = @{}
    if (Test-Path -LiteralPath $last -PathType Leaf) { foreach ($l in [IO.File]::ReadAllLines($last)) { if ($l -match '\A(attempt|name|src) (.+)\z') { $u[$Matches[1]] = $Matches[2] } } }
    $ri = Get-Item -LiteralPath $repo -Force
    if (-not ($ri -is [IO.DirectoryInfo]) -or ($ri.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Set-SlotHold $dir "the slot repo is not a plain folder: $repo" $u }
    $origin = ''
    try { $origin = (Run-Git -C $repo config --get remote.origin.url) | Select-Object -Last 1 } catch { $origin = '' }
    if ($origin -ne $mirror) { Set-SlotHold $dir "the slot repo $repo does not come from the shared mirror" $u }
    $nested = @(Get-ChildItem -LiteralPath $repo -Recurse -Force -Filter '.git' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne (Join-Path $repo '.git') } | Select-Object -First 1)
    if ($nested.Count) { Set-SlotHold $dir "a repo inside the slot repo: $($nested[0].FullName)" $u }
    # the last job's leftovers go to its own attempt before anything is reset
    $src = $null; $rec = @{}
    if ($u.attempt -and $u.name) {
      $rec = Read-ShipRecord (Join-Path $u.attempt "$($u.name)_ships_copied.txt")
      $sf = Join-Path $u.attempt 'ships_source.txt'
      if (Test-Path -LiteralPath $sf -PathType Leaf) { $src = ([IO.File]::ReadAllText($sf)).Trim() }
    }
    # a commit, branch or stash the last job made in the slot is never reset away: the slot is set aside instead
    $own = @()
    $heads = @(Run-Git -C $repo for-each-ref '--format=%(objectname) %(refname)' refs/heads refs/stash)
    $headSha = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
    foreach ($h in (@("$headSha HEAD") + $heads)) {
      $parts = "$h".Split(' ')
      if ($parts[1] -eq 'refs/stash') { $own += 'a stash'; continue }
      if (-not (Test-InMirror $parts[0])) { $own += "$($parts[1]) at $($parts[0]), which no mirror branch holds" }
    }
    if ($own.Count) { Set-SlotHold $dir "the last job left $($own -join '; ') in $repo; the slot is kept as it is" $u }
    $work = @(Get-KeptWork $repo $src $rec $null $null)
    if ($work.Count) {
      $dest = $null
      if ($u.attempt -and (Test-Path -LiteralPath $u.attempt -PathType Container)) { $dest = Join-Path (Join-Path $u.attempt "out_$($u.name)") 'slot_leftovers' }
      else { $dest = Join-Path $dir ('leftovers_' + [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')) }
      if (Test-Path -LiteralPath $dest) { $dest = $dest + '_' + [DateTime]::UtcNow.ToString('HHmmssfff') }
      try { Write-Output (Save-Leftovers $repo $work $dest) }
      catch { Set-SlotHold $dir "the last job's leftovers in $repo could not be saved ($($_.Exception.Message)); the slot is kept as it is" $u }
    }
    Invoke-WithPinnedMirror $pin { Run-Git -C $repo fetch -q --prune origin | Out-Null }
  } else {
    Invoke-WithPinnedMirror $pin { Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null }
    Run-Git -C $repo config gc.auto 0 | Out-Null
  }
  Run-Git -C $repo cat-file -e "$pin^{commit}" | Out-Null
  [IO.File]::WriteAllLines($last, [string[]]@("attempt $attempt", "name $name", "pin $pin", "at $([DateTime]::UtcNow.ToString('o'))"))
  Run-Git -C $repo -c core.autocrlf=false -c advice.detachedHead=false checkout -q -f --detach $pin | Out-Null
  Run-Git -C $repo clean -q -ffdx -e /godot/.godot/ -e '*.import' | Out-Null
  $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
  if ($head -ne $pin) { throw "slot repo $repo is at $head, not the pin $pin" }
  $changed = @(Run-Git -C $repo status --porcelain --untracked-files=no | Where-Object { $_ })
  if ($changed.Count) { throw "slot repo $repo still differs from the pin after the reset: $($changed[0])" }
  return $repo
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
    Invoke-WithPinnedMirror $C { Run-Git -c core.autocrlf=false clone --local -q --no-checkout $mirror $repo | Out-Null }
    Run-Git -C $repo -c core.autocrlf=false -c advice.detachedHead=false checkout -q --detach $C | Out-Null
    $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
    if ($head -ne $C) { throw "checkout $repo is at $head, not the pin $C" }
    [IO.File]::AppendAllText((Join-Path $attempt 'checkouts.txt'), "$B $C`r`n")
    Write-Output "checkout $B $C $repo"
  }
  'slot' {
    # Issue 1659: the warm-slot form of checkout (OJ_SLOTS=1 in the job bat). The first call of an attempt takes a slot;
    # every call resets that slot's repo to the pin. Writes <attempt>\slot_repo.txt (the repo path, for the bat) and
    # appends "<name> <pin> <repo>" to <attempt>\slots.txt. No checkouts.txt line: nothing per attempt to remove later.
    if ($C -notmatch '\A[0-9a-f]{40}\z') { throw "a pin must be a full 40-character commit, got: $C" }
    if ($B -notmatch '\A[A-Za-z0-9_-]{1,40}\z') { throw "checkout name not accepted: $B" }
    $attempt = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    if (-not $attempt.StartsWith($vt + $sep, [StringComparison]::OrdinalIgnoreCase)) { throw "attempt folder must be under $vt" }
    if (-not (Test-Path -LiteralPath $attempt -PathType Container)) { throw "no attempt folder $attempt" }
    $held = Get-HeldSlot $attempt
    if ($held) { Reset-Slot $held.Dir $attempt $B $C; $dir = $held.Dir }
    else {
      # A slot that turns out to need the Board's look (Reset-Slot sets hold.txt) is let go, and the next free one is
      # taken (Artoo on PR 1728). The job's own second checkout never moves: its slot holds its first arm's state.
      while ($true) {
        Enter-Slot $attempt
        $dir = (Get-HeldSlot $attempt).Dir
        try { Reset-Slot $dir $attempt $B $C; break }
        catch {
          if ($_.Exception.Message -notlike 'slot held:*') { throw }
          Write-Output $_.Exception.Message
          Exit-Slot $attempt
          [IO.File]::Delete((Join-Path $attempt 'slot.txt'))
        }
      }
    }
    $repo = Join-Path $dir 'repo'
    [IO.File]::WriteAllText((Join-Path $attempt 'slot_repo.txt'), "$repo`r`n")
    [IO.File]::AppendAllText((Join-Path $attempt 'slots.txt'), "$B $C $repo`r`n")
    Write-Output "slot checkout $B $C $repo"
  }
  'slothold' {
    # Internal (Start-SlotHolder): hold one slot's lease while the job's process lives, until slotrelease or 48 hours.
    $dir = $env:OJ_SLOT_DIR; $token = $env:OJ_SLOT_TOKEN
    $owner = [int]$env:OJ_SLOT_OWNER; $ownerStart = [long]$env:OJ_SLOT_OWNER_START
    $ready = Join-Path $dir "holder_$token.txt"; $release = Join-Path $dir "release_$token"
    $lease = $null
    try { $lease = [IO.File]::Open((Join-Path $dir '.slot-lease'), 'OpenOrCreate', 'ReadWrite', 'None') }
    catch { [IO.File]::WriteAllText($ready, "busy`r`n"); exit 1 }
    # Artoo on PR 1728: the lease alone is not the job. A holder can die while its job still copies ships or runs Godot in
    # the slot, so the slot stays the last job's until that job's own process has ended or its tail let the slot go.
    $prev = Join-Path $dir 'owner.txt'
    if (Test-Path -LiteralPath $prev -PathType Leaf) {
      $txt = [IO.File]::ReadAllText($prev)
      if ($txt -notmatch '(?m)^released' -and $txt -match '(?m)^job process ([0-9]+) ([0-9]+)\r?$' -and (Test-SameProcess ([int]$Matches[1]) ([long]$Matches[2]))) {
        $lease.Dispose(); [IO.File]::WriteAllText($ready, "busy: the last job's process $($Matches[1]) still runs`r`n"); exit 1
      }
    }
    $released = $false
    try {
      # markers of earlier holders are stale now that this one holds the lease
      foreach ($old in @(Get-ChildItem -LiteralPath $dir -Force -File | Where-Object { $_.Name -match '\A(holder|release)_[0-9a-f]{32}(\.txt|\.err)?\z' -and $_.Name -notlike "*$token*" })) { [IO.File]::Delete($old.FullName) }
      [IO.File]::WriteAllText((Join-Path $dir 'owner.txt'), "attempt $env:OJ_SLOT_ATTEMPT`r`ntoken $token`r`njob process $owner $ownerStart`r`nholder $PID`r`nsince $([DateTime]::UtcNow.ToString('o'))`r`n")
      [IO.File]::WriteAllText($ready, "held $PID $(Get-ProcStart $PID)`r`n")
      $end = [DateTime]::UtcNow.AddHours(48)
      while ([DateTime]::UtcNow -lt $end -and -not (Test-Path -LiteralPath $release) -and (Test-SameProcess $owner $ownerStart)) { Start-Sleep -Milliseconds 1000 }
      $released = Test-Path -LiteralPath $release
    } finally {
      # the tail's release frees the slot even while the job's cmd still runs its last lines
      if ($released -and [IO.File]::ReadAllText((Join-Path $dir 'owner.txt')) -notmatch '(?m)^released') { [IO.File]::AppendAllText((Join-Path $dir 'owner.txt'), "released $([DateTime]::UtcNow.ToString('o'))`r`n") }
      foreach ($f in @($ready, $release, (Join-Path $dir "holder_$token.err"))) { if (Test-Path -LiteralPath $f) { [IO.File]::Delete($f) } }
      $lease.Dispose()
    }
  }
  'slotrelease' {
    # The tail: lets this attempt's slot go (the holder ends) and waits up to 30 s for the lease to be free. The PC daemon
    # passes the lease it was given as OJ_SLOT_EXPECT (<slot>|<token>); a receipt that no longer matches keeps the slot.
    $expect = $env:OJ_SLOT_EXPECT; $env:OJ_SLOT_EXPECT = $null
    Exit-Slot ([IO.Path]::GetFullPath($A).TrimEnd('\', '/')) $expect
  }
  'slotcheck' {
    # Read only (issue 1662, the PC daemon): the live proof that this attempt still holds its slot (Test-SlotHeld: the
    # holder process with its start time, owner.txt naming the token, the lease file locked now). Prints
    # "held <slot>|<token>"; fails otherwise.
    $h = Get-HeldSlot ([IO.Path]::GetFullPath($A).TrimEnd('\', '/'))
    if (-not $h) { throw "no slot recorded for $A" }
    Write-Output "held $($h.Dir)|$($h.Token)"
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
      $srcText = [string]$e.src
      $srcOk = ($srcText -eq $stamp)
      if (-not $srcOk -and $srcText.StartsWith('{')) {
        # Since issue 1678 the game stamps each source file as [mtime, size, sha256] in JSON (build_assets.gd source_stamp),
        # glbs and their external maps. Check size and hash of every listed file, and that no glb is missing from the list.
        $why = ''
        try { $sj = $srcText | ConvertFrom-Json } catch { $sj = $null; $why = 'unreadable stamp' }
        if ($sj) {
          $names = @($sj.PSObject.Properties | ForEach-Object { $_.Name })
          foreach ($suf in '', '_damage', '_wreck') {
            $gn = "$code$suf.glb"
            if ((Test-Path -LiteralPath (Join-Path $dir $gn) -PathType Leaf) -and ($names -notcontains $gn)) { $why = "$gn not in the stamp" }
          }
          foreach ($sp in $sj.PSObject.Properties) {
            if ($why) { break }
            $sf = Join-Path $dir ($sp.Name.Replace('/', $sep)); $want = @($sp.Value)
            $there = Test-Path -LiteralPath $sf -PathType Leaf
            # [] = missing when cached; [mtime, size] (older stamps, glbs) = time and size as before; [mtime, size, sha256] adds the hash
            if ($want.Count -eq 0) { if ($there) { $why = "$($sp.Name) exists but was missing when cached" }; continue }
            if (-not $there) { $why = "$($sp.Name) missing"; continue }
            $fi = Get-Item -LiteralPath $sf
            if ($fi.Length -ne [long]$want[1]) { $why = "$($sp.Name) size differs"; continue }
            if ($want.Count -ge 3) {
              if ((Get-FileHash -LiteralPath $sf -Algorithm SHA256).Hash -ne [string]$want[2]) { $why = "$($sp.Name) hash differs" }
            } elseif (([DateTimeOffset]$fi.LastWriteTimeUtc).ToUnixTimeSeconds() -ne [long]$want[0]) { $why = "$($sp.Name) time differs" }
          }
        }
        if (-not $why) { $srcOk = $true; $stamp = 'json:' + (@($sj.PSObject.Properties | ForEach-Object { '{0}={1}' -f $_.Name, (@($_.Value) -join ',') }) -join ';') }
        else { $stamp = "json mismatch: $why" }
      }
      if (-not $hasRes) { $bad += "$code cached scene missing: $res" }
      elseif (-not $srcOk) { $bad += "$code cache was built from other files (stamp $srcText, copied files $stamp)" }
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
    $place = $null
    if ($B -like 'relay/*') {
      if ("$B $C" -notmatch ('\A' + $relayPattern + ' [A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*\z') -or "$B $C".Contains('..')) {
        Write-Output "checkouts kept: relay receipt not accepted: $B $C"; break
      }
      $place = @{ Ref = $B; Path = $C; From = 'the given relay place' }
    } elseif ($B) { try { Write-RelayReceipt $attempt $B $C } catch { Write-Output "checkouts kept: $($_.Exception.Message)"; break } }
    # This attempt only (review of PR 1644): earlier attempts of the job are cleared by their own relay waiter or the
    # janitor's relay sweep, which hold the job lease, the issue lock and the keep-list and process checks; an unguarded
    # sibling sweep here could race them.
    Drop-Attempt $attempt $place
    Write-Free $script:freed
  }
  'dropwait' {
    # Issue 1396 (Board, Nov 22): the PC relays an attempt only after its tail, so the tail's dropcheckouts finds no branch,
    # and with a new job name every night no later attempt of the same job clears it (20 checkouts of about 8 GB each in
    # one night). The tail starts this in a hidden window, with the attempt in OJ_DROPWAIT_ATTEMPT (not on its command
    # line, so the janitor's and its own process checks never see it as a user of the job folder). For a passed attempt
    # only, it asks origin (git ls-remote, prompts off, 120 s limit) for the attempt's relay branch every
    # OJ_DROPWAIT_POLL_SECONDS (300). When the branch is there it takes the job lease and the issue lock, runs the
    # janitor's checks (Get-WaitGuard), and runs dropcheckouts' own proof and drop for this attempt only (Drop-Attempt:
    # mirror lock, fresh relay proof, then any earlier unfinished removal, then each checkout, with the checks once more
    # before each rename). Any refusal is tried again: at once when the branch moves, else after a wait that doubles from
    # one poll to an hour. Nothing new starts after OJ_DROPWAIT_SECONDS (43200, 12 hours) and the mirror wait ends there
    # too; only a removal already under way finishes. The janitor's relay sweep covers anything later. dry: one look,
    # the dry proof, no lock, log, fetch or removal.
    $given = if ($A) { $A } else { "$env:OJ_DROPWAIT_ATTEMPT" }
    if (-not $given) { throw 'dropwait needs the attempt folder (argument or OJ_DROPWAIT_ATTEMPT)' }
    $attempt = [IO.Path]::GetFullPath($given).TrimEnd('\', '/')
    $problem = Get-AttemptProblem $attempt
    if ($problem) { Write-Output "checkouts kept: $problem"; break }
    $script:dropDry = $B -eq 'dry'
    if ($B -and -not $script:dropDry) { throw "dropwait takes only dry after the attempt folder, got: $B" }
    $script:freed = [long]0
    $env:GIT_TERMINAL_PROMPT = '0'; $env:GCM_INTERACTIVE = 'never'
    $jobDir = Split-Path -Parent $attempt
    $leaf = Split-Path -Leaf $attempt
    if ($env:OJ_DROPWAIT_LOG -eq '1' -and -not $script:dropDry) {
      # The log sits beside the attempt, named from it; an existing link or folder there is never written through.
      $log = Join-Path $jobDir "dropwait_$leaf.txt"
      $logItem = Get-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
      if (-not $logItem -or (($logItem -is [IO.FileInfo]) -and -not ($logItem.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
        try { $null = Start-Transcript -LiteralPath $log -Append } catch { }
      }
    }
    if ((Get-AttemptState $attempt) -ne 'PASS') { Write-Output "checkouts kept: $attempt is not a passed attempt; nothing to wait for"; break }
    $place = Get-RelayPlace $attempt (Split-Path -Leaf $jobDir) $leaf
    if (-not $place) { Write-Output "checkouts kept: no relay branch named for $attempt"; break }
    $issueLockPath = ''
    if ((Split-Path -Leaf $jobDir) -match '\Aopus([1-9][0-9]*)') {
      $runTemp = if ($env:PC_RUN_TEMP) { $env:PC_RUN_TEMP } else { [IO.Path]::GetTempPath() }
      $issueLockPath = Join-Path $runTemp "voidsworn-runner-issue-$($Matches[1]).lock"
    }
    $poll = 300; if ("$env:OJ_DROPWAIT_POLL_SECONDS" -match '\A[1-9][0-9]{0,4}\z') { $poll = [int]$env:OJ_DROPWAIT_POLL_SECONDS }
    $limit = 43200; if ("$env:OJ_DROPWAIT_SECONDS" -match '\A[0-9]{1,6}\z') { $limit = [int]$env:OJ_DROPWAIT_SECONDS }
    $script:waitUntil = [DateTime]::UtcNow.AddSeconds($limit)
    Write-Output "waiting for $($place.Ref) on origin (from $($place.From)) to clear $attempt; every $poll s for up to $limit s"
    $seen = ''; $nextTry = [DateTime]::MinValue; $backoff = $poll
    $script:beforeRemove = {
      $w = Get-WaitGuard $attempt
      if ($w) { throw "held back: $w" }
    }
    while ($true) {
      if (-not @(Get-ListedLeft $attempt).Count) { Write-Output "no listed checkout left in $attempt"; break }
      $left = ($script:waitUntil - [DateTime]::UtcNow).TotalSeconds
      if ($left -le 0) { Write-Output "checkouts kept: $attempt still lists checkouts after $limit s; the janitor's relay sweep handles it later"; break }
      $tip = ''
      try { $tip = Invoke-LsRemote $place.Ref ([Math]::Min(120, [Math]::Ceiling($left))) }
      catch { Write-Output "relay check failed, tried again later: $($_.Exception.Message)" }
      if ($tip -and ($tip -ne $seen -or [DateTime]::UtcNow -ge $nextTry)) {
        if ($tip -ne $seen) { Write-Output "relay branch $($place.Ref) is on origin at $tip"; $backoff = $poll }
        $seen = $tip
        $lease = $null; $issueLock = $null; $why = ''
        if (-not $script:dropDry) {
          try { $lease = Open-PlainLock (Join-Path $jobDir '.voidsworn-run-active') } catch { $why = "the job folder's lease is held or not a plain file" }
          if (-not $why -and $issueLockPath) {
            try { $issueLock = Open-PlainLock $issueLockPath } catch { $why = "the issue lock $issueLockPath is held or not a plain file" }
          }
        }
        # Checked after the locks are held, so nothing new can claim the folder between the check and the drop.
        if (-not $why) { $why = Get-WaitGuard $attempt }
        try {
          if ($why) { Write-Output "checkouts kept for now: $attempt ($why); tried again at the next look" }
          else { Drop-Attempt $attempt }
        } finally { if ($issueLock) { $issueLock.Dispose() }; if ($lease) { $lease.Dispose() } }
        if ($why) { $nextTry = [DateTime]::MinValue }
        elseif (@(Get-ListedLeft $attempt).Count -and -not $script:dropDry) {
          $nextTry = [DateTime]::UtcNow.AddSeconds($backoff)
          Write-Output "checkouts kept: tried again on this relay in $backoff s, or at once if the branch moves"
          $backoff = [Math]::Min(3600, $backoff * 2)
        }
      }
      if ($script:dropDry) { if (-not $tip) { Write-Output "checkouts kept: $($place.Ref) is not on origin yet (dry: one look)" }; break }
      $left = ($script:waitUntil - [DateTime]::UtcNow).TotalSeconds
      if ($left -le 0) { continue }
      Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($poll, [Math]::Ceiling($left))))
    }
    if (-not $script:dropDry) { Write-Free $script:freed }
  }
  'dropjobs' {
    # Issue 1396 (Board, Nov 22): the relay always lands after a job's tail, and no session runs dropcheckouts by hand, so
    # the janitor calls this hourly and after jobs. Every PASS attempt <job>\out_* that still lists a
    # checkout gets the same proof as dropcheckouts (origin's relay branch holds every out file byte for byte); anything
    # else is logged as kept. dry (a janitor dry run) removes nothing, finishes no earlier removal and fetches nothing.
    # One job folder per call (A): the janitor takes that folder's lease, issue lock, keep list and process checks
    # first and holds them through this call (Artoo on PR 1592), so this never sweeps folders it was not handed.
    $script:dropDry = $B -eq 'dry'
    if ($B -and -not $script:dropDry) { throw "dropjobs takes only dry after the job folder, got: $B" }
    $script:freed = [long]0
    $one = Get-Item -LiteralPath ([IO.Path]::GetFullPath($A).TrimEnd('\', '/')) -Force -ErrorAction SilentlyContinue
    if (-not $A -or -not (Test-PlainDir $one) -or $one.Name -notmatch '\A[A-Za-z0-9_-]+\z' -or
        -not (Split-Path -Parent $one.FullName).Equals($vt, [StringComparison]::OrdinalIgnoreCase)) { throw "dropjobs needs a job folder voidsworn_test\<job>, got: $A" }
    foreach ($job in @($one)) {
      foreach ($att in @($job.EnumerateDirectories('out_*'))) {
        if (-not (Test-PlainDir $att) -or (Get-AttemptState $att.FullName) -ne 'PASS') { continue }
        $list = Join-Path $att.FullName 'checkouts.txt'
        if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { continue }
        $left = @(Get-ListedLeft $att.FullName)
        if (-not $left.Count) { continue }
        $problem = Get-AttemptProblem $att.FullName
        if ($problem) { Write-Output "checkouts kept: $problem"; continue }
        Drop-Attempt $att.FullName
      }
    }
    if (-not $script:dropDry) { Write-Free $script:freed }
  }
  'relayfind' {
    # Issue 1695 (Board, Nov 22): attempts relayed before PR 1644 under another branch name or folder (board/pc-out-1547c
    # and so on) name no place the proof finds, so their checkouts never clear. For each passed attempt that still lists
    # a checkout and whose own place (Get-RelayPlace) does not prove, with no relay_receipt.txt or relay_branch.txt of its
    # own, this looks through every board/pc-out-* branch in the shared mirror for the folder holding one of its result
    # files, then runs the same byte check as the drop (Test-PlaceProof: every result file at that folder with the same
    # blob, or a listed skip). Only a place that proves is written, as the attempt's relay_found.txt
    # (a new file, never over an existing one; issue 1739: a relay_branch.txt from init does not stop the search). It is only a place to look: the waiter and the janitor's relay sweep prove
    # the bytes again under the mirror lock before any removal. Writes nothing else and removes nothing. <attempt> or all
    # (every voidsworn_test\<job>\out_*); dry writes nothing and fetches nothing; live fetches the mirror once first.
    $live = $B -ne 'dry'
    if ($B -and $live) { throw "relayfind takes only dry after the attempt folder or all, got: $B" }
    if (-not $A) { throw 'relayfind needs an attempt folder voidsworn_test\<job>\out_* or all' }
    $sweep = $A -eq 'all'
    $atts = if ($sweep) {
      @(foreach ($j in @((Get-Item -LiteralPath $vt -Force).EnumerateDirectories())) { if (Test-PlainDir $j) { foreach ($x in @($j.EnumerateDirectories('out_*'))) { $x.FullName } } })
    } else { @([IO.Path]::GetFullPath($A).TrimEnd('\', '/')) }
    $script:dropDry = $true
    if ($live) { Update-Mirror }
    $todo = @()
    foreach ($att in $atts) {
      $problem = Get-AttemptProblem $att
      if ($problem) { Write-Output "relay place not looked for: $problem"; continue }
      if ((Get-AttemptState $att) -ne 'PASS') { if (-not $sweep) { Write-Output "relay place not looked for: $att is not a passed attempt" }; continue }
      if (-not (Test-Path -LiteralPath (Join-Path $att 'checkouts.txt') -PathType Leaf) -or -not @(Get-ListedLeft $att).Count) {
        if (-not $sweep) { Write-Output "relay place not looked for: no listed checkout left in $att" }; continue
      }
      $job = Split-Path -Leaf (Split-Path -Parent $att); $leaf = Split-Path -Leaf $att
      $outs = @((Get-Item -LiteralPath $att -Force).EnumerateDirectories('out_*') | ForEach-Object { $_.FullName })
      $place = Get-RelayPlace $att $job $leaf
      $why = if ($place) { Test-PlaceProof $place $att $outs @('checkout_leftovers') } else { 'no place named' }
      if (-not $why) { Write-Output "relay place already proven: $att ($($place.Ref) $($place.Path), from $($place.From))"; continue }
      $own = @(foreach ($n in 'relay_receipt.txt', 'relay_found.txt') { if (Test-Path -LiteralPath (Join-Path $att $n)) { $n } })
      if ($own.Count) { Write-Output "relay place left alone: $att has its own $($own[0]), which does not prove ($why)"; continue }
      try { $got = Get-ResultWant $att $outs @('checkout_leftovers') } catch { Write-Output "relay place not looked for: $att ($($_.Exception.Message))"; continue }
      if (-not $got.Want.Count) { Write-Output "relay place not looked for: no result files under $att"; continue }
      # One result file of 10 MB or less to search for (a larger one may be left off the relay).
      $anchor = @($got.Want.Keys | Sort-Object | Where-Object { (Get-Item -LiteralPath $got.Files[$_] -Force).Length -le 10000000 } | Select-Object -First 1)
      if (-not $anchor.Count) { Write-Output "relay place not looked for: every result file under $att is over 10 MB"; continue }
      $todo += @{ Attempt = $att; Outs = $outs; Got = $got; Anchor = $anchor[0]; Blob = $got.Want[$anchor[0]]; Why = $why }
    }
    if (-not $todo.Count) { Write-Output 'relay places to look for: none'; break }
    # One pass over the relay branches in the shared mirror: every path that holds one of the searched blobs.
    $blobs = @{}; foreach ($t in $todo) { $blobs[$t.Blob] = @() }
    $refs = @(Run-Git --git-dir $mirror for-each-ref '--format=%(refname:strip=2)' refs/heads/board/ | Where-Object { "$_" -match '\Aboard/pc-out-[A-Za-z0-9._-]+\z' })
    Write-Output "looking through $($refs.Count) relay branch(es) for $($todo.Count) attempt(s)"
    foreach ($ref in $refs) {
      foreach ($l in @(Run-Git --git-dir $mirror -c core.quotepath=false ls-tree -r "refs/heads/$ref")) {
        if ("$l" -match '\A\d+ blob ([0-9a-f]{40})\t(.+)\z' -and $blobs.ContainsKey($Matches[1])) { $blobs[$Matches[1]] += , @{ Ref = $ref; Path = $Matches[2] } }
      }
    }
    foreach ($t in $todo) {
      $att = $t.Attempt; $tail = '/' + $t.Anchor
      $cands = @(foreach ($h in $blobs[$t.Blob]) {
        if (-not $h.Path.EndsWith($tail, [StringComparison]::Ordinal)) { continue }
        $p = $h.Path.Substring(0, $h.Path.Length - $tail.Length)
        if ("$($h.Ref) $p" -notmatch '\Aboard/pc-out-[A-Za-z0-9._-]+ [A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*\z' -or $p.Contains('..')) { continue }
        @{ Ref = $h.Ref; Path = $p; From = 'the relay search' }
      })
      $found = $null; $near = ''
      foreach ($cand in $cands) {
        $w = Test-PlaceProof $cand $att $t.Outs @('checkout_leftovers') $t.Got
        if (-not $w) { $found = $cand; break }
        if (-not $near) { $near = "closest $($cand.Ref) $($cand.Path): $w" }
      }
      if (-not $found) {
        if (-not $near) { $near = "no relay branch holds $($t.Anchor) with its bytes" }
        Write-Output "relay place not found: $att (own place: $($t.Why); $near)"; continue
      }
      $line = "$($found.Ref) $($found.Path)"
      if (-not $live) { Write-Output "relay place would be written: $(Join-Path $att 'relay_found.txt') = $line ($($cands.Count) folder(s) hold $($t.Anchor))"; continue }
      try {
        $fs = [IO.File]::Open((Join-Path $att 'relay_found.txt'), 'CreateNew', 'Write', 'None')
        try { $bytes = [Text.Encoding]::ASCII.GetBytes("$line`r`n"); $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Dispose() }
        Write-Output "relay place written: $(Join-Path $att 'relay_found.txt') = $line"
      } catch { Write-Output "relay place not written: $att ($($_.Exception.Message))" }
    }
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
      $gone = Remove-Owned $cache -InPlace
      Write-Output ("import cache removed after the PASS ({0:N1} GB): {1}; the clone stays for the publish" -f ($gone / 1GB), $cache)
      Write-Free $gone
    } catch { Write-Output "import cache kept: $($_.Exception.Message)" }
  }
  'droprepo' {
    try {
      if ($B -notmatch '\A[0-9a-f]{40}\z') { throw "a commit must be a full 40-character commit, got: $B" }
      if ($C -notmatch '\A[A-Za-z0-9_]+\z') { throw "not a hull code: $C" }
      $jobDir = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
      if (Test-Path -LiteralPath (Join-Path $jobDir 'repo.removing')) {
        Assert-NoLinks $jobDir
        foreach ($o in @(Complete-Removing $jobDir @('repo'))) { if ($o -is [long]) { Write-Free $o } else { Write-Output $o } }
      }
      $repo = Test-ShipClone $jobDir
      $head = (Run-Git -C $repo rev-parse HEAD) | Select-Object -Last 1
      if ($head -ne $B) { throw "HEAD is $head, not the published commit $B" }
      $script:mirrorLock = Lock-Mirror; $script:relayLock = Lock-RelayMirror
      Assert-Rebuildable $repo
      $export = Join-Path (Join-Path (Join-Path (Join-Path $jobDir 'out') 'recipe') 'export') $C
      if (-not (Test-Path -LiteralPath $export -PathType Container)) { throw "no collected export $export" }
      Write-RelayReceipt (Join-Path $jobDir 'out') $D $Folder
      Assert-Relayed (Join-Path $jobDir 'out') @((Join-Path $jobDir 'out')) @('checkout_leftovers_repo') (Split-Path -Leaf $jobDir) "$(Split-Path -Leaf $jobDir)_out"
      $work = @(Get-KeptWork $repo $null @{} "godot/assets/ships/$C/" $export)
      if (Test-Paused) { throw 'the Board PC pause is active' }
      if ($work.Count) {
        $dest = Join-Path (Join-Path $jobDir 'out') 'checkout_leftovers_repo'
        try { Write-Output (Save-Leftovers $repo $work $dest) }
        catch { throw ("it holds {0} path(s) that are not rebuildable leftovers and could not be saved ({1}), e.g. {2}" -f $work.Count, $_.Exception.Message, (($work | Select-Object -First 5) -join '; ')) }
      }
      $gone = Remove-Owned $repo -Commit $B
      Write-Output ("ship clone removed after the publish ({0:N1} GB): {1}" -f ($gone / 1GB), $repo)
      Write-Free $gone
    } catch { Write-Output "ship clone kept: $($_.Exception.Message)" }
    finally {
      if ($script:relayLock) { $script:relayLock.Dispose(); $script:relayLock = $null }
      if ($script:mirrorLock) { $script:mirrorLock.Dispose(); $script:mirrorLock = $null } }
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
    Write-Output ("survey: {0:N1} GB in job checkouts and ship clones (what removal would free: hard links shared with the mirror or another checkout are not counted); nothing was removed" -f ($total / 1GB))
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
