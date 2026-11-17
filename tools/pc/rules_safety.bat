@echo off
rem Double-click for both Godot-only rules safety checks. Watchers use nopause.
setlocal
set "HERE=%~dp0"
set "GAME="
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME (
  echo FAIL: cannot find godot\project.godot beside this launcher or two folders up.
  set "RESULT=1"
  goto :end
)
set "NODE=node"
if exist "%GAME%..\node\node.exe" set "NODE=%GAME%..\node\node.exe"
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not defined GODOT if exist "%GAME%..\godot_path.txt" set /p GODOT=<"%GAME%..\godot_path.txt"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT if exist "%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt" set /p GODOT=<"%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt"
if not defined GODOT (
  echo FAIL: set GODOT to the Godot console exe, or put its path in godot_path.txt.
  set "RESULT=1"
  goto :end
)
rem Optional RULES_SAFETY_WORKERS overrides the default four CPU workers.
set "WORKERS=4"
if defined RULES_SAFETY_WORKERS set "WORKERS=%RULES_SAFETY_WORKERS%"
"%NODE%" "%GAME%godot\rules\test\safety\run_cache_check.js" --project "%GAME%godot" --workers "%WORKERS%"
set "RESULT=%ERRORLEVEL%"
:end
echo.
if /i not "%~1"=="nopause" pause
exit /b %RESULT%
