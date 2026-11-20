# Refresh a lane's tools before its chain calls the runner. Windows PowerShell 5.1.
# Issue 1194: -Build build refreshes the main queue's build\tools (the watcher runs it between jobs), and -Build tools_live
# installs the one canonical tools copy every job and every tmo.bat uses: Downloads\voidsworn_test\tools_live\<version>\
# (a verified, never-edited copy of main's tools folder with its own hashes.txt) named by tools_live\current.txt.
# A new version never touches a running job's copy. Old lane backups and old tools_live versions rotate instead of
# stopping the refresh: an old backup goes only when every file in it is kept elsewhere, an old version only when it was
# replaced more than a day ago and no running process names it.
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('build_b', 'build_c', 'build_d', 'build_e', 'work217', 'build', 'tools_live')]
  [string]$Build
)

$ErrorActionPreference = 'Stop'
$Build = $Build.ToLowerInvariant()
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$seat = @{ build_b = 'board'; build_c = 'board_b'; build_d = 'board_c'; build_e = 'board_d'; work217 = 'work217'; build = 'build'; tools_live = 'tools_live' }[$Build]
$liveTools = Join-Path $root "$Build\tools"
$liveRoot = Join-Path $root 'tools_live'
$keepBackups = 3
# The watchdog, slot and step helper files a job runs; hashcheck strict stops a job when one differs (issue 1194).
$hashedFiles = @('tmo.bat', 'run_timeout.ps1', 'gpu_slots.js', 'job_wrap.bat', 'runner_common.ps1', 'jobs\opus_job_head.bat', 'jobs\opus_job_head.ps1')
$logPath = Join-Path $root 'lane_tools_refresh.txt'
$sourceRoot = Join-Path $root 'lane_tools_source'
$sourceRepo = Join-Path $sourceRoot 'main.git'
$backupRoot = Join-Path $root 'runner_backups'
$origin = 'https://github.com/rcbailey12/voidsworn.git'
$ref = 'refs/remotes/origin/main'

function Write-Step([string]$Message) {
  $line = '{0:yyyy-MM-ddTHH:mm:ssZ} {1} {2}' -f [DateTime]::UtcNow, $Build, $Message
  [IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine)
  Write-Host $line
}

function Assert-IdleLane {
  # tools_live versions are never edited in place, so a running job is never in the way.
  if ($seat -eq 'tools_live') { return }
  if ($seat -eq 'build') {
    # The main queue runs its jobs from build\; the watcher refreshes between jobs, so any running job refuses.
    $running = Join-Path $root 'queue\running'
    if ((Test-Path -LiteralPath $running) -and @(Get-ChildItem -LiteralPath $running -File -Filter '*.bat').Count) {
      throw "refused: a queue job is still running in $running"
    }
    return
  }
  $seatRoot = Join-Path $root $seat
  $statusFiles = foreach ($issue in Get-ChildItem -LiteralPath $seatRoot -Directory -Filter 'issue-*') {
    if ($seat -eq 'work217') {
      if ($issue.Name -notmatch '^issue-\d+-[a-z0-9]+$') { continue }
      foreach ($run in Get-ChildItem -LiteralPath $issue.FullName -Directory) {
        if ($run.Name -match '^\d{8}_\d{6}$') { Join-Path $run.FullName 'out\status.json' }
      }
    } elseif ($issue.Name -match '^issue-\d+$') {
      Join-Path $issue.FullName 'status.json'
    }
  }
  foreach ($file in $statusFiles) {
    if (-not (Test-Path -LiteralPath $file)) { continue }
    try {
      $state = [IO.File]::ReadAllText($file) | ConvertFrom-Json
      if (-not $state.status) { throw 'missing status' }
    } catch {
      throw "refused: cannot verify runner status at $file"
    }
    if ($state.status -eq 'running') { throw "refused: job still running at $file" }
  }
}

function Invoke-SourceGit([string]$Step, [string[]]$Arguments) {
  # The only remote is public. Suppress native output and prevent credential helpers and prompts.
  $ErrorActionPreference = 'Continue'
  $output = & git.exe -c credential.helper= -c core.autocrlf=false -c http.sslBackend=openssl -c maintenance.auto=false -c gc.auto=0 @Arguments 2>$null
  if ($LASTEXITCODE -ne 0) { throw "$Step failed (git exit $LASTEXITCODE)" }
  return $output
}

