@echo off
rem Issue 1413: rebake the Navy bomber with the shared Navy paint grain (same shape as OPUS1373_hegemony_HB1.bat).
set "SHIP=hegemony_HB1" & set "CODE=hegemony_HB1" & set "BRANCH=board/pin-1413d" & set "JOB_DIR=opus1413hb1" & set "SETS=close"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
