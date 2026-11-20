# Issue 1180 oneoff2 probe (Board, Nov 20). Read-only on every folder it looks at; the only write besides its report is
# a refresh of repo-mirror.git under the mirror lock (the same fetch every runner does), so relay branches are current.
# Report: voidsworn_test\opus1180\oneoff2\probe_report.txt
$ErrorActionPreference = 'Stop'
$vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$mirror = Join-Path $vt 'repo-mirror.git'
$outDir = Join-Path $vt 'opus1180\oneoff2'
$null = [IO.Directory]::CreateDirectory($outDir)
$report = Join-Path $outDir 'probe_report.txt'
$w = New-Object IO.StreamWriter($report, $false, (New-Object Text.UTF8Encoding($false)))
$w.AutoFlush = $true
function R($t) { $w.WriteLine($t); Write-Host $t }
function G {
  $ErrorActionPreference = 'Continue'
  $o = & git.exe --no-optional-locks @args 2>&1 | ForEach-Object { "$_" }
  return [pscustomobject]@{ Code = $LASTEXITCODE; Out = @($o) }
}
function Walk($dir) {
  # Size and newest times without following links; .git counted apart from the work tree.
  $bytes = 0L; $newest = [DateTime]::MinValue; $newestWork = [DateTime]::MinValue; $links = 0; $denied = 0
  $gitPrefix = (Join-Path $dir '.git') + '\'
  $stack = New-Object 'Collections.Generic.Stack[string]'; $stack.Push($dir)
  while ($stack.Count) {
    $d = $stack.Pop()
    try { $entries = @((New-Object IO.DirectoryInfo($d)).EnumerateFileSystemInfos()) } catch { $denied++; continue }
    foreach ($i in $entries) {
      if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { $links++; continue }
      if ($i -is [IO.DirectoryInfo]) { $stack.Push($i.FullName); continue }
      $bytes += $i.Length
      if ($i.LastWriteTime -gt $newest) { $newest = $i.LastWriteTime }
      if (-not $i.FullName.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase) -and $i.LastWriteTime -gt $newestWork) { $newestWork = $i.LastWriteTime }
    }
  }
  return [pscustomobject]@{ Bytes = $bytes; Newest = $newest; NewestWork = $newestWork; Links = $links; Denied = $denied }
}
function FirstLines($file, $n) { if (Test-Path -LiteralPath $file) { return @(Get-Content -LiteralPath $file -TotalCount $n) } ; return @() }
function LastLines($file, $n) { if (Test-Path -LiteralPath $file) { return @(Get-Content -LiteralPath $file -Tail $n) } ; return @() }
try { $procs = @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine }) } catch { $procs = $null }
function Procs($path) {
  if ($null -eq $procs) { return 'process list unavailable' }
  $needle = [regex]::Escape($path) + '(?=$|[\\/"''\s])'
  $hit = @($procs | Where-Object { $_.CommandLine -match $needle } | ForEach-Object { "$($_.ProcessId) $($_.Name)" })
  if ($hit.Count) { return 'NAMED BY ' + ($hit -join ', ') } ; return 'none'
}
$statusFiles = @(Get-ChildItem -LiteralPath $vt -Directory -Force | Where-Object { $_.Name -like 'board*' } |
  ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -Force -Filter 'issue-*' -ErrorAction SilentlyContinue } |
  ForEach-Object { Join-Path $_.FullName 'status.json' } | Where-Object { Test-Path -LiteralPath $_ })