function Assert-PlainPath($Item) {
  if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw "refused: linked path at $($Item.FullName)"
  }
}

function Get-ToolFiles([string]$Directory) {
  Assert-PlainPath (Get-Item -LiteralPath $Directory -Force)
  foreach ($item in Get-ChildItem -LiteralPath $Directory -Force) {
    Assert-PlainPath $item
    if ($item.PSIsContainer) { Get-ToolFiles $item.FullName } else { $item }
  }
}

function Test-ToolsMatch([string]$Target, [string]$Source, $SourceFiles) {
  $targetByPath = @{}
  foreach ($file in Get-ToolFiles $Target) { $targetByPath[$file.FullName.Substring($Target.Length + 1)] = $file }
  foreach ($file in $SourceFiles) {
    $current = $targetByPath[$file.FullName.Substring($Source.Length + 1)]
    if (-not $current -or $current.Length -ne $file.Length -or
      (Get-FileHash -LiteralPath $current.FullName).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
      return $false
    }
  }
  return $true
}

function Write-Hashes([string]$Version) {
  $lines = foreach ($name in $hashedFiles) {
    $file = Join-Path $Version "pc\$name"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
      if ($name -in @('tmo.bat', 'run_timeout.ps1', 'gpu_slots.js')) { throw "tools copy has no pc\$name" }
      continue
    }
    (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() + "  $name"
  }
  [IO.File]::WriteAllText((Join-Path $Version 'hashes.txt'), (($lines -join "`n") + "`n"))
}

function Test-Hashes([string]$Version) {
  $hashFile = Join-Path $Version 'hashes.txt'
  if (-not (Test-Path -LiteralPath $hashFile -PathType Leaf)) { return $false }
  $count = 0
  $listed = @()
  foreach ($line in [IO.File]::ReadAllLines($hashFile)) {
    if ($line -notmatch '^([0-9a-f]{64})  (\S+)$') { continue }
    $name = $Matches[2]
    $file = Join-Path $Version "pc\$name"
    $want = $Matches[1]
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $false }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $want) { return $false }
    $count++
    $listed += $name
  }
  # Every guarded file the version holds must be listed (a partial manifest is not a pass).
  foreach ($name in $hashedFiles) {
    if ((Test-Path -LiteralPath (Join-Path $Version "pc\$name") -PathType Leaf) -and $listed -notcontains $name) { return $false }
  }
  return $count -ge 3
}

function Get-RunningCommandLines {
  # $null means unknown: then nothing is treated as unused.
  try { return @(Get-CimInstance Win32_Process -ErrorAction Stop | ForEach-Object { [string]$_.CommandLine }) }
  catch { return $null }
}

function Remove-OldLiveVersions([string]$Current) {
  # Keep the current version, the newest few and anything replaced in the last day (a job resolves its version once at
  # its start and may run for hours). A version a running process names on its command line stays too.
  $versions = @(Get-ChildItem -LiteralPath $liveRoot -Directory -Force | Where-Object Name -Match '^[0-9a-f]{12}$' |
    Sort-Object CreationTimeUtc -Descending)
  if ($versions.Count -le ($keepBackups + 1)) { return }
  $commands = Get-RunningCommandLines
  if ($null -eq $commands) { Write-Step 'kept old tools_live versions: cannot list running processes'; return }
  for ($i = $keepBackups + 1; $i -lt $versions.Count; $i++) {
    $old = $versions[$i]
    if ($old.Name -eq $Current) { continue }
    $replaced = $versions[$i - 1].CreationTimeUtc
    if (([DateTime]::UtcNow - $replaced).TotalHours -lt 24) { continue }
    if (@($commands | Where-Object { $_ -and $_.IndexOf($old.FullName, [StringComparison]::OrdinalIgnoreCase) -ge 0 }).Count) {
      Write-Step "kept tools_live\$($old.Name): a running process uses it"
      continue
    }
    Assert-PlainPath $old
    $null = @(Get-ToolFiles $old.FullName)
    Remove-Item -LiteralPath $old.FullName -Recurse -Force
    Write-Step "rotated out tools_live\$($old.Name) (a verified copy of a main tools tree, replaced over a day ago)"
  }
}

