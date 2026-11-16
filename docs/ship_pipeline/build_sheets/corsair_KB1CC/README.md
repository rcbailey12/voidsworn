# corsair_KB1CC build sheet: the Wide Glacis, the Ashfall Hullbreaker bomber wing craft (R275 shape pass)

Issue 793. Hullbreaker bomber, data.js `bomber` (cls Squadron, `bombs` T: Bomb payload, 2 shots; hp 28, sp 5; the Hullbreakers
launch bombers, data.js FACTIONS corsair sq 'bomber'). Concept of record: KB1C-C, the Wide Glacis
(contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg; R259, Ryan, Nov 15: "the best by far", still a space
bomber, never a boat, barge, platform or ground vehicle). KB1C-C's written terms stand (the mouths at the glacis's extreme corners
in dark collars, the armoured lip), except its beam guard: R273 (Ryan, Nov 15 18:46 CST, on this sheet's first version, held at
0.61 of the length: "Yes, I agree with your take on the bomber. Wider for sure.") lifts it, so the craft now takes the render's
width. R275 (Ryan, Nov 15 21:28 CST, on the widened sheet: "Yes, send it back for those") sent it back for one shape pass: the
top is now the render's sloped glacis, low at the bow lip and rising to the stern bells with the edge rails running diagonally up
it, and the plating is the Hullbreaker patchwork (fewer, bigger, uneven plates of mixed size and angle, never rows; R240). Elsewhere, where the render drifts from the written sheet (design_notes_785_round3.md), the written sheet governs. Designer of record: the Opus builder; the Board is the
final designer and KB1C-C is a base (R233, R236). Rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU). No paint stack
(the Hullbreaker stack applies later) and no PC recipe run in this job.

![corsair_KB1CC overview](corsair_KB1CC_sheet_overview.jpg)

Start here: [the overview](corsair_KB1CC_sheet_overview.jpg), [the whole concept beside the build](corsair_KB1CC_compare.jpg)
(R229; since R275 its big build panel is the craft turned by eye to the picture's three-quarter, because the fitted camera looks
from almost dead ahead, where the ramp foreshortens to a block; the fitted view is the small panel), [the three issue 793 craft beside their flagships at true game scale](../hegemony_HF1D/issue793_craft_true_scale.jpg),
[the three at the battle camera, game size](../hegemony_HF1D/issue793_craft_battle_cam.jpg), [the weapon review](weapon_review.jpg)
(R241), then the full [sheet](sheet.jpg), [side_by_side.jpg](side_by_side.jpg), [fit_view.jpg](fit_view.jpg) and
[cells.jpg](cells.jpg) (the concept is one three-quarter picture with no true views, so cells.jpg shows it in place of the top
and side views).

Files: design `tools/blender/build_sheets/ships/corsair_KB1CC.py`, inventory `corsair_KB1CC_inv.py`, beauty camera
`corsair_KB1CC_camera.json`, recipe entry `tools/recipe/ships/corsair_KB1CC.json` (bake none), the craft parts in
`tools/blender/kits/hullbreakers/craft.py` (the kit's README, "Squadron craft": a module of its own, because the kit's parts.py is
hashed into the A16 fixture), the sandbox helpers in `contrib/opus/tools/issue793/`.

## Size (scale.md wins)

LENGTH 1.6, the hull table's CLS_LEN['Squadron']; the board draws a craft at 1.6 x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84
(docs/playbooks/scale.md, Squadron rows, binding). Every station in the design file is a share of LENGTH. Measured off the views:
1.60 long, 1.92 across the corner pods (1.20 of the length: the render's width, R273), 0.38 tall at the stern housing (the
ramp's top; 0.27 before R275, when the top was flat). The first sheet held 0.98 across (0.61, the old beam guard).

## The design, in short

1. **The central body** (R275): its top one long glacis ramp, low at the bow lip and rising aft (about 10 degrees) to an armoured
   lip against the stern housing; a flat belly with chines. Armoured edge rails with bolted clamps run diagonally up the ramp's two
   edges. At the bow the ramp sits below the shoulders, the rails at the foot of the shoulders' inner walls; aft it stands above
   them.
2. **The armoured lip** across the top of the ramp, against the stern housing, ends the slope (so it reads as armour on a hull)
   and carries the crew's vision slit in its face, looking forward down the ramp (no canopy).
3. **Two bomb tubes** (bombs T) at the glacis's extreme corners, the widest-separated pair in the field: each a dark armoured
   collar with welded bolts round a dark bore, the next salvaged bomb's nose seated deep inside, on an eight-sided armoured drum
   that runs back into the flank. Fixed forward: the bomber turns onto its target. Both fire every volley.
4. **Two shoulders** behind the pods, their tops sloping down and out to a thin edge (a flattened six-sided section, never a box on
   two track-like sponsons), each holding a bomb row; the starboard one a touch lower and shorter (lopsided). In each shoulder's
   slope a **hoist bay**: a heavy frame, pipes and the hoist block, an armoured door in a second tone.
5. **The thruster bank**: five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) high
   in the stern housing's aft face, at the top of the ramp.
6. **Plating** (R275): the Hullbreaker patchwork, laid by the sheet's own plater (`patchwork()` in the design file, so the kit's
   course plating and the A16 fixture stay as they are): each face cut at random into plates of mixed size (about 0.12 to 0.30
   across), each turned a few degrees (a third of them hard), its corners out of square, lapping its neighbours at its own height,
   a few left bare; rivets on a few plates only. The colours as before: rust and dried blood the main tones with soot and iron
   between and a few big trophy patches (R240, R252), by a shuffled share per face so no face runs dark.
