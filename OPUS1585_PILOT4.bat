@echo off
rem Issue 1585 Gate 1: ElevenLabs calibration pilot with R412 and R409 beats (about 2,840 credits; stop at 4,000 used). Replaces OPUS1585_PILOT, PILOT2 and PILOT3.
rem Needs: OPUS1585_KEYTEST passed, then Ryan saved the key with ELEVENLABS_API_KEY.bat. No Godot, no GPU, no ships.
rem Outputs stay in this job's out folder (candidates only, never into build\godot). Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1585pilot4"
set "LABEL=1585"
set "TOOLS=node"
set "PIN_NEW=fc3a30e69a55a2fba2b84c17f49d23cb8da81a1f"
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
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "G=%OJ_REPO%\contrib\opus\tools\sound"
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_pilot.json"
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
findstr /C:"ELEVENLABS GEN SELFTEST PASS" "%O%\selftest.txt" >NUL || (echo FAILED: selftest & exit /b 1)
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --dry > "%O%\dry.txt" 2>&1
set "JW_STEP=%1 smoke" & set "JW_EXPECT=%O%\smoke.txt" & call "%JW%" run 600 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --only fac_ithar_crack --max-credits 500 > "%O%\smoke.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\smoke.txt" >NUL || (echo FAILED: smoke did not pass, pilot not started & exit /b 1)
set "JW_STEP=%1 pilot" & set "JW_EXPECT=%O%\pilot.txt" & call "%JW%" run 3600 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --max-credits 4000 > "%O%\pilot.txt" 2>&1
set "JW_STEP=%1 listen" & set "JW_EXPECT=%O%\listen\index.html" & call "%JW%" run 300 node "%G%\listen_page.js" --list "%L%" --gen "%O%\elevenlabs" --repo "%OJ_REPO%" --out "%O%\listen" > "%O%\listen.txt" 2>&1
exit /b 0
