@echo off
rem Issue 1877 run 2 (R437): real 1080p look-bench clips of the four Chorus close-weapon options (PR 1904).
rem Helper clone pattern (issue 1180, R334): helper_clone.bat makes or reuses voidsworn_test\opus1877\repo on branch
rem opus/issue-1877, copies the checked ship files from build\godot, then runs :steps inside the folder's lease.
rem :steps (1) stops unless the clone is at 757b67aa, (2) stops unless B20_11 (the Spitter) and H8_23 (the Cordon) in
rem build\godot are the reviewed new builds (their glb sha256 equals the row in the pinned assets\ships\manifest.json),
rem (3) runs THAT clone's tools\pc\jobs\look_bench.bat on 757b67aa with the chorus_close rows only, its own LB_HOME.
rem Frames: opus1877\look_bench\runs\<commit>\moments\cc_*__c170 and __c26 (one PNG per frame, stamped). Deletes nothing.
setlocal
set "N=1877"
set "BRANCH=opus/issue-1877"
set "PIN=757b67aab8b8c7cb0100022c2c5b07d8f525d68f"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus%N%"
set "C=%H%\repo"
set "O=%H%\out"
if /i "%~1"=="steps" goto :steps
if not exist "%O%" mkdir "%O%"
echo OPUS1877_RUN2 started %DATE% %TIME% > "%O%\result.txt"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
set "HC=%VT%\tools_live\%TLV%\pc\helper_clone.bat"
if not exist "%HC%" (
  echo FAILED: helper_clone.bat not found in tools_live yet; ask the Board >> "%O%\result.txt"
  echo all done >> "%O%\result.txt"
  exit /b 1
)
call "%HC%" "%H%" "%BRANCH%" ships "%~f0" > "%O%\clone_log.txt" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo FAILED: exit %RC%, see clone_log.txt and job_log.txt >> "%O%\result.txt"
) else (
  echo PASS >> "%O%\result.txt"
)
echo all done %DATE% %TIME% >> "%O%\result.txt"
endlocal
exit /b 0

:steps
set "L=%O%\job_log.txt"
echo steps %DATE% %TIME% > "%L%"
set "HEADSHA="
for /f %%S in ('git -C "%C%" rev-parse HEAD') do set "HEADSHA=%%S"
if /i not "%HEADSHA%"=="%PIN%" (
  echo FAILED: clone is at %HEADSHA%, not the pinned %PIN%. The branch moved; ask the Board for a new pin. >> "%L%"
  exit /b 2
)
echo clone at pin %PIN% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $m = Get-Content -Raw -LiteralPath (Join-Path $env:C 'godot\assets\ships\manifest.json') | ConvertFrom-Json; $bad = @();" ^
  "foreach ($code in @('B20_11','H8_23')) { $want = $m.ships.$code.files.($code + '.glb').sha256; $f = Join-Path $env:VT ('build\godot\assets\ships\' + $code + '\' + $code + '.glb');" ^
  "  if (-not (Test-Path -LiteralPath $f)) { $bad += ($code + ': no ' + $f); continue }" ^
  "  $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $f).Hash.ToLowerInvariant();" ^
  "  if ($got -ne $want) { $bad += ($code + ': build\godot has ' + $got + ', the reviewed new build is ' + $want) } else { Write-Output ($code + ' OK ' + $got) } }" ^
  "if ($bad.Count) { $bad | ForEach-Object { Write-Output ('NOT THE NEW BUILD: ' + $_) }; exit 3 }" >> "%L%" 2>&1
if errorlevel 1 (
  echo FAILED: B20_11 or H8_23 in build\godot is not the reviewed new build; install them first. See job_log.txt >> "%L%"
  exit /b 3
)
set "PC_GPU_ISSUE=1877"
set "LB_HOME=%H%\look_bench"
set "LB_TOOL_REF=%PIN%"
set "LB_SHIPS=%VT%\build\godot"
set "LB_ARGS=--part moments --moments res://bench/look_moments_chorus_close.json"
call "%C%\tools\pc\jobs\look_bench.bat" %PIN% none >> "%L%" 2>&1
set "BX=%ERRORLEVEL%"
echo look_bench exit %BX% %DATE% %TIME% >> "%L%"
if not "%BX%"=="0" exit /b %BX%
exit /b 0
