@echo off
rem Issue 2044 look_bench capture (Opus, Nov 25): after = PR head d291e30b51d76469a712d5b4d040b205bf49cd1f, before = main a460906224a6c6f2603fe4f6eb150f14b1dfd52e, cameras 170 and 26, the PR's own
rem rows (godot/bench/look_moments_2044.json). R407: the PR is green and passed review at this head. Built from opus_job_template.bat; the
rem job head fetches the mirror only when a pin is missing (no full fetch, no mirror lock while the pins are present).
rem The before checkout runs the after side's bench script and rows, copied into an untracked folder (bench_after), so
rem both sides draw the same rows with the same bench; tracked files stay at the pin.
setlocal EnableExtensions
set "JOB=opus2044cap"
set "LABEL=2044"
set "TOOLS=godot"
set "PIN_NEW=d291e30b51d76469a712d5b4d040b205bf49cd1f"
set "PIN_OLD=a460906224a6c6f2603fe4f6eb150f14b1dfd52e"
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

set "BT=%OJ_OUT%\bench_tool"
call :one new %PIN_NEW%
call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "SCENE=res://bench/look_bench.tscn"
set "ROWS=res://bench/look_moments_2044.json"
if /i "%1"=="new" (
  if not exist "%BT%" mkdir "%BT%"
  copy /y "%OJ_REPO%\godot\bench\look_bench.gd" "%BT%\look_bench.gd" > nul
  copy /y "%OJ_REPO%\godot\bench$5" "%BT%$5" > nul
)
if /i "%1"=="old" (
  if not exist "%OJ_REPO%\godot\bench_after" mkdir "%OJ_REPO%\godot\bench_after"
  copy /y "%BT%\look_bench.gd" "%OJ_REPO%\godot\bench_after\look_bench.gd" > nul
  copy /y "%BT%$5" "%OJ_REPO%\godot\bench_after$5" > nul
  > "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo [gd_scene load_steps=2 format=3]
  >> "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo.
  >> "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo [ext_resource type="Script" path="res://bench_after/look_bench.gd" id="1"]
  >> "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo.
  >> "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo [node name="LookBench" type="Node"]
  >> "%OJ_REPO%\godot\bench_after\look_bench.tscn" echo script = ExtResource("1"^)
  set "SCENE=res://bench_after/look_bench.tscn"
  set "ROWS=res://bench_after/look_moments_2044.json"
)
if not exist "%BT%$5" (call "%JW%" fail "rows file missing" & exit /b 1)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 5400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 "%SCENE%" -- --out "%O%" --part moments --moments "%ROWS%" --commit %2 > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
exit /b 0
