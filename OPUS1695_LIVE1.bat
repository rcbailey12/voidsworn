@echo off
rem OPUS1695_LIVE1 (issue 1695, PR 1696 merged at fff264102bfb5e05acab7a01ab28ad50a169cf74): the relay place backfill, live. Queue it only after the Board
rem has read OPUS1695_DRY1. opus_job_head.ps1 relayfind all: fetches the shared mirror once (under its writers' lock), then
rem for every passed attempt under voidsworn_test that still lists checkouts and whose own relay place does not prove, with
rem no relay_receipt.txt or relay_branch.txt of its own, finds the board/pc-out-* folder that holds all its result files
rem byte for byte and writes that as a NEW relay_branch.txt in the attempt. That is the only file it writes. It deletes
rem nothing: the relay waiter and the janitor's relay sweep still prove the bytes under the mirror lock before any drop.
rem Run it before any live relay branch prune (PR 1672). Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions
set "PIN=fff264102bfb5e05acab7a01ab28ad50a169cf74"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "MIRROR=%VT%\repo-mirror.git"
set "JOB=%VT%\opus1695live1"
set "TOOLS=%JOB%\tools_%PIN:~0,8%"
set "OUT=%JOB%\out"
if not exist "%MIRROR%" (echo FAILED: no shared mirror at %MIRROR% & exit /b 2)
git --git-dir "%MIRROR%" cat-file -e %PIN%^^{commit} 2>nul
if errorlevel 1 (echo FAILED: the mirror does not hold %PIN%; fetch the mirror, then run this again & exit /b 2)
if not exist "%TOOLS%\jobs" mkdir "%TOOLS%\jobs"
if not exist "%OUT%" mkdir "%OUT%"
git --git-dir "%MIRROR%" show %PIN%:tools/pc/jobs/opus_job_head.ps1 > "%TOOLS%\jobs\opus_job_head.ps1"
if errorlevel 1 (echo FAILED: could not read tools/pc/jobs/opus_job_head.ps1 at %PIN% & exit /b 2)
set "LOG=%OUT%\relayfind_live1_1695.txt"
> "%LOG%" echo OPUS1695_LIVE1 pin %PIN%
for /f "skip=1 delims=" %%H in ('certutil -hashfile "%TOOLS%\jobs\opus_job_head.ps1" SHA256 ^| findstr /v /c:"CertUtil"') do >> "%LOG%" echo sha256 jobs\opus_job_head.ps1 %%H
powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLS%\jobs\opus_job_head.ps1" relayfind all >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>> "%LOG%" echo relayfind exit %RC%
findstr /c:"relay place written" /c:"relay place not written" /c:"relay place not found" /c:"relay place left alone" /c:"looking through" /c:"relay places to look for" /c:"relayfind exit" "%LOG%" > "%OUT%\relayfind_live1_1695_summary.txt"
if "%RC%"=="0" (echo done PASS: live backfill written to %LOG%) else (echo done FAILED: relayfind exit %RC%, see %LOG%)
exit /b %RC%
