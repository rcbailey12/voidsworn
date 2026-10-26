@echo off
rem Windows build of Voidsworn (Godot): writes build\export\Voidsworn.exe (+ Voidsworn.pck) and a log.
rem Queue job from Downloads\voidsworn_test\build. Downloads the Godot export templates once (about 1 GB) if missing.
rem After this, play_godot.bat runs the exported game.
setlocal
set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "TMO=%ROOT%tools\pc\tmo.bat"
set "LOG=%ROOT%..\shots\g2_export_log.txt"
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable"
echo export %date% %time% > "%LOG%"
if not exist "%TPL%\windows_release_x86_64.exe" (
  echo downloading export templates >> "%LOG%"
  powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; $t=Join-Path $env:TEMP 'gd_tpl.zip'; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz' -OutFile $t; $x=Join-Path $env:TEMP 'gd_tpl'; if(Test-Path $x){Remove-Item -Recurse -Force $x}; Expand-Archive -Path $t -DestinationPath $x -Force; New-Item -ItemType Directory -Force -Path '%TPL%' | Out-Null; Copy-Item -Force (Join-Path $x 'templates\*') '%TPL%'; Remove-Item $t" >> "%LOG%" 2>&1
)
if not exist "%TPL%\windows_release_x86_64.exe" (
  echo FAIL: no export templates in %TPL% >> "%LOG%"
  exit /b 1
)
if not exist "%ROOT%godot\gen\v3.txt" call "%TMO%" 900 "%G%" --headless --path "%ROOT%godot" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%ROOT%..\enginetest\assets\hi" --env "%ROOT%..\enginetest\assets\env" --max-seconds 600 >> "%LOG%" 2>&1
echo importing >> "%LOG%"
call "%TMO%" 1800 "%G%" --headless --path "%ROOT%godot" --import >> "%LOG%" 2>&1
if not exist "%ROOT%export" mkdir "%ROOT%export"
echo exporting >> "%LOG%"
call "%TMO%" 1800 "%G%" --headless --path "%ROOT%godot" --export-release "Windows Desktop" "%ROOT%export\Voidsworn.exe" >> "%LOG%" 2>&1
if exist "%ROOT%export\Voidsworn.exe" (echo OK: %ROOT%export\Voidsworn.exe >> "%LOG%") else (echo FAIL: no exe >> "%LOG%")
rem what is in the package: no test folders, the real campaign UI, fx, story and music player
call "%TMO%" 300 "%ROOT%export\Voidsworn.console.exe" --headless -- --check-export >> "%LOG%" 2>&1
rem a quick headless smoke of the exported build: 2 bot battles
call "%TMO%" 900 "%ROOT%export\Voidsworn.console.exe" --headless -- --bot-runs 2 --fast 40 --report "%ROOT%..\shots\g2_export_smoke.json" >> "%LOG%" 2>&1
exit /b 0
