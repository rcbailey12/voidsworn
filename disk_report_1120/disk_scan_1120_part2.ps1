# Board, Nov 19 2026 (18:52 CST): READ ONLY part 2 of the disk report. Skips reparse points, follows none. Appends to
# %VT%\disk_report_1120\report.txt. Deletes, moves and stops nothing.
$ErrorActionPreference = 'SilentlyContinue'
$V = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$report = Join-Path $V 'disk_report_1120\report.txt'
$RP = [IO.FileAttributes]::ReparsePoint
function Size-Tree([string]$root, [scriptblock]$fileFilter = $null, [scriptblock]$dirSkip = $null) {
  $total = [int64]0
  $di = New-Object IO.DirectoryInfo $root
  if (-not $di.Exists -or ($di.Attributes -band $RP)) { return [int64]0 }
  $stack = New-Object System.Collections.Stack; $stack.Push($di)
  while ($stack.Count) {
    $d = $stack.Pop()
    try { $entries = $d.GetFileSystemInfos() } catch { continue }
    foreach ($e in $entries) {
      if ($e.Attributes -band $RP) { continue }
      if ($e -is [IO.DirectoryInfo]) { if (-not ($dirSkip -and (& $dirSkip $e))) { $stack.Push($e) }; continue }
      if (-not $fileFilter -or (& $fileFilter $e)) { $total += $e.Length }
    }
  }
  $total
}
# all .godot import-cache folders under a root (not following reparse points)
function Godot-Caches([string]$root) {
  $sum = [int64]0; $n = 0
  $stack = New-Object System.Collections.Stack; $stack.Push((New-Object IO.DirectoryInfo $root))
  while ($stack.Count) {
    $d = $stack.Pop()
    try { $dirs = $d.GetDirectories() } catch { continue }
    foreach ($x in $dirs) {
      if ($x.Attributes -band $RP) { continue }
      if ($x.Name -eq '.godot') { $sum += (Size-Tree $x.FullName); $n++ } elseif ($x.Name -ne '.git') { $stack.Push($x) }
    }
  }
  [pscustomobject]@{ Bytes = $sum; Count = $n }
}
function GB($b) { '{0,8:N2}' -f ($b / 1GB) }
$L = New-Object System.Collections.ArrayList
function Add($t) { [void]$L.Add($t) }

Add ''; Add "==== PART 2 (whole-folder view, not only today) $((Get-Date).ToString('s'))"
# (a) voidsworn_test by category
$cats = [ordered]@{}
$top = Get-ChildItem -LiteralPath $V -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) }
foreach ($t in $top) {
  $n = $t.Name
  $cat = switch -regex ($n) {
    '^board'                 { 'job copies: board* (lane checkouts and repo-kept)'; break }
    '^build_[b-e]$'          { 'runner tools copies build_b..e'; break }
    '^build$'                { 'shared build (build\godot ships, gen, import cache) and old tools'; break }
    '^work217$'              { 'job copies: work217 run repos'; break }
    '^opus'                  { 'opus helper folders (job clones, outputs)'; break }
    '^(recipe|bake|bake_lo|bake_p2k|bakeoff|textures|blender|renders?|shots|look_bench|outputs)$' { 'recipe, bake and render outputs'; break }
    '^(queue|queue_b|runner.*|board1119|pause.*|disk_report.*)$' { 'queue, runner logs and backups, relays'; break }
    '^(node|godot)$'         { 'node and godot binaries'; break }
    '^repo-mirror'           { 'git mirrors'; break }
    '^mission'               { 'mission folders and backups'; break }
    default                  { 'other' }
  }
  if (-not $cats.Contains($cat)) { $cats[$cat] = [pscustomobject]@{ Bytes = [int64]0; Folders = New-Object System.Collections.ArrayList } }
  $b = Size-Tree $t.FullName
  $cats[$cat].Bytes += $b; [void]$cats[$cat].Folders.Add(('{0} {1}' -f (GB $b).Trim(), $n))
}
$rootFiles = (Get-ChildItem -LiteralPath $V -File -Force | Measure-Object Length -Sum).Sum
$all = ($cats.Values | Measure-Object Bytes -Sum).Sum + $rootFiles
Add ''; Add ("==== (a) voidsworn_test total {0} GB, by category (reparse points skipped)" -f (GB $all).Trim())
foreach ($k in ($cats.Keys | Sort-Object { $cats[$_].Bytes } -Descending)) {
  Add ("{0} GB  {1}" -f (GB $cats[$k].Bytes), $k)
  Add ("           " + (($cats[$k].Folders | Sort-Object { [double]($_ -split ' ')[0] } -Descending | Select-Object -First 8) -join ' | '))
}
Add ("{0} GB  loose files in the voidsworn_test root" -f (GB $rootFiles))
$gc = Godot-Caches $V
Add ("{0} GB  of the above is Godot import caches (.godot folders): {1} folders across all copies" -f (GB $gc.Bytes), $gc.Count)
$blend = Size-Tree $V { param($f) $f.Extension -in '.blend', '.blend1', '.blend2' } { param($d) $d.Name -eq '.git' }
Add ("{0} GB  of the above is .blend / .blend1 files" -f (GB $blend))
$gitObj = [int64]0; foreach ($t in $top) { foreach ($g in (Get-ChildItem -LiteralPath $t.FullName -Directory -Force -Filter '.git' -Recurse -Depth 3)) { if (-not ($g.Attributes -band $RP)) { $gitObj += Size-Tree $g.FullName } } }
Add ("{0} GB  of the above is .git folders inside job copies (depth up to 4)" -f (GB $gitObj))

