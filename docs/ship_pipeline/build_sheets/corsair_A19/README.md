# corsair_A19 build sheet: Hullbreaker gutship (the Mauler) (issue 633, round 2)

Ashfall Hullbreakers destroyer (the Mauler, the pack's gun ship), class Destroyer (9.5 world units, godot/render/hull_table.gd CLS_LEN); data.js c_reaver: torp F, scatter S, ability reload. The model is 9.50 long. Designer of record: Opus (R205, R207); the Board is the final designer (R233). Built from the accepted concept of PR 625 (contrib/muse/design/class_family_corsair_2026_11/, corsair_A19_beauty.jpg, v6, Ryan Nov 12 2026) and designs.md, the design of record for the fittings. The views were rendered in the Opus sandbox (Blender 5.3 as a Python module, CPU, 20 samples) from the same build.py; no PC run yet: the Board runs the recipe there after reviewing this sheet. Paint: `bake: none` (the sheet paint stack, PR 610, is not merged).

![corsair_A19 preview](preview.jpg)

**Start here (R229, the whole concept first):** [whole beauty beside the whole build](../../../shots/issue_633_hullbreakers/a19_whole_compare.jpg), [side against the concept sheet's side](../../../shots/issue_633_hullbreakers/a19_side_compare.jpg), [plan against plan](../../../shots/issue_633_hullbreakers/a19_top_compare.jpg), then the [bow](../../../shots/issue_633_hullbreakers/a19_bow_compare.jpg) and [stern](../../../shots/issue_633_hullbreakers/a19_stern_compare.jpg); the five Hullbreakers from above at one scale: [hullbreakers_lineup_top.jpg](../../../shots/issue_633_hullbreakers/hullbreakers_lineup_top.jpg). Then [side_by_side.jpg](side_by_side.jpg), [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## What the class is (the Board as designer, R233)

A long low slab whose defining shape is the arrow-head prow (round 2: the Board found round 1's bow blunt and square from above): a broad flat bow plate runs from a blunt point to the full beam over the first third, overhanging a narrow bow face that holds the two mismatched rocket casemates (Ryan's ruling: IN the bow face), a long braced tube to port and a short fat cluster of three to starboard, under a sloped chin with a pair of grabbers and a second pair under the forefoot. Behind the wedge a spine of three stacked blocks carries two scatter turrets, the whole scatter battery is on the STARBOARD side (three flank casemates between armour bricks), the port flank is widened by a side block with a big pale trophy plate in three torn sheets, and a raised stern block carries three lopsided bells. Every face is plated in courses at the destroyer's plate size with patches over joints and plates, the top faces stepped (R196, R197). It is not a small A16 (the barge's wide body and pods) or a small A17 (the cruiser's boxy head with two ears).

## Checks (all on this sheet's build)

| Check | Result |
|---|---|
| Fit check, seven tests (CLASH, MOUNT, ARC, SWEEP, EXHAUST, EXIT, LANE) | CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0, all zero ([fit_report.md](fit_report.md)) |
| Machines on a seam (R226), sandbox stage 4 audit | 0 of 22 machines across a seam; structure across: PH1 (a pipe) |
| Audit (tools/recipe/audit.py) | PASS: 0 problems |
| Audit self-test (audit_selftest.py) | PASS, all nine cases |
| Contract self-test (sheet_contract_selftest.py) | PASS (this branch carries PR 618's contract, merged in round 2) |
| Insides inside the skin (every inside vertex enclosed by the intact outside, rays six ways) | 0 of 264 outside |
| Detail density per part type (R224, under 0.75 of the hull is a fault) | none under; lowest antenna at 1.01 of the hull's triangles and 0.95 of its edge features per square unit |
| Inventory (every part has a job, present, shaped, detailed per cell) | 0 failing ([inventory.md](inventory.md)) |
| Triangles (reported, never capped) | 70054 outside, 464 inside, 70518 in all (round 1: 49934 and 464; the plates in courses carry the scrap brick, R196) |
| Outline overlap with the beauty at the sheet camera (reported, not a bar, RULEBOOK 5.8) | 77.9 percent (mass outline 80.2; round 1 77.3) |

The fit check, the seam and inside tests and the density were run in the sandbox (tools/blender/build_sheets/build.py fit mode; the seam, inside and density measures are scripted the same way as the Chorus sheets' check, issue 623). PR 608's death check in Godot needs the exported ship and runs on the PC.

## Proportions (concept against build, the same measure on both)

| | Hull length:beam | Hull length:height |
|---|---:|---:|
| Concept sheet, true top and side views (luminance mask over 14, median over the middle 60 percent) | 4.57 | 7.18 |
| Build (the sheet's top and side renders, same measure) | 4.10 | 6.15 |

Re-measured in round 2 with one script on both (round 1 read the concept at 4.58 and 7.33). The build is about a tenth wider and a sixth taller than the sheet's true views; the concept's dark belly drops out of the mask, which makes it read thinner. From above, the first third is now the concept's arrow-head (0.4 across at the tip, 1.3 just behind it, 2.1 by a third of the length). The inventory's own table ([inventory.md](inventory.md)) uses a colour-difference mask that drops most of the dark concept hull; the row above is the one to read.

## Weapons, seams, breach anchors

data.js c_reaver: torp F (slot 0) fired by the bow-face casemates R1 and R2; scatter S (slot 1) by casemates S1 to S3 and turrets S4 and S5. Two authored seams: B-1, the bow block weld (the bow tears away whole with its casemates, designs.md), and B-2, the stern block weld, each kinked round the machines near it. Four breach anchors (destroyer base 3, plus one), uneven: the bow seam to port, two along the middle deck (starboard, port), the stern block to starboard.

## Changed from the picture (R207, R233)

- **The two mismatched casemates sit IN the bow face: port, one long rocket tube on a brace; starboard, three short fat tubes banded together.** Ryan, Nov 12 (the round's ruling): "the two mismatched casemates sit IN the bow face", whatever the beauty's foredeck housings suggest. data.js c_reaver's only forward weapon is torp F, so both are rocket casemates (the Hullbreaker rattle rockets); the long tube stays short of a prow gun (RULEBOOK 4.4, Ryan on v5 "added a giant front gun again?")
- **The bow is an arrow-head from above: the broad flat bow plate runs from a blunt point 0.4 across to the full beam over the first third, overhanging a narrow bow face (1.1 across, 0.52 tall) that holds the two casemates; the hull's flanks widen back behind it.** the Board on round 1 (Nov 13, R233): the build had a blunt square bow; the picture's defining shape is the wedge prow (the concept sheet: 0.4 across at the tip, 1.3 just behind it, 2.1 by a third of the length). The face stays blunt and narrow, not a thin edge: the casemates need a face to sit in (designs.md)
- **Every face is plated in courses at the hull's plate size (0.2 to 0.46), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses.** the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit's courses plating (kit.py, opt-in, issue 633)
- **The whole scatter battery on the starboard side: three flank casemates of mixed calibre and two spine turrets resting to starboard.** data.js c_reaver: scatter S (one starboard battery); the picture's pods on both flanks and its foredeck guns have no other slot (R221)
- **No rocket racks on the middle deck.** designs.md's two racks would be a second forward launcher; data.js gives one torp slot and the bow casemates fire it
- **Port flank: the side block carries one big pale Hegemony trophy plate, in three torn sheets bolted edge to edge.** designs.md (the trophy plate widening the port outline amidships) on the picture's side block
- **Two grabber pairs: one under the chin, one under the forefoot.** the picture's claws at the chin and further aft; designs.md's four arms; split so the jaw is not a copy of A17's
- **Three engine bells, the centre the largest, staggered in the stern block.** designs.md; the picture's four become three, lopsided (port small and high, starboard lower)
- **Two dishes: the large one standing on the foredeck plate to port, a small one on the stern block to starboard.** designs.md; the picture shows one on the foredeck
- **Four attitude thrusters.** a ship in space needs them to turn
- **Insides: two decks, the gun crews' gallery along the starboard casemates, a kennel deck under the bow, the loot hold aft.** designs.md; R209, R215

## Open

- Belly detail between the grabber pairs and the stern block is designed here; the picture shows little of the underside
