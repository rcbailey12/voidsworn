@echo off
rem Issue 1767 (Artoo on PR 1772): fresh-process cost of a dense graveyard on the live board, old main against the PR
rem head. graveyard_load_probe.gd (beside this bat) is copied into godot\bench of each pinned checkout as an untracked
rem file (no tracked file changes) and run 3 times per commit, alternating old and new, each a fresh Godot process
rem through job_wrap at 1920x1080 Forward+. Each run prints one GRAVEYARD_LOAD line: board.build ms, first frame ms,
rem process ms, Godot static peak MB, video MB, Windows peak working set MB. summary.txt collects the six lines.
rem Queue after OPUS1767_PROPS_D. Built from opus_job_template.bat.
setlocal EnableExtensions
set "JOB=opus1767load"
set "LABEL=1767"
set "TOOLS=godot"
set "PIN_NEW=6458df0e75e67b85c237cd2a0a90e03dc9b5a3f3"
set "PIN_OLD=cf005360279fd4874f41d8d9ec9ee7b877db9bd5"
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"
set "PROBE=%~dp0graveyard_load_probe.gd"
if not exist "%PROBE%" (echo FAILED: graveyard_load_probe.gd must sit beside this bat & exit /b 2)

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

call :prep old %PIN_OLD%
set "REPO_OLD=%OJ_REPO%"
call :prep new %PIN_NEW%
set "REPO_NEW=%OJ_REPO%"
for %%i in (1 2 3) do (
  call :probe old "%REPO_OLD%" %%i
  call :probe new "%REPO_NEW%" %%i
)
> "%OJ_OUT%\summary.txt" echo old=%PIN_OLD% new=%PIN_NEW%
for %%n in (old new) do for %%i in (1 2 3) do (
  for /f "delims=" %%L in ('findstr /c:"GRAVEYARD_LOAD" "%OJ_OUT%\out_%%n\probe_%%i.txt"') do >> "%OJ_OUT%\summary.txt" echo %%n %%i %%L
)
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, the probe copied in, import
:prep
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
copy /y "%PROBE%" "%OJ_REPO%\godot\bench\graveyard_load_probe.gd" > nul || (call "%JW%" fail "%1 probe copy" & exit /b 1)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
exit /b 0

rem ---- one fresh process
:probe
set "O=%OJ_OUT%\out_%1"
set "JW_STEP=%1 graveyard load %3" & set "JW_EXPECT=%O%\probe_%3.txt" & call "%JW%" run 600 "%JW_GODOT%" --path "%~2\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://bench/graveyard_load_probe.gd > "%O%\probe_%3.txt" 2>&1
findstr /c:"GRAVEYARD_LOAD" "%O%\probe_%3.txt" > nul || call "%JW%" fail "%1 run %3 printed no GRAVEYARD_LOAD line"
exit /b 0
