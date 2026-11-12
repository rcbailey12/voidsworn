@echo off
rem Workhorse (#217, Opus, Nov 7 2026): one job-board issue, one model, OpenCode headless on Ryan's PC. Nobody watches the run.
rem Usage: work_issue.bat <issue number> <arm: deepseek, deepseekpro, kimi or kimicode> [dryrun]   (WORK_MODEL overrides the arm's model id)
rem Each run gets its own folder, Downloads\voidsworn_test\work217\issue-<n>-<arm>\<date_time>\, holding repo\ (a fresh clone of
rem main on branch work/issue-<n>-<arm>) and out\ (OpenCode events, the agent's report, run stats, balances, shots).
rem latest.txt in issue-<n>-<arm>\ names the newest run folder.
rem After the agent finishes, its shots are copied into docs\shots\issue-<n>-<arm>\ so the evidence rides the PR, the change is
rem committed and pushed, and GitHub opens the PR (auto_pr) and runs the checks. If the push fails: out\change.patch.
rem dryrun: a free stand-in model (work\mock_llm.js) instead of the real one, and "git push --dry-run" instead of a push.
rem After the agent stops the runner runs the standing checks and parity itself and pastes their rows into the commit text
rem (#356): each check has its own time limit, a timeout is printed as a timeout, and a failed check never stops the push.
rem Keys: DEEPSEEK_API_KEY and MOONSHOT_API_KEY, saved by work_setup.bat as user settings; read from the registry here, so a
rem window that was open before setup (the watcher) still finds them.
rem
rem Runner 2 (issue 377, Opus, Nov 12 2026):
rem  (a) An agent exit code that is not 0 (the time cap gives 124), or a merge the agent left unfinished, makes a PARTIAL run:
rem      it pushes to work/issue-<n>-<arm>-partial, which opens no pull request (tools/pc/issue-377-auto_pr.patch), and skips
rem      the runner checks.
rem  (b) After git add -A the guard step (work_issue.ps1 guard) refuses files over WORK_MAX_FILE_MB (default 8), anything
rem      under godot/gen, godot/.godot or godot/assets/ships/<hull>/ (previews and test stay allowed), new .uid files and new
rem      or re-saved .import files. Refused files are unstaged, copied to out\runs\<date_time>\refused\ (never deleted) and listed in
rem      result.txt and the PR text. Changed files outside the issue's Deliver to line are listed as a warning.
rem  (c) No force push. The run's one commit is made with git's plumbing and checked; when the branch already exists its
rem      earlier tip becomes the commit's second parent, so a rerun is a plain fast-forward push and the earlier run's
rem      commit stays reachable. Commit text ends with "Run-Number: k".
rem  (541) Before the push the commit must carry exactly the staged change (out\diffstat.txt); after the push GitHub's branch
rem      must be that commit with that diff (out\pushed_diffstat.txt). Any difference stops the run loudly: DIFF MISMATCH
rem      in result.txt, out\DIFF_MISMATCH.txt, exit code 10.
rem  (disk) Every run ends with its folder size in result.txt. Only when work217\runner_settings.txt says
rem      remove_repo_copy_after_push=yes (off by default; Ryan turns it on once with WORKHORSE_CLEANUP.bat) does a run whose
rem      push was checked remove its own repo\ copy; out\ is always kept. A dry run never removes anything.
rem Dry-run test knobs (ignored unless the third argument is dryrun): WORK_DRY_SCENARIO picks the stand-in model's script;
rem WORK_TEST_BRANCH pushes for real to that branch (it must not start with codex/, muse/, work/ or opus/, so no PR opens);
rem WORK_SKIP_CHECKS=1 skips the runner checks; WORK_DRY_SPARSE lists the only folders a lean test clone checks out;
rem WORK_TEST_FAULT=skipcommit leaves the change uncommitted, as the issue 541 run did. WORK_ROOT moves the run folders.
setlocal
set "N=%~1"
set "ARM=%~2"
set "MODE=%~3"
set "MODEL="
if /i "%ARM%"=="deepseek" set "MODEL=deepseek/deepseek-flash"
if /i "%ARM%"=="deepseekpro" set "MODEL=deepseek/deepseek-v4-pro"
if /i "%ARM%"=="kimi" set "MODEL=moonshotai/kimi-k3.1-pro"
rem kimicode: the Kimi Code plan (Ryan, Nov 12, issue 597); its key only works on api.kimi.com/coding/v1 (work\opencode.json)
if /i "%ARM%"=="kimicode" set "MODEL=kimicode/k3.1-pro"
if not defined MODEL (echo usage: work_issue.bat issue-number deepseek-deepseekpro-kimi-or-kimicode [dryrun] & exit /b 2)
if defined WORK_MODEL set "MODEL=%WORK_MODEL%"
rem The repo's bundled Node 22 first: the shell's Node 24 gives a false 4,048 pow differences in the parity math sweep (#217 trial)
set "PATH=%USERPROFILE%\Downloads\voidsworn_test\node;C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
rem The same bundled Node 22 for the runner's own check step (a quoted full path survives the time-limit wrapper)
set "NODE=node"
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
rem WORK_CAP: the run's cap in seconds (default one hour; set it before calling for a bigger job)
if not defined WORK_CAP set "WORK_CAP=3600"
rem CHECK_CAP and PARITY_CAP: each runner check gets its own time limit (#356). A check that hangs is killed and its
rem timeout is written into the commit text instead of eating the run.
if not defined CHECK_CAP set "CHECK_CAP=900"
if not defined PARITY_CAP set "PARITY_CAP=1500"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if not defined WORK_ROOT set "WORK_ROOT=%VT%\work217"
set "T=%~dp0"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1""
set "OC=%APPDATA%\npm\opencode.cmd"
set "BR=work/issue-%N%-%ARM%"
rem How the run ends: real pushes to GitHub; dry is "git push --dry-run"; test pushes for real to WORK_TEST_BRANCH.
set "PUSHMODE=real"
set "DRY=0"
if /i "%MODE%"=="dryrun" set "PUSHMODE=dry"
if /i "%MODE%"=="dryrun" set "DRY=1"
if /i not "%MODE%"=="dryrun" goto :branchset
if not defined WORK_TEST_BRANCH goto :branchset
echo %WORK_TEST_BRANCH%| findstr /r /i /c:"^codex/" /c:"^muse/" /c:"^work/" /c:"^opus/" > nul
if not errorlevel 1 (echo WORK_TEST_BRANCH must not start with codex/, muse/, work/ or opus/: those open pull requests & exit /b 2)
set "BR=%WORK_TEST_BRANCH%"
set "PUSHMODE=test"
:branchset
rem The run's commit carries Ryan's git identity, as before.
set "GIT_AUTHOR_NAME=Ryan Bailey"
set "GIT_AUTHOR_EMAIL=rcbailey12@gmail.com"
set "GIT_COMMITTER_NAME=Ryan Bailey"
set "GIT_COMMITTER_EMAIL=rcbailey12@gmail.com"
for /f %%s in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%s"
set "K=issue-%N%-%ARM%"
if /i "%MODE%"=="dryrun" set "K=dryrun-%N%-%ARM%"
set "A=%WORK_ROOT%\%K%\%STAMP%"
set "R=%A%\repo"
set "O=%A%\out"
set "RC=0"
set "OK=0"
mkdir "%O%"
echo %A%> "%WORK_ROOT%\%K%\latest.txt"
echo started %date% %time% (%MODE%) > "%O%\result.txt"
echo %MODEL%> "%O%\model.txt"
rem Ryan's one cleanup switch (issue 377). The runner only creates the file, with the setting off, and then only reads it.
set "SETF=%WORK_ROOT%\runner_settings.txt"
if not exist "%SETF%" call :settings
if not exist "%OC%" (echo OpenCode is not installed: run WORKHORSE_SETUP.bat first >> "%O%\result.txt" & exit /b 3)
rem parity.bat in a repo checkout reads godot_path.txt one folder above the repo
copy /y "%VT%\godot_path.txt" "%A%\godot_path.txt" >nul
set /p G=<"%VT%\godot_path.txt"

rem OpenCode takes its shell from SHELL (on Windows it otherwise falls back to PowerShell 5.1, where the usual shell commands fail)
set "SHELL=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_DISABLE_AUTOUPDATE=1"
set "OPENCODE_DISABLE_MODELS_FETCH=1"
rem one shell command may run 30 minutes (parity takes several; the default is 2 minutes)
set "OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS=1800000"
set "OPENCODE_CONFIG=%T%work\opencode.json"
if /i "%MODE%"=="dryrun" goto :drysetup
call :getkey DEEPSEEK_API_KEY
call :getkey MOONSHOT_API_KEY
call :getkey KIMI_CODE_API_KEY
if /i "%ARM%"=="kimicode" if not defined KIMI_CODE_API_KEY (echo no Kimi Code key saved: run KIMI_CODE_KEY.bat >> "%O%\result.txt" & exit /b 3)
if /i "%ARM%"=="kimicode" goto :clone
if /i not "%ARM%"=="kimi" if not defined DEEPSEEK_API_KEY (echo no DeepSeek key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & exit /b 3)
if /i "%ARM%"=="kimi" if not defined MOONSHOT_API_KEY (echo no Moonshot key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & exit /b 3)
goto :clone
:drysetup
set "DEEPSEEK_API_KEY=dry"
set "MOONSHOT_API_KEY=dry"
set "KIMI_CODE_API_KEY=dry"
set "OPENCODE_CONFIG=%T%work\opencode_mock.json"
start "workhorse stand-in model" /min "C:\Program Files\nodejs\node.exe" "%T%work\mock_llm.js" 8765 "%O%\mock_log.txt" %WORK_DRY_SCENARIO%
rem wait until the stand-in is listening (an earlier one may still hold the port for a few seconds)
powershell -NoProfile -Command "$f='%O%\mock_log.txt'; for($i=0;$i -lt 300;$i++){ if((Test-Path $f) -and (Select-String -Quiet -Path $f -Pattern 'listening')){exit 0}; Start-Sleep 1 }; exit 1"

:clone
if /i "%MODE%"=="dryrun" if defined WORK_DRY_SPARSE goto :leanclone
git clone -q -c core.autocrlf=false --depth 1 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
goto :cloned
:leanclone
rem Dry runs only: a blobless clone that checks out the named folders, so a test run keeps the PC folder lean.
git clone -q -c core.autocrlf=false --depth 1 --filter=blob:none --sparse https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
if exist "%R%\.git" git -C "%R%" sparse-checkout add %WORK_DRY_SPARSE% >> "%O%\git_log.txt" 2>&1
:cloned
if not exist "%R%\.git" (echo clone failed >> "%O%\result.txt" & exit /b 4)
pushd "%R%"
git checkout -q -B %BR%
git log -1 --format=%%H > "%O%\base_commit.txt"
%PS% prep %N% %ARM% "%R%" "%O%" "%G%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :prepfail
rem Only capture jobs copy the ship files: the launcher sets WORK_SHIPS=1. They are large and every run keeps its checkout (Board, Nov 10).
if defined WORK_SHIPS call "%T%get_ship_files.bat" "%VT%\build\godot" "%R%" "%R%\WORK_TASK.md" >> "%O%\ship_files.txt" 2>&1
if /i "%MODE%"=="dryrun" (echo dry> "%O%\balance_before.txt") else (%PS% balance %ARM% "%O%\balance_before.txt" > nul)
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_start.txt"
echo agent running %time% >> "%O%\result.txt"
call "%T%tmo.bat" %WORK_CAP% "%OC%" run --auto --format json -m %MODEL% --dir "%R%" "Read WORK_TASK.md in this folder and do exactly what it says. Do not commit and do not push." > "%O%\events.jsonl" 2> "%O%\stderr.txt"
> "%O%\exit.txt" echo %ERRORLEVEL%
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_agent_end.txt"
set /p OCX=<"%O%\exit.txt"
echo opencode exit %OCX% at %time% >> "%O%\result.txt"
rem (a) A run that did not end cleanly is PARTIAL: its own branch, no pull request (issue 377).
set "PB=%BR%"
set "PARTIAL="
if not "%OCX%"=="0" set "PARTIAL=agent exit %OCX%"
if "%OCX%"=="124" set "PARTIAL=stopped at the time cap of %WORK_CAP% s"
git rev-parse -q --verify MERGE_HEAD > nul 2>&1
if not errorlevel 1 set "PARTIAL=the agent left a merge unfinished"
if defined PARTIAL set "PB=%BR%-partial"
> "%O%\partial.txt" echo.%PARTIAL%
if defined PARTIAL echo PARTIAL RUN, %PARTIAL%: the work goes to %PB%, which opens no pull request >> "%O%\result.txt"
rem give the provider a minute to book the charge before reading the balance again
if /i not "%MODE%"=="dryrun" timeout /t 60 /nobreak > nul
if /i "%MODE%"=="dryrun" (echo dry> "%O%\balance_after.txt") else (%PS% balance %ARM% "%O%\balance_after.txt" > nul)
%PS% stats %N% %ARM% "%O%" > nul
move /y WORK_TASK.md "%O%\WORK_TASK.md" > nul
if exist "%O%\shots\*.png" (
  if not exist "docs\shots\issue-%N%-%ARM%" mkdir "docs\shots\issue-%N%-%ARM%"
  copy /y "%O%\shots\*.png" "docs\shots\issue-%N%-%ARM%\" > nul
)
rem #357 / R144: a capture run can re-save tracked .import files; restore them before the commit.
for /f "usebackq delims=" %%F in (`git ls-files "*.import"`) do git checkout -q -- "%%F"
git add -A
rem (b) The refuse list and the Deliver to warning (issue 377).
%PS% guard %N% %ARM% "%R%" "%O%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :guardfail
git diff --cached --quiet
if not errorlevel 1 goto :nochange
git diff --cached --stat > "%O%\diffstat.txt"
if defined PARTIAL (> "%O%\checks.txt" echo runner checks skipped: partial run & goto :afterchecks)
if /i "%MODE%"=="dryrun" if "%WORK_SKIP_CHECKS%"=="1" (> "%O%\checks.txt" echo runner checks skipped: dry run with WORK_SKIP_CHECKS=1 & goto :afterchecks)
rem Runner checks (#356): after the agent stops, run the checks ourselves and keep their rows for the commit text.
rem Each check has its own time limit through tmo.bat. A timeout is written as a timeout, and a failed check never
rem stops the push: the FAIL rows ride in the text and every byte of the run is kept.
call "%T%tmo.bat" %CHECK_CAP% "%NODE%" contrib\opus\tools\run_all_checks.js > "%O%\checks_node.txt" 2>&1
set "NODE_EXIT=%ERRORLEVEL%"
call "%T%tmo.bat" %PARITY_CAP% "%COMSPEC%" /c tools\pc\parity.bat nopause > "%O%\checks_parity.txt" 2>&1
set "PARITY_EXIT=%ERRORLEVEL%"
> "%O%\checks.txt" echo ## node contrib/opus/tools/run_all_checks.js ^(limit %CHECK_CAP% s^)
if "%NODE_EXIT%"=="124" (echo TIMEOUT: node contrib/opus/tools/run_all_checks.js hit its %CHECK_CAP% s limit >> "%O%\checks.txt") else (echo exit %NODE_EXIT% >> "%O%\checks.txt")
type "%O%\checks_node.txt" >> "%O%\checks.txt"
>> "%O%\checks.txt" echo.
>> "%O%\checks.txt" echo ## tools\pc\parity.bat nopause ^(limit %PARITY_CAP% s^)
if "%PARITY_EXIT%"=="124" (echo TIMEOUT: tools\pc\parity.bat nopause hit its %PARITY_CAP% s limit >> "%O%\checks.txt") else (echo exit %PARITY_EXIT% >> "%O%\checks.txt")
type "%O%\checks_parity.txt" >> "%O%\checks.txt"
echo checks: node exit %NODE_EXIT%, parity exit %PARITY_EXIT% at %time% >> "%O%\result.txt"
:afterchecks
%PS% msg %N% %ARM% "%O%"
rem (c) and the issue 541 check: one checked commit that keeps the branch's earlier tip, then a push with no force.
%PS% commit "%R%" "%O%" %PB% %PUSHMODE% >> "%O%\result.txt" 2>&1
set "SX=%ERRORLEVEL%"
if "%SX%"=="7" goto :nochange
if not "%SX%"=="0" goto :stopped
if "%PUSHMODE%"=="dry" (git push --dry-run origin HEAD:refs/heads/%PB% > "%O%\push.txt" 2>&1) else (git push origin HEAD:refs/heads/%PB% > "%O%\push.txt" 2>&1)
if errorlevel 1 goto :pushfail
%PS% confirm "%R%" "%O%" %PB% %PUSHMODE% >> "%O%\result.txt" 2>&1
set "SX=%ERRORLEVEL%"
if not "%SX%"=="0" goto :stopped
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_pushed.txt"
%PS% stats %N% %ARM% "%O%" > nul
if "%PUSHMODE%"=="dry" (echo dry run: push to %PB% would work, nothing pushed >> "%O%\result.txt") else (echo pushed %PB% >> "%O%\result.txt")
set "OK=1"
goto :finish

:getkey
for /f "tokens=2,*" %%a in ('reg query HKCU\Environment /v %1 2^>nul ^| findstr /c:"REG_"') do set "%1=%%b"
exit /b 0
:settings
> "%SETF%" echo # Workhorse runner settings (issue 377). The runner only reads this file; Ryan changes it with WORKHORSE_CLEANUP.bat.
>> "%SETF%" echo # remove_repo_copy_after_push=yes: after a push the runner has checked, it removes that run's repo copy and keeps out.
>> "%SETF%" echo remove_repo_copy_after_push=no
exit /b 0
:pushfail
set /p PRE=<"%O%\pre_commit.txt"
git diff --binary --output="%O%\change.patch" %PRE% HEAD
echo push failed, change saved as out\change.patch >> "%O%\result.txt"
set "RC=8"
goto :finish
:stopped
echo push stopped, the runner's check failed with code %SX%: read the lines above; nothing was merged >> "%O%\result.txt"
set "RC=%SX%"
goto :finish
:guardfail
echo the refuse step failed: nothing committed, nothing pushed >> "%O%\result.txt"
set "RC=13"
goto :finish
:nochange
echo the agent made no changes >> "%O%\result.txt"
set "RC=7"
goto :finish
:prepfail
echo could not read the issue from GitHub >> "%O%\result.txt"
set "RC=6"
goto :finish
:finish
popd
rem (disk) The run folder's size, and the repo copy removed only when Ryan's setting allows it and the push was checked.
%PS% tidy "%A%" "%WORK_ROOT%" "%SETF%" %OK% %DRY% >> "%O%\result.txt" 2>&1
exit /b %RC%
