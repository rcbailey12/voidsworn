# Movement specification (#228; Opus, Nov 8 2026)

One spec for how ships, wings, turrets and the campaign token move. It replaces the serial feel rulings as the build reference: R50 (A8 movement model, A9 pace setting, A22 overlap), R55 (A10 braking, A13 class split), R76 (A12 glide), within R64 (A3: about twice as slow, one ship at a time). Those rulings stay in FINDINGS as history; builders read this file. Source: the FX audit (contrib/muse/reviews/fx_audit_2026_11/, items A1 to A22) and the destruction audit (PF10). Every number below is the shipped value on main today unless marked otherwise; none of them was ever measured against a feel target, so they are the baseline the capture round (#233) judges, not a finished tuning.

## 1. The model (governs; A8, A10, A12, A13)

A ship moves as one continuous glide along a smooth curve through its hexes, the bow following the curve, the main drive doing the work, short thruster puffs only where the hull turns. No side-to-side shuffle, no flip-and-burn (R64), no snap stop.

- **Speed.** Cruise is one hex per unit of move time. Unit time per hex: 560 ms for the smallest escort to 860 ms for a battleship or bigger (`MOVE_HEX`), by hull size; a faction factor enters as its 0.35 power (`MOVE_PER`: Crusade 1.25, Chorus 1.1, Glasswrights 1.0, Hullbreakers 0.85, Hegemony 0.75, Eclipse 0.6, so the spread stays within about plus or minus 20 percent). The hull holds cruise for 80 percent of its hex time (`MOVE_CRUISE` 0.8); building and bleeding speed fill the rest.
- **Weight (mass-scaled acceleration).** Size class `sk` runs 0 (escort) to 1 (battleship and up). Time to build cruise from rest: 0.8 units for an escort to 1.6 for a battleship (`tr`, ship_view.gd), the same on the way down. Heavier hulls also get longer lead-in and lead-out: 250 ms to 450 ms (`MOVE_LEAD`).
- **Braking (A10).** The stop is the mirror of the start: speed bleeds to zero on the same eased curve over the last 0.8 to 1.6 units, retro jets at the bow lit while it bleeds. The final facing eases in over the move's last quarter. This is the shipped answer to R55's "too sudden"; the capture round judges it.
- **Corners and turns.** The curve slows at a corner by how far the course or heading swings there. A turn in place weighs 0.6 hex of time for an escort to 1.1 for a battleship per 60 degrees (`MOVE_ROT`), spin built and bled on an RCS couple (bow jets one way, stern jets the other).
- **Bank.** A roll into turns of at most 4 degrees, scaled by yaw rate (0.12 per radian a second), eased in and out over the move (`glide_bank`). Banking is a cinematic accent, not physics; it never exceeds 4 degrees.
- **Settle.** A small settle at the end of a segment, 14 percent of the segment (`SETTLE_T`).
- **Cap.** No single move takes longer than 7.0 s (`MOVE_CAP`) at normal speed.
- **Class split (A13).** The boundary is the hull class: squadrons (strike craft) are agile and move at 0.35 of a hull's hex time (`MOVE_SQUAD`), with no glide physics (they take the brisk path). Every hull from frigate up glides, its weight set by `sk`. Escorts are light, battleships and up are heavy, cruisers and carriers in between by size.
- **Charge.** A ramming charge runs at 0.72 of the normal time.

## 2. Pace settings (A9)

- **Cinematic** is the default and the reference (the glide above). **Brisk** is the earlier direct motion, kept as a player option and for comparison shots; **segments** survives only as a debug flag for before and after captures. The in-battle toggle switches cinematic and brisk.
- **Speed** (the player's speed setting, and Enter or Space to hurry a move under way) multiplies every move time; nothing else shortens a move.
- **Unmeasured (A2):** the round time at today's pace has never been timed. #238 times one battle round at each setting with `--pace-trace` so the pace debate has a number.

## 3. One at a time, and what may overlap (A22, A1)

R64 (one ship at a time) governs. The old "keep the B2 pace by overlapping animations and hurry" (R50) is retired with the B2 pace (R64). What may overlap: a ship's weapon fire, impacts and effects may run while the next ship starts to think; moves do not overlap. The rules' enemy think time stays hidden under the current move where it already is (A6); nothing hurries a move to keep a round under a target, because there is no round target any more.

## 4. First numbers where none existed

These are starting values (ASSUMED), each settled by the capture round in #233 on Ryan's eye.

- **Squadron wings (A15).** Shipped: each craft weaves around its slot on a closed sine path, 1.25 cycles a second (Chorus 1.8), sway 0.14 of craft length (Chorus 0.24), roll lead on the turn; trails sampled 30 times a second, 0.65 s long. Launch at battle start (R88). No physics model (PF12, #229). Wing flight across the board follows the unit's hex move at the squadron pace above.
- **Turret slew (A18).** No rate exists; turrets snap. Start: 90 degrees a second for escort and frigate turrets, 45 for cruiser and up, 30 for station turrets, eased in and out over a tenth of the swing; a turret finishes its slew before its shot leaves.
- **Campaign map flight (A20).** Shipped: the token flies a curve between stops in 2.4 s (`FLIGHT_SECONDS`, map3d.gd), click or Space to skip; the camera eases 1.1 s (1.6 s into a new sector). The capture round shows it beside 1.6 s and 3.2 s.

## 5. What this spec governs, and what it does not (PF10)

Governs: the glide in `godot/render/ship_view.gd` (`play_glide` and its constants `GL_*`, `tr`, `SETTLE_T`, the bank), the move timing in `godot/scenes/battle/battle.gd` (`MOVE_HEX`, `MOVE_LEAD`, `MOVE_CAP`, `MOVE_ROT`, `MOVE_SQUAD`, `MOVE_CRUISE`, `MOVE_PER`), the rules' pace table where it times moves (`PACE.move`, `PACE.rot`), the wing weave (squadron_wing.gd), turret slew, and the campaign flight. A change to any of these is a movement change and is judged against this file.

Does not govern: hit reactions and their masses (`REACT_MASS` in fx_ship.gd, the fx stack), death and wreck motion (the destruction stack, #233), the battle camera (calibration harness, #235), and the rules (hex steps, movement points).

**Flash's single tonnage bus** (one mass number per ship driving moves, hit shoves, camera shake and wreck drift) is not adopted now. The three masses do different jobs at different scales, and nothing yet shows they disagree on screen. It becomes the fix if the #233 captures show a heavy ship that moves heavy but reacts light, or the reverse.

## 6. How it is judged (A3)

One capture round in #233: the same three moves (escort, cruiser, battleship; a straight run, a run with one turn, a turn in place) at cinematic and brisk, the A3 side by side at today's pace and one slower alternate, plus turret slew and map flight at the values above. Ryan watches once. His picks become the numbers in this file, marked MEASURED by eye with the capture named.
