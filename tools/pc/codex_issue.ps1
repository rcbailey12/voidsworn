# Prepare one job-board issue for Codex (called by codex_issue.bat). PowerShell 5.1.
# Usage: codex_issue.ps1 prep <n> <repo folder> <out folder>   writes CODEX_TASK.md, effort.txt, title.txt
#        codex_issue.ps1 msg  <n> <repo folder> <out folder>   writes commit.txt from title.txt and Codex's last message
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$mode = $args[0]; $n = $args[1]; $repo = $args[2]; $out = $args[3]
$utf8 = New-Object System.Text.UTF8Encoding($false)
if ($mode -eq 'prep') {
  if ($env:PC_RUNNER_TEST -eq '1') {
    $i = Get-Content -LiteralPath $env:PC_TEST_ISSUE -Raw | ConvertFrom-Json
  } else {
    $i = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn-codex-board' } `
      -Uri "https://api.github.com/repos/rcbailey12/voidsworn/issues/$n"
  }
  $resume = ''; $rp = Join-Path $out 'resume.txt'
  if (Test-Path -LiteralPath $rp) { $resume = [IO.File]::ReadAllText($rp) }
  $body = [string]$i.body
  $effort = 'high'
  if ($body -match '(?im)^\s*Effort \(Codex\):\s*(xhigh|high|medium)') { $effort = $Matches[1].ToLower() }
  $godot = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe'
  $task = @"
# Codex job: issue #$n, "$($i.title)"

You are Codex, working one job from the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/$n).
This folder is a fresh checkout of main on the branch codex/issue-$n. Follow AGENTS.md and CLAUDE.md in this folder.
$resume

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- Run the check the job's "Done when" line names. The standing checks run with: node contrib/opus/tools/run_all_checks.js
  Godot, if a check needs it: $godot (use --headless).
- No em dashes in anything you write. Plain words.
- Do not commit and do not push: the runner does that after you finish.
- Keep scratch output (logs, temp checks) in %TEMP%, not in this folder.
- Save the screenshots, sheets and recordings your report links to in $out\shots (create it). Opus can only see that folder,
  not %TEMP%; link them there in your report.
- Finish with a short report: what you changed (files), the checks you ran and their result, anything you skipped and why.
  That report becomes the pull request description, so write it for a reviewer.

## The job

$body
"@
  [IO.File]::WriteAllText((Join-Path $repo 'CODEX_TASK.md'), $task, $utf8)
  [IO.File]::WriteAllText((Join-Path $out 'effort.txt'), $effort, [Text.Encoding]::ASCII)
  [IO.File]::WriteAllText((Join-Path $out 'title.txt'), [string]$i.title, $utf8)
  $dl = ''; if ($body -match '(?im)^\s*Deliver to:\s*(.+?)\s*$') { $dl = $Matches[1] }
  [IO.File]::WriteAllText((Join-Path $out 'deliver_to.txt'), $dl, $utf8)
  Write-Host "issue #$n prepared, effort $effort"
} elseif ($mode -eq 'msg') {
  # Keep Codex's scratch folders out of the commit (it sometimes leaves .codex-* check output in the repo).
  $ErrorActionPreference = 'Continue'
  Push-Location $repo
  Get-ChildItem -Force -Directory -Filter '.codex*' | ForEach-Object { & 'C:\Program Files\Git\cmd\git.exe' rm -r -q --cached --ignore-unmatch -- $_.Name | Out-Null; Remove-Item -Recurse -Force $_.FullName }
  Pop-Location
  $ErrorActionPreference = 'Stop'
  $title = [IO.File]::ReadAllText((Join-Path $out 'title.txt'))
  $last = ''
  $lp = Join-Path $out 'last.md'
  if (Test-Path $lp) { $last = [IO.File]::ReadAllText($lp) }
  if ($last.Length -gt 6000) { $last = $last.Substring(0, 6000) + "`n(report cut at 6000 characters; full text on Ryan's PC in board\issue-$n\last.md)" }
  $checks = ''
  foreach ($file in @('checks_node.txt','checks_parity.txt')) {
    $cp = Join-Path $out $file
    if (Test-Path -LiteralPath $cp) { $checks += "`n$file`n" + [IO.File]::ReadAllText($cp) }
  }
  $msg = "Codex (issue #$n): $title`n`n$last`n`nRunner checks:`n$checks`n`nRefs #$n`n"
  [IO.File]::WriteAllText((Join-Path $out 'commit.txt'), $msg, $utf8)
} else { Write-Host 'usage: codex_issue.ps1 prep|msg <n> <repo> <out>'; exit 2 }
