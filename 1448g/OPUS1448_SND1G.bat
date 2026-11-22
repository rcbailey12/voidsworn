@echo off
rem Issue 1448 SND-1, bat G (PR 1478): replaces SND1C to SND1F. G pins 1cc09be0 (main with the map jump queue, PR 1557; the recorder presses the real campaign
rem buttons, so reward picks carry their cue) and adds a 960x540 mp4 with sound beside each m4a (Board, Nov 22). The cause of "jump to 0-0 did not open" (SND1B,
rem LOAD14): the recorder pressed Jump while the sector map was still behind its loading cover, and map3d drops a jump
rem while loading. Fixed in b0a57df9 (main/player_path.gd waits for the map, logs map_ready and jump_open). This bat
rem reuses OPUS1434_LOAD13.bat's export and player-path steps line for line (build_info.json, export, --check-export,
rem then contrib/codex/player_path_1119/run.ps1, which owns the fresh recorder profile), with -Seeds 10.
rem What the sound wiring sounds like in the real exported game. Built from tools/pc/jobs/opus_job_template.bat on
rem opus_job_head.bat (issue 1303). One pinned commit, PR 1478's head 1cc09be0 (map wait, retry fix, real button presses, main merged).
rem Steps:
rem   1. checkout, ships, import.
rem   2. LOAD13's step 3: build_info.json for the pin, the Windows export into the attempt folder, --check-export.
rem   3. LOAD13's step 4: run.ps1 records route seed 10 (title, sector map, reward dialogs, three battle ends) from that
rem      export with Godot Movie Maker, sound included: player_path\seed-10.avi and seed-10.jsonl.
rem   4. three sound-only clips cut at the recorder's own frame marks: SND1_A_title_map.m4a, SND1_B_battle1_end_reward.m4a,
rem      SND1_C_battle2_end_reward.m4a. Each at most 240 s, under 10 MB, loudest moment at least -60 dB (lines from
rem      board/1238/pc/shots1238b_sound.bat).
rem   5. only after all three clips pass: deletes its own recording (seed-10.avi) and the review mp4s run.ps1 made, so no
rem      full video is kept (the three small clip mp4s stay). Nothing else is deleted; the head's tail removes its own pinned checkout on a PASS (R326).
rem The route has no shipyard stop; the shipyard's sound is covered by the headless audio_check.gd only.
rem Results: Downloads\voidsworn_test\opus1448g\out_<stamp>_<n>\out_new\clips\. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1448g"
set "LABEL=1448"
set "TOOLS=godot"
set "PIN_NEW=1cc09be0e6015d6fb6e3480d8264f7fc85c61e7d"
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

rem ---- 4. the player path from that export: route seed 10 only, Battles 1 to 3 (the recorder makes its own
rem      fresh profile per run, so PC_REAL_PROFILE is on for this step only, as player_path.bat sets it)
set "PC_REAL_PROFILE=1"
set "JW_STEP=%1 player path" & set "JW_EXPECT=%O%\player_path" & call "%JW%" run 7200 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\codex\player_path_1119\run.ps1" -Install "%E%" -Full "%O%\player_path" -Seeds 10 > "%O%\player_path_console.txt" 2>&1
set "PC_REAL_PROFILE="
if defined JW_STOP exit /b 0
rem ---- ffmpeg: FFMPEG_EXE, else Downloads\voidsworn_test\ffmpeg\bin, else the trellis2 venv's imageio_ffmpeg binary
set "FF=%FFMPEG_EXE%"
if not defined FF if exist "%VT%\ffmpeg\bin\ffmpeg.exe" set "FF=%VT%\ffmpeg\bin\ffmpeg.exe"
if not defined FF for /r "%USERPROFILE%\Downloads\trellis2\code\venv" %%X in (ffmpeg*.exe) do if not defined FF set "FF=%%X"
if not defined FF (call "%JW%" fail "%1 no ffmpeg found for the sound clips" & exit /b 1)
>> "%OJ_ST%" echo ffmpeg %FF%
set "AVI=%O%\player_path\seed-10.avi"
set "TR=%O%\player_path\seed-10.jsonl"
if not exist "%AVI%" (call "%JW%" fail "%1 no seed-10.avi from run.ps1, see player_path_console.txt" & exit /b 1)
call :clips %1
exit /b 0

