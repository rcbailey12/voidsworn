@echo off
rem Issue 1180: one shared base for helper PC jobs. See helper_clone.ps1.
rem   call helper_clone.bat <job folder> <branch> [ships] [job steps .bat]
rem     Makes or reuses <job folder>\repo from the shared repo-mirror.git (objects shared, no new download), checks out
rem     <branch>, with "ships" copies the checked ship files from build\godot (stopping if that would overwrite local
rem     work), then runs the job steps while holding the folder's lease. Exit: the job steps' exit code, 1 on a stop.
rem   call helper_clone.bat <job folder> release
rem     After the Board relays a PASS: removes this folder's own ship copies and import cache. The clone stays.
if /i "%~2"=="release" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0helper_clone.ps1" -JobDir "%~1" -Release
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0helper_clone.ps1" -JobDir "%~1" -Branch "%~2" -Ships "%~3" -Steps "%~4"
)
exit /b %ERRORLEVEL%
