@echo off
rem Issue 1497 selftest part 2 of 2. Run it only after OPUS1497_SELFTEST.bat passed and the Board relayed every file of
rem that attempt's out_new and out_old folders to a board/pc-out branch on GitHub. It is the step the Board runs after
rem every relay: tools_live's opus_job_head.ps1 dropcheckouts on the attempt.
rem What it does, all inside its own folders (Downloads\voidsworn_test\opus1497selftest and the ship stand-in
rem opus1497selftest_ship_<time> it makes itself); nothing else on the PC is touched or deleted:
rem   1. dropcheckouts on the newest passed attempt of opus1497selftest: NEW and OLD must go, with their build_info.json
rem      and changed .import files saved into out_new\checkout_leftovers and out_old\checkout_leftovers.
rem   2. a ship job stand-in: its own clone, a 64 MB import cache, an installed hull that matches its export (bytes of a
rem      file already relayed in part 1, so the stand-in's out counts as relayed) and a stray file; dropcache must remove
rem      only the cache, droprepo must save the stray file and remove the clone.
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

rem 2. a ship job stand-in in its own new folder
set "SJ=%VT%\opus1497selftest_ship_%STAMP%"
set "SRC=%ATT%\out_new\import.txt"
if exist "%SJ%" (set "BAD=%BAD% ship stand-in folder already exists;" & goto report)
if not exist "%SRC%" (set "BAD=%BAD% no relayed out_new\import.txt to build the stand-in from;" & goto report)
mkdir "%SJ%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" checkout "%SJ%" repo b683f7afa5f699ed04e3accf1784d71a45a619d0 >> "%L%" 2>&1
if errorlevel 1 (set "BAD=%BAD% ship stand-in clone;" & goto report)
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $c = Join-Path $env:SJ 'repo\godot\.godot\imported'; $null = [IO.Directory]::CreateDirectory($c); $f = [IO.File]::Create((Join-Path $c 'selftest.bin')); $f.SetLength(64MB); $f.Dispose(); foreach ($d in (Join-Path $env:SJ 'repo\godot\assets\ships\SELF1497'), (Join-Path $env:SJ 'out\recipe\export\SELF1497')) { $null = [IO.Directory]::CreateDirectory($d); [IO.File]::Copy($env:SRC, (Join-Path $d 'SELF1497.glb')) }; [IO.File]::WriteAllText((Join-Path $env:SJ 'repo\tools\selftest_1497_note.txt'), 'left by a stage')" >> "%L%" 2>&1
if errorlevel 1 (set "BAD=%BAD% ship stand-in files;" & goto report)
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
