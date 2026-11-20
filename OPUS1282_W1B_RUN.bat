@echo off
rem Issue 1282: Glasswright warming round on CD5, all seven stages (the bake changed), then the battle, close and cams shots.
rem Then (Artoo, PR 1283) the Glasswright Destroyer I11_37, an old hull not rebuilt with the kit, in the same clone, so the new drive glow shows on it too.
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1282" & set "JOB_DIR=opus1282w1" & set "SETS=battle,close,cams"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "J=%V%\opus1282w1"
if not exist "%J%\repo\godot\project.godot" (echo legacy shots SKIPPED: no clone > "%J%\out\legacy_shots_result.txt" & goto :eof)
"%V%\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%J%\repo\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%J%\out\shots_legacy" --facs ithar --sets battle,cams --codes I11_37 > "%J%\out\log_shots_legacy.txt" 2>&1
echo legacy shots exit %ERRORLEVEL% > "%J%\out\legacy_shots_result.txt"
