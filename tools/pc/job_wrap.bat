@echo off
rem Issue 1194: the shared step helper for PC job bats. Every step runs under the canonical watchdog (tools_live\<version>\pc
rem \tmo.bat), a failed step stops the job unless it is marked optional, declared outputs must not be empty, and the job
rem ends with "done PASS" or "done FAILED: <steps>" then "all done" in status.txt, done.txt says PASS or FAILED, and the
rem exit code is non-zero after any failure.
rem Use it from a job bat, after the job's own setlocal (the JW_ settings must not outlive the job):
rem   set "JW=<clone>\tools\pc\job_wrap.bat"
rem   call "%JW%" init "<out folder>" "<GPU label>" "<tools: godot blender ffmpeg node pil>"
rem   if errorlevel 1 exit /b %ERRORLEVEL%
rem   set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
rem   call "%JW%" end
rem   exit /b %ERRORLEVEL%
rem Before each run: JW_STEP names the step (required). JW_OPTIONAL=1: a failure is only noted. JW_CONTINUE=1: a failure
rem fails the job, but later steps still run (independent checks). JW_EXPECT=<path>;<path>: each must be a non-empty file,
rem or a folder holding a file, after the step. All four are cleared after every step, so none leaks into the next one.
rem The GPU label becomes PC_GPU_ISSUE, so every claim the watchdog takes names its owner (PC_DOCTOR.bat shows it).
rem Other commands:
rem   copy <src> <dst> <log> [new]  robocopy /E; exit 8 or more fails the job; "new" never overwrites newer files.
rem                                 A missing source is noted, not failed.
rem   fail "<step>"                 mark a step failed from the job's own check (JW_CONTINUE=1 keeps later steps running)
rem   note "<text>"                 one status line
rem init moves an older done.txt to done_previous.txt (nothing is deleted), refreshes tools_live when it can (a busy or
rem failed refresh keeps the installed version), stops when the watchdog or slot files differ from that version's hashes,
rem and runs the tool preflight before the job clones or claims the GPU. Exit 2: a missing tool; exit 1: any other stop.
rem The preflight sets JW_GODOT, JW_BLENDER, JW_FFMPEG, JW_NODE and JW_PIL (a Python with Pillow) to what it found.
rem Test settings: JW_TOOLS (a pc folder) and JW_HASHES replace tools_live; JW_NO_REFRESH=1 skips the refresh;
rem JW_NO_JANITOR=1 skips the after-job cleanup that end starts (janitor.ps1 --after-job, issue 1180).
if /i "%~1"=="init" goto jw_init
if /i "%~1"=="run" goto jw_run
if /i "%~1"=="copy" goto jw_copy
if /i "%~1"=="fail" goto jw_fail
if /i "%~1"=="note" goto jw_note
if /i "%~1"=="end" goto jw_end
echo job_wrap: unknown command "%~1"
exit /b 2

