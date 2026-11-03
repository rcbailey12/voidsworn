@echo off
setlocal
rem Queue the prototype on GPU lane A. No game files are replaced.
set "PCROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set "WORK=%TEMP%\voidsworn_issue75"
if not exist "%WORK%" mkdir "%WORK%"
set "JOB=%PCROOT%\queue\surface75_%RANDOM%_%RANDOM%.bat"
> "%WORK%\queue_job.bat" echo @echo off
>> "%WORK%\queue_job.bat" echo call "%~dp0..\..\pc\tmo.bat" 2400 "%PY%" -s "%~dp0run.py" --worker --work "%WORK%" ^> "%WORK%\driver.log" 2^>^&1
>> "%WORK%\queue_job.bat" echo exit /b %%ERRORLEVEL%%
copy /y "%WORK%\queue_job.bat" "%JOB%" >nul
echo Queued. Results: %WORK%\driver.log
echo Review sheets: docs\shots\ship_pipeline\issue75
pause
