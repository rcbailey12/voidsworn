@echo off
setlocal
rem Issue 2022. Run on a GPU lane after CI and review pass. Optional args: AFTER BEFORE.
set "WRECK_AFTER=%~1"
set "WRECK_BEFORE=%~2"
if not defined WRECK_AFTER set "WRECK_AFTER=origin/codex/issue-2022"
if not defined WRECK_BEFORE set "WRECK_BEFORE=96149fbb08feaa676a1bd447944fcad78ea5a3d8"
set "LB_HOME=%USERPROFILE%\Downloads\voidsworn_test\look_bench\issue-2022"
set "LB_TOOL_REF=%WRECK_AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_wreck_2022.json"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "PC_GPU_ISSUE=2022"
call "%~dp0look_bench.bat" "%WRECK_AFTER%" "%WRECK_BEFORE%"
exit /b %ERRORLEVEL%
