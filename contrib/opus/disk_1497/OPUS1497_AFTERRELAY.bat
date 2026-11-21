@echo off
rem Issue 1497 selftest part 2 of 2. Run it only after OPUS1497_SELFTEST.bat passed and the Board relayed, on one
rem board/pc-out branch, that attempt's out_new and out_old (as opus1497selftest_out_new/ and opus1497selftest_out_old/)
rem and opus1497selftestship\out (as opus1497selftestship_out/). It runs the steps the Board runs after every relay:
rem tools_live's opus_job_head.ps1 dropcheckouts on the attempt, and droprepo as publish_ship.bat does.
rem What it does, only inside the two folders part 1 made; nothing else on the PC is touched or deleted:
rem   1. dropcheckouts on the newest passed attempt of opus1497selftest: NEW and OLD must go, with their build_info.json
rem      and changed .import files saved into out_new\checkout_leftovers and out_old\checkout_leftovers.
rem   2. the ship job stand-in from part 1: dropcache must remove only its import cache, droprepo must save the stray
rem      file and remove the clone.
rem   3. the check: PASS only if NEW, OLD and the stand-in clone are gone and the saved files are there. result.txt in
rem      opus1497selftest\afterrelay_<time> names the GB freed and C: free.
rem Once queued, never edited; a change ships under a new name (next: OPUS1497_AFTERRELAY2.bat).
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "JOBDIR=%VT%\opus1497selftest"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "PS1=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.ps1"
if not exist "%PS1%" (echo FAILED: no %PS1% & exit /b 2)
findstr /c:"Assert-Relayed" "%PS1%" > nul || (echo FAILED: tools_live's head has no issue 1497 relay check; refresh tools_live first & exit /b 2)
set "STAMP="
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%S"
if not defined STAMP exit /b 2
set "AR=%JOBDIR%\afterrelay_%STAMP%"
if exist "%AR%" (echo FAILED: %AR% exists & exit /b 2)
mkdir "%AR%" || exit /b 2
set "R=%AR%\result.txt"
set "L=%AR%\log.txt"
> "%R%" echo issue 1497 selftest part 2, %DATE% %TIME%, tools_live %TLV%
set "BAD="
rem the newest attempt whose done.txt says PASS
set "ATT="
for /f "delims=" %%D in ('dir /b /ad /o-n "%JOBDIR%\out_*" 2^>nul') do if not defined ATT findstr /b /c:"PASS" "%JOBDIR%\%%D\done.txt" > nul 2>&1 && set "ATT=%JOBDIR%\%%D"
if not defined ATT (>> "%R%" echo selftest part 2 FAILED: no passed attempt of part 1 in %JOBDIR% & >> "%R%" echo all done & exit /b 1)
>> "%R%" echo attempt %ATT%

rem 1. the step the Board runs after a relay
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" dropcheckouts "%ATT%" > "%AR%\dropcheckouts.txt" 2>&1
type "%AR%\dropcheckouts.txt" >> "%L%"
if exist "%ATT%\new\" set "BAD=%BAD% new checkout still there;"
if exist "%ATT%\old\" set "BAD=%BAD% old checkout still there;"
if not exist "%ATT%\out_new\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% new's build_info.json not saved;"
if not exist "%ATT%\out_old\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% old's build_info.json not saved;"
findstr /c:"disk: checkouts freed" "%AR%\dropcheckouts.txt" > nul || set "BAD=%BAD% no freed GB line;"

rem 2. the ship job stand-in part 1 made
set "SJ=%VT%\opus1497selftestship"
if not exist "%SJ%\repo\.git\" (set "BAD=%BAD% no ship stand-in clone from part 1;" & goto report)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" dropcache "%SJ%" > "%AR%\ship_dropcache.txt" 2>&1
type "%AR%\ship_dropcache.txt" >> "%L%"
if exist "%SJ%\repo\godot\.godot\" set "BAD=%BAD% dropcache left the import cache;"
if not exist "%SJ%\repo\.git\" (set "BAD=%BAD% dropcache removed more than the import cache;" & goto report)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" droprepo "%SJ%" b683f7afa5f699ed04e3accf1784d71a45a619d0 SELF1497 > "%AR%\ship_droprepo.txt" 2>&1
type "%AR%\ship_droprepo.txt" >> "%L%"
if exist "%SJ%\repo\" set "BAD=%BAD% droprepo kept the stand-in clone (see ship_droprepo.txt);"
if not exist "%SJ%\out\checkout_leftovers_repo\files\tools\selftest_1497_note.txt" set "BAD=%BAD% droprepo did not save the stray file;"
if not exist "%SJ%\out\recipe\export\SELF1497\SELF1497.glb" set "BAD=%BAD% droprepo touched the job's out folder;"

:report
findstr /c:"removed after" /c:"saved " /c:"kept" /c:"disk: " /c:"import cache" /c:"ship clone" "%L%" >> "%R%"
if defined BAD (>> "%R%" echo selftest part 2 FAILED:%BAD%) else (>> "%R%" echo selftest part 2 PASS: no checkout left behind after the relay)
>> "%R%" echo all done
type "%R%"
if defined BAD exit /b 1
exit /b 0
