@echo off
rem Issue 1457 (PR 1483): the player path recording of Battles 1 to 3 on the pinned commit, the recorder fix itself.
rem Default seeds 31 (Hullbreakers) and 10 (Navy, expect one ROUTE DRIFT line: its planned 2-2 is now an event stop).
rem Done when both seed jsonl files end in the Battle 3 win. Seed 121 is a diagnostic and is not run here.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; the export, build_info.json, check-export and
rem player path steps are copied line for line from OPUS1433_PP2.bat (the same lines as OPUS1435_CLOSE_PP2).
rem Steps on main 86870004 (PR 1483 merged, PR 1443 click queue on main): the combined proof Artoo asked for:
rem   1. checkout, ships, import.
rem   3. a Windows export of the pin into the attempt folder (never the live build\export), with build_info.json for the
rem      recorder, and the export's own --check-export.
rem   4. the player path, both routes through Battles 1 to 3, recorded from that export.
rem   5. the PC drive is low: the step's own AVI and MP4 recordings inside the attempt folder are deleted after step 4;
rem      jsonl traces, logs and contact sheets stay.
rem Step numbers kept from OPUS1434_LOAD2 so the copied lines read the same. Nothing outside the attempt folder is
rem written or deleted. Once queued, never edited; a change ships under a new name (next: OPUS1457_MAIN2.bat).
setlocal EnableExtensions
set "JOB=opus1457main1"
set "LABEL=1457"
set "TOOLS=godot"
set "PIN_NEW=86870004926e76c15ef884c26a98d5cc1290d3d4"
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

rem ---- 5. the job's own videos (low drive): only inside this attempt's player_path folder
if exist "%O%\player_path" (
  del /s /q "%O%\player_path\*.avi" > "%O%\video_cleanup.txt" 2>&1
  del /s /q "%O%\player_path\*.mp4" >> "%O%\video_cleanup.txt" 2>&1
)
exit /b 0
