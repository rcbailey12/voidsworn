@echo off
rem Issue 209 round 7 on Ryan's PC (Opus worker thread): Ab7 = Ab6 with level casemates, the texture and paint pass, the bow pass,
rem then recipe stage 7 (the game export with hard points) and one battle capture of Ab7 firing its port casemates.
rem GPU RULE: nothing here touches the graphics card until Downloads\voidsworn_test\opus209\go7.txt exists. The Board commits that
rem file when Ryan gives a GPU window. This window checks every 30 seconds and otherwise just waits.
rem Started by pc\r7_queue.bat in its own window. Writes Downloads\voidsworn_test\opus209\out7\ (and builds the game's generated
rem files inside Opus's own clone, opus209\repo\godot). Reads B0 (bakeoff), round 6's Ab6 glb (out6f) and the A4 ship files
rem (build\godot\assets\ships, copied, never changed). Deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set RC=%O%\repo\tools\recipe
set G=%O%\repo\godot
set TMO=%O%\repo\tools\pc\tmo.bat
set OUT=%O%\out7
set B0=%V%\bakeoff\C15s_23_trellis.glb
set R209_SHIP=%RC%\ships\C15s_23.json
set R209_HULL=armA7
set CODE=C15s_23
for %%D in ("%OUT%" "%OUT%\r" "%OUT%\glb" "%OUT%\close" "%OUT%\godot\proj" "%OUT%\export\%CODE%" "%OUT%\fire") do if not exist %%D mkdir %%D
echo waiting for go7.txt since %date% %time% > "%OUT%\time.txt"
:gowait
if exist "%O%\go7.txt" goto go
timeout /t 30 /nobreak > nul
goto gowait
:go
echo go %date% %time% >> "%OUT%\time.txt"
rem one GPU job at a time: wait (up to 90 minutes) until the 5080 is idle, in case another thread's GPU run is still going
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
rem ---- stage 5: bake Ab7 (hull and parts atlases at 4096), render it with the round 4 cameras plus the concept view under the concept rig
"%B%" -b -P "%R%\bakeAb6.py" -- "%OUT%" "%B0%" none Ab7 4096 64 > "%OUT%\log_Ab7.txt" 2>&1
echo baked %date% %time% >> "%OUT%\time.txt"
if not exist "%OUT%\Ab7.blend" (echo BAKE FAILED >> "%OUT%\time.txt" & goto finish)
"%B%" -b "%OUT%\Ab7.blend" -P "%R%\render.py" -- "%OUT%\r" Ab7 > "%OUT%\logr_Ab7.txt" 2>&1
"%B%" -b "%OUT%\Ab7.blend" -P "%R%\render.py" -- "%OUT%\r" Ab7 --views=concept --light=concept > "%OUT%\logrc_Ab7.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
"%B%" -b "%OUT%\Ab7.blend" -P "%R%\close6.py" -- "%OUT%\close" Ab7 > "%OUT%\logc_Ab7.txt" 2>&1
echo close %date% %time% >> "%OUT%\time.txt"
rem ---- stage 6: the hand LOD chain and the Godot cost bench, round 6's Ab6 beside it
"%B%" -b "%OUT%\Ab7.blend" -P "%R%\export3.py" -- "%OUT%\glb\Ab7.glb" > "%OUT%\logx_Ab7.txt" 2>&1
if exist "%O%\out6f\glb\Ab6.glb" copy /y "%O%\out6f\glb\Ab6.glb" "%OUT%\glb\Ab6.glb" > nul
if exist "%O%\out6f\glb\Ab6_lods.json" copy /y "%O%\out6f\glb\Ab6_lods.json" "%OUT%\glb\Ab6_lods.json" > nul
echo exported lod %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab6,Ab7 2 > "%OUT%\log_godot.txt" 2>&1
echo bench %date% %time% >> "%OUT%\time.txt"
rem ---- stage 7: the game export with hard points, its check, and the proof that the check can fail
set EX=%OUT%\export\%CODE%
"%B%" -b "%OUT%\Ab7.blend" -P "%RC%\export7.py" -- "%R209_SHIP%" "%EX%" maps=2048 > "%OUT%\log_export.txt" 2>&1
"%BPY%" "%RC%\check_export.py" "%R209_SHIP%" "%EX%" > "%OUT%\log_export_check.txt" 2>&1
set CHK=%errorlevel%
"%BPY%" "%RC%\check_export_selftest.py" "%R209_SHIP%" "%EX%" > "%OUT%\log_export_selftest.txt" 2>&1
echo export check exit %CHK% %date% %time% >> "%OUT%\time.txt"
if not "%CHK%"=="0" (echo EXPORT CHECK FAILED: no battle capture >> "%OUT%\time.txt" & goto finish)
rem ---- step 5: the battle capture, in Opus's own clone. The A4 ship files are copied in from the build (copy only), except the
rem old C15s_23 (its wreck and damage pieces belong to the old hull); Ab7's export goes in its place.
robocopy "%V%\build\godot\assets\ships" "%G%\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid %CODE%*.* /XD test previews /NP /NDL /R:1 /W:1 > "%OUT%\log_a4copy.txt" 2>&1
if not exist "%G%\assets\ships\%CODE%" mkdir "%G%\assets\ships\%CODE%"
copy /y "%EX%\%CODE%.glb" "%G%\assets\ships\%CODE%\" > nul
copy /y "%EX%\%CODE%*.jpg" "%G%\assets\ships\%CODE%\" > nul
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --import > "%OUT%\log_import.txt" 2>&1
echo imported %date% %time% >> "%OUT%\time.txt"
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --script res://render/build_assets.gd -- --repo "%O%\repo" --hi "%V%\enginetest\assets\hi" --env "%V%\enginetest\assets\env" > "%OUT%\log_build_assets.txt" 2>&1
for %%N in (2 3) do if not exist "%G%\gen\v3.txt" call "%TMO%" 2400 "%GD%" --headless --path "%G%" --script res://render/build_assets.gd -- --repo "%O%\repo" --hi "%V%\enginetest\assets\hi" --env "%V%\enginetest\assets\env" >> "%OUT%\log_build_assets.txt" 2>&1
findstr /c:"check %CODE%" "%OUT%\log_build_assets.txt" >> "%OUT%\time.txt"
echo assets %date% %time% >> "%OUT%\time.txt"
set VENT_OUT=%OUT%\fire
set VENT_ONLY=after
set VENT_W=960
set VENT_H=540
set VENT_FPS=12
call "%TMO%" 1200 "%GD%" --path "%G%" --fixed-fps 60 --resolution 960x540 --position -2400,-1400 --script res://fx/test/ship_fire_probe.gd > "%OUT%\log_fire.txt" 2>&1
findstr /c:"[fire]" "%OUT%\log_fire.txt" > "%OUT%\fire\fire_report.txt"
"%BPY%" "%R%\fire_clip.py" "%OUT%\fire" > "%OUT%\log_fire_clip.txt" 2>&1
echo fire %date% %time% >> "%OUT%\time.txt"
:finish
echo done > "%OUT%\done7.txt"
