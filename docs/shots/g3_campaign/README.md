# G3 campaign screenshots (Godot, Ryan's PC, RTX 5080, 2560x1377 window)

Taken by the campaign screenshot tour (`godot/scenes/campaign/campaign.tscn -- shots`) and the 3D map probe (`map3d_probe.tscn`). Each folder is named for the commit that drew it. Converted to WebP (quality 82) to keep the repo small; the PNGs stay on the PC in `voidsworn_test\shots\`.

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
