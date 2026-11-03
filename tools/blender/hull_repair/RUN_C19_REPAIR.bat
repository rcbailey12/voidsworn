@echo off
setlocal
rem Queue this experiment through the owner's GPU lane and timeout runner.
set "PCROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set "WORK=%TEMP%\voidsworn_issue129"
if not exist "%WORK%" mkdir "%WORK%"
set "JOB=%PCROOT%\queue\repair129_%RANDOM%_%RANDOM%.bat"
> "%WORK%\queue_job.bat" echo @echo off
>> "%WORK%\queue_job.bat" echo call "%~dp0..\..\pc\tmo.bat" 10000 "%PY%" -s -B "%~dp0run.py" --worker --work "%WORK%" ^> "%WORK%\driver.log" 2^>^&1
>> "%WORK%\queue_job.bat" echo exit /b %%ERRORLEVEL%%
copy /y "%WORK%\queue_job.bat" "%JOB%" >nul
echo Queued. Review sheets: %PCROOT%\board\issue-129\shots
echo Progress and logs: %WORK%
pause
