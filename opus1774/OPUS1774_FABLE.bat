@echo off
rem Issue 1774: Fable review of the global cohesion package (R418: no caps, thinking and raw stream saved) through the Claude API (no GPU, no ElevenLabs credits, deletes nothing).
setlocal
set "J=%USERPROFILE%\Downloads\voidsworn_test\opus1774"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%\fable_call_1774.js"
endlocal
