@echo off
rem Issue 1657: double-click to DELETE the branches in the newest dry-run list (PRUNE_RELAY_BRANCHES_DRY.bat) from GitHub.
rem It asks you to type YES first. Each branch goes only if it has not moved since the list. Nothing on this PC is deleted.
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prune_relay_branches.ps1" live
echo.
pause