rem ------------------------------------------------------------------ init <out> <GPU label> <tools>
:jw_init
set "JW_OUT=%~2"
set "JW_FAILED="
set "JW_STOP="
set "JW_STEP="
set "JW_OPTIONAL="
set "JW_CONTINUE="
set "JW_EXPECT="
set "JW_RC=1"
if not defined JW_OUT echo job_wrap: init needs an output folder
if not defined JW_OUT exit /b 2
if not exist "%JW_OUT%" mkdir "%JW_OUT%"
set "JW_ST=%JW_OUT%\status.txt"
if exist "%JW_OUT%\done.txt" move /y "%JW_OUT%\done.txt" "%JW_OUT%\done_previous.txt" > nul
>> "%JW_ST%" echo [%date% %time%] job start
if not "%~3"=="" goto jw_label_ok
set "JW_FAILED=GPU label"
>> "%JW_ST%" echo FAILED: no GPU label; every job names its claims
goto jw_init_fail
:jw_label_ok
set "PC_GPU_ISSUE=%~3"
set "JW_VT=%USERPROFILE%\Downloads\voidsworn_test"
if defined JW_TOOLS goto jw_tools_set
if not "%JW_NO_REFRESH%"=="1" if exist "%~dp0lane_tools_refresh.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lane_tools_refresh.ps1" -Build tools_live >> "%JW_OUT%\tools_refresh.txt" 2>&1
set "JW_VER="
if exist "%JW_VT%\tools_live\current.txt" set /p JW_VER=<"%JW_VT%\tools_live\current.txt"
if defined JW_VER goto jw_ver_ok
set "JW_FAILED=tools_live"
>> "%JW_ST%" echo FAILED: no tools_live copy; see %JW_OUT%\tools_refresh.txt
goto jw_init_fail
:jw_ver_ok
set "JW_TOOLS=%JW_VT%\tools_live\%JW_VER%\pc"
set "JW_HASHES=%JW_VT%\tools_live\%JW_VER%\hashes.txt"
:jw_tools_set
if exist "%JW_TOOLS%\tmo.bat" goto jw_tmo_ok
set "JW_FAILED=tools_live"
>> "%JW_ST%" echo FAILED: no watchdog at %JW_TOOLS%\tmo.bat
goto jw_init_fail
:jw_tmo_ok
>> "%JW_ST%" echo tools: %JW_TOOLS%
if not defined JW_HASHES goto jw_hash_ok
powershell -NoProfile -ExecutionPolicy Bypass -File "%JW_TOOLS%\runner_common.ps1" hashcheck "%JW_OUT%" "%JW_TOOLS%" "%JW_HASHES%" strict >> "%JW_ST%" 2>&1
if not errorlevel 1 goto jw_hash_ok
set "JW_FAILED=tools hashcheck"
>> "%JW_ST%" echo FAILED: the watchdog or slot files differ from %JW_HASHES%
goto jw_init_fail
:jw_hash_ok
powershell -NoProfile -ExecutionPolicy Bypass -File "%JW_TOOLS%\runner_common.ps1" preflight-tools "%JW_OUT%" "%~4" >> "%JW_ST%" 2>&1
if not errorlevel 1 goto jw_tools_ok
set "JW_FAILED=preflight: missing tool"
set "JW_RC=2"
goto jw_init_fail
:jw_tools_ok
if exist "%JW_OUT%\tools.cmd" call "%JW_OUT%\tools.cmd"
>> "%JW_ST%" echo [%date% %time%] ready: GPU label %PC_GPU_ISSUE%
exit /b 0
:jw_init_fail
set "JW_STOP=1"
>> "%JW_ST%" echo done FAILED: %JW_FAILED%
>> "%JW_ST%" echo all done %date% %time%
> "%JW_OUT%\done.txt" echo FAILED: %JW_FAILED%
exit /b %JW_RC%

rem ------------------------------------------------------------------ run <seconds> <exe> [args ...]
:jw_run
setlocal EnableExtensions DisableDelayedExpansion
set "JW_RAW=%*"
set "JW_F=%JW_FAILED%"
set "JW_S=%JW_STOP%"
set "JW_RC=0"
set "JW_NAME=%JW_STEP%"
if not defined JW_NAME set "JW_NAME=unnamed step"
if not defined JW_ST goto jw_run_noinit
if not defined JW_STOP goto jw_run_go
>> "%JW_ST%" echo [%date% %time%] skipped %JW_NAME%: an earlier step failed
set "JW_RC=1"
goto jw_run_out
:jw_run_noinit
echo job_wrap: run before init
set "JW_RC=2"
goto jw_run_out
:jw_run_go
set "JW_RC=2"
if not defined PC_GPU_ISSUE (>> "%JW_ST%" echo FAILED: %JW_NAME%: no GPU label, call init first)
if not defined PC_GPU_ISSUE goto jw_run_fail
if not defined JW_STEP (>> "%JW_ST%" echo FAILED: a step has no JW_STEP name)
if not defined JW_STEP goto jw_run_fail
>> "%JW_ST%" echo [%date% %time%] step %JW_NAME% start
set "TMO_STEP=%JW_NAME%"
call "%JW_TOOLS%\tmo.bat" %JW_RAW:~4%
set "JW_RC=%ERRORLEVEL%"
if not "%JW_RC%"=="0" goto jw_run_bad
if not defined JW_EXPECT goto jw_run_ok
set "JW_EMPTY="
for %%E in ("%JW_EXPECT:;=" "%") do call :jw_expect "%%~E"
if not defined JW_EMPTY goto jw_run_ok
>> "%JW_ST%" echo step %JW_NAME%: empty or missing output %JW_EMPTY%
set "JW_RC=3"
goto jw_run_bad
:jw_run_ok
>> "%JW_ST%" echo [%date% %time%] step %JW_NAME% ok
goto jw_run_out
:jw_run_bad
>> "%JW_ST%" echo [%date% %time%] step %JW_NAME% exit %JW_RC%
if not "%JW_OPTIONAL%"=="1" goto jw_run_fail
>> "%JW_ST%" echo optional step %JW_NAME% failed; the job goes on
goto jw_run_out
:jw_run_fail
>> "%JW_ST%" echo FAILED: %JW_NAME%
if defined JW_F set "JW_F=%JW_F%, %JW_NAME%"
if not defined JW_F set "JW_F=%JW_NAME%"
if not "%JW_CONTINUE%"=="1" set "JW_S=1"
:jw_run_out
endlocal & set "JW_FAILED=%JW_F%" & set "JW_STOP=%JW_S%" & set "JW_STEP=" & set "JW_OPTIONAL=" & set "JW_CONTINUE=" & set "JW_EXPECT=" & exit /b %JW_RC%

