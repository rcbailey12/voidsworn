@echo off
rem Issue 1585: Windows check of the masked key bat with a DUMMY value (separate _SELFTEST name, removed after).
rem No real key, no network, no ElevenLabs call. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1585key"
set "LABEL=1585"
set "TOOLS=node"
set "PIN_NEW=baf255a042d2c13934a9d1c74281a4e9abeb0b5d"
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
set "JW_STEP=%1 keytest" & set "JW_EXPECT=%O%\keytest.txt" & call "%JW%" run 120 cmd /c ""%OJ_REPO%\tools\pc\elevenlabs_api_key.bat" /selftest" > "%O%\keytest.txt" 2>&1
findstr /C:"KEY BAT SELFTEST PASS" "%O%\keytest.txt" >NUL || (echo FAILED: key bat selftest & exit /b 1)
reg query HKCU\Environment /v VOIDSWORN_ELEVENLABS_API_KEY_SELFTEST >NUL 2>&1 && (echo FAILED: dummy value left behind & exit /b 1)
exit /b 0
