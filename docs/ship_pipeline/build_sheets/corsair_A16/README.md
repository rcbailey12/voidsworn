# corsair_A16 build sheet: the Warlord's Pyre-Barge

Ashfall Hullbreakers flagship, class Battle-barge, **26.0 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_boss).
Version 1, 2026-11-11. Designer of record: Opus (R205, R207). Open [sheet.jpg](sheet.jpg), then [feature_table.md](feature_table.md).

![corsair_A16 preview](preview.jpg)

- Views, one model, one scale: [side](side.jpg), [top](top.jpg), [underside](underside.jpg), [bow-on](bow.jpg),
  [engine end](stern.jpg), [INSIDE cutaway](cutaway.jpg), [three-quarter](threequarter.jpg).
- Proportion check: [beauty beside the blockout at the fitted camera](beauty_vs_blockout.jpg) and
  [the outline overlay](outline_check.jpg) (cyan the picture, orange the blockout). Numbers in [checks.json](checks.json).
- Blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A16\corsair_A16_blockout.blend` (on the PC, not in git).
- Design source: `tools/blender/build_sheets/ships/corsair_A16.py`.

## Proportions (measured first)

Hull 26.0 long, 8.3 beam, 4.45 deep: length to beam 3.13, length to hull depth 5.8 (castle top 4.6 above the hull datum;
11.9 over the gun barrels). Checked three ways: (1) the outline fit against the beauty peaks at these proportions (beam and
height scaled by 0.85, 0.92, 1.0 and 1.08 scored 83.6, 83.8, 84.3 and 83.3 percent at the first camera); (2) the round 8
generated sheet's own top view reads about 3 to 1; (3) the beauty's bow face against its foreshortened length gives about
3 to 1. Codex's first blockout (PR 536) was 26 by 14.8 (1.76 to 1), the "short wide egg".

Outline at the fitted camera: 85.8 percent (mass outline 85.7). Below the recipe's 90 percent gate, and on purpose in the
places listed under "Changed from the picture": the sagging chain loop (its enclosed gap counts as hull in the cut-out), the
claw blades, the guns retrained forward. The bow, the slab, the castle and the engine end sit on the picture's outline.
