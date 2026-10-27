@echo off
rem G4 effects gallery on Ryan's PC (queue job; runs from Downloads\voidsworn_test\build with the Godot project in build\godot).
rem Every Godot launch goes through the PC watchdog (tools\pc\tmo.bat: kills a hung run, exit 124).
rem Writes 4K stills, breach and weapon-mark close-ups, hit-reaction strips and frame-time JSONs to
rem Downloads\voidsworn_test\g4\%RUN%\ . Ends with exit /b (queue rule).
setlocal
set "RUN=%~1"
if "%RUN%"=="" set "RUN=run"
set /p G=<..\godot_path.txt
set "P=%CD%\godot"
set "OUT=%CD%\..\g4\%RUN%"
if not exist "%OUT%" mkdir "%OUT%"
echo [g4] godot=%G% project=%P% out=%OUT%
rem other streams' jobs re-extract parts of build\godot (render\ among them), so put G4's files back first
if exist "%CD%\..\g4\src\godot" xcopy /e /y /i /q "%CD%\..\g4\src\godot" "%P%" >nul
rem 1. the stills at 4K, max detail, AgX (the look.gd default)
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --fixed-fps 60 --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --shots "%OUT%\shots" --res 3840x2160 --quality max > "%OUT%\shots_log.txt" 2>&1
rem 1b. breach close-ups on two 8K flagships at stage 4 (prints the hull rebuild time for the big meshes)
set "PROBE_W=1920"
set "PROBE_H=1080"
set "PROBE_STAGE=4"
set "PROBE_FAC=corsair"
set "PROBE_CLS=Battle-barge"
set "PROBE_OUT=%OUT%\breach_corsair"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 600 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_breach_probe.gd > "%OUT%\breach_corsair_log.txt" 2>&1
set "PROBE_FAC=hegemony"
set "PROBE_CLS=Super-dreadnought"
set "PROBE_OUT=%OUT%\breach_hegemony"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 600 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_breach_probe.gd > "%OUT%\breach_hegemony_log.txt" 2>&1
rem 1c. every weapon's own mark (R43), one at a time, fresh and cooled, with its cost: the 8K barge and a Voidsworn dreadnought
set "PROBE_FAC=corsair"
set "PROBE_CLS=Battle-barge"
set "PROBE_OUT=%OUT%\marks_corsair"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_marks_probe.gd > "%OUT%\marks_corsair_log.txt" 2>&1
set "PROBE_FAC=voidsworn"
set "PROBE_CLS=Dreadnought"
set "PROBE_OUT=%OUT%\marks_voidsworn"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_marks_probe.gd > "%OUT%\marks_voidsworn_log.txt" 2>&1
rem ... and a small ship (a Voidsworn frigate at its battle size), where the marks are hardest to read from the battle camera
set "PROBE_CLS=Frigate"
set "PROBE_SIZE=0.55"
set "PROBE_OUT=%OUT%\marks_frigate"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_marks_probe.gd > "%OUT%\marks_frigate_log.txt" 2>&1
set "PROBE_SIZE="
rem 1d. hit reactions (R50) per weapon weight on a frigate and a super-dreadnought: numbers, a per-frame trace, a strip of
rem stills per hit, and 30 fps JPEG clips of the heavy hits (made into a video in the sandbox)
set "PROBE_OUT=%OUT%\react"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
set "PROBE_W=1280"
set "PROBE_H=720"
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_react_probe.gd > "%OUT%\react_log.txt" 2>&1
set "PROBE_OUT=%OUT%\react_clips"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
set "PROBE_CLIP=1"
set "PROBE_STILLS=0"
set "PROBE_ONLY=macro,gauss,torp,ram"
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --resolution 1920x1080 --script res://fx/test/fx_react_probe.gd > "%OUT%\react_clips_log.txt" 2>&1
set "PROBE_CLIP="
set "PROBE_STILLS="
set "PROBE_ONLY="
set "PROBE_W=1920"
set "PROBE_H=1080"
rem pack each clip's frames into one zip (fewer files to fetch)
for /d %%D in ("%OUT%\react_clips\clip_*") do powershell -NoProfile -Command "Compress-Archive -Path '%%D\*' -DestinationPath '%%D.zip' -Force"
rem 1f. the worker cost of the hull rebuild on the 8K hulls (headless): each mark alone, then every section at stage 4
set "PROBE_FAC=corsair"
set "PROBE_CLS=Battle-barge"
call tools\pc\tmo.bat 600 "%G%" --headless --path "%P%" --script res://fx/test/fx_cost_probe.gd > "%OUT%\cost_corsair_log.txt" 2>&1
set "PROBE_FAC=hegemony"
set "PROBE_CLS=Super-dreadnought"
call tools\pc\tmo.bat 600 "%G%" --headless --path "%P%" --script res://fx/test/fx_cost_probe.gd > "%OUT%\cost_hegemony_log.txt" 2>&1
rem 1e. the fx smoke test (flash cap, reduce flashing, errors); script errors do not reach its own count, so grep them
call tools\pc\tmo.bat 300 "%G%" --headless --path "%P%" --script res://fx/test/fx_smoke.gd > "%OUT%\smoke_log.txt" 2>&1
findstr /c:"SCRIPT ERROR" "%OUT%\smoke_log.txt" >nul && echo [g4] SMOKE HAS SCRIPT ERRORS
rem 3. reduce flashing: the same moments with the option on
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --fixed-fps 60 --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --shots "%OUT%\shots_calm" --res 3840x2160 --quality max --reduce-flashing --only g03,g09,g13_,g21_ > "%OUT%\shots_calm_log.txt" 2>&1
rem 4. frame times at 4K: everything, without effects, and high quality (the ACES, no-world, no-physics and 1440p
rem runs are in r4)
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_max.json" --res 3840x2160 --quality max > "%OUT%\bench_4k_max_log.txt" 2>&1
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_nofx.json" --res 3840x2160 --quality max --no-fx > "%OUT%\bench_4k_nofx_log.txt" 2>&1
call tools\pc\tmo.bat 900 "%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_high.json" --res 3840x2160 --quality high > "%OUT%\bench_4k_high_log.txt" 2>&1
echo [g4] done
dir /b "%OUT%"
exit /b 0
