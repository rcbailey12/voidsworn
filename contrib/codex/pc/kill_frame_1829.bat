@echo off
rem Board job for issue 1829. Pass the reviewed full commit and, optionally, the comparison commit.
rem Queue after green checks and review (R407). Two runs per pin, no screenshots in the timed replay.
setlocal EnableExtensions
set "PIN_NEW=%~1"
if not defined PIN_NEW (echo Usage: kill_frame_1829.bat REVIEWED_SHA [BASE_SHA] & exit /b 2)
set "PIN_OLD=%~2"
if not defined PIN_OLD set "PIN_OLD=9fd021bda3ad7ba0cb566f918fa3aeb74eaceacf"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "OJ_NEED_HULLS=V14_23 V15_37 V16_37 C13s_23 C14s_23 C15s_23"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live version & exit /b 2)
set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not exist "%HEAD%" (echo FAILED: missing job head & exit /b 2)
call "%HEAD%" init codex1829 1829 godot
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new "%PIN_NEW%"
if not defined JW_STOP call :one old "%PIN_OLD%"
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 "%~2"
if defined JW_STOP exit /b 1
call "%HEAD%" ships
if defined JW_STOP exit /b 1
set "PROBE=%OJ_OUT%\kill_frame_probe.gd"
set "MELT=%OJ_OUT%\capture1394.gd"
if "%~1"=="new" copy /y "%OJ_REPO%\godot\bench\kill_frame_probe.gd" "%PROBE%" >nul
if "%~1"=="new" copy /y "%OJ_REPO%\contrib\opus\melt_1394\capture.gd" "%MELT%" >nul
if not exist "%PROBE%" (call "%JW%" fail "missing kill frame probe" & exit /b 1)
if not exist "%MELT%" (call "%JW%" fail "missing 1394 melt probe" & exit /b 1)
set "O=%OJ_OUT%\out_%~1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%~1 import"
call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 exit /b 1
set "PC_GPU_MODE=solo"
for %%R in (1 2) do (
  call :replay %1 %%R
  if errorlevel 1 exit /b 1
)
set "PC_GPU_MODE="
set "JW_STEP=%~1 Warden melt shader"
set "JW_EXPECT=%O%\melt\%~1_capture.json"
call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --windowed --resolution 1920x1080 --script "%MELT%" -- "%O%\melt" warden %~1 > "%O%\melt.txt" 2>&1
if errorlevel 1 exit /b 1
if not "%~1"=="new" exit /b 0
findstr /b /c:"[fx] late shader: damage " "%O%\melt.txt" >nul && (call "%JW%" fail "Warden melt reported a late damage shader" & exit /b 1)
exit /b 0

:replay
set "JW_STEP=%~1 Corsair seed 7 run %~2"
set "JW_EXPECT=%O%\frames_%~2.json"
call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 --script "%PROBE%" -- --bot --fac corsair --obj ambush --map open --seed 7 --movement brisk --no-tips --pace-report --kill-frame-report "%O%\frames_%~2.json" > "%O%\replay_%~2.txt" 2>&1
if errorlevel 1 exit /b 1
findstr /b /c:"SCRIPT ERROR" "%O%\replay_%~2.txt" >nul && (call "%JW%" fail "battle replay logged a script error" & exit /b 1)
exit /b 0
