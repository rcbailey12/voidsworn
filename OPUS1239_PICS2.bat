@echo off
rem Issue 1239 pictures 2 (replaces OPUS1239_PICS1; Artoo on PR 1329: no own GitHub clone or hand-rolled copies, the
rem shared head's mirror checkout, ship identity per arm, I8_37 and H4_11 required). Built from
rem tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303).
rem NEW (the fix, PR 1329): 1. the collapse pace sheet for Ryan ("close the shield collapse by like 50, 75 or 100%"):
rem today's 0.70 s and 1.05, 1.225 and 1.40 s, a row each, for i_boss (CD5, I8_37) and h_boss (H4_11), fitted shield,
rem camera 60, with clip frames; 2. the hand-off "after" stills (shoulder break, lethal break, torpedo salvo).
rem OLD (main): the same probe copied in from NEW under a name main does not track, the "before" stills, then the
rem before and after sheets. mp4s from the clip frames when an ffmpeg is found (optional). GPU shared.
rem Every Godot start runs in the watchdog's throwaway profile; Ryan's options are hashed before and after by the head.
rem Results: Downloads\voidsworn_test\opus1239\out_<stamp>_<n>\sheets\. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1239"
set "LABEL=1239"
set "TOOLS=godot"
set "PIN_NEW=bb7ed70fb6cb7da5d5b6571a8b0b773a9fd9cfe6"
set "PIN_OLD=dd86803ccb78b9109cfd27cee1fbb2b6856e3d0d"
set "OJ_NEED_HULLS=I8_37 H4_11"
set "PROBE_SUBJECTS=i_boss,h_boss"

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

set "SH=%OJ_OUT%\sheets"
if not exist "%SH%" mkdir "%SH%"
call :one new %PIN_NEW%
set "NEWREPO=%OJ_REPO%"
call :one old %PIN_OLD%
call :clips
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then this arm's passes. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "PC_GPU_MODE=shared"
if /i "%1"=="new" (
  set "PROBE_OUT=%O%\pace" & set "PROBE_PACE=1"
  set "JW_STEP=new pace" & set "JW_EXPECT=%O%\pace\shield1239_pace.json" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://fx/test/shield_handoff_probe.gd > "%O%\pace_log.txt" 2>&1
  set "PROBE_PACE="
  copy /y "%O%\pace\SHIELD1239_*.png" "%SH%\" > nul 2>&1
  set "PROBE_OUT=%OJ_OUT%\handoff" & set "PROBE_TAG=after"
  set "JW_STEP=new after" & set "JW_EXPECT=%OJ_OUT%\handoff\handoff_after\shield1239.json" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://fx/test/shield_handoff_probe.gd > "%O%\after_log.txt" 2>&1
)
if /i "%1"=="old" (
  copy /y "%NEWREPO%\godot\fx\test\shield_handoff_probe.gd" "%OJ_REPO%\godot\fx\test\shield1239_main_probe.gd" > nul
  if not exist "%OJ_REPO%\godot\fx\test\shield1239_main_probe.gd" (call "%JW%" fail "old: probe copy from %NEWREPO%" & exit /b 1)
  set "PROBE_OUT=%OJ_OUT%\handoff" & set "PROBE_TAG=before"
  set "JW_STEP=old before" & set "JW_EXPECT=%OJ_OUT%\handoff\handoff_before\shield1239.json" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://fx/test/shield1239_main_probe.gd > "%O%\before_log.txt" 2>&1
  set "PROBE_TAG="
  set "PROBE_OUT=%SH%" & set "PROBE_COMPOSE=%OJ_OUT%\handoff\handoff_before;%OJ_OUT%\handoff\handoff_after"
  set "JW_STEP=sheets" & set "JW_EXPECT=%SH%\shield1239_compose_done.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://fx/test/shield1239_main_probe.gd > "%O%\compose_log.txt" 2>&1
  set "PROBE_COMPOSE="
)
set "PC_GPU_MODE="
exit /b 0

rem ---- mp4s from the pace clip frames, when an ffmpeg is found (optional: the sheets are the result)
:clips
if defined JW_STOP exit /b 0
set "FF="
if defined FFMPEG_EXE if exist "%FFMPEG_EXE%" set "FF=%FFMPEG_EXE%"
if not defined FF if exist "%VT%\ffmpeg\bin\ffmpeg.exe" set "FF=%VT%\ffmpeg\bin\ffmpeg.exe"
if not defined FF where ffmpeg > nul 2>&1 && set "FF=ffmpeg"
set "CPY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if not exist "%CPY%" set "CPY=%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe"
if not defined FF if exist "%CPY%" for /f "delims=" %%F in ('"%CPY%" -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())" 2^>nul') do set "FF=%%F"
if not defined FF (call "%JW%" note "no ffmpeg found: the pace clip frames stay in out_new\pace" & exit /b 0)
for /d %%D in ("%OJ_OUT%\out_new\pace\clip_*") do (
  "%FF%" -y -loglevel error -framerate 30 -i "%%D\f_%%04d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 20 "%SH%\SHIELD1239_%%~nxD.mp4"
  if errorlevel 1 (call "%JW%" note "clip %%~nxD did not encode") else (call "%JW%" note "clip %%~nxD encoded")
)
exit /b 0
