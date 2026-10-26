@echo off
rem G4 effects gallery on Ryan's PC (queue job; runs from Downloads\voidsworn_test\build with the Godot project in build\godot).
rem Writes 4K stills and frame-time JSONs to Downloads\voidsworn_test\g4\%RUN%\ . Ends with exit /b (queue rule).
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
"%G%" --path "%P%" --fixed-fps 60 --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --shots "%OUT%\shots" --res 3840x2160 --quality max > "%OUT%\shots_log.txt" 2>&1
rem 2. tonemapper comparison: the same moments under ACES
"%G%" --path "%P%" --fixed-fps 60 --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --shots "%OUT%\shots_aces" --res 3840x2160 --quality max --tonemap aces --only g01,g03,g05b,g07,g15_,g16,g18,g21_ > "%OUT%\shots_aces_log.txt" 2>&1
rem 3. reduce flashing: the same moments with the option on
"%G%" --path "%P%" --fixed-fps 60 --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --shots "%OUT%\shots_calm" --res 3840x2160 --quality max --reduce-flashing --only g03,g09,g13_,g21_ > "%OUT%\shots_calm_log.txt" 2>&1
rem 4. frame times at 4K: everything, then without each feature (the difference is its cost)
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_max.json" --res 3840x2160 --quality max > "%OUT%\bench_4k_max_log.txt" 2>&1
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_nofx.json" --res 3840x2160 --quality max --no-fx > "%OUT%\bench_4k_nofx_log.txt" 2>&1
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_noworld.json" --res 3840x2160 --quality max --no-world > "%OUT%\bench_4k_noworld_log.txt" 2>&1
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_nophysics.json" --res 3840x2160 --quality max --no-physics > "%OUT%\bench_4k_nophysics_log.txt" 2>&1
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_4k_high.json" --res 3840x2160 --quality high > "%OUT%\bench_4k_high_log.txt" 2>&1
"%G%" --path "%P%" --disable-vsync --resolution 1920x1080 res://fx/gallery/gallery.tscn -- --bench "%OUT%\bench_1440_max.json" --res 2560x1440 --quality max > "%OUT%\bench_1440_max_log.txt" 2>&1
echo [g4] done
dir /b "%OUT%"
exit /b 0
