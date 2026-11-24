@echo off
rem Board Nov 24: four Fable PR reviews through the Claude API (R446, R447). No GPU, no ElevenLabs, deletes nothing.
rem 1925 at fee505f3 (Astra Warden), 1874 at 8caeab8a (movement 2), 1737 at 33561155 (wrecks), 1772 at 7c734f53 (props). About $2 to $4 each.
rem Output out_<name>\review.md, then the Board relays it. Starts only on Ryan's typed go in the Board thread.
setlocal
set "J=%~dp0"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%fable_call.js" 1925
"%NODE%" "%J%fable_call.js" 1874
"%NODE%" "%J%fable_call.js" 1737
"%NODE%" "%J%fable_call.js" 1772
> "%J%OPUSFABLE1124B_exit.txt" echo OPUSFABLE1124B exit
endlocal
