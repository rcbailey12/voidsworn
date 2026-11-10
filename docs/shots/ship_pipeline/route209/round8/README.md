# Issue 209 round 8: Ab7 becomes Ab8

Branch `opus/issue-209-r8`, draft PR 389. Brief: the Board comment on issue 209 of Nov 10 ("round 7 result and the round 8 brief").
Sheets in this folder, battle camera first. PC output: `Downloads\voidsworn_test\opus209\out8b` (the adopted bake) and `out8` (the
first bake, kept for the before and after).

## The short read

- **Paint: yes, closer, and it reads in the game.** At the game's own camera the bow deck is now red-brown (88, 50, 40; Ab7's was
  a pale salmon 139, 103, 92) and the midship deck is copper (91, 50, 40), no longer pink (Ab7 110, 78, 70). Big orange rust
  blotches show on the bow and the midship tops. The bow deck's olive in round 7 and in this round's first bake was a UV fault,
  not paint (step 5).
- **Shape: a little closer, short of every target but one.** Bow third 90.3 to 91.5 (target 93), bow inner edges 42.6 to 46.4
  percent (target 55), whole ship 89.7 to 90.3 (gate 90: now over it). The near deck edge now sits 4.3 px from the concept's
  (Ab7 14.3). Two fit tries were used, as the brief allows; there is no third. Why it stopped short is below.
- **Game:** the stage 7 export, its check and its self-test pass (101,892 triangles, 28 hard points); the game loads Ab8 in
  C15s_23's place and it fires. Cost is level with Ab7.
- **PC bakes used: 2 of 3.** The third was not needed: what a bake can change (the bow deck colour, the midship pink) is right
  in the game now.

## Step 1: the bow shape, fitted (fit8.py, armA8.py)

The concept's bow, read before fitting: a long, low, rounded prow; a short step up to the forecastle hood that carries the twin
bow guns; the near deck edge runs nearly straight from the nose back to the first casemate and then rises slightly; a slab side
with the casemates framed in it; a flat belly with the ventral fin aft of the bow.

`fit8.py` fits smooth numbers (deck height, a superellipse plan, slab, tuck, belly, the hood face and lip, the bow gun and fin
offsets) by coordinate descent on the outline per third at the concept camera, with the bow's inner edges in the score. Every
number is held to a range that keeps the design: flat deck, sharp deck edge, slab side, flat belly, so no raked stem and no keel
(AGENTS.md). Each result is rebuilt in full by `armA8.py` and scored by `outline_thirds.py`.

| Sandbox scores at the concept camera | Bow third | Bow edges within 6 px | Concept bow edges matched | Whole ship | Near deck edge |
|---|---:|---:|---:|---:|---:|
| Ab7 (round 7) | 90.3 | 42.6 % | 52.6 % | 89.7 | 14.3 px |
| Try 1 (outline only) | 93.1 | 45.5 % | 53.7 % | 91.0 | 24.7 px |
| **Try 2 = Ab8 (outline plus the traced deck line)** | **91.5** | **46.4 %** | **55.4 %** | **90.3** | **4.3 px** |
| Ab8 game export (glb of the first bake, out8; same shape) | 91.5 | 46.8 % | 58.1 % | 90.2 | |
| Targets | 93 | 55 % | | 90 | |

Midship (90.6) and stern (85.0) did not move; the fit only touches the bow third.

Try 1 reached the outline target, but only by dropping the near deck edge 25 px under the concept's: it filled the concept's
outline with hull side where the concept has deck. That is a better number and the wrong ship, so try 2 adds the concept's near
deck edge as a traced line (`concept_bow_trace.json`, measured by `deck_line.py`) and was adopted. From the side (bow.jpg, the
fit tries row) Ab8 keeps a blunt, flat-fronted space prow and a flat belly: no stem rake, no keel.

### Why the fit stopped short

1. **One concept view.** The concept is a single painting from one camera. The outline at that camera does not pin the depth of
   the bow: a lower, wider prow and a taller, narrower one draw almost the same outline. Try 1 and try 2 are two answers that
   both fit the outline; only the traced deck line separated them, and it costs about 1.6 points of outline. A second concept
   view (side or top) would remove that freedom.
