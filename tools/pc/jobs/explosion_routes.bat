@echo off
rem Issue 353, explosion pictures step 1: bake route A and route B, time the bakes, bench today, A and B, write the sheet.
rem   explosion_routes.bat MODE OUT
rem MODE  smoke  a small fair sample: A at 64 cells, B at 64, 192 pixel cells (checks every step end to end, times the
rem              64 cell sample) plus the switch-off look bench of every moment and the fleet against the baseline run
rem       frame  the same small bakes (256 pixel cells), pack, the two moments benched and the sheet; nothing else. A fast
rem              look at how far the gas reaches in its grid and at the fire, before the long bakes
rem       full   the real bakes (A at 256 cells with noise, B at 128 cells with three seeds; 512 pixel cells), the two
rem              moments benched in all five looks, and the scene gate (R116) with the switch off and on
rem       repack no bakes: pack the bakes of an earlier run (BAKESRC, its OUT folder) again, then bench, sheet and gate
rem              FIREPASS (fire, firelo or firehi; default fire) picks which route A fire render is packed.
rem OUT   the output folder (status.txt, times.txt, bake_a, bake_b, atlases_a, atlases_b, bench_*, gate_*, done.txt)
rem Runs from this checkout (tools\pc\jobs\ inside it). Needs the PC-built hulls: copied (copy only) from FX_SHIPS, default
rem Downloads\voidsworn_test\bench351\repo\godot. One GPU job at a time: waits until the card is idle (up to 60 minutes)
rem before the bakes and before the benches. Nothing is deleted. done.txt is written whatever happens.
rem Every look is benched twice and the second run is kept (the first goes to OUT\first\; docs/shots/look_bench/README.md).
setlocal enabledelayedexpansion
set "MODE=%~1"
set "O=%~2"
if "%MODE%"=="" set "MODE=smoke"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
cd /d "%~dp0..\..\.."
set "R=%CD%"
if "%O%"=="" set "O=%R%\..\out_%MODE%"
if not exist "%O%" mkdir "%O%"
set "ST=%O%\status.txt"
set "TM=%O%\times.txt"
echo explosion routes %MODE% start %date% %time% > "%ST%"
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "SHA=%%H"
set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BL=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set "TMO=%R%\tools\pc\tmo.bat"
if "%FX_SHIPS%"=="" set "FX_SHIPS=%VT%\bench351\repo\godot"
if "%FIREPASS%"=="" set "FIREPASS=fire"
set "RA=256" & set "RB=128" & set "TILE=512" & set "LIM=5400"
if /i "%MODE%"=="smoke" set "RA=64" & set "RB=64" & set "TILE=192" & set "LIM=1200"
if /i "%MODE%"=="frame" set "RA=64" & set "RB=64" & set "TILE=256" & set "LIM=1200"
echo res A %RA% B %RB% tile %TILE% limit %LIM% s >> "%ST%"

rem ---- the PC-built hulls and import cache a fresh clone lacks (copy only, never over newer files)
if exist "%FX_SHIPS%\gen" robocopy "%FX_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\copy_gen.txt" 2>&1
if exist "%FX_SHIPS%\assets\ships" robocopy "%FX_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\copy_ships.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%FX_SHIPS%\.godot" robocopy "%FX_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\copy_cache.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo imported %date% %time% >> "%ST%"

rem ---- bakes: one Blender call per route and kind, each timed by the wall clock
set "BA=%O%\bake_a"
set "BB=%O%\bake_b"
if /i not "%MODE%"=="repack" goto bakes
set "BA=%BAKESRC%\bake_a"
set "BB=%BAKESRC%\bake_b"
echo repack from %BAKESRC% >> "%ST%"
goto pack
:bakes
call :gpuwait
echo bakes start %date% %time% >> "%ST%"
for %%K in (impact flash) do (
  echo A %%K start !date! !time! >> "%TM%"
  call "%TMO%" %LIM% "%BL%" -b -t 0 -P tools/blender/vfx/bake_route_a.py -- "%O%\bake_a" --resolution %RA% --tile %TILE% --kinds %%K > "%O%\bake_a_%%K.txt" 2>&1
  echo A %%K end !date! !time! exit !errorlevel! >> "%TM%"
  echo B %%K start !date! !time! >> "%TM%"
  call "%TMO%" %LIM% "%BL%" -b -t 0 -P tools/blender/vfx/bake_route_b.py -- "%O%\bake_b" --resolution %RB% --tile %TILE% --kinds %%K > "%O%\bake_b_%%K.txt" 2>&1
  echo B %%K end !date! !time! exit !errorlevel! >> "%TM%"
)
echo bakes done %date% %time% >> "%ST%"
:pack
echo pack start %date% %time% >> "%TM%"
"%PY%" tools/blender/vfx/pack_routes.py "%BA%" "%O%\atlases_a" --route a --fire %FIREPASS% > "%O%\pack_a.txt" 2>&1
echo pack a exit %ERRORLEVEL% >> "%ST%"
"%PY%" tools/blender/vfx/pack_routes.py "%BB%" "%O%\atlases_b" --route b > "%O%\pack_b.txt" 2>&1
echo pack b exit %ERRORLEVEL% >> "%ST%"
echo pack end %date% %time% >> "%TM%"

