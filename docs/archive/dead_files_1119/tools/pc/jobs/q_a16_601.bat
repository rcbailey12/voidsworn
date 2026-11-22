@echo off
rem issue 601: start the A16 paint run in its own window, so the queue stays free (q_flash246.bat pattern)
start "A16 601" cmd /c "%USERPROFILE%\Downloads\voidsworn_test\A16_RUN_601.bat"
echo launched
exit /b 0
