@echo off
rem Issue 362: the look bench's own moments sheets, main (before) against the branch (after), then a zip of them.
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
call "%D%\run362.bat" sheets moments_before_2 moments_after_2
call "%D%\zip362.bat" sheets_moments_before_2_vs_moments_after_2
echo %date% %time% job d done >> "%D%\status.txt"
exit /b 0
