@echo off
rem Issues 1524 and 1461 (SHOTS2, replaces OPUS1524_SHOTS): before and after of the three close actions in the real
rem battle scene on the PC (GPU, real hulls). OLD is the probe r2 commit with main's battle.gd; NEW is the wiring.
rem Per arm (out_old = before, out_new = after):
rem   RAM-1524_<arm>.jpg, BRD-1524_<arm>.jpg, CMD-1524_<arm>.jpg: a 2 by 2 strip of four moments, code name on it, 720 px
rem   RAM-FX_<arm>.mp4, BRD-FX_<arm>.mp4, CMD-FX_<arm>.mp4: one clip per moment at camera 170, 30 fps, 720 px tall
rem   (Godot movie maker, so the clip runs on the game clock; the .avi it writes is kept beside the .mp4)
rem   moments_after.txt (new arm only): the timing and sound check (close_action_moments_check.gd) on the GPU build
rem Made from tools/pc/jobs/opus_job_template.bat. Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1524b"
set "LABEL=1524"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=3ea515ef72f7adc3e0839cf80871bb7f2858311a"
set "PIN_OLD=0a9fe7c056f82b31ba3917432a3bfbb7b93b4496"

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
set "G=%OJ_REPO%\godot"
set "P=res://tools/probes/close_action_1524_shots.gd"
set "ST=PC, installed in game, pin %2"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%G%" --import > "%O%\import.txt" 2>&1
rem ---- strips: battle 1 (scenario s1), a window (GPU), camera 110
set "JW_STEP=%1 strips" & set "JW_EXPECT=%O%\CMD-1524_%3.jpg" & call "%JW%" run 900 "%JW_GODOT%" --path "%G%" --script %P% -- --scenario s1 --out "%O%" --arm %3 --cam 110 --stage "%ST%" > "%O%\strips.txt" 2>&1
rem ---- clips: one launch per moment, camera 170, movie maker at 30 fps, then a 720 px mp4
call :clip %1 %3 RAM
call :clip %1 %3 BRD
call :clip %1 %3 CMD
rem ---- the timing and sound check, new commit only (the old commit has no such file, and its code fails it by design)
if not "%1"=="new" exit /b 0
set "JW_STEP=%1 moments" & set "JW_EXPECT=%O%\moments_%3.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%G%" --script res://fx/test/close_action_moments_check.gd > "%O%\moments_%3.txt" 2>&1
exit /b 0

:clip
set "C=%O%\clip_%3"
if not exist "%C%" mkdir "%C%"
set "JW_STEP=%1 clip %3" & set "JW_EXPECT=%O%\%3-FX_%2.avi" & call "%JW%" run 1800 "%JW_GODOT%" --path "%G%" --write-movie "%O%\%3-FX_%2.avi" --fixed-fps 30 --script %P% -- --scenario s1 --out "%C%" --arm %2 --items %3 --cam 170 --stage "%ST%" > "%O%\clip_%3.txt" 2>&1
set "JW_STEP=%1 mp4 %3" & set "JW_EXPECT=%O%\%3-FX_%2.mp4" & call "%JW%" run 600 "%JW_FFMPEG%" -y -i "%O%\%3-FX_%2.avi" -vf scale=-2:720 -c:v libx264 -crf 20 -pix_fmt yuv420p "%O%\%3-FX_%2.mp4" > "%O%\mp4_%3.txt" 2>&1
exit /b 0