function Get-FileKeys([string]$Directory) {
  # relative path (lower case) -> SHA-256
  $keys = @{}
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return $keys }
  foreach ($file in Get-ToolFiles $Directory) {
    $keys[$file.FullName.Substring($Directory.Length + 1).ToLowerInvariant()] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  }
  return $keys
}

function Test-KeptElsewhere([string]$Relative, [string]$Hash, $Copies, $Snapshots) {
  foreach ($copy in $Copies) { if ($copy[$Relative] -eq $Hash) { return $true } }
  foreach ($snap in $Snapshots) {
    $file = Join-Path $snap.FullName $Relative
    if ((Test-Path -LiteralPath $file -PathType Leaf) -and
      (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -eq $Hash) { return $true }
  }
  return $false
}

function Remove-OldBackups {
  # Keep the newest few backups. An older one goes only when every file in it, byte for byte at the same path, is also
  # in the live tools, a newer backup or a saved main snapshot, so nothing that exists only there is lost.
  $all = @(Get-ChildItem -LiteralPath $backupRoot -Directory -Force | Where-Object Name -Match "^${Build}_\d{8}_\d{6}$" |
    Sort-Object Name -Descending)
  if ($all.Count -le $keepBackups) { return }
  $copies = New-Object System.Collections.ArrayList
  $null = $copies.Add((Get-FileKeys $liveTools))
  foreach ($newer in $all[0..($keepBackups - 1)]) { $null = $copies.Add((Get-FileKeys (Join-Path $newer.FullName 'tools'))) }
  $snapshots = @(Get-ChildItem -LiteralPath $sourceRoot -Directory -Force | Where-Object Name -Match '^[0-9a-f]{40}$')
  for ($i = $keepBackups; $i -lt $all.Count; $i++) {
    $old = $all[$i]
    Assert-PlainPath $old
    $oldKeys = Get-FileKeys (Join-Path $old.FullName 'tools')
    $unique = 0
    foreach ($relative in $oldKeys.Keys) {
      if (-not (Test-KeptElsewhere $relative $oldKeys[$relative] $copies $snapshots)) { $unique++ }
    }
    $unique += @(Get-ChildItem -LiteralPath $old.FullName -Force | Where-Object Name -ne 'tools').Count
    if ($unique) {
      Write-Step "kept backup $($old.Name): it holds $unique files found nowhere else"
      $null = $copies.Add($oldKeys)
      continue
    }
    Remove-Item -LiteralPath $old.FullName -Recurse -Force
    Write-Step "rotated out backup $($old.Name) (every file is kept in a newer copy)"
  }
}

function Switch-LivePointer([string]$Pointer, [string]$Version) {
  # current.txt flips in one rename, so a reader sees the old version or the new one, never half of either. Returns the
  # version it named before. File.Replace needs a real null for "no backup": PowerShell turns $null into "" for a .NET
  # string parameter, which Windows rejects ("The path is not of a legal form"; the Nov 20 1180 install), so pass
  # [NullString]::Value. A .tmp left by an interrupted flip is harmless: each flip writes its own new name.
  $previous = if (Test-Path -LiteralPath $Pointer) { ([IO.File]::ReadAllText($Pointer)).Trim() } else { '' }
  if ($previous -eq $Version) { return $previous }
  $temp = "$Pointer.$([guid]::NewGuid().ToString('N')).tmp"
  [IO.File]::WriteAllText($temp, $Version + "`r`n")
  if (Test-Path -LiteralPath $Pointer) { [IO.File]::Replace($temp, $Pointer, [NullString]::Value) } else { [IO.File]::Move($temp, $Pointer) }
  if (([IO.File]::ReadAllText($Pointer)).Trim() -ne $Version) { throw "current.txt does not name $Version after the switch" }
  return $previous
}

function Copy-Tools([string]$From, [string]$To, [string]$Step) {
  & robocopy.exe $From $To /E /COPY:DAT /DCOPY:DAT /IS /IT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -lt 0 -or $LASTEXITCODE -ge 8) { throw "$Step failed (robocopy exit $LASTEXITCODE)" }
  Write-Step $Step
}

