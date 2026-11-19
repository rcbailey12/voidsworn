@echo off
setlocal
title Save your OpenAI API key for the game runner
echo.
echo  Saves the API key from platform.openai.com for the game runner's OpenAI arm
echo  on this PC as a user setting named VOIDSWORN_OPENAI_API_KEY (never in a file).
echo  It is NOT saved as OPENAI_API_KEY on purpose: that name could switch your own Codex to API billing.
echo  To paste: right-click in this window, then press Enter.
echo.
set "K="
set /p "K=  OpenAI API key: "
if not defined K (echo  Nothing pasted, nothing saved. & pause & exit /b 1)
setx VOIDSWORN_OPENAI_API_KEY "%K%" 1>NUL
if errorlevel 1 (set "K=" & echo  Could not save the key. Nothing else changed. & pause & exit /b 1)
set "K="
echo.
echo  Saved. You can close this window. The Board takes it from here.
pause
