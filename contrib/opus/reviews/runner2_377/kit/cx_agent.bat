@echo off
rem Stand-in for Codex in the issue 377 dry run (no Codex usage): half the work, a ship file force-added, then exit 1.
> tools\pc\codex_partial377.txt echo half done by the stand-in
if not exist godot\assets\ships\C19_51 mkdir godot\assets\ships\C19_51
> godot\assets\ships\C19_51\C19_51_kit.glb echo glb
git add -f godot/assets/ships/C19_51/C19_51_kit.glb
> "%USERPROFILE%\Downloads\voidsworn_test\opus377\cx\issue-377\last.md" echo Stand-in report: wrote tools/pc/codex_partial377.txt and copied a ship file in, then stopped with exit 1.
exit /b 1
