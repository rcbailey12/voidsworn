# corsair_A17 build sheet: Hullbreaker wrecker (the Pack Hunter)

Ashfall Hullbreakers cruiser, class Cruiser, **14.5 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_marauder).
Version 1, 2026-11-11. Designer of record: Opus (R205, R207). Open [sheet.jpg](sheet.jpg), then [feature_table.md](feature_table.md).

![corsair_A17 preview](preview.jpg)

- Views, one model, one scale: [side](side.jpg), [top](top.jpg), [underside](underside.jpg), [bow-on](bow.jpg),
  [engine end](stern.jpg), [INSIDE cutaway](cutaway.jpg), [three-quarter](threequarter.jpg).
- Proportion check: [beauty beside the blockout at the fitted camera](beauty_vs_blockout.jpg) and
  [the outline overlay](outline_check.jpg). Numbers in [checks.json](checks.json).
- Blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A17\corsair_A17_blockout.blend` (on the PC, not in git).
- Design source: `tools/blender/build_sheets/ships/corsair_A17.py`.

## Proportions (measured first)

Hull 14.5 long, 4.88 beam, 3.83 deep: length to beam 2.97, length to depth 3.8: a heavy head, a narrow neck and a shoulder
hump. The first fit came out 5.55 by 4.35 (2.6 to 1, stubby). The outline cannot separate the two (an image model's picture
is not one consistent projection), so I took the leaner reading: factions.md asks for "lean, leaning forward", Ryan rejects
stubby ships, and the leaner hull also fits the picture better (outline 85.5 to 86.3 percent, with a camera at 49 degrees off
the bow and 30 up, close to the standard identity view, where the stubby fit needed a 7 degree roll).

Outline at the fitted camera: 86.3 percent (mass outline 86.8). The misses are the jaws (shortened and hinged, listed) and the
guns retrained forward. A small dark shadow notch under the port dish was filled in the cut-out (the picture's hull is there,
too dark for the cut-out to see).
