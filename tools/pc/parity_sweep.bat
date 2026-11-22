@echo off
rem Voidsworn rules sweep: compare every record from Godot with its cache on and off.
rem Double-click it (200 battles), or run "parity_sweep.bat 200 1 nopause" from a watcher job (count, seed, nopause).
setlocal enableextensions disabledelayedexpansion
set "HERE=%~dp0"
set "RESULT=1"
set "N=%~1"
if "%N%"=="" set "N=200"
set "SEED=%~2"
if "%SEED%"=="" set "SEED=1"
set "GAME="
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find the Godot project ^(godot\project.godot next to this file or two folders up^). & goto :end )
set "PROJ=%GAME%godot\"
set "NODE="
set "GODOT="
for %%D in ("%GAME%.") do set "SEARCH=%%~fD"
rem Find the PC bundle above build or any board lane checkout, as in parity.bat.
:bundle
if not defined NODE if exist "%SEARCH%\node\node.exe" set "NODE=%SEARCH%\node\node.exe"
if not defined GODOT if exist "%SEARCH%\godot_path.txt" set /p GODOT=<"%SEARCH%\godot_path.txt"
for %%D in ("%SEARCH%\..") do set "NEXT=%%~fD"
if /i "%NEXT%"=="%SEARCH%" goto :bundle_done
set "SEARCH=%NEXT%"
goto :bundle
:bundle_done
if not defined NODE set "NODE=node"
if not defined GODOT if exist "%HERE%godot_path.txt" set /p GODOT=<"%HERE%godot_path.txt"
if not defined GODOT ( echo FAIL: no godot_path.txt found ^(it holds the path to the Godot console exe^). & goto :end )
"%NODE%" "%PROJ%rules\test\safety\run_cache_check.js" --godot "%GODOT%" --cache-only --sweep "%N%" "%SEED%"
set "RESULT=%ERRORLEVEL%"
:end
echo.
if /i not "%~3"=="nopause" pause
endlocal & exit /b %RESULT%
