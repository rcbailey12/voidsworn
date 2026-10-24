# Faction asymmetry decision briefs: Qwen3.8-Max leg

Provenance: generated in Qwen chat on Oct 24, 2026, model Qwen3.8-Max, Thinking ON, Web search OFF, signed in as rcbailey12@gmail.com. All three granted files attached successfully (asymmetry_briefs_brief.txt 2.2 KB, asymmetry_decision.md 7.9 KB, faction_asymmetry.md 10.6 KB). OBSERVED quotes kept under 20 words; defaults recommended only, not decided. Em dashes in the model's text were normalized to hyphens for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the DeepSeek leg follow separately; nothing here is verified.

# VOIDSWORN FACTION ASYMMETRY: FIVE DECISION BRIEFS FOR THE OWNER

Context: Voidsworn is a 3D hex-grid fleet tactics roguelite in Babylon.js, PC-only, turn-based at around 20 ships. Three blind audits (Rey, DeepSeek, Qwen) converged on six faction identities and a merged first-three order, recorded in asymmetry_decision.md. Five decisions sit with the owner. These briefs argue each decision so the owner can rule fast. They are decision SUPPORT, not decision.

## BRIEF 1: Adopt the six identities as the design direction?

The decision: Yes or no. If yes, the six identities (Voidsworn armored broadside line; Hegemony standard and shield-stripper; Corsairs close-range raiders paid in salvage; Chorus swarm that eats; Ithar elite glass skirmishers; Deathless attrition engine) become the binding design direction for all subsequent faction work.

### Trade-offs

