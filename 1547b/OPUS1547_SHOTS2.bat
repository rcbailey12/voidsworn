@echo off
rem Issue 1547 (PR 1549; SHOTS2 replaces OPUS1547_SHOTS.bat, never queued: its pin went stale when main conflicted): the boarding breach looks on real hulls in the battle scene (GPU). One pin, opus/issue-1547
rem head e520b5ce (main merged in). Looks r0 (PR 1527, before), A, B (pick), C, each at cameras 110 and 170:
rem   BRD-1547-<look>_c<cam>.jpg: a 2 by 2 strip of four moments, code name, look and stage on it, 720 px
rem   (the folder per camera keeps the probe's own file name BRD-1547-<look>_after.jpg)
rem Clips at camera 170, 30 fps, 720 px tall, x264 crf 26 (each under 10 MB, checked): BRD-1547-B.mp4, BRD-1547-r0.mp4.
rem The .avi from Godot's movie maker is this job's own leftover and is deleted once its mp4 is written.
rem moments.txt and fx_check.txt: close_action_moments_check and close_action_fx_check on the GPU build.
rem result.txt: every expected file, its size, and PASS or MISSING; a clip over 10 MB is FAIL.
rem Stage on every picture: "PC, real hulls, pin e520b5ce" (set by the probe's --stage; the provenance stamp under it
rem is wrong, issue filed). Made from tools/pc/jobs/opus_job_template.bat after OPUS1524_SHOTS3.bat.
rem Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions EnableDelayedExpansion
set "JOB=opus1547b"
set "LABEL=1547"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=e520b5ce0b6d4ccf46f4205ea68e2363105b8458"
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
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "G=%OJ_REPO%\godot"
set "P=res://tools/probes/close_action_1524_shots.gd"
set "ST=PC, real hulls, pin %2"
set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%G%" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0
set "JW_CONTINUE=1"
rem ---- strips: battle 1 (scenario s1), a window (GPU), each look at cameras 110 and 170
for %%C in (110 170) do for %%L in (r0 A B C) do call :strip %1 %%L %%C
rem ---- clips at camera 170: B (the pick) and r0 (before)
call :clip %1 B
call :clip %1 r0
rem ---- the timing and effect checks on the GPU build
set "JW_STEP=%1 moments" & set "JW_EXPECT=%O%\moments.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%G%" --script res://fx/test/close_action_moments_check.gd > "%O%\moments.txt" 2>&1
set "JW_STEP=%1 fx check" & set "JW_EXPECT=%O%\fx_check.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%G%" --script res://fx/test/close_action_fx_check.gd > "%O%\fx_check.txt" 2>&1
call :result
exit /b 0

:strip
set "S=%O%\c%3_%2"
if not exist "%S%" mkdir "%S%"
set "JW_STEP=%1 strip %2 c%3" & set "JW_EXPECT=%S%\BRD-1547-%2_after.jpg" & call "%JW%" run 900 "%JW_GODOT%" --path "%G%" --script %P% -- --scenario s1 --out "%S%" --arm after --items BRD --cam %3 --look %2 --stage "%ST%" > "%S%\strip.txt" 2>&1
if exist "%S%\BRD-1547-%2_after.jpg" copy /y "%S%\BRD-1547-%2_after.jpg" "%O%\BRD-1547-%2_c%3.jpg" > nul
exit /b 0

:clip
set "C=%O%\clip_%2"
if not exist "%C%" mkdir "%C%"
set "JW_STEP=%1 clip %2" & set "JW_EXPECT=%O%\BRD-1547-%2.avi" & call "%JW%" run 1800 "%JW_GODOT%" --path "%G%" --write-movie "%O%\BRD-1547-%2.avi" --fixed-fps 30 --script %P% -- --scenario s1 --out "%C%" --arm after --items BRD --cam 170 --look %2 --stage "%ST%" > "%O%\clip_%2.txt" 2>&1
set "JW_STEP=%1 mp4 %2" & set "JW_EXPECT=%O%\BRD-1547-%2.mp4" & call "%JW%" run 600 "%JW_FFMPEG%" -y -i "%O%\BRD-1547-%2.avi" -vf scale=-2:720 -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p "%O%\BRD-1547-%2.mp4" > "%O%\mp4_%2.txt" 2>&1
if exist "%O%\BRD-1547-%2.mp4" if exist "%O%\BRD-1547-%2.avi" del /q "%O%\BRD-1547-%2.avi"
exit /b 0

:result
set "R=%O%\result.txt"
> "%R%" echo [1547] job %JOB% pin %PIN_NEW% stage "%ST%"
set "BAD=0"
for %%F in (BRD-1547-r0_c110.jpg BRD-1547-A_c110.jpg BRD-1547-B_c110.jpg BRD-1547-C_c110.jpg BRD-1547-r0_c170.jpg BRD-1547-A_c170.jpg BRD-1547-B_c170.jpg BRD-1547-C_c170.jpg BRD-1547-B.mp4 BRD-1547-r0.mp4) do (
	if exist "%O%\%%F" (
		set "SZ=%%~zF"
		for %%Z in ("%O%\%%F") do set "SZ=%%~zZ"
		if /i "%%~xF"==".mp4" if !SZ! GTR 10485760 (>> "%R%" echo FAIL %%F !SZ! bytes, over 10 MB& set "BAD=1")
		if !SZ! LEQ 10485760 >> "%R%" echo PASS %%F !SZ! bytes
		if /i not "%%~xF"==".mp4" if !SZ! GTR 10485760 >> "%R%" echo PASS %%F !SZ! bytes
	) else (>> "%R%" echo MISSING %%F& set "BAD=1")
)
findstr /c:"CLOSE_ACTION_MOMENTS PASS" "%O%\moments.txt" > nul && (>> "%R%" echo PASS moments) || (>> "%R%" echo FAIL moments, see moments.txt& set "BAD=1")
findstr /c:"CLOSE_ACTION_FX PASS" "%O%\fx_check.txt" > nul && (>> "%R%" echo PASS fx check) || (>> "%R%" echo FAIL fx check, see fx_check.txt& set "BAD=1")
if "!BAD!"=="0" (>> "%R%" echo [1547] RESULT PASS) else (>> "%R%" echo [1547] RESULT FAIL& call "%JW%" fail "1547: see out_new\result.txt")
exit /b 0
