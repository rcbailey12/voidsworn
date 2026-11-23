# Shared PC runner steps (issue 687; issue 722 adds space, hashwrite, hashcheck and model). PowerShell 5.1.
# No model calls except preflight.
# init <out> <branch>; wait <out>; checkout <repo> <out> <branch> <sparse>;
# preflight <out> <repo> <opencode|kimi|codex> <exe> <model> <variant>;
# scratch <out>: create and record the run's private TEMP directory.
# finish <out> <exit> <partial> <push mode> <checks ok> [repo].
# space <out> <settings file> <target path>: refuse to start when the target's drive has less than min_free_gb
#   (default 60) free; one line in result.txt, status failed. Test knobs: PC_TEST_SETTINGS, PC_TEST_SPACE_FREE_MB.
# hashwrite <tools dir> <hash file>: the Board writes SHA-256 of the runner and watchdog files after copying them.
# hashcheck <out> <tools dir> <hash file> [strict]: warn in result.txt when the running copies differ. With strict
#   (issue 1194), a differing or missing watchdog, slot or step helper file (tmo.bat, run_timeout.ps1, gpu_slots.js,
#   job_wrap.bat) stops the job with exit 14. Test knob: PC_TEST_HASHES.
# preflight-tools <out> <list> (issue 1194): find each named tool (godot, blender, ffmpeg, node, pil) before a job clones
#   or claims the GPU. Writes <out>\preflight.txt and <out>\tools.cmd (set JW_GODOT=... lines); exit 2 on a missing tool.
# model <out> <resolved> <default>: stamp the resolved model into status.json and result.txt, and warn when it
#   differs from the arm default, whatever the provider.
# base <repo> <out> <issue body file>: parse the optional Base line, fetch and commit its merge before the agent.
# announce <out> <issue> <seat> <repo> <ceiling seconds> <resume command> <push mode> [assignment branch]: validate and claim.
# board-dryrun <out>: list ACCEPT or REFUSE for every open codex, muse or opus issue, without claims or agent calls.
# Test claims require PC_TEST_GH and PC_TEST_GH_DB; real dry runs validate read-only. Linux probes use pwsh and real git.
# Public runner diagnostics are built from fixed text. Keep exceptions, reports from interrupted agents,
# raw check details, and resume tails in the local run folder. Never interpolate an arbitrary log line.
function Public-RunnerText($status, $reason, $code, $folder) {
  switch ($status) {
    'running' { return 'claimed before checkout and model calls' }
    'checked_push' { return 'non-partial push confirmed and runner checks passed' }
    'unverified' { return 'dry/test push or checks did not pass; chain stays stopped' }
    'no_changes' { return 'no changes pushed' }
    'partial' {
      switch -Exact ($reason) {
        'CEILING' { return 'CEILING' }
        'usage limit' { return 'usage limit' }
        'spend accounting unknown' { return 'spend accounting unknown' }
        { $_ -in @('Codex left a merge unfinished', 'the agent left a merge unfinished') } { return 'the agent left a merge unfinished' }
      }
      if ($reason -cmatch '\ASTALLED after ([0-9]{1,6}(?:[.,][0-9]{1,6})?) min\z') { return "STALLED after $($Matches[1]) min" }
      if ($reason -match '\A(?:codex|agent) exit (-?[0-9]{1,10})\z') { return "agent exit $($Matches[1])" }
      return 'agent run interrupted; see the local run folder'
    }
    'checks' {
      $rows = @()
      foreach ($check in @(
        @{ name = 'standing checks'; log = 'checks_node.txt'; code = $env:NODE_EXIT },
        @{ name = 'parity'; log = 'checks_parity.txt'; code = $env:PARITY_EXIT }
      )) {
        $label = $check.name
        if (-not (Test-Path -LiteralPath (Join-Path $folder $check.log) -PathType Leaf)) { $rows += "SKIP: $label"; continue }
        if ($check.code -eq '0') { $rows += "PASS: $label" }
        elseif ($check.code -eq '124') { $rows += "FAIL: $label timed out" }
        elseif ($check.code -match '\A-?[0-9]{1,10}\z') { $rows += "FAIL: $label (exit $($check.code))" }
        else { $rows += "SKIP: $label (no exit recorded)" }
      }
      return ($rows -join "`n")
    }
    default {
      if ($code -match '\A-?[0-9]{1,10}\z') { return "runner exit $code; see the local run folder" }
      return 'runner failed; see the local run folder'
    }
  }
}
# Issue 1739: what a removal would really free (hard links, other accounts' folders). Optional, so a lone copy of this
# file (a test fixture, hashwrite) still runs; without it sizes count every listed byte, as before.
$diskSpaceHelpers = Join-Path $PSScriptRoot 'disk_space.ps1'
if (Test-Path -LiteralPath $diskSpaceHelpers) { . $diskSpaceHelpers }
if ($args[0] -eq 'publication-library') { return }
$ErrorActionPreference = 'Stop'
$mode = $args[0]
$utf8 = New-Object Text.UTF8Encoding($false)
$test = $env:PC_RUNNER_TEST -eq '1'
$scratchOwnerFile = '.voidsworn-run-owner'
$scratchFailedFile = '.voidsworn-run-failed'
$fixedBlockPattern = '(?im)^[ \t]*Owner:[^\r\n]*(?:\r?\n(?![ \t]*(?:\r?$|`{3,}|~{3,}))[^\r\n]+)*'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Put($path, $value) { [IO.File]::WriteAllText($path, [string]$value, $utf8) }
function Read($path) { if (Test-Path -LiteralPath $path) { return [IO.File]::ReadAllText($path).Trim() }; return '' }
# result.txt may be held open by the .bat that redirects a step's output into it (work_issue.ps1 commit runs under
# '>> result.txt' and calls 'fetch' here): then Write-Host alone reaches result.txt through that redirect. Never throw
# from Log: on Nov 15 the lock made the earlier-tip fetch report failure and stopped Kimi 371's push.
function Log($line) {
  try { Add-Content -LiteralPath (Join-Path $script:out 'result.txt') -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
  Write-Host $line
}
function State($status, $reason) {
  $p = Join-Path $script:out 'status.json'
  $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
  $s.status = $status; $s.reason = $reason
  $s.finished = if ($status -eq 'running') { '' } else { [DateTime]::UtcNow.ToString('o') }
  $s.commit = Read (Join-Path $script:out 'run_commit.txt')
  Save-State $s
}
function Save-State($s) {
  $p = Join-Path $script:out 'status.json'
  # Replace in place atomically so a waiter never sees half a JSON document.
  $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
  Put $tmp ($s | ConvertTo-Json)
  [IO.File]::Replace($tmp, $p, "$tmp.previous")
}
function Git([string[]]$words) {
  $ea = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  # 'git.exe', never 'git': PowerShell finds this Git function before the program, so 'git' called itself until the
  # call depth overflowed (first live run, Nov 15). The test stub path never hit it.
  $exe = 'git.exe'; if ($PSVersionTable.Platform -eq 'Unix') { $exe = @(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source }
  if ($test -and $env:PC_TEST_GIT) { $exe = $env:PC_TEST_GIT }
  $lines = @(& $exe @words 2>&1); $script:gitExit = $LASTEXITCODE
  $ErrorActionPreference = $ea
  # Writing the log must never fail the job (Nov 16: four starts died when another process briefly held git_log.txt,
  # 'The process cannot access the file because it is being used by another process'). One append, retried, never thrown.
  $text = (@($lines | ForEach-Object { [string]$_ }) -join "`r`n")
  if ($script:out -and $text) {
    $gl = Join-Path $script:out 'git_log.txt'
    for ($t = 0; $t -lt 40; $t++) { try { [IO.File]::AppendAllText($gl, $text + "`r`n", $utf8); break } catch { Start-Sleep -Milliseconds 500 } }
  }
  return @($lines | ForEach-Object { [string]$_ })
}
function Read-CleanupGit([string[]]$words) {
  # Status must neither refresh the index nor start a filesystem monitor in the checkout.
  Git (@('--no-optional-locks','-c','core.fsmonitor=false') + $words)
}
function Must-Git([string[]]$words) {
  $null = Git $words
  if ($script:gitExit -ne 0) { throw "git $($words[0]) failed (exit $script:gitExit); see git_log.txt" }
}
function Retry-Git($label, [string[]]$words) {
  $delay = 120
  if ($test -and $env:PC_TEST_RETRY_SECONDS) { $delay = [int]$env:PC_TEST_RETRY_SECONDS }
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    Log "$label attempt $attempt/3"
    $null = Git $words
    if ($script:gitExit -eq 0) { return }
    if ($attempt -lt 3) { Log "$label failed (exit $script:gitExit); retry in $delay seconds"; Start-Sleep -Seconds $delay }
  }
  throw "$label failed after 3 attempts; see git_log.txt"
}
# Restart Manager can name file holders without installing handle.exe. It cannot report directory-only handles,
# and access may be denied in a sandbox; diagnostics must never prevent the preservation retry.
function Get-RepoHolders($full) {
  try {
    if (-not ('RunnerFileHolders' -as [type])) {
      Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
public static class RunnerFileHolders {
  [StructLayout(LayoutKind.Sequential)] public struct UniqueProcess {
    public uint id; public System.Runtime.InteropServices.ComTypes.FILETIME started;
  }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct Info {
    public UniqueProcess process;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string name;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)] public string service;
    public uint type, status, session;
    [MarshalAs(UnmanagedType.Bool)] public bool restartable;
  }
  [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)] static extern int RmStartSession(out uint session, uint flags, StringBuilder key);
  [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)] static extern int RmRegisterResources(uint session, uint files, string[] names, uint apps, IntPtr processes, uint services, IntPtr serviceNames);
  [DllImport("rstrtmgr.dll")] static extern int RmGetList(uint session, out uint needed, ref uint count, [In, Out] Info[] info, ref uint reasons);
  [DllImport("rstrtmgr.dll")] static extern int RmEndSession(uint session);
  public static Info[] Find(string[] paths) {
    uint session; int error = RmStartSession(out session, 0, new StringBuilder(33));
    if (error != 0) throw new Win32Exception(error);
    try {
      error = RmRegisterResources(session, (uint)paths.Length, paths, 0, IntPtr.Zero, 0, IntPtr.Zero);
      if (error != 0) throw new Win32Exception(error);
      uint needed, count = 0, reasons = 0;
      var info = new Info[0];
      for (int attempt = 0; attempt < 4; attempt++) {
        error = RmGetList(session, out needed, ref count, info, ref reasons);
        if (error == 0) { Array.Resize(ref info, (int)count); return info; }
        if (error != 234) throw new Win32Exception(error);
        count = needed; info = new Info[count];
      }
      throw new Win32Exception(error);
    } finally { RmEndSession(session); }
  }
}
'@
    }
    # Register files, not the directory: RmGetList rejects directories with ERROR_ACCESS_DENIED.
    $files = @(Get-ChildItem -LiteralPath $full -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $gitDir = Join-Path $full '.git'
    if (Test-Path -LiteralPath $gitDir -PathType Container) {
      $files += @(Get-ChildItem -LiteralPath $gitDir -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    $holders = @(); if ($files.Count) { $holders = @([RunnerFileHolders]::Find([string[]]$files)) }
    foreach ($holder in $holders) { Log "Windows file holder: PID $($holder.process.id) $($holder.name)" }
  } catch { Log "Windows file holder lookup unavailable: $($_.Exception.Message)" }
  try {
    # Command lines are useful for an agent holding only its current directory. These are candidates, not proof.
    $candidates = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine.IndexOf($full, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    foreach ($holder in $candidates) { Log "possible checkout holder: PID $($holder.ProcessId) $($holder.Name): $($holder.CommandLine)" }
    if (-not $holders.Count -and -not $candidates.Count) { Log 'Windows could not name the checkout holder (directory handles may not be reported)' }
  } catch { Log "Windows holder lookup unavailable: $($_.Exception.Message)" }
}
function Keep-Repo($repo, $tag) {
  if (-not (Test-Path -LiteralPath $repo)) { return }
  $full = [IO.Path]::GetFullPath($repo).TrimEnd('\')
  if ([IO.Path]::GetFileName($full) -ne 'repo') { throw "refusing to rename unexpected checkout path $full" }
  $name = "repo-$tag-$([guid]::NewGuid().ToString('N'))"
  $limit = 600.0; $pause = 1000
  if ($test -and $env:PC_TEST_KEEP_SECONDS) { $limit = [double]$env:PC_TEST_KEEP_SECONDS }
  if ($test -and $env:PC_TEST_KEEP_POLL_MS) { $pause = [int]$env:PC_TEST_KEEP_POLL_MS }
  $clock = [Diagnostics.Stopwatch]::StartNew(); $nextLog = 0.0
  while ($true) {
    try { Rename-Item -LiteralPath $full -NewName $name -ErrorAction Stop; break }
    catch {
      $failure = $_.Exception.Message
      if ($clock.Elapsed.TotalSeconds -ge $nextLog) {
        Log "checkout rename held; waiting up to $limit seconds: $full : $failure"
        Get-RepoHolders $full
        $nextLog = $clock.Elapsed.TotalSeconds + 60
      }
      $left = $limit - $clock.Elapsed.TotalSeconds
      if ($left -le 0) { throw "checkout rename still held after $limit seconds; earlier checkout kept at ${full}: $failure" }
      Start-Sleep -Milliseconds ([int][Math]::Min($pause, [Math]::Ceiling($left * 1000)))
    }
  }
  if ($tag -eq 'kept') {
    try {
      # Renaming a checkout can preserve its old timestamp. Date the kept copy at preservation time.
      $kept = Get-Item -LiteralPath (Join-Path (Split-Path -Parent $full) $name) -Force
      if (-not ($kept.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $kept.LastWriteTimeUtc = [DateTime]::UtcNow }
    } catch { Log "WARNING: could not date kept checkout ${name}: $($_.Exception.Message)" }
  }
  Log "earlier checkout kept beside repo as $name"
}
function Warn-KeptRepos($repo) {
  $board = Split-Path -Parent ([IO.Path]::GetFullPath($repo))
  try { $copies = @(Get-ChildItem -LiteralPath $board -Directory -Force | Where-Object { $_.Name -like 'repo-kept-*' }) }
  catch { Log "WARNING: kept checkout sizes unavailable in ${board}: $($_.Exception.Message)"; return }
  if ($copies.Count -le 2) { return }
  Log "WARNING: $board has $($copies.Count) repo-kept-* copies; left in place during checkout"
  foreach ($copy in $copies) {
    try {
      if ($copy.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'linked checkout; total unavailable' }
      $bytes = 0L; $pending = New-Object 'Collections.Generic.Stack[string]'; $pending.Push($copy.FullName)
      while ($pending.Count) {
        foreach ($item in (Get-ChildItem -LiteralPath $pending.Pop() -Force -ErrorAction Stop)) {
          if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'size excludes a linked path; total unavailable' }
          if ($item.PSIsContainer) { $pending.Push($item.FullName) } else { $bytes += $item.Length }
        }
      }
      Log "WARNING: kept checkout $($copy.FullName): $bytes logical bytes ($([Math]::Round($bytes / 1GB, 3)) GiB)"
    } catch { Log "WARNING: kept checkout $($copy.FullName): size unavailable ($($_.Exception.Message))" }
  }
}
function Get-BuildShipLatest($build, $code) {
  # Newest file time in the shared build's folder for one ship code, or $null when the build has no such ship.
  if (-not $script:buildShipLatest) { $script:buildShipLatest = @{} }
  if ($script:buildShipLatest.ContainsKey($code)) { return $script:buildShipLatest[$code] }
  $latest = $null
  $dir = Get-Item -LiteralPath (Join-Path $build "godot/assets/ships/$code") -Force -ErrorAction SilentlyContinue
  if ($dir -is [IO.DirectoryInfo] -and -not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    try {
      foreach ($file in $dir.EnumerateFiles('*', [IO.SearchOption]::AllDirectories)) {
        if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { $latest = $null; break }
        if (-not $latest -or $file.LastWriteTimeUtc -gt $latest) { $latest = $file.LastWriteTimeUtc }
      }
    } catch { $latest = $null }
  }
  $script:buildShipLatest[$code] = $latest
  return $latest
}
function Test-SharedBuildCopy($repo, $path, $allowSuperseded = $false) {
  # Use the same default shared build as get_ship_files.bat.
  $build = Join-Path $env:USERPROFILE 'Downloads/voidsworn_test/build'
  $local = Get-Item -LiteralPath (Join-Path $repo $path) -Force -ErrorAction SilentlyContinue
  $shared = Get-Item -LiteralPath (Join-Path $build $path) -Force -ErrorAction SilentlyContinue
  if (-not $shared -and $allowSuperseded -and $path -match '\Agodot/assets/ships/([A-Za-z0-9_][A-Za-z0-9_-]*)/' -and
      $local -is [IO.FileInfo] -and -not ($local.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    # Issue 1180 run 8 (Board, Nov 20): a ship file with no build twin (an old damage glb) is a candidate when the build
    # holds the same ship code installed later. Like any superseded file it is archived and read back before removal.
    $code = $Matches[1]
    $root = [IO.Path]::GetFullPath($repo).TrimEnd('\','/')
    for ($dir = $local.Directory; $dir -and $dir.FullName -ne $root; $dir = $dir.Parent) {
      if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $false }
    }
    $installed = Get-BuildShipLatest $build $code
    $floor = [DateTime]::new(2000, 1, 1, 0, 0, 0, [DateTimeKind]::Utc); $ceiling = [DateTime]::UtcNow.AddMinutes(5)
    $copyTime = $local.LastWriteTimeUtc
    $detail = "copy $($copyTime.ToString('o')), $($local.Length) bytes; no build twin; ship $code installed $(if ($installed) { $installed.ToString('o') } else { 'never' })"
    if (-not $installed) { return $false }
    if ($copyTime -lt $floor -or $copyTime -gt $ceiling -or $installed -gt $ceiling) { Log "shared copy time not trusted, kept: $path ($detail)"; return $false }
    if ($copyTime -ge $installed) { Log "copy is not older than the shared build, kept: $path ($detail)"; return $false }
    Log "superseded by the shared build: $path ($detail)"
    $script:cleanupSuperseded += ,$path
    return $true
  }
  if (-not $shared -and $allowSuperseded -and $path -match '\Agodot/gen/' -and
      $local -is [IO.FileInfo] -and -not ($local.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    # Issue 1180 (Board, Nov 20, R8 dry run 2): a generated file with no build twin (an old gen/damage scene) is a
    # candidate when the build's gen was regenerated later: gen/manifest.json is written on every regeneration, so a
    # file the newer gen no longer has is superseded. Archived and read back before removal, like every superseded file.
    $root = [IO.Path]::GetFullPath($repo).TrimEnd('\','/')
    for ($dir = $local.Directory; $dir -and $dir.FullName -ne $root; $dir = $dir.Parent) {
      if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $false }
    }
    $manifest = Get-Item -LiteralPath (Join-Path $build 'godot/gen/manifest.json') -Force -ErrorAction SilentlyContinue
    if ($manifest -isnot [IO.FileInfo] -or ($manifest.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
    $floor = [DateTime]::new(2000, 1, 1, 0, 0, 0, [DateTimeKind]::Utc); $ceiling = [DateTime]::UtcNow.AddMinutes(5)
    $copyTime = $local.LastWriteTimeUtc; $genTime = $manifest.LastWriteTimeUtc
    $detail = "copy $($copyTime.ToString('o')), $($local.Length) bytes; no build twin; build gen regenerated $($genTime.ToString('o'))"
    if ($copyTime -lt $floor -or $copyTime -gt $ceiling -or $genTime -lt $floor -or $genTime -gt $ceiling) { Log "shared copy time not trusted, kept: $path ($detail)"; return $false }
    if ($copyTime -ge $genTime) { Log "copy is not older than the shared build, kept: $path ($detail)"; return $false }
    Log "superseded by the shared build: $path ($detail)"
    $script:cleanupSuperseded += ,$path
    return $true
  }
  foreach ($file in @($local, $shared)) {
    if ($file -isnot [IO.FileInfo] -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
  }
  # Git can list the contents of a junction as ignored files. Keep checkouts that contain a linked ship directory.
  $root = [IO.Path]::GetFullPath($repo).TrimEnd('\','/')
  for ($dir = $local.Directory; $dir -and $dir.FullName -ne $root; $dir = $dir.Parent) {
    if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $false }
  }
  if ($local.Length -eq $shared.Length -and (Get-FileHash -LiteralPath $local.FullName -Algorithm SHA256).Hash -eq
      (Get-FileHash -LiteralPath $shared.FullName -Algorithm SHA256).Hash) { return $true }
  if (-not $allowSuperseded) { return $false }
  # Removal only, never reuse (issue 1180 run 7, Board Nov 20): a differing copy is superseded when the shared build holds
  # the same file written strictly later. Robocopy and checkout can reset times, so a missing (before 2000) or future time
  # keeps the copy, and every call logs both times and sizes.
  $copyTime = $local.LastWriteTimeUtc; $buildTime = $shared.LastWriteTimeUtc
  $floor = [DateTime]::new(2000, 1, 1, 0, 0, 0, [DateTimeKind]::Utc); $ceiling = [DateTime]::UtcNow.AddMinutes(5)
  $detail = "copy $($copyTime.ToString('o')), $($local.Length) bytes; build $($buildTime.ToString('o')), $($shared.Length) bytes"
  if ($copyTime -lt $floor -or $copyTime -gt $ceiling -or $buildTime -lt $floor -or $buildTime -gt $ceiling) {
    Log "shared copy time not trusted, kept: $path ($detail)"; return $false
  }
  if ($copyTime -ge $buildTime) { Log "copy is not older than the shared build, kept: $path ($detail)"; return $false }
  Log "superseded by the shared build: $path ($detail)"
  # Times only nominate a candidate (Artoo, PR 1260): the caller archives these bytes and reads them back before removal.
  $script:cleanupSuperseded += ,$path
  return $true
}
function Get-RepoCleanupStatus($repo) {
  $status = @(Read-CleanupGit @('-C',$repo,'-c','core.quotePath=false','status','--porcelain=v1','--untracked-files=all','--ignored','--ignore-submodules=none'))
  if ($gitExit -ne 0) {
    $detail = $status | Select-Object -First 1
    throw "working tree status not verified (Git exit ${gitExit}: $detail)"
  }
  return $status
}
function Reuse-Caches($repo, $status = @(Get-RepoCleanupStatus $repo), $allowWork = $false, $forRemoval = $false) {
  foreach ($line in $status) {
    # These installer leftovers can be untracked or ignored, depending on the checkout's ignore rules.
    if ($line -match '^(?:!!|\?\?) ("?)(godot/(?:\.stage7-replaced-[^/"\\:\r\n]+|assets/ships/manifest\.bak_[^/"\\:\r\n]+)/[^"\\:\r\n]+)(?<!/)\1$' -and
        (Test-Path -LiteralPath (Join-Path $repo $Matches[2]) -PathType Leaf)) {
      $Matches[2]
      continue
    }
    # All of gen must match the build, even files with a generally rebuildable extension.
    $inGen = $line -match '^!! "?godot/gen/'
    # Match ignored files only. A nested repository can show up as an ignored directory with a trailing slash.
    if (-not $inGen -and $line -match '^!! (godot/(?:\.godot/[^"\\:\r\n]+|[^"\\:\r\n]+\.import)|(?:[^"\\:\r\n]*/)?__pycache__/[^"\\:\r\n]+|[^"\\:\r\n]+\.pyc)(?<!/)$') {
      $Matches[1]
      continue
    }
    # parity_campaign.bat writes the campaign golden JSONL files and the parity log.
    if (-not $inGen -and $line -match '^!! ("?)(godot/(?:[^"\\:\r\n]+\.uid|(?:campaign|rules)/test/out/[^"\\:\r\n]+|campaign/test/(?:golden/[^/"\\:\r\n]+\.jsonl|parity_campaign_log\.txt)|rules/test/(?:golden/[^"\\:\r\n]+|parity_log\.txt))|\.onboarding_checks/[^"\\:\r\n]+)(?<!/)\1$') {
      $Matches[2]
      continue
    }
    if ($line -match '^!! ("?)(godot/(?:gen|assets/ships)/[^"\\:\r\n]+)(?<!/)\1$') {
      $path = $Matches[2]
      if (-not (Test-SharedBuildCopy $repo $path $forRemoval)) {
        $kind = if ($inGen) { 'generated' } else { 'ship' }
        throw "working tree needs keeping: $line (shared $kind copy could not be verified)"
      }
      $path
      continue
    }
    if ($allowWork -and -not $line.StartsWith('!! ')) { continue }
    throw "working tree needs keeping: $line"
  }
}
# Issue 1186: code-only lanes leave out the big picture folders unless the issue's Brief or Deliver to line names a path
# inside one. The profile is '/*' then '!/<dir>/' for each left-out folder, in this order, so the runner can recognise it.
$codeCheckoutDirs = @('docs/shots','docs/ship_pipeline/build_sheets','contrib/muse/design','hulls_hi','rocks_hi')
function Code-CheckoutExclusions($body) {
  $fields = [regex]::Matches($body, '(?im)^[ \t]*(?:Brief|Deliver to):([^\r\n]*)') |
    ForEach-Object { $_.Groups[1].Value.Replace('\', '/') }
  foreach ($dir in $codeCheckoutDirs) {
    $path = [regex]::Escape($dir)
    if (-not ($fields -match "(?i)(?<![\w./-])(?:\./)?$path(?=/|[^\w.-]|$)")) { $dir }
  }
}
function Code-CheckoutPatterns($excluded) {
  if (-not @($excluded).Count) { return @() }
  return @('/*') + @($excluded | ForEach-Object { "!/$_/" })
}
function Get-ManagedSparseExclusions($repo) {
  # Returns the left-out folders of a runner-managed sparse profile, nothing for a full checkout, and throws otherwise.
  $oldSparse = @(Read-CleanupGit @('-C',$repo,'config','--bool','core.sparseCheckout'))
  if ($gitExit -notin @(0,1)) { throw 'sparse checkout setting not verified' }
  if (-not ($oldSparse -contains 'true')) { return @() }
  $cone = @(Read-CleanupGit @('-C',$repo,'config','--bool','core.sparseCheckoutCone'))
  if ($gitExit -ne 0 -or $cone.Count -ne 1 -or $cone[0] -ne 'false') { throw 'sparse checkout profile is not runner-managed' }
  $patternFile = Get-Item -LiteralPath (Join-Path $repo '.git/info/sparse-checkout') -Force -ErrorAction SilentlyContinue
  if (-not $patternFile -or $patternFile -isnot [IO.FileInfo] -or ($patternFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'sparse checkout patterns are missing or linked'
  }
  $lines = @([IO.File]::ReadAllLines($patternFile.FullName) | Where-Object { $_ -ne '' })
  $excluded = @($codeCheckoutDirs | Where-Object { $lines -ccontains "!/$_/" })
  if (-not $excluded.Count -or (($lines -join "`n") -cne ((Code-CheckoutPatterns $excluded) -join "`n"))) {
    throw 'sparse checkout profile is not runner-managed'
  }
  return $excluded
}
function Assert-NoHiddenSparseEdits($repo, $excluded, $flags) {
  # Skip-worktree entries hide edits from git status. Allow them only inside the left-out folders, and only while no
  # such file is on disk: a file that is there could hold an edit that status cannot see.
  $skipped = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($line in $flags) {
    if ($line -cmatch '^[a-z] ') { throw 'index may hide tracked edits' }
    if ($line -cnotmatch '^S ') { continue }
    $path = $line.Substring(2)
    if (-not @($excluded | Where-Object { $path.StartsWith("$_/", [StringComparison]::Ordinal) }).Count) { throw 'index may hide tracked edits' }
    $null = $skipped.Add($path)
  }
  foreach ($dir in $excluded) {
    $full = Join-Path $repo $dir
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($file in [IO.Directory]::EnumerateFiles($full, '*', [IO.SearchOption]::AllDirectories)) {
      $relative = $file.Substring($repo.TrimEnd('\','/').Length + 1).Replace('\', '/')
      if ($skipped.Contains($relative)) { throw "index may hide tracked edits: $relative is on disk in a left-out folder" }
    }
  }
}
function Assert-SparseProfileChangeSafe($repo, $excluded, $patterns) {
  # The new profile must be one the runner writes: none, or '/*' then the left-out folders in the fixed order.
  $wanted = @($codeCheckoutDirs | Where-Object { @($patterns) -ccontains "!/$_/" })
  if ((@($patterns) -join "`n") -cne ((Code-CheckoutPatterns $wanted) -join "`n")) { throw 'sparse checkout profile differs and the new one is not runner-managed' }
  foreach ($dir in @($wanted | Where-Object { @($excluded) -notcontains $_ })) {
    $full = Join-Path $repo $dir
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $item = Get-Item -LiteralPath $full -Force
    if ($item -isnot [IO.DirectoryInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "sparse checkout profile differs and $dir is not a plain folder" }
    $tracked = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($path in @(Read-CleanupGit @('-C',$repo,'-c','core.quotePath=false','ls-files','--',"$dir/"))) { $null = $tracked.Add($path) }
    if ($gitExit -ne 0) { throw "sparse checkout profile differs and the tracked files in $dir were not verified" }
    foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($full, '*', [IO.SearchOption]::AllDirectories)) {
      $relative = $entry.Substring($repo.TrimEnd('\','/').Length + 1).Replace('\', '/')
      $info = Get-Item -LiteralPath $entry -Force
      if ($info.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "sparse checkout profile differs and $relative is a link" }
      if ($info -is [IO.DirectoryInfo]) { continue }
      if (-not $tracked.Contains($relative)) { throw "sparse checkout profile differs and $relative is not tracked, so leaving $dir out could lose it" }
    }
  }
}
function Set-RunnerSparseProfile($repo, $patterns) {
  # Applies a profile Assert-SparseProfileChangeSafe accepted, then proves the checkout carries it.
  if (-not @($patterns).Count) {
    Must-Git @('-C',$repo,'sparse-checkout','disable')
  } else {
    # --worktree: git sparse-checkout disable (an agent can run it) writes these to config.worktree, which wins over
    # .git/config; without that extension --worktree is plain --local.
    Must-Git @('-C',$repo,'config','--worktree','core.sparseCheckout','true')
    Must-Git @('-C',$repo,'config','--worktree','core.sparseCheckoutCone','false')
    $null = [IO.Directory]::CreateDirectory((Join-Path $repo '.git/info'))
    Put (Join-Path $repo '.git/info/sparse-checkout') ((@($patterns) -join "`n") + "`n")
    Must-Git @('-C',$repo,'sparse-checkout','reapply')
  }
  $now = @(Get-ManagedSparseExclusions $repo)
  if (((Code-CheckoutPatterns $now) -join "`n") -cne (@($patterns) -join "`n")) { throw 'sparse checkout profile change did not apply; checkout kept as is' }
}
function Get-RepoCleanupState($repo, $mirror, $patterns = @(), $allowWork = $false, $forRemoval = $false) {
  if ((Get-Item -LiteralPath $repo -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'checkout is a linked path' }
  $gitDir = Join-Path $repo '.git'
  if (-not (Test-Path -LiteralPath $gitDir -PathType Container)) { throw 'not a standalone checkout' }
  Assert-PlainDirectory (Get-Item -LiteralPath $gitDir -Force)
  Assert-NoGitLocalState $repo
  Assert-NoLiveWorktree $repo
  $top = @(Read-CleanupGit @('-C',$repo,'rev-parse','--show-toplevel'))
  if ($gitExit -ne 0) { throw "checkout root not verified (Git exit ${gitExit}: $($top[0]))" }
  if ([IO.Path]::GetFullPath($top[0]) -ne [IO.Path]::GetFullPath($repo)) { throw 'checkout root not verified' }
  # Removal accepts any runner-managed profile (issue 1186); any other sparse checkout is kept.
  # Issue 1739: the profile is per issue (a Brief or Deliver to line can opt a folder back in), and an agent can turn
  # sparse off, so refusing every change kept a ~28 GB copy per run on lane D. A runner-managed (or full) checkout now
  # takes the new profile in place when that cannot lose a byte: a folder it newly leaves out must hold only tracked
  # files (clean, checked by the status below), never an untracked or ignored one. Anything else is still kept.
  $excluded = @(Get-ManagedSparseExclusions $repo)
  $profileChange = $false
  if (-not $forRemoval -and ((@($patterns) -join "`n") -cne ((Code-CheckoutPatterns $excluded) -join "`n"))) {
    Assert-SparseProfileChangeSafe $repo $excluded $patterns
    $profileChange = $true
  }
  $shallow = @(Read-CleanupGit @('-C',$repo,'rev-parse','--is-shallow-repository'))
  # Reuse needs full history. Removal only needs every local commit in the mirror, checked below, so a shallow helper
  # clone qualifies (issue 1180 run 8).
  if ($gitExit -ne 0 -or ($shallow[0] -ne 'false' -and -not ($forRemoval -and $shallow[0] -eq 'true'))) { throw 'complete local history not verified' }
  $flags = @(Read-CleanupGit @('-C',$repo,'-c','core.quotePath=false','ls-files','-v'))
  if ($gitExit -ne 0) { throw 'index flags not verified' }
  Assert-NoHiddenSparseEdits $repo $excluded $flags
  $status = @(Get-RepoCleanupStatus $repo)
  $script:cleanupSuperseded = @()
  $caches = @(Reuse-Caches $repo $status $allowWork $forRemoval)
  $superseded = @($script:cleanupSuperseded)
  $local = @(Read-CleanupGit @('-C',$repo,'rev-list','--parents','--all','--reflog','HEAD'))
  if ($gitExit -ne 0 -or -not $local.Count) { throw 'local history not verified' }
  # A janitor dry run reuses the mirror's commit list within the run (issue 1396: a dry run over every job checkout took hours),
  # but only while the mirror's refs are exactly as they were when it was read: a fetch or prune in between (the relay
  # sweep's child, another runner) moves or drops refs, and then the list is read again (Artoo on PR 1592).
  $refSnapshot = $null
  if ($script:cacheMirrorCommits) {
    $refLines = @(Read-CleanupGit @('--git-dir',$mirror,'for-each-ref','--format=%(objectname) %(refname)'))
    if ($gitExit -ne 0) { throw 'mirror refs not verified' }
    # HEAD too: rev-list --all walks it, and a detached mirror HEAD can be the only thing holding a commit.
    $mirrorHead = @(Read-CleanupGit @('--git-dir',$mirror,'rev-parse','--verify','-q','HEAD'))
    $refSnapshot = ($refLines -join "`n") + "`nHEAD " + ($mirrorHead -join ' ')
  }
  if ($refSnapshot -and $script:mirrorCommitCache -and $script:mirrorCommitCache.Mirror -eq $mirror -and
      $script:mirrorCommitCache.Refs -ceq $refSnapshot) {
    $pushed = $script:mirrorCommitCache.Set
  } else {
    $remote = @(Read-CleanupGit @('--git-dir',$mirror,'rev-list','--all'))
    if ($gitExit -ne 0 -or -not $remote.Count) { throw 'fetched history not verified' }
    $pushed = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($id in $remote) { $null = $pushed.Add($id) }
    if ($refSnapshot) { $script:mirrorCommitCache = @{ Mirror = $mirror; Refs = $refSnapshot; Set = $pushed } }
  }
  $onlyLocal = foreach ($line in $local) {
    $id = ($line -split ' ', 2)[0]
    if ($pushed.Contains($id)) { continue }
    if (-not $allowWork) { throw "local history not in fetched mirror: $id" }
    $line
  }
  return [pscustomobject]@{ Caches = $caches; Status = $status; Local = @($onlyLocal); MirrorCommits = $pushed; Superseded = $superseded; ProfileChange = $profileChange }
}
function Get-RebuildableRepoFiles($repo, $mirror, $patterns = @()) {
  $state = Get-RepoCleanupState $repo $mirror $patterns
  $script:reuseProfileChange = [bool]$state.ProfileChange
  return $state.Caches
}
function Can-ReuseRepo($repo, $mirror, $patterns) {
  $script:reuseProfileChange = $false
  if (-not (Test-Path -LiteralPath $repo)) { return $false }
  try {
    $caches = @(Get-RebuildableRepoFiles $repo $mirror $patterns)
    # Keep the whole checkout when an ignored file obstructs the incoming tree.
    $paths = @(Read-CleanupGit @('--git-dir',$mirror,'-c','core.quotePath=false','ls-tree','-r','--name-only','refs/heads/main'))
    if ($gitExit -ne 0) { throw 'incoming paths not verified' }
    $files = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $dirs = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in $paths) {
      $null = $files.Add($path); $parent = $path
      while ($parent.Contains('/')) { $parent = $parent.Substring(0, $parent.LastIndexOf('/')); $null = $dirs.Add($parent) }
    }
    foreach ($cache in $caches) {
      $path = $cache.TrimEnd('/')
      if ($dirs.Contains($path)) { throw "cache would obstruct incoming directory: $cache" }
      while ($path) {
        if ($files.Contains($path)) { throw "cache would be overwritten by incoming file: $cache" }
        if (-not $path.Contains('/')) { break }; $path = $path.Substring(0, $path.LastIndexOf('/'))
      }
    }
    return $true
  } catch { Log "checkout needs keeping: $($_.Exception.Message)"; return $false }
}
function Repo-Mirror {
  if ($test) { return $env:PC_TEST_MIRROR }
  Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\repo-mirror.git'
}
function Cleanup-Paused {
  if (-not $env:USERPROFILE) { return $false }
  $flag = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\gpu_go.txt'
  if (-not (Test-Path -LiteralPath $flag)) { return $false }
  return (Get-Content -LiteralPath $flag -TotalCount 1) -match '^GPU not cleared: paused by the Board\b'
}
function Assert-PlainDirectory($directory) {
  for ($dir = $directory; $dir; $dir = $dir.Parent) {
    if ($dir -isnot [IO.DirectoryInfo] -or ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      throw "directory is missing or linked: $($dir.FullName)"
    }
  }
}
function Assert-NoLinkedChildren($directory) {
  $pending = New-Object 'Collections.Generic.Stack[string]'
  $pending.Push($directory)
  while ($pending.Count) {
    foreach ($item in (Get-ChildItem -LiteralPath $pending.Pop() -Force -ErrorAction Stop)) {
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "linked path: $($item.FullName)" }
      if ($item.PSIsContainer) { $pending.Push($item.FullName) }
    }
  }
}
function Read-ScratchOwner($directory) {
  $owner = Get-Item -LiteralPath (Join-Path $directory $scratchOwnerFile) -Force -ErrorAction SilentlyContinue
  if (-not $owner) { throw 'ownership token file is missing' }
  if ($owner -isnot [IO.FileInfo] -or ($owner.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $owner.Length -ne 32) {
    throw 'ownership token file changed'
  }
  $token = [IO.File]::ReadAllText($owner.FullName)
  if ($token -cnotmatch '\A[0-9a-f]{32}\z') { throw 'ownership token file changed' }
  return $token
}
function Get-OwnedScratch($record, $expected) {
  $temp = [IO.Path]::GetFullPath($env:PC_RUN_TEMP).TrimEnd('\','/')
  $full = [IO.Path]::GetFullPath($record.path)
  if ($full -ne $record.path -or $full -ne $expected -or (Split-Path -Parent $full) -ne $temp -or
      (Split-Path -Leaf $full) -notmatch '^voidsworn-run-(?:[1-9][0-9]*-)?[0-9a-f]{32}$') {
    throw 'recorded path does not match this run and its TEMP directory'
  }
  if (-not (Test-Path -LiteralPath $full)) { return }
  $dir = Get-Item -LiteralPath $full -Force
  Assert-PlainDirectory $dir
  if ((Read-ScratchOwner $full) -cne $record.token) { throw 'ownership token file changed' }
  # Linux filesystems do not always expose a stable directory birth time.
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and
      [string]$dir.CreationTimeUtc.Ticks -ne $record.created) { throw 'recorded directory was replaced' }
  return $dir
}
function Remove-CleanupDirectory($dir) {
  Assert-PlainDirectory (Get-Item -LiteralPath $dir.FullName -Force)
  if (Cleanup-Paused) { throw 'PC pause is active' }
  Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction Stop
  if (Test-Path -LiteralPath $dir.FullName) { throw 'directory could not be fully removed' }
}
function Complete-RunScratch($record, $keepFailed) {
  if (-not $record) { return }
  try {
    $dir = Get-OwnedScratch $record $env:PC_RUN_SCRATCH
    if (-not $dir) { return }
    if (-not $keepFailed) {
      Assert-NoLinkedChildren $dir.FullName
      Remove-CleanupDirectory $dir
      Log "run scratch removed: $($dir.FullName)"
      return
    }
    if ($dir.Name -notmatch '^voidsworn-run-([1-9][0-9]*)-[0-9a-f]{32}$') { return }
    $issue = $Matches[1]
    # Only the runner holding the issue across this run can replace its retry scratch.
    if ($env:PC_RUNNER_LOCKED_ISSUE -ne $issue) { throw 'run does not hold the issue lock' }
    $marker = Join-Path $dir.FullName $scratchFailedFile
    if (Test-Path -LiteralPath $marker) { return }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    $file = [IO.File]::Open($marker, 'CreateNew', 'Write', 'None')
    $file.Dispose()
    Log "run scratch kept for a retry for one day: $($dir.FullName)"
    foreach ($old in $dir.Parent.GetDirectories("voidsworn-run-$issue-*")) {
      if ($old.FullName -eq $dir.FullName -or $old.Name -notmatch "^voidsworn-run-$issue-[0-9a-f]{32}$") { continue }
      try {
        Assert-PlainDirectory $old
        if (-not (Get-FailedScratchMarker $old)) { continue }
        $null = Read-ScratchOwner $old.FullName
        Assert-NoLinkedChildren $old.FullName
        Remove-CleanupDirectory $old
        Log "older failed run scratch removed: $($old.FullName)"
      } catch { Log "older failed run scratch kept: $($old.FullName) ($($_.Exception.Message))" }
    }
  } catch { Log "run scratch kept: $($record.path) ($($_.Exception.Message))" }
}
function Get-FailedScratchMarker($dir) {
  $marker = Get-Item -LiteralPath (Join-Path $dir.FullName $scratchFailedFile) -Force -ErrorAction SilentlyContinue
  if ($marker -and ($marker -isnot [IO.FileInfo] -or ($marker.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
    throw 'retry marker is not a plain file'
  }
  return $marker
}
function Measure-CleanupDirectory($directory, [switch]$checkout, [switch]$allowLinks, [switch]$allowUnreadable) {
  Assert-PlainDirectory $directory
  $bytes = 0L; $latest = $directory.LastWriteTimeUtc; $links = @(); $unreadable = @()
  $fileLatest = [DateTime]::MinValue; $worktreeLatest = [DateTime]::MinValue
  # Issue 1739: FreeBytes is what removing the folder would give back. A hard link shared with a file outside it frees
  # nothing, and a folder another account owns cannot be removed by this one, so neither counts.
  $tally = $null
  if (Get-Command New-FreeTally -ErrorAction SilentlyContinue) {
    $tally = New-FreeTally
    if (Test-OtherAccountFolder $directory) { throw "owned by another account: $($directory.FullName)" }
  }
  $gitPrefix = (Join-Path $directory.FullName '.git') + [IO.Path]::DirectorySeparatorChar
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push($directory)
  while ($pending.Count) {
    $next = $pending.Pop()
    # A folder another account owns (Codex sandbox scratch) cannot be listed. With -AllowUnreadable it is noted and
    # skipped, so the rest is still sized (Board, R8 dry run: 68 TEMP rows had no size at all).
    try { $entries = @($next.EnumerateFileSystemInfos()) }
    catch {
      if (-not $allowUnreadable -or $next.FullName -eq $directory.FullName) { throw }
      $unreadable += ,$next; continue
    }
    $batch = New-Object 'Collections.Generic.List[object]'; $folders = New-Object 'Collections.Generic.List[object]'
    foreach ($item in $entries) {
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        # Links are listed, never followed or counted (legacy selftest fixtures hold junctions to shared ships).
        if (-not $allowLinks) { throw "linked path: $($item.FullName)" }
        $links += ,$item
        continue
      }
      if ($item.LastWriteTimeUtc -gt $latest) { $latest = $item.LastWriteTimeUtc }
      if ($item -is [IO.DirectoryInfo]) {
        if ($tally) { $folders.Add($item) } else { $pending.Push($item) }
        continue
      }
      $bytes += $item.Length
      if ($tally) { $batch.Add($item) }
      if ($item.LastWriteTimeUtc -gt $fileLatest) { $fileLatest = $item.LastWriteTimeUtc }
      if ($checkout -and $item.LastWriteTimeUtc -gt $worktreeLatest -and
          -not $item.FullName.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $worktreeLatest = $item.LastWriteTimeUtc
      }
    }
    if ($tally -and $batch.Count) { Add-FreeTallyBatch $tally $batch.ToArray() }
    if ($folders.Count) {
      $foreign = @(Select-OtherAccountFolders $folders.ToArray())
      foreach ($folder in $folders) {
        if ($foreign -contains $folder) {
          # Listed with the unreadable folders: left in place by a removal and never counted.
          if (-not $allowUnreadable) { throw "folder another account owns: $($folder.FullName)" }
          $unreadable += ,$folder; continue
        }
        $pending.Push($folder)
      }
    }
  }
  $free = $bytes; $shared = 0L; $unchecked = 0L
  if ($tally) { $sum = Complete-FreeTally $tally; $free = $sum.Free; $shared = $sum.SharedOutside; $unchecked = $sum.Unchecked }
  return [pscustomobject]@{ Bytes = $bytes; Latest = $latest; FileLatest = $fileLatest; WorktreeLatest = $worktreeLatest
    Links = $links; Unreadable = $unreadable; FreeBytes = $free; SharedBytes = $shared; UncheckedBytes = $unchecked }
}
function Format-CleanupSize($stats) {
  if (Get-Command Format-FreeBytes -ErrorAction SilentlyContinue) { return (Format-FreeBytes $stats) }
  return "$($stats.Bytes) bytes"
}
function Add-WouldFree($stats, $path) {
  # The janitor's closing line adds these up, so a dry run's total is what removal would really give back.
  $script:wouldFreeBytes += [long]$stats.FreeBytes
  $script:wouldFreeCount++
}
function Get-LinkTarget($link) {
  # Where a link points, for the log only: it is never followed.
  try { $t = @((Get-Item -LiteralPath $link.FullName -Force -ErrorAction Stop).Target) | Where-Object { $_ } | Select-Object -First 1 }
  catch { $t = $null }
  if ($t) { return [string]$t }; return 'target unknown'
}
function Remove-CleanupReadable($dir, $unreadable) {
  # Remove everything except folders another account owns and the folders that lead to them. Run only after links are
  # gone and the ownership checks passed; an unreadable folder cannot be listed, so nothing in it is followed or removed.
  $keep = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($u in $unreadable) {
    for ($d = $u; $d -and $d.FullName.Length -ge $dir.FullName.Length; $d = $d.Parent) { $null = $keep.Add($d.FullName) }
  }
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push($dir)
  while ($pending.Count) {
    $next = $pending.Pop()
    if ($unreadable | Where-Object { $_.FullName -eq $next.FullName }) { continue }
    foreach ($item in @($next.EnumerateFileSystemInfos())) {
      if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "a link appeared: $($item.FullName)" }
      if ($keep.Contains($item.FullName)) { $pending.Push($item); continue }
      if (Cleanup-Paused) { throw 'PC pause is active' }
      if ($item -is [IO.DirectoryInfo]) {
        Assert-NoLinkedChildren $item.FullName
        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
      } else { Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop }
    }
  }
}
function Remove-CleanupLinks($links) {
  # Remove each link itself, never its target. PowerShell 5.1's Remove-Item -Recurse can follow a junction.
  foreach ($link in $links) {
    $item = Get-Item -LiteralPath $link.FullName -Force -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "link was replaced: $($link.FullName)" }
    if (Cleanup-Paused) { throw 'PC pause is active' }
    if ($item -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($item.FullName, $false) } else { [IO.File]::Delete($item.FullName) }
    if (Test-Path -LiteralPath $item.FullName) { throw "link could not be removed: $($item.FullName)" }
  }
}
function Open-CleanupLock($path, $existingOnly = $false) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($item -and ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
    throw "lock is not a plain file: $path"
  }
  if ($existingOnly -and -not $item) { return }
  if ($existingOnly) { return [IO.File]::Open($path, 'Open', 'Read', 'None') }
  return [IO.File]::Open($path, 'OpenOrCreate', 'ReadWrite', 'None')
}
function Open-MirrorWriterLock($mirror) {
  # Issue 1396 (Artoo on PR 1592): every writer of the shared mirror (lane fetch and clone, the job head, helper_clone,
  # ship_job, look_bench) holds <mirror>.lock alone. A live removal holds it from its last mirror proof through the
  # delete, so no fetch or prune can drop the ref that proved the removal in between. Waits up to 10 minutes
  # (PC_MIRROR_LOCK_WAIT_SECONDS), then keeps the candidate.
  $wait = 600; if ("$env:PC_MIRROR_LOCK_WAIT_SECONDS" -match '\A[0-9]{1,5}\z') { $wait = [int]$env:PC_MIRROR_LOCK_WAIT_SECONDS }
  if (-not (Test-Path -LiteralPath (Split-Path -Parent $mirror) -PathType Container)) { throw "no folder for the shared repo copy lock: $mirror" }
  $deadline = [DateTime]::UtcNow.AddSeconds($wait)
  while ($true) {
    try { return [IO.File]::Open("$mirror.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] {
      if ([DateTime]::UtcNow -ge $deadline) { throw "shared repo copy stayed locked for $wait s (a mirror fetch is running)" }
      Start-Sleep -Milliseconds 500
    }
  }
}
function Assert-NoGitLocalState($candidate) {
  $gitDir = Join-Path $candidate '.git'
  foreach ($state in @('index.lock','HEAD.lock','packed-refs.lock','MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','BISECT_START','rebase-apply','rebase-merge','sequencer','modules')) {
    if (Test-Path -LiteralPath (Join-Path $gitDir $state)) { throw "Git holds local state: $state" }
  }
}
function Assert-NoLiveWorktree($candidate) {
  # Another live worktree can hold staged-only work under this .git; a prunable one (folder gone) shares nothing.
  if (Test-Path -LiteralPath (Join-Path $candidate '.git/worktrees')) {
    $lines = @(Read-CleanupGit @('-C',$candidate,'worktree','list','--porcelain'))
    if ($gitExit -ne 0) { throw 'checkout may be shared with another worktree' }
    # A worktree whose folder is gone is listed as prunable; it shares nothing (issue 1180 run 8). Count the live ones.
    $live = @(); $current = $null
    foreach ($line in ($lines + '')) {
      if ($line -like 'worktree *') { $current = @{ Path = $line.Substring(9); Prunable = $false } }
      elseif ($line -like 'prunable*' -and $current) { $current.Prunable = $true }
      elseif (-not $line -and $current) { if (-not $current.Prunable) { $live += $current.Path }; $current = $null }
    }
    if ($live.Count -ne 1) { throw "checkout may be shared with another worktree: $(($live | Select-Object -Skip 1) -join ', ')" }
  }
}
function Read-BoardKeepList($file) {
  # The Board's keep list (issue 1180, Nov 20): voidsworn_test\janitor_keep.txt, one exact folder path per line, # for
  # notes. A missing file is an empty list; a file that cannot be read stops the janitor rather than ignoring it.
  $item = Get-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
  if (-not $item) { return ,@() }
  if ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Board keep list is not a plain file: $file" }
  $paths = @()
  foreach ($line in [IO.File]::ReadAllLines($file)) {
    $p = $line.Trim().TrimStart([char]0xFEFF)
    if (-not $p -or $p.StartsWith('#')) { continue }
    $paths += [IO.Path]::GetFullPath($p).TrimEnd('\', '/')
  }
  return ,$paths
}
function Get-BoardKeepReason($path) {
  # Whole-path match: the candidate is a listed path, holds one, or sits inside one. Never a partial name match.
  # Every removal path loads the list itself (the janitor and the runner's end-of-job cleanup alike; Artoo on PR 1277).
  # A list that cannot be read throws, and the caller keeps the candidate.
  if ($null -eq $script:boardKeep) {
    $script:boardKeep = Read-BoardKeepList (Join-Path $env:USERPROFILE 'Downloads/voidsworn_test/janitor_keep.txt')
  }
  if (-not $script:boardKeep.Count) { return '' }
  $full = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
  foreach ($keep in $script:boardKeep) {
    if ($full -eq $keep -or $keep.StartsWith($full + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($keep + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($full, $keep, [StringComparison]::OrdinalIgnoreCase)) { return 'kept: on the Board keep list' }
  }
  return ''
}
function Clear-KeptCheckout($copy, $mirror, $dryRun, $now, $salvageRoot, $salvageName, $keepReason = '') {
  $candidate = $copy.FullName
  $size = 'size unavailable'; $mirrorLock = $null
  try {
    $stats = Measure-CleanupDirectory $copy -Checkout
    $size = Format-CleanupSize $stats
    $listed = Get-BoardKeepReason $candidate
    if ($listed) { throw $listed }
    if ($keepReason) { throw $keepReason }
    if ($salvageRoot -and $stats.WorktreeLatest -gt $now.AddHours(-3)) { throw 'touched in the last 3 hours' }
    Assert-NoGitLocalState $candidate
    # A live removal holds the mirror writers' lock from this history proof through the delete (Open-MirrorWriterLock).
    if (-not $dryRun) { $mirrorLock = Open-MirrorWriterLock $mirror }
    # Removal may accept ship and gen files the shared build has superseded; reuse never does.
    $state = Get-RepoCleanupState $candidate $mirror '' ([bool]$salvageRoot) $true
    Assert-NoLiveWorktree $candidate
    if (Cleanup-Paused) { throw 'PC pause is active' }
    $reason = 'rebuildable'
    if ($salvageRoot -and ($state.Local.Count -or $state.Status.Count -ne $state.Caches.Count)) {
      if ($stats.WorktreeLatest -gt $now.AddDays(-1)) { throw 'holds local work and was touched in the last day' }
      $backup = Join-Path $salvageRoot $salvageName
      if (Test-Path -LiteralPath $backup) { throw "salvage destination already exists: $backup" }
      $reason = 'after checked salvage of local work'
      if (-not $dryRun) { Save-CheckoutSalvage $candidate $mirror $state $backup }
    }
    if ($state.Superseded.Count) {
      # A same-name newer build file does not prove these bytes were replaced: archive them and read them back first.
      if (-not $salvageRoot) { throw 'superseded ship or gen files need a checked archive' }
      $archive = Join-Path $salvageRoot "$salvageName`_superseded"
      if (Test-Path -LiteralPath $archive) { throw "archive destination already exists: $archive" }
      $archiveBytes = 0L
      foreach ($path in $state.Superseded) { $archiveBytes += (Get-Item -LiteralPath (Join-Path $candidate $path) -Force).Length }
      $archived = "after checked archive of $($state.Superseded.Count) superseded ship or gen files, $archiveBytes bytes before dedupe"
      $reason = if ($reason -eq 'rebuildable') { $archived } else { "$reason; $archived" }
      if (-not $dryRun) { Save-SupersededArchive $candidate $state.Superseded $archive }
    }
    if ($dryRun) { Add-WouldFree $stats $candidate; Log "kept checkout would remove ($reason): $candidate ($size)"; return }
    $current = Measure-CleanupDirectory (Get-Item -LiteralPath $candidate -Force) -Checkout
    # Include Git metadata in the final check for changes made by another process.
    if ($current.Latest -ne $stats.Latest -or $current.WorktreeLatest -ne $stats.WorktreeLatest -or
        $current.Bytes -ne $stats.Bytes) { throw 'checkout changed during the scan' }
    Remove-CleanupDirectory $copy
    Add-WouldFree $stats $candidate
    Log "kept checkout removed ($reason): $candidate ($size)"
  } catch { Log "kept checkout retained: $candidate ($size; $($_.Exception.Message))" }
  finally { if ($mirrorLock) { $mirrorLock.Dispose() } }
}
function Remove-OlderKeptRepos($board, $mirror, $dryRun = $false, $now = [DateTime]::UtcNow, $salvageRoot = '') {
  Assert-PlainDirectory (Get-Item -LiteralPath $board -Force)
  $lock = $null
  try { $lock = Open-CleanupLock (Join-Path $board 'repo.cleanup.lock') $dryRun } catch { Log "kept checkout scan kept: $board ($($_.Exception.Message))"; return }
  try {
    $copies = @(Get-ChildItem -LiteralPath $board -Directory -Force |
      Where-Object { $_.Name -like 'repo-kept-*' } | Sort-Object LastWriteTimeUtc, CreationTimeUtc, Name -Descending)
    foreach ($copy in $copies) {
      if ($copy.Parent.FullName -ne $board) { Log "kept checkout retained: $($copy.FullName) (size unavailable; outside the board directory)"; continue }
      if ($copy -eq $copies[0]) {
        try { $stats = Measure-CleanupDirectory $copy; Log "kept checkout retained (newest): $($copy.FullName) ($(Format-CleanupSize $stats))" }
        catch { Log "kept checkout retained (newest): $($copy.FullName) (size unavailable; $($_.Exception.Message))" }
        continue
      }
      Clear-KeptCheckout $copy $mirror $dryRun $now $salvageRoot "$(Split-Path -Leaf $board)_$($copy.Name)"
    }
  } finally { if ($lock) { $lock.Dispose() } }
}
# Windows command line quoting, including trailing backslashes. Inputs are argument values, never shell snippets.
function Quote($value) { return '"' + ([regex]::Replace(([string]$value), '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"' }
# Final reporting is best effort. Start validation and claiming must fail closed.
function Invoke-Gh($method, $endpoint, $payload = $null, $pages = $false) {
  $script:ghOK = $false
  $script:ghError = ''
  try {
    $exe = 'gh'
    if ($test) {
      if (-not $env:PC_TEST_GH) { Log 'GitHub status skipped: test has no fake gh'; return '' }
      $exe = $env:PC_TEST_GH
    }
    $command = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $command -and -not $test) {
      # Chain windows opened before installation still have the old PATH.
      foreach ($install in @(
        @{ root = $env:ProgramFiles; relative = 'GitHub CLI/gh.exe' },
        @{ root = $env:LOCALAPPDATA; relative = 'Programs/GitHub CLI/gh.exe' }
      )) {
        if (-not $install.root) { continue }
        $candidate = Join-Path $install.root $install.relative
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
          $exe = $candidate
          $command = Get-Command $exe -ErrorAction SilentlyContinue
          if ($command) { break }
        }
      }
    }
    if (-not $command -and $script:boardReadOnly -and -not $test -and $method -eq 'GET') {
      # The public board audit works before gh is installed. Claims always require authenticated gh.
      if (-not $script:ghMissingLogged) {
        Log 'GitHub CLI gh is missing: claims will fail closed; this read-only audit uses public REST'
        $script:ghMissingLogged = $true
      }
      $items = @(); $page = 1
      do {
        $url = "https://api.github.com/repos/rcbailey12/voidsworn/$endpoint"
        if ($pages) { $url += "&page=$page" }
        $reply = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ 'User-Agent' = 'voidsworn-runner-board-audit' } -Uri $url
        if (-not $pages) { $script:ghOK = $true; return (ConvertTo-Json -InputObject $reply -Depth 30) }
        $items += @($reply); $page++
      } while (@($reply).Count -eq 100)
      $script:ghOK = $true
      return ('[' + (ConvertTo-Json -InputObject @($items) -Depth 30 -Compress) + ']')
    }
    if (-not $command) { throw 'GitHub CLI gh is missing; install it and run gh auth login before starting PC jobs' }
    if ($command.CommandType -eq 'Application') { $exe = $command.Source }
    if ($script:ghExeLogged -ne $exe) { Log "GitHub CLI: $exe"; $script:ghExeLogged = $exe }
    $words = @('api','--method',$method,"repos/rcbailey12/voidsworn/$endpoint")
    if ($pages) { $words += @('--paginate','--slurp') }
    if ($null -ne $payload) {
      $file = Join-Path $out 'github_payload.json'
      Put $file ($payload | ConvertTo-Json -Depth 8)
      $words += @('--input',$file)
    }
    $ea = $ErrorActionPreference
    try {
      $ErrorActionPreference = 'Continue'
      $lines = @(& $exe @words 2>&1); $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $ea }
    if ($code -ne 0) { throw "exit $code $($lines -join ' ')" }
    $script:ghOK = $true
    return ($lines -join "`n")
  } catch { $script:ghError = $_.Exception.Message; Log "WARNING: GitHub status $method $endpoint failed: $script:ghError"; return '' }
}
function Status-Body($s, $label, $code) {
  $g = $s.github
  $branch = $s.branch
  if ($label -eq 'partial') { $branch += '-partial' }
  $commit = $s.commit; if (-not $commit) { $commit = $g.start_commit }
  $reason = Public-RunnerText $s.status $s.reason $code
  return @"
$($g.marker)
Runner status: $label

- Seat: $($g.seat)
- Run: $($s.run)
- Lane: $($g.lane)
- Branch: $branch
- Started (UTC): $($g.started)
- Ceiling: $($g.ceiling) seconds
- Last commit: $commit
- How to resume: $($g.resume)
- Finished (UTC): $($s.finished)
- Result: $reason
"@
}
function Require-Gh($method, $endpoint, $payload = $null, $pages = $false) {
  $raw = Invoke-Gh $method $endpoint $payload $pages
  if (-not $script:ghOK) { throw "cannot validate or claim job: $method $endpoint failed ($script:ghError); no agent started" }
  try { return (ConvertFrom-Json $raw) }
  catch { throw "cannot validate or claim job: invalid JSON from $method $endpoint; no agent started" }
}
function Gh-Pages($endpoint) {
  $pages = Require-Gh 'GET' $endpoint $null $true
  foreach ($page in $pages) { foreach ($item in $page) { $item } }
}
function Current-Body($body, $prefix, [ref]$assignment) {
  # A marker is a line, not a heading or an occurrence: bold and plain run lines work too.
  $current = @(); $runs = @(); $fence = ''; $offset = 0
  $runLabel = '(?:run[ \t]+[0-9]+|(?:earlier|previous|old)[ \t-]+runs?)\b'
  $plainRun = '^[ \t]*' + $runLabel + '(?:[ \t]*\([^()]*\))?[ \t]*(?:[:.-][ \t]*.*)?$'
  foreach ($line in ([regex]::Split($body, '(?<=\n)'))) {
    $text = $line.TrimEnd("`r", "`n")
    if ($text -match '^ {0,3}(`{3,}|~{3,})') {
      $mark = $Matches[1]
      if (-not $fence) { $fence = $mark }
      elseif ($mark[0] -eq $fence[0] -and $mark.Length -ge $fence.Length -and $text -match '^ {0,3}(`{3,}|~{3,})[ \t]*$') { $fence = '' }
    } elseif (-not $fence) {
      $entry = @{ start = $offset; end = $offset + $line.Length; text = $text }
      if ($text.Contains('THIS IS THE JOB NOW')) { $current += $entry }
      # Headings and whole bold labels are explicit; plain labels must be short and use label punctuation.
      if ($text -match ('^ {0,3}#{1,6}[ \t]+' + $runLabel) -or
          $text -match ('^[ \t]*\*\*' + $runLabel + '.*\*\*[ \t]*$') -or
          ($text.Trim().Length -le 80 -and $text -match $plainRun)) { $runs += $entry }
    }
    $offset += $line.Length
  }
  if ($current.Count -gt 1) { throw "current instruction refused: expected one line containing THIS IS THE JOB NOW outside code fences, found $($current.Count); no agent started" }
  # Take only the opening fixed block, whether it is plain text or fenced for display.
  $blocks = [regex]::Matches($body, $fixedBlockPattern)
  $fixed = ''; if ($blocks.Count) { $fixed = $blocks[0].Value }
  foreach ($field in @('Owner','Brief','Deliver to','Branch','Done when')) {
    $pattern = [regex]::Escape($field)
    if ($field -eq 'Done when') { $pattern += '(?:[ \t]+\([^\r\n]*?\))?' }
    if ([regex]::Matches($fixed, "(?im)^[ \t]*${pattern}:[ \t]*\S[^\r\n]*").Count -ne 1) {
      throw "current instruction refused: fixed block needs one ${field}: line; no agent started"
    }
  }
  # The first tokens name the assignment. Older briefs can add a parenthetical note on either line.
  if ($assignment) {
    $assignment.Value = @{
      owner = [regex]::Match($fixed, '(?im)^[ \t]*Owner:[ \t]*([^ \t\r\n]+)').Groups[1].Value.Trim('`')
      branch = [regex]::Match($fixed, '(?im)^[ \t]*Branch:[ \t]*([^ \t\r\n]+)').Groups[1].Value.Trim('`')
    }
  }
  if ($prefix -eq 'codex' -and $fixed -notmatch '(?im)\bEffort \(Codex\):[ \t]*(xhigh|high|medium)\b') {
    throw 'current instruction refused: Codex fixed block needs Effort (Codex): high or xhigh; no agent started'
  }
  if ($current.Count -eq 0) {
    # A new job has no run history to select from. Its one fixed block and entire body are current.
    if ($blocks.Count -ne 1 -or $runs.Count) {
      throw "current instruction refused: found 0 THIS IS THE JOB NOW lines; without a marker use exactly one fixed block and no run history (fixed blocks: $($blocks.Count), run lines: $($runs.Count)); no agent started"
    }
    return $body.Trim()
  }
  $h = $current[0]
  $end = $body.Length
  foreach ($next in $runs) {
    if ($next.start -gt $h.start) { $end = $next.start; break }
  }
  $fixedMatch = [regex]::Match($body, [regex]::Escape($fixed))
  if ($h.start -lt $fixedMatch.Index) { throw 'current instruction refused: put the fixed block before the current run; no agent started' }
  $inline = $h.text -creplace '^.*?THIS IS THE JOB NOW', ''
  # The marker's run/date suffix identifies the brief, but is not an instruction.
  $inline = $inline -ireplace '^[ \t#*_:.,;-]*\([ \t]*run[ \t]+[0-9]+\b[^()]*\)', ''
  $inline = $inline -replace '^[\W_]*', ''
  if (-not $inline.Trim() -and -not $body.Substring($h.end, $end - $h.end).Trim()) { throw 'current instruction refused: the current block is empty; no agent started' }
  if ($h.start -lt $fixedMatch.Index + $fixed.Length) {
    # Some current jobs put their marker and the entire instruction on Done when itself.
    return $body.Substring($fixedMatch.Index, $end - $fixedMatch.Index).Trim()
  }
  return ($fixed.Trim() + "`n`n" + $body.Substring($h.start, $end - $h.start).Trim())
}
function Find-BaseLines($body) {
  [regex]::Matches($body, '(?im)^[ \t]*Base:[ \t]*([^\r\n]*)')
}
function Validate-Job($i, $issue, $seat, $pulls, $branches, $launchBranch = "$seat/issue-$issue") {
  if ($i.state -ne 'open' -or $i.pull_request) { throw "job refused: issue #$issue is not an open job (state: $($i.state)); no agent started" }
  if (@($i.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count) { throw "job refused: issue #$issue already carries running; another run owns the claim; no agent started" }
  $prefix = $seat
  $owners = @($seat)
  if ($seat -in @('deepseek','deepseekpro','kimi','kimicode','sonnet','opus','openai') -and $launchBranch -ceq "work/issue-$issue-$seat") {
    $prefix = 'work'
    # The Board assigns workhorse jobs under Owner: codex or names the arm itself.
    $owners += 'codex'
  } elseif ($seat -notin @('codex','muse','opus') -or $launchBranch -cne "$seat/issue-$issue") {
    throw "job refused: invalid launch assignment for seat $seat; no agent started"
  }
  $assignment = $null
  $body = Current-Body ([string]$i.body) $prefix ([ref]$assignment)
  if ($assignment.branch -cne $launchBranch) {
    throw "job refused: Branch: assigns issue #$issue to $($assignment.branch), launch is for $launchBranch; no agent started"
  }
  if ($assignment.owner -notin $owners) {
    throw "job refused: Owner: $($assignment.owner) does not match the $seat launch for issue #$issue; no agent started"
  }
  $jobBranch = "^(codex|work|muse|opus)/issue-$issue(?:-|$)"
  foreach ($pr in $pulls) {
    $ref = [string]$pr.head.ref
    if ($ref -match $jobBranch -or "$($pr.title)`n$($pr.body)" -match "(?im)(?:\b(?:issue|refs)\s+#$issue\b|/issues/$issue\b)") {
      if (($ref -split '/')[0] -ne $prefix) { throw "job refused: open PR #$($pr.number) from other seat $ref covers issue #$issue; no agent started" }
    }
  }
  $baseLines = @(Find-BaseLines $body)
  $base = if ($baseLines.Count -eq 1) { $baseLines[0].Groups[1].Value.Trim() }
  foreach ($branch in $branches) {
    if ($branch.name -match $jobBranch -and ([string]$branch.name -split '/')[0] -ne $prefix) {
      if ([string]::Equals($branch.name, $base, [StringComparison]::Ordinal)) {
        Log "Base branch $($branch.name) from another seat is this job's Base; does not block issue #$issue"
        continue
      }
      $tip = [string]$branch.commit.sha
      if ($tip -notmatch '^[0-9a-f]{40,64}$') { throw "job refused: cannot verify tip of delivery branch $($branch.name) for issue #$issue; no agent started" }
      $compare = Require-Gh 'GET' "compare/main...$tip"
      if ($compare.status -in @('behind','identical')) {
        Log "finished work: delivery branch $($branch.name) tip $tip is already in main ($($compare.status)); does not block issue #$issue"
        continue
      }
      throw "job refused: delivery branch $($branch.name) from another seat exists for issue #$issue; no agent started"
    }
  }
  return $body
}
function Runner-Temp {
  if ($env:PC_RUN_TEMP) { return $env:PC_RUN_TEMP }
  return [IO.Path]::GetTempPath()
}
function Issue-LockPath($issue, $temp = (Runner-Temp)) {
  if ($issue -notmatch '\A[1-9][0-9]*\z') { throw 'invalid job issue number; no agent started' }
  if ($test -and $env:PC_TEST_GH_DB) { return Join-Path (Split-Path -Parent $env:PC_TEST_GH_DB) "issue-$issue.lock" }
  return Join-Path $temp "voidsworn-runner-issue-$issue.lock"
}
function Issue-Lock($issue) {
  $path = Issue-LockPath $issue
  $deadline = [DateTime]::UtcNow.AddSeconds(30)
  while ($true) {
    try { return Open-CleanupLock $path }
    catch [IO.IOException] {
      if ([DateTime]::UtcNow -ge $deadline) { throw 'job claim stayed locked for 30 seconds; no agent started' }
      Start-Sleep -Milliseconds 100
    }
  }
}
function Open-HeldLock($path) {
  # An exclusive lock that child processes inherit. Windows releases it only when every process holding the handle has
  # exited, so a run whose waiting PowerShell dies keeps its lock while the batch and its tools still work (Artoo, PR 1250).
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($item -and ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
    throw "lock is not a plain file: $path"
  }
  return [IO.File]::Open($path, 'OpenOrCreate', 'ReadWrite', [IO.FileShare]::Inheritable)
}
function Invoke-LockedRunner($start, $issue) {
  # Keep the lock until the child finishes recording its result and cleaning its scratch.
  $lock = Open-HeldLock (Issue-LockPath $issue)
  try {
    $start.EnvironmentVariables['PC_RUNNER_LOCKED_ISSUE'] = $issue
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $child = [Diagnostics.Process]::Start($start)
    try {
      $stderr = $child.StandardError.ReadToEndAsync()
      while ($null -ne ($line = $child.StandardOutput.ReadLine())) { Write-Host $line }
      $child.WaitForExit()
      $errors = $stderr.GetAwaiter().GetResult()
      if ($errors) { [Console]::Error.Write($errors) }
      return $child.ExitCode
    }
    finally { $child.Dispose() }
  } finally { $lock.Dispose() }
}
if ($mode -eq 'cleanup-library') { return }
function End-Announcement($s) {
  if (-not $s.github -or -not $s.github.claimed) { return }
  try {
    $g = $s.github
    # Never edit or clear a claim replaced by another run, even on the same branch or seat.
    $raw = Invoke-Gh 'GET' "issues/comments/$($g.comment)"
    if (-not $ghOK) { return }
    $comment = ConvertFrom-Json $raw
    if (-not ([string]$comment.body).Contains("- Run: $($s.run)")) { Log 'GitHub finish skipped: status comment belongs to another run'; return }
    $label = 'failed'
    if ($s.status -eq 'checked_push') { $label = 'finished' }
    if ($s.status -eq 'unverified') { $label = 'unverified' }
    if ($s.status -eq 'partial') { $label = 'partial' }
    if ($g.comment) { $null = Invoke-Gh 'PATCH' "issues/comments/$($g.comment)" @{ body = (Status-Body $s $label $code) } }
    # Clearing the owned label must still be attempted when editing the comment fails.
    $null = Invoke-Gh 'DELETE' "issues/$($g.issue)/labels/running"
    if ($ghOK) { $g.claimed = $false; Save-State $s }
  } catch { Log "WARNING: GitHub final status failed: $($_.Exception.Message)" }
}
try {
  if ($mode -eq 'init') {
    $script:out = $args[1]
    $s = @{ run = [guid]::NewGuid().ToString('N'); branch = $args[2]; status = 'running'; reason = ''; commit = ''; started = [DateTime]::UtcNow.ToString('o'); finished = '' }
    Put (Join-Path $out 'status.json') ($s | ConvertTo-Json)
    # Keep any earlier resume note aside. The current run writes a note only when it has resume context.
    $resumePath = Join-Path $out 'resume.txt'
    if (Test-Path -LiteralPath $resumePath) { [IO.File]::Move($resumePath, "$resumePath.$($s.run).previous") }
    # Old run metadata must never turn a later failure into success.
    foreach ($f in @('stop_reason.txt','run_commit.txt','confirmed_commit.txt','partial.txt','checks_node.txt','checks_parity.txt','scratch_path.txt','commit.txt')) { Put (Join-Path $out $f) '' }
  }
  elseif ($mode -eq 'scratch') {
    $script:out = $args[1]
    $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    if ($s.status -ne 'running' -or $s.scratch) { throw 'scratch directory can only be created once for a running job' }
    $temp = Get-Item -LiteralPath $env:PC_RUN_TEMP -Force
    Assert-PlainDirectory $temp
    $issue = $env:PC_RUNNER_LOCKED_ISSUE
    $prefix = if ($issue -match '\A[1-9][0-9]*\z') { "voidsworn-run-$issue-" } else { 'voidsworn-run-' }
    $dir = New-Item -ItemType Directory -Path (Join-Path $temp.FullName ($prefix + [guid]::NewGuid().ToString('N')))
    $token = [guid]::NewGuid().ToString('N')
    Put (Join-Path $dir.FullName $scratchOwnerFile) $token
    $s | Add-Member -NotePropertyName scratch -NotePropertyValue @{
      path = $dir.FullName; token = $token; created = [string]$dir.CreationTimeUtc.Ticks
    }
    Save-State $s
    Put (Join-Path $out 'scratch_path.txt') ($dir.FullName + [Environment]::NewLine)
    Log "run scratch created: $($dir.FullName)"
  }
  elseif ($mode -eq 'wait') {
    $script:out = $args[1]
    if (-not $env:PC_WAIT_FOR) { exit 0 }
    $p = $env:PC_WAIT_FOR
    if (Test-Path -LiteralPath $p -PathType Container) { $p = Join-Path $p 'status.json' }
    if ([IO.Path]::GetFullPath($p) -eq [IO.Path]::GetFullPath((Join-Path $out 'status.json'))) { throw 'chain stopped: a job cannot wait for itself' }
    $limit = 43200; if ($env:PC_WAIT_SECONDS) { $limit = [int]$env:PC_WAIT_SECONDS }
    $end = [DateTime]::UtcNow.AddSeconds($limit)
    Log "chain waiting for $p"
    $run = ''
    while ($true) {
      if (-not (Test-Path -LiteralPath $p)) { throw 'chain stopped: predecessor status.json is missing; text results cannot prove a checked push' }
      $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
      if (-not $run) { $run = $s.run }
      if (-not $run -or $run -ne $s.run) { throw 'chain stopped: predecessor run changed while waiting' }
      if ($env:PC_WAIT_RUN -and $s.run -ne $env:PC_WAIT_RUN) { throw 'chain stopped: predecessor run id does not match PC_WAIT_RUN' }
      if ($s.status -eq 'checked_push' -and $s.commit -match '^[0-9a-f]{40,64}$') { Log "chain released: checked push $($s.branch) $($s.commit)"; exit 0 }
      if ($s.status -ne 'running') { throw "chain stopped: predecessor ended $($s.status): $($s.reason)" }
      if ([DateTime]::UtcNow -ge $end) { throw 'chain stopped: predecessor did not finish before the wait limit' }
      Start-Sleep -Milliseconds 500
    }
  }
  elseif ($mode -eq 'checkout') {
    $repo = $args[1]; $script:out = $args[2]; $br = $args[3]
    if ([IO.Path]::GetFileName([IO.Path]::GetFullPath($repo).TrimEnd('\','/')) -ne 'repo') { throw "unexpected checkout path $repo" }
    $patterns = @()
    $slot = Split-Path -Leaf (Split-Path -Parent $repo)
    if ($args[4]) { $patterns = @($args[4] -split '\s+') }
    elseif ($slot -match '\A(board_[cd]|slot_(deepseek|deepseekpro|kimi|kimicode|sonnet|opus|openai))\z') {
      # Only the opening fixed block can opt a folder back in. Later prose and older runs never change the profile.
      $snapshot = Read (Join-Path $out 'validated_issue.json')
      $fixed = [regex]::Match(($snapshot | ConvertFrom-Json).body, $fixedBlockPattern).Value
      $excluded = @(Code-CheckoutExclusions $fixed)
      $patterns = @(Code-CheckoutPatterns $excluded)
      if ($excluded.Count) { Log "code checkout excludes: $($excluded -join ', ')" }
    }
    $source = 'https://github.com/rcbailey12/voidsworn'
    $mirror = Repo-Mirror
    if ($test) {
      if (-not $env:PC_TEST_SOURCE -or -not $env:PC_TEST_MIRROR) { throw 'test checkout requires PC_TEST_SOURCE and PC_TEST_MIRROR (no live network)' }
      $source = $env:PC_TEST_SOURCE
    }
    $parent = Split-Path -Parent $mirror
    $null = New-Item -ItemType Directory -Force -Path $parent
    $lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30); $said = $false
    while (-not $lock) {
      try { $lock = [IO.File]::Open("$mirror.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
      catch [IO.IOException] {
        if (-not $said) { Log 'waiting for the shared repo copy'; $said = $true }
        if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }
        Start-Sleep -Milliseconds 500
      }
    }
    try {
      if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) {
        Must-Git @('init','--bare',$mirror)
        Must-Git @('--git-dir',$mirror,'remote','add','--mirror=fetch','origin',$source)
      }
      $url = @(Git @('--git-dir',$mirror,'remote','get-url','origin'))
      if ($gitExit -ne 0 -or $url[0] -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }
      Retry-Git 'mirror fetch' @('--git-dir',$mirror,'-c','http.lowSpeedLimit=1000','-c','http.lowSpeedTime=60','fetch','--prune','origin')
      # The remote default branch may not yet be set by init --bare.
      Must-Git @('--git-dir',$mirror,'symbolic-ref','HEAD','refs/heads/main')
      $reuse = Can-ReuseRepo $repo $mirror $patterns
      if ($reuse) {
        # --prune: a reused slot must drop a branch GitHub deleted, or a rerun would continue its stale tip (Artoo on PR 1804).
        Retry-Git 'checkout fetch' @('-C',$repo,'fetch','--no-tags','--prune',$mirror,'+refs/heads/*:refs/remotes/origin/*')
      }
    } finally { $lock.Dispose() }
    # A pinned lane must not hold the shared mirror lock for the ten-minute preservation wait.
    if (-not $reuse) { Keep-Repo $repo 'kept' }
    Warn-KeptRepos $repo
    $delay = 120; if ($test -and $env:PC_TEST_RETRY_SECONDS) { $delay = [int]$env:PC_TEST_RETRY_SECONDS }
    for ($attempt = 1; -not $reuse -and $attempt -le 3; $attempt++) {
        Log "local clone attempt $attempt/3"
        # Reacquire around each local clone: mirror fetch and hardlink cloning must still serialize.
        $lock = $null
        while (-not $lock) {
          try { $lock = [IO.File]::Open("$mirror.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
          catch [IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }
            Start-Sleep -Milliseconds 500
          }
        }
        try { $null = Git @('clone','-q','-c','core.autocrlf=false','--local','--no-checkout',$mirror,$repo) }
        finally { $lock.Dispose() }
        if ($gitExit -eq 0) { break }
        Keep-Repo $repo 'clone-failed'
        if ($attempt -eq 3) { throw 'local clone failed after 3 attempts; see git_log.txt' }
        Log "local clone failed; retry in $delay seconds"; Start-Sleep -Seconds $delay
    }
    # Local hardlinks share immutable objects without alternates. All pushes go to GitHub, never to the mirror.
    Must-Git @('-C',$repo,'remote','set-url','origin',$source)
    if (-not $reuse -and $patterns.Count) {
      # Write the patterns file and settings directly; the checkout below applies them. Passing '/*' as an argument let
      # PowerShell on Linux expand it into root folders, which left out every file (issue 1186, CI).
      Must-Git @('-C',$repo,'config','core.sparseCheckout','true')
      Must-Git @('-C',$repo,'config','core.sparseCheckoutCone','false')
      $null = [IO.Directory]::CreateDirectory((Join-Path $repo '.git/info'))
      Put (Join-Path $repo '.git/info/sparse-checkout') (($patterns -join "`n") + "`n")
    }
    # Issue 1739 (1747 run 2): a rerun started from main alone and its commit kept the earlier tip only as a second
    # parent, so the branch lost run 1's fixes. When the delivery branch already exists, the run starts from its tip
    # and main is merged on top; Base and -partial merges follow as before.
    $start = 'refs/remotes/origin/main'
    $earlier = @(Git @('-C',$repo,'rev-parse','--verify','--quiet',"refs/remotes/origin/$br^{commit}"))
    $continuing = $gitExit -eq 0 -and $earlier.Count -and $earlier[0] -match '^[0-9a-f]{40,64}$'
    if ($continuing) { $start = "refs/remotes/origin/$br" }
    $null = Git @('-C',$repo,'checkout','--no-overwrite-ignore','-q','-B',$br,$start)
    $switchExit = $gitExit
    if ($reuse) {
      # A writer may have changed the checkout after eligibility. Stop without discarding its bytes.
      try { $null = Reuse-Caches $repo }
      catch { throw "checkout changed while starting; kept as is: $($_.Exception.Message)" }
    }
    if ($switchExit -ne 0) { throw "git checkout failed (exit $switchExit); see git_log.txt" }
    if ($reuse -and $script:reuseProfileChange) {
      try { Set-RunnerSparseProfile $repo $patterns }
      catch { throw "checkout profile change failed; kept as is: $($_.Exception.Message)" }
      $shown = if (@($patterns).Count) { "leaves out $((@($codeCheckoutDirs | Where-Object { @($patterns) -ccontains "!/$_/" })) -join ', ')" } else { 'full checkout' }
      Log "sparse checkout profile changed in place ($shown); no tracked edit or untracked file was in a folder it leaves out"
    }
    if ($reuse) { Log 'earlier checkout reused in place; ignored files left in place' }
    $base = @(Git @('-C',$repo,'rev-parse','HEAD'))[0]
    Put (Join-Path $out 'base_commit.txt') $base
    if ($continuing) {
      if ($base -ne $earlier[0]) { throw "checkout of the earlier tip of $br did not land on $($earlier[0]); no agent started" }
      Put (Join-Path $out 'branch_tip.txt') $earlier[0]
      Log "continuing $br from its earlier tip $($earlier[0]), not from main alone (issue 1739)"
      $note = "Continued from the earlier tip of $br ($($earlier[0])): the earlier runs' work is already in this checkout. Keep it; do not restart from main."
      $null = Git @('-C',$repo,'merge-base','--is-ancestor','refs/remotes/origin/main','HEAD')
      if ($gitExit -eq 1) {
        $null = Git @('-C',$repo,'-c','commit.gpgsign=false','merge','--no-ff','--no-edit','--no-gpg-sign','-m',"Runner: origin/main into the earlier tip of $br",'refs/remotes/origin/main')
        if ($gitExit -ne 0) { throw "main merge into the earlier tip of $br failed; checkout and conflict kept; no agent started (see git_log.txt)" }
        $note += ' The runner merged origin/main on top and committed the merge.'
      } elseif ($gitExit -ne 0) { throw "could not tell whether main is in the earlier tip of $br; no agent started" }
      $resume = Read (Join-Path $out 'resume.txt')
      Put (Join-Path $out 'resume.txt') ("$resume`n$note".Trim())
      Log $note
    }
    $partial = "refs/remotes/origin/$br-partial"
    $tip = @(Git @('-C',$repo,'rev-parse','--verify','--quiet',$partial))
    if ($gitExit -eq 0) {
      $null = Git @('-C',$repo,'merge-base','--is-ancestor',$tip[0],'HEAD')
      if ($gitExit -eq 0) {
        Log "skipping $br-partial at $($tip[0]): already in HEAD"
        exit 0
      }
      Log "resuming $br-partial at $($tip[0])"
      # Full mirror history makes the merge base available. A conflict stays on disk and stops before the model.
      $null = Git @('-C',$repo,'merge','--no-edit',$partial)
      if ($gitExit -ne 0) { throw "resume merge failed for $br-partial; checkout and conflict kept; no agent started" }
      $resume = "Resumed by merging $br-partial ($($tip[0])). Inspect and finish this work; do not restart it from main."
      $message = (Git @('-C',$repo,'log','-1','--format=%B',$partial)) -join "`n"
      $note = [regex]::Match($message, '(?ms)^## Runner resume note \(issue 818\)\r?\n.*?^## End runner resume note')
      if ($note.Success) { $resume += "`n`n" + $note.Value }
      # Keep the continuation note written above (issue 1739).
      $earlierNote = Read (Join-Path $out 'resume.txt')
      Put (Join-Path $out 'resume.txt') ("$earlierNote`n$resume".Trim())
    }
  }
  elseif ($mode -eq 'base') {
    $repo = $args[1]; $script:out = $args[2]
    $body = [IO.File]::ReadAllText($args[3])
    $lines = @(Find-BaseLines $body)
    if ($lines.Count -eq 0) { exit 0 }
    if ($lines.Count -ne 1) { throw 'Base merge stopped: use one Base: <branch> line; no agent started' }
    $base = $lines[0].Groups[1].Value.Trim()
    $null = Git @('check-ref-format',"refs/heads/$base")
    if (-not $base -or $gitExit -ne 0) { throw "Base merge stopped: invalid branch '$base'; no agent started" }
    Log "Base: fetching and merging origin/$base before the agent"
    Retry-Git 'Base fetch' @('-C',$repo,'fetch','--no-tags','origin',"+refs/heads/${base}:refs/remotes/origin/$base")
    $tip = @(Git @('-C',$repo,'rev-parse',"refs/remotes/origin/$base"))[0]
    # --no-ff makes the runner commit a real merge even when a fast-forward is possible. No editor or signing prompt.
    $null = Git @('-C',$repo,'-c','commit.gpgsign=false','merge','--no-ff','--no-edit','--no-gpg-sign','-m',"Runner Base: origin/$base", "refs/remotes/origin/$base")
    if ($gitExit -ne 0) { throw "Base merge failed for origin/$base; checkout and conflict kept; no agent started (see git_log.txt)" }
    $note = "Base already merged by the runner: origin/$base ($tip). The merge is committed; do not merge it yourself."
    $resume = Read (Join-Path $out 'resume.txt')
    Put (Join-Path $out 'resume.txt') ("$resume`n$note".Trim())
    Log $note
  }
  elseif ($mode -eq 'board-dryrun') {
    $script:out = $args[1]
    $null = New-Item -ItemType Directory -Force -Path $out
    $script:boardReadOnly = $true
    if ($test -and (-not $env:PC_TEST_GH -or -not $env:PC_TEST_GH_DB)) { throw 'test board audit requires fake gh and PC_TEST_GH_DB' }
    $issues = @(Gh-Pages 'issues?state=open&per_page=100')
    $pulls = @(Gh-Pages 'pulls?state=open&per_page=100')
    $branches = @(Gh-Pages 'branches?per_page=100')
    $report = @("Board dry run (UTC): $([DateTime]::UtcNow.ToString('o')); no claims or agent calls")
    foreach ($i in ($issues | Sort-Object number)) {
      if ($i.pull_request -or $i.state -ne 'open') { continue }
      $seats = @($i.labels | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Where-Object { $_ -in @('codex','muse','opus') })
      foreach ($prefix in $seats) {
        try {
          $null = Validate-Job $i ([string]$i.number) $prefix $pulls $branches
          $report += "#$($i.number) [$prefix] ACCEPT"
        } catch { $report += "#$($i.number) [$prefix] REFUSE: $($_.Exception.Message)" }
      }
    }
    Put (Join-Path $out 'board_audit.txt') (($report -join "`n") + "`n")
    $report | ForEach-Object { Log $_ }
    exit 0
  }
  elseif ($mode -eq 'announce') {
    $script:out = $args[1]
    $issue = $args[2]
    if ($issue -notmatch '^[1-9][0-9]*$') { throw 'invalid job issue number; no agent started' }
    if ($test -and (-not $env:PC_TEST_GH -or -not $env:PC_TEST_GH_DB)) { throw 'test claim requires fake gh and PC_TEST_GH_DB (no live GitHub); no agent started' }
    $lock = $null
    if (($args[7] -eq 'real' -or $test) -and $env:PC_RUNNER_LOCKED_ISSUE -ne $issue) { $lock = Issue-Lock $issue }
    try {
      $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
      $repo = $args[4]
      $i = Require-Gh 'GET' "issues/$issue"
      if ($i.state -ne 'open' -or $i.pull_request) { throw "job refused: issue #$issue is not an open job (state: $($i.state)); no agent started" }
      if (@($i.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count) { throw "job refused: issue #$issue already carries running; another run owns the claim; no agent started" }
      $launchBranch = $args[8]
      if (-not $launchBranch) { $launchBranch = $s.branch }
      $pulls = @(Gh-Pages 'pulls?state=open&per_page=100')
      $branches = @(Gh-Pages 'branches?per_page=100')
      $body = Validate-Job $i $issue $args[3] $pulls $branches $launchBranch
      $comments = @(Gh-Pages "issues/$issue/comments?per_page=100")
      # Snapshot exactly what was validated. Prep must never re-fetch a possibly changed or older brief.
      Put (Join-Path $out 'validated_issue.json') (@{ number = $issue; title = $i.title; body = $body; run = $s.run } | ConvertTo-Json)
      $s | Add-Member -NotePropertyName instruction_run -NotePropertyValue $s.run -Force
      Save-State $s
      # Dry runs validate read-only. Only fixture tests may write to their fake GitHub.
      if ($args[7] -ne 'real' -and -not $test) { Log "job validated: issue #$issue (dry run, no claim written)"; exit 0 }
      $head = @($branches | Where-Object { $_.name -eq 'main' } | ForEach-Object { $_.commit.sha }) -join ''
      # Issue 947: the public status comment names the lane, never the machine or a PC path (folder stays in local state only).
      $lane = switch ((Split-Path -Leaf (Split-Path -Parent $repo)).ToLowerInvariant()) { 'board' { 'main' } 'board_b' { 'B' } 'board_c' { 'C' } 'board_d' { 'D' } default { 'other' } }
      $g = @{ issue = $issue; seat = $args[3]; folder = $repo; lane = $lane;
        started = [DateTime]::UtcNow.ToString('o'); ceiling = $args[5]; resume = $args[6]; comment = 0;
        start_commit = $head; claimed = $false; marker = "<!-- voidsworn-runner-status branch=$($s.branch) -->" }
      $s | Add-Member -NotePropertyName github -NotePropertyValue $g -Force
      Save-State $s
      $null = Invoke-Gh 'GET' 'labels/running'
      if (-not $ghOK) { $null = Require-Gh 'POST' 'labels' @{ name = 'running'; color = '1D76DB'; description = 'An agent is working this issue' } }
      $null = Require-Gh 'POST' "issues/$issue/labels" @{ labels = @('running') }
      $g.claimed = $true
      # Reuse this branch's comment on retries instead of adding a new comment every run.
      try {
        foreach ($comment in $comments) { if (([string]$comment.body).StartsWith($g.marker)) { $g.comment = $comment.id } }
        $payload = @{ body = (Status-Body $s 'running' '') }
        if ($g.comment) { $null = Require-Gh 'PATCH' "issues/comments/$($g.comment)" $payload }
        else { $reply = Require-Gh 'POST' "issues/$issue/comments" $payload; $g.comment = $reply.id }
        if (-not $g.comment) { throw 'claim comment has no id; no agent started' }
        $claimedIssue = Require-Gh 'GET' "issues/$issue"
        $claimedComment = Require-Gh 'GET' "issues/comments/$($g.comment)"
        if (-not @($claimedIssue.labels | Where-Object { $_.name -eq 'running' -or $_ -eq 'running' }).Count -or
          -not ([string]$claimedComment.body).StartsWith($g.marker) -or -not ([string]$claimedComment.body).Contains("- Run: $($s.run)")) {
          throw 'claim did not land: running label and owned status comment must read back; no agent started'
        }
        Save-State $s
      } catch {
        # Still under the issue lock: no other local seat can have acquired this label in between.
        $null = Invoke-Gh 'DELETE' "issues/$issue/labels/running"
        $g.claimed = $false; Save-State $s
        throw
      }
      Log "job claimed: issue #$issue by $($g.seat), run $($s.run); current instruction validated"
    } finally { if ($lock) { $lock.Dispose() } }
    exit 0
  }
  elseif ($mode -eq 'fetch') {
    $repo = $args[1]; $script:out = $args[2]
    Retry-Git 'branch fetch' @('-C',$repo,'fetch','-q','origin',$args[3])
  }
  elseif ($mode -eq 'preflight') {
    $script:out = $args[1]; $repo = $args[2]; $kind = $args[3]; $exe = $args[4]; $model = $args[5]; $variant = $args[6]
    $probe = Join-Path $out 'preflight'; $null = New-Item -ItemType Directory -Force -Path $probe
    $prompt = 'Reply with exactly RUNNER_READY. Do not use tools or read any files.'
    switch ($kind) {
      'opencode' { $words = @('run','--auto','--format','json','-m',$model,'--dir',$probe); if ($variant) { $words += @('--variant',($variant -replace '^--variant\s+','')) }; $words += $prompt }
      'kimi' { $words = @('-m',$model,'--output-format','text','-p',$prompt) }
      'codex' { $words = @('exec','-m',$model,'-c','model_reasoning_effort=low','--ephemeral','--skip-git-repo-check','--color','never','-C',$probe,'-o',(Join-Path $probe 'reply.txt'),$prompt) }
      default { throw "unknown preflight harness $kind" }
    }
    if ($test -and $env:PC_TEST_PREFLIGHT) { $exe = $env:PC_TEST_PREFLIGHT }
    Log "preflight: $kind $model"
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $exe; $psi.Arguments = ($words | ForEach-Object { Quote $_ }) -join ' '
    if ($exe -match '\.(cmd|bat)$') { $psi.FileName = $env:COMSPEC; $psi.Arguments = '/d /s /c ""' + $exe + '" ' + $psi.Arguments + '"' }
    $psi.WorkingDirectory = $probe; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    # The probe must use the same verified kill as an agent, including when taskkill cannot enumerate its tree.
    . (Join-Path $PSScriptRoot 'run_timeout.ps1') -LibraryOnly
    Initialize-RunTree
    $p = New-Object Diagnostics.Process; $p.StartInfo = $psi
    $null = $p.Start(); $stdout = $p.StandardOutput.ReadToEndAsync(); $stderr = $p.StandardError.ReadToEndAsync()
    $null = $p.Handle
    $tree = @{}; $tree[$p.Id] = $p
    try {
    $cap = 90; if ($test -and $env:PC_TEST_PREFLIGHT_SECONDS) { $cap = [int]$env:PC_TEST_PREFLIGHT_SECONDS }
    if (-not $p.WaitForExit($cap * 1000)) {
      Stop-RunTree $p $tree (Join-Path $out 'preflight_kill_log.txt')
      Put (Join-Path $out 'preflight_log.txt') ($stdout.Result + "`n" + $stderr.Result)
      throw "preflight failed: $kind timed out after $cap seconds"
    }
    $p.WaitForExit(); $code = $p.ExitCode
    } finally {
      Update-RunTree $tree
      if (@($tree.Values | Where-Object { -not $_.HasExited }).Count) { Stop-RunTree $p $tree (Join-Path $out 'preflight_kill_log.txt') }
      foreach ($child in $tree.Values) { $child.Dispose() }
    }
    $raw = $stdout.Result + "`n" + $stderr.Result
    Put (Join-Path $out 'preflight_log.txt') $raw
    $reply = Read (Join-Path $probe 'reply.txt')
    if ($kind -eq 'kimi') {
      # Kimi Code prints its thinking and its answer as bullet lines, then a 'To resume this session' line (first live run,
      # Nov 15): the reply is the answer line, bullet stripped.
      $reply = ''
      foreach ($line in ($stdout.Result -split '\r?\n')) { $t = ($line -replace '^[^A-Za-z0-9_]+','').Trim(); if ($t -eq 'RUNNER_READY') { $reply = $t } }
    }
    if ($kind -eq 'opencode') {
      $reply = ''
      foreach ($line in ($stdout.Result -split '\r?\n')) {
        try { $ev = $line | ConvertFrom-Json; if ($ev.type -eq 'text') { $reply += [string]$ev.part.text } } catch { }
      }
    }
    $problem = @($raw -split '\r?\n' | Where-Object { $_ -match '(?i)"type"\s*:\s*"error"|"is_error"\s*:\s*true|credit balance|no credential|not logged|unauthori[sz]ed|quota|rate.limit|expired|error:|"error"\s*:' } | Select-Object -Last 1)
    if ($code -ne 0 -or $problem.Count -or $reply.Trim() -ne 'RUNNER_READY') {
      $why = if ($problem.Count) { $problem[0] } else { @($raw -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -Last 1) -join '' }
      $why = ($why -replace '\s+',' ').Trim(); if ($why.Length -gt 350) { $why = $why.Substring(0,350) }
      throw "preflight failed: $kind exit $code; $why (see preflight_log.txt)"
    }
    Log "preflight passed: $kind $model"
  }
  elseif ($mode -eq 'space') {
    # Issue 722 (audit 706 finding 7): never start a run the disk cannot hold. Runs before the chain wait, so a
    # low disk also fails a chained child closed instead of burning a wait.
    $script:out = $args[1]; $setf = $args[2]; $target = $args[3]
    if ($test -and $env:PC_TEST_SETTINGS) { $setf = $env:PC_TEST_SETTINGS }
    $floor = 60; $janitorFloor = 150
    if (Test-Path -LiteralPath $setf) {
      foreach ($l in [IO.File]::ReadAllLines($setf)) {
        $m = [regex]::Match($l, '^\s*min_free_gb\s*=\s*(\d+)\s*$')
        if ($m.Success) { $floor = [int]$m.Groups[1].Value }
        $m = [regex]::Match($l, '^\s*janitor_free_gb\s*=\s*(\d+)\s*$')
        if ($m.Success) { $janitorFloor = [int]$m.Groups[1].Value }
      }
    }
    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($target)).TrimEnd('\')
    $free = (New-Object IO.DriveInfo($root)).AvailableFreeSpace
    if ($test -and $env:PC_TEST_SPACE_FREE_MB) { $free = [int64]$env:PC_TEST_SPACE_FREE_MB * 1MB }
    if (-not $test -and $args[4] -eq 'real' -and $free -lt ($janitorFloor * 1GB)) {
      Log "drive $root is below janitor_free_gb=$janitorFloor; checking for automatic cleanup"
      try { & (Join-Path $PSScriptRoot 'janitor.ps1') --low-space }
      catch { Log "janitor could not start: $($_.Exception.Message)" }
      $free = (New-Object IO.DriveInfo($root)).AvailableFreeSpace
    }
    $freeGB = [math]::Round($free / 1GB, 1)
    if ($free -lt ($floor * 1GB)) {
      $why = "refusing to start: drive $root has $freeGB GB free, below the min_free_gb=$floor floor"
      Log $why
      State 'failed' $why
      exit 14
    }
    Log "drive $root has $freeGB GB free (min_free_gb floor $floor)"
  }
  elseif ($mode -eq 'hashwrite') {
    # The Board runs this right after copying the runner files to a PC tools folder; hashcheck then guards the copies.
    $tools = $args[1]; $hashf = $args[2]
    $names = @('codex_issue.bat','codex_issue.ps1','runner_common.ps1','work_issue.bat','work_issue.ps1','review_evidence.ps1','run_timeout.ps1','tmo.bat','gpu_slots.js','janitor.ps1','janitor_salvage.ps1','janitor.bat')
    $lines = @()
    foreach ($n in $names) {
      $p = Join-Path $tools $n
      if (-not (Test-Path -LiteralPath $p)) { throw "hashwrite: $p is missing" }
      $lines += ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower() + "  $n")
    }
    Put $hashf (($lines -join "`n") + "`n")
    Write-Host "hashes written to $hashf ($($names.Count) files)"
  }
  elseif ($mode -eq 'hashcheck') {
    # Issue 722 (audit 706 finding 6): the running copies must be what the Board copied. A drift or a missing
    # hashes file is a warning only: a run must never stop because the Board has not written hashes yet.
    $script:out = $args[1]; $tools = $args[2]; $hashf = $args[3]
    if ($test -and $env:PC_TEST_HASHES) { $hashf = $env:PC_TEST_HASHES }
    # Issue 1194 (Artoo on PR 1254): strict fails closed. A missing or empty manifest, or one that leaves out a guarded
    # file, stops the job as surely as a changed file.
    $strict = $args[4] -eq 'strict'
    function Stop-Strict($why) {
      Log "STOPPED: $why"
      if (Test-Path -LiteralPath (Join-Path $script:out 'status.json')) { State 'failed' "STOPPED: $why" }
      exit 14
    }
    if ($strict -and -not (Test-Path -LiteralPath $hashf)) { Stop-Strict "no hashes file at $hashf" }
    if (-not (Test-Path -LiteralPath $hashf)) {
      Log "WARNING: no Board hashes file at $hashf; the running runner copies are not checked"
      exit 0
    }
    $want = @{}
    foreach ($l in [IO.File]::ReadAllLines($hashf)) {
      $m = [regex]::Match($l, '^([0-9a-fA-F]{64})\s+(\S+)\s*$')
      if ($m.Success) { $want[$m.Groups[2].Value] = $m.Groups[1].Value.ToLower() }
    }
    if ($strict) {
      $required = @('tmo.bat', 'run_timeout.ps1', 'gpu_slots.js')
      if (Test-Path -LiteralPath (Join-Path $tools 'job_wrap.bat')) { $required += 'job_wrap.bat' }
      $absent = @($required | Where-Object { -not $want.ContainsKey($_) })
      if ($absent.Count) { Stop-Strict "the hashes file $hashf leaves out: $($absent -join ', ')" }
    }
    if ($want.Count -eq 0) { Log "WARNING: the Board hashes file $hashf has no entries; the running runner copies are not checked"; exit 0 }
    $bad = @()
    foreach ($n in ($want.Keys | Sort-Object)) {
      $p = Join-Path $tools $n
      if (-not (Test-Path -LiteralPath $p)) { $bad += "$n (missing)"; continue }
      if ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower() -ne $want[$n]) { $bad += $n }
    }
    if ($bad.Count) { Log "WARNING: these runner files differ from the Board-copied hashes: $($bad -join ', ')" }
    else { Log "runner files match the Board hashes ($($want.Count) checked)" }
    # Issue 1194: a job must not run a watchdog or slot reader other than the one the hashes name.
    $guarded = @('tmo.bat', 'run_timeout.ps1', 'gpu_slots.js', 'job_wrap.bat')
    $stop = @($bad | Where-Object { $guarded -contains ($_ -replace ' \(missing\)$', '') })
    if ($args[4] -eq 'strict' -and $stop.Count) {
      $why = "STOPPED: the watchdog or slot files differ from $($hashf): $($stop -join ', ')"
      Log $why
      if (Test-Path -LiteralPath (Join-Path $script:out 'status.json')) { State 'failed' $why }
      exit 14
    }
  }
  elseif ($mode -eq 'preflight-tools') {
    # Issue 1194: jobs found a missing ffmpeg or Pillow only after an hour on the GPU. Each tool: an explicit setting
    # first, then the PC's usual place. Nothing is installed or changed.
    $script:out = $args[1]
    $vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
    $null = [IO.Directory]::CreateDirectory($script:out)
    $report = Join-Path $script:out 'preflight.txt'
    $lines = @("tool preflight $([DateTime]::UtcNow.ToString('s'))Z")
    $sets = @()
    $missing = @()
    function Find-Exe($candidates, $command) {
      foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return (Get-Item -LiteralPath $c).FullName } }
      if ($command) {
        $found = Get-Command -Name $command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.Source }
      }
      return ''
    }
    foreach ($tool in @(([string]$args[2]) -split '[\s,;]+' | Where-Object { $_ })) {
      $name = $tool.ToLowerInvariant()
      $path = ''
      switch ($name) {
        'godot' {
          $listed = ''
          $pathFile = Join-Path $vt 'godot_path.txt'
          if (Test-Path -LiteralPath $pathFile) { $listed = ([IO.File]::ReadAllLines($pathFile) | Select-Object -First 1).Trim() }
          $path = Find-Exe @($env:GODOT_EXE, $listed, (Join-Path $vt 'godot\Godot_v4.7.2-stable_win64_console.exe')) ''
        }
        'blender' { $path = Find-Exe @($env:BLENDER_EXE, (Join-Path $vt 'blender\blender-4.5.14-windows-x64\blender.exe')) '' }
        'ffmpeg' { $path = Find-Exe @($env:FFMPEG_EXE, (Join-Path $vt 'ffmpeg\bin\ffmpeg.exe')) 'ffmpeg' }
        'node' { $path = Find-Exe @($env:NODE_EXE, (Join-Path $vt 'node\node.exe')) 'node' }
        'pil' {
          # Python with Pillow: ComfyUI's portable Python has it on this PC.
          $pythons = @($env:PIL_PYTHON, (Join-Path $env:USERPROFILE 'Downloads\ComfyUI_windows_portable\python_embeded\python.exe'))
          foreach ($py in $pythons) {
            if (-not $py -or -not (Test-Path -LiteralPath $py -PathType Leaf)) { continue }
            $ea = $ErrorActionPreference
            try {
              $ErrorActionPreference = 'Continue'
              $null = & $py -c 'import PIL' 2>&1
              if ($LASTEXITCODE -eq 0) { $path = (Get-Item -LiteralPath $py).FullName; break }
            } catch { } finally { $ErrorActionPreference = $ea }
          }
        }
        default { $lines += "MISSING ${name}: unknown tool name (known: godot, blender, ffmpeg, node, pil)"; $missing += $name; continue }
      }
      if ($path) {
        $lines += "found ${name}: $path"
        $sets += ('set "JW_' + $name.ToUpperInvariant() + '=' + $path + '"')
      } elseif ($name -ne $null -and $missing -notcontains $name) {
        $lines += "MISSING ${name}: set " + @{ godot = 'GODOT_EXE'; blender = 'BLENDER_EXE'; ffmpeg = 'FFMPEG_EXE'; node = 'NODE_EXE'; pil = 'PIL_PYTHON' }[$name] + ' or install it'
        $missing += $name
      }
    }
    if ($missing.Count) { $lines += "STOPPED: missing tools: $($missing -join ', ')" } else { $lines += 'all tools found' }
    [IO.File]::WriteAllText($report, (($lines -join "`r`n") + "`r`n"), $utf8)
    [IO.File]::WriteAllText((Join-Path $script:out 'tools.cmd'), ((@('@echo off') + $sets) -join "`r`n") + "`r`n", (New-Object Text.ASCIIEncoding))
    foreach ($l in $lines) { Write-Host $l }
    if ($missing.Count) { exit 2 }
    exit 0
  }
  elseif ($mode -eq 'model') {
    # Issue 722 (audit 706 finding 6): stamp what will actually run. The bat passes the resolved id and the arm's
    # built-in default, so a same-provider override (the gap the provider guard cannot see) warns here.
    $script:out = $args[1]; $resolved = $args[2]; $default = $args[3]
    $p = Join-Path $script:out 'status.json'
    $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
    $s | Add-Member -NotePropertyName model -NotePropertyValue $resolved -Force
    $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
    Put $tmp ($s | ConvertTo-Json)
    [IO.File]::Replace($tmp, $p, "$tmp.previous")
    Log "model: $resolved"
    if ($resolved -ne $default) { Log "WARNING: resolved model $resolved differs from the arm default $default" }
  }
  elseif ($mode -eq 'effort') {
    # Ryan, Nov 17 2026: the reasoning effort is the same on every model; stamp it beside the model so each run shows it.
    $script:out = $args[1]; $effort = $args[2]
    $p = Join-Path $script:out 'status.json'
    $s = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json
    $s | Add-Member -NotePropertyName effort -NotePropertyValue $effort -Force
    $tmp = "$p.$([guid]::NewGuid().ToString('N')).tmp"
    Put $tmp ($s | ConvertTo-Json)
    [IO.File]::Replace($tmp, $p, "$tmp.previous")
    Log "effort: $effort"
  }
  elseif ($mode -eq 'finish') {
    $script:out = $args[1]; $code = $args[2]; $partial = $args[3]; $push = $args[4]; $checks = $args[5]
    $old = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    $status = 'failed'; $reason = "runner exit $code"
    if ($old.status -eq 'failed' -and $old.reason) { $reason = $old.reason }
    if ($code -eq '0' -and -not $partial) {
      $commit = Read (Join-Path $out 'run_commit.txt')
      $confirmed = Read (Join-Path $out 'confirmed_commit.txt')
      if ($push -eq 'real' -and $checks -eq '1' -and $commit -match '^[0-9a-f]{40,64}$' -and $confirmed -eq $commit) { $status = 'checked_push'; $reason = 'non-partial push confirmed and runner checks passed' }
      else { $status = 'unverified'; $reason = 'dry/test push or checks did not pass; chain stays stopped' }
    }
    elseif ($partial) { $status = 'partial'; $reason = $partial }
    elseif ($code -eq '7') { $status = 'no_changes'; $reason = 'no changes pushed' }
    Log "runner status: $status ($reason)"
    if ($push -eq 'real') {
      try {
        if (Cleanup-Paused) { Log 'run cleanup skipped during the PC pause' }
        else {
          Complete-RunScratch $old.scratch ($status -notin @('checked_push','no_changes'))
          if ($status -eq 'checked_push' -and $args[6]) {
            $repo = [IO.Path]::GetFullPath($args[6])
            $board = Split-Path -Parent $repo
            if ($test -or ((Split-Path -Leaf $repo) -eq 'repo' -and (Split-Path -Leaf $board) -in @('board','board_b','board_c','board_d') -and
                (Split-Path -Parent $board) -eq (Join-Path $env:USERPROFILE 'Downloads/voidsworn_test'))) {
              Remove-OlderKeptRepos $board (Repo-Mirror)
            }
          }
        }
      } catch { Log "run cleanup stopped: $($_.Exception.Message)" }
    }
    State $status $reason
    # State is authoritative; reporting errors never change it or the runner exit code.
    $s = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
    End-Announcement $s
    exit 0
  }
  else { throw "unknown runner step $mode" }
} catch {
  if ($script:out) {
    Log $_.Exception.Message
    if (Test-Path (Join-Path $out 'status.json')) {
      State 'failed' $_.Exception.Message
      End-Announcement (Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json)
    }
  }
  else { Write-Host $_.Exception.Message }
  exit 14
}
exit 0
