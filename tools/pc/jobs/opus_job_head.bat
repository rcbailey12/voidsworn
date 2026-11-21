@echo off
rem Issue 1303: one shared head for helper (Opus) PC proof bats. Start from opus_job_template.bat; do not hand-roll these
rem steps. It sits on job_wrap.bat (issue 1194: the canonical tools_live watchdog, a GPU label, preflight, honest done
rem lines) and adds what seven sent-back bats missed on Nov 19 and 20:
rem   init <job> <GPU label> <tools>  refuses unless this head is tools_live\<current.txt>\pc\jobs, the current installed
rem                                   copy (OPUS_JOB_HEAD_PREMERGE=1 only for a smoke before merge, logged; job_wrap then
rem                                   still comes from the current tools_live); clears job_wrap's test settings; after
rem                                   job_wrap init, verifies head and watchdog against that version's hashes.txt; makes a
rem                                   new attempt folder
rem                                   Downloads\voidsworn_test\<job>\out_<stamp>_<n> (never reused); job_wrap init; logs the
rem                                   path and sha256 of tools_live tmo.bat and run_timeout.ps1 (fail closed if either is
rem                                   missing); keeps the watchdog's throwaway Godot profile on (PC_REAL_PROFILE and
rem                                   PC_KEEP_GODOT_PROFILE cleared, issue 1228); hashes Ryan's real battle_opts.json and
rem                                   board_look.cfg. Sets OJ_OUT (the attempt folder), OJ_ST (its status.txt), JW, JW_GODOT.
rem   checkout <name> <40-hex sha>    a fresh checkout of that exact commit in OJ_OUT\<name> from the shared mirror; HEAD
rem                                   must equal the pin. Sets OJ_REPO.
rem   ships                           copies built hulls from LB_SHIPS (default build\godot) into OJ_REPO: gen whole with
rem                                   /E (gen\manifest.json must arrive), assets\ships with /E /XC /XN /XO /XF
rem                                   manifest.json README.md a4_props.gd *.uid /XD test previews; robocopy 8 or more fails,
rem                                   then fails if any tracked file in OJ_REPO differs from the pin, or if any copied
rem                                   ship's glb stamp differs from its gen cache (a publish during the copy); the
rem                                   measured hulls are listed in <OJ_REPO>_ships_identity.txt. Every checkout in a job
rem                                   must list the same hulls as the first one. Optional OJ_NEED_HULLS: codes that
rem                                   must be among the matching ships.
rem   (after init, every job_wrap step runs the watchdog verified at init: TMO_OWN_COPY=1 on that version's tmo.bat)
rem   tail                            hashes Ryan's options again (a change fails the job), then job_wrap end: "done
rem                                   PASS" or "done FAILED: ...", then "all done". Exit 0 only on PASS. After that,
rem                                   a PASS removes the job's own pinned checkouts, saving any small file the job left
rem                                   in one into out_<name>\checkout_leftovers first (issue 1497); a failure keeps them
rem                                   a day; earlier attempts of the job are cleared the same way; the GB freed and C:
rem                                   free go to status.txt (out_* and logs stay; OJ_KEEP_CHECKOUTS=1 keeps them).
rem Every Godot start in the job goes through: set "JW_STEP=<name>" & call "%JW%" run <seconds> "%JW_GODOT%" ...
rem The tail removes only the job's own pinned checkouts (RULEBOOK 3.3, R326); nothing else is deleted. The after-job janitor runs only when OPUS_JOB_JANITOR=1 (off by default; Ryan approves turning it on).
if /i "%~1"=="init" goto oj_init
if /i "%~1"=="checkout" goto oj_checkout
if /i "%~1"=="ships" goto oj_ships
if /i "%~1"=="tail" goto oj_tail
echo opus_job_head: unknown command "%~1"
exit /b 2

rem ------------------------------------------------------------------ init <job> <GPU label> <tools>
:oj_init
set "OJ_VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OJ_PS=%~dp0opus_job_head.ps1"
set "OJ_JOB=%~2"
set "OJ_OUT="
set "OJ_REPO="
echo %OJ_JOB%| findstr /r /x "[A-Za-z0-9_-][A-Za-z0-9_-]*" > nul
if errorlevel 1 (echo opus_job_head: job name not accepted: "%OJ_JOB%" & exit /b 2)
rem The head itself must be the installed main copy, so every job runs the same reviewed steps.
set "OJ_HERE=%~dp0"
set "OJ_TLV="
if exist "%OJ_VT%\tools_live\current.txt" set /p OJ_TLV=<"%OJ_VT%\tools_live\current.txt"
if not defined OJ_TLV (echo opus_job_head: refused, no tools_live\current.txt & exit /b 2)
set "OJ_LIVE="
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" live "%OJ_HERE%." > nul 2>&1
if not errorlevel 1 set "OJ_LIVE=1"
if not defined OJ_LIVE if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo opus_job_head: refused, this head is not the tools_live copy: %OJ_HERE% & exit /b 2)
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "OJ_STAMP=%%S"
set "OJ_OUT=%OJ_VT%\%OJ_JOB%\out_%OJ_STAMP%_%RANDOM%"
if exist "%OJ_OUT%" (echo opus_job_head: attempt folder already exists: %OJ_OUT% & exit /b 2)
set "PC_REAL_PROFILE="
set "PC_KEEP_GODOT_PROFILE="
rem job_wrap's test settings never pass through (Artoo on PR 1305): it resolves tools_live\current.txt itself and checks
rem that version's hashes strictly. No refresh mid-job, so the watchdog stays the version this head was checked against.
set "JW_TOOLS="
set "JW_HASHES="
set "JW_NO_REFRESH=1"
set "JW_NO_JANITOR="
if not "%OPUS_JOB_JANITOR%"=="1" set "JW_NO_JANITOR=1"
set "OJ_PRE=0"
if not defined OJ_LIVE set "OJ_PRE=1"
set "JW=%~dp0..\job_wrap.bat"
if "%OJ_PRE%"=="1" set "JW=%OJ_VT%\tools_live\%OJ_TLV%\pc\job_wrap.bat"
call "%JW%" init "%OJ_OUT%" "%~3" "%~4"
if errorlevel 1 exit /b %ERRORLEVEL%
set "OJ_ST=%JW_ST%"
>> "%OJ_ST%" echo head %~f0
if "%OJ_PRE%"=="1" >> "%OJ_ST%" echo head: OPUS_JOB_HEAD_PREMERGE=1, running a pre-merge copy (smoke only); job_wrap from tools_live
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" bundle "%OJ_HERE%." "%JW_TOOLS%" "%JW_HASHES%" %OJ_PRE% >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "the head and watchdog are not one verified current tools_live version" & call "%JW%" end & exit /b 1)
rem Stay on the bundle verified above for the whole job (Artoo on PR 1305): job_wrap always calls %JW_TOOLS%\tmo.bat, and
rem with TMO_OWN_COPY=1 that tmo.bat runs its own run_timeout.ps1 instead of rereading current.txt, so a tools refresh by
rem another process mid-job cannot switch the watchdog under it. Each step logs the watchdog it used.
set "TMO_OWN_COPY=1"
set "TMO_SAY_WATCHDOG=1"
>> "%OJ_ST%" echo watchdog pinned for this job: %JW_TOOLS%\run_timeout.ps1 (tools_live version %OJ_TLV%)
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" watchdog "%JW_TOOLS%" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "watchdog files missing in %JW_TOOLS%" & call "%JW%" end & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" hashes "%OJ_OUT%\real_options_before.txt" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "could not hash Ryan's real options" & call "%JW%" end & exit /b 1)
>> "%OJ_ST%" echo profile: every Godot start gets a throwaway profile from the watchdog
exit /b 0

