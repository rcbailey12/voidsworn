# Refresh a lane's tools before its chain calls the runner. Windows PowerShell 5.1.
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('build_b', 'build_c', 'build_d', 'build_e', 'work217')]
  [string]$Build
)

$ErrorActionPreference = 'Stop'
$Build = $Build.ToLowerInvariant()
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$seat = @{ build_b = 'board'; build_c = 'board_b'; build_d = 'board_c'; build_e = 'board_d'; work217 = 'work217' }[$Build]
$liveTools = Join-Path $root "$Build\tools"
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

function Copy-Tools([string]$From, [string]$To, [string]$Step) {
  & robocopy.exe $From $To /E /COPY:DAT /DCOPY:DAT /IS /IT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -lt 0 -or $LASTEXITCODE -ge 8) { throw "$Step failed (robocopy exit $LASTEXITCODE)" }
  Write-Step $Step
}

$lock = $null
try {
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
  Assert-PlainPath (Get-Item -LiteralPath (Split-Path -Parent $liveTools) -Force)
  if (-not (Test-Path -LiteralPath $liveTools -PathType Container)) { throw 'lane tools folder is missing' }

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

  $runner = if ($Build -eq 'work217') { 'work_issue.bat' } else { 'pc\codex_issue.bat' }
  if (-not (Test-Path -LiteralPath (Join-Path $snapshot $runner) -PathType Leaf)) { throw 'main tools snapshot has no lane runner' }
  $sourceFiles = @(Get-ToolFiles $snapshot)
  if (Test-ToolsMatch $liveTools $snapshot $sourceFiles) {
    Assert-IdleLane
    Write-Step "tools already match origin/main $commit"
    exit 0
  }

  $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory -Filter "${Build}_*" -Force |
    Where-Object Name -Match "^${Build}_\d{8}_\d{6}$")
  if ($backups.Count -ge 3) { throw 'refused: three dated backups already exist for this lane' }

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
} catch {
  $message = "FAILED: $($_.Exception.Message)"
  try { Write-Step $message } catch { Write-Host "$Build $message" }
  exit 1
} finally {
  if ($lock) { $lock.Dispose() }
}
