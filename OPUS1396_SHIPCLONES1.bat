@echo off
rem OPUS1396_SHIPCLONES1 (Board, Nov 22 2026; issue 1396): Ryan's own words in the Board thread, 8:26 AM CT "Yes run live
rem janitor, we also should be able to get up to like 400gb at least" and 9:13 AM CT "We've cleaned it without my click
rem before. Do it again". Removes ship job clones (voidsworn_test\opus*\repo with an out\recipe\export\<code> folder) only
rem through tools_live's own opus_job_head.ps1 droprepo, called in place: it takes the mirror locks, checks the clone holds
rem only rebuildable files (Assert-Rebuildable), proves every file of the job's out folder byte for byte on its relay branch
rem on origin (Assert-Relayed), saves any non-rebuildable leftover first, then removes. Anything it cannot prove is kept and
rem logged. The commit passed is the clone's own HEAD; the export folder names the hull code. Removes nothing else.
rem Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions EnableDelayedExpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "HEADPS=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.ps1"
if not exist "%HEADPS%" (echo FAILED: no %HEADPS% & exit /b 2)
set "OUT=%VT%\opus1396clones1\out"
if not exist "%OUT%" mkdir "%OUT%"
set "LOG=%OUT%\shipclones1.txt"
> "%LOG%" echo OPUS1396_SHIPCLONES1 tools_live %TLV%
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free before %%G
for /d %%J in ("%VT%\opus*") do (
  if exist "%%~fJ\repo\.git" if exist "%%~fJ\out\recipe\export" (
    set "HEADC="
    for /f "delims=" %%H in ('git -C "%%~fJ\repo" rev-parse HEAD 2^>nul') do set "HEADC=%%H"
    set "CODE="
    set /a NC=0
    for /d %%C in ("%%~fJ\out\recipe\export\*") do (set "CODE=%%~nxC" & set /a NC+=1)
    >> "%LOG%" echo ==== %%~fJ head !HEADC! code !CODE! exports !NC!
    if defined HEADC if "!NC!"=="1" (
      powershell -NoProfile -ExecutionPolicy Bypass -File "%HEADPS%" droprepo "%%~fJ" !HEADC! !CODE! >> "%LOG%" 2>&1
      >> "%LOG%" echo droprepo exit !ERRORLEVEL!
    ) else (
      >> "%LOG%" echo skipped: no HEAD or not exactly one export folder
    )
  )
)
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free after %%G
findstr /c:"====" /c:"ship clone removed" /c:"ship clone kept" /c:"skipped" /c:"bytes free" /c:"droprepo exit" "%LOG%" > "%OUT%\shipclones1_summary.txt"
echo done PASS: ship clone pass written to %LOG%
exit /b 0
