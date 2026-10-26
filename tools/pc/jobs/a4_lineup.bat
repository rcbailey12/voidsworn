@echo off
rem A4: a faction lineup sheet from the packed Godot files (tools/blender/a4/lineup.py). Set A4TITLE and A4SHIPS (codes) first.
rem Output: voidsworn_test\a4\lineups\<A4TAG>.png
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set A4=%USERPROFILE%\Downloads\voidsworn_test\a4
if not exist "%A4%\lineups" mkdir "%A4%\lineups"
call tools\pc\tmo.bat 600 %BL% -b --factory-startup -P a4tools\a4\lineup.py -- "%A4%\godot" "%A4%\lineups\%A4TAG%.webp" "%A4TITLE%" %A4SHIPS% --samples 48 > "%A4%\lineups\%A4TAG%_log.txt" 2>&1
type "%A4%\lineups\%A4TAG%_log.txt" | findstr /l /c:"[lineup]" /c:"Error" /c:"Traceback"
call tools\pc\tmo.bat 120 %PY% -s a4tools\a4\lineup.py --compose "%A4%\lineups\%A4TAG%.webp_layout.json"
exit /b
