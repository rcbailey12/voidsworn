@echo off
rem Issue 1843. Queue after green checks and review. Pass the reviewed full commit pin.
rem Corsair seed 7, two solo runs per pin, with no screenshot readbacks.
setlocal EnableExtensions
set "PIN_NEW=%~1"
if not defined PIN_NEW (echo Usage: round_2_compile_1843.bat REVIEWED_SHA & exit /b 2)
if not "%~2"=="" (echo FAILED: the main control pin is fixed in this job & exit /b 2)
set "PIN_CONTROL=3131184ba31ab9a8bfa772ddc679e6e9ffc4d5aa"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "OJ_NEED_HULLS=V14_23 V15_37 V16_37 C13s_23 C14s_23 C15s_23"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live version & exit /b 2)
set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not exist "%HEAD%" (echo FAILED: missing job head & exit /b 2)
call "%HEAD%" init codex1843 1843 godot
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new "%PIN_NEW%"
if not defined JW_STOP call :one control "%PIN_CONTROL%"
call "%HEAD%" tail
exit /b %ERRORLEVEL%

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
set "PC_GPU_MODE="
exit /b 0

:replay
set "JW_STEP=%~1 Corsair seed 7 run %~2"
set "JW_EXPECT=%O%\frames_%~2.json"
call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 --script "%PROBE%" -- --bot --fac corsair --obj ambush --map open --seed 7 --movement brisk --no-tips --pace-report --kill-frame-report "%O%\frames_%~2.json" %VERIFY% > "%O%\replay_%~2.txt" 2>&1
if errorlevel 1 exit /b 1
findstr /b /c:"SCRIPT ERROR" "%O%\replay_%~2.txt" >nul && (call "%JW%" fail "battle replay logged a script error" & exit /b 1)
findstr /b /c:"KILL_FRAME round_2_frames=" "%O%\replay_%~2.txt"
if errorlevel 1 (call "%JW%" fail "missing round 2 replay summary" & exit /b 1)
exit /b 0
