@echo off
rem Issue 1434 (Astra items 2, 10 and W4): battle ships built a few per frame under the cover, the title backdrop built
rem behind a menu that answers, the sound volume untouched. PC proof on real hulls. Replaces OPUS1434_LOAD7.bat (not run) and LOAD6 (ran, FAIL: frames of 5 to 10 s with world bakes pending; bake stages timed, Battle 2 repeated with warm shaders here), LOAD5, LOAD4, LOAD3, LOAD2. Before them, OPUS1434_LOAD.bat (pulled
rem before it ran: its bench could pass after a timeout and never clicked the title, Artoo on PR 1445).
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; export and player path steps as OPUS1435_CLOSE_PP2.
rem Steps on one pinned commit (opus/issue-1434 head d2daa57b, PR 1445):
rem   1. checkout, ships, import.
rem   2. load: godot/bench/load_1434.gd, fullscreen, real renderer, GPU solo. Cases: s25 (24 units, cold), the title, a leave case (New run clicked by a real mouse while the backdrop has work pending; no try caught pending fails as INCONCLUSIVE), with
rem      its backdrop at volume 0.25, then three sector 1 fights (seeds 101, 202, 303), then Battle 2 again with fresh bakes (b2r, reported only). Graded one by one: the longest ship
rem      build stretch, reaching play or showcase_ready before the time limit, the worst frame from the cover to play,
rem      a real mouse click on the title's Settings link while the backdrop builds (drawer open within 500 ms), and the
rem      shared sfx bus never moving. Result: out_new\load\load_result.txt, gate line "[load1434] RESULT PASS".
rem   3. a Windows export of the pin into the attempt folder (never the live build\export), with build_info.json for the
rem      recorder, and the export's own --check-export.
rem   4. the player path, both fresh Sunward routes through Battles 1 to 3, recorded from that export (judge against main:
rem      issue 1457).
rem Nothing outside the attempt folder is written or deleted. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434h"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=d2daa57b57e6e67786695a4b72f21b7603f0b576"
set "PIN_OLD="

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
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0

rem ---- 2. the load bench, fullscreen on the main screen, GPU solo (frame-time measurement)
set "H=%O%\load"
if not exist "%H%" mkdir "%H%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 load" & set "JW_EXPECT=%H%\load_result.txt" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --fullscreen --script res://bench/load_1434.gd -- --out "%H%" > "%H%\log.txt" 2>&1
set "PC_GPU_MODE="
if not exist "%H%\load_result.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load: no load_result.txt, see load\log.txt" & goto exp)
findstr /c:"[load1434] RESULT PASS" "%H%\load_result.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load: a graded item failed, see load\load_result.txt")

:exp
if defined JW_STOP exit /b 0
rem ---- 3. the export of the pin, for the recorder (build_info.json: the pinned commit, a clean checkout)
set "E=%O%\export"
if not exist "%E%" mkdir "%E%"
powershell -NoProfile -Command "$d = (& git -C '%OJ_REPO%' show -s --format=%%cI HEAD); $c = (& git -C '%OJ_REPO%' rev-parse HEAD); if ($c -ne '%2') { exit 1 }; @{commit = $c; commit_date = ([DateTimeOffset]::Parse($d)).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)} | ConvertTo-Json -Compress | Set-Content -LiteralPath '%OJ_REPO%\godot\build_info.json' -Encoding Ascii" > "%O%\build_info_log.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "could not write build_info.json for the pin" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%APPDATA%\Godot\export_templates\4.7.2.stable"
set "JW_STEP=%1 export" & set "JW_EXPECT=%E%\Voidsworn.pck;%E%\Voidsworn.console.exe" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%E%\Voidsworn.exe" > "%O%\export_log.txt" 2>&1
set "JW_STEP=%1 check export" & set "JW_EXPECT=%O%\check_export.txt" & call "%JW%" run 300 "%E%\Voidsworn.console.exe" --headless -- --check-export > "%O%\check_export.txt" 2>&1

rem ---- 4. the player path from that export: both fresh Sunward routes, Battles 1 to 3 (the recorder makes its own
rem      fresh profile per run, so PC_REAL_PROFILE is on for this step only, as player_path.bat sets it)
set "PC_REAL_PROFILE=1"
set "JW_STEP=%1 player path" & set "JW_EXPECT=%O%\player_path" & call "%JW%" run 7200 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\codex\player_path_1119\run.ps1" -Install "%E%" -Full "%O%\player_path" > "%O%\player_path_console.txt" 2>&1
set "PC_REAL_PROFILE="
exit /b 0
