# corsair_A17 build sheet: Hullbreaker wrecker, the Pack Hunter (round 3c, R221 clean-ups)

Ashfall Hullbreakers cruiser, class Cruiser, **14.5 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_marauder);
the model is 14.55. Version 3c, 2026-11-12: round 3's parts, fit check and turret marking (R217 to R219), with the massing
rebuilt to the concept's measured proportions after the Board's review of round 3 ("short, tall and round, a lump").
Designer of record: Opus (R205, R207). Rendered on Ryan's PC (Blender 4.5, GPU), blockout
`C:\Users\rcbai\Downloads\voidsworn_test\opus532\r221a\corsair_A17\corsair_A17_blockout.blend`.

**Round 3c (the Board on 3b): the head follows the beauty**, the picture Ryan judges against: a big, tall, boxy front block
(about 2.3 tall and 3.4 wide) towering over the neck, two big ear dishes (1.9 across, about the head's height) standing out
from brackets at its upper corners, and broad flat prongs (0.7 and 0.55 wide). The neck turrets and the rocket pod were lifted
so their arcs and exits clear the taller head; the fit check is still zero.

**R221 clean-ups (Ryan, Nov 12 2026).** The two chain girdles are cut ("There's no purpose"), and every inventory line names
its job (27 lines, 0 failing). The fit check's new LANE test (each rack's firing lane forward and backblast aft; no gun in
either) found the neck turrets P1 and S1 in the rocket pod's firing lane and the mid turrets P2 and S2 in its backblast: the
neck turrets moved outboard (0.6 to 1.3 off the centreline) and the mid turrets out and aft. Zero clashes in all seven tests;
every turret turns at least 155 degrees each way from rest (the fit report's reach table).

![corsair_A17 preview](preview.jpg)

Start here: **[side_by_side.jpg](side_by_side.jpg)** (concept left, blockout right, same camera, full view then bow,
midships and stern at the same windows), then [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## Proportions and structure (measured the same way on the concept and the build)

| | Hull length:beam | Hull length:height | Envelope length:beam | Envelope length:height |
|---|---:|---:|---:|---:|
| Concept (round 8 sheet, top and side views) | 2.75 | 4.06 | 2.04 | 3.54 |
| Round 3 build | 2.62 | 2.84 | 2.05 | 2.22 |
| Round 3b build | 2.82 | 3.84 | 1.91 | 2.88 |
| Round 3c build | 2.83 | 3.79 | 1.92 | 2.71 |
| **R221 build** | **2.84** | **3.82** | 1.92 | 2.71 |

Hull: length over the median beam or height across the middle 60 percent of the length. The envelope includes the guns,
dishes and belly turret. Distinct masses per cell (concept by eye, build from the model) are in [inventory.md](inventory.md):
every cell has at least the concept's count.

## What round 3b changed

1. **Long and low.** A base hull about 2 deep with a dark belly band stepping in under it; flank armour blocks on both sides,
   uneven and unmatched; six top blocks stepping up toward the stern (0.78, 0.9, 1.2, 1.3, 1.4, 1.52), with gaps and
   undercut bases. About 30 percent lower than round 3.
2. **The head** is the front block: chamfered, two roof steps (brow and crown), framed face panels with straps, a face
   overhanging a cut-in jaw mouth, the scoop drums under its lower corners, the ear dishes bolted to the drum tops.
3. **The jaws are long flat prongs** (new kit part `prong`): four blades with spine ridges, joint knuckles and hooked tips,
   reaching about a sixth of the length ahead of the head, each in its own housing in the mouth.
4. **Squat engine drums** in two columns a side, exits level, no bell touching another.
5. Everything from round 3 stays: kit part shapes, the fit check (zero clashes; 43 on the round 2 layout, see
   [fit_report.md](fit_report.md)), turret pivots with arcs (manifest.json), the inventory ticked per cell (27 lines after R221, each with its job, all
   present, shaped and detailed).

## What still differs from the concept, and why

- **The head** now follows the beauty rather than the round 8 sheet (which draws it narrower and lower); the two pictures
  disagree, and the beauty is the accepted one.
- **Surface density and colour**: the concept's small torn plates, rivets, grime and red engine glow are the paint stage;
  plate size is a kit setting.
- **Hull height** is about 7 percent over the sheet's (length:height 3.79 against 4.06): the taller head and the turrets add
  height the sheet's smaller head and guns do not.
