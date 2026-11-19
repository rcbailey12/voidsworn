param(
  [string]$Install,
  [string]$Full,
  [string]$Review,
  [ValidateSet(10, 121)][int[]]$Seeds = @(121, 10)
)
$ErrorActionPreference = 'Stop'
$pc = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$repo = Split-Path (Split-Path (Split-Path $PSScriptRoot))
if (-not $Install) { $Install = Join-Path $pc 'build\export' }
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not $Full) { $Full = Join-Path $pc "shots\player_path_$stamp" }
if (-not $Review) { $Review = Join-Path $Full 'review' }
$Install = [IO.Path]::GetFullPath($Install)
$Full = [IO.Path]::GetFullPath($Full)
$Review = [IO.Path]::GetFullPath($Review)
$game = Join-Path $Install 'Voidsworn.console.exe'
$pack = Join-Path $Install 'Voidsworn.pck'
foreach ($file in @($game, $pack)) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing installed game file: $file" }
}
if (Test-Path -LiteralPath $Full) { throw "Choose a new full recording folder: $Full" }
New-Item -ItemType Directory -Path $Full | Out-Null
$go = Join-Path $pc 'gpu_go.txt'
$python = (Get-Content -LiteralPath (Join-Path $pc 'python_path.txt') -TotalCount 1).Trim()
$compose = Join-Path $PSScriptRoot 'compose.py'
& $python -B $compose --check
if ($LASTEXITCODE) { throw 'The recording encoder did not pass its preflight' }

$watch = [Diagnostics.Stopwatch]::StartNew()
$buildHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $pack).Hash.ToLowerInvariant()
$temp = Join-Path $env:TEMP ('voidsworn-player-path-' + [guid]::NewGuid())
$tmo = Join-Path $repo 'tools\pc\tmo.bat'
$keepAppData = $env:APPDATA
$keepLocalAppData = $env:LOCALAPPDATA
$gameOverrides = @(Get-ChildItem Env:VS_*)
$keepMode = $env:PC_GPU_MODE
$keepWeight = $env:PC_GPU_WEIGHT
$failures = @()
try {
  foreach ($entry in $gameOverrides) {
    [Environment]::SetEnvironmentVariable($entry.Name, $null, 'Process')
  }
  foreach ($seed in $Seeds) {
    if (-not (Test-Path -LiteralPath $go) -or (Get-Content -LiteralPath $go -TotalCount 1) -notmatch '^GPU cleared(?:$|:)') {
      throw "The GPU queue is paused. See $go"
    }
    $avi = Join-Path $Full "seed-$seed.avi"
    $trace = Join-Path $Full "seed-$seed.jsonl"
    foreach ($attempt in 1, 2) {
      $attemptPath = Join-Path $temp "seed-$seed-attempt-$attempt"
      $env:APPDATA = Join-Path $attemptPath 'profile'
      $env:LOCALAPPDATA = $env:APPDATA
      $env:VS_PLAYER_PATH_PROFILE = $env:APPDATA
      New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
      $env:PC_GPU_MODE = 'shared'
      $env:PC_GPU_WEIGHT = '1'
      $log = Join-Path $attemptPath 'launcher.log'
      $gameLog = Join-Path $attemptPath 'game.log'
      Write-Host "Recording seed $seed to $avi"
      $ErrorActionPreference = 'Continue'
      try {
        & $tmo 1800 $game --log-file $gameLog --resolution 1920x1080 --windowed --disable-vsync --fixed-fps 30 --write-movie $avi -- --player-path $trace --player-path-seed $seed 2>&1 | Out-File -LiteralPath $log -Encoding utf8
        $code = $LASTEXITCODE
      } finally { $ErrorActionPreference = 'Stop' }
      # The sector map builds in a background thread. A slow first load can miss the jump before Battle 1 starts.
      $startupTimeout = $code -and (Test-Path -LiteralPath $trace) -and
        (Select-String -LiteralPath $trace -Pattern '"battle":0.*"reason":"jump to 0-0 did not open"' -Quiet)
      if ($attempt -eq 2 -or -not $startupTimeout) { break }
      foreach ($file in @($avi, $trace)) {
        if (Test-Path -LiteralPath $file) { Move-Item -LiteralPath $file -Destination $attemptPath }
      }
      Write-Host "Retrying seed $seed after the first map jump timed out"
    }
    if ($code) {
      $failures += "Seed $seed failed. See $log and $gameLog"
      continue
    }
    if (-not (Test-Path -LiteralPath $avi) -or -not (Test-Path -LiteralPath $trace)) {
      $failures += "Seed $seed produced no recording. Check the installed recorder and $log"
      continue
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $pack).Hash.ToLowerInvariant() -ne $buildHash) {
      throw 'The installed build changed during the recording'
    }
    & $python -B $compose $Full $Review $temp $seed $buildHash
    if ($LASTEXITCODE) { $failures += "Seed $seed review encoding failed. Masters are in $Full" }
  }
} finally {
  $env:APPDATA = $keepAppData
  $env:LOCALAPPDATA = $keepLocalAppData
  $env:VS_PLAYER_PATH_PROFILE = $null
  foreach ($entry in $gameOverrides) {
    [Environment]::SetEnvironmentVariable($entry.Name, $entry.Value, 'Process')
  }
  $env:PC_GPU_MODE = $keepMode
  $env:PC_GPU_WEIGHT = $keepWeight
}
if ($failures.Count) { throw ($failures -join [Environment]::NewLine) }
"Full run: {0:N0} seconds" -f $watch.Elapsed.TotalSeconds | Tee-Object -FilePath (Join-Path $Full 'elapsed.txt')
Write-Host "Full 1080p recordings: $Full"
Write-Host "Review clips and sheets: $Review"
