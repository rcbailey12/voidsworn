@echo off
rem Issue 1078 run 2 (Opus helper, R334): shield failure looks on the installed ships, then the solo GPU cost pass.
rem Writes only under Downloads\voidsworn_test\opus1078\. Every step logs to opus1078\out\result.txt; last line "all done".
rem The look pass shares the GPU; the cost pass claims it solo (R293, PC_GPU_MODE=solo inside the job). Nothing is deleted.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1078_HOME=%VT%\opus1078"
if not exist "%S1078_HOME%\out" mkdir "%S1078_HOME%\out"
echo OPUS1078_RUN2 start %date% %time% >> "%S1078_HOME%\out\result.txt"
set "R=%S1078_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" >> "%S1078_HOME%\out\result.txt" 2>&1
git -C "%R%" fetch origin >> "%S1078_HOME%\out\result.txt" 2>&1
git -C "%R%" checkout -f --detach origin/opus/issue-1078 >> "%S1078_HOME%\out\result.txt" 2>&1
copy /y "%R%\tools\pc\jobs\shield_looks_1078.bat" "%S1078_HOME%\job.bat" > nul
if not exist "%S1078_HOME%\job.bat" (
  echo FAILED: no job file on the branch >> "%S1078_HOME%\out\result.txt"
  echo all done >> "%S1078_HOME%\out\result.txt"
  goto :eof
)
call "%S1078_HOME%\job.bat" origin/opus/issue-1078
endlocal
