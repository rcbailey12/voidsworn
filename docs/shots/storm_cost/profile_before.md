# Issue 982: attribution before production edits

Recorded 2026-11-17T16:45:49.380620+00:00. world_living.gd SHA256: `983c2f2ab352c6aae01b22f655ec4e1ff5bd845b1d9b082a9aa4f914954b6dfa`.

Solo RTX 5080, seed 4103, 31 storm and 28 nebula hexes, PR 976 c170 view, live time, 4K. One diagnostic session, two passes per ablation; retain pass 2 after 180 warm frames, at least 720 measured frames and 8 seconds. These are independent full-scene removals; their differences are not additive.

| Tier | Variant | GPU median ms | Change from full ms |
|---|---|---:|---:|
| max | full | 17.844 | +0.000 |
| max | cards_off | 2.646 | -15.198 |
| max | storm_cards_off | 6.390 | -11.454 |
| max | nebula_cards_off | 14.216 | -3.628 |
| max | fog_off | 17.891 | +0.047 |
| max | fog_64 | 17.780 | -0.064 |
| max | lights_off | 17.881 | +0.037 |
| low | full | 22.721 | +0.000 |
| low | cards_off | 1.419 | -21.302 |
| low | storm_cards_off | 6.399 | -16.322 |
| low | nebula_cards_off | 17.823 | -4.898 |
| low | lights_off | 22.590 | -0.131 |

Actual live tree, before ablations:

- max: {"fog_injecting": 2, "fog_volumes": 7, "nebula_cards": 65, "omni": 4, "storm_cards": 72}
- low: {"fog_injecting": 0, "fog_volumes": 0, "nebula_cards": 93, "omni": 4, "storm_cards": 103}

cards_off hides only the gas MultiMeshes; storm_cards_off and nebula_cards_off isolate each gas family. fog_off hides only FogVolumes, retaining the tiny background haze. fog_64 changes the fog grid from 128x128 to 64x128. lights_off hides the four direct bolt lights and their fog injection while retaining bolt meshes and shader-driven cloud flashes.

Source cause to test: both card shaders evaluate multiple five-octave world-space noise fields before computing their thin height-layer support. Cards expand to three times their original width, shading large masked or empty regions repeatedly. Low has more cards than Max because it replaces fog with three puffs per hex. The fix will reject provably empty support before noise and reduce the dim low-tier bottom puffs. The Max fog grid, volumes and bolt lights will stay as measured.
