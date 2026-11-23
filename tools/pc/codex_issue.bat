@echo off
rem Work one job-board issue with Codex on Ryan's PC (queued by codex_board.ps1 as a lane B job).
rem Usage: codex_issue.bat <issue number>
rem Fresh checkout of main in the lane's Downloads\voidsworn_test\board*\repo (issue 947) on branch codex/issue-<n>, Codex runs at the effort
rem the issue names (high by default), then the change is committed and pushed. GitHub opens the PR and runs the checks.
rem If the push fails, the change is saved as build_b\cx_issue<n>.patch for Opus instead.
rem Everything for the job (log, Codex's report, result) lands in Downloads\voidsworn_test\board\issue-<n>\.
rem Runner 2 (issue 377, Opus, Nov 12 2026), the same steps as tools/pc/work_issue.bat through work_issue.ps1:
rem  a Codex exit code that is not 0 (124 is stall or ceiling) pushes to codex/issue-<n>-partial, which opens no pull request;
rem  the guard step refuses ship, gen, .uid, .import and oversized files (copies kept per run in board\issue-<n>\runs\<date_time>\refused) and warns
rem  about files outside the issue's Deliver to; one checked commit keeps the branch's earlier tip as a parent, so the push
rem  needs no force; GitHub's branch must then carry exactly out\diffstat.txt, or the run stops loudly (DIFF MISMATCH).
rem Runner 3 (issue 722, audit 706 findings 6 and 7), the same start checks as work_issue.bat: refuse to start below
rem the min_free_gb free-space floor (work217\runner_settings.txt, default 60), warn in result.txt when this tools
rem folder's runner and watchdog files differ from the Board's work217\runner_hashes.txt, and stamp the resolved model
rem (CODEX_MODEL, default gpt-6.2-sol since Nov 17 2026) into out\status.json and result.txt.
rem Test mode (for the Board's dry runs): CODEX_TEST_ROOT moves repo and out folders there, CODEX_TEST_AGENT is a .bat run
rem in place of Codex (no Codex usage), CODEX_TEST_BRANCH is the branch pushed to (it must not start with codex/, muse/,
rem work/ or opus/), CODEX_TEST_SPARSE lists the only folders a lean test clone checks out.
setlocal
set "PYTHONDONTWRITEBYTECODE=1"
rem The one Codex model pin (Ryan, Nov 17 2026: fresh work on gpt-6.2-sol). Change it here only.
if not defined CODEX_MODEL set "CODEX_MODEL=gpt-6.2-sol"
set "N=%~1"
if "%N%"=="" (echo usage: codex_issue.bat ^<issue number^> & exit /b 2)
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
rem Same Node 22 as work_issue.bat for the runner's standing checks and parity.
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "PATH=%USERPROFILE%\Downloads\voidsworn_test\node;%PATH%"
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "B=%ROOT%\build_b"
set "TP=%~dp0"
rem %TPC% is %TP% without its trailing backslash, for passing the tools folder as a bare quoted argument (issue 722:
rem cmd merges "%TP%" with the next quoted argument because of the backslash before the quote).
set "TPC=%TP:~0,-1%"
rem Issue 947: each lane runs its own tools copy and its own board folder (build_b main: board, build_c lane B: board_b,
rem build_d lane C: board_c, build_e lane D: board_d). The folder comes from where this file sits, so one runner file
rem serves every lane. On Nov 17 a single hard-coded board\repo sent lanes C and D at the main chain's live checkout.
for %%I in ("%TP%..\..") do set "LANEDIR=%%~fI"
for %%I in ("%LANEDIR%") do set "LANEDIR=%%~nxI"
set "BOARD="
if /i "%LANEDIR%"=="build_b" set "BOARD=board"
if /i "%LANEDIR%"=="build_c" set "BOARD=board_b"
if /i "%LANEDIR%"=="build_d" set "BOARD=board_c"
if /i "%LANEDIR%"=="build_e" set "BOARD=board_d"
if not defined CODEX_TEST_ROOT if not defined BOARD (echo job refused: this runner copy is in %LANEDIR%, which is not a lane tools folder ^(build_b to build_e^); no agent started & exit /b 2)
set "R=%ROOT%\%BOARD%\repo"
set "O=%ROOT%\%BOARD%\issue-%N%"
set "ASSIGNED_BRANCH=codex/issue-%N%"
set "BR=%ASSIGNED_BRANCH%"
set "PUSHMODE=real"
rem R276: all nested GPU launchers inherit the issue and the code-only lane.
set "PC_GPU_ISSUE=%N%"
if not defined PC_GPU_WAIT_SECONDS set "PC_GPU_WAIT_SECONDS=1500"
set "PC_GPU_LANE="
echo %R%| findstr /i /c:"board_c" >nul
if not errorlevel 1 set "PC_GPU_LANE=C"
echo %R%| findstr /i /c:"board_d" >nul
if not errorlevel 1 set "PC_GPU_LANE=D"
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
rem The PowerShell parent owns the lane until this batch returns, including final reporting.
set "PC_RUNNER_TEST=0"
if defined CODEX_TEST_ROOT if defined CODEX_TEST_AGENT set "PC_RUNNER_TEST=1"
if "%~2"=="locked" if /i "%CODEX_LOCKED_REPO%"=="%R%" goto :locked
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TP%codex_issue.ps1" run "%N%" "%R%"
exit /b %ERRORLEVEL%
:locked
set "CODEX_LOCKED_REPO="
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%codex_issue.ps1""
set "PSW=powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%work_issue.ps1""
set "COMMON=powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%runner_common.ps1""
set "CHECKS_OK=0"
rem The run's commit carries Ryan's git identity, as before.
set "GIT_AUTHOR_NAME=Ryan Bailey"
set "GIT_AUTHOR_EMAIL=rcbailey12@users.noreply.github.com"
set "GIT_COMMITTER_NAME=Ryan Bailey"
set "GIT_COMMITTER_EMAIL=rcbailey12@users.noreply.github.com"
if not exist "%O%" mkdir "%O%"
echo started %date% %time% > "%O%\result.txt"
%COMMON% init "%O%" "%BR%"
if errorlevel 1 exit /b 14
rem (722) Free-space floor, Board hashes and the resolved model stamp, as in work_issue.bat.
set "SETF=%ROOT%\work217\runner_settings.txt"
set "HASHF=%ROOT%\work217\runner_hashes.txt"
rem (1739) lane_tools_refresh.ps1 writes each lane's own hashes beside its tools; the shared work217 file went stale.
if exist "%ROOT%\%LANEDIR%\runner_hashes.txt" set "HASHF=%ROOT%\%LANEDIR%\runner_hashes.txt"
%COMMON% space "%O%" "%SETF%" "%ROOT%" "%PUSHMODE%"
if errorlevel 1 exit /b 14
%COMMON% hashcheck "%O%" "%TPC%" "%HASHF%"
rem (1194) Every tmo.bat step runs the canonical watchdog in tools_live: stop when its files differ from its hashes.
set "TLV="
if not "%PC_RUNNER_TEST%"=="1" if exist "%ROOT%\tools_live\current.txt" set /p TLV=<"%ROOT%\tools_live\current.txt"
if not "%PC_RUNNER_TEST%"=="1" if exist "%ROOT%\tools_live\" if not defined TLV (echo tools_live is installed but current.txt is blank; stopped >> "%O%\result.txt" & exit /b 14)
if defined TLV (
  %COMMON% hashcheck "%O%" "%ROOT%\tools_live\%TLV%\pc" "%ROOT%\tools_live\%TLV%\hashes.txt" strict
  if errorlevel 1 exit /b 14
)
%COMMON% model "%O%" "%CODEX_MODEL%" "%CODEX_MODEL%"
%COMMON% wait "%O%"
if errorlevel 1 exit /b 14
rem Validate and claim before checkout, Base/resume merges, preflight or agent work (issue 888).
if not defined CODEX_CAP set "CODEX_CAP=21600"
%COMMON% announce "%O%" "%N%" codex "%R%" "%CODEX_CAP%" "codex_issue.bat %N%" "%PUSHMODE%" "%ASSIGNED_BRANCH%"
if errorlevel 1 exit /b 14
set "SPARSE="
if defined CODEX_TEST_ROOT set "SPARSE=%CODEX_TEST_SPARSE%"
%COMMON% checkout "%R%" "%O%" "%BR%" "%SPARSE%"
if errorlevel 1 exit /b 14
pushd "%R%"
%PS% prep %N% "%R%" "%O%"
if errorlevel 1 goto :prepfail
set /p EFF=<"%O%\effort.txt"
%COMMON% effort "%O%" "%EFF%"
rem Give the probe, agent, and checks one private scratch directory, recorded before use.
set "PC_RUN_TEMP=%TEMP%"
%COMMON% scratch "%O%"
if errorlevel 1 goto :probefail
set /p PC_RUN_SCRATCH=<"%O%\scratch_path.txt" || goto :probefail
set "TEMP=%PC_RUN_SCRATCH%"
set "TMP=%PC_RUN_SCRATCH%"
set "TMPDIR=%PC_RUN_SCRATCH%"
set "PROBE=%APPDATA%\npm\codex.cmd"
if "%PC_RUNNER_TEST%"=="1" set "PROBE=%CODEX_TEST_AGENT%"
%COMMON% preflight "%O%" "%R%" codex "%PROBE%" %CODEX_MODEL% ""
if errorlevel 1 goto :probefail
rem Progress watch applies only to the agent, never preflight or the runner's own checks.
set "TMO_REPO=%R%"
set "TMO_OUT=%O%"
set "TMO_LOG=%O%\log.txt"
set "TMO_ERR_LOG="
rem CODEX_CAP is a hard ceiling in seconds; STALL_MIN defaults to 30 in the watchdog.
if not defined CODEX_CAP set "CODEX_CAP=21600"
if defined CODEX_TEST_ROOT if defined CODEX_TEST_AGENT goto :testagent
call "%TP%tmo.bat" %CODEX_CAP% "%APPDATA%\npm\codex.cmd" exec -m %CODEX_MODEL% -c model_reasoning_effort=%EFF% --approve-for-me --ephemeral --color never -C "%R%" -o "%O%\last.md" "Read CODEX_TASK.md in this folder and do exactly what it says. Do not commit." > "%O%\log.txt" 2>&1
set "CX=%ERRORLEVEL%"
goto :ran
:testagent
call "%TP%tmo.bat" %CODEX_CAP% "%COMSPEC%" /d /s /c ""%CODEX_TEST_AGENT%"" > "%O%\log.txt" 2>&1
set "CX=%ERRORLEVEL%"
:ran
set "TMO_REPO="
set "TMO_FATAL_PATTERN="
set "TMO_OUT="
set "TMO_LOG="
echo codex exit %CX% >> "%O%\result.txt"
rem Usage limit: leave the issue for the board to retry on a later poll instead of marking it done.
rem Nov 3 fix: look only at the last 40 lines. Codex often prints this script while it works, so a whole-log
rem search matched its own text and threw away three finished jobs (66, 75, 78).
rem A watchdog stop always saves its resume note on -partial, even if the last output mentions a usage limit.
if "%CX%"=="124" goto :publishwork
powershell -NoProfile -Command "if ((Get-Content -LiteralPath '%O%\log.txt' -Tail 40) -match ('hit your usage'+' limit')) { exit 1 }; exit 0"
if errorlevel 1 goto :limit
:publishwork
move /y CODEX_TASK.md "%O%\CODEX_TASK.md" >nul
if "%PC_RUNNER_TEST%"=="1" if "%PC_TEST_STOP_BEFORE_PUBLISH%"=="1" goto :testfinish
rem A run that did not end cleanly is PARTIAL: its own branch, no pull request (issue 377).
set "PB=%BR%"
set "PARTIAL="
if not "%CX%"=="0" set "PARTIAL=codex exit %CX%"
if "%CX%"=="124" if exist "%O%\stop_reason.txt" set /p PARTIAL=<"%O%\stop_reason.txt"
git rev-parse -q --verify MERGE_HEAD > nul 2>&1
if not errorlevel 1 set "PARTIAL=Codex left a merge unfinished"
if defined PARTIAL set "PB=%BR%-partial"
> "%O%\partial.txt" echo.%PARTIAL%
if defined PARTIAL echo PARTIAL RUN, %PARTIAL%: the work goes to %PB%, which opens no pull request >> "%O%\result.txt"
rem Issue 889: copy stamped, linked review pictures and use repo paths in the report.
if not defined PARTIAL (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%TP%review_evidence.ps1" prepare "%R%" "%O%" "docs/shots/issue-%N%-codex" >> "%O%\result.txt" 2>&1
  if errorlevel 1 goto :guardfail
)
git add -A
%PSW% guard %N% codex "%R%" "%O%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :guardfail
git diff --cached --quiet
if errorlevel 1 goto :haschange
if defined PARTIAL goto :haschange
findstr /c:"Resumed by merging" /c:"Base already merged" "%O%\resume.txt" >nul
if errorlevel 1 goto :nochange
:haschange
rem A chain needs green runner checks as well as a confirmed non-partial push.
if defined PARTIAL goto :afterchecks
if "%PC_RUNNER_TEST%"=="1" goto :afterchecks
rem Issue 1739: 3600 s. A serial suite took about 950 s on a quiet PC and over 1,800 s with two lanes checking at once
rem (1801, 1803, Nov 23). No row hung; each row keeps its own 300 or 600 s limit, which is what catches a hang.
call "%TP%tmo.bat" 3600 node contrib\opus\tools\run_all_checks.js > "%O%\checks_node.txt" 2>&1
set "NODE_EXIT=%ERRORLEVEL%"
call "%TP%tmo.bat" 1500 "%COMSPEC%" /c tools\pc\parity.bat nopause > "%O%\checks_parity.txt" 2>&1
set "PARITY_EXIT=%ERRORLEVEL%"
if "%NODE_EXIT%"=="0" if "%PARITY_EXIT%"=="0" set "CHECKS_OK=1"
echo checks: node exit %NODE_EXIT%, parity exit %PARITY_EXIT% >> "%O%\result.txt"
:afterchecks
%PS% msg %N% "%R%" "%O%"
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
%COMMON% finish "%O%" 0 "%PARTIAL%" "%PUSHMODE%" "%CHECKS_OK%" "%R%"
if errorlevel 1 (popd & exit /b 14)
popd
exit /b 0
:pushfail
set /p PRE=<"%O%\pre_commit.txt"
git diff --binary --output="%B%\cx_issue%N%.patch" %PRE% HEAD
echo push failed, patch saved as build_b\cx_issue%N%.patch >> "%O%\result.txt"
%COMMON% finish "%O%" 8 "%PARTIAL%" "%PUSHMODE%" 0
popd
exit /b 8
:testfinish
%COMMON% finish "%O%" 0 "" "%PUSHMODE%" 0
if errorlevel 1 (popd & exit /b 14)
popd
exit /b 0
:stopped
echo push stopped, the runner's check failed with code %SX%: read the lines above >> "%O%\result.txt"
%COMMON% finish "%O%" "%SX%" "%PARTIAL%" "%PUSHMODE%" 0
popd
exit /b %SX%
:guardfail
echo the refuse step failed: nothing committed, nothing pushed >> "%O%\result.txt"
%COMMON% finish "%O%" 13 "%PARTIAL%" "%PUSHMODE%" 0
popd
exit /b 13
:nochange
echo Codex made no changes >> "%O%\result.txt"
%COMMON% finish "%O%" 7 "%PARTIAL%" "%PUSHMODE%" 0
popd
exit /b 7
:prepfail
echo could not read the issue >> "%O%\result.txt"
%COMMON% finish "%O%" 6 "" "%PUSHMODE%" 0
popd
exit /b 6
:probefail
%COMMON% finish "%O%" 14 "" "%PUSHMODE%" 0
popd
exit /b 14
:limit
echo usage limit hit, left on the board to retry >> "%O%\result.txt"
move /y CODEX_TASK.md "%O%\CODEX_TASK.md" >nul
rem Keep whatever Codex got done as a patch before resetting the checkout.
git add -A
git diff --cached --binary > "%O%\limit_wip.patch"
git reset -q
rem Keep the checkout too. The patch and files can be salvaged without deleting anything.
%COMMON% finish "%O%" 9 "usage limit" "%PUSHMODE%" 0
powershell -NoProfile -Command "$f=Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\board\queued.txt'; (Get-Content $f) -ne '%N%' | Set-Content $f"
popd
exit /b 9
