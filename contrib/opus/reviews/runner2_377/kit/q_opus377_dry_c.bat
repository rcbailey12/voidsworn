@echo off
rem Issue 377 per-run refused folder dry run in its own window, so the queue stays free (Opus worker, Nov 12 2026).
start "opus377 per-run dry run" /min "%COMSPEC%" /c "%USERPROFILE%\Downloads\voidsworn_test\opus377\dry377c.bat"
exit /b 0
