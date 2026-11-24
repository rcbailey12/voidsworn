@echo off
rem Issue 1752 Gate 3 Wave M2 (re-planned after M1, plan 9): 11 faction battle loops with stems (calm = all but drums, intense = full mix), title x2, 6 map, 2 boss, nemesis, shop, 3 reward, 7 stings: 44 steps, 46,290 credits estimated; stop at 52,000 used. Then the listening page.
rem Needs Ryan's typed "go wave m2" in the Board thread. No Godot, no GPU, no ships, deletes nothing.
rem Skeleton copied whole from OPUS1752_WAVEE.bat (passed Nov 24). Pinned to the Gate 3 list PR's merge on main. Fresh job name, so a fresh output folder. Once queued, never edited.
rem The list file must match elevenlabs_gate3.json by sha256 and the dry run must list 44 steps, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752wavem2"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=2a429c418790f77c18847fc3250db13caa296cf3"
set "LIST_SHA=1daecbc2d2da3919492c168124f97daa683e6b7abb62bd02d89d910f0f531d46"
set "WAVE=mus_voidsworn_loop_b,mus_hegemony_loop_a,mus_hegemony_loop_b,mus_corsair_loop_a,mus_corsair_loop_b,mus_chorus_loop_a,mus_chorus_loop_b,mus_ithar_loop_a,mus_ithar_loop_b,mus_deathless_loop_a,mus_deathless_loop_b,mus_title,mus_map_s1_1,mus_map_s1_2,mus_map_s2_1,mus_map_s2_2,mus_map_s3_1,mus_map_s3_2,mus_boss_1,mus_boss_2,mus_nemesis,mus_reward_1,mus_reward_2,mus_reward_3,mus_shop,mus_sting_victory_1,mus_sting_victory_2,mus_sting_champion,mus_sting_defeat_1,mus_sting_defeat_2,mus_sting_run_won,mus_sting_run_lost"
if "%PIN_NEW%"=="SET_TO_MERGED_MAIN_SHA" (echo FAILED: set PIN_NEW to the merged main commit first & exit /b 2)

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
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
> "%O%\keepers_not_remade.txt" echo The 65 Gate 2 keepers are in keepers_gate2.json and the game, not re-made here.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_gate3.json"
rem Resume (Board, Nov 24: Wave F remade 21 paid takes because each run opens a fresh out_ folder): takes live in one fixed folder per job, so a rerun skips what is made (the generator skips a file whose name and size match, and its receipts block a double pay). Copied into out_new for the relay at the end; nothing is deleted.
set "E=%VT%\el_resume\%JOB%"
if not exist "%E%" mkdir "%E%"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not the Gate 3 list, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 52000 > "%O%\dry.txt" 2>&1
findstr /C:"44 steps, " "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not list the 44 M2 steps, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 52000 > "%O%\wave_m2.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_m2.txt" >NUL && (> "%O%\result.txt" echo PASS: wave M2, all 44 steps made, see wave_m2.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave M2, see wave_m2.txt and elevenlabs\receipts.jsonl; rerun the same job to resume from %E%)
robocopy "%E%" "%O%\elevenlabs" /E /NFL /NDL /NJH /NJS /NP > "%O%\copy_takes.txt"
node "%G%\listen_page.js" --list "%L%" --gen "%O%\elevenlabs" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
