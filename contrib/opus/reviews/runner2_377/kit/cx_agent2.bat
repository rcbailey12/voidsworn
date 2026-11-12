@echo off
rem Stand-in for Codex in the issue 377 rerun dry run (no Codex usage): half the work and a ship file force-added whose
rem content names this run (CX_RUN), then exit 1. Two runs share one board-style folder: both refused copies must survive.
> tools\pc\codex_partial377.txt echo half done by the stand-in, run %CX_RUN%
if not exist godot\assets\ships\C19_51 mkdir godot\assets\ships\C19_51
> godot\assets\ships\C19_51\C19_51_kit.glb echo glb from stand-in run %CX_RUN%
git add -f godot/assets/ships/C19_51/C19_51_kit.glb
> "%USERPROFILE%\Downloads\voidsworn_test\opus377\cx\issue-377\last.md" echo Stand-in report, run %CX_RUN%: wrote tools/pc/codex_partial377.txt and copied a ship file in, then stopped with exit 1.
exit /b 1
