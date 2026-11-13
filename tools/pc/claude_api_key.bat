@echo off
title Save your Claude API key for the game runner
echo.
echo  Saves the API key from platform.claude.com (Ryan's Individual Org, the Max plan's $100 a month of credits)
echo  on this PC as a user setting named VOIDSWORN_CLAUDE_API_KEY (never in a file).
echo  It is NOT saved as ANTHROPIC_API_KEY on purpose: that name would switch your own Claude Code to API billing.
echo  To paste: right-click in this window, then press Enter.
echo.
set "K="
set /p "K=  Claude API key: "
if not defined K (echo  Nothing pasted, nothing saved. & pause & exit /b 1)
setx VOIDSWORN_CLAUDE_API_KEY "%K%" 1>NUL
set "K="
echo.
echo  Saved. You can close this window. Claude takes it from here.
pause
