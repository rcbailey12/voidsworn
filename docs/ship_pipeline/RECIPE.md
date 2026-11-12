# The ship recipe

Ryan, Nov 9 2026 (FINDINGS R150, R151): turn issue 209 rounds 1 to 5 into a repeatable recipe now, prove it on Ab5 (the C15s
Hullbreaker cruiser), then redo the concepts and run every ship through it. Parts are not one shared kit: every faction has its own
parts kit with its own shape language; only invisible plumbing is shared.

Every stage is one double-click file in `tools\recipe\` on Ryan's PC (it runs from Opus's clone or any clone of the repo). Each
asks for the ship id once (the concept's file name, for example `C15s_23`), writes into
`Downloads\voidsworn_test\recipe\<ship>\`, and ends with a plain PASS, FAIL or "done" line. Nothing is deleted. Heavy steps run on
the 5080; all tools are free and local.

**The method this recipe runs (binding; docs/playbooks/ships.md section 0 has each rule with its source, and section 2c the parts inventory, one detail level, the fit check and the massing check of R217 and R218):** a build sheet
that passes the concept sheet standard comes first (R203); hand-built and kit parts, AI parts only through a reviewed
faction part library (R96 Q5); the AI shape reference of stage 2 is a tracing guide, never shipped; paint from masks baked
from the ship's own geometry plus trim sheets and decals, colours sampled from the concept, the concept never projected
(R96 Q1); breakable by design with insides built through the whole hull (hidden until a piece breaks), rim bands and a dark inner
liner, ships blown apart unevenly by the faction's rule, never sliced (R98, R99 Q1, R186, R215); costs reported, never capped, against the measured scene gate
(R111). Each build writes docs/ship_pipeline/build_sheets/SHIP/manifest.json (part, route, kit id or library entry), and
run_all_checks compares it with the build sheet (R214).

**Must already be on the PC before the first run** (the recipe does not install these): Blender 4.5.14 at
`Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\`, Godot 4.7.2 (the console build) at
`Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe`, and, for stage 2 only, the TRELLIS.2 venv at
`Downloads\trellis2\code\venv\`. Pillow and scipy go into Blender's own python on the first run of any stage (`env.bat`, before
stage 1 writes the concept).

**Every stage stops on its own failure** (Muse's check of round 6, condition 4; R158): each step's output or its own success line in
its log is checked, the stage prints `Stage N FAILED: ...` with the log to read, and exits non-zero. No stage prints "done" after a
failed step. Stage 2 fails when the shape reference is still missing; stages 3 and 5 refuse to start without it; stage 4 fails when
the build is not written, when the audit lists any problem or any part across a break line, or when the audit's self-test lets a
broken build through; stages 3 and 4 report the outline overlap and never stop on it (stage 4 still makes the clay close-ups first, so the
shape can be judged); stage 6 fails when the LOD export or the Godot bench does not finish; stage 7 as below.

| Stage | File | What it does | Output | Time on the PC |
|---|---|---|---|---|
| 1. Concept in | `1_concept_in.bat` | checks `docs\ship_pipeline\concepts\<ship>.webp`, starts `tools\recipe\ships\<ship>.json` from the template (asks the faction), writes the concept with its outline | `concept.png` | seconds |
| 2. AI shape reference | `2_shape_ref.bat` | TRELLIS.2 turns the concept cut-out into one whole-hull mesh: a shape reference and a source of surface grime, never shipped. Every current concept already has one | `bakeoff\<ship>_trellis.glb` | 2 to 4 min |
| 3. Traced hull and the outline overlap | `3_trace_hull.bat` | slices the shape reference and fits clean faceted sections (`b0trace.py`); tunes the hull module's numbers on the concept outline with a pull toward the shape reference (`tune5.py`); scores the outline at the concept's own camera, then the outline per third and the inner edge check (`outline_thirds.py`; `standing.py outline`). The overlap is reported against the ship json `outline_gate` and `outline_third_slack`; it is not a pass bar (RULEBOOK 5.8) | `sil\sil_<cell>.png`, `sil\outline_thirds.json`, the reported overlap | 10 to 25 min (tune) |
| 4. Faction parts kit | `4_parts_kit.bat` | builds the hull with the faction kit's parts at the ship's sockets, audits it (`audit.py`: nothing floats, nothing crosses the build's own break lines, no gun aimed backward or into the ship against its mount normal), proves the audit can fail (`audit_selftest.py`: five broken copies refused, each for its own reason), re-scores the outline overlap and the per-third and inner edge checks with the parts on, scores the outline from the second camera (`outline_battle.py`: the game battle camera at r 170 and the studio battle camera, against the B0 shape reference), renders clay close-ups at the concept camera | `build\<cell>.blend`, `audit.json`, `sil\outline_thirds.json`, `sil\outline_battle.json`, `clay\` | about 5 min |
| 5. Paint bake | `5_paint_bake.bat` | the bake script named by the ship json's `bake` (`bakeAb6.py` for C15s_23; it builds whichever hull module `hull` names, so any ship whose hull module follows `armA5` to `armA7` uses it; a ship with its own bake names it there): the faction paint and the shape reference's grime baked to atlases (hull albedo, ORM, detail normal; parts albedo, ORM), renders at the concept camera (studio and concept light), the fixed views (top and below, the underside still) and the far side (starboard, `side_s`, on request in `render.py`), weapon close-ups, the concept and model blink sheet (`blink.py`), then the standing paint, licence and light checks | `<cell>.blend`, maps, `r\`, `close\`, `bow_blink.gif` | 30 to 40 min |
| 6. LOD | `6_lod.bat` | the hand LOD chain (lod0 to lod3 sharing one set of atlases, small parts drop out by size) and the Godot cost bench (twenty copies, 1080p and 3D at 4K). Costs are reported, never capped (R111) | `glb\<cell>.glb`, `godot\` | about 3 min |
| 7. Game export | `7_export.bat` | runs every standing ship check (`standing.py all`), then writes the game's ship folder from the baked ship and the ship json, with no hand steps: the ship glb with a node per hard point, the 2048 map set and `manifest_entry.json` with the point counts. Then reads the glb back and checks it: FAIL when any required point is missing (a weapon slot, an engine, a hangar mouth, the core, the braking and boarding origins), the breach count for the class and faction is wrong, a hard point is off the mesh, or the manifest entry disagrees. Then proves the check can fail (every broken copy must be refused, each for its own reason). Details below and in `HARDPOINTS.md` | `recipe\<ship>\export\<code>\` | about a minute |

Ryan's review rounds sit after stage 3 (shape), after stage 5 (weapons and paint, the close-up and paint sheets) and after
stage 6 (cost). Opus builds the sheets from the stage outputs (`tools/blender/r209/sheets7pc.py` since round 7: the battle camera
first, then paint region by region, the bow with the outline per third and the inner edge check from `outline_thirds.py`, the far
side, weapons, overview and the firing capture).

## What a ship needs (the per-ship data)

`tools/recipe/ships/<ship>.json` (C15s_23 is the worked example):

- `faction`: picks the kit, `tools/blender/kits/<faction>/` (see `tools/blender/kits/README.md`);
- `hull`: the hull module, a Python file that builds the hull blocks; `tune`: its tuned numbers (written by stage 3);
- `concept_camera`: the camera fitted to the concept (stage 3 fits one when this is empty);
- `outline_gate`: 0.90 and `outline_third_slack`: 5.0, the context the reported outline overlap is printed against (not a pass bar, RULEBOOK 5.8);
- `lights`: the window and trim lights the bake writes, each in pixels across on a 70 px ship (for example
  `{"windows": 2.5, "trim": 2.0}`); empty while the paint has no light map. `light_min_px`: 2.0, the smallest a light may be;
- `game_ship` and `game_code`: the ship's id in `data.js` and the folder name in `godot/assets/ships` (stage 7); `length_world`:
  its class length;
- `parts`: the sockets, one per weapon or marking: `part` (a kit part), `seat` (`flank`: find the hull side at x and z; `top`:
  find the deck at x and y), `pos`, `aim`, `size`, `pair` (adds the exact starboard mirror), `variant` and `variant_s` (each
  twin's own salvage detail), `extra` (the part's own numbers: barrel length, drum count, rack height).

Socket positions and sizes are measured off the concept through the fitted camera: pick the weapon's pixel in the concept, cast it
onto a plane at a plausible height, read x, y and z (round 6 README, section 1, has the C15s numbers and the method). Then the
outline is read by eye: a part that pokes outside the concept's outline at the concept camera costs overlap, so sizes settle
where the weapons read like the concept and the reported overlap is read for what it says (RULEBOOK 5.8); the guns are
never bent to raise it (5.10).

## What the stage 4 audit proves, and what it does not

- **Floating:** every part intersects the hull or another part (BVH overlap: faces that cross), or has a sampled vertex within
  0.002 of the hull. A part resting exactly on another part without crossing its faces is not excused. A part intersecting only
  another part is excused, so a chain of parts can hang off one that meets the hull; the test does not prove that each part sits on its own mount (that is the
  placement rule, checked by eye on the clay close-ups).
- **Break lines:** the build's own (`common.set_break` writes them into the blend as `r209_t_lines` and `r209_l_line`). With none in
  the blend, or with either list empty, the audit fails; it never falls back to an older hull's lines.
- **Guns:** each gun carries its aim and its mount's outward normal (`plumbing.register_gun`, kept by the hull module in
  `r209_guns`). A gun aimed backward (x below -0.05) or into the ship (aim against the mount normal) is a problem; when any gun lacks
  its normal the audit fails (it names the guns), because the into-the-ship test could not run for them (Muse check of PR 341,
  condition 1).

## Stage 7: the game export (issue 209 round 7; FINDINGS R155, R156)

The recipe writes the hard points as a required output, and the effects are built to that contract (outside audit pass 1,
finding 6: today the effects guess gun positions from the hull's box and read only the engine points). The contract itself,
every point type, its axes and the smallest required set per class, is `docs/ship_pipeline/HARDPOINTS.md`; the one count
table is `tools/blender/kits/shared/hardpoints.py` and both the writer and the checker read it.

What the ship json adds for it: `game_ship` (the ship's id in `data.js`; its weapon list is the slot order), `game_code` (the
folder name in `godot/assets/ships`), `length_world`, and on each weapon socket a `slot` (and `slot_s` for the starboard mirror):
the 0-based weapon slot its muzzles fire for. A socket with no slot gets no hard point.

What it writes (`tools/recipe/export7.py`), in the game's frame (+X bow, +Y up, -Z port):

| Output | What |
|---|---|
| `<code>.glb` | one ship node, one mesh with exterior surfaces (`<code>_hull`, `<code>_parts`, `<code>_glow`) plus authored interior surfaces, and an empty child node per hard point. The maps are outside the glb, by relative URI, as the A4 ships have them |
| `hp_w<slot>_<weapon>_<arc>_<n>` | one per weapon muzzle: the barrel tips the kit registers while it builds (`plumbing.register_gun`), so a hard point is always on a real barrel. Node -Z along the barrel, +Y away from the hull. The weapon and arc are read from `data.js`, never typed. Extras: kind, size, arc, arc_deg, slot, weapon, radius, socket |
| `hp_eng_<n>` | one per engine exit (the hull module registers them): -Z out of the bell, `extras.radius` |
| `hp_bay_<n>` | one per hangar mouth the hull module registers (`plumbing.register_bay`): -Z the launch direction, `extras.hangar` |
| `hp_breach_<n>` | the breach anchors for the hull's class and faction (one table, never a constant): spread over prow, mid and eng, sides balanced, each at least 0.03 from every part; +Y the outward normal. Placement follows the faction sheet (for example the Hullbreakers uneven, the Sunward broadside deck line) |
| `hp_core` | the hull's centre of mass |
| `hp_rcs_<n>` | two braking puff origins, one port and one starboard on the forward half: -Z the braking thrust, `extras.side` |
| `hp_board_<n>` | two boarding origins, one port and one starboard on the mid hull: -Z out toward the target, `extras.side` |
| `<code>_base.jpg`, `_orm.jpg`, `_normal.jpg` | the hull atlas at 2048 |
| `<code>_parts_base.jpg`, `<code>_parts_orm.jpg` | the parts atlas at 2048 |
| `manifest_entry.json` | the ship's manifest entry: class, band, length and the point counts (gun, engine, bay, breach, core, rcs, board) |
| `<code>_export.json`, `<code>_check.json` | every hard point, the weapon slots, triangles, every file with size and sha256; the check's result |

The check (`tools/recipe/check_export.py`, plain Python) reads the written glb the way the game will. It fails the export when: a
weapon slot has no hard point, or a weapon hard point names a slot, weapon or arc `data.js` does not have; a required point is
missing (a weapon point for every slot, `hp_core`, `hp_eng`, two `hp_rcs`, two `hp_board`, and `hp_bay` when `data.js` gives the
ship a hangar); the breach count is not the class and faction count, the anchors do not cover the sections the count needs, or the
sides are more than one apart; a hard point is more than 0.012 of the ship's length off the mesh (the length is the x extent of the
glb's mesh box, so the limit scales with the ship; `hp_core` must be inside the hull's box); a weapon rests aimed backward, a port
mount sits to starboard or the other way round, a forward weapon does not point forward, an engine does not point aft; a weapon
point lacks one of the eight extras in the table above or its extras slot, weapon or arc disagree with its name; a breach anchor
is closer than 0.03 (ship frame, `export7.BREACH_CLEAR`) to a part surface, or +Y is not its outward normal; the manifest entry is
missing or its counts disagree; a map the glb names is not in the folder. `check_export_selftest.py` then breaks copies of the real
export (a slot's points removed, a point moved 0.05 of the ship's length off the hull, a gun turned aft, a port point mirrored to
starboard, `hp_core` removed, a weapon's `extras.socket` removed, an engine, rcs and board origin removed, a breach anchor removed,
a breach anchor moved onto a muzzle, a breach anchor turned to face in) and the check must refuse every copy, each for its own
reason. `contract_selftest.py` proves the same check on the round 7 ship (C15s_23) in the sandbox, with its real `data.js` weapon
list and the 5 anchors the cruiser of the Hullbreakers gets from the table. An `unbaked=1` test export names its surfaces
`<code>_hull` and `<code>_parts` too, so the clearance is measured in the sandbox as on a baked ship.

Stage 7 never copies into the game on its own (the build's ship folder is shared). Set `INSTALL_TO` to a Godot project folder to
install a checked export there: what it replaces is copied to `export\replaced_<date>\` first, the old ship's wreck and damage
files are moved there too (they belong to the old hull), and `manifest_entry.json` is merged into
`assets/ships/manifest.json`. Nothing is deleted.

### Authored insides and weak seams (issue 557)

Stage 7 keeps every visible, non-proxy `role=interior` object and applies the hull's `skin` solidify modifier. It never
replaces an authored room with a flat cap. A build without interior geometry or authored seams fails export and readback.
The original materials, including interior paint, are retained; the inner skin gets a separate dark material. Interior
surfaces share the ship mesh and stay behind its opaque exterior until damage or separation exposes them. They still cost
triangles, surfaces, memory and renderer work: occlusion is not a promise of zero frame cost. Measure the #207 scene.

**The version 1 format** is the ship node's GLB `extras.voidsworn_destruct` dictionary. It contains `version: 1`,
`interior_materials: [material name, ...]`, and `seams: [{p: [x,y,z], n: [x,y,z]}, ...]`, all in the GLB ship frame.
Transverse seams have normal `[1,0,0]`. The optional longitudinal seam has normal `[0,1,0]` and `span: [x0,x1]`, identifying
the transverse compartment it weakens. Positions are points, normals are unit vectors. The writer converts Blender Z up
to glTF Y up once. Its inputs are the build's scene `r209_t_lines` and `r209_l_line`; no default joints are supplied.
`interior_materials` names actual nonempty surfaces, including `<code>_inside_skin` for the retained inner liner.
The reader `fx_hull.gd` transforms seams into the hull analysis frame, accounting for ship scale, and recognises those
materials before the damage and fracture fallback. A GLB extra was chosen so installing the ship also installs its seams
and insides, without a sidecar that can go missing or old fixed chunks that would replace the current explosion.

`fx_death.gd` uses those seams as weak joints, with waves, kink, missing bite, chips, scorch and faction matter retained.
The number of main pieces follows the supplied structure; legacy ships without the extra keep the #167 fallback.
Authored rooms keep their geometry through wounds and death; `fx_breach.gd` removes the shell at the wound and keeps its
torn edge, without laying its generic cavity floor and frames over the authored room. Old hulls still get those floors.
An inner liner by itself fails readback: the export must also contain real room surfaces. The optional
`authored_interiors_check.gd -- --legacy-cache` PC check verifies every installed older asset keeps the legacy reader
and its original outside triangles.

Prove the written asset with `fx/test/authored_interiors_check.gd -- EXPORT/CODE.glb` in headless Godot, and compare the
same installed ship at camera 170 and 60 with `fx/test/authored_interiors_probe.gd -- AUTHORED LEGACY MOVED SHOTS` on the GPU.
`tools/recipe/interiors_export_probe.py` repeats the three exports from one baked blend (`variant=authored`, `legacy`,
`moved`); `moved` shifts the first transverse joint by 0.10 ship units in Blender before export. Optional `fixture=1` adds
six clearly named machinery marker boxes between Ab8's decks for the pipeline test, identically before each export;
these are test geometry, not production ship art. The legacy comparison
pins the exporter at commit `902388eb2fa3582bd26531be3e3ec38d8d01dfd0` (optional `baseline=REV` override). The capture probe
saves an installed scene and loads it through ShipView, then calls the production damage and death paths. Keep the raw
stills and record triangles, surfaces/draw calls and the #207 frame median and 4K GPU cost beside them. The only cost gate
is RULEBOOK 3.9. `check_export_selftest.py` proves that removing interior primitives or seams from a valid export fails.

**Not written yet (exactly what is left of the A4 set):**

1. `<code>_wreck.glb`: no fixed chunk file is needed for new recipe ships. The runtime fractures their exported shell and
   authored interiors near their exported weak seams, with the current irregular explosion. Older ship assets still load.
2. `<code>_damage.glb` and the `skin_<n>` hull patches in the ship glb: the breach holes and per-weapon damage. The `hp_breach`
   anchors (one per section and side, the class and faction count) are already there for it.
3. `<code>_emissive.jpg`: the glow (engine throats, muzzles, lamps) is its own surface with an emissive factor, not a map.
4. One surface: the A4 ships have one mesh surface and one map set; a recipe ship has two atlases (hull, parts), so three surfaces.
   Merging them into one atlas is a bake-stage change (stage 5), not an export change.
5. `ships.json` rows in `godot/assets/ships` (the manifest entry is written by stage 7), and the R116 scene gate with the ship in
   a real battle.
6. The effects reading the points (the attach point service of audit finding 6): today the game still fires from its guessed side
   mounts and its box corners, so gun smoke does not start at the barrels, wings launch from the box centre, braking puffs sit on
   box corners and boarding picks its own point. The contract `HARDPOINTS.md` states the reader rules; that service is its own job.

## Standing checks every ship keeps (issue 363)

These are not one-off sheets. Every stage writes them into the job folder and stage 7 refuses to export a ship without them
(`tools/recipe/standing.py all`):

| Check | Where it runs | What it proves |
|---|---|---|
| outline per third, inner edge | stages 3 and 4 (`outline_thirds.py`) | the outline overlap for bow, midship and stern separately, reported against the gate and `outline_third_slack` (not a pass bar, RULEBOOK 5.8), and every third has the inner edge distances (median px and share within 6 px), so a wrong third cannot hide in the whole-ship average |
| outline from the second camera | stage 4 (`outline_battle.py`) | the same overlap per third at the game's battle camera (r 170) and the studio battle camera, against the B0 shape reference; this is the angle the player uses, not the concept camera |
| blink sheet | stage 5 (`blink.py`) | `bow_blink.gif`: the concept and the model at the fitted concept camera, alternating, so the bow can be flipped in front of Ryan |
| paint sides | stage 5 (`render.py`: concept, `below`, `side_s`) | the concept side, the underside and the far (starboard) side stills all exist; paint is judged on all three, not only the side the concept shows |
| texture licences | stage 5 (`standing.py licences`) | every downloaded texture under the job's `textures/` has its own line in `licences.json`: file, source, licence (CC0, CC-BY, CC-BY-SA, public domain or own work) and what it is used for |
| light sizes | stages 5 and 7 (`standing.py lights`) | every window and trim light declared in the ship json's `lights` is at least `light_min_px` (2.0) pixels across on a 70 px ship at the battle camera; an empty `lights` block passes because the present paint has no light map |

Round 7 delivered the first four as one-off scripts and sheets (`outline_thirds.py`, `sheets7pc.py`'s `bow_blink.gif` and
`far_side.jpg`); round 8 added the second camera (`outline_battle.py`). This job makes all of them standing stages and adds
the licence and light size checks. A ship's job folder therefore always holds `sil/outline_thirds.json`,
`sil/outline_battle.json`, `bow_blink.gif`, the paint side stills and `licences.json` (when textures are used).

The two new checks need the painter to record what it did. A bake that downloads a texture puts a copy (or a same-named
placeholder) in the job's `textures/` folder and writes `licences.json` with one entry per file: `file`, `source` (a URL or
"own work"), `licence` (CC0, CC-BY, CC-BY-SA, public domain or own work) and `used` (what the texture is for). A bake that
writes window or trim lights puts their size in pixels across on a 70 px ship into the ship json's `lights` block, for
example `{"windows": 2.5, "trim": 2.0}`. Empty `lights` means the paint has no such lights yet, not that the rule is waived.

## What is generic now and what is not yet

| Generic (any concept, any faction) | Per ship today | Next |
|---|---|---|
| stages 1, 2, 5, 6, 7; the outline overlap report and the standing checks (per third, inner edge, second camera, paint sides, blink sheet, licences, light sizes); the fitted concept camera; the shared plumbing (sockets, seating, scale rules, audit, tags, the muzzle, engine and bay registry); the hard point contract and its one count table (`kits/shared/hardpoints.py`); bake, LOD chain, cost bench; the game export, its hard points and its check | the hull module's block table (C15s: raised forward deck, deckhouse and tower tiers, hump, aft body, stern block, sponsons, modules, cargo blocks; `armA5.py`); the sockets in the ship json | a block table as data in the ship json, so a new hull needs no Python; the wreck and damage glbs and the scene gate (stage 7, list above) |
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
- The outline overlap after round 7 reads 89.7 percent (scored from the PC glb; the game export 89.6), under the 90 point it
  was once scored against: the bow pass cost 0.3 against Ab6's 90.0. Per third (`outline_thirds.py`, audit pass 2 finding 13):
  bow 90.3 (Ab6 91.0), midship 90.7, stern 85.1. The old gate exited on that low whole number; it is now reported, and R156 puts
  the bow's look ahead of the score.
- Round 8 (`docs/shots/ship_pipeline/route209/round8/README.md`): hull module `armA8` (the bow third fitted by
  `tools/blender/r209/fit8.py` to the concept outline and its traced near deck edge, numbers in `fit8_bow.json`). Outline after
  round 8: bow third 91.5, midship 90.6, stern 85.0 (the per-third floor at gate 90 and slack 5 is 85.0), whole 90.3 (over the
  90 gate), bow inner edges within 6 px 46.4 percent. Second camera (`outline_battle.json`): game camera bow 85.2, midship 90.9,
  stern 85.8, whole 87.7; studio camera bow 74.6, midship 90.7, stern 89.2, whole 86.0 (against B0, not the concept).
- The round 7 game export has 28 hard points: 18 gun muzzles (its 4 weapon slots), 3 engines, 6 breach anchors and 1 core. Under
  the contract the ship gets 5 breach anchors (Cruiser, 4 from the class table, +1 for the Hullbreakers) plus 2 braking origins and
  2 boarding origins, so a PC re-export (stage 7) is needed before this ship matches the contract; this job did not run one.
- Stage 5 lesson (round 8): thin plates and edge-on bevels can bake from the wrong side. A bevelled deck lip that `smart_project`
  unwraps as one island seen edge-on, or a thin plate whose top and underside share texels, takes the underside's paint (the
  belly) on the top. Build deck lips with square edges, turn inside-out plates outward, and give downward faces high on the ship
  their region's band in `paint.py`. Check the bow deck in the concept-rig render after every bake.
- Stage 5 paint check: `tools/blender/r209/preview7.py ... light=game` renders under the game's key, fill and ambient, so a colour
  that goes pink or salmon in the game shows up in the sandbox before a PC bake. Confirm in the game capture.
- `shape_ref_yaw` 22.0 is the C15s_23 value (its shape reference turned into the ship frame); a new ship measures its own.
