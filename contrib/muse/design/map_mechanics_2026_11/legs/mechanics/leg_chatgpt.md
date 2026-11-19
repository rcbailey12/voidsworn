# ChatGPT leg (GPT-6 at High, picker verified before and after; chat only; dashes normalized to hyphens per repo rule)

Voidsworn movement council: mechanics, AI design, and bot implementation

Central finding

Voidsworn does not primarily have a movement-frequency problem. It has a movement-value problem.

The measured 90%+ post-contact move rate matters. The bot is already moving during combat, but most moves are small adjustments inside an established firing position. It has little reason to abandon that position because doing so often costs immediate expected damage without offering a compensating benefit.

The best solution combines three changes:

1. Give substantial movement a direct defensive benefit. A ship that travels meaningfully becomes harder to hit.
2. Give the bot a reason to seek a different fighting position. Flanking, weapon range preferences, and coordinated attacking lanes should create destinations worth traveling toward.
3. Change how the bot values getting there. It must sometimes accept a small immediate offensive sacrifice for a better position, without returning to the objective-overweighting failure already measured.

I would test these separately before combining them.

The assumed baseline throughout is the owner's preferred 1.25 speed + range configuration, rounded to whole numbers.

A. Mechanics: what moving buys

1. Evasive translation

BUCKET A - ONE NEW COMBAT RULE - HIGH PRIORITY

Description: Ships become harder to hit when they cover meaningful distance during an activation.

Start with two experimental thresholds:

Net displacement | Direct-fire accuracy against ship
0-2 hexes | No modifier
3-4 hexes | -10 percentage points
5+ hexes | -15 percentage points

The benefit lasts until the ship's next activation. Use net displacement between starting and ending hexes, not total path length.

Why movement increases: A ship currently sitting at an optimal firing position gains something from leaving it. Fast ships receive a stronger survival advantage, while slower battleships remain comparatively vulnerable. Moving rapidly across the battlefield becomes a defensive choice rather than merely transportation.

Crucially, this rewards longer movement during combat, not just more movement events.

Smallest implementation: Record each ship's activation-start hex, calculate net displacement after movement, and apply the appropriate accuracy modifier to incoming direct-fire attacks. Add a visible evasion indicator. Do not alter the torpedo collision model in this first test.

Simulator test: Run mirror-fleet tests with the evasion rule enabled and disabled, using the unchanged bot initially, followed by an evasion-aware scorer.

Primary metrics:

Mean post-contact net displacement.

Share of post-contact firing activations involving 3+ or 5+ hexes of movement.

Damage avoided due to evasion.

Secondary: battle duration, speed-class survival, and win splits.

Biggest risk: Mandatory-looking movement. Ships might circle around targets for an artificial defensive bonus, or fast ships might become disproportionately difficult to kill. The rule should reward tactical travel, not demand maximum movement every activation.

The first experiment should establish whether the benefit is large enough to change decisions without making stationary ships nonviable.

2. Rear-quarter pressure

BUCKET A - ONE NEW COMBAT RULE - MEDIUM PRIORITY

Description: Direct-fire attacks originating behind a target receive a modest advantage.

Prototype a +10 percentage-point hit bonus when the attacker occupies either of the target's two rearward hex-direction sectors, defined relative to its facing.

This is an explicit new vulnerability rule. It does not assume that rear shields have a separate strength pool.

Why movement increases: A ship facing an opponent's bow has an incentive to travel around it. The defender can turn to deny that advantage, creating a continuing contest over positioning rather than two ships remaining nose-to-nose.

It also gives faster ships a useful role even without superior weapon damage.

Smallest implementation: Calculate attack bearing relative to target facing during hit resolution. Apply the modifier to eligible direct-fire attacks. Make the resulting flanking shots visually identifiable.

Simulator test: Compare ordinary mirror fleets with the rear-quarter rule on and off, first with unchanged AI and then with flank-aware destination scoring.

Primary metrics:

Percentage of shots fired from rear quarters.

Post-contact net displacement.

Number of distinct attack bearings against a target.

Frequency of ships turning to protect their rear.

Biggest risk: A moving cluster may simply become a rotating cluster. The fleet could all chase the same rear arc rather than spread out. This mechanic supplies a reason to flank, but it does not solve coordination.

3. Long-gun close-range weakness

BUCKET A - ONE WEAPON TRAIT - MEDIUM PRIORITY

Description: Give one category of long-range direct-fire weapon a close-range accuracy penalty.

