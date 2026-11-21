# Issue 1439: Windows' own view of the game's graphics memory, one sample a second, until the stop file appears or
# MaxSeconds pass. Writes unix_ms,pid,name,dedicated_mb,shared_mb,adapter_dedicated_mb to Out. Reads counters only.
param([string]$Out, [string]$Stop, [int]$MaxSeconds = 1800)
$ErrorActionPreference = 'Continue'
"unix_ms,pid,name,dedicated_mb,shared_mb,adapter_dedicated_mb" | Set-Content -LiteralPath $Out -Encoding Ascii
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds -and -not (Test-Path -LiteralPath $Stop)) {
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $adapter = 0.0
  try {
    $a = Get-Counter -Counter '\GPU Adapter Memory(*)\Dedicated Usage' -ErrorAction Stop
    foreach ($s in $a.CounterSamples) { if ($s.CookedValue -gt $adapter) { $adapter = $s.CookedValue } }
  } catch {}
  $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Voidsworn*' -or $_.ProcessName -like 'Godot*' })
  foreach ($p in $procs) {
    $ded = 0.0; $sh = 0.0
    try {
      $c = Get-Counter -Counter @("\GPU Process Memory(pid_$($p.Id)_*)\Dedicated Usage", "\GPU Process Memory(pid_$($p.Id)_*)\Shared Usage") -ErrorAction Stop
      foreach ($s in $c.CounterSamples) {
        if ($s.Path -like '*dedicated usage') { $ded += $s.CookedValue } else { $sh += $s.CookedValue }
      }
    } catch {}
    "{0},{1},{2},{3:F1},{4:F1},{5:F1}" -f $now, $p.Id, $p.ProcessName, ($ded / 1MB), ($sh / 1MB), ($adapter / 1MB) | Add-Content -LiteralPath $Out -Encoding Ascii
  }
  Start-Sleep -Milliseconds 700
}
