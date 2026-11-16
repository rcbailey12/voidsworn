@echo off
rem Pause every Board job on the PC without losing or deleting anything (Ryan, Nov 15 2026; RULEBOOK 3, the pause rule).
rem Double-click to pause now, or: pause_all.bat 19:25  to pause at that time. Logs to Downloads\voidsworn_test\pc_pause.txt.
title PC pause (Board)
set "PA="
if not "%~1"=="" set "PA=-At %~1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pause_all.ps1" %PA%
