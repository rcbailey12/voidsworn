@echo off
rem Issue 1078 Glasswright redo (Opus helper, R334): the clean collapse on the new CD5 flagship (issue 1183, installed as
rem i_boss / I8_37 in build\godot by r5d), sheets at cameras 170 and 60, fitted and egg. Pinned to commit 42f4a4a1.
rem GLASS6 drew the old I8_37 scene; this job rebuilds the ship cache from assets\ships first. Look pass only (S1078_SKIP_FLASH, S1078_SKIP_COST). The job uses the tools_live watchdog (fails closed, logs its path
rem and hash), copies the hulls without a4_props.gd, runs Godot in a throwaway profile and hashes Ryan's options before
rem and after. Writes only under Downloads\voidsworn_test\opus1078\; logs to opus1078\out\result.txt, last line "all done".
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1078_HOME=%VT%\opus1078"
if not exist "%S1078_HOME%\out" mkdir "%S1078_HOME%\out"
echo OPUS1078_GLASS7 start %date% %time% commit 42f4a4a1 >> "%S1078_HOME%\out\result.txt"
set "R=%S1078_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone -q https://github.com/rcbailey12/voidsworn "%R%" >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" fetch -q origin >> "%S1078_HOME%\git.txt" 2>&1
git -C "%R%" show 42f4a4a190a5998f2b78fda1830f66959f5fd8b2:tools/pc/jobs/shield_looks_1078.bat > "%S1078_HOME%\job_lf_glass7.txt" 2>> "%S1078_HOME%\git.txt"
rem the repo keeps .bat files with LF inside git; find /v "" writes every line back with CRLF for cmd
type "%S1078_HOME%\job_lf_glass7.txt" | find /v "" > "%S1078_HOME%\job_glass7.bat"
findstr /c:"--ships-only" "%S1078_HOME%\job_glass7.bat" > nul
if errorlevel 1 (
  echo FAILED: commit 42f4a4a1 not fetched or its job file is old ^(no ship cache rebuild^) >> "%S1078_HOME%\out\result.txt"
  echo all done >> "%S1078_HOME%\out\result.txt"
  endlocal & exit /b 1
)
set "S1078_SUBJECTS=i_boss"
set "PROBE_LOOKS=collapse"
set "PROBE_CLIP="
set "S1078_SKIP_FLASH=1"
set "S1078_SKIP_COST=1"
call "%S1078_HOME%\job_glass7.bat" 42f4a4a190a5998f2b78fda1830f66959f5fd8b2
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
