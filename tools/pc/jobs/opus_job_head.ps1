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
#   hashes <out file>                          sha256 of Ryan's real battle_opts.json and board_look.cfg
#   dropcheckouts <attempt folder>             after a PASS (the tail never calls it after a failure): removes the job's own pinned checkouts, the
#                                              rebuildable leftovers RULEBOOK 3.3 / R326 let a job remove. Only folders
#                                              listed in <attempt>\checkouts.txt by this head's checkout step, directly in an
#                                              attempt folder voidsworn_test\<job>\out_*, that are plain folders whose
#                                              .git\HEAD still names the listed pin and whose files hold no work (Get-KeptWork:
#                                              no tracked change; every untracked or ignored file is the import cache, an
#                                              unchanged ships copy, a byte copy of a tracked file, or a sidecar of one of
#                                              those). Links are removed as links, never
#                                              followed. out_*, the logs and every other file stay. The Board's PC pause
#                                              (gpu_go.txt) removes nothing. A refusal is logged and never fails the job.
# Nothing else is deleted. Test settings (helper_clone's): PC_TEST_HELPER=1, PC_TEST_HELPER_VT, PC_TEST_SOURCE, PC_TEST_REALU.
param([Parameter(Mandatory)][ValidateSet('live', 'bundle', 'watchdog', 'checkout', 'tracked', 'shipcheck', 'hashes', 'dropcheckouts')][string]$Action,
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
function Get-KeptWork($repo, $src) {
  # Every tracked change (staged or not) and every untracked or ignored path that is not proven rebuildable:
  #  - godot/.godot/ (Godot's import cache and editor state);
  #  - a file under godot/gen/ or godot/assets/ships/ whose ships source copy ($src, the LB_SHIPS the ships step
  #    recorded) has the same size and modified time (what robocopy copied and left alone);
  #  - a byte copy of a file the pin tracks (the probe copies in godot/bench);
  #  - a .import or .uid sidecar whose own file is tracked or proven above.
  # Anything else, such as a new or changed ship file a job wrote, keeps the checkout (Artoo, PR 1326).
  $ErrorActionPreference = 'Continue'
  $raw = (& $gitExe -C $repo -c core.quotepath=false status --porcelain=v1 -z --untracked-files=all --ignored=traditional 2>$null) -join "`n"
  if ($LASTEXITCODE -ne 0) { return @('git status failed') }
  $keep = @(); $copies = @(); $sidecars = @(); $proven = @{}
  foreach ($e in ($raw -split "`0")) {
    if ($e.Length -lt 4) { continue }
    $code = $e.Substring(0, 2); $rel = $e.Substring(3)
    if ($code -ne '??' -and $code -ne '!!') { $keep += "changed: $rel"; continue }
    if ($rel.StartsWith('godot/.godot/', [StringComparison]::Ordinal)) { continue }
    if ($rel.EndsWith('/')) { $keep += "new: $rel"; continue }
    if ($rel.EndsWith('.import', [StringComparison]::Ordinal) -or $rel.EndsWith('.uid', [StringComparison]::Ordinal)) { $sidecars += $rel; continue }
    $from = $null
    foreach ($pre in 'gen/', 'assets/ships/') {
      if ($src -and $rel.StartsWith('godot/' + $pre, [StringComparison]::Ordinal)) { $from = Join-Path $src ($rel.Substring(6).Replace('/', $sep)) }
    }
    if ($from) {
      $mine = Get-Item -LiteralPath (Join-Path $repo $rel.Replace('/', $sep)) -Force -ErrorAction SilentlyContinue
      $theirs = Get-Item -LiteralPath $from -Force -ErrorAction SilentlyContinue
      if ($mine -is [IO.FileInfo] -and $theirs -is [IO.FileInfo] -and -not ($mine.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
          $mine.Length -eq $theirs.Length -and $mine.LastWriteTimeUtc -eq $theirs.LastWriteTimeUtc) { $proven[$rel] = $true; continue }
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
    $attempt = [IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    $item = Get-Item -LiteralPath $attempt -Force -ErrorAction SilentlyContinue
    $jobDir = Split-Path -Parent $attempt
    if ($item -isnot [IO.DirectoryInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $item.Name -notmatch '\Aout_[A-Za-z0-9_-]+\z' -or
        -not (Split-Path -Parent $jobDir).Equals($vt, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $jobDir) -notmatch '\A[A-Za-z0-9_-]+\z' -or
        ((Get-Item -LiteralPath $jobDir -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      Write-Output "checkouts kept: $attempt is not a job attempt folder voidsworn_test\<job>\out_*"; break
    }
    $src = $null
    $srcFile = Join-Path $attempt 'ships_source.txt'
    if (Test-Path -LiteralPath $srcFile -PathType Leaf) { $src = ([IO.File]::ReadAllText($srcFile)).Trim() }
    $list = Join-Path $attempt 'checkouts.txt'
    if (-not (Test-Path -LiteralPath $list -PathType Leaf)) { Write-Output "no checkouts listed in $attempt"; break }
    foreach ($line in [IO.File]::ReadAllLines($list)) {
      if ($line -notmatch '\A([A-Za-z0-9_-]{1,40}) ([0-9a-f]{40})\z') { if ($line.Trim()) { Write-Output "checkouts.txt line not accepted, ignored: $line" }; continue }
      $name = $Matches[1]; $pin = $Matches[2]
      $repo = Join-Path $attempt $name
      try {
        $r = Get-Item -LiteralPath $repo -Force -ErrorAction SilentlyContinue
        if ($null -eq $r) { Write-Output "checkout $name already gone: $repo"; continue }
        if ($r -isnot [IO.DirectoryInfo] -or ($r.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'not a plain folder' }
        $git = Get-Item -LiteralPath (Join-Path $repo '.git') -Force -ErrorAction SilentlyContinue
        if ($git -isnot [IO.DirectoryInfo] -or ($git.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'no .git folder of its own' }
        $headFile = Join-Path $git.FullName 'HEAD'
        if (-not (Test-Path -LiteralPath $headFile -PathType Leaf) -or ([IO.File]::ReadAllText($headFile)).Trim() -ne $pin) { throw "HEAD is no longer the pin $pin" }
        $work = @(Get-KeptWork $repo $src)
        if ($work.Count) { throw ("it holds {0} path(s) that are not rebuildable leftovers, e.g. {1}" -f $work.Count, (($work | Select-Object -First 5) -join '; ')) }
        if (Test-Paused) { throw 'the Board PC pause is active' }
        $freed = Remove-LinkSafeTree $repo
        Write-Output ("checkout {0} removed after the job ({1:N1} GB): {2}" -f $name, ($freed / 1GB), $repo)
      } catch { Write-Output "checkout $name kept: $repo ($($_.Exception.Message))" }
    }
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
