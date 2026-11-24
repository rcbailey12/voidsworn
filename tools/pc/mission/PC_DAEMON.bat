@echo off
rem Issue 1662: the label-driven PC runner daemon (pc_daemon.js). Double-click: a dry run that reads GitHub once and
rem lists what it would run; it changes nothing. "PC_DAEMON.bat live" runs jobs; the Board turns that on only after
rem its review and a PC proof. To stop a live daemon between jobs, create voidsworn_test\pc_daemon\stop.txt.
setlocal
set "NODE=node"
if exist "C:\Program Files\nodejs\node.exe" set "NODE=C:\Program Files\nodejs\node.exe"
if exist "%USERPROFILE%\Downloads\voidsworn_test\node\node.exe" set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
title Voidsworn PC daemon
if /i "%~1"=="live" ("%NODE%" "%~dp0pc_daemon.js" --live) else ("%NODE%" "%~dp0pc_daemon.js" --once)
set "RESULT=%ERRORLEVEL%"
if /i not "%~1"=="live" pause
exit /b %RESULT%
