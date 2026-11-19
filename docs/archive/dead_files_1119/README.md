# Dead files archived on Nov 19 2026 (issue 1206)

Every file here was moved with `git mv` from the path in its row; history is kept (`git log --follow`). Nothing was deleted and no other file was edited. Nothing in this folder is followed or run (AGENTS.md: docs/archive is history).

## The proof, per file

A file is dead only if `git grep -I -F` for its basename, and for its stem (name without extension), finds nothing outside `contrib/`, `docs/archive/`, `docs/shots/`, the file itself and its `.uid`. That search covers every tracked text file: .bat, .ps1, .py, .gd, .tscn, .tres, .json, .md, .js, .sh and .github/workflows. One grep per term, for example:

```
git grep -n -I -F -e <term> -- . ':!contrib/' ':!docs/archive/' ':!docs/shots/'
```

A reference from another file in this same list does not count (both moved together; the list was solved to a fixed point). Four files were cleared by hand because their only hits were a different file or a variable sharing the stem; the reason is in their row. I also checked for wildcard or folder runs (`jobs\*`, `c19_*`, `glob(...)` over these folders): none reach these files.

Candidates: the Board's 15 plus every path in the Neon health audit section 5 (185 in all). 84 proved dead by grep on main; 82 are here. The two ui344 shot runners went back to tools/pc/jobs because open work still needs them (Artoo's review of PR 1214: issue 1223 keeps them as deliverables and PRs 1169 and 1224 edit them). I also checked every open pull request and open issue body for the other 82: none names them. The rest stay, listed at the end with what still names them.

