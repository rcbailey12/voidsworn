@echo off
rem Portable safe mode. Keep this file beside Voidsworn.exe and Voidsworn.pck.
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0" || exit /b 1
"%~dp0Voidsworn.exe" --rendering-method gl_compatibility %*
set "PLAY_RC=%ERRORLEVEL%"
popd
exit /b %PLAY_RC%
