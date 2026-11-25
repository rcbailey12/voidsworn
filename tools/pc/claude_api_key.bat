@echo off
title Save your Claude API key for the game runner
echo.
echo  Saves the API key from platform.claude.com (Ryan's Individual Org, the Max plan's $100 a month of credits)
echo  on this PC as a user setting named VOIDSWORN_CLAUDE_API_KEY (never in a file).
echo  It is NOT saved as ANTHROPIC_API_KEY on purpose: that name would switch your own Claude Code to API billing.
echo  The key is read without showing it on screen.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = Read-Host -AsSecureString '  Claude API key: '; $b = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try { $k = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }; if ([string]::IsNullOrEmpty($k)) { exit 1 }; try { [System.Environment]::SetEnvironmentVariable('VOIDSWORN_CLAUDE_API_KEY', $k, 'User') } catch { exit 1 }; $k = $null"
if errorlevel 1 (echo  Nothing saved. Check your paste and try again. & pause & exit /b 1)
echo.
echo  Saved. You can close this window. Claude takes it from here.
pause
