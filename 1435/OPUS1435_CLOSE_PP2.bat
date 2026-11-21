@echo off
rem Issue 1435 PC proof (PR 1441 head 416ffaf0; v2 of OPUS1435_CLOSE_PP.bat: Alt-F4 only with the game verified in front), from tools/pc/jobs/opus_job_template.bat. One pinned checkout with the
rem built ships, then:
rem   1. close timing: the game windowed in a quick battle, closed by the title bar X and by Alt-F4 during the load (cuts
rem      still running) and mid-battle; each close timed from the request to process exit, the game log read for
rem      "[main] quit (window)", the fx retire/drain lines and any crash (close1435_timing2.ps1 beside this bat);
rem   2. a Windows export of the pin into the attempt folder (never the live build\export), with build_info.json for the
rem      recorder, and the export's own --check-export;
rem   3. the player path, both fresh Sunward routes through Battles 1 to 3, recorded from that export.
rem Outputs: <attempt>\out_new\close\close_timing.txt, <attempt>\out_new\player_path\. Nothing outside the attempt folder
rem is written or deleted. Once queued, this bat is never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1435d"
set "LABEL=1435"
set "TOOLS=godot"
set "PIN_NEW=416ffaf0ac6712d14ea70bfc1f9c9ecffc69b3bf"
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
if not exist "%HERE%close1435_timing2.ps1" (echo FAILED: close1435_timing2.ps1 is not beside this bat & exit /b 2)
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
copy /y "%HERE%close1435_timing2.ps1" "%O%\close1435_timing2.ps1" > nul
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1

rem ---- 1. the real window close, X and Alt-F4, during the load and mid-battle (independent of 2 and 3)
set "JW_STEP=%1 close timing" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\close\close_timing.txt" & call "%JW%" run 900 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%O%\close1435_timing2.ps1" -Godot "%JW_GODOT%" -Project "%OJ_REPO%\godot" -Out "%O%\close" > "%O%\close_console.txt" 2>&1

rem ---- 2. the export of the pin, for the recorder (build_info.json: the pinned commit, a clean checkout)
set "E=%O%\export"
if not exist "%E%" mkdir "%E%"
powershell -NoProfile -Command "$d = (& git -C '%OJ_REPO%' show -s --format=%%cI HEAD); $c = (& git -C '%OJ_REPO%' rev-parse HEAD); if ($c -ne '%2') { exit 1 }; @{commit = $c; commit_date = ([DateTimeOffset]::Parse($d)).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)} | ConvertTo-Json -Compress | Set-Content -LiteralPath '%OJ_REPO%\godot\build_info.json' -Encoding Ascii" > "%O%\build_info_log.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "could not write build_info.json for the pin" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%APPDATA%\Godot\export_templates\4.7.2.stable"
set "JW_STEP=%1 export" & set "JW_EXPECT=%E%\Voidsworn.pck;%E%\Voidsworn.console.exe" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%E%\Voidsworn.exe" > "%O%\export_log.txt" 2>&1
set "JW_STEP=%1 check export" & set "JW_EXPECT=%O%\check_export.txt" & call "%JW%" run 300 "%E%\Voidsworn.console.exe" --headless -- --check-export > "%O%\check_export.txt" 2>&1

rem ---- 3. the player path from that export: both fresh Sunward routes, Battles 1 to 3 (the recorder makes its own
rem      fresh profile per run, so PC_REAL_PROFILE is on for this step only, as player_path.bat sets it)
set "PC_REAL_PROFILE=1"
set "JW_STEP=%1 player path" & set "JW_EXPECT=%O%\player_path" & call "%JW%" run 7200 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\codex\player_path_1119\run.ps1" -Install "%E%" -Full "%O%\player_path" > "%O%\player_path_console.txt" 2>&1
set "PC_REAL_PROFILE="
exit /b 0
