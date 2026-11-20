@echo off
rem Issue 1291, the Chorus rollout, C12 run B: the drone-spawn C12 (chorus_C12, game folder B19_11) through the shared ship job, a trial only.
rem The C13 round G look (R349, PR 1308) on main's kit at 6f79e00c or later (grown paint default, close_gaps, detail check gate) ported to the C12 sheet on the shared Chorus kit: body.field skin, armadillo bands from
rem belly edge to belly edge, flat chitin caps over the bile domes, fused chitin on the belly; the R341 scute shell removed.
rem ship_job.bat clones once from the shared repo-mirror.git into opus1291c12b\repo, builds stages 3 to 7 into that clone's own
rem godot folder (never build\godot), runs the readback, the interiors and death seam checks, then the shots, and ends
rem "done PASS" or "done FAILED: <step>" then "all done". No publish: Ryan sees the in-game sheet first. The Board pins the
rem branch head and holds work/issue-1291-c12 until this has run.
rem Publishing after Ryan's yes is tools\pc\jobs\publish_ship.bat opus1291c12b B19_11 <commit= line> <glb sha256>.
set "SHIP=chorus_C12" & set "CODE=B19_11" & set "BRANCH=work/issue-1291-c12" & set "JOB_DIR=opus1291c12b" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
