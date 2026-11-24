@echo off
rem Queue on the Windows PC after green checks and review at the same commit (R407).
rem No argument or "capture" writes the sheets. "timing" claims the GPU solo.
rem Argument 2 overrides the output folder. LB_SHIPS may name a different installed Godot asset folder.
setlocal EnableExtensions DisableDelayedExpansion
if /i "%~1"=="help" goto help
set "MODE=%~1"
if not defined MODE set "MODE=capture"
if /i "%MODE%"=="capture" goto paths
if /i "%MODE%"=="timing" goto paths
goto help

:paths
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%~dp0..\tmo.bat"
for %%D in ("%~dp0..\..\..\godot") do set "PROJECT=%%~fD"
set "OUT=%~2"
if not defined OUT set "OUT=%VT%\board_b\issue-1779\shots"
if not defined LB_SHIPS set "LB_SHIPS=%VT%\build\godot"
if not exist "%G%" (echo Missing Godot 4.7.2 at "%G%" & exit /b 1)
if not exist "%PROJECT%\bench\battle_post_fx_bench.tscn" (echo Run the launcher from the reviewed 1779 checkout. & exit /b 1)
if not exist "%LB_SHIPS%\gen\ships\station_T2.scn" (echo Missing the installed station_T2 in "%LB_SHIPS%". & exit /b 1)
if not exist "%OUT%\" mkdir "%OUT%"
if not exist "%OUT%\" (echo Could not create "%OUT%". & exit /b 1)
set "LOG=%TEMP%\voidsworn-1779-%MODE%-%RANDOM%-%RANDOM%.log"
set "PC_GPU_ISSUE=1779"
set "TMO_STEP=1779 asset import"
robocopy "%LB_SHIPS%\gen" "%PROJECT%\gen" /E /XC /XN /XO /NP /NDL /NFL /R:1 /W:1 > "%LOG%" 2>&1
if errorlevel 8 goto failed
robocopy "%LB_SHIPS%\assets\ships" "%PROJECT%\assets\ships" /E /XC /XN /XO /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /NFL /R:1 /W:1 >> "%LOG%" 2>&1
if errorlevel 8 goto failed
call "%TMO%" 1200 "%G%" --headless --path "%PROJECT%" --import >> "%LOG%" 2>&1
if errorlevel 1 goto failed
if /i "%MODE%"=="timing" goto timing

set "TMO_STEP=1779 comparison sheets"
set "PC_GPU_MODE=shared"
set "PC_GPU_WEIGHT=1"
call "%TMO%" 2400 "%G%" --path "%PROJECT%" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 res://bench/battle_post_fx_bench.tscn -- --out "%OUT%" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
goto verify

:timing
set "TMO_STEP=1779 solo frame timing"
set "PC_GPU_MODE=solo"
call "%TMO%" 2400 "%G%" --path "%PROJECT%" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/battle_post_fx_bench.tscn -- --out "%OUT%" --timing >> "%LOG%" 2>&1
if errorlevel 1 goto failed

:verify
findstr /C:"SCRIPT ERROR" /C:"Battle lens compute shader:" /C:"[post_fx] " "%LOG%" | findstr /C:"ERROR" > nul
if not errorlevel 1 goto failed
echo 1779 %MODE% done. See "%OUT%" and "%LOG%".
exit /b 0

:failed
echo 1779 %MODE% failed. See "%LOG%".
exit /b 1

:help
echo battle_post_fx_1779.bat [capture ^| timing] [output-folder]
exit /b 0
