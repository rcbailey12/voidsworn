@echo off
rem WORKHORSE_CLEANUP.bat (issue 377, Opus, Nov 12 2026): Ryan's one switch for the workhorse runner's disk use.
rem Each workhorse run keeps a full copy of the repo (repo\) beside its reports (out\). With the switch on, a run whose push
rem the runner has checked removes its own repo\ copy and keeps out\ (reports, logs, shots, refused files). Off by default.
rem It writes Downloads\voidsworn_test\work217\runner_settings.txt; the runner only reads that file. Nothing is removed here.
setlocal
title Workhorse cleanup switch
set "F=%USERPROFILE%\Downloads\voidsworn_test\work217\runner_settings.txt"
echo.
echo  Each workhorse run keeps a full copy of the game's code, 1 to 25 GB. With this switch on, a run that pushed
echo  its work and passed the runner's push check removes its own copy afterwards. Its reports and pictures stay.
echo  Runs that fail, or stop before a checked push, always keep everything.
echo.
if exist "%F%" (echo  Now: & findstr /b /c:"remove_repo_copy_after_push=" "%F%" & findstr /b /c:"min_free_gb=" "%F%") else (echo  Now: off, never set)
echo.
set "ANS="
set /p ANS= Type YES to turn it on, or NO to turn it off, then press Enter: 
set "V="
if /i "%ANS%"=="YES" set "V=yes"
if /i "%ANS%"=="NO" set "V=no"
if not defined V (echo. & echo  Nothing changed. & pause & exit /b 1)
rem Issue 722: keep the free-space floor Ryan or the runner set; only the cleanup switch changes here.
set "MB=60"
if exist "%F%" for /f "tokens=1,2 delims==" %%a in ('type "%F%"') do if /i "%%a"=="min_free_gb" set "MB=%%b"
> "%F%" echo # Workhorse runner settings (issue 377, issue 722). The runner only reads this file; Ryan changes it with WORKHORSE_CLEANUP.bat.
>> "%F%" echo # remove_repo_copy_after_push=yes: after a push the runner has checked, it removes that run's repo copy and keeps out.
>> "%F%" echo remove_repo_copy_after_push=%V%
>> "%F%" echo # min_free_gb: the run refuses to start when the drive holding Downloads\voidsworn_test has less free space than this (issue 722).
>> "%F%" echo min_free_gb=%MB%
echo.
echo  Done: remove_repo_copy_after_push=%V%
echo  It applies from the next workhorse run. Old run folders are not touched.
pause
exit /b 0
