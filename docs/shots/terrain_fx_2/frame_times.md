# Terrain effects 2: measured frame times

Solo GPU; fixed c170 beta 0.98; idle real battle; no HUD; live presentation time; 180 warm frames before each of two passes; at least 720 measured frames and 8 seconds per pass; retain pass 2. 4K is 2x 3D scaling in a 1920x1080 viewport.

Eight or nine installed ships are present, as recorded per row. The graveyard uses seed 4107 and 40 debris hexes. The storm uses seed 4103 with the real terrain generator adding a nebula sector condition: 31 storm and 28 nebula hexes. These are terrain planning views, not a combat or scene-207 gate result.

| Map | Quality | Resolution | Frame median ms | Frame p95 ms | GPU median ms | Frames |
|---|---|---|---:|---:|---:|---:|
| graveyard | max | 1080p | 3.682 | 3.735 | 3.362 | 2165 |
| graveyard | max | 4K | 6.979 | 7.014 | 6.649 | 1145 |
| graveyard | low | 1080p | 2.599 | 2.632 | 2.287 | 3074 |
| graveyard | low | 4K | 5.142 | 5.168 | 4.808 | 1555 |
| storm | max | 1080p | 4.767 | 4.792 | 4.428 | 1677 |
| storm | max | 4K | 16.710 | 16.759 | 16.359 | 720 |
| storm | low | 1080p | 5.739 | 5.776 | 5.415 | 1392 |
| storm | low | 4K | 21.549 | 21.612 | 21.209 | 720 |

Max uses MSAA 4x and the existing fog route. Low uses FXAA and the existing cloud-card route. No new point lights are added.

| Map | Quality | Omni lights | Fog-injecting lights | Fog volumes |
|---|---|---:|---:|---:|
| graveyard | max | 0 | 0 | 2 |
| graveyard | low | 0 | 0 | 0 |
| storm | max | 4 | 2 | 7 |
| storm | low | 4 | 0 | 0 |

The stacking storm retains four bolt lights, with two injecting fog at max; no separate nebula point light is present. Graveyard has no terrain point lights. Counts are taken from the actual world tree.

The existing low storm path is slower than max here and exceeds the 16.7 ms 4K goal. The accepted storm shaders, card counts and bolt code are unchanged by this job. This report records that limitation; it does not claim a passed scene-207 gate or redesign the storm ladder.

[Statistics for both passes](frame_times.json). Captures use a solo claim from tools/pc/gpu_slots.js through tmo.bat.
