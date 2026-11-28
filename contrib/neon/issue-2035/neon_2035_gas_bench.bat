@echo off
rem Issue 2035 (AAA item 9): before/after PC look bench and 12.5 ms gate for nebula and ion storm hexes.
rem Queue on Ryan's PC only after CI checks are green and review passes at PIN_NEW (RULEBOOK 3.12, R407).
rem Produces four Ryan-ready <= 720 px comparison sheets (N2035_NEB_C170, N2035_NEB_C26,
rem N2035_STORM_C170, N2035_STORM_C26) plus solo 1080p/4K frame-time gate JSONs.
setlocal EnableExtensions
set "JOB=neon2035"
set "LABEL=2035"
set "TOOLS=godot pil"
set "PIN_NEW=942b451be5ff67ca2a31d59ffe2ed223c07fc5cb"
set "PIN_OLD=ee398fcf4f12b4f2408d6b0dee87a404dce9ef12"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

set "GOFILE=%VT%\gpu_go.txt"
set "T2035=%OJ_OUT%\tools_2035"
if not exist "%T2035%" mkdir "%T2035%"

call :run_arm new %PIN_NEW%
call :run_arm old %PIN_OLD%
call :compose_sheets
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:run_arm
set "ARM=%~1"
set "PIN=%~2"
call "%HEAD%" checkout %ARM% %PIN%
if errorlevel 1 exit /b 1
call "%HEAD%" ships
if errorlevel 1 exit /b 1
set "O=%OJ_OUT%\out_%ARM%"
if not exist "%O%" mkdir "%O%"
if not exist "%O%\timing_nebula" mkdir "%O%\timing_nebula"
if not exist "%O%\timing_storm" mkdir "%O%\timing_storm"
if /i "%ARM%"=="new" (
  copy /y "%OJ_REPO%\godot\world\gas_2035_capture.gd" "%T2035%\" > nul
  copy /y "%OJ_REPO%\godot\world\gas_2035_capture.tscn" "%T2035%\" > nul
  copy /y "%OJ_REPO%\godot\world\nebula_bench_2035.tscn" "%T2035%\" > nul
  copy /y "%OJ_REPO%\contrib\neon\issue-2035\make_sheets_2035.py" "%T2035%\" > nul
) else (
  copy /y "%T2035%\gas_2035_capture.gd" "%OJ_REPO%\godot\world\" > nul
  copy /y "%T2035%\gas_2035_capture.tscn" "%OJ_REPO%\godot\world\" > nul
  copy /y "%T2035%\nebula_bench_2035.tscn" "%OJ_REPO%\godot\world\" > nul
)
set "JW_STEP=%ARM% import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if /i "%ARM%"=="new" (
  set "JW_STEP=new gas_depth_light_check" & set "JW_EXPECT=%O%\gas_depth_light_check.txt" & call "%JW%" run 300 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://world/test/gas_depth_light_check.gd > "%O%\gas_depth_light_check.txt" 2>&1
)

rem ---- shared GPU captures: nebula and storm hexes with ships inside at cameras 170 and 26
set "PC_GPU_MODE=shared"
set "PC_GPU_WEIGHT=1"
set "JW_STEP=%ARM% capture nebula" & set "JW_EXPECT=%O%\gas2035_nebula_c170_calm.png;%O%\gas2035_nebula_c170_flash.png;%O%\gas2035_nebula_c26_calm.png;%O%\gas2035_nebula_c26_flash.png" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync res://world/gas_2035_capture.tscn -- --captures --map-case nebula --terrain-tier max --go-file "%GOFILE%" --out "%O%" > "%O%\capture_nebula.txt" 2>&1
set "JW_STEP=%ARM% capture storm" & set "JW_EXPECT=%O%\gas2035_storm_c170_calm.png;%O%\gas2035_storm_c170_flash.png;%O%\gas2035_storm_c26_calm.png;%O%\gas2035_storm_c26_flash.png" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync res://world/gas_2035_capture.tscn -- --captures --map-case storm --terrain-tier max --go-file "%GOFILE%" --out "%O%" > "%O%\capture_storm.txt" 2>&1

rem ---- solo GPU timing (RULEBOOK 3.4, 3.9, 12.5): warmup pass then retained 3-session gate at 1080p and 4K
set "PC_GPU_MODE=solo"
set "PC_GPU_WEIGHT="
if not exist "%O%\warm_nebula" mkdir "%O%\warm_nebula"
if not exist "%O%\warm_storm" mkdir "%O%\warm_storm"
set "JW_STEP=%ARM% warm nebula" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --disable-vsync res://world/nebula_bench_2035.tscn -- --map-case nebula --terrain-tier max --sessions 1 --warmup 60 --frames 120 --modes base,res_2160 --go-file "%GOFILE%" --out "%O%\warm_nebula" > "%O%\warm_nebula.txt" 2>&1
set "JW_STEP=%ARM% timing nebula" & set "JW_EXPECT=%O%\timing_nebula\scene_gate.json" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --disable-vsync res://world/nebula_bench_2035.tscn -- --map-case nebula --terrain-tier max --sessions 3 --warmup 120 --frames 720 --modes base,res_2160 --go-file "%GOFILE%" --out "%O%\timing_nebula" > "%O%\timing_nebula.txt" 2>&1
set "JW_STEP=%ARM% warm storm" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --disable-vsync res://world/nebula_bench_2035.tscn -- --map-case storm --terrain-tier max --sessions 1 --warmup 60 --frames 120 --modes base,res_2160 --go-file "%GOFILE%" --out "%O%\warm_storm" > "%O%\warm_storm.txt" 2>&1
set "JW_STEP=%ARM% timing storm" & set "JW_EXPECT=%O%\timing_storm\scene_gate.json" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --disable-vsync res://world/nebula_bench_2035.tscn -- --map-case storm --terrain-tier max --sessions 3 --warmup 120 --frames 720 --modes base,res_2160 --go-file "%GOFILE%" --out "%O%\timing_storm" > "%O%\timing_storm.txt" 2>&1
set "PC_GPU_MODE="
exit /b 0

:compose_sheets
rem Restore clean PIN_NEW checkout so picture_provenance stamps the exact branch commit.
call "%HEAD%" checkout new %PIN_NEW%
if errorlevel 1 exit /b 1
set "SH=%OJ_OUT%\out_sheets"
if not exist "%SH%" mkdir "%SH%"
set "JW_STEP=compose comparison sheets" & set "JW_EXPECT=%SH%\N2035_NEB_C170.jpg;%SH%\N2035_NEB_C26.jpg;%SH%\N2035_STORM_C170.jpg;%SH%\N2035_STORM_C26.jpg;%SH%\summary_2035.json" & call "%JW%" run 300 "%JW_PIL%" "%T2035%\make_sheets_2035.py" --before "%OJ_OUT%\out_old" --after "%OJ_OUT%\out_new" --out "%SH%" --before-sha "%PIN_OLD%" --after-sha "%PIN_NEW%" --repo "%OJ_REPO%" > "%SH%\sheets_log.txt" 2>&1
exit /b 0
