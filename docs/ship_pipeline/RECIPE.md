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
shape can be judged); stage 6 fails when the LOD export or the Godot bench does not finish; stage 7 as below. Set
`RECIPE_NOPAUSE=1` to run any stage from a queue job without the key press at the end.

**env.bat reads the ship file with `for /f` lines whose whole command is wrapped in one more pair of quotes** (issue 587
finding 1, issue 592): cmd strips the first and last quote of a quoted command, so without the extra pair the python path and
the script path broke apart and HULL, CELL and CODE came back empty on the PC. Every launcher that reads the ship file this way
(env.bat and stages 3, 4 and 5) keeps the extra quotes.

| Stage | File | What it does | Output | Time on the PC |
|---|---|---|---|---|
| 1. Concept in | `1_concept_in.bat` | reads the concept the ship json names (`concept`; a new ship without a json: `docs\ship_pipeline\concepts\<ship>.webp`, then starts the json from the template and asks the faction), writes it square with its outline as alpha (`ship.py concept`: its own alpha, else the build sheets' rule: luminance over 28, closed, holes filled, the largest shape) | `concept.png` | seconds |
| 2. AI shape reference | `2_shape_ref.bat` | TRELLIS.2 turns the concept into one whole-hull mesh: a shape reference and a source of surface grime, never shipped. Its input is the concept squared with no cut-out of ours when the concept has no alpha (`ship.py concept ... raw`): TRELLIS.2 removes the background itself, where the luminance rule loses a dark belly. A new concept (every redone concept, A16 first) needs this run | `bakeoff\<ship>_trellis.glb` | 2 to 4 min |
| 3. Traced hull and the outline overlap | `3_trace_hull.bat` | slices the shape reference and fits clean faceted sections (`b0trace.py`); tunes the hull module's numbers on the concept outline with a pull toward the shape reference (`tune5.py`); scores the outline at the concept's own camera, then the outline per third and the inner edge check (`outline_thirds.py`; `standing.py outline`). The overlap is reported against the ship json `outline_gate` and `outline_third_slack`; it is not a pass bar (RULEBOOK 5.8). A ship built from a build sheet is not traced or tuned (below) | `sil\sil_<cell>.png`, `sil\outline_thirds.json`, the reported overlap | 10 to 25 min (tune) |
| 4. Faction parts kit | `4_parts_kit.bat` | builds the hull with the faction kit's parts at the ship's sockets, audits it (`audit.py`: nothing floats, nothing crosses the build's own break lines, no gun aimed backward or into the ship against its mount normal), proves the audit can fail (`audit_selftest.py`: six broken copies refused, each for its own reason, a build with no longitudinal seam not refused for that alone, and on a build that marks part kinds a machine moved onto a seam refused and a structure part not); for a ship built from a build sheet it first proves the build contract (`sheet_contract_selftest.py`, below), re-scores the outline overlap and the per-third and inner edge checks with the parts on, scores the outline from the second camera (`outline_battle.py`: the game battle camera at r 170 and the studio battle camera, against the B0 shape reference), renders clay close-ups at the concept camera | `build\<cell>.blend`, `audit.json`, `sil\outline_thirds.json`, `sil\outline_battle.json`, `clay\` | about 5 min |
| 5. Paint bake | `5_paint_bake.bat` | `"bake": "stack"` (a ship built from a build sheet, A16 the first; issue 601): the faction kit's paint stack, `bake_sheet.py` (below, "The paint stack for sheet ships"); a faction whose kit has no stack yet goes the `"none"` way and the stage says so. `"bake": "none"`: nothing is baked, stage 4's build goes on unpainted and stage 7 writes an unbaked test export. Otherwise the bake script named by the ship json's `bake` (`bakeAb6.py` for C15s_23; it builds whichever hull module `hull` names, so any ship whose hull module follows `armA5` to `armA7` uses it; a ship with its own bake names it there): the faction paint and the shape reference's grime baked to atlases (hull albedo, ORM, detail normal; parts albedo, ORM), renders at the concept camera (studio and concept light), the fixed views (top and below, the underside still) and the far side (starboard, `side_s`, on request in `render.py`), weapon close-ups, the concept and model blink sheet (`blink.py`), then the standing paint, licence and light checks | `<cell>.blend`, maps, `r\`, `close\`, `bow_blink.gif` | 30 to 40 min |
| 6. LOD | `6_lod.bat` | an analysis product (issue 592): the hand LOD chain (lod0 to lod3 sharing one set of atlases, small parts drop out by size; the reduced levels are cleaned of the zero-area faces the decimate leaves, so they import whole) and the Godot cost bench (twenty copies, 1080p and 3D at 4K) at the ship's own class length (`length=` from the ship json, or its build sheet). The game ships stage 7's export and loads no LOD chain; lod0 is that same geometry, so the bench's lod0 numbers are the shipped mesh's in the studio scene. The binding cost is the #207 scene gate on the installed ship (RULEBOOK 3.9). Costs are reported, never capped (R111) | `glb\<cell>.glb`, `godot\` | about 3 min |
| 7. Game export | `7_export.bat` | runs every standing ship check (`standing.py all`), then writes the game's ship folder from the baked ship and the ship json, with no hand steps: the ship glb with a node per hard point, the 2048 map set and `manifest_entry.json` with the point counts. Then reads the glb back and checks it: FAIL when any required point is missing (a weapon slot, an engine, a hangar mouth, the core, the braking and boarding origins), the breach count for the class and faction is wrong, a hard point is off the mesh, or the manifest entry disagrees. Then proves the check can fail (every broken copy must be refused, each for its own reason). Details below and in `HARDPOINTS.md` | `recipe\<ship>\export\<code>\` | about a minute |

Ryan's review rounds sit after stage 3 (shape), after stage 5 (weapons and paint, the close-up and paint sheets) and after
stage 6 (cost). Opus builds the sheets from the stage outputs (`tools/blender/r209/sheets7pc.py` since round 7: the battle camera
first, then paint region by region, the bow with the outline per third and the inner edge check from `outline_thirds.py`, the far
side, weapons, overview and the firing capture).

## Ships built from a build sheet (issue 592; RULEBOOK 0.9, R225)

An approved build sheet (ships.md step D) is the ship's design: its masses, part builders, mounts, seams, insides, hard points
and class length are decided there once, and the recipe reads them; it never keeps a second copy. The ship json names the sheet
(`"sheet": "corsair_A16"`, the design file `tools/blender/build_sheets/ships/<sheet>.py`) and the hull module `sheet_hull`
(`tools/blender/r209/sheet_hull.py`), and carries only the game ids, the concept and the recipe settings: no parts list, no
`length_world`, no tune. Worked example: `tools/recipe/ships/corsair_A16.json`.

How the sheet feeds stages 2 and 3 without losing its design: stage 2 makes the shape reference from the same accepted concept
the sheet was designed from (the json's `concept`); it is the grime source for a later paint bake and the reference of the
second-camera outline score, never a hull to trace. Stage 3 does not trace or tune: the sheet is the hull. It still reads the
shape reference, fits the concept camera when the json has none (the sheet's own beauty camera is in another format), builds the
sheet hull and reports its outline overlap, so stages 4 and 5 find the same records as for any ship. Every stage that builds
(stage 3's outline dump, stage 4) builds through `sheet_hull`, so they all see the same ship.

The build contract (`tools/blender/build_sheets/contract.py`) turns the built sheet scene, in place, into the scene the recipe
reads, one authority per datum:

| Datum | The sheet writes it | The recipe reads it |
|---|---|---|
| units | world units, the design origin | length one: every mesh scaled by one over the model's length (the outside's x extent), same origin |
| class length | the design file's `LENGTH` | scene `r209_length_world` (export7, the manifest entry); `ship.py get length_world` reads the sheet too (stage 6) |
| hull thickness | the hull loft's solidify modifier `shell` | the same modifier, named `skin`, thickness scaled |
| insides | `inside=True` objects (decks, bulkheads, rooms) | role `interior`, visible to the render and the export |
| hull and parts | role `hull` (masses, plates); any other role is a part; one object per part and material, sharing `grp` | export7 joins role `hull` as the hull surface; the audit holds a part by its `grp` |
| seams | `K.break_line`: kind `trans` at x with its plan path of (x, y); kind `long` along a path of (x, z) | `r209_t_lines` (x), `r209_t_paths` (the plan paths, read by the audit and written into the GLB seams); `r209_l_line` = [mean z, min x, max x] of the path, or [] |
| part kinds | each part's objects: `part_kind` and `machine`, from the faction kit's `MACHINES` | unchanged: the stage 4 audit (R226) |
| guns and launchers | the kit's fit records: muzzles, barrel aim, bore, mount normal, the slot letter and weapon | `r209_hp` muzzles, slot = the data.js index of that weapon and arc (one entry, or the contract refuses it); `r209_guns` |
| turrets | pivots `<id>_turret` with their turning meshes as children (R219) | the same hierarchy; the pivot's slot becomes the data.js index |
| engines | `K.engine`: the bell exit centre and its radius | `r209_hp` engines: aft, at the open bell's centre (stage 7's bell check) |
| core, breach, rcs, board, bay | `K.point` rows (a bay with its launch `dir`) | `r209_points` and `r209_hp` bays. Export7 uses the build's points instead of placing its own: each side point goes onto the hull side within 0.04 of where the sheet put it (a breach anchor also 0.03 clear of every part), and how far each moved is in the export json; the breach count must still be the class and faction count |

`tools/recipe/sheet_contract_selftest.py` (stage 4, every sheet ship) rebuilds the sheet and proves each row: the outside is one
length long, the length, seams, muzzles and slots, turret pivots, engines, insides and hull thickness are the sheet's, and a
ship whose weapon list lacks a sheet weapon, or a sheet with two longitudinal seams, is refused by name. A sheet ship is painted by its faction kit's paint stack (`"bake": "stack"`, below); `bakeAb6.py` refuses a sheet hull rather
than add C15s's break structure to it.

## The paint stack for sheet ships (issue 601; ships.md section 0 item 2)

The method is R96 Q1, binding: procedural materials driven by masks baked from the ship's own geometry, plus a trim sheet and
decals; colours may be sampled from the concept; the concept picture is never projected onto the ship; only CC0 textures (RULEBOOK 5.13: the
Hullbreaker trim sheet and decals are own work, drawn by the stack and dedicated CC0). It is written once per faction kit and every sheet ship of that faction uses it (R218; RULEBOOK 0.9,
R225: one home per fact):

| Fact | Its one home | Read by |
|---|---|---|
| where each colour zone sits on the ship | the build sheet: each object's material is its zone (soot, soot2, rust, iron, blood, pale, violet, steel, dark, dish, warhead, brass; glow, ember, light glow) | the stack, per object |
| what each zone is made of: two tones sampled from the concept, rust, grime, wear, scuffs, rivets, roughness, metal | `tools/blender/kits/<kit>/stack.py` `CONCEPT` and `ZONES` (the samples' method is written there, `sample_concept()` repeats it) | `kits/shared/paint_stack.py` |
| the layers' sizes in ship lengths (mask reach, rivet pitch, scuff tile, rust streaks) | the faction stack's `LAYERS` | the shared stack |
| the trim sheet and the decal art | drawn by the faction stack (`trim_sheet()`, `decal_atlas()`), written to the job's `textures\` with a licence line each (CC0, own work) | the shared stack; `standing.py licences` |
| where decals go | rules in the faction stack's `DECALS` (station along the ship, height band, face, size), placed on each ship's own surfaces by ray cast | the shared stack (`place_decals`, reported in `CELL.json`) |
| glow colours (engine throat and bell lining, running lights) | `godot/fx/faction_looks.json` (the game's own: `engine`, `accent`) | the faction stack's `glow_material` |
| the battle albedo lift (R227) | the game (`godot/render/look.gd`); the paint is not lifted | `paint_sheet.py` applies it only to preview the game's read |

`tools/blender/r209/bake_sheet.py` (env.bat sets `BAKE` to it when the ship json says `"stack"` and the kit has `stack.py`):
1. builds the sheet through `sheet_hull` and the build contract, the same ship stage 4 audited;
2. unwraps two atlases (hull, parts; smart projection and a tight pack: a sheet hull is many thousand small islands);
3. bakes the masks per atlas from the ship's own geometry into `CELL_hull_masks.png` and `CELL_parts_masks.png`: R ambient
   occlusion at a short reach (cavities), G convex edges (bevel normal against the face normal, occluded corners removed),
   B ambient occlusion at a long reach (grime). The hull is baked with the parts in place and the parts with the hull in place;
4. builds one procedural material per (zone, atlas): the plate's own tone per UV island plus a soft patch and fine mottle; the
   trim sheet's scuffs and rivet rows set back from every plate edge (box projected at ship scale, so a gun and a hull plate
   carry the same density, R224); the zone's own trim rows (`ZONE_BY_KIND`: the launch bay mouth's warning stripes); rust in
   cavities, under edges and in a few blooms, running down the sides; grime low, under parts and toward the engines; the decals;
   edge wear to bare metal last, so it eats into the decals;
5. bakes albedo and ORM for both atlases and the hull's detail normal (the layers' height through a bump), then puts the
   textured materials on the ship (`export7.py` reads them as before) and keeps glow, ember and light as their own emissive
   surfaces; the insides keep the sheet's own materials;
6. measures R224 (`tools/recipe/density.py`): per part type, triangles and edge features per square unit, texels per square
   unit and paint detail (the share of the surface as busy as the hull's busiest 30 percent), each against the hull; a part type
   under 0.75 of the hull is flagged in `density.json` and printed by stage 5 (reported, not a pass bar).
The job's `textures\` holds the trim sheet and the decal atlas and `licences.json` their lines, so the licence check now
reads real entries. Running lights (R228): the faction stack's `RUNNING_LIGHTS` rule builds flush red lenses in thin iron frames
on the hull (a row per flank at the sheet's lamp height, deck-edge points; clear of parts, decals and the breach, braking and
boarding points; each frame bridges the plate steps under it), sized to the light rule with a margin (2.2 px on a 70 px ship),
emissive under the game's 0.8 glow threshold; the measured size goes into the job's `lights.json`, which `standing.py lights`
reads over the ship json's `lights`. Plate patchwork, seams and brick rust (R228) are the faction stack's `PATCH_FAMILIES`,
`patch_cell` and `CONCEPT`. Engine glow is the game's (R228): the export's `hp_eng` points with their bell radius drive the
game's engine effect (`godot/fx/fx_hull.gd` reads them as the nozzles), beside the sheet's emissive throat and bell lining.

Pictures: `tools/blender/build_sheets/paint_sheet.py` renders the painted blend at the sheet's concept camera and the four flat
views under the game's light with the battle lift; `paint_compare.py` lays them beside the concept (and the game's camera 170
and 60 shots, `a4_shots.gd` set `cams`) as pictures for Ryan. The PC run for A16 is `tools/pc/jobs/A16_RUN_601.bat`.


## What a ship needs (the per-ship data)

`tools/recipe/ships/<ship>.json` (C15s_23 is the worked example):

- `faction`: picks the kit, `tools/blender/kits/<faction>/` (see `tools/blender/kits/README.md`);
- `hull`: the hull module, a Python file that builds the hull blocks; `tune`: its tuned numbers (written by stage 3);
- `concept_camera`: the camera fitted to the concept (stage 3 fits one when this is empty);
- `outline_gate`: 0.90 and `outline_third_slack`: 5.0, the context the reported outline overlap is printed against (not a pass bar, RULEBOOK 5.8);
- `bake`: the stage 5 bake: `stack` (a sheet ship: its faction kit's paint stack), `none` (unpainted), or a bake script
  (`bakeAb6.py`, the traced hulls);
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
- **Break lines:** the build's own (`common.set_break`, or the build sheet contract, writes them into the blend as `r209_t_lines`
  and `r209_l_line`). Transverse seams are required: with none in the blend, or the list empty, the audit fails. The
  longitudinal seam is optional, as in the export format (issue 592): `r209_l_line` missing or `[]` means the build has none, and
  a present one must be `[z, x0, x1]` with x0 below x1. The audit never falls back to an older hull's lines.
- **A part is its objects together:** a build sheet writes one object per part and material, all carrying the part's `grp`; a
  part is held when any of its objects meets the hull or another part (issue 592).
- **Machines never cross a seam; structure may (R226, RULEBOOK 5.17).** Each part's objects carry `part_kind` and `machine`,
  stamped by the sheet kit from the faction kit's `MACHINES` (`tools/blender/kits/<kit>/parts.py`). A machine (gun, turret,
  casemate, launcher, engine, thruster, claw, sensor mast) across a seam fails the audit; its footprint is all its objects but
  turning meshes, which ride the turret's ring. Structure across a seam is listed in `structure_across_seams`, not failed. A
  seam with a plan path (`r209_t_paths`, from the sheet's `K.break_line(..., path=)`) is tested along the path, so a seam can
  kink round a machine. A build with no kind marks holds every part to the machine rule, as before.
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
| `turret_<n>` | issue 560 (RULEBOOK 6.17): one per turret the kit marks, a child of the ship node at the ring centre: +Y the turning axis, -Z the rest aim. Its turning mesh `turret_<n>_turn` and its muzzles (`hp_w`, with `extras.turret`) hang under it; the ring stays in the ship mesh. Extras: kind, id, socket, slot, weapon, arc_lo, arc_hi, rest_yaw, rest_pitch (docs/ship_pipeline/HARDPOINTS.md "Turrets") |
| `<code>_base.jpg`, `_orm.jpg`, `_normal.jpg` | the hull atlas at 2048 |
| `<code>_parts_base.jpg`, `<code>_parts_orm.jpg` | the parts atlas at 2048 |
| `manifest_entry.json` | the ship's manifest entry: class, band, length and the point counts (gun, engine, bay, breach, core, rcs, board) |
| `<code>_export.json`, `<code>_check.json` | every hard point, the weapon slots, triangles, every file with size and sha256; the check's result |

The check (`tools/recipe/check_export.py`, plain Python) reads the written glb the way the game will. It fails the export when: a
weapon slot has no hard point, or a weapon hard point names a slot, weapon or arc `data.js` does not have; a required point is
missing (a weapon point for every slot, `hp_core`, `hp_eng`, two `hp_rcs`, two `hp_board`, and `hp_bay` when `data.js` gives the
ship a hangar); the breach count is not the class and faction count, the anchors do not cover the sections the count needs, or the
sides are more than one apart; a hard point is more than 0.012 of the ship's length off the mesh (the length is the x extent of the
glb's mesh box, so the limit scales with the ship; `hp_core` must be inside the hull's box). An engine point is the centre of
its bell's exit, and an open bell has no mesh there: an engine point over the limit passes only when the authored bell is there
(`open_bell`, issue 592): mesh on its exit plane (within the limit along the axis) at 0.7 to 1.15 of `extras.radius` from the
axis in at least 10 of 12 sectors round it, a throat upstream (mesh inside 0.9 of the radius within two radii forward), and
nothing in the exhaust path (no mesh inside 0.6 of the radius within two radii aft). The limit is not loosened for any point; a weapon rests aimed backward, a port
mount sits to starboard or the other way round, a forward weapon does not point forward, an engine does not point aft; a weapon
point lacks one of the eight extras in the table above or its extras slot, weapon or arc disagree with its name; a breach anchor
is closer than 0.03 (ship frame, `export7.BREACH_CLEAR`) to a part surface, or +Y is not its outward normal; the manifest entry is
missing or its counts disagree; a map the glb names is not in the folder; a turret the kit marks (a ship json part `turret`, or
one the blend marked, which the export records in `asset.extras.turrets_marked`) has no `turret_<n>` node of its own, or its
muzzles hang on the ship node (the export merged it), or a turret node lacks its turning mesh, a muzzle, an extra, sits off the
mesh, rests aimed aft or rests outside its own arc. Every point is read through the node tree, so a turret's muzzle is checked
where the turret puts it. `check_export_selftest.py` then breaks copies of the real
export (a slot's points removed, a point moved 0.05 of the ship's length off the hull, a gun turned aft, a port point mirrored to
starboard, `hp_core` removed, a weapon's `extras.socket` removed, an engine, rcs and board origin removed, a breach anchor removed,
a breach anchor moved onto a muzzle, a breach anchor turned to face in; on an export with turrets, the turrets folded back into
the ship mesh and the turning meshes taken away; on an export with an open bell, that engine's radius doubled and its point
moved half a radius down its exhaust) and the check must refuse every copy, each for its own reason. `contract_selftest.py` proves the same check on the round 7 ship (C15s_23) in the sandbox, with its real `data.js` weapon
list and the 5 anchors the cruiser of the Hullbreakers gets from the table. An `unbaked=1` test export names its surfaces
`<code>_hull` and `<code>_parts` too, so the clearance is measured in the sandbox as on a baked ship.

**Turrets (issue 560; RULEBOOK 6.17, Ryan R219).** A turret gun turns to face its target in the game; a casemate or broadside
battery stays fixed. The blend says which guns turn in one of two ways (tools/blender/kits/shared/turrets.py): the kit puts an
empty `<id>_turret` at the ring centre (local +Z the turning axis, local +X the rest aim; properties turret=1, slot, weapon,
arc_lo, arc_hi, rest_yaw, rest_pitch) with the turning meshes as its children (the build-sheet kit does this while it builds), or
the kit lists its turning pieces in `TURRET_TURN` in its kit.py and stage 7 marks each turret socket in memory before it reads the
scene (the recipe Hullbreaker kit; the blend on disk is never changed). Stage 7 then joins each turret's turning meshes into
`turret_<n>_turn` under `turret_<n>` and hangs that turret's muzzles under it; everything else is joined into the ship mesh as
before. A kit that marks no turret exports exactly as before. The turret test ship (`tools/recipe/turret_fixture.py`, a small
test hull with the recipe kit's own turret parts, exported by this script with `unbaked=1`) is the game check's fixture
(`godot/render/test/fixtures/T560_fx/`, `godot/render/test/turret_check.gd`).

Stage 7 never copies into the game on its own (the build's ship folder is shared). Set `INSTALL_TO` to a Godot project folder to
install a checked export there: what it replaces is copied to `export\replaced_<date>\` first, the old ship's wreck and damage
files are moved there too (they belong to the old hull), and `manifest_entry.json` is merged into
`assets/ships/manifest.json`. Nothing is deleted. Copying is not the install (issue 587 finding 8): the game draws ships from its
asset cache (`gen/manifest.json`, `gen/ships/`), so stage 7 then refreshes the ship cache (`render/build_assets.gd
--ships-only`: a ship whose files changed is rebuilt, and its entry names no damage or wreck scene the folder no longer has) and
reads the ship back the way the game draws it (`render/test/installed_ship_check.gd CODE`: the cache was built from the
installed files, no old damage or wreck entry, and ShipView loads the ship with every hard point and turret node of the glb).
Either failing fails the stage. `render/test/install_refresh_check.gd` proves the route headless in user:// (an old hull with
damage and wreck, then a new one installed over it).

### Authored insides and weak seams (issue 557)

Stage 7 keeps every visible, non-proxy `role=interior` object and applies the hull's `skin` solidify modifier. It never
replaces an authored room with a flat cap. A build without interior geometry or authored seams fails export and readback.
The original materials, including interior paint, are retained; the inner skin gets a separate dark material. Interior
surfaces share the ship mesh and stay behind its opaque exterior until damage or separation exposes them. They still cost
triangles, surfaces, memory and renderer work: occlusion is not a promise of zero frame cost. Measure the #207 scene.

**The version 1 format** is the ship node's GLB `extras.voidsworn_destruct` dictionary. It contains `version: 1`,
`interior_materials: [material name, ...]`, and `seams: [{p: [x,y,z], n: [x,y,z]}, ...]`, all in the GLB ship frame.
Transverse seams have normal `[1,0,0]`; one built from a sheet also carries `path`, its plan path as `[x, z]` points in the
GLB ship frame (R226: it kinks round machines; the runtime does not read it yet, its breaks still tilt about `p`). The optional longitudinal seam has normal `[0,1,0]` and `span: [x0,x1]`, identifying
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
| light sizes | stages 5 and 7 (`standing.py lights`) | every window and trim light declared in the ship json's `lights`, and every light a paint stack measured into the job's `lights.json` (issue 601, R228), is at least `light_min_px` (2.0) pixels across on a 70 px ship at the battle camera; with neither, it passes because the paint has no lights |

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
| the Hullbreaker kit and paint (`kits/hullbreakers/`); the paint stack for sheet ships (`kits/shared/paint_stack.py`, the Hullbreakers' `kits/hullbreakers/stack.py`) | | a kit per faction: Sunward Crusade, Glasswrights, Eclipse, Chorus, Hegemony Navy, each with its own shape language and paint |

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
