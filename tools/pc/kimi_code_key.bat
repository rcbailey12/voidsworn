@echo off
title Save your Kimi Code key
echo.
echo  Saves your Kimi Code plan key on this PC as a user setting (never in a file).
echo  Get it at https://www.kimi.com/code/console  (a key made there, not on platform.moonshot.ai).
echo  To paste: right-click in this window, then press Enter.
echo.
set "K="
set /p "K=  Kimi Code key: "
if not defined K (echo  Nothing pasted, nothing saved. & pause & exit /b 1)
setx KIMI_CODE_API_KEY "%K%" 1>NUL
set "K="
echo.
echo  Saved. You can close this window. Claude takes it from here.
pause
