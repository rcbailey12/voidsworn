# R1 follow-up: campaign screens (Godot, Ryan's PC, RTX 5080, 3840x2066 window)

Shot by `godot/campaign/test/r1_ui_shots.gd` in one lane A job (`queue\r1_ui_d039a7a.bat`): before is 8efa1bf, after is d039a7a. Same profile every time: 100 renown, only Vex bought, War chest I unlocked, seed 4242. Each `*.webp` is a before and after sheet; `after_*.webp` is the after shot alone at 2560 wide. The PNGs stay on the PC in `voidsworn_test\shots\r1_ui_d039a7a\`.

| Sheet | What changed |
|---|---|
| `a1_admiral_hegemony` | Before: every card said "Unlock for N renown in Legacy" (even First Admiral Kassar, "0 renown"), and Kassar could still be launched while shown as locked. After: Kassar, the Hegemony's free first admiral, is Selected; the other three carry an "Unlock for 30 / 45 / 80 renown" button. Locked cards stay dimmed (the existing style), so their buttons look dim too even when you can afford them. |
| `a2_admiral_crusade` | The same for the Sunward Crusade (Vex selected; Malek, Ashgrove, Thale with unlock buttons). |
| `b1_progression_legacy` | Before: there was no Legacy tab, so the Legacy unlocks (carrier and battleship hulls, war chests, command points and the rest) could not be bought at all. After: a Legacy tab (second) in the Hull variants card style. Owned shows "Unlocked", chained unlocks say what they need first. |
| `c1_shipyard` | No visible change with the starting fleet (the decommission label now comes from the same function as the payout). |
| `c2_shipyard_flagship_hull` | A sector flagship hull in the fleet (no shop price, no refit slots). Before: the shipyard page failed to build (two script errors), leaving the map. After: the page builds; the Pyre-Barge decommissions for 140. |

Logs: no script error in the after run. Lane B at d039a7a: rules parity 48 of 48 (worst enemy think 0.437 s), campaign parity 30 of 30.
