@echo off
rem FLEET_E: pinned to the joint G stack (pearl glass Glasswright insides, R448) plus the GS1 frigate insides fix (main with 1724, 1763 with the Glasswright rooms, 1755, 1786 with the R431 round 3
rem Glasswright pearl shells, 1737), so the Glasswright rows bake round 3 with rooms and the smoked lining. Replaces FLEET_D (pearl insides).
rem Fleet re-export (issue 1743 with 1680): every recipe ship rebaked and exported once, with the Interior Kit V2 insides
rem (PR 1763) and the R411 size-tiered maps (PR 1724, export7 picks the band itself): 7 ships at 4096 (flagships and
rem battleships), 9 strike craft at 1024, the other 21 at 2048. Stages 5 (paint bake at 4096, which builds the sheet and its
rem modeled insides), 6 (LOD) and 7 (export, its own check_export and selftest) per ship, installed only into this job's own
rem checkout, then the install readback, the authored interiors check and the death seam check on each installed glb.
rem STAGES ONLY: nothing goes into build\godot (R427 merge freeze). Publishing is publish_ship.bat per ship, after Ryan's OK.
rem Exports stay in Downloads\voidsworn_test\recipe\<ship>\export\<code>\ for that publish; the relay gets only small files:
rem each ship's <code>_export.json, its stage logs, and sizes.csv (before = Ryan's installed folder, after = this export, MB).
rem A failed ship is recorded and the job goes on to the next one; the job fails at the end if any ship failed.
rem   OPUS1743_FLEET_E.bat                 all 37 ships
rem   OPUS1743_FLEET_E.bat hegemony_H10    one ship (any recipe ship id)
rem Long GPU job: stage 5 is about 30 to 40 minutes a ship. Queue only after green checks and a passed review (R407).
rem Built from opus_job_template.bat. Once queued, never edited: a change ships under a new name. Deletes nothing.
setlocal EnableExtensions
set "JOB=opus1743fleete"
set "LABEL=1743"
set "TOOLS=godot blender pil"
set "PIN_NEW=fea28b4da6f292f00947d08eeae88155c3936c58"
set "PIN_OLD="
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"
set "FLEET=voidsworn_S8 chorus_C10 corsair_A16 deathless_E11 hegemony_H10 hegemony_IM5 ithar_CD5"
set "FLEET=%FLEET% voidsworn_S9 voidsworn_S10 voidsworn_S11 chorus_C11 chorus_C12 chorus_C13 chorus_C14"
set "FLEET=%FLEET% corsair_A17 corsair_A18 corsair_A19 corsair_A20 deathless_E12 deathless_E13 deathless_E14"
set "FLEET=%FLEET% hegemony_H7 hegemony_H8 hegemony_O2 hegemony_O3 ithar_GA1 ithar_GL1 ithar_GP1 ithar_GS1"
set "FLEET=%FLEET% voidsworn_SF3 voidsworn_SB4 chorus_CS1BA2 corsair_KF1 corsair_KB1CC hegemony_HF1D hegemony_HB1 ithar_GV2 ithar_GW4"
if not "%~1"=="" set "FLEET=%~1"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "O=%OJ_OUT%\out_fleet"
if not exist "%O%" mkdir "%O%"
set "GAMESHIPS=%VT%\build\godot\assets\ships"
> "%O%\sizes.csv" echo ship,code,maps_target,maps_written,before_MB,after_MB,result
set "SHIPS_FAILED="
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
for %%S in (%FLEET%) do call :ship %%S
> "%O%\fleet_result.txt" echo failed ships:%SHIPS_FAILED%
if defined SHIPS_FAILED call "%JW%" fail "ships failed:%SHIPS_FAILED% (see %O%\fleet_result.txt and sizes.csv)"
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one ship: stages 5, 6, 7, each inside setlocal (env.bat sets JOB and other names; they must not leak into this job)
:ship
set "SHIP=%1"
set "SO=%O%\%1"
if not exist "%SO%" mkdir "%SO%"
set "CODE="
for /f "usebackq delims=" %%L in (`""%JW_PIL%" -c "import json;s=json.load(open(r'%OJ_REPO%\tools\recipe\ships\%1.json'));print(s.get('game_code') or s['ship'])""`) do set "CODE=%%L"
if not defined CODE (set "SHIPS_FAILED=%SHIPS_FAILED% %1(no-ship-json)" & >> "%O%\sizes.csv" echo %1,,,,,,no ship json & exit /b 0)
set "SFAIL="
set "INSTALL_TO=%OJ_REPO%\godot"
set "RECIPE_NOPAUSE=1"
set "PC_GPU_ISSUE=%LABEL%"
set "PC_GPU_WAIT_SECONDS=3600"
call :stage %1 5_paint_bake
if not defined SFAIL call :stage %1 6_lod
if not defined SFAIL call :stage %1 7_export
if not defined SFAIL findstr /c:"UNDERSIZED maps" "%SO%\log_7_export.txt" > nul && set "SFAIL=undersized"
set "INSTALL_TO=" & set "SHIP="
set "EX=%VT%\recipe\%1\export\%CODE%"
if exist "%EX%\%CODE%_export.json" copy /y "%EX%\%CODE%_export.json" "%SO%\" > nul
if not defined SFAIL if not exist "%OJ_REPO%\godot\assets\ships\%CODE%\%CODE%.glb" set "SFAIL=not-installed"
if not defined SFAIL call :checks %1 %CODE%
set "TGT=" & set "WR="
if exist "%SO%\%CODE%_export.json" for /f "usebackq tokens=1,2" %%A in (`powershell -NoProfile -Command "$j = Get-Content -Raw '%SO%\%CODE%_export.json' | ConvertFrom-Json; '' + $j.maps_target + ' ' + $j.maps"`) do (set "TGT=%%A" & set "WR=%%B")
set "MB0=" & set "MB1="
for /f "usebackq delims=" %%M in (`powershell -NoProfile -Command "if (Test-Path '%GAMESHIPS%\%CODE%') { '{0:N1}' -f ((Get-ChildItem -LiteralPath '%GAMESHIPS%\%CODE%' -File -Recurse | Where-Object { $_.Extension -ne '.import' } | Measure-Object Length -Sum).Sum / 1MB) } else { 'none' }"`) do set "MB0=%%M"
for /f "usebackq delims=" %%M in (`powershell -NoProfile -Command "if (Test-Path '%EX%') { '{0:N1}' -f ((Get-ChildItem -LiteralPath '%EX%' -File | Measure-Object Length -Sum).Sum / 1MB) } else { 'none' }"`) do set "MB1=%%M"
if defined SFAIL (set "SHIPS_FAILED=%SHIPS_FAILED% %1(%SFAIL%)" & >> "%O%\sizes.csv" echo %1,%CODE%,%TGT%,%WR%,"%MB0%","%MB1%",FAILED %SFAIL%) else (>> "%O%\sizes.csv" echo %1,%CODE%,%TGT%,%WR%,"%MB0%","%MB1%",PASS)
exit /b 0

