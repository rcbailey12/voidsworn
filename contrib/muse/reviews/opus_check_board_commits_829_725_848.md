# Check: three Board commits on merged PRs (829 fixture, 725 planet JPEGs, 848 merge)

Refs #256. Batch item 2 (Board brief, issue 256 comment 6915278472). Three Board-written commits on already-merged PRs, each with one question from the brief. Chair-verified against the commits and the repo trees at those commits; these are factual questions with mechanical answers, so no council legs were run.

## Verdict: GO on all three

### 1. PR 829, commit aea70a5c4be9: "regenerate the A16 death-seam fixture" — same 151,844 triangles? YES

The commit changes only godot/fx/test/fixtures/C19_51_unbaked.glb.gz and its .sheet.txt (the sheet's sha256 line only). The chair decompressed and parsed both GLB versions, the parent's (at cc8b15fdc) and the regenerated one, and summed the index accessors across all primitives: 9 meshes, 21 triangle primitives, exactly 151,844 triangles in BOTH. The geometry count is unchanged, as the commit message claims; the regeneration moved bytes, not triangles. PR 829's head carries four green check runs, including Godot game checks (the suite the death-seam check runs in), and the PR merged Nov 16, 2026.

One observation, not a condition: the sheet.txt sha256 matches neither the stored .glb.gz nor its decompressed GLB, on either the old or the new version. Whatever the hash covers (most likely the PC-side file before packing), it fails the same way before and after this commit, so the commit did not break it; flagging only so a future checker does not rediscover it mid-investigation.

### 2. PR 725, commit 56683cb56470: "store the planet shots as JPEG q90" — every README link still resolves? YES

The commit renames the captured PNGs in docs/shots/look_bench/planets/ to .jpg (66 renames) and updates that folder's README (+6/-3, including the Board's own note: 51 captured PNGs stored as JPEG quality 90, 44 MB to 11 MB, capture scripts still write PNG). The chair extracted every relative link from the post-commit README and checked each against the folder's tree at that commit: all 10 resolve (R01_sources.jpg, R01_storage.json, R01_pack_compare_c26.jpg, the three R01_compare_c*.jpg, R01_after_planet.jpg, R01_after_board_top.jpg, R01_scan_03.jpg, R01_scale_Frigate_c170.jpg). The README's remaining .png mentions are backticked names inside the PC review packet (after/run2/ and the shadows pair), not repo links, and they are correctly left as PNG.

### 3. PR 848, merge commit 788433c391a0: "godot_checks.txt keeps both new checks" — YES

The merge brought main (fe3847eaf) into the issue 843 branch (3d7a4aff2). The chair compared godot/tools/ci/godot_checks.txt at both parents and at the merge: branch side 108 lines, main side 110, merge 111, and the merge file contains every line from both parents, nothing lost and nothing invented. The branch's new check survives (render/test/formation_check.gd, issue 843: no projected wingmate footprints overlap through flight), and so do all three of main's newer lines (hull_lift_check, issue 811; shield_pool_test, R246/issue 371; finale_check, issue 44). The merge did the one thing a checks-file merge must do.

Side note for the Board, since it closes a loop from this morning's opus_check_830 addendum: PR 848's branch commit (3d7a4aff2, Codex, issue 843) is the formation spacing fix itself, "Squadron formation spacing follows each craft's size (wide KB1CC overlaps its wingmates)", so the wide-bomber wingmate overlap the rebuilt KB1CC sheet flagged already has its fix merged, with the formation_check above as its guard.
