@echo off
rem Issue 1143 (PR 1215): record Battles 1 to 3 the way a player sees them, on current main, and KEEP the videos.
rem Why a new run: OPUS1457_MAIN1 (main 86870004) passed both routes, then its step 5 deleted both AVI masters and all
rem 17 MP4s under the low-drive rule before any copy existed (opus1457main1_out_new\video_cleanup.txt). Nothing to recover.
rem Seeds 31 (Hullbreakers) and 10 (Navy, one ROUTE DRIFT line expected: its planned 2-2 is an event stop).
rem Steps 1 to 4 are OPUS1457_MAIN1.bat's lines unchanged (checkout, ships, import, export with build_info.json,
rem --check-export, player path from that export). Only step 5 is new: keep1143_videos.ps1 (beside this bat) checks
rem every clip and sheet, makes a verified 1080p copy of each AVI master, copies the set to
rem Downloads\voidsworn_test\shots\player_path_1143\<pin>_<stamp> (no janitor scans shots\) and reads every copy back.
rem Only after all of that passes does it delete the two raw AVI masters in this attempt's own folder. Any failure
rem deletes nothing. KEEP_AVI=1 keeps the raw masters too. The review MP4s and sheets stay in out_new for the relay.
rem Done when status.txt says done PASS and out_new\keep_report.txt ends in KEEP PASS.
rem Needs C: over the runner's 60 GB floor (the raw masters are several GB each until step 5).
rem Once queued, never edited; a change ships under a new name (next: OPUS1143_REC2.bat).
setlocal EnableExtensions
set "JOB=opus1143rec1"
set "LABEL=1143"
set "TOOLS=godot ffmpeg pil"
set "PIN_NEW=7e5a085f6c73ae7a586d606dd323a50c784ae738"
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
if not exist "%HERE%keep1143_videos.ps1" (echo FAILED: keep1143_videos.ps1 is not beside this bat & exit /b 2)
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
copy /y "%HERE%keep1143_videos.ps1" "%O%\keep1143_videos.ps1" > nul
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0

rem ---- 3. the export of the pin, for the recorder (build_info.json: the pinned commit, a clean checkout)
set "E=%O%\export"
if not exist "%E%" mkdir "%E%"
powershell -NoProfile -Command "$d = (& git -C '%OJ_REPO%' show -s --format=%%cI HEAD); $c = (& git -C '%OJ_REPO%' rev-parse HEAD); if ($c -ne '%2') { exit 1 }; @{commit = $c; commit_date = ([DateTimeOffset]::Parse($d)).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)} | ConvertTo-Json -Compress | Set-Content -LiteralPath '%OJ_REPO%\godot\build_info.json' -Encoding Ascii" > "%O%\build_info_log.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "could not write build_info.json for the pin" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%APPDATA%\Godot\export_templates\4.7.2.stable"
set "JW_STEP=%1 export" & set "JW_EXPECT=%E%\Voidsworn.pck;%E%\Voidsworn.console.exe" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%E%\Voidsworn.exe" > "%O%\export_log.txt" 2>&1
set "JW_STEP=%1 check export" & set "JW_EXPECT=%O%\check_export.txt" & call "%JW%" run 300 "%E%\Voidsworn.console.exe" --headless -- --check-export > "%O%\check_export.txt" 2>&1
if defined JW_STOP exit /b 0

rem ---- 4. the player path from that export: both fresh Sunward routes, Battles 1 to 3 (the recorder makes its own
rem      fresh profile per run, so PC_REAL_PROFILE is on for this step only, as player_path.bat sets it)
set "PC_REAL_PROFILE=1"
set "JW_STEP=%1 player path" & set "JW_EXPECT=%O%\player_path" & call "%JW%" run 7200 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\codex\player_path_1119\run.ps1" -Install "%E%" -Full "%O%\player_path" > "%O%\player_path_console.txt" 2>&1
set "PC_REAL_PROFILE="
if defined JW_STOP exit /b 0

rem ---- 5. keep, check, read back; only then remove this attempt's own raw AVI masters (nothing outside the attempt
rem      folder is deleted; shots\player_path_1143 is only written)
set "KA="
if "%KEEP_AVI%"=="1" set "KA=-KeepAvi"
set "JW_STEP=%1 keep videos" & set "JW_EXPECT=%O%\keep_report.txt;%O%\keep_manifest.txt;%O%\keep_path.txt" & call "%JW%" run 3600 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%O%\keep1143_videos.ps1" -Full "%O%\player_path" -Repo "%OJ_REPO%" -Python "%JW_PIL%" -Ffmpeg "%JW_FFMPEG%" -Pin %2 -Out "%O%" %KA% > "%O%\keep_console.txt" 2>&1
exit /b 0
