@echo off
rem Issue 1291 run G: the Chorus spitter C13 (chorus_C13, game folder B20_11) through the shared ship job, a trial only.
rem Round G (Ryan, Nov 20: armour over the whole body, "caps, but flatter" on the sacs), through the shared ship job and
rem repo mirror like F (RULEBOOK 3.3). ship_job.bat clones once from the shared repo-mirror.git into
rem opus1291g\repo, builds stages 3 to 7 into that clone's own godot folder (never build\godot), runs the readback, the
rem interiors and death seam checks, then the shots, and ends "done PASS" or "done FAILED: <step>" then "all done".
rem The look: round F (satin veils, bands wrapping the body belly edge to belly edge) with flat chitin caps over the
rem flank sacs, kit and sheet commit f23c6274. The Board pins the branch head and holds opus/issue-1291 until this has run.
rem Publishing after Ryan's yes is tools\pc\jobs\publish_ship.bat opus1291g B20_11 <commit= line> <glb sha256>.
set "SHIP=chorus_C13" & set "CODE=B20_11" & set "BRANCH=opus/issue-1291" & set "JOB_DIR=opus1291g" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
