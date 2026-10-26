@echo off
rem Voidsworn rules parity SWEEP (G1 exit check): N random battles with every setting varied (fight type, field, map, sides,
rem admiral, fleets, boons, relics, heat, AI level, Classic mode, campaign events), run in the game's own rules (Node) and in
rem the Godot port, and compared after every action. Prints PASS or FAIL and one line per battle that differs.
rem Double-click it (200 battles), or run "parity_sweep.bat 200 1 nopause" from a watcher job (count, seed, nopause).
setlocal enabledelayedexpansion
set "HERE=%~dp0"
set "N=%~1"
if "%N%"=="" set "N=200"
set "SEED=%~2"
if "%SEED%"=="" set "SEED=1"
set "GAME="
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the Godot project ^(godot\project.godot next to this file or two folders up^). & goto :end )
set "PROJ=%GAME%godot\"
set "T=%PROJ%rules\test\"
set "NODE=node"
if exist "%GAME%..\node\node.exe" set "NODE=%GAME%..\node\node.exe"
set "GODOT="
if exist "%GAME%..\godot_path.txt" set /p GODOT=<"%GAME%..\godot_path.txt"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
set "LOG=%T%sweep_log.txt"
if not exist "%T%golden\sweep" mkdir "%T%golden\sweep"
if not exist "%T%out\sweep" mkdir "%T%out\sweep"
del /q "%T%golden\sweep\*.jsonl" 2>nul
del /q "%T%out\sweep\*.jsonl" 2>nul
echo Voidsworn rules parity sweep, %N% battles, seed %SEED%, %date% %time% > "%LOG%"
echo.
echo [1/4] Exporting the game's data tables for Godot...
"%NODE%" "%T%node\export_data.js" "%PROJ%rules\data\tables.json" >> "%LOG%" 2>&1 || ( echo   FAIL: data export & goto :end )
echo [2/4] Making %N% random battles ^(seed %SEED%^)...
"%NODE%" "%T%node\sweep_gen.js" %N% %SEED% "%T%out\sweep.json" >> "%LOG%" 2>&1
echo [3/4] Playing them in the game's rules ^(Node^) and in the Godot port...
set "T0=%time%"
"%NODE%" "%T%node\golden.js" batch "%T%out\sweep.json" "%T%golden\sweep" >> "%LOG%" 2>&1
"%GODOT%" --headless --path "%PROJ%." --script res://rules/test/parity_main.gd -- batch "%T%out\sweep.json" "%T%out\sweep" > "%T%out\sweep_godot.log" 2>&1
findstr /c:"SCRIPT ERROR" /c:"NOT PORTED" "%T%out\sweep_godot.log" > "%T%out\sweep_err.txt"
if not errorlevel 1 ( echo   Godot reported errors ^(first lines^): & powershell -NoProfile -Command "Get-Content '%T%out\sweep_err.txt' -TotalCount 5" )
echo   started %T0%, finished %time%
echo [4/4] Comparing every battle, record by record...
"%NODE%" "%T%node\sweep_check.js" "%T%out\sweep.json" "%T%golden\sweep" "%T%out\sweep" > "%T%out\sweep.txt" 2>&1
type "%T%out\sweep.txt"
type "%T%out\sweep.txt" >> "%LOG%"
:end
echo.
if /i not "%~3"=="nopause" pause
endlocal
exit /b
