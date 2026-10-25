@echo off
rem Play the latest Voidsworn test build (B1 plus B2). Double-click this file.
rem It starts a small local web server for the game folder and opens the game in your browser.
rem Close the black "Voidsworn server" window when you are done playing.
cd /d "%~dp0build"
set /p PY=<"%~dp0python_path.txt"
start "Voidsworn server" "%PY%" -m http.server 8765 --bind 127.0.0.1
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:8765/index_test.html"
