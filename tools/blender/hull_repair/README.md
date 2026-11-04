# Pyre-Barge repair in place, issue 129

Double-click **RUN_C19_REPAIR.bat** on Ryan's PC. It uses the existing GPU queue, portable ComfyUI Python, installed local models, Blender 4.5.14 and Godot 4.7.2. It waits while the game is open. There are no downloads or paid services.

The experiment uses today's `a4/out/C19_51/C19_51_ship.npz`, with the current packed game scene as the today control. It never substitutes the clean shell from issue 111. The exact round 2 Hullbreaker trim is regenerated and checked against the committed PNG by SHA256. No projected concept paint or AI normal map enters a repaired material.

The six exports are the five requested stages with stage 4 split into 4a and 4b:

1. `S1`: today's geometry, shared trim and Hullbreaker PBR.
2. `S2`: S1 plus large wavy plate flattening. The region growth follows `hs/panel_flatten.py`. Small details and region borders stay put; the next two rings blend into the fitted plane.
3. `S3`: S2 plus separated crease topology, hard shading breaks, narrow physical grooves, dark groove floors, thin worn-edge strips, trim AO and per-piece values. Small machinery remains in its original shape. Wear does not replace whole source triangles.
4. `S4a`: S3 plus cut closures, measured mounts, hand-built guns, engine block, bridge tiers and sensor arrays. `S4b` uses independently generated AI engine, bridge and matched gun parts at the same mounts.
5. `S5`: S1 through S3 plus the visually selected replacements, weighted normals and shared materials. `choices.json` in the work folder records the choice. The default selects the hand parts pending visual review.

`ai_parts.py` saves untouched concept crops, local Qwen cleanup prompts, images and histories, then the full 1536 Pixal3D shape cascade for each isolated part. `--retry bridge` retains the first attempt and makes one targeted replacement. Generation is evidence, not approval of an invented shape. A separate midships cut-and-join trial is rendered and kept out of the final ship.

Native AI parts can exceed 20 million triangles each. `pack_parts.py` uses arrays to add normals and trim UVs without putting them all through BMesh. It removes only zero-area triangles, reverses inward source winding and converts the trim's V coordinate to glTF. There is no decimator, remesher or triangle target in the retained path. `assembly.gd` loads those meshes as shared resources in both the isolated studio and the actual game battle. A stage GLB with native parts is its hull and mounts, accompanied by the assembly records in `build.json` and the packed part GLBs. It is not a self-contained production asset.

Everything large or temporary stays in `%TEMP%\voidsworn_issue129`: meshes, `.blend` files, source snapshots, import caches, settings, save directories and logs. Review sheets and measurements go to `docs/shots/ship_pipeline/repair_c19/`. Full screenshots, AI images and generation records also go to `Downloads\voidsworn_test\board\issue-129\shots`, where Opus can see them.

For a working session, the runner accepts `--worker --phase build --stage S3`, `--phase capture`, `--phase game`, or `--phase sheets`. `--phase capture --route S4b` updates that route's studio/game evidence and merges its measured row with the retained routes. The midships trial is also recaptured. Build and capture phases use the PC timeout runner; the double-click batch queues lane A. `checks.py --work <TEMP folder>` runs standing checks with Node 22 and CI rules parity on a private fixture copy. The full batch runs these checks before composing sheets. It does not rewrite checked-in goldens.

The measurements use the rounds 1 and 2 studio, G4 lighting, 1920 by 1080, Forward+, compressed mipmapped textures, MSAA 4x, 100 warm-up frames and 360 measured frames. Twenty shared ships use the same non-overlapping 5 by 4 layout. These are isolated rendering figures, not whole-battle performance or 4K measurements. The separate game captures prove that the prototypes appear with the actual HUD, board, ShipView and lighting.

The part comparison adds the same 0.9-energy camera-direction inspection light to both versions, then removes it before benchmarks. `--worker --phase parts` refreshes these detail shots without replacing measured rows; `--route S4a` restricts that refresh to one route.

The outcome and remaining visual work belong in the [review report](../../../docs/shots/ship_pipeline/repair_c19/README.md). No shipping ship asset, game code, player save, commit or push is part of this job.
