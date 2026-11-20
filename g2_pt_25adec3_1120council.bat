@echo off
rem G2 playtest exe for the 1120 council audit, from main 25adec313dd8370fa2007032939378eec2d29097 (lane A, Board Nov 20 16:10 UTC, Ryan R319).
rem Current recipe (LOOP.md lane A, PR 1042 captures) with one widening: the code archive is the WHOLE tracked godot tree at the pin (one zip, no ship
rem glbs, no gen), because main changed project.godot ([shader_globals]), music\ and bench\, which the src1..src3 split leaves stale.
rem 0. Ship check before anything moves: every ship file the pin's manifest lists must match build\godot\assets\ships (fail closed).
rem 1. Sync: code folders move aside to ..\sync_old\<T>\ (nothing is deleted), then the godot archive unpacks over build\godot (assets\ships
rem    gets only its tracked text files and previews; installed glbs, gen and .godot stay) and tools\pc + tools\picture_font.json unpack at the root.
rem    export\previous moves aside too, so the export's own move overwrites nothing.
rem 2. Ship check again after the sync, on the files the export packs (the pin's manifest is now the one on the PC).
rem 3. g2_playtest_capture.bat prepare <full SHA> <git %cI date>; then g2_export.bat only on exit 0; then capture into the fresh shots\<T>\.
rem tools\pc\tmo.bat here is main's, byte-identical to tools_live 5b6fdb65e676 pc\tmo.bat and run_timeout.ps1. Ends with exit /b <0 or 1>.
setlocal enabledelayedexpansion
if not exist godot\project.godot (
  echo not in build
  exit /b 1
)
set "T=g2_pt_25adec3_1120council"
set "SHA=25adec313dd8370fa2007032939378eec2d29097"
set "SHADATE=2026-11-20T17:27:14+00:00"
set "S=%CD%\..\shots\%T%"
set "OLD=%CD%\..\sync_old\%T%"
set "RC=1"
if exist "%S%" (echo FAIL: %S% already exists, refusing to reuse a playtest folder & exit /b 1)
mkdir "%S%"
if not exist "%OLD%" mkdir "%OLD%"
echo [%date% %time%] start, main %SHA% > "%S%\result.txt"
for %%Z in (%T%_godot.zip %T%_tools.zip %T%_manifest.json %T%_mcheck.ps1) do if not exist %%Z echo FAIL: missing %%Z >> "%S%\result.txt"
findstr /c:"FAIL: missing" "%S%\result.txt" > nul
if not errorlevel 1 goto done
call tools\pc\tmo.bat 600 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CD%\%T%_mcheck.ps1" -Manifest "%CD%\%T%_manifest.json" -ShipDir "%CD%\godot\assets\ships" -Out "%S%\manifest_check_before_sync.txt" > "%S%\manifest_check_before_sync_log.txt" 2>&1
echo manifest check before sync exit !ERRORLEVEL! >> "%S%\result.txt"
type "%S%\manifest_check_before_sync.txt" >> "%S%\result.txt"
findstr /c:"MANIFEST OK" "%S%\manifest_check_before_sync.txt" > nul
if errorlevel 1 (
  echo FAIL: ship manifest check did not pass, nothing moved, no build >> "%S%\result.txt"
  goto done
)
for %%D in (audio bench campaign fx main music portraits render rules scenes story ui world) do if exist godot\%%D move godot\%%D "%OLD%\%%D" > nul
for %%D in (audio bench campaign fx main music portraits render rules scenes story ui world) do if exist godot\%%D echo could not move godot\%%D aside, unpacking over it >> "%S%\result.txt"
if exist export\previous move export\previous "%OLD%\export_previous" > nul
if exist export\previous echo could not move export\previous aside >> "%S%\result.txt"
tar -xf %T%_godot.zip -C godot
if errorlevel 1 echo FAIL: unpack godot >> "%S%\result.txt"
tar -xf %T%_tools.zip -C .
if errorlevel 1 echo FAIL: unpack tools >> "%S%\result.txt"
findstr /c:"FAIL: unpack" "%S%\result.txt" > nul
if not errorlevel 1 goto done
call tools\pc\tmo.bat 600 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CD%\%T%_mcheck.ps1" -Manifest "%CD%\godot\assets\ships\manifest.json" -ShipDir "%CD%\godot\assets\ships" -Out "%S%\manifest_check_packaged.txt" > "%S%\manifest_check_packaged_log.txt" 2>&1
echo manifest check on the packaged ship files exit !ERRORLEVEL! >> "%S%\result.txt"
type "%S%\manifest_check_packaged.txt" >> "%S%\result.txt"
findstr /c:"MANIFEST OK" "%S%\manifest_check_packaged.txt" > nul
if errorlevel 1 (
  echo FAIL: packaged ship files do not match the pin's manifest, no export >> "%S%\result.txt"
  goto done
)
call tools\pc\jobs\g2_playtest_capture.bat prepare %SHA% %SHADATE% > "%S%\prepare_log.txt" 2>&1
set "PX=!ERRORLEVEL!"
echo [%date% %time%] prepare exit !PX! >> "%S%\result.txt"
if not "!PX!"=="0" goto done
type godot\build_info.json >> "%S%\result.txt"
echo. >> "%S%\result.txt"
echo [%date% %time%] synced, export start >> "%S%\result.txt"
set "PT_SHOTS=%S%"
for /f "delims=" %%Q in ('powershell -NoProfile -Command "(Get-Date).ToString('s')"') do set "SMOKE_SINCE=%%Q"
call "%CD%\..\board1119\pt_25adec3\g2_export_nopromote.bat"
set "EX=!ERRORLEVEL!"
echo [%date% %time%] export (no promotion) exit code !EX! >> "%S%\result.txt"
if not "!EX!"=="0" (echo FAIL: export or check step failed, nothing promoted, Nov 17 build stays live >> "%S%\result.txt" & goto done)
set "CAND="
set /p CAND=<"%S%\candidate.txt"
echo candidate !CAND! >> "%S%\result.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\..\board1119\pt_25adec3\smoke_check.ps1" -Report "%S%\smoke.json" -Log "%S%\export_log.txt" -Since "!SMOKE_SINCE!" -Out "%S%\result.txt"
set "SC=!ERRORLEVEL!"
echo smoke check exit !SC! >> "%S%\result.txt"
if not "!SC!"=="0" (echo FAIL: smoke check did not pass, candidate NOT promoted, Nov 17 build stays live >> "%S%\result.txt" & goto done)
if exist export-previous-pt1120c (echo FAIL: export-previous-pt1120c exists, not promoting >> "%S%\result.txt" & goto done)
move export export-previous-pt1120c > nul
if errorlevel 1 (echo FAIL: could not move the live export aside, not promoting >> "%S%\result.txt" & goto done)
move "!CAND!" export > nul
if errorlevel 1 (move export-previous-pt1120c export > nul & echo FAIL: could not move the candidate in, live export restored >> "%S%\result.txt" & goto done)
echo [%date% %time%] promoted by hand: !CAND! to export, the Nov 17 build to export-previous-pt1120c >> "%S%\result.txt"
dir export >> "%S%\result.txt"
set "PC_GPU_ISSUE=1363"
call tools\pc\jobs\g2_playtest_capture.bat capture "%S%"
set "CX=!ERRORLEVEL!"
echo [%date% %time%] capture exit !CX! >> "%S%\result.txt"
if "!CX!"=="0" set "RC=0"
:done
echo [%date% %time%] build bat done, exit !RC! >> "%S%\result.txt"
type "%S%\result.txt"
endlocal & exit /b %RC%