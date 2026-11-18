# Leg: DeepSeek (DeepThink on, Search off; verified before and after)
# AI behaviour improvements, issue 1048. Model's response, verbatim.

## Problems a player would notice

- **Veteran ships die unbraced when their own numbers say brace.** AI-1 (BLOCKER): a veteran at 63% hull with a spent gun moved 8 to 4 hexes toward the enemy line, fired nothing, and ended unbraced under 32 expected threat. The mid-move volley path returned before the veteran brace decision its own numbers satisfied. The brace logic also lives in three places with three condition sets, so veteran survival looks inconsistent. Current main may have moved since the pin; the AI-1 test status on main is NOT CHECKED.
- **A cheap frigate and a capital price death the same.** AI-3: two movers identical in normalised numbers, differing only in hull value cp1 vs cp5, accepted the same lethal hex at exactly the same kill value 40. A player sees capitals take screen-level lethal risks.
- **Torpedo boats advance when they cannot shoot.** AI-4: a ship whose only gun is a reloading torpedo closed 10 to 6 hexes against unarmed targets instead of holding or kiting. The leash runs off the spent gun's minimum range even when nothing can bear.
- **Carriers dump wings into threat and leave them.** AI-5: the carrier launches pre-move from the launch hex nearest the enemy into 9 expected threat while threat-free launch hexes exist; the wing is then left behind when the carrier moves.
- **Fleets beeline and clump; objectives do not spread them.** Sim evidence: on big maps both fleets beeline and clump; no tested objective variant - plural sites, rent, pull weights up to 4.0, majority scoring - spread the battle under the current scorer. The scorer prices combat value for the moving ship and cannot see off-fleet objective value.
- **Post-contact battle reads as a small-move slugfest.** Feel data: 91-94% of post-contact activations already move, but the perceived slugfest is small moves of 2.3-2.8 hexes. The AI is not blind to movement defence; the gap is magnitude.
- **Role/formation play is flattened.** The movement scorer is a single attractor, with a Hegemony-only formation pull and escort spacing around the flagship only on flagship objectives. Outside those cases, ships do not visibly screen, escort, kite, or hold stand-off roles.

## Ranked improvement proposals

### 1. One veteran damage-control/brace arbiter

**Decision change:** Replace the three brace condition sets with one post-volley, post-final-position evaluator using final threat, hull, own offense, spent weapons, and path. Veteran braces when its own conditions are met; the mid-move volley path cannot return before that decision. Normal difficulty keeps only the simple fallback.

**Other game:** XCOM 2 enemy Hunker Down: low-HP/flanked enemies choose a visible defensive posture instead of advancing. The key is one readable survival decision, not three hidden ones.

**Build cost:** Small - consolidate existing checks and add a regression test; mostly logic cleanup.

**Sim proof:** Re-run the AI-1 scenario; metric "unbraced veteran under threat where brace condition is satisfied" goes to zero. Also check veteran brace rate when threat >45% hp and hull <70%, damage taken per veteran survivor, player win rate unchanged, median rounds not longer. Setup: paired veteran-seat seeds at current main.

### 2. Objective-aware movement scorer

**Decision change:** Add a separate, capped objective-value term to the movement score: off-fleet holding value, plural-site priority, majority/rent value. Do not multiply all score terms; keep combat scoring additive and add objective value as its own attractor. This is the untested fix named in the sim evidence: an objective-aware scorer, not more objective types.

**Other game:** Company of Heroes 2 AI capture-point priority: squads are assigned to capture/hold points based on point income and threat, not just enemy proximity.

**Build cost:** Large - new scoring term, tuning, and acceptance tests across map/objective variants.

**Sim proof:** Big maps with plural sites, rent, and majority scoring; metrics coverage up, clustering down, objective hold time up. Guardrails: player win rate must not rise like the multiplicative test (5/24 -> 13/24), median rounds must not stretch like 9.5 -> 11.0, and damage per round stays stable. Setup: identical seeds, paired player-vs-AI retest.

### 3. Carrier launch scoring and sequencing

**Decision change:** Score launch hexes by expected threat, wing survival, carrier final hex, cohesion/support, not distance only. If pre-move launch is unsafe and a safe alternative exists, do not launch there; consider move-then-launch when safe. Do not strand the wing behind the carrier.

**Other game:** Homeworld carrier Guard/Retreat behaviour: strike craft launch and return around a protected carrier position rather than a fixed nearest point.

**Build cost:** Medium - isolated to carrier pre-move ability and launch scoring.

**Sim proof:** AI-5 setup; metrics: launches into threat while safe hex exists down, wing-carrier distance down, wing survival up, carrier damage not worse, player win rate stable. Also confirm carriers still launch under pressure so they do not become passive.

### 4. Value-scaled death cliff

**Decision change:** Replace the flat -25 death-cliff weight with a penalty scaled by ship cp/fleet value and expected loss, capped to avoid cowardice. Keep it veteran-first; normal can stay simpler.

