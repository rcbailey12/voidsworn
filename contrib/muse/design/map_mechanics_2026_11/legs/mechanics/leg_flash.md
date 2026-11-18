# Flash leg (Gemini, "Quick answers 3.5 Flash-Lite", signed in as Ryan Bailey; picker verified before and after; chat "Fixing Static Fleet Combat AI")

Voidsworn's static slugfest stems from a single design trap: the bot's utility scorer treats position as a derivative of immediate damage. Because expected offense dominates the math, any move away from a firing position looks like a net loss of utility. To break the blob, movement must buy something that raw firepower cannot duplicate, and the bot's evaluation function must be restructured to value space as much as damage.

Bucket (A): Mechanics (What Moving Buys)

1. Kinetic Inertia & Broadside Momentum
Bucket: Mechanics
Description: Capital ships maintain momentum. If a ship moves at least 4 hexes in a straight line before firing, its broadside weapons gain a range or accuracy bonus (+1 hex range or +15% damage), representing kinetic energy transfer. Conversely, ending an activation stationary or after a jagged zigzag imposes an accuracy penalty.
Causal Path: Ships are rewarded for committing to high-speed passes and drive-by runs rather than halting to trade blow-for-blow. Moving further is now a prerequisite for peak damage output.
Implementation Sketch: Add a MomentumCounter state variable tracking consecutive straight hexes moved. If Counter >= 4, multiply broadside weapon damage or range factors by 1.15.
Simulator Test & Metric: Run 100 mirror battles. Track Mean Firing Range and Post-Contact Move Distance. Both should rise by 20-30% if the mechanic works.
Biggest Risk / Downside: Can make nimble ships overwhelmingly dominant if tuning is too steep, causing slow capital ships to become unviable.

2. Directional Shield Drift & Dynamic Evasion
Bucket: Mechanics
Description: Moving 1 hex grants 0% evasion; moving max speed grants 15% damage reduction against incoming non-torpedo fire. This is a function of speed moved in the current activation.
Causal Path: Standing still makes a ship a sitting duck. Even during a firefight, spending 2-3 movement points to reposition grants a tangible defensive benefit, forcing a trade-off between perfect firing arcs and survival.
Implementation Sketch: In the damage routing function, multiply incoming damage by 1.0 - (speed_moved_this_turn / max_speed) * 0.15.
Simulator Test & Metric: Metric: Walking-Only Turn Share (should drop significantly below 10%) and Average Damage Taken per Activation.
Biggest Risk / Downside: Slow, heavy brawler ships risk becoming unviable if they cannot compensate for their lack of speed with armor or shield strength.

Bucket (B): AI Design (Position and Coordination)

3. Threat-Weighted Spatial Fields (Influence Maps)
Bucket: AI Design
Description: Instead of evaluating hexes purely by local targets, the bot computes a low-cost spatial field of the board each round. Enemy heavy guns project a "danger gradient" that decays with distance; friendly capitals project a "mutual support gradient." Objective hexes add a small attractive pull that decays over a radius of 5-7 hexes.
Causal Path: The bot stops walking blindly into the center of the enemy fleet. It learns to probe flanks, exploit gaps in enemy coverage, and hold high-value terrain, because the field makes those positions visibly more attractive than the blob center.
Implementation Sketch: Maintain a 2D array representing board control. Each enemy ship contributes a Gaussian falloff of threat to surrounding hexes. Each objective contributes a positive value. The bot adds the field value at a candidate destination to its utility score.
Simulator Test & Metric: Metric: Board Coverage Ratio (percentage of unique hexes visited per battle) and Mean Distance Between Friendly Ships (should increase, showing spread).
Biggest Risk / Downside: Computation overhead if calculated at high frequency, though a coarse 3-hex resolution map updated once per round keeps cost trivial.

4. Flanking Vector & Shield Arc Targeting
Bucket: AI Design
Description: The bot evaluates potential destinations not just by whether they can shoot, but by which shield arc they will hit. It actively seeks positions that attack the enemy's weaker side or rear arcs.
Causal Path: To hit side or rear arcs, ships must sweep wide, circle around, or coordinate pincer movements. This breaks the head-on slugfest and forces ships to use their full speed to get into flanking positions.
Implementation Sketch: In the target-scoring pass, multiply expected damage by an arc factor: Front = 1.0x, Side = 1.3x, Rear = 1.6x. The bot will then naturally prefer destinations that offer a rear shot.
Simulator Test & Metric: Metric: Flank Attack Share (percentage of total weapon hits landing on side/rear arcs) and Mean Firing Range.
Biggest Risk / Downside: Can cause erratic orbiting behavior if enemy facing changes rapidly between activations, leading to ships chasing a rear arc they can never reach.

Bucket (C): Bot Approach (Implementation in Utility Scorer)

5. Multiplicative Consideration Structuring (Utility AI Overhaul)
Bucket: Bot Approach
Description: Replace the current additive utility sum (Offense - Threat - Distance) with a multiplicative response curve architecture. If any critical consideration drops to zero (e.g., a hex is in lethal threat), the total utility collapses, preventing a single high-offense hex from overriding all other concerns.
Causal Path: Forces the bot to balance offense, defense, and positioning symmetrically. A hex with high damage but also high threat will no longer be chosen over a safe hex with moderate damage, encouraging the bot to maneuver for a better combined position.
Implementation Sketch: Refactor destination scoring: TotalUtility = OffenseScore * DefenseScore * PositioningScore. Each score is normalized between 0.0 and 1.0 using response curves.
Simulator Test & Metric: Metric: Post-Contact Move Rate and Survival Rate of Flagships.
Biggest Risk / Downside: Requires careful curve tuning; poorly tuned multipliers can cause the bot to become overly passive or freeze in place if all scores are low.

6. Two-Phase Turn Planning: Strike and Slip
Bucket: Bot Approach
Description: Split the bot's activation logic into two sequential evaluations: first, identify the best firing position; second, evaluate if a secondary "repositioning slide" (moving remaining movement points away from concentrated enemy lines) is viable without losing the shot. If a safe slip vector exists, take it.
Causal Path: Even when forced to engage, ships no longer park in place after firing; they use leftover speed to nudge behind cover or out of primary focus-fire cones.
Implementation Sketch: After selecting the optimal firing hex, filter reachable secondary destinations within remaining speed that increase distance to the nearest unengaged enemy while preserving the firing solution.
Simulator Test & Metric: Metric: Average Distance Moved Post-Firing per activation.
Biggest Risk / Downside: May occasionally lead to jittery micro-movements that look unnatural if distance weights are too volatile.

Top 3 Ranking and Rationale
1. Idea 5: Multiplicative Consideration Structuring (Bot Approach)
Why: It directly fixes the root mathematical flaw in the current utility scorer. Without changing a single rule of the game, it stops the bot from valuing raw damage above all else and naturally forces tactical positioning.
2. Idea 1: Kinetic Inertia & Broadside Momentum (Mechanics)
Why: It provides an immediate, visceral mechanical reward for moving fast. It directly targets the owner's complaint that speed and range "do not feel meaningfully different" by making high-speed runs demonstrably superior to static brawling.
3. Idea 3: Threat-Weighted Spatial Fields (AI Design)
Why: It gives the bot spatial awareness beyond its immediate line of sight. By letting ships "feel" danger gradients across the board, it naturally eliminates clumped death-balls and spreads engagements across the map.
