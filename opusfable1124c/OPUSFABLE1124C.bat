@echo off
rem Board Nov 24: two holistic Fable reviews through the Claude API (Ryan Nov 24 04:15 UTC in the Board thread). No GPU, deletes nothing.
rem lore = story and faction text on main; fx = graphics and effects code and look rules on main. About $6 to $8 each.
setlocal
set "J=%~dp0"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%fable_call.js" lore
"%NODE%" "%J%fable_call.js" fx
> "%J%OPUSFABLE1124C_exit.txt" echo OPUSFABLE1124C exit
endlocal
