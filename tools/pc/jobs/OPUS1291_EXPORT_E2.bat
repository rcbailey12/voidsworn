@echo off
rem Issue 1291 run E2: the Chorus spitter C13 (chorus_C13, game folder B20_11) through the shared ship job, a trial only.
rem Replaces OPUS1291_EXPORT_E.bat (never run): Artoo on PR 1308 asked that the next attempt use the approved PC checkout
rem path (RULEBOOK 3.3) instead of a GitHub clone per run. ship_job.bat clones once from the shared repo-mirror.git into
rem opus1291e\repo, builds stages 3 to 7 into that clone's own godot folder (never build\godot), runs the readback, the
rem interiors and death seam checks, then the shots, and ends "done PASS" or "done FAILED: <step>" then "all done".
rem The look: round D, soft rim on the glow materials, satin veils (roughness .6), kit commit 7710e842. The branch head
rem a3c93c5d adds only the E launcher on top of it; the Board holds opus/issue-1291 until this has run.
rem Publishing after Ryan's yes is tools\pc\jobs\publish_ship.bat opus1291e B20_11 <commit= line> <glb sha256>.
set "SHIP=chorus_C13" & set "CODE=B20_11" & set "BRANCH=opus/issue-1291" & set "JOB_DIR=opus1291e" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
