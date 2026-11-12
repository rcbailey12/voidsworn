# Workhorse runner helpers (#217, Opus, Nov 7 2026). PowerShell 5.1. Called by work_issue.bat and work_setup.bat.
# Usage:
#   work_issue.ps1 prep    <n> <arm> <repo> <out> <godot exe>   writes <repo>\WORK_TASK.md and <out>\title.txt
#   work_issue.ps1 balance <arm> <out file>                      writes the account balance (number and currency) or "unknown"
#   work_issue.ps1 keycheck <arm>                                 exit 0 if the saved key opens the provider's model list
#   work_issue.ps1 lasttext <events.jsonl>                        prints the agent's final text
#   work_issue.ps1 stats   <n> <arm> <out>                        reads events.jsonl, balances and times; writes stats.txt and last.md
#   work_issue.ps1 msg     <n> <arm> <out>                        writes commit.txt (becomes the PR description)
# Runner 2 (issue 377, Opus, Nov 12 2026); codex_issue.bat uses these three too:
#   work_issue.ps1 guard   <n> <tag> <repo> <out>                 the refuse list and the Deliver to warning, on the staged change
#   work_issue.ps1 commit  <repo> <out> <branch> <real|dry|test>  one commit that keeps the branch's earlier tip, checked before push
#   work_issue.ps1 confirm <repo> <out> <branch> <real|dry|test>  after the push: GitHub's branch must carry exactly out\diffstat.txt
#   work_issue.ps1 tidy    <run folder> <root> <settings> <ok> <dry>  run folder size; removes repo\ only if Ryan's setting allows
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

