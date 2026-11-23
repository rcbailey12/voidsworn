@echo off
rem Issue 1434 LOAD29 with issues 1518 and 1519 (Board, Nov 21: one pin for all three; graded on a WARM profile, the cold
rem first launch reported alongside on the same items, with one condition on the cold pass: the loading cover stays up
rem LOAD25: warm title frame 650 ms (every gas patch built in one world_build frame, 463 ms before the draw); a close in the battle's first frame waited on 1.3 to 2.3 s of sky and sound loads; the 1519 frame was 200.7 ms; the title cases' leave came after the close on a slow start; warm altf4_load_5s never saw its Alt-F4 (the game was not in front, harness). LOAD29: gas patches one a frame; the sky, the sound clips and the effects script load on workers from game start, and nothing waits on those reads inside a frame (a battle waits for its sky a frame at a time, late clips join later, every way into a battle waits a frame at a time for the effects script) (Artoo); a close before a campaign battle begins settles nothing (Artoo); title music after the first title frame; a battle left mid-build stops its board and world build; --title-after counts from the game's start. Merged with current main. Its own Godot profiles are deleted at the end (issue 1830). Lean: no export and no player path. Replaces OPUS1434_LOAD28.bat, OPUS1434_LOAD27.bat and OPUS1434_LOAD26.bat (not run: held for Artoo), OPUS1434_LOAD25.bat (ran Nov 23) and every earlier LOAD bat.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; steps 1 to 3 as LOAD23.
rem Steps on one pinned commit (opus/issue-1434 head c331e1a2, PR 1445):
rem   1. checkout, ships, import.
rem   2. contrib\opus\pc\1434\load1434_runs.ps1 from the pinned checkout, GPU solo:
rem      a. the load bench (godot/bench/load_1434.gd, fullscreen) on a fresh profile inside the attempt folder: cold,
rem         reported, plus its COVER line (cover up on every frame to play, no frame of 5 s or more);
rem      b. the same bench again on that same profile: warm, graded (slice, ready, cover frame, title click, title
rem         frame, bus, leave);
rem      c. the six CLOSE5 close cases (issue 1435 method), each on its own fresh profile (cold), then each on the
rem         warm profile, both graded on their own lines: window hidden within 500 ms of the close during a load (1518: altf4_load_5s,
rem         title_load_5s, title_battle_30s), first title frame within 200 ms of leaving the battle (1519: both title
rem         cases), one window-route quit, exit 0, no crash; an Alt-F4 case that could not send its keys is UNVERIFIED.
rem      Result: out_new\load10\load10_result.txt, gate line "[load10] RESULT PASS".
rem   3. the Godot test profiles under out_new\load10 (profile_warm and close_*\*\profile) are deleted: rebuildable leftovers
rem      of this job (RULEBOOK 3.3), kept results and logs untouched.
rem   No export and no player path this run (Board, Nov 22: disk tight).
rem Nothing outside the attempt folder is written or deleted. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434ad"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=c331e1a2bba780bbbcb8b39e54b957c8b85f7d22"
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

call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0

rem ---- 2. load bench cold and warm, then the close cases cold and warm (GPU solo: frame-time measurement)
set "H=%O%\load10"
if not exist "%H%" mkdir "%H%"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 load10" & set "JW_EXPECT=%H%\load10_result.txt" & call "%JW%" run 5400 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%OJ_REPO%\contrib\opus\pc\1434\load1434_runs.ps1" -Godot "%JW_GODOT%" -Project "%OJ_REPO%\godot" -Out "%H%" > "%H%\console.txt" 2>&1
set "PC_GPU_MODE="
if not exist "%H%\load10_result.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: no load10_result.txt, see load10\console.txt" & goto exp)
findstr /c:"[load10] RESULT PASS" "%H%\load10_result.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 load10: a graded item failed, see load10\load10_result.txt")

:exp
rem ---- 3. this job's own Godot profiles go (issue 1830: their long names broke the relay)
if exist "%H%\profile_warm" rmdir /s /q "%H%\profile_warm"
for /d %%S in ("%H%\close_*") do for /d %%C in ("%%S\*") do if exist "%%C\profile" rmdir /s /q "%%C\profile"
exit /b 0
