@echo off
rem Issue 1982 / 1645 R4STALL (Board, Nov 24 14:23 UTC): the round 4 Hullbreaker stall before and after PR 2004 (merged at
rem efabe897). Solo GPU (frame-time rule). Before = main at efabe897's first parent 84a2557c, after = main at efabe897.
rem Each side: one checkout, ships, import, then the 1558A frame-time run as it was first measured on the PC
rem (wait1558\OPUS1558_FT.bat step A: battle.tscn --torp-ft --fac corsair --obj ambush --map open --seed 7 --movement
rem brisk --quit-after 900, 1920x1080, twice), through r4stall_wrap.gd (beside this bat, copied into the job's own
rem checkout as bench\_r4stall_wrap.gd, never committed) so every frame of each --torp-ft record (r4_x09, r4_x05 and the
rem rest) is kept. Then r4stall_report.py: R4STALL_table.md (worst, p99, the stall frame in ms) and one R4STALL_<record>.png
rem frame-time graph per record. Nothing on the PC is deleted. Built from tools/pc/jobs/opus_job_template.bat.
setlocal EnableExtensions
set "JOB=r4stall"
set "LABEL=1982"
set "TOOLS=godot pil"
set "PIN_NEW=efabe897157b8cb7fe1acff1a950e7eb5c92acc8"
set "PIN_OLD=84a2557c0e2b55fa22f21bcf3551a38055451269"
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
set "R4_HERE=%~dp0"

set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
if not exist "%R4_HERE%r4stall_wrap.gd" (echo FAILED: r4stall_wrap.gd missing beside the bat & exit /b 2)
if not exist "%R4_HERE%r4stall_report.py" (echo FAILED: r4stall_report.py missing beside the bat & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one old %PIN_OLD%
call :one new %PIN_NEW%
copy /y "%R4_HERE%r4stall_wrap.gd" "%OJ_OUT%\r4stall_wrap.gd" > nul
copy /y "%R4_HERE%r4stall_report.py" "%OJ_OUT%\r4stall_report.py" > nul
set "JW_STEP=R4STALL report" & set "JW_CONTINUE=1" & set "JW_EXPECT=%OJ_OUT%\R4STALL_table.md;%OJ_OUT%\R4STALL_r4_x09.png;%OJ_OUT%\R4STALL_r4_x05.png" & call "%JW%" run 300 "%JW_PIL%" "%OJ_OUT%\r4stall_report.py" "%OJ_OUT%" r4_x09,r4_x05 > "%OJ_OUT%\report_log.txt" 2>&1
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the two frame-time runs. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
copy /y "%R4_HERE%r4stall_wrap.gd" "%OJ_REPO%\godot\bench\_r4stall_wrap.gd" > nul
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "VS_1379_PD="
set "VS_1379_OLD="
for %%N in (1 2) do (
  if not exist "%O%\ft_corsair_7_%%N" mkdir "%O%\ft_corsair_7_%%N"
  set "JW_STEP=%1 ft corsair_7 %%N" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\ft_corsair_7_%%N\r4stall_frames.json" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 --script res://bench/_r4stall_wrap.gd -- --torp-shots "%O%\ft_corsair_7_%%N" --torp-ft --fac corsair --obj ambush --map open --seed 7 --movement brisk --quit-after 900 > "%O%\ft_corsair_7_%%N\run.txt" 2>&1
)
exit /b 0
