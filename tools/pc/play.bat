@echo off
rem Play the latest Voidsworn test build. Double-click this file.
rem It starts a small local web server for the game folder and opens the game in Microsoft Edge
rem (a separate browser from your Chrome, so a stuck Chrome cannot slow the game down).
rem Close the black "Voidsworn server" window when you are done playing.
cd /d "%~dp0build"
set /p PY=<"%~dp0python_path.txt"
start "Voidsworn server" "%PY%" -m http.server 8765 --bind 127.0.0.1
timeout /t 2 /nobreak >nul
start "" msedge --new-window "http://127.0.0.1:8765/index_test.html"
