@echo off
rem Issue 2046. Board GPU queue, after green checks and review.
rem capture.bat [AFTER [BEFORE]]     capture.bat --dry-run
setlocal
for %%P in ("%~dp0..\..\..\..") do set "ROOT=%%~fP"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "BENCH=%ROOT%\tools\pc\jobs\look_bench.bat"
set "ROWS=%ROOT%\godot\bench\look_moments_2046.json"
if /i "%~1"=="--dry-run" (
  if not exist "%BENCH%" exit /b 1
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0proof.ps1" -RowsPath "%ROWS%"
  exit /b
)
set "AFTER_REF=%~1"
set "BEFORE_REF=%~2"
if not defined AFTER_REF set "AFTER_REF=origin/codex/issue-2046"
rem The shared bench needs Wounds V2 on both revisions.
if not defined BEFORE_REF set "BEFORE_REF=96149fbb08feaa676a1bd447944fcad78ea5a3d8"
if not defined VS_2046_SHOTS set "VS_2046_SHOTS=%VT%\board_e\issue-2046\shots"
set "LB_HOME=%VT%\look_bench_2046"
set "LB_TOOL_REF=%AFTER_REF%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_2046.json"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "LB_QUIET=1"
set "PC_GPU_ISSUE=2046"
call "%BENCH%" "%AFTER_REF%" "%BEFORE_REF%"
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0proof.ps1" -RowsPath "%ROWS%" -BenchHome "%LB_HOME%" -Shots "%VS_2046_SHOTS%"
exit /b %ERRORLEVEL%
