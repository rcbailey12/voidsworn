@echo off
rem Issue 1238 run 2: re-shoot the clips WITH SOUND, after (1dcd6cf2, the PR 1243 merge, pinned) and before (main 41858aba, just
rem before that merge, 1dcd6cf2^1), so Ryan gets an audible before/after. Run 1's AVIs were digital silence: the bench's
rem death cues played in a world with no listener; fixed on branch opus/issue-1238-sound (bench/look_bench.gd), whose
rem bench script and rows are used for both runs.
rem Each attempt writes to its own new folder (shots\run_<stamp>\), so a retry never measures an older clip.
rem For each clip: measures the sound and FAILS if the loudest moment is under -60 dB, then makes a 720p mp4.
rem The job exits 1 unless the import, both captures, both profile hash checks, both sound checks and both encodes pass.
rem Its own clone in Downloads\voidsworn_test\opus1238b; hulls copied in from build\godot (else audit2), copy only.
rem Godot runs use a throwaway profile; your real settings are hashed before and after. Nothing on the PC is deleted.
rem Godot runs go through the installed tools_live tmo.bat (GPU slot), never the clone's own copy.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1238b"
set "R=%H%\repo"
set "BR=opus/issue-1238-sound"
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%S"
set "RUN=%H%\shots\run_%STAMP%"
if exist "%RUN%" (
  echo FAILED: run folder %RUN% already exists
  exit /b 1
)
mkdir "%RUN%"
set "ST=%RUN%\status.txt"
set "BAD="
echo shots1238b start %date% %time% run_%STAMP% > "%ST%"
rem Built ships: the shared PC build (build\godot), else the old audit2 checkout. LB_SHIPS overrides both (issue 1223).
if "%LB_SHIPS%"=="" if exist "%VT%\build\godot\gen" set "LB_SHIPS=%VT%\build\godot"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
rem The installed main watchdog in tools_live (fail closed when it is missing).
set "TMO="
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not defined TMO (
  echo FAILED: no tools_live tmo.bat, tools_live\current.txt = %TLV% >> "%ST%"
  goto fail
)
echo watchdog %TMO% >> "%ST%"
rem ffmpeg: FFMPEG_EXE, else Downloads\voidsworn_test\ffmpeg\bin, else the trellis2 venv's imageio_ffmpeg binary.
set "FF=%FFMPEG_EXE%"
if not defined FF if exist "%VT%\ffmpeg\bin\ffmpeg.exe" set "FF=%VT%\ffmpeg\bin\ffmpeg.exe"
if not defined FF for /r "%USERPROFILE%\Downloads\trellis2\code\venv" %%X in (ffmpeg*.exe) do if not defined FF set "FF=%%X"
if not defined FF (
  echo FAILED: no ffmpeg found for the sound check >> "%ST%"
  goto fail
)
echo ffmpeg %FF% >> "%ST%"
if not exist "%H%\bench" mkdir "%H%\bench"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%RUN%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: git fetch, see %RUN%\git.txt >> "%ST%"
  goto fail
)
for %%F in (look_bench.gd look_bench.tscn look_moments_1238_clip.json) do (
  git -C "%R%" show origin/%BR%:godot/bench/%%F > "%H%\bench\%%F"
  if errorlevel 1 (
    echo FAILED: no godot/bench/%%F on %BR% >> "%ST%"
    goto fail
  )
)
git -C "%R%" rev-parse origin/%BR% > "%RUN%\bench_commit.txt"
call :one after 1dcd6cf227896d9745622dec6960893ac2795fee
call :one before 41858aba3bda701f33890185c84aea9d9276fbb7
if defined BAD goto fail
echo ALL PASS: both clips have sound >> "%ST%"
echo shots1238b done %date% %time% >> "%ST%"
type "%ST%"
start "" "%RUN%"
exit /b 0
:fail
echo shots1238b FAILED %date% %time% >> "%ST%"
type "%ST%"
start "" "%RUN%"
exit /b 1

rem ---- :one NAME REF: one clip with sound; sets BAD on any failure
:one
set "NAME=%~1"
set "REF=%~2"
set "O=%RUN%\%NAME%"
mkdir "%O%"
git -C "%R%" checkout -f --detach %REF% >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: %NAME% cannot check out %REF% >> "%ST%"
  set "BAD=1"
  exit /b 1
)
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
set /p SHA=<"%O%\commit.txt"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
for %%F in (look_bench.gd look_bench.tscn look_moments_1238_clip.json) do copy /y "%H%\bench\%%F" "%R%\godot\bench\%%F" > nul
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 (
  echo FAILED: %NAME% import, see %O%\import.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
set "AVI=%O%\D1238_%NAME%_deaths_with_sound.avi"
set "P=%RUN%\profile_%NAME%"
mkdir "%P%"
call :hashes "%O%\real_before.txt"
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
set "VS_CAPTURE_PROFILE=%P%"
mkdir "%O%\clip"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%AVI%" res://bench/look_bench.tscn -- --out "%O%\clip" --part moments --no-warm --commit %SHA% --moments res://bench/look_moments_1238_clip.json --sound > "%O%\log_clip.txt" 2>&1
set "CAPEL=%errorlevel%"
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "VS_CAPTURE_PROFILE="
call :hashes "%O%\real_after.txt"
fc /b "%O%\real_before.txt" "%O%\real_after.txt" > nul
if errorlevel 1 (
  echo FAILED: %NAME% your own settings changed during the capture >> "%ST%"
  set "BAD=1"
) else (
  echo own settings untouched: %NAME% >> "%ST%"
)
if not "%CAPEL%"=="0" (
  echo FAILED: %NAME% capture exit %CAPEL%, see %O%\log_clip.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
findstr /c:"LOOK_BENCH_DONE" "%O%\log_clip.txt" > nul
if errorlevel 1 (
  echo FAILED: %NAME% capture did not finish, see %O%\log_clip.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
if not exist "%AVI%" (
  echo FAILED: %NAME% no clip file >> "%ST%"
  set "BAD=1"
  exit /b 1
)
rem the sound check: the loudest moment must be at least -60 dB (run 1 was -91 dB, digital silence)
"%FF%" -hide_banner -nostats -i "%AVI%" -vn -af volumedetect -f null - > "%O%\volume.txt" 2>&1
set "MAXDB="
for /f "tokens=2 delims=:" %%A in ('findstr /c:"max_volume" "%O%\volume.txt"') do set "MAXDB=%%A"
for /f "tokens=1" %%A in ("!MAXDB!") do set "MAXDB=%%A"
if not defined MAXDB (
  echo FAILED: %NAME% SOUND CHECK, no audio level read, see %O%\volume.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
powershell -NoProfile -Command "if ([double]'!MAXDB!' -lt -60) { exit 1 } else { exit 0 }"
if errorlevel 1 (
  echo FAILED: %NAME% SOUND CHECK, loudest moment !MAXDB! dB is under -60 dB >> "%ST%"
  set "BAD=1"
  exit /b 1
)
echo SOUND CHECK PASS: %NAME% loudest moment !MAXDB! dB >> "%ST%"
rem a 720p mp4 for relaying (the AVI stays as the source)
"%FF%" -hide_banner -y -i "%AVI%" -vf scale=-2:720 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 160k "%O%\D1238_%NAME%_deaths_with_sound_720p.mp4" > "%O%\encode.txt" 2>&1
if errorlevel 1 (
  echo FAILED: %NAME% mp4 encode, see %O%\encode.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
echo mp4 done: %NAME% D1238_%NAME%_deaths_with_sound_720p.mp4 >> "%ST%"
exit /b 0

rem ---- :hashes FILE: hashes of the real profile's options, settings and look files (missing files listed as missing)
:hashes
set "U=%APPDATA%\Godot\app_userdata\Voidsworn"
> "%~1" echo real profile %U%
for %%F in (battle_opts.json settings.json board_look.cfg voidsworn_career.json voidsworn_campaign.json) do (
  if exist "%U%\%%F" (certutil -hashfile "%U%\%%F" SHA256 | findstr /v /c:"CertUtil" >> "%~1") else (echo %%F missing >> "%~1")
)
exit /b 0
