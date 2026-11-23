@echo off
rem Issue 1752 Gate 2 Wave B: the 55 sound effects not yet made, prompts rewritten to Ryan's Wave A3 picks (PR 1860, plan 8.2): 108 takes, 5,112 credits estimated, about 1,410 real; stop at 6,000 used. Then the listening page.
rem Needs Ryan's typed "go wave b" in the Board thread. Music prototypes are not in this wave (Gate 3). No Godot, no GPU, no ships, deletes nothing.
rem Skeleton copied whole from OPUS1752_WAVEA3B.bat (the working one). Pinned to PR 1860's merge on main. Fresh job name, so a fresh output folder. Once queued, never edited.
rem The list file must match PR 1860's manifest by sha256 and the dry run must show 108 still to make, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752waveb"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=e3c6699d706fddfefc9bf25eec0bc464461e0bee"
set "LIST_SHA=24d1bf316961dde68fc32f44ca324f3e8eb9b6a60bbded02a64c80f6b34751ac"
set "WAVE=wep_sunward_hbattery_salvo,wep_sunward_autocannon,wep_sunward_torp_launch,wep_sunward_turret,wep_sunward_hbattery,wep_flak_airburst,wep_torp_eject,evt_pass_by_slug,wep_directorate_turbo,wep_directorate_hturbo,wep_directorate_ion_beam,wep_directorate_picket,wep_hullbreaker_scatter,wep_hullbreaker_rockets,wep_hullbreaker_junk_gun,wep_chorus_bioplasma,wep_chorus_tendril,wep_chorus_spore_cloud,wep_chorus_sporeb,wep_ithar_needle,wep_ithar_pulsar,wep_ithar_startorp,wep_eclipse_gsentry,wep_eclipse_gauss_charge,wep_eclipse_nlance,wep_eclipse_doom,wep_eclipse_doom_charge,wep_craft_guns,wep_craft_bombs,wep_mech_recoil_tail,wep_layer_body_heavy,imp_glass_armor,imp_obsidian_eclipse,imp_metal_light,imp_energy_sear,imp_las,imp_acid_on_metal,shd_break_prismatic,shd_hit_absorb,dmg_turret_knockout,dmg_shield_burnout,dmg_breach_shear_metal,dmg_breach_vent,dmg_engine_fail,death_directorate_blackout,death_hullbreaker_snap,death_ithar_shatter,death_eclipse_shear,death_metal_break,death_sunward_magazine,ui_boss_arrival,evt_fleet_warp_in,ui_confirm_latch,ui_turn_start,amb_bridge_bed"
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
> "%O%\keepers_not_remade.txt" echo Already made and picked in Waves A, A2 and A3, not re-made here (plan 8.1). Music prototypes wait for Gate 3.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
set "E=%O%\elevenlabs"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not PR 1860's manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 6000 > "%O%\dry.txt" 2>&1
findstr /C:"108 steps, 108 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 108 new takes, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 6000 > "%O%\wave_b.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_b.txt" >NUL && (> "%O%\result.txt" echo PASS: wave B, all 108 takes made, see wave_b.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave B, see wave_b.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
