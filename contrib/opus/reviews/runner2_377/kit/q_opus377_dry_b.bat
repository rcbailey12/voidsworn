@echo off
rem Issue 377 confirmation dry run in its own window, so the queue stays free (Opus worker, Nov 12 2026).
start "opus377 confirmation dry run" /min "%COMSPEC%" /c "%USERPROFILE%\Downloads\voidsworn_test\opus377\dry377b.bat"
exit /b 0
