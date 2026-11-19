Implemented the 15 text and display fixes for #1147. Battle 2 now teaches its objective, the Command hover shows what waiting adds, the shipyard quotes the real repair rate, and Beat 3 text appears only when earned. No gameplay rules or prices changed.

The [per-item report](contrib/openai/truth_pass2_1119/README.md) lists the changed files, what each screen reads, and the test for each fix.

| Check | Result |
| --- | --- |
| Standing checks | 74 `PASS`, 2 `KNOWN` baseline rows, 0 failures |
| Onboarding | `ONBOARDING QUICK CHECKS PASS` |
| Rules parity | `PASS: the Godot port matches the game's rules exactly.` All 284 saved battles match the refreshed fixtures. |
| Campaign parity | `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.` |
| Godot game checks | `PASS: every listed headless Godot check passed.` 86 ran. |
| Supporting checks | `load all: 241 scripts, 16 scenes, 0 failed`; `bot battle: PASS`; `PASS: Nemesis scenarios identical (219 records)`; `Map read-only: PASS (119 checks)` |
| Oracle copy, run last | `PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files` |

- **Callers:** Traced the HUD, campaign screens, reward flow, Dossier, and Career Chronicle.
- **Saves:** Tested older options, reward offers, Career paint settings, and Sector I, II, and III runs across reload.
- **Twins:** Re-exported both tables. Compared 1,770 records across the 16 changed battle fixtures and found only the intended ship-name and Command-log changes.
- **UI:** Headless checks passed. No review pictures were produced because another job held the GPU in solo mode.
- **CI:** The expanded tests run through the existing Godot check list.

No commit or push was made.