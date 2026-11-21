# Read-only disk survey (Board, Nov 21). Deletes nothing.
$ErrorActionPreference = 'SilentlyContinue'
$V = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
function Get-B($p) { $o = robocopy $p "C:\__nonexist__" /L /S /E /BYTES /NFL /NDL /NJH /XJ /R:0 /W:0 /NP 2>$null; $l = $o | ? { $_ -match '^\s*Bytes :' }; if ($l) { [long](($l -split '\s+')[3]) } else { 0 } }
function Newest($p) { (Get-ChildItem $p -Recurse -File -Force -ErrorAction SilentlyContinue | sort LastWriteTime -Descending | select -First 1).LastWriteTime }
$cl = (Get-CimInstance Win32_Process | % CommandLine) -join "`n"
$queued = (Get-ChildItem $V -File -Filter '*.bat' | ? { $_.Name -match '_WAIT|_RUN|HELPERS_CHAIN' } | ? { $cl -match [regex]::Escape($_.Name) } | % { Get-Content $_.FullName -Raw }) -join "`n"
$relayed = (Get-ChildItem (Join-Path $V 'board1119') -Directory -Filter 'pcout_*' | % { Get-ChildItem $_.FullName -Directory -Name }) -join "`n"
function Use($path) { $leaf = Split-Path $path -Leaf; $top = ($path.Substring($V.Length + 1) -split '\\')[0]
  if ($cl -match [regex]::Escape("\$top\")) { return 'in use' }
  if ($queued -match [regex]::Escape("\$top")) { return 'queued job uses' }
  return '' }
function Classify($path, $use) {
  if ($use) { return 'in use' }
  $n = Split-Path $path -Leaf
  if ($n -in 'repo','new','old','repo4','.godot','profile','scratch' -or $n -match '^(profile_|scratch|out_before_|cleanup_)') { return 'rebuildable' }
  if ($path -match '\\(build|recipe|tools_live|godot|blender|node|repo-mirror(-c)?\.git|board1119|board|board_b|work217|shots)$') { return 'kept on purpose (tooling, live build, mirror or relay staging)' }
  return 'result folder (check relay)' }
$rows = New-Object System.Collections.ArrayList
$top = Get-ChildItem $V -Directory -Force | % { [pscustomobject]@{ P = $_.FullName; B = (Get-B $_.FullName) } } | sort B -Descending
foreach ($t in ($top | select -First 40)) { $u = Use $t.P; [void]$rows.Add([pscustomobject]@{ Area = 'voidsworn_test top'; Path = $t.P; GB = [math]::Round($t.B / 1GB, 2); LastWrite = (Get-Item $t.P).LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = $u; Class = (Classify $t.P $u) }) }
foreach ($t in ($top | select -First 10)) { Get-ChildItem $t.P -Force | % { $b = if ($_.PSIsContainer) { Get-B $_.FullName } else { $_.Length }; [pscustomobject]@{ P = $_.FullName; B = $b; D = $_.PSIsContainer } } | sort B -Descending | select -First 6 | % { $u = Use $_.P; [void]$rows.Add([pscustomobject]@{ Area = 'voidsworn_test child'; Path = $_.P; GB = [math]::Round($_.B / 1GB, 2); LastWrite = (Get-Item $_.P -Force).LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = $u; Class = (Classify $_.P $u) }) } }
# deeper: every checkout / import cache / out_before under job folders
Get-ChildItem $V -Directory -Filter 'opus*' | % { Get-ChildItem $_.FullName -Directory -Recurse -Depth 2 -Force | ? { $_.Name -in 'repo','new','old','repo4' -or $_.Name -match '^out_before_' } } | % { $u = Use $_.FullName; [void]$rows.Add([pscustomobject]@{ Area = 'checkout or old out'; Path = $_.FullName; GB = [math]::Round((Get-B $_.FullName) / 1GB, 2); LastWrite = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = $u; Class = (Classify $_.FullName $u) }) }
# outside
$D = Join-Path $env:USERPROFILE 'Downloads'
Get-ChildItem $D -Force | ? { $_.Name -ne 'voidsworn_test' } | % { $b = if ($_.PSIsContainer) { Get-B $_.FullName } else { $_.Length }; [pscustomobject]@{ P = $_.FullName; B = $b } } | sort B -Descending | select -First 15 | % { $c = if ($_.P -match 'trellis2') { 'kept on purpose (trellis2, never touched)' } else { 'Ryan''s own / other' }; [void]$rows.Add([pscustomobject]@{ Area = 'Downloads'; Path = $_.P; GB = [math]::Round($_.B / 1GB, 2); LastWrite = (Get-Item $_.P -Force).LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = ''; Class = $c }) }
$T = $env:TEMP
Get-ChildItem $T -Directory -Force | % { [pscustomobject]@{ P = $_.FullName; B = (Get-B $_.FullName) } } | sort B -Descending | select -First 20 | % { $u = if ($cl -match [regex]::Escape((Split-Path $_.P -Leaf))) { 'in use' } else { '' }; $c = if ($u) { 'in use' } elseif ($_.P -match 'f3dbf944d81e440088426930df7896a3') { 'kept on purpose (Board keep list)' } else { 'rebuildable' }; [void]$rows.Add([pscustomobject]@{ Area = 'TEMP'; Path = $_.P; GB = [math]::Round($_.B / 1GB, 2); LastWrite = (Get-Item $_.P -Force).LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = $u; Class = $c }) }
$vr = Get-ChildItem $T -Directory -Filter 'voidsworn-run-*' -Force; [void]$rows.Add([pscustomobject]@{ Area = 'TEMP total'; Path = "$T (all) / voidsworn-run-* count $($vr.Count)"; GB = [math]::Round((Get-B $T) / 1GB, 2); LastWrite = ''; Use = ''; Class = 'rebuildable (mostly)' })
foreach ($p in "$env:APPDATA\Godot", "$env:LOCALAPPDATA\Godot", "$env:APPDATA\Godot\app_userdata", "$env:LOCALAPPDATA\Godot\shader_cache", "$env:APPDATA\Blender Foundation", "$env:LOCALAPPDATA\Temp\blender*", "$env:LOCALAPPDATA\pip\cache", "$env:USERPROFILE\.cache", "$env:USERPROFILE\.cache\huggingface", "$env:USERPROFILE\.cache\torch", "$env:LOCALAPPDATA\NVIDIA\DXCache", "$env:LOCALAPPDATA\NVIDIA\GLCache", "$V\repo-mirror.git", "$V\repo-mirror-c.git", "$env:USERPROFILE\Videos") {
  foreach ($q in (Get-Item $p -Force -ErrorAction SilentlyContinue)) { $c = switch -Regex ($q.FullName) { 'repo-mirror' { 'kept on purpose (shared mirror)' } 'Videos$' { 'Ryan''s own / other' } 'app_userdata$' { 'kept on purpose (holds Ryan''s real profile; test profiles inside are rebuildable)' } '\\Godot$' { 'kept on purpose (Godot data incl. export templates)' } default { 'rebuildable (cache)' } }; [void]$rows.Add([pscustomobject]@{ Area = 'outside'; Path = $q.FullName; GB = [math]::Round((Get-B $q.FullName) / 1GB, 2); LastWrite = $q.LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = ''; Class = $c }) } }
$rb = 0L; Get-ChildItem 'C:\$Recycle.Bin' -Force -Directory | % { $rb += Get-B $_.FullName }; [void]$rows.Add([pscustomobject]@{ Area = 'outside'; Path = 'C:\$Recycle.Bin (all users)'; GB = [math]::Round($rb / 1GB, 2); LastWrite = ''; Use = ''; Class = 'rebuildable (Recycle Bin, Ryan empties it)' })
# git object stores over 5 GB
Get-ChildItem $V -Directory -Recurse -Depth 3 -Force -Filter '.git' | % { $b = Get-B (Join-Path $_.FullName 'objects'); if ($b -gt 5GB) { [void]$rows.Add([pscustomobject]@{ Area = 'git objects over 5 GB'; Path = $_.FullName; GB = [math]::Round($b / 1GB, 2); LastWrite = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = (Use $_.FullName); Class = 'rebuildable (clone object store)' }) } }
# videos
$vids = Get-ChildItem $V -Recurse -File -Force -Include *.mp4, *.mkv, *.avi -ErrorAction SilentlyContinue
$vids | group { ($_.FullName.Substring($V.Length + 1) -split '\\')[0] } | % { [void]$rows.Add([pscustomobject]@{ Area = 'videos by job'; Path = $_.Name; GB = [math]::Round((($_.Group | Measure Length -Sum).Sum) / 1GB, 2); LastWrite = ($_.Group | sort LastWriteTime -Descending | select -First 1).LastWriteTime.ToString('yyyy-MM-dd HH:mm'); Use = "$($_.Count) files"; Class = 'relayed result kept on purpose (videos stay on the PC)' }) }
$rows | Export-Csv (Join-Path $V 'board1119\disk_survey_1121.csv') -NoTypeInformation
$d = Get-PSDrive C; "C: total {0:N1} GB, free {1:N1} GB" -f (($d.Used + $d.Free) / 1GB), ($d.Free / 1GB)
"videos: {0} files {1:N1} GB" -f $vids.Count, (($vids | Measure Length -Sum).Sum / 1GB)
"rows: $($rows.Count)"
