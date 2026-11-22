@echo off
rem OPUS1396_LIVE (issue 1396, PR 1592): the live janitor run from the exact pin DRY4 passed on Windows (Board, Nov 22;
rem Ryan's R400 OK). It removes only what the dry run listed under the safe rules (RULEBOOK 3.3): older lane kept
rem checkouts after checked salvage, owned or tool-named TEMP scratch, helper folders whose every out file is relayed,
rem rebuildable job checkouts, and relayed PASS attempt checkouts after the full proof under the mirror writers' lock.
rem The four files are read from the shared mirror at the exact pin (no checkout, no fetch). If the mirror lacks the
rem pin, it stops and says so. Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions
set "PIN=88aef74a0fd60fd9304bbab620008e739ed32557"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1396live"
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
set "LOG=%OUT%\janitor_live_1396.txt"
> "%LOG%" echo OPUS1396_LIVE pin %PIN%
for %%F in (janitor.ps1 janitor_salvage.ps1 runner_common.ps1 jobs\opus_job_head.ps1) do (
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\%%F" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 %%F %%H
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\janitor.ps1" >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>> "%LOG%" echo janitor exit %RC%
findstr /c:"time cap" /c:"time:" /c:"folder time" /c:"job checkout" /c:"job relay" /c:"kept checkout removed" /c:"removed" /c:"free space" "%LOG%" > "%OUT%\janitor_live_1396_removals.txt"
if "%RC%"=="0" (echo done PASS: live run written to %LOG%) else (echo done FAILED: janitor exit %RC%, see %LOG%)
exit /b %RC%
