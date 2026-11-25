@echo off
setlocal
title Save your OpenAI API key for the game runner
echo.
echo  Saves the API key from platform.openai.com for the game runner's OpenAI arm
echo  on this PC as a user setting named VOIDSWORN_OPENAI_API_KEY (never in a file).
echo  It is NOT saved as OPENAI_API_KEY on purpose: that name could switch your own Codex to API billing.
echo  The key is read without showing it on screen.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = Read-Host -AsSecureString '  OpenAI API key: '; $b = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try { $k = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }; if ([string]::IsNullOrEmpty($k)) { exit 1 }; try { [System.Environment]::SetEnvironmentVariable('VOIDSWORN_OPENAI_API_KEY', $k, 'User') } catch { exit 1 }; $k = $null"
if errorlevel 1 (echo  Nothing saved. Check your paste and try again. & pause & exit /b 1)
echo.
echo  Saved. You can close this window. The Board takes it from here.
pause
