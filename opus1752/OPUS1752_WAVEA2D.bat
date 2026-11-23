@echo off
rem Issue 1752 Gate 2 Wave A2, finish: makes only the 4 takes wavea2c lost to HTTP 400 text_too_long (prompts over 450 characters, nothing charged).
rem Ryan's go for Wave A2 (Nov 23 2026 00:55 UTC) covers finishing it. About 272 credits estimated, about 75 real; stop at 600 used. Wave B stays held.
rem Resumes into wavea2c's own output folder, so its 16 made takes are kept and never paid again. Once queued, never edited.
rem Gates: the folder must exist, the list must match PR 1799's manifest by sha256, and the dry run must show 4 still to make, or nothing is sent.
rem The listening page runs outside the step wrapper, so it builds even if a take fails (wavea2c's page was skipped for that reason).
setlocal EnableExtensions
set "JOB=opus1752wavea2d"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=025ee1e4d9e2942d8ceec3946e16857186a6b783"
set "LIST_SHA=97265918b421ee9bbdf8c79f984cc8564a9a928c8cea9a904e1db8edc8029887"
set "WAVE=wep_directorate_laser,wep_eclipse_gauss_fire,wep_chorus_spines,imp_bio_flesh,death_chorus_rupture,wep_ithar_shard,wep_sunward_lance_beam,shd_break_energy,ui_reward_vault,imp_metal_heavy"
if "%PIN_NEW%"=="SET_TO_MERGED_MAIN_SHA" (echo FAILED: set PIN_NEW to the merged main commit first & exit /b 2)

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "A2=%VT%\opus1752wavea2c\out_20261122_192230_29378\out_new"
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
set "E=%A2%\elevenlabs"
if not exist "%E%\receipts.jsonl" (> "%O%\result.txt" echo FAILED: wavea2c folder %E% is gone, nothing sent & echo FAILED: no wavea2c folder & exit /b 1)
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not PR 1799's manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 600 > "%O%\dry.txt" 2>&1
findstr /C:"20 steps, 4 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show exactly 4 takes to make, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 600 > "%O%\wave_a2_finish.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_a2_finish.txt" >NUL && (> "%O%\result.txt" echo PASS: wave A2 finished, all 20 takes on disk, see wave_a2_finish.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave A2 finish, see wave_a2_finish.txt and %E%\receipts.jsonl)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
if not exist "%O%\elevenlabs" mkdir "%O%\elevenlabs"
copy /y "%E%\*.mp3" "%O%\elevenlabs\" >NUL
copy /y "%E%\manifest.jsonl" "%O%\elevenlabs\" >NUL
copy /y "%E%\receipts.jsonl" "%O%\elevenlabs\" >NUL
>> "%O%\result.txt" echo listen page: out_new\listen\index.html; all takes and receipts copied to out_new\elevenlabs for the relay
exit /b 0
