# Board, Nov 19 2026 (18:47 CST): READ ONLY disk report. Skips reparse points (junctions, symlinks) and follows none.
# Writes only %VT%\disk_report_1120\report.txt. Deletes, moves and stops nothing.
$ErrorActionPreference = 'SilentlyContinue'
$V = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$outDir = Join-Path $V 'disk_report_1120'
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir 'report.txt'
$since = Get-Date -Year 2026 -Month 11 -Day 19 -Hour 14 -Minute 0 -Second 0
$RP = [IO.FileAttributes]::ReparsePoint

function Measure-Tree([string]$root) {
  $total = [int64]0; $recent = [int64]0; $files = 0; $latest = [datetime]::MinValue
  $stack = New-Object System.Collections.Stack
  $di = New-Object IO.DirectoryInfo $root
  if (-not $di.Exists) { return $null }
  if ($di.Attributes -band $RP) { return [pscustomobject]@{ Path=$root; Bytes=0; Recent=0; Files=0; Latest=$di.LastWriteTime; Note='reparse point, not followed' } }
  $stack.Push($di)
  while ($stack.Count) {
    $d = $stack.Pop()
    try { $entries = $d.GetFileSystemInfos() } catch { continue }
    foreach ($e in $entries) {
      if ($e.Attributes -band $RP) { continue }
      if ($e -is [IO.DirectoryInfo]) { $stack.Push($e); continue }
      $total += $e.Length; $files++
      $t = if ($e.LastWriteTime -gt $e.CreationTime) { $e.LastWriteTime } else { $e.CreationTime }
      if ($t -gt $latest) { $latest = $t }
      if ($t -ge $since) { $recent += $e.Length }
    }
  }
  [pscustomobject]@{ Path=$root; Bytes=$total; Recent=$recent; Files=$files; Latest=$latest; Note='' }
}
function GB($b) { '{0,8:N2}' -f ($b / 1GB) }
function Row($m) { "{0} GB  new/changed since 14:00 {1} GB  {2,8} files  latest {3:MM-dd HH:mm}  {4}{5}" -f (GB $m.Bytes), (GB $m.Recent), $m.Files, $m.Latest, $m.Path, $(if ($m.Note) { "  [$($m.Note)]" }) }

$lines = New-Object System.Collections.ArrayList
function Out-Section($title, $rows) { [void]$lines.Add(''); [void]$lines.Add("==== $title"); foreach ($r in ($rows | Sort-Object Bytes -Descending)) { [void]$lines.Add((Row $r)) } }

$drive = Get-PSDrive C
$head = @("disk report (read only, reparse points skipped) $((Get-Date).ToString('s'))", ("C: free {0:N2} GB, used {1:N2} GB" -f ($drive.Free/1GB), ($drive.Used/1GB)), "growth window: files created or written since $($since.ToString('s'))")

# 1. voidsworn_test top level, and one level down under the busy folders
$top = @(Get-ChildItem -LiteralPath $V -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) } | ForEach-Object { Measure-Tree $_.FullName })
$rootFiles = Get-ChildItem -LiteralPath $V -File -Force; $rf = ($rootFiles | Measure-Object Length -Sum).Sum
$top += [pscustomobject]@{ Path="$V\(files in the root)"; Bytes=[int64]$rf; Recent=[int64](($rootFiles | Where-Object { $_.LastWriteTime -ge $since } | Measure-Object Length -Sum).Sum); Files=@($rootFiles).Count; Latest=($rootFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime; Note='' }
Out-Section 'voidsworn_test, top level' $top
$deep = @()
foreach ($t in $top) {
  $name = Split-Path $t.Path -Leaf
  if ($name -match '^(board.*|build.*|work217|opus.*|ship_job|recipe|queue)$') {
    $deep += @(Get-ChildItem -LiteralPath $t.Path -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) } | ForEach-Object { Measure-Tree $_.FullName })
  }
}
Out-Section 'one level down (board*, build*, work217, opus*, ship_job, recipe, queue)' ($deep | Where-Object { $_.Bytes -ge 100MB })

