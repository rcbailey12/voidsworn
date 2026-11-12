@echo off
rem Issue 377: print both Codex reruns' refused ship file copies into one shallow file the Board can read.
set "C=%USERPROFILE%\Downloads\voidsworn_test\opus377\cx\issue-377\runs"
set "F=%USERPROFILE%\Downloads\voidsworn_test\opus377\cx_refused_contents.txt"
> "%F%" echo refused copies kept per run:
for /d %%r in ("%C%\*") do (
  >> "%F%" echo == %%~nxr
  >> "%F%" type "%%r\refused\godot\assets\ships\C19_51\C19_51_kit.glb"
)
exit /b 0
