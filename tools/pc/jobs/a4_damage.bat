@echo off
rem A4 breach damage (R39) for ships that are already built: re-pack each (the ship glb gains its skin_<n> patches, CODE_damage.glb is
rem written next to it, 2048 and 4096 sets) and render the damage review sheet. No rebake. Called from a queued job:
rem   set A4DMG=C13s_23 C14s_23 ...   then   call a4tools\a4_damage.bat
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set A4=%USERPROFILE%\Downloads\voidsworn_test\a4
if "%A4DMG%"=="" set A4DMG=C13s_23
for %%C in (%A4DMG%) do call :one %%C
goto done
:one
set OUT=%A4%\out\%1
if not exist "%OUT%\%1_meta.json" echo a4 damage: %1 is not built yet
if not exist "%OUT%\%1_meta.json" goto :eof
echo --- a4 damage %1 ---
call tools\pc\tmo.bat 300 %PY% -s a4tools\a4\pack.py "%OUT%\%1_meta.json" "%A4%\godot" --res auto --hi "%A4%\godot_hi" --hires 4096
call tools\pc\tmo.bat 600 %BL% -b --factory-startup -P a4tools\a4\dmgview.py -- "%OUT%\%1_ship.npz" "%OUT%\%1_meta.json" "%OUT%\dmg\%1_damage.png" > "%OUT%\dmg_log.txt" 2>&1
type "%OUT%\dmg_log.txt" | findstr /l /c:"dmgview" /c:"Error" /c:"Traceback"
call tools\pc\tmo.bat 60 %PY% -s a4tools\a4\dmgview.py --compose "%OUT%\dmg\%1_damage.png_layout.json"
if not exist "%CD%\godot\assets\ships\%1" mkdir "%CD%\godot\assets\ships\%1"
xcopy "%A4%\godot\%1\*" "%CD%\godot\assets\ships\%1\" /y /q
goto :eof
:done
call tools\pc\tmo.bat 300 %PY% -s a4tools\a4\manifest.py "%A4%\godot" "%A4%\out" "%A4%\manifest"
set A4DMG=
echo --- a4 damage done ---
exit /b
