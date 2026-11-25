@echo off
rem Issue 1360 (PR 1986, storm lightning as baked Blender bolts; Board, Nov 24 13:51 UTC): before and after clips and stills, code STB,
rem on ONE commit (work/issue-1360-opus 89b0e342 (Board combine with main, scene_gate 180 s wait): 5087a901 plus the three storm bolt .import files). Six passes of bench/scene_gate.tscn --still (the storm map, the fixed effect
rem clock, a volley every 21 steps, 470 steps), each recorded with --write-movie at 1920x1080, fixed-fps 60:
rem   before_c170 / before_c60       VS_STORM_BOLTS=ribbon (the old ribbon)
rem   after_c170 / after_c60         VS_STORM_BOLTS unset (the baked bolts, the PR's default)
rem   afterrf_c170 / afterrf_c60     baked, with the game's Reduced Flashing on (battle.set_fx_opts, as main.gd applies the setting)
rem The camera is held on the map's first ion storm patch at radius 170 (the battle camera) or 60 by stb_wrap.gd (beside this
rem bat; copied into the job's own checkout as bench\_stb_wrap.gd, never committed). Ambient strikes come every 0.3 to 3.5 s.
rem Each clip (stb_stills.py, ffmpeg): an mp4 of its last 12 s (1280 wide, crf 26) and the 3 brightest strike frames (ffmpeg
rem signalstats), each with an STB footer; then one STB_sheet.jpg of every pass. Shared GPU slot (no frame-time gate).
rem Nothing on the PC is deleted. Built from tools/pc/jobs/opus_job_template.bat. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1360storm2"
set "LABEL=1360"
set "TOOLS=godot ffmpeg pil"
set "PIN_NEW=89b0e3428999483a130989fe2fe39f05be00a9ae"
set "PIN_OLD="
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "STB_HERE=%~dp0"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
if not exist "%STB_HERE%stb_wrap.gd" (echo FAILED: stb_wrap.gd missing beside the bat & exit /b 2)
if not exist "%STB_HERE%stb_stills.py" (echo FAILED: stb_stills.py missing beside the bat & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "O=%OJ_OUT%\out_new"
if not exist "%O%" mkdir "%O%"
copy /y "%STB_HERE%stb_wrap.gd" "%OJ_REPO%\godot\bench\_stb_wrap.gd" > nul
copy /y "%STB_HERE%stb_wrap.gd" "%O%\stb_wrap.gd" > nul
copy /y "%STB_HERE%stb_stills.py" "%O%\stb_stills.py" > nul
set "JW_STEP=new import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\fx\atlases\storm" (call "%JW%" fail "no fx\atlases\storm in the checkout (baked bolts missing)" & exit /b 1)
call :pass before_c170 ribbon 170 0
call :pass before_c60 ribbon 60 0
call :pass after_c170 baked 170 0
call :pass after_c60 baked 60 0
call :pass afterrf_c170 baked 170 1
call :pass afterrf_c60 baked 60 1
set "JW_STEP=STB sheet" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\STB_sheet.jpg" & call "%JW%" run 300 "%JW_PIL%" "%O%\stb_stills.py" sheet "%O%" before_c170,after_c170,afterrf_c170,before_c60,after_c60,afterrf_c60 > "%O%\sheet_log.txt" 2>&1
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pass: <name> <ribbon|baked> <camera radius> <reduced flashing 0|1>
:pass
set "P=%O%\%1"
if not exist "%P%" mkdir "%P%"
set "VS_STORM_BOLTS="
if "%2"=="ribbon" set "VS_STORM_BOLTS=ribbon"
set "STB_R=%3"
set "STB_RF=%4"
set "JW_STEP=%1 clip" & set "JW_CONTINUE=1" & set "JW_EXPECT=%P%\STB_%1.avi;%P%\still_470_wide.png" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%P%\STB_%1.avi" --script res://bench/_stb_wrap.gd -- --out "%P%" --still > "%P%\log.txt" 2>&1
set "VS_STORM_BOLTS=" & set "STB_R=" & set "STB_RF="
set "JW_STEP=%1 stills" & set "JW_CONTINUE=1" & set "JW_EXPECT=%P%\STB_%1_1.jpg" & call "%JW%" run 600 "%JW_PIL%" "%O%\stb_stills.py" stills "%JW_FFMPEG%" "%P%\STB_%1.avi" "%P%" %1 > "%P%\stills_log.txt" 2>&1
exit /b 0
