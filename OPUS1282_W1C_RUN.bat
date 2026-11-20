@echo off
rem Issue 1282: Glasswright warming round on CD5, all seven stages (the bake changed), then the battle, close and cams shots.
rem Then (Artoo, PR 1283) the Glasswright Destroyer I11_37, an old hull not rebuilt with the kit, shot in the same clone so
rem the new drive glow shows on an old hull too. W1C (Board): that step runs through the canonical watchdog,
rem tools_live\<current>\pc\tmo.bat, with a time limit and a GPU claim like ship_job's own a4_shots step.
rem Writes only under opus1282w1\out (shots_legacy, log_shots_legacy.txt, legacy_shots_result.txt). Deletes nothing.
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1282" & set "JOB_DIR=opus1282w1" & set "SETS=battle,close,cams"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "J=%V%\opus1282w1"
set "R=%J%\out\legacy_shots_result.txt"
if not exist "%J%\out" mkdir "%J%\out"
echo legacy start %DATE% %TIME% > "%R%"
if not exist "%J%\repo\godot\project.godot" (echo legacy shots SKIPPED: no clone >> "%R%" & goto done)
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (echo FAILED: tools_live\current.txt is missing or empty >> "%R%" & goto done)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (echo FAILED: no watchdog at %TM% >> "%R%" & goto done)
if not exist "%V%\tools_live\%TLV%\pc\run_timeout.ps1" (echo FAILED: no run_timeout.ps1 beside %TM% >> "%R%" & goto done)
echo watchdog %TM% >> "%R%"
certutil -hashfile "%TM%" SHA256 >> "%R%" 2>&1
set PC_GPU_WAIT_SECONDS=3600
set "PC_GPU_ISSUE=opus1282w1"
call "%TM%" 3600 "%V%\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%J%\repo\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%J%\out\shots_legacy" --facs ithar --sets battle,cams --codes I11_37 > "%J%\out\log_shots_legacy.txt" 2>&1
set E=%ERRORLEVEL%
echo legacy shots exit %E% >> "%R%"
if "%E%"=="0" (echo PASSED >> "%R%") else (echo FAILED: legacy shots >> "%R%")
:done
echo all done %DATE% %TIME% >> "%R%"
endlocal
