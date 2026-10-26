@echo off
rem Voidsworn A3 rules parity check: runs the game's own battle rules in Node (the oracle) and the Godot port headless,
rem on the same seeded battles, and prints PASS or FAIL with the first difference.
rem Double-click it, or run "parity.bat nopause" from a watcher job.
rem Works from Downloads\voidsworn_test\build\ (game files beside it, the Godot project in build\godot_rules\)
rem or from a repo checkout (tools\pc\parity.bat).
setlocal enabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
if exist "%HERE%data.js" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\data.js" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the game files ^(data.js^) next to this file or two folders up. & goto :end )
set "RULES="
if exist "%GAME%godot_rules\project.godot" set "RULES=%GAME%godot_rules\"
if not defined RULES if exist "%GAME%contrib\opus\enginetest\godot_rules\project.godot" set "RULES=%GAME%contrib\opus\enginetest\godot_rules\"
if not defined RULES ( echo FAIL: cannot find the Godot rules project ^(godot_rules\project.godot^). & goto :end )
set "NODE=node"
if exist "%GAME%..\node\node.exe" set "NODE=%GAME%..\node\node.exe"
set "GODOT="
if exist "%GAME%..\godot_path.txt" set /p GODOT=<"%GAME%..\godot_path.txt"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
set "VS_ROOT=%GAME%"
set "LOG=%RULES%parity_log.txt"
if not exist "%RULES%golden" mkdir "%RULES%golden"
if not exist "%RULES%out" mkdir "%RULES%out"
echo Voidsworn rules parity, %date% %time% > "%LOG%"
echo Game files: %GAME% >> "%LOG%"
echo Godot: %GODOT% >> "%LOG%"
set FAILS=0
set "GD="%GODOT%" --headless --path "%RULES%." --script res://main.gd --"

echo.
echo [1/5] Exporting the game's data tables for Godot...
"%NODE%" "%RULES%node\export_data.js" "%RULES%data\tables.json" >> "%LOG%" 2>&1 || ( echo   FAIL: data export & set /a FAILS+=1 )

echo [2/5] Random numbers: first 10,000 draws from 3 seeds...
for %%S in (1001 7 4242424242) do (
  "%NODE%" "%RULES%node\golden.js" prng %%S 10000 "%RULES%golden\prng_%%S.txt" >> "%LOG%" 2>&1
  !GD! prng %%S 10000 "%RULES%out\prng_%%S.txt" >> "%LOG%" 2>&1
  "%NODE%" "%RULES%node\compare.js" same "%RULES%golden\prng_%%S.txt" "%RULES%out\prng_%%S.txt" > "%RULES%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   seed %%S: FAIL & type "%RULES%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   seed %%S: PASS )
  type "%RULES%out\cmp.txt" >> "%LOG%"
)

echo [3/5] Math functions the rules use ^(sin, cos, atan2, exp, hypot, round^) on 243,721 inputs...
"%NODE%" "%RULES%node\golden.js" math "%RULES%golden\math.txt" >> "%LOG%" 2>&1
!GD! math "%RULES%golden\math.txt" > "%RULES%out\math.txt" 2>&1
if errorlevel 1 ( echo   FAIL & type "%RULES%out\math.txt" & set /a FAILS+=1 ) else ( echo   PASS )
type "%RULES%out\math.txt" >> "%LOG%"

echo [4/5] Seeded battles, every activation compared ^(state hash, PRNG state^)...
for %%B in (s1 s2 s3 s4 s5) do (
  "%NODE%" "%RULES%node\golden.js" scenario %%B "%RULES%golden\%%B.jsonl" >> "%LOG%" 2>&1
  !GD! scenario %%B "%RULES%out\%%B.jsonl" >> "%LOG%" 2>&1
  "%NODE%" "%RULES%node\compare.js" scenario "%RULES%golden\%%B.jsonl" "%RULES%out\%%B.jsonl" > "%RULES%out\cmp.txt" 2>&1
  if errorlevel 1 ( echo   battle %%B: FAIL & type "%RULES%out\cmp.txt" & set /a FAILS+=1 ) else ( echo   battle %%B: PASS )
  type "%RULES%out\cmp.txt" >> "%LOG%"
)

echo [5/5] Enemy think time in the two 10-against-10 sector 3 battles ^(report only; game bar: worst under about 0.5 s^)...
for %%B in (s4 s5) do (
  "%NODE%" "%RULES%node\timing.js" %%B "%RULES%golden\%%B.jsonl.timing.json" "%RULES%out\%%B.jsonl.timing.json" > "%RULES%out\timing.txt" 2>&1
  type "%RULES%out\timing.txt"
  type "%RULES%out\timing.txt" >> "%LOG%"
)

echo.
if %FAILS%==0 ( echo PASS: the Godot port matches the game's rules exactly. & echo PASS >> "%LOG%" ) else ( echo FAIL: %FAILS% check^(s^) differ. Details above and in %LOG% & echo FAIL >> "%LOG%" )
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal
