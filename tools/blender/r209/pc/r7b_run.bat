@echo off
rem Issue 209 round 7, step 5 only: the battle capture of Ab7 firing its port casemates. Reuses round 7's run (out7): no rebake,
rem no re-render, no re-export. The game's generated files from r7_run.bat stay in opus209\repo\godot (gen\ and
rem assets\ships\ are git-ignored, so the branch checkout leaves them); they are rebuilt only if missing or if the ship glb in
rem the game differs from out7's export. Writes Downloads\voidsworn_test\opus209\out7b\ only. Deletes nothing.
rem Why a repair: r7_run.bat's probe did not parse (an untyped variable) and its clip step needed Pillow, which Blender's
rem Python on the PC does not have. The probe now writes JPEG frames; the clip and the strip are built in the cloud sandbox.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set G=%O%\repo\godot
set TMO=%O%\repo\tools\pc\tmo.bat
set OUT=%O%\out7b
set EX=%O%\out7\export\C15s_23
set CODE=C15s_23
for %%D in ("%OUT%" "%OUT%\fire") do if not exist %%D mkdir %%D
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
echo start %date% %time% > "%OUT%\time.txt"
rem one GPU job at a time: wait (up to 90 minutes) until the 5080 is idle
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
rem are the game's built assets still there and built from out7's export?
set REBUILD=0
if not exist "%G%\gen\v3.txt" set REBUILD=1
if not exist "%G%\assets\ships\%CODE%\%CODE%.glb" set REBUILD=1
if "%REBUILD%"=="0" fc /b "%EX%\%CODE%.glb" "%G%\assets\ships\%CODE%\%CODE%.glb" > nul || set REBUILD=1
dir /tc "%G%\gen\v3.txt" "%G%\assets\ships\%CODE%\%CODE%.glb" "%EX%\%CODE%.glb" >> "%OUT%\time.txt" 2>&1
echo rebuild=%REBUILD% >> "%OUT%\time.txt"
if "%REBUILD%"=="0" goto fire
robocopy "%V%\build\godot\assets\ships" "%G%\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid %CODE%*.* /XD test previews /NP /NDL /R:1 /W:1 > "%OUT%\log_a4copy.txt" 2>&1
if not exist "%G%\assets\ships\%CODE%" mkdir "%G%\assets\ships\%CODE%"
copy /y "%EX%\%CODE%.glb" "%G%\assets\ships\%CODE%\" > nul
copy /y "%EX%\%CODE%*.jpg" "%G%\assets\ships\%CODE%\" > nul
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --import > "%OUT%\log_import.txt" 2>&1
call "%TMO%" 2400 "%GD%" --headless --path "%G%" --script res://render/build_assets.gd -- --repo "%O%\repo" --hi "%V%\enginetest\assets\hi" --env "%V%\enginetest\assets\env" > "%OUT%\log_build_assets.txt" 2>&1
findstr /c:"check %CODE%" "%OUT%\log_build_assets.txt" >> "%OUT%\time.txt"
echo assets %date% %time% >> "%OUT%\time.txt"
:fire
rem the probe: the game's own default camera (r 170) at 1920x1080 so the ship is drawn at its played size, then r 62 and r 22
set VENT_OUT=%OUT%\fire
set VENT_ONLY=after
set VENT_RANGE=game,battle,close
set VENT_W=1920
set VENT_H=1080
set VENT_FPS=12
call "%TMO%" 1500 "%GD%" --path "%G%" --fixed-fps 60 --resolution 960x540 --position -2400,-1400 --script res://fx/test/ship_fire_probe.gd > "%OUT%\log_fire.txt" 2>&1
echo fire exit %errorlevel% %date% %time% >> "%OUT%\time.txt"
findstr /L /c:"[fire]" /c:"[vent]" /c:"VENT_DONE" /c:"SCRIPT ERROR" "%OUT%\log_fire.txt" > "%OUT%\fire\fire_report.txt"
echo done > "%OUT%\done7b.txt"
