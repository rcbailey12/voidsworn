@echo off
rem Issue 1316 drive glow proof 2 (replaces DRIVE1: its run B hung 60 minutes inside the NEW bench before writing any
rem row, with no line saying which). The same bench and rows run in the cloud to LOOK_BENCH_DONE (old meshes), so the hang
rem is PC side, most likely the new CD5 build. Proof 2 runs each row as its own bench start (--only <row>, 1200 s ceiling,
rem a failing row fails the job but the next rows still run), Eclipse and I11_37 first, CD5 last, so the log names the
rem row that hangs and the other rows still deliver pictures. Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303).
rem The look bench with effects on, rows godot/bench/look_moments_1316.json (on the NEW pin): ships at full burn
rem ("engine": 1.6), cameras 170, 60 and 26 (170 is the 1 to 1 battle crop):
rem   CD5 (I8_37, new build) on its engines and the whole ship; I11_37 Destroyer (old A4 hull) on its engines;
rem   D20_23 Eclipse Destroyer on its engines in the same light, to compare the violet.
rem NEW (PR 1348): violet Glasswright drive, no corona. OLD (main): the same rows file copied in from NEW (main does
rem not track it), today's pale drive with the silver corona. Then look_bench_sheets.py (from NEW) makes the stamped
rem before (top) and after (bottom) sheets with a difference number per still. GPU shared.
rem Every Godot start runs in the watchdog's throwaway profile; Ryan's options are hashed before and after by the head.
rem Each row writes out_<arm>\bench_<row>\; sheets\<row>\ holds its before and after sheet.
rem Results: Downloads\voidsworn_test\opus1316\out_<stamp>_<n>\sheets\. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1316"
set "LABEL=1316"
set "TOOLS=godot pil"
set "PIN_NEW=ed0dde7e530b075d4fb3c085d06eeccbaacc7889"
set "PIN_OLD=7f13c84701b4866d92d585bd64ec37e7c46321f8"
set "OJ_NEED_HULLS=I8_37 I11_37 D20_23"

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
set "ROWS=g1316_eclipse_engines g1316_i11_engines g1316_cd5_engines g1316_cd5_ship"
call :one new %PIN_NEW%
set "NEWREPO=%OJ_REPO%"
call :one old %PIN_OLD%
for %%R in (%ROWS%) do call :sheet %%R
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then one bench start per row. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if /i "%1"=="old" (
  copy /y "%NEWREPO%\godot\bench\look_moments_1316.json" "%OJ_REPO%\godot\bench\look_moments_1316.json" > nul
  if not exist "%OJ_REPO%\godot\bench\look_moments_1316.json" (call "%JW%" fail "old: rows copy from %NEWREPO%" & exit /b 1)
)
for %%R in (%ROWS%) do call :row %1 %2 %%R
exit /b 0

:row
if defined JW_STOP exit /b 0
set "PC_GPU_MODE=shared"
set "JW_CONTINUE=1" & set "JW_STEP=%1 bench %3" & set "JW_EXPECT=%O%\bench_%3\bench.json" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --disable-vsync res://bench/look_bench.tscn -- --out "%O%\bench_%3" --part moments --moments res://bench/look_moments_1316.json --only %3 --commit %2 > "%O%\bench_%3_log.txt" 2>&1
set "PC_GPU_MODE="
exit /b 0

rem ---- one row's stamped before and after sheet (the sheet maker from the NEW pin, Pillow from the preflight); a row
rem missing on either side is skipped with a note (its bench step already failed the job)
:sheet
if not exist "%OJ_OUT%\out_new\bench_%1\bench.json" (call "%JW%" note "sheet %1 skipped: no new bench" & exit /b 0)
if not exist "%OJ_OUT%\out_old\bench_%1\bench.json" (call "%JW%" note "sheet %1 skipped: no old bench" & exit /b 0)
set "JW_CONTINUE=1" & set "JW_STEP=sheet %1" & set "JW_EXPECT=%SH%\%1\summary.txt" & call "%JW%" run 600 "%JW_PIL%" "%NEWREPO%\tools\pc\jobs\look_bench_sheets.py" --before "%OJ_OUT%\out_old\bench_%1" --after "%OJ_OUT%\out_new\bench_%1" --out "%SH%\%1" --label-before "main 7f13c847 (pale drive, silver corona)" --label-after "PR 1348 ed0dde7e (violet drive, no corona)"
exit /b 0
