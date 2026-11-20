@echo off
rem Issue 1303 smoke (headless only, no GPU timing): proves the shared helper head on Windows before it merges.
rem Pinned: the head from opus/issue-1303 at 1ae2e422f213e946db93a821d55b5cda2aca3a6d, in a read-only copy Downloads\voidsworn_test\opus1303\src_<sha8>.
rem The head is not in tools_live until merge, so cases B to D set OPUS_JOB_HEAD_PREMERGE=1 (the head logs it); job_wrap
rem and the watchdog still come from the current tools_live and are hash-verified. Five cases:
rem   A  the head refuses to start from outside tools_live without that switch (exit 2, nothing made)
rem   B  a real run: init, checkout of the pin in a new attempt folder, ships copy and tracked check, a headless import
rem      and load_all.gd through job_wrap, tail (options hash) -> done PASS, exit 0
rem   C  a short pin: checkout fails, later steps skip, tail -> done FAILED, exit 1
rem   D  leftover wrapper settings (JW_TOOLS and JW_HASHES at a fake folder, PC_REAL_PROFILE=1) are cleared: init passes
rem      against the real current tools_live, tail -> done PASS
rem   E  the watchdog cannot switch mid-job: in a throwaway USERPROFILE (the real tools_live is never touched), stub
rem      versions v1 and v2 hold the pinned tmo.bat; under TMO_OWN_COPY=1 (what the head sets) step 1 runs v1, the pointer
rem      moves to v2, step 2 still runs v1; a control step without it follows the pointer to v2
rem Results: Downloads\voidsworn_test\opus1303\smoke_<stamp>.txt plus each attempt's status.txt. Nothing is deleted.
setlocal EnableExtensions
set "SHA=1ae2e422f213e946db93a821d55b5cda2aca3a6d"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1303"
set "SRC=%H%\src_%SHA:~0,8%"
if not exist "%H%" mkdir "%H%"
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%S"
set "SUM=%H%\smoke_%STAMP%.txt"
set "PASSES=0"
set "B_OUT="
echo smoke1303 start %date% %time% pin %SHA% > "%SUM%"
if exist "%SRC%\.git" goto have_src
git -c core.autocrlf=false clone -q --no-checkout https://github.com/rcbailey12/voidsworn "%SRC%" >> "%SUM%" 2>&1
if errorlevel 1 (echo FAILED: clone >> "%SUM%" & goto out)
:have_src
git -C "%SRC%" fetch -q origin opus/issue-1303 >> "%SUM%" 2>&1
git -C "%SRC%" -c advice.detachedHead=false checkout -q --detach %SHA% >> "%SUM%" 2>&1
if errorlevel 1 (echo FAILED: checkout of the pin >> "%SUM%" & goto out)
for /f %%C in ('git -C "%SRC%" rev-parse HEAD') do set "GOT=%%C"
if not "%GOT%"=="%SHA%" (echo FAILED: source copy is at %GOT%, not %SHA% >> "%SUM%" & goto out)
git -C "%SRC%" status --porcelain --untracked-files=no > "%H%\src_status_%STAMP%.txt"
for %%A in ("%H%\src_status_%STAMP%.txt") do if %%~zA GTR 0 (echo FAILED: the source copy has local changes >> "%SUM%" & goto out)
set "HEADBAT=%SRC%\tools\pc\jobs\opus_job_head.bat"

call :case_a
if "%RC%"=="2" (echo PASS A: head outside tools_live refused, exit 2 >> "%SUM%" & set /a PASSES+=1) else (echo FAILED A: exit %RC%, expected 2 >> "%SUM%")
call :case_b
if "%RC%"=="0" (echo PASS B: full run done PASS, exit 0, attempt %B_OUT% >> "%SUM%" & set /a PASSES+=1) else (echo FAILED B: exit %RC%, see %B_OUT%\status.txt >> "%SUM%")
call :case_c
if "%RC%"=="1" (echo PASS C: short pin refused, done FAILED, exit 1, attempt %C_OUT% >> "%SUM%" & set /a PASSES+=1) else (echo FAILED C: exit %RC%, expected 1, see %C_OUT%\status.txt >> "%SUM%")
call :case_d
if "%RC%"=="0" (echo PASS D: leftover JW_TOOLS, JW_HASHES and PC_REAL_PROFILE cleared, done PASS, attempt %D_OUT% >> "%SUM%" & set /a PASSES+=1) else (echo FAILED D: exit %RC%, see %D_OUT%\status.txt >> "%SUM%")
call :case_e
if "%RC%"=="0" (echo PASS E: steps 1 and 2 both ran v1 after the pointer moved to v2; the control step ran v2 >> "%SUM%" & set /a PASSES+=1) else (echo FAILED E: %E_WHY%, see %H%\case_e_%STAMP% >> "%SUM%")
:out
echo smoke1303 end %date% %time%: %PASSES% of 5 cases passed >> "%SUM%"
type "%SUM%"
if defined B_OUT if exist "%B_OUT%\status.txt" (echo ---- B status & type "%B_OUT%\status.txt")
if "%PASSES%"=="5" exit /b 0
exit /b 1

