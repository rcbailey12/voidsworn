@echo off
rem ============================================================================
rem  VOIDSWORN CUTOVER GATE - double-click launcher
rem
rem  Runs every verification tool (findings regression suite, oracle drift
rem  guard, data validators, importer fixture and converter checks, telemetry
rem  demonstration) against the game repo and writes one verdict report:
rem  gate_report.md beside this file.
rem
rem  HOW TO POINT IT AT THE REPO (first match wins):
rem    1. Drag the repo folder onto this .bat, or pass its path as argument 1.
rem    2. If this file lives inside the repo at
rem       contrib\muse\tools\cutover_gate\, the repo root is found from here.
rem    3. %USERPROFILE%\workspace\voidsworn-fresh, when it exists.
rem    4. Otherwise you are asked to type the path.
rem
rem  Requires Node.js on PATH. No Python, no installs, nothing is modified
rem  in the repo: the gate only reads it.
rem ============================================================================
setlocal

set "GATE_DIR=%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js was not found on PATH.
  echo Install Node from https://nodejs.org and run this again.
  pause
  exit /b 1
)

set "REPO=%~1"
if not "%REPO%"=="" goto have_repo

rem Inside-the-repo default: four levels up from contrib\muse\tools\cutover_gate
if exist "%GATE_DIR%..\..\..\..\battle.js" (
  set "REPO=%GATE_DIR%..\..\..\.."
  goto have_repo
)

if exist "%USERPROFILE%\workspace\voidsworn-fresh\battle.js" (
  set "REPO=%USERPROFILE%\workspace\voidsworn-fresh"
  goto have_repo
)

set /p "REPO=Type the full path to the voidsworn repo folder and press Enter: "

:have_repo
if not exist "%REPO%\battle.js" (
  echo.
  echo That folder does not look like the voidsworn repo ^(no battle.js in it^):
  echo   %REPO%
  pause
  exit /b 1
)

echo Running the cutover gate against:
echo   %REPO%
echo This takes about fifteen seconds. Nothing in the repo is changed.
echo.

node "%GATE_DIR%gate.js" "%REPO%"
set "GATE_EXIT=%ERRORLEVEL%"

echo.
echo Report written to:
echo   %GATE_DIR%gate_report.md
echo.

rem Open the report in the default Markdown/text viewer. If the association
rem fails, the path above is on screen and the pause below keeps it there.
start "" "%GATE_DIR%gate_report.md" >nul 2>nul

if "%GATE_EXIT%"=="1" echo NOTE: the gate exit code was 1 - a REGRESSION, or a component did not run. See the report.
pause
exit /b %GATE_EXIT%
