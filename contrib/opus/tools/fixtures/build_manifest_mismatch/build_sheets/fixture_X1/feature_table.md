# fixture_X1: a deliberately mismatched build sheet (issue 550 test fixture, not a ship)

Read by contrib/opus/tools/build_manifest_tests.js only. Its manifest.json disagrees with this sheet on purpose; the
planted faults are listed in ../../README.md. Frame and units as on a real sheet.

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note | Route |
|---|---|---:|---:|---:|---:|---|---|---|---|---|
| K1 | twin turret | 2 barrels | 30.0 | 1.00 | 1.50 | forward | P scatter | picture | planted: the manifest says hand-built | kit |
| K2 | engine, bell 1.2 across | 1 | 98.0 | 0.00 | 0.00 | exhaust aft | - | picture | matches | kit |
| G1 | listening dish, 1.8 across | 1 | 15.0 | 0.50 | 1.20 | - | - | picture | planted: generated, no library entry | generated |
| G2 | boarding claw, 2 segments, 3 fingers | 1 | 20.0 | 0.00 | -1.50 | hook forward and down | - | picture | planted: entry not reviewed | generated: test_lib/unreviewed_claw |
| G3 | listening dish, 1.2 across | 1 | 60.0 | -0.50 | 1.20 | - | - | picture | generated from a reviewed entry: passes | generated: test_lib/reviewed_dish |
| G4 | antenna array, 1.4 tall, 2 whips | 1 | 80.0 | 0.00 | 1.50 | - | - | picture | planted: entry the library does not hold | generated |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull slab | 5.0 to 95.0 | -2.00 to 2.00 | -1.00 to 1.00 | soot | planted: the manifest says kit (no Route column here, so the sheet says hand-built) |
| Deck | 20.0 to 60.0 | -1.50 to 1.50 | 1.00 to 1.40 | rust | matches |

## INSIDE (R98, R209): what each break reveals

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 40.0 (seam wanders 38.0 to 42.0) | planted: the manifest gives midships piece 1 no interior |
| B-2 | 70.0 (seam wanders 68.0 to 72.0) | planted: the manifest has no stern piece |

Full interiors throughout the hull (R215).
