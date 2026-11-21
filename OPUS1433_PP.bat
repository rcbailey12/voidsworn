@echo off
rem Issue 1433 (PR 1443): the player path recording of Battles 1 to 3 on the pinned commit. Replaces step 3 of
rem OPUS1433_HOVER.bat, whose recorder refused both seeds on frame 1 ("Godot must resolve user:// inside a dedicated
rem temporary profile from player_path.bat"): that bat called run.ps1 directly, so PC_REAL_PROFILE was not set and the
rem watchdog swapped in its own throwaway profile. This bat calls the checkout's tools\pc\jobs\player_path.bat, which
rem sets PC_REAL_PROFILE=1 for the recorder only (run.ps1 makes and checks its own fresh profile per seed).
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303).
rem Steps on the same pin as OPUS1433_HOVER.bat (148d446c):
rem   1. checkout, ships, import, then a fresh Windows release export into the attempt folder.
rem   2. player_path.bat on that export: both fresh Sunward routes (seeds 121 and 10) through Battles 1 to 3, its own
rem      shared GPU slot. Output: out_new\player_path\ (recordings, traces, review). Judge against main (issue 1457:
rem      seed 10 stops at route 2-2, seed 121 losses): no new errors or crashes.
rem The hover step is not repeated (it passed: board/pc-out-1433 at 7a3b5262).
rem Results: Downloads\voidsworn_test\opus1433pp\out_<stamp>_<n>\. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1433pp"
set "LABEL=1433"
set "TOOLS=godot"
set "PIN_NEW=148d446cb979c851ed618ed2af3b4a85b8a2c2d3"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
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
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0
rem ---- the release export, as g2_export.bat makes it, into this attempt folder (the live build\export is not touched)
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable"
if not exist "%TPL%\windows_release_x86_64.exe" (call "%JW%" fail "%1 export: no export templates in %TPL%" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%TPL%"
set "EXP=%O%\export"
if not exist "%EXP%" mkdir "%EXP%"
set "JW_STEP=%1 export" & set "JW_EXPECT=%EXP%\Voidsworn.pck" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%EXP%\Voidsworn.exe" > "%O%\export.txt" 2>&1
set "PC_GODOT_EXPORT_TEMPLATES="
if defined JW_STOP exit /b 0
rem ---- step 2: the player path recording of Battles 1 to 3 on the step 1 export (fresh isolated profiles, player defaults)
if defined JW_STOP exit /b 0
set "PP=%O%\player_path"
set "PC_GPU_ISSUE=opus1433_player_path"
rem player_path.bat sets PC_REAL_PROFILE=1 inside its own setlocal; the job's settings are unchanged after it returns
call "%OJ_REPO%\tools\pc\jobs\player_path.bat" "%EXP%" "%PP%" > "%O%\player_path_log.txt" 2>&1
set "PPC=%ERRORLEVEL%"
set "PC_GPU_ISSUE="
if not "%PPC%"=="0" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 player_path: exit %PPC%, see player_path_log.txt")
exit /b 0
