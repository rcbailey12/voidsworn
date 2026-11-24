@echo off
rem Issue 1434 LOAD30d with issues 1518 and 1519 (Board, Nov 21: one pin for all three; graded on a WARM profile, the cold
rem first launch reported alongside on the same items, with one condition on the cold pass: the loading cover stays up
rem LOAD29: warm title frame 1046 ms (a 1043 ms main-thread step in the backdrop's start, unnamed); cold s25 7.6 s frame (7 board hull-debris chunks installed after the stage-in drain stopped watching, 83 pipelines); the warm load closes were seen late because the game had drawn no frame 7.7 s after launch (the main script compiled the battle, HUD and campaign host first); a battle left mid-warm-up logged get_tree errors. LOAD30: the launch reads the battle scene and campaign host on workers (main script 2.8 s to 0.2 s in the cloud) and prints when Main is ready; the load waits for the hull-debris chunks and stages them; the left battle's warm-up stops out of the tree; the title line names the backdrop's made time and start parts. Alt-F4 posts WM_SYSCOMMAND SC_CLOSE (harness, 96943e18). Merged with current main (PR 1782 asteroids). Its own Godot profiles are deleted at the end (issue 1830). Lean: no export and no player path. LOAD30b added: the title waits a frame at a time for the launch's campaign host read (Artoo on cc4a63ce). LOAD30d fixes (Fable on 98926849): the runner's step 4 no longer overwrites the result file path, so the title launch lines, the grades and the RESULT reach load10_result.txt; the host is read first and held, the title's Quick battle waits for the battle scene, the 1519 first title frame counts only a draw with the title in the tree. LOAD30c added (Artoo on 6784b6b1): launch to the first painted title menu on its own line in the bench and in a new step 2d, two cold launches to the title (no save, and a valid saved run written by bench/write_save_1434.gd inside its own profile), each failing plainly with no menu in 20 s. Replaces OPUS1434_LOAD30c.bat, OPUS1434_LOAD30b.bat and OPUS1434_LOAD30.bat (queued, not run), OPUS1434_LOAD29.bat (ran Nov 23) and every earlier LOAD bat.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; steps 1 to 3 as LOAD23.
rem Steps on one pinned commit (opus/issue-1434 head ffc4ead9, PR 1445):
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
rem      d. two cold launches to the title on fresh profiles, without a save and with a valid saved run: the menu painted
rem         within 20 s with the expected first button ("New run", "Continue run"), on their own lines.
rem      Result: out_new\load10\load10_result.txt, gate line "[load10] RESULT PASS".
rem   3. the Godot test profiles under out_new\load10 (profile_warm and close_*\*\profile) are deleted: rebuildable leftovers
rem      of this job (RULEBOOK 3.3), kept results and logs untouched.
rem   No export and no player path this run (Board, Nov 22: disk tight).
rem Nothing outside the attempt folder is written or deleted. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434ah"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=ffc4ead9dd5f330ad2b4906857489de85660472f"
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
