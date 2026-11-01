# F1: turn flow, move hexes and the play log (feel pass, Nov 1)

Captured in the running game on Ryan's PC (RTX 5080, Forward+), lane A job `f1_shots_0354234`. The F1 code in these pictures is main commits ad8521a, fe4a459, 545ec46 and 0354234 (the job ran the same tree before the push).

## What you'll see in a battle now

- **The game hands you a ship.** When it is your turn, the next ready ship is picked for you: it has a gold UP tag over it, a breathing gold ring under it, and "Up" in your fleet list. If it is off screen the camera glides to it. You can still pick another ship (click it, or Next ship / Tab) as long as the one that is up has not moved or fired yet.
- **A card at the bottom says what to do.** It names the ship that is up and shows three steps: 1 Move (how much is left), 2 Fire (guns ready, how many can fire now), 3 End ship. One plain sentence says what to do next, and the big buttons are there: Move here, Fire, Brace, Next ship (Tab), End ship (Space).
- **Moves are planned before they happen.** Click a blue hex: a see-through copy of your ship appears there, facing the way it will end up (Q and E turn it), with its path and its firing arcs from that spot. Nothing has moved yet. Click the same hex again (or Enter) to go, or Esc to drop the plan. Once a move is made it can't be taken back.
- **Clicking an enemy never fires.** The first click targets it: the card shows how many guns bear and the expected damage from where the ship really is. Click it again (or Enter, or the Fire button) to fire, once. If it is out of reach, the first click shows the attack-move instead: where your ship would stop, its path, and what would fire on the way; a second click commits it.
- **Ending a ship.** Space or End ship ends it. A ship that has nothing left to do (no movement, no gun that can hit anything, no brace, ability, ram or boarding) ends by itself with a short note, and the next one is handed over.
- **The enemy's turn is marked.** A violet strip at the top says ENEMY TURN, which ship is acting and how far through their ships they are ("ship 3 of 7"), with a progress bar. When all your ships are done and the enemy plays out the rest of the round, a big "Enemy turn" banner shows once. Enter or Space still hurries them.
- **Reinforcements are announced.** A banner (Reinforcements, or Enemy reinforcements), a line naming the ship, a flash and an "Arrived" tag where it appears, a camera nudge over to it and back, and NEW next to it in your fleet list.
- **The board.** The hexes your ship can reach are blue, with a lit edge and one bright outline around the whole area. No terrain, zone or marker uses blue, so they can't be mixed up with nebula (violet), debris (sand), storms (yellow), exits (green) or the relay (gold). The rest of the grid is a quiet grey that fades away from the ship that is up. The firing arcs are now thin bright edges with almost no fill, so they no longer wash half the board tan.
- **The play log.** Every one of your ship turns is recorded: which ship, how it was picked (handed over or picked by you), how long until the first action, what it did (moves, fire, brace, abilities), plans and targets dropped, and how it ended. It goes into the campaign save's run log and into a file per battle in the game's user folder (`play_logs`), so the next playtest gives real data.

## Pictures

| File | What it shows |
|---|---|
| `compare_move_hexes_before_after.jpg` | Before (the exe you played) and after: the move hexes and arcs |
| `1_move_planned_ghost_and_card.jpg` | A planned move: blue area, outline, ghost, path, the card with Move here |
| `2_enemy_targeted_odds_fire_button.jpg` | An enemy targeted: the odds in the card and the Fire 1 weapon button |
| `3_attack_move_preview.jpg` | An out-of-reach enemy clicked once: the ghost where the ship would stop and the path |
| `4_next_ship_handed_over.jpg` | After the enemy's reply, the next ship handed over |
| `5_enemy_reinforcements_banner.jpg` | Enemy reinforcements arriving in round 3 |
| `6_twenty_ships_first_hand_over.jpg` | The opening of a 20-ship battle |
| `7_after_firing.jpg` | Right after a volley |
| `clip_end_ship_enemy_turn_handover_20ships.mp4`, `..._sector1.mp4` | 9 s each: End ship, the enemy turn strip, the hand-over, repeated |
| `clip_enemy_reinforcements.mp4` | 5 s: the reinforcement banner and camera nudge |

The clips are driven by the test script, which clicks at machine speed; a person plays slower. Ship movement speed is F2's work and is not in these clips yet.

## Checks

- **Rules untouched.** No file in `godot/rules/` changed. Cloud rules parity 48 of 48 battles, PRNG and math PASS; campaign parity 30 of 30; Nemesis scenarios, save and arc hook PASS (before and after rebasing on R1's step 13).
- **Same outcomes.** The bot campaign (seeds 1001 and 1002, 18 battles) plays out identically with and without F1 on current main: same results, rounds, survivors and hull.
- **Acceptance trace** (`godot/scenes/battle/f1_trace.gd`, Codex's "playable phased battle" checklist): it plays a battle through the real click and key handlers and records the rules state hash and the random generator's state around every step. Clicking an enemy once, targeting, planning a move, turning the plan and cancelling change nothing at all (same hash, no random draw); committing a move or a volley changes the battle once; Enter pressed twice during a volley does not fire twice; Brace and Pass end the ship; the game hands over the next ship after the enemy's reply; a full round completes without a stall; reinforcements are announced; the card fits on screen. PC: 74 checks in 4 battles (s5 20 ships, s14 breakthrough with an attack-move, s9 enemy reinforcements over 4 rounds, a sector 1 opener), 0 failed. Cloud: 10 scenarios, 0 failed. `trace.txt` and `trace.jsonl` per battle are in `Downloads\voidsworn_test\shots\f1_0354234\`.

## Calls I made (technical, vetoable)

1. Hand-over order is your fleet list, top to bottom, continuing after the last ship handed over (predictable; not "most urgent first").
2. The camera glides only when the handed-over ship is not already well inside the view, so it does not swing around when the ship is on screen.
3. Space cannot end a ship in its first half second after hand-over, so a Space pressed to hurry the enemy never ends your next ship by accident.
4. Enter confirms what is planned (move, fire, attack-move) and never ends a ship; Space ends it. In the enemy turn both still hurry.
5. "Nothing left" ignores turning in place: a ship with no movement, no gun that can hit, no brace, ability, ram or boarding ends itself even if it could still pivot.
6. The "your turn" sound plays only at the first hand-over of each round, not after every enemy move.
7. The planned-move ghost shows how many guns would bear from there, and orange rings on enemies they would reach, but not hit odds: the rules give odds only from where the ship actually is. Odds from the planned hex need a small read-only addition to the rules API (R1's folder); I have not added it.
8. Mid-move fire as its own declared step (Muse's option) is not built; the attack-move preview covers that case.
9. Classic mode (whole turns, a setup option) keeps its old controls; the card does not show there.
10. The play log keeps every activation for the newest 40 battles in the save; older battles keep only their summary.

## For other streams

- `godot/campaign/campaign.gd`: one new function `tel_battle` (R1 owns the file; announced in `contrib/opus/compute/port_notes.md`).
- battle.gd: F1's edits stay out of F2's move functions (`_play_move`, `_move_segments`, the move pace lines).
