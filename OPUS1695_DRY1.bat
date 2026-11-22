@echo off
rem OPUS1695_DRY1 (issue 1695, PR for branch opus/issue-1695 at e03b03bf2b6d06dfd3e939ba3dd1da0da59d1bba): a read-only dry run of the relay place backfill.
rem opus_job_head.ps1 relayfind all dry: for every passed attempt under voidsworn_test that still lists checkouts and whose
rem own relay place does not prove, it looks through every board/pc-out-* branch in the shared mirror for the folder that
rem holds all its result files byte for byte, and prints the relay_branch.txt line a live run would write. Writes nothing,
rem fetches nothing, removes nothing, takes no lock. The head is read from the shared mirror at the exact pin (no checkout,
rem no fetch). If the mirror lacks the pin, it stops and says so. Once queued, this file is frozen; a change ships under a
rem new name.
setlocal EnableExtensions
set "PIN=e03b03bf2b6d06dfd3e939ba3dd1da0da59d1bba"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1695dry1"
set "TOOLS=%JOB%\tools_%PIN:~0,8%"
set "OUT=%JOB%\out"
if not exist "%MIRROR%" (echo FAILED: no shared mirror at %MIRROR% & exit /b 2)
git --git-dir "%MIRROR%" cat-file -e %PIN%^^{commit} 2>nul
if errorlevel 1 (echo FAILED: the mirror does not hold %PIN%; fetch the mirror, then run this again & exit /b 2)
if not exist "%TOOLS%\jobs" mkdir "%TOOLS%\jobs"
if not exist "%OUT%" mkdir "%OUT%"
git --git-dir "%MIRROR%" show %PIN%:tools/pc/jobs/opus_job_head.ps1 > "%TOOLS%\jobs\opus_job_head.ps1"
if errorlevel 1 (echo FAILED: could not read tools/pc/jobs/opus_job_head.ps1 at %PIN% & exit /b 2)
set "LOG=%OUT%\relayfind_dry1_1695.txt"
> "%LOG%" echo OPUS1695_DRY1 pin %PIN%
for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\jobs\opus_job_head.ps1" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 jobs\opus_job_head.ps1 %%H
powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\jobs\opus_job_head.ps1" relayfind all dry >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>> "%LOG%" echo relayfind exit %RC%
findstr /c:"relay place would be written" /c:"relay place not found" /c:"relay place left alone" /c:"looking through" /c:"relay places to look for" /c:"relayfind exit" "%LOG%" > "%OUT%\relayfind_dry1_1695_summary.txt"
if "%RC%"=="0" (echo done PASS: dry run written to %LOG%) else (echo done FAILED: relayfind exit %RC%, see %LOG%)
exit /b %RC%
