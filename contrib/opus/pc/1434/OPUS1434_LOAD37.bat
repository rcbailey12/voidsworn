@echo off
rem Issue 2027, LOAD37, from OPUS1434_LOAD36.bat. Same cold and warm load and close suite.
rem Board: call with the exact pushed and reviewed codex/issue-2027 head after green checks.
rem Timing claims the GPU solo. Profiles and recovered logs are confined to this attempt.
setlocal EnableExtensions
set "JOB=opus1434as"
set "LABEL=2027"
set "TOOLS=godot"
set "PIN_NEW=%~1"
powershell.exe -NoProfile -Command "if ($env:PIN_NEW -notmatch '^[0-9a-f]{40}$') { exit 2 }"
if errorlevel 1 (
  echo FAILED: pass the exact pushed issue 2027 head as the first argument
  exit /b 2
)
set "PIN_OLD="

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

call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0

rem ---- 2e. the bake service close proof (issues 1434 and 1765, Artoo): windowed, the same build
set "JW_CONTINUE=1"
set "JW_STEP=%1 bake_close" & set "JW_EXPECT=%O%\bake_close.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s res://world/test/bake_close_check.gd > "%O%\bake_close.txt" 2>&1
findstr /c:"PASS: bake_close_check" "%O%\bake_close.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 bake_close: see bake_close.txt")

rem ---- 2f. the quick battle screenshot check (issue 1978, Artoo on 9c015f43): windowed, the same build
set "QS=%O%\quick_shots"
if not exist "%QS%" mkdir "%QS%"
set "JW_CONTINUE=1"
set "JW_STEP=%1 quick_shots" & set "JW_EXPECT=%O%\quick_shots.txt" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" -s res://main/test/quick_battle_shots_check.gd -- --seed 4242 --shots "%QS%" --fac hegemony --map belt --window 1280x720 > "%O%\quick_shots.txt" 2>&1
findstr /c:"PASS: seeded quick battle" "%O%\quick_shots.txt" > nul
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

:exp
rem ---- 3. this job's own Godot profiles go (issue 1830: their long names broke the relay)
if exist "%H%\profile_warm" rmdir /s /q "%H%\profile_warm"
for /d %%S in ("%H%\close_*") do for /d %%C in ("%%S\*") do if exist "%%C\profile" rmdir /s /q "%%C\profile"
exit /b 0
