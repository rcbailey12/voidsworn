@echo off
rem Issue 209 round 4: round 3 cells (Ab3, Hy3) rendered at the concept camera too, for the paint sheet. Writes opus209\out4b\r3\.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set R=%O%\repo\tools\blender\r209
if not exist "%O%\out4b\r3" mkdir "%O%\out4b\r3"
"%B%" -b "%O%\out3\Ab3.blend" -P "%R%\render.py" -- "%O%\out4b\r3" Ab3 --views=concept > "%O%\out4b\r3\log_Ab3.txt" 2>&1
"%B%" -b "%O%\out3c\Hy3.blend" -P "%R%\render.py" -- "%O%\out4b\r3" Hy3 --views=concept > "%O%\out4b\r3\log_Hy3.txt" 2>&1
echo done > "%O%\out4b\r3\done.txt"
