@echo off
rem Issue 1752 Gate 2 Wave A3: Fable's fixed prompts for the 6 Wave A2 rejects plus 3 one-change twins (PR 1808): 9 ids, 18 takes, 800 credits estimated, about 223 real; stop at 900 used. Then the listening page.
rem Needs Ryan's typed "go wave a3" in the Board thread. Wave B stays held. No Godot, no GPU, no ships, deletes nothing.
rem WAVEA3B (Board, Nov 23 04:30 UTC): A3 failed in 7 s before any call because line 28 was a bare "call :one" with no label; fixed like A2D.
rem Pinned to PR 1808's merge on main. Fresh job name, so a fresh output folder; Wave A and A2 folders are never touched. Once queued, never edited.
rem The list file must match PR 1808's manifest by sha256 and the dry run must show 18 still to make, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752wavea3b"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=87c831a002002b94592fed82e2cdf93767c2d029"
set "LIST_SHA=adff3b6565e0d8cd4fcbc755991a9ed4b62034f9f4d6409c6ce26add3618a958"
set "WAVE=wep_sunward_lance_beam,wep_sunward_lance_beam_inf45,shd_break_energy,wep_directorate_laser,wep_directorate_laser_b,wep_ithar_shard,wep_chorus_spines,wep_eclipse_gauss_fire,wep_eclipse_gauss_fire_ctl"
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
> "%O%\keepers_not_remade.txt" echo Wave A2 keepers, not re-made here: imp_metal_heavy t1 t2; death_chorus_rupture t2 (t1 alternate); ui_reward_vault t1 t2; imp_bio_flesh t1 t2; wep_eclipse_gauss_fire t1. Files: voidsworn branch board/pc-out-wavea2-1752.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
set "E=%O%\elevenlabs"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not PR 1808's manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 900 > "%O%\dry.txt" 2>&1
findstr /C:"18 steps, 18 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 18 new takes, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 900 > "%O%\wave_a3.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_a3.txt" >NUL && (> "%O%\result.txt" echo PASS: wave A3, all 18 takes made, see wave_a3.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave A3, see wave_a3.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