**Other game:** Total War campaign AI army-loss aversion by unit cost/strength balance: high-cost units are withdrawn rather than traded like cheap ones.

**Build cost:** Small - one weight becomes a scaled term; tuning is the main work.

**Sim proof:** Re-run the AI-3 sweep: cp1 vs cp5 movers should now accept lethal hexes at different kill values. Metrics: capital loss rate down, frigate screening unchanged, player win rate and median rounds stable. Setup: the existing cp1/cp5 lethal-hex sweep.

### 5. Bearing-weapon approach leash

**Decision change:** Compute the leash only from weapons that can bear/fire this activation. Ignore spent/reloading weapons. If nothing can bear, hold at safe/objective range or reposition to reload; do not close merely because a spent gun has a minimum range.

**Other game:** Total War artillery Skirmish Mode: ranged units without a useful shot fall back rather than close. Also StarCraft II kite micro: units maintain range while weapons are on cooldown.

**Build cost:** Small - leash filter and a few condition changes.

**Sim proof:** AI-4 setup; metrics: hexes closed while no bearing gun goes to zero, hold/kite distance preserved, torpedo shots per battle not down, damage taken not up, player win rate stable. Add a stall guard: median rounds must not rise.

### 6. Role-aware stance weights

**Decision change:** Stop using one attractor for every ship. Add visible role stances: capital stand-off, screen escort, torpedo kite, carrier rear. Keep faction profiles and normal-difficulty simplification; veteran gets the sharper role weights.

**Other game:** StarCraft II unit-role micro: zealots front-line, stalkers kite, colossi stay behind; formation keeping is role-dependent, not one blob target.

**Build cost:** Medium - role tagging plus scoring terms and tuning.

**Sim proof:** Mixed fleets on flagship objectives; metrics: clustering down, coverage up, escort spacing around flagship improved, capital damage taken down, carrier distance preserved, player win rate stable. Setup: flagship-objective maps with mixed roles.

### 7. Conditional no-shot finish-move

**Decision change:** Only units that fired nothing or had no bearing shot get a bounded second reposition after the volley. Units with shots keep the current single-pass. Cap displacement and threat exposure.

**Other game:** XCOM 2 no-shot fallback to cover/overwatch: units without a shot reposition to cover and take a defensive action rather than shuffle in the open.

**Build cost:** Medium - needs a restricted second pass and tuning.

**Sim proof:** Base-stats post-contact setup; metrics: displacement among no-shot activations up, damage per round unchanged, player win rate unchanged, median rounds not longer. This is deliberately narrower than the failed two-pass test, which bought 20-23% more displacement but lost damage and wins at a 10% score budget.

## Recommended first three, in order

1. **One veteran damage-control/brace arbiter.** First because AI-1 is the blocker and the three-place brace logic makes the AI look dumb in a high-salience moment: a veteran dying unbraced under threat. It is small, testable, and establishes one readable survival rule.
2. **Objective-aware movement scorer.** Second because beeline/clump is the biggest macro feel problem, but it is large and risky: the sim already shows that naive spread - multiplicative scoring - makes the AI fight worse and lengthens battles. It should come after the brace baseline is clean and be gated by combat-loss and stall metrics.
3. **Carrier launch scoring and sequencing.** Third because AI-5 is visible, isolated, and medium cost. It can ship while the objective scorer is being tuned, and it directly fixes "carrier throws wings into flak and abandons them."

Order matters because the first is a regression/consistency fix, the second is the highest-feel but highest-risk scorer change, and the third is an isolated visible fix that does not depend on the scorer rewrite.

## What could make the AI feel worse to fight

- **Naive spread/objective weighting:** multiplicative scoring already raised player win rate from 5/24 to 13/24, reduced veteran survivors, and stretched battles 9.5 -> 11.0 median. If objective weight is too high, the AI plays tag, ignores the player fleet, and stalls. Cap objective value and require stable damage per round.
- **Always-on veteran brace:** if veterans brace too often, they become damage sponges and fights slow down. Keep thresholds, keep the tradeoff visible, and let normal difficulty use the simpler fallback.
- **Too-strong value-scaled death cliff:** capitals may become cowardly and never commit, making them unpunishable. Cap the penalty and keep it veteran-first.
- **Carrier safety at all costs:** a carrier that never launches under pressure becomes passive and unreadable. Safe launch must still have risk/reward and objective pressure.
- **Bearing-weapon leash with no cap:** torpedo boats can kite forever. Add a leash/objective cap and watch median rounds.
- **Role stances as hidden special cases:** role behaviour must be legible from ship class/faction. Readable and fair beats optimal; telegraph veteran sharpness through visible stance/launch/focus behaviour, not hidden exceptions.
- **Broad two-pass movement:** the tested two-pass bought displacement but failed the "no damage loss" bar. Restrict any finish-move to no-shot units, or it will feel passive and stall-prone.
