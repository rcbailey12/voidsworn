@echo off
setlocal
rem Issue 195 review assets only. Does not install, commit, push or swap props.
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "REPO=%ROOT%\board\repo"
set "BEFORE=%ROOT%\board\issue-183\shots"
set "SHOTS=%ROOT%\board\issue-195\shots"
set "GODOT=%ROOT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "PYTHON=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set /p BLENDER=<"%ROOT%\blender_path.txt"
if not exist "%BEFORE%\refinery_detail.glb" (
  echo Missing issue 183 before models. Retain that review folder to rebuild.
  goto :failed
)
if not exist "%SHOTS%" mkdir "%SHOTS%"
for %%V in (fleet refinery) do (
  copy /y "%BEFORE%\%%V_detail.glb" "%SHOTS%\%%V_before.glb" >nul
  if not exist "%SHOTS%\%%V_local_masks.png" copy /y "%BEFORE%\%%V_local_masks.png" "%SHOTS%\%%V_local_masks.png" >nul
  if not exist "%SHOTS%\%%V_local_masks.sha256" copy /y "%BEFORE%\%%V_local_masks.sha256" "%SHOTS%\%%V_local_masks.sha256" >nul
)
pushd "%REPO%"
call "%REPO%\tools\pc\tmo.bat" 1200 "%BLENDER%" -b -t 12 --python-exit-code 1 -P "%REPO%\tools\blender\hs\station_kit.py" -- --detail --readable-paint --reuse-local-masks --faction ithar --out "%SHOTS%" > "%TEMP%\station195_bake.log" 2>&1
if errorlevel 1 goto :failed_pop
call "%REPO%\tools\pc\tmo.bat" 120 "%GODOT%" --headless --path "%ROOT%\build\godot" --log-file "%TEMP%\station195_import_engine.log" --script "%REPO%\tools\blender\hs\station_check.gd" -- --paint-check "%SHOTS%" > "%TEMP%\station195_import.log" 2>&1
if errorlevel 1 goto :failed_pop
for %%H in (1080 2160) do (
  for %%K in (before detail) do (
    call "%REPO%\tools\pc\tmo.bat" 180 "%GODOT%" --path "%ROOT%\build\godot" --windowed --resolution 960x540 --position -8000,-8000 --log-file "%TEMP%\station195_capture_engine.log" --script "%REPO%\tools\blender\hs\station_check.gd" -- --paint-review "%SHOTS%" "%REPO%\godot" %%K %%H > "%TEMP%\station195_capture_%%K_%%H.log" 2>&1
    if errorlevel 1 goto :failed_pop
  )
)
for %%K in (before detail) do (
  call "%REPO%\tools\pc\tmo.bat" 180 "%GODOT%" --path "%ROOT%\build\godot" --windowed --resolution 960x540 --position -8000,-8000 --log-file "%TEMP%\station195_measure_engine.log" --script "%REPO%\tools\blender\hs\station_check.gd" -- --measure "%SHOTS%" "%REPO%\godot" %%K > "%TEMP%\station195_measure_%%K.log" 2>&1
  if errorlevel 1 goto :failed_pop
)
"%PYTHON%" "%REPO%\tools\blender\hs\station_paint_sheets.py" "%SHOTS%" > "%TEMP%\station195_sheets.log" 2>&1
if errorlevel 1 goto :failed_pop
popd
echo Ready for Ryan's look: %SHOTS%\station_paint_overview.jpg
echo Native 1080p and 4K blur sheets are beside it.
echo The S10 brightness comparison needs an approved dark station reference.
pause
exit /b 0
:failed_pop
popd
:failed
echo Review build failed. Logs are in %TEMP%\station195_*.log.
pause
exit /b 1
