@echo off
rem get_ship_files.bat: put the built ship files a capture job needs into this checkout, then check them.
rem The real ship files (godot\gen and godot\assets\ships) live only on Ryan's PC, so a fresh clone draws every ship as a
rem placeholder block. This step copies them from a named source folder (copy only, never delete), verifies every file
rem against the sha256 values in godot\assets\ships\manifest.json, and exits non-zero when a file is missing or wrong.
rem
rem Usage: get_ship_files.bat [source folder] [repo folder] [task file]
rem   source folder  holds gen\ and assets\ships\ (default: %%USERPROFILE%%\Downloads\voidsworn_test\build\godot)
rem   repo folder    the checkout to fill (default: the repo this script sits in, ..\..)
rem   task file      optional: a line saying where the hulls came from is appended to it
rem
rem Exit: 0 all copied and every manifest file matches; 1 a file is missing or wrong; 2 the source has no gen or
rem       assets\ships; 3 the copy failed.
setlocal EnableExtensions
set "SRC=%~1"
if not defined SRC set "SRC=%USERPROFILE%\Downloads\voidsworn_test\build\godot"
set "REPO=%~2"
if not defined REPO set "REPO=%~dp0..\.."
set "TASK=%~3"
set "DEST=%REPO%\godot"
set "PS1=%TEMP%\voidsworn_get_ship_files_%RANDOM%%RANDOM%.ps1"

echo SHIP_FILES source: %SRC%
echo SHIP_FILES repo:   %REPO%
if not exist "%SRC%\gen\manifest.json" goto :nosource
if not exist "%SRC%\assets\ships\" goto :nosource

rem Copy only. Never /MIR or /PURGE: a short source must never delete files already on this PC.
robocopy "%SRC%\gen" "%DEST%\gen" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 goto :copyfail
robocopy "%SRC%\assets\ships" "%DEST%\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 goto :copyfail

rem Verify every shipped file in the tracked manifest. A missing or wrong file is listed, and the exit is non-zero.
if not exist "%DEST%\assets\ships\manifest.json" goto :nomanifest
> "%PS1%" echo $ErrorActionPreference = 'Stop'
>> "%PS1%" echo $root = $args[0]
>> "%PS1%" echo $manPath = Join-Path $root 'assets\ships\manifest.json'
>> "%PS1%" echo $raw = Get-Content -Raw -LiteralPath $manPath
>> "%PS1%" echo $man = ConvertFrom-Json -InputObject $raw
>> "%PS1%" echo $count = 0
>> "%PS1%" echo $bad = @()
>> "%PS1%" echo foreach ($p in $man.ships.PSObject.Properties) {
>> "%PS1%" echo   $code = $p.Name
>> "%PS1%" echo   foreach ($fp in $p.Value.files.PSObject.Properties) {
>> "%PS1%" echo     $name = $fp.Name
>> "%PS1%" echo     $path = Join-Path (Join-Path (Join-Path $root 'assets\ships') $code) $name
>> "%PS1%" echo     $count = $count + 1
>> "%PS1%" echo     if (-not (Test-Path -LiteralPath $path)) { $bad += ('missing ' + $code + '/' + $name); continue }
>> "%PS1%" echo     $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
>> "%PS1%" echo     if ($h -ne ([string]$fp.Value.sha256).ToLower()) { $bad += ('wrong ' + $code + '/' + $name + ' ' + $h) }
>> "%PS1%" echo   }
>> "%PS1%" echo }
>> "%PS1%" echo if ($bad.Count -gt 0) {
>> "%PS1%" echo   Write-Host ('SHIP_FILES: ' + $bad.Count + ' of ' + $count + ' files do not match the manifest')
>> "%PS1%" echo   foreach ($b in $bad) { Write-Host ('MISMATCH ' + $b) }
>> "%PS1%" echo   exit 1
>> "%PS1%" echo }
>> "%PS1%" echo Write-Host ('SHIP_FILES OK: ' + $count + ' files match godot/assets/ships/manifest.json')
>> "%PS1%" echo exit 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%DEST%"
set "VC=%ERRORLEVEL%"
del /q "%PS1%" >nul 2>&1
if not "%VC%"=="0" goto :verifyfail

call :tasknote "Ship files: copied from %SRC% and checked against godot/assets/ships/manifest.json."
exit /b 0

:nosource
echo SHIP_FILES: source folder has no gen\manifest.json or assets\ships: %SRC%
call :tasknote "Ship files: NOT copied (%SRC% has no gen or assets\ships); capture scripts will stop with placeholder hull."
exit /b 2

:copyfail
echo SHIP_FILES: copy failed from %SRC% to %DEST%
call :tasknote "Ship files: the copy from %SRC% failed; capture scripts may stop with placeholder hull."
exit /b 3

:nomanifest
echo SHIP_FILES: missing %DEST%\assets\ships\manifest.json
call :tasknote "Ship files: copied from %SRC% but the manifest is missing; capture scripts will stop with placeholder hull."
exit /b 1

:verifyfail
echo SHIP_FILES: one or more files do not match godot/assets/ships/manifest.json (see the MISMATCH lines above)
call :tasknote "Ship files: copied from %SRC% but FAILED the sha256 check; capture scripts will stop with placeholder hull."
exit /b 1

:tasknote
if not defined TASK exit /b 0
if not exist "%TASK%" exit /b 0
>>"%TASK%" echo.
>>"%TASK%" echo %~1
exit /b 0
