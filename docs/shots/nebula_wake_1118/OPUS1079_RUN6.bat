@echo off
rem Issue 1079 run 6 (Ryan, Nov 19: make the capital's wake as steady as the frigate's): the clip again, nothing else, on the new
rem wake code (capital points closer together, one swirl side per ship). Opus worker; R334, the Board queues it.
rem Writes only under Downloads\voidsworn_test\opus1079\. Never deletes anything. Every step logs to out6\result.txt.
rem 1. Clone branch opus/issue-1079 fresh into opus1079\run<N>\repo (first free N).
rem 2. Copy in the installed ship files, the built hull cache (gen) and the import cache from build\godot (copy only).
rem 3. Godot import of the clone.
rem 4. Clip: the dense-storm fixture, a frigate and a capital fly through the nebula, wake off then on, 1280x720, 30 fps,
rem    at the battle camera (c170) and closer (c120). Frames only; the cloud assembles and checks the video. GPU shared.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus1079"
set "R=%W%\repo"
set "O=%W%\out6"
set "B=%VT%\build\godot"
set "G="
if exist "%VT%\godot_path.txt" set /p G=<"%VT%\godot_path.txt"
if not defined G set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%O%" mkdir "%O%"
set "RES=%O%\result.txt"
echo start run 6 %date% %time% >> "%RES%"
if not exist "%G%" (set "FAILMSG=no Godot at %G%" & goto fail)
rem Artoo on PR 1181: never reset a reused clone. Each run clones fresh into the first free run folder; nothing is removed.
set "N=1"
:findrun
if exist "%W%\run%N%" (set /a N+=1 & goto findrun)
set "R=%W%\run%N%\repo"
echo run folder %W%\run%N% >> "%RES%"
git clone --depth 1 --branch opus/issue-1079 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git clone failed; see out6\git_log.txt" & goto fail)
:cloned
for /f %%H in ('git -C "%R%" log -1 --format^=%%H') do set "HASH=%%H"
echo commit %HASH% >> "%RES%"
rem Artoo on PR 1181 (issue 1228): every Godot start here runs in a throwaway profile, so no battle can rewrite Ryan's
rem real options. His battle_opts.json and board_look.cfg are hashed before and after; a change fails the run.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set "PROF=%W%\profile_%N%"
if not exist "%PROF%\appdata" mkdir "%PROF%\appdata"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_before.txt" 2>&1
set "APPDATA=%PROF%\appdata"
set "LOCALAPPDATA=%PROF%\appdata"
echo throwaway profile %PROF%\appdata >> "%RES%"
set "TMO=%VT%\build\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
robocopy "%B%\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_ships.txt" 2>&1
if errorlevel 8 (set "FAILMSG=ship copy failed; see out6\copy_ships.txt" & goto fail)
robocopy "%B%\gen" "%R%\godot\gen" /E /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_gen.txt" 2>&1
if errorlevel 8 (set "FAILMSG=gen copy failed; see out6\copy_gen.txt" & goto fail)
robocopy "%B%\.godot" "%R%\godot\.godot" /E /NP /NDL /NFL /R:1 /W:1 > "%O%\copy_import.txt" 2>&1
if errorlevel 8 (set "FAILMSG=import cache copy failed; see out6\copy_import.txt" & goto fail)
if not exist "%R%\godot\gen\v3.txt" (set "FAILMSG=build\godot\gen has no v3.txt; the hull cache is not built" & goto fail)
echo copied ships, gen and import cache from build\godot %time% >> "%RES%"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=Godot import failed; see out6\import_log.txt" & goto fail)
echo import ok %time% >> "%RES%"
set "PC_GPU_ISSUE=1079"
set "PC_GPU_MODE=shared"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --fixed-fps 30 --script res://world/nebula_wake_capture.gd -- "%O%\clip" shots max 1280 720 170 > "%O%\clip_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=clip capture c170 failed; see out6\clip_log.txt" & goto fail)
if not exist "%O%\clip\max_c170_on\f0329.jpg" (set "FAILMSG=clip c170 is missing frames" & goto fail)
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --fixed-fps 30 --script res://world/nebula_wake_capture.gd -- "%O%\clip" shots max 1280 720 120 > "%O%\clip120_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=clip capture c120 failed; see out6\clip120_log.txt" & goto fail)
echo clip frames ok (c170 and c120) %time% >> "%RES%"
call :realcheck
if errorlevel 1 (set "FAILMSG=Ryan's real options changed during the run; see out6\real_profile_*.txt" & goto fail)
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