rem ------------------------------------------------------------------ checkout <name> <sha>
:oj_checkout
if not defined OJ_OUT (echo opus_job_head: checkout before init & exit /b 2)
if defined JW_STOP (>> "%OJ_ST%" echo skipped checkout %~2: an earlier step failed & exit /b 1)
set "OJ_REPO="
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" checkout "%OJ_OUT%" "%~2" "%~3" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "checkout %~2 %~3" & exit /b 1)
set "OJ_REPO=%OJ_OUT%\%~2"
exit /b 0

rem ------------------------------------------------------------------ ships
:oj_ships
if not defined OJ_REPO (echo opus_job_head: ships before checkout & exit /b 2)
if defined JW_STOP (>> "%OJ_ST%" echo skipped ships: an earlier step failed & exit /b 1)
if not defined LB_SHIPS set "LB_SHIPS=%OJ_VT%\build\godot"
if not exist "%LB_SHIPS%\gen" (call "%JW%" fail "no built ships at %LB_SHIPS%\gen" & exit /b 1)
>> "%OJ_ST%" echo ships from %LB_SHIPS% into %OJ_REPO%
rem The tail's checkout removal proves each copied ship file unchanged against this source.
> "%OJ_OUT%\ships_source.txt" echo %LB_SHIPS%
rem gen is untracked and copied whole with no skip flags, so the source always wins (as get_ship_files.bat does): its
rem manifest.json is what the game reads to find the built hulls. The /XF list is for assets\ships only, where
rem manifest.json is the tracked checksum list (RUN1262C dropped gen\manifest.json and every hull drew as a placeholder).
robocopy "%LB_SHIPS%\gen" "%OJ_REPO%\godot\gen" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OJ_REPO%_ships_gen.txt" 2>&1
if errorlevel 8 (call "%JW%" fail "ships copy gen, see %OJ_REPO%_ships_gen.txt" & exit /b 1)
if not exist "%OJ_REPO%\godot\gen\manifest.json" (call "%JW%" fail "no gen\manifest.json after the ships copy; every hull would draw as a placeholder" & exit /b 1)
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%OJ_REPO%\godot\assets\ships" /E /XC /XN /XO /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OJ_REPO%_ships_assets.txt" 2>&1
if errorlevel 8 (call "%JW%" fail "ships copy assets, see %OJ_REPO%_ships_assets.txt" & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" tracked "%OJ_REPO%" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "tracked files changed by the ships copy in %OJ_REPO%" & exit /b 1)
rem The two copies are separate passes, so a ship published in between would pair a new glb with an old cache
rem (Artoo, PR 1324). Every copied ship must match its cache stamp; the measured hulls go to <repo>_ships_identity.txt.
rem OJ_NEED_HULLS (optional, codes split by spaces) names the hulls the job's fixtures draw; each must be a matching ship.
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" shipcheck "%OJ_REPO%" "%OJ_REPO%_ships_identity.txt" "%OJ_NEED_HULLS%" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "ships do not match their cache in %OJ_REPO%, see %OJ_ST%" & exit /b 1)
rem Issue 1497: the hashes of what was copied, so the tail can prove these files unchanged even after a publish moves
rem build\godot on during the job. A record that cannot be written only means the tail proves less; it never fails the job.
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" shiprecord "%OJ_REPO%" "%OJ_REPO%_ships_copied.txt" >> "%OJ_ST%" 2>&1
if errorlevel 1 >> "%OJ_ST%" echo note: the ships copy record could not be written; the tail proves copies against build\godot only
rem Every checkout in one job must measure the same fleet: a publish between two checkouts (OLD and NEW arms) would
rem give each a self-consistent but different set of hulls (Artoo, PR 1324). The first checkout's identity is the
rem reference; any later one that differs fails the job.
if not exist "%OJ_OUT%\ships_identity_first.txt" (copy /y "%OJ_REPO%_ships_identity.txt" "%OJ_OUT%\ships_identity_first.txt" > nul & exit /b 0)
fc /b "%OJ_OUT%\ships_identity_first.txt" "%OJ_REPO%_ships_identity.txt" > nul 2>&1
if errorlevel 1 (call "%JW%" fail "the hulls in %OJ_REPO% differ from the first checkout's (a ship was published between them), see %OJ_OUT%\ships_identity_first.txt" & exit /b 1)
>> "%OJ_ST%" echo ships in %OJ_REPO% are the same fleet as the first checkout
exit /b 0

rem ------------------------------------------------------------------ tail
:oj_tail
if not defined OJ_OUT (echo opus_job_head: tail before init & exit /b 2)
set "OJ_TLV_NOW="
if exist "%OJ_VT%\tools_live\current.txt" set /p OJ_TLV_NOW=<"%OJ_VT%\tools_live\current.txt"
if not "%OJ_TLV_NOW%"=="%OJ_TLV%" >> "%OJ_ST%" echo note: tools_live moved from %OJ_TLV% to %OJ_TLV_NOW% during the job; every step stayed on %OJ_TLV%
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" hashes "%OJ_OUT%\real_options_after.txt" >> "%OJ_ST%" 2>&1
if errorlevel 1 goto oj_tail_nohash
fc /b "%OJ_OUT%\real_options_before.txt" "%OJ_OUT%\real_options_after.txt" > nul 2>&1
if errorlevel 1 goto oj_tail_changed
>> "%OJ_ST%" echo Ryan's real options unchanged (battle_opts.json, board_look.cfg)
goto oj_tail_end
:oj_tail_nohash
call "%JW%" fail "could not hash Ryan's real options after the job"
goto oj_tail_end
:oj_tail_changed
call "%JW%" fail "Ryan's real options changed during the job"
:oj_tail_end
rem The job's own pinned checkouts are rebuildable from their pins (RULEBOOK 3.3, R326) and run to 22 GB each, so after a
rem PASS they go; any small file the job left in one is saved first into out_<name>\checkout_leftovers (issue 1497: on
rem Nov 21 every passing job kept its checkout for a build_info.json or a few .import files and C: fell to 55 GB).
rem A failed attempt keeps its checkouts for a day for the post-mortem; every tail, pass or fail, also clears this job's
rem earlier attempts (a passed one now, a failed or unfinished one after a day). out_*, the logs and the ship records
rem always stay. OJ_KEEP_CHECKOUTS=1 keeps everything (logged).
rem It runs after job_wrap end has written the done line, so a slow or stuck removal can never delay or lose the result.
set "OJ_DROP=1"
set "OJ_PASSED=1"
if "%OJ_KEEP_CHECKOUTS%"=="1" (>> "%OJ_ST%" echo checkouts kept: OJ_KEEP_CHECKOUTS=1& set "OJ_DROP=")
if defined JW_FAILED (>> "%OJ_ST%" echo checkouts of this attempt kept for a day: the job failed& set "OJ_PASSED=0")
call "%JW%" end
set "OJ_RC=%ERRORLEVEL%"
if defined OJ_DROP powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" dropcheckouts "%OJ_OUT%" %OJ_PASSED% >> "%OJ_ST%" 2>&1
exit /b %OJ_RC%
