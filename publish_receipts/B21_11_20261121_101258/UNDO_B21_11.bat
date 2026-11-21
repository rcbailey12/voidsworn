@echo off
rem Issue 1311: put B21_11 in build\godot back as it was before the publish of 20261121_101258 from opus1291c11g. Deletes nothing.
setlocal EnableExtensions
if not exist "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_profile\Roaming" mkdir "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_profile\Roaming" "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_profile\Local"
set "APPDATA=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_profile\Roaming"
set "LOCALAPPDATA=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_profile\Local"
set "U=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\undo_%RANDOM%.txt"
set "TLV="
if exist "C:\Users\rcbai\Downloads\voidsworn_test\tools_live\current.txt" set /p TLV=<"C:\Users\rcbai\Downloads\voidsworn_test\tools_live\current.txt"
set "TMO=C:\Users\rcbai\Downloads\voidsworn_test\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" echo no watchdog at %TMO% > "%U%"
if not exist "%TMO%" goto failed
call "%TMO%" 600 "C:\Users\rcbai\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" -B "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\tool\publish_ship.py" undo "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" B21_11 "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258" > "%U%" 2>&1
if errorlevel 1 goto failed
call "%TMO%" 2400 "C:\Users\rcbai\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" -B "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\B21_11_20261121_101258\tool\publish_ship.py" locked "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" --script res://render/build_assets.gd -- --ships-only >> "%U%" 2>&1
if errorlevel 1 goto failed
echo undo of B21_11 PASS >> "%U%"
echo undo of B21_11 PASS, log in %U%
exit /b 0
:failed
echo undo of B21_11 FAILED, see %U% >> "%U%"
echo undo of B21_11 FAILED, see %U%
exit /b 1