For example, a selected heavy gun loses 20 percentage points of accuracy at range 1-2, retaining its normal effectiveness at range 3+.

Do not apply this across all long-range weapons initially.

Why movement increases: Long-range ships need to maintain separation instead of remaining stationary once an enemy closes. Short-range ships benefit from penetrating inside that preferred range, so both sides have reasons to maneuver.

This creates distinct fighting styles without simply increasing range or speed.

Smallest implementation: Add a close-range penalty trait to one existing weapon family, with the same range-dependent modifier in the bot's damage estimator.

Simulator test: Use mixed fleets containing heavy ranged ships and close-range attackers, alongside weapon-family-specific controls.

Primary metrics:

Range distribution of shots by weapon family.

Retreat or separation moves after first contact.

Distance traveled while continuing to fire.

Differences in firing positions between weapon classes.

Biggest risk: The penalty could weaken certain fleets and create endless pursuit-and-retreat cycles. Range preference needs to produce decisions, not battles where nobody can catch anybody.

This is a later test than evasion because its effects depend heavily on fleet composition.

B. AI design: how the opponent should think

4. Future firing position value

BUCKET B - SMALL SCORING EXTENSION - HIGH PRIORITY

Description: Score a position partly by the attacks it enables on the following activation, not only the attacks available immediately.

The bot should value an endpoint that approaches an advantageous firing arc, desired range band, or escape route even if the current shot is slightly worse.

Why movement increases: Current optimization creates a local trap: once a ship can shoot, moving farther often has no benefit. Future-position value creates a reason to travel toward a stronger attack position.

The causal difference is important. This is not another bonus for being near an enemy. It specifically values attainable future firing opportunities that are unavailable from the current position.

Smallest implementation: For each shortlisted destination, estimate the best attainable weapon opportunity on the next activation. Initially use sampled target-relative range and bearing positions rather than a complete two-turn search.

Apply a discount to that future value and a strict limit on how much immediate combat utility the bot can sacrifice to pursue it.

Simulator test: Compare the current utility scorer with a scorer that includes future firing opportunity, using identical mechanics.

Primary metrics:

Net displacement across successive activations.

Improvement in firing position between activations.

Share of longer moves that lead to improved subsequent attacks.

Shot-origin diversity.

Biggest risk: Overvaluing hypothetical future attacks. Battles last only 8-12 rounds, and the target can move before the ship acts again. The future estimate must account for activation order and uncertainty.

5. Coordinated attack lanes

BUCKET B - LIGHT COORDINATION LAYER - HIGH PRIORITY

Description: Give ships distinct tactical destinations around important targets instead of allowing every ship to independently optimize against the nearest enemy.

For each priority enemy, define several desirable approach sectors and range bands. Assign ships to compatible positions based on speed, weapon arcs, existing location, and combat role.

A long-range ship might take a lateral firing position while a fast attacker approaches the rear. A screening ship might remain between an important friendly unit and an approaching threat.

Why movement increases: The current bot independently makes similar decisions for similar ships. Coordinated destinations break that symmetry.

Ships must travel to different useful positions, increasing separation, firing-angle diversity, and meaningful crossfire.

Unlike making objectives arbitrarily attractive, these destinations remain directly connected to combat.

Smallest implementation: At the beginning of a round, assign each ship a target and a desired attacking sector, using a small greedy assignment across six capital ships.

Keep assignments stable until the next planning pass unless a critical event invalidates them. Do not build a general-purpose squad-command system.

Simulator test: Compare independent destination selection against assigned attack lanes using the same combat rules and utility weights.

Primary metrics:

Distinct attack sectors occupied per target.

Attack-bearing diversity.

Friendly-ship clustering near the primary target.

Net distance traveled toward assigned positions.

Damage concentration and win rate.

Biggest risk: Spreading ships can weaken focus fire and expose isolated attackers. The desired outcome is better attacking geometry, not maximum separation.

Two ships attacking the same target from different directions may be preferable to two ships attacking unrelated targets.

6. Opportunity and threat fields

BUCKET B - SMALL PROTOTYPE, LARGER FULL SYSTEM - MEDIUM PRIORITY

Description: Replace the single attraction toward the enemy fleet with a spatial picture of useful and dangerous positions.

For each relevant hex, estimate:

Likely enemy fire exposure.

Access to advantageous range and firing arcs.

Friendly congestion.

Future attack opportunities.

Objective relevance where strategically necessary.

The important addition is opportunity across space, not merely a more detailed threat calculation.

Why movement increases: The bot can identify good fighting areas beyond the nearest enemy's position. It can choose a safer lateral approach, a useful firing lane, or a position that avoids crowding.

