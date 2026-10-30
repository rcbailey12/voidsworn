# Faction shape and roster expansion - synthesis (Oct 29 program)

Four prongs: Qwen SHAPES PARTIAL, Argon SHAPES PARTIAL, DeepSeek SHAPES PARTIAL, Rey (blind) SHAPES PARTIAL.

## Verdict: SHAPES PARTIAL (4 of 4)

The faction shapes are real where the game is played: stats, movement rules, traits, and credit prices all differ by faction in ways a player can feel. They are asserted rather than earned at the fleet-building screen, because the currency that decides how many hulls take the field, CP, is universal, and enemy generation never sees the credit asymmetry at all.

## Findings that stand

1. Credit shape never reaches enemy fleets (Argon, Rey; chair verified). genEnemyFleet spends CP only; FAC_PRICE is never consulted. Whatever the credit tables say about elite Eclipse or swarm Chorus, an enemy fleet's composition cannot express it. On the player side the asymmetry is real but one-directional.

2. The ruled Eclipse battleship is mispriced by a missing table key, and the ladder inverts (Rey's sharpening of a point Argon and Qwen both touched; chair verified the arithmetic). FAC_PRICE for deathless has no Battleship key, so the ruled cp6 battleship prices by the fallback at 370 credits, less than Eclipse's own cp4 cruiser at 390 after its 1.55 multiplier. The elite premium inverts at exactly the hull Ryan's Oct 29 Q7 ruling added. Adding the key (Qwen proposed 1.6) is a one-line fix with a designer-visible consequence.

3. CP is symmetric at the ladder bottom (Rey): all six frigates cost 1 CP and all destroyers 2 CP, so elite versus swarm is invisible in the early game where most battles are fought.

4. d_boss is the only Deathless hull without reanimate (all legs), and it recycles the harvester's gun kit at 3x the CP. With the Q7 battleship coming, the Eclipse top end currently reads as a scaled cruiser, not a capstone.

5. Chorus has regeneration but no feed or grow mechanic (Argon, Qwen), so its swarm identity is numeric (more, cheaper hulls) rather than mechanical. Its heavy archetype slot is thin; the Rey leg argues a cp4 Chorus heavy cruiser is the only new hull beyond the ruled battleship that a job justifies.

## The CP question: three positions, one constraint

Ryan asked how CP should work across factions given their shapes. The four prongs produced three answers:

- Multiplier on hull cost (Qwen: Eclipse x1.5, Chorus x0.75, fractional). Rejected by Argon's generator arithmetic: the fill loop's while(budget>=1) guard wastes fractional remainders and ceiling truncation can leave up to 44% of a swarm budget unspent in its model. Any multiplier design must answer that arithmetic.
- Multiplier at fleet-building or budget level (DeepSeek: Eclipse 1.5x, Chorus 0.7x applied to budgets, bosses excluded). Its own finding concedes the generator must apply the same multiplier or enemy fleets misprice by up to 50%. Avoids the fractional-hull problem, doubles the bookkeeping surface.
- No hull-CP change at all (Rey): the board ceiling (RAMP.ceil minus live player ships) silently converts any swarm CP discount into heavier hulls rather than more hulls, so a discount cannot buy the swarm fantasy anyway. Give the Chorus a faction-aware ceiling allowance instead, and carry elite feel on the player side with an Eclipse frigate/destroyer CP step (1 to 2, 2 to 3), flagged sims-first.

The chair's read: the Rey position is the only one that starts from what the ceiling actually does to a discount, and it is the cheapest to test, because the ceiling allowance and the Eclipse step are both measurable in the existing sim harness before any generator surgery. The multiplier positions remain live alternatives if sims show the ceiling allowance cannot produce visibly larger Chorus fleets within the 20-ship density leaning.

## The battleship sketch convergence, and its one conflict

All four prongs sketched nearly the same hull (cp 6-7, hp 250-280, armor .35-.40, regen, reanimate, a doom-class forward gun, gauss broadsides, point defense, no hangar), which is strong evidence the slot has an obvious shape. But all three external sketches gave it reclaim, which conflicts with Ryan's Oct 29 Q10 ruling (reclaim stays the harvester's signature). Only the Rey sketch complies, with a rebuild-aura ability instead. The synthesis adopts the compliant direction: the battleship's signature should be a new ability in Eclipse's idiom (rebuild aura, or reanimate extended to neighbors), not a second reclaim.

## Designer questions

One, for Ryan, in the program report: the CP direction (multiplier on budgets, per DeepSeek; integer ladder re-base, per Argon; or ceiling allowance plus a player-side Eclipse step, per Rey), with the sims-first path priced. The Battleship price key is not a question; it is a bug-shaped fix for Opus.

## Addendum: designer's ruling (Ryan, Oct 29, 2026, evening)

Ryan ruled on the principle: Eclipse ships should be stronger but more expensive, Chorus the opposite, faction appropriate across the board. The asymmetry direction is therefore settled, and it applies across the systems that express cost and strength (stats, credit price, and CP), not one lever in isolation.

Chair mapping of the ruling onto the three mechanisms on file, flagged for correction if Ryan reads his words differently: the principle endorses real per-faction cost differences (which kills the universal-CP status quo and the pure ceiling-allowance-only reading), but Argon's generator arithmetic still binds any implementation, because fractional hull costs strand budget in the fill loop. The compliant implementations are therefore the budget-level multiplier (DeepSeek) or the integer ladder re-base (Argon), and the Rey leg's ceiling point survives as a necessary companion rather than an alternative: if the Chorus discount buys cheaper hulls but the board ceiling still caps the fleet at the same count, the swarm discount converts into heavier hulls, so a Chorus ceiling allowance has to ride along for the discount to express as more ships. Sims first, per the Rey leg's flag, before any generator change ships. The Battleship price key remains a bug-shaped fix for Opus regardless of mechanism.
