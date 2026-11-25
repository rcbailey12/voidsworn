@echo off
setlocal
rem Issue 2018. Run on the Board GPU line after green checks and review.
rem Optional: capture.bat AFTER BEFORE. --plan validates the rows without running Godot.
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "SPARK_MOMENTS=%~dp0look_moments.json"
set "SPARK_BASE=dc3bff4a6e5d625d8b19423db2a18b4b777d559a"
set "SPARK_JOB=%VT%\board\issue-2018"
set "SPARK_SHOTS=%SPARK_JOB%\shots"
set "SPARK_AFTER=%~1"
set "SPARK_BEFORE=%~2"
if /i "%SPARK_AFTER%"=="--plan" goto plan
if not defined SPARK_AFTER set "SPARK_AFTER=origin/codex/issue-2018"
if not defined SPARK_BEFORE set "SPARK_BEFORE=%SPARK_BASE%"
set "PC_GPU_ISSUE=2018"
set "LB_HOME=%SPARK_JOB%\bench"
set "LB_TOOL_REF=%SPARK_BASE%"
set "LB_RUN_NAME="
set "LB_PRE_RUN="
set "LB_QUIET=1"
set "LB_MOMENTS=%SPARK_MOMENTS%"
call "%~dp0..\..\..\tools\pc\jobs\look_bench.bat" "%SPARK_AFTER%" "%SPARK_BEFORE%" go
if errorlevel 1 exit /b 1
for /f %%H in ('git -C "%LB_HOME%\repo" rev-parse --short^=8 "%SPARK_AFTER%"') do set "SPARK_A=%%H"
for /f %%H in ('git -C "%LB_HOME%\repo" rev-parse --short^=8 "%SPARK_BEFORE%"') do set "SPARK_B=%%H"
if not defined SPARK_A exit /b 1
if not defined SPARK_B exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0review_sheets.ps1"
exit /b %ERRORLEVEL%

:plan
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0review_sheets.ps1" -Plan
exit /b %ERRORLEVEL%
