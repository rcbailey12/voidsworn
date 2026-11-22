@echo off
rem OPUS1644_DRY5 (issue 1396, PR 1644 at 4ac0877d4425dbcf92f41b7f7284ece408d29cf6, after the fixes for the review of issue 1647): a read-only Windows dry pass
rem of the relay waiter before any live use. Deletes nothing (except its own smoke log from an earlier run of this bat):
rem  1. janitor.ps1 --dry-run from the pin (its relay sweep runs opus_job_head.ps1 dropjobs dry: checks and prints only).
rem  2. opus_job_head.ps1 dropwait <attempt> dry for every voidsworn_test\opus*\out_* and pt*\out_* folder that still has a
rem     checkouts.txt: one look at origin and the dry proof, no lock, log, fetch or removal. Failed and unfinished
rem     attempts are skipped by the script itself.
rem  3. A launcher smoke check: the tail's exact hidden Start-Process line, with OJ_DROPWAIT_ATTEMPT pointing at an empty
rem     attempt made here (opus1396dry5\out_smoke, no done.txt). The waiter must start hidden, read the attempt from the
rem     environment, write its log in this job folder and stop at "not a passed attempt". Nothing else is touched.
rem The tools are read from the shared mirror at the exact pin (no checkout, no fetch). Once queued, this file is frozen;
rem a change ships under a new name.
setlocal EnableExtensions
set "PIN=4ac0877d4425dbcf92f41b7f7284ece408d29cf6"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1396dry5"
set "TOOLS=%JOB%\tools_%PIN:~0,8%"
set "OUT=%JOB%\out"
if not exist "%MIRROR%" (echo FAILED: no shared mirror at %MIRROR% & exit /b 2)
git --git-dir "%MIRROR%" cat-file -e %PIN%^^{commit} 2>nul
if errorlevel 1 (echo FAILED: the mirror does not hold %PIN%; fetch the mirror, then run this again & exit /b 2)
if not exist "%TOOLS%\jobs" mkdir "%TOOLS%\jobs"
if not exist "%OUT%" mkdir "%OUT%"
for %%F in (janitor.ps1 janitor_salvage.ps1 runner_common.ps1) do (
  git --git-dir "%MIRROR%" show %PIN%:tools/pc/%%F > "%TOOLS%\%%F"
  if errorlevel 1 (echo FAILED: could not read tools/pc/%%F at %PIN% & exit /b 2)
)
git --git-dir "%MIRROR%" show %PIN%:tools/pc/jobs/opus_job_head.ps1 > "%TOOLS%\jobs\opus_job_head.ps1"
if errorlevel 1 (echo FAILED: could not read tools/pc/jobs/opus_job_head.ps1 at %PIN% & exit /b 2)
set "OJ_PS=%TOOLS%\jobs\opus_job_head.ps1"
set "LOG=%OUT%\dry5_1644.txt"
> "%LOG%" echo OPUS1644_DRY5 pin %PIN%
for %%F in (janitor.ps1 janitor_salvage.ps1 runner_common.ps1 jobs\opus_job_head.ps1) do (
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\%%F" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 %%F %%H
)
>> "%LOG%" echo ==== 1. janitor dry run
powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\janitor.ps1" --dry-run >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>> "%LOG%" echo janitor exit %RC%
>> "%LOG%" echo ==== 2. dropwait dry over attempts that still list checkouts
set "WAITS=0"
set "WAITFAIL=0"
for /d %%J in ("%VT%\opus*" "%VT%\pt*") do if /i not "%%~nxJ"=="opus1396dry5" (
  for /d %%A in ("%%~fJ\out_*") do if exist "%%~fA\checkouts.txt" (
    >> "%LOG%" echo ---- %%~fA
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" dropwait "%%~fA" dry >> "%LOG%" 2>&1
    if errorlevel 1 (set /a WAITFAIL+=1 & >> "%LOG%" echo dropwait dry exit nonzero for %%~fA)
    set /a WAITS+=1
  )
)
>> "%LOG%" echo dropwait dry runs %WAITS%, nonzero exits %WAITFAIL%
>> "%LOG%" echo ==== 3. launcher smoke check
set "SMOKE=%JOB%\out_smoke"
set "SMOKELOG=%JOB%\dropwait_out_smoke.txt"
if not exist "%SMOKE%" mkdir "%SMOKE%"
if exist "%SMOKELOG%" del /q "%SMOKELOG%"
set "OJ_DROPWAIT_ATTEMPT=%SMOKE%"
set "OJ_DROPWAIT_LOG=1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Start-Process -WindowStyle Hidden -FilePath powershell.exe -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File \"{0}\" dropwait' -f $env:OJ_PS)" > nul 2>&1
set "LAUNCH=%ERRORLEVEL%"
>> "%LOG%" echo launcher exit %LAUNCH%
set "SMOKEOK="
for /l %%N in (1,1,30) do if not defined SMOKEOK (
  ping -n 2 127.0.0.1 > nul
  if exist "%SMOKELOG%" findstr /c:"is not a passed attempt; nothing to wait for" "%SMOKELOG%" > nul 2>&1 && set "SMOKEOK=1"
)
if exist "%SMOKELOG%" (type "%SMOKELOG%" >> "%LOG%") else (>> "%LOG%" echo no waiter log at %SMOKELOG%)
if defined SMOKEOK (>> "%LOG%" echo smoke PASS: hidden waiter read the attempt from the environment and logged in the job folder) else (>> "%LOG%" echo smoke FAILED: no "not a passed attempt" line in %SMOKELOG% after 30 s)
findstr /c:"would remove" /c:"checkouts kept" /c:"relay branch" /c:"not on origin" /c:"held back" /c:"smoke " /c:"nonzero" /c:"janitor exit" /c:"launcher exit" "%LOG%" > "%OUT%\dry5_1644_summary.txt"
if not "%RC%"=="0" (echo done FAILED: janitor exit %RC%, see %LOG% & exit /b 1)
if not "%LAUNCH%"=="0" (echo done FAILED: launcher exit %LAUNCH%, see %LOG% & exit /b 1)
if not defined SMOKEOK (echo done FAILED: launcher smoke check, see %LOG% & exit /b 1)
if not "%WAITFAIL%"=="0" (echo done FAILED: %WAITFAIL% dropwait dry runs exited nonzero, see %LOG% & exit /b 1)
echo done PASS: dry pass written to %LOG%
exit /b 0
