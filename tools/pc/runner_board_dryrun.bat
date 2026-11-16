@echo off
rem Read-only board audit. No claims, checkout, agent, commit or push.
setlocal
set "AUDIT_OUT=%TEMP%\voidsworn-board-audit-%RANDOM%-%RANDOM%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0runner_common.ps1" board-dryrun "%AUDIT_OUT%"
set "AUDIT_EXIT=%ERRORLEVEL%"
echo Audit saved in %AUDIT_OUT%
pause
exit /b %AUDIT_EXIT%
