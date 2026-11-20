# Issue 1180 (Board, Nov 20): the end of a queue job's owned TEMP scratch (ship_job.bat, look_bench.bat).
# Usage: scratch_done.ps1 <scratch folder> <job exit code> <base TEMP> <job key>
#   exit 0 : the scratch goes now (links removed as links, never followed).
#   other  : the scratch is kept for a day with a .voidsworn-run-failed marker naming the job; older failed scratch of the
#            same job goes, so each job keeps only its newest failure. The janitor removes it after that day.
# Only a folder named voidsworn-run-<32 hex> directly under the base TEMP, carrying a valid .voidsworn-run-owner token
# and no held .voidsworn-run-active marker, is touched. Every problem is logged and leaves the folder for the janitor.
# The Board's PC pause (gpu_go.txt, RULEBOOK 3.11) removes nothing: it is checked right before every removal.
param([string]$Scratch, [int]$Code, [string]$BaseTemp, [string]$JobKey)
$ErrorActionPreference = 'Stop'
function Test-Owned($dir) {
  $item = Get-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue
  if ($item -isnot [IO.DirectoryInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $null }
  if ($item.Name -cnotmatch '\Avoidsworn-run-[0-9a-f]{32}\z') { return $null }
  if ([IO.Path]::GetFullPath($item.Parent.FullName).TrimEnd('\', '/') -ne [IO.Path]::GetFullPath($BaseTemp).TrimEnd('\', '/')) { return $null }
  $owner = Get-Item -LiteralPath (Join-Path $item.FullName '.voidsworn-run-owner') -Force -ErrorAction SilentlyContinue
  if ($owner -isnot [IO.FileInfo] -or $owner.Length -ne 32 -or [IO.File]::ReadAllText($owner.FullName) -cnotmatch '\A[0-9a-f]{32}\z') { return $null }
  return $item
}
function Test-Paused {
  # The same pause line runner_common.ps1 Cleanup-Paused reads. Tests point PC_CLEANUP_PAUSE_FILE at a fixture.
  $flag = if ($env:PC_RUNNER_TEST -ceq '1' -and $env:PC_CLEANUP_PAUSE_FILE) { $env:PC_CLEANUP_PAUSE_FILE }
    elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\gpu_go.txt' } else { $null }
  if (-not $flag -or -not (Test-Path -LiteralPath $flag -PathType Leaf)) { return $false }
  return [string](Get-Content -LiteralPath $flag -TotalCount 1) -match '^GPU not cleared: paused by the Board\b'
}
function Assert-NotPaused { if (Test-Paused) { throw 'PC pause is active' } }
function Assert-Idle($dir) {
  $marker = Join-Path $dir '.voidsworn-run-active'
  if (Test-Path -LiteralPath $marker) {
    try { $h = [IO.File]::Open($marker, 'Open', 'Read', 'None'); $h.Dispose() } catch { throw 'its tools are still running' }
  }
}
function Remove-LinkSafeTree($root) {
  $dirs = New-Object 'Collections.Generic.List[string]'
  $pending = New-Object 'Collections.Generic.Stack[IO.DirectoryInfo]'
  $pending.Push((Get-Item -LiteralPath $root -Force))
  while ($pending.Count) {
    $next = $pending.Pop(); $dirs.Add($next.FullName)
    foreach ($entry in @($next.EnumerateFileSystemInfos())) {
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($entry -is [IO.DirectoryInfo]) { [IO.Directory]::Delete($entry.FullName, $false) } else { [IO.File]::Delete($entry.FullName) }
      } elseif ($entry -is [IO.DirectoryInfo]) { $pending.Push($entry) }
      else { $entry.Attributes = [IO.FileAttributes]::Normal; [IO.File]::Delete($entry.FullName) }
    }
  }
  for ($i = $dirs.Count - 1; $i -ge 0; $i--) { [IO.Directory]::Delete($dirs[$i], $false) }
}
try {
  $dir = Test-Owned $Scratch
  if (-not $dir) { Write-Output "job scratch left for the janitor (not an owned voidsworn-run folder under $BaseTemp): $Scratch"; exit 0 }
  Assert-Idle $dir.FullName
  if ($Code -eq 0) {
    Assert-NotPaused
    Remove-LinkSafeTree $dir.FullName
    Write-Output "job scratch removed after PASS: $($dir.FullName)"
    exit 0
  }
  $key = ($JobKey -replace '[\r\n]', ' ').Trim()
  [IO.File]::WriteAllText((Join-Path $dir.FullName '.voidsworn-run-failed'), $key)
  Write-Output "job scratch kept for a day after exit $Code (newest failure of $key): $($dir.FullName)"
  foreach ($old in @((Get-Item -LiteralPath $BaseTemp -Force).EnumerateDirectories('voidsworn-run-*'))) {
    if ($old.FullName -eq $dir.FullName) { continue }
    try {
      if (-not (Test-Owned $old.FullName)) { continue }
      $marker = Join-Path $old.FullName '.voidsworn-run-failed'
      if (-not (Test-Path -LiteralPath $marker -PathType Leaf) -or [IO.File]::ReadAllText($marker) -cne $key) { continue }
      Assert-Idle $old.FullName
      Assert-NotPaused
      Remove-LinkSafeTree $old.FullName
      Write-Output "older failed scratch of the same job removed: $($old.FullName)"
    } catch { Write-Output "older failed scratch kept: $($old.FullName) ($($_.Exception.Message))" }
  }
} catch { Write-Output "job scratch left for the janitor: $Scratch ($($_.Exception.Message))" }
exit 0
