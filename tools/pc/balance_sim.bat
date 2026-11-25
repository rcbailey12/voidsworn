@echo off
rem Run the Godot balance sim. Modes: campaign, campaignrewards, fmatrix, run. Pass mode, count, and nopause.
rem Double-click for campaign. Run plays complete campaigns on both difficulties. Set PFACTION for one faction or AI for one difficulty.
rem Set ONLY_BOSS=1 to select the boss cells and the elite comparison.
setlocal enableextensions disabledelayedexpansion
for %%D in ("%~dp0..\..") do set "BALANCE_REPO=%%~fD"
set "BALANCE_GODOT=%GODOT_EXE%"
set "BALANCE_SEARCH=%BALANCE_REPO%"
set "BALANCE_RESULT=1"

:find_godot
if defined BALANCE_GODOT goto :run
if exist "%BALANCE_SEARCH%\godot_path.txt" set /p BALANCE_GODOT=<"%BALANCE_SEARCH%\godot_path.txt"
if defined BALANCE_GODOT goto :run
for %%D in ("%BALANCE_SEARCH%\..") do set "BALANCE_PARENT=%%~fD"
if /i "%BALANCE_PARENT%"=="%BALANCE_SEARCH%" goto :use_path
set "BALANCE_SEARCH=%BALANCE_PARENT%"
goto :find_godot

:use_path
set "BALANCE_GODOT=godot.exe"

:run
set "BALANCE_MODE=%~1"
set "BALANCE_COUNT=%~2"
if not defined BALANCE_MODE set "BALANCE_MODE=campaign"
if not defined BALANCE_COUNT (
    set "BALANCE_COUNT=10"
    if /i "%BALANCE_MODE%"=="fmatrix" set "BALANCE_COUNT=6"
)
"%BALANCE_GODOT%" --headless --log-file "%TEMP%\voidsworn-balance-%RANDOM%-%RANDOM%.log" --path "%BALANCE_REPO%\godot" --script res://rules/sim/balance_sim.gd -- "%BALANCE_MODE%" "%BALANCE_COUNT%"
set "BALANCE_RESULT=%ERRORLEVEL%"
if /i not "%~3"=="nopause" pause
endlocal & exit /b %BALANCE_RESULT%
