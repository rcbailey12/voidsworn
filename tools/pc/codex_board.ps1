# Codex job-board poller (Ryan, Nov 2 2026, FINDINGS R75). PowerShell 5.1.
# Looks once at the open GitHub issues labeled "codex" (and not "blocked"). For each one that has no
# open codex/issue-<n> pull request and hasn't been queued before, it drops a lane B job that runs codex_issue.bat <n>.
# codex_board.bat calls this every 10 minutes. Reading the board needs no sign-in (the repo is public).
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root  = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$state = Join-Path $root 'board\queued.txt'
$queue = Join-Path $root 'queue_b'
New-Item -ItemType Directory -Force -Path (Join-Path $root 'board') | Out-Null
if (-not (Test-Path $state)) { New-Item -ItemType File -Path $state | Out-Null }
$done = @(Get-Content $state | Where-Object { $_ -match '^\d+$' })
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
try {
  $issues = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn-codex-board' } `
    -Uri 'https://api.github.com/repos/rcbailey12/voidsworn/issues?labels=codex&state=open&per_page=50&sort=created&direction=asc'
} catch { Write-Host "[$stamp] board not reachable: $($_.Exception.Message)"; exit 0 }
$git = 'C:\Program Files\Git\cmd\git.exe'
$found = 0
foreach ($i in $issues) {
  if ($i.pull_request) { continue }
  $labels = @($i.labels | ForEach-Object { $_.name })
  if ($labels -contains 'blocked') { continue }
  $n = [string]$i.number
  if ($done -contains $n) { continue }
  # Nov 4: skip only while a PR from codex/issue-<n> is still open. A merged or closed PR leaves its branch behind
  # (branches cannot be deleted from Opus's sandbox), and an issue reopened for another run must still be queued.
  try {
    $open = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn-codex-board' } `
      -Uri "https://api.github.com/repos/rcbailey12/voidsworn/pulls?state=open&head=rcbailey12:codex/issue-$n"
  } catch { continue }
  if (@($open).Count -gt 0) { Add-Content $state $n; continue }
  $job = Join-Path $queue "cx_issue$($n)_job.bat"
  $line = 'call "%USERPROFILE%\Downloads\voidsworn_test\build_b\tools\pc\codex_issue.bat" ' + $n
  Set-Content -Path $job -Value "@echo off`r`n$line`r`n" -Encoding ASCII
  Add-Content $state $n
  Write-Host "[$stamp] queued issue #$n for Codex: $($i.title)"
  $found++
}
if ($found -eq 0) { Write-Host "[$stamp] nothing new on the board" }
