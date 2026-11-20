@echo off
rem Issue 1180: one shared base for helper PC jobs. Usage: call helper_clone.bat <job folder> <branch> [ships]
rem Makes or reuses <job folder>\repo from the shared repo-mirror.git (objects shared, no new download), checks out
rem <branch>, and with "ships" copies the checked ship files from build\godot. Exit 0 on success. See helper_clone.ps1.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0helper_clone.ps1" -JobDir "%~1" -Branch "%~2" -Ships "%~3"
exit /b %ERRORLEVEL%