:stage
rem stage bats call env.bat, which sets JOB, CODE and more: setlocal keeps them out of this job. Each heavy step inside a
rem stage already runs under the tools_live watchdog (tools\recipe\*.bat call tmo.bat with PC_GPU_ISSUE as the claim label).
setlocal
set "SHIP=%1"
>> "%SO%\stages.txt" echo %1 %2 start %DATE% %TIME%
call "%OJ_REPO%\tools\recipe\%2.bat" > "%SO%\log_%2.txt" 2>&1
set "EL=%ERRORLEVEL%"
>> "%SO%\stages.txt" echo %1 %2 exit %EL% at %TIME%
endlocal & if not "%EL%"=="0" set "SFAIL=%2"
exit /b 0

:checks
set "JW_STEP=%1 readback" & set "JW_CONTINUE=1" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://render/test/installed_ship_check.gd -- %2 > "%SO%\readback.txt" 2>&1
findstr /c:"INSTALL READBACK PASS code=%2 " "%SO%\readback.txt" > nul || set "SFAIL=readback"
set "JW_STEP=%1 interiors" & set "JW_CONTINUE=1" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://fx/test/authored_interiors_check.gd -- "%OJ_REPO%\godot\assets\ships\%2\%2.glb" > "%SO%\interiors.txt" 2>&1
if errorlevel 1 if not defined SFAIL set "SFAIL=interiors"
set "JW_STEP=%1 death seam" & set "JW_CONTINUE=1" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://fx/test/death_seam_check.gd -- "%OJ_REPO%\godot\assets\ships\%2\%2.glb" > "%SO%\death_seam.txt" 2>&1
if errorlevel 1 if not defined SFAIL set "SFAIL=death-seam"
exit /b 0
