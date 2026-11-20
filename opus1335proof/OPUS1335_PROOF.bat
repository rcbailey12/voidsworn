@echo off
title Code-only: 1335 salvage stdin proof, main 1f9ff05a, janitor DRY RUN only (Board, Nov 20)
rem Board, Nov 20 16:19 UTC: a fresh checkout of main 1f9ff05a (PR 1345) from repo-mirror.git in opus1335proof\repo; then (1) node
rem contrib\opus\tools\salvage_stdin_tests.js with voidsworn_test\node\node.exe, launched from Windows PowerShell 5.1; (2) that checkout's
rem tools\pc\janitor.bat --dry-run (report only, no removals). Outside the GPU and ship lines; touches no tools_live file. Deletes nothing.
rem Writes opus1335proof\result.txt; its own end line is "OPUS1335 proof exit".
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%V%\opus1335proof"
set "R=%W%\repo"
set "SHA=1f9ff05acd1baf6cc9199ae7c202b6845ff24969"
set "RES=%W%\result.txt"
set "RC=1"
if exist "%R%" (echo FAIL: %R% already exists >> "%RES%" & goto end)
if not exist "%W%" mkdir "%W%"
echo start %DATE% %TIME% > "%RES%"
git -c core.autocrlf=false clone -q --no-checkout "%V%\repo-mirror.git" "%R%" >> "%RES%" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%RES%" 2>&1
for /f %%H in ('git -C "%R%" rev-parse HEAD') do set "HEADC=%%H"
echo commit=!HEADC! >> "%RES%"
if not "!HEADC!"=="%SHA%" (echo FAIL: checkout is not at the pin >> "%RES%" & goto end)
powershell -NoProfile -Command "'PowerShell ' + $PSVersionTable.PSVersion.ToString() + ', OEM code page ' + [Console]::OutputEncoding.CodePage + ', chcp ' + ((chcp) -replace '\D','')" >> "%RES%" 2>&1
pushd "%R%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%V%\node\node.exe' contrib\opus\tools\salvage_stdin_tests.js; exit $LASTEXITCODE" > "%W%\salvage_stdin_tests.txt" 2>&1
set "TX=!ERRORLEVEL!"
popd
echo salvage_stdin_tests exit !TX! >> "%RES%"
call "%R%\tools\pc\janitor.bat" --dry-run > "%W%\janitor_dry_1335.txt" 2>&1
set "JX=!ERRORLEVEL!"
echo janitor dry run exit !JX! >> "%RES%"
if "!TX!"=="0" if "!JX!"=="0" set "RC=0"
:end
echo OPUS1335 proof exit !RC! at %TIME% >> "%RES%"
endlocal & exit /b %RC%