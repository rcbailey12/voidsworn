@echo off
rem Issue 1752 Gate 2 Wave E: 4 ids Neon marked still needing work after Wave D (issue 1899, plan 8.5): 8 takes, 280 credits estimated, about 80 real; stop at 500 used. Then the listening page.
rem Needs Ryan's typed "go wave e" in the Board thread. No Godot, no GPU, no ships, deletes nothing.
rem Skeleton copied whole from OPUS1752_WAVED.bat (passed Nov 23). Pinned to the Wave E PR's merge on main. Fresh job name, so a fresh output folder. Once queued, never edited.
rem The list file must match the Wave E manifest by sha256 and the dry run must show 8 still to make, or nothing is sent.
rem R418: the generator writes receipts.jsonl, manifest.jsonl and each file as it goes. The wave and the listening page run outside the step wrapper, so the page builds even if a take fails.
setlocal EnableExtensions
set "JOB=opus1752wavee"
set "LABEL=1752"
set "TOOLS=node"
set "PIN_NEW=e756b55d39f007023d5b72676c8787417257daa8"
set "LIST_SHA=0f255160aba56f06b87ab23de38cabbc8a3f5a5f57977fa7294af1495b25384f"
set "WAVE=wep_directorate_picket,wep_eclipse_gsentry,imp_metal_light,death_eclipse_shear"
if "%PIN_NEW%"=="e756b55d39f007023d5b72676c8787417257daa8" (echo FAILED: set PIN_NEW to the merged main commit first & exit /b 2)

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
> "%O%\keepers_not_remade.txt" echo Wave B, C and D keepers and Ryan's picks are in plan 8.3 to 8.5, not re-made here.
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot_v2.json"
set "E=%O%\elevenlabs"
certutil -hashfile "%L%" SHA256 > "%O%\list_sha.txt" 2>&1
findstr /i /c:"%LIST_SHA%" "%O%\list_sha.txt" >NUL || (> "%O%\result.txt" echo FAILED: list file is not the Wave E manifest, nothing sent & echo FAILED: list sha256 mismatch & exit /b 1)
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (> "%O%\result.txt" echo FAILED: selftest, nothing sent & echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --dry --only %WAVE% --max-credits 500 > "%O%\dry.txt" 2>&1
findstr /C:"8 steps, 8 still to make" "%O%\dry.txt" >NUL || (> "%O%\result.txt" echo FAILED: dry run did not show 8 new takes, nothing sent & echo FAILED: dry & exit /b 1)
node "%G%\elevenlabs_gen.js" --list "%L%" --out "%E%" --only %WAVE% --max-credits 500 > "%O%\wave_e.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\wave_e.txt" >NUL && (> "%O%\result.txt" echo PASS: wave E, all 8 takes made, see wave_e.txt for credits) || (> "%O%\result.txt" echo INCOMPLETE: wave E, see wave_e.txt and elevenlabs\receipts.jsonl; rerun the same job to resume)
node "%G%\listen_page.js" --list "%L%" --gen "%E%" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
>> "%O%\result.txt" echo listen page: out_new\listen\index.html (rows for items not in this wave show takes missing); takes and receipts in out_new\elevenlabs for the relay
exit /b 0
