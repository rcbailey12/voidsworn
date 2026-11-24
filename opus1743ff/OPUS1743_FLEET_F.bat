@echo off
rem FLEET_F: a two-ship rerun after FLEET_E, the Glasswright strike craft ithar_GV2 and ithar_GW4, pinned to the joint stack
rem with the exteriors kit head dbdaa9b3 (both craft on the I8_37 shell; GL1's torpedo stays on the keel, so GL1 is not rerun)
rem and the interior kit fix that gives the craft Glasswright crystal machinery inside (it was Hullbreaker machinery).
rem Same steps as FLEET_E: stages 5, 6 and 7 per ship, installed only into this job's own checkout, then the install readback,
rem the authored interiors check and the death seam check. STAGES ONLY: nothing goes into build\godot; publishing is
rem publish_ship.bat per ship after Ryan's OK. A failed ship is recorded and the job goes on; it fails at the end if any did.
rem   OPUS1743_FLEET_F.bat                 both craft
rem   OPUS1743_FLEET_F.bat ithar_GV2       one ship
rem Queue after FLEET_E. Built from opus_job_template.bat. Once queued, never edited: a change ships under a new name. Deletes nothing.
setlocal EnableExtensions
set "JOB=opus1743fleetf"
set "LABEL=1743"
set "TOOLS=godot blender pil"
set "PIN_NEW=1d07c1c0099378bff7d0b9ad1eaef0cb8a1d940f"
set "PIN_OLD="
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"
set "FLEET=ithar_GV2 ithar_GW4"
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
