@echo off
rem Issue 209 round 6 on Ryan's PC (Opus worker thread): Ab6 = Ab5's hull with the Hullbreaker kit weapons and the Hullbreaker paint.
rem Bake Ab6 on the 5080 (bakeAb6.py, parts atlas at full resolution), render it with the round 4 cameras (studio rig) plus the
rem concept view under the concept rig, render the weapon close-ups at the concept camera for Ab6 and for round 5's Ab5, export Ab6
rem with the hand LOD chain, run the Godot cost bench with Ab5 beside it. One GPU job at a time.
rem Started by pc\r6_queue.bat in its own window. Writes Downloads\voidsworn_test\opus209\out6\. Reads B0 (bakeoff), round 5's Ab5.blend
rem and glb (out5b); deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out6
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\close" mkdir "%OUT%\close"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
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
"%B%" -b -P "%R%\bakeAb6.py" -- "%OUT%" "%B0%" none Ab6 4096 64 > "%OUT%\log_Ab6.txt" 2>&1
echo baked %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab6.blend" "%B%" -b "%OUT%\Ab6.blend" -P "%R%\render.py" -- "%OUT%\r" Ab6 > "%OUT%\logr_Ab6.txt" 2>&1
if exist "%OUT%\Ab6.blend" "%B%" -b "%OUT%\Ab6.blend" -P "%R%\render.py" -- "%OUT%\r" Ab6 --views=concept --light=concept > "%OUT%\logrc_Ab6.txt" 2>&1
"%B%" -b "%O%\out5b\Ab5.blend" -P "%R%\render.py" -- "%OUT%\r" Ab5 --views=concept --light=concept > "%OUT%\logrc_Ab5.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab6.blend" "%B%" -b "%OUT%\Ab6.blend" -P "%R%\close6.py" -- "%OUT%\close" Ab6 > "%OUT%\logc_Ab6.txt" 2>&1
"%B%" -b "%O%\out5b\Ab5.blend" -P "%R%\close6.py" -- "%OUT%\close" Ab5 > "%OUT%\logc_Ab5.txt" 2>&1
echo close %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab6.blend" "%B%" -b "%OUT%\Ab6.blend" -P "%R%\export3.py" -- "%OUT%\glb\Ab6.glb" > "%OUT%\logx_Ab6.txt" 2>&1
copy /y "%O%\out5b\glb\Ab5.glb" "%OUT%\glb\Ab5.glb" > nul
copy /y "%O%\out5b\glb\Ab5_lods.json" "%OUT%\glb\Ab5_lods.json" > nul
echo exported %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab5,Ab6 2 > "%OUT%\log_godot.txt" 2>&1
echo godot %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
