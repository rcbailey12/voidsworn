@echo off
rem OPUS1695_DROP1 (Board, Nov 22 2026; issues 1396, 1695): Ryan's own words in the Board thread at 8:26 AM CT, "Yes run live
rem janitor, we also should be able to get up to like 400gb at least". Clears the pinned checkouts of PASSED attempts only,
rem one attempt at a time (dropwait itself refuses any attempt that is not PASS), through the merged relay waiter (opus_job_head.ps1 dropwait at main fff26410): job lease, issue
rem lock, the janitor's checks, mirror lock, then a fresh byte-for-byte proof that every result file is on origin's relay
rem branch before each checkout goes. A failed, unfinished or unproven attempt is kept and logged. Each attempt waits at most
rem 10 minutes (OJ_DROPWAIT_SECONDS=600, polls every 60 s). Removes nothing else: no ship clones, runner slots, staging,
rem TEMP or Downloads. Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions EnableDelayedExpansion
set "PIN=fff264102bfb5e05acab7a01ab28ad50a169cf74"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1695drop1"
set "TOOLS=%JOB%\tools_%PIN:~0,8%"
set "OUT=%JOB%\out"
if not exist "%MIRROR%" (echo FAILED: no shared mirror at %MIRROR% & exit /b 2)
git --git-dir "%MIRROR%" cat-file -e %PIN%^^{commit} 2>nul
if errorlevel 1 (echo FAILED: the mirror does not hold %PIN%; fetch the mirror, then run this again & exit /b 2)
if not exist "%TOOLS%\jobs" mkdir "%TOOLS%\jobs"
if not exist "%OUT%" mkdir "%OUT%"
for %%F in (jobs\opus_job_head.ps1 runner_common.ps1 janitor.ps1 janitor_salvage.ps1) do (
  git --git-dir "%MIRROR%" show %PIN%:tools/pc/%%F > "%TOOLS%\%%F" 2>nul
)
if not exist "%TOOLS%\jobs\opus_job_head.ps1" (echo FAILED: could not read opus_job_head.ps1 at %PIN% & exit /b 2)
set "LOG=%OUT%\drop1_1695.txt"
> "%LOG%" echo OPUS1695_DROP1 pin %PIN%
for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\jobs\opus_job_head.ps1" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 jobs\opus_job_head.ps1 %%H
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free before %%G
set "OJ_DROPWAIT_SECONDS=600"
set "OJ_DROPWAIT_POLL_SECONDS=60"
set /a N=0
for /d %%J in ("%VT%\opus*" "%VT%\pt*") do (
  for /d %%A in ("%%~fJ\out_*") do (
    if exist "%%~fA\checkouts.txt" (
      set /a N+=1
      >> "%LOG%" echo ==== %%~fA
      powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\jobs\opus_job_head.ps1" dropwait "%%~fA" >> "%LOG%" 2>&1
      >> "%LOG%" echo dropwait exit !ERRORLEVEL!
    )
  )
)
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free after %%G
findstr /c:"====" /c:"removed" /c:"checkouts kept" /c:"held back" /c:"freed" /c:"bytes free" /c:"dropwait exit" "%LOG%" > "%OUT%\drop1_1695_summary.txt"
echo done PASS: drop pass written to %LOG%
exit /b 0
