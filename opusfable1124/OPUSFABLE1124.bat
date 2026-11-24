@echo off
rem Board Nov 24: two Fable PR reviews through the Claude API (Ryan Nov 24 02:01 UTC: "start using the claude api credits"). No GPU, no ElevenLabs, deletes nothing.
rem 1445 at 98926849 (loading), then 1914 at 86049dda (brisk camera). About $4 to $6 each; Board cap for both $15. Output out_<name>\review.md, then the Board relays it.
setlocal
set "J=%~dp0"
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" set "NODE=node"
if not defined VOIDSWORN_CLAUDE_API_KEY for /f "tokens=3" %%a in ('reg query HKCU\Environment /v VOIDSWORN_CLAUDE_API_KEY 2^>nul ^| findstr /i VOIDSWORN_CLAUDE_API_KEY') do set "VOIDSWORN_CLAUDE_API_KEY=%%a"
"%NODE%" "%J%fable_call.js" 1445
"%NODE%" "%J%fable_call.js" 1914
> "%J%OPUSFABLE1124_exit.txt" echo OPUSFABLE1124 exit
endlocal
