@echo off
rem A3 effects-parity proof (FINDINGS R28): the Godot scene with the effects ported from the Babylon half.
rem Same shot list and clock as the blind round: stills for main, max and board at 4K, plus frame-time JSONs
rem (main, max, board, stress, 40 ships at 4K and 1440p, and a capped max run), as the final round had them.
rem Runs from Downloads\voidsworn_test\build. Needs (copied in first): enginetest\godot\ = the repo's
rem contrib\opus\enginetest\godot\ (all files); enginetest\assets\ (already there, with hi\ and env\); godot\ (godot_setup.ps1).
set L=..\smoke_log.txt
set ROOT=%USERPROFILE%\Downloads\voidsworn_test
set ET=%ROOT%\enginetest
set /p G=<"%ROOT%\godot_path.txt"
if not exist "%G%" set G=%ROOT%\godot\Godot_v4.7.2-stable_win64_console.exe
set RES=%ET%\results\a3
set SH=%ET%\shots\a3
if not exist "%RES%" mkdir "%RES%"
if not exist "%SH%" mkdir "%SH%"
echo --- a3_godot_fx: Godot effects-parity stills and frame times --- >> %L%
if not exist "%ET%\godot\bfx.gd" echo a3_godot_fx: enginetest\godot\bfx.gd is missing, copy the project in first >> %L%
if not exist "%ET%\godot\bfx.gd" goto done
cd /d "%ET%"
rem stills: main, max (plus the six hero close-ups), board
"%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots "%SH%\g_main" --res 3840x2160 > "%RES%\shots_main_log.txt" 2>&1
"%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots "%SH%\g_max" --res 3840x2160 --max > "%RES%\shots_max_log.txt" 2>&1
"%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 --fixed-fps 60 -- --shots "%SH%\g_board" --res 3840x2160 --board > "%RES%\shots_board_log.txt" 2>&1
rem frame times (20 s each after the 3 s warm-up)
for %%M in (main max board stress) do (
  "%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench "%RES%\g_%%M_2160.json" --seconds 20 --res 3840x2160 --%%M > "%RES%\bench_%%M_2160_log.txt" 2>&1
  "%G%" --path godot --rendering-method forward_plus --resolution 2560x1440 --disable-vsync -- --bench "%RES%\g_%%M_1440.json" --seconds 20 --res 2560x1440 --%%M > "%RES%\bench_%%M_1440_log.txt" 2>&1
)
"%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 --disable-vsync -- --bench "%RES%\g_ships40_2160.json" --seconds 20 --res 3840x2160 --ships 40 > "%RES%\bench_ships40_2160_log.txt" 2>&1
"%G%" --path godot --rendering-method forward_plus --resolution 3840x2160 -- --bench "%RES%\g_max_2160_vsync.json" --seconds 20 --res 3840x2160 --max --vsync > "%RES%\bench_max_vsync_log.txt" 2>&1
"%G%" --path godot --rendering-method gl_compatibility --resolution 3840x2160 --disable-vsync -- --bench "%RES%\g_gl_main_2160.json" --seconds 20 --res 3840x2160 > "%RES%\bench_gl_main_log.txt" 2>&1
dir /b "%SH%\g_main" "%SH%\g_max" "%SH%\g_board" >> %L% 2>&1
dir /b "%RES%\*.json" >> %L% 2>&1
findstr /i /c:"SCRIPT ERROR" /c:"SHADER ERROR" "%RES%\*_log.txt" >> %L% 2>&1
:done
echo --- a3_godot_fx done --- >> %L%
cd /d "%~dp0"
