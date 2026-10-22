@echo off
set L=..\smoke_log.txt
echo --- texture download (ambientCG CC0, 2K JPG) --- >> %L%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tex_dl.ps1" >> %L% 2>&1
echo --- textures done --- >> %L%
cd /d "%~dp0"
