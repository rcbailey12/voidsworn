@echo off
rem Issue 1659 proof C of 3 (right after B, same watcher). Before its own checkout it saves slot_gpu_1's owner.txt as B
rem left it (B's token, a "released" line from B's tail), then takes a slot. Done when: owner_before.txt has B's attempt
rem and a released line, and C's slots_used.txt names slots\slot_gpu_1 (the slot B's dead holder had, freed by the tail
rem while the same watcher shell kept running: compare the "job process" lines of owner_before.txt and C's owner.txt).
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, a fresh checkout or warm slot per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1659slotc"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1659"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=478c28ddabe346891c845b176a236815b33ff0e6"
set "PIN_OLD="
rem Issue 1659: OJ_SLOTS=1 resets a warm slot (voidsworn_test\slots) instead of a fresh clone per attempt. Off until the
rem Board turns it on after the Windows proof (Artoo on PR 1728). OJ_SLOT_KIND is gpu (slot_gpu_1 or slot_gpu_2) for
rem anything that renders, cpu (slot_cpu) for headless-only checks.
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

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

rem the slot as B left it, before this job takes one
if not exist "%OJ_OUT%" mkdir "%OJ_OUT%"
copy /y "%VT%\slots\slot_gpu_1\owner.txt" "%OJ_OUT%\owner_before.txt" > nul
call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS: record which slot and pin this checkout used, for the proof log
copy /y "%OJ_OUT%\slots.txt" "%O%\slots_used.txt" > nul
copy /y "%VT%\slots\slot_gpu_1\owner.txt" "%O%\owner_after.txt" > nul
exit /b 0
