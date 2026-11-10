# The ship recipe

Ryan, Nov 9 2026 (FINDINGS R150, R151): turn issue 209 rounds 1 to 5 into a repeatable recipe now, prove it on Ab5 (the C15s
Hullbreaker cruiser), then redo the concepts and run every ship through it. Parts are not one shared kit: every faction has its own
parts kit with its own shape language; only invisible plumbing is shared.

Every stage is one double-click file in `tools\recipe\` on Ryan's PC (it runs from Opus's clone or any clone of the repo). Each
asks for the ship id once (the concept's file name, for example `C15s_23`), writes into
`Downloads\voidsworn_test\recipe\<ship>\`, and ends with a plain PASS, FAIL or "done" line. Nothing is deleted. Heavy steps run on
the 5080; all tools are free and local.

**Must already be on the PC before the first run** (the recipe does not install these): Blender 4.5.14 at
`Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\`, Godot 4.7.2 (the console build) at
`Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe`, and, for stage 2 only, the TRELLIS.2 venv at
`Downloads\trellis2\code\venv\`. Pillow and scipy go into Blender's own python on the first run of any stage (`env.bat`, before
stage 1 writes the concept).

**Every stage stops on its own failure** (Muse's check of round 6, condition 4; R158): each step's output or its own success line in
its log is checked, the stage prints `Stage N FAILED: ...` with the log to read, and exits non-zero. No stage prints "done" after a
failed step. Stage 2 fails when the shape reference is still missing; stages 3 and 5 refuse to start without it; stage 4 fails when
the build is not written, when the audit lists any problem or any part across a break line, or when the audit's self-test lets a
broken build through; stages 3 and 4 exit non-zero when the outline gate fails (stage 4 still makes the clay close-ups first, so the
shape can be judged); stage 6 fails when the LOD export or the Godot bench does not finish; stage 7 as below.

| Stage | File | What it does | Output | Time on the PC |
|---|---|---|---|---|
| 1. Concept in | `1_concept_in.bat` | checks `docs\ship_pipeline\concepts\<ship>.webp`, starts `tools\recipe\ships\<ship>.json` from the template (asks the faction), writes the concept with its outline | `concept.png` | seconds |
| 2. AI shape reference | `2_shape_ref.bat` | TRELLIS.2 turns the concept cut-out into one whole-hull mesh: a shape reference and a source of surface grime, never shipped. Every current concept already has one | `bakeoff\<ship>_trellis.glb` | 2 to 4 min |
| 3. Traced hull and the outline gate | `3_trace_hull.bat` | slices the shape reference and fits clean faceted sections (`b0trace.py`); tunes the hull module's numbers on the concept outline with a pull toward the shape reference (`tune5.py`); scores the outline at the concept's own camera. Gate: 90 percent overlap | `sil\sil_<cell>.png`, PASS or FAIL | 10 to 25 min (tune) |
| 4. Faction parts kit | `4_parts_kit.bat` | builds the hull with the faction kit's parts at the ship's sockets, audits it (`audit.py`: nothing floats, nothing crosses the build's own break lines, no gun aimed backward or into the ship against its mount normal), proves the audit can fail (`audit_selftest.py`: three broken copies refused), re-scores the gate with the parts on, renders clay close-ups at the concept camera | `build\<cell>.blend`, `audit.json`, `clay\` | about 5 min |
| 5. Paint bake | `5_paint_bake.bat` | the bake script named by the ship json's `bake` (`bakeAb6.py` for C15s_23; it builds whichever hull module `hull` names, so any ship whose hull module follows `armA5` to `armA7` uses it; a ship with its own bake names it there): the faction paint and the shape reference's grime baked to atlases (hull albedo, ORM, detail normal; parts albedo, ORM), renders at the concept camera (studio and concept light) and the fixed views, weapon close-ups | `<cell>.blend`, maps, `r\`, `close\` | 30 to 40 min |
| 6. LOD | `6_lod.bat` | the hand LOD chain (lod0 to lod3 sharing one set of atlases, small parts drop out by size) and the Godot cost bench (twenty copies, 1080p and 3D at 4K). Costs are reported, never capped (R111) | `glb\<cell>.glb`, `godot\` | about 3 min |
| 7. Game export | `7_export.bat` | writes the game's ship folder from the baked ship and the ship json, with no hand steps: the ship glb with a node per hard point, and the 2048 map set. Then reads the glb back and checks it: FAIL when a weapon slot of the ship's `data.js` weapon list has no hard point, or a hard point is off the mesh. Then proves the check can fail (three broken copies must be refused). Details below | `recipe\<ship>\export\<code>\` | about a minute |

Ryan's review rounds sit after stage 3 (shape), after stage 5 (weapons and paint, the close-up and paint sheets) and after
stage 6 (cost). Opus builds the sheets from the stage outputs (`tools/blender/r209/sheets7pc.py` since round 7: the battle camera
first, then paint region by region, the bow with the outline per third and the inner edge check from `outline_thirds.py`, the far
side, weapons, overview and the firing capture).

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

## What the stage 4 audit proves, and what it does not

- **Floating:** every part touches the hull or touches another part. A part resting only on another part is excused, so a chain of
  parts can hang off one that touches the hull; the test does not prove that each part sits on its own mount (that is the
  placement rule, checked by eye on the clay close-ups).
- **Break lines:** the build's own (`common.set_break` writes them into the blend as `r209_t_lines` and `r209_l_line`). With none in
  the blend the audit fails; it never falls back to an older hull's lines.
- **Guns:** each gun carries its aim and its mount's outward normal (`plumbing.register_gun`, kept by the hull module in
  `r209_guns`). A gun aimed backward (x below -0.05) or into the ship (aim against the mount normal) is a problem; with no normals at
  all the audit fails, because the into-the-ship test could not run.

## Stage 7: the game export (issue 209 round 7; FINDINGS R155, R156)

The recipe writes the hard points as a required output, and the effects are built to that contract (outside audit pass 1,
finding 6: today the effects guess gun positions from the hull's box and read only the engine points).

What the ship json adds for it: `game_ship` (the ship's id in `data.js`; its weapon list is the slot order), `game_code` (the
folder name in `godot/assets/ships`), `length_world`, and on each weapon socket a `slot` (and `slot_s` for the starboard mirror):
the 0-based weapon slot its muzzles fire for. A socket with no slot gets no hard point.

What it writes (`tools/recipe/export7.py`), in the game's frame (+X bow, +Y up, -Z port):

| Output | What |
|---|---|
| `<code>.glb` | one ship node, one mesh with three surfaces (`<code>_hull`, `<code>_parts`, `<code>_glow`), and an empty child node per hard point. The maps are outside the glb, by relative URI, as the A4 ships have them |
| `hp_w<slot>_<weapon>_<arc>_<n>` | one per weapon muzzle: the barrel tips and launch mouths the kit registers while it builds (`plumbing.register_gun`), so a hard point is always on a real barrel. Node -Z along the barrel, +Y away from the hull. The weapon and arc are read from `data.js`, never typed. Extras: kind, size, arc, arc_deg, slot, weapon, radius, socket |
| `hp_eng_<n>` | one per engine exit (the hull module registers them): -Z out of the bell, `extras.radius` |
| `hp_breach_<n>` | six breach anchors on open hull, two per section (prow, mid, eng), each at least 0.03 from every part; +Y is the outward normal |
| `hp_core` | the hull's centre of mass |
| `<code>_base.jpg`, `_orm.jpg`, `_normal.jpg` | the hull atlas at 2048 |
| `<code>_parts_base.jpg`, `_parts_orm.jpg` | the parts atlas at 2048 |
| `<code>_export.json`, `<code>_check.json` | every hard point, the weapon slots, triangles, every file with size and sha256; the check's result |

The check (`tools/recipe/check_export.py`, plain Python) reads the written glb the way the game will. It fails the export when: a
weapon slot has no hard point, or a weapon hard point names a slot, weapon or arc `data.js` does not have; a hard point is more
than 0.012 of the ship's length off the mesh (`hp_core` must be inside the hull's box); a weapon rests aimed backward, a port
mount sits to starboard or the other way round, a forward weapon does not point forward, an engine does not point aft; `hp_eng`,
`hp_breach` or `hp_core` is missing; a map the glb names is not in the folder. `check_export_selftest.py` then breaks three
copies of the real export (a slot's points removed, a point moved off the hull, a gun turned aft) and the check must refuse all
three.

Stage 7 never copies into the game on its own (the build's ship folder is shared). Set `INSTALL_TO` to a Godot project folder to
install a checked export there: what it replaces is copied to `export\replaced_<date>\` first, and the old ship's wreck and damage
files are moved there too, because they belong to the old hull. Nothing is deleted.

**Not written yet (exactly what is left of the A4 set):**

1. `<code>_wreck.glb`: the death pieces (the hull cut along its authored break lines into chunks with cut faces).
2. `<code>_damage.glb` and the `skin_<n>` hull patches in the ship glb: the breach holes and per-weapon damage. The six
   `hp_breach` anchors are already there for it.
3. `<code>_emissive.jpg`: the glow (engine throats, muzzles, lamps) is its own surface with an emissive factor, not a map.
4. One surface: the A4 ships have one mesh surface and one map set; a recipe ship has two atlases (hull, parts), so three surfaces.
   Merging them into one atlas is a bake-stage change (stage 5), not an export change.
5. `manifest.json` and `ships.json` rows in `godot/assets/ships`, and the R116 scene gate with the ship in a real battle.
6. The effects reading `hp_w` (the attach point service of audit finding 6): today the game still fires from its guessed side
   mounts, so gun smoke does not start at the barrels yet.

## What is generic now and what is not yet

| Generic (any concept, any faction) | Per ship today | Next |
|---|---|---|
| stages 1, 2, 5, 6, 7; the outline gate; the fitted concept camera; the shared plumbing (sockets, seating, scale rules, audit, tags, the muzzle and engine registry); bake, LOD chain, cost bench; the game export, its hard points and its check | the hull module's block table (C15s: raised forward deck, deckhouse and tower tiers, hump, aft body, stern block, sponsons, modules, cargo blocks; `armA5.py`); the sockets in the ship json | a block table as data in the ship json, so a new hull needs no Python; the wreck and damage glbs and the scene gate (stage 7, list above) |
| the Hullbreaker kit and paint (`kits/hullbreakers/`) | | a kit per faction: Sunward Crusade, Glasswrights, Eclipse, Chorus, Hegemony Navy, each with its own shape language and paint |

The section fits in stage 3 (`b0trace.py`) are generic; turning them into the hull module's knot table was a hand step in round 5
(smoothed and squared up), and the block table is a design step: which blocks the concept has. That is the one creative step left
in the recipe, and the next change makes it data.

## The worked example: C15s_23, Ab8 (issue 209 rounds 6 to 8)

- Ship file: `tools/recipe/ships/C15s_23.json`; hull module `armA7` (round 5's traced hull with round 7's bow pass, plus the
  kit; `armA6` is the same ship before the bow pass); tune `tools/blender/r209/tune5_P.json`; concept camera
  `docs/shots/ship_pipeline/route209/round4/concept_camera.json`; game ship `c_marauder`, game code `C15s_23`.
- Kit: `tools/blender/kits/hullbreakers/kit.py` and `paint.py`.
- Reports and sheets: `docs/shots/ship_pipeline/route209/round6/README.md`, `docs/shots/ship_pipeline/route209/round7/README.md`.
- The outline gate after round 7 reads 89.7 percent (scored from the PC glb; the game export 89.6), under the 90 gate: the bow
  pass cost 0.3 against Ab6's 90.0. Per third (`outline_thirds.py`, audit pass 2 finding 13): bow 90.3 (Ab6 91.0), midship 90.7,
  stern 85.1. Stage 4 exits on the gate FAIL; that is the honest reading, and R156 puts the bow's look ahead of the score.
- Round 8 (`docs/shots/ship_pipeline/route209/round8/README.md`): hull module `armA8` (the bow third fitted by
  `tools/blender/r209/fit8.py` to the concept outline and its traced near deck edge, numbers in `fit8_bow.json`). Outline after
  round 8: bow third 91.5, whole 90.3 (over the 90 gate), bow inner edges within 6 px 46.4 percent. Stage 7 PASS, 101,892
  triangles, 28 hard points.
- Stage 5 lesson (round 8): thin plates and edge-on bevels can bake from the wrong side. A bevelled deck lip that `smart_project`
  unwraps as one island seen edge-on, or a thin plate whose top and underside share texels, takes the underside's paint (the
  belly) on the top. Build deck lips with square edges, turn inside-out plates outward, and give downward faces high on the ship
  their region's band in `paint.py`. Check the bow deck in the concept-rig render after every bake.
- Stage 5 paint check: `tools/blender/r209/preview7.py ... light=game` renders under the game's key, fill and ambient, so a colour
  that goes pink or salmon in the game shows up in the sandbox before a PC bake. Confirm in the game capture.
- `shape_ref_yaw` 22.0 is the C15s_23 value (its shape reference turned into the ship frame); a new ship measures its own.