# 2. TEMP folders over 500 MB, and totals by prefix
$tmp = @(Get-ChildItem -LiteralPath $env:TEMP -Directory -Force | Where-Object { -not ($_.Attributes -band $RP) } | ForEach-Object { Measure-Tree $_.FullName })
Out-Section "TEMP ($env:TEMP) folders over 500 MB" ($tmp | Where-Object { $_.Bytes -ge 500MB })
[void]$lines.Add(''); [void]$lines.Add('==== TEMP totals by name prefix')
$tmp | Group-Object { $n = Split-Path $_.Path -Leaf; if ($n -like 'voidsworn-run-*') { 'voidsworn-run-*' } elseif ($n -like 'voidsworn-parity-*') { 'voidsworn-parity-*' } elseif ($n -like 'godot*') { 'godot*' } elseif ($n -like 'voidsworn*') { 'voidsworn* (other)' } elseif ($n -like 'stage7-checked-*') { 'stage7-checked-*' } else { 'others' } } |
  ForEach-Object { [pscustomobject]@{ Name=$_.Name; Count=$_.Count; Bytes=($_.Group | Measure-Object Bytes -Sum).Sum; Recent=($_.Group | Measure-Object Recent -Sum).Sum } } | Sort-Object Bytes -Descending |
  ForEach-Object { [void]$lines.Add(("{0} GB  new/changed since 14:00 {1} GB  {2,4} folders  {3}" -f (GB $_.Bytes), (GB $_.Recent), $_.Count, $_.Name)) }
$tf = Get-ChildItem -LiteralPath $env:TEMP -File -Force; [void]$lines.Add(("{0} GB  loose files in TEMP root ({1})" -f (GB (($tf | Measure-Object Length -Sum).Sum)), @($tf).Count))

# 3. Godot and Blender user folders
$gb = @()
foreach ($p in @("$env:APPDATA\Godot", "$env:LOCALAPPDATA\Godot", "$env:APPDATA\Blender Foundation", "$env:LOCALAPPDATA\Blender Foundation", "$env:TEMP\blender*")) {
  foreach ($q in (Get-Item -Path $p -Force)) { $m = Measure-Tree $q.FullName; if ($m) { $gb += $m } }
}
Out-Section 'Godot and Blender user, cache and temp folders' $gb

# 4. other big places on C:
$other = @()
foreach ($p in @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\AppData\Local\Temp", 'C:\ProgramData', 'C:\Windows\Temp', "$env:USERPROFILE\.codex", "$env:USERPROFILE\.cache", "$env:USERPROFILE\AppData\Local\OpenAI", "$env:USERPROFILE\AppData\Local\npm-cache", "$env:USERPROFILE\AppData\Roaming\npm")) {
  $m = Measure-Tree $p; if ($m) { $other += $m }
}
foreach ($f in @('C:\pagefile.sys', 'C:\hiberfil.sys', 'C:\swapfile.sys')) { $i = Get-Item -LiteralPath $f -Force; if ($i) { $other += [pscustomobject]@{ Path=$f; Bytes=$i.Length; Recent=$(if ($i.LastWriteTime -ge $since) { $i.Length } else { 0 }); Files=1; Latest=$i.LastWriteTime; Note='system file' } } }
Out-Section 'other places on C:' $other

# biggest growers since 14:00 across everything measured (leaf rows only, to avoid double counting the parents)
$leaf = @($deep) + @($tmp) + @($gb) + @($other | Where-Object { $_.Path -notmatch 'Downloads$|AppData\\Local\\Temp$' }) + @($top | Where-Object { (Split-Path $_.Path -Leaf) -notmatch '^(board.*|build.*|work217|opus.*|ship_job|recipe|queue)$' })
[void]$lines.Add(''); [void]$lines.Add('==== biggest growers since 14:00 (new or changed bytes)')
$leaf | Where-Object { $_.Recent -ge 500MB } | Sort-Object Recent -Descending | Select-Object -First 30 | ForEach-Object { [void]$lines.Add(("{0} GB new  of {1} GB  {2}" -f (GB $_.Recent), (GB $_.Bytes), $_.Path)) }

($head + $lines) | Set-Content -LiteralPath $report -Encoding UTF8
"report written: $report"
