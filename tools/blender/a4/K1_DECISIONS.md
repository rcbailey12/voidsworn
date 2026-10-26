# K1: kit decisions for the A4 ship rollout

Decided by Claude on Oct 26, 2026 (travel sprint, R34) as technical calls. Ryan can veto any of them; each one says what changes if he does.
Source of the open list: FINDINGS K1 and `contrib/muse/reviews/kit_spec_synthesis.md` ("Open decisions").

## 1. Size classes

**Call:** keep the game's own class names (data.js `cls`) as each ship's class, and map them onto four kit bands that set part sizes,
hard point sizes and texture size. No invented ladder.

| Band | Classes | Game length (CLS_LEN, world units) | Texture in the repo | Wreck chunks |
|---|---|---|---|---|
| S | Frigate, Squadron craft, relay beacon | 1.6 to 6.5 | 2048 (craft 1024) | 4 (craft 3) |
| M | Destroyer, Cruiser, transport | 9.5 to 14.5 | 2048 | 6 |
| L | Battleship, Carrier, Battle-barge | 16.5 to 26 | 2048 | 8 |
| XL | Dreadnought, Super-dreadnought, Ark, Bio-titan, Tomb-ark, station | 26 to 31 | 2048 | 10 |

**Why:** the synthesis found both outside drafts invented their ladders, and five classes are singletons, so per-class ceilings mean
nothing. Bands are only used where a range is needed (part sizes, wreck counts).

**Part sizes are set in world units and divided by the class length**, so a medium turret looks the same size on a frigate and on a
battleship (every ship file is built at length 1.0 and the game scales it by CLS_LEN):

| Mount size | Turret ring radius (world) | Typical use |
|---|---|---|
| S | 0.16 | flak, autocannon, point defence |
| M | 0.26 | turret, battery, torpedo tube |
| L | 0.40 | heavy battery, ion and lance mounts |
| XL | 0.55 | spinal and doom weapons on the flagships |

If vetoed: the table is one dict in `tools/blender/a4/kit.py` (`MOUNT_R`); changing it rebuilds every ship the same way.

## 2. Handedness and frame

**Call:** every A4 export uses one frame, the standard glTF one, with true chirality: **+X is the bow, +Y is up, -Z is port, +Z is
starboard** (right-handed, metres are ship lengths: the hull runs about x -0.5 to +0.5). The ship looks in Godot exactly as it looks in
today's Babylon game.