:case_a
setlocal
set "OPUS_JOB_HEAD_PREMERGE="
call "%HEADBAT%" init opus1303 1303 "godot" > "%H%\case_a_%STAMP%.txt" 2>&1
endlocal & set "RC=%ERRORLEVEL%"
exit /b 0

:case_b
setlocal
set "OPUS_JOB_HEAD_PREMERGE=1"
call "%HEADBAT%" init opus1303 1303 "godot"
if errorlevel 1 (endlocal & set "RC=%ERRORLEVEL%" & set "B_OUT=init-failed" & exit /b 0)
call "%HEADBAT%" checkout new %SHA%
call "%HEADBAT%" ships
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
set "JW_STEP=load_all" & set "JW_EXPECT=%OJ_OUT%\load_all.txt" & call "%JW%" run 900 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://tools/ci/load_all.gd > "%OJ_OUT%\load_all.txt" 2>&1
call "%HEADBAT%" tail
endlocal & set "RC=%ERRORLEVEL%" & set "B_OUT=%OJ_OUT%"
exit /b 0

:case_c
setlocal
set "OPUS_JOB_HEAD_PREMERGE=1"
call "%HEADBAT%" init opus1303neg 1303 "godot"
if errorlevel 1 (endlocal & set "RC=%ERRORLEVEL%" & set "C_OUT=init-failed" & exit /b 0)
call "%HEADBAT%" checkout new %SHA:~0,8%
call "%HEADBAT%" ships
set "JW_STEP=import" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
call "%HEADBAT%" tail
endlocal & set "RC=%ERRORLEVEL%" & set "C_OUT=%OJ_OUT%"
exit /b 0

:case_d
setlocal
set "OPUS_JOB_HEAD_PREMERGE=1"
set "JW_TOOLS=%H%\fake_tools\pc"
set "JW_HASHES=%H%\fake_tools\hashes.txt"
set "PC_REAL_PROFILE=1"
call "%HEADBAT%" init opus1303d 1303 "godot"
if errorlevel 1 (endlocal & set "RC=%ERRORLEVEL%" & set "D_OUT=init-failed" & exit /b 0)
>> "%OJ_ST%" echo case D after init: JW_TOOLS=%JW_TOOLS% PC_REAL_PROFILE=[%PC_REAL_PROFILE%] TMO_OWN_COPY=[%TMO_OWN_COPY%]
call "%HEADBAT%" tail
endlocal & set "RC=%ERRORLEVEL%" & set "D_OUT=%OJ_OUT%"
exit /b 0

:case_e
setlocal
set "E=%H%\case_e_%STAMP%"
set "FL=%E%\profile\Downloads\voidsworn_test\tools_live"
mkdir "%FL%\v1\pc" "%FL%\v2\pc"
copy /y "%SRC%\tools\pc\tmo.bat" "%FL%\v1\pc\tmo.bat" > nul
copy /y "%SRC%\tools\pc\tmo.bat" "%FL%\v2\pc\tmo.bat" > nul
> "%FL%\v1\pc\run_timeout.ps1" echo Write-Output 'STUB v1'
> "%FL%\v2\pc\run_timeout.ps1" echo Write-Output 'STUB v2'
> "%FL%\current.txt" echo v1
set "USERPROFILE=%E%\profile"
set "PC_RUNNER_TEST="
set "TMO_OWN_COPY=1"
call "%FL%\v1\pc\tmo.bat" 5 cmd > "%E%\step1.txt" 2>&1
> "%FL%\current.txt" echo v2
call "%FL%\v1\pc\tmo.bat" 5 cmd > "%E%\step2.txt" 2>&1
set "TMO_OWN_COPY="
call "%FL%\v1\pc\tmo.bat" 5 cmd > "%E%\control.txt" 2>&1
set "WHY="
findstr /c:"STUB v1" "%E%\step1.txt" > nul || set "WHY=step 1 did not run v1"
findstr /c:"STUB v1" "%E%\step2.txt" > nul || set "WHY=step 2 switched watchdog after the pointer moved"
findstr /c:"STUB v2" "%E%\control.txt" > nul || set "WHY=the control step did not follow the pointer"
if defined WHY (endlocal & set "RC=1" & set "E_WHY=%WHY%" & exit /b 0)
endlocal & set "RC=0"
exit /b 0
