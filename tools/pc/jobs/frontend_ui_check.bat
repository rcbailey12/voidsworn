@echo off
rem Issue 1217 phase 5: the start screens check. Double-click it, or queue it.
rem 1. front_end_test (headless): the kit, Settings, the desk, the flagship podium, Esc and Back on every start page.
rem 2. front_end_shots at 1920x1080 and 3840x2160 with the live title battle: title, Settings, Credits, the faction and
rem    admiral desk, the flagship podium, Progression, Lineage and How to play.
rem 3. front_end_sheet: one contact sheet per screen group (F2 title, F3 desk, F4 flagship, F5 pages), each at most 720 tall.
rem Every run gets its own new folder, Downloads\voidsworn_test\shots\frontend_ui\<commit>_<time>\. Each Godot start gets
rem the watchdog's own throwaway profile (tmo.bat, issue 1369: the watchdog is the one owner), so Ryan's own settings and
rem campaign save are never read or written; front_end_shots refuses to run on Windows without it, so this file clears
rem PC_REAL_PROFILE. Deletes nothing of its own. Exits 1 on any failure.
rem Runs in the checkout it sits in (its built ships must be there: godot\gen). Each Godot run goes through tmo.bat.
setlocal enabledelayedexpansion
for %%I in ("%~dp0..\..\..") do set "ROOT=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "G="
if exist "%VT%\godot_path.txt" set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%ROOT%\tools\pc\tmo.bat"
for /f %%C in ('git -C "%ROOT%" rev-parse --short HEAD') do set "COMMIT=%%C"
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "OUT=%VT%\shots\frontend_ui\!COMMIT!_!STAMP!"
if exist "%OUT%" (echo FAIL: %OUT% already exists & exit /b 1)
mkdir "%OUT%"
set "ST=%OUT%\status.txt"
echo frontend_ui_check start %date% %time% commit !COMMIT! > "%ST%"
rem the watchdog gives every Godot start a fresh profile and removes it after; PC_REAL_PROFILE=1 would turn that off
set "PC_REAL_PROFILE="
set "RESULT=PASS"
call "%TMO%" 600 "%G%" --headless --path "%ROOT%\godot" --script res://ui/test/front_end_test.gd > "%OUT%\front_end_test.txt" 2>&1
set "EC=!ERRORLEVEL!"
findstr /c:"Front end: PASS" "%OUT%\front_end_test.txt" > nul
if errorlevel 1 set "EC=1"
if "!EC!"=="0" (echo front_end_test PASS >> "%ST%") else (set "RESULT=FAIL" & echo front_end_test FAIL, see front_end_test.txt >> "%ST%")
for %%S in (1920x1080 3840x2160) do (
  set "O=%OUT%\%%S"
  mkdir "!O!"
  call "%TMO%" 1200 "%G%" --path "%ROOT%\godot" --rendering-method forward_plus --windowed --resolution %%S --script res://ui/test/front_end_shots.gd -- "!O!" "!COMMIT!" --expect=%%S > "!O!\log.txt" 2>&1
  set "EC=!ERRORLEVEL!"
  if "!EC!"=="0" (
    call "%TMO%" 300 "%G%" --headless --path "%ROOT%\godot" --script res://tools/front_end_sheet.gd -- "!O!" "!O!\sheets" > "!O!\sheets_log.txt" 2>&1
    set "EC=!ERRORLEVEL!"
  )
  for %%P in (F2 F3 F4 F5) do if not exist "!O!\sheets\sheet_%%P.png" set "EC=1"
  if "!EC!"=="0" (echo %%S pictures and sheets PASS >> "%ST%") else (set "RESULT=FAIL" & echo %%S pictures or sheets FAIL, see %%S\log.txt and %%S\sheets_log.txt >> "%ST%")
)
echo RESULT %RESULT% >> "%ST%"
echo folder %OUT% >> "%ST%"
echo done %date% %time% >> "%ST%"
type "%ST%"
if "%RESULT%"=="PASS" exit /b 0
exit /b 1
