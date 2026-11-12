@echo off
rem Issue 377 dry runs: start them in their own window so the queue stays free (Opus worker, Nov 12 2026).
start "opus377 dry runs" /min "%COMSPEC%" /c "%USERPROFILE%\Downloads\voidsworn_test\opus377\dry377.bat"
exit /b 0
