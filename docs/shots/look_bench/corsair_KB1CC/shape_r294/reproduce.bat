@echo off
setlocal
set "KB903_REPO=%~dp0..\..\..\..\.."
if not exist "%KB903_REPO%\tools\blender\build_sheets\ships\corsair_KB1CC.py" set "KB903_REPO=%~dp0..\..\repo"
cd /d "%KB903_REPO%"
python "docs\shots\look_bench\corsair_KB1CC\shape_r294\reproduce.py" "%TEMP%\voidsworn903" all
if errorlevel 1 (
  echo KB1CC rebuild failed. Read the named log in %%TEMP%%\voidsworn903.
  pause
  exit /b 1
)
echo KB1CC review pictures are beside this file and in board_b\issue-903\shots.
pause
exit /b 0
