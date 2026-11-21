@echo off
rem Issue 1448 SND-1, bat C (PR 1478): replaces OPUS1448_SND1B.bat, which failed on Nov 21 at "jump to 0-0 did not open"
rem (the first map load, built in a background thread, can miss the first jump; run.ps1 retries that once). Same steps,
rem pinned to PR 1478's head c102aec6 (main merged), plus that one retry. A cloud run of the route on c102aec6 (headless)
rem reached all three battle ends.
rem what the sound wiring sounds like in the real exported game. Built from
rem tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303). One pinned commit, the PR head.
rem Steps:
rem   1. checkout, ships, import; build_info.json for the recorder; the Windows release export into the attempt folder
rem      (export lines copied from board/1439/pc/OPUS1439_MEASURE3.bat).
rem   2. the player-path recorder (main/player_path.gd) plays route seed 10 in the exported game: title, sector map, the
rem      reward dialogs and three battle ends. Godot Movie Maker records it with its sound (launch line and fresh profile
rem      copied from contrib/codex/player_path_1119/run.ps1, the known-good player_path.bat route). One retry, only for that first-jump timeout.
rem   3. three sound clips cut from the recording at the recorder's own frame marks, sound only (no video kept):
rem      SND1_A_title_map.m4a (title, setup, map, first jump), SND1_B_battle1_end_reward.m4a (Battle 1's end sound, the
rem      reward dialogs, the map), SND1_C_battle2_end_reward.m4a (the same after Battle 2). Each at most 240 s, must be
rem      under 10 MB and pass the sound check (loudest moment at least -60 dB, lines copied from
rem      board/1238/pc/shots1238b_sound.bat).
rem   4. only after all three clips pass: deletes its own recording (the .avi) and its own recorder profiles under %TEMP%.
rem      Nothing else is deleted; the head's tail removes its own pinned checkout on a PASS (R326).
rem The route has no shipyard stop; the shipyard's sound is covered by the headless audio_check.gd only.
rem Results: Downloads\voidsworn_test\opus1448\out_<stamp>_<n>\out_new\clips\. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1448"
set "LABEL=1448"
set "TOOLS=godot"
set "PIN_NEW=c102aec653590ca83f6256d9844b15d99b2c5b2f"
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
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0
rem ---- the recorder plays only a build exported from a clean commit (player_path.gd reads res://build_info.json)
echo {"commit": "%2"} > "%OJ_REPO%\godot\build_info.json"
rem ---- the release export, as g2_export.bat makes it, into this attempt folder (the live build\export is not touched)
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable"
if not exist "%TPL%\windows_release_x86_64.exe" (call "%JW%" fail "%1 export: no export templates in %TPL%" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%TPL%"
set "EXP=%O%\export"
if not exist "%EXP%" mkdir "%EXP%"
set "JW_STEP=%1 export" & set "JW_EXPECT=%EXP%\Voidsworn.pck" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%EXP%\Voidsworn.exe" > "%O%\export.txt" 2>&1
set "PC_GODOT_EXPORT_TEMPLATES="
if defined JW_STOP exit /b 0
rem ---- ffmpeg: FFMPEG_EXE, else Downloads\voidsworn_test\ffmpeg\bin, else the trellis2 venv's imageio_ffmpeg binary
set "FF=%FFMPEG_EXE%"
if not defined FF if exist "%VT%\ffmpeg\bin\ffmpeg.exe" set "FF=%VT%\ffmpeg\bin\ffmpeg.exe"
if not defined FF for /r "%USERPROFILE%\Downloads\trellis2\code\venv" %%X in (ffmpeg*.exe) do if not defined FF set "FF=%%X"
if not defined FF (call "%JW%" fail "%1 no ffmpeg found for the sound clips" & exit /b 1)
>> "%OJ_ST%" echo ffmpeg %FF%
set "AVI=%O%\SND1_route10.avi"
set "TR=%O%\SND1_route10.jsonl"
rem attempt 1 is optional only so its first-jump timeout can be retried; any other failure fails the job below
set "JW_OPTIONAL=1"
call :record %1 1
set "TRY="
findstr /c:"jump to 0-0 did not open" "%TR%" > nul 2>&1
if not errorlevel 1 set "TRY=2"
if defined TRY >> "%OJ_ST%" echo %1 record: the first map jump timed out before Battle 1, one retry as run.ps1 does
if defined TRY if exist "%AVI%" del /q "%AVI%"
if defined TRY move /y "%TR%" "%O%\SND1_route10_attempt1.jsonl" > nul
if defined TRY call :record %1 2
if not defined TRY if not "%REC_RC%"=="0" call "%JW%" fail "%1 record 1: exit %REC_RC%, see record_1.txt and game_1.log"
if defined JW_STOP exit /b 0
call :clips %1
exit /b 0

rem ---- :record NAME ATTEMPT: the exported game under the watchdog, in a fresh recorder profile under %TEMP%
:record
for /f %%G in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString()"') do set "PPG=%%G"
set "PPT=%TEMP%\voidsworn-player-path-%PPG%"
set "PPP=%PPT%\profile"
mkdir "%PPP%"
>> "%OJ_ST%" echo %1 record attempt %2: profile %PPP%
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
for /f "delims==" %%V in ('set VS_ 2^>nul') do set "%%V="
set "PC_REAL_PROFILE=1"
set "APPDATA=%PPP%"
set "LOCALAPPDATA=%PPP%"
set "VS_PLAYER_PATH_PROFILE=%PPP%"
set "PC_GPU_MODE=shared"
set "PC_GPU_WEIGHT=1"
set "REC_RC=0"
set "JW_STEP=%1 record %2" & set "JW_EXPECT=%AVI%;%TR%" & call "%JW%" run 2400 "%EXP%\Voidsworn.console.exe" --log-file "%O%\game_%2.log" --resolution 1920x1080 --windowed --disable-vsync --fixed-fps 30 --write-movie "%AVI%" -- --player-path "%TR%" --player-path-seed 10 > "%O%\record_%2.txt" 2>&1
set "REC_RC=%ERRORLEVEL%"
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "PC_REAL_PROFILE="
set "VS_PLAYER_PATH_PROFILE="
set "PC_GPU_MODE="
set "PC_GPU_WEIGHT="
set "PPT_%2=%PPT%"
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
if not exist "%C%\SND1_C_battle2_end_reward.m4a" set "CBAD=1"
if defined CBAD (call "%JW%" fail "%1 clips: see the status lines above; the recording is kept" & exit /b 1)
rem ---- all three clips passed: delete this job's own recording and recorder profiles (RULEBOOK 3.3, R326)
del /q "%AVI%"
if defined PPT_1 if exist "%PPT_1%" rmdir /s /q "%PPT_1%"
if defined PPT_2 if exist "%PPT_2%" rmdir /s /q "%PPT_2%"
>> "%OJ_ST%" echo %1 clips PASS: %C%; own recording and recorder profiles deleted
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
exit /b 0
