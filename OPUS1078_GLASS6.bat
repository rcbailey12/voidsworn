@echo off
rem Issue 1078 Glasswright redo (Opus helper, R334): the clean collapse on the new CD5 flagship (issue 1183, installed as
rem i_boss / I8_37 in build\godot by r5d), sheets at cameras 170 and 60, fitted and egg. Pinned to commit 20fb9d01.
rem Look pass only (S1078_SKIP_FLASH, S1078_SKIP_COST). The job uses the tools_live watchdog (fails closed, logs its path
rem and hash), copies the hulls without a4_props.gd, runs Godot in a throwaway profile and hashes Ryan's options before
rem and after. Writes only under Downloads\voidsworn_test\opus1078\; logs to opus1078\out\result.txt, last line "all done".
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1078_HOME=%VT%\opus1078"
if not exist "%S1078_HOME%\out" mkdir "%S1078_HOME%\out"
echo OPUS1078_GLASS6 start %date% %time% commit 20fb9d01 >> "%S1078_HOME%\out\result.txt"
set "R=%S1078_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone -q https://github.com/rcbailey12/voidsworn "%R%" >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" fetch -q origin >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" show 20fb9d01b22b3cfec994322eead6f8ca1857868f:tools/pc/jobs/shield_looks_1078.bat > "%S1078_HOME%\job_lf_glass6.txt" 2>> "%S1078_HOME%\git.txt"
rem the repo keeps .bat files with LF inside git; find /v "" writes every line back with CRLF for cmd
type "%S1078_HOME%\job_lf_glass6.txt" | find /v "" > "%S1078_HOME%\job_glass6.bat"
findstr /c:"tools_live" "%S1078_HOME%\job_glass6.bat" > nul
if errorlevel 1 (
  echo FAILED: commit 20fb9d01 not fetched or its job file is old ^(no tools_live watchdog^) >> "%S1078_HOME%\out\result.txt"
  echo all done >> "%S1078_HOME%\out\result.txt"
  endlocal & exit /b 1
)
set "S1078_SUBJECTS=i_boss"
set "PROBE_LOOKS=collapse"
set "PROBE_CLIP="
set "S1078_SKIP_FLASH=1"
set "S1078_SKIP_COST=1"
call "%S1078_HOME%\job_glass6.bat" 20fb9d01b22b3cfec994322eead6f8ca1857868f
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
