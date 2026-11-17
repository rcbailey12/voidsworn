@echo off
setlocal
set "NODE=node"
if exist "C:\Program Files\nodejs\node.exe" set "NODE=C:\Program Files\nodejs\node.exe"
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
title Voidsworn mission control phone link
"%NODE%" "%~dp0phone.js" on
set "RESULT=%ERRORLEVEL%"
if /i not "%~1"=="nopause" pause
exit /b %RESULT%
