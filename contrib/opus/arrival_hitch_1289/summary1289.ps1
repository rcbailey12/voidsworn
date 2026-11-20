# Issue 1289: one table of every CAPTURE1289 row (out\<which>\s<N>\<mode>_<tpl>.json), and the acceptance check.
# Accept: every after row of prewarmed (both hulls) and firstkill has no frame over 100 ms (the arrival frame, built in
# parts, and every frame after the kill), and every kill broke into pieces. Prints ACCEPT <n> of <m>; exit 0 only when all.
param([string]$Out)
$rows = @()
$need = 0
$met = 0
foreach ($j in Get-ChildItem -LiteralPath $Out -Recurse -Filter *.json | Sort-Object FullName) {
  $d = Get-Content -LiteralPath $j.FullName -Raw | ConvertFrom-Json
  $which = Split-Path (Split-Path (Split-Path $j.FullName -Parent) -Parent) -Leaf
  $sess = Split-Path (Split-Path $j.FullName -Parent) -Leaf
  if ($d.skipped) { $rows += "{0,-6} {1,-3} {2,-10} {3,-8} skipped: {4}" -f $which, $sess, $d.mode, $d.tpl, $d.skipped; continue }
  $r = $d.result
  $a = $r.arrival
  $f = $a.frame0
  $first = if ($r.first_arrival) { "{0:N0}" -f $r.first_arrival.worst_ms } else { "-" }
  $arr = if ($a) { "{0:N0} (view {1:N0} fx {2:N0} sync {3:N0} step {4:N0} render {5:N0}; pipes {6})" -f $a.worst_ms, $f.view, $f.fx_add, $f.sync, $f.step, $f.render, (($f.pipelines.PSObject.Properties | ForEach-Object { "$($_.Name) $($_.Value)" }) -join ", ") } else { "-" }
  $k = $r.kill
  $rows += "{0,-6} {1,-3} {2,-10} {3,-8} first {4,-6} arrival {5} | kill call {6:N0} worst after {7:N0} {8} pieces {9} | worst {10:N0} ms" -f $which, $sess, $d.mode, $d.tpl, $first, $arr, $k.kill_call_ms, $k.window.wall.worst, $k.outcome, $k.hull_pieces, $r.worst_frame_ms
  if ($which -eq "after" -and ($d.mode -eq "prewarmed" -or $d.mode -eq "firstkill")) {
    $need += 1
    if ($r.worst_frame_ms -le 100 -and $k.outcome -eq "fractured") { $met += 1 }
  }
}
$rows
"ACCEPT $met of $need (after prewarmed and firstkill rows: no frame over 100 ms, kill broke into pieces)"
if ($need -gt 0 -and $met -eq $need) { exit 0 } else { exit 1 }
