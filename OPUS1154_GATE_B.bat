@echo off
rem Issue 1154, scene gate rerun B (RULEBOOK 3.9) with C13 (B20_11) installed, solo on the RTX 5080.
rem Run A failed: the clone opus1154\repo had no built hulls (19 "placeholder hull" errors: V1b_r_23, V17_37 and the other
rem old hulls), and the base build timed out before the gate measured anything. This run prepares the clone the way the
rem issue 207 gate job does (tools\pc\jobs\bench207_scene_gate.bat), then measures:
rem   1. the ship files built on this PC copied from build\godot\assets\ships into the clone (copy only), except B20_11,
rem      which stays this branch's own install;
rem   2. one Godot import, then build_assets with the hi and env folders from %VT%\bench207_settings.txt until
rem      godot\gen\v3.txt exists (up to 3 passes), so every hull is real, not a placeholder;
rem   3. the B20_11 readback (installed_ship_check.gd), logged;
rem   4. two launches of the gate (base, res_1440, res_2160), the second kept: it must write a fresh scene_gate.json and
rem      log no "placeholder hull".
rem Throwaway profile guard (issue 1228): APPDATA and LOCALAPPDATA point into opus1154\profile, so no Godot run here can
rem rewrite Ryan's real settings. Writes only under opus1154\; deletes nothing.
rem Everything logs to opus1154\out_b\; result.txt ends in "all done PASS" or "all done FAILED: <step>", and the job exits
rem 0 only on PASS.
setlocal EnableDelayedExpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "C=%VT%\opus1154\repo"
set "O=%VT%\opus1154\out_b"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
if exist "%VT%\godot_path.txt" set /p GD=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
set "RES=%O%\result.txt"
echo start scene gate B %DATE% %TIME% > "%RES%"
set "FAILMSG="
if not exist "%C%\godot\assets\ships\B20_11\B20_11.glb" (set "FAILMSG=no installed B20_11 in the clone; run the paint run first" & goto fail)
if not exist "%VT%\build\godot\assets\ships" (set "FAILMSG=no build\godot\assets\ships to copy the PC's ships from" & goto fail)
set "SETF=%VT%\bench207_settings.txt"
set "HI="
set "ENVF="
if exist "%SETF%" for /f "usebackq tokens=1,* delims==" %%A in ("%SETF%") do (
  if /i "%%A"=="hi" set "HI=%%B"
  if /i "%%A"=="env" set "ENVF=%%B"
)
if not defined HI (set "FAILMSG=no hi= line in %SETF%" & goto fail)
if not defined ENVF (set "FAILMSG=no env= line in %SETF%" & goto fail)
if not exist "%HI%" (set "FAILMSG=the hi folder does not exist: %HI%" & goto fail)
if not exist "%ENVF%" (set "FAILMSG=the env folder does not exist: %ENVF%" & goto fail)
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
rem the throwaway profile (after git, which reads its own settings from the real profile)
set "PROF=%VT%\opus1154\profile"
if not exist "%PROF%\Roaming" mkdir "%PROF%\Roaming"
if not exist "%PROF%\Local" mkdir "%PROF%\Local"
set "APPDATA=%PROF%\Roaming"
set "LOCALAPPDATA=%PROF%\Local"
echo profile guard APPDATA=%APPDATA% >> "%RES%"
set "TMO=%C%\tools\pc\tmo.bat"
rem 1. the PC's built ships into the clone, B20_11 excepted
robocopy "%VT%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews B20_11 /NP /NDL /R:1 /W:1 > "%O%\shipcopy_log.txt" 2>&1
if errorlevel 8 (set "FAILMSG=the ship copy failed; see %O%\shipcopy_log.txt" & goto fail)
echo ship copy done >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -File '%C%\godot\assets\ships' -Filter *.glb | ForEach-Object { $_.LastWriteTime = Get-Date }"
rem 2. import and asset build
call "%TMO%" 2400 "%GD%" --headless --path "%C%\godot" --import > "%O%\import_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=the Godot import failed; see %O%\import_log.txt" & goto fail)
echo import done >> "%RES%"
for %%N in (1 2 3) do (
  if "%%N"=="1" (set RUNB=1) else (set RUNB=)
  if not exist "%C%\godot\gen\v3.txt" set RUNB=1
  if defined RUNB (
    call "%TMO%" 2400 "%GD%" --headless --path "%C%\godot" --script res://render/build_assets.gd -- --repo "%C%" --hi "%HI%" --env "%ENVF%" >> "%O%\build_assets_log.txt" 2>&1
    echo build_assets pass %%N exit !ERRORLEVEL! >> "%RES%"
  )
)
if not exist "%C%\godot\gen\v3.txt" (set "FAILMSG=build_assets wrote no godot\gen\v3.txt after 3 passes; see %O%\build_assets_log.txt" & goto fail)
rem 3. C13 still reads back as installed after the asset build
call "%TMO%" 600 "%GD%" --headless --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- B20_11 > "%O%\log_readback.txt" 2>&1
echo B20_11 readback exit %ERRORLEVEL% >> "%RES%"
rem 4. the gate, solo
set PC_GPU_MODE=solo
set PC_GPU_ISSUE=1154
set PC_GPU_WAIT_SECONDS=7200
for %%N in (1 2) do (
  echo gate %%N started > "%O%\gate_%%N_started.txt"
  call "%TMO%" 2400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\scene_gate_%%N" --modes base,res_1440,res_2160 > "%O%\log_scene_gate_%%N.txt" 2>&1
  echo scene gate %%N exit !ERRORLEVEL! >> "%RES%"
  findstr /c:"placeholder hull" "%O%\log_scene_gate_%%N.txt" > nul && echo scene gate %%N STILL HAS PLACEHOLDER HULLS >> "%RES%"
)
findstr /c:"placeholder hull" "%O%\log_scene_gate_2.txt" > nul && (set "FAILMSG=placeholder hulls in the measured launch; see %O%\log_scene_gate_2.txt" & goto fail)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=Get-Item -LiteralPath '%O%\gate_2_started.txt'; $r=Get-Item -LiteralPath '%O%\scene_gate_2\scene_gate.json' -ErrorAction Stop; if ($r.LastWriteTimeUtc -le $m.LastWriteTimeUtc) { exit 1 }"
if errorlevel 1 (set "FAILMSG=launch 2 wrote no fresh scene_gate.json; see %O%\log_scene_gate_2.txt" & goto fail)
findstr /l /c:"[scene_gate] DONE" "%O%\log_scene_gate_2.txt" >> "%RES%" 2>&1
findstr /i /c:"B20_11" "%O%\log_scene_gate_2.txt" >> "%RES%" 2>&1
echo all done PASS %DATE% %TIME% >> "%RES%"
exit /b 0
:fail
echo FAILED: %FAILMSG% >> "%RES%"
echo all done FAILED: %FAILMSG% %DATE% %TIME% >> "%RES%"
exit /b 1
