# Battlefield synthesis: arenas, generation, terrain and objects (Oct 28, 2026)

Chair synthesis of the Oct 28 battle-layer program, battlefield item (commission items 1 and 2, audited together: one pack, one leg set). Legs: DeepSeek (FIELDS VARY ON PAPER), Qwen (FIELDS VARY), Argon (FIELDS VARY ON PAPER). Evidence pinned to main 264f441d. Code claims below are chair-verified in voidsworn-fresh unless marked as leg inference. Filed legs: contrib/deepseek/reviews/battlefield_2026_10_28.md, contrib/qwen/reviews/battlefield_2026_10_28.md, contrib/gemini/reviews/battlefield_argon_high_2026_10_28.md.

## Verdict

**FIELDS VARY, THEN GET ERODED.** The generator's axes do real work (Qwen's weighting), and then post-generation systems flatten the result (Argon and DeepSeek's weighting). Both halves are true. The single highest-value fix in the item is clearSpawns: a safety system tuned far enough that it deletes the terrain the generator just placed, in exactly the shapes whose identity lives in the middle of the board. Terrain itself is mechanically real (seven types, real effects), but two of its seven types are strictly dominated and its colors collide in exact pairs, so the board is harder to read than it is to play.

## Findings (ranked)

1. **clearSpawns bulldozes the field after generation (all three legs; Argon and DeepSeek BLOCKER, Qwen FIX).** Chair-verified at battle.js:289-294: rock and hulks are deleted within radius 2 of player ships and radius 1 of enemies, plus a corridor up to 6 hexes toward the enemy centroid, 3 wide for the first 3 steps. On ring, archipelago, belt, and lanes boards this erases the center, which is where those shapes keep their identity. The system has a self-count (B.spawnCleared) and an env escape (NOCLEAR), so it is a tuned safety system, not an accident. The synthesis position: keep the safety, make it shape-aware (never clear a shape's defining feature hexes) and shrink the corridor.

2. **Boss fights delete 45 percent of the rock (all three legs).** Chair-verified at battle.js:313, with the comment stating the intent (flagship duels need firing lanes, not a maze). Combined with finding 1, boss boards are the emptiest boards in the game, and one of only three boss shapes is ring, whose identity is its rock. If the intent is dueling lanes, thinning should carve lanes, not Swiss-cheese the shape.

3. **Terrain colors collide in exact pairs (DeepSeek, chair-verified).** battle.js:9-12: rock and hulk share #bda088; station and planet share #9a948a. All four are mechanically identical blockers, so the cost is not tactical misreads, it is objective legibility: in the ruled wide opening shot (whole battlefield, then zoom to the player's fleet), the player cannot tell which blocker is the station they are defending. One-line fix class: four distinct colors.

4. **The gravity well never appears in the terrain legend (Argon; constants chair-verified).** battle.js:280-284: assist radius 6 (+1 MP), pull radius 5, damage radius 3 (7 HP). terrainPresent() reads only B.terrain, so the strongest terrain feature in the game is invisible in the legend. DeepSeek adds that the well is gated to deep maps, so most fights never see it at all. Richest feature, worst discoverability.

5. **Deployment fallbacks erase the interesting modes (all three legs).** deploy()'s single-centroid scorer can collapse the two-sided ambush onto one edge; the half-board fallback erases flank and ambush deployment on narrow shapes; flank deployment as built moves both fleets to opposite corners facing head-on (Argon: a line fight rotated, not a flank). The deployment modes exist in the menu more honestly than on the board.

6. **Axis shapes are gated out by arena weights (Qwen, chair-corrected).** ENC_ARENA weights: rout is 65 percent non-strip; hold is 100 percent non-strip (round .6, square .4); flagship is 80 percent non-strip. So for hold encounters the five strip-axis shapes never appear at all, and shape variety is largely a strip-arena phenomenon. Qwen's leg understated these percentages; the corrected numbers above are the chair's from the pack table.

7. **Lanes builds its wall along the advance, not across it (Argon).** The lanes barrier runs parallel to the strip advance axis at midR instead of across it. Chair note: the gap positions in Argon's leg are illustrative inference, not measured; the orientation claim is read from the generator and plausible. Opus can confirm in one read. If true, the shape named for channeling movement does not channel it.

8. **Reinforcement edges are hardcoded left and right (Argon).** edgeHex assumes strip orientation; on rotated arenas reinforcements can spawn in the enemy's rear, and on strip they arrive 13 to 15 hexes from the fight in round 3 to 4 of a 4 to 8 round battle. Read from the pack, not chair re-verified line by line.

9. **Canvas scale is a live question, with corrected math (Qwen and DeepSeek).** The 30x22 canvas (448 strip hexes) hosts at most 20 ships. Qwen's crossing-time framing used the full 28-hex width; fleets actually deploy about 15 to 17 hexes apart (player c 5-7, enemy c 22-24), and the difficulty pack's sims resolve in 4 to 8 rounds, so the board is not too big to fight on. The density point survives as a feel question (how much empty hex a battle should open with, under the ruled zoom-out opening), not as a defect.

10. **Two terrain types are dominated, one axis is cosmetic (all three legs).** Debris (-10 to be hit) is a strictly worse nebula (-15) under the same rule shape. Biome does no mechanical work at all; all three legs rank it the least variety-bearing axis, and the ion storm (10 shield stripped per facing per turn, -10 aim) shows the generator can do more when it wants to. Engagement's shape list names archipelago twice (chair-verified at battle.js:59), double-weighting it.

## What the legs split on

Only weighting. Qwen reads the generator's axes as the story (objective plus arena genuinely changes fights, especially the angled approaches on round and square arenas); Argon and DeepSeek read the post-generation erosion as the story. The synthesis holds both: generation is good, erosion is the tax on it, and the fix order follows the erosion, not the generator.

## Questions for the designer

1. clearSpawns: is the current radius and corridor the intended safety level, and may it become shape-aware so a shape's defining features are never cleared? (Fix direction is clear either way; the radius is the tuning call.)
2. Lanes: should the barrier run across the advance (channeling) or along it (a wall to fight beside)? The name argues across.
3. Flank deployment: is the opposite-corners geometry intended as a rotated line fight, or should a flank start actually place a fleet on the enemy's side arc?
4. Debris at -10 vs nebula at -15: is the gap deliberate (debris is common, nebula is special) or an unexamined default?
5. Biome: mechanical forever-no, or visual only by design? If visual only, the synthesis recommends saying so in the design docs so future audits stop scoring it as a variety axis.
6. Opening-shot legibility: with battles ruled to open zoomed out on the whole field, should objective terrain (the defend station above all) read distinctly at that distance? The color fix in finding 3 is the cheap version of yes.

## Not checked

Camera fit beyond the opening-shot rule (the playable Godot battle is the real test); visual silhouette and sprite legibility (Ryan's eye, at the playtest); whether the Godot port reproduces clearSpawns and the arena weights identically.
