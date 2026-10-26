@echo off
rem A4 kit rollout: build, bake, check and pack ONE ship on Ryan's PC (keeps each queued job well under 20 minutes).
rem Queue it as a copy named per ship, with the ship code on the first line after this comment block set below, e.g. queue\a4_C13s_23_1.bat.
rem Needs (copied in first, from a fresh staging folder): build\a4tools\a4\*.py, build\a4tools\a2detail\*.py, build\a4tools\hs\{hs_lib,detail_lib}.py.
rem hulls_hi\ is already in build\. Output: voidsworn_test\a4\out\CODE\ (log, bakes, check renders and sheets) and
rem voidsworn_test\a4\godot\CODE\ (2048 textures, what goes into the repo) and voidsworn_test\a4\godot_hi\CODE\ (4096, PC only).
if "%A4CODE%"=="" set A4CODE=C13s_23
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set A4=%USERPROFILE%\Downloads\voidsworn_test\a4
set OUT=%A4%\out\%A4CODE%
if not exist "%OUT%" mkdir "%OUT%"
if not exist a4tools\a4\a4_ship.py echo a4: build\a4tools is missing, copy it in first
if not exist a4tools\a4\a4_ship.py goto done
set A4_ROOT=%CD%
set CHECK_SAMPLES=24
echo --- a4 %A4CODE%: build and bake ---
%BL% -b --factory-startup -P a4tools\a4\a4_ship.py -- %A4CODE% "%OUT%" --res 4096 --samples 16 --checks "%OUT%\checks" > "%OUT%\build_log.txt" 2>&1
type "%OUT%\build_log.txt" | findstr /l /c:"[a4]" /c:"[a2]" /c:"[wreck]" /c:"[kit]" /c:"dress " /c:"Error" /c:"Traceback"
echo --- a4 %A4CODE%: pack ---
%PY% -s a4tools\a4\pack.py "%OUT%\%A4CODE%_meta.json" "%A4%\godot" --res 2048 --hi "%A4%\godot_hi" --hires 4096
%PY% -s -c "import sys; sys.path.insert(0, r'a4tools\a2detail'); import checks_sheet; checks_sheet.make(r'%OUT%\checks', '%A4CODE%')"
%BL% -b --factory-startup -P a4tools\a2detail\reimport.py -- "%A4%\godot\%A4CODE%\%A4CODE%.glb" "%A4%\godot\%A4CODE%\%A4CODE%_wreck.glb" 2>nul | findstr /l /c:"[reimport]"
dir /b "%A4%\godot\%A4CODE%"
:done
set A4_ROOT=
set CHECK_SAMPLES=
echo --- a4 %A4CODE% done ---
cd /d "%~dp0"
exit /b
