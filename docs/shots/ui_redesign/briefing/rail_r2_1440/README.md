# Orders sheet campaign map, 1440

Issue 441. Captured in the real Godot 4.7.2 campaign scene on the RTX 5080, Forward+, high map detail, default UI scale.

Run from the repository root:

```powershell
& 'C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe' --path godot --script res://ui/campaign/rail_orders_shots.gd -- ABSOLUTE_OUTPUT_FOLDER --win 2560x1440 --no-tips
```

- sector_1, sector_2, sector_3: seed 344, reached through campaign actions at the same jump.
- route_1 to route_3: each route chosen at the first sector's fork.
- action_hover and action_focus: the real button's mouse and keyboard states.
- dossier, map_key, fleet_purchase: the retained detail and the moved purchase.
- four_routes and four_route_1 to four_route_4: seed 2, a real generated fork reached through campaign actions.
- long_names_fleet_7 and long_names_fleet_12: explicit stress fixtures using the longest region, route, generated Nemesis combination and ship names measured from the shipped tables. Fleets of seven and twelve are injected for layout coverage. These are not campaign progression claims.
- fleet_overflow_scrolled: the last row remains reachable.
- fleet_seven_lines: the seven-row capacity at a simple stop, with long ship names.
- sector_N_background: same scene and veil with the rail hidden for contrast samples.
- readability.json: captured text rectangles, sizes, colors, visible fleet rows and overlap results.
- contrast.json: worst-pixel WCAG contrast from the rail-hidden captures, including the solid action hover sample.

The 1080 folder also holds the untouched-main before image and the before_after comparison. The Board mirror is C:/Users/rcbai/Downloads/voidsworn_test/board/issue-441/shots/.