7. **INSIDE** (small, for the build contract only): the two magazine rows in the shoulders, the crew cell under the lip, the
   reactor under the ramp, the drive room in the stern housing; one seam (B-1) at a weld between the reactor and the crew cell. The game shows a craft's death as a spark
   (godot/fx/fx_death.gd `_wing_death`), so nothing breaks open.

## Weapons (R221, R241)

| Weapon | Mounts | data.js and lore | Built as |
|---|---|---|---|
| ![](weapon_bombs.jpg) Bomb payload (bombs) | BT1, BT2 | 2 shots, 9 damage, range 1 (k sq), pierce 0.6; battle look `bombs` | one bomb tube in each corner pod: a dark armoured collar with welded bolts, a bore with a bomb nose seated deep inside, an eight-sided drum with two riveted bands and a welded patch |

Weapon match (`weapon_match.json`): **PASS**, 0 problems. Slot 0 bombs T, 2 shots: BT1 and BT2, one muzzle each, the same type,
mount and size; both fire every volley. The table already allows bombs on a fixed bomb-tube launcher (FITS `bombs`); no new row.

## Checks (sandbox, Nov 15 2026)

| Check | Result |
|---|---|
| Fit check (clash.py) | 0 of every kind; 116 objects, 10 parts, 76 rays, 5 exhaust cones, 3 apertures, 4 lanes ([fit_report.md](fit_report.md)); the first layout's bells touched (fixed, see the report); the R275 pass found nothing new |
| Weapon match and `weapon_match_selftest.py` | PASS; self-test PASS (36 planted faults, 7 of them craft faults) |
| Build contract (`sheet_contract_selftest.py`) | PASS: length 1.6, 1 transverse seam, 2 muzzles in slot 0, 5 engines, 5 inside objects, the skins; its three broken inputs refused |
| Stage 4 audit (`audit.py` on the sheet_hull build) and `audit_selftest.py` | PASS: 61 parts, none across the seam (B-1 at -0.238); self-test PASS (BT1 moved onto the seam is refused, W1 the slit allowed as structure) |
| Inventory (R218, R221) | 0 failing; every built part has a job ([inventory.md](inventory.md)) |
| Outline overlap at the camera fitted to KB1C-C | 81.3 percent, mass outline 81.6 (reported, not a bar; [outline_check.jpg](outline_check.jpg)); 84.6 before R275: from the fitted view ahead the ramp's raised stern stands above the picture's outline (a shallower ramp scored 83.3 but read flat); the first sheet, at 0.61 of the length, scored 51 |
| Detail density, mesh (R224) | no flags: the hoist bays 3.6 times the hull's triangles per square unit (0.72 before R275: the bigger plates made the hull plainer, so the bays now stand out), the tubes 4.6, the slit 65 ([density_mesh.json](density_mesh.json)) |

## Budget (the stage 4 sheet_hull build)

17,936 triangles outside, 140 inside (R275; 53,988 before, with the course plating); 13 outside materials (soot, soot2, rust,
blood, iron, steel, pale, violet, dark, ember, glow, warhead, brass), so about 13 draw calls a craft once joined by material,
against 5 surfaces for today's code-built craft. A wing of four: about 71,700 triangles. Against the Sunward pair: SF3 18,606
outside and 7 materials, SB4 20,516 and 6, so KB1CC is now under both in triangles and over both in materials. The plates are
about 4,000 triangles and their rivets about 2,700; the paint stack would fold the plate tones into one textured surface.
Reported, not capped; the scene gate is not measured here.

## Changed from KB1C-C (every change, with its reason)

The full list is in [feature_table.md](feature_table.md), "Changed from the picture"; the same list is on the sheet. In short: the
craft widened to the render's proportions, about 1.2 of its length (R273); its top the render's glacis ramp rising aft, the
patchwork plating (R275); the corner mouths are dark bomb tubes, not lit like engines, and
fixed forward; an armoured lip with a vision slit ends the glacis at the stern housing; the side bays are the bomb hoists in the shoulders' slopes; the
shoulders slope to a thin edge and the pods sit at mid-height on the corners, so nothing hangs under the hull and nothing reads as
track or roller; the stern row is five mismatched bells in a recess; no dishes, claws, antennas or lamps at this size.

## Open

- The colours are schematic zones; the Hullbreaker paint stack (rust, soot, trophy colours, the red running lights) paints the
  craft later.
- The ramp's front third runs between the shoulders: by the design file's numbers the shoulders' tops (0.064 of the length at
  their inner edge, the starboard one a touch lower) stand above the ramp from the bow back to about station 0.13 to 0.19, so the
  rails start at the foot of the shoulders' inner walls and the ramp only stands clear of them a third of the way back. It keeps
  the corner pods at their height; lowering the shoulders' fore stations would bring the whole ramp into view. A Board call.
- At its new width the bombers touch their wingmates in the game's wing formation (godot/render/squadron_wing.gd sets the
  offsets from the craft's length, about 0.95 of it sideways; see the true-scale and battle pictures). The formation, or the craft
  data that sizes it, needs a wider spacing for this bomber; a Board call.
- R274: the pale trophy plates stay on this sheet as the pale zone; the Hullbreaker paint stack makes them dark grey metal for every
  ship (issue 726).
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7
  export or install here.