This could help ships distribute across terrain and multiple combat fronts.

Smallest implementation: Before building a board-wide influence map, compute a coarse set of tactical position values around a few priority targets. Use cached weapon ranges, arcs, and enemy threat estimates.

Only expand to a full grid-wide field if the coarse version proves valuable.

Simulator test: Compare the existing destination scorer with one that reads coarse opportunity fields.

Primary metrics:

Combat-phase board coverage.

Shot-origin diversity.

Friendly congestion.

Exposure-adjusted damage exchange.

Travel toward useful terrain or firing positions.

Biggest risk: Recreating the existing failure with more machinery. If every field simply reinforces enemy proximity, ships will still converge.

Also, spreading across the board is not intrinsically valuable. A concentrated fleet can be tactically correct. The field must identify positions with actual combat advantages, not reward empty hexes.

C. Bot approach: concrete changes to the utility scorer

7. Combat-preserving movement selection

BUCKET C - SCORING CHANGE ONLY - HIGHEST IMPLEMENTATION PRIORITY

Description: Stop treating the single highest immediate-utility destination as automatically correct.

Instead, generate a shortlist of destinations with comparable immediate combat value, then choose among them based on movement, defensive benefit, and future positioning.

Why movement increases: The current scorer may prefer a two-hex shuffle over a five-hex reposition because the shorter move yields marginally higher expected damage.

If that difference is small, the longer movement could be tactically superior, especially with evasion or future firing advantages.

This is the lowest-risk way to test whether the current bot is trapped by overly precise local optimization.

Smallest implementation: Keep the existing candidate enumeration and core utility calculation.

Then introduce a two-pass selection:

