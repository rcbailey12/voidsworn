@echo off
rem Issue 1843. Queue after green checks and review. Pass the reviewed full commit pin.
rem Corsair seed 7 twice and one imported Glasswright Blink per pin, solo, no screenshot readbacks.
setlocal EnableExtensions
set "PIN_NEW=%~1"
if not defined PIN_NEW (echo Usage: round_2_compile_1843.bat REVIEWED_SHA & exit /b 2)
if not "%~2"=="" (echo FAILED: the main control pin is fixed in this job & exit /b 2)
rem Main parent of the run 5 integration, with the same load path and no warm outline.
set "PIN_CONTROL=4a6c1c18b2b1a84991ac48bf9cceb97220179faa"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "OJ_NEED_HULLS=V14_23 V15_37 V16_37 C13s_23 C14s_23 C15s_23 I14_23"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live version & exit /b 2)
set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not exist "%HEAD%" (echo FAILED: missing job head & exit /b 2)
call "%HEAD%" init codex1843 1843 godot
if errorlevel 1 exit /b %ERRORLEVEL%

set "REPLAY_MISSED="
for %%P in (new control) do for %%R in (1 2) do set "REPLAY_%%P_%%R=NOT_RUN"
call :one new "%PIN_NEW%"
if not defined JW_STOP call :one control "%PIN_CONTROL%"
set "ACCEPTANCE=PASS"
if defined REPLAY_MISSED set "ACCEPTANCE=FAIL"
for %%S in (%REPLAY_new_1% %REPLAY_new_2% %REPLAY_control_1% %REPLAY_control_2%) do (
  if "%%S"=="NOT_RUN" set "ACCEPTANCE=INCOMPLETE"
  if "%%S"=="ERROR" set "ACCEPTANCE=INCOMPLETE"
)
set "SUMMARY=%OJ_OUT%\round_2_acceptance.txt"
> "%SUMMARY%" echo ROUND_2_ACCEPTANCE %ACCEPTANCE% new_1=%REPLAY_new_1% new_2=%REPLAY_new_2% control_1=%REPLAY_control_1% control_2=%REPLAY_control_2% candidate_pin=%PIN_NEW% control_pin=%PIN_CONTROL% || call "%JW%" fail "could not write the round 2 acceptance summary"
if exist "%SUMMARY%" type "%SUMMARY%"
call "%HEAD%" tail
set "TAIL_RC=%ERRORLEVEL%"
if "%ACCEPTANCE%"=="FAIL" exit /b 3
if "%ACCEPTANCE%"=="INCOMPLETE" exit /b 1
exit /b %TAIL_RC%

:one
call "%HEAD%" checkout %1 "%~2"
if defined JW_STOP exit /b 1
call "%HEAD%" ships
if defined JW_STOP exit /b 1
set "PROBE=%OJ_OUT%\kill_frame_probe.gd"
rem Measure both pins with the same probe from the reviewed checkout.
if "%~1"=="new" copy /y "%OJ_REPO%\godot\bench\kill_frame_probe.gd" "%PROBE%" >nul
if not exist "%PROBE%" (call "%JW%" fail "missing kill frame probe" & exit /b 1)
set "O=%OJ_OUT%\out_%~1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%~1 import"
set "JW_EXPECT="
call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 exit /b 1
set "VERIFY=--require-round-2-hitch"
if "%~1"=="new" set "VERIFY=--require-no-round-2-compiles"
set "PC_GPU_MODE=solo"
for %%R in (1 2) do (
  call :replay %1 %%R
  if errorlevel 1 exit /b 1
)
call :blink %1
set "PC_GPU_MODE="
if defined JW_STOP exit /b 1
exit /b 0

:replay
set "JW_STEP=%~1 Corsair seed 7 run %~2"
set "JW_EXPECT=%O%\frames_%~2.json"
rem Retain all four traces if the replay ran but missed its compile verdict.
set "JW_CONTINUE=1"
call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 --script "%PROBE%" -- --bot --fac corsair --obj ambush --map open --seed 7 --movement brisk --no-tips --pace-report --kill-frame-report "%O%\frames_%~2.json" %VERIFY% > "%O%\replay_%~2.txt" 2>&1
set "REPLAY_RC=%ERRORLEVEL%"
if not "%REPLAY_RC%"=="0" if not "%REPLAY_RC%"=="3" goto replay_bad
if not exist "%O%\frames_%~2.json" goto replay_bad
for %%F in ("%O%\frames_%~2.json") do if "%%~zF"=="0" goto replay_bad
findstr /b /c:"SCRIPT ERROR" "%O%\replay_%~2.txt" >nul && goto replay_bad
findstr /b /c:"KILL_FRAME round_2_frames=" "%O%\replay_%~2.txt"
if errorlevel 1 goto replay_bad
if "%REPLAY_RC%"=="3" (
  rem The wrapper also uses exit 3 for missing output. Only a probe verdict may continue.
  findstr /b /c:"KILL_FRAME VERDICT_FAILED " "%O%\replay_%~2.txt"
  if errorlevel 1 goto replay_bad
  set "REPLAY_%~1_%~2=VERDICT_FAILED"
  set "REPLAY_MISSED=1"
) else (
  set "REPLAY_%~1_%~2=PASS"
)
exit /b 0

:replay_bad
set "REPLAY_%~1_%~2=ERROR"
call "%JW%" fail "%~1 Corsair run %~2 did not produce a valid replay"
exit /b 1

:blink
set "JW_STEP=%~1 first Glasswright Blink"
set "JW_EXPECT=%O%\blink.json"
call "%JW%" run 300 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 --script "%PROBE%" -- --seed 7 --movement brisk --no-tips --blink-frame-report "%O%\blink.json" > "%O%\blink.txt" 2>&1
if errorlevel 1 exit /b 1
findstr /b /c:"SCRIPT ERROR" "%O%\blink.txt" >nul && (call "%JW%" fail "Blink measurement logged a script error" & exit /b 1)
findstr /b /c:"KILL_FRAME blink_frames=" "%O%\blink.txt"
if errorlevel 1 (call "%JW%" fail "missing Blink measurement summary" & exit /b 1)
exit /b 0
