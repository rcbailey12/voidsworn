@echo off
rem Work one job-board issue with Codex on Ryan's PC (queued by codex_board.ps1 as a lane B job).
rem Usage: codex_issue.bat <issue number>
rem Fresh checkout of main in Downloads\voidsworn_test\board\repo on branch codex/issue-<n>, Codex runs at the effort
rem the issue names (high by default), then the change is committed and pushed. GitHub opens the PR and runs the checks.
rem If the push fails, the change is saved as build_b\cx_issue<n>.patch for Opus instead.
rem Everything for the job (log, Codex's report, result) lands in Downloads\voidsworn_test\board\issue-<n>\.
setlocal
set "N=%~1"
if "%N%"=="" (echo usage: codex_issue.bat ^<issue number^> & exit /b 2)
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "B=%ROOT%\build_b"
set "R=%ROOT%\board\repo"
set "O=%ROOT%\board\issue-%N%"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File %B%\tools\pc\codex_issue.ps1"
if not exist "%O%" mkdir "%O%"
echo started %date% %time% > "%O%\result.txt"
if not exist "%R%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%R%"
if not exist "%R%\.git" (echo clone failed >> "%O%\result.txt" & exit /b 4)
pushd "%R%"
git config core.autocrlf false
git fetch -q --depth 1 origin main
if errorlevel 1 goto :fetchfail
git checkout -q -f -B codex/issue-%N% origin/main
git clean -fdq
%PS% prep %N% "%R%" "%O%"
if errorlevel 1 goto :prepfail
set /p EFF=<"%O%\effort.txt"
call "%B%\tools\pc\tmo.bat" 3600 "%APPDATA%\npm\codex.cmd" exec -m gpt-6.1-sol -c model_reasoning_effort=%EFF% --approve-for-me --ephemeral --color never -C "%R%" -o "%O%\last.md" "Read CODEX_TASK.md in this folder and do exactly what it says. Do not commit." > "%O%\log.txt" 2>&1
echo codex exit %ERRORLEVEL% >> "%O%\result.txt"
rem Usage limit: leave the issue for the board to retry on a later poll instead of marking it done.
rem Nov 3 fix: look only at the last 40 lines. Codex often prints this script while it works, so a whole-log
rem search matched its own text and threw away three finished jobs (66, 75, 78).
powershell -NoProfile -Command "if ((Get-Content -LiteralPath '%O%\log.txt' -Tail 40) -match ('hit your usage'+' limit')) { exit 1 }; exit 0"
if errorlevel 1 goto :limit
del /q CODEX_TASK.md 2>nul
git add -A
git diff --cached --quiet
if not errorlevel 1 goto :nochange
%PS% msg %N% "%R%" "%O%"
git -c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com" commit -q -F "%O%\commit.txt"
git push -q -f origin codex/issue-%N% > "%O%\push.txt" 2>&1
if errorlevel 1 goto :pushfail
echo pushed codex/issue-%N% >> "%O%\result.txt"
popd
exit /b 0
:pushfail
git format-patch -1 --stdout > "%B%\cx_issue%N%.patch"
echo push failed, patch saved as build_b\cx_issue%N%.patch >> "%O%\result.txt"
popd
exit /b 8
:nochange
echo Codex made no changes >> "%O%\result.txt"
popd
exit /b 7
:fetchfail
echo fetch failed >> "%O%\result.txt"
popd
exit /b 5
:prepfail
echo could not read the issue >> "%O%\result.txt"
popd
exit /b 6
:limit
echo usage limit hit, left on the board to retry >> "%O%\result.txt"
del /q CODEX_TASK.md 2>nul
rem Keep whatever Codex got done as a patch before resetting the checkout.
git add -A
git diff --cached --binary > "%O%\limit_wip.patch"
git reset -q
git checkout -q -f -- .
git clean -fdq
powershell -NoProfile -Command "$f=Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\board\queued.txt'; (Get-Content $f) -ne '%N%' | Set-Content $f"
popd
exit /b 9
