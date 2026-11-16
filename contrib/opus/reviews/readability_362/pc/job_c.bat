@echo off
rem Issue 362: the final fleet probe (twice, keep the second) on the branch head once job b is done, then its zip.
rem Job b's own probe ran one commit early (90dc1227, the first lifts); its gate and moments ran on 5244d3ec.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
:waitb
findstr /c:"job b done" "%D%\status.txt" > nul
if not errorlevel 1 goto go
timeout /t 60 /nobreak > nul
goto waitb
:go
call "%D%\run362.bat" probe origin/opus/issue-362 final
call "%D%\zip362.bat" probe_final_2
echo %date% %time% job c done >> "%D%\status.txt"
exit /b 0
