# Workhorse runner helpers (#217, Opus, Nov 7 2026). PowerShell 5.1. Called by work_issue.bat and work_setup.bat.
# Usage:
#   work_issue.ps1 prep    <n> <arm> <repo> <out> <godot exe>   writes <repo>\WORK_TASK.md and <out>\title.txt
#   work_issue.ps1 balance <arm> <out file>                      writes the account balance (number and currency) or "unknown"
#   work_issue.ps1 keycheck <arm>                                 exit 0 if the saved key opens the provider's model list
#   work_issue.ps1 lasttext <events.jsonl>                        prints the agent's final text
#   work_issue.ps1 stats   <n> <arm> <out>                        reads events.jsonl, balances and times; writes stats.txt and last.md
#   work_issue.ps1 msg     <n> <arm> <out>                        writes commit.txt (becomes the PR description)
# Keys come from the environment (DEEPSEEK_API_KEY, MOONSHOT_API_KEY) and are never written to any file.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$utf8 = New-Object System.Text.UTF8Encoding($false)
$mode = $args[0]

function Arm-Info($arm) {
  switch ($arm) {
    { $_ -in 'deepseek','deepseekpro' } { return @{ base = 'https://api.deepseek.com'; key = $env:DEEPSEEK_API_KEY; models = 'https://api.deepseek.com/models'; bal = 'https://api.deepseek.com/user/balance' } }
    'kimi'     { return @{ base = 'https://api.moonshot.ai/v1'; key = $env:MOONSHOT_API_KEY; models = 'https://api.moonshot.ai/v1/models'; bal = 'https://api.moonshot.ai/v1/users/me/balance' } }
    default    { throw "unknown arm $arm" }
  }
}

function Read-Events($path) {
  $ev = @()
  if (-not (Test-Path $path)) { return $ev }
  foreach ($line in [IO.File]::ReadAllLines($path)) {
    $t = $line.Trim()
    if ($t.StartsWith('{')) { try { $ev += ,($t | ConvertFrom-Json) } catch { } }
  }
  return $ev
}

function Last-Text($ev) {
  $last = ''
  foreach ($e in $ev) { if ($e.type -eq 'text' -and $e.part.text) { $last = [string]$e.part.text } }
  return $last
}

function Read-Txt($p) { if (Test-Path $p) { return ([IO.File]::ReadAllText($p)).Trim() } else { return '' } }

if ($mode -eq 'prep') {
  $n = $args[1]; $arm = $args[2]; $repo = $args[3]; $out = $args[4]; $godot = $args[5]
  $i = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'voidsworn-workhorse' } -Uri "https://api.github.com/repos/rcbailey12/voidsworn/issues/$n"
  $task = @"
# Workhorse job: issue #$n, "$($i.title)"

You are the coding seat on the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/$n), doing the job Codex used to do.
This folder is a fresh checkout of main on the branch work/issue-$n-$arm. Follow AGENTS.md and CLAUDE.md, except the
"work in your own folder" rule: you are the main coding seat for this job, so edit the game files the job names.
Nobody is watching this run and nobody can answer questions. Make the sensible call, say what you chose in your report, and keep going.

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- No em dashes in anything you write. Plain words, plain ASCII.
- Do not commit and do not push: the runner does that after you finish.
- Keep scratch output (logs, temp files) out of this folder, in the system temp folder.
- Save the screenshots your report links to in $out\shots (create it). The reviewer sees that folder.
- Finish with a short report: what you changed (files), each check you ran and its result (paste the PASS or FAIL lines),
  anything you skipped and why. Your report goes at the top of the pull request description; the runner runs the standing
  checks and parity itself after you stop and adds their real rows under it, so write it for a reviewer.

Before you finish, check how your change reaches the rest of the game (the reviewer checks all five, so do it first):
- Callers: search the whole repo for every function, constant and save field you changed or added, and check or fix each use.
- Saves: a player profile or run save written before your change must still load and behave; say how you checked.
- Twins: rules that live in both the JS root files (battle.js, data.js and core.js) and the Godot port must change on both sides. The root files are the only copy (the oracle folders were deleted in PR 381). If you change one of them, re-export both tables (godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json) and run contrib/opus/tools/oracle_copy_test.js last; rules parity and campaign parity prove the two sides match.
- UI: every screen that shows what you changed (campaign map, intel, panels, HUD) must read the new value the same way.
- CI: a new test file must be added to contrib/opus/tools/run_all_checks.js, or GitHub never runs it; say which checks GitHub runs.
Put one line per item in your report with what you found.

How to run things on this PC (Windows 10; your shell is Git Bash):
- Standing checks: node contrib/opus/tools/run_all_checks.js
- Rules parity and campaign parity (needs Godot, a few minutes): cmd.exe //c "tools\\pc\\parity.bat nopause"
  It prints PASS or FAIL per check; campaign parity runs at the end. Both must PASS. One shell command may run up to
  30 minutes, so run parity in the foreground and wait for it.
- Godot 4 console exe: $godot
  Before any Godot run that loads scenes, UI or textures, import once: "$godot" --headless --path godot --import
- Screenshots of the campaign UI: godot/campaign/test/r1_ui_shots.gd is a worked example of a script that builds a campaign
  screen and saves a PNG (run it without --headless so it can capture). Copy its pattern for your own shot script.

## The job

