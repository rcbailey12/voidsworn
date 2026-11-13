# Faction parts kits

Ryan, Nov 9 2026 14:52 CST (FINDINGS R151): parts are NOT one shared kit. Every faction gets its own parts kit with its own shape
language; only invisible plumbing is shared. Hullbreakers scavenge, so their kit is a mismatched, salvaged mix that may borrow other
factions' parts, welded and patched.

```
tools/blender/kits/
  shared/plumbing.py      invisible plumbing only: ship frame and scale rules, mount sockets and seating on the real hull,
                          the gun-aim rule, tags the paint, LOD and export read, the one-pass audit. No shapes, no paint.
  shared/turrets.py       the turret marking in a blend (issue 560): which meshes turn, about which pivot (see below)
  hullbreakers/kit.py     the Ashfall Hullbreakers parts: casemate, bow_battery, drum_rack (drums), turret (own and borrowed),
                          marking (stencils, tags, lamps); salvage helpers (weld beads, patch plates, quilted sleeves)
  hullbreakers/paint.py   the Hullbreaker paint bands (red-forward, gunmetal-aft, heavy rust and grime, worn edges, markings)
  <faction>/kit.py        one per faction, same function shape: part(socket, seat, rnd), PARTS dict, build(sockets, seat)
  <faction>/paint.py      the faction's own bands and masks, same make / assign interface (bake, LOD, export are shared)
```

Faction ids (AGENTS.md): `corsair` = Ashfall Hullbreakers (`hullbreakers/`), `voidsworn` = Sunward Crusade, `ithar` = the
Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Hegemony Navy. Kits so far: `hullbreakers/` (issue 209
round 6 proves it on the C15s cruiser), `eclipse/` (issue 532, the E11 and E12 sheets) and `chorus/` (issue 623, the C10 and C11
sheets: grown parts, weapons as organs; its README says what each part is and does).

## What is shared and what is not

| Shared (plumbing) | Per faction (look) |
|---|---|
| ship frame: x to the bow, y to port, z up, length 1.0 | every part's shape: profiles, proportions, panelling, greebles |
| scale classes (`SCALE`): barrel radius, mount footprint, drum radius, LOD drop sizes | which part families exist (a Glasswright kit has no drum racks) |
| sockets: a part's position, the hull normal it sits on, its aim, its side, mirrored pairs | how pairs differ in detail (Hullbreakers: patches and welds never match) |
| seating by ray cast on the real hull (`Seat.flank`, `Seat.top`, `resolve`) | the paint bands, colours, wear and markings |
| rules: guns never aim backward or into the ship, no part across a break line, nothing floats | borrowed parts (a Hullbreaker kit may weld on another navy's turret) |
| tags read by the bake, LOD and export: role (part, trim, dark, glow, decal), kind, size | |
| bake, LOD chain and export scripts (tools/blender/r209: bakeAb6.py, export3.py) | |

## How a ship uses a kit

A ship's placement file, `tools/recipe/ships/<ship>.json`, names its faction and lists sockets: part, seat mode (`flank`: find the
hull side at x, z; `top`: find the deck at x, y), position, aim, size, `pair` for a mirrored starboard twin, and `variant` /
`variant_s` for each twin's own salvage detail. The hull module builds the hull, then `kit.build(sockets, seat)` builds the
weapons and returns any gun aimed against the rules (must be empty). See `docs/ship_pipeline/RECIPE.md`.

## How a kit marks a turret (issue 560; RULEBOOK 6.17)

Ryan, Nov 11 2026 (R219): "I agree with your design on turrets": turret guns turn to face their target when they fire; fixed
side guns (casemates, broadside batteries) stay fixed. Every faction kit builds a turret so the game can turn it:

- Split the turret into what stays on the hull (the ring, its bolts, welds to the deck) and what turns (housing, mantlet,
  breeches, barrels, muzzle brakes, anything on the housing). The turning part turns about the mount normal through the ring
  centre, so model it round that axis: at its rest aim nothing may sit inside another part, and the fit check sweeps it.
- Mark it in one of two ways (the Blender side is `shared/turrets.py`; the game contract is docs/ship_pipeline/HARDPOINTS.md
  "Turrets"):
  1. while building, add an empty `<id>_turret` at the ring centre on the ring's top face, local +Z the mount normal, local +X
     the rest aim, with properties `turret=1`, `slot`, `weapon`, `arc_lo`, `arc_hi` (bearings from the bow in degrees, + to
     port; the rules' arc unless the kit's own is narrower), `rest_yaw`, `rest_pitch`, and parent the turning meshes to it
     (the build-sheet kit, `tools/blender/build_sheets/kit.py` `emit(pivot=...)`, issue 532);
  2. or name the turning pieces `<socket><piece>` and list the pieces in `TURRET_TURN` in the kit's `kit.py`; stage 7 marks
     each socket whose part is `turret` from that list (the recipe kit here, `hullbreakers/kit.py`).
- Register each barrel's muzzle with `plumbing.register_gun(..., tip=..., socket=<the turret's socket or id>)`, so the export
  hangs that muzzle under its turret and the flash leaves the turned barrel.
- A casemate, sponson or broadside battery is never marked. Its muzzles stay on the ship node and never move.

Hulls built before issue 560 keep fixed guns: the 36 A4 hulls (one baked mesh, one material; `hp_w` points only) and the round 7
export of C15s_23 now in the game build. The recipe cruiser gets turning turrets from a stage 7 re-export of its baked blend
(the kit's `TURRET_TURN` marks turA and turS), no rebuild needed.
