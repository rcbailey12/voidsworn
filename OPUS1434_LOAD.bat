@echo off
rem Issue 1434 (Astra items 2, 10 and W4): battle ships built a few per frame under the cover, the title backdrop built
rem behind a menu that answers, the sound volume untouched. PC proof on real hulls.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat, like OPUS1433_HOVER.bat.
rem Steps on one pinned commit (opus/issue-1434 head a665ce76, PR 1445):
rem   1. checkout, ships, import, then a Windows release export of that checkout into the attempt folder.
rem   2. load: godot/bench/load_1434.gd, fullscreen, real renderer, GPU solo. Cases: s25 (24 units, cold), the title with
rem      its backdrop at volume 0.25, then three sector 1 fights (seeds 101, 202, 303). PASS needs every case's longest
rem      ship build stretch under 500 ms and the title's sfx bus never moving. Result: out_new\load\load_result.txt.
rem   3. player_path: contrib/codex/player_path_1119/run.ps1 from the same checkout on the step 1 export, both fresh
rem      Sunward routes through Battles 1 to 3 (its own shared GPU slot, as player_path.bat does). Output: out_new\player_path\.
rem The job's done line is PASS only when both steps pass. Results: Downloads\voidsworn_test\opus1434\out_<stamp>_<n>\.
rem Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=a665ce76b70311a3be859b497cac5cedfa8c6281"

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
rem ---- step 2: the load bench, fullscreen on the main screen, GPU solo (frame-time measurement)
set "H=%O%\load"
if not exist "%H%" mkdir "%H%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 load"
set "JW_EXPECT=%H%\load_result.txt"
call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --fullscreen --script res://bench/load_1434.gd -- --out "%H%" > "%H%\log.txt" 2>&1
set "PC_GPU_MODE="
if not exist "%H%\load_result.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load: no load_result.txt, see load\log.txt" & goto pp)
findstr /c:"[load1434] RESULT PASS" "%H%\load_result.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load: a build stretch over 500 ms or the bus moved, see load\load_result.txt")
:pp
rem ---- step 3: the player path recording of Battles 1 to 3 on the step 1 export (fresh isolated profiles, player defaults)
if defined JW_STOP exit /b 0
set "PP=%O%\player_path"
set "PC_GPU_ISSUE=opus1434_player_path"
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\codex\player_path_1119\run.ps1" -Install "%EXP%" -Full "%PP%" > "%O%\player_path_log.txt" 2>&1
set "PPC=%ERRORLEVEL%"
set "PC_GPU_ISSUE="
if not "%PPC%"=="0" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 player_path: exit %PPC%, see player_path_log.txt")
exit /b 0
