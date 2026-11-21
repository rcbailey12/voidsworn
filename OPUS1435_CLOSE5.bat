@echo off
rem Issue 1435 PC proof (PR 1441 head 31fc45e3, round 2; CLOSE5 supersedes CLOSE4: v5 script adds request-to-hidden and battle-to-title timings, Artoo on PR 1441), from tools/pc/jobs/opus_job_template.bat. One pinned checkout with the
rem built ships, then only the close timing (the export and player path ran in CLOSE_PP2):
rem   close timing: the game windowed in a quick battle, closed by the title bar X and by Alt-F4 during the load (cuts
rem      still running) and mid-battle; each close timed from the request to process exit, the game log read for
rem      "[main] quit (window)", the fx retire/drain lines and any crash (close1435_timing5.ps1 beside this bat);
rem Output: <attempt>\out_new\close\close_timing.txt and .json, each case's game.log and godot_file.log. Nothing outside the attempt folder
rem is written or deleted. Once queued, this bat is never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1435g"
set "LABEL=1435"
set "TOOLS=godot"
set "PIN_NEW=31fc45e3b52ee5a86fce2a174a8413bbedb1ea5b"
set "PIN_OLD="
set "HERE=%~dp0"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
if not exist "%HERE%close1435_timing5.ps1" (echo FAILED: close1435_timing5.ps1 is not beside this bat & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
copy /y "%HERE%close1435_timing5.ps1" "%O%\close1435_timing5.ps1" > nul
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1

rem ---- the real window close, X and Alt-F4, during the load and mid-battle
set "JW_STEP=%1 close timing" & set "JW_EXPECT=%O%\close\close_timing.txt" & call "%JW%" run 900 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%O%\close1435_timing5.ps1" -Godot "%JW_GODOT%" -Project "%OJ_REPO%\godot" -Out "%O%\close" > "%O%\close_console.txt" 2>&1

exit /b 0
