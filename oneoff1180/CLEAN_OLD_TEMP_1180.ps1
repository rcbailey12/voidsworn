# Issue 1180, one-off (Ryan approves once): remove the agent-named TEMP folders the janitor cannot prove are ours.
# Reads CLEAN_OLD_TEMP_1180_list.txt next to this file: one full folder path per line (the Board's reviewed list).
# Each path must still exist, be a plain folder (not a link), sit directly under %TEMP% (or be the one stray .git in
# voidsworn_test\board1119), be untouched for 12 hours and not be named by a running program. Links inside are removed
# as links and never followed. Nothing outside the list is touched. Log: CLEAN_OLD_TEMP_1180_log.txt next to this file.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$listFile = Join-Path $here 'CLEAN_OLD_TEMP_1180_list.txt'
$logFile = Join-Path $here 'CLEAN_OLD_TEMP_1180_log.txt'
$temp = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')
$vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$extra = @((Join-Path $vt 'board1119\stray_git_1119v'))
$cutoff = (Get-Date).AddHours(-12)
function Log($t) { Add-Content -LiteralPath $logFile -Value $t; Write-Host $t }
function Measure-Folder($dir) {
  $bytes = 0L; $links = @(); $denied = @(); $latest = $dir.LastWriteTime
  $stack = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'; $stack.Push($dir)
  while ($stack.Count) {
    $next = $stack.Pop()
    try { $entries = @($next.EnumerateFileSystemInfos()) } catch { $denied += ,$next.FullName; continue }
    foreach ($i in $entries) {
      if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { $links += ,$i; continue }
      if ($i.LastWriteTime -gt $latest) { $latest = $i.LastWriteTime }
      if ($i -is [IO.DirectoryInfo]) { $stack.Push($i) } else { $bytes += $i.Length }
    }
  }
  return @{ Bytes = $bytes; Links = $links; Denied = $denied; Latest = $latest }
}
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log "one-off TEMP cleanup started $(Get-Date -Format o) (administrator: $admin)"
$drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($temp))
Log "free space before: $([Math]::Round($drive.AvailableFreeSpace / 1GB, 1)) GB"
try { $commandLines = @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine } | ForEach-Object { $_.CommandLine }) }
catch { Log 'stopped: running programs could not be checked; nothing removed'; Log 'all done'; exit 1 }
$plan = @()
foreach ($line in [IO.File]::ReadAllLines($listFile)) {
  $p = $line.Trim()
  if (-not $p -or $p.StartsWith('#')) { continue }
  $full = [IO.Path]::GetFullPath($p).TrimEnd('\')
  $item = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
  if (-not $item) { Log "skip (already gone): $full"; continue }
  if ($item -isnot [IO.DirectoryInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Log "skip (not a plain folder): $full"; continue }
  if ((Split-Path -Parent $full) -ne $temp -and $extra -notcontains $full) { Log "skip (not directly under TEMP): $full"; continue }
  $needle = [regex]::Escape($full) + '(?=$|[\\/"''\s])'
  if ($commandLines | Where-Object { $_ -match $needle }) { Log "skip (a running program names it): $full"; continue }
  $m = Measure-Folder $item
  if ($m.Denied -contains $full) { Log "skip (cannot be read even as administrator): $full"; continue }
  if ($m.Latest -gt $cutoff) { Log "skip (changed in the last 12 hours, $($m.Latest)): $full"; continue }
  $plan += ,@{ Item = $item; Bytes = $m.Bytes; Links = $m.Links }
  $note = if ($m.Denied.Count) { "  ($($m.Denied.Count) parts unreadable, left in place)" } else { '' }
  Write-Host ("{0,8:N1} GB  {1:yyyy-MM-dd}  {2}{3}" -f ($m.Bytes / 1GB), $m.Latest, $full, $note)
}
if (-not $plan.Count) { Log 'nothing to remove'; Log 'all done'; exit 0 }
$total = ($plan | ForEach-Object { $_.Bytes } | Measure-Object -Sum).Sum
Write-Host ''
Write-Host ("{0} folders, {1:N1} GB. Type YES to delete exactly these, anything else to stop." -f $plan.Count, ($total / 1GB))
if ((Read-Host) -cne 'YES') { Log 'stopped: Ryan did not type YES; nothing removed'; Log 'all done'; exit 0 }
foreach ($p in $plan) {
  $d = $p.Item.FullName
  try {
    foreach ($l in $p.Links) {
      if ($l -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($l.FullName, $false) } else { [IO.File]::Delete($l.FullName) }
    }
    $left = Measure-Folder (Get-Item -LiteralPath $d -Force)
    if ($left.Links.Count) { throw 'a link appeared while cleaning' }
    if ($left.Denied.Count) {
      # Remove everything that can be read; unreadable parts and the folders leading to them stay.
      $keep = @{}; foreach ($u in $left.Denied) { for ($x = $u; $x.Length -ge $d.Length; $x = Split-Path -Parent $x) { $keep[$x] = 1 } }
      $stack = New-Object 'Collections.Generic.Stack[string]'; $stack.Push($d)
      while ($stack.Count) {
        $next = $stack.Pop(); if ($left.Denied -contains $next) { continue }
        foreach ($c in @(Get-ChildItem -LiteralPath $next -Force)) {
          if ($keep.ContainsKey($c.FullName)) { $stack.Push($c.FullName) } else { Remove-Item -LiteralPath $c.FullName -Recurse -Force }
        }
      }
      Log "removed all but $($left.Denied.Count) unreadable parts of $d ($($p.Bytes) bytes, $($p.Links.Count) links removed as links)"
      continue
    }
    Remove-Item -LiteralPath $d -Recurse -Force
    if (Test-Path -LiteralPath $d) { throw 'not fully removed (in use?)' }
    Log "removed $d ($($p.Bytes) bytes, $($p.Links.Count) links removed as links)"
  } catch { Log "kept $d ($($_.Exception.Message))" }
}
Log "free space after: $([Math]::Round($drive.AvailableFreeSpace / 1GB, 1)) GB"
Log 'all done'
