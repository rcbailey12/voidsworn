@echo off
rem Windows build of Voidsworn (Godot): writes build\export\Voidsworn.exe (+ Voidsworn.pck) and a log.
rem Queue job from Downloads\voidsworn_test\build. Downloads the Godot export templates once (about 1 GB) if missing.
rem After this, play_godot.bat runs the exported game.
rem Build and check a separate candidate before replacing the whole live export folder.
rem Optional first argument: the project folder (default godot).
setlocal EnableExtensions DisableDelayedExpansion
set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "TMO=%ROOT%tools\pc\tmo.bat"
set "LOG=%ROOT%..\shots\g2_export_log.txt"
set "PROJ=%ROOT%godot"
if not "%~1"=="" set "PROJ=%ROOT%%~1"
rem Issue 1663: the overnight export passes its checkout's full path (C:\...).
set "G2_ARG=%~1"
if defined G2_ARG if "%G2_ARG:~1,1%"==":" set "PROJ=%~f1"
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
rem a quick headless smoke of the exported build: 2 bot battles. Its exit code alone is not proof (issue 1365, Nov 20:
rem a parse error ran no battle, exited 0, and the previous run's report was still on disk), so the report must be new
rem and show 2 runs with no errors or softlocks, and the smoke output must hold no script or parse error.
rem The report and output are named by this candidate's id, so a second export at the same time never shares them;
rem the gate reads only these, and the fixed-name copies after it are for people.
set "SHOTS=%ROOT%..\shots"
set "SMOKE_REPORT=%SHOTS%\g2_export_smoke_%BUILD_ID%.json"
set "SMOKE_OUT=%SHOTS%\g2_export_smoke_output_%BUILD_ID%.txt"
set "SMOKE_OK=0"
set "SMOKE_START="
for /f %%T in ('powershell -NoProfile -Command "[DateTime]::UtcNow.Ticks"') do set "SMOKE_START=%%T"
if not defined SMOKE_START goto failed
call "%TMO%" 900 "%CANDIDATE_EXPORT%\Voidsworn.console.exe" --headless -- --bot-runs 2 --fast 40 --report "%SMOKE_REPORT%" > "%SMOKE_OUT%" 2>&1
set "SMOKE_RC=%ERRORLEVEL%"
type "%SMOKE_OUT%" >> "%LOG%"
if not "%SMOKE_RC%"=="0" goto smoke_done
powershell -NoProfile -Command ^
  "$r = $env:SMOKE_REPORT; $f = Get-Item -LiteralPath $r -ErrorAction SilentlyContinue;" ^
  "if (-not $f) { Write-Output 'FAIL: the smoke wrote no report'; exit 1 };" ^
  "if ($f.LastWriteTimeUtc.Ticks -lt [long]$env:SMOKE_START) { Write-Output 'FAIL: the smoke report is older than this run'; exit 1 };" ^
  "try { $j = Get-Content -LiteralPath $r -Raw | ConvertFrom-Json } catch { Write-Output 'FAIL: the smoke report is not JSON'; exit 1 };" ^
  "$runs = @($j.runs).Count; if ($runs -ne 2 -or $j.errors -ne 0 -or $j.softlocks -ne 0) { Write-Output ('FAIL: smoke report has {0} runs, {1} errors, {2} softlocks (want 2, 0, 0)' -f $runs, $j.errors, $j.softlocks); exit 1 };" ^
  "$bad = @(Select-String -LiteralPath $env:SMOKE_OUT -Pattern 'SCRIPT ERROR','Parse Error' -SimpleMatch);" ^
  "if ($bad.Count) { Write-Output ('FAIL: smoke output has a script error: ' + $bad[0].Line.Trim()); exit 1 };" ^
  "Write-Output 'smoke report checked: 2 runs, 0 errors, 0 softlocks, no script errors'" >> "%LOG%" 2>&1
if not errorlevel 1 set "SMOKE_OK=1"
:smoke_done
rem the latest smoke under fixed names for people (no report this run: the old copy goes, so none is mistaken for it)
if exist "%SMOKE_REPORT%" (move /y "%SMOKE_REPORT%" "%SHOTS%\g2_export_smoke.json" >nul) else (if exist "%SHOTS%\g2_export_smoke.json" del /f /q "%SHOTS%\g2_export_smoke.json")
if exist "%SMOKE_OUT%" move /y "%SMOKE_OUT%" "%SHOTS%\g2_export_smoke_output.txt" >nul
if not "%SMOKE_OK%"=="1" goto failed
rem Issue 1663: the overnight export never replaces the live folder while the game runs (Ryan playing it).
if not "%G2_PROMOTE_ONLY_IDLE%"=="1" goto promote
tasklist /fo csv /nh 2>nul | findstr /i /c:"\"Voidsworn.exe\"" /c:"\"Voidsworn.console.exe\"" >nul
if not errorlevel 1 (echo FAIL: Voidsworn is running, so the live export was not replaced; the candidate stays in %CANDIDATE_EXPORT% >> "%LOG%" & exit /b 1)
:promote
rem Keep the old folder intact. Roll it back if the second same-volume move fails.
powershell -NoProfile -Command ^
  "$ErrorActionPreference = 'Stop'; $live = $env:LIVE_EXPORT; $backup = $env:BACKUP_EXPORT; $saved = $false;" ^
  "$lock = [IO.File]::Open(($live + '-promote.lock'), 'OpenOrCreate', 'ReadWrite', 'None');" ^
  "try { if ([IO.Directory]::Exists($live)) { [IO.Directory]::Move($live, $backup); $saved = $true };" ^
  "      try { [IO.Directory]::Move($env:CANDIDATE_EXPORT, $live) } catch { if ($saved) { [IO.Directory]::Move($backup, $live) }; throw }" ^
  "} finally { $lock.Dispose() }" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
echo OK: %LIVE_EXPORT%\Voidsworn.exe >> "%LOG%"
exit /b 0

:failed
echo FAIL: an export, check or promotion step failed (see above); no candidate was published. >> "%LOG%"
exit /b 1
