@echo off
rem Issue 1777 (Ship Exteriors V2, Law 6 wave A) sign-off stills: the newest ship of each faction (V16_37, H10_23, C15s_23,
rem B21_11, I15_11, D21_23) after three hits, plus the issue proof hulls intact (S9 V14_23, S10 V16_37, H10, A16 C19_51,
rem C11 B21_11, C14 B22_11, I8_37, I15_11, E12 D21_23), held, at cameras 170 and 26 (bench/look_moments_ship_look_v2.json),
rem before (VS_SHIP_LOOK_V2=0) and after (VS_SHIP_LOOK_V2=1) on ONE pinned commit (opus/issue-1777 b0768e6b), PC-built
rem hulls. Stills only. Frame time is the separate solo bat OPUS1777_FRAMETIME.bat. Queue only after green checks and the
rem Board audit (R407). Built from opus_job_template.bat; once queued it is never edited (a change ships under a new name).
setlocal EnableExtensions
set "JOB=opus1777look"
set "LABEL=1777"
set "TOOLS=godot"
set "PIN_NEW=b0768e6b6e498121e0c3f630f84704636355d00f"
set "PIN_OLD="

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
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\bench\look_moments_ship_look_v2.json" (call "%JW%" fail "rows file missing" & exit /b 1)
if not exist "%OJ_REPO%\godot\assets\ships\detail\voidsworn_n.png" (call "%JW%" fail "detail maps missing" & exit /b 1)
call :run before 0
call :run after 1
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one switch setting: the bench rows at cameras 170 and 26. Every Godot start goes through job_wrap.
:run
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "VS_SHIP_LOOK_V2=%2"
set "PICTURE_SOURCE_REPO=%OJ_REPO%"
set "JW_STEP=%1 ship look v2 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --commit %PIN_NEW% --part moments --moments res://bench/look_moments_ship_look_v2.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
findstr /c:"LOOK_BENCH CODE MISMATCH" "%O%\bench_log.txt" > nul && call "%JW%" fail "%1 a row drew a different hull than it pins (see %O%\bench_log.txt)"
set "VS_SHIP_LOOK_V2="
exit /b 0
