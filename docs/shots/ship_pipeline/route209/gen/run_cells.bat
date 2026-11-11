@echo off
rem Opus #209 round 1: build every cell and render it (Blender 4.5 on the GPU). Waits for the TRELLIS pass. Logs in opus209\out\.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out\cells
if not exist "%OUT%\r" mkdir "%OUT%\r"
:wait
if exist "%O%\gen\trellis_done4.txt" goto go
timeout /t 20 /nobreak >nul
goto wait
:go
echo start %date% %time% > "%O%\out\cells_time.txt"
"%B%" -b -P "%R%\armA.py" -- "%OUT%" > "%O%\out\log_A.txt" 2>&1
for %%C in (B0 B1 B2 B3) do "%B%" -b -P "%R%\armB.py" -- %%C "%O%\gen\3d" "%V%\bakeoff\C15s_23_trellis.glb" "%OUT%" > "%O%\out\log_%%C.txt" 2>&1
echo built %date% %time% >> "%O%\out\cells_time.txt"
for %%C in (A B0 B1 B2 B3) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\render.py" -- "%OUT%\r" %%C > "%O%\out\logr_%%C.txt" 2>&1
echo rendered %date% %time% >> "%O%\out\cells_time.txt"
echo done > "%O%\out\cells_done.txt"
