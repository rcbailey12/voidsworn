# Pause every Board job on Ryan's PC without losing or deleting anything (Ryan, Nov 15 2026: "I don't want to cause anything
# to get lost or deleted with the pauses as well, so let's bake that in"; RULEBOOK 3.x, the pause rule).
#
# How: (1) withdraw the GPU go; (2) close only the chain windows still WAITING (no job inside them yet, so nothing to save);
# (3) end the AI processes (codex, opencode). A runner whose agent ends commits the work so far and pushes it to the issue's
# -partial branch (codex_issue.bat and work_issue.bat, issue 377), so the work survives in GitHub and the next run resumes it.
# A queued job that starts after this sees its agent ended at the preflight and stops before touching anything. Job windows that
# are mid-run are never closed (closing one would stop its runner before the push). Nothing is ever deleted.
# (4) wait for runner status, then verify each confirmed commit on GitHub before declaring a restart safe.
# Usage: powershell -File pause_all.ps1 [-At HH:mm] [-Minutes 60]
param([string]$At = "", [int]$Minutes = 60)

function Read-PauseText($Path) {
  if (Test-Path -LiteralPath $Path -PathType Leaf) { return [IO.File]::ReadAllText($Path).Trim() }
  return ''
}
function Read-PauseState($Path) {
  try {
    $s = Read-PauseText $Path | ConvertFrom-Json -ErrorAction Stop
    if (-not $s.status -or -not $s.run -or -not $s.branch) { return $null }
    return $s
  } catch { return $null }
}
function Get-PauseJobs($Root) {
  $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop)
  $recent = (Get-Date).ToUniversalTime().AddMinutes(-30)
  # Only job metadata, never a recursive walk through repos, caches or old Codex runs/backups.
  foreach ($lane in @('board','board_b','board_c','board_d','board_e','board_f','work217')) {
    $base = Join-Path $Root $lane
    if (-not (Test-Path -LiteralPath $base -PathType Container)) { continue }
    $jobs = @(
      foreach ($dir in Get-ChildItem -LiteralPath $base -Directory -ErrorAction Stop) {
        if ($lane -eq 'work217') {
          if ($dir.Name -notmatch '^issue-\d+-[a-z0-9]+$') { continue }
          $outs = @(Get-ChildItem -LiteralPath $dir.FullName -Directory -ErrorAction Stop |
            Where-Object { $_.Name -match '^\d{8}_\d{6}$' } |
            ForEach-Object { Join-Path $_.FullName 'out' })
        } else {
          if ($dir.Name -notmatch '^issue-\d+$') { continue }
          $outs = @($dir.FullName)
        }
        foreach ($out in $outs) {
          $s = Read-PauseState (Join-Path $out 'status.json')
          $stamp = [datetime]::MinValue
          if (-not $s -or -not [datetime]::TryParse([string]$s.started, [ref]$stamp)) {
            $f = Get-Item -LiteralPath (Join-Path $out 'result.txt') -ErrorAction SilentlyContinue
            $stamp = if ($f) { $f.LastWriteTimeUtc } else { $dir.LastWriteTimeUtc }
          } else { $stamp = $stamp.ToUniversalTime() }
          $activity = [datetime]::MinValue
          foreach ($name in @('status.json','log.txt','result.txt','checks_node.txt','checks_parity.txt')) {
            $file = Get-Item -LiteralPath (Join-Path $out $name) -ErrorAction SilentlyContinue
            if ($file -and $file.LastWriteTimeUtc -gt $activity) { $activity = $file.LastWriteTimeUtc }
          }
          # DeepSeek keeps out and repo beside each other under its timestamped run folder.
          $folder = if ($lane -eq 'work217') { Split-Path -Parent $out } else { $out }
          $pattern = [regex]::Escape($folder.Replace('/','\')) + '(?=[\\/"\s]|$)'
          $hasProcess = @($processes | Where-Object { ([string]$_.CommandLine).Replace('/','\') -match $pattern }).Count -gt 0
          [pscustomobject]@{
            Lane = $lane; Job = $dir.Name; Out = $out; State = $s; Stamp = $stamp
            Activity = $activity; HasProcess = $hasProcess; Leftover = $false
          }
        }
      }
    )
    # Newest means last activity, not start time: a stopped run may have started after a still-live job.
    $latest = $jobs | Sort-Object Activity, Stamp -Descending | Select-Object -First 1
    foreach ($j in $jobs) {
      $j.Leftover = $j.State.status -eq 'running' -and $j -ne $latest -and
        $j.Activity -lt $recent -and -not $j.HasProcess
      if ($j -eq $latest -or $j.State.status -eq 'running') { $j }
    }
  }
}
function Update-PauseJobs($Root, $Jobs, $Leftovers) {
  foreach ($j in Get-PauseJobs $Root) {
    if ($j.Leftover -and -not $Jobs.ContainsKey($j.Out)) { $Leftovers[$j.Out] = $j }
    else {
      # Once seen live during this pause, await its runner even if its checks later go quiet.
      if (-not $Jobs.ContainsKey($j.Out)) { $Jobs[$j.Out] = $j }
      $Leftovers.Remove($j.Out)
    }
  }
}
function Invoke-PauseGit($Ref, $Deadline, $Executable = 'git.exe') {
  # Bound the verification by the same pause deadline. No prompt, no gh, no checkout or origin assumptions.
  $ms = [int][math]::Min(30000, [math]::Max(0, ($Deadline - (Get-Date)).TotalMilliseconds))
  if ($ms -le 0) { throw 'time limit reached before GitHub verification' }
  $info = New-Object Diagnostics.ProcessStartInfo
  $info.FileName = $Executable
  $info.Arguments = 'ls-remote --exit-code https://github.com/rcbailey12/voidsworn.git ' + $Ref
  $info.UseShellExecute = $false; $info.CreateNoWindow = $true
  $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
  $info.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
  $info.EnvironmentVariables['GCM_INTERACTIVE'] = 'Never'
  $p = New-Object Diagnostics.Process
  $p.StartInfo = $info
  try {
    $null = $p.Start()
    $stdout = $p.StandardOutput.ReadToEndAsync(); $stderr = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($ms)) { throw 'git ls-remote timed out; checkpoint unverified' }
    if ($p.ExitCode -ne 0) { throw "git ls-remote failed (exit $($p.ExitCode))" }
    return $stdout.GetAwaiter().GetResult()
  } finally {
    # Never kill another process, including on a verification timeout.
    $p.Dispose()
  }
}
function Test-PauseJob($Job, $Deadline) {
  $word = 'unresolved'; $reason = ''; $ref = ''; $commit = ''
  try {
    $s = Read-PauseState (Join-Path $Job.Out 'status.json')
    if (-not $s) { throw 'status.json missing or unreadable' }
    if ($Job.State -and $Job.State.run -ne $s.run) { throw 'runner changed during pause' }
    if ($s.status -eq 'running') { throw 'runner still running (checks or push unfinished; time limit reached)' }
    if ($s.status -notin @('checked_push','partial')) { throw "runner status $($s.status) is unverified" }
    if ($s.branch -notmatch '^(codex|work|muse|opus)/issue-\d+(-[a-z0-9]+)*$') { throw 'invalid delivery branch' }
    $commit = Read-PauseText (Join-Path $Job.Out 'run_commit.txt')
    $confirmed = Read-PauseText (Join-Path $Job.Out 'confirmed_commit.txt')
    if ($commit -notmatch '^[0-9a-f]{40,64}$' -or $confirmed -ne $commit -or $s.commit -ne $commit) {
      throw 'run_commit.txt, confirmed_commit.txt and status commit do not agree'
    }
    $ref = "refs/heads/$($s.branch)"
    if ($s.status -eq 'partial') { $ref += '-partial' }
    $remote = Invoke-PauseGit $ref $Deadline
    if ($remote.Trim() -notmatch ('^' + [regex]::Escape($commit) + '\s+' + [regex]::Escape($ref) + '$')) {
      throw 'GitHub branch does not hold the confirmed commit'
    }
    # A rerun must not replace the metadata while the network check is in flight.
    $after = Read-PauseState (Join-Path $Job.Out 'status.json')
    if (-not $after -or $after.run -ne $s.run -or $after.status -ne $s.status -or $after.commit -ne $commit) {
      throw 'runner changed during GitHub verification'
    }
    $word = if ($s.status -eq 'checked_push') { 'done' } else { 'checkpoint verified' }
    $reason = "$ref $commit"
  } catch { $reason = $_.Exception.Message }
  return [pscustomobject]@{ Word = $word; Reason = $reason; State = $s; Commit = $commit }
}
function Invoke-Pause($V, $At, $Minutes) {
$L = Join-Path $V 'pc_pause.txt'
function Log($m) { Add-Content -LiteralPath $L -Value ("{0:HH:mm:ss} {1}" -f (Get-Date), $m) }
Set-Content -LiteralPath $L -Value ("armed {0}" -f (Get-Date))
if ($At) {
  $t = [datetime]::ParseExact($At, 'HH:mm', $null)
  if ($t -lt (Get-Date).AddMinutes(-1)) { $t = $t.AddDays(1) }
  Log "waiting until $t"
  while ((Get-Date) -lt $t) { Start-Sleep 20 }
}
Log 'pausing'
Log 'lanes: main=board, B=board_b, C=board_c, D=board_d, E=board_e, F=board_f, DeepSeek=work217'
Set-Content -LiteralPath (Join-Path $V 'gpu_go.txt') -Value ("GPU not cleared: paused by the Board at {0:yyyy-MM-dd HH:mm} for Ryan. Paused until he says go again." -f (Get-Date))
Log 'gpu_go.txt: GPU not cleared'
# (2) chain windows still waiting for an earlier chain: their log's last line starts with "waiting"
foreach ($f in Get-ChildItem -LiteralPath $V -Filter '*.txt' | Where-Object { $_.Name -match '^(codex_chain_|codex_lane_|ds_)' }) {
  $last = (Get-Content -LiteralPath $f.FullName -Tail 1)
  if ($last -match '^waiting') {
    $id = $f.BaseName; $found = $false
    foreach ($p in Get-CimInstance Win32_Process -Filter "Name='cmd.exe'") {
      # -match is case-insensitive: codex_chain_15h.txt belongs to the window running CODEX_CHAIN_15H.bat
      if ($p.CommandLine -match [regex]::Escape($id)) {
        Log ("closing waiting window for {0} (pid {1})" -f $id, $p.ProcessId)
        & taskkill /F /T /PID $p.ProcessId | Out-Null; $found = $true
      }
    }
    if ($found) { Add-Content -LiteralPath $f.FullName -Value ("paused by the Board {0:HH:mm}: not started, nothing to save" -f (Get-Date)) }
  }
}
# (3) end the agents; keep ending any new ones (a queued job's preflight) until the window closes
$end = (Get-Date).AddMinutes($Minutes); $quiet = 0; $settled = $false
$jobs = @{}; $leftovers = @{}; $scanError = ''
while ((Get-Date) -lt $end) {
  try {
    Update-PauseJobs $V $jobs $leftovers
    $scanError = ''
  } catch { $scanError = "lane scan failed: $($_.Exception.Message)" }
  # Only the Board's own agents: a codex or opencode process whose command line names the voidsworn_test job folders.
  # Ryan's own Codex app (or anything else he runs) never matches and is never touched (Nov 15 19:39: the first version
  # ended every codex process, and his Codex app kept restarting and being ended again).
  try {
    $hit = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { ($_.Name -match '^(codex|opencode)(\.exe)?$') -and ($_.CommandLine -match 'voidsworn_test') })
    $git = @(Get-CimInstance Win32_Process -Filter "Name='git.exe'" -ErrorAction Stop | Where-Object { $_.CommandLine -match 'voidsworn_test' })
  } catch {
    $scanError = "process scan failed: $($_.Exception.Message)"; $quiet = 0
    Start-Sleep 10; continue
  }
  foreach ($p in $hit) { Log ("ending {0} pid {1}" -f $p.Name, $p.ProcessId); & taskkill /F /T /PID $p.ProcessId | Out-Null }
  if ($hit.Count -eq 0) { $quiet++ } else { $quiet = 0 }
  # Quiet for 3 minutes is necessary, but a runner in checks can have no agent or git process at all.
  $pending = @($jobs.Values | Where-Object {
    $s = Read-PauseState (Join-Path $_.Out 'status.json')
    -not $s -or $s.status -eq 'running'
  })
  if ($quiet -ge 18 -and $git.Count -eq 0 -and $pending.Count -eq 0 -and -not $scanError) { $settled = $true; break }
  Start-Sleep 10
}
try {
  Update-PauseJobs $V $jobs $leftovers
} catch { $scanError = "lane scan failed: $($_.Exception.Message)" }
$results = @{}
foreach ($j in @($jobs.Values)) { $results[$j.Out] = Test-PauseJob $j $end }
# Network checks can take time. A new queued run or a replaced status must not inherit an earlier safe result.
try {
  Update-PauseJobs $V $jobs $leftovers
  $active = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
    ($_.Name -match '^(codex|opencode|git)(\.exe)?$') -and ($_.CommandLine -match 'voidsworn_test')
  })
  if ($active.Count) { $scanError = 'agents or git still active under voidsworn_test' }
} catch { $scanError = "final lane/process scan failed: $($_.Exception.Message)" }
$unresolved = @()
foreach ($j in @($leftovers.Values | Sort-Object Out)) {
  Log ("leftover record (not counted): {0}/{1}, last activity {2:yyyy-MM-dd HH:mm:ss} UTC; {3}" -f
    $j.Lane, $j.Job, $j.Activity, $j.Out)
}
foreach ($lane in @('board','board_b','board_c','board_d','board_e','board_f','work217')) {
  $laneJobs = @($jobs.Values | Where-Object { $_.Lane -eq $lane } | Sort-Object Out)
  if (-not $laneJobs.Count) { Log "${lane}: no current job found" }
  foreach ($j in $laneJobs) {
    $result = $results[$j.Out]
    if (-not $result) {
      $result = [pscustomobject]@{ Word = 'unresolved'; Reason = 'job appeared during GitHub verification' }
    } elseif ($result.Word -ne 'unresolved') {
      try {
        $s = Read-PauseState (Join-Path $j.Out 'status.json')
        $changed = -not $s -or $s.run -ne $result.State.run -or $s.status -ne $result.State.status -or
          $s.branch -ne $result.State.branch -or $s.commit -ne $result.Commit -or
          (Read-PauseText (Join-Path $j.Out 'run_commit.txt')) -ne $result.Commit -or
          (Read-PauseText (Join-Path $j.Out 'confirmed_commit.txt')) -ne $result.Commit
      } catch { $changed = $true }
      if ($changed) {
        $result.Word = 'unresolved'; $result.Reason = 'runner changed before final report'
      }
    }
    $name = "$lane/$($j.Job)"
    Log ("{0}: {1} ({2}); {3}" -f $name, $result.Word, $result.Reason, $j.Out)
    if ($result.Word -eq 'unresolved') { $unresolved += $name }
  }
}
if (-not $settled -or $scanError -or (Get-Date) -ge $end) {
  $why = if ($scanError) { $scanError } else { 'time limit reached before agents and runners settled' }
  Log "pause: unresolved ($why)"; $unresolved += 'pause'
}
if ($unresolved.Count) { Log ("NOT safe to restart: " + ($unresolved -join ', ')) }
else { Log 'safe to restart' }
}
# Dot sourcing defines the real functions for the fixture test without pausing the PC.
if ($MyInvocation.InvocationName -ne '.') {
  Invoke-Pause (Join-Path $env:USERPROFILE 'Downloads\voidsworn_test') $At $Minutes
}
