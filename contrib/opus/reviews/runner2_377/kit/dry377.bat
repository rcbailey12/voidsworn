@echo off
rem Issue 377 runner 2 dry runs (Opus worker, Nov 12 2026). Everything lands in Downloads\voidsworn_test\opus377.
rem Free: the stand-in model (mock_llm.js) and a stand-in for Codex; no paid model calls. Pushes go only to runner377/...
rem test branches, which open no pull request and start no checks. Nothing is deleted.
title opus377 runner 2 dry runs
setlocal
set "H=%USERPROFILE%\Downloads\voidsworn_test\opus377"
set "S=%H%\dry_status.txt"
set "WORK_ROOT=%H%\runs"
set "WORK_TEST_BRANCH=runner377/issue-377-deepseek"
set "WORK_SKIP_CHECKS=1"
set "WORK_DRY_SPARSE=tools/pc contrib/opus/tools godot/assets/ships godot/gen godot/fx/atlases/weapons/muzzle docs/shots/issue-377-deepseek"
> "%S%" echo dry runs started %date% %time%

set "WORK_DRY_SCENARIO=refuse"
set "WORK_CAP=900"
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run1 refuse: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"

set "WORK_DRY_SCENARIO=timecap"
set "WORK_CAP=60"
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run2 timecap: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"

> "%WORK_ROOT%\runner_settings.txt" echo remove_repo_copy_after_push=yes
set "WORK_DRY_SCENARIO=merge"
set "WORK_CAP=900"
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run3 merge rerun, setting yes: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"

set "WORK_TEST_FAULT=skipcommit"
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run4 merge with the 541 fault: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"
set "WORK_TEST_FAULT="

set "CODEX_TEST_ROOT=%H%\cx"
set "CODEX_TEST_AGENT=%H%\cx_agent.bat"
set "CODEX_TEST_BRANCH=runner377/codex-377"
set "CODEX_TEST_SPARSE=tools/pc godot/assets/ships"
call "%H%\tools\pc\codex_issue.bat" 377
>> "%S%" echo run5 codex stand-in: exit %ERRORLEVEL% at %time%
>> "%S%" echo all done %date% %time%
exit /b 0
