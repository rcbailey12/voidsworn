# The ship recipe

Ryan, Nov 9 2026 (FINDINGS R150, R151): turn issue 209 rounds 1 to 5 into a repeatable recipe now, prove it on Ab5 (the C15s
Hullbreaker cruiser), then redo the concepts and run every ship through it. Parts are not one shared kit: every faction has its own
parts kit with its own shape language; only invisible plumbing is shared.

Every stage is one double-click file in `tools\recipe\` on Ryan's PC (it runs from Opus's clone or any clone of the repo). Each
asks for the ship id once (the concept's file name, for example `C15s_23`), writes into
`Downloads\voidsworn_test\recipe\<ship>\`, and ends with a plain PASS, FAIL or "done" line. Nothing is deleted. Heavy steps run on
the 5080; all tools are free and local.

| Stage | File | What it does | Output | Time on the PC |
|---|---|---|---|---|
| 1. Concept in | `1_concept_in.bat` | checks `docs\ship_pipeline\concepts\<ship>.webp`, starts `tools\recipe\ships\<ship>.json` from the template (asks the faction), writes the concept with its outline | `concept.png` | seconds |
| 2. AI shape reference | `2_shape_ref.bat` | TRELLIS.2 turns the concept cut-out into one whole-hull mesh: a shape reference and a source of surface grime, never shipped. Every current concept already has one | `bakeoff\<ship>_trellis.glb` | 2 to 4 min |
| 3. Traced hull and the outline gate | `3_trace_hull.bat` | slices the shape reference and fits clean faceted sections (`b0trace.py`); tunes the hull module's numbers on the concept outline with a pull toward the shape reference (`tune5.py`); scores the outline at the concept's own camera. Gate: 90 percent overlap | `sil\sil_<cell>.png`, PASS or FAIL | 10 to 25 min (tune) |
| 4. Faction parts kit | `4_parts_kit.bat` | builds the hull with the faction kit's parts at the ship's sockets, audits it (nothing floats, nothing crosses a break line, no gun aimed backward or into the ship), re-scores the gate with the parts on, renders clay close-ups at the concept camera | `build\<cell>.blend`, `audit.json`, `clay\` | about 5 min |
| 5. Paint bake | `5_paint_bake.bat` | the faction paint and the shape reference's grime baked to atlases (hull albedo, ORM, detail normal; parts albedo, ORM), renders at the concept camera (studio and concept light) and the fixed views, weapon close-ups | `<cell>.blend`, maps, `r\`, `close\` | 30 to 40 min |
| 6. LOD | `6_lod.bat` | the hand LOD chain (lod0 to lod3 sharing one set of atlases, small parts drop out by size) and the Godot cost bench (twenty copies, 1080p and 3D at 4K). Costs are reported, never capped (R111) | `glb\<cell>.glb`, `godot\` | about 3 min |
| 7. Export | `7_export.bat` | copies the LOD glb for the game import. Not automated yet: the game's A4 ship format (hard points, wreck and damage glbs, the 2048 map set) and the R116 scene gate, a board job of its own | `recipe\export\<ship>\` | seconds |

Ryan's review rounds sit after stage 3 (shape), after stage 5 (weapons and paint, the close-up and paint sheets) and after
stage 6 (cost). Opus builds the sheets from the stage outputs (`tools/blender/r209/sheets6.py`).

## What a ship needs (the per-ship data)

`tools/recipe/ships/<ship>.json` (C15s_23 is the worked example):

- `faction`: picks the kit, `tools/blender/kits/<faction>/` (see `tools/blender/kits/README.md`);
- `hull`: the hull module, a Python file that builds the hull blocks; `tune`: its tuned numbers (written by stage 3);
- `concept_camera`: the camera fitted to the concept (stage 3 fits one when this is empty);
- `outline_gate`: 0.90;
- `parts`: the sockets, one per weapon or marking: `part` (a kit part), `seat` (`flank`: find the hull side at x and z; `top`:
  find the deck at x and y), `pos`, `aim`, `size`, `pair` (adds the exact starboard mirror), `variant` and `variant_s` (each
  twin's own salvage detail), `extra` (the part's own numbers: barrel length, drum count, rack height).

Socket positions and sizes are measured off the concept through the fitted camera: pick the weapon's pixel in the concept, cast it
onto a plane at a plausible height, read x, y and z (round 6 README, section 1, has the C15s numbers and the method). Then the
gate decides: a part that pokes outside the concept's outline at the concept camera costs overlap, so sizes settle where the
weapons read like the concept and the outline stays at 90 percent or better.

## What is generic now and what is not yet

| Generic (any concept, any faction) | Per ship today | Next |
|---|---|---|
| stages 1, 2, 5, 6, 7; the outline gate; the fitted concept camera; the shared plumbing (sockets, seating, scale rules, audit, tags); bake, LOD chain, cost bench | the hull module's block table (C15s: raised forward deck, deckhouse and tower tiers, hump, aft body, stern block, sponsons, modules, cargo blocks; `armA5.py`); the sockets in the ship json | a block table as data in the ship json, so a new hull needs no Python; the A4 game-format export and the scene gate in stage 7 |
| the Hullbreaker kit and paint (`kits/hullbreakers/`) | | a kit per faction: Sunward Crusade, Glasswrights, Eclipse, Chorus, Hegemony Navy, each with its own shape language and paint |

The section fits in stage 3 (`b0trace.py`) are generic; turning them into the hull module's knot table was a hand step in round 5
(smoothed and squared up), and the block table is a design step: which blocks the concept has. That is the one creative step left
in the recipe, and the next change makes it data.

## The worked example: C15s_23, Ab6 (issue 209 round 6)

- Ship file: `tools/recipe/ships/C15s_23.json`; hull module `armA6` (round 5's traced hull, `armA5.py`, plus the kit); tune
  `tools/blender/r209/tune5_P.json`; concept camera `docs/shots/ship_pipeline/route209/round4/concept_camera.json`.
- Kit: `tools/blender/kits/hullbreakers/kit.py` and `paint.py`.
- Report and sheets: `docs/shots/ship_pipeline/route209/round6/README.md`.
