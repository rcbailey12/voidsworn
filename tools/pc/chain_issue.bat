@echo off
rem Usage: chain_issue.bat "predecessor out\status.json" work_issue.bat 642 opus
rem Or: chain_issue.bat "predecessor out\status.json" codex_issue.bat 687
rem The child runner logs and waits on this exact predecessor run before cloning or calling a model.
setlocal
if "%~3"=="" (echo usage: chain_issue.bat status.json work_issue.bat-or-codex_issue.bat issue [arm] & exit /b 2)
if /i "%~2"=="work_issue.bat" goto :valid
if /i "%~2"=="codex_issue.bat" goto :valid
echo runner must be work_issue.bat or codex_issue.bat
exit /b 2
:valid
set "PC_WAIT_FOR=%~1"
call "%~dp0%~2" %3 %4 %5
exit /b %ERRORLEVEL%
