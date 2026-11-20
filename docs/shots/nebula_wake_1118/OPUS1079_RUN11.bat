@echo off
rem Issue 1079 run 11 (Fable on PR 1181: a ship that moved and parked kept its trail slot, so a later mover's trail was cut short; fixed, and the look of one ship flying and stopping is unchanged from run 10), same steps and safeguards as run 10: the wake is one continuous strip
rem along each ship's path instead of separate points. Clip, stills, storm-fixture cost and scene 207 cost, all again.
rem Opus worker; R334, the Board queues it. Writes only under Downloads\voidsworn_test\opus1079\. Never deletes anything.
rem Every step logs to out11_<N>\result.txt, N the attempt number.
rem 1. Clone branch opus/issue-1079 fresh into opus1079\run<N>\repo (first free N), throwaway Windows profile.
rem 2. Copy in the installed ship files, the built hull cache (gen) and the import cache from build\godot (copy only).
rem 3. Godot import of the clone.
rem 4. Clip (GPU shared): wake off then on, 1280x720, 30 fps, at c170 and c120. Stills at max, high and low.
rem 5. Cost, GPU solo (R293): the dense-storm fixture, wake off/on, max, high and low, 1080p and 4K, 3 sessions; then
rem    scene 207 (bench\scene_gate.tscn) modes base, wake_idle, wake_full, 3 sessions.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus1079"
set "B=%VT%\build\godot"
set "G="
if exist "%VT%\godot_path.txt" set /p G=<"%VT%\godot_path.txt"
if not defined G set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
rem Artoo on PR 1181: fresh proof per attempt. Claim the first free attempt number N by creating run<N> (mkdir fails if
rem it exists, so two starts never share one); this attempt's clone, output (out11_<N>) and profile (profile_<N>) are all
rem new folders, so no check below can ever read an earlier attempt's frame, json or receipt. Nothing is removed.
if not exist "%W%" mkdir "%W%"
set "N=1"
:findrun
mkdir "%W%\run%N%" 2> nul || (set /a N+=1 & goto findrun)
set "R=%W%\run%N%\repo"
set "O=%W%\out11_%N%"
mkdir "%O%" 2> nul || (echo out folder %O% already exists & exit /b 1)
set "RES=%O%\result.txt"
echo start run 11 attempt %N% %date% %time% >> "%RES%"
echo run folder %W%\run%N% >> "%RES%"
echo out folder %O% >> "%RES%"
if not exist "%G%" (set "FAILMSG=no Godot at %G%" & goto fail)
git clone --depth 1 --branch opus/issue-1079 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git clone failed; see %O%\git_log.txt" & goto fail)
:cloned
for /f %%H in ('git -C "%R%" log -1 --format^=%%H') do set "HASH=%%H"
echo commit %HASH% >> "%RES%"
rem The game code must be exactly what this run was written for: the godot\ tree of e74c21d1 (later commits that only
rem touch docs keep it). Any other godot\ tree fails the run.
for /f %%T in ('git -C "%R%" rev-parse HEAD:godot') do set "TREE=%%T"
echo godot tree %TREE% >> "%RES%"
if not "%TREE%"=="45e2fddb5a56164e393ada68171d7edecf5a9449" (set "FAILMSG=the clone's godot tree is %TREE%, not the one this run was written for" & goto fail)
rem Artoo on PR 1181 (issue 1228): every Godot start here runs in a throwaway profile, so no battle can rewrite Ryan's
rem real options. His battle_opts.json and board_look.cfg are hashed before and after; a change fails the run.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set "PROF=%W%\profile_%N%"
if exist "%PROF%" (set "FAILMSG=profile folder %PROF% already exists; this attempt needs a fresh one" & goto fail)
mkdir "%PROF%\appdata"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_before.txt" 2>&1
set "APPDATA=%PROF%\appdata"
set "LOCALAPPDATA=%PROF%\appdata"
echo throwaway profile %PROF%\appdata >> "%RES%"
rem Artoo (1077, PR 1231): every Godot start goes through the canonical watchdog, tools_live's current version (named in
rem tools_live\current.txt), never a build or clone copy. Its path and both hashes go in the receipt.
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (set "FAILMSG=tools_live\current.txt is missing or empty" & goto fail)
set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" (set "FAILMSG=no watchdog at %TMO%" & goto fail)
if not exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" (set "FAILMSG=no run_timeout.ps1 beside %TMO%" & goto fail)
echo watchdog %TMO% >> "%RES%"
certutil -hashfile "%TMO%" SHA256 >> "%RES%" 2>&1
certutil -hashfile "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" SHA256 >> "%RES%" 2>&1
robocopy "%B%\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_ships.txt" 2>&1
if errorlevel 8 (set "FAILMSG=ship copy failed; see %O%\copy_ships.txt" & goto fail)
robocopy "%B%\gen" "%R%\godot\gen" /E /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_gen.txt" 2>&1
if errorlevel 8 (set "FAILMSG=gen copy failed; see %O%\copy_gen.txt" & goto fail)
robocopy "%B%\.godot" "%R%\godot\.godot" /E /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_import.txt" 2>&1
if errorlevel 8 (set "FAILMSG=import cache copy failed; see %O%\copy_import.txt" & goto fail)
if not exist "%R%\godot\gen\v3.txt" (set "FAILMSG=build\godot\gen has no v3.txt; the hull cache is not built" & goto fail)
echo copied ships, gen and import cache from build\godot %time% >> "%RES%"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=Godot import failed; see %O%\import_log.txt" & goto fail)
echo import ok %time% >> "%RES%"
set "PC_GPU_ISSUE=1079"
set "PC_GPU_MODE=shared"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --fixed-fps 30 --script res://world/nebula_wake_capture.gd -- "%O%\clip" shots max 1280 720 170 > "%O%\clip_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=clip capture c170 failed; see %O%\clip_log.txt" & goto fail)
if not exist "%O%\clip\max_c170_on\f0329.jpg" (set "FAILMSG=clip c170 is missing frames" & goto fail)
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --fixed-fps 30 --script res://world/nebula_wake_capture.gd -- "%O%\clip" shots max 1280 720 120 > "%O%\clip120_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=clip capture c120 failed; see %O%\clip120_log.txt" & goto fail)
echo clip frames ok (c170 and c120) %time% >> "%RES%"
echo stills start %time% >> "%RES%"
:stills
for %%T in (max high low) do (
  call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --script res://world/nebula_wake_capture.gd -- "%O%\still" still %%T 1280 720 > "%O%\still_%%T_log.txt" 2>&1
  if errorlevel 1 (set "FAILMSG=still %%T failed; see %O%\still_%%T_log.txt" & goto fail)
)
echo stills ok %time% >> "%RES%"
set "PC_GPU_MODE=solo"
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv > "%O%\gpu.csv" 2>&1
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://world/nebula_wake_capture.gd -- "%O%\timing" timing > "%O%\timing_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=storm fixture timing failed; see %O%\timing_log.txt" & goto fail)
echo storm fixture timing ok %time% >> "%RES%"
:gate
set "PC_GPU_ISSUE=1079"
set "PC_GPU_MODE=solo"
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv >> "%O%\gpu.csv" 2>&1
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\gate" --sessions 3 --warmup 180 --frames 720 --modes base,wake_idle,wake_full --build-wait-s 300 > "%O%\gate_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=scene 207 gate failed; see %O%\gate_log.txt" & goto fail)
if not exist "%O%\gate\scene_gate.json" (set "FAILMSG=scene 207 gate wrote no scene_gate.json" & goto fail)
echo scene 207 gate ok %time% >> "%RES%"
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv,noheader >> "%O%\gpu.csv" 2>&1
call :realcheck
if errorlevel 1 (set "FAILMSG=Ryan's real options changed during the run; see %O%\real_profile_*.txt" & goto fail)
echo real options unchanged >> "%RES%"
echo all done >> "%RES%"
exit /b 0
:realcheck
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_after.txt" 2>&1
fc /b "%O%\real_profile_before.txt" "%O%\real_profile_after.txt" > nul
exit /b %ERRORLEVEL%
:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REALU (call :realcheck & if errorlevel 1 (echo FAILED: Ryan's real options changed during the run >> "%RES%") else (echo real options unchanged >> "%RES%"))
echo all done >> "%RES%"
exit /b 1
