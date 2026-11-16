# Run a program with a ceiling (PC watchdog). Agent runs also stop when progress stalls (issue 818).
# The program's output goes to this window (so "tmo.bat ... > log.txt 2>&1" captures it).
# Call it through tools\pc\tmo.bat <seconds> <exe> [args ...]: the bat hands the whole command line over in TMO_ARGS, so
# arguments that start with "-" or "--" reach the program untouched (PowerShell would read them as its own parameters).
param([switch]$LibraryOnly)
$ErrorActionPreference = 'Stop'

# runner_stall_tests.js runs this decision with fake clocks on Linux CI and probes real processes on Windows.
function Get-StopReason($Elapsed, $Idle, $Ceiling, $StallMinutes) {
  if ($Elapsed -ge $Ceiling) { return 'CEILING' }
  if ($Idle -ge ($StallMinutes * 60)) { return "STALLED after $StallMinutes min" }
  return ''
}
function Get-RunProgress($Repo, $Logs) {
  $files = @{}
  $dirs = New-Object 'System.Collections.Generic.Stack[string]'
  $dirs.Push($Repo)
  while ($dirs.Count) {
    foreach ($f in (Get-ChildItem -LiteralPath $dirs.Pop() -Force -ErrorAction SilentlyContinue)) {
      # Reading git status may touch its index; Git housekeeping must not keep a silent agent alive.
      # Do not follow junctions outside this run's checkout.
      if ($f.Name -eq '.git' -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
      if ($f.PSIsContainer) { $dirs.Push($f.FullName) }
      else { $files[$f.FullName] = "$($f.LastWriteTimeUtc.Ticks):$($f.Length)" }
    }
  }
  $head = (& git.exe -C $Repo rev-parse --verify HEAD 2>$null) -join ''
  $bytes = @{}
  foreach ($path in $Logs) {
    $f = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    $bytes[$path] = if ($f) { $f.Length } else { 0 }
  }
  return @{ Files = $files; Head = $head; Bytes = $bytes }
}
function Test-RunProgress($Before, $After) {
  if ($After.Head -and $After.Head -ne $Before.Head) { return $true }
  if ($After.Files.Count -ne $Before.Files.Count) { return $true }
  foreach ($key in $After.Files.Keys) {
    if (-not $Before.Files.ContainsKey($key) -or $Before.Files[$key] -ne $After.Files[$key]) { return $true }
  }
  foreach ($key in $After.Bytes.Keys) {
    if ($After.Bytes[$key] -gt $Before.Bytes[$key]) { return $true }
  }
  return $false
}
function Save-RunResume($Repo, $Out, $Logs, $Reason, $Base) {
  $utf8 = New-Object Text.UTF8Encoding($false)
  $changed = @(& git.exe --no-optional-locks -C $Repo -c core.quotepath=off diff --name-only $Base -- 2>$null)
  $changed += @(& git.exe --no-optional-locks -C $Repo -c core.quotepath=off ls-files --others --exclude-standard 2>$null)
  $changed = @($changed | Sort-Object -Unique)
  $note = "## Runner resume note (issue 818)`nStop reason: $Reason`n`nChanged files (from run base $Base):`n"
  if ($changed.Count) { $note += ($changed | ForEach-Object { "- $_" }) -join "`n" }
  else { $note += '(none)' }
  foreach ($path in $Logs) {
    $note += "`n`nLast log lines ($([IO.Path]::GetFileName($path))):`n"
    if (Test-Path -LiteralPath $path) {
      $tail = @(Get-Content -LiteralPath $path -Tail 12 -ErrorAction SilentlyContinue | ForEach-Object {
        $line = [string]$_; if ($line.Length -gt 400) { $line = $line.Substring(0, 400) + ' [cut]' }; $line
      })
      $note += $tail -join "`n"
    } else { $note += '(no output)' }
  }
  $note += "`n## End runner resume note`n"
  [IO.File]::WriteAllText((Join-Path $Out 'resume.txt'), $note, $utf8)
  [IO.File]::WriteAllText((Join-Path $Out 'stop_reason.txt'), $Reason, $utf8)
}
if ($LibraryOnly) { return }
$raw = $env:TMO_ARGS
if (-not $raw) { Write-Output 'usage: tmo.bat <seconds> <exe> [args ...]'; exit 125 }
$m = [regex]::Match($raw, '^\s*(\d+)\s+("([^"]+)"|(\S+))\s*(.*)$')
if (-not $m.Success) { Write-Output "run_timeout: cannot read the command line: $raw"; exit 125 }
$Seconds = [int]$m.Groups[1].Value
$Exe = if ($m.Groups[3].Success) { $m.Groups[3].Value } else { $m.Groups[4].Value }
$argLine = $m.Groups[5].Value
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$logDir = Join-Path $root 'queue\logs'
if (-not (Test-Path $logDir)) { $logDir = $PSScriptRoot }
$log = Join-Path $logDir 'timeouts.log'
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_TIMEOUT_LOG) { $log = $env:PC_TEST_TIMEOUT_LOG }
$watch = $env:TMO_REPO -and $env:TMO_OUT -and $env:TMO_LOG
$watchRepo = $env:TMO_REPO; $watchOut = $env:TMO_OUT
$stall = 30.0
if ($watch -and $env:STALL_MIN) { $stall = [double]::Parse($env:STALL_MIN, [Globalization.CultureInfo]::InvariantCulture) }
if ($Seconds -le 0 -or $stall -le 0 -or [double]::IsNaN($stall) -or [double]::IsInfinity($stall)) { throw 'ceiling and STALL_MIN must be positive' }
$logs = @($env:TMO_LOG, $env:TMO_ERR_LOG) | Where-Object { $_ }
if ($watch) {
  $before = Get-RunProgress $watchRepo $logs
  $base = $before.Head
  $bp = Join-Path $watchOut 'base_commit.txt'
  if (Test-Path -LiteralPath $bp) { $base = [IO.File]::ReadAllText($bp).Trim() }
}
# Nov 1: a test job ran all through Ryan's first Godot playtest, slowing the PC and overwriting the game's log.
# Wait while Ryan is playing: the game is Voidsworn.exe or a windowed Godot started with no job arguments
# (play_godot.bat passes none; every job passes --headless, --script, --bot or similar). Waiting is not timed.
function Test-RyanPlaying {
  try { $ps = Get-CimInstance Win32_Process -Filter "Name LIKE 'Voidsworn%.exe' OR Name LIKE 'Godot%.exe'" } catch { return $false }
  foreach ($q in $ps) {
    if ($q.Name -like '*_console.exe') { continue }
    $cl = [string]$q.CommandLine
    $rest = [regex]::Replace($cl, '^\s*("[^"]*"|\S+)', '')
    $rest = [regex]::Replace($rest, '--path\s+("[^"]*"|\S+)', '')
    if ($rest -notmatch '--?\w') { return $true }
  }
  return $false
}
$w0 = Get-Date; $said = $false
# Codex jobs are light (one model session, small node scripts) and do not touch the game's log: they run during play.
$noWait = ($Exe -match 'codex(\.cmd|\.exe)?$') -or ($env:PC_RUNNER_TEST -eq '1')
while ((-not $noWait) -and (Test-RyanPlaying) -and ((Get-Date) - $w0).TotalHours -lt 8) {
  if (-not $said) { Write-Output "run_timeout: the game is open, waiting until it closes"; "$(Get-Date -Format s) WAIT game open: $Exe" | Out-File $log -Append -Encoding utf8; $said = $true }
  Start-Sleep -Seconds 20
}
if ($said) { "$(Get-Date -Format s) RESUME after $([int]((Get-Date) - $w0).TotalMinutes) min: $Exe" | Out-File $log -Append -Encoding utf8 }
# R293: acquire only around the GPU command, never the whole model session.
# A pending solo claim drains all shared slots and blocks new workers.
$gpuHelper = Join-Path $PSScriptRoot 'gpu_slots.js'
$gpuNode = 'node.exe'
$bundledNode = Join-Path $root 'node\node.exe'
if (Test-Path -LiteralPath $bundledNode) { $gpuNode = $bundledNode }
$gpuRoot = $root
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_GPU_ROOT) { $gpuRoot = $env:PC_TEST_GPU_ROOT }
$gpuToken = ''
try {
$classify = @{ exe = $Exe; args = $argLine; cwd = (Get-Location).Path; requested = [string]$env:PC_GPU_MODE; weight = [string]$env:PC_GPU_WEIGHT } | ConvertTo-Json -Compress
$gpuClass = ($classify | & $gpuNode $gpuHelper classify) -join ''
if ($LASTEXITCODE -ne 0) { throw 'GPU command classification failed' }
$gpuClass = $gpuClass | ConvertFrom-Json
$gpuMode = $gpuClass.mode
if ($gpuMode) {
  Write-Output "GPU: waiting for $gpuMode claim, weight $($gpuClass.weight) (issue $env:PC_GPU_ISSUE)"
  & $gpuNode $gpuHelper acquire $gpuRoot ([string]$env:PC_GPU_ISSUE + ':gpu') $PID $gpuMode $gpuClass.weight | ForEach-Object {
    if ($_ -eq 'WAIT') { Write-Host "GPU: still waiting for $gpuMode claim" }
    else { $gpuToken = [string]$_ }
  }
  if ($LASTEXITCODE -ne 0 -or -not $gpuToken) { throw 'GPU claim failed; command was not started' }
  Write-Output "GPU: acquired $gpuMode claim $gpuToken"
}
# A forced claim applies to this command only, never a nested watchdog.
$env:PC_GPU_MODE = ''
$env:PC_GPU_WEIGHT = ''
$timer = [Diagnostics.Stopwatch]::StartNew()
$lastProgress = 0.0
$scanEvery = 60.0
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_SCAN_S) { $scanEvery = [double]$env:PC_TEST_SCAN_S }
$nextScan = $scanEvery
# Child commands may use tmo.bat too. Their own timeout must never overwrite this agent's resume note.
$env:TMO_REPO = ''; $env:TMO_OUT = ''; $env:TMO_LOG = ''; $env:TMO_ERR_LOG = ''
try {
  if ($argLine -ne '') { $p = Start-Process -FilePath $Exe -ArgumentList $argLine -NoNewWindow -PassThru }
  else { $p = Start-Process -FilePath $Exe -NoNewWindow -PassThru }
} catch {
  "$(Get-Date -Format s) START FAILED $Exe $argLine : $_" | Out-File $log -Append -Encoding utf8
  Write-Output "run_timeout: could not start $Exe : $_"
  exit 125
}
$null = $p.Handle   # keeps the exit code readable after the process ends
$poll = 5000
if ($env:PC_RUNNER_TEST -eq '1' -and $env:PC_TEST_POLL_MS) { $poll = [int]$env:PC_TEST_POLL_MS }
while ($true) {
  $remaining = [Math]::Max(1, [Math]::Min($poll, ($Seconds - $timer.Elapsed.TotalSeconds) * 1000))
  if ($p.WaitForExit([int]$remaining)) { $p.WaitForExit(); exit $p.ExitCode }
  if ($watch) {
    # Scan the checkout once a minute, not every poll: a full walk of a big checkout every 5 s would load Ryan's PC for hours,
    # and a 30 minute stall window does not need finer steps (Board review, Nov 15).
    if ($timer.Elapsed.TotalSeconds -ge $nextScan) {
      $after = Get-RunProgress $watchRepo $logs
      if (Test-RunProgress $before $after) { $lastProgress = $timer.Elapsed.TotalSeconds }
      $before = $after
      $nextScan = $timer.Elapsed.TotalSeconds + $scanEvery
    }
    $reason = Get-StopReason $timer.Elapsed.TotalSeconds ($timer.Elapsed.TotalSeconds - $lastProgress) $Seconds $stall
  } else {
    $reason = if ($timer.Elapsed.TotalSeconds -ge $Seconds) { 'CEILING' } else { '' }
  }
  if ($p.HasExited) { $p.WaitForExit(); exit $p.ExitCode }
  if ($reason) { break }
}
$secs = [int]$timer.Elapsed.TotalSeconds
& taskkill.exe /PID $p.Id /T /F | Out-Null
if ($watch) { Save-RunResume $watchRepo $watchOut $logs $reason $base }
"$(Get-Date -Format s) TIMEOUT $reason after $secs s (ceiling $Seconds s), killed tree of PID $($p.Id): $Exe $argLine" | Out-File $log -Append -Encoding utf8
Write-Output "run_timeout: TIMEOUT $reason after $secs s, killed $Exe (PID $($p.Id)) and its children"
exit 124
} finally {
  if ($gpuToken) {
    & $gpuNode $gpuHelper release $gpuRoot $gpuToken
    if ($LASTEXITCODE -ne 0) { Write-Output "GPU: release failed; dead owner PID $PID will be reclaimed" }
  }
}
