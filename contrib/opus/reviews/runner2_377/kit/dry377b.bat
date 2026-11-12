@echo off
rem Issue 377 confirmation dry run with the final work_issue.ps1: the refuse case again, run 3 on the same test branch.
title opus377 confirmation dry run
setlocal
set "H=%USERPROFILE%\Downloads\voidsworn_test\opus377"
set "S=%H%\dry_status_b.txt"
set "WORK_ROOT=%H%\runs"
set "WORK_TEST_BRANCH=runner377/issue-377-deepseek"
set "WORK_SKIP_CHECKS=1"
set "WORK_DRY_SPARSE=tools/pc contrib/opus/tools godot/assets/ships godot/gen godot/fx/atlases/weapons/muzzle docs/shots/issue-377-deepseek"
set "WORK_DRY_SCENARIO=refuse"
set "WORK_CAP=900"
> "%S%" echo started %date% %time%
call "%H%\tools\pc\work_issue.bat" 377 deepseek dryrun
>> "%S%" echo run6 refuse again: exit %ERRORLEVEL% at %time%
type "%WORK_ROOT%\dryrun-377-deepseek\latest.txt" >> "%S%"
exit /b 0
