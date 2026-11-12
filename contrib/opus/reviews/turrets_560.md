# Issue 560: turret guns turn to face their target

Refs #560. Opus worker, Nov 12 2026. Branch opus/issue-560, stacked on opus/issue-370 (PR 570, the attach point service, not
merged yet): until 570 merges, PR 576 also shows 370's commits. Ryan's ruling: R219, RULEBOOK 6.17 ("I agree with your design on
turrets": turret guns turn to face their target when they fire; fixed side guns stay fixed).

## For Ryan

The recipe cruiser's two deck turrets now turn smoothly toward the ship they shoot at, fire from the turned barrel, and swing back
to rest afterwards. The casemates on its sides do not move. A turret never turns its barrel through its own ship: the aft turret
(turS) sits so close to the stern deck dressing that it can only turn about 15 degrees each way, which is a build fix (see
"Found on the way"). At the battle camera a turret is a few pixels across, so the turn reads as a small flicker of the barrel;
it reads clearly from camera 60 in. Pictures: `docs/shots/turrets/`.

## What changed

**Export (stage 7).** Both export routes used to weld every gun into the one ship mesh (contrib/opus/reviews/handoff_trace_559.md
row 2). Now:

- `tools/recipe/export7.py`: a turret leaves the export as its own node `turret_<n>` at the ring centre (+Y the turning axis, -Z
  the rest aim; extras kind, id, socket, slot, weapon, arc_lo, arc_hi, rest_yaw, rest_pitch), with its turning mesh
  `turret_<n>_turn` and its muzzles (`hp_w...`, extras.turret) as children (lines 348 to 368); the ring stays in the ship mesh.
  The meshes are joined per turret (`prep` and `join`, lines 211 to 252); the glTF selection is now recursive (line 380); the
  asset extras record `turrets_marked` (line 410), the manifest entry a turret count.
- How the blend says which guns turn (`tools/blender/kits/shared/turrets.py`): an empty `<id>_turret` with the turning meshes as
  its children (the build-sheet kit's marking, issue 532, `tools/blender/build_sheets/kit.py` `emit(pivot=...)`), or a
  `TURRET_TURN` list of the kit's turning pieces that stage 7 applies in memory (`mark_from_parts`; export7.py lines 70 to 95).
  The recipe Hullbreaker kit now declares `TURRET_TURN` (tools/blender/kits/hullbreakers/kit.py line 258).
- `tools/blender/kits/shared/hardpoints.py` (lines 220 to 272): the turret contract (names, extras, the rules arcs, the
  checks), plain Python, one source for the export and the check.
- `tools/recipe/check_export.py`: reads every node through the tree (`world_matrices`, line 64), so a turret's muzzle is checked
  where its turret puts it; fails a ship whose kit marks a turret that the export merged (lines 256 to 268), and a turret with no
  turning mesh, no muzzle, a missing extra, a pivot off the mesh, a rest aim aft or a rest outside its arc.
- Self-tests: `check_export_selftest.py` adds `turret_merged` and `turret_no_mesh` (on an export that has turrets);
  `contract_selftest.py` builds the C15s_23 fixture with its two json turrets and adds the same two refusals.

**Game.** `godot/fx/fx_hull.gd` (the attach point service, section "turrets", line 1051 on):

- `_read_turrets` finds the `turret_<n>` nodes; `_read_points` keeps each turret muzzle in its turret's frame (line 747).
- `_turret_clearance` (line 1162), once per hull: the yaws a turret may reach from rest, walking both ways until its arc ends or a
  barrel line would run into the ship (the hull and every part that does not turn), edges to a tenth of a degree; the reach may
  pass 180 degrees the far way round a blocked sector.
- `guns()` (line 871) turns each turret it uses toward the target (`turret_aim`, line 1288): the goal is the target's bearing
  clamped to the reach (an unreachable target gets the nearer edge); the traverse is a cubic that starts at the turret's current
  speed and ends at rest, timed by `_traverse_time` (line 1265) so the average rate is at most 150 degrees a second and the
  acceleration at most 900 degrees a second squared (tuning values, lines 1065 to 1069). A turret muzzle comes back where the
  turned barrel will be (`muzzle_at`), with its arrival time.
- `godot/fx/fx_weapons.gd`: each turret shot waits for its turret (the "lead", lines 135 to 150 and 180), then
  `turret_release` (line 190) holds the aim through the last shot plus 0.9 s and swings it home. The volley also returns
  `muzzles` (each shot's start point and turret) for the checks (line 191).
- `godot/fx/fx_ship.gd`: `turret_step(fx.now)` writes each turret's pose on its node every frame (line 298), so the turret
  follows the effect clock (hit pause, kill slow motion, hurry) in step with its shots; the damage frame is never a turret mesh
  (line 145).
- `godot/render/ship_view.gd` needed no change: it already keeps the glb's node tree (build_assets.gd `_glb_to_scene`), and its
  fit and look passes take the turret meshes like any other.
- Rules: no rules file changed. The volley takes the rules' shots and hits as before; only the look's timing moves (RULEBOOK 7.4).

**Checks.** `godot/render/test/turret_check.gd` (headless, listed in godot/tools/ci/godot_checks.txt) on the turret test ship
(below). `godot/fx/test/attach_check.gd` (issue 370) measured turned turret muzzles against the hull at rest and failed on the
re-exported cruiser on the PC; it now turns each one back by its turret's yaw first.

**Bench.** `godot/bench/look_moments_turrets.json` (three rows on the re-exported C15s_23) and an optional `focus_off` per row in
`godot/bench/look_bench.gd`, so the close cameras centre on the aft deck.

## The test ship

My call: a small Blender export through the real stage 7, using the recipe Hullbreaker kit's own `turret()`
(`tools/recipe/turret_fixture.py`, ship json `tools/recipe/ships/_turret_fixture.json`, written to
`godot/render/test/fixtures/T560_fx/`, 118 KB, `unbaked=1`). Why: it proves the whole road (kit part, blend marking, export,
check, glb, game) on GitHub where no ship files exist, and it uses both marking routes: turA is marked in the blend (the
build-sheet way, with a narrower arc of its own, -120 to +120) and turB by the kit's `TURRET_TURN` list (the recipe way), with a
mast beside turB so the "never into its own ship" rule is exercised. It is test geometry, not ship art.

For the pictures, the real ship: the round 8b baked cruiser (`opus209\out8b\Ab8.blend`, opened read only) re-exported through
stage 7 on the PC: 125,656 triangles in the ship mesh, two turrets (1,172 triangles), 18 muzzles, 5 breach anchors, rcs and
board points; check PASS and selftest PASS (18 cases, the two turret cases included). `turrets_560/pc/`.

## Proofs

| What | Result | Where |
|---|---|---|
| The pre-560 exporter on the same test scene is refused | FAIL, 4 problems: both turrets merged, both muzzles on the ship node | turrets_560/fixture_pre560_export_refused.txt |
| The new export of the test ship | PASS; selftest PASS (18 cases) | turrets_560/fixture_export_check.txt, fixture_export_selftest.txt |
| Contract selftest on C15s_23 (no Blender) | PASS, merged and no-mesh copies refused | turrets_560/contract_selftest.txt |
| Real cruiser re-export on the PC | check PASS, selftest PASS | turrets_560/pc/log_check.txt, log_selftest.txt |
| turret_check (sandbox and PC) | PASS: 20 shots at 10 bearings; the barrel's bearing at the shot matches the target within 0.001 degrees when reachable; out of reach it holds the edge exactly (turA at +-120 for targets astern; turB at +72 or -257.7 for targets behind its mast); every shot starts 0.0000 from the turned muzzle node; no frame past the reach; no barrel line into the ship (an independent ray test); peak 225 degrees a second, at most 0.24 degrees change of step per frame; back to rest after every volley; fixed guns never move; the same hits with turret nodes removed | turrets_560/turret_check_sandbox.txt, .json; pc/log_turret_check_b.txt |
| attach_check on the PC, real cruiser | PASS, 151 points, 0 off the hull, 0 skipped | turrets_560/pc/log_attach_b.txt |
| All headless Godot checks (sandbox) | 41 of 41 PASS (death_leap_check after reusing the base import cache; the sandbox's own import of fx/atlases differed) | turrets_560/sandbox_headless_checks.txt |
| Standing checks (run_all_checks.js), doc check | PASS (known baseline only) | |
| Cost | turret_step 7 microseconds a frame for a ship with two turrets (PC 7.4, sandbox 6.8); two more draw calls per turreted ship (the turret meshes); no new triangles | |

## Pictures (docs/shots/turrets/)

The look bench's script with this job's rows (`godot/bench/look_moments_turrets.json`) on Ryan's PC (RTX 5080), GPU checked free
first, benched twice at commit 1878cf02, the second run kept (RULEBOOK 12.5); every cell a 1 to 1 pixel crop centred on the aft
deck. Sheets made by `turrets_560/sheets560.py`. No main baseline: main cannot turn a turret.

| Picture | What it shows |
|---|---|
| `t_turrets_port_aft_c26.jpg` | the closest camera: turA (centre) swings from the bow toward a target to port and aft, fires, and comes back to rest by 4.1 s; turS (left, under the stern gantry) only moves inside its 15 degree reach |
| `t_turrets_stbd_bow_c26.jpg` | the same toward a target to starboard and forward |
| `turrets_c60.jpg` | both rows at camera 60 |
| `turrets_c170.jpg` | the battle camera at true pixels, and the same cells magnified 3 times: the turret is a few pixels; the turn shows as a small change of the barrel and the flash leaves the aft deck |
| `casemates_fixed.jpg` | the port casemates fire (forward, out of this aft crop): the deck turrets are not asked and do not move |

Cost and log: `turrets_560/pc/bench_b2.json`, `log_bench_b2.txt` (9 stills, 0 warnings); the PC run files `pc/run560.bat` and
`pc/run560b.bat`.

## How a kit marks a turret (every future faction kit)

Written into `tools/blender/kits/README.md` ("How a kit marks a turret"), `docs/ship_pipeline/HARDPOINTS.md` ("Turrets"),
`docs/ship_pipeline/RECIPE.md` stage 7 and `tools/blender/kits/hullbreakers/README.md`:

1. Split the turret into what stays (ring, bolts, welds) and what turns (housing, mantlet, breeches, barrels, brakes), modelled
   round the mount normal through the ring centre.
2. Mark it: an empty `<id>_turret` at the ring's top centre (local +Z the mount normal, +X the rest aim; turret=1, slot, weapon,
   arc_lo, arc_hi, rest_yaw, rest_pitch) with the turning meshes as its children; or list the turning pieces in `TURRET_TURN`.
3. Register each barrel's muzzle with `register_gun(..., tip=, socket=<the turret's socket or id>)`.
4. Never mark a casemate, sponson or broadside battery.

The Hullbreakers build-sheet kit for A16 and A17 (branch opus/issue-532, PR 547) already writes route 1, so their turrets are
turret-ready; when they go through stage 7 their sheets' `<id>_turret` empties become `turret_<n>` nodes with no further work.
Those sheets do not register muzzles in `scene['r209_hp']` yet (the build sheets are not stage 7 blends); that is the build job's.

## Which hulls keep fixed guns

- All 36 A4 hulls in the game build (one baked mesh and one material each; only `hp_w` points): fixed, as before.
- The C15s_23 round 7 export installed in the game build today: fixed until the re-export above is installed (stage 7 with
  `INSTALL_TO`, the Board's call; the export is in `opus560\export\C15s_23` on the PC).
- Any ship whose kit marks no turret: exports and plays exactly as before.

## Found on the way

- turS on the recipe cruiser can train only -14.7 to +14.7 degrees: past that its barrel line runs into fixed parts on the stern
  deck (the ship mesh's parts surface at about 1.1 units ahead and 0.35 to port of its ring, and again at 0.5 units out at 45 to
  60 degrees; probed on the real export in the sandbox). The game keeps it inside that reach, so against a target to the side it
  fires at the edge. Fix in the build: raise turS on a barbette or clear the dressing round it. turA reaches -121.6 to +121.6.
- RULEBOOK 4.2 ("no gun faces backward") is enforced at rest (the export check refuses a turret resting aft). A turret with a
  T arc does train aft at a target behind, because R219 asks it to face its target. If the Board reads 4.2 as "never aft, even
  while tracking", narrow the arc in `hardpoints.RULES_ARC` T or in the kit.

## Not done, and unsure

- The scene gate (bench/scene_gate.gd) was not rerun: it needs every hull of the #207 battle built in a clone, and the cost here
  is 7 microseconds and two draw calls per turreted ship. The Board may want it after the re-export is installed.
- Barrels do not change elevation: they keep the kit's rest pitch (the board is flat; R219 asks for the bearing).
- A turret's clearance is tested against the hull and fixed parts; another turret is ignored (both move). Superfiring layouts are
  the build's fit check (RULEBOOK 5.15).
- Damage marks drawn as an overlay (fx_breach's marks mesh) do not follow a turret that has turned; the rebuilt turret mesh does.
- The look-bench rows are new: no main baseline exists for them (main cannot turn a turret).