$lock = $null
$checkoutLock = $null
try {
  if ($seat -like 'board*') {
    $repo = Join-Path $root "$seat\repo"
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($repo))
    # codex_issue.ps1 holds this same lock through final reporting.
    try { $checkoutLock = [IO.File]::Open("$repo.checkout.lock", 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { throw 'refused: Codex checkout lock is busy or unavailable' }
  }
  # Serialize the shared fetch, snapshot, log and backup allocation across lanes. Keep the lock file.
  $lockPath = Join-Path $root 'lane_tools_refresh.lock'
  $lockDeadline = [DateTime]::UtcNow.AddMinutes(2)
  while (-not $lock) {
    try { $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] {
      $sharingViolation = ($_.Exception.HResult -band 0xFFFF) -eq 32
      if (-not $sharingViolation -or [DateTime]::UtcNow -ge $lockDeadline) { throw }
      Start-Sleep -Milliseconds 500
    }
  }

  Write-Step 'checking for running jobs'
  Assert-IdleLane
  if ($seat -ne 'tools_live') {
    Assert-PlainPath (Get-Item -LiteralPath (Split-Path -Parent $liveTools) -Force)
    if (-not (Test-Path -LiteralPath $liveTools -PathType Container)) { throw 'lane tools folder is missing' }
  }

  $env:GIT_CONFIG_NOSYSTEM = '1'
  $env:GIT_CONFIG_GLOBAL = 'NUL'
  $env:GIT_TERMINAL_PROMPT = '0'
  $env:GIT_NO_REPLACE_OBJECTS = '1'
  foreach ($directory in @($sourceRoot, $backupRoot)) {
    $null = [IO.Directory]::CreateDirectory($directory)
    Assert-PlainPath (Get-Item -LiteralPath $directory -Force)
  }
  if (-not (Test-Path -LiteralPath $sourceRepo)) {
    $null = Invoke-SourceGit 'create shared shallow source' @('init', '--bare', '--template=', $sourceRepo)
    Write-Step 'created shared shallow source'
  }
  Assert-PlainPath (Get-Item -LiteralPath $sourceRepo -Force)
  $gitRepo = @("--git-dir=$sourceRepo", '-c', "remote.origin.url=$origin", '-c', 'remote.origin.promisor=true')
  $fetch = $gitRepo + @('fetch', '--no-tags', '--no-auto-gc', '--no-recurse-submodules', '--filter=blob:none')
  $null = Invoke-SourceGit 'fetch origin/main' ($fetch + @('--depth=1', 'origin', "+refs/heads/main:$ref"))
  $commit = Invoke-SourceGit 'resolve origin/main' ($gitRepo + @('rev-parse', '--verify', "$ref^{commit}"))
  if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'invalid origin/main commit' }
  Write-Step "fetched origin/main $commit"

  # Codex installs tools\pc below tools; the workhorse runner sits directly in tools.
  $treePath = if ($Build -eq 'work217') { 'tools/pc' } else { 'tools' }
  $tree = Invoke-SourceGit 'resolve tools tree' ($gitRepo + @('rev-parse', '--verify', "${commit}:$treePath"))
  if ($tree -notmatch '^[0-9a-f]{40}$') { throw 'invalid origin/main tools tree' }
  $snapshot = Join-Path $sourceRoot $tree
  if (-not (Test-Path -LiteralPath $snapshot)) {
    # Git archive fetches missing blobs for this tree in one batch from the promisor remote.
    $export = Join-Path $sourceRoot "export-$([guid]::NewGuid().ToString('N'))"
    $archive = "$export.zip"
    $null = Invoke-SourceGit 'archive main tools' ($gitRepo + @('archive', '--format=zip', "--output=$archive", $tree))
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $export)
    [IO.Directory]::Move($export, $snapshot)
    Write-Step "saved tools snapshot $tree"
  }

  $runner = if ($Build -eq 'work217') { 'work_issue.bat' } elseif ($seat -like 'board*') { 'pc\codex_issue.bat' } else { 'pc\tmo.bat' }
  if (-not (Test-Path -LiteralPath (Join-Path $snapshot $runner) -PathType Leaf)) { throw 'main tools snapshot has no lane runner' }
  $sourceFiles = @(Get-ToolFiles $snapshot)

  if ($seat -eq 'tools_live') {
    $null = [IO.Directory]::CreateDirectory($liveRoot)
    Assert-PlainPath (Get-Item -LiteralPath $liveRoot -Force)
    $version = $tree.Substring(0, 12)
    $target = Join-Path $liveRoot $version
    if ((Test-Path -LiteralPath $target) -and -not (Test-Hashes $target)) {
      # An interrupted install: set it aside (never delete it) and install again.
      $aside = Join-Path $liveRoot "$version-incomplete-$([guid]::NewGuid().ToString('N'))"
      [IO.Directory]::Move($target, $aside)
      Write-Step "set aside incomplete tools_live\$version as $aside"
    }
    if (-not (Test-Path -LiteralPath $target)) {
      $staged = Join-Path $liveRoot "stage-$([guid]::NewGuid().ToString('N'))"
      Copy-Tools $snapshot $staged 'copied main tools to the tools_live stage'
      if (-not (Test-ToolsMatch $staged $snapshot $sourceFiles)) { throw 'staged tools_live copy failed verification' }
      Write-Hashes $staged
      [IO.Directory]::Move($staged, $target)
      Write-Step "installed tools_live\$version from origin/main $commit"
    }
    if (-not (Test-Hashes $target)) { throw "tools_live\$version does not match its hashes.txt" }
    # current.txt flips in one rename, so a reader sees the old version or the new one, never half of either.
    $previous = Switch-LivePointer (Join-Path $liveRoot 'current.txt') $version
    if ($previous -ne $version) {
      Write-Step "tools_live now uses $version (was $(if ($previous) { $previous } else { 'none' }))"
    } else { Write-Step "tools_live already uses $version" }
    try { Remove-OldLiveVersions $version } catch { Write-Step "kept old tools_live versions: $($_.Exception.Message)" }
    exit 0
  }
  if (Test-ToolsMatch $liveTools $snapshot $sourceFiles) {
    Assert-IdleLane
    Write-Step "tools already match origin/main $commit"
    exit 0
  }

  Assert-IdleLane
  $staged = Join-Path $sourceRoot "$Build-stage-$([guid]::NewGuid().ToString('N'))"
  Copy-Tools $liveTools $staged 'copied old tools to staging'
  Copy-Tools $snapshot $staged 'copied main tools to staging'
  if (-not (Test-ToolsMatch $staged $snapshot $sourceFiles)) { throw 'staged tools failed verification' }
  Write-Step 'verified staged tools'
  Assert-IdleLane

  # No live files are overwritten one by one. Keep the original directory as the dated backup.
  $backup = Join-Path $backupRoot ('{0}_{1:yyyyMMdd_HHmmss}' -f $Build, (Get-Date))
  $null = New-Item -ItemType Directory -Path $backup
  $original = Join-Path $backup 'tools'
  $activated = $false
  [IO.Directory]::Move($liveTools, $original)
  try {
    Write-Step "backed up tools to $backup"
    [IO.Directory]::Move($staged, $liveTools)
    $activated = $true
    Write-Step "installed origin/main $commit"
  } catch {
    $installError = $_
    try {
      if ($activated) { [IO.Directory]::Move($liveTools, $staged) }
      [IO.Directory]::Move($original, $liveTools)
    } catch { throw "restore failed, old tools kept at ${original}: $($_.Exception.Message)" }
    throw $installError
  }
  try { Remove-OldBackups } catch { Write-Step "kept old backups: $($_.Exception.Message)" }
} catch {
  $message = "FAILED: $($_.Exception.Message)"
  try { Write-Step $message } catch { Write-Host "$Build $message" }
  exit 1
} finally {
  if ($lock) { $lock.Dispose() }
  if ($checkoutLock) { $checkoutLock.Dispose() }
}
