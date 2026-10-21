@echo off
REM Voidsworn PC test runner: one-time setup (Python 3.12 per-user, portable Node, Playwright + Chromium)
cd /d "%~dp0"
echo Setup started %date% %time% > setup_log.txt
where py >nul 2>&1 && (py -3 --version >> setup_log.txt 2>&1) || (
  echo Installing Python 3.12 via winget... >> setup_log.txt
  winget install -e --id Python.Python.3.12 --scope user --silent --accept-package-agreements --accept-source-agreements >> setup_log.txt 2>&1
)
set "PYEXE="
for /f "delims=" %%i in ('py -3 -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%i"
if "%PYEXE%"=="" if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PYEXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if "%PYEXE%"=="" (echo ERROR python not found after install >> setup_log.txt & echo SETUP FAILED > setup_done.txt & exit /b 1)
echo Python: %PYEXE% >> setup_log.txt
echo %PYEXE%> python_path.txt
"%PYEXE%" -m pip install --upgrade pip playwright >> setup_log.txt 2>&1
"%PYEXE%" -m playwright install chromium >> setup_log.txt 2>&1
if not exist node\node.exe (
  echo Downloading portable Node 22... >> setup_log.txt
  powershell -NoProfile -Command "Invoke-WebRequest https://nodejs.org/dist/v22.11.0/node-v22.11.0-win-x64.zip -OutFile node.zip; Expand-Archive node.zip -DestinationPath nodetmp -Force; Move-Item nodetmp\node-v22.11.0-win-x64 node; Remove-Item node.zip; Remove-Item nodetmp -Recurse" >> setup_log.txt 2>&1
)
node\node.exe --version >> setup_log.txt 2>&1
"%PYEXE%" -c "import playwright;print('playwright ok')" >> setup_log.txt 2>&1
echo SETUP DONE %date% %time% >> setup_log.txt
echo SETUP DONE > setup_done.txt
