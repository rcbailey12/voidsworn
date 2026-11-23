@echo off
rem R431 round 3 AFTER pictures collector (opus431f_<ship> jobs, six hulls). The OPUS431_<ship>_RUN.bat ship_job runs write their in-game shots to
rem voidsworn_test\opus431_<ship>\out\shots and their Blender pictures under out\recipe; relay_push only sends out_* folders,
rem so those never reached the relay (GP1 relay bc73d35e had text only). This job copies the pictures (jpg and png, read
rem only, nothing deleted or changed there) into its own out_after_<ship> folders and relays them. Run it after all five
rem RUN jobs finish. A ship with no folder yet is logged and skipped. Light job: no GPU, no Godot start.
setlocal EnableExtensions
set "JOB=opus431fafter"
set "LABEL=1777"
set "TOOLS=godot"
set "PIN_NEW=906d2b480e01c6c95bfc8f6f391fba61ef5a79b7"
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

call "%HEAD%" checkout new %PIN_NEW%
for %%S in (GP1 GA1 GL1 GS1 GV2 GW4) do call :grab %%S
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- copy one ship's pictures. robocopy copies only (no /MOV, no /MIR, no /PURGE); exit codes under 8 are success.
:grab
set "SRC=%VT%\opus431f_%1\out"
set "O=%OJ_OUT%\out_after_%1"
if not exist "%O%" mkdir "%O%"
if not exist "%SRC%" (echo no folder %SRC% > "%O%\missing.txt" & exit /b 0)
copy /y "%SRC%\result.txt" "%O%\result.txt" > nul 2>&1
if exist "%SRC%\shots" robocopy "%SRC%\shots" "%O%\shots" *.jpg *.png *.json /S /MAX:10000000 /R:1 /W:1 /NP > "%O%\copy_shots.txt" 2>&1
if exist "%SRC%\recipe" robocopy "%SRC%\recipe" "%O%\recipe" *.jpg *.png /S /MAX:10000000 /R:1 /W:1 /NP > "%O%\copy_recipe.txt" 2>&1
dir /s /b "%O%" > "%O%\list.txt"
exit /b 0
