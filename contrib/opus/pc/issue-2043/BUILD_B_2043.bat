@echo off
setlocal DisableDelayedExpansion
rem Board GPU queue, after green checks and review at the exact after SHA (R407).
rem Usage: BUILD_B_2043.bat AFTER_SHA [BEFORE_SHA], both full commit pins.
rem The standing look bench handles GPU claims, warm-up, capture and picture stamps.
set "CAPTURE_2043_AFTER=%~1"
set "CAPTURE_2043_BEFORE=%~2"
if not defined CAPTURE_2043_BEFORE set "CAPTURE_2043_BEFORE=649f694d69343cdf8f0d954b7094fb0b6f2838fd"
if not defined CAPTURE_2043_AFTER (
  echo Usage: BUILD_B_2043.bat AFTER_SHA [BEFORE_SHA]
  exit /b 2
)
powershell -NoProfile -Command "if ($env:CAPTURE_2043_AFTER -notmatch '^[0-9a-f]{40}$' -or $env:CAPTURE_2043_BEFORE -notmatch '^[0-9a-f]{40}$' -or $env:CAPTURE_2043_AFTER -eq $env:CAPTURE_2043_BEFORE) { exit 2 }"
if errorlevel 1 (
  echo FAILED: give two different full commit pins.
  exit /b 2
)
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (
  echo FAILED: the installed PC tools are not available.
  exit /b 2
)
set "BENCH=%VT%\tools_live\%TLV%\pc\jobs\look_bench.bat"
if not exist "%BENCH%" (
  echo FAILED: the installed look bench is missing.
  exit /b 2
)
set "CAPTURE_2043_A=%CAPTURE_2043_AFTER:~0,8%"
set "CAPTURE_2043_B=%CAPTURE_2043_BEFORE:~0,8%"
set "LB_HOME=%VT%\board\issue-2043\bench_%CAPTURE_2043_A%"
set "LB_TOOL_REF=%CAPTURE_2043_AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_2043.json"
set "LB_QUIET=1"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "PC_GPU_ISSUE=2043"
set "CAPTURE_2043_SHOTS=%VT%\board\issue-2043\shots"
call "%BENCH%" "%CAPTURE_2043_AFTER%" "%CAPTURE_2043_BEFORE%"
if errorlevel 1 exit /b 1
rem The generic sheet maker allows partial sets. Refuse to publish one for this job.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $a=$env:CAPTURE_2043_A; $b=$env:CAPTURE_2043_B; $runs=Join-Path $env:LB_HOME 'runs'; $cfg=Get-Content -Raw (Join-Path $runs ($a+'/moments.json')) | ConvertFrom-Json; if (($cfg.cameras -join ',') -ne '170,26' -or !$cfg.rows) { throw 'Missing Build B moment configuration' }; foreach ($pin in @($a,$b)) { $report=Get-Content -Raw (Join-Path $runs ($pin+'/bench.json')) | ConvertFrom-Json; foreach ($row in $cfg.rows) { foreach ($cam in $cfg.cameras) { $frame=@($report.stills | Where-Object { $_.id -ceq $row.id -and $_.cam -eq $cam }); if ($frame.Count -ne 1 -or @($frame[0].cells).Count -ne $row.windows[0][2]) { throw ('Missing or partial row '+$row.id+' c'+$cam+' in '+$pin) } } } }; $sheets=Join-Path $env:LB_HOME ('sheets/'+$b+'_vs_'+$a+'/moments'); $files=@(foreach ($row in $cfg.rows) { Get-Item -LiteralPath (Join-Path $sheets ($row.id+'.jpg')), (Join-Path $sheets ($row.id+'.jpg.provenance.json')) }); $null=New-Item -Force -ItemType Directory -Path $env:CAPTURE_2043_SHOTS; foreach ($file in $files) { Copy-Item -LiteralPath $file.FullName -Destination $env:CAPTURE_2043_SHOTS -Force }; Write-Output ('PASS '+$cfg.rows.Count+' Build B strips and sidecars in '+$env:CAPTURE_2043_SHOTS)"
if errorlevel 1 exit /b 1
exit /b 0
