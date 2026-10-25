# Engine test round 3, Oct 25 2026 (Ryan's PC, RTX 5080)

Babylon 9.30.0 at f6e850f; Godot 4.7.2 at 45da251 (fp Forward+, gl Compatibility); Godot exported .exe (109 MB) cold and warm 5 s runs. Max mode on today's assets (max-detail ships not in yet). Uncapped frame times; the vsync runs come next round.

| file | mode | height | avg ms | worst 1% ms | max ms | load s |
|---|---|---|---|---|---|---|
| babylon930_board_1440.json | board | 1440 | 2.465 | 6.759 | 54.1 | 6.261 |
| babylon930_board_2160.json | board | 2160 | 3.574 | 15.77 | 63.7 | 6.31 |
| babylon930_main_1440.json | main | 1440 | 0.638 | 9.439 | 12.4 | 3.205 |
| babylon930_main_2160.json | main | 2160 | 1.084 | 20.442 | 36.5 | 3.705 |
| babylon930_max_1440.json | max | 1440 | 2.624 | 8.293 | 11.6 | 6.316 |
| babylon930_max_2160.json | max | 2160 | 4.994 | 26.515 | 31.3 | 6.403 |
| babylon930_ships40_1440.json | ships40 | 1440 | 2.124 | 5.238 | 10 | 5.836 |
| babylon930_ships40_2160.json | ships40 | 2160 | 2.606 | 14.987 | 18.8 | 5.676 |
| babylon930_stress_1440.json | stress | 1440 | 1.427 | 8.95 | 12.6 | 4.61 |
| babylon930_stress_2160.json | stress | 2160 | 1.951 | 21.312 | 25.3 | 4.786 |
| godot3_fp_1440_board.json | board | 1440 | 1.621 | 3.143 | 7.751 | 4.241 |
| godot3_fp_1440_main.json | main | 1440 | 1.162 | 1.941 | 7.072 | 3.496 |
| godot3_fp_1440_max.json | max | 1440 | 4.096 | 6.595 | 8.506 | 5.487 |
| godot3_fp_1440_ships40.json | ships40 | 1440 | 4.252 | 6.743 | 9.379 | 4.308 |
| godot3_fp_1440_stress.json | stress | 1440 | 2.532 | 4.384 | 7.509 | 3.979 |
| godot3_fp_2160_board.json | board | 2160 | 2.733 | 4.481 | 6.422 | 4.609 |
| godot3_fp_2160_main.json | main | 2160 | 2.209 | 3.147 | 7.814 | 3.683 |
| godot3_fp_2160_max.json | max | 2160 | 6.666 | 9.099 | 12.535 | 5.495 |
| godot3_fp_2160_ships40.json | ships40 | 2160 | 4.464 | 7.486 | 10.279 | 4.359 |
| godot3_fp_2160_stress.json | stress | 2160 | 3.377 | 5.142 | 9.67 | 3.911 |
| godot3_gl_1440_main.json | main | 1440 | 1.629 | 3.083 | 6.887 | 3.037 |
| godot3_gl_1440_stress.json | stress | 1440 | 3.892 | 6.537 | 8.602 | 3.48 |
| godot3_gl_2160_main.json | main | 2160 | 2.093 | 3.687 | 5.42 | 4.957 |
| godot3_gl_2160_stress.json | stress | 2160 | 4.363 | 6.91 | 8.397 | 3.431 |
| godot_exe_cold.json | main | 1440 | 1.204 | 2.746 | 30.553 | 3.706 |
| godot_exe_warm.json | main | 1440 | 1.183 | 2.094 | 6.4 | 3.179 |
