@echo off
rem Workhorse (#217, Opus, Nov 7 2026): one job-board issue, one model, OpenCode headless on Ryan's PC. Nobody watches the run.
rem Usage: work_issue.bat <issue number> <arm: deepseek, deepseekpro or kimi> [dryrun]   (WORK_MODEL overrides the arm's model id)
rem Each run gets its own folder, Downloads\voidsworn_test\work217\issue-<n>-<arm>\<date_time>\, holding repo\ (a fresh clone of
rem main on branch work/issue-<n>-<arm>) and out\ (OpenCode events, the agent's report, run stats, balances, shots).
rem Nothing is deleted anywhere. latest.txt in issue-<n>-<arm>\ names the newest run folder.
rem After the agent finishes, its shots are copied into docs\shots\issue-<n>-<arm>\ so the evidence rides the PR, the change is
rem committed and pushed, and GitHub opens the PR (auto_pr) and runs the checks. If the push fails: out\change.patch.
rem dryrun: a free stand-in model (work\mock_llm.js) instead of the real one, and "git push --dry-run" instead of a push.
rem After the agent stops the runner runs the standing checks and parity itself and pastes their rows into the commit text
rem (#356): each check has its own time limit, a timeout is printed as a timeout, and a failed check never stops the push.
rem Keys: DEEPSEEK_API_KEY and MOONSHOT_API_KEY, saved by work_setup.bat as user settings; read from the registry here, so a
rem window that was open before setup (the watcher) still finds them.
setlocal
set "N=%~1"
set "ARM=%~2"
set "MODE=%~3"
set "MODEL="
if /i "%ARM%"=="deepseek" set "MODEL=deepseek/deepseek-flash"
if /i "%ARM%"=="deepseekpro" set "MODEL=deepseek/deepseek-v4-pro"
if /i "%ARM%"=="kimi" set "MODEL=moonshotai/kimi-k3.1-pro"
if not defined MODEL (echo usage: work_issue.bat issue-number deepseek-deepseekpro-or-kimi [dryrun] & exit /b 2)
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
set "T=%~dp0"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1""
set "OC=%APPDATA%\npm\opencode.cmd"
set "BR=work/issue-%N%-%ARM%"
for /f %%s in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%s"
set "K=issue-%N%-%ARM%"
if /i "%MODE%"=="dryrun" set "K=dryrun-%N%-%ARM%"
set "A=%VT%\work217\%K%\%STAMP%"
set "R=%A%\repo"
set "O=%A%\out"
mkdir "%O%"
echo %A%> "%VT%\work217\%K%\latest.txt"
echo started %date% %time% (%MODE%) > "%O%\result.txt"
echo %MODEL%> "%O%\model.txt"
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
if /i not "%ARM%"=="kimi" if not defined DEEPSEEK_API_KEY (echo no DeepSeek key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & exit /b 3)
if /i "%ARM%"=="kimi" if not defined MOONSHOT_API_KEY (echo no Moonshot key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & exit /b 3)
goto :clone
:drysetup
set "DEEPSEEK_API_KEY=dry"
set "MOONSHOT_API_KEY=dry"
set "OPENCODE_CONFIG=%T%work\opencode_mock.json"
start "workhorse stand-in model" /min "C:\Program Files\nodejs\node.exe" "%T%work\mock_llm.js" 8765 "%O%\mock_log.txt"
rem wait until the stand-in is listening (an earlier one may still hold the port for a few seconds)
powershell -NoProfile -Command "$f='%O%\mock_log.txt'; for($i=0;$i -lt 90;$i++){ if((Test-Path $f) -and (Select-String -Quiet -Path $f -Pattern 'listening')){exit 0}; Start-Sleep 1 }; exit 1"

:clone
git clone -q -c core.autocrlf=false --depth 1 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
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
rem give the provider a minute to book the charge before reading the balance again
if /i not "%MODE%"=="dryrun" timeout /t 60 /nobreak > nul
if /i "%MODE%"=="dryrun" (echo dry> "%O%\balance_after.txt") else (%PS% balance %ARM% "%O%\balance_after.txt" > nul)
%PS% stats %N% %ARM% "%O%" > nul
move /y WORK_TASK.md "%O%\WORK_TASK.md" > nul
if exist "%O%\shots\*.png" (
  if not exist "docs\shots\issue-%N%-%ARM%" mkdir "docs\shots\issue-%N%-%ARM%"
  copy /y "%O%\shots\*.png" "docs\shots\issue-%N%-%ARM%\" > nul
)
git add -A
git diff --cached --quiet
if not errorlevel 1 goto :nochange
git diff --cached --stat > "%O%\diffstat.txt"
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
%PS% msg %N% %ARM% "%O%"
git -c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com" commit -q -F "%O%\commit.txt"
if /i "%MODE%"=="dryrun" (git push --dry-run origin %BR% > "%O%\push.txt" 2>&1) else (git push -q -f origin %BR% > "%O%\push.txt" 2>&1)
if errorlevel 1 goto :pushfail
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_pushed.txt"
%PS% stats %N% %ARM% "%O%" > nul
if /i "%MODE%"=="dryrun" (echo dry run: push to %BR% would work, nothing pushed >> "%O%\result.txt") else (echo pushed %BR% >> "%O%\result.txt")
popd
exit /b 0

:getkey
for /f "tokens=2,*" %%a in ('reg query HKCU\Environment /v %1 2^>nul ^| findstr /c:"REG_"') do set "%1=%%b"
exit /b 0
:pushfail
git format-patch -1 --stdout > "%O%\change.patch"
echo push failed, change saved as out\change.patch >> "%O%\result.txt"
popd
exit /b 8
:nochange
echo the agent made no changes >> "%O%\result.txt"
popd
exit /b 7
:prepfail
echo could not read the issue from GitHub >> "%O%\result.txt"
popd
exit /b 6
