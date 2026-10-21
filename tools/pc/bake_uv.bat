@echo off
set T=%USERPROFILE%\Downloads\voidsworn_test
cd /d %T%\build
if exist %T%\hulls_uv.zip (
  if exist hulls_uv rmdir /s /q hulls_uv
  if exist hulls_hi_uv rmdir /s /q hulls_hi_uv
  tar -xf %T%\hulls_uv.zip
)
set PYTHONPATH=
for %%o in (bake bake_lo) do if exist %T%\%%o rmdir /s /q %T%\%%o
set BAKE_REFS=hulls_hi_uv
set BAKE_OUT=bake
set BAKE_DIV=1
call %T%\bake_all.bat
set BAKE_REFS=hulls_uv
set BAKE_OUT=bake_lo
set BAKE_DIV=2
call %T%\bake_all.bat
cd /d %T%
if exist bake.zip del bake.zip
tar -a -cf bake.zip bake bake_lo
echo done > %T%\bakeuv_done.txt
