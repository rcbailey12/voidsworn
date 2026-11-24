@echo off
rem Issue 1236 wrecks, SEAMS1 (read only, no GPU work). The WRECK5c clip showed the round 4 three-piece breakup on only one
rem of ten rows: the real hulls mostly kept one joint. This job prints each installed hull's authored transverse joints
rem along its length (0 stern, 1 bow) so the joint choice can be fixed against the real ships. One pin: b716bed0
rem (WRECK5c's after 184f94a7 plus godot/bench/seam_dump_1236.gd), reachable from claude/project-thread-q7nudv. Writes
rem out_new\seams_1236.json and out_new\seams_log.txt. Headless; nothing on the PC is deleted. Built from
rem tools/pc/jobs/opus_job_template.bat (the OPUS1587_WOUNDS4 layout).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1236seams"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1236"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=b716bed0b22047774fa7d47ba6a9407997a37a2e"
set "PIN_OLD="

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
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

rem The old pin first, as WRECK4
if defined PIN_OLD call :one old %PIN_OLD%
call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS (issue 1236 SEAMS1): the dump, headless
if not exist "%OJ_REPO%\godot\bench\seam_dump_1236.gd" (call "%JW%" fail "%1 seam dump script missing" & exit /b 1)
set "SEAM_OUT=%O%\seams_1236.json"
set "JW_STEP=%1 seams" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://bench/seam_dump_1236.gd > "%O%\seams_log.txt" 2>&1
findstr /c:"SEAM_DUMP_DONE" "%O%\seams_log.txt" > nul || call "%JW%" fail "%1 seam dump did not finish (see %O%\seams_log.txt)"
exit /b 0
