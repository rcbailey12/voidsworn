@echo off
rem Issue 1311: put ithar_GW4 in build\godot back as it was before the publish of 20261121_211313 from opus1373gw4n. Deletes nothing.
setlocal EnableExtensions
if not exist "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_profile\Roaming" mkdir "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_profile\Roaming" "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_profile\Local"
set "APPDATA=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_profile\Roaming"
set "LOCALAPPDATA=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_profile\Local"
set "U=C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\undo_%RANDOM%.txt"
set "TLV="
if exist "C:\Users\rcbai\Downloads\voidsworn_test\tools_live\current.txt" set /p TLV=<"C:\Users\rcbai\Downloads\voidsworn_test\tools_live\current.txt"
set "TMO=C:\Users\rcbai\Downloads\voidsworn_test\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" echo no watchdog at %TMO% > "%U%"
if not exist "%TMO%" goto failed
call "%TMO%" 600 "C:\Users\rcbai\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" -B "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\tool\publish_ship.py" undo "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" ithar_GW4 "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313" > "%U%" 2>&1
if errorlevel 1 goto failed
call "%TMO%" 2400 "C:\Users\rcbai\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" -B "C:\Users\rcbai\Downloads\voidsworn_test\build\godot\_replaced\ithar_GW4_20261121_211313\tool\publish_ship.py" locked "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\rcbai\Downloads\voidsworn_test\build\godot" --script res://render/build_assets.gd -- --ships-only >> "%U%" 2>&1
if errorlevel 1 goto failed
echo undo of ithar_GW4 PASS >> "%U%"
echo undo of ithar_GW4 PASS, log in %U%
exit /b 0
:failed
echo undo of ithar_GW4 FAILED, see %U% >> "%U%"
echo undo of ithar_GW4 FAILED, see %U%
exit /b 1
