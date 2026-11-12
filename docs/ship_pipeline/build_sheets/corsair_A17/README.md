# corsair_A17 build sheet: Hullbreaker wrecker, the Pack Hunter (round 2)

Ashfall Hullbreakers cruiser, class Cruiser, **14.5 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_marauder).
Version 2, 2026-11-11, after Ryan's review of round 1 (R213; A17 stays lean). Designer of record: Opus (R205, R207).
Open [sheet.jpg](sheet.jpg) (beauty and blockout first), [feature_table.md](feature_table.md), [manifest.json](manifest.json).

![corsair_A17 preview](preview.jpg)

- Views, one model, one scale: [side](side.jpg), [top](top.jpg), [underside](underside.jpg), [bow-on](bow.jpg),
  [engine end](stern.jpg), [INSIDE cutaway](cutaway.jpg), [three-quarter](threequarter.jpg),
  [beauty beside the blockout](beauty_vs_blockout.jpg), [outline overlay](outline_check.jpg), [checks.json](checks.json).
- Design source: `tools/blender/build_sheets/ships/corsair_A17.py`.

## Depth and massing (why)

Profile from the round 8 sheet's side view (about 74 px per unit there): a low heavy head (scoop drums and jaws), a pinched
neck, the body deck at 1.5 and a shoulder hump to 2.85 with a crest to 3.2 over a flat belly at -1.75. Hull depth 3.35
(length to depth 4.3), 5.0 to the crest (2.9); beam 5.15 (2.8), lean as Ryan kept it. The TRELLIS reference for A17 came
out in a different axis frame and was not used for numbers.

## Guns by slot (data.js c_marauder: scatter P, scatter S, torp F, flak T)

- **P and S (scatter), mirrored, three mounts a side:** two deck-edge twin turrets (38 and 52 percent) at 45 degrees off the
  bow and a hump-flank twin casemate (73 percent) at 55 degrees.
- **F (torp):** a 2 by 3 rattle-rocket pod on the brow, firing over the jaws.
- **T (flak):** a twin on the hump crest and a twin belly turret, both on the centreline.

Outline at the fitted camera: 83.7 percent. Honest read: the same ship (heavy head with ears and scoop drums, jaws, hump,
stacked engines), still a blockout without the picture's plate density.
