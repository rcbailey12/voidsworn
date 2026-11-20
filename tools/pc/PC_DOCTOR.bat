@echo off
rem PC doctor (issue 1194): double-click for a read-only look at the GPU queue. It lists every GPU claim with its owner,
rem child process, age and health, damaged slot files, Godot or Blender processes that look stuck, and failed queue jobs.
rem It changes, moves and stops nothing; the report is also saved to Downloads\voidsworn_test\pc_doctor.txt.
rem   PC_DOCTOR.bat          quick look (30 second CPU sample)
rem   PC_DOCTOR.bat strict   a full 5 minute sample, so "idle" means idle for 5 minutes
setlocal
set "SAMPLE=30"
if /i "%~1"=="strict" set "SAMPLE=300"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pc_doctor.ps1" -SampleSeconds %SAMPLE%
set "DX=%ERRORLEVEL%"
if not "%PC_DOCTOR_NO_PAUSE%"=="1" pause
endlocal & exit /b %DX%
