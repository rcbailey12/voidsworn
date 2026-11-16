# Hullbreaker paint, issue 726 run 4

Source: `0e9c791d+normal726-run4`, with accepted PRs 866, 884 and 898. These are the current R252/R274 Hullbreaker stack,
without changes to geometry, faction paint settings or the A16 fixture record. Every sheet names its ship, source and stage.

| Ship | Stage 5: beauty beside accepted concept | Stage 7: actual playable game, camera 170 |
| --- | --- | --- |
| A16 | [Painted proof](A16_paint_full.jpg) | [Installed proof](A16_ingame_cam170.jpg) |
| A17 | [Painted proof](A17_paint_full.jpg) | [Installed proof](A17_ingame_cam170.jpg) |
| A18 | [Painted proof](A18_paint_full.jpg) | [Installed proof](A18_ingame_cam170.jpg) |
| A19 | [Painted proof](A19_paint_full.jpg) | [Installed proof](A19_ingame_cam170.jpg) |
| A20 | [Painted proof](A20_paint_full.jpg) | [Installed proof](A20_ingame_cam170.jpg) |

[A16 stored R274 preview beside run 4](A16_r274_reference_vs_run4.jpg) checks the approved paint against the completed bake.
The stored preview uses 1024-pixel maps; the completed stage 5 uses 4096-pixel maps. Its sharper small detail is expected.
[A20 normal-method comparison](A20_normal_routes.jpg) uses the same painted mesh, camera and lighting with only the normal
method changed. Its beauty-image difference is 0.846 of one 8-bit colour step RMS.

The original captures, before/after comparisons, all stage logs, five 16-bit height maps per ship, manifests and check results
are in `C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run4/`. The ten primary JPGs here are byte-identical
copies of that folder's per-ship `pictures/` files, all 1280 pixels wide and at most 720 pixels tall.

[Reviewer report](../../../../contrib/codex/issue726/REPORT.md), [method and diagnostics](../../../../contrib/codex/issue726/NOTES.md),
[paint recipe](../../../ship_pipeline/RECIPE.md).
