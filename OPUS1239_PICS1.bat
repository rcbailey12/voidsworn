@echo off
rem Issue 1239 pictures (Opus helper, R334): the collapse pace sheet for Ryan (today 0.70 s, then 50, 75 and 100 percent
rem slower), with an mp4 per pace, and the shield hand-off before and after sheets (shoulder break, lethal break, torpedo
rem salvo). Subjects i_boss (the new CD5, I8_37) and h_boss, fitted shield, camera 60. Branch pinned to ff33fb6f, main
rem pinned to dd86803c. The job uses the tools_live watchdog (fails closed, logs its path and hash), copies the hulls
rem without a4_props.gd, rebuilds the ship cache, runs Godot in a throwaway profile and hashes Ryan's options before and
rem after. GPU shared, no cost pass. Writes only under Downloads\voidsworn_test\opus1239\; logs to
rem opus1239\out\result.txt, last line "all done".
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "S1239_HOME=%VT%\opus1239"
if not exist "%S1239_HOME%\out" mkdir "%S1239_HOME%\out"
echo OPUS1239_PICS1 start %date% %time% commit ff33fb6f main dd86803c >> "%S1239_HOME%\out\result.txt"
set "R=%S1239_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone -q https://github.com/rcbailey12/voidsworn "%R%" >> "%S1239_HOME%\git.txt" 2>&1
git -C "%R%" fetch -q origin >> "%S1239_HOME%\git.txt" 2>&1
git -C "%R%" show ff33fb6f39216a5f83552a3b5b600cc78da60c6f:tools/pc/jobs/shield_handoff_1239.bat > "%S1239_HOME%\job_lf_pics1.txt" 2>> "%S1239_HOME%\git.txt"
rem the repo keeps .bat files with LF inside git; find /v "" writes every line back with CRLF for cmd
type "%S1239_HOME%\job_lf_pics1.txt" | find /v "" > "%S1239_HOME%\job_pics1.bat"
findstr /c:"shield_handoff_probe.gd" "%S1239_HOME%\job_pics1.bat" > nul
if errorlevel 1 (
  echo FAILED: commit ff33fb6f not fetched or its job file is missing >> "%S1239_HOME%\out\result.txt"
  echo all done >> "%S1239_HOME%\out\result.txt"
  endlocal & exit /b 1
)
set "S1239_SUBJECTS=i_boss,h_boss"
call "%S1239_HOME%\job_pics1.bat" ff33fb6f39216a5f83552a3b5b600cc78da60c6f dd86803ccb78b9109cfd27cee1fbb2b6856e3d0d
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
