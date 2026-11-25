@echo off
rem Issue 2018 / PR 2049 shared sparks look capture (Board, Nov 24 21:50 UTC; R407: All checks green at a28bdcfc, review passed).
rem A fresh checkout of codex/issue-2018 at exactly a28bdcfc6e269994b97911d6a56cb7068b6c7002 (refused if HEAD differs), then
rem that commit's own contrib\codex\issue-2018\capture.bat run unedited with AFTER a28bdcfc (full sha) and BEFORE 3d7ecab7.
rem capture.bat calls the checkout's look_bench.bat (LB_HOME board\issue-2018\bench) and then review_sheets.ps1; its shots
rem and sheets go to board\issue-2018\shots. Afterwards those, the bench run pictures and logs are copied into
rem opus2018sp\out_capture_<stamp> for the relay. Nothing on the PC is deleted.
setlocal EnableExtensions
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "SHA=a28bdcfc6e269994b97911d6a56cb7068b6c7002"
set "BEFORE=3d7ecab76a2fe72df169ac1198602431f54d599c"
set "J=%V%\opus2018sp"
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%S"
set "CO=%J%\co_%STAMP%"
set "O=%J%\out_capture_%STAMP%"
if not exist "%J%" mkdir "%J%"
mkdir "%O%"
echo checkout %SHA% into %CO% > "%O%\job.txt"
git clone -q --no-checkout "%V%\repo-mirror.git" "%CO%" >> "%O%\job.txt" 2>&1
git -C "%CO%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%O%\job.txt" 2>&1
for /f %%H in ('git -C "%CO%" rev-parse HEAD') do set "HEADSHA=%%H"
if /i not "%HEADSHA%"=="%SHA%" (echo FAILED: checkout HEAD %HEADSHA% is not %SHA% >> "%O%\job.txt" & exit /b 2)
echo HEAD %HEADSHA% >> "%O%\job.txt"
set "PC_GPU_WAIT_SECONDS=3600"
echo plan check: >> "%O%\job.txt"
call "%CO%\contrib\codex\issue-2018\capture.bat" --plan >> "%O%\job.txt" 2>&1
echo capture start %DATE% %TIME% >> "%O%\job.txt"
call "%CO%\contrib\codex\issue-2018\capture.bat" %SHA% %BEFORE% > "%O%\capture_console.txt" 2>&1
set "RC=%ERRORLEVEL%"
echo capture exit %RC% %DATE% %TIME% >> "%O%\job.txt"
if exist "%V%\board\issue-2018\shots" robocopy "%V%\board\issue-2018\shots" "%O%\shots" /E /NFL /NDL /NJH /NJS /NP >nul
if exist "%V%\board\issue-2018\bench\runs" robocopy "%V%\board\issue-2018\bench\runs" "%O%\bench_runs" *.png *.jpg *.json *.txt *.md /S /MAXAGE:1 /NFL /NDL /NJH /NJS /NP >nul
exit /b %RC%
