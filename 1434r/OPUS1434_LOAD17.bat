@echo off
rem Issue 1434 LOAD17 with issues 1518 and 1519 (Board, Nov 21: one pin for all three; graded on a WARM profile, the cold
rem first launch reported alongside on the same items, with one condition on the cold pass: the loading cover stays up
rem while shaders compile, never a blank or stalled window). LOAD15 left: the warm title frame (601 ms), battle cover frames up to 1.2 s (the Navy fighter wing's model loaded on the main thread, now preloaded on a worker, its setup split into load, instance and finish; terrain files loaded again each battle, now kept for the session), one 3 to 6 s draw inside hull preparation on the 24-ship battle (each frame row names the hull-prep step read as its draw began), and the warm close during the title load (2.1 s; the close's frame log now names the world's build step). The pin includes current main. The player path is reported only. Replaces OPUS1434_LOAD16.bat (never queued: its step label was read after the draw, Artoo), OPUS1434_LOAD15.bat (ran: target b, the cold title frame and the player path passed) and every earlier LOAD bat.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; export and player path steps as LOAD9.
rem Steps on one pinned commit (opus/issue-1434 head 057db2b4, PR 1445):
rem   1. checkout, ships, import.
rem   2. contrib\opus\pc\1434\load1434_runs.ps1 from the pinned checkout, GPU solo:
rem      a. the load bench (godot/bench/load_1434.gd, fullscreen) on a fresh profile inside the attempt folder: cold,
rem         reported, plus its COVER line (cover up on every frame to play, no frame of 5 s or more);
rem      b. the same bench again on that same profile: warm, graded (slice, ready, cover frame, title click, title
rem         frame, bus, leave);
rem      c. the six CLOSE5 close cases (issue 1435 method), each on its own fresh profile (cold), then each on the
rem         warm profile, both graded on their own lines: window hidden within 500 ms of the close during a load (1518: altf4_load_5s,
rem         title_load_5s, title_battle_30s), first title frame within 200 ms of leaving the battle (1519: both title
rem         cases), one window-route quit, exit 0, no crash; an Alt-F4 case that could not send its keys is UNVERIFIED.
rem      Result: out_new\load10\load10_result.txt, gate line "[load10] RESULT PASS".
rem   3. a Windows export of the pin into the attempt folder, with build_info.json, and the export's --check-export.
rem   4. the player path, both fresh Sunward routes through Battles 1 to 3, recorded from that export.
rem Nothing outside the attempt folder is written or deleted. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434r"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=057db2b44f759336333f3f1e8e6a3599efc542f9"
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

rem ---- 2. load bench cold and warm, then the close cases cold and warm (GPU solo: frame-time measurement)
set "H=%O%\load10"
if not exist "%H%" mkdir "%H%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 load10" & set "JW_EXPECT=%H%\load10_result.txt" & call "%JW%" run 5400 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\opus\pc\1434\load1434_runs.ps1" -Godot "%JW_GODOT%" -Project "%OJ_REPO%\godot" -Out "%H%" > "%H%\console.txt" 2>&1
set "PC_GPU_MODE="
if not exist "%H%\load10_result.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: no load10_result.txt, see load10\console.txt" & goto exp)
findstr /c:"[load10] RESULT PASS" "%H%\load10_result.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: a graded item failed, see load10\load10_result.txt")

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
