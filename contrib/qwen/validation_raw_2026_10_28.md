# Qwen blind validation leg: learning-frame approaches and six faction cycles (Oct 28, 2026)

Chair note: filed verbatim from the model's reply (Qwen3.8-Max, both model gates passed). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://chat.qwen.ai/c/72d476fb-77f6-47be-a8a5-b59b68aff95b

# DESIGN VALIDATION REPORT

## PROOF OF READING

Sections read: EVIDENCE PACK title line · THE COMMISSIONER'S QUESTION · PREMISES · THE SYSTEMS AS BUILT · THE APPROACH UNDER REVIEW · THE SIX LEARNING CYCLES · LORE FACTS THE CYCLES MUST NOT CONTRADICT · WHAT TO JUDGE.

Overall verdict on the approach set: SOUND WITH CONDITIONS.

| Faction | Verdict |
|---|---|
| F1 Sunward Crusade | SOUND |
| F2 Hegemony | NOT READY |
| F3 Ashfall Hullbreakers | SOUND |
| F4 The Chorus | SOUND |
| F5 The Glasswrights | SOUND WITH CONDITIONS |
| F6 The Eclipse | SOUND |

## FINDINGS (ranked most severe first)

1. [BLOCKER] F2 Hegemony cycle contradicts L7.

The cycle states the Registry "reissues synchronized doctrine to all fleets at once" and that learning is "a software push: die, upload, update everyone's doctrine overnight." L7 permits no instant communication across sectors except within a single fleet's battle network or the Eclipse Archive. The Registry administers multiple fleets across sectors; it is neither exception. "Overnight" and "at once" across all task forces require FTL information transfer the lore explicitly forbids. (F2 mechanism as written: READ. L7 constraint: READ. Contradiction: INFERRED from the two.)

2. [FIX] F5 Glasswright cycle undermines A3's debrief premise.

A3 frames the end-of-run screen as "the debrief the next attempt inherits." F5 states a new run incorporates "everything recovered by its launch, not the fate of the fleet just played." The player who just lost run N sees a debrief, but the fiction says run N+1 does not learn from it. The failure-as-tuition framing is hollowed out for one-sixth of the player base. (A3 wording: READ. F5 exception clause: READ. Conflict: INFERRED.)

3. [FIX] F5 shard-recovery timeline creates a tempo fiction the game cannot honour.

