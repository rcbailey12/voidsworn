@echo off
setlocal
title Save your ElevenLabs API key for the sound jobs
echo.
echo  Saves the API key from elevenlabs.io (Settings, API keys) for the sound generation jobs
echo  on this PC as a user setting named VOIDSWORN_ELEVENLABS_API_KEY (never in a file, never in the repo).
echo  Tip: when you make the key, allow only Sound Effects and Music, and set a credit cap.
echo  To paste: right-click in this window, then press Enter.
echo.
set "K="
set /p "K=  ElevenLabs API key: "
if not defined K (echo  Nothing pasted, nothing saved. & pause & exit /b 1)
setx VOIDSWORN_ELEVENLABS_API_KEY "%K%" 1>NUL
if errorlevel 1 (set "K=" & echo  Could not save the key. Nothing else changed. & pause & exit /b 1)
set "K="
echo.
echo  Saved. You can close this window. The Board takes it from here.
pause
