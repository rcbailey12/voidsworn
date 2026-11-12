@echo off
rem Look bench pre-run (issue 600): lay a freshly installed ship over the bench's own game checkout, as stage 7 installs it,
rem so the bench draws the new ship beside every other PC-built hull. look_bench.bat calls it with its checkout folder:
rem   set LB_PRE_RUN=Downloads\voidsworn_test\look_bench\tool\tools\pc\jobs\lb_overlay_ship.bat
rem It writes only into that checkout and deletes nothing (anything it replaces is moved into overlay_aside\ there):
rem   1. LB_SHIPS's gen and assets\ships over the checkout's, every file, so every other hull is the PC's built one (a run
rem      that copied a folder with fewer hulls left a smaller cache behind); the new ship's own folder is not taken from there;
rem   2. an older damage or wreck glb of the ship is moved aside (stage 7 does the same: they belong to the old hull);
rem   3. OV_FROM\assets\ships\OV_CODE (the new glb and its maps) into the checkout;
rem   4. the export's manifest entry into the checkout's assets\ships\manifest.json (tools\recipe\manifest_merge.py, as stage 7);
rem   5. an import, the ships-only cache rebuild (render\build_assets.gd --ships-only) and the install readback, as stage 7.
rem Settings:
rem   OV_FROM   a godot folder stage 7 installed the ship into (required)
rem   OV_CODE   the ship's folder code (default C19_51)
rem   OV_ENTRY  the export's manifest_entry.json (default Downloads\voidsworn_test\recipe\corsair_A16\export\OV_CODE\manifest_entry.json)
rem   OV_PY     a python for the manifest merge (default Blender's, as the recipe uses)
rem Uses look_bench.bat's G (Godot), LB_SHIPS and TMO. Prints OVERLAY PASS or OVERLAY FAILED lines (the bench's pre_run.txt);
rem the bench's own placeholder guard still stops if the ship would draw as a block.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "CO=%~1\godot"
if "%OV_CODE%"=="" set "OV_CODE=C19_51"
if "%OV_ENTRY%"=="" set "OV_ENTRY=%VT%\recipe\corsair_A16\export\%OV_CODE%\manifest_entry.json"
if "%OV_PY%"=="" set "OV_PY=%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
if "%G%"=="" set /p G=<"%VT%\godot_path.txt"
if "%TMO%"=="" set "TMO=%~dp0..\tmo.bat"
if not exist "%CO%\project.godot" (echo OVERLAY FAILED: %CO% is not a Godot project & exit /b 1)
if not exist "%OV_FROM%\assets\ships\%OV_CODE%\%OV_CODE%.glb" (echo OVERLAY FAILED: no %OV_CODE%.glb under OV_FROM=%OV_FROM% & exit /b 1)
if not exist "%OV_ENTRY%" (echo OVERLAY FAILED: no manifest entry at %OV_ENTRY% & exit /b 1)
set "ASIDE=%~1\overlay_aside\%OV_CODE%_%RANDOM%"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%CO%\gen" /E /NFL /NDL /NJH /NJS /R:1 /W:1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%CO%\assets\ships" /E /XD %OV_CODE% /NFL /NDL /NJH /NJS /R:1 /W:1
for %%S in (_damage _wreck) do (
  if exist "%CO%\assets\ships\%OV_CODE%\%OV_CODE%%%S.glb" (
    if not exist "%ASIDE%" mkdir "%ASIDE%"
    move /y "%CO%\assets\ships\%OV_CODE%\%OV_CODE%%%S.glb" "%ASIDE%\" > nul
    echo moved aside %OV_CODE%%%S.glb into %ASIDE%
  )
)
robocopy "%OV_FROM%\assets\ships\%OV_CODE%" "%CO%\assets\ships\%OV_CODE%" /E /NFL /NDL /NJH /NJS /R:1 /W:1
"%OV_PY%" "%~1\tools\recipe\manifest_merge.py" "%OV_ENTRY%" "%CO%" %OV_CODE%
if errorlevel 1 (echo OVERLAY FAILED: the manifest entry was not merged & exit /b 1)
call "%TMO%" 1800 "%G%" --headless --path "%CO%" --import > "%~1\overlay_import.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%CO%" --script res://render/build_assets.gd -- --ships-only > "%~1\overlay_cache.txt" 2>&1
findstr /c:"[assets] ships refreshed" "%~1\overlay_cache.txt" > nul || (echo OVERLAY FAILED: the ship cache was not refreshed, see %~1\overlay_cache.txt & exit /b 1)
call "%TMO%" 600 "%G%" --headless --path "%CO%" --script res://render/test/installed_ship_check.gd -- %OV_CODE% > "%~1\overlay_readback.txt" 2>&1
findstr /c:"INSTALL READBACK PASS" "%~1\overlay_readback.txt" > nul || (type "%~1\overlay_readback.txt" & echo OVERLAY FAILED: the game does not draw the new %OV_CODE% & exit /b 1)
echo OVERLAY PASS: %OV_CODE% from %OV_FROM% laid over %CO%, every other hull from %LB_SHIPS%
endlocal
exit /b 0
