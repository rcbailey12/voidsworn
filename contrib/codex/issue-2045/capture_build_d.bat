@echo off
rem Queue after the exact after revision has green checks and has passed review (R407).
rem Usage: capture_build_d.bat [AFTER [BEFORE]] or capture_build_d.bat --plan (no capture).
setlocal
for %%I in ("%~dp0..\..\..") do set "REPO=%%~fI"
set "AFTER=%~1"
set "BEFORE=%~2"
if not defined AFTER set "AFTER=origin/codex/issue-2045"
if not defined BEFORE set "BEFORE=4712aa00fa07f88e156bd08b900eade4fce9628f"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "LB_HOME=%VT%\board\issue-2045\look_bench"
set "SHOTS=%VT%\board\issue-2045\shots"
set "LB_TOOL_REF=%AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_build_d.json"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "LB_QUIET=1"
set "PC_GPU_ISSUE=2045"
set "PC_GPU_WEIGHT=1"
if /i "%AFTER%"=="--plan" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_build_d.ps1" -Plan -Repo "%REPO%"
  exit /b
)
rem The standing look bench owns GPU scheduling through job_wrap and tmo.bat. It also stamps both revisions.
call "%REPO%\tools\pc\jobs\look_bench.bat" "%AFTER%" "%BEFORE%"
if errorlevel 1 exit /b %ERRORLEVEL%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_build_d.ps1" -Repo "%REPO%" -Bench "%LB_HOME%" -Shots "%SHOTS%"
exit /b %ERRORLEVEL%
