# Warden, Opus blind leg (issue 1889, voidsworn_S9O)

Blind builder pair 2: the Sunward Warden frigate rebuilt from its accepted concept alone, beside Astra's S9A. Never merged
unless Ryan picks it. Pictures here are rev 2, stage "paint proof" (cloud CPU bake, not the PC run, not in the game).

## What was read

- The brief, /mnt/project-files/board/1889/opus_brief.md.
- docs/ship_pipeline/build_sheets/voidsworn_S9/concept_beauty.jpg and concept_sheet.jpg (the approved pick, R331).
- The "Warden, frigate" table in contrib/muse/design/class_family_sunward_2026_11/designs.md (it wins over the pictures).
- Method: docs/playbooks/ships.md section 0, the 1888 hull methods (tools/recipe/hull_methods.py), the Sunward kit, and the
  S10 Vigil and S8 sheets as the family pattern.
- Not read: the voidsworn_S9 sheet, its inventory, recipe json or history, the S11 Harrow sheet (it says it is built on S9's
  pattern, so it was closed as soon as that line showed), codex/issue-1889 and contrib/codex/warden_astra_1124.

## Files

| File | What |
|---|---|
| tools/blender/build_sheets/ships/voidsworn_S9O.py | the build sheet |
| tools/blender/build_sheets/ships/voidsworn_S9O_inv.py | the parts inventory, written from the pictures |
| tools/blender/build_sheets/ships/voidsworn_S9O_camera.json | the beauty camera fitted to the concept (outline overlap 84.2 percent, body 86.0) |
| tools/recipe/ships/voidsworn_S9O.json | recipe json, game_code V14_23, cell S9O |
| contrib/opus/warden_opus_1124/S9O_*.jpg | the five views, the same five as the Picket comparison |
| contrib/opus/warden_opus_1124/render_views.py | renders those five views from any stage 5 blend with fixed cameras, so S9A, S9O and S9 can be shot alike |

## Method

- Hull: three modules ending at their authored breaks. Midships and drive are `FlatSoleLoft` modules (`loft_module`); the
  spearhead keeps the loft's ten-point section and closes it to one point at mid height (a diamond at the tip).
- Plating: the Sunward kit's own forged rows (`forged_plates`), rivets scaled to the frigate; never `plate_region` (Navy only).
- `slatted_cassette`: eight reactor cooler cassettes on the aft deck beside the spine block (dark iron slats over ember).
- `belly_cover`: five removable covers along the belly service trunk (each lid its own mesh).
- `broken_stripe`: the worked-iron spike along the spearhead's ridge, broken at the casemate; the trim race along each flank's
  band, broken at the boarding door.
- Fittings in hull-tone iron, seated on hull structure (the Picket v2 lesson): the casemate on a forged seat, the flak tubs on
  forged strakes, the coolers in the deck.
- Frigate-size kit parts: the engines are the kit's bell built at 1/0.45 and shrunk (as the radiator's scale hook does);
  lamps, louvres and slits use the kit parts' own size arguments.

## Design calls (the table wins over the pictures)

- Repeater casemate at station 14 percent (the concept draws it near 25), three barrels in one rotary cluster, all firing.
  Rev 2 (Ryan, Nov 24: the rev 1 gun "looks comically large and out of place"): the casemate is built at kit scale 0.3
  instead of 0.5, about 40 percent smaller every way, on a smaller seat.
- One spark flak pair at 60 percent (the beauty draws four tubs), on strakes at the deck edges.
- Three spires at 68 / 76 / 84 percent (the beauty draws four), tallest 0.64, about 70 percent of the table's 0.9 (R331).
- Beam 1.5 at 72 percent (the concept reads nearer 1.1 wide).
- Command slits: two, either side of the feed trunk, in the spine block's face at 58 percent.
- Breaks: spearhead root (B-1), drive section (B-2), lengthwise along the lower band facet (B-3), the spire line as one piece (B-4).

## Evidence (cloud, Nov 24 2026, rev 2)

- Fit check: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0.
- Weapon match: PASS (0 problems).
- Inventory: 0 failing.
- contrib/opus/tools/issue1414/cloud_ship_check.sh: stage 4 audit, outline steps (overlap 79.9 percent), sheet contract, unbaked export,
  check_export and its self-test, the V14_23 game export points and the death seam all PASS.
- Stage 5 paint (tools/blender/r209/bake_sheet.py, 1024, 8 samples, CPU): the Sunward stack, 6 decals placed.
- Budget (stage 4 build): 40,100 triangles outside, 4,124 inside, 280 outside objects, 21 inside.
- Not run here: the PC's seven stages (OPUS1889_S9O_SHIPJOB.bat on opus/pin-1889-s9o; the Board queues it), GPU renders,
  in-game shots.
