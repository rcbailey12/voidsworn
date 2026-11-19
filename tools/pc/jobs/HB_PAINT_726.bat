@echo off
rem Issue 726 run 4: per-material 16-bit patchwork heights, then one GPU normal pass.
rem Copy of the HB_PAINT_R240 route, with checked exits and before/after pictures.
setlocal
for %%I in ("%~dp0..\..\..") do set "PAINT_REPO=%%~fI"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0hb_paint_726.ps1" -Repo "%PAINT_REPO%"
exit /b %ERRORLEVEL%
