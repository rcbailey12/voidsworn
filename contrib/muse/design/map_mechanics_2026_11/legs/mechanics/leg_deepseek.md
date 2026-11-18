# DeepSeek leg (DeepThink ON, Search OFF, verified before and after; chat "Movement in Voidsworn")

Assumption: 1.25 speed + range baseline. The evidence says objective pull is the wrong lever; put movement value into the terms the scorer already reads: expected offense, expected incoming damage, and position value.

A. Mechanics: what moving buys

A1. Evasion from movement
- Bucket: A mechanics.
- Description: A ship gains evasion charges from hexes moved this activation, capped, applied against direct-fire incoming attacks until its next activation. Standing still gives zero.
- Why ships move: The bot's threat term is expected incoming damage at a destination. If farther movement lowers that threat, farther destinations score better. Standing slugfests become worse than repositioning.
- Smallest implementation: Add evasion = min(3, floor(hexes_moved / 2)); each charge reduces hit chance or expected damage by a fixed small amount. Add it to both combat resolution and the bot's threat estimate. No new subsystem.
- Simulator test/metric: Baseline vs evasion build, same seeds/maps. Expect mean post-contact move distance up, share of post-contact activations moving 1 hex or less down, board coverage up, shot clustering down. Also watch rounds; if rounds rise sharply, cap too high.
- Risk: Kiting/circling and longer battles; fast ships may dominate. Mitigate with cap, decay, and direct-fire-only evasion.

A2. Crossfire bearing bonus
- Bucket: A mechanics.
- Description: A ship that moved at least 2 hexes and attacks a target from a bearing at least 2 hexsides different from the last attacker's bearing on that target gets a modest accuracy/damage bonus.
- Why ships move: The bot's offense estimate can see the bonus. Destinations that produce a new bearing score higher, so ships orbit and crossfire instead of stacking on one firing line.
- Smallest implementation: Track last_attack_bearing[target]; if moved >= 2 and bearing difference >= 2 hexsides, add +10% expected damage or +1 damage. Add to target scoring and expected offense.
- Simulator test/metric: New metric "bearing diversity per target" should rise; shot clustering should fall; coverage and post-contact move distance should rise. If it only increases damage without bearing diversity, it failed.
- Risk: Bot over-spreads and loses focus fire. Keep bonus modest and require actual movement plus bearing difference.

A3. Arc-committed capital weapons
- Bucket: A mechanics.
- Description: Give at least one weapon per ship a narrow firing arc: spinal (1 hexside) or broadside (2 opposite sides). Facing and position determine whether the best weapon bears.
- Why ships move: The bot must include arc fit in expected offense. A destination that brings the spinal mount to bear beats a slightly closer destination that masks it. Enemy arc threat also makes flanking safer.
- Smallest implementation: Pick one existing long-range weapon; require target within 1 hexside of facing. Add arc predicate to target scoring and threat estimate. No new subsystem beyond the predicate.
- Simulator test/metric: New metric "arc-bearing rate" should rise; facing changes per move and post-contact move distance should rise. Mean firing range may shift. If arc-bearing rate does not move, the bot is not using the rule.
- Risk: Bot may spin in place or lose too much offense. Prototype one weapon only, after A1/A2.

B. AI design: how the bot should think about position

B1. Threat/opportunity influence fields
- Bucket: B AI design.
- Description: Replace "distance to nearest enemy" and purely local threat with two spatial fields: enemy threat propagated with distance decay, and opportunity/value of attacking from a hex. Destination utility samples the fields.
- Why ships move: The enemy fleet stops being the only attractor. A farther hex on a weak flank or low-threat frontier can score better than a close hex in the blob. Ships move further and spread to field edges.
- Smallest implementation: Per hex, compute threat = sum of enemy expected damage x decay(distance); opportunity = sum of our expected damage to enemies from that hex x decay. Add capped field terms and downweight/remove nearest-enemy distance.
- Simulator test/metric: Board coverage, mean pairwise ship separation, and post-contact move distance should rise; shot clustering should fall. Add "field value of chosen hex" and check it improves over baseline.
- Risk: Stale or badly tuned fields make the bot hover at edges or avoid combat. Use decay, caps, and keep a small enemy-attractor term.

