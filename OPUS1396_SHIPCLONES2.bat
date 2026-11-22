@echo off
rem OPUS1396_SHIPCLONES2 (Board, Nov 22 2026; issue 1396): Ryan typed "Yes run the ship clones cleanup" in the Board thread at
rem 9:24 AM CT. SHIPCLONES1 kept all 7 clones because their relays live under other branch names. This passes each clone's
rem exact relay branch and tree folder to tools_live's own opus_job_head.ps1 droprepo, called in place: it writes the
rem receipt, takes the mirror locks, checks HEAD is the published commit, that the clone holds only rebuildable files, and
rem that every file of the job's out folder is on that branch on origin byte for byte, then removes. Anything that does not
rem prove is kept and logged. Removes nothing else. Once queued, this file is frozen; a change ships under a new name.
setlocal EnableExtensions
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "HEADPS=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.ps1"
if not exist "%HEADPS%" (echo FAILED: no %HEADPS% & exit /b 2)
set "OUT=%VT%\opus1396clones2\out"
if not exist "%OUT%" mkdir "%OUT%"
set "LOG=%OUT%\shipclones2.txt"
> "%LOG%" echo OPUS1396_SHIPCLONES2 tools_live %TLV%
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free before %%G
call :one opus1373gv2n 746d8d7c9a27a155575727e9e4c018b7ba6ebd66 ithar_GV2 board/pc-out-1373n-gv2 opus1373gv2n_out
call :one opus1373gw4n 746d8d7c9a27a155575727e9e4c018b7ba6ebd66 ithar_GW4 board/pc-out-1373n-gw4 opus1373gw4n_out
call :one opus1373kf1l 237fd5b260efe1be2df04aba5492ed7d41e505c6 corsair_KF1 board/pc-out-1373kf1l opus1373kf1l_out
call :one opus1415i_GA1 752bfcba5f1715b52d11a7d9557b505cb78c9d21 I16_11 board/pc-out-1415i-ga1 opus1415i_GA1_out
call :one opus1415i_GL1 752bfcba5f1715b52d11a7d9557b505cb78c9d21 I11_37 board/pc-out-1415i-gl1 opus1415i_GL1_out
call :one opus1415i_GP1 752bfcba5f1715b52d11a7d9557b505cb78c9d21 I15_11 board/pc-out-1415i-gp1 opus1415i_GP1_out
call :one opus1415i_GS1 752bfcba5f1715b52d11a7d9557b505cb78c9d21 I14_23 board/pc-out-1415i-gs1 opus1415i_GS1_out
for /f "tokens=3" %%G in ('dir /-c "%SystemDrive%\" ^| findstr /c:"bytes free"') do >> "%LOG%" echo C: bytes free after %%G
findstr /c:"====" /c:"ship clone removed" /c:"ship clone kept" /c:"bytes free" /c:"droprepo exit" "%LOG%" > "%OUT%\shipclones2_summary.txt"
echo done PASS: ship clone pass written to %LOG%
exit /b 0

:one
>> "%LOG%" echo ==== %VT%\%1 head %2 code %3 relay %4 %5
if not exist "%VT%\%1\repo" (>> "%LOG%" echo skipped: no repo folder & exit /b 0)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HEADPS%" droprepo "%VT%\%1" %2 %3 %4 %5 >> "%LOG%" 2>&1
>> "%LOG%" echo droprepo exit %ERRORLEVEL%
exit /b 0
