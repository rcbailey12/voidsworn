@echo off
rem Play Voidsworn in Godot with the simpler Compatibility renderer (OpenGL). Use this only if play_godot.bat will not start.
call "%~dp0play_godot.bat" --rendering-method gl_compatibility
