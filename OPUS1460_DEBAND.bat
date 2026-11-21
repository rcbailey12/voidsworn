@echo off
rem Issue 1460 (Opus helper): debanding before and after, one pinned commit (opus/issue-1460). world_shots.tscn on the
rem two dark storm cases (nebula_storm, deep_storm), default battle camera (c170), 1920x1080, Forward+, quality max.
rem "before": an override.cfg in the checkout turns use_debanding off; the job deletes its own override.cfg after.
rem "after": the branch as committed (debanding on). Outputs: out_new\before\*.jpg and out_new\after\*.jpg.
rem Built from tools/pc/jobs/opus_job_template.bat. Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1460"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1460"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=dc1ce56a27b05a1440c01221685aa57da8ecc106"
set "PIN_OLD="

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

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS: before (debanding forced off by the job's own override.cfg), then after (as committed)
if not exist "%O%\before" mkdir "%O%\before"
if not exist "%O%\after" mkdir "%O%\after"
> "%OJ_REPO%\godot\override.cfg" echo [rendering]
>> "%OJ_REPO%\godot\override.cfg" echo anti_aliasing/quality/use_debanding=false
set "JW_STEP=%1 before" & set "JW_EXPECT=%O%\before\deep_storm_1_default.jpg" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://world/world_shots.tscn -- --out "%O%\before" --only nebula_storm,deep_storm --quality max > "%O%\before_log.txt" 2>&1
del /q "%OJ_REPO%\godot\override.cfg"
if exist "%OJ_REPO%\godot\override.cfg" (echo FAILED: override.cfg still there & exit /b 1)
set "JW_STEP=%1 after" & set "JW_EXPECT=%O%\after\deep_storm_1_default.jpg" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://world/world_shots.tscn -- --out "%O%\after" --only nebula_storm,deep_storm --quality max > "%O%\after_log.txt" 2>&1
exit /b 0
