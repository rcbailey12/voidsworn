@echo off
rem Issue 1752 Gate 2 Wave A2: the 10 items Ryan's Wave A ear audit failed, rewritten in PR 1794 (20 takes, 976 credits estimated, about 270 real; stop at 1,200 used), then the listening page.
rem Ryan's go: Nov 23 2026 00:55 UTC (adopted Antigravity's audit, asked for Wave A2 into a fresh folder). Wave B stays held.
rem Pinned to PR 1794's merge on main. Fresh job name, so a fresh output folder; Wave A's out_new is never touched. Once queued, never edited.
rem The list file must match PR 1794's manifest by sha256 and the dry run must show 20 still to make, or nothing is sent. No Godot, no GPU, no ships.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes; result.txt says PASS, INCOMPLETE or FAILED.
setlocal EnableExtensions
set "JOB=opus1752wavea2c"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=f767f45cd5756a91b7229901ed9624c38ca01ee1"
set "LIST_SHA=e2460d11796254cd6b78d4d29d4b1f3d4da8d361500e6caae6dc16274510d071"
set "WAVE=wep_directorate_laser,wep_eclipse_gauss_fire,wep_chorus_spines,imp_bio_flesh,death_chorus_rupture,wep_ithar_shard,wep_sunward_lance_beam,shd_break_energy,ui_reward_vault,imp_metal_heavy"
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
> "%O%\cleared_from_wave_a.txt" echo Cleared in Wave A (Ryan's ear audit, Nov 23 2026), not re-made here: wep_sunward_battery t1 t2; wep_sunward_battery_v3ab t1 (flagship reference); imp_metal_heavy_v3ab t1 (needs a second take later); ui_click_switch t1 t2 (t3 dropped). Files: voidsworn-relay pc-out-opus1752wavea out_20261122_161523_25483\out_new\elevenlabs.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not PR 1794's manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --dry --only %WAVE% --max-credits 1200 > "%O%\dry.txt" 2>&1
findstr /C:"20 steps, 20 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 20 new takes, nothing sent & echo FAILED: dry & exit /b 1)
set "JW_STEP=%1 wave A2" & set "JW_EXPECT=%O%\wave_a2.txt" & call "%JW%" run 3600 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --only %WAVE% --max-credits 1200 > "%O%\wave_a2.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_a2.txt" >NUL && (> "%O%\result.txt" echo PASS: wave A2, all 20 takes made, see wave_a2.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave A2, see wave_a2.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
set "JW_STEP=%1 listen" & set "JW_EXPECT=%O%\listen\index.html" & call "%JW%" run 300 node "%G%\listen_page.js" --list "%L%" --gen "%O%\elevenlabs" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing)
exit /b 0
