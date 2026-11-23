@echo off
rem Workhorse (#217, Opus, Nov 7 2026): one job-board issue, one model, OpenCode headless on Ryan's PC. Nobody watches the run.
rem Usage: work_issue.bat <issue number> <arm: deepseek, deepseekpro, kimi, kimicode, sonnet, opus or openai> [dryrun]
rem WORK_MODEL overrides an OpenCode model within its provider. kimicode uses Kimi CLI and WORK_KIMI_MODEL.
rem PC_WAIT_FOR names the predecessor's status.json; only a checked non-partial push with passing checks releases it.
rem Each arm shares work217\slot_<arm>\repo, with one run owning the slot at a time.
rem Each run keeps its own work217\issue-<n>-<arm>\<date_time>\out\ (events, report, stats, balances, shots).
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
rem  (a) An agent exit code that is not 0 (stall or ceiling gives 124), or a merge the agent left unfinished, makes a PARTIAL run:
rem      it pushes to work/issue-<n>-<arm>-partial, which opens no pull request (tools/pc/issue-377-auto_pr.patch), and skips
rem      the runner checks.
rem  (b) After git add -A the guard step (work_issue.ps1 guard) refuses files over WORK_MAX_FILE_MB (default 8), anything
rem      under godot/gen, godot/.godot or godot/assets/ships/<hull>/ (previews and test stay allowed), new .uid files and new
rem      or re-saved .import files. Refused files are unstaged, copied to out\runs\<date_time>\refused\ (never deleted) and listed in
rem      result.txt and the PR text. Changed files outside the issue's Deliver to line are listed as a warning.
rem  (c) No force push. The run's one commit is made with git's plumbing and checked; when the branch already exists the
rem      run starts from its earlier tip with main merged in (issue 1739), so a rerun is a plain fast-forward push that keeps
rem      the earlier runs' files, and a run that does not descend from that tip stops with exit 15 before the push.
rem      Commit text ends with "Run-Number: k".
rem  (541) Before the push the commit must carry exactly the staged change (out\diffstat.txt); after the push GitHub's branch
rem      must be that commit with that diff (out\pushed_diffstat.txt). Any difference stops the run loudly: DIFF MISMATCH
rem      in result.txt, out\DIFF_MISMATCH.txt, exit code 10.
rem  (disk) Report run folder and shared checkout sizes separately in result.txt. Keep the slot after a push for reuse.
rem Runner 3 (issue 722, Nov 15 2026; Muse audit 706 findings 6 and 7):
rem  (model) Every run stamps the resolved model id into out\status.json and result.txt, and result.txt warns when it
rem      differs from the arm's default, whatever the provider: a same-provider WORK_MODEL override (invisible to the
rem      provider guard above) warns here. The kimicode arm stamps the Kimi Code CLI model.
rem  (space) Before anything else the run refuses to start (one line in result.txt, status failed) when the drive
rem      holding Downloads\voidsworn_test has less than min_free_gb free; the floor is a tuning value in
rem      work217\runner_settings.txt, seeded at 60 when the runner creates the file.
rem  (hashes) At start the runner compares the SHA-256 of its own tools folder's work_issue.bat, work_issue.ps1,
rem      codex_issue.bat, codex_issue.ps1, runner_common.ps1, run_timeout.ps1, tmo.bat and gpu_slots.js against work217\runner_hashes.txt, which the Board
rem      writes (runner_common.ps1 hashwrite) when it copies the files to the PC. A mismatch or a missing file is a
rem      warning in result.txt, never a stop.
rem Dry-run test knobs (ignored unless the third argument is dryrun): WORK_DRY_SCENARIO picks the stand-in model's script;
rem WORK_TEST_BRANCH pushes for real to that branch (it must not start with codex/, muse/, work/ or opus/, so no PR opens);
rem WORK_SKIP_CHECKS=1 skips the runner checks; WORK_DRY_SPARSE lists the only folders a lean test clone checks out;
rem WORK_TEST_FAULT=skipcommit leaves the change uncommitted, as the issue 541 run did. WORK_ROOT moves the run folders and slots.
setlocal
set "PYTHONDONTWRITEBYTECODE=1"
set "N=%~1"
set "ARM=%~2"
set "MODE=%~3"
set "MODEL="
if /i "%ARM%"=="deepseek" set "MODEL=deepseek/deepseek-flash"
if /i "%ARM%"=="deepseekpro" set "MODEL=deepseek/deepseek-v4-pro"
if /i "%ARM%"=="kimi" set "MODEL=moonshotai/kimi-k3.1-pro"
rem kimicode: the Kimi Code plan (Ryan, Nov 12, issue 597); its key only works on api.kimi.com/coding/v1 (work\opencode.json)
if /i "%ARM%"=="kimicode" set "MODEL=kimicode/k3.1-pro"
rem sonnet: Claude Sonnet 5.5 on the Max plan's monthly API credits (Ryan, Nov 12, issue 614); key VOIDSWORN_CLAUDE_API_KEY, never ANTHROPIC_API_KEY, which would switch Ryan's own Claude Code to API billing
if /i "%ARM%"=="sonnet" set "MODEL=anthropic/claude-sonnet-5-5"
rem opus: Claude Opus 5.5 on the same credits (Ryan, Nov 12 16:15: "why not use it as another opus worker")
if /i "%ARM%"=="opus" set "MODEL=anthropic/claude-opus-5-5"
if /i "%ARM%"=="openai" set "MODEL=openai/gpt-6.2-sol"
if not defined MODEL (echo usage: work_issue.bat issue-number deepseek-deepseekpro-kimi-kimicode-sonnet-opus-or-openai [dryrun] & exit /b 2)
for %%A in (deepseek deepseekpro kimi kimicode sonnet opus openai) do if /i "%ARM%"=="%%A" set "ARM=%%A"
rem The arm default, captured before WORK_MODEL below: issue 722 stamps the resolved model and warns when it differs.
set "DEFAULT_MODEL=%MODEL%"
rem WORK_MODEL overrides the model only within the arm's own provider (Board, Nov 13: a q_ file set WORK_MODEL=kimicode/k3 in the
rem queue watcher's window, and three later opus-arm runs ran on Kimi and stopped on its quota); one from another provider is ignored
if defined WORK_MODEL for /f "tokens=1 delims=/" %%P in ("%MODEL%") do for /f "tokens=1 delims=/" %%Q in ("%WORK_MODEL%") do if /i "%%P"=="%%Q" (set "MODEL=%WORK_MODEL%") else (echo WORK_MODEL %WORK_MODEL% ignored: arm %ARM% runs on %%P)
rem OpenAI defaults to high. Legacy kimicode OpenCode dry runs keep the issue 656 variants.
rem Other arms ignore WORK_EFFORT so a setting left in the queue watcher's window cannot change them.
set "EFFORT="
set "EFFORT_LEVELS="
if /i "%ARM%"=="kimicode" set "EFFORT_LEVELS=low high max"
if /i "%ARM%"=="openai" set "EFFORT_LEVELS=low medium high max"
if not defined WORK_EFFORT goto :effortset
if not defined EFFORT_LEVELS (echo WORK_EFFORT ignored: only openai and legacy kimicode take an effort & goto :effortset)
rem OpenCode variant names are case sensitive. Stamp and pass the same lowercase value.
for %%L in (%EFFORT_LEVELS%) do if /i "%WORK_EFFORT%"=="%%L" set "EFFORT=%%L"
if not defined EFFORT echo WORK_EFFORT ignored: use one of %EFFORT_LEVELS%
:effortset
if /i "%ARM%"=="openai" if not defined EFFORT set "EFFORT=high"
set "VARIANT="
if defined EFFORT set "VARIANT=--variant %EFFORT%"
rem The repo's bundled Node 22 first: the shell's Node 24 gives a false 4,048 pow differences in the parity math sweep (#217 trial)
set "PATH=%USERPROFILE%\Downloads\voidsworn_test\node;C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
rem The same bundled Node 22 for the runner's own check step (a quoted full path survives the time-limit wrapper)
set "NODE=node"
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
rem WORK_CAP: hard ceiling in seconds (default six hours). STALL_MIN defaults to 30 in the watchdog.
if not defined WORK_CAP set "WORK_CAP=21600"
rem CHECK_CAP and PARITY_CAP: each runner check gets its own time limit (#356). A check that hangs is killed and its
rem timeout is written into the commit text instead of eating the run.
rem Issue 1739: the node suite cap is 3600 s; a loaded PC ran it past 1800 s with no row hung (1801, 1803).
if not defined CHECK_CAP set "CHECK_CAP=3600"
if not defined PARITY_CAP set "PARITY_CAP=1500"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "SLOT_ROOT=%WORK_ROOT%"
if not defined SLOT_ROOT set "SLOT_ROOT=%VT%\work217"
rem A manual dry run with the default root must not switch a live slot.
if not defined WORK_ROOT if /i "%MODE%"=="dryrun" set "SLOT_ROOT=%SLOT_ROOT%\dryrun_slots"
set "SLOT=%SLOT_ROOT%\slot_%ARM%"
set "R=%SLOT%\repo"
if not defined WORK_ROOT set "WORK_ROOT=%VT%\work217"
set "T=%~dp0"
rem %TC% is %T% without its trailing backslash, for passing the tools folder as a bare quoted argument (issue 722:
rem cmd merges "%T%" with the next quoted argument because of the backslash before the quote).
set "TC=%T:~0,-1%"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1""
set "COMMON=powershell -NoProfile -ExecutionPolicy Bypass -File "%T%runner_common.ps1""
set "PC_RUNNER_TEST=0"
if /i "%MODE%"=="dryrun" if defined WORK_TEST_AGENT set "PC_RUNNER_TEST=1"
rem Issue 1186: work_issue.ps1 run holds the arm's slot lock and the issue lock, and the whole process tree of this
rem batch inherits both, so they stay held through checkout, the agent and final reporting.
if "%~4"=="locked" if "%PC_RUNNER_LOCKED_ISSUE%"=="%N%" if /i "%WORK_LOCKED_REPO%"=="%R%" goto :locked
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1" run "%N%" "%ARM%" "%MODE%" "%R%"
exit /b %ERRORLEVEL%
:locked
rem Kimi Code runs on its own CLI and saved plan login, never an API key.
if /i "%ARM%"=="kimicode" set "WORK_HARNESS=kimi"
rem (722) What will actually run: the Kimi Code CLI model for the kimicode arm whenever the real CLI or its test
rem stand-in runs (live, or dryrun in test mode); otherwise the OpenCode model. DEFAULT_MODEL stays the arm's
rem built-in choice, so WORK_KIMI_MODEL or a same-provider WORK_MODEL shows as a warning through runner_common.
set "KMODEL=kimi-code/kimi-for-coding"
if defined WORK_KIMI_MODEL set "KMODEL=%WORK_KIMI_MODEL%"
set "RESOLVED=%MODEL%"
if /i "%ARM%"=="kimicode" if /i not "%MODE%"=="dryrun" set "KHARNESS=1"
if /i "%ARM%"=="kimicode" if "%PC_RUNNER_TEST%"=="1" set "KHARNESS=1"
if defined KHARNESS set "RESOLVED=%KMODEL%"
if defined KHARNESS set "DEFAULT_MODEL=kimi-code/kimi-for-coding"
set "OC=%APPDATA%\npm\opencode.cmd"
if "%PC_RUNNER_TEST%"=="1" if /i "%ARM%"=="openai" set "OC=%WORK_TEST_AGENT%"
set "ASSIGNED_BRANCH=work/issue-%N%-%ARM%"
set "BR=%ASSIGNED_BRANCH%"
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
set "K=issue-%N%-%ARM%"
if /i "%MODE%"=="dryrun" set "K=dryrun-%N%-%ARM%"
:runfolder
set "STAMP="
for /f %%s in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%s"
if not defined STAMP (echo could not name the run folder & exit /b 14)
set "A=%WORK_ROOT%\%K%\%STAMP%"
if exist "%A%" goto :runfolder
set "O=%A%\out"
set "RC=0"
set "CHECKS_OK=0"
rem R276: all nested GPU launchers inherit the issue and the code-only lane.
set "PC_GPU_ISSUE=%N%"
if not defined PC_GPU_WAIT_SECONDS set "PC_GPU_WAIT_SECONDS=1500"
set "PC_GPU_LANE="
echo %R%| findstr /i /c:"board_c" >nul
if not errorlevel 1 set "PC_GPU_LANE=C"
echo %R%| findstr /i /c:"board_d" >nul
if not errorlevel 1 set "PC_GPU_LANE=D"
mkdir "%O%"
echo %A%> "%WORK_ROOT%\%K%\latest.txt"
echo started %date% %time% (%MODE%) > "%O%\result.txt"
rem Ryan's runner switches (issue 377, issue 722). The runner only creates these files, with safe defaults, and then only reads them.
set "SETF=%WORK_ROOT%\runner_settings.txt"
set "HASHF=%WORK_ROOT%\runner_hashes.txt"
if not exist "%SETF%" call :settings
%COMMON% init "%O%" "%BR%"
if errorlevel 1 exit /b 14
rem (722) Nothing runs below the free-space floor: no mirror fetch, no model probe, no agent.
%COMMON% space "%O%" "%SETF%" "%VT%" "%PUSHMODE%"
if errorlevel 1 exit /b 14
rem (722) The Board's hashes guard the running copies; a mismatch warns and the run goes on (%TC% is set above).
%COMMON% hashcheck "%O%" "%TC%" "%HASHF%"
rem (1194) Every tmo.bat step runs the canonical watchdog in tools_live: stop when its files differ from its hashes.
set "TLV="
if not "%PC_RUNNER_TEST%"=="1" if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not "%PC_RUNNER_TEST%"=="1" if exist "%VT%\tools_live\" if not defined TLV (echo tools_live is installed but current.txt is blank; stopped >> "%O%\result.txt" & exit /b 14)
if defined TLV (
  %COMMON% hashcheck "%O%" "%VT%\tools_live\%TLV%\pc" "%VT%\tools_live\%TLV%\hashes.txt" strict
  if errorlevel 1 exit /b 14
)
rem (722) Stamp the resolved model before the wait so every later state of the run names it.
%COMMON% model "%O%" "%RESOLVED%" "%DEFAULT_MODEL%"
if /i "%ARM%"=="openai" (
  %COMMON% effort "%O%" "%EFFORT%"
  if errorlevel 1 goto :setupfail
  echo %MODEL% %VARIANT%> "%O%\model.txt"
)
%COMMON% wait "%O%"
if errorlevel 1 exit /b 14
rem Refuse unpriced models and spent budgets before checkout or any paid probe. Dry runs never touch the ledger.
if /i "%ARM%"=="openai" (
  %PS% openai-budget "%O%" "%WORK_ROOT%" "%SETF%" "%RESOLVED%" "%DRY%"
  if errorlevel 1 goto :setupfail
)
rem Every work arm, including Kimi, validates and claims before tools, checkout or model calls (issue 888).
%COMMON% announce "%O%" "%N%" "%ARM%" "%R%" "%WORK_CAP%" "work_issue.bat %N% %ARM%" "%PUSHMODE%" "%ASSIGNED_BRANCH%"
if errorlevel 1 exit /b 14
if /i not "%ARM%"=="openai" (
  if defined VARIANT (echo %MODEL% %VARIANT%> "%O%\model.txt") else (echo %MODEL%> "%O%\model.txt")
)
if "%PC_RUNNER_TEST%"=="1" goto :toolsready
if /i "%ARM%"=="kimicode" goto :toolsready
if not exist "%OC%" (echo OpenCode is not installed: run WORKHORSE_SETUP.bat first >> "%O%\result.txt" & goto :setupfail)
:toolsready
rem Keep Godot discovery working when WORK_ROOT is outside the PC bundle.
copy /y "%VT%\godot_path.txt" "%SLOT%\godot_path.txt" >nul
set /p G=<"%VT%\godot_path.txt"

rem OpenCode takes its shell from SHELL (on Windows it otherwise falls back to PowerShell 5.1, where the usual shell commands fail)
set "SHELL=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_DISABLE_AUTOUPDATE=1"
set "OPENCODE_DISABLE_MODELS_FETCH=1"
rem Keep OpenCode's bundled ChatGPT OAuth plugin from replacing this arm's explicit API key and endpoint.
if /i "%ARM%"=="openai" set "OPENCODE_DISABLE_DEFAULT_PLUGINS=1"
rem one shell command may run 30 minutes (parity takes several; the default is 2 minutes)
set "OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS=1800000"
set "OPENCODE_CONFIG=%T%work\opencode.json"
rem kimicode: its own config with no helper agents (issue 597: five parallel helpers spent the plan's 5-hour window in 9 minutes); sonnet uses it too, to keep API credit spend linear
if /i "%ARM%"=="kimicode" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
if /i "%ARM%"=="sonnet" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
if /i "%ARM%"=="openai" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
if /i "%ARM%"=="opus" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
rem deepseek arms too (Ryan, Nov 12: "$20 at DeepSeek API in like a week ... not super sustainable"): one agent, no helpers
if /i "%ARM%"=="deepseek" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
if /i "%ARM%"=="deepseekpro" set "OPENCODE_CONFIG=%T%work\opencode_lean.json"
if /i "%MODE%"=="dryrun" goto :drysetup
rem OpenAI reads only this user setting, cleared first so an inherited value cannot override the saved key.
if /i "%ARM%"=="openai" goto :openaikey
call :getkey DEEPSEEK_API_KEY
call :getkey MOONSHOT_API_KEY
call :getkey KIMI_CODE_API_KEY
call :getkey VOIDSWORN_CLAUDE_API_KEY
if /i "%ARM%"=="sonnet" if not defined VOIDSWORN_CLAUDE_API_KEY (echo no Claude API key saved: run CLAUDE_API_KEY.bat >> "%O%\result.txt" & goto :setupfail)
if /i "%ARM%"=="sonnet" goto :clone
if /i "%ARM%"=="opus" if not defined VOIDSWORN_CLAUDE_API_KEY (echo no Claude API key saved: run CLAUDE_API_KEY.bat >> "%O%\result.txt" & goto :setupfail)
if /i "%ARM%"=="opus" goto :clone
if /i "%ARM%"=="kimicode" goto :clone
if /i not "%ARM%"=="kimi" if not defined DEEPSEEK_API_KEY (echo no DeepSeek key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & goto :setupfail)
if /i "%ARM%"=="kimi" if not defined MOONSHOT_API_KEY (echo no Moonshot key saved: run WORKHORSE_SETUP.bat >> "%O%\result.txt" & goto :setupfail)
goto :clone
:openaikey
set "VOIDSWORN_OPENAI_API_KEY="
call :getkey VOIDSWORN_OPENAI_API_KEY
%PS% openai-key "%O%"
if errorlevel 1 goto :setupfail
goto :clone
:drysetup
if "%PC_RUNNER_TEST%"=="1" goto :clone
set "DEEPSEEK_API_KEY=dry"
set "MOONSHOT_API_KEY=dry"
set "KIMI_CODE_API_KEY=dry"
set "VOIDSWORN_CLAUDE_API_KEY=dry"
set "VOIDSWORN_OPENAI_API_KEY=dry"
set "OPENCODE_CONFIG=%T%work\opencode_mock.json"
powershell -NoProfile -Command "$dq=[char]34; Start-Process -WindowStyle Hidden -FilePath 'C:\Program Files\nodejs\node.exe' -ArgumentList ($dq+$env:T+'work\mock_llm.js'+$dq+' 8765 '+$dq+$env:O+'\mock_log.txt'+$dq+' '+$env:WORK_DRY_SCENARIO)"
rem wait until the stand-in is listening (an earlier one may still hold the port for a few seconds)
powershell -NoProfile -Command "$f='%O%\mock_log.txt'; for($i=0;$i -lt 300;$i++){ if((Test-Path $f) -and (Select-String -Quiet -Path $f -Pattern 'listening')){exit 0}; Start-Sleep 1 }; exit 1"

:clone
set "SPARSE="
if /i "%MODE%"=="dryrun" set "SPARSE=%WORK_DRY_SPARSE%"
%COMMON% checkout "%R%" "%O%" "%BR%" "%SPARSE%"
if errorlevel 1 (
  %PS% disk "%A%" "%R%" >> "%O%\result.txt" 2>&1
  exit /b 14
)
pushd "%R%"
%PS% prep %N% %ARM% "%R%" "%O%" "%G%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :prepfail
rem Give the probe, agent, and checks one private scratch directory, recorded before use.
set "PC_RUN_TEMP=%TEMP%"
%COMMON% scratch "%O%"
if errorlevel 1 goto :probefail
set /p PC_RUN_SCRATCH=<"%O%\scratch_path.txt" || goto :probefail
set "TEMP=%PC_RUN_SCRATCH%"
set "TMP=%PC_RUN_SCRATCH%"
set "TMPDIR=%PC_RUN_SCRATCH%"
rem Tiny model call before ship copying or the full agent. CLI login and billing failures stop here.
if "%PC_RUNNER_TEST%"=="1" goto :testpreflight
if /i "%MODE%"=="dryrun" goto :ocpreflight
if /i "%ARM%"=="kimicode" goto :kimisetup
:ocpreflight
%COMMON% preflight "%O%" "%R%" opencode "%OC%" "%MODEL%" "%VARIANT%"
if errorlevel 1 goto :probefail
goto :ready
:testpreflight
set "PKIND=opencode"
set "PKMODEL=%MODEL%"
if /i "%ARM%"=="kimicode" set "PKIND=kimi"
if /i "%ARM%"=="kimicode" set "PKMODEL=kimi-code/kimi-for-coding"
if /i "%ARM%"=="kimicode" if defined WORK_KIMI_MODEL set "PKMODEL=%WORK_KIMI_MODEL%"
%COMMON% preflight "%O%" "%R%" "%PKIND%" "%WORK_TEST_AGENT%" "%PKMODEL%" "%VARIANT%"
if errorlevel 1 goto :probefail
goto :ready
:kimisetup
call :findkimi
if not defined KIMIEXE (echo preflight failed: Kimi Code CLI not found >> "%O%\result.txt" & goto :probefail)
%COMMON% preflight "%O%" "%R%" kimi "%KIMIEXE%" "%KMODEL%" ""
if errorlevel 1 goto :probefail
:ready
rem Only capture jobs copy the ship files: the launcher sets WORK_SHIPS=1 (Board, Nov 10).
if defined WORK_SHIPS call "%T%get_ship_files.bat" "%VT%\build\godot" "%R%" "%R%\WORK_TASK.md" >> "%O%\ship_files.txt" 2>&1
if /i "%MODE%"=="dryrun" (echo dry> "%O%\balance_before.txt") else (%PS% balance %ARM% "%O%\balance_before.txt" > nul)
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_start.txt"
echo agent running %time% >> "%O%\result.txt"
set "TMO_REPO=%R%"
set "TMO_OUT=%O%"
set "TMO_LOG=%O%\log.txt"
set "TMO_ERR_LOG=%O%\stderr.txt"
if /i "%ARM%"=="openai" goto :agent_openai
if "%PC_RUNNER_TEST%"=="1" goto :testagent
if /i "%MODE%"=="dryrun" goto :agent_oc
rem The kimicode arm uses Kimi Code CLI and the PC user's plan login, matching its preflight.
if /i not "%ARM%"=="kimicode" goto :agent_oc
set "KIMIEXE="
call :findkimi
goto :kimiagent
:findkimi
set "KIMIEXE="
for /f "delims=" %%k in ('where kimi 2^>nul') do if not defined KIMIEXE set "KIMIEXE=%%k"
rem the queue watcher may have been started before Kimi Code was installed, so its PATH is old: add the user PATH from the registry
set "UPATH="
for /f "tokens=2,*" %%a in ('reg query HKCU\Environment /v Path 2^>nul ^| find /i "Path"') do set "UPATH=%%b"
if defined UPATH call set "PATH=%PATH%;%UPATH%"
if not defined KIMIEXE for /f "delims=" %%k in ('where kimi 2^>nul') do if not defined KIMIEXE set "KIMIEXE=%%k"
for %%c in ("%APPDATA%\npm\kimi.cmd" "%USERPROFILE%\.local\bin\kimi.exe" "%USERPROFILE%\.kimi-code\bin\kimi.exe" "%LOCALAPPDATA%\Programs\kimi-code\kimi.exe") do if not defined KIMIEXE if exist %%c set "KIMIEXE=%%~c"
set "KMODEL=kimi-code/kimi-for-coding"
if defined WORK_KIMI_MODEL set "KMODEL=%WORK_KIMI_MODEL%"
exit /b 0
:kimiagent
echo harness: Kimi Code CLI %KIMIEXE% -m %KMODEL% >> "%O%\result.txt"
echo kimi-cli %KMODEL%> "%O%\model.txt"
call "%T%tmo.bat" %WORK_CAP% "%KIMIEXE%" -m %KMODEL% --output-format stream-json -p "Read WORK_TASK.md in this folder and do exactly what it says. Do not commit and do not push." > "%O%\log.txt" 2> "%O%\stderr.txt"
> "%O%\exit.txt" echo %ERRORLEVEL%
goto :agent_end
:testagent
call "%T%tmo.bat" %WORK_CAP% "%COMSPEC%" /d /s /c ""%WORK_TEST_AGENT%"" > "%O%\log.txt" 2> "%O%\stderr.txt"
> "%O%\exit.txt" echo %ERRORLEVEL%
goto :agent_end
:agent_openai
%PS% openai-agent "%O%" "%R%" "%OC%" "%MODEL%" "%VARIANT%" %WORK_CAP%
> "%O%\exit.txt" echo %ERRORLEVEL%
goto :agent_end
:agent_oc
call "%T%tmo.bat" %WORK_CAP% "%OC%" run --auto --format json -m %MODEL% %VARIANT% --dir "%R%" "Read WORK_TASK.md in this folder and do exactly what it says. Do not commit and do not push." > "%O%\log.txt" 2> "%O%\stderr.txt"
> "%O%\exit.txt" echo %ERRORLEVEL%
:agent_end
set "TMO_REPO="
set "TMO_FATAL_PATTERN="
set "TMO_OUT="
set "TMO_LOG="
set "TMO_ERR_LOG="
rem Keep the event reader's existing input as well as the watchdog's log.txt.
copy /y "%O%\log.txt" "%O%\events.jsonl" >nul
powershell -NoProfile -Command "(Get-Date).ToString('s')" > "%O%\time_agent_end.txt"
set /p OCX=<"%O%\exit.txt"
echo opencode exit %OCX% at %time% >> "%O%\result.txt"
rem (a) A run that did not end cleanly is PARTIAL: its own branch, no pull request (issue 377).
set "PB=%BR%"
set "PARTIAL="
if not "%OCX%"=="0" set "PARTIAL=agent exit %OCX%"
if "%OCX%"=="124" if exist "%O%\stop_reason.txt" set /p PARTIAL=<"%O%\stop_reason.txt"
git rev-parse -q --verify MERGE_HEAD > nul 2>&1
if not errorlevel 1 set "PARTIAL=the agent left a merge unfinished"
if defined PARTIAL set "PB=%BR%-partial"
> "%O%\partial.txt" echo.%PARTIAL%
if defined PARTIAL echo PARTIAL RUN, %PARTIAL%: the work goes to %PB%, which opens no pull request >> "%O%\result.txt"
rem give the provider a minute to book the charge before reading the balance again
if /i not "%MODE%"=="dryrun" timeout /t 60 /nobreak > nul
if /i "%MODE%"=="dryrun" (echo dry> "%O%\balance_after.txt") else (%PS% balance %ARM% "%O%\balance_after.txt" > nul)
if /i "%ARM%"=="openai" (
  %PS% openai-spend "%N%" "%O%" "%WORK_ROOT%" "%SETF%" "%RESOLVED%" "%DRY%"
  if errorlevel 1 (
    set "PARTIAL=spend accounting unknown"
    set "PB=%BR%-partial"
    set "RC=14"
    > "%O%\partial.txt" echo spend accounting unknown
    echo PARTIAL RUN, spend accounting unknown: the work goes to %BR%-partial, which opens no pull request >> "%O%\result.txt"
  )
)
%PS% stats %N% %ARM% "%O%" > nul
move /y WORK_TASK.md "%O%\WORK_TASK.md" > nul
if "%PC_RUNNER_TEST%"=="1" if "%PC_TEST_STOP_BEFORE_PUBLISH%"=="1" goto :testfinish
rem Issue 889: validate and copy linked pictures with sidecars, including JPG, WebP and GIF.
if not defined PARTIAL (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%T%review_evidence.ps1" prepare "%R%" "%O%" "docs/shots/issue-%N%-%ARM%" >> "%O%\result.txt" 2>&1
  if errorlevel 1 goto :guardfail
)
rem #357 / R144: a capture run can re-save tracked .import files; restore them before the commit.
for /f "usebackq delims=" %%F in (`git ls-files "*.import"`) do git checkout -q -- "%%F"
git add -A
rem (b) The refuse list and the Deliver to warning (issue 377).
%PS% guard %N% %ARM% "%R%" "%O%" >> "%O%\result.txt" 2>&1
if errorlevel 1 goto :guardfail
git diff --cached --quiet
if errorlevel 1 goto :haschange
if defined PARTIAL goto :haschange
%PS% head-changed "%R%" "%O%" >> "%O%\result.txt" 2>&1
if "%ERRORLEVEL%"=="7" goto :nochange
if errorlevel 1 goto :guardfail
:haschange
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
if "%NODE_EXIT%"=="0" if "%PARITY_EXIT%"=="0" set "CHECKS_OK=1"
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
goto :finish

:getkey
for /f "tokens=2,*" %%a in ('reg query HKCU\Environment /v %1 2^>nul ^| findstr /c:"REG_"') do set "%1=%%b"
exit /b 0
:settings
> "%SETF%" echo # Workhorse runner settings (issue 722). The runner only reads this file after creating it.
>> "%SETF%" echo # min_free_gb: the run refuses to start when the drive holding Downloads\voidsworn_test has less free space than this (issue 722).
>> "%SETF%" echo min_free_gb=60
>> "%SETF%" echo janitor_free_gb=150
>> "%SETF%" echo # OpenAI monthly estimate budget in USD. November 2026 starts with 94 left.
>> "%SETF%" echo openai_budget_usd=94
exit /b 0
:testfinish
rem Free integration proof: keep the agent's files but never create a commit or push.
set "RC=0"
goto :finish
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
:probefail
if exist WORK_TASK.md move /y WORK_TASK.md "%O%\WORK_TASK.md" > nul
set "RC=14"
goto :finish
:setupfail
%COMMON% finish "%O%" 3 "" "%PUSHMODE%" 0
exit /b 3
:finish
rem Include failed probes and partial runs too. The ledger uses the run folder as an id, so this cannot charge twice.
if /i "%ARM%"=="openai" (
  %PS% openai-spend "%N%" "%O%" "%WORK_ROOT%" "%SETF%" "%RESOLVED%" "%DRY%"
  if errorlevel 1 set "RC=14"
)
popd
%COMMON% finish "%O%" "%RC%" "%PARTIAL%" "%PUSHMODE%" "%CHECKS_OK%" "%R%"
if errorlevel 1 set "RC=14"
if defined PC_RUN_TEMP set "TEMP=%PC_RUN_TEMP%"
if defined PC_RUN_TEMP set "TMP=%PC_RUN_TEMP%"
if defined PC_RUN_TEMP set "TMPDIR=%PC_RUN_TEMP%"
%PS% disk "%A%" "%R%" >> "%O%\result.txt" 2>&1
exit /b %RC%