2. **The camera is estimated.** The concept camera was solved in round 4 from the painting. A painting is not a true
   perspective; a degree of error in the camera moves the bow outline by several pixels, which is the size of what is left.
   The yellow strip along the top of the Ab8 outline (the hood and bow guns standing above the concept's line) is partly this.
3. **The inner-edge score is mostly not hull shape.** Its concept edges are luminance edges in the painting: rust blotches,
   painted panel lines, highlights. The model's edges are flat-shaded geometry. Moving hull sections cannot create edges that
   are paint in the concept; 55 percent would need the bow's plates, hatches and casemate frames placed edge for edge on the
   painting, which is a detail pass, not a shape fit (round 7 tried a detail pass and the outline got worse).
4. **The design ranges.** The fit is held to a flat deck, a sharp deck edge, a slab side and a flat belly. The concept's prow
   curves a little in section; a fit allowed to bow the side or round the deck edge would score higher and break the hull rules
   that keep it a space ship. I kept the ranges.
5. **Few numbers.** About a dozen smooth numbers describe the bow. More sections (a knot every few percent of the length) would
   follow the outline closer, at the price of a lumpier hull that then needs fairing.

What a different approach would need: a second concept view of the bow (a side or top painting from Rey's image models), or a
better trace source than the painting (a cleaned line drawing of the concept's edges), and then more sections with a fairing
term. Without a second view, more fitting mostly trades outline against deck edge.

## Step 2: casemates aimed 8 degrees forward of the beam, level

Board ruling on PR 341. Aim (0.139, 0.990, 0) for the port casemates, mirrored to starboard. weapons.jpg, the bow casemates row.
The export check reads the hard points as aimed out and forward (no backward-aimed point; the self-test's backward case still
fails as it must).

## Step 3: paint in layers from the concept

Layer 1, region colours sampled from the concept: a deck red on the up-facing hull of the red front (the bow deck brighter than
the midship tops), the pale dust that went salmon in the game cut to a thin dusting, decks less metallic. Layer 2, rust in the
concept's big orange blotches (noise at about 0.05 of the ship's length) on the decks and upper sides. Layer 3, round 7's wear
and grime unchanged. `preview7.py` gained `light=game` (the game's key, fill and ambient) so paint was judged under the game's
light in the sandbox before baking.

Sampled colours (paint.jpg, `paint_game.json`, `paint_regions.json`):

| Region | Where | Concept | Ab7 | Ab8 |
|---|---|---|---|---|
| Bow deck (forward of the hood) | in the game | | 139, 103, 92 (pale salmon) | **88, 50, 40 (red-brown)** |
| Bow hood top | in the game | | 164, 122, 105 | 138, 89, 74 |
| Midship deck | in the game | | 110, 78, 70 (pink) | **91, 50, 40 (copper)** |
| Aft side | in the game | | 67, 62, 58 | 61, 56, 53 |
| Bow deck | concept rig | 172, 127, 118 | 55, 41, 35 (olive) | 71, 44, 38 |
| Bow side | concept rig | 63, 33, 28 | 50, 23, 20 | 44, 18, 14 |
| Casemate plate | concept rig | 68, 43, 39 | 63, 51, 45 | 58, 29, 25 |

**Is the bow deck red in the game? Yes**, red-brown, where Ab7's read pale salmon at the game camera and olive close up.
**Is the midship deck still pink in the game? No**, it reads copper with rust blotches. Under the concept rig in Blender the
midship tops beside the drum racks still look lighter salmon; in the game they do not.

## Step 4: the outline at the battle camera (outline_battle.py)

The concept exists from one camera only, so the battle camera outline is scored against B0, the shape reference made from the
concept. That makes it a consistency check, not a concept match (outline_battle.jpg).

| Against B0, bow / whole | Game camera (34 degrees up, port beam) | Studio battle camera (55 up, azimuth 150) |
|---|---:|---:|
| Ab7 | 86.9 / 88.3 | 75.5 / 86.1 |
| Ab8 | 85.2 / 87.7 | 74.6 / 86.0 |

Ab8 moved away from B0 at the battle cameras by 1 to 2 points on the bow while moving toward the concept at the concept camera.
B0 is the AI's reading of the concept, not the concept, so a fit to the painting can move away from it; I have not measured
where B0's bow differs from the painting. It is a reminder that the bow fit is tuned to one view.

## Step 5: two PC bakes, stage 7 and the fire capture

- **First bake (out8, 9 min on the 5080):** the bow deck came out olive again in Blender while its paint was red. Probing the
  baked hull showed a UV fault, not paint: the bevelled deck lip was one smooth `smart_project` island projected edge-on, and
  each thin deck plate's top and underside landed on the same texels, so the undersides (painted as belly) won. armA8 now builds
  the deck lip with square edges and turns inside-out plates outward (12 were); `paint.py` gives downward faces high on the
  ship their region's band, not belly; the deck reds went one step darker for the game camera. paint.jpg, last row, shows both.
- **Second bake (out8b, 8 min, adopted):** bake, renders (studio, concept rig, starboard), close-ups, the LOD chain and bench,
  the stage 7 export with check and self-test, the game import and the battle capture.
  - Export check: PASS. 101,892 triangles; slots scatter P 4, scatter S 4, torp F 8, flak T 2 hard points; 28 hard points in all
    (gun 18, breach 6, engine 3, core 1). Ab7 was 102,072 triangles, 28 hard points.
  - Self-test: PASS (pass passes; no_slot, off_mesh and backward each fail as they must).
  - Game: `check C15s_23 loads=true hardpoints=28 hull_meshes=1`, no import errors; fire capture exit 0 at game, battle and
    close range (VENT_DONE).
  - LOD chain, triangles: Ab8 126,828 / 90,780 / 59,156 / 24,848 (Ab7 127,188 / 91,068 / 59,870 / 25,068).
  - Cost bench, 20 ships, frame median at 1x / 2x: hand LODs Ab8 1.28 / 2.78 ms, Ab7 1.19 / 2.81 ms; auto LOD Ab8 1.16 /
    2.71, Ab7 1.17 / 2.72. Level within run noise.
- **Third bake: not used.** Nothing in out8b is something a bake would cure.

## The sheets

| Sheet | What it shows |
|---|---|
| battle.jpg | Ab7 and Ab8 in the game at the default camera (r 170), 1:1 and 2x, Ab8 firing, then the studio battle camera |
| bow.jpg | concept, Ab7, Ab8 at the concept camera (paint and clay) and from the side; the numbers; outline and inner-edge overlays; the traced deck line; the two fit tries |
| bow_blink.gif | concept and Ab8 at the concept camera, alternating |
| paint.jpg | concept, Ab7, Ab8 whole, then region by region with sampled colours; then in the game with sampled colours; then the first bake beside the second |
| far_side.jpg | starboard quarter, starboard side, top, underside; Ab7 beside Ab8 |
| hull_side.jpg | the bow side close: concept, Ab7, Ab8, and the 4x close-ups |
| weapons.jpg | bow casemates (8 degrees), twin bow guns, drum racks, aft drums: concept, Ab7, Ab8, Ab8 clay |
| overview.jpg | Ab8 paint and clay: concept camera, hero, side, top, below |
| fire.jpg | Ab8 firing its port casemates in the game, game camera then close |
| outline_battle.jpg | the outline against B0 at the game and studio battle cameras |

## What I see, honestly

- **Battle distance:** the front half reads red with orange rust and the back half dark grey, the concept's big read. The pink
  midship is gone. At 1:1 (about 190 px of ship) Ab7 and Ab8 differ mainly in that colour; the shape change is not visible.
- **The front by eye:** closer in paint (the red deck with big blotches is the concept's), slightly closer in shape (the near
  deck edge follows the concept's line now). The nose is still blunter and taller than the painting's long low prow, and the
  twin bow guns sit at the nose where the concept has them further back on the raised hood.
- **The front by number:** bow third +1.2, whole +0.6 (now over the 90 gate), bow edges +3.8 points. Short of 93 and 55.
- **Concept rig close up:** the bow deck is red but much darker than the concept's lit deck (71, 44, 38 against 172, 127, 118);
  the concept's deck catches its key light as a pale rusty red that our rig does not reproduce.

## What is still off

1. Bow shape short of the targets (93 / 55); the method's limits are above. Needs a second concept view to go further.
2. The twin bow guns sit at the nose; the concept puts them on the hood further aft.
3. Bow deck darker than the concept's lit deck under the concept rig (correct hue, wrong value).
4. The game fires from the hull-box mounts, 5.9 world units (a quarter ship length) from the real muzzles (issues 363 and 370,
   not in this round).
5. No wreck or damage glb for the recipe ship (`wreck_chunks=0`).
6. Stern third outline 85.0, the weakest since round 4; untouched.
7. Ab8 sits 1 to 2 points further from B0 at the battle cameras than Ab7 (step 4).

## Effort in agent terms

| Step | PC runs | Notes |
|---|---:|---|
| Steps 1 to 4 (earlier worker) | none | sandbox: two fit tries, the paint layers, the battle camera outline |
| First bake | 1 (out8, 9 min) | showed the UV fault on the bow deck |
| Second bake | 1 (out8b, 8 min) | adopted; everything from bake to fire capture |
| Sheets and report (this worker) | none | sandbox; read the PC output, no new PC job |

## Files

- Sheets and data: this folder (`outline_thirds.json`, `silhouette_scores.json`, `outline_battle.json`, `deck_line.json`,
  `paint_regions.json`, `paint_game.json`, `concept_bow_trace.json`).
- Tools: `tools/blender/r209/fit8.py`, `fit8_bow.json` (try 2), `fit8_bow_try1.json`, `armA8.py`, `outline_battle.py`,
  `deck_line.py`, `sheets8.py`, `preview7.py`; `tools/blender/kits/hullbreakers/paint.py`; `tools/recipe/ships/C15s_23.json`;
  PC jobs `tools/blender/r209/pc/r8_run.bat`, `r8b_run.bat`.
- Sheets usage: `python3 tools/blender/r209/sheets8.py UPLOADS_OPUS209_DIR docs/ship_pipeline/concepts/C15s_23.webp SIL_DIR OUT_DIR TRY_VIEWS.png`.

Refs #209
