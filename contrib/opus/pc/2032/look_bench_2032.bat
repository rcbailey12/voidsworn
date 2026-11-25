@echo off
setlocal
rem Run on a GPU lane after both CI and review pass. Optional args: AFTER BEFORE.
set "AFTER=%~1"
set "BEFORE=%~2"
if not defined AFTER set "AFTER=origin/codex/issue-2032"
if not defined BEFORE set "BEFORE=17b151f032d7562d47f9db083322c4d064bcb1aa"
if /i "%BEFORE%"=="none" (
  echo Issue 2032 needs both the before and after revisions.
  exit /b 1
)
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "LB_HOME=%VT%\look_bench\issue-2032"
set "LB_TOOL_REF=%AFTER%"
set "LB_ARGS=--part moments --moments "%LB_HOME%\tool\contrib\opus\pc\2032\look_moments.json" --strict-moments"
set "LB_PRE_RUN="
set "LB_RUN_NAME="
set "LB_QUIET=1"
set "PC_GPU_ISSUE=2032"
call "%~dp0..\..\..\..\tools\pc\jobs\look_bench.bat" "%AFTER%" "%BEFORE%"
if errorlevel 1 exit /b 1

rem The stock bench leaves the tool at AFTER, and its game checkout at BEFORE.
for /f %%H in ('git -C "%LB_HOME%\tool" rev-parse --short^=8 HEAD') do set "AFTER_SHA=%%H"
for /f %%H in ('git -C "%LB_HOME%\repo" rev-parse --short^=8 HEAD') do set "BEFORE_SHA=%%H"
if not defined AFTER_SHA exit /b 1
if not defined BEFORE_SHA exit /b 1
set "SHEETS=%LB_HOME%\sheets\%BEFORE_SHA%_vs_%AFTER_SHA%"
set "SHOTS=%VT%\board\issue-2032\shots"
if not exist "%SHOTS%" mkdir "%SHOTS%"
for %%I in (Lance_hit Torpedo_kill Capital_death) do (
  copy /y "%SHEETS%\moments_overview_2032_%%I.jpg" "%SHOTS%\2032_%%I.jpg" > nul
  if errorlevel 1 exit /b 1
  copy /y "%SHEETS%\moments_overview_2032_%%I.jpg.provenance.json" "%SHOTS%\2032_%%I.jpg.provenance.json" > nul
  if errorlevel 1 exit /b 1
)
echo 2032 review sheets: "%SHOTS%"
exit /b 0