:jw_expect
if "%~1"=="" exit /b 0
if not exist "%~1" set "JW_EMPTY=%~1"
if not exist "%~1" exit /b 0
set "JW_ATTR=%~a1"
if /i not "%JW_ATTR:~0,1%"=="d" goto jw_expect_file
dir /b /s /a-d "%~1" 2> nul | findstr /r "." > nul
if errorlevel 1 set "JW_EMPTY=%~1"
exit /b 0
:jw_expect_file
if "%~z1"=="0" set "JW_EMPTY=%~1"
exit /b 0

rem ------------------------------------------------------------------ copy <src> <dst> <log> [new]
:jw_copy
setlocal EnableExtensions DisableDelayedExpansion
set "JW_F=%JW_FAILED%"
set "JW_S=%JW_STOP%"
set "JW_RC=0"
set "JW_NAME=copy %~nx2"
if not defined JW_STOP goto jw_copy_go
>> "%JW_ST%" echo [%date% %time%] skipped %JW_NAME%: an earlier step failed
set "JW_RC=1"
goto jw_copy_out
:jw_copy_go
if exist "%~2" goto jw_copy_src
>> "%JW_ST%" echo [%date% %time%] %JW_NAME% skipped: no source %~2
goto jw_copy_out
:jw_copy_src
if /i "%~5"=="new" robocopy "%~2" "%~3" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%~4" 2>&1
if /i not "%~5"=="new" robocopy "%~2" "%~3" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%~4" 2>&1
set "JW_RC=%ERRORLEVEL%"
if %JW_RC% GEQ 8 goto jw_copy_bad
>> "%JW_ST%" echo [%date% %time%] %JW_NAME% ok, robocopy %JW_RC%
set "JW_RC=0"
goto jw_copy_out
:jw_copy_bad
>> "%JW_ST%" echo FAILED: %JW_NAME%, robocopy exit %JW_RC%, see %~4
if defined JW_F set "JW_F=%JW_F%, %JW_NAME%"
if not defined JW_F set "JW_F=%JW_NAME%"
if not "%JW_CONTINUE%"=="1" set "JW_S=1"
:jw_copy_out
endlocal & set "JW_FAILED=%JW_F%" & set "JW_STOP=%JW_S%" & set "JW_CONTINUE=" & exit /b %JW_RC%

rem ------------------------------------------------------------------ fail "<step>", note "<text>"
:jw_fail
>> "%JW_ST%" echo FAILED: %~2
if defined JW_FAILED set "JW_FAILED=%JW_FAILED%, %~2"
if not defined JW_FAILED set "JW_FAILED=%~2"
if not "%JW_CONTINUE%"=="1" set "JW_STOP=1"
set "JW_CONTINUE="
exit /b 1

:jw_note
>> "%JW_ST%" echo [%date% %time%] %~2
exit /b 0

rem ------------------------------------------------------------------ end
:jw_end
if not defined JW_ST echo job_wrap: end before init
if not defined JW_ST exit /b 2
call :jw_janitor
if not defined JW_FAILED goto jw_pass
>> "%JW_ST%" echo done FAILED: %JW_FAILED%
>> "%JW_ST%" echo all done %date% %time%
> "%JW_OUT%\done.txt" echo FAILED: %JW_FAILED%
exit /b 1
:jw_pass
>> "%JW_ST%" echo done PASS
>> "%JW_ST%" echo all done %date% %time%
> "%JW_OUT%\done.txt" echo PASS
exit /b 0

rem Issue 1180: start the janitor's after-job cleanup in its own hidden window, so the job ends now and the queue never
rem waits on it. The janitor itself keeps it to once an hour and skips without a word while another cleanup runs, any GPU
rem claim is held (so no timing is skewed) or the Board's pause is on. JW_NO_JANITOR=1 turns it off (tests).
:jw_janitor
if "%JW_NO_JANITOR%"=="1" exit /b 0
if not exist "%JW_TOOLS%\janitor.ps1" exit /b 0
set "JW_JANITOR=%JW_TOOLS%\janitor.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -WindowStyle Hidden -FilePath powershell.exe -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File \"{0}\" --after-job' -f $env:JW_JANITOR)" > nul 2>&1
set "JW_JANITOR="
exit /b 0