The cycle says "uncrewed gatherer hulls recover [shards] over years" and the forge "casts continuously from shards of fleets lost long ago." A player starting run 2 thirty seconds after run 1 must be told their new fleet was cast from shards of a fleet that died years ago, not the one they just flew. The fiction implies waiting and staggered timelines; the game tempo is immediate and serial. A narrative wrapper (the queue, the staggered expeditions) is sketched but not yet sufficient to make the player feel their loss mattered now. (Shard timeline: READ. Tempo requirement: INFERRED from roguelite genre norms and P1's run cadence.)

4. [NOTE] F1 Crusade cycle under-uses the debt idiom mandated by L5.

L5 specifies losses are "recorded as debts owed, not sins or martyrdoms." The cycle describes the Hall of the Fallen as an archive where records are "studied by the next fleet." Study is adjacent to debt-keeping but is not the same idiom. The fiction should frame each unlock as a debt being paid down-the next fleet owes the lost fleet a better attempt-rather than as neutral scholarship. As written, the cycle could belong to any archive-keeping faction. (L5 wording: READ. F1 cycle wording: READ. Gap: INFERRED.)

5. [NOTE] A3 debrief risks formulaic repetition by run 4 at 80% loss.

By run 4 a typical player has lost three times. The debrief must name "sync progress named, mastery progress named, the specific unlock now affordable." If the player died early all three times (<10 renown each), the named lessons will be thin: a few renown, no threshold crossed, no unlock affordable. The first thing that feels false is the debrief insisting "this attempt taught" when the player died to the same sector-1 elite in the same way three runs running. (80% loss rate: READ. Debrief contents: READ. Repetition risk: INFERRED.)

6. [NOTE] F2 and F6 share the same information-theoretic shape.

Both cycles describe instantaneous, total, cumulative transfer of combat knowledge to all future units. F6 is lore-legal because L7 explicitly exempts the Archive. F2 is not. If F2 is redesigned to respect L7, the two will differentiate. As currently written, they are the same mechanism in different skins: die → all future forces immediately know. (F2 and F6 descriptions: READ. Structural equivalence: INFERRED.)

7. [NOTE] A2's "no single purchase is the difference" claim depends on LEGACY tier distribution.

LEGACY totals 635 renown across 12 upgrades. If the first three tiers (extra starting credits) cost, say, 30/60/100, a player on run 4 with ~150 accumulated renown can buy all three, creating a visible power spike that feels like a single purchase making the difference. The horizontal-first intent holds only if early LEGACY nodes are genuinely lateral (a starting relic, a salvage bonus) rather than raw stat additions. (LEGACY total: READ. Tier costs: not specified in pack; distribution concern INFERRED.)

8. [NOTE] F4 Chorus learning is passive evolution; player upgrade choice needs fiction support.

The cycle says "whatever killed the last brood is bred out or armored against." This is natural selection, not decision. The player selecting a specific LEGACY node or mastery threshold is making a choice, but the fiction implies the brood simply adapts without direction. The Chorus needs a thin fiction for player-directed adaptation (e.g., the flesh-shapers' residual coding, or the brood's tropism toward specific threats) to justify the player browsing an upgrade menu. (F4 cycle: READ. Player-choice gap: INFERRED.)

9. [NOTE] Heat's "worse omens" framing is thin for seven mechanically distinct rules.

A4 reframes Heat as "later attempts sailing a known route under worse omens for greater standing." Seven distinct self-imposed rules (each +10% renown) need seven distinct fictional justifications. "Worse omens" is a single mood, not seven. Without per-rule fiction, Heat reverts to a naked difficulty toggle and breaks P4's story-wrap requirement. (Heat count and bonus: READ. Reframe language: READ. Per-rule gap: INFERRED.)

10. [NOTE] F3 oral/physical learning creates a minor fiction-gameplay gap.

The Hullbreakers learn through "scar-stories" and being "suckled on the story." The actual gameplay is a menu of renown purchases and mastery thresholds. The pack does not describe how a menu interaction is fictionally presented as a pack elder telling a scar-story. This is a presentation-layer issue, not a structural one, but it is the cycle most dependent on UI fiction to land. (F3 cycle: READ. UI gap: INFERRED.)

## EXPLICIT CHECKS

### a. THE FRAME: does the learning frame cover doctrine, lineage, and memory equally?

Doctrine (LEGACY) maps cleanly to every faction: standing orders, software doctrine, pack law, bred-in adaptations, recast patterns, compiled baselines. Memory (core sync) also maps: the cores "recognise and trust" a line, which works for all six factions as a relationship between a patron and a recurring petitioner.

Lineage (mastery) is the tightest fit. The frame offers "an admiral's house, line, pack, or line of descent." This covers F1 (house), F3 (pack), F4 (brood descent), F5 (optical lineage), F6 (iteration chain). For F2, the Hegemony's identity is synchronisation under a flagship anchor (L6); an individual admiral's personal mastery sits uneasily with a doctrine that is supposed to be uniform and Registry-issued. The fiction must explain why one admiral's lineage grants options the Registry hasn't pushed to everyone. This is solvable but currently unaddressed. No track is fully resistant, but Lineage requires the most per-faction justification work.

### b. THE SET: are the six cycles genuinely six mechanisms?

| Faction | Mechanism | Tempo | Fidelity |
|---|---|---|---|
| F1 | Serial generational study | Slow (one generation) | Lossy (interpretation) |
| F2 | Centralised software push | Overnight (violates L7) | Lossless |
| F3 | Oral/physical inheritance | Seasonal | Lossy (memory degrades) |
| F4 | Biological evolution | One brood generation | Lossy (mutation) |
| F5 | Lagged optical replay and recasting | Years, staggered | Perfect but delayed |
| F6 | Instant versioning | Immediate | Lossless |

Five of six are distinct in both mechanism and tempo. F2 and F6 collapse into the same mechanism as currently written: both are instant, total, lossless transfer to all future units. They differ only in fiction (software push vs. compilation). If F2 is redesigned to respect L7-e.g., telemetry carried home by survivors, doctrine updated only when a task force returns to Registry space-the two separate cleanly. As written, they are one mechanism in two coats.

### c. TEMPO: does each cycle explain a player starting the next run immediately?

- F1: Yes. The next crusade is already being taught; the player steps into the next generation's fleet. No waiting implied.
- F2: Yes in tempo (overnight update), but only by violating L7. If fixed for L7, the answer becomes no: the cycle implies a delay the game cannot show.
- F3: Yes. "The pack that hunts you next season" implies a seasonal gap, but "next season" can be read as the next attempt; packs are raised continuously. Acceptable.
- F4: Yes. Brood generations are grown in sequence; the next brood is already in the vat when the last one dies.
- F5: Problematic. The cycle explicitly says the next run does not incorporate the fleet just played and that shard recovery takes years. The player clicks "new run" and must accept that their fleet was cast from shards of a fleet lost long ago, not the one they just lost. The "staggered expeditions" and "queue" language provides a structural excuse but not an emotional one. The tempo fiction requires the player to accept a lag the game does not make them feel.
- F6: Yes. Minds are already in the Archive; the next iteration compiles instantly. Perfect tempo fit.

Flagged: F5. Its fiction implies waiting, staggered timelines, and a learning lag the game's immediate-restart tempo cannot honour without a strong narrative bridge.

### d. THE SHAPE: tracing runs 1, 5, and 10

Economy summary (READ): ~100 renown per win, ~45 per mid-run death, <10 per early death. Total sinks: 635 (LEGACY) + 930 (Admirals) + 250 (variants) = 1,815 renown. Mastery capstone at 50 XP per admiral × 24 admirals. Full core sync at 25 protocols × 6 cores.

Run 1. The player has the Sunward Crusade's first admiral (free, 0 renown), a base fleet, no LEGACY upgrades, no variants, no core sync, no mastery thresholds. They face three sectors, a Nemesis, and a flagship boss per sector with a bare toolbox. P2 demands this be near-impossible; the economy confirms it. The player has nothing to buy and no options to widen. Expected outcome: early or mid-run death, yielding <10 to ~45 renown. The power source is purely player skill and basic game knowledge, which is insufficient by design.

Runs 2-4 (accumulation phase). Assume two mid-run deaths (~90 renown) and one early death (~8 renown): ~98 renown cumulative. The player can afford the first LEGACY tier (extra starting credits, likely 30-50 renown) and possibly the second admiral (30 renown). One hull variant (out of 12 purchasable) may be in reach. Mastery XP for the starting admiral sits around 6-10 (first threshold at 6: alternate starting fleet). Core sync at 2-4 protocols for one core (first tier at 4: improved offers). The toolbox has widened modestly: one new fleet option, a small credit cushion, slightly better core offers. This is horizontal growth. No single purchase trivialises a sector.

Runs 4-6 (first-completion window). Cumulative renown likely 200-350 (mix of mid-deaths and possibly one deep run). LEGACY has 3-4 of 12 nodes. Second admiral unlocked; possibly third (45 renown). One or two hull variants. Mastery at 6-16 for the main admiral (alternate fleet, wider aspect choice). Core sync at 4-12 for one core (improved offers, possibly a starting protocol). Heat is not yet available (requires first victory). The player now has genuine strategic options: alternate fleet compositions, a starting relic, a second Command option at mastery 16. Combined with four or five runs of player skill growth, the game's checks become coverable. First completion at runs 4-6 is plausible under this economy, provided LEGACY's early nodes are lateral rather than raw power (see Finding 7). The win itself pays ~100 renown, unlocking Heat and a visible jump in accumulation rate.

Run 5 territory. Post first win, the player has ~300-500 cumulative renown. First LEGACY tier complete. Two admirals at moderate mastery. One core approaching sync tier 2. Heat available: the player is now self-imposing difficulty for +10% renown. The fiction frame (A4) says "roughly a generation of attempts has sailed; the first doctrine tier is complete and one or two lineages are deep." This matches the numbers. The feel-shift from "surviving" to "optimising and experimenting" is real.

Run 10 territory. Cumulative renown likely 700-1,000+. Most of LEGACY purchased. Three or four admirals unlocked for the main faction, two or three at mastery 16-30. Core sync at 12-25 for one or two cores. Multiple hull variants. Heat at 2-4 rules. The long tail is mastery depth (30→50 XP), full core sync, Heat climbing, and faction-wide completion. No new systems are needed; the pull is depth within existing systems. A4's description matches.

Verdict on A2: The shape delivers P2 (bare toolbox run 1), P3 (distinct milestones at 1, 5, 10), and the runs-4-to-6 first completion, conditional on LEGACY's early tiers being genuinely horizontal rather than stat-stacking.

### e. DEFEAT: does the debrief framing hold at 80% loss?

The debrief-as-tuition works for runs 1-3: everything is new, every death buys a visible first (first renown, first threshold, first unlock). By run 4, the player has lost three times. The debrief must show different progress each time. The pack's answer-name sync progress, name mastery progress, name the specific unlock now affordable-is correct in principle.

The first thing that feels false: a run-4 death that yields 8 renown and crosses no threshold, where the debrief still insists "this attempt taught the Crusade something." If the player died in sector 1 to the same elite they died to in run 2, the named lesson is a lie or a platitude. The debrief must either (a) show micro-progress that is genuinely new (a specific enemy pattern logged, a route revealed, a Nemesis adaptation noted), or (b) acknowledge the repetition honestly: "The Crusade learned nothing new from this loss; the debt stands." Option (b) is riskier but more honest and fits L5's debt idiom. Without one of these, the framing wears out at run 4.

## RUN 1 / RUN 5 / RUN 10

Run 1. The player commands the Sunward Crusade's default admiral with a base fleet, no LEGACY, no variants, no core sync, no mastery thresholds. They know almost nothing about sector layouts, elite patterns, or the Nemesis. They are chasing survival in a game designed to kill them. They die in sector 1 or early sector 2. The debrief names the debt: a handful of renown, no thresholds crossed. The fiction says the Hall of the Fallen records this fleet's loss and the next crusade will be marginally better taught. The player feels outmatched and green, which is correct.

Run 5. The player has two or three admirals, an alternate starting fleet from mastery 6, a wider aspect choice, one or two hull variants, a starting relic from LEGACY, and one core approaching sync tier 1. They have won once (or are close). They know the sector structure, the Nemesis's adaptation patterns, and which elite fights to avoid. They are chasing Heat unlocks and the second mastery threshold. The fiction says a generation of crusades has sailed and the doctrine is thickening. The player feels competent and is beginning to optimise rather than survive.

Run 10. The player has most of LEGACY, three or four admirals with mastery at 16-30, two cores at sync 12+, multiple hull variants, and Heat at 2-4. They are chasing mastery 50, full core sync at 25, Heat 5+, and completion of all six factions' admiral ladders. No new systems are coming; the pull is depth, self-imposed difficulty, and faction completion. The fiction says the Crusade's debt ledger is long and the doctrine is now a library. The player is in the long tail, and the game is asking them to set their own goals.

## NOT CHECKED

- Actual LEGACY tier costs. The pack gives the total (635) but not the per-node distribution. The shape analysis assumes a spread; a front-loaded distribution would change the run-4 power curve.
- Mastery XP earn rate. The pack gives thresholds (0/6/16/30/50) but not how many XP per run or per battle. The run-5 and run-10 mastery estimates are rough.
- Nemesis adaptation specifics. The pack names the Nemesis but does not describe what it adapts to or how quickly. This affects whether accumulated options genuinely counter it or whether it scales to negate them.
- Core sync protocol earn rate. "Picking a core's protocols in-run raises its sync tier" but the number of protocols per run is not stated. The 25-protocol full sync timeline is estimated.
- Hull variant mechanical impact. 18 variants are listed as "sidegrades" but their actual mechanical spread is not described. Whether they are genuinely lateral or covertly vertical is not judgeable.
- Faction-specific starting fleets and how they interact with the six cycles. The pack describes cycles but not whether each faction's starting fleet is mechanically distinct.
- Heat rule specifics. Seven rules are mentioned but not described. The "worse omens" framing cannot be evaluated against actual mechanical content.
- The boot-time grant defect. Declared out of scope by the pack; assumed fixed for this review.

## QUESTIONS FOR THE DESIGNER

1. F2 and L7: The Hegemony's "overnight software push" across all fleets violates the no-FTL-communication rule. Is the Registry intended to be local to a single task force's battle network, or must the cycle be redesigned around light-speed-lag telemetry carried home by survivors? Stakes: as written, F2 is lore-illegal and structurally identical to F6; the fix determines whether the Hegemony's identity is instant synchronisation or slow, hard-won doctrine revision.

2. F5 and the debrief: The Glasswright cycle explicitly says the next run does not learn from the fleet just played. What does the Glasswright end-of-run debrief say to the player, given that A3 requires the debrief to name what the next attempt inherits? Stakes: if the debrief cannot honestly connect the loss just suffered to the next run's content, A3's failure-as-tuition framing breaks for one-sixth of the player base.

3. LEGACY tier distribution: Are the first three LEGACY nodes (extra starting credits in three tiers) intended to be the first purchases a player makes, or are they priced to be mid-progression? Stakes: if they are cheap and early, they create a vertical power spike that contradicts A2's "horizontal first, vertical modest" and makes a single purchase feel like the difference between runs 3 and 4.
