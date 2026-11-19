@echo off
rem Opus helper 1204 (PR 1216): bot runs and look bench on the branch, in its own window.
start "Opus 1204: quit clean + look bench" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1204\go1204.bat"
exit /b
