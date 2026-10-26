# Run a program with a time limit (PC job watchdog). Starts it, waits up to the limit, and if it overruns kills it with
# its whole process tree, logs that, and returns exit code 124. Otherwise returns the program's own exit code.
# The program's output goes to this window (so "tmo.bat ... > log.txt 2>&1" captures it).
# Call it through tools\pc\tmo.bat <seconds> <exe> [args ...]: the bat hands the whole command line over in TMO_ARGS, so
# arguments that start with "-" or "--" reach the program untouched (PowerShell would read them as its own parameters).
$ErrorActionPreference = 'Stop'
$raw = $env:TMO_ARGS
if (-not $raw) { Write-Output 'usage: tmo.bat <seconds> <exe> [args ...]'; exit 125 }
$m = [regex]::Match($raw, '^\s*(\d+)\s+("([^"]+)"|(\S+))\s*(.*)$')
if (-not $m.Success) { Write-Output "run_timeout: cannot read the command line: $raw"; exit 125 }
$Seconds = [int]$m.Groups[1].Value
$Exe = if ($m.Groups[3].Success) { $m.Groups[3].Value } else { $m.Groups[4].Value }
$argLine = $m.Groups[5].Value
$root = Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'
$logDir = Join-Path $root 'queue\logs'
if (-not (Test-Path $logDir)) { $logDir = $PSScriptRoot }
$log = Join-Path $logDir 'timeouts.log'
$t0 = Get-Date
try {
  if ($argLine -ne '') { $p = Start-Process -FilePath $Exe -ArgumentList $argLine -NoNewWindow -PassThru }
  else { $p = Start-Process -FilePath $Exe -NoNewWindow -PassThru }
} catch {
  "$(Get-Date -Format s) START FAILED $Exe $argLine : $_" | Out-File $log -Append -Encoding utf8
  Write-Output "run_timeout: could not start $Exe : $_"
  exit 125
}
$null = $p.Handle   # keeps the exit code readable after the process ends
if ($p.WaitForExit($Seconds * 1000)) {
  $p.WaitForExit()
  exit $p.ExitCode
}
$secs = [int]((Get-Date) - $t0).TotalSeconds
& taskkill.exe /PID $p.Id /T /F | Out-Null
"$(Get-Date -Format s) TIMEOUT after $secs s (limit $Seconds s), killed tree of PID $($p.Id): $Exe $argLine" | Out-File $log -Append -Encoding utf8
Write-Output "run_timeout: TIMEOUT after $Seconds s, killed $Exe (PID $($p.Id)) and its children"
exit 124
