@echo off
rem R427 (Ryan Nov 23 14:22 UTC): Fable review of all of Neon's Nov 23 reviews through the Claude API (no GPU, deletes nothing). Paid: about $6 to $12.
setlocal
set "J=%USERPROFILE%\Downloads\voidsworn_test\opus1844f"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%\fable_call_neon1123.js"
endlocal
