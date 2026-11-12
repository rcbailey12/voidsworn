# The hard point contract

Issue 363. This is the contract the ship recipe writes and the effects read. It is owned by the Board; the one count table
lives in code at `tools/blender/kits/shared/hardpoints.py`, and both the writer (`tools/recipe/export7.py`) and the checker
(`tools/recipe/check_export.py`) read it, so a number in this document and a number in the code cannot drift apart.

The rule behind it (Ryan, R164, Nov 10 2026): "It should vary by size of ship, faction, etc. We want things to be on theme."
So there is no fixed hard point count. Gun points follow the hull's own weapon slots and barrels, engine points follow its
engines, bay points follow its hangars, and breach anchors follow the class and faction table below.

## The frame and the node axes

Every game ship is in the game frame: **+X is the bow, +Y is up, -Z is port** (standard glTF, right-handed, true chirality;
`tools/blender/a4/K1_DECISIONS.md` decision 2). Every hard point is an empty node, a direct child of the ship node, with its
own translation and rotation already in that frame (the ship node itself has no transform). The one exception is a turret's
muzzle: it is a child of its turret node (see "Turrets" below), so its transform is in the turret's frame and it turns with
the barrels. The check and the game read every point through the node tree.

Every point uses the same local axes:

- local **-Z** is the point's forward: the barrel at rest, the plume, the launch direction, the breach tangent or the party
  direction;
- local **+Y** is the point's up: away from the hull (the mount normal), ship up, or the outward surface normal;
- local **+X** completes the right-handed frame.

The game reads a node's -Z as `-basis.z` and its +Y as `basis.y` after import. A point with a wrong axis is a broken point,
not a cosmetic one: a gun fires backward or a plume leaves sideways.

## Point types

| Type | Name | What it is | Axes | `extras` |
|---|---|---|---|---|
| weapon | `hp_w<slot>_<weapon>_<arc>_<n>` | one weapon muzzle (barrel tip) for slot `<slot>` of the ship's `data.js` weapon list (0-based). The slot, weapon and arc are read from `data.js`, never typed | -Z along the barrel at rest; +Y away from the hull | `kind=gun`, `size`, `arc`, `arc_deg`, `slot`, `weapon`, `radius`, `socket` |
| engine | `hp_eng_<n>` | one engine exit | -Z out of the bell along the plume (aft); +Y ship up | `kind=engine`, `radius`, `engine` |
| bay | `hp_bay_<n>` | a hangar mouth and launch point | -Z out of the mouth along the launch direction; +Y ship up | `kind=bay`, `hangar` |
| breach | `hp_breach_<n>` | a breach anchor: where the hull opens when it dies | +Y the outward surface normal; -Z a tangent along the hull | `kind=breach`, `section` (`prow`, `mid`, `eng`), `side` (`P` or `S`), `clear` |
| core | `hp_core` | the hull's centre of mass: the death explosion origin | identity, the ship frame itself | `kind=core` |
| braking origin | `hp_rcs_<n>` | a braking puff origin (an attitude thruster) | -Z along the braking thrust (forward for a braking burn); +Y ship up | `kind=rcs`, `side` |
| boarding origin | `hp_board_<n>` | where a boarding party leaves the hull | -Z out of the hull toward the target (the side normal at rest); +Y ship up | `kind=board`, `side` |

`<n>` is a 0-based counter within its type (and within its slot for weapons), with no gaps. A name that is not one of these
patterns is refused by the check.

The braking and boarding origins are new in this job. The K1 decision 7 list had no type for them and the hole check (Muse,
F6) found that the effects were using box corners and their own ray for both. `hp_bay` covers both a hangar mouth and a
launch point; there is no separate launch type. A carrier registers one mouth per hangar it actually has; `data.js` gives the
hangar count, the model decides how many mouths that is.

## Breach anchors: one table, by class and faction

The base count comes from the class table in `docs/playbooks/factions.md` ("Breach anchors by class"). A faction adds or
removes one where its sheet says so. The exact rules in `hardpoints.py`:

| Class (`data.js` `cls`) | Base anchors |
|---|---|
| Squadron, beacon | 0 |
| Frigate | 2 |
| Destroyer | 3 |
| Cruiser, transport | 4 |
| Carrier, Battleship, Battle-barge | 6 |
| Dreadnought, Super-dreadnought, Ark, Bio-titan, Tomb-ark, station | 8 |

| Faction | Adjustment | Source |
|---|---|---|
| Sunward Crusade (`voidsworn`) | 0 | its sheet places anchors on the broadside deck line, evenly spaced |
| Hegemony Navy (`hegemony`) | 0 | module joints |
| Ashfall Hullbreakers (`corsair`, `hullbreakers` in the ship json) | +1 | "One more breach anchor than the base count, placed unevenly." |
| The Glasswrights (`ithar`) | -1 | "One fewer breach anchor than the base count; each large optic is its own break piece." |
| Eclipse (`deathless`) | 0 | the shade bands |
| The Chorus (`chorus`) | +1 where the base is 6 or more | "One more breach anchor than the base count on the big ones." |

