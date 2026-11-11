@echo off
rem Issue 209 round 8, second bake (out8b): r8_run.bat after two bake fixes found on the first one (out8): the bow deck lip and deck plates baked olive (UV islands, not paint), and the deck reds a step darker for the game camera. Same steps.
rem the layered paint. Bake, renders (studio, concept rig, starboard), close-ups, the hand LOD chain and the cost bench beside
rem Ab7, recipe stage 7 (game export, its check and self-test), the game import, and the battle capture at the game's camera.
rem Started by pc\r8_queue.bat in its own window. Writes Downloads\voidsworn_test\opus209\out8\ (and rebuilds the game's generated
rem files inside Opus's own clone, opus209\repo\godot, as round 7 did). Reads B0 (bakeoff), round 7's Ab7 glb (out7) and the A4 ship
rem files (build\godot\assets\ships, copied, never changed). Deletes nothing. No go file (the GPU is the Board's tonight); it still
rem waits for an idle graphics card first, because another helper captures on the same card.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set RC=%O%\repo\tools\recipe
set G=%O%\repo\godot
set TMO=%O%\repo\tools\pc\tmo.bat
set OUT=%O%\out8b
set B0=%V%\bakeoff\C15s_23_trellis.glb
set R209_SHIP=%RC%\ships\C15s_23.json
set R209_HULL=armA8
set CODE=C15s_23
for %%D in ("%OUT%" "%OUT%\r" "%OUT%\glb" "%OUT%\close" "%OUT%\godot\proj" "%OUT%\export\%CODE%" "%OUT%\fire") do if not exist %%D mkdir %%D
echo start %date% %time% > "%OUT%\time.txt"
set /a W=0
:gpuwait
set U=0
for /f %%U in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set U=%%U
if %U% LSS 15 goto gpufree
set /a W+=1
if %W% GEQ 90 goto gpufree
timeout /t 60 /nobreak > nul
goto gpuwait
:gpufree
echo gpu free after %W% min %date% %time% >> "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
rem ---- stage 5: bake Ab8 (hull and parts atlases at 4096), renders, close-ups
"%B%" -b -P "%R%\bakeAb6.py" -- "%OUT%" "%B0%" none Ab8 4096 64 > "%OUT%\log_Ab8.txt" 2>&1
echo baked %date% %time% >> "%OUT%\time.txt"
if not exist "%OUT%\Ab8.blend" (echo BAKE FAILED >> "%OUT%\time.txt" & goto finish)
"%B%" -b "%OUT%\Ab8.blend" -P "%R%\render.py" -- "%OUT%\r" Ab8 > "%OUT%\logr_Ab8.txt" 2>&1
"%B%" -b "%OUT%\Ab8.blend" -P "%R%\render.py" -- "%OUT%\r" Ab8 --views=concept --light=concept > "%OUT%\logrc_Ab8.txt" 2>&1
"%B%" -b "%OUT%\Ab8.blend" -P "%R%\render.py" -- "%OUT%\r" Ab8 --views=side_s,hero_s > "%OUT%\logrs_Ab8.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
"%B%" -b "%OUT%\Ab8.blend" -P "%R%\close6.py" -- "%OUT%\close" Ab8 > "%OUT%\logc_Ab8.txt" 2>&1
echo close %date% %time% >> "%OUT%\time.txt"
rem ---- stage 6: the hand LOD chain and the Godot cost bench, round 7's Ab7 beside it
"%B%" -b "%OUT%\Ab8.blend" -P "%R%\export3.py" -- "%OUT%\glb\Ab8.glb" > "%OUT%\logx_Ab8.txt" 2>&1
if exist "%O%\out7\glb\Ab7.glb" copy /y "%O%\out7\glb\Ab7.glb" "%OUT%\glb\Ab7.glb" > nul
if exist "%O%\out7\glb\Ab7_lods.json" copy /y "%O%\out7\glb\Ab7_lods.json" "%OUT%\glb\Ab7_lods.json" > nul
echo exported lod %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab7,Ab8 2 > "%OUT%\log_godot.txt" 2>&1
echo bench %date% %time% >> "%OUT%\time.txt"
rem ---- stage 7: the game export with hard points, its check, and the proof that the check can fail
set EX=%OUT%\export\%CODE%
"%B%" -b "%OUT%\Ab8.blend" -P "%RC%\export7.py" -- "%R209_SHIP%" "%EX%" maps=2048 > "%OUT%\log_export.txt" 2>&1
"%BPY%" "%RC%\check_export.py" "%R209_SHIP%" "%EX%" > "%OUT%\log_export_check.txt" 2>&1
set CHK=%errorlevel%
"%BPY%" "%RC%\check_export_selftest.py" "%R209_SHIP%" "%EX%" > "%OUT%\log_export_selftest.txt" 2>&1
echo export check exit %CHK% %date% %time% >> "%OUT%\time.txt"
if not "%CHK%"=="0" (echo EXPORT CHECK FAILED: no battle capture >> "%OUT%\time.txt" & goto finish)
rem ---- the game import, in Opus's own clone: the A4 ship files copied in from the build (copy only), Ab8's export in C15s_23's place
robocopy "%V%\build\godot\assets\ships" "%G%\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid %CODE%*.* /XD test previews /NP /NDL /R:1 /W:1 > "%OUT%\log_a4copy.txt" 2>&1
if not exist "%G%\assets\ships\%CODE%" mkdir "%G%\assets\ships\%CODE%"
copy /y "%EX%\%CODE%.glb" "%G%\assets\ships\%CODE%\" > nul
copy /y "%EX%\%CODE%*.jpg" "%G%\assets\ships\%CODE%\" > nul
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --import > "%OUT%\log_import.txt" 2>&1
echo imported %date% %time% >> "%OUT%\time.txt"
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --script res://render/build_assets.gd -- --repo "%O%\repo" --hi "%V%\enginetest\assets\hi" --env "%V%\enginetest\assets\env" > "%OUT%\log_build_assets.txt" 2>&1
findstr /c:"check %CODE%" "%OUT%\log_build_assets.txt" >> "%OUT%\time.txt"
echo assets %date% %time% >> "%OUT%\time.txt"
rem ---- the battle capture: the game's own default camera (r 170) at 1920x1080 (the ship at its played size), then r 62 and r 22
set VENT_OUT=%OUT%\fire
set VENT_ONLY=after
set VENT_RANGE=game,battle,close
set VENT_W=1920
set VENT_H=1080
set VENT_FPS=12
call "%TMO%" 1500 "%GD%" --path "%G%" --fixed-fps 60 --resolution 960x540 --position -2400,-1400 --script res://fx/test/ship_fire_probe.gd > "%OUT%\log_fire.txt" 2>&1
echo fire exit %errorlevel% %date% %time% >> "%OUT%\time.txt"
findstr /L /c:"[fire]" /c:"[vent]" /c:"VENT_DONE" /c:"SCRIPT ERROR" "%OUT%\log_fire.txt" > "%OUT%\fire\fire_report.txt"
:finish
echo done %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done8b.txt"
