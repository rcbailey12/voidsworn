# Playbook: the one scale table

Issue 710, FINDINGS R247 (Ryan, Nov 14 2026): "On nebula/storm/asteroid hexes, can you add something to it that makes it
feel scalable and realistic in size? Right now a nebula might be 1 or 2 hexes and look super small next to a ship. The scale
is all off and it feels very odd. Same with stations. Let's ensure everything makes sense with scale of their model and
their hex." This file is the single table every board object is sized against. The check beside it
(godot/render/test/scale_check.gd) reads the live values from the code and fails when an object leaves its target range.

## 1. The unit

- One board unit is one world unit. `HEX_S = 10` is the corner radius (godot/render/hull_table.gd).
- A hex is 20.00 across its corners and 17.32 across its flats. A ship is drawn at its hull length (hull table
  `length_for`: `HULL_LEN` when present, else `CLS_LEN`) times `SHIP_K = 1.6`; a wing craft adds `SQUADRON_K = 1.5`.
- The glb manifest (godot/assets/ships/manifest.json) carries each hull's `length_world`. The check proves every hull's
  `length_world` equals its hull-table length, so the table and the glbs agree and the drawn length below is the real one.
  A17 (`C15s_23`) is 14.6, claw tip to stern, as approved in R229 and recorded in its build sheet; other cruisers keep 14.5.
- Sizes are the object's long axis (length or diameter) on the board, or on the campaign map where the row says map.
  Map units are a separate scale and are only compared with each other, never with board units.

## 2. The table

Every row is in board units against HEX_S = 10 unless it says map. "Today" is what the code draws now (measured from the
live constants and the glbs, not estimated). "Target" is the R247 range the check enforces. The last column says why.

| Kind | Object | Today | Target | Why |
|---|---|---|---|---|
| Ship | Transport | 17.60 | 8.00 to 100.00 | a class length; transports sit between a destroyer and a cruiser |
| Ship | Frigate | 10.40 | 8.00 to 100.00 | fills most of its hex, the baseline small hull |
| Ship | Destroyer | 15.20 | 8.00 to 100.00 | a third longer than a frigate |
| Ship | Cruiser | 23.20 | 8.00 to 100.00 | overhangs its hex, the first capital frame |
| Ship | A17 Hullbreaker cruiser | 23.36 | 8.00 to 100.00 | R229's approved claw-tip-to-stern length, matching the installed export |
| Ship | Carrier | 26.40 | 8.00 to 100.00 | a cruiser's hull with a flight deck |
| Ship | Battleship | 33.60 | 8.00 to 100.00 | a capital that clearly outweighs a cruiser |
| Ship | Dreadnought | 43.20 | 8.00 to 100.00 | a heavy capital, the largest common line |
| Ship | Super-dreadnought | 49.60 | 8.00 to 100.00 | the biggest class; every other size is checked against it |
| Ship | Battle-barge | 41.60 | 8.00 to 100.00 | a dreadnought-weight barge |
| Ship | Bio-titan | 44.80 | 8.00 to 100.00 | a living capital at dreadnought weight |
| Ship | Ark | 41.60 | 8.00 to 100.00 | a carrier-weight ark |
| Ship | Tomb-ark | 44.80 | 8.00 to 100.00 | a dreadnought-weight tomb-ark |
| Squadron | Fighter | 3.84 | 2.00 to 6.00 | tiny beside a frigate (under half its length, 5.20) |
| Squadron | Bomber | 3.84 | 2.00 to 6.00 | same wing frame as a fighter, only its load differs |
| Station | Station, one hex | 26.00 | 99.20 to 297.60 | must dwarf every ship class, so at least twice the super-dreadnought |
| Station | Station, five or more hexes | 46.00 | 99.20 to 297.60 | the big cluster must dwarf the fleet too |
| Terrain | Nebula, one-hex cloud | 83.00 | 74.40 to 297.60 | much larger than any ship and spilling past its hex |
| Terrain | Nebula, tying veil | 138.00 | 20.00 to 297.60 | the faint high veil still spans more than a hex |
| Terrain | Ion storm, one-hex cloud | 83.00 | 74.40 to 297.60 | a dark vast mass, not a puff the size of a frigate |
| Terrain | Asteroid field, biggest rock | 15.20 | 20.80 to 83.20 | the biggest rock dwarfs a frigate |
| Terrain | Debris, biggest piece | 5.60 | 1.00 to 10.40 | rubble and torn plate stay smaller than the smallest hull |
| Terrain | Board planet, diameter | 100.00 | 80.00 to 992.00 | a world cap reads bigger than the fleet beside it |
| Wreck | Board hulk | 11.00 | 7.60 to 18.24 | a wreck keeps half to all of the destroyer hull it was |
| Explosion | Death core flash, Transport | 28.17 | 5.28 to 52.80 | sized to its ship (small band) |
| Explosion | Death core flash, Frigate | 28.17 | 3.12 to 31.20 | sized to its ship (small band) |
| Explosion | Death core flash, Destroyer | 33.25 | 4.56 to 45.60 | sized to its ship (destroyer band, issue 463) |
| Explosion | Death core flash, Cruiser | 39.38 | 6.96 to 69.60 | sized to its ship (cruiser band) |
| Explosion | Death core flash, Carrier | 55.16 | 7.92 to 79.20 | sized to its ship (capital band) |
| Explosion | Death core flash, Battleship | 55.16 | 10.08 to 100.80 | sized to its ship (capital band) |
| Explosion | Death core flash, Dreadnought | 55.16 | 12.96 to 129.60 | sized to its ship (capital band) |
| Explosion | Death core flash, Super-dreadnought | 55.16 | 14.88 to 148.80 | sized to its ship (capital band) |
| Explosion | Death core flash, Battle-barge | 55.16 | 12.48 to 124.80 | sized to its ship (capital band) |
| Explosion | Death core flash, Bio-titan | 55.16 | 13.44 to 134.40 | sized to its ship (capital band) |
| Explosion | Death core flash, Ark | 55.16 | 12.48 to 124.80 | sized to its ship (capital band) |
| Explosion | Death core flash, Tomb-ark | 55.16 | 13.44 to 134.40 | sized to its ship (capital band) |
| Explosion | Big hit blast, Transport | 10.20 | 3.52 to 35.20 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Frigate | 10.20 | 2.08 to 20.80 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Destroyer | 10.20 | 3.04 to 30.40 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Cruiser | 11.60 | 4.64 to 46.40 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Carrier | 13.20 | 5.28 to 52.80 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Battleship | 16.80 | 6.72 to 67.20 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Dreadnought | 21.60 | 8.64 to 86.40 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Super-dreadnought | 24.80 | 9.92 to 99.20 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Battle-barge | 20.80 | 8.32 to 83.20 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Bio-titan | 22.40 | 8.96 to 89.60 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Ark | 20.80 | 8.32 to 83.20 | a torpedo's ring and dust, sized to its ship |
| Explosion | Big hit blast, Tomb-ark | 22.40 | 8.96 to 89.60 | a torpedo's ring and dust, sized to its ship |
| Map | Fleet marker, flagship | 8.50 | 1.30 to 4.00 times its escort (4.60) | the flagship reads bigger than an escort |
| Map | Station node, shipyard | 6.40 | 12.75 to 51.00 | a station node must be larger than the fleet marker |
| Map | Nebula region | 66.00 | 4.80 to 200.00 | a nebula region is much larger than a stop's ring |
| Map | Nebula region vs fleet | 7.76 times | 2.00 to 40.00 times | a nebula region is larger than the fleet marker |

