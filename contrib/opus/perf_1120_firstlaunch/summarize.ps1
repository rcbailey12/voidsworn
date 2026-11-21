# Issue 1439: one readable table per run folder (summary.json and events.jsonl from godot/bench/perf_1439.gd, gpu.csv
# from gpu_mem_sampler.ps1). Writes <Run>\summary.txt. The game process is the one with the largest dedicated peak.
param([string]$Run)
$ErrorActionPreference = 'Stop'
$s = Get-Content -LiteralPath (Join-Path $Run 'summary.json') -Raw | ConvertFrom-Json
$rows = @()
$csv = Join-Path $Run 'gpu.csv'
if (Test-Path -LiteralPath $csv) { $rows = @(Import-Csv -LiteralPath $csv) }
$game = $null
if ($rows.Count) {
  $game = ($rows | Group-Object pid | Sort-Object { ($_.Group | Measure-Object -Property dedicated_mb -Maximum).Maximum } -Descending | Select-Object -First 1).Name
  $rows = @($rows | Where-Object { $_.pid -eq $game })
}
$o = New-Object System.Collections.Generic.List[string]
$o.Add("Run: $Run")
$o.Add("Note: $($s.note)  Battles reached: $($s.battles)  Frames: $($s.frames)")
$o.Add("Adapter: $($s.adapter)  Viewport: $($s.viewport)  Quality: $($s.settings.quality)  Fullscreen: $($s.settings.fullscreen)")
$launch = 0
if ($s.launch_unix_ms) { $launch = [int64]$s.launch_unix_ms }
$ev = @()
$evf = Join-Path $Run 'events.jsonl'
if (Test-Path -LiteralPath $evf) { $ev = @(Get-Content -LiteralPath $evf | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }) }
$td = @($ev | Where-Object { $_.kind -eq 'title_drawn' } | Select-Object -First 1)
if ($td.Count) {
  $line = "First drawn title: {0:N0} ms after engine start" -f [double]$td[0].engine_ms
  if ($launch -gt 0) { $line += ("; {0:N0} ms after the bat launched the exe" -f ([int64]$td[0].unix_ms - $launch)) }
  $o.Add($line)
}
foreach ($p in $s.playable_engine_ms.PSObject.Properties) { $o.Add(("Battle {0} playable (cover lifted): {1:N0} ms after engine start" -f $p.Name, [double]$p.Value)) }
if ($game) { $o.Add("Windows GPU memory: process $game, $($rows.Count) samples") } else { $o.Add("Windows GPU memory: no samples") }
$o.Add("")
$o.Add("{0,-15}{1,9}{2,10}{3,8}{4,10}{5,10}{6,10}{7,10}{8,10}{9,10}" -f 'stage','seconds','worst ms','>100ms','compiles','vram MB','tex MB','buf MB','win ded','win shr')
foreach ($r in $s.stages) {
  $win = @($rows | Where-Object { [int64]$_.unix_ms -ge [int64]$r.first_unix_ms -and [int64]$_.unix_ms -le [int64]$r.last_unix_ms })
  $wd = '-'; $ws = '-'
  if ($win.Count) {
    $wd = '{0:N0}' -f ($win | Measure-Object -Property dedicated_mb -Maximum).Maximum
    $ws = '{0:N0}' -f ($win | Measure-Object -Property shared_mb -Maximum).Maximum
  }
  $sec = ([double]$r.last_ms - [double]$r.first_ms) / 1000.0
  $o.Add("{0,-15}{1,9:N1}{2,10:N0}{3,8}{4,10}{5,10:N0}{6,10:N0}{7,10:N0}{8,10}{9,10}" -f $r.stage, $sec, [double]$r.worst_dt, $r.over_100ms, $r.compiles, [double]$r.vram_mb_peak, [double]$r.texture_mb_peak, [double]$r.buffer_mb_peak, $wd, $ws)
}
$o.Add("")
$o.Add("compiles = pipeline compilations during the stage (canvas, mesh, surface, draw, specialization); vram/tex/buf = Godot's")
$o.Add("monitors (peak); win ded/shr = Windows dedicated and shared GPU memory for the game process (peak, 1 s samples).")
$o | Set-Content -LiteralPath (Join-Path $Run 'summary.txt') -Encoding Ascii
$o | ForEach-Object { Write-Output $_ }
