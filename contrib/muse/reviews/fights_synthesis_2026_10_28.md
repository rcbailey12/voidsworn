# Fights synthesis: encounters and boss fights (Oct 28, 2026)

Chair synthesis of the Oct 28 battle-layer program, encounters item. Legs: DeepSeek, Qwen, Argon, all DISTINCT ON PAPER. Evidence pinned to main 264f441d. Filed legs: contrib/deepseek/reviews/fights_2026_10_28.md, contrib/qwen/reviews/fights_2026_10_28.md, contrib/gemini/reviews/fights_argon_high_2026_10_28.md.

## Verdict

**DISTINCT ON PAPER, 3 of 3.** The eight encounters are genuinely different fights at the level of objective, win condition, and shape pool; no leg found a fake encounter. The item's problems concentrate exactly where a roguelike can least afford them: the boss fight, the one encounter every run is building toward, where three quarters of the objective rolls work against the climax, and in telegraphing, where two encounters hide the number the player is actually playing against.

## Findings (ranked)

1. **Boss Decapitation voids the boss's own escort (all three legs, BLOCKER).** The boss objective roll is rout, rout, ambush, flagship (50/25/25), and the flagship roll is Decapitation: kill the flagship and the fleet scatters. A boss fight's escort is fixed and hand-built, and Decapitation makes it strategically irrelevant: the correct play is to ignore the escort the fight was designed around and burn the flagship. A quarter of boss fights tell the player to skip the fight's own content.

2. **The rout roll is the mirror problem (Argon, extends finding 1).** On a rout roll, the boss can flee alive once its escort is ground down (the climax escapes), or the boss's command point weight forces something close to a total wipe anyway (the rout condition barely matters). Between Decapitation and rout, 75 percent of boss rolls strain the climax in one direction or the other. Only the ambush roll plays the boss fight as designed.

3. **Fix options on the table.** Argon proposes a Command Link: escorts within 3 hexes of the flagship redirect half its incoming damage to themselves, which makes the escort the path to the flagship instead of an obstacle beside it. DeepSeek's Ambush fix (finding 4) has the same shape: make the sub-objective load-bearing. The synthesis carries the Command Link as the lead option for Decapitation, with the simpler alternative of removing flagship from the boss objective roll and giving boss fights their own objective table.

4. **Ambush is the rout verb with a deployment twist (all three legs).** Its win condition adds nothing rout does not already ask; the difference is starting positions. DeepSeek's proposed fix: the two pincers must be destroyed before they link up, which gives Ambush a timer and a geography rout lacks. Qwen's BLOCKER on Ambush is conditional on whether ambush fleets flee at two-thirds strength; that is verifiable in battle code the pack did not include, and it is flagged below as an Opus check.

5. **Telegraphing hides the operative number in two encounters (DeepSeek and Argon; Qwen split).** Breakthrough's preview never states how many ships must escape; Hold the station never states the station's starting integrity. Qwen rates Hold the station honest because the mechanic and timer are named; DeepSeek flags the missing integrity number. Both are true at different levels: the preview names the verb and hides the threshold. Argon adds a live interaction: on defend with a swarm, integrity ticks per ship inside the ring, so the preview's own recommended counter (bring area weapons, hold the ring) can accelerate the loss if played naively. The synthesis position: previews should state thresholds, not just verbs.

6. **Deathless nodes can roll a carrier archetype the faction does not own (Argon; premises chair-verified).** The archetype roll in core.js is faction-independent, so Deathless nodes roll the carrier archetype about 15 percent of the time even though the Deathless roster (d_scythe, d_jackal, d_harvester, sq:null at data.js:128) contains no carrier. The node preview names it "Repair host" and advises bringing fighters and flak against wings that do not exist. What the generator actually spawns on that roll was in no pack; it is a one-read check for Opus and the item's clearest false-preview defect.

7. **The modal ordinary fight has no archetype (all three legs).** About 38 percent of ordinary fights roll no archetype, making the plainest fight the most common one. Combined with the battlefield item's shape gating, early-sector variety rests heavily on terrain the clearSpawns system then thins (see the battlefield synthesis).

8. **Boss hulls recycle roster kits (Argon and the DeepSeek roster leg, cross-item).** c_boss reuses c_hulk's launch and hangar 2; b_boss reuses b_brood's launch and hangar 3. The difficulty evidence from the Oct 28 program agrees from the other side: bosses measure long (7.3 to 8.0 rounds), not lethal. Boss fights are endurance tests against scaled hulls, which is why findings 1 and 2 hurt: the objective roll is doing variety work the hulls are not.

9. **The Deathless boss is the only Deathless hull without reanimate (Argon, chair-verified).** data.js:101 against lines 98-100: every other Deathless hull reanimates; d_boss does not. Recorded fully in the roster synthesis; it lands here too because it is the boss of the faction whose identity is coming back.

## Distribution caveat (chair)

Qwen's and Argon's legs both reconstruct encounter distribution from an assumed column count (about 4 to 5 columns per sector). The actual generator (genSector, core.js:251) builds 7 columns: col 0 a single node, cols 1-4 with 2 to 4 nodes, col 5 rest, col 6 boss. Their qualitative conclusions (archetypes carry repetition first, verbs second, shapes mostly on bosses) survive; their per-sector percentages do not, and the synthesis does not repeat them. Node modifiers never roll in columns 0-1 (Qwen), so sector 1's menu is structurally the plainest regardless.

## Questions for the designer

1. Boss objectives: should boss fights keep the shared objective roll, or get their own table? If the shared roll stays, does the Command Link (finding 3) make Decapitation honest, or is removing flagship from the boss roll cleaner?
2. Ambush: adopt the destroy-one-pincer-before-they-link condition, or accept Ambush as a deployment variant of rout and price it as such in the node menu?
3. Previews: is the standard "name the verb, state the threshold" (escape count, starting integrity) agreed for all encounter previews?
4. Deathless carrier roll: should the archetype roll be filtered by faction roster (no carrier archetype where no carrier exists), or should Deathless gain a carrier? The roster synthesis raises the same fork from the hull side.
5. The 38 percent no-archetype rate: intended baseline texture, or should the modal fight carry an archetype?

## Not checked

What actually spawns on a Deathless carrier-archetype roll (Opus one-read check); whether ambush fleets flee at two-thirds (battle code, outside the pack); the shipped UI's preview text beyond the pack slices (the findings are about pack-level preview data; if the UI adds thresholds the pack lacks, finding 5 downgrades to a pack defect).
