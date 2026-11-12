# Build sheets, issue 532: corsair_A16 and corsair_A17 (Opus worker, Nov 11 2026)

Ryan, R203: "I want to make sure that they are good enough to actually hand build from in blender." Both sheets are built
from one Blender blockout per ship (tools/blender/build_sheets/), rendered on the PC (Blender 4.5.14, Cycles on the 5080,
about a minute per ship), and laid out in the sandbox. Sheets: docs/ship_pipeline/build_sheets/corsair_A16/ and corsair_A17/.

| Ship | Game length | Hull beam / depth | L:B / L:H (hull) | Side vs top length | Outline at the beauty camera |
|---|---:|---|---|---:|---:|
| corsair_A16 Pyre-Barge | 26.0 (model 26.0) | 8.30 / 4.45 | 3.13 / 5.8 | 0.00 percent | 85.8 percent |
| corsair_A17 Pack Hunter | 14.5 (model 14.52) | 4.88 / 3.83 | 2.97 / 3.8 | 0.00 percent | 86.3 percent |

## How the proportions were checked (proportions first)

- A camera is fitted to the accepted beauty (fit.py: the camera only, never the ship) and the blockout outline is scored
  against the beauty's cut-out. Then beam and height are scaled and rescored: for A16 the score peaks at the built
  proportions (0.85, 0.92, 1.0, 1.08 scored 83.6, 83.8, 84.3, 83.3 at the first camera); for A17 the leaner hull (0.88 of the
  first fit) scores better (85.5 to 86.3) with a more natural camera (49 off the bow, 30 up, roll 1.4 instead of 6.7).
- Cross-checked against the round 8 generated sheet's top view (A16 about 3 to 1) and the beauty's bow face against its
  foreshortened length.
- Codex's A16 (PR 536) was 26 by 14.8 (1.76 to 1): its TRELLIS shape reference read the beauty's depth as 0.59 of the length.
  Single-picture shape guides cannot judge depth, which is why the outline scan above varies proportion explicitly.
- The outline gate is under the recipe's 90 percent on both. The misses are the deliberate corrections (the sagging chain
  loop, whose enclosed gap the cut-out counts as hull; the claw and jaw blades; guns retrained forward). Codex's 90.2 came
  from an egg that fills the blob; the gate measures overlap, not proportion. The Board decides whether that is acceptable.

## The standard's fail list, line by line (both ships)

1. A required view missing, cropped or in perspective: PASS. True side, true top, underside, bow-on and the engine end are
   orthographic renders; the three-quarter identity view is the accepted beauty, with the blockout's own 45/30 view beside it.
2. A side or top view re-projected from the three-quarter: PASS. All views are renders of the 3D blockout.
3. Dimensions disagreeing by more than 2 percent: PASS. Length side vs top 0.00 percent on both; model vs game 0.00 (A16) and
   0.14 (A17); height side vs bow-on 0.00; beam top vs bow-on 0.58 (A16) and 1.72 (A17) percent of length (the top view
   measures its widest row, the bow-on view the union over all stations, so the gun barrels make the small gap).
4. Counts, outlines or colour breaks differing between views or the table: PASS. One model writes every view and the table.
5. A gun pointing aft or ambiguous, or the wrong aspect: PASS. Every gun rests forward or trained 35 to 60 degrees off the bow
   (kit.py refuses a yaw past 100 degrees); a gun pointing square out of the side would be end-on and ambiguous in the profile,
   so broadside guns rest trained forward. Far-side guns are grey rings in the side view.
6. A feature missing from a view with no note: PASS. Belly items are noted as not shown in the top view and are on the
   underside; the engine end has its own view.
7. No stated length, scale bar or feature table: PASS. Length from hull_table.gd, 5-unit bars on every orthographic view,
   the table on the sheet (compact) and in full in feature_table.md (count, station, offset, height, direction, game slot,
   source).
8. Anything that reads as a sea vessel: PASS as I read it. Flat armoured bellies with chines, no keel or stem, no masts or
   cranes; dishes, scoops, claws and engine bells. The Board should look at the A16 profile (a long slab with a raised stern
   castle) for any tanker read.

Side view prow overhang dimensioned: A16 1.32 (the scoop lips ahead of the deck edge), A17 2.37 (the jaw tips).

## INSIDE (R98, R209)

Each sheet carries a centreline cutaway (the port half removed) with deck levels, frame stations (F0 to F6 on A16, F0 to F4 on
A17), numbered spaces (core, engine room, magazines, hangar on A16, kennels and holds, machinery), armour thickness by zone,
the break lines on the chained patch seams (Battle-barge 3, cruiser 2, factions.md) and the breach anchors from the PR 530
contract (Battle-barge 6 + 1 = 7, Cruiser 4 + 1 = 5, uneven, spread prow, mid, engine), plus hp_core, two rcs, two boarding
points and, on A16, the launch bay for data.js hangar 2.

## Dressing the views (step 4 of the issue)

Not done: the sheets carry the clean blockout renders. The issue allows it ("If step 4 cannot hold the shape, deliver the clean
blockout renders"), Codex's local Qwen pilot on the same views was rejected for drifting, and the trial (issue 398) showed
image models do not hold counts. The beauty stays the finish reference, beside the views on each sheet.

## Things the Board should know

- PC trap (new): device_commit_files can write a STALE copy when the same container path is committed again in one session
  (kit.py and corsair_A17.py landed old twice). Commit each new version from a fresh path, then stage the PC file back and
  compare a checksum before queueing the job.
- The PC jobs: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\render.bat <ship> <tag> ...`, queued with one-line files in
  queue\; renders and .blend in opus532\<ship>\. tools/blender/build_sheets/render_sheets.bat is the double-click version from
  any clone.
- Question for Ryan (identity): A17 is built about 12 percent leaner than its first fit (length to beam 3.0 instead of 2.6),
  because the picture reads both ways and factions.md says "lean". If he wants the heavier bulldog of the picture, it is one
  number in corsair_A17.py.
