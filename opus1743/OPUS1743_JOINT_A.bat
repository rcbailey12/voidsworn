@echo off
rem R421 joint sheet (issue 1743, with 1741 PR 1755 and 1777 PR 1786): the six reference hulls with their painted
rem Interior Kit V2 exports (V16_37, H10_23, C19_51, B21_11, I15_11, D21_23), each intact, breached (three hits, 50% hull)
rem and broken (death, 4 s and 6 s), at cameras 170 and 26, with VS_WOUNDS_V2=1 and VS_SHIP_LOOK_V2=1, on ONE commit:
rem the scratch branch claude/project-thread-kzjmk5 that merges 1763 (e1153b84), 1755 (b60983b2), 1786 (a8b3cb20) and main.
rem The painted exports come from the private relay repo (voidsworn-relay, same branch name, pinned commit); every file is
rem checked against contrib/opus/joint_1743/SHA256SUMS.txt in the pinned checkout before anything is copied. Deletes
rem nothing: older damage and wreck glbs are moved aside inside the job checkout. Built from opus_job_template.bat.
rem Queue only after green checks and a passed review (R407). Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1743joint"
set "LABEL=1743"
set "TOOLS=godot pil"
set "PIN_NEW=2ffa5fd8ae989c9e776c8e905e29c97942071b70"
set "PIN_OLD="
set "RELAY_URL=https://github.com/rcbailey12/voidsworn-relay"
set "RELAY_BRANCH=claude/project-thread-kzjmk5"
set "RELAY_PIN=e1a13417dc7a447c9cec56e807db15d84a0365fe"
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"

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
call "%HEAD%" ships
set "O=%OJ_OUT%\out_joint"
if not exist "%O%" mkdir "%O%"
if not exist "%OJ_REPO%\godot\bench\look_moments_joint_1743.json" (call "%JW%" fail "rows file missing" & call "%HEAD%" tail & exit /b 1)

rem ---- the painted exports: a shallow clone of the relay branch, then the commit must be the pin (fail closed)
set "RL=%OJ_OUT%\relay_joint1743"
if exist "%RL%" (call "%JW%" fail "relay folder %RL% already exists" & call "%HEAD%" tail & exit /b 1)
set "JW_STEP=relay clone" & call "%JW%" run 1800 git -c core.autocrlf=false clone --depth 1 --branch %RELAY_BRANCH% %RELAY_URL% "%RL%" > "%O%\relay_git.txt" 2>&1
set "RLHEAD="
if exist "%RL%\.git" for /f %%H in ('git -C "%RL%" rev-parse HEAD') do set "RLHEAD=%%H"
> "%O%\relay_head.txt" echo relay HEAD %RLHEAD%, pin %RELAY_PIN%
if not "%RLHEAD%"=="%RELAY_PIN%" call "%JW%" fail "relay branch is not at %RELAY_PIN% (see %O%\relay_head.txt)"
set "JW_STEP=install painted exports" & set "JW_EXPECT=%O%\install.txt" & call "%JW%" run 900 "%JW_PIL%" -B "%OJ_REPO%\contrib\opus\joint_1743\install_joint.py" "%RL%\joint1743" "%OJ_REPO%\godot" > "%O%\install.txt" 2>&1
findstr /c:"JOINT INSTALL PASS" "%O%\install.txt" > nul || call "%JW%" fail "painted exports not installed (see %O%\install.txt)"

rem ---- stage 7's import, ships-only cache rebuild and one install readback per hull
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=ship cache" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://render/build_assets.gd -- --ships-only > "%O%\ships_cache.txt" 2>&1
findstr /c:"[assets] ships refreshed" "%O%\ships_cache.txt" > nul || call "%JW%" fail "ship cache not refreshed (see %O%\ships_cache.txt)"
for %%C in (V16_37 H10_23 C19_51 B21_11 I15_11 D21_23) do call :readback %%C

rem ---- the sheet: both switches on, every joint row at cameras 170 and 26
set "VS_WOUNDS_V2=1"
set "VS_SHIP_LOOK_V2=1"
set "JW_STEP=joint bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 3000 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_joint_1743.json --commit %PIN_NEW% > "%O%\bench_log.txt" 2>&1
set "VS_WOUNDS_V2=" & set "VS_SHIP_LOOK_V2="
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "bench did not finish (see %O%\bench_log.txt)"
findstr /c:"LOOK_BENCH CODE MISMATCH" "%O%\bench_log.txt" > nul && call "%JW%" fail "a row drew the wrong hull (see %O%\bench_log.txt)"
findstr /c:"SCRIPT ERROR" "%O%\bench_log.txt" > nul && call "%JW%" fail "script errors in the bench (see %O%\bench_log.txt)"
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:readback
set "JW_STEP=readback %1" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://render/test/installed_ship_check.gd -- %1 > "%O%\readback_%1.txt" 2>&1
findstr /c:"INSTALL READBACK PASS code=%1 " "%O%\readback_%1.txt" > nul || call "%JW%" fail "the game does not draw the new %1 (see %O%\readback_%1.txt)"
exit /b 0