How today's values are read (the check reads the same constants):

- Ships: `length_for(code, class) * SHIP_K`; fighters and bombers `CLS_LEN["Squadron"] * SHIP_K * SQUADRON_K`
  (godot/render/hull_table.gd, godot/render/ship_view.gd).
- Station: `STATION_BASE_LEN + STATION_PER_HEX * hexes` or `STATION_BIG_LEN` (godot/render/board.gd).
- Nebula and storm: `cloud_span()` samples the actual isolated-hex soft footprint at mask alpha above 0.001,
  rather than the enclosing card rectangle. Default max volumes and high/low cards share this 83-unit mask.
  `GAS_VEIL_MAX * GAS_CLOUD_SCALE` is the enclosing veil width (godot/world/world_living.gd).
  The fog box is 96 units wide and 38.5 high, from y -7 to 31.5 (about two hex corner diameters).
  Route A is the default after Ryan's R270 pick. `VS_NEBULA_ROUTE=today` is historical bench reproduction only.
- Asteroid: `BLOCKER_SCALE_MAX * rock long axis`; the rock library's longest axis is 2.0 (godot/world/world.gd,
  godot/world/rocks/rocks.json).
- Debris: `DEBRIS_ROCK_MAX * rock long axis` (godot/world/world_living.gd).
- Planet: `2 * (PLANET_R_DEFAULT * PLANET_EDGE_K * HEX_S + HEX_S / 2)`, the battle.js planetEdge rule
  (godot/render/board.gd).
- Wreck: `HULK_SCALE` (godot/render/board.gd).
- Death flash: `CORE_FLASH_PX[band] * STAGING_UNITS_PER_PIXEL`; the band is the class's death tier
  (godot/fx/fx_death.gd, godot/fx/fx_ship.gd).
- Big hit: `BIG_HIT_RING * max(scale_k, VIS_K_HIT)` (godot/fx/fx_weapons.gd, godot/fx/fx_ship.gd).
- Map: `RING_R`, `TOKEN_FLAGSHIP_LEN`, `TOKEN_ESCORT_LEN`, `SHIPYARD_LEN`, `REGION_NEBULA_SPREAD` and
  `CLOUD_PUFF_MAX` (godot/ui/campaign/map3d.gd, godot/ui/campaign/map3d_system.gd).

## 3. What is still wrong today

These rows fail today; they are the acceptance test for the three sizing jobs. scale_check.gd lists them as KNOWN (each
naming its job), so the check stays green and guards every other row; every other row in the table passes.

