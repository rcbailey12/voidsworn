@echo off
rem Issue 209 round 2 on Ryan's PC (Opus worker thread): build the round 2 cells, render them (Cycles on the 5080), export them to
rem glb and run the Godot cost bench (20 copies, LOD off and on, 1080p and 3D at 4K). One GPU job at a time, all in sequence.
rem Started by a one-line queue job (pc\r2_queue.bat) so the queue stays free. Writes Downloads\voidsworn_test\opus209\out2\.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out2
set G=%O%\gen\3d
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
"%B%" -b -P "%R%\armA2.py" -- "%OUT%" 0 > "%OUT%\log_A2s.txt" 2>&1
echo A2s %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\armA2.py" -- "%OUT%" 2 > "%OUT%\log_A2.txt" 2>&1
echo A2 %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\armB2.py" -- B0r2 "%G%" "%B0%" "%OUT%" > "%OUT%\log_B0r2.txt" 2>&1
echo B0r2 %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\armB2.py" -- B3r2 "%G%" "%B0%" "%OUT%" > "%OUT%\log_B3r2.txt" 2>&1
echo B3r2 %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\bakeAb.py" -- "%OUT%" "%B0%" 4096 > "%OUT%\log_Ab.txt" 2>&1
echo Ab %date% %time% >> "%OUT%\time.txt"
for %%C in (A2 B3r2 Ab B0r2) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\render.py" -- "%OUT%\r" %%C > "%OUT%\logr_%%C.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
for %%C in (A2s A2 B3r2 Ab B0r2) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\export_glb.py" -- "%OUT%\glb\%%C.glb" > "%OUT%\logx_%%C.txt" 2>&1
for %%C in (A B3) do if exist "%O%\out\cells\%%C.blend" "%B%" -b "%O%\out\cells\%%C.blend" -P "%R%\export_glb.py" -- "%OUT%\glb\%%C.glb" > "%OUT%\logx_%%C.txt" 2>&1
echo exported %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209.gd" "%OUT%\godot\proj\" > nul
"%GD%" --headless --path "%OUT%\godot\proj" --script res://bench209.gd --check-only > "%OUT%\log_godot_parse.txt" 2>&1
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209.gd -- "%OUT%\glb" "%OUT%\godot" A,B3,A2s,A2,B3r2,Ab,B0r2 2 > "%OUT%\log_godot.txt" 2>&1
echo godot %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
