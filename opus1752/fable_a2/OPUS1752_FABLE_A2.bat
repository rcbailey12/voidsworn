@echo off
rem Issue 1752: Fable audit of the Wave A2 ear audit through the Claude API (no GPU, no ElevenLabs credits, deletes nothing).
rem Runs from its own folder; output lands in out_a2 next to this file.
setlocal
set "J=%~dp0"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%fable_call_a2.js"
endlocal