R "issue 1180 oneoff2 probe $(Get-Date -Format o) on $env:COMPUTERNAME"
$drive = New-Object IO.DriveInfo('C')
R "C: free $([Math]::Round($drive.AvailableFreeSpace / 1GB, 1)) GB"
# Mirror refresh under the shared lock, so relay branches are current.
$lock = $null; $deadline = (Get-Date).AddMinutes(30)
while (-not $lock) {
  try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }
  catch [IO.IOException] { if ((Get-Date) -ge $deadline) { R 'mirror lock busy for 30 minutes; relay counts use the mirror as it is'; break }; Start-Sleep -Milliseconds 500 }
}
if ($lock) { try { $f = G --git-dir $mirror fetch -q --prune origin; R "mirror refresh exit $($f.Code)" } finally { $lock.Dispose() } }
$receipts = New-Object 'Collections.Generic.HashSet[string]'
$refs = G --git-dir $mirror for-each-ref '--format=%(refname:short)' 'refs/heads/board/pc-out-*'
R "relay branches: $($refs.Out.Count)"
foreach ($line in (G --git-dir $mirror rev-list --objects '--glob=refs/heads/board/pc-out-*').Out) { $null = $receipts.Add(($line -split ' ', 2)[0]) }

R ''
R '=== A. board kept copies (7 bad HEAD, 3 MERGE_HEAD)'
$copies = @(
  'board\repo-kept-a96a526aa67d494fbbf7d841454ca0cb', 'board\repo-kept-cb9c4e3c05c8424cba7a86cb5a9de9cb',
  'board\repo-kept-81506ef10ec64d3c96aa8cacc744b33c', 'board\repo-kept-64b7f32ffa4849c7a4bd726da6ea4cb4',
  'board\repo-kept-70f1a89ca7014f369e1696c81db59112', 'board\repo-kept-aceb3473930c4e27ad65642d23ce25fa',
  'board\repo-kept-d084110f41ff45c69bea582ef588917c', 'board\repo-kept-0007d7218e4a477fa27a2c925515cd68',
  'board_c\repo-kept-7103eb6705144c7da25ef676a676852a', 'board_c\repo-kept-21f1637f37cd4c49b04eae1a5492281b')
