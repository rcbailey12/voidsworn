@echo off
rem Build sheet renders (issue 532). Double-click, or give ship codes: render_sheets.bat corsair_A16 corsair_A17
rem Writes Downloads\voidsworn_test\build_sheets\<ship>\ (renders, model json, blockout .blend). Then run layout.py on that folder.
setlocal
set B=%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe
set O=%USERPROFILE%\Downloads\voidsworn_test\build_sheets
set S=%*
if "%S%"=="" set S=corsair_A16 corsair_A17
for %%X in (%S%) do (
  echo rendering %%X
  "%B%" -b -P "%~dp0build.py" -- %%X "%O%\%%X" render > "%O%_%%X.log" 2>&1
)
echo done. Pictures are in %O%
pause
