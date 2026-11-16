@echo off
rem Issue 362 calibration 2 (rim light from the line of sight, new base numbers): waits for job a to finish, then the
rem branch's variants on the darkest sky and the storm, once.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
:waita
findstr /c:"job a done" "%D%\status.txt" > nul
if not errorlevel 1 goto go
timeout /t 60 /nobreak > nul
goto waita
:go
call "%D%\run362.bat" probe origin/opus/issue-362 cal2 variants_cal2.json world+storm
call "%D%\zip362.bat" probe_cal2_1
echo %date% %time% job c2 done >> "%D%\status.txt"
exit /b 0
