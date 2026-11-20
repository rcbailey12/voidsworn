# Issue 1289: one table of every CAPTURE1289 row (out\<which>\s<N>\<mode>_<tpl>.json), and the acceptance check.
# Accept (Artoo on PR 1293): the six named AFTER rows (prewarmed c_boss, prewarmed warden, firstkill c_boss; sessions 1 and
# 2) are all present, each with no frame over 100 ms (the arrival frame, built in parts, and every frame after the kill)
# and a kill that broke into pieces. Prints ACCEPT <n> of 6; exit 0 only when all six pass. Every other row (arrival,
# again, cold, the before commit) is a diagnostic: shown in the table, a missing one listed, never part of the gate.
param([string]$Out)
$rows = @()
$met = 0
$gate = @{}
foreach ($n in 1, 2) { foreach ($m in "prewarmed_c_boss", "prewarmed_warden", "firstkill_c_boss") { $gate["s$n\$m"] = "missing" } }
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
  $gk = "$sess\$($d.mode)_$($d.tpl)"
  if ($which -eq "after" -and $gate.ContainsKey($gk)) {
    if ($r.worst_frame_ms -gt 0 -and $r.worst_frame_ms -le 100 -and $k.outcome -eq "fractured" -and $k.hull_pieces -gt 0) { $gate[$gk] = "pass"; $met += 1 } else { $gate[$gk] = "over budget or no pieces" }
  }
}
# diagnostic rows that never wrote a result (a crash such as the Jolt abort of issue 1279, or a timeout), listed, not gated
foreach ($w in "after", "before") { foreach ($n in 1, 2) { foreach ($m in "arrival_c_boss", "again_c_boss", "prewarmed_c_boss", "firstkill_c_boss", "cold_c_boss", "arrival_warden", "prewarmed_warden") {
  if (-not (Test-Path -LiteralPath (Join-Path $Out "$w\s$n\$m.json"))) { $rows += "MISSING $w s$n $m (see its log_$m.txt)" } } } }
$rows
foreach ($g in $gate.Keys | Sort-Object) { "gate after $g : $($gate[$g])" }
"ACCEPT $met of 6 (after prewarmed c_boss, prewarmed warden, firstkill c_boss, two sessions: no frame over 100 ms, kill broke into pieces)"
if ($met -eq 6) { exit 0 } else { exit 1 }
