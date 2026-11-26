@echo off
rem Issue 2134 LOAD39, copied from the all arm of OPUS2085_ARMS4.bat.
rem Queue only after green checks and passed review. The pin contains the exact game and bench source.
rem The delivery commit only updates this launcher and drops the runner task file.
rem Keep the cold/warm load and close suite, windowed quick battle and all-arm extras.
setlocal EnableExtensions
set "JOB=opus2134load39"
set "LABEL=2134"
set "TOOLS=godot"
set "PIN_NEW=6d8b49bf65d91ba225b392aab1ff1618e62e7ee6"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one load39 %PIN_NEW%
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "LOAD39 could not finish its setup")
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call :prepare %1 %2
if errorlevel 1 exit /b 1
set "WATCH=%OJ_OUT%\quick_watch.gd"
if not exist "%WATCH%" copy /y "%OJ_REPO%\contrib\codex\issue-2085\quick_watch.gd" "%WATCH%" > nul
if not exist "%WATCH%" (call "%JW%" fail "copy quick battle watchdog" & exit /b 1)

rem ---- 2e. the bake service close proof (issues 1434 and 1765, Artoo): windowed, the same build
set "JW_CONTINUE=1"
set "JW_STEP=%1 bake_close" & set "JW_EXPECT=%O%\bake_close.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s res://world/test/bake_close_check.gd > "%O%\bake_close.txt" 2>&1
findstr /c:"PASS: bake_close_check" "%O%\bake_close.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 bake_close: see bake_close.txt")

rem ---- 2f. the same quick battle screenshot check with an out-of-band heartbeat
call :quick %1
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 quick_shots: see quick_shots.txt")

rem ---- 2g. the round 4 Hullbreaker replay (issue 1982, PR 2004), windowed, the same build
set "JW_CONTINUE=1"
set "JW_STEP=%1 round4" & set "JW_EXPECT=%O%\round4.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s res://scenes/battle/test/round4_hullbreaker_check.gd > "%O%\round4.txt" 2>&1
findstr /c:"PASS: round 4" "%O%\round4.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 round4: see round4.txt")

rem ---- 2h. flown movement (issue 505, PR 1874 stage 2), windowed, the same build
set "JW_CONTINUE=1"
set "JW_STEP=%1 movement_flight" & set "JW_EXPECT=%O%\movement_flight.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s res://scenes/battle/test/movement_flight_check.gd > "%O%\movement_flight.txt" 2>&1
findstr /c:"movement flight: PASS" "%O%\movement_flight.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 movement_flight: see movement_flight.txt")

rem ---- 2. load bench cold and warm, then the close cases cold and warm (GPU solo: frame-time measurement)
set "H=%O%\load10"
if not exist "%H%" mkdir "%H%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 load10" & set "JW_EXPECT=%H%\load10_result.txt" & call "%JW%" run 5400 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\opus\pc\1434\load1434_runs.ps1" -Godot "%JW_GODOT%" -Project "%OJ_REPO%\godot" -Out "%H%" -Load37 > "%H%\console.txt" 2>&1
set "PC_GPU_MODE="
if not exist "%H%\load10_result.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: no load10_result.txt, see load10\console.txt" & goto exp)
findstr /c:"[load10] RESULT PASS" "%H%\load10_result.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: a graded item failed, see load10\load10_result.txt")
rem Both profiles must pass the 500 ms title gate and show no ships frame over 400 ms.
for %%T in (cold warm) do (
  findstr /l /c:"[load1434] title PASS (slice PASS, ready PASS" "%H%\load_%%T\load_result.txt" > nul
  if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 %%T title frame: see load10\load_%%T\load_result.txt")
  set "LOAD39_RESULT=%H%\load_%%T\load_result.txt"
  powershell.exe -NoProfile -Command "$line = (Select-String -LiteralPath $env:LOAD39_RESULT -SimpleMatch '[load1434] title worst frames split: ' | Select-Object -First 1).Line; if (-not $line) { exit 1 }; $frames = [regex]::Matches($line, '(?:frames split: |; )(\d+) ms ([\w>-]+) \(began at'); if ($frames.Count -ne 5 -or [int]$frames[4].Groups[1].Value -gt 400) { exit 1 }; foreach ($f in $frames) { if ([int]$f.Groups[1].Value -gt 400 -and $f.Groups[2].Value -match '(^|->)ships($|->)') { exit 1 } }"
  if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 %%T ships margin: over 400 ms or missing proof, see load10\load_%%T\load_result.txt")
)

:exp
rem ---- 3. this job's own Godot profiles go (issue 1830: their long names broke the relay)
if exist "%H%\profile_warm" rmdir /s /q "%H%\profile_warm"
for /d %%S in ("%H%\close_*") do for /d %%C in ("%%S\*") do if exist "%%C\profile" rmdir /s /q "%%C\profile"
exit /b 0

:prepare
call "%HEAD%" checkout %1 %2
if errorlevel 1 exit /b 1
call "%HEAD%" ships
if errorlevel 1 exit /b 1
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
exit /b %ERRORLEVEL%

:quick
set "QS=%O%\quick_shots"
if not exist "%QS%" mkdir "%QS%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 quick_shots" & set "JW_EXPECT=%O%\quick_shots.txt" & call "%JW%" run 900 "%JW_GODOT%" --verbose --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s "%WATCH%" -- --seed 4242 --shots "%QS%" --fac hegemony --map belt --window 1280x720 > "%O%\quick_shots.txt" 2>&1
set "QR=%ERRORLEVEL%"
set "PC_GPU_MODE="
if not "%QR%"=="0" exit /b %QR%
findstr /l /c:"PASS: seeded quick battle" "%O%\quick_shots.txt" > nul
if errorlevel 1 exit /b 1
if not exist "%QS%\09_end.png" exit /b 1
if not exist "%QS%\09_end.png.provenance.json" exit /b 1
exit /b 0
