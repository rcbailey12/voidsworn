# G3 campaign screenshots (Godot, Ryan's PC, RTX 5080, 2560x1377 window)

Taken by the campaign screenshot tour (`godot/scenes/campaign/campaign.tscn -- shots`) and the 3D map probe (`map3d_probe.tscn`). Each folder is named for the commit that drew it. Converted to WebP (quality 82) to keep the repo small; the PNGs stay on the PC in `voidsworn_test\shots\`.

## 9416dff (R51 round 2: stop objects at full finish, the black hole, sci-fi headers, label priority)

One PC job (`queue\g3_r51d_9416dff.bat`): `before_*` is 9ef9b85 (the first R51 set Ryan saw), `after_*` is 9416dff; same seed, window and angles. The map shots are `m1` to `m5` as before. The close-ups come from `stops_probe.tscn` (the same camera offset for each kind of stop; close-ups resized to 1920 wide):

| File | Stop |
|---|---|
| `*_s_sun` | the Hollow Sun (before: the dead star and fire ring; after: the black hole with its disc, lensed arcs and photon ring) |
| `*_s_planet` | a planet-edge fight (atmosphere limb, clouds, moon on its orbit) |
| `*_s_station` | an orbital-station fight (after: the procedural station) |
| `*_s_belt` | an asteroid-belt fight (after: displaced rocks with craters along the orbit) |
| `*_s_wreck` | a ship-graveyard fight (after: A4's real death pieces) |
| `*_s_nebula` | an ion-storm fight (nebula pocket) |
| `*_s_shipyard` | a shipyard (after: gantry, crane, floodlights, a hull being built) |
| `*_s_drydock` | a drydock (after: dock frame, clamps, work lights, drones) |
| `*_s_field` | field repairs (after: tender with lattice arms and drones) |
| `*_s_event` | an unknown signal |
| `*_s_flagship` | the sector flagship |

Since 9416dff (not in these shots): lattice members drawn as one MultiMesh each, slimmer bars, crisper lensed arcs, calmer drone plating, and the fleet, shipyard and battle pages now sit over the dimmed star system.

## 9ef9b85 (R51 star system, first before and after set)

One PC job (`queue\g3_r51_9ef9b85.bat`) drew both: `before_*` is the map at 1edd967 (the round 2 map Ryan saw), `after_*` is 9ef9b85, same seed (4242), same window, same angles (`campaign.tscn -- mapshots` and `map3d_probe.tscn`).

| File | Shot |
|---|---|
| `before_m1_map`, `after_m1_map` | the start of a run, sector I, settled camera |
| `before_m2_hover`, `after_m2_hover` | the hover card over a fight in the middle of the sector, with the safest and richest routes lit |
| `after_m3_zoom` | zoomed in toward the first jump (the old map had no zoom) |
| `after_m4_low` | Map detail: Low (the same system with fewer stars, clouds and debris) |
| `before_m5_sector2`, `after_m5_sector2` | the start of sector II (the Nemesis clock is full, so every fight is his) |
| `before_map3d_route`, `after_map3d_route` | the probe's route planner shot, another frame |
| `before_map3d_flying`, `after_map3d_flying` | the fleet in flight on its first jump |

Known for the next round: ship hulls (stations, the fleet, the flagship, patrols) read too small at this zoom; label stacks can still touch where stops crowd (a de-overlap pass is in the next commit); a Nemesis crest prints beside every one of his fights when the clock is full.

## 89fb977 (3D map round 2, stream B screens, the Nemesis face)

| File | Screen |
|---|---|
| `07_map.webp`, `08_map.webp` | the 3D sector map, sector I, start of a run (08 is a second frame of the same map) |
| `map3d.webp` | the 3D map probe, another seed |
| `map3d_route.webp` | the probe after hovering a node for the route planner (the planner found no route through that node in this shot) |
| `06_intro.webp` | the sector intro dialog over the map |
| `20_sector.webp` | the sector change dialog (sector II) with toasts |
| `04_admiral.webp` | faction, admiral and run options |
| `09_fleet.webp` | the fleet screen |
| `21_shipyard.webp` | a shipyard |
| `17_event.webp` | an event |
| `15_boon.webp` | a boon offer |
| `99_end.webp` | the run's end screen |

## 06b96d7 (Nemesis v2 card, intel strip, key, framing; story hooks not yet in that PC build)

Same files as above, plus `13_prize.webp` and `14_boon.webp`. What changed on screen: an opaque war-room panel; the Nemesis card with persona, strengths and their effects, his faction behaviour, the clock with its count, riches, weaknesses with how to learn them; the intel strip with the sector condition's effect, a Progress box and the run's Heat rules; a key that says what each stop gives and the danger bands; the fleet token is the flagship's real hull with two escorts.

Two capture faults in this set, fixed for the next one (262bb28): `07_map`, `08_map` and `map3d` were taken while the arrival camera was still leaning in on the fleet (so the chart looks zoomed and runs under the panel; settled, the framing keeps every stop left of the panel, checked in the cloud), and the probe's mouse warp cleared the hovered node in `map3d_route` (no route drawn). The PC build had no `godot/story/` yet at capture time, so the story lines, Rename and Career buttons do not show.
