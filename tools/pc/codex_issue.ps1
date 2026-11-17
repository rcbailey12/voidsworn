# Prepare one job-board issue for Codex (called by codex_issue.bat). PowerShell 5.1.
# Usage: codex_issue.ps1 prep <n> <repo folder> <out folder>   writes CODEX_TASK.md, effort.txt, title.txt
#        codex_issue.ps1 msg  <n> <repo folder> <out folder>   writes commit.txt from title.txt and Codex's last message
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$mode = $args[0]; $n = $args[1]; $repo = $args[2]; $out = $args[3]
$utf8 = New-Object System.Text.UTF8Encoding($false)
# Issue 953: the report and the runner check logs carry PC paths. A path to a file inside this job's checkout becomes a
# GitHub link on the delivery branch, so it opens on a phone; every other path under the user's home folder becomes
# %USERPROFILE%\..., so no PC folder name reaches a public pull request. Everything else is left exactly as written.
function Path-Pattern([string]$p) {
  if (-not $p) { return '' }
  # Either separator matches, whatever the host wrote: every joined separator is [\\/]+, and a leading
  # separator (a Unix absolute path) is part of the match so none is left in front of the replacement.
  $lead = ''
  if ($p -match '^[\\/]') { $lead = '[\\/]+' }
  $segs = @($p -split '[\\/]+' | Where-Object { $_ -ne '' })
  if (-not $segs.Count) { return '' }
  return $lead + (@($segs | ForEach-Object { [regex]::Escape($_) }) -join '[\\/]+')
}
function Profile-Root {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  if ($env:HOME) { return $env:HOME }
  return ''
}
function Rewrite-ReportPaths([string]$text, [string]$repo, [string]$branch, [string]$profileRoot) {
  if (-not $text) { return $text }
  $repoPat = Path-Pattern $repo
  if ($repoPat) {
    $tail = '([\\/][^\s\)\]\>"' + [char]39 + [char]96 + ',;]*)'
    $rx = New-Object System.Text.RegularExpressions.Regex ('(?i)' + $repoPat + $tail)
    $text = $rx.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{
      param($m)
      $rel = $m.Groups[1].Value -replace '\\', '/'
      $trail = ''
      $t2 = [regex]::Match($rel, '^(.*?)([.,;:]+)$')
      if ($t2.Success) { $rel = $t2.Groups[1].Value; $trail = $t2.Groups[2].Value }
      return 'https://github.com/rcbailey12/voidsworn/blob/' + $branch + $rel + $trail
    })
  }
  $homePat = Path-Pattern $profileRoot
  if ($homePat) {
    $homeTail = '([\\/][^\s\)\]\>"' + [char]39 + [char]96 + ',;]*)?'
    $hx = New-Object System.Text.RegularExpressions.Regex ('(?i)' + $homePat + $homeTail)
    $text = $hx.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{
      param($m)
      $rest = $m.Groups[1].Value
      if ($rest) { $rest = $rest.Substring(1) }
      $trail = ''
      $t2 = [regex]::Match($rest, '^(.*?)([.,;:]+)$')
      if ($t2.Success) { $rest = $t2.Groups[1].Value; $trail = $t2.Groups[2].Value }
      if ($rest) { return '%USERPROFILE%\' + $rest + $trail } else { return '%USERPROFILE%' + $trail }
    })
  }
  return $text
}

if ($mode -eq 'prep') {
  $i = Get-Content -LiteralPath (Join-Path $out 'validated_issue.json') -Raw | ConvertFrom-Json
  $state = Get-Content -LiteralPath (Join-Path $out 'status.json') -Raw | ConvertFrom-Json
  if ($i.number -ne $n -or $i.run -ne $state.run -or $state.instruction_run -ne $state.run -or $state.status -ne 'running') {
    throw 'job preparation refused: no validated current instruction for this run; no agent started'
  }
  $body = [string]$i.body
  $bodyFile = Join-Path $out 'issue_body.txt'
  [IO.File]::WriteAllText($bodyFile, $body, $utf8)
  & (Join-Path $PSScriptRoot 'runner_common.ps1') base $repo $out $bodyFile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $resume = ''; $rp = Join-Path $out 'resume.txt'
  if (Test-Path -LiteralPath $rp) { $resume = [IO.File]::ReadAllText($rp) }
  $body = [string]$i.body
  $effort = 'high'
  if ($body -match '(?im)\bEffort \(Codex\):[ \t]*(xhigh|high|medium)\b') { $effort = $Matches[1].ToLower() }
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
- Never edit anything under .github/workflows (the PC token has no workflow scope, so the push is refused): if CI needs a change, say exactly what in your report.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Lane C is code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp checks) in %TEMP%, not in this folder.
- Save review pictures and their .provenance.json sidecars in $out\shots (create it). The runner copies linked stamped
  pictures into docs/shots/issue-$n-codex and rewrites links to repo paths before publishing. Never link other PC paths.
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
  if (Test-Path -LiteralPath (Join-Path $out 'stop_reason.txt')) {
    $reason = [IO.File]::ReadAllText((Join-Path $out 'stop_reason.txt')).Trim()
    if ($reason) { $msg += "`n" + [IO.File]::ReadAllText((Join-Path $out 'resume.txt')) }
  }
  # Issue 953: the delivery branch is the one the .bat pushes this run to (a partial run takes -partial).
  $branch = "codex/issue-$n"
  $pp = Join-Path $out 'partial.txt'
  if ((Test-Path -LiteralPath $pp) -and ([IO.File]::ReadAllText($pp)).Trim()) { $branch += '-partial' }
  $msg = Rewrite-ReportPaths $msg $repo $branch (Profile-Root)
  [IO.File]::WriteAllText((Join-Path $out 'commit.txt'), $msg, $utf8)
} else { Write-Host 'usage: codex_issue.ps1 prep|msg <n> <repo> <out>'; exit 2 }
