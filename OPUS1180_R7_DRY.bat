@echo off
rem Issue 1180 run 7 (Opus helper, branch opus/issue-1180-run7: superseded ship and gen files): janitor DRY RUN on the real PC.
rem Dry run only: it lists every cleanup candidate with size and reason and removes nothing (janitor.ps1 --dry-run).
rem Writes only under Downloads\voidsworn_test\opus1180r7\. No GPU. Nothing is deleted.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1180r7"
set "C=%H%\repo"
set "O=%H%\out"
if not exist "%O%" mkdir "%O%"
echo started %DATE% %TIME% > "%O%\result.txt"
if not exist "%C%\.git" git clone -q --depth 5 --filter=blob:none --sparse -b opus/issue-1180-run7 https://github.com/rcbailey12/voidsworn "%C%" >> "%O%\result.txt" 2>&1
git -C "%C%" sparse-checkout set tools/pc >> "%O%\result.txt" 2>&1
git -C "%C%" fetch -q --depth 5 origin opus/issue-1180-run7 >> "%O%\result.txt" 2>&1
git -C "%C%" checkout -q -f -B run1180 FETCH_HEAD >> "%O%\result.txt" 2>&1
git -C "%C%" rev-parse HEAD > "%O%\commit.txt"
type "%O%\commit.txt" >> "%O%\result.txt"
if not exist "%C%\tools\pc\janitor.ps1" (
  echo FAILED: janitor.ps1 missing from the checkout >> "%O%\result.txt"
  echo all done >> "%O%\result.txt"
  exit /b 1
)
echo janitor dry run started %DATE% %TIME% >> "%O%\result.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\janitor.ps1" --dry-run > "%O%\janitor_dry.txt" 2>&1
echo janitor dry run exit code %ERRORLEVEL% (0 is clean) >> "%O%\result.txt"
for /f %%N in ('findstr /C:"would remove" "%O%\janitor_dry.txt" ^| find /c /v ""') do echo would remove rows: %%N >> "%O%\result.txt"
for /f %%N in ('findstr /C:"would keep" /C:"retained" /C:"kept" "%O%\janitor_dry.txt" ^| find /c /v ""') do echo keep rows: %%N >> "%O%\result.txt"
for /f %%N in ('findstr /C:"dubious ownership" "%O%\janitor_dry.txt" ^| find /c /v ""') do echo dubious ownership rows: %%N >> "%O%\result.txt"
findstr /C:"superseded by the shared build" /C:"copy is not older" /C:"time not trusted" "%O%\janitor_dry.txt" > "%O%\superseded_calls.txt"
for /f %%N in ('findstr /C:"superseded by the shared build" "%O%\janitor_dry.txt" ^| find /c /v ""') do echo superseded calls: %%N >> "%O%\result.txt"
findstr /C:"free space" /C:"all done" /C:"janitor stopped" /C:"could not start" "%O%\janitor_dry.txt" >> "%O%\result.txt"
echo all done %DATE% %TIME% >> "%O%\result.txt"
endlocal
