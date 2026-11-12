@echo off
rem Issue 559 (read-only trace): lean sparse clone of main's godot\ code, the two ships copied in, then the game's own asset
rem build, the game-side captures (probe559.gd) and the Blender-side renders (blend559.py). Writes only under opus559\.
setlocal
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus559"
set "B=%R%\blender\blender-4.5.14-windows-x64\blender.exe"
set /p G=<"%R%\godot_path.txt"
set "P=%D%\repo\godot"
cd /d "%D%"
echo start %date% %time% > "%D%\status.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%D%\gpuwait.ps1" -log "%D%\gpu_log.txt"
if errorlevel 1 (
  echo gpu busy for 40 minutes, stopped >> "%D%\status.txt"
  exit /b 1
)
echo gpu free %time% >> "%D%\status.txt"
if not exist "%D%\repo\.git" (
  git -c core.autocrlf=false clone --depth 1 --filter=blob:none --sparse https://github.com/rcbailey12/voidsworn.git "%D%\repo" > "%D%\log_clone.txt" 2>&1
  git -C "%D%\repo" sparse-checkout set --no-cone "/godot/*" "!/godot/music/" "!/godot/portraits/" "!/godot/audio/" "!/godot/fx/test/results/" "!/godot/assets/ships/previews/" >> "%D%\log_clone.txt" 2>&1
)
git -C "%D%\repo" rev-parse HEAD > "%D%\commit.txt"
if not exist "%P%\project.godot" (
  echo clone failed >> "%D%\status.txt"
  exit /b 1
)
if not exist "%P%\assets\ships\C19_51" mkdir "%P%\assets\ships\C19_51"
if not exist "%P%\assets\ships\C15s_23" mkdir "%P%\assets\ships\C15s_23"
if not exist "%P%\p559" mkdir "%P%\p559"
copy /y "%R%\build\godot\assets\ships\C19_51\C19_51.glb" "%P%\assets\ships\C19_51\" > nul
copy /y "%R%\build\godot\assets\ships\C19_51\C19_51_*.jpg" "%P%\assets\ships\C19_51\" > nul
copy /y "%R%\opus209\out7\export\C15s_23\C15s_23.glb" "%P%\assets\ships\C15s_23\" > nul
copy /y "%R%\opus209\out7\export\C15s_23\C15s_23_*.jpg" "%P%\assets\ships\C15s_23\" > nul
copy /y "%D%\probe559.gd" "%P%\p559\probe559.gd" > nul
echo copied %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 2400 "%G%" --headless --path "%P%" --import > "%D%\log_import.txt" 2>&1
echo import exit %errorlevel% %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 1200 "%G%" --headless --path "%P%" --script res://render/build_assets.gd -- --repo "%D%\norepo" > "%D%\log_build.txt" 2>&1
echo build_assets exit %errorlevel% %time% >> "%D%\status.txt"
set "P559_OUT=%D%\out_g"
set "P559_SHIPS=C19_51:corsair:Battle-barge,C15s_23:corsair:Cruiser"
call "%D%\tmo.bat" 1200 "%G%" --path "%P%" --windowed --resolution 480x270 --fixed-fps 60 --script res://p559/probe559.gd > "%D%\log_probe.txt" 2>&1
echo probe exit %errorlevel% %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 1800 "%B%" -b --factory-startup -P "%D%\blend559.py" -- "%D%\out_b" C19_51 41.6 "glb=%R%\a4\godot_hi\C19_51\C19_51.glb" > "%D%\log_blend_c19.txt" 2>&1
echo blender c19 exit %errorlevel% %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 1800 "%B%" -b "%R%\opus209\out7\Ab7.blend" -P "%D%\blend559.py" -- "%D%\out_b" C15s_23 23.2 > "%D%\log_blend_c15.txt" 2>&1
echo blender c15 exit %errorlevel% %time% >> "%D%\status.txt"
echo done %date% %time% >> "%D%\status.txt"
exit /b 0
