@echo off
rem Issue 370 job A (no GPU): lean sparse clone of opus/issue-370, the built hulls' source files (all 36 A4 ships, plus
rem the recipe ship C15s_23 from opus209\out7 in place of the A4 one), the game's own import and asset build, then the
rem attach check on every hull. Copies only; writes only under opus370\. Never deletes anything.
setlocal
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus370"
set /p G=<"%R%\godot_path.txt"
set "P=%D%\repo\godot"
cd /d "%D%"
echo start %date% %time% > "%D%\status_a.txt"
if not exist "%D%\repo\.git" (
  git -c core.autocrlf=false clone --filter=blob:none --sparse --branch opus/issue-370 https://github.com/rcbailey12/voidsworn.git "%D%\repo" > "%D%\log_clone.txt" 2>&1
  git -C "%D%\repo" sparse-checkout set --no-cone "/godot/*" "!/godot/music/" "!/godot/portraits/" "!/godot/fx/test/results/" "!/godot/assets/ships/previews/" >> "%D%\log_clone.txt" 2>&1
)
git -C "%D%\repo" fetch origin opus/issue-370 main >> "%D%\log_clone.txt" 2>&1
git -C "%D%\repo" checkout -f --detach origin/opus/issue-370 >> "%D%\log_clone.txt" 2>&1
git -C "%D%\repo" rev-parse HEAD > "%D%\commit_after.txt"
if not exist "%P%\project.godot" (
  echo clone failed >> "%D%\status_a.txt"
  exit /b 1
)
robocopy "%R%\build\godot\assets\ships" "%P%\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP /R:1 /W:1 > "%D%\log_copy.txt" 2>&1
robocopy "%R%\build\godot\gen" "%P%\gen" /E /XD hi damage wreck ships /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >> "%D%\log_copy.txt" 2>&1
rem the recipe ship replaces the A4 C15s_23 (as the 559 trace did): its glb and maps only
copy /y "%R%\opus209\out7\export\C15s_23\C15s_23.glb" "%P%\assets\ships\C15s_23\" >> "%D%\log_copy.txt" 2>&1
copy /y "%R%\opus209\out7\export\C15s_23\C15s_23_*.jpg" "%P%\assets\ships\C15s_23\" >> "%D%\log_copy.txt" 2>&1
echo copied %time% >> "%D%\status_a.txt"
call "%D%\tmo.bat" 3600 "%G%" --headless --path "%P%" --import > "%D%\log_import.txt" 2>&1
echo import exit %errorlevel% %time% >> "%D%\status_a.txt"
call "%D%\tmo.bat" 2400 "%G%" --headless --path "%P%" --script res://render/build_assets.gd -- --repo "%D%\norepo" > "%D%\log_build.txt" 2>&1
echo build_assets exit %errorlevel% %time% >> "%D%\status_a.txt"
call "%D%\tmo.bat" 2400 "%G%" --headless --path "%P%" --script res://fx/test/attach_check.gd -- --out "%D%\attach_after.json" > "%D%\log_attach_after.txt" 2>&1
echo attach check exit %errorlevel% %time% >> "%D%\status_a.txt"
echo done %date% %time% >> "%D%\status_a.txt"
exit /b 0
