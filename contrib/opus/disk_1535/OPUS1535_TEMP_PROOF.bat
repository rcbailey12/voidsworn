@echo off
rem Issue 1535 PC proof, from tools/pc/jobs/opus_job_template.bat. Job tools must not leave TEMP folders the normal
rem cleanup cannot delete (cleanup 4, Nov 21: 31 voidsworn-run folders, about 49 GB, held private mkdtemp folders).
rem One checkout of the PR 1535 head, then, exactly as ship_job.bat sets it up: an owned voidsworn-run TEMP, with
rem the checkout's tools\pc\pysite on PYTHONPATH, and in it
rem   1. the picture provenance standing check (it must PASS and say it removed its own folder),
rem   2. probe_1535.py: a mkdtemp folder under that TEMP must inherit its access (the stock mkdtemp is the control),
rem   3. tools_live's scratch_done.ps1 with a PASS code, as every ship job and look bench run ends,
rem   4. the check: the whole voidsworn-run folder is gone. out_new\result.txt says PASS or what is left.
rem Only its own job folder and its own voidsworn-run folder are touched. Once queued, never edited; a change ships under
rem a new name (next: OPUS1535_TEMP_PROOF_B.bat).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1535"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1535"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=node pil"
rem the preflight finds Python only through PIL_PYTHON on this PC (as OPUS1516_COLLECT_PROOF_B.bat)
if not defined PIL_PYTHON set "PIL_PYTHON=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=9c5e2124a06e6eebc7a38fc81a48e771a589d5a3"
set "PIN_OLD="

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "R=%O%\result.txt"
if defined JW_STOP exit /b 0
whoami /groups | findstr /c:"S-1-16-12288" > nul && (>> "%O%\token.txt" echo this job's token: elevated) || (>> "%O%\token.txt" echo this job's token: not elevated)
rem the job TEMP, made exactly as ship_job.bat makes it
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $id=[guid]::NewGuid().ToString('N'); $dir=Join-Path $env:TEMP ('voidsworn-run-' + $id); $null=[IO.Directory]::CreateDirectory($dir); [IO.File]::WriteAllText((Join-Path $dir '.voidsworn-run-owner'),$id); $dir" > "%O%\scratch_path.txt" 2>> "%OJ_ST%"
if errorlevel 1 (call "%JW%" fail "could not make the job TEMP" & exit /b 1)
set "BASE_TEMP=%TEMP%"
set "SCR="
set /p SCR=<"%O%\scratch_path.txt"
if not defined SCR (call "%JW%" fail "no job TEMP path" & exit /b 1)
set "BASE_PYTHONPATH=%PYTHONPATH%"
set "TEMP=%SCR%"
set "TMP=%SCR%"
set "TMPDIR=%SCR%"
set "PYTHONPATH=%OJ_REPO%\tools\pc\pysite"
set "PYTHON=%JW_PIL%"
set "JW_STEP=%1 picture provenance check" & set "JW_EXPECT=%O%\picture.txt" & call "%JW%" run 900 "%JW_NODE%" "%OJ_REPO%\contrib\opus\tools\picture_provenance_tests.js" > "%O%\picture.txt" 2>&1
set "JW_STEP=%1 mkdtemp probe" & set "JW_EXPECT=%O%\probe.txt" & call "%JW%" run 300 "%JW_PIL%" "%OJ_REPO%\contrib\opus\disk_1535\probe_1535.py" > "%O%\probe.txt" 2>&1
dir /b /a "%SCR%" > "%O%\scratch_before_cleanup.txt" 2>&1
set "TEMP=%BASE_TEMP%"
set "TMP=%BASE_TEMP%"
set "TMPDIR=%BASE_TEMP%"
set "PYTHONPATH=%BASE_PYTHONPATH%"
rem the cleanup every ship job and look bench run ends with (a PASS code: it removes the owned folder)
set "SD="
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\scratch_done.ps1" set "SD=%VT%\tools_live\%TLV%\pc\scratch_done.ps1"
if not defined SD if exist "%VT%\tools_live\current.txt" (set /p TLV=<"%VT%\tools_live\current.txt")
if not defined SD if exist "%VT%\tools_live\%TLV%\pc\scratch_done.ps1" set "SD=%VT%\tools_live\%TLV%\pc\scratch_done.ps1"
if not defined SD (call "%JW%" fail "no tools_live scratch_done.ps1" & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SD%" -Scratch "%SCR%" -Code 0 -BaseTemp "%BASE_TEMP%" -JobKey "opus1535 proof" > "%O%\scratch_done.txt" 2>&1
set "BAD="
findstr /c:"its own folder removed" "%O%\picture.txt" > nul || set "BAD=%BAD% the picture check did not pass and remove its folder;"
findstr /b /c:"PASS probe 1535" "%O%\probe.txt" > nul || set "BAD=%BAD% the mkdtemp probe did not pass;"
if exist "%SCR%\" set "BAD=%BAD% the job TEMP is still there after scratch_done;"
if exist "%SCR%\" dir /s /b /a "%SCR%" > "%O%\scratch_left.txt" 2>&1
> "%R%" echo issue 1535 proof, job TEMP %SCR%
type "%O%\token.txt" >> "%R%"
findstr /c:"probe_protected" /c:"control_protected" /c:"python" "%O%\probe.txt" >> "%R%"
type "%O%\scratch_done.txt" >> "%R%"
if defined BAD (>> "%R%" echo FAILED:%BAD%) else (>> "%R%" echo PASS: the picture check removed its folder, mkdtemp inherits access, and the whole job TEMP is gone)
if defined BAD (call "%JW%" fail "1535 proof:%BAD%" & exit /b 1)
exit /b 0
