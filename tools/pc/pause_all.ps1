# Pause every Board job on Ryan's PC without losing or deleting anything (Ryan, Nov 15 2026: "I don't want to cause anything
# to get lost or deleted with the pauses as well, so let's bake that in"; RULEBOOK 3.x, the pause rule).
#
# How: (1) withdraw the GPU go; (2) close only the chain windows still WAITING (no job inside them yet, so nothing to save);
# (3) end the AI processes (codex, opencode). A runner whose agent ends commits the work so far and pushes it to the issue's
# -partial branch (codex_issue.bat and work_issue.bat, issue 377), so the work survives in GitHub and the next run resumes it.
# A queued job that starts after this sees its agent ended at the preflight and stops before touching anything. Job windows that
# are mid-run are never closed (closing one would stop its runner before the push). Nothing is ever deleted.
# Usage: powershell -File pause_all.ps1 [-At HH:mm] [-Minutes 60]
param([string]$At = "", [int]$Minutes = 60)
$V = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
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
$end = (Get-Date).AddMinutes($Minutes); $quiet = 0
while ((Get-Date) -lt $end) {
  # Only the Board's own agents: a codex or opencode process whose command line names the voidsworn_test job folders.
  # Ryan's own Codex app (or anything else he runs) never matches and is never touched (Nov 15 19:39: the first version
  # ended every codex process, and his Codex app kept restarting and being ended again).
  $hit = @(Get-CimInstance Win32_Process | Where-Object { ($_.Name -match '^(codex|opencode)(\.exe)?$') -and ($_.CommandLine -match 'voidsworn_test') })
  foreach ($p in $hit) { Log ("ending {0} pid {1}" -f $p.Name, $p.ProcessId); & taskkill /F /T /PID $p.ProcessId | Out-Null }
  if ($hit.Count -eq 0) { $quiet++ } else { $quiet = 0 }
  # quiet for 3 minutes and no runner still pushing (git) under the voidsworn folders: done
  $git = @(Get-CimInstance Win32_Process -Filter "Name='git.exe'" | Where-Object { $_.CommandLine -match 'voidsworn_test' })
  if ($quiet -ge 18 -and $git.Count -eq 0) { break }
  Start-Sleep 10
}
Log 'paused: no agents running; partial work pushed by each runner (check the -partial branches)'