# (b) TEMP by prefix
Add ''; Add "==== (b) %TEMP% by prefix"
$tmpRows = foreach ($d in (Get-ChildItem -LiteralPath $env:TEMP -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) })) {
  $p = $d.Name; $k = if ($p -like 'voidsworn-run-*') { 'voidsworn-run-*' } elseif ($p -like 'voidsworn-parity-*') { 'voidsworn-parity-*' } elseif ($p -like 'voidsworn*') { 'voidsworn* (other)' } elseif ($p -like 'godot*') { 'godot*' } elseif ($p -like 'stage7-checked-*') { 'stage7-checked-*' } elseif ($p -like 'claude*') { 'claude*' } elseif ($p -match '^(tmp|_MEI|pip-|npm-|node-)') { 'tool temp (tmp, pip, npm, node, pyinstaller)' } else { 'others' }
  [pscustomobject]@{ K = $k; B = (Size-Tree $d.FullName) }
}
$tmpRows | Group-Object K | ForEach-Object { [pscustomobject]@{ K = $_.Name; N = $_.Count; B = ($_.Group | Measure-Object B -Sum).Sum } } | Sort-Object B -Descending | ForEach-Object { Add ("{0} GB  {1,4} folders  {2}" -f (GB $_.B), $_.N, $_.K) }
Add ("{0} GB  TEMP total (folders) plus {1} GB loose files" -f (GB (($tmpRows | Measure-Object B -Sum).Sum)), (GB ((Get-ChildItem -LiteralPath $env:TEMP -File -Force | Measure-Object Length -Sum).Sum)))

# (c) biggest non-project folders on C:
Add ''; Add "==== (c) biggest folders on C: outside voidsworn_test"
$cand = New-Object System.Collections.ArrayList
foreach ($d in (Get-ChildItem -LiteralPath 'C:\' -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) -and $_.Name -notin @('Users', '$Recycle.Bin', 'System Volume Information') })) { [void]$cand.Add([pscustomobject]@{ P = $d.FullName; B = (Size-Tree $d.FullName) }) }
$rb = Get-Item -LiteralPath 'C:\$Recycle.Bin' -Force; if ($rb) { [void]$cand.Add([pscustomobject]@{ P = 'C:\$Recycle.Bin (all users)'; B = (Size-Tree $rb.FullName) }) }
foreach ($d in (Get-ChildItem -LiteralPath $env:USERPROFILE -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) -and $_.Name -notin @('Downloads', 'AppData') })) { [void]$cand.Add([pscustomobject]@{ P = $d.FullName; B = (Size-Tree $d.FullName) }) }
foreach ($d in (Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.Name -ne 'voidsworn_test' -and -not ($_.Attributes -band $RP) })) { $b = if ($_ -is [IO.DirectoryInfo] -or $d.PSIsContainer) { Size-Tree $d.FullName } else { $d.Length }; [void]$cand.Add([pscustomobject]@{ P = $d.FullName; B = $b }) }
foreach ($side in 'Local', 'LocalLow', 'Roaming') { foreach ($d in (Get-ChildItem -LiteralPath "$env:USERPROFILE\AppData\$side" -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) -and $_.Name -ne 'Temp' })) { [void]$cand.Add([pscustomobject]@{ P = $d.FullName; B = (Size-Tree $d.FullName) }) } }
foreach ($f in 'C:\pagefile.sys', 'C:\hiberfil.sys', 'C:\swapfile.sys') { $i = Get-Item -LiteralPath $f -Force; if ($i) { [void]$cand.Add([pscustomobject]@{ P = $f; B = $i.Length }) } }
$cand | Sort-Object B -Descending | Select-Object -First 25 | ForEach-Object { Add ("{0} GB  {1}" -f (GB $_.B), $_.P) }

# (d) every drive
Add ''; Add "==== (d) drives"
Get-PSDrive -PSProvider FileSystem | ForEach-Object { if ($_.Used -ne $null) { Add ("{0}:  used {1} GB  free {2} GB  total {3} GB  {4}" -f $_.Name, (GB $_.Used).Trim(), (GB $_.Free).Trim(), (GB ($_.Used + $_.Free)).Trim(), $_.Description) } }
Get-Volume | Where-Object { $_.DriveLetter -or $_.FileSystemLabel } | ForEach-Object { Add ("volume {0}: label '{1}' {2} {3}  size {4} GB  free {5} GB  health {6}" -f $_.DriveLetter, $_.FileSystemLabel, $_.FileSystem, $_.DriveType, (GB $_.Size).Trim(), (GB $_.SizeRemaining).Trim(), $_.HealthStatus) }
Add ''; Add "==== shadow copies / restore points (read only)"
(vssadmin list shadowstorage 2>&1) | Where-Object { $_ -match 'Used|Allocated|Maximum|For volume' } | ForEach-Object { Add ("  " + $_.Trim()) }
Add-Content -LiteralPath $report -Value $L -Encoding UTF8
"part 2 appended"