rem ---- :clips NAME: three sound clips at the recorder's frame marks (30 frames a second), checked, then the recording goes
:clips
set "C=%O%\clips"
if not exist "%C%" mkdir "%C%"
powershell -NoProfile -Command "$ic = [Globalization.CultureInfo]::InvariantCulture; $e = @(Get-Content -LiteralPath '%TR%' | Where-Object { $_.Trim() } | ForEach-Object { ConvertFrom-Json $_ }); $f = { param($k, $b) ($e | Where-Object { $_.kind -eq $k -and $_.battle -eq $b } | Select-Object -First 1).frame }; $s1 = & $f 'battle_start' 1; $c1 = & $f 'end_card' 1; $s2 = & $f 'battle_start' 2; $c2 = & $f 'end_card' 2; $s3 = & $f 'battle_start' 3; if ($null -in @($s1, $c1, $s2, $c2, $s3)) { 'MISSING'; exit 1 }; $cut = { param($a, $b) $st = [Math]::Max(0.0, $a / 30.0); $d = [Math]::Min(240.0, $b / 30.0 - $st); [string]::Format($ic, '{0:F2} {1:F2}', $st, $d) }; (& $cut 0 ($s1 + 60)) + ' ' + (& $cut ($c1 - 300) ($s2 + 60)) + ' ' + (& $cut ($c2 - 300) ($s3 + 60))" > "%O%\cuts.txt" 2>&1
if errorlevel 1 (call "%JW%" fail "%1 clips: the recorder's frame marks are missing, see cuts.txt" & exit /b 1)
set "CBAD="
for /f "usebackq tokens=1-6" %%a in ("%O%\cuts.txt") do (
  call :clip SND1_A_title_map %%a %%b
  call :clip SND1_B_battle1_end_reward %%c %%d
  call :clip SND1_C_battle2_end_reward %%e %%f
)
if not exist "%C%\SND1_C_battle2_end_reward.mp4" set "CBAD=1"
if defined CBAD (call "%JW%" fail "%1 clips: see the status lines above; the recording is kept" & exit /b 1)
rem ---- all three clips passed: delete this job's own recording and run.ps1's review mp4s (RULEBOOK 3.3, R326)
del /q "%AVI%"
if exist "%O%\player_path\review" del /q /s "%O%\player_path\review\*.mp4" > nul 2>&1
>> "%OJ_ST%" echo %1 clips PASS: %C%; own recording and review mp4s deleted
exit /b 0

rem ---- :clip FILE START SECONDS: one sound-only clip, under 10 MB, loudest moment at least -60 dB; sets CBAD on a miss
:clip
"%FF%" -hide_banner -y -ss %2 -t %3 -i "%AVI%" -vn -c:a aac -b:a 160k "%C%\%1.m4a" > "%C%\%1_encode.txt" 2>&1
if errorlevel 1 (>> "%OJ_ST%" echo FAILED: %1 encode, see %1_encode.txt & set "CBAD=1" & exit /b 0)
for %%Z in ("%C%\%1.m4a") do set "SZ=%%~zZ"
if %SZ% GEQ 10000000 (>> "%OJ_ST%" echo FAILED: %1 is %SZ% bytes, not under 10 MB & set "CBAD=1" & exit /b 0)
"%FF%" -hide_banner -nostats -i "%C%\%1.m4a" -af volumedetect -f null - > "%C%\%1_volume.txt" 2>&1
set "MAXDB="
for /f "tokens=2 delims=:" %%A in ('findstr /c:"max_volume" "%C%\%1_volume.txt"') do set "MAXDB=%%A"
for /f "tokens=1" %%A in ("%MAXDB%") do set "MAXDB=%%A"
if not defined MAXDB (>> "%OJ_ST%" echo FAILED: %1 SOUND CHECK, no audio level read & set "CBAD=1" & exit /b 0)
powershell -NoProfile -Command "if ([double]'%MAXDB%' -lt -60) { exit 1 } else { exit 0 }"
if errorlevel 1 (>> "%OJ_ST%" echo FAILED: %1 SOUND CHECK, loudest moment %MAXDB% dB is under -60 dB & set "CBAD=1" & exit /b 0)
>> "%OJ_ST%" echo SOUND CHECK PASS: %1 from %2 s for %3 s, %SZ% bytes, loudest %MAXDB% dB
rem the same cut as a small picture-and-sound mp4 (960x540, capped bit rate), under 10 MB
"%FF%" -hide_banner -y -ss %2 -t %3 -i "%AVI%" -vf scale=960:540 -c:v libx264 -preset veryfast -crf 28 -maxrate 2200k -bufsize 4400k -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "%C%\%1.mp4" > "%C%\%1_video_encode.txt" 2>&1
if errorlevel 1 (>> "%OJ_ST%" echo FAILED: %1 video encode, see %1_video_encode.txt & set "CBAD=1" & exit /b 0)
for %%Z in ("%C%\%1.mp4") do set "VSZ=%%~zZ"
if %VSZ% GEQ 10000000 (>> "%OJ_ST%" echo FAILED: %1.mp4 is %VSZ% bytes, not under 10 MB & del /q "%C%\%1.mp4" & set "CBAD=1" & exit /b 0)
>> "%OJ_ST%" echo VIDEO PASS: %1.mp4 960x540 with sound, %VSZ% bytes
exit /b 0
