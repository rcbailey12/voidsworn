@echo off
rem Issue 1180 LIVE janitor run (Board queues it; R336 and R339). Code: main at eace9e2cc53e0f9ebcd7fdd1f20dd96633c49a10 (PR 1252 merge).
rem Removes only what janitor.ps1's rules allow: rebuildable kept copies, finished work217 run copies (after checked
rem salvage where they hold local work), owned TEMP scratch and old opus<N> helper folders. Everything else is kept.
rem Order: a fresh dry run first (for comparison), then the live run. The janitor writes its own
rem voidsworn_test\janitor_<stamp>.txt (free space before and after, one row per folder, "all done").
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1180"
set "C=%H%\live_repo"
set "O=%H%\out_live"
set "WANT=eace9e2cc53e0f9ebcd7fdd1f20dd96633c49a10"
if not exist "%O%" mkdir "%O%"
echo started %DATE% %TIME% > "%O%\result.txt"
if not exist "%C%\.git" git clone -q --filter=blob:none --sparse --no-checkout https://github.com/rcbailey12/voidsworn "%C%" >> "%O%\result.txt" 2>&1
git -C "%C%" sparse-checkout set tools/pc >> "%O%\result.txt" 2>&1
git -C "%C%" fetch -q origin main >> "%O%\result.txt" 2>&1
git -C "%C%" checkout -q -f --detach %WANT% >> "%O%\result.txt" 2>&1
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set "GOT=%%H"
echo code %GOT% >> "%O%\result.txt"
if /i not "%GOT%"=="%WANT%" (
  echo FAILED: checkout is %GOT%, wanted %WANT%; nothing run >> "%O%\result.txt"
  echo all done >> "%O%\result.txt"
  exit /b 1
)
if not exist "%C%\tools\pc\janitor.ps1" (
  echo FAILED: janitor.ps1 missing; nothing run >> "%O%\result.txt"
  echo all done >> "%O%\result.txt"
  exit /b 1
)
echo dry run started %DATE% %TIME% >> "%O%\result.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\janitor.ps1" --dry-run > "%O%\janitor_dry_before.txt" 2>&1
echo dry run exit code %ERRORLEVEL% >> "%O%\result.txt"
for /f %%N in ('findstr /C:"would remove" "%O%\janitor_dry_before.txt" ^| find /c /v ""') do echo dry run would remove rows: %%N >> "%O%\result.txt"
echo live run started %DATE% %TIME% >> "%O%\result.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\janitor.ps1" > "%O%\janitor_live.txt" 2>&1
echo live run exit code %ERRORLEVEL% (0 is clean, also when some folders were in use) >> "%O%\result.txt"
for /f "delims=" %%L in ('dir /b /o-d "%VT%\janitor_*.txt" 2^>nul') do if not defined LOGF set "LOGF=%%L"
if defined LOGF copy /y "%VT%\%LOGF%" "%O%\%LOGF%" > nul
echo janitor log %LOGF% >> "%O%\result.txt"
for /f %%N in ('findstr /B /C:"removed" /C:"kept checkout removed" "%O%\janitor_live.txt" ^| find /c /v ""') do echo removed rows: %%N >> "%O%\result.txt"
for /f %%N in ('findstr /C:"salvage verified" "%O%\janitor_live.txt" ^| find /c /v ""') do echo salvage files verified: %%N >> "%O%\result.txt"
findstr /C:"free space" /C:"all done" /C:"janitor stopped" /C:"could not start" /C:"skipped" /C:"lock in use" "%O%\janitor_live.txt" >> "%O%\result.txt"
echo all done %DATE% %TIME% >> "%O%\result.txt"
endlocal
