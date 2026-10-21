@echo off
set T=%USERPROFILE%\Downloads\voidsworn_test
if exist %T%\rocks rmdir /s /q %T%\rocks
mkdir %T%\rocks
for %%z in (rocks1 rocks2 rocks3 rocks4) do tar -xf %T%\%%z.zip -C %T%\rocks
set /p PYEXE=<%T%\python_path.txt
set PYTHONPATH=
"%PYEXE%" %T%\rocks_bake.py
cd /d %T%\rocks
if exist %T%\rocks_baked.zip del %T%\rocks_baked.zip
tar -a -cf %T%\rocks_baked.zip rocks_bake rocks_bake_lo
echo done > %T%\rocks_done.txt
