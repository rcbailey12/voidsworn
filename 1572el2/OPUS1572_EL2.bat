@echo off
rem Issue 1572 follow-up, EL2 (replaces EL1 after Artoo on PR 1577): ElevenLabs batch 1 sound candidates (Ryan chose Creator monthly, Nov 22 2026).
rem Needs: Ryan has double-clicked tools\pc\elevenlabs_api_key.bat once (VOIDSWORN_ELEVENLABS_API_KEY).
rem No Godot, no GPU, no ships: a pinned checkout for the script and the list, then node calls the API.
rem Outputs stay in this job's out folder (candidates only, never into build\godot). Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1572el2"
set "LABEL=1572"
set "TOOLS=node"
set "PIN_NEW=729e8ec3c2a182cb93b7a849172c2cc3c633e7c0"
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
set "L=%OJ_REPO%\contrib\opus\sound\elevenlabs_batch1.json"
set "JW_STEP=%1 selftest" & set "JW_EXPECT=%O%\selftest.txt" & call "%JW%" run 300 node "%G%\elevenlabs_gen_selftest.js" > "%O%\selftest.txt" 2>&1
set "JW_STEP=%1 dry" & set "JW_EXPECT=%O%\dry.txt" & call "%JW%" run 120 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --dry > "%O%\dry.txt" 2>&1
set "JW_STEP=%1 smoke" & set "JW_EXPECT=%O%\smoke.txt" & call "%JW%" run 600 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --only ui_click --max-credits 1000 > "%O%\smoke.txt" 2>&1
findstr /C:"ELEVENLABS GEN PASS" "%O%\smoke.txt" >NUL || (echo FAILED: smoke did not pass, full batch not started & exit /b 1)
set "JW_STEP=%1 generate" & set "JW_EXPECT=%O%\generate.txt" & call "%JW%" run 7200 node "%G%\elevenlabs_gen.js" --list "%L%" --out "%O%\elevenlabs" --max-credits 40000 > "%O%\generate.txt" 2>&1
exit /b 0
