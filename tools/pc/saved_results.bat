@echo off
rem Double-click for fresh parity and saved Godot results, using one Godot run. Watchers use nopause.
setlocal enableextensions disabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
set "RESULT=1"
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find godot\project.godot. & goto :end )
for %%D in ("%GAME%.") do set "GAME=%%~fD"
set "NODE="
set "SEARCH=%GAME%"
:bundle
if not defined NODE if exist "%SEARCH%\node\node.exe" set "NODE=%SEARCH%\node\node.exe"
if not defined GODOT if exist "%SEARCH%\godot_path.txt" set /p GODOT=<"%SEARCH%\godot_path.txt"
for %%D in ("%SEARCH%\..") do set "NEXT=%%~fD"
if /i "%NEXT%"=="%SEARCH%" goto :bundle_done
set "SEARCH=%NEXT%"
goto :bundle
:bundle_done
if not defined NODE set "NODE=node"
if not defined GODOT ( echo FAIL: set GODOT or supply godot_path.txt above this checkout. & goto :end )
"%NODE%" "%GAME%\godot\rules\test\saved\check.js"
set "RESULT=%ERRORLEVEL%"
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal & exit /b %RESULT%
