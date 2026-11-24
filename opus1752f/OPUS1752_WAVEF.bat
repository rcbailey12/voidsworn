@echo off
rem Issue 1752 Gate 3 Wave F: 34 sounds still on old placeholders, 4 polish re-rolls, 16 new moments and 2 more takes of 27 keepers for variety: 161 takes, 8,264 credits estimated, about 2,300 real; stop at 10,000 used. Then the listening page.
rem Needs Ryan's typed "go wave f" in the Board thread. No Godot, no GPU, no ships, deletes nothing.
rem Skeleton copied whole from OPUS1752_WAVEE.bat (passed Nov 24). Pinned to the Gate 3 list PR's merge on main. Fresh job name, so a fresh output folder. Once queued, never edited.
rem The list file must match elevenlabs_gate3.json by sha256 and the dry run must show 161 still to make, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752wavef"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=e942faf678ef0bb8c3adff6a853efd953be8d7de"
set "LIST_SHA=4a5709be6e07c6e8194b70dcf23011d4aa77eee67dcf6d07e6b63443ce0105e1"
set "WAVE=wep_ithar_flak,imp_gauss_slug,imp_ion_disrupt,imp_patter_hull,imp_patter_shield,boom_pop_metal,boom_small_metal,boom_medium_metal,ship_engine_loop,ship_craft_launch,ship_phase_jump,ship_engine_cough,ship_thruster_puff,ship_power_charge,death_metal_powerdown,death_metal_vent,death_metal_crack,death_metal_run,death_debris_cool,death_hulk_vent,death_metal_tail,death_wreck_settle,death_bass_drop,ord_brace_lock,ord_adapt_shift,ord_board_grapple,ui_cancel_switch,ui_select_detent,ui_hover_tick,ui_panel_slide,ui_alert_bell,ui_round_bell,ui_enemy_turn,wep_ithar_pulsar_b,wep_hullbreaker_rockets_b,ui_boss_arrival_long,dmg_engine_fail_long,evt_ram_impact,evt_torp_intercept,shd_raise,evt_gravity_well,evt_nebula_bed,evt_asteroid_scrape,evt_hull_alarm,ui_command_issue,map_fleet_jump,map_fleet_arrive,ui_purchase,ui_module_install,ui_relic_socket,ui_rank_up,ui_event_comm,ui_ship_lost,imp_metal_light_more,imp_metal_heavy_more,imp_las_more,imp_energy_sear_more,imp_bio_flesh_more,imp_glass_armor_more,imp_obsidian_eclipse_more,shd_hit_absorb_more,wep_sunward_autocannon_more,wep_sunward_turret_more,wep_sunward_hbattery_more,wep_flak_airburst_more,wep_directorate_laser_b_more,wep_directorate_turbo_more,wep_directorate_hturbo_more,wep_directorate_picket_more,wep_hullbreaker_scatter_more,wep_hullbreaker_junk_gun_more,wep_chorus_spines_more,wep_chorus_spore_cloud_more,wep_chorus_sporeb_more,wep_ithar_shard_more,wep_ithar_needle_more,wep_eclipse_gsentry_more,wep_eclipse_gauss_fire_ctl_more,wep_craft_guns_more,ui_confirm_latch_more"
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
set "E=%O%\elevenlabs"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not the Gate 3 list, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 10000 > "%O%\dry.txt" 2>&1
findstr /C:"161 steps, 161 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 161 new takes, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 10000 > "%O%\wave_f.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_f.txt" >NUL && (> "%O%\result.txt" echo PASS: wave F, all 161 takes made, see wave_f.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave F, see wave_f.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
