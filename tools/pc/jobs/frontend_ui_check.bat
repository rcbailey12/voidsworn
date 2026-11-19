@echo off
rem Issue 1217 phase 5: the start screens check. Double-click it, or queue it.
rem 1. front_end_test (headless): the kit, Settings, the desk, the flagship podium, Esc and Back on every start page.
rem 2. front_end_shots at 1920x1080 and 3840x2160 with the live title battle: title, Settings, Credits, the faction and
rem    admiral desk, the flagship podium, Progression, Lineage and How to play.
rem 3. front_end_sheet: one contact sheet per screen group (F2 title, F3 desk, F4 flagship, F5 pages), each at most 720 tall.
rem Runs in the checkout it sits in (its built ships must be there: godot\gen). Writes only under
rem Downloads\voidsworn_test\shots\frontend_ui\ and deletes nothing. Each Godot run goes through tmo.bat (GPU slots).
setlocal enabledelayedexpansion
for %%I in ("%~dp0..\..\..") do set "ROOT=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%ROOT%\tools\pc\tmo.bat"
set "OUT=%VT%\shots\frontend_ui"
if not exist "%OUT%" mkdir "%OUT%"
set "ST=%OUT%\status.txt"
for /f %%C in ('git -C "%ROOT%" rev-parse --short HEAD') do set "COMMIT=%%C"
echo frontend_ui_check start %date% %time% commit !COMMIT! > "%ST%"
set "RESULT=PASS"
call "%TMO%" 600 "%G%" --headless --path "%ROOT%\godot" --script res://ui/test/front_end_test.gd > "%OUT%\front_end_test.txt" 2>&1
findstr /c:"Front end: PASS" "%OUT%\front_end_test.txt" > nul
if errorlevel 1 (set "RESULT=FAIL" & echo front_end_test FAIL >> "%ST%") else (echo front_end_test PASS >> "%ST%")
for %%S in (1920x1080 3840x2160) do (
  set "O=%OUT%\%%S"
  if not exist "!O!" mkdir "!O!"
  call "%TMO%" 1200 "%G%" --path "%ROOT%\godot" --rendering-method forward_plus --windowed --resolution %%S --script res://ui/test/front_end_shots.gd -- "!O!" "!COMMIT!" > "!O!\log.txt" 2>&1
  call "%TMO%" 300 "%G%" --headless --path "%ROOT%\godot" --script res://tools/front_end_sheet.gd -- "!O!" "!O!\sheets" > "!O!\sheets_log.txt" 2>&1
  if exist "!O!\sheets\sheet_F5.png" (echo %%S pictures and sheets PASS >> "%ST%") else (set "RESULT=FAIL" & echo %%S pictures or sheets FAIL, see !O!\log.txt >> "%ST%")
)
echo RESULT %RESULT% >> "%ST%"
echo done %date% %time% >> "%ST%"
type "%ST%"
exit /b 0