$($i.body)
"@
  [IO.File]::WriteAllText((Join-Path $repo 'WORK_TASK.md'), $task, $utf8)
  [IO.File]::WriteAllText((Join-Path $out 'title.txt'), [string]$i.title, $utf8)
  Write-Host "issue #$n prepared for the $arm arm"
}
elseif ($mode -eq 'balance') {
  $arm = $args[1]; $file = $args[2]; $a = Arm-Info $arm; $v = 'unknown'
  try {
    $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ Authorization = "Bearer $($a.key)" } -Uri $a.bal
    if ($arm -like 'deepseek*') { $b = $r.balance_infos | Select-Object -First 1; $v = "$($b.total_balance) $($b.currency)" }
    else { $v = "$($r.data.available_balance) USD" }
  } catch { $v = 'unknown' }
  [IO.File]::WriteAllText($file, $v, [Text.Encoding]::ASCII)
  Write-Host $v
}
elseif ($mode -eq 'keycheck') {
  $arm = $args[1]; $a = Arm-Info $arm
  if (-not $a.key) { Write-Host 'no key saved'; exit 1 }
  try {
    $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ Authorization = "Bearer $($a.key)" } -Uri $a.models
    $ids = @($r.data | ForEach-Object { $_.id }) -join ', '
    Write-Host "key works; models: $ids"; exit 0
  } catch { Write-Host "key refused or no network: $($_.Exception.Message)"; exit 1 }
}
elseif ($mode -eq 'lasttext') {
  Write-Output (Last-Text (Read-Events $args[1]))
}
elseif ($mode -eq 'stats') {
  $n = $args[1]; $arm = $args[2]; $out = $args[3]
  $ev = Read-Events (Join-Path $out 'events.jsonl')
  $tin = 0; $tout = 0; $treason = 0; $tcr = 0; $tcw = 0; $cost = 0.0; $steps = 0; $tools = 0; $errs = 0
  foreach ($e in $ev) {
    if ($e.type -eq 'step_finish') {
      $steps++
      $k = $e.part.tokens
      if ($k) { $tin += [double]$k.input; $tout += [double]$k.output; $treason += [double]$k.reasoning; $tcr += [double]$k.cache.read; $tcw += [double]$k.cache.write }
      if ($e.part.cost) { $cost += [double]$e.part.cost }
    }
    elseif ($e.type -eq 'tool_use') { $tools++; if ($e.part.state.status -eq 'error') { $errs++ } }
  }
  $last = Last-Text $ev
  [IO.File]::WriteAllText((Join-Path $out 'last.md'), $last, $utf8)
  $b0 = Read-Txt (Join-Path $out 'balance_before.txt'); $b1 = Read-Txt (Join-Path $out 'balance_after.txt')
  $charge = 'unknown (read it on the provider console)'
  try {
    $x0 = [double]($b0 -split ' ')[0]; $x1 = [double]($b1 -split ' ')[0]
    $charge = '{0:N4} {1}' -f ($x0 - $x1), (($b0 -split ' ')[1])
  } catch { }
  $t0 = Read-Txt (Join-Path $out 'time_start.txt'); $t1 = Read-Txt (Join-Path $out 'time_agent_end.txt'); $t2 = Read-Txt (Join-Path $out 'time_pushed.txt')
  $mins = ''
  try { $mins = '{0:N1}' -f ((([datetime]$t1) - ([datetime]$t0)).TotalMinutes) } catch { }
  $s = @"
arm: $arm
model: $(Read-Txt (Join-Path $out 'model.txt'))
opencode exit: $(Read-Txt (Join-Path $out 'exit.txt'))
started: $t0
agent finished: $t1 ($mins minutes)
pushed: $t2
steps (model calls): $steps
tool calls: $tools (failed: $errs)
tokens: input $tin, output $tout, reasoning $treason, cache read $tcr, cache write $tcw
cost OpenCode estimated from its price table (USD): $('{0:N4}' -f $cost)
balance before: $b0
balance after: $b1
real charge (balance before minus after): $charge
"@
  [IO.File]::WriteAllText((Join-Path $out 'stats.txt'), $s, $utf8)
  Write-Host $s
}
elseif ($mode -eq 'msg') {
  $n = $args[1]; $arm = $args[2]; $out = $args[3]
  $title = Read-Txt (Join-Path $out 'title.txt')
  $last = Read-Txt (Join-Path $out 'last.md')
  if (-not $last) { $last = '(the agent left no final report; see board log on the PC)' }
  if ($last.Length -gt 6000) { $last = $last.Substring(0, 6000) + "`n(report cut at 6000 characters; full text on Ryan's PC in the run's out\last.md)" }
  $stats = Read-Txt (Join-Path $out 'stats.txt')
  $checks = Read-Txt (Join-Path $out 'checks.txt')
  if (-not $checks) { $checks = '(the runner wrote no check output for this run; see the run folder on the PC)' }
  $fence = '```'
  $msg = "Workhorse $arm arm (issue #$n): $title`n`n$last`n`n## Checks run by the runner`n`n$fence`n$checks`n$fence`n`n## Run stats (runner)`n`n$fence`n$stats`n$fence`n`nRefs #$n`n"
  [IO.File]::WriteAllText((Join-Path $out 'commit.txt'), $msg, $utf8)
}
else { Write-Host 'usage: work_issue.ps1 prep|balance|keycheck|lasttext|stats|msg ...'; exit 2 }
