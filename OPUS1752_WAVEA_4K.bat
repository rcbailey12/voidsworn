@echo off
rem Issue 1752 Gate 2 Wave A: 14 ElevenLabs items (27 files, about 1,060 credits estimated; stop at 1,200 used), then the listening page.
rem Needs: PR 1753 merged to main. Before queueing, set PIN_NEW below to that merged main commit (40 hex). Once queued, never edited.
rem The list file must match the reviewed 72-item pack by sha256, or nothing is sent. No Godot, no GPU, no ships.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes; result.txt says PASS, INCOMPLETE or FAILED.
setlocal EnableExtensions
set "JOB=opus1752wavea"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=cc0d94fd13391ac566666d79c2ed8518ce9fa579"
set "LIST_SHA=4690fcc8cece729bbcc92642889a733273a0321fec4543da7e485477d62f5fb5"
set "WAVE_A=wep_sunward_battery,wep_sunward_battery_v3ab,wep_directorate_laser,wep_chorus_spines,wep_ithar_shard,wep_eclipse_gauss_fire,wep_sunward_lance_beam,imp_metal_heavy,imp_metal_heavy_v3ab,imp_bio_flesh,shd_break_energy,death_chorus_rupture,ui_click_switch,ui_reward_vault"
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
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not the reviewed 72-item pack, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --dry --only %WAVE_A% --max-credits 4000 > "%O%\dry.txt" 2>&1
findstr /C:"27 steps" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not list 27 steps, nothing sent & echo FAILED: dry & exit /b 1)
set "JW_STEP=%1 wave A" & set "JW_EXPECT=%O%\wave_a.txt" & call "%JW%" run 3600 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --only %WAVE_A% --max-credits 4000 > "%O%\wave_a.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_a.txt" >NUL && (> "%O%\result.txt" echo PASS: wave A, all 27 files made, see wave_a.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave A, see wave_a.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
set "JW_STEP=%1 listen" & set "JW_EXPECT=%O%\listen\index.html" & call "%JW%" run 300 node "%G%\listen_page.js" --list "%L%" --gen "%O%\elevenlabs" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html
exit /b 0
