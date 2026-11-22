@echo off
rem Rules check (Godot only, against the saved results, R405) and the saved campaign check, as in CI.
rem Double-click, or parity.bat nopause from a watcher. Set PARITY_RUN_ROOT to keep detailed rules records.
setlocal enableextensions disabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
set "RESULT=1"
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find godot\project.godot. & goto :end )
for %%D in ("%GAME%.") do set "GAME=%%~fD"
set "NODE="
set "GODOT="
set "SEARCH=%GAME%"
rem Find the PC bundle above build or any board lane checkout, without relying on PATH.
:bundle
if not defined NODE if exist "%SEARCH%\node\node.exe" set "NODE=%SEARCH%\node\node.exe"
if not defined GODOT if exist "%SEARCH%\godot_path.txt" set /p GODOT=<"%SEARCH%\godot_path.txt"
for %%D in ("%SEARCH%\..") do set "NEXT=%%~fD"
if /i "%NEXT%"=="%SEARCH%" goto :bundle_done
set "SEARCH=%NEXT%"
goto :bundle
:bundle_done
if not defined NODE set "NODE=node"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found. & goto :end )
"%NODE%" "%GAME%\godot\rules\test\node\run_parity.js"
set "RESULT=%ERRORLEVEL%"
rem Issue 1654 (R405): the campaign is checked in Godot against its saved results, never against the frozen browser files.
rem parity_campaign.bat is the old browser comparison, kept for history only.
set "SAVED_CAMPAIGN_SELFTEST=1"
"%NODE%" "%GAME%\godot\campaign\test\node\saved_campaign.js"
if errorlevel 1 set "RESULT=1"
set "SAVED_CAMPAIGN_SELFTEST="
"%NODE%" "%GAME%\godot\campaign\test\node\saved_campaign.js" check 1 30
if errorlevel 1 set "RESULT=1"
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal & exit /b %RESULT%
