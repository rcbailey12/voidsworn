@echo off
rem A2 engine test, max-detail round: five flagships at 8K plus the barge re-bake, into enginetest\assets\hi\.
rem Runs from Downloads\voidsworn_test\build. Needs (copied in first): build\a2detail\ = the repo's tools\blender\a2detail\*.py plus
rem tools\blender\hs\hs_lib.py and tools\blender\hs\detail_lib.py; build\hulls_hi\ (already there); build\project_paint.py (already there).
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51\v15
set A2=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\a2detail
set OUT=%USERPROFILE%\Downloads\voidsworn_test\enginetest\assets\hi
set CHK=%A2%\checks
set RES=8192
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%A2%\barge" mkdir "%A2%\barge"
if not exist "%CHK%" mkdir "%CHK%"
echo --- a2_detail: max-detail flagships at %RES% --- >> %L%
if not exist a2detail\a2_ship.py echo a2_detail: build\a2detail is missing, copy it in first >> %L%
if not exist a2detail\a2_ship.py goto done
set A2_ROOT=%CD%
set CHECK_SAMPLES=32
for %%C in (V1b_r_23 H4_11 B16_23 I8_37 D22_23) do (
  echo a2_detail: %%C >> %L%
  %BL% -b --factory-startup -P a2detail\a2_ship.py -- %%C "%A2%" %RES% --samples 24 --checks "%CHK%" > "%A2%\%%C_log.txt" 2>&1
  type "%A2%\%%C_log.txt" | findstr /l /c:"[a2]" /c:"dress " /c:"spires" /c:"Error" /c:"Traceback" >> %L%
  %PY% -s a2detail\pack_glb.py "%A2%\%%C_meta.json" >> %L% 2>&1
  %PY% -s a2detail\pack_glb.py --sheets "%CHK%" %%C >> %L% 2>&1
  if exist "%A2%\%%C.glb" copy /y "%A2%\%%C.glb" "%OUT%\%%C.glb" >nul
)
echo --- a2_detail: barge re-bake at %RES% (project_paint PAINT=proc, as c19_v15d) --- >> %L%
set PAINT=proc
set PATCH=
set OCC=%IO%\v15_kit.glb
set EXPORT=%A2%\barge\shell_painted.glb
%BL% -b --factory-startup -P project_paint.py -- "%IO%\v15_shell.glb" "%A2%\barge\shell_albproj.png" %RES% > "%A2%\barge\shellproj_log.txt" 2>&1
type "%A2%\barge\shellproj_log.txt" | findstr /i /c:"baked" /c:"Error" /c:"Traceback" >> %L%
set OCC=%IO%\v15_shell.glb
set EXPORT=%A2%\barge\kit_painted.glb
set AOD=.015
%BL% -b --factory-startup -P project_paint.py -- "%IO%\v15_kit.glb" "%A2%\barge\kit_albproj.png" %RES% > "%A2%\barge\kitproj_log.txt" 2>&1
type "%A2%\barge\kitproj_log.txt" | findstr /i /c:"baked" /c:"Error" /c:"Traceback" >> %L%
set OCC=
set EXPORT=
set AOD=
set PAINT=
set PATCH=
%BL% -b --factory-startup -P a2detail\a2_barge.py -- "%A2%\barge" "%A2%" %RES% --checks "%CHK%" > "%A2%\barge_log.txt" 2>&1
type "%A2%\barge_log.txt" | findstr /l /c:"[a2b]" /c:"Error" /c:"Traceback" >> %L%
%PY% -s a2detail\pack_glb.py "%A2%\C19_51_shell_meta.json" "%A2%\C19_51_kit_meta.json" >> %L% 2>&1
%PY% -s a2detail\pack_glb.py --sheets "%CHK%" C19_51 >> %L% 2>&1
if exist "%A2%\C19_51_shell.glb" copy /y "%A2%\C19_51_shell.glb" "%OUT%\C19_51_shell.glb" >nul
if exist "%A2%\C19_51_kit.glb" copy /y "%A2%\C19_51_kit.glb" "%OUT%\C19_51_kit.glb" >nul
set A2_ROOT=
set CHECK_SAMPLES=
dir /b "%OUT%" >> %L%
:done
echo --- a2_detail done --- >> %L%
cd /d "%~dp0"
