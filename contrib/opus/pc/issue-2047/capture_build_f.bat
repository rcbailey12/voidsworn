@echo off
rem Board GPU job, only after All checks and independent review (R407, R413).
rem Usage: capture_build_f.bat AFTER_SHA [BEFORE_SHA]
rem Pass full commit pins. A committed PR checkout can use its HEAD by double-clicking.
rem If omitted, BEFORE is the base from the build brief.
setlocal EnableExtensions
set "AFTER=%~1"
set "BEFORE=%~2"
if not defined AFTER for /f %%H in ('git -C "%~dp0." rev-parse HEAD 2^>nul') do set "AFTER=%%H"
if not defined AFTER (
  echo Usage: capture_build_f.bat AFTER_SHA [BEFORE_SHA]
  exit /b 2
)
if not defined BEFORE set "BEFORE=deec695cb3c3137241d889eedb266b22ef365d96"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not exist "%HEAD%" (echo FAILED: missing tools_live PC job head & exit /b 2)
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "OJ_NEED_HULLS=V16_37 C15s_23 D20_23 H9_23 I15_11 D21_23"
call "%HEAD%" init buildf2047 2047 "godot pil"
if errorlevel 1 exit /b %ERRORLEVEL%

set "ROWS=%OJ_OUT%\build_f_rows.json"
set "SHEETS=%OJ_OUT%\build_f_sheets.py"
set "PICTURE_PYTHON=%JW_PIL%"
set "REVIEW=%OJ_OUT%\out_review"
if not defined VS_2047_SHOTS set "VS_2047_SHOTS=%VT%\board_f\issue-2047\shots"
call :one new "%AFTER%"
if errorlevel 1 goto tail
call :one old "%BEFORE%"
if errorlevel 1 goto tail
set "JW_STEP=label and verify c170 and c26 sheets"
set "JW_EXPECT=%REVIEW%\PASS.txt"
call "%JW%" run 300 "%JW_PIL%" "%SHEETS%" "%OJ_REPO%\tools" "%OJ_OUT%\out_old" "%OJ_OUT%\out_new" "%REVIEW%" "%VS_2047_SHOTS%" > "%OJ_OUT%\sheets.txt" 2>&1
:tail
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %~1 "%~2"
if errorlevel 1 exit /b 1
call "%HEAD%" ships
if errorlevel 1 exit /b 1
if "%~1"=="new" (
  copy /y "%OJ_REPO%\godot\bench\look_moments_beams_2047.json" "%ROWS%" > nul
  if errorlevel 1 (call "%JW%" fail "copy matched bench rows" & exit /b 1)
  copy /y "%OJ_REPO%\contrib\opus\pc\issue-2047\build_f_sheets.py" "%SHEETS%" > nul
  if errorlevel 1 (call "%JW%" fail "copy sheet builder" & exit /b 1)
)
set "O=%OJ_OUT%\out_%~1"
mkdir "%O%"
if errorlevel 1 (call "%JW%" fail "create %~1 output folder" & exit /b 1)
set "PICTURE_SOURCE_REPO=%OJ_REPO%"
set "PICTURE_STAMP_TOOL=%OJ_REPO%\tools\picture_provenance.py"
set "JW_STEP=%~1 import"
call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 exit /b 1
rem RULEBOOK 12.5: capture both pins twice and keep their second render.
call :bench "%~1 warm" "%OJ_OUT%\warm_%~1" "%~2" "%O%\warm.txt"
if errorlevel 1 exit /b 1
call :bench "%~1 keep" "%O%" "%~2" "%O%\bench.txt"
exit /b %ERRORLEVEL%

:bench
set "JW_STEP=%~1"
set "JW_EXPECT=%~2\bench.json;%~2\moments.json"
call "%JW%" run 3600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%~2" --commit "%~3" --part moments --moments "%ROWS%" > "%~4" 2>&1
if errorlevel 1 exit /b 1
findstr /c:"LOOK_BENCH_DONE" "%~4" > nul
if errorlevel 1 (call "%JW%" fail "%~1 missing LOOK_BENCH_DONE" & exit /b 1)
findstr /c:"SCRIPT ERROR" /c:"SHADER ERROR" /c:"LOOK_BENCH CODE MISMATCH" /c:"reported no impact time" "%~4" > nul
if not errorlevel 1 (call "%JW%" fail "%~1 invalid capture, see bench log" & exit /b 1)
exit /b 0
