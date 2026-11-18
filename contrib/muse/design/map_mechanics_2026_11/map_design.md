# Making the whole map matter: chaired design (Voidsworn battle design round)

Commissioned by Ryan, Nov 17, 2026. Council: blind Rey (written first), DeepSeek, Qwen, Flash. Grok seat parked by Ryan (grok.com bot wall). Evidence: the 1004 speed sweep (864 battles), the range sweep (1,296 battles), and this round's coverage probes (324 battles, measure_map.js, 12 seeds per config, medians). Full pack and leg texts sit beside this doc in the job folder.

## Verdict

GO WITH CONDITIONS. The diagnosis is unanimous across all four legs and confirmed by the probes: every encounter defines exactly one point of value, both fleets converge on it, and the rest of the map is margin. The fix is to pluralize the points of value, then make deployment and reserves decisions about them. The condition: each build lands behind its probe, with the pass numbers in section 4, and nothing ships on argument alone.

## 1. Diagnosis (chaired, unanimous)

A single-attractor objective makes position interchangeable, and interchangeable position makes the board irrelevant (Qwen's sentence, adopted). Speed sets how fast a fleet reaches the one point; range sets how close it must get; neither creates a second place worth being. Deployment distance looked like the master lever only because it is the one axis along which the single attractor can be displaced.

Probe confirmation, medians:
- Rout coverage falls as maps grow: 0.174-0.181 (30x22), 0.144-0.160 (34x24), 0.118-0.135 (38x26). Bigger maps are empty margin around the same meeting point.
- No existing objective beats the rout baseline on coverage. Ambush is a knife fight (move-only 1.7-2.8%, first shot activation 0). Defend parks at the station. Hold is the baseline with a relay nearby. Flagship is baseline-shaped and longer.
- Intercept's high combined coverage (0.163 / 0.147) is one side's forced march: enemy coverage 0.095-0.100 against player 0.063-0.072. It is the exception that proves the rule (DeepSeek).
- Asymmetric speed buys win rate (7-8 of 12), not map use. Asymmetric range stretches mean firing range (3.44 to 3.84 at x1.5) and buys almost nothing else. Qwen's refinement, adopted: speed does express itself, as a race advantage to the one point. The fix is to give it somewhere else to go, not to blunt it.

## 2. Design principles (chaired set)

1. Two attractors minimum. Every encounter presents at least two spatially separated things worth being at, so a fleet must split, choose, or sequence. A single objective point is banned as a shape.
2. Position pays rent. Holding ground must beat passing through it, or nobody holds. This is what makes range a position to defend and speed the tool that attacks positions.
3. The current bot must be able to see the value. A mechanism registers under the existing objective scoring, or it names exactly one added bot term. If the sim cannot measure it, it is a promise, not a design.
4. Data-shaped before logic-shaped before new-subsystem-shaped. Parity cost (browser copy plus Godot) scales with subsystem count. Rank honestly, in agent passes and files touched.

## 3. Chair's code check (what the legs got right and wrong about testability)

Checked against battle.js and sim3d.js in the sim source, Nov 17, 2026:

- The objective is a single object with a single hex. botObj (sim3d.js line 44) scores hold as hdist(v, o.hex) * 1.6; the veteran aiObj variant and objectiveTick (battle.js) also read o.hex singular, and hold keeps one score pair. So plural sites are NOT a pure data edit (Flash's "testable now, uses existing objective scoring routines" and Qwen's "possibly one line" both understate it). DeepSeek's framing is the accurate one: objective data plus one scoring generalization, namely min-distance over a sites list in botObj and aiObj, and any-site control in objectiveTick. That is still the smallest real fix in the round: 1-2 passes, about 3 files per copy.
- Hunt's degeneracy is structural, confirmed in code: hunt deploys in line mode (battle.js line 348), the flagship is simply the priciest enemy hull in that line (line 377), and the hunter's bot pulls toward it at weight 2.5 (botObj). Correction to this doc's first draft: the flagship does have a flee term in the shipped AI (aiObjScore: it runs from the nearest hunter, capped once it is 9 hexes clear), but line deployment starts it inside weapon reach at activation 0, so the term never gets to express itself; it is caught in the first exchange. Qwen's assumed flee logic (the fleet rout flee at two thirds lost) is a different rule and does not apply. So a hunt fix needs deployment separation first; whether it needs any new bot term is an open question the deployment change may answer by itself (DeepSeek asked for one; the code suggests it may already exist).
- Qwen's hunt arithmetic contradicts hunt's own clock: a chase lasting 8-12 rounds cannot happen inside a jump-out at the end of round 6. Separation must be tuned so contact lands around rounds 3-4, leaving 2-3 rounds of fighting before the jump.
- One prediction split the council could not settle by argument, recorded as an open test: under plural sites, DeepSeek expects move-only activations to RISE 5-10 points (fleets transit between sites), Qwen expects them to FALL below 16% (ships cycle between sites and fire). Both cannot be right; the build 1 probe decides it, and either result is informative.

## 4. The builds, in order

### Build 1 (first): plural sites, starting with hold
- Change hold from one relay to three, placed in a triangle with at least 10 hexes mutual separation on 34x24 and at least 12 on 38x26. Win condition unchanged in shape: a ship beside a relay with no enemy there at round start scores; any relay scores toward the same 3. Generalize B.obj to a sites list; botObj and aiObj take min distance over sites; objectiveTick checks control at any site.
- Arena weighting for hold shifts toward shapes that put terrain between the relays (hourglass, lanes, archipelago), per Qwen.
- Size: 1-2 passes, about 3 files per copy (objective data, bot scoring, objective tick), plus parity.
- Probe: same harness as this round, hold on belt, station, storm at 34x24 and 38x26, 12 seeds. Pass numbers (Qwen's set, adopted): combined coverage above 0.18 on 34x24; both sides above 0.09 each; rounds inside 8-12; no single hex cluster drawing more than 40% of shots (needs a shot-location tally added to the measure script, small). Move-only is reported, not gated, because the council split on its direction (section 3).
- Why first: unanimous across all four legs, smallest change that attacks the attractor directly, and its result validates or kills the diagnosis for everything below.

### Build 2: the hunt fix
- Deploy the flagship on the far edge, out of immediate reach, with 2 escorts screening 4-6 hexes ahead; hunters deploy on the near edge as now. Add one bot term: the quarry moves to maximize distance from the nearest hunter toward its exit side until the jump-out round. Tune separation so first contact lands at rounds 3-4 on 34x24 (inside the existing round 6 clock; the clock does not move).
- Rejected from the legs: Flash's cannot-be-targeted-until-round-3 gate (a new invulnerability rule; the screen and the distance do the work), Qwen's flagship speed bonus and activation-order change (held in reserve as tuning dials if the probe shows the chase still collapsing; a permanently faster flagship is a stat exception the design does not need yet).
- Size: 1 pass deployment data plus 1 small bot term, about 2 files per copy.
- Probe pass numbers (DeepSeek's, adjusted to the clock): first shot activation at least 5; rounds 4-6; hunter win rate between 4 and 9 of 12 (from 12 of 12); coverage above 0.10 on 34x24.

### Build 3: plural sites extended
- Defend: station plus two outposts (either scores pressure; the station battery precedent already makes a held site fight back). Intercept: two transport groups on separate, offset lanes, so the interceptor must split or choose. Break: exit gates on two non-adjacent edges.
- Same sites generalization as build 1, so this is data work once build 1 lands: 1 pass per encounter, mostly data.
- Probe: per-encounter coverage and both-sides split against this round's baselines (defend 0.133 / 0.112, intercept 0.163 / 0.147 with its lopsided split, break 0.121 / 0.099). The intercept pass condition is the split, not the total: player coverage must rise toward the enemy's, or it is the forced march again (DeepSeek's rejection test, adopted).

### Build 4: reserves as a timed commitment
- A player may hold up to 2 ships in reserve at deployment (the reserve flag already exists). From round 2, reserves may be committed at a board edge in the player's half, not within 3 hexes of an enemy. Speed buys entry: a ship with speed 5 or better may enter from a flank edge as well as the home edge (blind Rey's mechanism, adopted; it is the one proposal in the round that makes speed a strategic resource rather than a movement stat).
- Bot term (one): commit when the objective score at the nearest contested site drops below a threshold, entering at the edge nearest that site (Qwen's form).
- Size: 2 passes, about 3 files per copy.
- Probe: mid-game coverage (rounds 3-6 sampled separately), second-contact count (a new contact cluster after round 3), reserve ship time-to-first-shot by speed.

### Build 5: deployment as a decision (only after builds 1-3)
- Form: 2-3 named packages per encounter, chosen simultaneously and hidden until both commit. A package bundles band depth, lateral offset, and reserve split (examples: forward/left, standard/centre, deep/reserve-heavy). Not free placement; packages are data (DeepSeek and Qwen converge here; Flash's template version is the same idea with fixed hexes).
- Anti-dominance is empirical, not argued: run every package pairing, 12 seeds each; no package may win more than 60% across pairings, and the win-rate spread across pairings stays within about 15 points (Qwen's test, adopted). A dominant package is a geometry bug: adjust site placement or package offsets, do not nerf the package.
- Sequencing is a hard condition (DeepSeek, adopted): before plural sites, deployment choice collapses to one solved band depth, and the chair would refuse it as the main fix.

### Later candidates (not in the first five)
- Terrain that pays rent (Qwen 3b, blind Rey 5): bonus tags on existing terrain hexes (sensor ridge: +1 effective range while occupying; debris: shield regen; firing lane: to-hit), placed on transit routes between sites, with one small bot term (bonus value as a tiebreaker in destination scoring, about 0.3x objective pull). Build after plural sites, when the transit routes exist.
- Standoff dividend (blind Rey 6): a ship that fires at long band without having moved keeps a facing or accuracy benefit. Smaller than Qwen's threat-projection rule (3e), which is the same instinct at subsystem cost; threat projection is parked unless the dividend proves the appetite for area denial.
- Moving relay / patrol site (DeepSeek): the site cycles among 3 hexes every 3 rounds. A variant to probe after static plural sites are measured, not before.
- Terrain lane curation (DeepSeek): honest support work (its own estimate: coverage +0.01-0.02 alone), folded into build 3's data pass rather than standing alone.

### Companion item (campaign level, not a map fix)
Roll the existing encounters for real: campaign column 0 and boss fights currently default to rout (bosses: rout, rout, ambush, per the code's own note that more waits on a design call). This round is that design call's evidence: once builds 1-3 land, weight the full pool for column 0 and bosses. Data change in the encounter roll. It does not fix map use inside a battle and is not sold as doing so; it makes the fixed objectives the game actually played.

## 5. Refusals (consolidated, unanimous unless noted)

- Bigger maps as a fix. Coverage falls with size (0.18 to 0.12); area without distributed value is dead space at any size.
- Global speed or range buffs as pacing fixes. Measured across 2,160 battles: they change the walk, not the reasons.
- Random events as structure. Adds variance to when things happen, not to where they matter (Qwen).
- A terrain-only fix. One site remains one attractor (DeepSeek).
- Free deployment bands without hidden, opposed choice. They solve to one dominant package.
- Fog of war over the full map (Qwen). Expensive in parity, hides the one point of value without creating a second, and the sim bot cannot model it.
- New encounter types beyond the existing eight. The eight are sufficient once their geometry is fixed.
- Speed as activation currency (Qwen 3f, scoped and set aside by its own author). Activation-scheduler rework, highest parity cost, unmeasurable until built; revisit only after builds 1-5 are measured.
- Anything that needs the bot rewritten before it can be tested (blind Rey). One named bot term per mechanism is the budget.

## 6. What would change this design

- If build 1's probe misses its pass numbers (coverage stays at baseline, or one relay still draws most shots), the single-attractor diagnosis is wrong or the bot's nearest-site pull is stronger than the geometry, and builds 3-5 should not proceed on this argument. The fallback investigation is the bot's scoring weights, not more content.
- If plural sites work for hold but the intercept split does not move, traversal objectives need route-level value (partial progress per lane crossed), which is a different mechanism than sites and needs its own round.

## Leg record

- Blind Rey (written before probes and council): diagnosis in three causes (objective monoculture in practice, convergent tactical logic, no persistent value away from the fight); proposals: roll the pool, split the point of value, priced deployment, reserves with a clock and speed-linked entry, ground that pays rent, standoff dividend. Its probe prediction (non-rout objectives raise coverage only modestly unless traversal is forced) is what the probes showed.
- DeepSeek: the most disciplined leg on testability; named the bot terms the others assumed away; its intercept rejection test and deployment sequencing condition are adopted. Its coverage gain estimate (+0.03-0.06 on 38x26) is the conservative bound against Flash's 0.20 target.
- Qwen: the deepest leg; the diagnosis sentence, the success metrics for build 1, the anti-dominance test, and the terrain rent detail are adopted. Slips recorded: hunt chase length contradicts the round 6 clock; flee logic assumed where none applies to the flagship; multi-site cost understated as possibly one line.
- Flash: correct diagnosis and the same first build; the weakest leg on costing. Slips recorded: plural sites claimed testable now on existing routines (the objective hex is singular in code); the hunt targeting gate is a new rule presented as a data change; its center hazard strip duplicates what the corridor and lanes shapes already do.
- Grok: seat parked by Ryan, Nov 17, 2026 (grok.com bot wall persisted through reloads, a fresh route, and Ryan's own manual attempt). The seat can still be run against this doc before build 1 is commissioned if the wall clears.

## 7. Sizing and scaling test (Nov 17, 2026, 384 battles, at Ryan's direction)

Ryan's ruling: the design above answered why the map does not matter, but his original ask also covered map sizes and speed/range scaling, and the two are to be tied together and tested, not argued. So build 1 was prototyped in a local copy of the sim (sites list on the objective, botObj and aiObjScore generalized to the nearest site with the veteran per-site two-ship pull kept, objectiveTick scoring any uncontested site toward the same 3, both sides able to score in the same round) and run on the belt map, mirror fleets, 12 seeds per config: hold with 3 relays (h3) against hold with 1 relay (h1) and a rout reference, at 30x22, 34x24, 38x26 and a new 42x30, each under five stat arms (base; speed x1.5; range x1.5; both; speed x2 + range x1.5). Achieved minimum site separations: 7-8 hexes (30x22), 10 (34x24), 11 (38x26), 12-13 (42x30); the strip arena, not the canvas, is what limits separation. Sanity: rout baselines in the patched copies reproduce the earlier probe numbers exactly (0.174 / 0.144 / 0.118), so the prototype changed hold only. Medians:

Coverage, h1 vs h3 at base stats: 30x22: 0.163 vs 0.160. 34x24: 0.128 vs 0.131. 38x26: 0.113 vs 0.110. 42x30: 0.090 vs 0.089. Per-side splits under h3 stay at baseline levels (best case 0.072 / 0.079 on 34x24). Shot clustering (share of shots whose target falls in the single busiest hex-plus-neighbours cluster) is unchanged: h3 0.44-0.49 against h1 0.43-0.48. Rounds shorten slightly under h3 (9-10). Move-only under h3 vs h1: 15.5% vs 17.1% (30x22), 19.6% vs 21.5% (34x24), 28.0% vs 29.0% (38x26), 35.8% vs 33.3% (42x30).

Verdicts:
1. Build 1 as prototyped MISSES its section 4 pass numbers. On 34x24 the targets were coverage above 0.18 (got 0.131), both sides above 0.09 (got 0.072 / 0.079), cluster at most 0.40 (got 0.48); only rounds (10.0, target 8-12) passed. Plural sites alone do not spread the battle at any size. Per section 6, builds 3-5 do not proceed on the original argument.
2. The council's move-only split is settled: neither side. DeepSeek predicted a 5-10 point rise, Qwen a fall below 16%; measured movement is essentially unchanged, because the fleets do not actually split. The transit both legs imagined never happens.
3. Why it failed (chair's reading): the prototype changed what the scoreboard counts, not where ships go. In the bot's movement scoring, offense against the enemy fleet dominates and the objective term is a tiebreaker that only binds when a ship has no shot; the veteran AI by design sends only two ships per site. Holding a relay pays score, slowly (3 round-starts), and pays nothing the combat terms can feel, while killing the fleet in front of you pays immediately. Principle 2 (position pays rent) was the load-bearing one, and build 1 did not implement it. The diagnosis (single attractor) survives only in a sharper form: the attractor is not the objective hex, it is the enemy fleet itself, and a site the fleet can ignore is not an attractor at all.
4. Scaling under the new geometry behaves as it did under the old. Speed x1.5 shortens battles (rounds 6-8) and does not lift coverage; on 42x30 it halves the wait for first contact (activation 24 to 13) without making the map used. Range x1.5 stretches mean firing range everywhere (to 4.3-5.0 from about 3.1) and, under h3, brings first contact much earlier on 34x24 (activation 12 to 2) and 42x30 (24 to 13), but coverage stays flat. Combined arms cut move-only hard on 30x22 and 34x24 (down to 0.8-12.0%) and barely on 42x30 (19.5-21.4%). The extreme corner (speed x2 + range x1.5) is the only arm that moves first contact on 38x26 (13 to 6), and coverage there still falls slightly (0.102). No stat arm, at any size, under either geometry, raises coverage. The sweeps' conclusion stands and is now geometry-independent: stats change the walk and the fighting distance, never the spread.
5. Expansion to 42x30 is REFUTED under both geometries. It has the lowest coverage (0.080-0.103 across all configs), the latest first contact at base stats (activation 24, a full extra approach phase over 38x26), and the highest move-only shares (up to 35.8%). Even with relays at 12-13 hex separation, the fleets cross more empty space to reach the same fight. There is no size at which area substitutes for value.
6. Size roles, now measured under both geometries: 30x22 is the knife-fight size (contact at activation 0-2, best coverage). 34x24 is the sweet spot for objective play (earliest relative contact of the big sizes, best big-map coverage). 38x26 is playable but pays an approach tax (first contact 12-13) that only the extreme stat corner relieves. 42x30 is out.

The next test the evidence points to (not yet run): sites plus rent. Give a held relay a battery, on the defend station precedent (stationFire already exists): a relay fires on nearby enemies for the side holding it. That puts site value inside evalOffense and evalThreat, the terms that actually move ships, instead of in a score race the bots can ignore. Same harness, same matrix at 34x24 and 38x26, base stats plus the range x1.5 arm. If coverage still does not move with rent on the sites, the attractor really is the fleet alone, and the honest redesign target becomes the combat scoring itself, not objective geometry.

### 7b. Follow-up probes (Nov 17, 2026, evening, 72 more battles)

Three more arms at 34x24 and 38x26, base stats, 12 seeds each, against the h3 controls above, run to find out whether the failure was the mechanism or the tuning:

- Sites plus rent (a held relay fires once per round at the nearest enemy capital within 5 hexes, 12 damage, on the stationFire pattern): coverage 0.134 / 0.113 against controls 0.131 / 0.110; cluster unchanged; player wins tick up slightly in all four cells (the player bot contests relays with its whole fleet, the veteran AI with two ships per site, so the player collects more battery fire). Rent as outcome pressure does not spread the battle, because nothing in movement scoring knows the battery exists; it is chip damage that lands wherever the fleets already are.
- Sites with the objective pull cranked (botObj and aiObjScore hold weight 1.6 to 4.0, stay bonus raised): coverage FALLS (0.123 / 0.088), move-only jumps (35.8% / 60.6%), cluster rises (0.59 both), rounds collapse (5.0 / 4.0). A louder objective converts firing turns into transit turns and ends battles in score rushes; the fleets pile onto relays instead of onto each other, the same blob with a different centre. Player wins rise (8 and 9 of 12) on the bot asymmetry, an artefact, not a success.
- Sites with majority scoring (a side scores only while holding at least two relays uncontested): coverage 0.133 / 0.114, cluster unchanged, rounds lengthen (11.0 / 11.5, battles end by annihilation more often), player wins fall (3 and 2) because the player bot's nearest-site habit concentrates on one relay. Forcing a split through the scoring rule does not produce one either; the bots do not reorganize, they just score less.

Final state of the question. Across 456 battles, no objective-side variant spreads the battle: not more sites, not sites that shoot, not a louder objective, not a scoring rule that requires a split. The movement scoring sees the enemy fleet and almost nothing else, and anything it cannot see does not move ships, while anything that shouts over it degrades the fight. What does work, reliably, is the tempo and shape layer: range and speed dials change when contact happens, at what distance fleets fight, and how many turns are spent walking. If spread is ever to exist in this game, it has to be built inside the movement scoring itself (concentration costs, multi-direction attack value, per-ship assignment), which is a bot design project, not an objective or map project. The alternative the evidence supports: accept the convergent fleet fight as the game's texture, tune tempo with the stat dials per encounter and size, and spend the design budget on encounter variety (the hunt deployment fix, reserves, deployment packages), none of which depends on spread.

### 7c. The feel test: 1.25 speed and range, whole numbers (Nov 17, 2026, evening, 180 battles)

Ryan reframed the goal: not coverage for its own sake, but feel. Ships should read as fast spacecraft, movement should stay meaningful after the shooting starts instead of settling into a standing exchange, and the dial options should feel different from each other. So this run added post-contact movement metrics (share of activations after first contact in which the ship moves; share in which it moves and fires; hexes travelled per moving activation) and tested a symmetric 1.25 speed + range arm with all scaled values rounded to whole numbers (a range 5 gun becomes 6, speed 6 becomes 8), against base and 1.5 combined, rout and three-relay hold, 30x22 / 34x24 / 38x26, 12 seeds each.

Baseline correction first: in bot play the standing slugfest is not literal. At base stats, 91-94% of post-contact activations already include movement and 78-88% include moving and firing. What is small is the distance: 2.3-2.8 hexes per move, a shuffle inside the blob, which matches Ryan's feel report better than "nobody moves" would.

What 1.25 does (rout figures; hold tracks the same way): distance per move rises everywhere, 2.75 to 3.24 (30x22), 2.54 to 3.19 (34x24), 2.55 to 2.97 (38x26), roughly a quarter to a third more travel per activation. Move-only turns fall hard on 30x22 (15.9% to 3.8%) and 38x26 (27.8% to 18.2%), moderately on 34x24 (20.9% to 15.6%). First contact on 34x24 rout arrives at activation 4 instead of 12; 38x26 barely improves (13 to 12, the approach is simply long). Move-and-fire becomes the dominant pattern on 38x26 (78.0% to 93.1% of post-contact activations). Rounds shorten slightly (about a round). Coverage is flat, as expected by now. Against 1.5, 1.25 captures most of the feel change (distance per move 3.19 vs 3.94 on 34x24 is the one metric where 1.5 clearly goes further) with less tempo distortion; the returns diminish past 1.25, which supports Ryan's middle-ground instinct.

Two cautions. Whole numbers make the dial lumpy per hull: speed 5 gains 20% (to 6) while speed 6 gains 33% (to 8); range 5 gains 20% while range 6 gains 33%. That lumpiness is also a source of difference between options, since some hulls cross a whole-hex threshold and others do not, but it should be a chosen texture, not an accident. And the incentive structure is untouched: ships move because the bot repositions for arcs and threat, and bigger budgets make those moves bigger. Movement happens more and travels further at 1.25; it still does not buy anything new. If moving is to mean something, that is a mechanics question (what a ship gains by having moved), separate from stat dials.

Chair's verdict on the dial: 1.25 combined, whole numbers, is a defensible global feel setting on this evidence: faster contact on mid-size maps, visibly larger movement, far fewer dead turns, battles barely shorter, no coverage cost (there was none to lose). It is a pacing and texture improvement, not a positional one, and should be adopted, if adopted, in those words.