| Old path | Terms grepped | Result |
| --- | --- | --- |
| `artshot.py` | `artshot.py` , `artshot` | 0 hits; Board sample |
| `cmdshot.py` | `cmdshot.py` , `cmdshot` | 0 hits |
| `godot/audio/build/bake_sound_weight.gd` | `bake_sound_weight.gd` , `bake_sound_weight` | 0 live hits (2 from other files in this list or itself); Board sample |
| `godot/tools/e14_lift_capture.gd` | `e14_lift_capture.gd` , `e14_lift_capture` | 0 live hits (3 from other files in this list or itself); Board sample |
| `godot/ui/battle/keel_shots.gd` | `keel_shots.gd` , `keel_shots` | 0 live hits (2 from other files in this list or itself) |
| `godot/ui/campaign/rail_orders_shots.gd` | `rail_orders_shots.gd` , `rail_orders_shots` | 0 live hits (2 from other files in this list or itself) |
| `godot/ui/text_floor_shots.gd` | `text_floor_shots.gd` , `text_floor_shots` | 0 live hits (4 from other files in this list or itself) |
| `godot/world/distinct_capture.tscn` | `distinct_capture.tscn` , `distinct_capture` | 0 live hits (1 from other files in this list or itself) |
| `godot/world/lightning_capture.tscn` | `lightning_capture.tscn` , `lightning_capture` | 0 live hits (1 from other files in this list or itself) |
| `godot/world/nebula_bench.tscn` | `nebula_bench.tscn` , `nebula_bench` | cleared by hand: stem only matches `nebula_bench.gd` (the script, which stays); `nebula_bench.tscn` matches nothing and nothing loads the scene by uid (it has none); Board sample |
| `godot/world/nebula_capture.tscn` | `nebula_capture.tscn` , `nebula_capture` | cleared by hand: stem only matches `nebula_capture.gd` (the script, which stays and is extended by three captures); `nebula_capture.tscn` matches nothing |
| `godot/world/storm_capture.tscn` | `storm_capture.tscn` , `storm_capture` | 0 live hits (1 from other files in this list or itself); Board sample |
| `godot/world/storm_lightning_check.gd` | `storm_lightning_check.gd` , `storm_lightning_check` | 0 hits; Board sample |
| `godot/world/test_world.gd` | `test_world.gd` , `test_world` | 0 live hits (2 from other files in this list or itself); Board sample; its `.uid` moved with it |
| `godot/world/tools/bake_preview.gd` | `bake_preview.gd` , `bake_preview` | 0 live hits (2 from other files in this list or itself); its `.uid` moved with it |
| `intentshot.py` | `intentshot.py` , `intentshot` | 0 hits |
| `motionshot.py` | `motionshot.py` , `motionshot` | 0 hits |
| `motiontest.py` | `motiontest.py` , `motiontest` | 0 hits |
| `pacecheck.py` | `pacecheck.py` , `pacecheck` | cleared by hand: stem only matches tools/pacecheck_godot.sh naming itself (a different file); `pacecheck.py` matches nothing |
| `shapeshot.py` | `shapeshot.py` , `shapeshot` | 0 hits |
| `shipvis.py` | `shipvis.py` , `shipvis` | 0 hits |
| `smoke_dbg.py` | `smoke_dbg.py` , `smoke_dbg` | 0 hits; Board sample |
| `smoke_dbg2.py` | `smoke_dbg2.py` , `smoke_dbg2` | 0 hits |
| `teltest.py` | `teltest.py` , `teltest` | 0 hits |
| `terrcheck.py` | `terrcheck.py` , `terrcheck` | 0 hits |
| `tools/blender/a1/render_v15.py` | `render_v15.py` , `render_v15` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/bake_uv.bat` | `bake_uv.bat` , `bake_uv` | cleared by hand: stem `bake_uv` only matches a NumPy variable in tools/blender/surface_bakeoff/round2_build.py:396,400; the file name matches nothing; Board sample |
| `tools/pc/codex_run.bat` | `codex_run.bat` , `codex_run` | 0 live hits (4 from other files in this list or itself); Board sample |
| `tools/pc/fx_run.bat` | `fx_run.bat` , `fx_run` | 0 live hits (2 from other files in this list or itself); Board sample |
| `tools/pc/hy_bakeoff.py` | `hy_bakeoff.py` , `hy_bakeoff` | 0 live hits (1 from other files in this list or itself); Board sample |
| `tools/pc/jobs/A17_RUN_532.bat` | `A17_RUN_532.bat` , `A17_RUN_532` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/A18_A20_PAINT_651.bat` | `A18_A20_PAINT_651.bat` , `A18_A20_PAINT_651` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/E11_E12_PAINT_642c.bat` | `E11_E12_PAINT_642c.bat` , `E11_E12_PAINT_642c` | 0 live hits (6 from other files in this list or itself) |
| `tools/pc/jobs/E11_E12_RUN_618.bat` | `E11_E12_RUN_618.bat` , `E11_E12_RUN_618` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/a3_godot_fx.bat` | `a3_godot_fx.bat` , `a3_godot_fx` | 0 live hits (3 from other files in this list or itself) |
| `tools/pc/jobs/c19_10_kitdark_probe3.bat` | `c19_10_kitdark_probe3.bat` , `c19_10_kitdark_probe3` | 0 hits |
| `tools/pc/jobs/c19_11_normals_probe.bat` | `c19_11_normals_probe.bat` , `c19_11_normals_probe` | 0 hits |
| `tools/pc/jobs/c19_12_hull_face_probe.bat` | `c19_12_hull_face_probe.bat` , `c19_12_hull_face_probe` | 0 hits |
| `tools/pc/jobs/c19_13_faceout.bat` | `c19_13_faceout.bat` , `c19_13_faceout` | 0 hits |
| `tools/pc/jobs/c19_14_plating_finish.bat` | `c19_14_plating_finish.bat` , `c19_14_plating_finish` | 0 hits |
| `tools/pc/jobs/c19_14b.bat` | `c19_14b.bat` , `c19_14b` | 0 hits |
| `tools/pc/jobs/c19_14c.bat` | `c19_14c.bat` , `c19_14c` | 0 hits |
| `tools/pc/jobs/c19_14d_shots.bat` | `c19_14d_shots.bat` , `c19_14d_shots` | 0 hits |
| `tools/pc/jobs/c19_14e_probe.bat` | `c19_14e_probe.bat` , `c19_14e_probe` | 0 hits |
| `tools/pc/jobs/c19_14f_probe.bat` | `c19_14f_probe.bat` , `c19_14f_probe` | 0 hits |
| `tools/pc/jobs/c19_14g.bat` | `c19_14g.bat` , `c19_14g` | 0 hits |
| `tools/pc/jobs/c19_1b_views_front_back.bat` | `c19_1b_views_front_back.bat` , `c19_1b_views_front_back` | 0 hits |
| `tools/pc/jobs/c19_2_mesh_fit_paint.bat` | `c19_2_mesh_fit_paint.bat` , `c19_2_mesh_fit_paint` | 0 hits |
| `tools/pc/jobs/c19_3_lod.bat` | `c19_3_lod.bat` , `c19_3_lod` | 0 hits |
| `tools/pc/jobs/c19_5_flatten_panels.bat` | `c19_5_flatten_panels.bat` , `c19_5_flatten_panels` | 0 hits |
| `tools/pc/jobs/c19_6_shell_to_game.bat` | `c19_6_shell_to_game.bat` , `c19_6_shell_to_game` | 0 hits |
| `tools/pc/jobs/c19_7_infill.bat` | `c19_7_infill.bat` , `c19_7_infill` | 0 hits |
| `tools/pc/jobs/c19_7_repack_only.bat` | `c19_7_repack_only.bat` , `c19_7_repack_only` | 0 hits |
| `tools/pc/jobs/c19_8_kitdark_probe.bat` | `c19_8_kitdark_probe.bat` , `c19_8_kitdark_probe` | 0 hits |
| `tools/pc/jobs/c19_9_kitdark_probe2.bat` | `c19_9_kitdark_probe2.bat` , `c19_9_kitdark_probe2` | 0 hits |
| `tools/pc/jobs/env230_motion.bat` | `env230_motion.bat` , `env230_motion` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/nem122_checks.bat` | `nem122_checks.bat` , `nem122_checks` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/planet369_bench.bat` | `planet369_bench.bat` , `planet369_bench` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/planet369_check.bat` | `planet369_check.bat` , `planet369_check` | 0 live hits (1 from other files in this list or itself) |
| `tools/pc/jobs/planet369_check.gd` | `planet369_check.gd` , `planet369_check` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/planet369_probe.gd` | `planet369_probe.gd` , `planet369_probe` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/planet369_scale.patch` | `planet369_scale.patch` , `planet369_scale` | 0 hits |
| `tools/pc/jobs/planet369_sheets.bat` | `planet369_sheets.bat` , `planet369_sheets` | 0 live hits (1 from other files in this list or itself) |
| `tools/pc/jobs/planet369_sheets.py` | `planet369_sheets.py` , `planet369_sheets` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/planet369_showcase.gd` | `planet369_showcase.gd` , `planet369_showcase` | 0 live hits (2 from other files in this list or itself) |
| `tools/pc/jobs/q_a16_601.bat` | `q_a16_601.bat` , `q_a16_601` | 0 hits |
| `tools/pc/jobs/q_a17_532.bat` | `q_a17_532.bat` , `q_a17_532` | 0 hits |
| `tools/pc/jobs/q_c623.bat` | `q_c623.bat` , `q_c623` | 0 hits |
| `tools/pc/jobs/q_e618.bat` | `q_e618.bat` , `q_e618` | 0 hits |
| `tools/pc/jobs/q_paint_601.bat` | `q_paint_601.bat` , `q_paint_601` | 0 hits |
| `tools/pc/jobs/q_paint_642c.bat` | `q_paint_642c.bat` , `q_paint_642c` | 0 hits |
| `tools/pc/jobs/q_paint_651.bat` | `q_paint_651.bat` , `q_paint_651` | 0 hits |
| `tools/pc/jobs/stall220.bat` | `stall220.bat` , `stall220` | 0 hits |
| `tools/pc/jobs/stall220_stills.bat` | `stall220_stills.bat` , `stall220_stills` | 0 hits |
| `tools/pc/jobs/ui231_shots.bat` | `ui231_shots.bat` , `ui231_shots` | 0 hits |
| `tools/pc/jobs/ui271_build_shots.bat` | `ui271_build_shots.bat` , `ui271_build_shots` | 0 hits |
| `tools/pc/trellis_bakeoff.py` | `trellis_bakeoff.py` , `trellis_bakeoff` | 0 live hits (1 from other files in this list or itself) |
| `tools/pc/vs_art_o.py` | `vs_art_o.py` , `vs_art_o` | 0 hits |
| `tools/pc/vs_mesh12.py` | `vs_mesh12.py` , `vs_mesh12` | 0 hits; Board sample |
| `tools/pc/work_pro_120.bat` | `work_pro_120.bat` , `work_pro_120` | 0 hits; Board sample |
| `ux4shot.py` | `ux4shot.py` , `ux4shot` | 0 hits |
| `wshot.py` | `wshot.py` , `wshot` | 0 hits |

