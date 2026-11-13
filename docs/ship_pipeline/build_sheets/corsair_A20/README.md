# corsair_A20 build sheet: Hullbreaker hulk-carrier (the Den) (issue 633, round 2)

Ashfall Hullbreakers hulk-carrier (the Den), class Carrier (16.5 world units, godot/render/hull_table.gd CLS_LEN); data.js c_hulk: turret T twice, ability launch, hangar 2. The model is 16.50 long. Designer of record: Opus (R205, R207); the Board is the final designer (R233). Built from the accepted concept of PR 625 (contrib/muse/design/class_family_corsair_2026_11/, corsair_A20_beauty.jpg, v2s, Ryan Nov 12 2026) and designs.md, the design of record for the fittings. The views were rendered in the Opus sandbox (Blender 5.3 as a Python module, CPU, 20 samples) from the same build.py; no PC run yet: the Board runs the recipe there after reviewing this sheet. Paint: `bake: none` (the sheet paint stack, PR 610, is not merged).

![corsair_A20 preview](preview.jpg)

**Start here (R229, the whole concept first):** [whole beauty beside the whole build](../../../shots/issue_633_hullbreakers/a20_whole_compare.jpg), [side against the concept sheet's side](../../../shots/issue_633_hullbreakers/a20_side_compare.jpg), [plan against plan](../../../shots/issue_633_hullbreakers/a20_top_compare.jpg), then the [bow](../../../shots/issue_633_hullbreakers/a20_bow_compare.jpg) and [stern](../../../shots/issue_633_hullbreakers/a20_stern_compare.jpg); the five Hullbreakers from above at one scale: [hullbreakers_lineup_top.jpg](../../../shots/issue_633_hullbreakers/hullbreakers_lineup_top.jpg). Then [side_by_side.jpg](side_by_side.jpg), [cells.jpg](cells.jpg) and [fit_view.jpg](fit_view.jpg).

## What the class is (the Board as designer, R233)

A wide, flat, heavy slab, the widest Hullbreaker for its length, with a bow block standing out ahead of it as tall as the slab and about half its beam, its face filled by two huge intake tubes side by side (the README's bow intakes; round 2: the Board found round 1's tubes missing), dark-lined down their bores. Both hangar mouths are on the PORT flank (Ryan's ruling; the sheet's side view is the layout of record) and they are big now: three quarters of the flank's height, 3.2 and 2.6 long with a 1.4 plate between them, lined dark inside so they read as deep openings from the beauty camera, each with a torn plate rim, plated armoured doors slid clear on rails, launch rails on the floor, ceiling beams with dim red lamps, wall ribs and an inner blast door; a cobbled fighter (the game's 1.6) noses out of the forward mouth and a second is parked in the aft one. A salvage deck of three stacked plate tiers with lockers bolted down and a spare engine bell lying cold in a cradle, five mismatched bells along the top of the stern, one in a violet Eclipse housing. Every face is plated in courses at the carrier's plate size with patches over joints and plates, the top faces stepped (R196, R197). Two dorsal turrets (data.js), two shoulder dishes, a pair of bow grabbers and two heavy grapple arms folded flat under the stern quarters.

## Checks (all on this sheet's build)

| Check | Result |
|---|---|
| Fit check, seven tests (CLASH, MOUNT, ARC, SWEEP, EXHAUST, EXIT, LANE) | CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0, all zero ([fit_report.md](fit_report.md)) |
| Machines on a seam (R226), sandbox stage 4 audit | 0 of 22 machines across a seam; structure across: H1 and H2 (the mouths, openings), HB1 and HB5 (deck lockers), L3 (a lamp) |
| Audit (tools/recipe/audit.py) | PASS: 0 problems |
| Audit self-test (audit_selftest.py) | PASS, all nine cases |
| Contract self-test (sheet_contract_selftest.py) | PASS on PR 618's contract, merged into this branch in round 2 (its slot_map deals the two turret T slots; main's slot_index refuses a doubled pair) |
| Insides inside the skin (every inside vertex enclosed by the intact outside, rays six ways) | 0 of 352 outside |
| Detail density per part type (R224, under 0.75 of the hull is a fault) | none under; lowest hangar at 0.94 of the hull's triangles and 0.98 of its edge features per square unit |
| Inventory (every part has a job, present, shaped, detailed per cell) | 0 failing ([inventory.md](inventory.md)) |
| Triangles (reported, never capped) | 91576 outside, 620 inside, 92196 in all (round 1: 75308 and 620; the plates in courses carry the scrap brick, R196) |
| Outline overlap with the beauty at the sheet camera (reported, not a bar, RULEBOOK 5.8) | 74.8 percent (mass outline 74.9; round 1 55.9) |

