# Engine test final round, Oct 25 2026 (Ryan's PC, RTX 5080, 240 Hz monitor)

Babylon 9.30.0 at c10dc4d (fb_*); Godot 4.7.2 at 20831b0 (fg_fp Forward+, fg_gl Compatibility). Max-detail 8K ships in assets/hi. CAUTION: Babylon's max mode did not load assets/hi in this round (a build bug, being fixed), so fb_max_* used the old assets and are not comparable; Godot's max load (38 s) is runtime glTF import of uncompressed 8K textures, which an imported Godot project would not pay. *_vsync files are capped to the 240 Hz display.

| file | engine | mode | height | avg ms | worst 1% ms | max ms | load s | dropped | refresh |
|---|---|---|---|---|---|---|---|---|---|
| fb_board_1440.json | babylon | board | 1440 | 2.485 | 6.348 | 67.6 | 6.631 | None | None |
| fb_board_2160.json | babylon | board | 2160 | 3.591 | 13.743 | 22.4 | 6.577 | None | None |
| fb_board_html_2160.json | babylon | board | 2160 | 3.52 | 10.526 | 19.1 | 6.544 | None | None |
| fb_main_1440.json | babylon | main | 1440 | 0.635 | 8.994 | 12 | 3.285 | None | None |
| fb_main_1440_vsync.json | babylon | main | 1440 | 4.167 | 4.356 | 5.2 | 3.263 | 0 | 240 |
| fb_main_2160.json | babylon | main | 2160 | 1.085 | 19.97 | 36.4 | 3.336 | None | None |
| fb_main_2160_vsync.json | babylon | main | 2160 | 4.167 | 4.344 | 4.5 | 3.488 | 0 | 240 |
| fb_max_1440.json | babylon | max | 1440 | 2.649 | 8.697 | 54.4 | 6.543 | None | None |
| fb_max_1440_vsync.json | babylon | max | 1440 | 4.167 | 4.444 | 5.3 | 6.647 | 0 | 240 |
| fb_max_2160.json | babylon | max | 2160 | 5.032 | 27.288 | 37.9 | 6.596 | None | None |
| fb_max_2160_vsync.json | babylon | max | 2160 | 5.617 | 8.003 | 10.2 | 6.408 | 8 | 178.571 |
| fb_ships40_1440.json | babylon | ships40 | 1440 | 2.279 | 4.245 | 5.6 | 5.76 | None | None |
| fb_ships40_2160.json | babylon | ships40 | 2160 | 2.613 | 12.992 | 17.6 | 5.749 | None | None |
| fb_stress_1440.json | babylon | stress | 1440 | 1.421 | 8.049 | 12.5 | 4.561 | None | None |
| fb_stress_1440_vsync.json | babylon | stress | 1440 | 4.167 | 4.342 | 4.9 | 4.608 | 0 | 240 |
| fb_stress_2160.json | babylon | stress | 2160 | 1.961 | 20.942 | 25.7 | 4.573 | None | None |
| fb_stress_2160_vsync.json | babylon | stress | 2160 | 4.167 | 4.319 | 4.6 | 4.512 | 0 | 240 |
| fg_fp_board_1440.json | godot | board | 1440 | 1.584 | 3.336 | 8.607 | 4.178 |  |  |
| fg_fp_board_2160.json | godot | board | 2160 | 2.713 | 4.311 | 8.543 | 4.242 |  |  |
| fg_fp_main_1440.json | godot | main | 1440 | 1.135 | 1.942 | 4.923 | 3.51 |  |  |
| fg_fp_main_1440_vsync.json | godot | main | 1440 | 4.168 | 5.17 | 11.581 | 3.721 | 4 | 240.0 |
| fg_fp_main_2160.json | godot | main | 2160 | 2.175 | 3.126 | 7.419 | 3.519 |  |  |
| fg_fp_main_2160_vsync.json | godot | main | 2160 | 4.167 | 4.509 | 4.876 | 3.706 | 0 | 240.0 |
| fg_fp_max_1440.json | godot | max | 1440 | 4.827 | 7.137 | 8.96 | 38.016 |  |  |
| fg_fp_max_1440_vsync.json | godot | max | 1440 | 4.946 | 7.505 | 9.492 | 38.183 | 192 | 240.0 |
| fg_fp_max_2160.json | godot | max | 2160 | 7.54 | 10.97 | 15.79 | 38.033 |  |  |
| fg_fp_max_2160_vsync.json | godot | max | 2160 | 7.574 | 10.879 | 13.598 | 38.067 | 2468 | 240.0 |
| fg_fp_ships40_1440.json | godot | ships40 | 1440 | 3.039 | 5.076 | 7.557 | 4.332 |  |  |
| fg_fp_ships40_2160.json | godot | ships40 | 2160 | 3.727 | 5.71 | 9.343 | 4.22 |  |  |
| fg_fp_stress_1440.json | godot | stress | 1440 | 2.113 | 3.802 | 7.297 | 3.84 |  |  |
| fg_fp_stress_1440_vsync.json | godot | stress | 1440 | 4.167 | 4.873 | 5.699 | 4.115 | 0 | 240.0 |
| fg_fp_stress_2160.json | godot | stress | 2160 | 3.248 | 4.542 | 6.755 | 3.874 |  |  |
| fg_fp_stress_2160_vsync.json | godot | stress | 2160 | 4.17 | 5.297 | 8.457 | 4.103 | 4 | 240.0 |
| fg_gl_main_1440.json | godot | main | 1440 | 1.44 | 2.797 | 6.267 | 2.978 |  |  |
| fg_gl_main_2160.json | godot | main | 2160 | 1.917 | 3.466 | 4.671 | 3.962 |  |  |
| fg_gl_stress_1440.json | godot | stress | 1440 | 3.09 | 5.366 | 7.692 | 3.34 |  |  |
| fg_gl_stress_2160.json | godot | stress | 2160 | 3.66 | 5.73 | 8.062 | 3.368 |  |  |
| godot_exe_cold.json | godot | main | 1440 | 1.192 | 2.059 | 6.515 | 3.085 |  |  |
| godot_exe_warm.json | godot | main | 1440 | 1.166 | 2.105 | 6.407 | 3.015 |  |  |
