@echo off
rem Issue 377, Muse's condition on PR 575: two Codex stand-in runs sharing board-style folder cx\issue-377 must keep both
rem runs' refused copies (out\runs\<date_time>\refused). Then one workhorse refuse run on the same final code. Free.
title opus377 per-run refused folder dry run
setlocal
set "H=%USERPROFILE%\Downloads\voidsworn_test\opus377"
set "S=%H%\dry_status_c.txt"
> "%S%" echo started %date% %time%
set "CODEX_TEST_ROOT=%H%\cx"
set "CODEX_TEST_AGENT=%H%\cx_agent2.bat"
set "CODEX_TEST_BRANCH=runner377/codex-377"
set "CODEX_TEST_SPARSE=tools/pc godot/assets/ships"
set "CX_RUN=A"
call "%H%\tools\pc\codex_issue.bat" 377
>> "%S%" echo run7 codex rerun A: exit %ERRORLEVEL% at %time%
copy /y "%H%\cx\issue-377\result.txt" "%H%\cx_result_A.txt" > nul
timeout /t 2 /nobreak > nul
set "CX_RUN=B"
call "%H%\tools\pc\codex_issue.bat" 377
>> "%S%" echo run8 codex rerun B: exit %ERRORLEVEL% at %time%
copy /y "%H%\cx\issue-377\result.txt" "%H%\cx_result_B.txt" > nul
set "CODEX_TEST_ROOT="
set "WORK_ROOT=%H%\runs"
set "WORK_TEST_BRANCH=runner377/issue-377-deepseek"
set "WORK_SKIP_CHECKS=1"
set "WORK_DRY_SPARSE=tools/pc contrib/opus/tools godot/assets/ships godot/gen godot/fx/atlases/weapons/muzzle docs/shots/issue-377-deepseek"
set "WORK_DRY_SCENARIO=refuse"
set "WORK_CAP=900"
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run9 workhorse refuse: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"
>> "%S%" echo all done %date% %time%
exit /b 0