The fit check, the seam and inside tests and the density were run in the sandbox (tools/blender/build_sheets/build.py fit mode; the seam, inside and density measures are scripted the same way as the Chorus sheets' check, issue 623). PR 608's death check in Godot needs the exported ship and runs on the PC.

## Proportions (concept against build, the same measure on both)

| | Hull length:beam | Hull length:height |
|---|---:|---:|
| Concept sheet, true top and side views (luminance mask over 14, median over the middle 60 percent) | 3.37 | 5.86 |
| Build (the sheet's top and side renders, same measure) | 2.71 | 5.82 |

Re-measured in round 2 with one script on both (round 1 read the concept at 3.40 and 5.83). The width call stays (the Board on round 1): the slab is wider than the sheet's top view, toward the accepted beauty (about 2.4); its height matches the sheet's side view. From above the bow block now stands out ahead of the slab at about half its beam, as wide as the two huge tubes side by side need. The inventory's own table ([inventory.md](inventory.md)) uses a colour-difference mask that drops most of the dark concept hull; the row above is the one to read.

## Weapons, seams, breach anchors

data.js c_hulk lists turret T twice: T1 on the fore deck tier and T2 on the aft, all round. The contract deals them over the two slots in build order (PR 618's slot_map; this branch merged PR 618 in round 2, so the stage 4 stand-in ran on it). Bays: hp_bay_0 and hp_bay_1, one per mouth, launching to port, hangar 2. Three authored seams: B-1 the fore weld, B-2 through the hangar block between the mouths (the plate between them tears first and the craft spill, designs.md), B-3 the aft weld; machines kinked round. Seven breach anchors (carrier base 6, plus one), uneven, port anchors off the mouths.

## The recipe (issue 633)

C16s_23 (`corsair|Carrier` in godot/render/hull_table.gd AI_HULLS), bake none. In the sandbox: contract self-test PASS; stage 4 audit and its self-test PASS; export7 unbaked at the default tolerance 89344 triangles, hard points gun 4, engine 5, bay 2, breach 7, core 1, rcs 2, board 2, two turrets; check_export PASS and its self-test PASS; install (manifest_merge, build_assets --ships-only) and INSTALL READBACK PASS (27 nodes); authored_interiors_check 0 failures (21161 interior triangles); death_seam_check 0 of 22 machines split, 0 of 11459 insides outside their piece. Three sheet changes came from the recipe (each also on the changes list, and the sheet re-rendered): the plate between the mouths is 1.4 wide (mouths 3.2 and 2.6, were 3.6 and 3.0), because the export puts a breach anchor at least 0.03 of the length (0.5) from every part and the 0.6 plate left no such point on the port flank amidships; the two bay points sit on the mouth floors at the lip (a hard point must be on the mesh, the mouth is open air); the three seam paths run on past the flanks to 4.2 off the axis, as C10's and C11's do (paths that stopped at 3.0, inside the widest parts, left 26 inside triangles outside their piece). The aft fighter moved to the middle of its shorter mouth. The PC run: tools/pc/jobs/A18_A20_RUN_633.bat (queue file q_a633.bat), not queued.

## Changed from the picture (R207, R233)

- **Both hangar mouths on the PORT flank, big: the forward one 3.2 long and the aft one 2.6, 1.58 high (three quarters of the flank), 1.9 deep to the back wall and 1.6 to the blast door.** Ryan's ruling for the round (the sheet's side view is the layout of record; the front view's mouths either side of the intakes are a drift); sized between the sheet's side view and the beauty so a 1.6 fighter fits and they read as launch bays with depth
- **Each mouth is a real recess with a torn plate rim, armoured doors slid clear on rails, launch rails on the floor, ceiling beams, a dim red lamp, frame ribs and an inner blast door on the back wall.** the Board's brief: they must read as launch bays with depth; designs.md's armoured doors slid open and red lamps
- **The mouths are lined dark (floor, ceiling, back wall and ends): only the rails, ribs, red lamps and the fighters catch the light.** the Board on round 1 (Nov 13): the mouths must be big, deep, dark openings that show from the beauty camera with the fighter in them; round 1's were 1.37 high and lit grey inside, so they read as shallow grilles
- **The bow block is as tall as the slab and about half its beam (3.2 across, 1.9 tall, 2.7 long); its face carries two huge intake tubes side by side, each 1.1 across (three quarters of the face's height), reaching 2.3 back into the block.** the Board on round 1 (Nov 13): the build had no twin tubes (two 0.8 tubes in a narrow block); the README's bow intakes and the beauty's two huge tubes. The concept sheet's plan draws the block about 0.4 of the beam; it is widened so the tubes fit side by side
- **Bow thrusters and the bow lamps on the bow block's flanks, the chin scoop under the web between the tubes.** the wider block and its tubes fill the old places
- **The bow block's front corners are closed plate, carrying the two shoulder dishes.** the beauty's front openings beside the intake block are the drift Ryan ruled out; designs.md puts the dishes on the shoulders
- **The slab is 5.5 wide over its hull, about 6 over the starboard bricks (hull length to beam 2.7 on the top view) and 2.05 deep.** the accepted beauty (v2s, "hull deepened") draws it about 2.4 long for its width, the sheet's top view 3.4; the build sits between, nearer the beauty (R229: the whole concept; as A17's head followed its beauty)
- **Two dorsal turrets, one on the fore deck tier and one on the aft.** data.js c_hulk: turret T twice (R221); designs.md's bow casemates, starboard flank guns and rocket rack have no slot, so they are not built
- **Five mismatched bells in a row along the top of the stern, one in a violet Eclipse trophy housing.** designs.md; the picture's eight become five
- **A fighter nosing out of the forward mouth and a second parked deeper in the aft one, both 1.6 long.** designs.md (the forward mouth); the game's squadron length gives the scale
- **The spare engine bell lies across the deck in a cradle, cold.** the picture's bell on the deck; designs.md: bolted down flat (field repairs)
- **The salvage deck is three low tiers of stacked plate with lockers bolted down, not loose junk.** Ryan R185: nothing hangs off the ship; stacked and bolted scrap brick (R196, R197)
- **One pair of grabbers under the bow block and two heavy grapple arms folded flat under the stern quarters.** designs.md (four bow arms become two, so the jaw is not A17's; the grapples drag prizes alongside)
- **Four attitude thrusters.** a ship in space needs them to turn
- **The plate between the mouths is 1.4 wide (the mouths 3.2 and 2.6 long, were 3.6 and 3.0), and the port mid breach anchor and boarding origin sit on it at x -0.65.** the recipe (issue 633): the export puts a breach anchor on open hull at least 0.03 of the ship's length (0.5) from every part; between round 2's mouths the plate was 0.6 wide, so no point on the port flank amidships was that clear of the rims (the plate between the mouths tears first, designs.md, so the anchor belongs there)
- **Every face is plated in courses at the hull's plate size (0.4 to 0.9), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses.** the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit's courses plating (kit.py, opt-in, issue 633)
- **Insides: two hangar deck levels behind each mouth, loot holds in the bow, a kennel deck, the core between the hangar decks, machinery and the engine room aft.** designs.md; R209, R215

## Open

- Belly detail between the bow grabbers and the stern grapples is designed here; the picture does not show the underside