**Why:** the game's hull files store "x bow, y up, z port", which is correct in Babylon (left-handed). Read as-is by a right-handed engine
(Godot, Blender, glTF) they come out mirrored. The A2 engine-test exports were mirrored this way (harmless for symmetric hulls, wrong
for the barge's stolen starboard engine and for port and starboard hard points). The A4 loader reflects once at import and flips the
triangle winding to match, so nothing is mirrored from there on.

**Check (automatic, every build):** port hard points must come out with z < 0 and starboard ones with z > 0, and every triangle must face
outward (signed volume positive).

Inside Blender the A4 scripts work in x bow, y port, z up (true chirality, right-handed). Blender's own glTF exporter turns that into the
glTF frame above.

If vetoed (keep the old mirrored frame): one sign in `tools/blender/a4/frame.py`.

## 3. Faction glow mapping (FAC3D has no "glow" key)

**Call:** the kit's glow roles map onto FAC3D keys like this:

| Kit role | FAC3D key | Where |
|---|---|---|
| engine glow, plume colour | `eng` | engine bell glow discs, `hp_eng_*` hard points |
| windows, running lights, lenses | `win` | baked emissive map |
| weapon muzzle colour | `bolt` (guns), `beam` (lances, ions, beams) | the effects helper reads it per weapon family |
| shield | `shield` | faction colour (R3) |

Each ship's glb carries these colours in `asset.extras.palette` so the Godot side never has to look them up in ships3d.js.

**Gain calibration (Huber fit over a FAC3D colour chart, clamp 0.75 to 1.25, 3% residual gate):** adopted as a procedure, but it runs
once G4 locks the lighting and tonemapper in Godot (G4 owns them, and a gain fitted under today's lights would be thrown away). Until
then the gain is 1.0 and the baked albedo uses the FAC3D values directly.

## 4. Symmetry

**Call:**
- Voidsworn, Hegemony, Ithar, Deathless: **bilateral**. Every hand-built part and hard point comes as a mirrored port and starboard pair,
  or sits on the centreline. AI hull asymmetry that reads as a blob gets rebuilt; asymmetry that reads as design stays.
- Chorus: bilateral where the body allows (grown pairs), singles where the AI body is lopsided (living things are not exact).
- Corsair: **deliberately asymmetric** (art direction, CLAUDE.md exception): mismatched pairs, one side heavier, salvage bolted on.
  Hard points still come in port and starboard sets so the game's P and S batteries both have somewhere to fire from.

## 5. The "Basilica" proof manifest

**Call:** bound to **V1b_r_23**, the Voidsworn Ascendant dreadnought: the faction flagship, built first in the Voidsworn pass (plan A4:
"flagship first, it proves the faction look"). Its ship file in `tools/blender/a4/ships.py` is the proof manifest.

## 6. Ship template as data (schema only)

**Call (already decided, recorded here):** no TypeScript codegen. Each ship is one entry in `tools/blender/a4/ships.py`, checked by
`check_entry()` before the build (unknown keys, missing hard points for a weapon slot, backward aim, mount sizes outside the table all
stop the build). Hard points carry: mount name, size class, the weapon slot they serve, allowed weapon kinds, rest direction, firing arc,
and a muzzle marker.

**Firing arcs (radians from the rest direction, all keep guns from ever pointing backward):**

| Arc code (data.js) | Rest direction | Arc |
|---|---|---|
| F (forward) | along the bow | +-30 degrees |
| T (turret) | along the bow | +-135 degrees in yaw (never into the rear 90 degrees) |
| P / S (broadside) | out to the side, 15 degrees forward | 30 to 150 degrees from the bow on its side |

## 7. Hard point names (what the Godot effects helper attaches to)

Every ship glb has an empty node per hard point, child of the ship node, named:

- `hp_w<slot>_<kind>_<arc>_<n>`: weapon slot `<slot>` (0-based, the order of the ship's `w` list in data.js), e.g. `hp_w0_hbattery_P_1`.
  Node -Z points along the rest firing direction (Godot's forward), +Y away from the hull.
- `hp_eng_<n>`: engine exits. Node -Z points out of the bell (the plume direction, aft). `extras.radius` is the bell radius.
- `hp_bay_<n>`: hangar mouths (carriers): where craft launch, -Z is the launch direction.
- `hp_breach_<n>`: breach anchor candidates, spread over the open hull. +Y is the outward surface normal.
- `hp_core`: the hull's centre of mass (death explosion origin).

Each node's glTF `extras` repeats the data (kind, size, arc, slot, radius) for scripts.

## 8. The measurement pass (Oct 26, hulls_hi)

| Class | Hulls | Source triangles | Source maps | Length : width : height |
|---|---|---|---|---|
| Frigate | H7 V14 C13s B19 I14 D9 | 20,000 | 1024 | 1 : 0.18 to 0.97 : 0.23 to 0.69 |
| Destroyer | H8 V15 C14s B20 I11 D20 | 20,000 | 1024 | 1 : 0.17 to 0.84 : 0.19 to 0.38 |
| Cruiser | H9 V16 C15s B21 I15 D21 | 28,000 | 2048 | 1 : 0.16 to 0.94 : 0.17 to 0.50 |
| Carrier | V18 C16s B22 I16 | 38,000 | 2048 | 1 : 0.29 to 0.55 : 0.23 to 0.49 |
| Battleship | H10 V17 | 38,000 | 2048 | 1 : 0.19 to 0.23 : 0.23 to 0.26 |
| Flagships | V1b H4 C19 B16 I8 D22 | 38,000 | 2048 | 1 : 0.24 to 1.03 : 0.33 to 0.88 |
| Squadron | S1 S2 B23 | 2,400 | 512 | 1 : 0.37 to 1.10 : 0.26 to 0.30 |
| Objectives | O1 O2 O3 | 8,866 to 28,000 | 512 to 2048 | station flat disc, transport tube, beacon upright |

Orientation audit: two hulls were meshed side-on (I14_23, I15_11; the game turns them with AI_HULL_YAW). I8_37 and I16_11 stand their
sails upright and read oddly in the game (BACKLOG section 2): the A4 Ithar pass rebuilds their sails (see the Ithar notes in
`tools/blender/a4/README.md`). The beacon O3_11 is taller than long (by design: a mast structure).

**Budgets (no hard triangle caps, R and D5):** A4 ships land at about 2.5 to 4 times the source triangles (the A2 flagships were 4.1x),
plus wreck chunks. Textures: one 2048 atlas per ship in the repo (base, ORM, normal, emissive; about 4 to 7 MB a ship), and a 4096 set on
the PC for a max-detail option. Godot compresses them to VRAM formats on import.

## 9. The cyan baked-result gate

**Call:** dropped. Shields keep faction colours (R3), interface shield bars stay cyan in the UI only, and no faction hull, glow or trim is
cyan (Ithar's jade is green-leaning, Hegemony's blue is blue). Nothing for a gate to protect.

## 10. Wreck and death pieces

**Call:** every ship ships a `CODE_wreck.glb` beside it: the finished hull (same atlas, same textures) cut into 3 to 10 chunks by planes
through the hull (more across than along, so it breaks like a ship, not like a loaf), every cut capped with a scorched interior
material, each chunk its own node with its origin at its own centre of mass and its volume in `extras`. Documented in
`godot/assets/ships/README.md`.
