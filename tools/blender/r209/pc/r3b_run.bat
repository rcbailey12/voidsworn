@echo off
rem Issue 209 round 3, second PC run: the hybrid (Hy3) again with its generated hero parts on their own texture atlas (the first run
rem packed them in with the hand parts and they baked black), then its renders and LOD export, then the Godot bench for all three
rem cells. Writes Downloads\voidsworn_test\opus209\out3b\ (Ab3 is copied from out3). Deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out3b
set G=%O%\gen\3d
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
"%B%" -b -P "%R%\bakeAb3.py" -- "%OUT%" "%B0%" "%G%" Hy3 4096 64 > "%OUT%\log_Hy3.txt" 2>&1
echo Hy3 %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Hy3.blend" "%B%" -b "%OUT%\Hy3.blend" -P "%R%\render.py" -- "%OUT%\r" Hy3 > "%OUT%\logr_Hy3.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Hy3.blend" "%B%" -b "%OUT%\Hy3.blend" -P "%R%\export3.py" -- "%OUT%\glb\Hy3.glb" > "%OUT%\logx_Hy3.txt" 2>&1
copy /y "%O%\out3\glb\Ab3.glb" "%OUT%\glb\Ab3.glb" > nul
copy /y "%O%\out3\glb\Ab3_lods.json" "%OUT%\glb\Ab3_lods.json" > nul
if exist "%O%\out2\glb\Ab.glb" copy /y "%O%\out2\glb\Ab.glb" "%OUT%\glb\Ab.glb" > nul
echo exported %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab,Ab3,Hy3 2 > "%OUT%\log_godot.txt" 2>&1
echo godot %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