The expected count is `max(0, base + adjustment)`. Examples: a Hullbreaker cruiser gets 5, a Glasswright cruiser gets 3, a
Chorus carrier gets 7, a Hegemony battleship gets 6, a Hullbreaker dreadnought gets 9, a squadron craft gets 0. The round 7
ship `C15s_23` (a Hullbreaker cruiser) gets **5**; the round 7 export that shipped has 6, so it needs a PC re-export to match
this table.

Placement is by faction, not one layout for every hull. The export uses the faction's preferred side height
(`FACTION_Z` in `hardpoints.py`: the broadside deck line for the Sunward, the module joints for the Hegemony, the lens bays
for the Glasswrights, the shade bands for the Eclipse, the sacs and flanks for the Chorus) and jitters the Hullbreakers'
positions deterministically so their anchors are uneven but the same on every export. Every anchor stays on open hull, at
least 0.03 (ship units) from every part surface.

The count is spread over the three sections and both sides by the one layout rule (`breach_layout`):

| Anchors | Sections | Sides |
|---|---|---|
| 0 | none | none |
| 1 | mid | one side |
| 2 | prow, eng | one each, port and starboard |
| 3 | prow, mid, eng | alternating, port first |
| 4 to 9 | even, the extra in mid first, then prow, then eng | alternating, port first |

The check enforces the count, that every section the count needs has at least one anchor, and that the port and starboard
totals stay within one of even. It does not force one exact placement: the faction sheet and Ryan's eye own that.

## The smallest required set per class

These are minimums (except the breach count, which is exact). More points are allowed: a hull with more barrels than one per
slot gets more weapon points.

| Class | Weapon points | Engines | Bays | Breach | Core | Braking origins | Boarding origins |
|---|---|---|---|---|---|---|---|
| Squadron | one per weapon slot | 0 | 0 | 0 | 1 | 0 | 0 |
| Frigate | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 (port and starboard) | 2 (port and starboard) |
| Destroyer | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Cruiser | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Transport | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Carrier | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Battleship | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Battle-barge | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Dreadnought, Super-dreadnought, Ark, Bio-titan, Tomb-ark | one per slot | at least 1 | 1 when `hangar` is above 0 | table | 1 | 2 | 2 |
| Station | 0 | 0 | 0 | table | 1 | 0 | 0 |
| Beacon | 0 | 0 | 0 | 0 | 1 | 0 | 0 |

The weapon slots are the `data.js` `w` list for the ship's `game_ship` id, in order. One point per slot is the floor; the
Hullbreaker cruiser has 18 muzzles for its 4 slots, which is legal. A ship with a hangar in `data.js` must register at least
one `hp_bay` or the export fails.

## When shots outnumber points

The guns must never start a shot in empty space because a slot has fewer points than the volley has shots. The reader rule:

1. Gather the authored points for the slot: `hp_w<slot>_*`, sorted by `<n>`.
2. If there are enough points, give each shot its own point for that volley, starting at a per-battle rotating offset so the
   same point is not always the first to fire.
3. If there are more shots than points, **cycle through the points**: shot `i` uses point `i % count`, continuing from the
   rotating offset. The first point may therefore fire twice in one volley, which is what the old side-mount fan did.
4. If a hull has no point for that slot at all (an old A4 ship, or a broken install), use a **surface ray** from the volley
   direction onto the hull's own triangles, once per shot. The ray hit is the attach point and its normal is the surface
   normal.
5. If the ray misses too, **skip that shot's effect** and log one line per hull and point type per battle. Never fall back to a
   point on the hull's bounding box, and never a fold point or a guessed fraction of the length.

The same first-choice rule applies to engine plumes, bay launches, braking puffs, boarding parties, breach damage and the
core. The core is special: it has no ray fallback because the death explosion has to start inside the hull; a missing core is
a load error, not a reason to guess.

## When a required point is missing

Two places, two different jobs:

- **The export.** Stage 7 fails. `check_export.py` names every missing point and the expected count, exits non-zero, and
  stage 7 writes `FAILED` and installs nothing. A ship cannot enter the game without the smallest required set.
- **The game.** An old hull, or a ship folder that was copied without its points, does not block a battle. The attach point
  service logs one line per hull and point type at load ("hp_w2 missing on B19_11; using the surface ray"), then uses the ray
  where one exists, or skips the effect. A skipped effect is visible as a missing plume or puff in a capture, never as a point
  in empty space.

The old A4 hulls keep their existing points and the fallback above. This contract is enforced for ships built by the recipe;
the 36 old hulls are not retrofitted (Board verdict on audit finding 6: build the points into the new recipe instead of
retrofitting hulls that will be replaced).

## Turrets (issue 560)

RULEBOOK 6.17 (Ryan, Nov 11 2026, R219: "I agree with your design on turrets"): turret guns turn to face their target when they
fire; fixed side guns (casemates, broadside batteries) stay fixed. A turret reaches the game as its own node:

