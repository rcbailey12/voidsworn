@echo off
rem Issue 1078 run 3 retry R3 (Opus helper, R334): shield failure looks r2 on the installed ships, then the solo GPU cost pass.
rem Writes only under Downloads\voidsworn_test\opus1078\. Every step logs to opus1078\out\result.txt; last line "all done".
rem The look pass shares the GPU; the cost passes claim it solo (R293, PC_GPU_MODE=solo and PC_GPU_ISSUE=1078 inside the job).
rem This wrapper never checks anything out: it reads the job file straight from the fetched branch; the job itself does the
rem safe checkout (saved status and patch, stop on unexpected changes, no forced checkout; issue 1179). Nothing is deleted.
rem R3 writes job_run3_r3.bat, a new file, so it never overwrites job_run3.bat while run 3 R2 is still reading it.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1078_HOME=%VT%\opus1078"
if not exist "%S1078_HOME%\out" mkdir "%S1078_HOME%\out"
echo OPUS1078_RUN3_R3 start %date% %time% >> "%S1078_HOME%\out\result.txt"
set "R=%S1078_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone -q https://github.com/rcbailey12/voidsworn "%R%" >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" fetch -q origin >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" show origin/opus/issue-1078:tools/pc/jobs/shield_looks_1078.bat > "%S1078_HOME%\job_lf_r3.txt" 2>> "%S1078_HOME%\git.txt"
rem the repo keeps .bat files with LF inside git; find /v "" writes every line back with CRLF for cmd
type "%S1078_HOME%\job_lf_r3.txt" | find /v "" > "%S1078_HOME%\job_run3_r3.bat"
findstr /c:"glob,exclude" "%S1078_HOME%\job_run3_r3.bat" > nul
if errorlevel 1 (
  echo FAILED: the job file on the branch is missing or old ^(no git-filtered safe checkout, ac7abd78 or later^) >> "%S1078_HOME%\out\result.txt"
  echo all done >> "%S1078_HOME%\out\result.txt"
  goto :eof
)
call "%S1078_HOME%\job_run3_r3.bat" origin/opus/issue-1078
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
