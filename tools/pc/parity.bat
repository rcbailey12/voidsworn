@echo off
rem Rules parity: the same five steps and diagnostics as run_parity.sh, with separate start /b workers.
rem Double-click, or parity.bat nopause from a watcher. Records and parity_log.txt are kept in TEMP.
setlocal enableextensions disabledelayedexpansion
set "HERE=%~dp0"
set "GAME="
set "RESULT=1"
if exist "%HERE%godot\project.godot" set "GAME=%HERE%"
if not defined GAME if exist "%HERE%..\..\godot\project.godot" set "GAME=%HERE%..\..\"
if not defined GAME ( echo FAIL: cannot find godot\project.godot. & goto :end )
for %%D in ("%GAME%.") do set "GAME=%%~fD"
set "NODE="
set "GODOT="
set "SEARCH=%GAME%"
rem Find the PC bundle above build or any board lane checkout, without relying on PATH.
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
if not defined GODOT ( echo FAIL: no godot_path.txt found. & goto :end )
"%NODE%" "%GAME%\godot\rules\test\node\run_parity.js"
set "RESULT=%ERRORLEVEL%"
rem Keep the existing campaign hand-off. Its implementation and coverage are unchanged.
if exist "%HERE%parity_campaign.bat" (
  call "%HERE%parity_campaign.bat" nopause
) else if exist "%HERE%tools\pc\parity_campaign.bat" (
  call "%HERE%tools\pc\parity_campaign.bat" nopause
) else (
  echo FAIL: parity_campaign.bat not found next to parity.bat or in tools\pc\.
  set "RESULT=1"
  goto :end
)
if errorlevel 1 set "RESULT=1"
:end
echo.
if /i not "%~1"=="nopause" pause
endlocal & exit /b %RESULT%
