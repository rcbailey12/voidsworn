HISTORY (marked Nov 11 2026): the Oct 22 status of the 36 old AI hulls in the frozen browser game (AI_HULLS in ships3d.js); browser-era history, not the Godot product. The 36 old concepts are history, not targets (docs/playbooks/ships.md section 1), and "Ithar have sails" contradicts the Glasswright Never list (docs/playbooks/factions.md). Where each faction stands now: docs/playbooks/factions.md, "The concept redo". The live ship method is docs/playbooks/ships.md section 0 and docs/ship_pipeline/RECIPE.md; the rules are docs/RULEBOOK.md sections 4 and 5. Kept for history; do not follow.

# Ship queue

Every AI hull in the game (`AI_HULLS` in ships3d.js) and where it stands in the pipeline (`README.md`).
Priority 1 = capitals, flagships and the station: the biggest on screen, so Ryan zooms in on them. 2 = escorts. 3 = squadron craft (tiny on screen;
a lighter pass may do). Faction notes:
- Corsair may stay junky (bolt-ons haphazard, paint mismatches fine).
- Chorus are living bio-ships (no bolt-on guns; veins and sacs glow) and Ithar have sails and pale hulls. For those the sweep is about
  crisp silhouettes and clean organic forms, not mechanical parts. Ask Ryan before inventing a hand-built style for them.

Steps: V = views approved, M = Pixal3D mesh, P = paint projected, K = hand-built kit, G = in game, S = blob sweep passed (`BLOB_SWEEP.md`).

| Pri | Faction | Class | Code | Status | V | M | P | K | G | S | Blob sweep notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | chorus | Carrier | B22_11 | not started |  |  |  |  |  |  |  |
| 1 | chorus | Bio-titan | B16_23 | not started |  |  |  |  |  |  |  |
| 1 | corsair | Carrier | C16s_23 | not started |  |  |  |  |  |  |  |
| 1 | corsair | Battle-barge | C19_51 | v13d Oct 22: clean shell hull (owner OK'd shape), sponsons + front armour, weathered paint, detail_lib pass (plating, patches, pipes, vents, dents, Corsair jank), atlas gap fill, hull lighting fixed; v14 (Oct 22): mixed-shape trimmed plating, belly slabs, uneven rows, baked finish maps; awaiting owner verdict | x | x | x | x | x |  | bow, rack, bridge, guns, side blocks, plates, thrusters, stern house, tanks rebuilt; big flat hull panels still AI |
| 1 | deathless | Tomb-ark | D22_23 | not started |  |  |  |  |  |  |  |
| 1 | hegemony | Battleship | H10_23 | not started |  |  |  |  |  |  |  |
| 1 | hegemony | Super-dreadnought | H4_11 | not started |  |  |  |  |  |  |  |
| 1 | ithar | Carrier | I16_11 | not started |  |  |  |  |  |  |  |
| 1 | ithar | Ark | I8_37 | not started |  |  |  |  |  |  |  |
| 1 | obj | station | O1_37 | not started |  |  |  |  |  |  |  |
| 1 | voidsworn | Battleship | V17_37 | not started |  |  |  |  |  |  |  |
| 1 | voidsworn | Dreadnought | V1b_r_23 | not started |  |  |  |  |  |  |  |
| 1 | voidsworn | Carrier | V18_51 | not started |  |  |  |  |  |  |  |
| 2 | chorus | Frigate | B19_11 | not started |  |  |  |  |  |  |  |
| 2 | chorus | Destroyer | B20_11 | not started |  |  |  |  |  |  |  |
| 2 | chorus | Cruiser | B21_11 | not started |  |  |  |  |  |  |  |
| 2 | corsair | Frigate | C13s_23 | not started |  |  |  |  |  |  |  |
| 2 | corsair | Destroyer | C14s_23 | not started |  |  |  |  |  |  |  |
| 2 | corsair | Cruiser | C15s_23 | not started |  |  |  |  |  |  |  |
| 2 | deathless | Frigate | D9_23 | not started |  |  |  |  |  |  |  |
| 2 | deathless | Destroyer | D20_23 | not started |  |  |  |  |  |  |  |
| 2 | deathless | Cruiser | D21_23 | not started |  |  |  |  |  |  |  |
| 2 | hegemony | Frigate | H7_23 | not started |  |  |  |  |  |  |  |
| 2 | hegemony | Destroyer | H8_23 | not started |  |  |  |  |  |  |  |
| 2 | hegemony | Cruiser | H9_23 | not started |  |  |  |  |  |  |  |
| 2 | ithar | Frigate | I14_23 | not started |  |  |  |  |  |  |  |
| 2 | ithar | Destroyer | I11_37 | not started |  |  |  |  |  |  |  |
| 2 | ithar | Cruiser | I15_11 | not started |  |  |  |  |  |  |  |
| 2 | obj | transport | O2_37 | not started |  |  |  |  |  |  |  |
| 2 | obj | beacon | O3_11 | not started |  |  |  |  |  |  |  |
| 2 | voidsworn | Frigate | V14_23 | not started |  |  |  |  |  |  |  |
| 2 | voidsworn | Destroyer | V15_37 | not started |  |  |  |  |  |  |  |
| 2 | voidsworn | Cruiser | V16_37 | not started |  |  |  |  |  |  |  |
| 3 | craft | fighter | S1_51 | not started |  |  |  |  |  |  |  |
| 3 | craft | bomber | S2_23 | not started |  |  |  |  |  |  |  |
| 3 | craft | spore | B23_51 | not started |  |  |  |  |  |  |  |

Concept paintings: `Downloads\voidsworn_meshes\picks\` on Ryan's PC (file names carry the code). When several concept options were good Ryan leaned to `_51`.