Option A: Adopt all six as stated.
- Costs: Locks the design space for all future faction work. Any future mechanic must be tested against six identities rather than one generic system. OBSERVED: "Prohibitions create identity cheapest" (asymmetry_decision.md), which means every future feature must check six prohibition lists rather than one ruleset. INFERRED: this increases QA surface area roughly sixfold for any new weapon, class, or admiral added later.
- Buys: A unified direction that all three audits independently converged on. OBSERVED: "When three unrelated model families assign the same identity to every faction, the identities are probably just what the data already wants to be" (asymmetry_decision.md). INFERRED: adoption means the team stops re-litigating identity and moves to execution, saving at least one full design cycle of debate.
- Breaks if wrong: If one identity proves unfun in play (e.g., Voidsworn's slow line feels passive rather than commanding), the owner must either break the adopted direction publicly or force a fix that contradicts the identity. INFERRED: the cost of reversal grows with every data pass built on the identity.

Option B: Adopt with modifications (e.g., merge two identities, swap one).
- Costs: Reopens the design question the audits closed. INFERRED: the three audits ran blind and converged; diverging from their consensus requires the owner to name what the data missed, which is a higher evidentiary bar than accepting convergence.
- Buys: Owner agency over a specific identity that feels wrong at the table. INFERRED: useful if the owner's play experience contradicts an audit's read (e.g., if Deathless already feels distinct in current play).
- Breaks if wrong: A partial adoption creates ambiguity about which identities are binding, stalling implementation. INFERRED: Opus cannot gate rosters against a half-adopted identity list.

Option C: Reject; commission a fourth audit or a different framework.
- Costs: Time. Three audits already ran at HEAD 51337c2. INFERRED: a fourth audit at the same commit adds little unless the methodology changes.
- Buys: Nothing the first three did not already provide, unless the owner suspects a shared blind spot. INFERRED: the brief's grounding shows all three used the same pack, so a shared blind spot is possible but unlikely given independent model families.
- Breaks if wrong: Delays every downstream decision (briefs 2-5) indefinitely.

### Settling evidence
- OBSERVED: "The sameness is real and measured, not a feeling" (asymmetry_decision.md). The price ladder, class ladder, and stat bands are documented in Rey's audit: "Every faction's frigate costs exactly 70, every destroyer exactly 130" (faction_asymmetry.md).
- OBSERVED: "All three independently produced the same headline evidence" (asymmetry_decision.md).
- INFERRED: The strongest settling evidence is the owner's own play experience. If the owner plays one battle as Chorus and one as Ithar today and the opening moves feel identical, the identities are needed. Rey's audit states: "If the same opening moves feel right in both, it is not done" (faction_asymmetry.md).
- INFERRED: No sim run can settle an identity adoption; it is a design-direction call. The sim can only confirm or deny after implementation.

### Recommended default
Adopt all six (Option A). Reasoning: three blind audits converged; the identities are derived from data already in the rosters rather than invented whole-cloth; and the alternative (no direction) leaves every subsequent decision (briefs 2-5) unanswerable. INFERRED: the cost of adoption is low because the identities mostly formalize what the data already half-expresses - OBSERVED: "the game has asymmetry of flavour and of a few numbers, but not of decisions" (faction_asymmetry.md). Adopting the identities is the permission slip to make those flavours into decisions.
Data-only vs engine: Adoption itself is neither; it is a policy statement. The implementation costs are catalogued in Brief 2.

## BRIEF 2: Approve the merged first-three order (price ladder and roster gates; hard prohibitions; per-faction economy hook)?

The decision: Approve or reject the sequence: (1) break the shared price ladder and gate the rosters; (2) enforce the hard prohibitions; (3) add the per-faction economy hook.

### Trade-offs

Step 1 - Break the shared price ladder and gate the rosters.
- Costs: One data pass across all hull costs and faction access lists. INFERRED: every fleet-building UI, tooltip, and AI budget calculator that reads cost must be checked for hardcoded assumptions. Rey's audit notes the ladder is "the single most legible sameness in the game" (faction_asymmetry.md), so changing it touches player-facing numbers immediately.
- Buys: Immediate, visible differentiation in every fleet-building decision. OBSERVED: "Frigates stop costing 70 everywhere; Chorus and Corsair hulls get cheaper and more numerous, Ithar and Voidsworn dearer" (asymmetry_decision.md). INFERRED: this is the cheapest single change that makes a player feel a different faction at the roster screen before any battle begins.
- Breaks if wrong: If the new prices are miscalibrated, one faction becomes unaffordable or trivially cheap. INFERRED: the sim matrix can catch this quickly because cost is a direct input to fleet composition.
- Classification: Data-only. No engine change required. OBSERVED: "Data-only, one pass, immediately visible in every fleet-building decision" (asymmetry_decision.md).

Step 2 - Enforce the hard prohibitions.
- Costs: A handful of boolean checks in order and fit-out code. OBSERVED: "making them rules costs a handful of boolean checks: Ithar cannot Brace, Hegemony cannot board, Chorus cannot fit shield modules or repair at shipyards, Deathless cannot launch squadrons or be boarded" (asymmetry_decision.md). INFERRED: each check is one conditional in the relevant code path; the total is likely under ten lines of logic across the codebase.
- Buys: Identity through restriction, which the audits unanimously endorsed. OBSERVED: "Prohibitions create identity cheapest" (asymmetry_decision.md). INFERRED: prohibitions also reduce the decision tree for the player, increasing per-activation decision weight because the remaining choices matter more - a direct fit with the stated feel target.
- Breaks if wrong: If a prohibition removes a strategy the player relied on without offering a replacement, the faction feels nerfed rather than differentiated. INFERRED: mitigation is to pair each prohibition with the faction's positive identity hook (e.g., Ithar loses Brace but gains shield recharge or superior blink).
- Classification: Mostly data/boolean-gate. Qwen's framing is one-line checks. INFERRED: Chorus "cannot fit shield modules" may require a fit-out filter, still data-adjacent. "Cannot repair at shipyards" touches the repair code path but is a conditional, not a new system.

Step 3 - Add the per-faction economy hook.
- Costs: This is the one true engine change. OBSERVED: "DeepSeek flags this as the one true ENGINE CHANGE" (asymmetry_decision.md). INFERRED: a faction modifier table must be read by shipyard, repair, and reward code, meaning at least three code paths gain a faction lookup. The Corsair capture loop and Chorus feed loop are special cases that add further logic.
- Buys: Without it, every economy proposal stays fiction. OBSERVED: "Without it, every economy proposal in all three audits stays fiction" (asymmetry_decision.md). INFERRED: economy is the only lever that changes between-battle decisions, which is where a roguelite lives; without it, asymmetry is confined to the battle screen.
- Breaks if wrong: An economy hook that is too generous creates a snowball; too weak and it is invisible. INFERRED: the risk is asymmetric - a snowball breaks the roguelite loop, while invisibility merely wastes the implementation cost.
- Classification: Engine change. Requires a new modifier table and hooks into at least three existing systems.

Sequencing risk of approving all three together: INFERRED: Steps 1 and 2 are low-risk and can ship in one patch. Step 3 is higher-risk and benefits from being designed after the sim shows how Steps 1 and 2 already shift behaviour. Approving all three as a bundle is fine as policy; implementing them in strict order protects against coupling.

### Settling evidence
- OBSERVED: "The proof is distributions, not win rates" (asymmetry_decision.md). After Steps 1 and 2, run the harness on fixed seeds and compare: engagement-range histogram, hulls per battle, damage mix. If distributions diverge, the steps worked.
- OBSERVED: "pairwise metric vectors diverge beyond noise while mirror win rates remain roughly balanced" (asymmetry_decision.md, quoting DeepSeek's acceptance criterion).
- INFERRED: For Step 3, the settling evidence is the economy ledger - credits gained, repair spend, hull losses per faction per battle. If Corsairs do not end battles with more credits than they started, the capture loop is not functioning.

### Recommended default
Approve all three in the stated order. Reasoning: Steps 1 and 2 are cheap, mostly data-only, and immediately visible; Step 3 is the only item that unlocks the between-battle layer. INFERRED: rejecting Step 3 while approving 1 and 2 leaves the game with asymmetric battles but identical campaign economics, which is half the job. The brief's constraint notes data-only changes are cheaper than engine changes; Steps 1 and 2 honour that, and Step 3 is flagged transparently as the one engine ask.

## BRIEF 3: Ithar shield recharge - new rule now, or sim first with no-Brace alone?

The decision: Implement Ithar shield recharge immediately as a new rule, or implement only the no-Brace prohibition and run the sim to see whether recharge is also needed.

### Trade-offs

Option A: Implement shield recharge now (alongside no-Brace).
- Costs: A new rule in the shield system. INFERRED: shield recharge is not currently a per-faction mechanic; it requires either a faction-tagged modifier on the shield-regen tick or a per-hull flag. This is a small engine addition, not data-only. Rey's audit marks it: "NEED: shield recharge is a new rule but a small one" (faction_asymmetry.md).
- Buys: The full Ithar fantasy in one pass: shields go down, you kite, they come back, you re-engage. OBSERVED: "its shields recharge mid-battle (the only faction that does)" (faction_asymmetry.md). INFERRED: this creates a distinct tactical problem for the opponent - "get through the shields before they come back" - which is a decision, not a decimal.
- Breaks if wrong: If recharge is too fast, Ithar becomes unkillable in sustained fights and the glass-hull identity evaporates. INFERRED: the counter is to tune recharge rate and pair it with the existing "hull repairs 50% dearer" cost (Qwen's proposal), but tuning requires sim time.

Option B: Sim first with no-Brace alone; add recharge only if the sim shows Ithar underperforms.
- Costs: One extra sim cycle before Ithar feels complete. INFERRED: the no-Brace prohibition is one boolean check - OBSERVED: "Ithar cannot Brace, enforced by one check in the order code" (asymmetry_decision.md) - so it is trivially reversible and testable.
- Buys: Evidence before commitment. INFERRED: if no-Brace alone already forces Ithar into a hit-and-run pattern that feels distinct, recharge may be unnecessary complexity. The sim's distribution data (range at time of death, shield-vs-hull damage ratio) will show whether Ithar already plays differently.
- Breaks if wrong: If the sim shows Ithar still dies in the same range band as every other faction without recharge, the owner has lost one cycle and must still implement the rule. INFERRED: this is a delay cost, not a design cost.

Option C: Implement recharge now but flag it as experimental (toggleable in the sim harness).
- Costs: Slightly more implementation effort than Option A (needs a toggle). INFERRED: negligible if the recharge is already a faction-flagged modifier.
- Buys: Both data points in one sim run: with and without recharge, same seeds. INFERRED: this is strictly more informative than either A or B alone.
- Breaks if wrong: Nothing additional beyond A's risks; the toggle mitigates them.

### Settling evidence
- OBSERVED: "Qwen's three clusters are the quick version: range at time of death, shield-vs-hull damage ratio, resource delta per battle" (asymmetry_decision.md). If Ithar's range-at-death and shield ratio already diverge from other factions with no-Brace alone, recharge is optional.
- OBSERVED: "Shield recharge is the contested mechanic: Rey and Qwen both proposed it…DeepSeek thinks shield cycling with existing surge is enough" (asymmetry_decision.md). INFERRED: the disagreement among auditors is itself evidence that the answer is not obvious from data alone and requires sim.
- INFERRED: The specific metric to watch is shield-vs-hull damage ratio per Ithar battle. If Ithar hulls are taking disproportionate hull damage (shields down, no recharge, frail hp), the faction is underperforming its identity.

### Recommended default
Sim first with no-Brace alone (Option B), with recharge prepped as a toggle for the next cycle (Option C as fallback). Reasoning: no-Brace is data-only (one boolean), reversible, and immediately testable. Shield recharge is a small engine addition. INFERRED: the brief's constraint favours data-only changes first; no-Brace is the cheapest identity lever available. If the sim shows Ithar still clusters with other factions at range 4-5 with identical damage profiles, recharge is justified. If Ithar already kites and fades distinctly, recharge is gilding.
Data-only vs engine: No-Brace is data/boolean-gate. Shield recharge is a small engine addition (new rule in shield tick, faction-tagged).

## BRIEF 4: Chorus feed mechanic (no shipyard repair, kills heal) - in or out?

The decision: Adopt the Chorus feed mechanic - no shipyard repair; nearby kills restore hull, repurposing the existing avenge logic - or exclude it.

### Trade-offs

Option A: In (adopt the feed mechanic).
- Costs: Two changes: (1) disable shipyard repair for Chorus, (2) wire the avenge/relic logic so that nearby kills restore hull instead of (or in addition to) their current function. INFERRED: the first is a boolean gate in the repair code path (data-adjacent). The second repurposes existing logic - OBSERVED: "Qwen's feed mechanic (no shipyard repair at all; nearby kills restore hull, repurposing the existing avenge logic)" (asymmetry_decision.md) - so it is a modification, not a new system.
- Buys: Chorus gains an economy no other faction shares and a reason to stay in the fight. OBSERVED: "which gives Chorus an economy no other faction shares and a reason to stay in the fight" (asymmetry_decision.md). INFERRED: this directly supports the swarm identity - more bodies stay alive longer, the pack thins but does not rout, and the player is incentivised to keep fighting rather than disengage. It also creates a unique between-battle decision: Chorus does not visit shipyards, so its campaign routing differs.
- Breaks if wrong: If the heal rate is too low, Chorus is strictly worse than every other faction (no repair AND no feed). If too high, Chorus snowballs and becomes unkillable in prolonged engagements. INFERRED: the tuning risk is real but bounded by the existing avenge numbers, which provide a starting point.

Option B: Out (reject the feed mechanic).
- Costs: Chorus loses its unique economy hook. INFERRED: without feed, Chorus's identity rests entirely on zero shields, regrow, and cheap hulls - mechanics that differentiate its combat profile but not its campaign economy. The faction becomes "swarm in battle, standard between battles."
- Buys: Simplicity. No modification to the avenge logic. No risk of a snowball. INFERRED: one fewer special case in the economy hook (Brief 2, Step 3).
- Breaks if wrong: Chorus becomes the faction that is asymmetric in combat but generic in campaign, undermining the roguelite loop where between-battle decisions dominate play time. INFERRED: given the game is a roguelite, between-battle identity may matter more than in-battle identity for long-term engagement.

Option C: In, but with a cap or diminishing returns (e.g., feed heals up to 50% of lost hull, or only the first N kills per turn).
- Costs: Slightly more complex implementation than Option A. INFERRED: a cap is one additional variable in the feed calculation.
- Buys: Bounds the snowball risk while preserving the identity. INFERRED: the owner gets the flavour without the balance terror.
- Breaks if wrong: A cap that is too low makes feed feel irrelevant; too high and it is Option A anyway.

### Settling evidence
- OBSERVED: "the brood-mother as a true mid-battle spawner (Rey and DeepSeek both), and Qwen's feed mechanic" are called "Two standout concepts" (asymmetry_decision.md). The audits treat feed as central to Chorus, not optional.
- OBSERVED: "Recommendation: adopt both; Chorus becomes the reference swarm" (asymmetry_decision.md).
- INFERRED: The sim test is the resource delta per battle (Qwen's third cluster). Run Chorus with and without feed on fixed seeds. If Chorus without feed ends battles with negative resource delta (hull losses exceed gains) while every other faction breaks even or positive, the faction is structurally punished and feed is needed.
- INFERRED: The economy ledger (credits gained, repair spend, hull losses) from DeepSeek's telemetry list will show whether Chorus's no-repair constraint is offset by kill-healing or simply punitive.

### Recommended default
In (Option A), with a tuning cap reserved for the sim pass (Option C as implementation detail). Reasoning: the feed mechanic is the single cheapest way to give Chorus a unique campaign economy, and it repurposes existing avenge logic rather than building a new system. OBSERVED: "repurposing the existing avenge logic" (asymmetry_decision.md). INFERRED: this is closer to a data/logic modification than a true engine addition, though it touches the repair code path (one boolean gate to disable shipyard repair for Chorus). The identity payoff - OBSERVED: "a reason to stay in the fight" (asymmetry_decision.md) - is disproportionate to the implementation cost. Rejecting it leaves Chorus economically generic, which contradicts the swarm-that-eats fantasy the three audits converged on.
Data-only vs engine: Disabling shipyard repair for Chorus is a boolean gate (data-adjacent). Repurposing avenge logic as feed is a logic modification within an existing system, not a new engine feature. INFERRED: this is cheaper than Brief 2 Step 3's full economy hook but more than a pure data pass.

## BRIEF 5: Deathless reanimate - Opus to report what the existing rule actually does before any design builds on it?

The decision: Commission Opus to inspect the code and report what the existing reanimate rule actually does on Deathless hulls, before any design work proceeds. The brief notes this is "a factual question with a definite answer in the code."

### Trade-offs

Option A: Yes, commission the report before designing around reanimate.
- Costs: One Opus investigation cycle. INFERRED: this is a code-reading task, not an implementation task, so it is cheap in engineering time but blocks Deathless-specific design until answered.
- Buys: Certainty. The three audits disagree on what exists. OBSERVED: "DeepSeek reports a reanimate rule already exists on Deathless hulls (reanimate:true, with a check in the battle code), while Rey's audit treated a return-from-wreck rule as an engine ask" (asymmetry_decision.md). INFERRED: designing on top of a misread fact risks either duplicating an existing system or building on a phantom. The report resolves a factual dispute that no amount of design discussion can settle.
- Breaks if wrong: Nothing breaks. The worst case is a short delay. INFERRED: if Opus reports the rule exists and works, design proceeds faster than expected. If it does not exist, the design team knows the true scope of the engine ask.

Option B: No, proceed with design assuming reanimate must be built from scratch.
- Costs: If DeepSeek is right and reanimate already exists, the team duplicates work or overwrites a functioning system. INFERRED: this is the higher-risk branch because it assumes the more expensive case without checking.
- Buys: No delay. Design proceeds immediately. INFERRED: useful only if the owner is confident reanimate does not exist, which contradicts DeepSeek's specific claim of reanimate:true in the data.
- Breaks if wrong: Wasted implementation effort, or a conflict between the new system and the quiet existing one.

Option C: No, proceed assuming reanimate already exists and works, and design around it.
- Costs: If Rey is right and it is an engine ask, the design is built on a fiction. INFERRED: this is the opposite error of Option B.
- Buys: No delay, and if DeepSeek is right, the design is immediately implementable.
- Breaks if wrong: The design specifies behaviour the code does not support, requiring a redesign or an engine change that was not budgeted.

### Settling evidence and the three branches
The brief specifies three possible answers from Opus. Each implies different design consequences:

Branch 1: Reanimate exists and works as described (DeepSeek is correct).
- OBSERVED: "DeepSeek reports a reanimate rule already exists on Deathless hulls (reanimate:true, with a check in the battle code)" (asymmetry_decision.md).
- INFERRED: If this is true, Deathless's signature mechanic is already built and "merely quiet" (asymmetry_decision.md). The design task becomes surfacing and tuning an existing rule: making reanimate visible to the player (UI feedback, battle log), tuning its trigger conditions, and ensuring it interacts correctly with the wreck-field economy (reclaim). This is data and presentation work, not engine work.
- INFERRED: The design implication is that Deathless is closer to its final identity than any other faction. The owner's remaining task is to make the existing rule legible and to build the surrounding identity (no shields, highest armor, phase, wrecks-as-resource) around it.

Branch 2: Reanimate exists in the data but is quiet, broken, or unreachable (a middle case).
- INFERRED: This is the most likely branch if the rule was prototyped and never finished. The reanimate:true flag exists in hull data, and a check exists in battle code, but the check never fires due to a missing condition, a disabled code path, or a zero-probability trigger.
- INFERRED: The design implication is that the engine scaffold exists but needs a bug fix or a condition change to activate. This is a small code fix, cheaper than building from scratch but not free. The design can proceed as if reanimate will work, with the caveat that Opus must confirm the fix before the sim validates it.
- INFERRED: Qwen's "flavourful cheap bits" (no crew / boarding immunity, acid as counter) remain valid regardless of this branch and are data-only additions.

Branch 3: Reanimate does not exist as described (Rey is correct; it is an engine ask).
- OBSERVED: "Rey's audit treated a return-from-wreck rule as an engine ask" (asymmetry_decision.md).
- INFERRED: If this is true, Deathless's signature is unbuilt. The design must either (a) scope and implement a return-from-wreck system, which is a genuine engine addition, or (b) lean on the existing mechanics (reclaim, phase, high armor, zero shields) and treat reanimate as a stretch goal. Option (b) keeps Deathless viable without the engine ask but weakens the Necron-fantasy parallel.
- INFERRED: The design implication is that Deathless becomes the most expensive faction to bring to identity parity, and the owner must decide whether the return-from-wreck fantasy is worth the engine cost or whether attrition-through-armor-and-reclaim is sufficient.

### Settling evidence
- OBSERVED: "Opus confirms what reanimate currently does before anyone designs around it" (asymmetry_decision.md). This is the audits' own recommendation.
- OBSERVED: "This one is a factual question with a definite answer in the code" (asymmetry_decision.md, echoed in the brief).
- INFERRED: The evidence is the code itself. Opus reads the hull data for the reanimate flag, traces the battle-code check, and reports: does it fire, under what conditions, and what does it produce (a new hull, a restored hull, a temporary entity)? No sim, no design discussion, no audit can substitute for this reading.

### Recommended default
Yes, commission the report (Option A). Reasoning: the cost is one code-reading cycle; the benefit is certainty on a factual dispute between two of the three audits. OBSERVED: "If DeepSeek is right, Deathless's signature is already built and merely quiet" (asymmetry_decision.md). INFERRED: every other option risks building on a false premise, and the report is the only way to resolve the dispute. The brief itself calls this "a factual question with a definite answer in the code," which means the answer exists and is cheap to retrieve. No design work on Deathless beyond the already-agreed data pass (armor values, zero-shields enforcement, no-squadrons prohibition) should proceed until the report lands.
Data-only vs engine: The report itself is neither; it is investigation. The downstream work depends on the branch: Branch 1 is data/presentation, Branch 2 is small code fix, Branch 3 is engine addition. Qwen's boarding-immunity and acid-counter additions are data-only regardless of branch.

## NOT SPECIFIED

The following items are not addressed by these briefs and remain outside the scope of the five decisions:
- Balance numbers. All cost adjustments (e.g., Chorus frigates at 50, Ithar at 95) are directional starting points. OBSERVED: "Balance numbers in Part 3 are directional starting points for the sim to judge, not tuned values" (faction_asymmetry.md). No brief here recommends specific numbers.
- New factions. OBSERVED: "No new-faction proposals (six is enough until the six differ)" (faction_asymmetry.md). These briefs do not consider a seventh faction.
- Campaign or map-layer asymmetry beyond the economy hooks noted in Briefs 2 and 4. INFERRED: faction-specific events, map generation, or campaign structure are not covered.
- Admiral asymmetry beyond the shared cost curve. Rey's audit proposes faction-breaking 80-cost admirals (OBSERVED: "the Chorus admiral who grants shields, the Ithar admiral who fields a swarm" - faction_asymmetry.md), but this is not among the five decisions and is not briefed here.
- The variant-hull question. Rey's census found 12 of 45 hulls are same-stat weapon swaps (OBSERVED: "12 of 45 hulls are variant hulls whose stats are identical to a base hull with a weapon swap" - asymmetry_decision.md). Whether to consolidate, differentiate, or leave them is not among the five decisions.
- MOVE_FEEL and presentation-layer asymmetry. OBSERVED: "the presentation layer (MOVE_FEEL) is already more asymmetric than the rules layer" (asymmetry_decision.md). No brief addresses whether to extend, reduce, or leave MOVE_FEEL as is.
- Boss scaling. DeepSeek noted boss scaling is "the one faction-specific table in the game, also enemy-side only" (asymmetry_decision.md). This is flagged but not among the five decisions.
- Sim harness specifics. The briefs reference the harness and telemetry but do not specify seed counts, budget levels, or statistical thresholds for "beyond noise." INFERRED: these are implementation details for Opus and the sim pipeline.
- Timeline and sequencing beyond the first-three order. No brief recommends dates, sprint allocations, or dependency ordering beyond the stated sequence.
- The owner's play-test. Rey's human test - OBSERVED: "play one battle as Chorus and one as Ithar. If the same opening moves feel right in both, it is not done" (faction_asymmetry.md) - is noted as the final acceptance gate but is not something these briefs can perform or substitute for.

End of briefs. All five decisions are the owner's. These briefs recommend defaults; they do not decide.
