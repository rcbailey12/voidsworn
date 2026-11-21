# Issue 1439: Windows' own view of graphics memory for every Voidsworn or Godot process, one sample a second, until
# the stop file appears or MaxSeconds pass. Writes unix_ms,pid,name,dedicated_mb,shared_mb,adapter_dedicated_mb,ok to
# Out. A counter that cannot be read leaves its value empty and ok=0 (never a zero reading). summarize.ps1 keeps only
# the game's own process id (perf_1439.gd writes it). Reads counters only.
param([string]$Out, [string]$Stop, [int]$MaxSeconds = 1800)
$ErrorActionPreference = 'Continue'
"unix_ms,pid,name,dedicated_mb,shared_mb,adapter_dedicated_mb,ok" | Set-Content -LiteralPath $Out -Encoding Ascii
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds -and -not (Test-Path -LiteralPath $Stop)) {
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $adapter = ''
  try {
    $a = Get-Counter -Counter '\GPU Adapter Memory(*)\Dedicated Usage' -ErrorAction Stop
    $top = 0.0
    foreach ($s in $a.CounterSamples) { if ($s.CookedValue -gt $top) { $top = $s.CookedValue } }
    $adapter = '{0:F1}' -f ($top / 1MB)
  } catch {}
  $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Voidsworn*' -or $_.ProcessName -like 'Godot*' })
  foreach ($p in $procs) {
    $ded = ''; $sh = ''; $ok = 0
    try {
      $c = Get-Counter -Counter @("\GPU Process Memory(pid_$($p.Id)_*)\Dedicated Usage", "\GPU Process Memory(pid_$($p.Id)_*)\Shared Usage") -ErrorAction Stop
      $d = 0.0; $h = 0.0; $nd = 0; $nh = 0
      foreach ($s in $c.CounterSamples) {
        if ($s.Status -ne 0) { continue }
        if ($s.Path -like '*dedicated usage') { $d += $s.CookedValue; $nd++ } else { $h += $s.CookedValue; $nh++ }
      }
      if ($nd -gt 0 -and $nh -gt 0) { $ded = '{0:F1}' -f ($d / 1MB); $sh = '{0:F1}' -f ($h / 1MB); $ok = 1 }
    } catch {}
    "{0},{1},{2},{3},{4},{5},{6}" -f $now, $p.Id, $p.ProcessName, $ded, $sh, $adapter, $ok | Add-Content -LiteralPath $Out -Encoding Ascii
  }
  Start-Sleep -Milliseconds 700
}
