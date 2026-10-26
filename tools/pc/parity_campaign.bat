@echo off
rem Voidsworn campaign parity check (G3): plays 30 seeded full runs (title to the end screen) twice, once with the game's own
rem JS campaign files in Node (the oracle, pinned in godot\campaign\test\oracle\) and once with the Godot port headless, using
rem the same scripted player. Compares the campaign state after every click and prints PASS or FAIL with the first difference.
rem Double-click it, or run "parity_campaign.bat nopause" from a watcher job. parity.bat calls it at the end.
rem Works from Downloads\voidsworn_test\build\ (the repo's godot\ folder copied to build\godot\) or from a repo checkout.
setlocal enabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the Godot project ^(godot\project.godot next to this file or two folders up^). & goto :end )
set "PROJ=%GAME%godot\"
set "T=%PROJ%campaign\test\"
set "NODE=node"
if exist "%GAME%..\node\node.exe" set "NODE=%GAME%..\node\node.exe"
set "GODOT="
if exist "%GAME%..\godot_path.txt" set /p GODOT=<"%GAME%..\godot_path.txt"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
set "LOG=%T%parity_campaign_log.txt"
if not exist "%T%golden" mkdir "%T%golden"
if not exist "%T%out" mkdir "%T%out"
echo Voidsworn campaign parity, %date% %time% > "%LOG%"
echo Project: %PROJ% >> "%LOG%"
echo Godot: %GODOT% >> "%LOG%"
set FAILS=0
set "SEEDS="
for /L %%S in (1,1,30) do set "SEEDS=!SEEDS! %%S"

echo.
echo Campaign parity (G3)
echo [1/3] Campaign tables still match the pinned JS files...
"%NODE%" "%T%node\export_campaign.js" "%T%out\tables_check.json" >> "%LOG%" 2>&1
"%NODE%" -e "process.exit(require(process.argv[1]).sha256===require(process.argv[2]).sha256?0:1)" "%T%out\tables_check.json" "%PROJ%campaign\data\campaign_tables.json" >> "%LOG%" 2>&1
if errorlevel 1 ( echo   FAIL: campaign_tables.json is stale & set /a FAILS+=1 ) else ( echo   PASS )

echo [2/3] Playing 30 seeded runs in the JS game and in Godot...
for /L %%S in (1,1,30) do "%NODE%" "%T%node\golden_campaign.js" %%S "%T%golden\c%%S.jsonl" >> "%LOG%" 2>&1
"%GODOT%" --headless --path "%PROJ%." --script res://campaign/test/parity_campaign.gd -- "%T%out" !SEEDS! >> "%LOG%" 2>&1

echo [3/3] Comparing every click ^(buttons on screen, campaign state, saved copy, PRNG state^)...
for /L %%S in (1,1,30) do (
  "%NODE%" "%T%node\compare_campaign.js" "%T%golden\c%%S.jsonl" "%T%out\c%%S.jsonl" > "%T%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   run %%S: FAIL & type "%T%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   run %%S: PASS )
  type "%T%out\cmp.txt" >> "%LOG%"
)

echo.
if %FAILS%==0 ( echo PASS: the Godot campaign matches the game on all 30 seeded runs. & echo PASS >> "%LOG%" ) else ( echo FAIL: %FAILS% check^(s^) differ. Details above and in %LOG% & echo FAIL >> "%LOG%" )
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal
exit /b
