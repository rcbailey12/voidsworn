@echo off
title Save your Kimi Code key
echo.
echo  Saves your Kimi Code plan key on this PC as a user setting (never in a file).
echo  Get it at https://www.kimi.com/code/console  (a key made there, not on platform.moonshot.ai).
echo  The key is read without showing it on screen.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = Read-Host -AsSecureString '  Kimi Code key: '; $b = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try { $k = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }; if ([string]::IsNullOrEmpty($k)) { exit 1 }; try { [System.Environment]::SetEnvironmentVariable('KIMI_CODE_API_KEY', $k, 'User') } catch { exit 1 }; $k = $null"
if errorlevel 1 (echo  Nothing saved. Check your paste and try again. & pause & exit /b 1)
echo.
echo  Saved. You can close this window. Claude takes it from here.
pause
