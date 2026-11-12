@echo off
rem Work one job-board issue with Codex on Ryan's PC (queued by codex_board.ps1 as a lane B job).
rem Usage: codex_issue.bat <issue number>
rem Fresh checkout of main in Downloads\voidsworn_test\board\repo on branch codex/issue-<n>, Codex runs at the effort
rem the issue names (high by default), then the change is committed and pushed. GitHub opens the PR and runs the checks.
rem If the push fails, the change is saved as build_b\cx_issue<n>.patch for Opus instead.
rem Everything for the job (log, Codex's report, result) lands in Downloads\voidsworn_test\board\issue-<n>\.
rem Runner 2 (issue 377, Opus, Nov 12 2026), the same steps as tools/pc/work_issue.bat through work_issue.ps1:
rem  a Codex exit code that is not 0 (124 is the time cap) pushes to codex/issue-<n>-partial, which opens no pull request;
rem  the guard step refuses ship, gen, .uid, .import and oversized files (copies kept per run in board\issue-<n>\runs\<date_time>\refused) and warns
rem  about files outside the issue's Deliver to; one checked commit keeps the branch's earlier tip as a parent, so the push
rem  needs no force; GitHub's branch must then carry exactly out\diffstat.txt, or the run stops loudly (DIFF MISMATCH).
rem Test mode (for the Board's dry runs): CODEX_TEST_ROOT moves repo and out folders there, CODEX_TEST_AGENT is a .bat run
rem in place of Codex (no Codex usage), CODEX_TEST_BRANCH is the branch pushed to (it must not start with codex/, muse/,
rem work/ or opus/), CODEX_TEST_SPARSE lists the only folders a lean test clone checks out.
setlocal
set "N=%~1"
if "%N%"=="" (echo usage: codex_issue.bat ^<issue number^> & exit /b 2)
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "B=%ROOT%\build_b"
set "TP=%~dp0"
set "R=%ROOT%\board\repo"
set "O=%ROOT%\board\issue-%N%"
set "BR=codex/issue-%N%"
set "PUSHMODE=real"
if not defined CODEX_TEST_ROOT goto :setup
set "B=%CODEX_TEST_ROOT%"
set "R=%CODEX_TEST_ROOT%\repo"
set "O=%CODEX_TEST_ROOT%\issue-%N%"
set "PUSHMODE=dry"
if not defined CODEX_TEST_BRANCH goto :setup
echo %CODEX_TEST_BRANCH%| findstr /r /i /c:"^codex/" /c:"^muse/" /c:"^work/" /c:"^opus/" > nul
if not errorlevel 1 (echo CODEX_TEST_BRANCH must not start with codex/, muse/, work/ or opus/ & exit /b 2)
set "BR=%CODEX_TEST_BRANCH%"
set "PUSHMODE=test"
:setup
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%codex_issue.ps1""
set "PSW=powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%work_issue.ps1""
rem The run's commit carries Ryan's git identity, as before.
set "GIT_AUTHOR_NAME=Ryan Bailey"
set "GIT_AUTHOR_EMAIL=rcbailey12@gmail.com"
set "GIT_COMMITTER_NAME=Ryan Bailey"
set "GIT_COMMITTER_EMAIL=rcbailey12@gmail.com"
if not exist "%O%" mkdir "%O%"
echo started %date% %time% > "%O%\result.txt"
if exist "%R%\.git" goto :cloned
if defined CODEX_TEST_SPARSE goto :leanclone
git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%R%"
goto :cloned
:leanclone
git clone -q -c core.autocrlf=false --depth 1 --filter=blob:none --sparse https://github.com/rcbailey12/voidsworn "%R%"
if exist "%R%\.git" git -C "%R%" sparse-checkout add %CODEX_TEST_SPARSE%
:cloned
if not exist "%R%\.git" (echo clone failed >> "%O%\result.txt" & exit /b 4)
pushd "%R%"
git config core.autocrlf false
git fetch -q --depth 1 origin main
if errorlevel 1 goto :fetchfail
git checkout -q -f -B %BR% origin/main
git clean -fdq
git log -1 --format=%%H > "%O%\base_commit.txt"
%PS% prep %N% "%R%" "%O%"
if errorlevel 1 goto :prepfail
set /p EFF=<"%O%\effort.txt"
if defined CODEX_TEST_ROOT if defined CODEX_TEST_AGENT goto :testagent
call "%TP%tmo.bat" 3600 "%APPDATA%\npm\codex.cmd" exec -m gpt-6.1-sol -c model_reasoning_effort=%EFF% --approve-for-me --ephemeral --color never -C "%R%" -o "%O%\last.md" "Read CODEX_TASK.md in this folder and do exactly what it says. Do not commit." > "%O%\log.txt" 2>&1
set "CX=%ERRORLEVEL%"
goto :ran
:testagent
call "%TP%tmo.bat" 600 "%COMSPEC%" /c %CODEX_TEST_AGENT% > "%O%\log.txt" 2>&1
set "CX=%ERRORLEVEL%"
:ran
echo codex exit %CX% >> "%O%\result.txt"
rem Usage limit: leave the issue for the board to retry on a later poll instead of marking it done.
rem Nov 3 fix: look only at the last 40 lines. Codex often prints this script while it works, so a whole-log
rem search matched its own text and threw away three finished jobs (66, 75, 78).
powershell -NoProfile -Command "if ((Get-Content -LiteralPath '%O%\log.txt' -Tail 40) -match ('hit your usage'+' limit')) { exit 1 }; exit 0"
if errorlevel 1 goto :limit
del /q CODEX_TASK.md 2>nul
rem A run that did not end cleanly is PARTIAL: its own branch, no pull request (issue 377).
set "PB=%BR%"
set "PARTIAL="
if not "%CX%"=="0" set "PARTIAL=codex exit %CX%"
if "%CX%"=="124" set "PARTIAL=stopped at the time cap"
git rev-parse -q --verify MERGE_HEAD > nul 2>&1
if not errorlevel 1 set "PARTIAL=Codex left a merge unfinished"
if defined PARTIAL set "PB=%BR%-partial"
> "%O%\partial.txt" echo.%PARTIAL%
if defined PARTIAL echo PARTIAL RUN, %PARTIAL%: the work goes to %PB%, which opens no pull request >> "%O%\result.txt"
git add -A
%PS% msg %N% "%R%" "%O%"
%PSW% guard %N% codex "%R%" "%O%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :guardfail
git diff --cached --quiet
if not errorlevel 1 goto :nochange
%PSW% commit "%R%" "%O%" %PB% %PUSHMODE% >> "%O%\result.txt" 2>&1
set "SX=%ERRORLEVEL%"
if "%SX%"=="7" goto :nochange
if not "%SX%"=="0" goto :stopped
if "%PUSHMODE%"=="dry" (git push --dry-run origin HEAD:refs/heads/%PB% > "%O%\push.txt" 2>&1) else (git push origin HEAD:refs/heads/%PB% > "%O%\push.txt" 2>&1)
if errorlevel 1 goto :pushfail
%PSW% confirm "%R%" "%O%" %PB% %PUSHMODE% >> "%O%\result.txt" 2>&1
set "SX=%ERRORLEVEL%"
if not "%SX%"=="0" goto :stopped
if "%PUSHMODE%"=="dry" (echo dry run: push to %PB% would work, nothing pushed >> "%O%\result.txt") else (echo pushed %PB% >> "%O%\result.txt")
popd
exit /b 0
:pushfail
set /p PRE=<"%O%\pre_commit.txt"
git diff --binary --output="%B%\cx_issue%N%.patch" %PRE% HEAD
echo push failed, patch saved as build_b\cx_issue%N%.patch >> "%O%\result.txt"
popd
exit /b 8
:stopped
echo push stopped, the runner's check failed with code %SX%: read the lines above >> "%O%\result.txt"
popd
exit /b %SX%
:guardfail
echo the refuse step failed: nothing committed, nothing pushed >> "%O%\result.txt"
popd
exit /b 13
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
