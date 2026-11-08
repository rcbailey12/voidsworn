@echo off
rem Workhorse setup (#217, Opus, Nov 7 2026). Double-click it once (from Downloads\voidsworn_test as WORKHORSE_SETUP.bat, or
rem from tools\pc). It installs OpenCode, asks for the DeepSeek and Moonshot API keys once each (saved as user settings, never
rem in a file), checks both keys and balances, then asks each model for one word through OpenCode to prove the whole headless
rem path works on this PC (a fraction of a cent). Safe to run again: press Enter at a key prompt to keep the saved key.
rem Result: Downloads\voidsworn_test\work217\setup_result.txt (log: setup_log.txt). Nothing is deleted.
setlocal
title Workhorse setup
set "T=%~dp0"
if not exist "%T%work_issue.ps1" set "T=%~dp0work217\tools\"
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;%APPDATA%\npm;%PATH%"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\work217"
if not exist "%W%" mkdir "%W%"
set "LOG=%W%\setup_log.txt"
set "RES=%W%\setup_result.txt"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%T%work_issue.ps1""
set "OC=%APPDATA%\npm\opencode.cmd"
set "OCWANT=1.19.5"
set "SHELL=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe"
set "OPENCODE_DISABLE_AUTOUPDATE=1"
set "OPENCODE_DISABLE_MODELS_FETCH=1"
set "OPENCODE_CONFIG=%T%work\opencode.json"
set FAILS=0
echo Workhorse setup %date% %time% > "%LOG%"
echo Workhorse setup %date% %time% > "%RES%"
echo.
echo  Workhorse setup: installs OpenCode, saves your two API keys, and checks that both models answer.
echo.

echo [1/4] Installing OpenCode %OCWANT% ...
call npm i -g opencode-ai@%OCWANT% >> "%LOG%" 2>&1
set "OCV="
for /f "delims=" %%v in ('call "%OC%" --version 2^>nul') do set "OCV=%%v"
if "%OCV%"=="%OCWANT%" (
  echo       OpenCode %OCV% is installed.
  echo OpenCode %OCV% installed: PASS >> "%RES%"
) else (
  echo       FAIL: OpenCode did not install ^(got "%OCV%"^). Details in work217\setup_log.txt
  echo OpenCode install: FAIL, version "%OCV%" >> "%RES%"
  set /a FAILS+=1
)

echo.
echo [2/4] Your API keys. To paste, right-click in this window, then press Enter.
call :getkey DEEPSEEK_API_KEY
call :getkey MOONSHOT_API_KEY
call :askkey DEEPSEEK_API_KEY DeepSeek platform.deepseek.com
call :askkey MOONSHOT_API_KEY Moonshot platform.kimi.ai

echo.
echo [3/4] Checking the keys and balances ...
call :checkkey deepseek DeepSeek
call :checkkey kimi Moonshot

echo.
echo [4/4] Does OpenCode start on this PC and get an answer from each model?
call :ready deepseek deepseek/deepseek-flash DeepSeek
call :ready kimi moonshotai/kimi-k3.1-pro Kimi

echo.
if %FAILS%==0 (
  echo  ALL PASS. Setup is done. Tell Opus, or double-click WORKHORSE_TRIAL.bat when you are ready.
  echo ALL PASS >> "%RES%"
) else (
  echo  %FAILS% step^(s^) failed. Tell Opus; the details are in work217\setup_result.txt.
  echo %FAILS% FAILED >> "%RES%"
)
echo.
pause
exit /b %FAILS%

:getkey
for /f "tokens=2,*" %%a in ('reg query HKCU\Environment /v %1 2^>nul ^| findstr /c:"REG_"') do set "%1=%%b"
exit /b 0

:askkey
set "NEW="
if defined %1 echo       A %2 key is already saved. Paste a new one to replace it, or just press Enter to keep it.
if not defined %1 echo       Paste your %2 API key ^(from %3^).
set /p "NEW=      %2 key: "
if not defined NEW goto :askdone
set "NEW=%NEW: =%"
setx %1 "%NEW%" > nul
set "%1=%NEW%"
echo       Saved.
:askdone
set "NEW="
exit /b 0

:checkkey
%PS% keycheck %1 > "%W%\keycheck_%1.txt" 2>&1
if errorlevel 1 (
  echo       %2 key: FAIL, the key was refused. Check it on the %2 site and run setup again.
  echo %2 key: FAIL >> "%RES%"
  type "%W%\keycheck_%1.txt" >> "%LOG%"
  set /a FAILS+=1
  exit /b 0
)
%PS% balance %1 "%W%\balance_%1.txt" > nul
set "BAL="
set /p BAL=<"%W%\balance_%1.txt"
echo       %2 key works. Balance: %BAL%
echo %2 key: PASS, balance %BAL% >> "%RES%"
type "%W%\keycheck_%1.txt" >> "%LOG%"
exit /b 0

:ready
call "%T%tmo.bat" 300 "%OC%" run --auto --format json -m %2 --dir "%W%" "Reply with the single word READY and nothing else." > "%W%\ready_%1.jsonl" 2> "%W%\ready_%1_err.txt"
%PS% lasttext "%W%\ready_%1.jsonl" > "%W%\ready_%1_answer.txt" 2>&1
set "ANS="
set /p ANS=<"%W%\ready_%1_answer.txt"
findstr /i "READY" "%W%\ready_%1_answer.txt" > nul
if errorlevel 1 (
  echo       %3: FAIL, no answer through OpenCode. Opus checks work217\ready_%1.jsonl.
  echo %3 through OpenCode: FAIL >> "%RES%"
  findstr /i /c:"opencode run [message" "%W%\ready_%1.jsonl" > nul && echo %3: OpenCode printed its help text instead of running ^(the known Windows bug^) >> "%RES%"
  set /a FAILS+=1
) else (
  echo       %3 answered through OpenCode: %ANS%
  echo %3 through OpenCode: PASS >> "%RES%"
)
exit /b 0
