@echo off
rem Issue 1497 selftest part 2 of 2. Run it only after OPUS1497_SELFTEST4.bat passed and the Board relayed, on one
rem board/pc-out branch, that attempt folder (its out_new and out_old, as <attempt folder name>/out_new/ and .../out_old/,
rem the RUN6 layout) and opus1497st4ship\out (as opus1497st4ship_out/), files over 10 MB left out and listed in
rem skipped_over_10MB.txt at each tree folder's root. Both 11 MB results must then count as kept on the PC only. Then:
rem   OPUS1497_AFTERRELAY4.bat <relay branch>
rem Before the merge (a smoke), set OPUS_JOB_HEAD_PREMERGE=1 and OPUS_JOB_HEAD as for part 1: the PowerShell half next
rem to that head is used instead of tools_live's.
rem It runs the steps the Board runs after every relay, with that branch as the receipt: tools_live's
rem opus_job_head.ps1 dropcheckouts on the attempt, and droprepo as publish_ship.bat does.
rem What it does, only inside the two folders part 1 made; nothing else on the PC is touched or deleted:
rem   1. dropcheckouts on the newest passed attempt of opus1497st4: NEW and OLD must go, with their build_info.json
rem      and changed .import files saved into out_new\checkout_leftovers and out_old\checkout_leftovers.
rem   2. the ship job stand-in from part 1: dropcache must remove only its import cache, droprepo must save the stray
rem      file and remove the clone.
rem   0. pair 2's leftover (Board, Nov 21): opus1497st2's passed attempt whose old checkout went but whose new one stopped
rem      half way on a locked pack file. Only when that attempt has its relay receipt, old is gone and new is a plain
rem      folder: new is recorded in removing.txt with its listed pin and renamed to new.removing, then dropcheckouts on
rem      that attempt finishes it with its own link, HEAD and pause checks. Nothing else in opus1497st2 is touched.
rem   1b. during step 1, a file in NEW is held open (no delete or rename) for 25 s, so the removal may have to wait and retry (result.txt says whether it did).
rem   3. the check: PASS only if NEW, OLD and the stand-in clone are gone and the saved files are there. result.txt in
rem      opus1497st4\afterrelay_<time> names the GB freed and C: free.
rem Once queued, never edited; a change ships under a new name (next: OPUS1497_AFTERRELAY5.bat).
setlocal EnableExtensions
set "RELAY=%~1"
echo %RELAY%| findstr /r /x "board/pc-out-[A-Za-z0-9._-]*" > nul || (echo usage: OPUS1497_AFTERRELAY4.bat board/pc-out-^<name^> & exit /b 2)
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "JOBDIR=%VT%\opus1497st4"
set "TLV="
set "PS1="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" for %%H in ("%OPUS_JOB_HEAD%") do set "PS1=%%~dpHopus_job_head.ps1"
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "TLV=pre-merge copy %OPUS_JOB_HEAD%"
if not defined PS1 if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
if not defined PS1 set "PS1=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.ps1"
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
>> "%R%" echo attempt %ATT%, relay %RELAY%
for %%N in ("%ATT%") do set "ATTNAME=%%~nxN"

rem 0. pair 2's half-removed new checkout, inside opus1497st2 only
set "A2="
for /f "delims=" %%D in ('dir /b /ad /o-n "%VT%\opus1497st2\out_*" 2^>nul') do if not defined A2 findstr /b /c:"PASS" "%VT%\opus1497st2\%%D\done.txt" > nul 2>&1 && set "A2=%VT%\opus1497st2\%%D"
set "PIN2="
if defined A2 for /f "usebackq tokens=1,2" %%a in ("%A2%\checkouts.txt") do if "%%a"=="new" set "PIN2=%%b"
set "DO2="
if defined A2 if defined PIN2 if exist "%A2%\relay_receipt.txt" if exist "%A2%\new\" if not exist "%A2%\old\" if not exist "%A2%\new.removing\" set "DO2=1"
if defined DO2 powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $n = Get-Item -LiteralPath (Join-Path $env:A2 'new') -Force; if ($n.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'new is a link' }; [IO.File]::AppendAllText((Join-Path $env:A2 'removing.txt'), ('new.removing ' + $env:PIN2 + [char]13 + [char]10)); [IO.Directory]::Move($n.FullName, $n.FullName + '.removing')" > "%AR%\pair2.txt" 2>&1
if defined DO2 powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" dropcheckouts "%A2%" >> "%AR%\pair2.txt" 2>&1
if defined DO2 (type "%AR%\pair2.txt" >> "%L%")
if defined DO2 if exist "%A2%\new.removing\" set "BAD=%BAD% pair 2's new checkout is still there (see pair2.txt);"
if defined DO2 if exist "%A2%\new\" set "BAD=%BAD% pair 2's new checkout was not renamed (see pair2.txt);"
if defined DO2 (>> "%R%" echo pair 2 leftover: %A2%\new) else (>> "%R%" echo pair 2 leftover: none found to finish)

