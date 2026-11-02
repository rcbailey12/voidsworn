@echo off
rem Voidsworn: Codex job-board watcher (Ryan, Nov 2 2026). Leave this window open (minimised is fine).
rem Every 10 minutes it checks GitHub for open issues labeled "codex" and queues each new one for Codex on lane B.
rem Codex then works the issue in Downloads\voidsworn_test\board\repo and pushes a codex/issue-<n> branch;
rem GitHub opens the pull request and runs the checks by itself. Close this window to stop.
title Voidsworn Codex board watcher
:loop
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Downloads\voidsworn_test\build_b\tools\pc\codex_board.ps1"
timeout /t 600 /nobreak >nul
goto loop
