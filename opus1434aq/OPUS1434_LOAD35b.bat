@echo off
rem Issue 1434 LOAD35b with issues 1518 and 1519 (Board, Nov 21: one pin for all three; graded on a WARM profile, the cold
rem first launch reported alongside on the same items, with one condition on the cold pass: the loading cover stays up
rem LOAD29: warm title frame 1046 ms (a 1043 ms main-thread step in the backdrop's start, unnamed); cold s25 7.6 s frame (7 board hull-debris chunks installed after the stage-in drain stopped watching, 83 pipelines); the warm load closes were seen late because the game had drawn no frame 7.7 s after launch (the main script compiled the battle, HUD and campaign host first); a battle left mid-warm-up logged get_tree errors. LOAD30: the launch reads the battle scene and campaign host on workers (main script 2.8 s to 0.2 s in the cloud) and prints when Main is ready; the load waits for the hull-debris chunks and stages them; the left battle's warm-up stops out of the tree; the title line names the backdrop's made time and start parts. Alt-F4 posts WM_SYSCOMMAND SC_CLOSE (harness, 96943e18). Merged with current main (PR 1782 asteroids). Its own Godot profiles are deleted at the end (issue 1830). Lean: no export and no player path. LOAD30b added: the title waits a frame at a time for the launch's campaign host read (Artoo on cc4a63ce). LOAD35b is LOAD35 on head 81368f70, main merged in again (PR 1984 quick battle capture exits kept ahead of 1445's staged retirement; PR 1985's showcase args guard), plus step 2f (Artoo on 9c015f43): the windowed quick battle screenshot check (main/test/quick_battle_shots_check.gd, seed 4242). LOAD35 (staged on 9c015f43, not run) was LOAD34b on head 9c015f43, main merged in (PR 1786 Ship Exteriors V2 default on, PR 1861; Artoo: the timing gate pins the combined head), plus: the title backdrop leaves the viewport's anti-aliasing as the menu had it (LOAD34b's events: its 4X to 2X MSAA switch cost the next title draw 847 ms warm); the bench names the debris mesh build, each warm surface step and each chunk join. LOAD34b was LOAD34 on head a2f314cd: the title backdrop's MSAA is chosen before the viewport quality write, so the viewport takes one MSAA value and the AA trace sees every change (Artoo on b21535a6). LOAD34 was LOAD33c on head b21535a6, which adds (from LOAD33c's results: title 919 ms cold and 713 ms warm in "start", no pipelines; cold s25 one debris surface 73 pipelines in 5.7 s): the world sky's radiance spread over frames (INCREMENTAL, same result as QUALITY); hull-debris surfaces warm their colour then shadow passes a frame apart; the bench rows name render events (world sky, nebula map, planet maps, viewport AA). LOAD33c was LOAD33b on head 156fbc66, main merged in (PR 1966's check shards, PR 1967's shared shader cache and close guards; Artoo: the load and close proof runs on the merged head). LOAD33b was LOAD33 on head 8721dd85: the title's R01 check asks the bake cache whether both R01 textures are still held, so an evicted R01 sends the title back to the baked look (Artoo on 002e143f). LOAD33 was LOAD32 on head 002e143f, which added (from LOAD32's results): the title menu's backdrop board takes a baked planet look until a battle has put the 8K R01 maps on screen (LOAD32 cold title: 682 ms of a 910 ms frame was their 853 MB upload, new with Planets V2); the first hull-debris chunk joins once per surface, a frame apart, under the cover (LOAD32 s25: one chunk alone made 59 pipelines in a 5.9 s frame, cold and warm); the ship setup line splits look assign time by reused material and in-tree (warm title 1148 ms: V16_37's look assign 957 ms). LOAD32 was LOAD31 on head 7ff7e711, which added: the board's hull-debris chunks join one a frame while a battle loads (LOAD30d cold s25: 7 chunks in one frame compiled 59 surface pipelines, a 5.7 s frame); the bench names the hull reads finished before each row's draw (LOAD30d warm title: a 1131 ms draw with no viewport time); main merged again. LOAD31 (never queued) was LOAD30d on the head merged with PR 1776 (Planets V2) and PR 1932 (sound wiring), plus step 2e, the Windows close proof Artoo asked for across the two PRs: world/test/bake_close_check.gd run windowed (a close before the bake service attaches frees it; a close while its worker is inside a job stops and joins it). LOAD30d fixed (Fable on 98926849): the runner's step 4 no longer overwrites the result file path, so the title launch lines, the grades and the RESULT reach load10_result.txt; the host is read first and held, the title's Quick battle waits for the battle scene, the 1519 first title frame counts only a draw with the title in the tree. LOAD30c added (Artoo on 6784b6b1): launch to the first painted title menu on its own line in the bench and in a new step 2d, two cold launches to the title (no save, and a valid saved run written by bench/write_save_1434.gd inside its own profile), each failing plainly with no menu in 20 s. Replaces OPUS1434_LOAD35.bat (staged on 9c015f43, not run), OPUS1434_LOAD34b.bat (ran Nov 24 on a2f314cd), OPUS1434_LOAD34.bat (staged on b21535a6), OPUS1434_LOAD33c.bat (ran Nov 24 on 156fbc66), OPUS1434_LOAD33b.bat (staged on 8721dd85, not run), OPUS1434_LOAD33.bat (staged on 002e143f), OPUS1434_LOAD32.bat (ran Nov 24 on 7ff7e711), OPUS1434_LOAD31.bat (staged, never queued), OPUS1434_LOAD30d.bat (ran or running Nov 24 on ffc4ead9), OPUS1434_LOAD30c.bat, OPUS1434_LOAD30b.bat and OPUS1434_LOAD30.bat (queued, not run), OPUS1434_LOAD29.bat (ran Nov 23) and every earlier LOAD bat.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat; steps 1 to 3 as LOAD23.
rem Steps on one pinned commit (opus/issue-1434 head 81368f70, PR 1445):
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
rem      e. world/test/bake_close_check.gd, windowed on the same build: out_new\bake_close.txt, "PASS: bake_close_check".
rem      Result: out_new\load10\load10_result.txt, gate line "[load10] RESULT PASS".
rem   3. the Godot test profiles under out_new\load10 (profile_warm and close_*\*\profile) are deleted: rebuildable leftovers
rem      of this job (RULEBOOK 3.3), kept results and logs untouched.
rem   No export and no player path this run (Board, Nov 22: disk tight).
rem Nothing outside the attempt folder is written or deleted. Once queued, never edited; a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1434aq"
set "LABEL=1434"
set "TOOLS=godot"
set "PIN_NEW=81368f70a01557a4c987543361ac749170edcfa1"
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

rem ---- 2e. the bake service close proof (issues 1434 and 1765, Artoo): windowed, the same build
set "JW_CONTINUE=1"
set "JW_STEP=%1 bake_close" & set "JW_EXPECT=%O%\bake_close.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --windowed --resolution 1280x720 -s res://world/test/bake_close_check.gd > "%O%\bake_close.txt" 2>&1
findstr /c:"PASS: bake_close_check" "%O%\bake_close.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 bake_close: see bake_close.txt")

rem ---- 2f. the quick battle screenshot check (issue 1978, Artoo on 9c015f43): windowed, the same build
set "QS=%O%\quick_shots"
if not exist "%QS%" mkdir "%QS%"
set "JW_CONTINUE=1"
set "JW_STEP=%1 quick_shots" & set "JW_EXPECT=%O%\quick_shots.txt" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" -s res://main/test/quick_battle_shots_check.gd -- --seed 4242 --shots "%QS%" --fac hegemony --map belt --window 1280x720 > "%O%\quick_shots.txt" 2>&1
findstr /c:"PASS: seeded quick battle" "%O%\quick_shots.txt" > nul
if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "%1 quick_shots: see quick_shots.txt")

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
