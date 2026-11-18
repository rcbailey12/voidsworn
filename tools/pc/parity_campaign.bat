@echo off
rem Voidsworn campaign parity check (G3): plays 30 seeded full runs (title to the end screen) twice, once with the game's own
rem JS campaign files at the repo root in Node (the oracle) and once with the Godot port headless, using
rem the same scripted player. Compares the campaign state after every click and prints PASS or FAIL with the first difference.
rem Double-click it, or run "parity_campaign.bat nopause" from a watcher job. parity.bat calls it at the end.
rem Works from Downloads\voidsworn_test\build\ (the repo's godot\ folder copied to build\godot\) or from a repo checkout.
setlocal enableextensions disabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
set "RESULT=1"
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the Godot project ^(godot\project.godot next to this file or two folders up^). & goto :end )
set "PROJ=%GAME%godot\"
set "T=%PROJ%campaign\test\"
set "NODE="
set "GODOT="
for %%D in ("%GAME%.") do set "SEARCH=%%~fD"
rem Find the PC bundle above build or any board lane checkout, as in parity.bat.
:bundle
if not defined NODE if exist "%SEARCH%\node\node.exe" set "NODE=%SEARCH%\node\node.exe"
if not defined GODOT if exist "%SEARCH%\godot_path.txt" set /p GODOT=<"%SEARCH%\godot_path.txt"
for %%D in ("%SEARCH%\..") do set "NEXT=%%~fD"
if /i "%NEXT%"=="%SEARCH%" goto :bundle_done
set "SEARCH=%NEXT%"
goto :bundle
:bundle_done
if not defined NODE set "NODE=node"
rem Node guard (issue 357): the rules math targets V8 in Node 22; another major gives a false parity failure.
"%NODE%" -e "process.exit(process.versions.node.split('.')[0]==='22'?0:3)" >nul 2>&1
if errorlevel 1 ( echo FAIL: Node major 22 is required, use the bundled Node 22 at voidsworn_test\node\node.exe. & exit /b 1 )
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
set "LOG=%T%parity_campaign_log.txt"
if not exist "%T%golden" mkdir "%T%golden"
if not exist "%T%out" mkdir "%T%out"
echo Voidsworn campaign parity, %date% %time% > "%LOG%"
echo Project: %PROJ% >> "%LOG%"
echo Godot: %GODOT% >> "%LOG%"
set FAILS=0
setlocal enabledelayedexpansion
set "SEEDS="
for /L %%S in (1,1,30) do set "SEEDS=!SEEDS! %%S"
endlocal & set "SEEDS=%SEEDS%"

echo.
echo Campaign parity (G3)
echo [1/4] Campaign tables still match the root JS files...
"%NODE%" "%T%node\export_campaign.js" "%T%out\tables_check.json" >> "%LOG%" 2>&1
if not errorlevel 1 "%NODE%" -e "process.exit(require(process.argv[1]).sha256===require(process.argv[2]).sha256?0:1)" "%T%out\tables_check.json" "%PROJ%campaign\data\campaign_tables.json" >> "%LOG%" 2>&1
if errorlevel 1 ( echo   FAIL: campaign_tables.json is stale & set /a FAILS+=1 ) else ( echo   PASS )

echo [2/4] Playing 30 seeded runs in the JS game and in Godot...
for %%S in (%SEEDS%) do (
  "%NODE%" "%T%node\golden_campaign.js" %%S "%T%golden\c%%S.jsonl" >> "%LOG%" 2>&1
  if errorlevel 1 ( echo   FAIL: the JS run for seed %%S did not finish & set /a FAILS+=1 )
)
"%GODOT%" --headless --path "%PROJ%." --script res://campaign/test/parity_campaign.gd -- "%T%out" %SEEDS% >> "%LOG%" 2>&1
if errorlevel 1 ( echo   FAIL: the Godot runs did not finish & set /a FAILS+=1 )

echo [3/4] Comparing every click ^(buttons on screen, campaign state, saved copy, PRNG state^)...
for %%S in (%SEEDS%) do (
  "%NODE%" "%T%node\compare_campaign.js" "%T%golden\c%%S.jsonl" "%T%out\c%%S.jsonl" > "%T%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   run %%S: FAIL & type "%T%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   run %%S: PASS )
  type "%T%out\cmp.txt" >> "%LOG%"
)

echo [4/4] Cross-twin save hand-off ^(fixed seed and step count, record by record^)...
"%NODE%" "%T%node\cross_twin_handoff_test.js" "%GODOT%" 1 40 >> "%LOG%" 2>&1
if errorlevel 1 ( echo   FAIL & set /a FAILS+=1 ) else ( echo   PASS )

echo.
if not "%FAILS%"=="0" (
  echo FAIL: %FAILS% check^(s^) differ. Details above and in "%LOG%"
  echo FAIL >> "%LOG%"
  goto :end
)
rem Keep diagnostics through the final comparison. On success remove only the files this run writes.
for %%S in (%SEEDS%) do (
  call :remove_output "golden\c%%S.jsonl"
  call :remove_output "out\c%%S.jsonl"
)
call :remove_output "out\tables_check.json"
call :remove_output "out\cmp.txt"
if not "%FAILS%"=="0" (
  echo FAIL: could not remove %FAILS% campaign parity output file^(s^). Details in "%LOG%"
  echo FAIL >> "%LOG%"
  goto :end
)
echo PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
echo PASS >> "%LOG%"
set "RESULT=0"
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal & exit /b %RESULT%

:remove_output
if exist "%T%%~1" del /q "%T%%~1" >> "%LOG%" 2>&1
if not exist "%T%%~1" exit /b 0
echo Could not remove "%T%%~1" >> "%LOG%"
set /a FAILS+=1
exit /b 1
