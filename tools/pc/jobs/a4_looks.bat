@echo off
rem A4: Workbench look sheets (coordinate grid) of raw hulls on the PC GPU, for planning cuts and parts. Set A4LOOK to the hull codes.
rem Needs build\a4tools (tools/blender/a4/stage.py). Output: voidsworn_test\a4\looks\CODE_look.png
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set LK=%USERPROFILE%\Downloads\voidsworn_test\a4\looks
if not exist "%LK%" mkdir "%LK%"
set A4_ROOT=%CD%
call tools\pc\tmo.bat 900 %BL% -b --factory-startup -P a4tools\a4\look.py -- "%LK%" %A4LOOK% > "%LK%\looks_log.txt" 2>&1
type "%LK%\looks_log.txt" | findstr /l /c:"look:" /c:"Error" /c:"Traceback"
for %%F in ("%LK%\*_layout.json") do call tools\pc\tmo.bat 60 %PY% -s a4tools\a4\look.py --compose "%%F"
for %%F in ("%LK%\*_layout.json") do del "%%F"
dir /b "%LK%\*.png"
set A4_ROOT=
exit /b
