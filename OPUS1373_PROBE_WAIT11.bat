@echo off
title GPU line: 1373 squadron_probe at 9c0acd29, GPU solo (Board, Nov 20)
rem Board, Nov 20 19:47 UTC (replaces WAIT to WAIT10, all stopped before they ran): waits for the five BJ exits (chain_1119bj.txt); kits from opus1373n, o, p, q, r;
rem and "OPUS1369 frontend exit" in opus1369d_wait.txt, refreshes repo-mirror.git for 03a916d3, makes a fresh clone in opus1373probe11\repo, copies build\godot's
rem ships and gen in, then the five 1373 installs from the job clones (opus1373a..e: assets\ships\<code>\ and gen\ships\<code>.*), imports, then runs
rem res://fx/test/squadron_probe.gd through build\tools\pc\tmo.bat with PC_GPU_MODE=solo (nothing else on the GPU during the run, timing pass included),
rem PC_GPU_ISSUE=1373 and SQUADRON_OUT=opus1373probe11\out. End line "OPUS1373 probe exit". Writes opus1373probe11_wait.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "SHA=9c0acd29c9fe5da9a652517f4fbf2382bfc8c7f3"
set "W=%V%\opus1373probe11"
set "R=%W%\repo"
set "L=%V%\opus1373probe11_wait.txt"
set "PC_GPU_ISSUE=1373"
set "PC_GPU_WAIT_SECONDS=3600"
set /p G=<"%V%\godot_path.txt"
echo waiting for the five BJ exits %DATE% %TIME% > "%L%"
:wait
findstr /b /c:"1373 chorus_CS1BA2_R3 exit" "%V%\chain_1119bj.txt" >nul 2>&1 || goto sleep
findstr /b /c:"1373 ithar_GF1_R4 exit" "%V%\chain_1119bj.txt" >nul 2>&1 || goto sleep
findstr /b /c:"1373 ithar_GB1_R8 exit" "%V%\chain_1119bj.txt" >nul 2>&1 || goto sleep
findstr /b /c:"1373 hegemony_HB1_R5 exit" "%V%\chain_1119bj.txt" >nul 2>&1 || goto sleep
findstr /b /c:"1373 corsair_KF1_R3 exit" "%V%\chain_1119bj.txt" >nul 2>&1 && goto go

:sleep
timeout /t 60 /nobreak >nul
goto wait
:go

powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" %SHA% >> "%L%" 2>&1
if exist "%W%" (echo FAIL: %W% already exists >> "%L%" & echo OPUS1373 probe exit 1 at %TIME% >> "%L%" & exit /b 1)
mkdir "%W%"
git -c core.autocrlf=false clone -q --no-checkout "%V%\repo-mirror.git" "%R%" >> "%L%" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%L%" 2>&1
for /f %%H in ('git -C "%R%" rev-parse HEAD') do echo clone at %%H >> "%L%"
robocopy "%V%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP > "%W%\log_copy_ships.txt" 2>&1
robocopy "%V%\build\godot\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /NP > "%W%\log_copy_gen.txt" 2>&1
for %%P in (opus1373n:chorus_CS1BA2 opus1373o:ithar_GF1 opus1373p:ithar_GB1 opus1373q:hegemony_HB1 opus1373r:corsair_KF1) do (
  for /f "tokens=1,2 delims=:" %%X in ("%%P") do (
    if exist "%V%\%%X\repo\godot\assets\ships\%%Y" (
      robocopy "%V%\%%X\repo\godot\assets\ships\%%Y" "%R%\godot\assets\ships\%%Y" /E /XF *.uid /NFL /NDL /NJH /NJS /NP >> "%W%\log_copy_kit.txt" 2>&1
      robocopy "%V%\%%X\repo\godot\gen\ships" "%R%\godot\gen\ships" "%%Y.*" /NFL /NDL /NJH /NJS /NP >> "%W%\log_copy_kit.txt" 2>&1
      echo kit %%Y copied from %%X >> "%L%"
    ) else (echo kit %%Y MISSING in %%X >> "%L%")
  )
)
git -C "%R%" status --porcelain --untracked-files=no > "%W%\tracked_changes.txt" 2>&1
echo import start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
set "SQUADRON_EXPECT=voidsworn|fighter=voidsworn_SF3,voidsworn|bomber=voidsworn_SB4,hegemony|fighter=hegemony_HF1D,hegemony|bomber=hegemony_HB1,corsair|bomber=corsair_KB1CC,corsair|fighter=corsair_KF1,chorus|spore=chorus_CS1BA2,ithar|fighter=ithar_GF1,ithar|bomber=ithar_GB1"
echo probe start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo OPUS1373 probe exit !ERRORLEVEL! at %TIME% >> "%L%"
exit /b 0