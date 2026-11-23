@echo off
rem Issue 1739 diagnosis E (Board, for a proven root cause): runner_selftest under a lane-shaped long TEMP and a short TEMP,
rem on main d872fb17 (old) and on the PR 1793 head 81a6b40e (new). Code only, no GPU, no Codex usage, deletes nothing.
rem Each run prints its whole output and the longest path its fixture created (RUNNER_SELFTEST_KEEP=1 keeps the evidence).
rem Done when: out_new and out_old each hold runner_long.txt, runner_short.txt and longest_long.txt, longest_short.txt; the Board relays the attempt folder.
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, a fresh checkout or warm slot per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1739diage"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1739"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=node"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=81a6b40e27dc5ac4af5acdd150df5dee609d2d6b"
set "PIN_OLD=d872fb177cbb574044415e22ec1173549759a5e5"
rem Issue 1659: OJ_SLOTS=1 resets a warm slot (voidsworn_test\slots) instead of a fresh clone per attempt. Off until the
rem Board turns it on after the Windows proof (Artoo on PR 1728). OJ_SLOT_KIND is gpu (slot_gpu_1 or slot_gpu_2) for
rem anything that renders, cpu (slot_cpu) for headless-only checks.
set "OJ_SLOTS=0"
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
set "LONGEST=const fs=require('fs'),p=require('path');let roots=[];for(const d of process.argv.slice(1)){try{for(const n of fs.readdirSync(d)){if(n.startsWith('runner687 proof ')){const q=p.join(d,n);roots.push([fs.statSync(q).mtimeMs,q])}}}catch(e){}}roots.sort((a,b)=>b[0]-a[0]);if(!roots.length){console.log('no runner687 proof folder found');process.exit(0)}const root=roots[0][1];let best='',count=0;function walk(d){let es;try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){console.log('unreadable: '+d+' '+e.code);return}for(const e of es){const q=p.join(d,e.name);count++;if(q.length>best.length)best=q;if(e.isDirectory())walk(q)}}walk(root);console.log('root '+root.length+' chars: '+root);console.log('entries '+count);console.log('longest '+best.length+' chars: '+best);console.log('over 259 chars: '+(best.length>259))"
rem ---- STEPS: one lane-shaped scratch (Temp\voidsworn-run-1667-<32 hex>, as codex_issue.bat makes it), then the pair.
rem The fixture keeps its evidence (RUNNER_SELFTEST_KEEP=1); this job deletes nothing, so up to four small
rem "runner687 proof" folders and the empty scratch stay in Temp for the janitor or Ryan.
set "REAL_TEMP=%TEMP%"
set "HEX="
for /f %%G in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString([string][char]78)"') do set "HEX=%%G"
if not defined HEX (echo FAILED: no scratch name > "%O%\runner_long.txt" & exit /b 0)
set "LANE_TEMP=%REAL_TEMP%\voidsworn-run-1667-%HEX%"
mkdir "%LANE_TEMP%"
echo real TEMP %REAL_TEMP% > "%O%\temps.txt"
echo lane TEMP %LANE_TEMP% >> "%O%\temps.txt"
pushd "%OJ_REPO%"
git log -1 --format=%%H >> "%O%\temps.txt" 2>&1
set "RUNNER_SELFTEST_KEEP=1"
set "TEMP=%LANE_TEMP%" & set "TMP=%LANE_TEMP%" & set "TMPDIR=%LANE_TEMP%"
set "JW_STEP=runner_long" & set "JW_OPTIONAL=1" & call "%JW%" run 900 "%JW_NODE%" tools\pc\runner_selftest.js > "%O%\runner_long.txt" 2>&1
set "TEMP=%REAL_TEMP%" & set "TMP=%REAL_TEMP%" & set "TMPDIR=%REAL_TEMP%"
"%JW_NODE%" -e "%LONGEST%" "%LANE_TEMP%" "%REAL_TEMP%" > "%O%\longest_long.txt" 2>&1
set "JW_STEP=runner_short" & set "JW_OPTIONAL=1" & call "%JW%" run 900 "%JW_NODE%" tools\pc\runner_selftest.js > "%O%\runner_short.txt" 2>&1
"%JW_NODE%" -e "%LONGEST%" "%REAL_TEMP%" > "%O%\longest_short.txt" 2>&1
set "RUNNER_SELFTEST_KEEP="
popd
exit /b 0
