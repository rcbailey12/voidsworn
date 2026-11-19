@echo off
rem Issue 1078: the shield failure looks (today's, energy shear, clean collapse) on the installed ships, for Ryan to pick.
rem   shield_looks_1078.bat [REF]     REF defaults to origin/opus/issue-1078
rem Writes Downloads\voidsworn_test\shield1078\<run>\: the sheets (one per subject, shield shape and camera), clip
rem frames and an mp4 per story when an ffmpeg is found, then the cost pass with the GPU to itself (R293: PC_GPU_MODE=solo,
rem every shielded ship failing in the same frame, GPU time per look). status.txt says where it is. Nothing is deleted.
rem Optional settings: S1078_SHIPS (a godot folder with the installed hulls, default build\godot), S1078_SKIP_LOOK=1,
rem S1078_SKIP_COST=1, S1078_SUBJECTS (rules ids).
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HOME1078=%VT%\shield1078"
set "REF=%~1"
if "%REF%"=="" set "REF=origin/opus/issue-1078"
if "%S1078_SHIPS%"=="" set "S1078_SHIPS=%VT%\build\godot"
if not exist "%HOME1078%" mkdir "%HOME1078%"
set "ST=%HOME1078%\status.txt"
echo shield1078 start %date% %time% ref=%REF% > "%ST%"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\build\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%VT%\build_b\tools\pc\tmo.bat"

set "R=%HOME1078%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%HOME1078%\git.txt" 2>&1
git -C "%R%" fetch origin >> "%HOME1078%\git.txt" 2>&1
git -C "%R%" checkout -f --detach %REF% >> "%HOME1078%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %REF% >> "%ST%"
  goto finish
)
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "SHA=%%H"
set "OUT=%HOME1078%\%SHA%"
if not exist "%OUT%" mkdir "%OUT%"
echo commit %SHA% >> "%ST%"
rem the installed hulls and the import cache a fresh clone lacks (copy only, never over newer files)
if exist "%S1078_SHIPS%\gen" robocopy "%S1078_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_gen.txt" 2>&1
if exist "%S1078_SHIPS%\assets\ships" robocopy "%S1078_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_ships.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%S1078_SHIPS%\.godot" robocopy "%S1078_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_cache.txt" 2>&1
set "PICTURE_STAMP_TOOL=%R%\tools\picture_provenance.py"
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%OUT%\import.txt" 2>&1
echo imported %date% %time% >> "%ST%"

if "%S1078_SKIP_LOOK%"=="1" goto cost
set "PROBE_OUT=%OUT%\look"
set "PROBE_CLIP=1"
set "PROBE_COST="
if not "%S1078_SUBJECTS%"=="" set "PROBE_SUBJECTS=%S1078_SUBJECTS%"
set "PC_GPU_MODE=shared"
call "%TMO%" 5400 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\look_log.txt" 2>&1
findstr /c:"SHIELD1078_DONE" "%OUT%\look_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the look pass did not finish, see %OUT%\look_log.txt >> "%ST%"
  goto finish
)
echo look pass done %date% %time% >> "%ST%"
rem clips: ffmpeg from PATH, else the one inside ComfyUI's portable Python (imageio_ffmpeg)
set "FF="
where ffmpeg > nul 2>&1 && set "FF=ffmpeg"
set "CPY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if "%FF%"=="" if exist "%CPY%" for /f "delims=" %%F in ('"%CPY%" -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())" 2^>nul') do set "FF=%%F"
if "%FF%"=="" (
  echo no ffmpeg: clip frames kept, no mp4 >> "%ST%"
  goto cost
)
for /d %%D in ("%OUT%\look\clip_*") do "%FF%" -y -loglevel error -framerate 30 -i "%%D\f_%%04d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 20 "%OUT%\look\%%~nxD.mp4"
echo clips done %date% %time% >> "%ST%"

:cost
if "%S1078_SKIP_COST%"=="1" goto done
set "PROBE_OUT=%OUT%\cost"
set "PROBE_CLIP="
set "PROBE_COST=1"
set "PROBE_SHAPES=fitted,egg"
set "PC_GPU_MODE=solo"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\cost_log.txt" 2>&1
set "PC_GPU_MODE="
findstr /c:"SHIELD1078_DONE" "%OUT%\cost_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the cost pass did not finish, see %OUT%\cost_log.txt >> "%ST%"
  goto finish
)
echo cost pass done %date% %time% >> "%ST%"

rem the same cost pass on main (today's look only, the probe copied in), so the numbers compare against main itself
copy /y "%R%\godot\fx\test\shield_fail_probe.gd" "%HOME1078%\probe_copy.gd" > nul
git -C "%R%" checkout -f --detach origin/main >> "%HOME1078%\git.txt" 2>&1
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "MSHA=%%H"
copy /y "%HOME1078%\probe_copy.gd" "%R%\godot\fx\test\shield_fail_probe.gd" > nul
set "PROBE_OUT=%OUT%\cost_main_%MSHA%"
set "PROBE_LOOKS=today"
set "PC_GPU_MODE=solo"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\cost_main_log.txt" 2>&1
set "PC_GPU_MODE="
set "PROBE_LOOKS="
echo main cost pass %MSHA% done %date% %time% >> "%ST%"

:done
git -C "%R%" checkout -f --detach %SHA% > nul 2>&1
echo DONE %SHA% %date% %time% >> "%ST%"

:finish
echo shield1078 end %date% %time% >> "%ST%"
endlocal
