@echo off
rem G2 battle screenshots for the screenshot-verdict skill: the Godot battle scene at fixed moments
rem (opening board, move preview, attack tip, threat map top-down, mid-battle fire, end card) on three battles.
rem Queue job: runs from Downloads\voidsworn_test\build (the repo synced there, the Godot project in build\godot).
rem Output: Downloads\voidsworn_test\shots\g2\<battle>\*.png and a log per battle.
setlocal
set "ROOT=%~dp0"
if exist "%CD%\godot\project.godot" set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "OUT=%ROOT%..\shots\g2"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%ROOT%godot\gen\manifest.json" (
  echo Building the Godot assets first...
  "%G%" --headless --path "%ROOT%godot" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%ROOT%..\enginetest\assets\hi" --env "%ROOT%..\enginetest\assets\env" > "%OUT%\build_assets_log.txt" 2>&1
)
for %%B in (s1 s2 s3) do (
  echo battle %%B
  "%G%" --path "%ROOT%godot" --rendering-method forward_plus --resolution 2560x1440 -- --scenario %%B --shots "%OUT%\%%B" --quit-after 900 > "%OUT%\%%B_log.txt" 2>&1
)
echo sector 1 random
"%G%" --path "%ROOT%godot" --rendering-method forward_plus --resolution 2560x1440 -- --seed 4242 --shots "%OUT%\sector1" --quit-after 900 > "%OUT%\sector1_log.txt" 2>&1
echo done
exit /b 0
