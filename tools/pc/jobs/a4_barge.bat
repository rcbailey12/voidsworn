@echo off
rem A4: the Pyre-Barge (C19_51) into the A4 Godot format from its approved A2 8K painted files (tools/blender/a4/barge4.py).
rem Needs build\a4tools (tools/blender/a4/stage.py) and comfy_io\a2detail\C19_51_shell.glb, C19_51_kit.glb (the A2 job's output).
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set A4=%USERPROFILE%\Downloads\voidsworn_test\a4
set A2=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\a2detail
set OUT=%A4%\out\C19_51
if not exist "%OUT%" mkdir "%OUT%"
echo --- a4 C19_51 (barge): import, re-bake onto one atlas, hard points, wreck ---
call tools\pc\tmo.bat 900 %BL% -b --factory-startup -P a4tools\a4\barge4.py -- "%A2%\C19_51_shell.glb" "%A2%\C19_51_kit.glb" "%OUT%" --res 4096 --checks "%OUT%\checks" > "%OUT%\build_log.txt" 2>&1
type "%OUT%\build_log.txt" | findstr /l /c:"[barge4]" /c:"[a2]" /c:"[wreck]" /c:"Error" /c:"Traceback"
call tools\pc\tmo.bat 300 %PY% -s a4tools\a4\pack.py "%OUT%\C19_51_meta.json" "%A4%\godot" --res auto --hi "%A4%\godot_hi" --hires 4096
call tools\pc\tmo.bat 120 %PY% -s a4tools\a4\sheet.py "%OUT%\checks" C19_51
call tools\pc\tmo.bat 300 %BL% -b --factory-startup -P a4tools\a2detail\reimport.py -- "%A4%\godot\C19_51\C19_51.glb" "%A4%\godot\C19_51\C19_51_wreck.glb" > "%OUT%\reimport_log.txt" 2>&1
type "%OUT%\reimport_log.txt" | findstr /l /c:"[reimport]"
dir /b "%A4%\godot\C19_51"
echo --- a4 C19_51 done ---
exit /b
