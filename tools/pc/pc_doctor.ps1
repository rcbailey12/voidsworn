# PC doctor (issue 1194): a read-only look at the GPU queue on Ryan's PC. Windows PowerShell 5.1.
# Prints every GPU claim (owner, mode, weight, age, the watchdog and its GPU child and whether each is still alive),
# damaged slot files, Godot or Blender processes that look stuck (running over 5 minutes and idle through the sample),
# the installed tools_live version and the queue's failed jobs. It changes, moves and stops nothing; the only file it
# writes is the report, Downloads\voidsworn_test\pc_doctor.txt.
#   pc_doctor.ps1 [-SampleSeconds 30] [-Root <folder>]
# A process counts as idle when it used no CPU time during the sample. For the strict "idle over 5 minutes" reading run
# PC_DOCTOR.bat strict, which samples for 300 seconds.
param(
  [int]$SampleSeconds = 30,
  [string]$Root = (Join-Path $env:USERPROFILE 'Downloads\voidsworn_test')
)
$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function Say([string]$Text) { $lines.Add($Text); Write-Host $Text }
function Age([DateTime]$Since) {
  $span = [DateTime]::UtcNow - $Since.ToUniversalTime()
  if ($span.TotalMinutes -lt 1) { return '{0:0} s' -f $span.TotalSeconds }
  if ($span.TotalHours -lt 2) { return '{0:0} min' -f $span.TotalMinutes }
  return '{0:0.0} h' -f $span.TotalHours
}
# Same identity as the watchdog and gpu_slots.js: PID, start time as UTC file time, lower-case process name.
function Get-Identity([int]$ProcessId) {
  try { $p = [Diagnostics.Process]::GetProcessById($ProcessId) } catch { return $null }
  try {
    if ($p.HasExited) { return $null }
    return @{ start = [string]$p.StartTime.ToFileTimeUtc(); exe = $p.ProcessName.ToLowerInvariant(); started = $p.StartTime }
  } catch { return @{ start = ''; exe = ''; started = $null } } finally { $p.Dispose() }
}
function Health($Item) {
  if (-not $Item -or -not $Item.pid) { return 'none' }
  $id = Get-Identity ([int]$Item.pid)
  if (-not $id) { return "PID $($Item.pid) GONE" }
  if ($null -eq $Item.startTime -and $null -eq $Item.exe) { return "PID $($Item.pid) alive (old claim, PID only)" }
  if ($id.start -ne [string]$Item.startTime -or $id.exe -ne [string]$Item.exe) { return "PID $($Item.pid) REUSED by $($id.exe)" }
  return "PID $($Item.pid) $($Item.exe) alive"
}

Say ("PC doctor {0:yyyy-MM-dd HH:mm} (read only)" -f (Get-Date))
Say "Folder: $Root"
Say ''

