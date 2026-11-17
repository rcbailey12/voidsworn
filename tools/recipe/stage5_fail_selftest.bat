@echo off
rem Issue 873: fault test for 5_paint_bake.bat and bench207_scene_gate.bat. Fake Blender, Godot and nvidia-smi
rem executables in TEMP; no GPU, no Blender install, no network. Run it on Ryan's PC.
setlocal
node "%~dp0stage5_fail_selftest.js"
exit /b %ERRORLEVEL%
