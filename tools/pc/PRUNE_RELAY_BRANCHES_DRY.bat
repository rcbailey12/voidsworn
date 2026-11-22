@echo off
rem Issue 1657: double-click to LIST the stale board/pc-out and board/pin branches on GitHub. Deletes nothing.
rem The list goes to Downloads\voidsworn_test\prune\. Send it to the Board, then run PRUNE_RELAY_BRANCHES_LIVE.bat only
rem after you say yes in the chat.
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prune_relay_branches.ps1"
echo.
pause