## Kept (still named by a live file)

Strict rule: any mention outside the excluded folders keeps the file, including history lines in PROGRESS.md and skill notes. The Board can rule on the history-only ones later.

| Path | First live mention |
| --- | --- |
| `boardshot.py` | .claude/skills/screenshot-verdict/SKILL.md:57 (1) |
| `boonflow.py` | PROGRESS.md:228 (1) |
| `bosscheck.py` | smoke.py:89 (3) |
| `camtest.py` | PROGRESS.md:272 (1) |
| `closeshot.py` | .claude/skills/screenshot-verdict/SKILL.md:57 (22) |
| `cmdui.py` | smoke.py:82 (4) |
| `corsairfx.py` | tools/pc/jobs/c19_v15d.bat:63 (4) |
| `enccheck.py` | PROGRESS.md:158 (1) |
| `evtest.py` | PROGRESS.md:171 (1) |
| `exittest.py` | PROGRESS.md:158 (1) |
| `fxshot.py` | .claude/skills/screenshot-verdict/SKILL.md:57 (11) |
| `gallery.py` | AUDIT_v53H.md:245 (96) |
| `healtest.py` | smoke.py:86 (3) |
| `hitchprobe.py` | gfx3d.js:426 (1) |
| `hudaudit.py` | PROGRESS.md:160 (1) |
| `loadprobe.py` | PROGRESS.md:530 (1) |
| `losshot.py` | PROGRESS.md:215 (1) |
| `mapprev.py` | PROGRESS.md:158 (1) |
| `overlapprobe.py` | PROGRESS.md:265 (1) |
| `rb2.py` | docs/ship_pipeline/build_sheets/chorus_C10/C10_camera170.jpg.provenance.json:74 (54) |
| `recapshot.py` | PROGRESS.md:218 (1) |
| `renderbudget.py` | PROGRESS.md:167 (3) |
| `softlock.py` | PROGRESS.md:136 (33) |
| `step2test.py` | smoke.py:76 (3) |
| `striptap.py` | smoke.py:80 (3) |
| `worldshot.py` | AUDIT_v53H.md:109 (2) |
| `yardcheck.py` | smoke.py:84 (3) |
| `tools/pc/bake_all.bat` | tools/pc/bake_uv.bat:14 (10) |
| `tools/pc/rocks_bake.bat` | tools/blender/README.md:5 (2) |
| `tools/pc/work_trial.bat` | tools/pc/work/README.md:81 (2) |
| `tools/pc/jobs/A16_RUN_601.bat` | docs/ship_pipeline/RECIPE.md:254 (2) |
| `tools/pc/jobs/A18_A20_RUN_633.bat` | docs/ship_pipeline/build_sheets/corsair_A18/README.md:106 (4) |
| `tools/pc/jobs/C10_C11_RUN_623.bat` | docs/ship_pipeline/build_sheets/chorus_C11/README.md:25 (2) |
| `tools/pc/jobs/E11_E12_PAINT_642.bat` | tools/pc/jobs/q_paint_642.bat:2 (9) |
| `tools/pc/jobs/E11_E12_PAINT_642d.bat` | docs/ship_pipeline/RECIPE.md:320 (6) |
| `tools/pc/jobs/HB_PAINT_726.bat` | docs/ship_pipeline/RECIPE.md:185 (1) |
| `tools/pc/jobs/PAINT_RUN_601.bat` | docs/ship_pipeline/RECIPE.md:254 (1) |
| `tools/pc/jobs/a2_detail.bat` | tools/blender/a2detail/a2_barge.py:2 (1) |
| `tools/pc/jobs/a4_barge.bat` | tools/blender/a4/stage.py:35 (1) |
| `tools/pc/jobs/a4_damage.bat` | tools/blender/a4/stage.py:35 (1) |
| `tools/pc/jobs/a4_lineup.bat` | tools/blender/a4/stage.py:35 (3) |
| `tools/pc/jobs/a4_looks.bat` | tools/blender/a4/stage.py:35 (2) |
| `tools/pc/jobs/a4_regen.bat` | tools/blender/a4/README.md:90 (3) |
| `tools/pc/jobs/a4_repaint.bat` | tools/blender/a4/stage.py:5 (5) |
| `tools/pc/jobs/a4_ship.bat` | tools/blender/a4/README.md:109 (21) |
| `tools/pc/jobs/c19_1_views.bat` | docs/ship_pipeline/README.md:28 (1) |
| `tools/pc/jobs/c19_4_kit_to_game.bat` | docs/ship_pipeline/README.md:28 (1) |
| `tools/pc/jobs/c19_v15c.bat` | assets/ships/C19_51/README.md:11 (named as the PC job) (1) |
| `tools/pc/jobs/c19_v15d.bat` | tools/pc/jobs/a2_detail.bat:31 (1) |
| `tools/pc/jobs/fx_inside_capture.bat` | godot/fx/API.md:354 (documented run path) (1) |
| `tools/pc/jobs/hb_paint_726.ps1` | tools/pc/jobs/HB_PAINT_726.bat:6 (4) |
| `tools/pc/jobs/hb_paint_726_logs.ps1` | tools/pc/jobs/hb_paint_726.ps1:3 (3) |
| `tools/pc/jobs/hb_paint_726_pictures.py` | tools/pc/jobs/hb_paint_726.ps1:177 (1) |
| `tools/pc/jobs/planet369_board.patch` | godot/world/world_planet.gd:17 (1) |
| `tools/pc/jobs/planet369_download.bat` | tools/pc/jobs/planet369_download.py:4 (3) |
| `tools/pc/jobs/planet369_download.py` | tools/pc/jobs/planet369_download.bat:7 (3) |
| `tools/pc/jobs/planet369_pack.bat` | tools/pc/jobs/planet369_remix.bat:9 (59) |
| `tools/pc/jobs/planet369_pack.gd` | godot/world/rocks/LICENCE_369.md:59 (61) |
| `tools/pc/jobs/planet369_pack.py` | godot/world/rocks/LICENCE_369.md:133 (60) |
| `tools/pc/jobs/planet369_remix.bat` | godot/world/rocks/LICENCE_369.md:59 (68) |
| `tools/pc/jobs/planet369_remix.py` | godot/world/rocks/LICENCE_369.md:59 (67) |
| `tools/pc/jobs/q_a633.bat` | docs/ship_pipeline/build_sheets/corsair_A18/README.md:106 (2) |
| `tools/pc/jobs/q_paint_642.bat` | docs/ship_pipeline/RECIPE.md:320 (3) |
| `tools/pc/jobs/q_paint_642d.bat` | docs/ship_pipeline/RECIPE.md:320 (3) |
| `tools/pc/jobs/v13k_winding_audit.bat` | docs/ship_pipeline/GRAPHICS_REVIEW.md:24 (1) |
| `tools/blender/a1/barge_shapes.py` | tools/blender/a1/barge_v15.py:5 (11) |
| `tools/blender/a1/barge_v15.py` | assets/ships/C19_51/README.md:7 (8) |
| `tools/blender/a1/clay.py` | tools/blender/a2detail/checks.py:1 (169) |
| `tools/blender/a1/sheet.py` | docs/ship_pipeline/RECIPE.md:51 (3720) |
| `tools/blender/surface_bakeoff/README.md` | .claude/skills/screenshot-verdict/SKILL.md:16 (185) |
| `tools/blender/surface_bakeoff/ROUND2.md` | tools/blender/surface_bakeoff/round2_run.py:1 (2) |
| `tools/blender/surface_bakeoff/RUN_SURFACE_BAKEOFF.bat` | tools/blender/surface_bakeoff/README.md:3 (2) |
| `tools/blender/surface_bakeoff/RUN_SURFACE_ROUND2.bat` | tools/blender/surface_bakeoff/ROUND2.md:3 (3) |
| `tools/blender/surface_bakeoff/build.py` | .claude/skills/playtest-and-balance/SKILL.md:11 (3317) |
| `tools/blender/surface_bakeoff/probe.gd` | docs/ship_pipeline/RECIPE.md:221 (333) |
| `tools/blender/surface_bakeoff/project.godot` | godot/fx/API.md:29 (718) |
| `tools/blender/surface_bakeoff/round2_build.py` | tools/blender/hull_repair/round4_hand.py:309 (5) |
| `tools/blender/surface_bakeoff/round2_game.gd` | tools/blender/hull_repair/round4_run.py:44 (6) |
| `tools/blender/surface_bakeoff/round2_probe.gd` | tools/blender/surface_bakeoff/ROUND2.md:13 (4) |
| `tools/blender/surface_bakeoff/round2_run.py` | tools/blender/surface_bakeoff/ROUND2.md:19 (5) |
| `tools/blender/surface_bakeoff/run.py` | docs/ship_pipeline/AUDIT_BRIEF.md:102 (6723) |
| `tools/blender/surface_bakeoff/verify.py` | tools/blender/surface_bakeoff/README.md:13 (81) |
| `tools/blender/r209/armA.py` | tools/blender/r209/README.md:8 (109) |
| `tools/blender/r209/armA2.py` | tools/blender/r209/README.md:23 (9) |
| `tools/blender/r209/armA3.py` | tools/blender/r209/README.md:38 (13) |
| `tools/blender/r209/armA4.py` | tools/blender/r209/README.md:52 (10) |
| `tools/blender/r209/armA6.py` | tools/blender/r209/README.md:77 (8) |
| `tools/blender/r209/armA7.py` | tools/blender/r209/README.md:81 (18) |
| `tools/blender/r209/armA8.py` | docs/ship_pipeline/RECIPE.md:673 (7) |
| `tools/blender/r209/bakeAb.py` | tools/blender/r209/README.md:25 (65) |
| `tools/blender/r209/bakeAb3.py` | tools/blender/r209/README.md:40 (8) |
| `tools/blender/r209/bakeAb4.py` | tools/blender/r209/README.md:54 (8) |
| `tools/blender/r209/bakeAb5.py` | tools/blender/r209/README.md:68 (6) |
| `tools/blender/r209/close5.py` | tools/blender/r209/README.md:69 (5) |
| `tools/blender/r209/export_glb.py` | tools/blender/r209/README.md:26 (3) |
| `tools/blender/r209/preview6.py` | tools/blender/r209/README.md:80 (3) |
| `tools/blender/r209/fit8_bow.json` | docs/ship_pipeline/RECIPE.md:674 (4) |
| `tools/blender/r209/fit8_bow_try1.json` | tools/blender/r209/deck_line.py:29 (1) |
| `godot/render/backdrop.gd` | godot/render/build_assets.gd:75 (108) |
| `godot/tools/probes/rim_soft_probe.gd` | docs/ship_pipeline/RECIPE.md:221 (1) |
| `godot/world/finale_shots.gd` | godot/fx/API.md:178 (1) |
| `tools/pc/jobs/ui344_briefing_shots.bat` | open issue 1223 (deliverable), PRs 1169 and 1224 edit it |
| `tools/pc/jobs/ui344_rollout_shots.bat` | open issue 1223 (deliverable), PRs 1169 and 1224 edit it |
