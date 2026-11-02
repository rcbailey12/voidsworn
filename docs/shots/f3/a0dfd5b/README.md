# F3 round 2: effects that land, and wrecks that are not hollow (a0dfd5b, Nov 1 2026)

Ryan after the first playtest: "Effects looked very weak, especially at a distance and for smaller ships." Opus's read of
round 1 (docs/shots/f3/53c1b51): from the normal battle camera most weapons were still a thin line and a small dot.
Ryan again at 16:12: "a ship can explode and it's just empty inside so it's clearly a shell. same with the holes in ships."

Before = today's game with the effects as they were after round 1. After = this commit. Same game build, same PC
(Ryan's, RTX 5080), same moments.

## Look at these first

1. **summary_small.jpg**: a frigate firing at a frigate, every weapon and a kill, at the moment it lands. Columns:
   before and after from the normal battle camera, then before and after fully zoomed out (that view is enlarged).
2. **summary_big.jpg**: the same for capital ships.
3. **inside_kill.jpg**: three ships blowing up (Hullbreaker battle-barge, Hegemony super-dreadnought, Crusade frigate),
   before and after in pairs of rows: from the battle camera, from close, looking into a piece, then 1.2 s and 3.5 s after.
4. **inside_holes.jpg**: the same ships with their hulls breached, close up and from the kill-zoom distance.
5. **clip_20_ships.mp4**: 9 seconds of a 20-ship fight, before on top, after below. (The plain white boxes are stand-ins
   the test fleet uses where a ship class has no model yet; they never appear in the game.)
6. **calm_small.jpg**: with "reduce flashing" on: no bright flashes at all, everything still readable.

## What changed, in plain words

- **Hits are a real burst now.** Every hit flashes at a size you can see from the battle camera, bigger for heavier
  guns (light guns 34 pixels on a 1080p screen, heavy 56), with a hot core that holds for a third of a second, sparks
  and a few glowing bits of debris, and a short light that lights up the target's own plating.
- **You can see who fired.** Every gun shows a muzzle flash (20 to 32 pixels) and briefly lights its own ship.
- **Small fast guns are bolder and still different from each other.** Autocannon: a stuttering brass flicker and fat
  short tracers, four to a burst. Laser turret: long hard bolts in the faction's colour with a white core. Flak:
  bursts around the target (not on it) with a pale ring and shrapnel. Gauss: a white flash and a shock ring at the
  gun, an instant bright line, and a punch ring where it hits. Prism shards: glassy needles that throw off colour.
- **Shield hits show whose shield it is.** A ripple in the faction's colour races out over the bubble from the hit.
- **Kills are the biggest thing on screen.** A blinding core flash, a shock ring racing out, burning pieces thrown
  clear trailing fire, then a few seconds of secondary blasts on the drifting pieces and a glow where the ship was.
- **Wrecks and holes are not hollow any more.** When a hull is opened (a breach, a burn-through, or a ship breaking
  up), the inside now shows decks, ceilings with light strips, bulkheads with frame ribs, some rooms on fire or lit
  red, and the cut decks as thick torn metal with glowing stretches that cool. Before, a broken piece was an empty
  painted skin you could see through. Pieces also vent air from their torn edges.
- **Hits no longer get switched off in a busy fight.** The safety limit of 3 bright flashes a second (for players
  sensitive to flashing) used to count every small hit, so in a big battle most hits, and a dying ship's own blast,
  were quietly toned down. Now only flashes big enough on screen to matter count (the same rule the standard uses).

## Numbers

- Frame rate with 20 ships, full effects (bench.json; "1% low" is the frame rate in the slowest moments, goal above
  40). Same session, before then after: 1080p 64.6 then 63.5; 4K 39.6 then 41.7. Two earlier same-session pairs:
  1080p 66.7 then 65.3 and 65.5 then 61.4; 4K 41.1 then 41.3 and 40.4 then 39.0. So round 2 costs about 0.1 ms a
  frame. Note for Opus: at 4K the game itself now sits right at 40 before any of these effects (round 1 measured 44 on
  an older build), so the 4K margin is gone whatever F3 does.
- Flash safety: never more than 3 counted flashes in any second; none with reduce flashing on. Effects smoke test: 0
  errors. No shader errors on the PC.

## Calls Claude made (you can overrule any of them)

- Sizes on a 1080-line screen: hit flashes 34, 46, 56 px by weight (plasma 6 more), muzzle flashes 20, 26, 32 px,
  shield ripples 36 to 64 px, a kill's core about 90 px for a frigate up to 190 px for a capital, its shock ring about
  2.6 times that. Everything a normal hit makes stays under the size that counts as a flash.
- Compartments inside a hull are sized to the ship (7%, 4.5% and 6% of its length); about a third of them burn or show
  red emergency light.
- No extra camera shake: round 1's small zoom punch on heavy hits and kills stays (off with screen shake off, halved
  with reduce flashing).

## Still open

- From the battle camera a frigate's kill is clearer than before but still small in a still frame; the close views of
  a capital kill are dominated by the fireball for about a second (that was already so before this round).

## How these were made

Ryan's PC, lane A. Before: run f3b r1 (fx from d0138fe on today's build). After: run f3b r4 on a0dfd5b (sheets, inside
stills, clip, reduce-flashing sheets, smoke test, benches before and after in one session). Tools:
`godot/fx/test/fx_range_probe.gd`, the new `godot/fx/test/fx_inside_probe.gd`, the gallery's `--clip` and `--bench`.
