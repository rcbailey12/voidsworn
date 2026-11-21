@echo off
rem Board: frozen pin board/pin-1415e = d9017947b0f7a465a7be775081b36090c93f61e8 (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GA1" & set "CODE=I16_11" & set "BRANCH=board/pin-1415e" & set "JOB_DIR=opus1415e_GA1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
