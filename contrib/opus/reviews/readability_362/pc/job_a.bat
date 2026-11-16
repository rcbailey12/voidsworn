@echo off
rem Issue 362 GPU window 1: setup; before (main at b7cacdc4): probe twice, moments twice, gate twice; then the
rem calibration variants of the branch (world and storm skies, once). Order: cheap steps first.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
call "%D%\run362.bat" setup
if errorlevel 1 exit /b 1
call "%D%\run362.bat" probe b7cacdc4 before
call "%D%\run362.bat" probe origin/opus/issue-362 cal variants_cal.json world,storm
call "%D%\run362.bat" gate b7cacdc4 before
call "%D%\run362.bat" moments b7cacdc4 before
echo %date% %time% job a done >> "%D%\status.txt"
exit /b 0
