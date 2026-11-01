# F2 movement: one smooth motion per move, about twice as slow (Nov 1, 2026)

Ryan after his first Godot playtest (R65): "Ship movement feels way too jerky and fast still. I'm fine slowing things down. It doesn't feel like a space battle right now. It feels rushed and frenzied and sped up." His ruling (R64): about twice as slow, ships moving one at a time, longer enemy turns accepted, Enter or Space to hurry stays, flip-and-burn stays off.

## What to watch (start here)

1. `frigate_before_after.mp4`: the smallest ship's long move (4 hexes, 3 turns, one of them between two runs), left as played on Nov 1, right now.
2. `dreadnought_before_after.mp4`: the biggest ship (2 hexes with a turn between them).
3. `speed_and_spin.png`: the same two moves as numbers. Before, the hull shoots off, stops dead, spins on the spot, shoots off again. Now it never stops until it arrives, and it spins slowly and steadily.

The single clips (`*_before.mp4`, `*_after.mp4`) and the frame strips (`*_frames.jpg`) are the same moves. The text files are the raw records: the PC runs' logs, and the pace check before (the Nov 1 pace, which fails the new ruling by design) and after.

## What changed, in plain words

- **One motion, not pieces.** A ship used to play each straight run and each turn separately, starting and stopping dead between them. Now the whole move is one glide: the ship builds speed, slows into a corner while its bow comes round, picks up speed again, and eases into its final hex. It only comes to a full stop at the start, at the end, or if it has to reverse.
- **Slower and heavier.** A ship cruises a hex in about 0.4 to 0.75 s (by size), and building and bleeding speed adds to that, more for big ships. The frigate's move went from 1.5 s to 3.6 s; the dreadnought's from 1.1 s to 3.6 s. Top speed fell from 7 to 2 hexes a second for the frigate and from 5 to 1 for the dreadnought.
- **Big ships turn slowly.** Spin rates fell from 500 to 800 degrees a second to about 40 (dreadnought) and 120 (frigate).
- **Enemy ships move like yours.** Before, enemy moves were squeezed to fit a 12 to 15 second turn: an enemy frigate crossed 5 hexes in a quarter of a second (63 ms a hex). That was most of the frenzy. Now enemy ships move at the same pace as yours, one at a time.
- **Thrusters still follow the physics** (R50): the main engine only lights while it pushes the ship ahead, the bow jets brake, side jets push sideways (including the pull into a curved corner), the bow-and-stern jets start and stop each turn. No banking.
- Enter or Space still hurries any move. The game's rules are untouched: every battle plays out exactly as before (parity PASS, same results in every fight measured below).

## Enemy turn length (Ryan accepted longer turns; this is how much longer)

Measured headless at real game speed, same battles before and after (the outcomes are identical):

| Fight | Ships | Before: average, worst round | Now: average, worst round |
|---|---|---|---|
| s26 | 10 | 5.0 s, 7.7 s | 13.5 s, 22.5 s |
| s23 | 20 | 9.1 s, 12.1 s | 31.9 s, 47.6 s |
| s24 | 28 | 5.5 s, 15.4 s | 14.8 s, 51.5 s |

That is about 2.7 to 3.5 times as long, more than the "about twice" in the ruling, because enemy moves were squeezed far harder than the player's (down to a tenth of the time). The opening rounds of big fights, when every ship closes in, are the longest. **Question for Ryan (through Opus):** keep this, or play enemy moves somewhat faster than yours? One number does it (an enemy move share in battle.gd); for example enemy moves at 0.7 of your pace would bring the 20-ship fight's average to roughly 26 s. Enter or Space hurries any enemy turn.

## How it was checked

- Clips: Ryan's PC, lane A job `f2_mv_61a3ad7` (scenario s9, 1600x900, 30 frames a second, the HUD hidden). Before and after come from the same build: before is `--movement segments`, which is the exact motion and pace of the build Ryan played (kept as a test switch). The capture code is 61a3ad7, the same game code as dc9e467 on main (rebased).
- Speed and spin chart: the PC runs' own `--speed-trace` output.
- `tools/pacecheck_godot.sh` (new; replaces the retired 12 s target and 15 s limit): every move in the three fights above stays within the ruling (cruise 500 to 950 ms a hex, 7 s at most per move, never two ships moving at once, enemy moves not squeezed). PASS.
- Cloud rules parity (`godot/rules/test/run_parity.sh`): PASS, 48 of 48 battles. Two headless bot campaign runs: 0 errors, 0 softlocks.

## Calls I made (vetoable)

- The ruled 560 to 860 ms a hex is the hex time by size (escort to battleship and up); a ship cruises at 0.8 of it and its speed-up, slow-down, corners and turns add on top, so short moves of big ships run longer than the plain number (a dreadnought's 2-hex move with a turn: 3.6 s).
- The old faction speed factors (Crusade slower, Eclipse faster) stay as a light flavour only (their 0.35 power), so every faction stays near the ruled range.
- A 60 degree turn weighs 0.6 (escort) to 1.1 (battleship) hexes; turns get their own eased spin, slower for bigger hulls.
- Strike craft move at 0.35 of the hex time: agile, as Ryan asked on Oct 27 (R55), and there are many of them.
- Enemy moves no longer count toward the round budget (the budget still speeds up the enemy's fire and deaths late in a long turn).
- No end-of-move overshoot (the old "settle"): the ship eases into its hex instead.
- The Brisk movement setting keeps its old shape at the new pace; `--movement segments` keeps the Nov 1 motion for comparisons.
- Flip-and-burn stays off (Ryan's ruling); its test switch only works with `--movement segments`.

## Not done here / for other streams

- Wing phases still move your squadrons one by one; letting a wing phase's craft move together would shorten enemy turns noticeably (F1's turn-flow code, not F2's).
