@echo off
rem Issue 1752 Gate 2 Wave C: 25 ids Ryan rejected in Wave B, prompts rewritten to his notes (PR 1868, plan 8.3): 49 takes, 2,572 credits estimated, about 707 real; stop at 3,000 used. Then the listening page.
rem Needs Ryan's typed "go wave c" in the Board thread. No Godot, no GPU, no ships, deletes nothing.
rem Skeleton copied whole from OPUS1752_WAVEB.bat (passed Nov 23). Pinned to PR 1868's merge on main. Fresh job name, so a fresh output folder. Once queued, never edited.
rem The list file must match PR 1868's manifest by sha256 and the dry run must show 49 still to make, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752wavec"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=9afbc41d1e95d221ce0d4df55340f712d524e38b"
set "LIST_SHA=7d2078b5078411a8ae1305504d109825f8881b313f949832d0b5e470970c3090"
set "WAVE=wep_sunward_turret,wep_sunward_hbattery,wep_directorate_picket,wep_eclipse_gsentry,wep_eclipse_doom,wep_eclipse_doom_charge,wep_chorus_spore_cloud,wep_chorus_sporeb,wep_hullbreaker_junk_gun,wep_torp_eject,evt_pass_by_slug,wep_craft_bombs,imp_obsidian_eclipse,imp_metal_light,imp_energy_sear,imp_las,imp_acid_on_metal,dmg_shield_burnout,dmg_breach_shear_metal,dmg_breach_vent,death_ithar_shatter,death_eclipse_shear,death_sunward_magazine,evt_fleet_warp_in,amb_bridge_bed"
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
> "%O%\keepers_not_remade.txt" echo Wave B keepers and Ryan's picks are in plan 8.3, not re-made here.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
set "E=%O%\elevenlabs"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not PR 1868's manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 3000 > "%O%\dry.txt" 2>&1
findstr /C:"49 steps, 49 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 49 new takes, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 3000 > "%O%\wave_c.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_c.txt" >NUL && (> "%O%\result.txt" echo PASS: wave C, all 49 takes made, see wave_c.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave C, see wave_c.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
