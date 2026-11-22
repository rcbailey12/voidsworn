@echo off
rem Issue 1587 (Opus): live hull wounds, look-bench before/after sheet plus a solo frame-time check, on main after the
rem movement merge (Artoo on PR 1631). Before is 0bd4643f (main adda5bee plus only the look bench harness: the "sync"
rem event and the rows file godot/bench/look_moments_1587.json; on branch claude/project-thread-q7nudv); after is
rem opus/issue-1587 9758eb3b (the wounds merged with that same main). Rows: wounded cruisers of all six factions (every
rem section at stage 3), the blowout as the mid section crosses into stage 3 (Sunward, Navy), a Navy ion lance on a
rem Sunward hull, a Sunward lance cut cooling over 10 s; cameras 170 and 26. Then the 1558 frame-time battles (Navy seed
rem 3, Hullbreakers seed 7, twice each) on both pins, GPU solo: damaged ships move, brake and slide there. Built from
rem tools/pc/jobs/opus_job_template.bat.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1587c"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1587"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=9758eb3b57e48b8d3191b0ff827809e22894a575"
set "PIN_OLD=0bd4643f3cc274f02febf865a20c83c6b7b7a5da"

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
rem ---- STEPS (issue 1587). The game as it ships, no option switches.
rem A: the look bench rows, 1080p, fixed 60 fps (the head sets the throwaway profile)
if not exist "%OJ_REPO%\godot\bench\look_moments_1587.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_1587.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
rem B: frame time through the battle, no pictures, twice each (the 1558 layout): Navy seed 3, Hullbreakers seed 7.
rem Done when: the new pin's frame times match the old pin's (no regression from the wounds).
for %%R in (hegemony_3 corsair_7) do (
  for /f "tokens=1-2 delims=_" %%a in ("%%R") do (
    for %%N in (1 2) do (
      if not exist "%O%\ft_%%R_%%N" mkdir "%O%\ft_%%R_%%N"
      set "JW_STEP=%1 ft %%R %%N" & set "JW_EXPECT=%O%\ft_%%R_%%N\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\ft_%%R_%%N" --torp-ft --fac %%a --obj ambush --map open --seed %%b --movement brisk --quit-after 900 > "%O%\ft_%%R_%%N\run.txt" 2>&1
    )
  )
)
exit /b 0