rem 1b. hold a file in NEW open for 25 s (reads allowed, no delete or rename) while step 1 runs
set "LOCKF=%ATT%\new\godot\project.godot"
if exist "%LOCKF%" start "" /b powershell -NoProfile -Command "$f = [IO.File]::Open($env:LOCKF, 'Open', 'Read', 'Read'); [IO.File]::WriteAllText((Join-Path $env:AR 'lock_held.txt'), (Get-Date -Format o)); Start-Sleep -Seconds 25; $f.Dispose(); [IO.File]::WriteAllText((Join-Path $env:AR 'lock_released.txt'), (Get-Date -Format o))"
if exist "%LOCKF%" powershell -NoProfile -Command "for ($i = 0; $i -lt 40 -and -not (Test-Path (Join-Path $env:AR 'lock_held.txt'))); $i++) { Start-Sleep -Milliseconds 250 }"
if not exist "%AR%\lock_held.txt" set "BAD=%BAD% the test lock was not taken;"
powershell -NoProfile -Command "Get-Date -Format o" > "%AR%\drop_started.txt"

rem 1. the step the Board runs after a relay
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" dropcheckouts "%ATT%" %RELAY% %ATTNAME% > "%AR%\dropcheckouts.txt" 2>&1
powershell -NoProfile -Command "Get-Date -Format o" > "%AR%\drop_ended.txt"
type "%AR%\dropcheckouts.txt" >> "%L%"
if exist "%ATT%\new.removing\" set "BAD=%BAD% new.removing left behind;"
findstr /c:"still locked, trying again" "%AR%\dropcheckouts.txt" > nul && (>> "%R%" echo lock retry seen: yes) || (>> "%R%" echo lock retry seen: no, the 25 s test lock ended before the removal reached it ^(timing only, not a failure^))
if exist "%ATT%\new\" set "BAD=%BAD% new checkout still there;"
if exist "%ATT%\old\" set "BAD=%BAD% old checkout still there;"
if not exist "%ATT%\out_new\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% new's build_info.json not saved;"
if not exist "%ATT%\out_old\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% old's build_info.json not saved;"
findstr /c:"disk: checkouts freed" "%AR%\dropcheckouts.txt" > nul || set "BAD=%BAD% no freed GB line;"
findstr /c:"result kept on the PC only: out_new/selftest_big.bin" "%AR%\dropcheckouts.txt" > nul || set "BAD=%BAD% the 11 MB result was not counted as left out by the relay;"
if not exist "%ATT%\out_new\selftest_big.bin" set "BAD=%BAD% the 11 MB result is gone;"

rem 2. the ship job stand-in part 1 made
set "SJ=%VT%\opus1497st4ship"
if not exist "%SJ%\repo\.git\" (set "BAD=%BAD% no ship stand-in clone from part 1;" & goto report)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" dropcache "%SJ%" > "%AR%\ship_dropcache.txt" 2>&1
type "%AR%\ship_dropcache.txt" >> "%L%"
if exist "%SJ%\repo\godot\.godot\" set "BAD=%BAD% dropcache left the import cache;"
if not exist "%SJ%\repo\.git\" (set "BAD=%BAD% dropcache removed more than the import cache;" & goto report)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" droprepo "%SJ%" e89e33e74417d013bf35252bdabf0958b96f5016 SELF1497 %RELAY% opus1497st4ship_out > "%AR%\ship_droprepo.txt" 2>&1
type "%AR%\ship_droprepo.txt" >> "%L%"
if exist "%SJ%\repo\" set "BAD=%BAD% droprepo kept the stand-in clone (see ship_droprepo.txt);"
if not exist "%SJ%\out\checkout_leftovers_repo\files\tools\selftest_1497_note.txt" set "BAD=%BAD% droprepo did not save the stray file;"
if not exist "%SJ%\out\recipe\export\SELF1497\SELF1497.glb" set "BAD=%BAD% droprepo touched the job's out folder;"
findstr /c:"result kept on the PC only: recipe/export/SELF1497/SELF1497.glb" "%AR%\ship_droprepo.txt" > nul || set "BAD=%BAD% the 11 MB ship glb was not counted as left out by the relay;"

:report
findstr /c:"removed after" /c:"saved " /c:"kept" /c:"results relayed" /c:"earlier removal" /c:"disk: " /c:"import cache" /c:"ship clone" "%L%" >> "%R%"
if defined BAD (>> "%R%" echo selftest part 2 FAILED:%BAD%) else (>> "%R%" echo selftest part 2 PASS: no checkout left behind after the relay)
>> "%R%" echo all done
type "%R%"
if defined BAD exit /b 1
exit /b 0
