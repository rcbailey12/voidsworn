@echo off
rem OPUS1396_DRY2 (issue 1396, PR 1592, replaces OPUS1396_DRY: adds the relay sweep through jobs\opus_job_head.ps1 dropjobs dry): a read-only janitor dry run from the PR's pinned commit, so the Board can read
rem what the widened janitor WOULD remove before any live run. Deletes nothing: janitor.ps1 --dry-run never removes,
rem never takes the janitor lock and never creates a lease or lock file; the relay sweep runs opus_job_head.ps1 dropjobs with
rem 'dry', which only checks and prints. The four files are read from the
rem shared mirror at the exact pin (no checkout, no fetch). If the mirror lacks the pin, it stops and says so.
rem Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions
set "PIN=8ef4f843ae6c7b18bf78d0a90221c33e1fd93da0"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1396dry2"
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
set "LOG=%OUT%\janitor_dry2_1396.txt"
> "%LOG%" echo OPUS1396_DRY2 pin %PIN%
for %%F in (janitor.ps1 janitor_salvage.ps1 runner_common.ps1 jobs\opus_job_head.ps1) do (
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\%%F" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 %%F %%H
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\janitor.ps1" --dry-run >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>> "%LOG%" echo janitor exit %RC%
findstr /c:"job checkout" /c:"job relay" /c:"kept checkout would remove" /c:"would remove" "%LOG%" > "%OUT%\janitor_dry2_1396_removals.txt"
if "%RC%"=="0" (echo done PASS: dry run written to %LOG%) else (echo done FAILED: janitor exit %RC%, see %LOG%)
exit /b %RC%
