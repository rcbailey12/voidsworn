@echo off
setlocal
set "BPY=%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
"%BPY%" -B "%~dp0stage_recipe.py" %*
set "RESULT=%ERRORLEVEL%"
if not defined RECIPE_NOPAUSE pause
exit /b %RESULT%
