@echo off
rem Issues 1692 and 1693 recheck (WAVE2AB2) after the fix runs: PR 1758 at 90953201 (shock ring removed, tendril
rem untouched per R437) and PR 1784 at 97387d35 (ion arc only on a live shield, bigger acid mist, sizzle capped at two).
rem Before is e7a501b6 (main bc820fde, the newest main both PR heads contain, plus only the bench files: look_bench.gd
rem handing its sound player to the effects under --sound, look_moments_2ab.json, look_moments_2ab2.json,
rem look_moments_2ab_clip.json). After is fa94324f (that commit merged with both PR heads, nothing else). Both reachable
rem from branch claude/project-thread-lnk6bv.
rem Rows (look_moments_2ab2.json, cameras 170 and 26): battery and heavy battery muzzles, las turret and plasma cannon in
rem flight and landing (the las window now reaches its shot), plasma cannon hit, ion-locked shield empty and half full,
rem a shield hit at 20 vs 50 percent pool, idle acid on a Sunward and an Eclipse cruiser.
rem Clip (new pin only, camera 170): about 8 s of idle acid with the game's sound, WAVE2AB2_acid_sizzle.avi and .mp4.
rem GPU: ordinary job, no frame-time measurement. Built from tools/pc/jobs/opus_job_template.bat (the OPUS1692_WAVE2AB layout).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1692ab2"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1692"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot ffmpeg"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=fa94324f829dbca10dae757c283dd7932bb91fd3"
set "PIN_OLD=e7a501b677855a019222c64ddf4bc5ad15838514"
rem Issue 1659: warm slots on, gpu kind (this job renders).
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

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
rem ---- STEPS (issues 1692 and 1693, recheck). The game as it ships, no option switches (VS_WOUNDS_V2 not set).
rem A: the look bench rows, 1080p, fixed 60 fps (the head sets the throwaway profile)
if not exist "%OJ_REPO%\godot\bench\look_moments_2ab2.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_2ab2.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
rem B (new pin only): the acid sizzle clip with picture and sound, then as mp4 1280 wide
if not "%1"=="new" exit /b 0
if not exist "%O%\clip" mkdir "%O%\clip"
set "JW_STEP=%1 clip" & set "JW_EXPECT=%O%\WAVE2AB2_acid_sizzle.avi" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%O%\WAVE2AB2_acid_sizzle.avi" res://bench/look_bench.tscn -- --out "%O%\clip" --part moments --no-warm --sound --moments res://bench/look_moments_2ab_clip.json > "%O%\clip_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\clip_log.txt" > nul || call "%JW%" fail "%1 clip did not finish (see %O%\clip_log.txt)"
if defined JW_FFMPEG if exist "%O%\WAVE2AB2_acid_sizzle.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\WAVE2AB2_acid_sizzle.avi" -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -c:a aac -b:a 128k "%O%\WAVE2AB2_acid_sizzle.mp4" > nul 2>&1
exit /b 0
