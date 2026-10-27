@echo off
rem Voidsworn rules parity check: runs the game's own battle rules in Node (the oracle) and the Godot port headless,
rem on the same seeded battles, and prints PASS or FAIL with the first difference. Then prints enemy think times (report only).
rem Double-click it, or run "parity.bat nopause" from a watcher job.
rem Works from Downloads\voidsworn_test\build\ (the repo's godot\ folder copied to build\godot\)
rem or from a repo checkout (tools\pc\parity.bat).
setlocal enabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the Godot project ^(godot\project.godot next to this file or two folders up^). & goto :end )
set "PROJ=%GAME%godot\"
rem the rules oracle is the pinned copy in godot\rules\test\oracle\ (see its README)
set "T=%PROJ%rules\test\"
set "NODE=node"
if exist "%GAME%..\node\node.exe" set "NODE=%GAME%..\node\node.exe"
set "GODOT="
if exist "%GAME%..\godot_path.txt" set /p GODOT=<"%GAME%..\godot_path.txt"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
set "LOG=%T%parity_log.txt"
if not exist "%T%golden" mkdir "%T%golden"
if not exist "%T%out" mkdir "%T%out"
echo Voidsworn rules parity, %date% %time% > "%LOG%"
echo Project: %PROJ% >> "%LOG%"
echo Godot: %GODOT% >> "%LOG%"
set FAILS=0
set "GD="%GODOT%" --headless --path "%PROJ%." --script res://rules/test/parity_main.gd --"
set "SCEN="
"%NODE%" -e "console.log(Object.keys(require(process.argv[1])).join(' '))" "%T%scenarios.json" > "%T%out\scen.txt" 2>> "%LOG%"
set /p SCEN=<"%T%out\scen.txt"

echo.
echo [1/5] Exporting the game's data tables for Godot...
"%NODE%" "%T%node\export_data.js" "%PROJ%rules\data\tables.json" >> "%LOG%" 2>&1 || ( echo   FAIL: data export & set /a FAILS+=1 )

echo [2/5] Random numbers: first 10,000 draws from 3 seeds...
for %%S in (1001 7 4242424242) do (
  "%NODE%" "%T%node\golden.js" prng %%S 10000 "%T%golden\prng_%%S.txt" >> "%LOG%" 2>&1
  !GD! prng %%S 10000 "%T%out\prng_%%S.txt" >> "%LOG%" 2>&1
  "%NODE%" "%T%node\compare.js" same "%T%golden\prng_%%S.txt" "%T%out\prng_%%S.txt" > "%T%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   seed %%S: FAIL & type "%T%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   seed %%S: PASS )
  type "%T%out\cmp.txt" >> "%LOG%"
)

echo [3/5] Math functions the rules use ^(sin, cos, atan2, exp, hypot, round, pow^) on 316,090 inputs...
"%NODE%" "%T%node\golden.js" math "%T%golden\math.txt" >> "%LOG%" 2>&1
!GD! math "%T%golden\math.txt" > "%T%out\math.txt" 2>&1
if errorlevel 1 ( echo   FAIL & type "%T%out\math.txt" & set /a FAILS+=1 ) else ( echo   PASS )
type "%T%out\math.txt" >> "%LOG%"

echo [4/5] Seeded battles, every activation compared ^(state hash, PRNG state^): !SCEN!
for %%B in (!SCEN!) do (
  if exist "%T%golden\%%B.jsonl" del "%T%golden\%%B.jsonl"
  if exist "%T%out\%%B.jsonl" del "%T%out\%%B.jsonl"
  "%NODE%" "%T%node\golden.js" scenario %%B "%T%golden\%%B.jsonl" >> "%LOG%" 2>&1
  !GD! scenario %%B "%T%out\%%B.jsonl" >> "%LOG%" 2>&1
  "%NODE%" "%T%node\compare.js" scenario "%T%golden\%%B.jsonl" "%T%out\%%B.jsonl" > "%T%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   battle %%B: FAIL & type "%T%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   battle %%B: PASS )
  type "%T%out\cmp.txt" >> "%LOG%"
)

echo [4b] Threat overlay ^(ui3d.js computeThreat^) against api.threat_map, rounds 1 to 3...
for %%B in (s4 s19 s23) do (
  "%NODE%" "%T%node\golden.js" threat %%B "%T%golden\threat_%%B.json" >> "%LOG%" 2>&1
  !GD! threat %%B "%T%out\threat_%%B.json" >> "%LOG%" 2>&1
  fc /b "%T%golden\threat_%%B.json" "%T%out\threat_%%B.json" > nul 2>&1
  if errorlevel 1 ( echo   threat map %%B: FAIL & set /a FAILS+=1 ) else ( echo   threat map %%B: PASS )
)

echo [4c] Threads and the hard stop: enemy steps on a worker thread while the scene reads ^(s4, s23^)...
"%GODOT%" --headless --path "%PROJ%." --script res://rules/test/thread_test.gd -- s4 s23 > "%T%out\thread.txt" 2>&1
if errorlevel 1 ( echo   FAIL & findstr /b /c:"thread test" /c:"hard stop" /c:"  halted" "%T%out\thread.txt" & set /a FAILS+=1 ) else ( findstr /b /c:"thread test" /c:"hard stop" "%T%out\thread.txt" )
type "%T%out\thread.txt" >> "%LOG%"

echo [5/5] Enemy think time in the timing battles ^(report only; game bar: worst under about 0.5 s^)...
"%NODE%" "%T%node\timing.js" all "%T%." > "%T%out\timing.txt" 2>&1
type "%T%out\timing.txt"
type "%T%out\timing.txt" >> "%LOG%"

echo.
if %FAILS%==0 ( echo PASS: the Godot port matches the game's rules exactly. & echo PASS >> "%LOG%" ) else ( echo FAIL: %FAILS% check^(s^) differ. Details above and in %LOG% & echo FAIL >> "%LOG%" )
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal
rem ===================== G3 campaign parity (appended by the G3 helper; everything is in parity_campaign.bat) =====================
rem parity_campaign.bat sits beside this file in a repo checkout or in build\; in a lane B copy (build_b\parity.bat) it is in tools\pc\
if exist "%~dp0parity_campaign.bat" ( call "%~dp0parity_campaign.bat" %1 ) else if exist "%~dp0tools\pc\parity_campaign.bat" ( call "%~dp0tools\pc\parity_campaign.bat" %1 ) else ( echo FAIL: parity_campaign.bat not found next to parity.bat or in tools\pc\ )
