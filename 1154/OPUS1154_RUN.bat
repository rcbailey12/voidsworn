@echo off
rem Issue 1154: the binding scene gate (RULEBOOK 3.9) with C13 (B20_11) installed, solo on the RTX 5080.
rem Uses this job's own clone opus1154\repo as the paint PREVIEW run left it (branch opus/issue-1154 with codex/issue-1058
rem merged, B20_11 installed and imported). Two launches, the second kept (warm once). Writes only under opus1154\out\.
rem Deletes nothing. Every step logs to opus1154\out\result.txt; the last line is "all done".
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1154\repo
set O=%V%\opus1154\out
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start scene gate %DATE% %TIME% > "%RES%"
if not exist "%C%\godot\assets\ships\B20_11\B20_11.glb" (echo FAILED: no installed B20_11 in the clone; run the paint run first >> "%RES%" & goto end)
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set PC_GPU_MODE=solo
set PC_GPU_ISSUE=1154
set PC_GPU_WAIT_SECONDS=7200
for %%N in (1 2) do (
  call "%C%\tools\pc\tmo.bat" 2400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\scene_gate_%%N" --modes base,res_1440,res_2160 > "%O%\log_scene_gate_%%N.txt" 2>&1
  echo scene gate %%N exit !ERRORLEVEL! >> "%RES%"
)
findstr /l /c:"[scene_gate] DONE" "%O%\log_scene_gate_2.txt" >> "%RES%" 2>&1
findstr /i /c:"B20_11" "%O%\log_scene_gate_2.txt" >> "%RES%" 2>&1
:end
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
