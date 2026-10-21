@echo off
set /p PYEXE=<"%USERPROFILE%\Downloads\voidsworn_test\python_path.txt"
"%PYEXE%" "%USERPROFILE%\Downloads\voidsworn_test\bake_all.py" %*
echo done > "%USERPROFILE%\Downloads\voidsworn_test\bake_done.txt"
