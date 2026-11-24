@echo off
rem Issue 2042 (AAA effects sweep, Build A): before/after look bench captures at cameras 170 and 26.
rem Covers all 4 Build A items per faction where they differ:
rem   1. Directional RCS cone jets (voidsworn, hegemony, corsair, ithar, chorus, deathless)
rem   2. Moving engine trails anchored to nozzle and tapered (hegemony, corsair, chorus, deathless)
rem   3. Main engine plumes with bright core and outer wash (all 6 factions)
rem   4. Strike craft trails unified on SH.CRAFT_TRAIL (hegemony, ithar, chorus)
rem
rem Queued by the Board on Ryan's PC GPU line after checks are green and review passes (RULEBOOK 3.12, R407).
rem Double-click or run from the PC queue:
rem   capture_2042_before_after.bat [AFTER_REF] [BEFORE_REF] [go]
rem Defaults: AFTER_REF=origin/neon/issue-2042, BEFORE_REF=origin/main.
rem Sheets land in %USERPROFILE%\Downloads\voidsworn_test\look_bench_2042\sheets\.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "AFTER=%~1"
set "BEFORE=%~2"
set "GOWAIT=%~3"
if "%AFTER%"=="" set "AFTER=origin/neon/issue-2042"
if "%BEFORE%"=="" set "BEFORE=origin/main"

set "PC_GPU_ISSUE=2042"
set "LB_HOME=%VT%\look_bench_2042"
set "LB_TOOL_REF=%AFTER%"
set "LB_ARGS=--part moments --moments res://bench/look_moments_2042.json"

set "LB_BAT="
if exist "%VT%\tools_live\current.txt" (
  set /p TLV=<"%VT%\tools_live\current.txt"
)
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\jobs\look_bench.bat" (
  set "LB_BAT=%VT%\tools_live\%TLV%\pc\jobs\look_bench.bat"
)
if not defined LB_BAT if exist "%~dp0..\..\..\tools\pc\jobs\look_bench.bat" (
  set "LB_BAT=%~dp0..\..\..\tools\pc\jobs\look_bench.bat"
)
if not defined LB_BAT (
  echo FAILED: look_bench.bat not found in tools_live or repo tools\pc\jobs
  exit /b 2
)

echo Running issue 2042 Build A before/after look bench:
echo   after:   %AFTER%
echo   before:  %BEFORE%
echo   moments: res://bench/look_moments_2042.json (cameras 170 and 26)
echo   output:  %LB_HOME%\sheets\
call "%LB_BAT%" "%AFTER%" "%BEFORE%" "%GOWAIT%"
exit /b %ERRORLEVEL%
