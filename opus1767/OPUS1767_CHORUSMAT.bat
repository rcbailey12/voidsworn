@echo off
rem Issue 1767 (R423 on PR 1772): why Chorus hulks barely darken. PROPS_G, H, I and K moved the Chorus albedo tint, yet
rem the Chorus wrecks at camera 170 changed 2 to 3 percent. chorus_material_probe.gd (beside this bat) is copied into
rem godot\bench of the pinned checkout as an untracked file and run once in a window (texture readback needs the GPU).
rem It prints one CHORUS_MAT line per hull surface (B20_11, B21_11, C14s_23, H8_23 for comparison): material class,
rem flags, texture, the measured mean, the derelict tint and effective luminance. Text only, no pictures; a few seconds of
rem GPU. Built from OPUS1767_LOAD.bat.
setlocal EnableExtensions
set "JOB=opus1767chorusmat"
set "LABEL=1767"
set "TOOLS=godot"
set "PIN_NEW=115411a57374d4959177dc9b126a508897a2aa6b"
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"
set "PROBE=%~dp0chorus_material_probe.gd"
if not exist "%PROBE%" (echo FAILED: chorus_material_probe.gd must sit beside this bat & exit /b 2)

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

call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "O=%OJ_OUT%\out_new"
if not exist "%O%" mkdir "%O%"
copy /y "%PROBE%" "%OJ_REPO%\godot\bench\chorus_material_probe.gd" > nul || (call "%JW%" fail "probe copy" & exit /b 1)
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=chorus material probe" & set "JW_EXPECT=%O%\chorus_mat.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1280x720 --script res://bench/chorus_material_probe.gd > "%O%\chorus_mat.txt" 2>&1
findstr /c:"CHORUS_MAT_DONE" "%O%\chorus_mat.txt" > nul || call "%JW%" fail "the probe printed no CHORUS_MAT_DONE"
call "%HEAD%" tail
exit /b %ERRORLEVEL%