Pass 1: existing immediate combat utility (expected offense minus expected threat) for every reachable state; best = max.
Pass 2: retain states within a budget of best (budget = 10% of the ship's expected normal volley damage, an experimental starting value), with threat within an acceptable limit; among the eligible, choose by movement defense value + future position value + assigned lane progress. Begin with displacement alone as the secondary preference.

Simulator test: Compare the unchanged scorer against two-pass selection before introducing any new combat mechanics.

Primary metrics:

Average post-contact net displacement.

Share of firing activations moving 4+ hexes.

Average immediate combat utility sacrificed.

Subsequent attack quality.

Win split.

Biggest risk: Making the bot willingly sacrifice real combat value for movement that looks impressive but accomplishes nothing.

That is why the combat-quality budget and next-activation outcome measurements are essential. Distance alone is not sufficient.

8. Predictive torpedo avoidance

BUCKET C - PROJECTILE FORECASTING - HIGH SPECIALIST VALUE

Description: Evaluate incoming torpedoes according to where they can strike over the next one or two rounds, rather than treating them primarily as a small threat penalty at the current destination.

Use the actual projectile behavior, including any guidance or interception rules already implemented.

Why movement increases: Torpedoes provide an existing, visible reason to abandon an otherwise profitable firing position.

A ship that can dodge a dangerous projectile by crossing several hexes should value that movement, even if it momentarily weakens its firing angle.

This is also good for the human player because torpedoes already communicate danger through visible travel.

Smallest implementation: For each candidate destination, project relevant torpedo trajectories and estimate the probability and consequence of a hit before the ship's next movement opportunity.

Add expected projectile damage to the existing destination threat calculation. Avoid building a general predictive combat search.

Simulator test: Run torpedo-heavy encounters with identical mechanics and the existing versus predictive threat scorer.

Primary metrics:

Incoming torpedo hit rate.

Damage avoided through movement.

Distance traveled in response to incoming torpedoes.

Retained outgoing fire.

Win rate and round count.

Add a counterfactual measure: whether an available alternative destination would have avoided a hit that the original choice suffered.

Biggest risk: If torpedoes are already easy to dodge, accurate forecasting could make them ineffective against the bot. Evasive movement also needs to respect weapon commitment, activation timing, and any homing rules.

Do not silently strengthen torpedo tracking to compensate until the defensive behavior has been measured.

9. Persistent tactical course

BUCKET C - SMALL BOT MEMORY CHANGE - MEDIUM PRIORITY

Description: Remember a ship's intended tactical destination for a short period instead of recalculating an entirely independent goal every activation.

An assigned flanking position, preferred range band, or screening location should persist for approximately two activations unless events make it inappropriate.

Why movement increases: The current bot can change its preferred endpoint every activation as enemy locations and threat values change.

That creates small, locally sensible adjustments without sustained positional progress.

A stable destination allows a ship to complete a longer maneuver across multiple activations rather than repeatedly restarting its decision process.

Smallest implementation: Save a target, approach sector, and preferred range band per ship.

Retain them until the destination becomes invalid, the target disappears, the ship faces critical danger, or a significantly better tactical opportunity appears.

The bot still enumerates legal moves every activation. It does not commit blindly to a physical path.

Simulator test: Compare a scorer that replans from scratch with one that retains the same tactical goal for up to two activations.

Primary metrics:

Multi-activation net displacement.

Frequency of reversing direction.

Percentage of assigned tactical positions reached.

Improvement in eventual firing geometry.

Combat performance.

Biggest risk: Persistent plans can become stubborn plans. In alternating activation combat, an enemy can invalidate a maneuver before it completes.

Emergency overrides must take priority over commitment.

Recommended implementation order

I would not build all nine ideas together. The key is to separate whether the problem lies in scoring, missing combat incentives, or the bot's inability to execute a longer plan.

Step 0: Instrument combat movement. Question: are ships actually changing tactical positions?
Step 1: #7 Two-pass selection. Question: can better scoring produce longer movement with existing rules?
Step 2: #1 Evasive translation. Question: does a mechanical reward change combat behavior?
Step 3: #4 Future firing value. Question: will ships invest in a better position next turn?
Step 4: #5 Attack-lane coordination. Question: can ships occupy different useful positions without sacrificing focus fire?
Step 5: #9 Persistent course. Question: can they complete those maneuvers?
Step 6: #8 Predictive torpedo avoidance. Question: can existing projectiles create tactical movement?
Step 7: #2 Rear-quarter pressure. Question: is another directional combat incentive needed?
Step 8: #3 Range specialization. Question: does differentiated weapon positioning improve fleet identity?
Step 9: #6 Spatial influence fields. Question: are richer positional models worth their complexity?

Steps 7-9 are conditional. If earlier changes produce good maneuvering, there is no reason to add rules or infrastructure merely to make the AI more sophisticated.

Measurement and acceptance

The existing measurements need a few additions. In particular, board coverage and move rate are inadequate primary success criteria for this project.

Metrics: post-contact net displacement (ships actually change position, rather than count movement along loops); long move-and-fire share; multi-activation displacement; shot-origin diversity; attack-bearing diversity; tactical position payoff; combat-phase coverage.

For every experimental change, use paired seeds, swapped starting sides, mirror fleets, and the 1.25 speed/range baseline. Preserve encounter-type reporting rather than judging only aggregate results.

Provisional acceptance gates:

Approximately 20-30% improvement in mean post-contact net displacement.

A meaningful increase in long moves that also fire, not walking-only turns.

Improved positional payoff, not simply more hexes traveled.

No material degradation in encounter completion, fight duration, or previously balanced win splits.

No rise in objective score rushes or obviously circular movement.

These are experimental targets, not predictions of what the simulation will show.

Also inspect a small set of battle replays. A bot can improve all movement statistics while producing an unconvincing battle.

My top three

1. Evasive translation (#1). Best direct answer to the owner's complaint. It creates a rule-level reason to move during a firefight, makes speed a survival characteristic, and gives players immediate feedback. The bot can learn to value it through the existing threat scorer.

2. Combat-preserving movement selection (#7). Highest-value first experiment. It requires no new gameplay rule and directly challenges the local-optimization failure identified by the measurements. If it succeeds, the team learns that substantial improvement was possible without a new subsystem.

3. Coordinated attack lanes (#5). Strongest answer to the spatial concentration problem. Independent ships optimizing against the same enemy naturally converge. Assigning distinct, useful combat positions is more promising than strengthening a generic objective attraction or enlarging the board.

Final council recommendation

Prototype #7 first, then #1, then #5. Use #4 and #9 if the bot identifies useful positions but fails to travel toward or hold them.

I would explicitly defer mandatory movement, complicated momentum systems, simultaneous orders, and full-board influence maps. The evidence does not establish that Voidsworn needs them, and some could undermine its existing alternating-activation combat.

The desired experience is not six ships racing around a map. It is six ships making recognizable tactical maneuvers: a fast attacker taking the long route to a vulnerable rear, a heavy ship withdrawing to preserve its firing range, a screening vessel crossing to intercept danger, and a battleship deliberately accepting exposure because holding its firing position is worth more than evading.

Success is when the player can answer, "Why did that ship move there?" and the answer is something better than "Because it had movement points left."
