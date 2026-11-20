# Issue 1180 oneoff2 (Ryan approves once): remove board kept copies and idle helper folders the janitor cannot prove safe,
# from the Board's reviewed list CLEAN_1180_ONEOFF2_list.txt: "<full path> | issue <N> | <evidence>" per line, # for notes.
# Each path is checked again now: it must exist as a plain folder under voidsworn_test\board*\repo-kept-* or
# voidsworn_test\opus<N>[out...], not be on janitor_keep.txt, not be named by a running program, hold no links, and have
# no file outside .git written in the last hour (git's own housekeeping touches .git; the probe saw no process). A helper folder's lease is taken and held while it is removed. Ryan types YES once.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$listFile = Join-Path $here 'CLEAN_1180_ONEOFF2_list.txt'
$logFile = Join-Path $here 'CLEAN_1180_ONEOFF2_log.txt'
$vt = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$cutoff = (Get-Date).AddHours(-1)
function Log($t) { Add-Content -LiteralPath $logFile -Value $t; Write-Host $t }
function Walk($dir) {
  $bytes = 0L; $newest = [DateTime]::MinValue; $links = 0
  $stack = New-Object 'Collections.Generic.Stack[string]'; $stack.Push($dir)
  while ($stack.Count) {
    foreach ($i in @((New-Object IO.DirectoryInfo($stack.Pop())).EnumerateFileSystemInfos())) {
      if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { $links++; continue }
      if ($i -is [IO.DirectoryInfo]) { $stack.Push($i.FullName); continue }
      $bytes += $i.Length
      if ($i.LastWriteTime -gt $newest -and $i.FullName -notmatch '\\\.git\\') { $newest = $i.LastWriteTime }
    }
  }
  return [pscustomobject]@{ Bytes = $bytes; Newest = $newest; Links = $links }
}
$keep = @()
$keepFile = Join-Path $vt 'janitor_keep.txt'
if (Test-Path -LiteralPath $keepFile) {
  $keep = @([IO.File]::ReadAllLines($keepFile) | ForEach-Object { $_.Trim().TrimStart([char]0xFEFF) } | Where-Object { $_ -and -not $_.StartsWith('#') } |
    ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') })
}
Log "oneoff2 cleanup started $(Get-Date -Format o)"
$drive = New-Object IO.DriveInfo('C')
Log "free space before: $([Math]::Round($drive.AvailableFreeSpace / 1GB, 1)) GB"
try { $procs = @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine } | ForEach-Object { $_.CommandLine }) }
catch { Log 'stopped: running programs could not be checked; nothing removed'; Log 'all done'; exit 1 }
$plan = @()
foreach ($line in [IO.File]::ReadAllLines($listFile)) {
  $t = $line.Trim()
  if (-not $t -or $t.StartsWith('#')) { continue }
  $parts = $t -split '\|'
  $full = [IO.Path]::GetFullPath($parts[0].Trim()).TrimEnd('\')
  $label = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
  $rel = if ($full.StartsWith($vt + '\', [StringComparison]::OrdinalIgnoreCase)) { $full.Substring($vt.Length + 1) } else { '' }
  if ($rel -notmatch '\Aboard[a-z_]*\\repo-kept-[0-9a-f]{32}\z' -and $rel -notmatch '\Aopus[1-9][0-9]*(out[^\\]*)?\z') { Log "skip (not a board kept copy or helper folder): $full"; continue }
  $item = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
  if (-not $item) { Log "skip (already gone): $full"; continue }
  if ($item -isnot [IO.DirectoryInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Log "skip (not a plain folder): $full"; continue }
  if ($keep | Where-Object { $_ -eq $full -or $_.StartsWith($full + '\', [StringComparison]::OrdinalIgnoreCase) -or $full.StartsWith($_ + '\', [StringComparison]::OrdinalIgnoreCase) }) { Log "skip (on the Board keep list): $full"; continue }
  $needle = [regex]::Escape($full) + '(?=$|[\\/"''\s])'
  if ($procs | Where-Object { $_ -match $needle }) { Log "skip (a running program names it): $full"; continue }
  try { $m = Walk $full } catch { Log "skip (could not read: $($_.Exception.Message)): $full"; continue }
  if ($m.Links) { Log "skip (holds $($m.Links) links): $full"; continue }
  if ($m.Newest -gt $cutoff) { Log "skip (a file outside .git changed in the last hour, $($m.Newest)): $full"; continue }
  $plan += ,[pscustomobject]@{ Path = $full; Bytes = $m.Bytes; Label = $label }
  Write-Host ("{0,8:N1} GB  {1:yyyy-MM-dd}  {2,-12} {3}" -f ($m.Bytes / 1GB), $m.Newest, $label, $full)
}
if (-not $plan.Count) { Log 'nothing to remove'; Log 'all done'; exit 0 }
$total = ($plan | Measure-Object -Property Bytes -Sum).Sum
Write-Host ''
Write-Host ("{0} folders, {1:N1} GB. Type YES to delete exactly these, anything else to stop." -f $plan.Count, ($total / 1GB))
if ((Read-Host) -cne 'YES') { Log 'stopped: Ryan did not type YES; nothing removed'; Log 'all done'; exit 0 }
foreach ($p in $plan) {
  $lease = $null
  try {
    $leasePath = Join-Path $p.Path '.voidsworn-run-active'
    if (Test-Path -LiteralPath $leasePath) {
      try { $lease = [IO.File]::Open($leasePath, 'Open', 'Read', 'None') } catch { throw 'a helper run holds its lease' }
    }
    if ((Walk $p.Path).Links) { throw 'a link appeared' }
    foreach ($c in @((New-Object IO.DirectoryInfo($p.Path)).EnumerateFileSystemInfos())) {
      if ($c.FullName -eq $leasePath) { continue }
      if ($c -is [IO.DirectoryInfo]) {
        # rd with the \\?\ prefix handles the long Godot cache paths PowerShell 5.1 cannot; no links remain to follow.
        & cmd.exe /d /c "rd /s /q `"\\?\$($c.FullName)`"" | Out-Null
        if (Test-Path -LiteralPath $c.FullName) { throw "could not remove $($c.Name) (in use or too long)" }
      } else { Remove-Item -LiteralPath $c.FullName -Force }
    }
    if ($lease) { $lease.Dispose(); $lease = $null; [IO.File]::Delete($leasePath) }
    [IO.Directory]::Delete($p.Path, $false)
    Log "removed $($p.Path) ($($p.Bytes) bytes, $($p.Label))"
  } catch { Log "kept $($p.Path) ($($_.Exception.Message))" }
  finally { if ($lease) { $lease.Dispose() } }
}
Log "free space after: $([Math]::Round($drive.AvailableFreeSpace / 1GB, 1)) GB"
Log 'all done'
