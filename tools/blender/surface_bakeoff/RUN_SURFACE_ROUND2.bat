@echo off
setlocal
rem Queue issue 111 on GPU lane A. All game work is isolated under TEMP.
set "PCROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set "WORK=%TEMP%\voidsworn_issue111"
if not exist "%WORK%" mkdir "%WORK%"
set "JOB=%PCROOT%\queue\surface111_%RANDOM%_%RANDOM%.bat"
> "%WORK%\queue_job.bat" echo @echo off
>> "%WORK%\queue_job.bat" echo call "%~dp0..\..\pc\tmo.bat" 3000 "%PY%" -s "%~dp0round2_run.py" --worker --work "%WORK%" ^> "%WORK%\driver.log" 2^>^&1
>> "%WORK%\queue_job.bat" echo exit /b %%ERRORLEVEL%%
copy /y "%WORK%\queue_job.bat" "%JOB%" >nul
echo Queued. Review sheets: docs\shots\ship_pipeline\issue75b
echo Full screenshots: %PCROOT%\board\issue-111\shots
pause