| Object | Today | Target | Waiting on |
|---|---|---|---|
| Station, one hex | 26.00 | 99.20 to 297.60 | issue 373 (the station) |
| Station, five or more hexes | 46.00 | 99.20 to 297.60 | issue 373 (the station) |
| Asteroid field, biggest rock | 15.20 | 20.80 to 83.20 | issue 369 (planet and rocks) |
| Map station node, shipyard | 6.40 | 12.75 to 51.00 | issue 373 (the station) |

When issue 368, 369 or 373 lands, it changes the live size in the code named in section 2 (never a copy of the table) and
this check's row turns PASS; the same change deletes the row's line from KNOWN in scale_check.gd (a KNOWN row that passes
fails the check until it is deleted). It cannot drift back: the check is in godot/tools/ci/godot_checks.txt and runs in
the Godot checks.

## 4. Checks

- `godot --headless --path godot --script res://render/test/scale_check.gd` prints one line per object and exits 1 when
  an object outside the KNOWN list leaves its target range, or a KNOWN row passes.
- It is listed in godot/tools/ci/godot_checks.txt, so GitHub and godot/tools/ci/run_checks.sh run it with every other
  headless Godot check.
- Any new board object that has a size (a new terrain kind, a new station type, a new explosion) adds a row here and a
  check line in scale_check.gd in the same change.

## 5. Hazard edges and the board floor (Ryan, Nov 20 2026)

Ryan, Nov 20 01:11 UTC ("Picks ok", Board thread), on the backdrop audit check
(/mnt/project-files/audits/neon_1119/backdrop_audit_check_1120.md):

- **Clouds stay big; the hazard edge is drawn.** A nebula or ion storm cloud keeps spilling past its hexes (section 2,
  R247), so the cloud itself does not mark where cover or shield drain stops. The normal battle view (cine) draws a faint
  outline along the outer edge of each nebula and storm patch only (no inner hex lines, no debris or rock edges); Z keeps
  the full tactical outlines. Why: the clouds reach about 2.4 hexes from a hazard hex centre, so players could not tell
  where the rules edge was without Z. Job: issue 1267.
- **Solid and cover rims on hover; reach hatching only with Z (Ryan, Nov 20 2026, issue 1359 thread).** Ryan picked
  option B of issue 1359 at 17:30 UTC ("can we do b but have it only show up when you hover over it in cinematic mode and
  then when you have the full grid ... it shows by default"): an amber rim round solid ground (rock, hulk, station and
  the map's set-piece holes; the planet and station exclusion colour) and a softer tan rim round debris cover. In cine
  only the patch under the cursor shows its rim; Z shows every patch. At 17:57 UTC he picked "Only with Z" for the enemy
  reach hatching (issue 271): cine draws none, Z draws it board-wide. Why: at c170 a hulk looked like a bigger piece of
  the debris around it, and the board-wide hatching blurred into far-off grid lines that came and went with the Move
  step (Neon backdrop audit H4). Code: godot/render/board.gd, godot/world/board_look.gd.
- **No dark scrim under the board.** The cine look keeps underlay 0.0 (godot/world/board_look.gd); readability over
  bright skies is solved by the hazard outline and the sky, not a mat under the hexes. Why: a scrim brings back the
  board-game plate RULEBOOK 10.1 rules out (R70).

## 6. One line style (Ryan, Nov 20 2026, R362)

Every line drawn on or over the battle board shares one style: one helper owns width by camera distance, glow and fade,
and callers pass only a role (grid, move, terrain or hazard edge, torpedo lane, target marker); the role sets the colour
from one table. Storm lightning plays baked bolt flipbooks (issue 1360: `tools/blender/vfx/bake_storm_bolts.py`, atlases
in `godot/fx/atlases/storm/`) and keeps only its colours from this table (`bolt_core`, `bolt_skirt`, `bolt_corona`);
`VS_STORM_BOLTS=ribbon` brings back the old ribbon for before shots. The picks above still
hold (faint grid near ships, hazard outline in cine, debris rims on hover). Why: the grid, terrain edges, torpedo lanes
and lightning each chose their own width, glow and colour, so the board read as four different games. Job: issue 1374.

How it works (issue 1374): `godot/render/line_style.gd` is the one place to change a line. Its `ROLE` table holds every
line colour and strength (grid per look, move hexes and path, hover, threat, targets, blocked shots, each terrain, hazard
and objective edge, the solid rim, storm bolt colours). Its constants set the width rule
(`CORE_W` world units up close, never under `CORE_PX` screen pixels), the fade law (a line the pixel floor widens dims in
step, `WIDEN_DIM`), the glow band (`GLOW_W`, starting at `GLOW_K` of the core) and the edge shimmer (`BREATH`). Grid,
target and hover rings are core only (no glow), so the grid stays faint. Shaders include `LS.GLSL`; meshes use
`LS.strip_into` and `LS.material`. Never add a line with its own width, glow or colour: add a role. Torpedo lanes and
their hex marker are not in it: Ryan picked torpedoes that hit in the same shot with no lane (issue 1379). Check:
`godot/render/test/line_style_check.gd`.
