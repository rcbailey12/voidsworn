# Issue 370: the attach point service

Refs #370. Opus worker, Nov 12 2026. Branch opus/issue-370 (PR 570), merged with main after 557 (PR 568) landed; 557's
authored interior code in fx_hull.gd (`_authored`, `interior_material`, the interior-aware `faces_of`) is kept as it was.

## For Ryan

Every gun flash, wing launch, braking or turning jet, wound and boarding breach now starts on the ship: at the point the
builder placed (a barrel tip, a hangar mouth, a breach spot, the core), or, where a hull has none, on the plating a ray
finds, or not at all. Nothing is placed on the ship's invisible bounding box any more. On the recipe cruiser the 18 built
gun muzzles are used. Pictures: `docs/shots/look_bench/attach/` (before on the left, after on the right).

## The service (godot/fx/fx_hull.gd, "the attach point service")

Order of trust for every point type (HARDPOINTS.md): the authored point; else a surface ray onto the hull's own triangles;
else nothing: the effect is skipped, one `[attach]` line is logged per hull, point type and outcome, and the skip is
counted. No path returns a box point or a box fraction. The box only aims rays.

| Call | Authored point | Fallback (all on the plating) | Then |
|---|---|---|---|
| `guns(slot, weapon, target, n, bow_first)` | `hp_w<slot>_*` for that slot and weapon; else that weapon on any slot that bears; else that slot (a sister ship's weapon) | the four station rays per side (as before), a missed station now takes the nearest seen sample facing that side; the bow ray for heavy forward weapons | skip the volley's effects |
| `bay(i, toward)` | `hp_bay_<n>`, cycled per launch | ray up and toward the wing through the core; ray from straight above; the seen sample facing that way most | skip |
| `core_point()`, `core`, `shield_centre()` | `hp_core` | none (contract): a hull without one uses the centre of volume of its own triangles and logs a load error once | skip only with no triangles |
| `breach_point(sec, nth)` | `hp_breach_<n>` of that section (`extras.section`, else by length) | `surface_sample` (the seen samples, each a ray hit) | skip with no triangles |
| `jet(near, through, out)` | `hp_rcs_<n>` on that side and that end, nearest the aim | ray on that side at that station; the nearest seen sample facing the gas's way | skip |
| `board_origin(toward)` | `hp_board_<n>` on the side facing the target | the side plating facing it through the core | skip |

When shots outnumber points: shot i uses point (offset + i) mod count; the offset starts per slot from the hull code and
moves on one per volley (HARDPOINTS.md "When shots outnumber points", rules 2 and 3).

## Every call site moved

| File and line (branch head) | Effect | Was | Now |
|---|---|---|---|
| fx/fx_weapons.gd:132-152 | gun muzzles, every volley | `A.hull.mounts_for` stations, box point on a miss; heavy forward weapons from `bow + 0.3` | `A.hull.guns(opts.slot, wid, ...)`; a station or bow hit keeps its small push off the plate; an authored muzzle is used as is |
| scenes/battle/battle.gd:1917 | the slot reaches the volley | not passed | `"slot": e["weapon"]` (the rules' fire event already carries it, rules.gd:3034) |
| fx/fx_weapons.gd:1160-1168 | wing launch origin and target | `C.hull.c + H * 0.3`, to `S.hull.c` | `C.hull.bay(...)`, to the wing's `hull.core` |
| fx/fx_weapons.gd:1225-1229 | travelling torpedo lane and launch | `A.hull.bow` | `A.hull.guns(-1, "torp" or "startorp", ...)`: its tube, else the bow plating |
| fx/fx_ship.gd:301, 430, 441, 442, 458, 482 | shield bubble centre, shield hits | `hull.c` | `hull.shield_centre()` (the core); the radii grow by the core's offset so the bubble still covers the hull |
| fx/fx_ship.gd:814-838 (`_anchor`) | wounds: main hole "a", second hole "b", scorches "sc0" to "sc2" | `random_sample` | "a" and "b" from `hp_breach_*` of the section; else and for scorches `surface_sample` |
| fx/fx_ship.gd:856, 865, 899, 1114, 1201 | callers of `_anchor` | assumed a point | stop when there is none |
| fx/fx_ship.gd:705-714 (`_rcs`) | hit-reaction jets | corner ray (PR 327) | `hull.jet(corner, c, outward)`: `hp_rcs` first, the same ray, then a facing sample |
| fx/fx_ship.gd:1280-1287 (`pulse`) | ability pulse | `hull.c` | `hull.core_point()` |
| fx/fx_ship.gd:1293 (`tick_flare`) | burn, acid and storm flares | `random_sample` | `surface_sample` (counted) |
| fx/fx_ship.gd:1316-1320 (`jump_out`) | jump flash | `hull.c` | `hull.core` |
| fx/fx.gd:1165-1187 (`board`) | boarding origin and breach | attacker `hull.c`; target ray at box offsets | attacker `hull.board_origin(...)`; the target's side plating through its core; a miss is counted |
| render/ship_view.gd:1298-1372 (`_couple_puffs`, `_retro_puffs`, `_aft_puffs`, `_side_puffs`, `jet_aims`) | braking, stern, side and turning jets, idle station keeping | puffs at box fractions (L x 0.36 to 0.5, half the box beam, 0.2 up) | the same spots only aim; `jet_point` asks `attach.jet(...)` (fx_ship.setup hands ShipView its hull; a ShipView with no effects builds its own); no point, no puff |
| fx/fx.gd:1001-1022 | the per-battle report | none | `attach_report()`: one line per ship at removal and at release |
| fx/fx_hull.gd:574-604 (`_mount_row`) | gun stations | a missed ray became a box point | the nearest seen sample facing that side, else left out |

Not moved, on purpose or by order:

- fx/fx_death.gd:1474 (death fallback `s.hull.c` when there are fewer than two seeds), :2036 (wreck mark fallback
  `c + H * 0.5`, a box point), :1594 (wreck spin pivot about `hull.c`): fx_death.gd was 557's when this job started and the
  brief said not to touch it. 557 has merged; moving these three to `s.hull.core` is a one-line change each, for the Board
  to allow.
- fx/fx_ship.gd:568 (the hit kick's torque arm about `hull.c`): physics, not a placement.
- fx/fx_ship.gd:1273 (a damaged squadron's smoke ribbon): a wing of craft has no hull of its own.
- fx/fx_weapons.gd:107-108, :1315 (`to_c`, the target's box centre): the aim of a volley and the misses that fly past it,
  not where an effect starts.

## The check (godot/fx/test/attach_check.gd, headless, in godot/tools/ci/godot_checks.txt)

Limit: 0.012 of the ship's length (the export check's own, tools/recipe/check_export.py `tol`), plus the barrel or bell
radius for an authored muzzle or engine exit; the core must lie inside the box (as in the export check). Distance: the
shortest of 258 rays from the point onto the triangles (an upper bound, so a pass is sound).

Walked per hull: every authored point, the gun stations, muzzles for every slot and weapon over 16 target directions,
launches, boarding, the core, breach anchors and samples, every ShipView movement jet (`ShipView.jet_aims`, the one
source the jets use) and the hit-reaction corners. Stand-ins built in the script (slab wedge, torus ring, disc and spire
tower) carry it on GitHub, where no ship files exist; on the PC it also walks every ship present.

Behaviour proofs in the check: an authored muzzle wins over the ray; five shots over two muzzles fire 3 and 2 and the next
volley starts on the other; a hull with no authored point uses the ray; a hull with no triangles places nothing and counts
all 8 requests as skips; the ring's launch with no bay lands on its plating; the ring's prow wound sits on its anchor; a
copy of the slab with a muzzle 3 units off the hull is refused.

Fails on main first (the same walk on main's gun stations, `attach_370/attach_proof_main.gd`, output in
`attach_370/main_fails_first.txt`): 24 points off the hull, the ring's guns up to 4.77 and the tower's up to 6.74 units
from any plating. On this branch: 0 (`attach_370/branch_standins.txt`).

## Results on Ryan's PC (all 36 hulls, the recipe ship in place of the A4 C15s_23)

`attach_370/attach_pc_after.json` and `attach_pc_log.txt` (commit 5e34c654, Nov 11 23:13 CST): ATTACH_CHECK PASS, 39 hulls
(36 and the three stand-ins), 0 failures, 0 points off the hull; the worst point anywhere is 24 percent of its limit
(V15_37). Authored points read per hull match godot/assets/ships/manifest.json (C19_51 7 muzzles, 6 engines, 8 breach
anchors; C15s_23 18 muzzles, 6 anchors; carriers B22_11, C16s_23, I16_11, V18_51 2 bays each). No hull has `hp_rcs` or
`hp_board`; every hull has `hp_core`.

Skipped effects: 0 on every hull in the walk, the recipe ship included. Per battle on the bench: 0, see the pictures section.

## Pictures

The look bench's own script (godot/bench/look_bench.gd) with this job's rows (godot/bench/look_moments_attach.json, run with
`--moments`), on Ryan's PC (RTX 5080), the GPU checked free first (under 15 percent twice, no Blender). Main (646e87c8) and
the branch (071e4641) were each benched twice with the same script and rows; the second run of each is kept (RULEBOOK 12.5).
Sheets made by `attach_370/sheets370.py`; the PC jobs are `attach_370/pc/run370a.bat` and `run370b.bat`.

| Picture | What it shows |
|---|---|
| `docs/shots/look_bench/attach/jets_c170.jpg` | the battle camera, true pixels: on main the slab's and the tower's jets float off the hull; on the branch the tower's start on its disc rim |
| `tower_attach_c60.jpg` | jets: main around the spire in empty space, the branch on the rim; wounds: one now on the spire |
| `slab_attach_c60.jpg` | jets: main above and below the sail in space, the branch along the spine; launch: main's glow hangs in space above the spine |
| `ring_attach_c170.jpg` | the forward doom beam now leaves the ring's authored bow point (right rim); wounds move from the ring's middle onto its rim |
| `barge_attach_c60.jpg` | jets: main's top right puff in space, the branch's on the plating; guns alternate between the two authored port muzzles |
| `recipe_attach_c60.jpg` | jets: main's around the hull in space, the branch's at the hull's ends; the broadside flash leaves a built turret |
| `strips/` | every camera 26 strip of the slab, the ring and the tower, before and after |

Skipped effects per battle: every `[attach] battle` line in the branch's kept run (100 lines: attacker and target, every
moment, all five hulls) reads `skipped 0`, the recipe ship included (`attach_370/bench_after_attach_lines.txt`). Guns on
all five hulls came from authored muzzles only (`gun hp N ray 0`). Launches used the ray on all five (none has `hp_bay`);
jets used the ray (none has `hp_rcs`).

Seen by eye, not yet right:

- The slab's launch glow on the branch is not visible: the ray puts it on the spine, inside the hull's own bright glow.
  Not skipped (the log says ray), not in empty space, but nothing to see. A look call: launch from the bay plating facing the
  camera, or brighten the launch flash.
- On the ring and the slab at camera 170 the jets that now start on the plating are hard to see (small against the hull
  or inside the spine glow); on main they read because they floated in open space. Puff size and brightness on the plating
  are a look tuning for the Board (render/ship_view.gd `_puff`, PUFF_MIN).

## What waits on 557 (now merged) and on a re-export

- `hp_rcs` and `hp_board`: tools/recipe/export7.py already writes both (lines 160-161, 284-288) and
  tools/recipe/check_export.py refuses an export without them (lines 16-17, 181-185; hardpoints.py `missing_required`).
  No code is missing: the round 7 C15s_23 export predates the contract, so it needs a stage 7 re-export on the PC. The A4
  hulls (C19_51 included) will never get them; they use the surface ray, which the check holds to the hull.
- `hp_bay` on C19_51 (the barge has `hangar:2`, data.js:84, and no bay point): its launches use the ray; a re-export of
  the barge through the recipe would add them.
- fx_death.gd's three box-centre uses above, now that 557 has merged.

## Checks run

- Sandbox (Linux Godot 4.7.2): every listed headless check, 40 of them, PASS, the new attach check included.
- GitHub at 5e34c654: standing checks and Godot game checks green (rules parity was cancelled by the next push; the
  latest head runs it again). Movement playback and rules results do not change: no rules file is touched, and
  movement_flight_check and nose_first_check pass (the jets moved, the flight did not).

## Unsure

- The shield bubble now centres on the core and grows by the core's offset (2.5 units on the barge), so on an off-centre
  hull it is a little bigger than before. Issue 371 replaces the bubble with a hull skin; if the Board prefers, the
  bubble can stay on the box centre until then (one line, `shield_centre`).
- The jet choice among authored `hp_rcs` points (same side, same end, nearest the aim) has never seen a real `hp_rcs`;
  it waits on the re-export.
- A volley with no `slot` (the gallery, scene_gate) matches muzzles by weapon id and bearing; a hull built for a sister ship
  whose weapon ids differ falls to the rays.