B2. Sector/bearing deconfliction
- Bucket: B AI design.
- Description: Before activations, assign each ship a target sector or bearing around the enemy fleet. During destination scoring, penalize hexes near ally chosen destinations and same-bearing attacks.
- Why ships move: Without coordination, all ships score the same high-offense hex near the enemy and blob. Deconfliction makes a slightly worse individual hex better if it fills an open bearing, so ships spread and move farther to assigned sectors.
- Smallest implementation: At round start assign sectors by ship index (left/center/right or nearest/weakest). Add sum 1/distance(dest, ally_chosen_dest) penalty and bearing-overlap penalty. No full planning.
- Simulator test/metric: Mean pairwise separation and coverage should rise; shot clustering and "deconfliction violations" should fall; bearing diversity per target should rise.
- Risk: Splits fleet and loses focus. Deconflict only within a small radius and keep target focus.

B3. One-turn shot-and-denial lookahead
- Bucket: B AI design.
- Description: Score a destination by current shot plus whether it enables a good shot next turn and denies enemy good shots. Cheap version: penalize hexes inside current enemy firing arcs; reward hexes with next-turn line to enemy weak facings.
- Why ships move: Current scoring is myopic. A predictive term rewards repositioning to future firing lanes and out of enemy arcs, so movement becomes larger and more purposeful.
- Smallest implementation: Add capped terms: enemy_arc_coverage_on_hex penalty and next_turn_shot_opportunity bonus. No full enemy-response search at first.
- Simulator test/metric: New metric "predicted next-turn shot rate" should rise; "enemy arc coverage on chosen hex" should fall; post-contact move distance should rise.
- Risk: Compute cost and oscillation. Prototype as one capped consideration, not a full lookahead rewrite.

C. Bot approach: concrete implementation order

C1. Multiplicative considerations with caps
- Bucket: C bot approach.
- Description: Convert core utility terms to normalized considerations with response curves and capped contributions; multiply core terms or use weighted geometric mean. Keep objective small.
- Why ships move: New movement values will be drowned if the scorer remains an additive sum where raw offense or threat dominates. Multiplicative scoring lets a destination with good evasion/crossfire but slightly less raw offense win.
- Smallest implementation: Log each consideration per candidate; replace the additive sum for offense/threat/movement/objective with weighted product; cap each term's share.
- Simulator test/metric: New metric "destination contribution share" per term; ensure no single term exceeds roughly half. Then add A1/A2 and confirm post-contact move distance does not fall and coverage stays stable.
- Risk: Tuning fragility and passive bot. Keep additive fallback and A/B same seeds.

C2. One-at-a-time movement-value ablation
- Bucket: C bot approach.
- Description: Implement A1, A2, A3 as scoring considerations first, then combat rules, one build flag at a time. Add evasion_at_dest, crossfire_bonus_at_dest, arc_fit_at_dest to candidate scoring and log chosen-state contributions.
- Why ships move: This proves each mechanic actually changes destination choice. If scoring ignores it, the rule will not move ships.
- Smallest implementation: Feature flags per term; same maps/seeds/control bot; compare each step.
- Simulator test/metric: Evasion step: distance per move up, standing-still share down. Crossfire step: bearing diversity up. Arc step: arc-bearing rate up. Reject any step that does not move its metric.
- Risk: Interaction effects. Use same seeds and ablation; do not stack all three before measuring.

C3. Top-N ally-destination repulsion filter
- Bucket: C bot approach.
- Description: After utility scoring, keep top N destinations; apply a deconfliction penalty against already committed ally destinations this round, then select. This is the minimal implementation of B2.
- Why ships move: Later ships cannot choose the same blob cell/bearing as earlier ships. They take different hexes, increasing spread and movement.
- Smallest implementation: Maintain chosen destinations for current round; for candidates in top N, subtract k / (1 + hex_distance(candidate, ally_dest)); no penalty if no ally within 3 hexes.
- Simulator test/metric: Mean pairwise separation and coverage up; shot clustering and "ally destination overlap" down.
- Risk: Forces bad hexes. Use top-N only and small penalty; test after C1.

Top 3 ranking
A1 Evasion from movement. Smallest rule, directly enters the threat term the bot already uses, visible to humans, and attacks the standing-slugfest symptom at its cause.
A2 Crossfire bearing bonus. One tracked bearing plus a modest offense bonus; makes movement buy damage and forces orbiting/crossfire instead of one firing line.
B1 Threat/opportunity influence fields. The right structural fix to the nearest-enemy attractor, but needs C1-style scoring discipline and tuning; it is the best spread lever after movement has direct value.
Implement C1 first as plumbing, then A1, then A2, then B1. Do not lead with objective changes; the evidence already says that path fails.
