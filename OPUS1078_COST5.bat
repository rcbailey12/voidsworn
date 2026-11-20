@echo off
rem Issue 1078 cost-only rerun (Opus helper, R334): branch and main GPU cost, solo, pinned to commit c3dc2b64.
rem Run 4 (8605a168) had no main numbers: the main probe failed to parse. No look or flash pass here (S1078_SKIP_LOOK,
rem S1078_SKIP_FLASH). Writes only under Downloads\voidsworn_test\opus1078\; logs to opus1078\out\result.txt, last line "all done".
rem The job does the safe checkout, the throwaway Godot profile and the hash check of Ryan's real options. Nothing is deleted.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1078_HOME=%VT%\opus1078"
if not exist "%S1078_HOME%\out" mkdir "%S1078_HOME%\out"
echo OPUS1078_COST5 start %date% %time% commit c3dc2b64 >> "%S1078_HOME%\out\result.txt"
set "R=%S1078_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone -q https://github.com/rcbailey12/voidsworn "%R%" >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" fetch -q origin >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" show c3dc2b649a842239872ad729301d1980b1c16454:tools/pc/jobs/shield_looks_1078.bat > "%S1078_HOME%\job_lf_cost5.txt" 2>> "%S1078_HOME%\git.txt"
rem the repo keeps .bat files with LF inside git; find /v "" writes every line back with CRLF for cmd
type "%S1078_HOME%\job_lf_cost5.txt" | find /v "" > "%S1078_HOME%\job_cost5.bat"
findstr /c:"S1078_SKIP_FLASH" "%S1078_HOME%\job_cost5.bat" > nul
if errorlevel 1 (
  echo FAILED: commit c3dc2b64 not fetched or its job file is old ^(no S1078_SKIP_FLASH^) >> "%S1078_HOME%\out\result.txt"
  echo all done >> "%S1078_HOME%\out\result.txt"
  endlocal & exit /b 1
)
set "S1078_SKIP_LOOK=1"
set "S1078_SKIP_FLASH=1"
call "%S1078_HOME%\job_cost5.bat" c3dc2b649a842239872ad729301d1980b1c16454
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
