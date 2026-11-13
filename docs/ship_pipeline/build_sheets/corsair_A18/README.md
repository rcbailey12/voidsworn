# corsair_A18 build sheet: Hullbreaker raider (the Sniffer) (issue 633, first sheet)

Ashfall Hullbreakers frigate (the Sniffer, the pack's finder), class Frigate (6.5 world units, godot/render/hull_table.gd CLS_LEN); data.js c_raider: autocannon T, ability overburn, speed 6, evasion 28. The model is 6.51 long. Designer of record: Opus (R205, R207); the Board is the final designer (R233). Built from the accepted concept of PR 625 (contrib/muse/design/class_family_corsair_2026_11/, corsair_A18_beauty.jpg, v3, Ryan Nov 12 2026) and designs.md, the design of record for the fittings. The views were rendered in the Opus sandbox (Blender 5.3 as a Python module, CPU, 20 samples) from the same build.py; no PC run yet: the Board runs the recipe there after reviewing this sheet. Paint: `bake: none` (the sheet paint stack, PR 610, is not merged).

![corsair_A18 preview](preview.jpg)

**Start here (R229, the whole concept first):** [whole beauty beside the whole build](../../../shots/issue_633_hullbreakers/a18_whole_compare.jpg), [side against the concept sheet's side](../../../shots/issue_633_hullbreakers/a18_side_compare.jpg), [plan against plan](../../../shots/issue_633_hullbreakers/a18_top_compare.jpg), then the [bow](../../../shots/issue_633_hullbreakers/a18_bow_compare.jpg) and [stern](../../../shots/issue_633_hullbreakers/a18_stern_compare.jpg); the five Hullbreakers from above at one scale: [hullbreakers_lineup_top.jpg](../../../shots/issue_633_hullbreakers/hullbreakers_lineup_top.jpg). Then [side_by_side.jpg](side_by_side.jpg), [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## What the class is (the Board as designer, R233)

A lean wedge: the bow runs down to a small grilled face over a cut-in chin with one pair of grabbers, a raised spine of five stacked blocks carries the one twin autocannon turret, and two engine drums stand out on short pylons at the stern quarters with a small bell between. Its outline from above is its own: the STARBOARD bow shoulder swells out round a raised sponson carrying one oversized listening dish set nearly flush (designs.md's "little brick with one big ear", on the side the accepted picture draws its disc), and the PORT drum is the larger, so the frigate is lopsided corner to corner. It is not a small A16 (no wide body, no gun rows, no stern pods block) or a small A17 (no boxy head, one ear).

## Checks (all on this sheet's build)

| Check | Result |
|---|---|
| Fit check, seven tests (CLASH, MOUNT, ARC, SWEEP, EXHAUST, EXIT, LANE) | CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0, all zero ([fit_report.md](fit_report.md)) |
| Machines on a seam (R226), sandbox stage 4 audit | 0 of 13 machines across a seam; structure across: none |
| Audit (tools/recipe/audit.py) | PASS: 0 problems |
| Audit self-test (audit_selftest.py) | PASS, all nine cases |
| Contract self-test (sheet_contract_selftest.py) | PASS, on main and on PR 618's contract |
| Insides inside the skin (every inside vertex enclosed by the intact outside, rays six ways) | 0 of 232 outside |
| Detail density per part type (R224, under 0.75 of the hull is a fault) | none under; lowest antenna at 1.21 of the hull's triangles and 1.22 of its edge features per square unit |
| Inventory (every part has a job, present, shaped, detailed per cell) | 0 failing ([inventory.md](inventory.md)) |
| Triangles (reported, never capped) | 37296 outside, 408 inside, 37704 in all |
| Outline overlap with the beauty at the sheet camera (reported, not a bar, RULEBOOK 5.8) | 77.8 percent (mass outline 78.4) |

The fit check, the seam and inside tests and the density were run in the sandbox (tools/blender/build_sheets/build.py fit mode; the seam, inside and density measures are scripted the same way as the Chorus sheets' check, issue 623). PR 608's death check in Godot needs the exported ship and runs on the PC.

## Proportions (concept against build, the same measure on both)

| | Hull length:beam | Hull length:height |
|---|---:|---:|
| Concept sheet, true top and side views (luminance mask over 14, median over the middle 60 percent) | 3.62 | 5.18 |
| Build (the sheet's top and side renders, same measure) | 3.73 | 4.17 |

The sheet's true views are the reference for the massing (the beauty's three-quarter reads deeper; designs.md's "about 3:1" is longer in the picture). Plan matches; the build stands about a fifth taller than the sheet's side view over its raised spine and turret (the concept's dark belly drops out of the mask, which flatters it). The inventory's own table ([inventory.md](inventory.md)) uses a colour-difference mask that drops most of the dark concept hull, so its concept numbers read thinner than the picture; the row above is the one to read. Structure per cell is in the inventory: every cell has at least the concept's count of masses.

## Weapons, seams, breach anchors

One weapon slot (data.js c_raider): the twin autocannon turret T1 on the spine's gun block, all round, resting forward. One authored seam, B-1, behind the sensor head (the head tears away with the dish still on it, designs.md), kinked round the dish, the bow thrusters and the turret. Three breach anchors (frigate base 2, plus one for the Hullbreakers), uneven: port behind the head, starboard midships, port ahead of the engine block.

## Changed from the picture (R207, R233)

- **One gun: a twin autocannon turret on the spine's gun block.** data.js c_raider carries one weapon, autocannon T (R221: weapons from data.js); the picture's rows of flank guns, designs.md's two bow casemates and its rocket rack have no slot, so they are not built
- **The one big ear: an oversized listening dish (1.1 across, three quarters of the beam) on a bolted sponson that swells the PORT bow shoulder.** designs.md ("a little brick with one big ear", "the port shoulder swollen out past the hull line by the dish mount"); the v3 picture draws a flush disc on the starboard foredeck. On the port side it gives the frigate its own outline from above (R233)
- **Lopsided engines: two drums on short pylons at the stern quarters, the starboard drum clearly larger, and one small centre bell.** designs.md (two bells, the starboard larger) with the picture's outrigger drums; the picture's three stacked centre bells become one, so the stern does not read as A16's pods
- **The wake-sniffer scoop sits in the bow face, behind a grille.** designs.md puts it under the chin; the picture's face is a grilled mouth, and the chin carries the grabbers
- **One pair of small grabber arms under the chin, splayed a little.** designs.md: one pair (A17 carries two pairs); the picture shows a pair of hooked claws there
- **The spine is five stacked blocks with gaps, the gun block and the sensor block the tallest.** the picture's raised spine; stacked and bolted scrap brick (R196, R197), not one smooth deckhouse
- **Armour bricks bolted on the flanks, three to port and two to starboard; the starboard flank keeps a pale Hegemony trophy plate.** the picture's patchwork flank; designs.md's trophy plate
- **Four small attitude thrusters.** a ship in space needs them to turn (the overburn raider turns hard)
- **Insides: one deck with the listening room, a kennel nook, a closet loot hold, the core and the engine room.** designs.md; R209, R215

## Open

- Belly detail between the grabber housings and the engine block is designed here; the picture does not show the underside
- A second autocannon mount on the T slot (a battery, as A17's P slot) would make the frigate read more armed from above; the brief asked for one turret, so it is not built.