# ---- tools_live
$pointer = Join-Path $Root 'tools_live\current.txt'
if (Test-Path -LiteralPath $pointer) {
  $version = ([IO.File]::ReadAllText($pointer)).Trim()
  $hashFile = Join-Path $Root "tools_live\$version\hashes.txt"
  $state = 'hashes.txt missing'
  if (Test-Path -LiteralPath $hashFile) {
    $bad = @()
    foreach ($l in [IO.File]::ReadAllLines($hashFile)) {
      if ($l -notmatch '^([0-9a-f]{64})  (\S+)$') { continue }
      $f = Join-Path $Root "tools_live\$version\pc\$($Matches[2])"
      $want = $Matches[1]
      if (-not (Test-Path -LiteralPath $f) -or (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant() -ne $want) { $bad += $Matches[2] }
    }
    $state = if ($bad.Count) { "DIFFERS: $($bad -join ', ')" } else { 'files match their hashes' }
  }
  Say "Tools: tools_live\$version ($state)"
} else { Say 'Tools: tools_live is not installed yet (lane_tools_refresh.ps1 -Build tools_live)' }
Say ''

# ---- GPU claims
$go = Join-Path $Root 'gpu_go.txt'
$goLine = if (Test-Path -LiteralPath $go) { ([IO.File]::ReadAllLines($go) | Select-Object -First 1) } else { '(no gpu_go.txt: no new GPU work starts)' }
Say "GPU go: $goLine"
$capacity = '2 (default)'
$capFile = Join-Path $Root 'gpu_slots.json'
if (Test-Path -LiteralPath $capFile) {
  try {
    $cap = [IO.File]::ReadAllText($capFile) | ConvertFrom-Json
    if ([int]$cap.sharedSlots -ge 1) { $capacity = [string]$cap.sharedSlots } else { $capacity = 'DAMAGED (sharedSlots missing): admission is stopped' }
  } catch { $capacity = 'DAMAGED (not JSON): admission is stopped' }
}
Say "Shared capacity: $capacity"
$slotFiles = @(Get-ChildItem -LiteralPath $Root -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '^gpu_slot_[1-9][0-9]*$' -or $_.Name -eq 'gpu_solo' } | Sort-Object Name)
$held = 0
$claimPids = @{}
foreach ($file in $slotFiles) {
  $raw = ''
  try { $raw = ([IO.File]::ReadAllText($file.FullName)).Trim() } catch { Say "  $($file.Name): CANNOT READ ($($_.Exception.Message))"; continue }
  if (-not $raw) { Say "  $($file.Name): free"; continue }
  try { $c = $raw | ConvertFrom-Json } catch { Say "  $($file.Name): CORRUPT (not JSON); gpu_slots.js moves it aside on its next admission"; continue }
  if (-not $c.token -or -not $c.pid) { Say "  $($file.Name): CORRUPT (no token or PID)"; continue }
  $held++
  $owner = if ($c.issue) { [string]$c.issue } else { '(no label)' }
  $age = 'unknown'
  if ($c.started) {
    # Windows PowerShell may already turn the ISO time into a DateTime.
    $since = $c.started
    if ($since -isnot [DateTime]) {
      $since = [DateTime]::Parse([string]$since, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
    }
    $age = Age $since
  }
  $kind = if ($file.Name -eq 'gpu_solo') { 'solo' } else { "$($c.mode) weight $($c.weight)" }
  Say "  $($file.Name): $owner, $kind, age $age"
  Say "      watchdog: $(Health $c)"
  $claimPids[[int]$c.pid] = $owner
  if ($c.child) { Say "      GPU child: $(Health $c.child)"; $claimPids[[int]$c.child.pid] = $owner }
  elseif ($c.state -ne 'orphaned_child') { Say '      GPU child: not started yet (waiting for admission or starting)' }
  if ($c.state -eq 'orphaned_child') {
    Say '      ORPHANED CHILD: the watchdog could not kill its child; the slot stays held until these exit:'
    foreach ($s in @($c.survivors)) { Say "        $(Health $s)"; $claimPids[[int]$s.pid] = $owner }
  }
}
if (-not $slotFiles.Count) { Say '  no slot files yet' }
Say "Claims held: $held"
$corrupt = @(Get-ChildItem -LiteralPath $Root -File -Force -Filter 'gpu_slot_corrupt_*' -ErrorAction SilentlyContinue)
if ($corrupt.Count) {
  Say "Damaged slot files set aside earlier (kept, never deleted): $($corrupt.Count)"
  foreach ($f in ($corrupt | Sort-Object LastWriteTime -Descending | Select-Object -First 5)) { Say "  $($f.Name), $(Age $f.LastWriteTimeUtc) ago" }
}
Say ''

# ---- Godot and Blender processes that look stuck
$names = @('godot', 'blender')
$first = @{}
foreach ($p in @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $n = $_.ProcessName.ToLowerInvariant(); @($names | Where-Object { $n -like "$_*" }).Count })) {
  try { $first[$p.Id] = $p.TotalProcessorTime.TotalSeconds } catch { }
}
if ($first.Count) { Start-Sleep -Seconds ([Math]::Max(1, $SampleSeconds)) }
$stuck = 0
Say "Godot and Blender processes (CPU sampled over $SampleSeconds s):"
foreach ($procId in ($first.Keys | Sort-Object)) {
  try { $p = Get-Process -Id $procId -ErrorAction Stop } catch { continue }
  $cpu = 0.0
  try { $cpu = $p.TotalProcessorTime.TotalSeconds - $first[$procId] } catch { }
  $started = $null
  try { $started = $p.StartTime } catch { }
  $ageText = if ($started) { Age $started } else { 'unknown' }
  $old = $started -and (([DateTime]::Now - $started).TotalMinutes -gt 5)
  $owner = if ($claimPids.ContainsKey($procId)) { "claim of $($claimPids[$procId])" } else { 'no GPU claim' }
  $flag = ''
  if ($old -and $cpu -lt 0.05) { $flag = 'STUCK? idle, running over 5 min'; $stuck++ }
  Say ("  PID {0} {1}, age {2}, CPU {3:0.00} s in sample, {4} {5}" -f $procId, $p.ProcessName, $ageText, $cpu, $owner, $flag)
}
if (-not $first.Count) { Say '  none running' }
Say "Possibly stuck: $stuck"
Say ''

# ---- queue results
foreach ($q in @('queue', 'queue_b')) {
  $failed = Join-Path $Root "$q\failed"
  $running = Join-Path $Root "$q\running"
  $nRun = @(Get-ChildItem -LiteralPath $running -File -Filter '*.bat' -ErrorAction SilentlyContinue).Count
  $f = @(Get-ChildItem -LiteralPath $failed -File -Filter '*.bat' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  Say "${q}: $nRun running, $($f.Count) failed"
  foreach ($j in ($f | Select-Object -First 5)) { Say "  failed: $($j.Name), $(Age $j.LastWriteTimeUtc) ago (log: $q\logs\$($j.Name).log)" }
}

try { [IO.File]::WriteAllLines((Join-Path $Root 'pc_doctor.txt'), $lines) } catch { Write-Host "(report not saved: $($_.Exception.Message))" }
exit 0
