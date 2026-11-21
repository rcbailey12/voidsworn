@echo off
rem Issue 1524: before and after pictures of a ram and a boarding in the real battle scene on the PC (GPU, real hulls).
rem OLD is the probe commit (main's battle.gd plus the probe), NEW is the wiring commit. Each arm writes RAM-1524_<arm>.jpg
rem and BRD-1524_<arm>.jpg (a 2 by 2 strip of four moments, code name on it, 720 px) into out_<old|new>.
rem Made from tools/pc/jobs/opus_job_template.bat. Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1524"
set "LABEL=1524"
set "TOOLS=godot"
set "PIN_NEW=5aa1e1692f8ff3a29b9b237b1548f2ed05f0051e"
set "PIN_OLD=6be527ff0d880179cf5b021aa8cfd02517e61093"

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

call :one new %PIN_NEW% after
call :one old %PIN_OLD% before
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- the probe: battle 1 (scenario s1), max quality, a window (GPU); it expects both strips
set "JW_STEP=%1 shots" & set "JW_EXPECT=%O%\BRD-1524_%3.jpg" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --script res://tools/probes/close_action_1524_shots.gd -- --scenario s1 --out "%O%" --arm %3 --cam 110 --stage "PC, installed in game, pin %2" > "%O%\shots.txt" 2>&1
exit /b 0