| Node | Where | Axes | `extras` |
|---|---|---|---|
| `turret_<n>` | a child of the ship node, at the ring centre on the ring's top face (the pivot) | +Y the turning axis (the mount normal, away from the hull); -Z the rest aim projected into the ring's plane | `kind=turret`, `id` (the kit's part id), `socket`, `slot`, `weapon`, `arc_lo`, `arc_hi`, `rest_yaw`, `rest_pitch` |
| `turret_<n>_turn` | a child of `turret_<n>`, in its frame | | (a mesh: housing, mantlet, breeches, barrels) |
| `hp_w<slot>_<weapon>_<arc>_<k>` | a child of `turret_<n>`, one per barrel of that turret | as every weapon point | the weapon extras plus `turret=<n>` |

`arc_lo` and `arc_hi` are bearings from the bow in degrees, + to port (the frame of core.js `inArc`): the arc the turret may
train through. A kit that gives no arc of its own gets its slot's rules arc (`hardpoints.RULES_ARC`: F -60 to 60, P 30 to 150,
S -150 to -30, T all round). The ring and its bolts stay in the ship mesh. `<n>` counts the ship's turrets from 0.

How a kit marks a turret in its blend is in `tools/blender/kits/README.md` ("How a kit marks a turret") and
`tools/blender/kits/shared/turrets.py`: an empty `<id>_turret` with the turning meshes as its children, or a `TURRET_TURN` list
of the kit's turning pieces that stage 7 applies. The export writes the nodes above (`export7.py`); the check
(`check_export.py`) fails a ship whose kit marks a turret that the export merged into the ship mesh (no `turret_<n>` of its own,
or its muzzles on the ship node), a turret node with no turning mesh or no muzzle, a missing extra, a pivot off the mesh, a
turret resting aimed aft or resting outside its own arc.

In the game (the attach point service, godot/fx/fx_hull.gd "turrets"): before a turret's shots it turns toward the target, the
goal clamped to its arc and to the yaws where its barrels stay clear of its own ship (checked once when the ship is added,
against the hull and every part that does not turn); the traverse is eased (an average 150 degrees a second, never faster than
1.5 times that, never accelerating faster than 900 degrees a second squared; tuning values); each shot waits until its turret
arrives and leaves the turned muzzle; after its last shot the turret holds 0.9 s and trains back to rest. The rules never see it
(RULEBOOK 7.4). A hull with no turret node keeps fixed guns: the 36 A4 hulls and the round 7 export of C15s_23.

## The shield surface (for P3-22)

The shield job (P3-22, issue 371) needs a surface it can hug to the hull, not a sphere. The recipe names it as an output so
the shield job can build against a fixed file:

- file: `<CODE>_shield.glb`, beside the ship in `godot/assets/ships/<CODE>/`;
- root node: `<CODE>_shield`, child of nothing (P3-22 parents it under the ship node at identity, like `_damage.glb`);
- one mesh, one surface named `<CODE>_shield`, built from the ship's own hull pushed out by 0.01 to 0.02 ship lengths, with no
  gaps at the bow or the engine bells;
- facing data per vertex (or per triangle) for the four rules facings, in the rules' own order: prow, starboard, aft, port, so
  one surface carries all four facings (R160 point (d) allows this; four meshes are not required);
- the faction's shield colour in `asset.extras.palette.shield`, so the shader never looks it up in `ships3d.js`;
- Eclipse ships get no shield surface (the rules give them none).

The export does not write this file yet. P3-22 owns it; this contract only fixes the name and the shape so the two jobs do not
invent different ones.

## How the contract is enforced

- `tools/blender/kits/shared/hardpoints.py`: the point types, the axes, the smallest required set and the one breach table.
  Plain Python, no Blender and no numpy.
- `tools/recipe/export7.py`: writes the points in this contract, writes `manifest_entry.json` with the counts, and calls
  `hardpoints.missing_required` before it writes anything; a missing required point stops the export.
- `tools/recipe/check_export.py`: reads the written glb the way the game will and fails on a missing required point, a wrong
  breach count or layout, a wrong axis, an off-mesh point, or a manifest entry that disagrees with the points.
- `tools/recipe/check_export_selftest.py`: breaks a real export in every required way and proves the check refuses each copy
  for its own reason. Stage 7 runs it after the check.
- `tools/recipe/contract_selftest.py`: proves the same check on the round 7 ship in the sandbox, with its real weapon list.
- `tools/recipe/contract_tables_selftest.py`: the pure table and standing gate test, run by the standing checks on GitHub.
- `tools/recipe/standing.py`: the standing gates (outline per third, inner edges, second camera, paint sides, blink sheet,
  texture licences, light sizes) that stage 7 also requires before it exports.

## What this contract does not do

The game side is the attach point service at the end of `godot/fx/fx_hull.gd` (issue 370): every effect that starts on the
ship reads these points first, then a surface ray, then skips and counts (godot/fx/API.md section 2;
`godot/fx/test/attach_check.gd` holds every point to the export check's own 0.012 of the ship's length). This contract does not
rebuild the old A4 hulls: they keep their existing points and the fallback above. Neither the A4 hulls nor the round 7 export
carry `hp_rcs` or `hp_board` yet; the export writes them, so a re-export adds them.
