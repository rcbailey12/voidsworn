@echo off
rem Issue 1693 run 4. Board queue only after the exact AFTER commit passes checks and review (R407).
rem Usage: wave2b_run4.bat AFTER_SHA
rem The same four rows run at cameras 170 and 26 on both pins. Each run has a warm pass before saving frames.
setlocal EnableExtensions
set "AFTER=%~1"
set AFTER | findstr /r /x "AFTER=[0-9a-fA-F][0-9a-fA-F]*" >nul || goto usage
if "%AFTER:~39,1%"=="" goto usage
if not "%AFTER:~40,1%"=="" goto usage
rem BEFORE is the run 3 tip with the same main already merged by the run 4 runner.
set "BEFORE=5d445b9a34374dd9685d86a65a9add51982ed713"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "BENCH=%~dp0look_bench.bat"
if not exist "%BENCH%" set "BENCH=%VT%\build_b\tools\pc\jobs\look_bench.bat"
if not exist "%BENCH%" (
  echo FAILED: look_bench.bat not found.
  exit /b 2
)
set "PC_GPU_ISSUE=1693"
set "LB_HOME=%VT%\look_bench_1693_run4"
set "LB_TOOL_REF=%AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_1693_run4.json"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "LB_QUIET=1"
call "%BENCH%" "%AFTER%" "%BEFORE%"
exit /b %ERRORLEVEL%

:usage
echo Usage: wave2b_run4.bat AFTER_SHA ^(the full 40-character reviewed commit^)
exit /b 2
