@echo off
rem Issue 230 motion capture (AS10, AS14, NB8; contrib/opus/briefs/environment_reconciliation.md section 8).
rem Start it from a one-line queue job (queue\q230_motion.bat: start "env230" cmd /c "<this file>") so the queue stays free.
rem 1. A clone of branch opus/issue-230 in Downloads\voidsworn_test\opus230\repo (LF line endings: core.autocrlf=false).
rem 2. The built hulls and A4 ship files copied in from build\godot (copy only; nothing is deleted anywhere), so ships
rem    draw as in the game, then one Godot import.
rem 3. world_shots.gd --motion on four cases, five variants, look C, 1920x1080, windowed on the RTX 5080.
rem Output: Downloads\voidsworn_test\opus230\out\<variant>\ (sheets, diffs, first frames, logs) and status.txt.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus230"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% >> "%O%\status.txt"
if exist "%R%\.git" goto update
git -c core.autocrlf=false clone --depth 1 --branch opus/issue-230 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
goto cloned
:update
git -C "%R%" fetch --depth 1 origin opus/issue-230 > "%O%\git_log.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_log.txt" 2>&1
:cloned
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\world\world_shots.tscn" (
  echo clone failed >> "%O%\status.txt"
  exit /b 1
)
set "TMO=%R%\tools\pc\tmo.bat"
robocopy "%VT%\build\godot\gen" "%R%\godot\gen" /E /NP /NDL /R:1 /W:1 > "%O%\gencopy_log.txt" 2>&1
robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /R:1 /W:1 > "%O%\a4copy_log.txt" 2>&1
echo import %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
set "CASES=boneyard_graveyard,nebula_storm,deep_storm,frontier_belt"
set "SHOTS=res://world/world_shots.tscn"
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE="
set "VS_GAS_FLAT="
call :run shipped
set "VS_TUMBLE=periods"
call :run periods
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE=1"
call :run cap_rocks
set "VS_TUMBLE=periods"
call :run periods_rocks
set "VS_TUMBLE="
set "VS_ROCK_TUMBLE="
set "VS_GAS_FLAT=1"
call :run gas_flat nebula_storm,deep_storm
set "VS_GAS_FLAT="
echo all done %date% %time% >> "%O%\status.txt"
cd /d "%VT%\build"
exit /b 0

:run
set "ONLY=%CASES%"
if not "%~2"=="" set "ONLY=%~2"
if not exist "%O%\%~1" mkdir "%O%\%~1"
echo %~1 start %time% >> "%O%\status.txt"
call "%TMO%" 1500 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 %SHOTS% -- --out "%O%\%~1" --motion 30 --every 5 --tag %~1 --only %ONLY% > "%O%\%~1\log.txt" 2>&1
echo %~1 done %time% >> "%O%\status.txt"
exit /b 0
