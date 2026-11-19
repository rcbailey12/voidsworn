# Issue 1116: flash safety

The flash counter now measures the billboard at its camera depth. The camera-edge test shows a 150.74 px flash booking 151 px, up from 123 px on main, and the fourth flash is turned down. A cruiser torpedo shield crackle books one 110 px picture. Turning on Reduce Flashing while a shot is in flight softens the hit, muzzle flash, and event light at arrival.

## What changed

- [fx.gd](../../../godot/fx/fx.gd) uses the camera projection and view depth used by the draw. [fx_shaders.gd](../../../godot/fx/fx_shaders.gd) shares the sprite pixel floors with the counter and reads the live setting for weapon pictures already on screen. Event lights also read the setting when they appear or while visible.
- [fx_weapons.gd](../../../godot/fx/fx_weapons.gd) books baked flashes at arrival and shares the impact flash's permit with its body. The shield crackle books at the sprite centre and emits directly, like a pop. [fx_ship.gd](../../../godot/fx/fx_ship.gd) passes the same sprite floor for its shield-break pop. The normal colour, size, peak, and duration of a permitted flash stay as authored.
- The audit cases now run as [flash_projection.gd](../../../godot/fx/test/flash_projection.gd) and [shield_flash_booking.gd](../../../godot/fx/test/shield_flash_booking.gd). [hit_recipe_check.gd](../../../godot/fx/test/hit_recipe_check.gd) exercises the setting change between scheduling and arrival.

## Checks

```text
Main: FAIL flash projection: 151.0 px shown, 123 px booked, 17908 px2 shown, 15606 px2 limit, 4 bright in one second (expected 3)
Main: FAIL shield torpedo flash: 2 bookings, 1 counted (expected 1 booking, 0 counted)
PASS flash projection (edge, no floor): 150.74 px shown, 151 px booked
PASS edge flash cap: 3 bright in one second (expected 3)
PASS shield torpedo flash (normal): 1 bookings, 0 counted, 1 sprites, 4.20 power
PASS shield torpedo flash (budget full): 1 bookings, 0 counted, 1 sprites, 1.25 power
PASS shield torpedo flash (reduced): 0 bookings, 0 counted, 1 sprites, 1.25 power
FLASH_AREA failures=0
HIT_RECIPE failures=0
load all: 229 scripts, 16 scenes, 0 failed
PASS: every listed headless Godot check passed. (74 checks; 5 FX checks rerun after the shield-break caller fix.)
bot battle: PASS (seed 360)
PASS fixture record matches the A16 inputs and compressed GLB
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
PASS: old settings load and the saved Reduce Flashing option reaches battle FX
```

Standing checks: `node contrib/opus/tools/run_all_checks.js` returned 0 (69 PASS, 2 KNOWN baseline rows).

## Impact sweep

- Callers: searched the repo for the booking and draw helpers and traced the volley, torpedo, shield, death, and lightning paths. The existing unconditional death-core permit still applies.
- Saves: a scratch settings file with the old keys reached battle FX through the actual settings loader. The run save, old map save, and cross-twin load checks passed.
- Twins: this is Godot presentation only. No rule or table changed; the oracle-copy check and both parity suites passed.
- UI: title Settings and the battle menu still drive the same `reduce_flashing` value. Map, intel, and HUD have no flash-budget readout.
- CI: the new GDScript checks are in [godot_checks.txt](../../../godot/tools/ci/godot_checks.txt), the list GitHub's Godot game job runs. The Node standing list is separate.

No captures, GPU checks, or frame timing were run, per the brief. The checks measure projection, bookings, and material settings headless; they do not sample rendered brightness.
