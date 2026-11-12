# corsair_A16 build sheet: the Warlord's Pyre-Barge (round 2)

Ashfall Hullbreakers flagship, class Battle-barge, **26.0 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_boss).
Version 2, 2026-11-11, after Ryan's review of round 1 (R213: guns randomly placed, flatter than the concept, square blocks).
Designer of record: Opus (R205, R207). Open [sheet.jpg](sheet.jpg): the accepted beauty and the blockout at the camera
fitted to it come first. Then [feature_table.md](feature_table.md) and [manifest.json](manifest.json) (R214).

![corsair_A16 preview](preview.jpg)

- Views, one model, one scale (80 px per unit): [side](side.jpg), [top](top.jpg), [underside](underside.jpg),
  [bow-on](bow.jpg), [engine end](stern.jpg), [INSIDE cutaway](cutaway.jpg), [three-quarter](threequarter.jpg),
  [beauty beside the blockout](beauty_vs_blockout.jpg), [outline overlay](outline_check.jpg), [checks.json](checks.json).
- Design source: `tools/blender/build_sheets/ships/corsair_A16.py`.

## Depth and massing (why)

Round 1 fitted one three-quarter camera, which cannot see height. Round 2 reads the true profile off the round 8 sheet's
side view (48 px per unit at this length) and the plan off its top view, with the TRELLIS shape reference
(board\issue-532\shots\corsair_A16\shape_reference_v2.glb) as a check on the massing:

| Reading | Hull depth (belly to deck) | To the castle roof | Beam |
|---|---:|---:|---:|
| Round 8 side and top views | 5.5 | 6.0 | 8.5 |
| TRELLIS shape reference | about 6 | 7.9 | about 11 (it reads depth into width, the "egg") |
| Round 1 (rejected) | 4.45 | 6.6 with a thin castle | 8.3 |
| **Round 2** | **4.9 slab + tier 2 to 5.7** | **6.5, bridge 7.1** | **8.7** |

So length to depth is 4.0 to the castle roof (5.3 for the slab alone) and length to beam 3.0: the long slab Ryan accepted,
with real elevation: a blunt chin rising to the scoops, the slab, a raised armoured tier 2 with a sloped front at 23 percent,
the castle at 59 to 80 percent, the bridge block and flak turret on top, the stern deck and the engine pods.

## Guns by slot (data.js c_boss: scatter P, scatter S, htorp F, flak T)

- **P and S (scatter), matched mirror batteries, six mounts a side:** a bow ball casemate trained 15 degrees off the bow, three
  deck-edge twin turrets on tier 2 (stations 27, 37, 47 percent) resting 45 degrees off the bow, and two castle-flank twin
  casemates (65 and 73 percent) at 55 degrees. One mount family per tier.
- **F (htorp):** one 10-tube heavy rocket rack on the spine at 41 percent, firing over the bow, magazine directly below.
- **T (flak):** two twin turrets on the spine, 360 degree arcs: one on the gun bunker (31 percent), one superfiring on the
  bridge (69 percent).

Outline at the fitted camera (az 45, el 24, roll -1.4): 84.3 percent. My honest read of the side by side: plainly the same
ship (the slab, the twin scoops and dishes, the rack, the castle, the big port pod, the claws), but still a blockout: the
picture's density of small plates, rivets and wear is a paint and kit job, not a sheet job.
