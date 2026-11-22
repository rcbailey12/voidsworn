@echo off
rem Issue 1657: send one job attempt's results to the private relay repo (voidsworn-relay, branch pc-out-<job>).
rem   relay_push.bat <job> <attempt folder> [dry]
rem dry lists what would go and changes nothing. Never deletes anything on the PC or on GitHub.
setlocal
if "%~2"=="" (echo usage: relay_push.bat ^<job^> ^<attempt folder^> [dry] & exit /b 2)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0relay_push.ps1" "%~1" "%~2" "%~3"
exit /b %ERRORLEVEL%