foreach ($rel in $copies) {
  $p = Join-Path $vt $rel
  R ''
  R "--- $p"
  if (-not (Test-Path -LiteralPath $p)) { R 'gone'; continue }
  $s = Walk $p
  R ("size {0} bytes; newest work file {1:yyyy-MM-dd HH:mm}; newest any {2:yyyy-MM-dd HH:mm}; links {3}; unreadable {4}" -f $s.Bytes, $s.NewestWork, $s.Newest, $s.Links, $s.Denied)
  R "processes: $(Procs $p)"
  $gd = Join-Path $p '.git'
  R "HEAD file: $((FirstLines (Join-Path $gd 'HEAD') 1) -join '')"
  $alt = Join-Path $gd 'objects\info\alternates'
  foreach ($a in (FirstLines $alt 5)) { R "alternates: $a (exists: $(Test-Path -LiteralPath $a))" }
  $h = G -C $p rev-parse --verify HEAD; R "rev-parse HEAD: exit $($h.Code) $($h.Out -join ' ')"
  foreach ($l in (LastLines (Join-Path $gd 'logs\HEAD') 5)) { R "reflog: $(($l -split "`t", 2)[-1]) [$((($l -split ' ')[1]))]" }
  foreach ($l in (FirstLines (Join-Path $gd 'FETCH_HEAD') 5)) { R "FETCH_HEAD: $l" }
  foreach ($l in (FirstLines (Join-Path $gd 'MERGE_HEAD') 2)) { R "MERGE_HEAD: $l" }
  foreach ($l in (FirstLines (Join-Path $gd 'MERGE_MSG') 3)) { R "MERGE_MSG: $l" }
  $st = G -C $p status --porcelain --untracked-files=normal
  R "status: exit $($st.Code), $($st.Out.Count) lines"
  foreach ($l in ($st.Out | Select-Object -First 25)) { R "  $l" }
  $name = Split-Path -Leaf $p
  foreach ($sf in $statusFiles) { if ([IO.File]::ReadAllText($sf).Contains($name)) { R "named in: $sf" } }
}

R ''
R '=== B. helper folders not on the Board active list'
$active = @('opus1077','opus1078','opus1155','opus1157','opus1156','opus1211','opus1234','opus1154','opus1183','opus1232','opus1235','opus1236','opus1237','opus1238','opus1180')
foreach ($dir in @(Get-ChildItem -LiteralPath $vt -Directory -Force -Filter 'opus*')) {
  $base = ($dir.Name -replace 'out.*$', '')
  if ($active -contains $base) { continue }
  if ($dir.Name -notmatch '^opus[1-9][0-9]*(out.*)?$') { continue }
  R ''
  R "--- $($dir.FullName)"
  $s = Walk $dir.FullName
  R ("size {0} bytes; newest file {1:yyyy-MM-dd HH:mm}; links {2}; unreadable {3}" -f $s.Bytes, $s.Newest, $s.Links, $s.Denied)
  R "processes: $(Procs $dir.FullName)"
  foreach ($top in @($dir.EnumerateFileSystemInfos())) {
    if ($top -is [IO.DirectoryInfo]) { $t = Walk $top.FullName; R ("  {0,-30} folder {1,14} bytes newest {2:yyyy-MM-dd HH:mm}{3}" -f $top.Name, $t.Bytes, $t.Newest, $(if (Test-Path -LiteralPath (Join-Path $top.FullName '.git')) { ' (git checkout)' } else { '' })) }
    else { R ("  {0,-30} file   {1,14} bytes {2:yyyy-MM-dd HH:mm}" -f $top.Name, $top.Length, $top.LastWriteTime) }
  }
  # Every file outside a git checkout, checked against the relay branches.
  $files = @(); $checkouts = @()
  $stack = New-Object 'Collections.Generic.Stack[string]'; $stack.Push($dir.FullName)
  while ($stack.Count) {
    $d = $stack.Pop()
    if ($d -ne $dir.FullName -and (Test-Path -LiteralPath (Join-Path $d '.git'))) { $checkouts += $d; continue }
    try { $entries = @((New-Object IO.DirectoryInfo($d)).EnumerateFileSystemInfos()) } catch { continue }
    foreach ($i in $entries) {
      if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($i -is [IO.DirectoryInfo]) { $stack.Push($i.FullName) } else { $files += $i }
    }
  }
  $unrelayed = @(); $relayed = 0
  for ($k = 0; $k -lt $files.Count; $k += 200) {
    $chunk = @($files[$k..([Math]::Min($k + 199, $files.Count - 1))])
    $hashes = @($chunk | ForEach-Object { $_.FullName } | & git.exe --git-dir $mirror hash-object --no-filters --stdin-paths)
    if ($hashes.Count -ne $chunk.Count) { R "  hash check failed for $($chunk.Count) files; counted as not relayed"; $unrelayed += $chunk; continue }
    for ($j = 0; $j -lt $chunk.Count; $j++) { if ($receipts.Contains($hashes[$j])) { $relayed++ } else { $unrelayed += $chunk[$j] } }
  }
  $ub = ($unrelayed | Measure-Object -Property Length -Sum).Sum
  R "files outside checkouts: $($files.Count); on a relay branch: $relayed; not relayed: $($unrelayed.Count) ($ub bytes)"
  foreach ($grp in ($unrelayed | Group-Object { $_.Extension.ToLower() } | Sort-Object Count -Descending | Select-Object -First 8)) {
    R ("  not relayed {0,-8} {1,6} files {2,14} bytes" -f $grp.Name, $grp.Count, ($grp.Group | Measure-Object -Property Length -Sum).Sum)
  }
  foreach ($u in ($unrelayed | Sort-Object Length -Descending | Select-Object -First 10)) { R "  largest not relayed: $($u.FullName.Substring($dir.FullName.Length + 1)) ($($u.Length) bytes)" }
  foreach ($c in $checkouts) {
    $h = G -C $c rev-parse --short HEAD; $st = G -C $c status --porcelain --untracked-files=no
    R "  checkout $($c.Substring($dir.FullName.Length + 1)): HEAD $($h.Out -join ' '), tracked changes $($st.Out.Count)"
  }
}
R ''
R 'all done'
$w.Dispose()
