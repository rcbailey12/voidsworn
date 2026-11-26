@echo off
rem Board queue, after green checks and review. Pass the pinned baseline checkout and an optional new output directory.
rem Both checkouts need the same installed ship cache and imported assets. Keep the baseline and candidate at their pins.
setlocal EnableExtensions DisableDelayedExpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if "%~1"=="" (
  echo Usage: %~nx0 BASELINE_CHECKOUT [NEW_OUTPUT_DIRECTORY]
  exit /b 2
)
set "BEFORE=%~f1"
for %%I in ("%~dp0..\..\..") do set "AFTER=%%~fI"
set "BENCH=%AFTER%\godot\bench\performance_1780.gd"
set "SHOTS=%VT%\board\issue-1780\shots"
set "OUT=%TEMP%\voidsworn-1780-%RANDOM%-%RANDOM%"
if not "%~2"=="" set "OUT=%~f2"
if /i "%BEFORE%"=="%AFTER%" exit /b 2
if not exist "%BEFORE%\godot\project.godot" exit /b 2
if not exist "%BENCH%" exit /b 2
if exist "%OUT%" (
  echo Choose a new output directory so cache and timing runs start cold.
  exit /b 2
)
set /p GODOT=<"%VT%\godot_path.txt"
if not exist "%GODOT%" exit /b 2
if not exist "%VT%\gpu_go.txt" exit /b 2
set /p GPU_GO=<"%VT%\gpu_go.txt"
if not "%GPU_GO%"=="GPU cleared" exit /b 2
mkdir "%OUT%" || exit /b 1
git -C "%BEFORE%" rev-parse HEAD > "%OUT%\before-revision.txt" || exit /b 1
git -C "%AFTER%" rev-parse HEAD > "%OUT%\after-revision.txt" || exit /b 1
echo 1780 results: "%OUT%"
set "TMO_STEP=issue-1780"
set "TMO_FATAL_PATTERN=SCRIPT ERROR|Shader compilation failed"
set "TMO_REPO="
set "TMO_OUT="
set "TMO_LOG="
set "PC_GPU_MODE=solo"
set "PC_REAL_PROFILE=1"

rem A fresh profile and bake directory for each cold row. Its paired warm run reuses both.
for %%R in (1080 2160) do (
  call :pair "%BEFORE%" "before\storm\%%R" %%R storm default || exit /b 1
  call :pair "%AFTER%" "after\storm\%%R" %%R storm default || exit /b 1
)
for %%M in (fsr2_native fsr2_quality) do (
  call :pair "%AFTER%" "after\storm\2160" 2160 storm %%M || exit /b 1
)
for %%M in (belt planet) do (
  call :pair "%BEFORE%" "before\%%M\2160" 2160 %%M default || exit /b 1
)
call :pair "%AFTER%" "after\belt\2160" 2160 belt default || exit /b 1
rem Same revision, seed, camera and AA. Each format gets its own cold and warm cache.
for %%C in (off on) do (
  call :pair "%AFTER%" "after\planet\2160" 2160 planet default %%C || exit /b 1
)

rem The review sheets combine three adjacent frames at the same camera positions, left to right.
set "PC_GPU_MODE=none"
set "PICTURE_SOURCE_REPO=%AFTER%"
call "%~dp0..\tmo.bat" 120 "%GODOT%" --headless --path "%AFTER%\godot" --script "%BENCH%" -- --sheet --out "%OUT%\after\storm\2160" --shots "%SHOTS%" > "%OUT%\sheets.log" 2>&1
if errorlevel 1 exit /b 1
call "%~dp0..\tmo.bat" 120 "%GODOT%" --headless --path "%AFTER%\godot" --script "%BENCH%" -- --bc7-sheet --out "%OUT%\after\planet\2160" --shots "%SHOTS%" > "%OUT%\bc7-sheets.log" 2>&1
exit /b %ERRORLEVEL%

:pair
setlocal
set "PROJECT=%~1"
set "PICTURE_SOURCE_REPO=%PROJECT%"
set "ROW=%OUT%\%~2\%~5"
set "BC7=off"
if not "%~6"=="" (
  set "BC7=%~6"
  set "ROW=%OUT%\%~2\%~6"
)
set "APPDATA=%ROW%\profile"
set "LOCALAPPDATA=%APPDATA%"
set "VS_WORLD_CACHE=%ROW%\bakes"
mkdir "%APPDATA%" || exit /b 1
mkdir "%ROW%\cold" || exit /b 1
call "%~dp0..\tmo.bat" 600 "%GODOT%" --path "%PROJECT%\godot" --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --script "%BENCH%" -- --out "%ROW%\cold" --resolution %~3 --map %~4 --aa %~5 --bc7 %BC7% > "%ROW%\cold.log" 2>&1
if errorlevel 1 exit /b 1
if not exist "%ROW%\cold\timing.json" exit /b 1
mkdir "%ROW%\warm" || exit /b 1
set "CAPTURE="
if "%~3"=="2160" if "%~4"=="storm" set "CAPTURE=--pictures"
if "%~3"=="2160" if "%~4"=="planet" set "CAPTURE=--pictures"
call "%~dp0..\tmo.bat" 600 "%GODOT%" --path "%PROJECT%\godot" --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --script "%BENCH%" -- --out "%ROW%\warm" --resolution %~3 --map %~4 --aa %~5 --bc7 %BC7% %CAPTURE% > "%ROW%\warm.log" 2>&1
if errorlevel 1 exit /b 1
if not exist "%ROW%\warm\timing.json" exit /b 1
endlocal
exit /b 0