# ---- Runner 2 helpers (issue 377) ----
# git's output as an array of lines; $script:gx holds its exit code. stderr is dropped (PowerShell 5.1 turns it into errors).
function Git-Lines { $o = & git @args 2>$null; $script:gx = $LASTEXITCODE; if ($null -eq $o) { return @() }; return @($o | ForEach-Object { [string]$_ }) }
function Git-One { $o = @(Git-Lines @args); if ($o.Count) { return $o[0].Trim() } else { return '' } }
function Write-Lines($path, $lines) { [IO.File]::WriteAllText($path, ((@($lines) -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false))) }
function Read-Lines($path) { if (-not (Test-Path -LiteralPath $path)) { return @() }; return @([IO.File]::ReadAllLines($path) | Where-Object { $_ -ne '' }) }
# Folders and files named on the issue's "Deliver to" line (anything with a slash, or a file name with an extension).
function Scope-Paths($dl) {
  $res = @()
  if (-not $dl) { return $res }
  $t = $dl -replace '[`"''()\[\]]', ' '
  foreach ($m in [regex]::Matches($t, '[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-<>*{}]*)+|[A-Za-z0-9_\-]+\.[A-Za-z0-9]{1,5}\b')) {
    $p = $m.Value
    $cut = $p.IndexOfAny([char[]]'<*{'); if ($cut -ge 0) { $p = $p.Substring(0, $cut) }
    $p = $p.TrimEnd('.', ',', ';', ':').TrimEnd('/')
    if ($p.Length -ge 2) { $res += $p }
  }
  return $res
}
function In-Scope($p, $scope) {
  foreach ($s in $scope) { if ($p -ieq $s -or $p.StartsWith($s + '/', [StringComparison]::OrdinalIgnoreCase)) { return $true } }
  return $false
}
# Why a staged file may not be committed, or $null. The second line of defence behind godot/.gitignore (R144).
function Refuse-Reason($st, $p, $repo, $maxMb) {
  $lp = $p.ToLower()
  if ($lp.StartsWith('godot/gen/')) { return 'under godot/gen (built on the PC, never committed)' }
  if ($lp.StartsWith('godot/.godot/')) { return "under godot/.godot (Godot's import cache)" }
  if ($p -match '^godot/assets/ships/([^/]+)/' -and $Matches[1] -notin @('previews', 'test')) { return "ship files under godot/assets/ships/$($Matches[1])/ (PC-built, never committed)" }
  if ($lp.EndsWith('.uid') -and $st -eq 'A') { return 'a new .uid file (Godot makes these)' }
  if ($lp.EndsWith('.import') -and $st -eq 'M') { return 'a re-saved .import file (Godot rewrites these on import)' }
  if ($lp.EndsWith('.import') -and $st -eq 'A') { return 'a new .import file (Godot makes these)' }
  if ($st -eq 'A' -or $st -eq 'M') {
    $f = Join-Path $repo ($p -replace '/', '\')
    if (Test-Path -LiteralPath $f) {
      $mb = (Get-Item -LiteralPath $f -Force).Length / 1MB
      if ($mb -gt $maxMb) { return ('{0:N1} MB, over the {1} MB limit (WORK_MAX_FILE_MB)' -f $mb, $maxMb) }
    }
  }
  return $null
}
# The staged change, kept as a patch beside the run when the runner stops before a push.
function Save-Patch($out, $pre) { & git diff --cached --binary "--output=$(Join-Path $out 'change.patch')" $pre 2>$null }

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
  # The issue's "Deliver to" line: the guard step warns about changed files outside it (issue 377).
  $dl = ''
  if ([string]$i.body -match '(?im)^\s*Deliver to:\s*(.+?)\s*$') { $dl = $Matches[1] }
  [IO.File]::WriteAllText((Join-Path $out 'deliver_to.txt'), $dl, $utf8)
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
elseif ($mode -eq 'guard') {
  # After git add -A: refuse what must never be committed, keep a copy of it in out\refused (never deleted), and warn
  # about changed files outside the issue's Deliver to line. Writes refused.txt, scope_warnings.txt and guard.md.
  $ErrorActionPreference = 'Continue'
  $n = $args[1]; $tag = $args[2]; $repo = $args[3]; $out = $args[4]
  $maxMb = 8; if ($env:WORK_MAX_FILE_MB) { $maxMb = [double]$env:WORK_MAX_FILE_MB }
  Push-Location $repo
  $staged = @(Git-Lines -c core.quotepath=off diff --cached --name-status --no-renames)
  if ($gx -ne 0) { Write-Host 'guard failed: git could not list the staged change'; Pop-Location; exit 1 }
  $dlFile = Join-Path $out 'deliver_to.txt'
  $dl = Read-Txt $dlFile
  if (-not (Test-Path $dlFile)) {
    try {
      $i = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 -Headers @{ 'User-Agent' = 'voidsworn-runner' } -Uri "https://api.github.com/repos/rcbailey12/voidsworn/issues/$n"
      if ([string]$i.body -match '(?im)^\s*Deliver to:\s*(.+?)\s*$') { $dl = $Matches[1] }
      [IO.File]::WriteAllText($dlFile, $dl, $utf8)
    } catch { }
  }
  $scope = @(Scope-Paths $dl)
  $refused = @(); $warn = @()
  foreach ($l in $staged) {
    $parts = $l -split "`t", 2
    if ($parts.Count -lt 2) { continue }
    $st = $parts[0].Substring(0, 1); $p = $parts[1]
    $why = Refuse-Reason $st $p $repo $maxMb
    if ($why) { $refused += [pscustomobject]@{ S = $st; P = $p; Why = $why }; continue }
    if ($p -like "docs/shots/issue-$n-$tag/*") { continue }
    if ($scope.Count -and -not (In-Scope $p $scope)) { $warn += "$st $p" }
  }
  $keep = Join-Path $out 'refused'
  $bad = @()
  foreach ($r in $refused) {
    if ($r.S -ne 'D') {
      $src = Join-Path $repo ($r.P -replace '/', '\'); $dst = Join-Path $keep ($r.P -replace '/', '\')
      try { New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; Copy-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop } catch { $bad += "copy failed: $($r.P)" }
    }
    & git reset -q -- ":(literal)$($r.P)" 2>$null
  }
  # The refused files must be out of the commit now (they stay in the working folder and in out\refused).
  $after = @(Git-Lines -c core.quotepath=off diff --cached --name-only --no-renames)
  foreach ($r in $refused) { if ($after -contains $r.P) { $bad += "still staged: $($r.P)" } }
  $rl = @($refused | ForEach-Object { "$($_.S) $($_.P): $($_.Why)" })
  Write-Lines (Join-Path $out 'refused.txt') $rl
  Write-Lines (Join-Path $out 'scope_warnings.txt') $warn
  $md = @()
  if ($refused.Count) {
    Write-Host "REFUSED $($refused.Count) file(s): not committed, copies kept in out\refused (never deleted):"
    $rl | ForEach-Object { Write-Host "  $_" }
    $md += "Refused by the runner, not committed ($($refused.Count); copies kept on the PC in the run's out\refused):"
    $md += @($rl | Select-Object -First 30 | ForEach-Object { "- $_" })
    if ($rl.Count -gt 30) { $md += "- and $($rl.Count - 30) more (out\refused.txt on the PC)" }
    $md += ''
  } else { Write-Host 'refuse list: nothing refused' }
  if (-not $scope.Count) {
    Write-Host 'scope: no folders found on the issue''s Deliver to line, so nothing was checked against it'
    $md += 'Scope: no folders found on the issue''s Deliver to line; not checked.'
  } elseif ($warn.Count) {
    Write-Host "WARNING: $($warn.Count) changed file(s) outside the issue's Deliver to ($($scope -join ', ')):"
    $warn | ForEach-Object { Write-Host "  $_" }
    $md += "Warning: changed outside the issue's Deliver to ($($scope -join ', ')):"
    $md += @($warn | Select-Object -First 30 | ForEach-Object { "- $_" })
    if ($warn.Count -gt 30) { $md += "- and $($warn.Count - 30) more (out\scope_warnings.txt on the PC)" }
  } else { Write-Host "scope: every changed file is inside the issue's Deliver to" }
  Write-Lines (Join-Path $out 'guard.md') $md
  Pop-Location
  if ($bad.Count) { Write-Host 'guard failed:'; $bad | ForEach-Object { Write-Host "  $_" }; exit 1 }
  exit 0
}
elseif ($mode -eq 'commit') {
  # One commit for the run, made with git's plumbing (no hooks, no editor, its exit code checked). Its parents are the
  # agent's HEAD (with any merge the agent made under it) and the branch's earlier tip on GitHub, so a rerun pushes as a
  # fast-forward with no force and the earlier run stays reachable. Then the check the issue 541 trap needs: the commit
  # must carry exactly the staged change (out\diffstat.txt). The author is git's own identity, or GIT_AUTHOR_* and
  # GIT_COMMITTER_* when the calling .bat sets them. Exit 0 ready to push, 7 nothing to commit, 10 diff mismatch,
  # 11 commit failed, 12 the branch's earlier tip could not be read.
  $ErrorActionPreference = 'Continue'
  $repo = $args[1]; $out = $args[2]; $br = $args[3]; $push = $args[4]
  $fault = ''; if ($push -ne 'real' -and $env:WORK_TEST_FAULT) { $fault = $env:WORK_TEST_FAULT }
  Push-Location $repo
  $pre = Git-One rev-parse HEAD
  [IO.File]::WriteAllText((Join-Path $out 'pre_commit.txt'), $pre, [Text.Encoding]::ASCII)
  & git diff --cached --quiet 2>$null
  if ($LASTEXITCODE -eq 0) { Write-Host 'nothing left to commit after the refuse list'; Pop-Location; exit 7 }
  $num = @(Git-Lines -c core.quotepath=off diff --cached --numstat --no-renames)
  Write-Lines (Join-Path $out 'diff_numstat.txt') $num
  Write-Lines (Join-Path $out 'diffstat.txt') @(Git-Lines -c core.quotepath=off diff --cached --stat --no-renames)
  # The branch's earlier tip (an earlier run, or the Board's own fix-ups): kept, never overwritten.
  $old = ''
  $ls = @(Git-Lines ls-remote origin "refs/heads/$br")
  if ($gx -ne 0) { Write-Host "push stopped: could not read branch $br on GitHub, the check failed; change kept as out\change.patch"; Save-Patch $out $pre; Pop-Location; exit 12 }
  if ($ls.Count) {
    $want = ($ls[0] -split '\s+')[0]
    & git fetch -q --depth 1 origin "+refs/heads/${br}:refs/remotes/origin/runner-prev" 2>$null
    $old = Git-One rev-parse -q --verify 'refs/remotes/origin/runner-prev^{commit}'
    if (-not $old) { Write-Host "push stopped: could not fetch the earlier tip $want of $br, the check failed; change kept as out\change.patch"; Save-Patch $out $pre; Pop-Location; exit 12 }
  }
  [IO.File]::WriteAllText((Join-Path $out 'prev_tip.txt'), $old, [Text.Encoding]::ASCII)
  $runNo = 1
  if ($old) {
    $runNo = 2
    $om = (Git-Lines log -1 --format=%B $old) -join "`n"
    if ($om -match '(?m)^Run-Number: (\d+)') { $runNo = [int]$Matches[1] + 1 }
  }
  # The message: the runner's text (commit.txt) plus the runner's own block. Never empty (issue 541: an empty
  # commit.txt made the old runner's commit abort, and its push carried only the agent's merge commit).
  $msg = ''
  $cp = Join-Path $out 'commit.txt'
  if (Test-Path $cp) { $msg = [IO.File]::ReadAllText($cp) }
  $n = ''; if ($br -match 'issue-(\d+)') { $n = $Matches[1] }
  if (-not $msg.Trim()) { $msg = "Runner commit for $br (the message step left no text; the agent's report is in the run's out folder on the PC)`n`nRefs #$n`n"; Write-Host 'WARNING: commit.txt was empty, the runner wrote a plain message' }
  $partial = Read-Txt (Join-Path $out 'partial.txt')
  $guard = Read-Txt (Join-Path $out 'guard.md')
  $base = Read-Txt (Join-Path $out 'base_commit.txt')
  $block = "## Runner (issue 377)`n`n"
  if ($partial) {
    $msg = "PARTIAL RUN, not a finished job ($partial): " + $msg
    $block += "PARTIAL RUN: $partial. This branch ends in -partial and opens no pull request. The Board reruns the job or takes the work by hand.`n`n"
  }
  if ($guard) { $block += "$guard`n`n" }
  if ($base -and $base -ne $pre) {
    $ac = @(Git-Lines log --format='%h %s' "$base..$pre")
    if ($ac.Count) { $block += "Commits the agent made itself (merges included), under this one:`n" + (($ac | ForEach-Object { "- $_" }) -join "`n") + "`n`n" }
  }
  if ($old) { $block += "Earlier tip of $br kept: $old is this commit's second parent, so the earlier run stays reachable. This commit's files are this run's alone.`n" }
  $block += "Run-Number: $runNo`n"
  $final = $msg.TrimEnd() + "`n`n" + $block
  [IO.File]::WriteAllText($cp, $final, $utf8)
  $new = $pre
  if ($fault -eq 'skipcommit') {
    Write-Host 'TEST FAULT skipcommit (dry run only): the runner leaves the staged change uncommitted, as the issue 541 run did'
  } else {
    $tree = Git-One write-tree
    if ($gx -ne 0 -or -not $tree) { Write-Host 'COMMIT FAILED: git write-tree failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
    $pargs = @('-p', $pre)
    $mh = Git-One rev-parse -q --verify MERGE_HEAD
    if ($mh) { $pargs += @('-p', $mh) }
    if ($old -and $old -ne $pre) { $pargs += @('-p', $old) }
    $new = Git-One commit-tree $tree @pargs -F $cp
    if ($gx -ne 0 -or -not $new) { Write-Host 'COMMIT FAILED: git commit-tree failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
    & git update-ref -m 'runner commit (issue 377)' HEAD $new $pre 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host 'COMMIT FAILED: git update-ref failed; nothing pushed, change kept as out\change.patch'; Save-Patch $out $pre; Pop-Location; exit 11 }
  }
  [IO.File]::WriteAllText((Join-Path $out 'run_commit.txt'), $new, [Text.Encoding]::ASCII)
  # Before the push: the commit must carry exactly the staged change, and nothing may be left staged.
  $head = Git-One rev-parse HEAD
  $num2 = @(Git-Lines -c core.quotepath=off diff --numstat --no-renames $pre $head)
  & git diff --cached --quiet $head 2>$null; $clean = ($LASTEXITCODE -eq 0)
  if ((($num -join "`n") -ne ($num2 -join "`n")) -or -not $clean -or $head -ne $new) {
    $v = @('DIFF MISMATCH before the push (issue 377): the commit to push does not carry the staged change.', "agent HEAD $pre, commit to push $head", '', 'staged (out\diffstat.txt):') + $num + @('', 'in the commit to push:') + $num2
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') $v
    Write-Host '!!! DIFF MISMATCH: push stopped, the check failed. The commit to push does not carry the change in out\diffstat.txt.'
    Write-Host "!!! staged: $($num.Count) file(s); in the commit to push: $($num2.Count). Nothing pushed; the staged change is kept as out\change.patch; see out\DIFF_MISMATCH.txt"
    Save-Patch $out $pre; Pop-Location; exit 10
  }
  $sh = $new.Substring(0, [Math]::Min(9, $new.Length))
  if ($old) { Write-Host "commit $sh (run $runNo of $br) carries the staged change ($($num.Count) files); earlier tip $($old.Substring(0, 9)) kept as its parent, so the push needs no force" }
  else { Write-Host "commit $sh (run 1 of $br) carries the staged change ($($num.Count) files)" }
  Pop-Location; exit 0
}
elseif ($mode -eq 'confirm') {
  # After the push: GitHub's branch must be the runner's commit, and its diff from the agent's HEAD must be exactly
  # out\diffstat.txt. Writes pushed_diffstat.txt. Exit 10, loudly, when they differ.
  $ErrorActionPreference = 'Continue'
  $repo = $args[1]; $out = $args[2]; $br = $args[3]; $push = $args[4]
  Push-Location $repo
  $pre = Read-Txt (Join-Path $out 'pre_commit.txt'); $new = Read-Txt (Join-Path $out 'run_commit.txt')
  $num = @(Read-Lines (Join-Path $out 'diff_numstat.txt'))
  if ($push -eq 'dry') { Write-Host 'dry run: nothing pushed; the commit that would be pushed carries exactly out\diffstat.txt (checked before the push)'; Pop-Location; exit 0 }
  $ls = @(Git-Lines ls-remote origin "refs/heads/$br")
  $remote = ''; if ($ls.Count) { $remote = ($ls[0] -split '\s+')[0] }
  if ($remote -ne $new) {
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') @('PUSH CHECK FAILED (issue 377)', "GitHub's $br is '$remote'", "the runner's commit is $new")
    Write-Host "!!! PUSH CHECK FAILED: GitHub's $br is '$remote', not the runner's commit $new. See out\DIFF_MISMATCH.txt"
    Pop-Location; exit 10
  }
  $num2 = @(Git-Lines -c core.quotepath=off diff --numstat --no-renames $pre $remote)
  & git -c core.quotepath=off diff --stat --no-renames "--output=$(Join-Path $out 'pushed_diffstat.txt')" $pre $remote 2>$null
  if (($num -join "`n") -ne ($num2 -join "`n")) {
    Write-Lines (Join-Path $out 'DIFF_MISMATCH.txt') (@('DIFF MISMATCH after the push (issue 377)', 'out\diffstat.txt:') + $num + @('', "pushed ($pre..$remote):") + $num2)
    Write-Host "!!! DIFF MISMATCH after the push, the check failed: GitHub's $br does not carry exactly out\diffstat.txt. Do not merge it; see out\DIFF_MISMATCH.txt"
    Pop-Location; exit 10
  }
  Write-Host "pushed diff checked: GitHub's $br ($($remote.Substring(0, 9))) carries exactly out\diffstat.txt ($($num.Count) files)"
  Pop-Location; exit 0
}
elseif ($mode -eq 'tidy') {
  # Every run: report the run folder's size. Only when Ryan's setting says yes (off by default) and the run ended in a
  # checked push, remove the run's own repo\ copy; out\ (reports, logs, shots, refused files) is always kept.
  $ErrorActionPreference = 'Continue'
  $run = $args[1]; $root = $args[2]; $setf = $args[3]; $ok = $args[4]; $dry = $args[5]
  function SizeOf($p) { if (-not (Test-Path -LiteralPath $p)) { return [double]0 }; $s = (Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; if ($s) { return [double]$s } else { return [double]0 } }
  $repo = Join-Path $run 'repo'; $outd = Join-Path $run 'out'
  $rs = SizeOf $repo; $os = SizeOf $outd
  Write-Host ('run folder size: {0:N2} GB (repo copy {1:N2} GB, out {2:N1} MB) in {3}' -f (($rs + $os) / 1GB), ($rs / 1GB), ($os / 1MB), $run)
  $on = $false
  if (Test-Path -LiteralPath $setf) { foreach ($l in [IO.File]::ReadAllLines($setf)) { if ($l.Trim() -ieq 'remove_repo_copy_after_push=yes') { $on = $true } } }
  if (-not (Test-Path -LiteralPath $repo)) { exit 0 }
  if (-not $on) { Write-Host "repo copy kept: remove_repo_copy_after_push is not yes in $setf"; exit 0 }
  if ($ok -ne '1') { Write-Host 'repo copy kept: the setting is on, but this run did not end in a checked push'; exit 0 }
  $runFull = [IO.Path]::GetFullPath($run).TrimEnd('\'); $rootFull = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
  if (-not $runFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath (Join-Path $repo '.git')) -or -not (Test-Path -LiteralPath (Join-Path $outd 'result.txt'))) {
    Write-Host "repo copy kept: safety check failed (the run folder must sit under $root and hold repo\.git and out\result.txt)"; exit 0
  }
  if ($dry -eq '1') { Write-Host ('dry run: the setting is on and the push was checked, so a real run would now remove {0} ({1:N2} GB) and keep out\; nothing removed' -f $repo, ($rs / 1GB)); exit 0 }
  Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $repo) { & cmd.exe /c rd /s /q "\\?\$repo" 2>$null }
  if (Test-Path -LiteralPath $repo) { Write-Host ('repo copy only partly removed: {0:N2} GB left in {1}' -f ((SizeOf $repo) / 1GB), $repo) }
  else { Write-Host ('repo copy removed after the checked push (Ryan''s setting): {0}, {1:N2} GB freed; out\ kept' -f $repo, ($rs / 1GB)) }
  exit 0
}
else { Write-Host 'usage: work_issue.ps1 prep|balance|keycheck|lasttext|stats|msg|guard|commit|confirm|tidy ...'; exit 2 }