rem ---- the two moments in all five looks (VS_FX_ATLAS is the bench-only switch; empty draws the shipped look)
call :gpuwait
set "ONLY=w_torp_void_hull,d_cruiser"
call :bench today ""
call :bench a_flash "%O%\atlases_a\flash"
call :bench a_core "%O%\atlases_a\core"
call :bench b_flash "%O%\atlases_b\flash"
call :bench b_core "%O%\atlases_b\core"
"%PY%" tools/pc/jobs/explosion_routes_sheet.py --runs today="%O%\bench_today" a_flash="%O%\bench_a_flash" a_core="%O%\bench_a_core" b_flash="%O%\bench_b_flash" b_core="%O%\bench_b_core" --out "%O%\explosion_routes_sheet.jpg" --strips "%O%\strips" > "%O%\sheet.txt" 2>&1
echo sheet exit %ERRORLEVEL% %date% %time% >> "%ST%"

if /i "%MODE%"=="frame" goto finish
if /i not "%MODE%"=="smoke" goto gate
rem ---- smoke mode: the switch off, every moment and the fleet, against the accepted baseline run (base_f, 499aae8)
set "VS_FX_ATLAS="
echo bench off_all start %date% %time% >> "%ST%"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%\bench_off_all" --commit %SHA% > "%O%\bench_off_all_log.txt" 2>&1
echo bench off_all exit %ERRORLEVEL% %date% %time% >> "%ST%"
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_off_all_log.txt" > nul && echo off_all LOOK_BENCH_DONE >> "%ST%"
"%PY%" tools/pc/jobs/look_bench_sheets.py --before "%VT%\bench351\runs\base_f" --after "%O%\bench_off_all" --out "%O%\sheets_off_vs_base_f" --label-before base_f --label-after switch_off --tol 2.0 > "%O%\sheets_off.txt" 2>&1
echo sheets off exit %ERRORLEVEL% %date% %time% >> "%ST%"
goto finish

:gate
rem ---- the scene gate (R116): frame median at 1080p and GPU ms at 4K, switch off and on (two sessions a mode)
for %%C in (off a_core b_core) do (
  set "VS_FX_ATLAS="
  if "%%C"=="a_core" set "VS_FX_ATLAS=%O%\atlases_a\core"
  if "%%C"=="b_core" set "VS_FX_ATLAS=%O%\atlases_b\core"
  echo gate %%C start !date! !time! >> "%ST%"
  call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\gate_%%C" --modes base,deaths,res_2160 --sessions 2 > "%O%\gate_%%C_log.txt" 2>&1
  echo gate %%C exit !errorlevel! !date! !time! >> "%ST%"
)
set "VS_FX_ATLAS="

:finish
echo explosion routes %MODE% done %date% %time% >> "%ST%"
dir /b /s "%O%\atlases_a" "%O%\atlases_b" > "%O%\files.txt" 2>&1
echo done > "%O%\done.txt"
endlocal
exit /b 0

rem ---------------------------------------------------------------- :bench NAME ATLASDIR
:bench
set "VS_FX_ATLAS=%~2"
if not exist "%O%\first" mkdir "%O%\first"
echo bench %~1 first run start %date% %time% atlas=%~2 >> "%ST%"
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%\first\bench_%~1" --part moments --only %ONLY% --commit %SHA% > "%O%\first\bench_%~1_log.txt" 2>&1
echo bench %~1 start %date% %time% atlas=%~2 >> "%ST%"
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%\bench_%~1" --part moments --only %ONLY% --commit %SHA% > "%O%\bench_%~1_log.txt" 2>&1
echo bench %~1 exit %ERRORLEVEL% %date% %time% >> "%ST%"
findstr /c:"LOOK_BENCH placeholder hull" "%O%\bench_%~1_log.txt" > nul && echo PLACEHOLDER HULL in bench %~1 >> "%ST%"
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_%~1_log.txt" > nul && echo bench %~1 LOOK_BENCH_DONE >> "%ST%"
set "VS_FX_ATLAS="
exit /b 0

rem ---------------------------------------------------------------- :gpuwait (under 15 percent, up to 60 minutes)
:gpuwait
set /a GW=0
:gpuloop
set U=0
for /f %%U in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set U=%%U
if %U% LSS 15 goto gpufree
set /a GW+=1
if %GW% GEQ 60 goto gpufree
timeout /t 60 /nobreak > nul
goto gpuloop
:gpufree
echo gpu free after %GW% min %date% %time% >> "%ST%"
exit /b 0
