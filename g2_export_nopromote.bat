@echo off
rem PT1120C copy of tools/pc/jobs/g2_export.bat at 3baef93628129a796460fc7784737104ca88a828 up to and including the bot smoke, with NO promotion (Board, Nov 20 17:25 UTC).
rem LOG and the smoke report go to %PT_SHOTS%. On success it writes the candidate folder to %PT_SHOTS%\candidate.txt and exits 0.
rem Windows build of Voidsworn (Godot): writes build\export\Voidsworn.exe (+ Voidsworn.pck) and a log.
rem Queue job from Downloads\voidsworn_test\build. Downloads the Godot export templates once (about 1 GB) if missing.
rem After this, play_godot.bat runs the exported game.
rem Build and check a separate candidate before replacing the whole live export folder.
rem Optional first argument: the project folder (default godot).
setlocal EnableExtensions DisableDelayedExpansion
set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "TMO=%ROOT%tools\pc\tmo.bat"
set "LOG=%PT_SHOTS%\export_log.txt"
set "PROJ=%ROOT%godot"
if not "%~1"=="" set "PROJ=%ROOT%%~1"
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable"
echo export %date% %time% from %PROJ% > "%LOG%"
if not exist "%TPL%\windows_release_x86_64.exe" (
  echo downloading export templates >> "%LOG%"
  powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; $t=Join-Path $env:TEMP 'gd_tpl.zip'; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz' -OutFile $t; $x=Join-Path $env:TEMP 'gd_tpl'; if(Test-Path $x){Remove-Item -Recurse -Force $x}; Expand-Archive -Path $t -DestinationPath $x -Force; New-Item -ItemType Directory -Force -Path '%TPL%' | Out-Null; Copy-Item -Force (Join-Path $x 'templates\*') '%TPL%'; Remove-Item $t" >> "%LOG%" 2>&1
)
if not exist "%TPL%\windows_release_x86_64.exe" (
  echo FAIL: no export templates in %TPL% >> "%LOG%"
  exit /b 1
)
if not exist "%PROJ%\gen\v3.txt" (
  call "%TMO%" 900 "%G%" --headless --path "%PROJ%" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%ROOT%..\enginetest\assets\hi" --env "%ROOT%..\enginetest\assets\env" --max-seconds 600 >> "%LOG%" 2>&1
  if errorlevel 1 goto failed
)
echo importing >> "%LOG%"
call "%TMO%" 1800 "%G%" --headless --path "%PROJ%" --import >> "%LOG%" 2>&1
if errorlevel 1 goto failed
set "BUILD_ID="
for /f %%I in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString()"') do set "BUILD_ID=%%I"
if not defined BUILD_ID goto failed
set "LIVE_EXPORT=%ROOT%export"
set "CANDIDATE_EXPORT=%ROOT%export-candidate-%BUILD_ID%"
set "BACKUP_EXPORT=%ROOT%export-previous-%BUILD_ID%"
mkdir "%CANDIDATE_EXPORT%" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
echo exporting >> "%LOG%"
set "PC_GODOT_EXPORT_TEMPLATES=%TPL%"
call "%TMO%" 1800 "%G%" --headless --path "%PROJ%" --export-release "Windows Desktop" "%CANDIDATE_EXPORT%\Voidsworn.exe" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
for %%F in (Voidsworn.exe Voidsworn.console.exe Voidsworn.pck) do if not exist "%CANDIDATE_EXPORT%\%%F" goto failed
rem what is in the package: no test folders, the real campaign UI, fx, story and music player
call "%TMO%" 300 "%CANDIDATE_EXPORT%\Voidsworn.console.exe" --headless -- --check-export >> "%LOG%" 2>&1
if errorlevel 1 goto failed
rem a quick headless smoke of the exported build: 2 bot battles
call "%TMO%" 900 "%CANDIDATE_EXPORT%\Voidsworn.console.exe" --headless -- --bot-runs 2 --fast 40 --report "%PT_SHOTS%\smoke.json" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
echo %CANDIDATE_EXPORT%> "%PT_SHOTS%\candidate.txt"
echo OK: candidate %CANDIDATE_EXPORT% (not promoted) >> "%LOG%"
exit /b 0

:failed
echo FAIL: an export or check step failed (see above); nothing promoted. >> "%LOG%"
exit /b 1
