@echo off
rem Issue 1262, RUN1262E: the final three-change PR head against the main it is built on, timing and pictures, both
rem arms on one fleet. Built from tools/pc/jobs/opus_job_template.bat (issue 1303). Artoo on PR 1297: RUN1262D's shots
rem were taken with the dropped rock-shadow limit still on; this captures the code that would merge.
rem NEW = PR 1297 head 0172d99f (SSIL off on Max, zero underlay hidden, bounded Max storm cards; rock limit dropped).
rem OLD = main 56881a5e, the main merged into that head. Sessions alternate NEW and OLD, three each, then 1070's shots.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1262e"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1262"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=0172d99fc20d91b7c632a31e759bb63f4ac0967a"
set "PIN_OLD=56881a5ecc88b29fff01964320fc569520abae5e"
rem The hulls the gate and dense fixtures draw (RUN1262C's placeholder list): each must be a copied ship matching its cache.
set "OJ_NEED_HULLS=B19_11 B20_11 C13s_23 C19_51 D20_23 D21_23 H7_23 H8_23 I11_37 I14_23 V14_23 V15_37 V16_37 V17_37 V18_51 V1b_r_23"

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
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

set "PC_GPU_MODE=solo"
set "VS_SHIELD_SHAPE=fitted"
set "VS_1262_OLD="
set "CASES=gate:max:2:base,dense:max:2:native_lod,gate:max:1:base,dense:max:1:native_lod"
set "CASES_R=dense:max:1:native_lod,gate:max:1:base,dense:max:2:native_lod,gate:max:2:base"

call :prep new %PIN_NEW%
set "R_NEW=%OJ_REPO%"
call :prep old %PIN_OLD%
set "R_OLD=%OJ_REPO%"
rem Three sessions, the arms alternating and the case order reversed every other session (as run1262.ps1 did).
call :time new 1 "%CASES%"
call :time old 1 "%CASES%"
call :time old 2 "%CASES_R%"
call :time new 2 "%CASES_R%"
call :time new 3 "%CASES%"
call :time old 3 "%CASES%"
call :shots new
call :shots old
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships (stamp check, same fleet as the first, needed hulls), import, the 1070 probe.
:prep
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
if defined JW_STOP exit /b 1
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
copy /y "%OJ_REPO%\contrib\codex\perf_1118\boot.gd" "%OJ_REPO%\godot\bench\boot.gd" > nul
copy /y "%OJ_REPO%\contrib\codex\perf_1118\perf_1118.gd" "%OJ_REPO%\godot\bench\perf_1118.gd" > nul
if not exist "%OJ_REPO%\godot\bench\perf_1118.gd" (call "%JW%" fail "%1 probe copy" & exit /b 1)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
exit /b 0

rem ---- one timing session: the four cases at Max, 1080p and 4K, GPU solo, in a throwaway profile.
:time
if defined JW_STOP exit /b 1
if /i "%1"=="new" (set "R=%R_NEW%") else (set "R=%R_OLD%")
set "F=%OJ_OUT%\out_%1\t\s%2"
mkdir "%F%"
set "JW_STEP=%1 timing s%2" & set "JW_EXPECT=%F%\samples.jsonl" & call "%JW%" run 1800 "%JW_GODOT%" --path "%R%\godot" --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --log-file "%F%\engine.log" --script res://bench/boot.gd -- --out "%F%" --cases "%~3" --session %2 --suite switches > "%F%\run.txt" 2>&1
exit /b 0

rem ---- 1070's fixed shots (c170 and c26) for one arm.
:shots
if defined JW_STOP exit /b 1
if /i "%1"=="new" (set "R=%R_NEW%") else (set "R=%R_OLD%")
set "F=%OJ_OUT%\out_%1\shots"
mkdir "%F%"
set "JW_STEP=%1 shots" & set "JW_EXPECT=%F%\samples.jsonl" & call "%JW%" run 1800 "%JW_GODOT%" --path "%R%\godot" --rendering-method forward_plus --rendering-driver vulkan --windowed --resolution 1920x1080 --log-file "%F%\engine.log" --script res://bench/boot.gd -- --out "%F%" --cases "%CASES%" --suite shots > "%F%\run.txt" 2>&1
exit /b 0
