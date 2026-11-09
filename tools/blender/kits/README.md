# Faction parts kits

Ryan, Nov 9 2026 14:52 CST (FINDINGS R151): parts are NOT one shared kit. Every faction gets its own parts kit with its own shape
language; only invisible plumbing is shared. Hullbreakers scavenge, so their kit is a mismatched, salvaged mix that may borrow other
factions' parts, welded and patched.

```
tools/blender/kits/
  shared/plumbing.py      invisible plumbing only: ship frame and scale rules, mount sockets and seating on the real hull,
                          the gun-aim rule, tags the paint, LOD and export read, the one-pass audit. No shapes, no paint.
  hullbreakers/kit.py     the Ashfall Hullbreakers parts: casemate, bow_battery, drum_rack (drums), turret (own and borrowed),
                          marking (stencils, tags, lamps); salvage helpers (weld beads, patch plates, quilted sleeves)
  hullbreakers/paint.py   the Hullbreaker paint bands (red-forward, gunmetal-aft, heavy rust and grime, worn edges, markings)
  <faction>/kit.py        one per faction, same function shape: part(socket, seat, rnd), PARTS dict, build(sockets, seat)
  <faction>/paint.py      the faction's own bands and masks, same make / assign interface (bake, LOD, export are shared)
```

Faction ids (AGENTS.md): `corsair` = Ashfall Hullbreakers (`hullbreakers/`), `voidsworn` = Sunward Crusade, `ithar` = the
Glasswrights, `deathless` = Eclipse, `chorus` = the Chorus, `hegemony` = Hegemony Navy. Only `hullbreakers/` exists so far (issue
209 round 6 proves it on the C15s cruiser).

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
