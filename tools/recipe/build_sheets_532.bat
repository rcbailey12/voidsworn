@echo off
setlocal
rem Issue 532 only. Rebuilds reference sheets, never installs game assets.
for %%I in ("%~dp0..\..") do set SHEET_REPO=%%~fI
set SHEET_PC=%USERPROFILE%\Downloads\voidsworn_test
set SHEET_ROOT=%SHEET_PC%\board\issue-532\shots
set SHEET_PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe
set SHEET_TPY=%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe
set SHEET_BLENDER=%SHEET_PC%\blender\blender-4.5.14-windows-x64\blender.exe
set SHEET_SCRIPT=%SHEET_REPO%\tools\recipe\build_sheets_532.py
set PYTHONPYCACHEPREFIX=%TEMP%\issue532_pycache
cd /d "%SHEET_REPO%"
echo Checking for another Blender or AI job before using the GPU...
powershell -NoProfile -Command "$p=Get-Process blender,python,pythonw -ErrorAction SilentlyContinue; if($p){$p | Select-Object Id,ProcessName; exit 1}; exit 0"
if errorlevel 1 (echo Another Blender or AI process is running. Try again when it finishes. & goto bad)
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv
"%SHEET_PY%" "%SHEET_SCRIPT%" prep "%SHEET_ROOT%"
if errorlevel 1 goto bad
"%SHEET_TPY%" "%SHEET_SCRIPT%" shape "%SHEET_ROOT%" > "%TEMP%\issue532_shape_v2.log" 2>&1
if errorlevel 1 goto bad
rem Reuse the reviewed, frozen fit. Geometry fitting commands remain available
rem in the Python script for a new concept; regeneration is deterministic.
"%SHEET_PY%" "%SHEET_SCRIPT%" restore "%SHEET_ROOT%"
if errorlevel 1 goto bad
"%SHEET_BLENDER%" -b -P "%SHEET_SCRIPT%" -- render "%SHEET_ROOT%" > "%TEMP%\issue532_render.log" 2>&1
if errorlevel 1 goto bad
"%SHEET_PY%" "%SHEET_SCRIPT%" sheets "%SHEET_ROOT%"
if errorlevel 1 goto bad
"%SHEET_PY%" "%SHEET_SCRIPT%" check "%SHEET_ROOT%"
if errorlevel 1 goto bad
echo PASS: both measured sheets rebuilt. Pictures are in %SHEET_ROOT%
pause
exit /b 0
:bad
echo FAILED: the build sheet checks did not pass. Logs are in TEMP, named issue532.
pause
exit /b 1
