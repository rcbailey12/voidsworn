# voidsworn_SF3 build sheet: the Spire Dart, the Sunward Crusade fighter wing craft (first sheet)

Issue 769. Sunward fighter, data.js `fighter` (cls Squadron, `guns` T: Interceptor guns, 3 shots; hp 18, sp 6). Concept of
record: SF3 (contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg; Ryan, Nov 14 23:57 CST, R255: "Agree on sf3
and sb4"). The notes' own ruling block (design_notes_757.md) names SF4 at 23:51; R255 and the issue name SF3 six minutes later,
so SF3 is built. Designer of record: the Opus builder; the Board is the final designer and SF3 is a base (R233, R236).
Rendered in the issue 769 sandbox (Blender 5.3, Cycles CPU, 16 samples). No paint stack (issue 756 applies the Sunward stack
later) and no PC recipe run in this job. Its partner sheet is [voidsworn_SB4](../voidsworn_SB4/README.md).

![voidsworn_SF3 overview](voidsworn_SF3_sheet_overview.jpg)

Start here: [the overview](voidsworn_SF3_sheet_overview.jpg), [the whole concept beside the build](voidsworn_SF3_compare_SF3.jpg)
(R229), [both craft beside the S8 flagship at true game scale](voidsworn_SF3_SB4_true_scale.jpg), [both craft at the battle
camera, game size](voidsworn_SF3_SB4_battle_cam.jpg), [the weapon review](weapon_review.jpg) (R241), then the full
[sheet](sheet.jpg), [side_by_side.jpg](side_by_side.jpg), [fit_view.jpg](fit_view.jpg) and [cells.jpg](cells.jpg) (the concept is
one three-quarter picture with no true views, so cells.jpg shows it in place of the top and side views).

Files: design `tools/blender/build_sheets/ships/voidsworn_SF3.py`, inventory `voidsworn_SF3_inv.py`, beauty camera
`voidsworn_SF3_camera.json`, recipe entry `tools/recipe/ships/voidsworn_SF3.json` (bake none), the Sunward kit's craft parts in
`tools/blender/kits/voidsworn/` (its README, "Squadron craft"), the sandbox helpers in `contrib/opus/tools/issue769/`.

## Size (scale.md wins)

LENGTH 1.6, the hull table's CLS_LEN['Squadron']; the board draws a craft at 1.6 x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84
(docs/playbooks/scale.md, Squadron rows, binding). The design notes' 3.2 units for the fighter is overruled by scale.md: fighter
and bomber are the same length, and the fighter reads apart by its slim outline. Every station in the design file is a share of
LENGTH, so the length is one line. Measured on the true-scale picture: the S8 flagship 43.2 long, each craft 3.9 (3.84 plus the
lit edge), so a craft is about a twelfth of the flagship.

## The design, in short

1. **The forged blade**: one narrow body from the point to the stern, a low spine strip, the deck, upper facets out to a thin
   knife edge, lower facets, a flat belly; widest (0.37) at the stern third. No wing, no sweep, no aerofoil.
2. **The stern block**: the blade thickens into a raised armoured block with a sloping forward face; it holds the pilot, the
   reactor and the drives.
3. **The interceptor guns** (guns T): three short barrels in one emitter cluster on a shallow traverse ring, sunk in an armoured
   well on the blade's back near the bow (the concept's dorsal recess). They turn all round and elevate to 45.
4. **One radiator spire** on the stern block: upright, square-topped, four ember fins a side, an ember glow at its root: the
   flagship's spire line reduced to one, and never a tail fin.
5. **Two drives**: deep bells sunk in eight-sided armoured cowls in the stern face, smaller and dimmer than the concept's.
6. **No canopy**: the pilot looks out through one armoured ember slit in the block's sloping face. Heat louvres on the block's
   flanks (the concept's glowing slats).
7. **INSIDE** (small, for the build contract only): the gun feed, the pilot's cell, the reactor under the spire, the drive room;
   one seam (B-1) at the block's toe. The game shows a craft's death as a spark and hides it (godot/fx/fx_death.gd
   `_wing_death`), so nothing breaks open; the build contract (tools/blender/build_sheets/contract.py) refuses a sheet with no
   inside and no seam.

## Weapons (R221, R241)

| Weapon | Mount | data.js and lore | Built as |
|---|---|---|---|
| ![](weapon_guns.jpg) Interceptor guns (guns) | G1 | 3 shots, 4 damage, range 1 (k sq), x2.2 against squadrons; battle look `guns` | three barrels in one banded emitter jacket on a block mantlet, a low faceted housing on a traverse ring in a riveted well; flared muzzles, dark bores |

Weapon match (`weapon_match.json`): **PASS**, 0 problems. Slot 0 guns T, 3 shots: G1, three muzzles, every barrel fires every
volley. No dish, antenna or mast (0 sensor pairs).

## Checks (sandbox, Nov 15 2026)

| Check | Result |
|---|---|
| Fit check (clash.py) | 0 of every kind; 56 objects, 7 parts, 114 rays, 1 turret swept all round ([fit_report.md](fit_report.md)) |
| Weapon match and `weapon_match_selftest.py` | PASS; self-test PASS (25 planted faults, 4 of them craft faults) |
| Build contract (`sheet_contract_selftest.py`) | PASS: length 1.6, 1 transverse seam, 3 muzzles in slot 0, 1 turret pivot, 2 engines, 4 inside objects, the skin |
| Stage 4 audit (`audit.py` on the sheet_hull build) and `audit_selftest.py` | PASS: 37 parts, none across the seam, the gun not into the craft; self-test PASS |
| Inventory (R218, R221) | 0 failing; every built part has a job ([inventory.md](inventory.md)) |
| Outline overlap at the camera fitted to SF3 | 90.8 percent, mass outline 91.1 (reported, not a bar; [outline_check.jpg](outline_check.jpg)) |
| Detail density, mesh (R224, `contrib/opus/tools/issue738/density_mesh.py`) | flagged: radiator 0.23 and 0.20 of the hull, the louvres 0.45 and 0.37, the drives' edges 0.53 ([density_mesh.json](density_mesh.json)); the hull's plating is dense for a craft (see Budget) |

## Budget (the stage 4 sheet_hull build)

18,606 triangles outside, 112 inside; 7 outside materials (black iron, darker iron, worked iron, dark, ember fins, bell lining,
throat glow), so about 7 draw calls a craft once joined by material, against 5 surfaces for today's code-built craft. A wing of
four: about 74,900 triangles. The forged plating is 12,462 of the 18,606. Reported, not capped; the scene gate is not measured
here.

## Changed from SF3 (every change, with its reason)

The full list is in [feature_table.md](feature_table.md), "Changed from the picture"; the same list is on the sheet.
