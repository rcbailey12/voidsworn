# Station kit (tools/blender/hs/station_kit.py)

Updated Nov 9 2026 for issue #230 (ST10 of the Nov 6 environment audit). The earlier text described the kit as the
issue 61 proxy blockout gate only; the kit has since carried issues 183, 195 and 199. This page says what the kit is
now, which of its checks fail a run and which only report, and how each run starts.

## What the kit is

One Blender 4.5 script builds both station variants (fleet station and refinery, R79) from one shared spine. X is the
spine, Y lateral, Z up; dimensions are world units. It has three stages, each with its owner approval:

| Stage | Issue | Ruling | What it adds |
|---|---|---|---|
| Blockout | #61 | R91, R94 (shape locked Nov 4) | spine, cradle, towers, gantry, refinery column and tanks |
| Detail additions | #183 | R100 (additions only on the R94 shapes), R104 (keep the shapes, repaint) | equipment housings, process pipes, antenna arrays, break lines |
| Readable paint | #195 | R105 (the readable-paint standard), R109 (more surface detail needed) | three-coat metal repaint, faction lips and tower band, light strips |
| Detail pass | #199 (open) | R113, R116 (re-specced: triangles and ms reported, never capped) | surface detail on top of the #195 paint |

Breakable by design (R98): `break_variants` cuts authored junction lines with hollow liners and decks, exported
separately; the intact R94 solids are never cut.

The live board still draws the painted A4 objective O1_37 through `godot/assets/ships/a4_props.gd`. No kit output is
swapped into the game yet: every output is review material until Ryan approves a swap (backdrops synthesis section 5).

## Checks that fail a run (correctness)

- `audit()`: every part touches the graph (no disconnected parts), no gun faces backward, no static part blocks a
  forward battery lane, and the bounds are finite.
- `merge_export()`: the re-imported GLB has the same triangle count it exported, with finite positions.
- Detail stage: every R94 primitive keeps its exact vertex, polygon, transform and bevel hashes (`locked_snapshot`).
  This is R100's additions-only doctrine, which R113 kept.
- Breaks: three material slots kept, no uncapped boundary edges, and the break GLB round trip matches.

## Values that are reported, not asserted

- Triangles (R113, Nov 7; the R100 40k and 45k ceiling is withdrawn, ST5 in #208): printed as
  `[station-detail] <variant> triangles N` and stored as `triangles_roundtrip` in the audit JSON.
- The R91 and R94 shape values (ST3, #230): total length (R94 default 46), skyline top (R91: at least 15), the fleet
  dorsal tops (4.5, 5.0, 4.0, 6.5), the fleet gantry crossbeam top (9) and the refinery secondary process column top
  (under 12). They are stored as `r94_shape` and `r94_heights`, each with `matches_r94`. A build that differs prints a
  `REPORT:` line and carries on, so a better silhouette can be tried without editing an assert. The R94 shapes stay
  the default build.
- Station milliseconds are priced on the #207 scene gate like ships (R113, R116), not in this script.

## How each run starts (PC, through the queue)

- Blockout: `tools/pc/jobs/station_blockout.bat` (writes `blockout_audit.json` and the review renders; Pillow sheets by
  `station_sheets.py`).
- Detail and readable paint: `tools/blender/hs/station_paint_review.bat` runs `station_kit.py --detail
  --readable-paint`, then `station_check.gd --paint-check` and the 1080 and 2160 `--paint-review` captures, then
  `station_paint_sheets.py` (blur sheets, geometry equality, paint measurements). `--finish-breaks` completes an
  interrupted break export.
- Every review step writes `detail_audit.json` in the shots folder. Lane A needs the OptiX GPU.

## Fit notes kept from issue 61

The full cradle is 36 units long and 12 wide; the real Battleship (33.6 by 8.83) fits it. At the compact size of 30
the cradle shrinks to 23.48 and the Battleship overhangs. The Frigate (10.4) has a 12-unit service berth on the full
station, 7.83 at the compact size. The comparisons keep both ships at their shipped sizes, so the lack of an enclosed
fit at the compact size is visible rather than hidden. Do not resize the ships or the compact station to hide it.

Studio renders are review material and are never described as in-game shots.
