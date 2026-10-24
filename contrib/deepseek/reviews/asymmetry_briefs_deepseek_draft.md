# FACTION ASYMMETRY DECISION BRIEFS

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report; em dashes normalized to hyphens, wording otherwise unchanged. Note: the first generation attempt stalled server-side and was abandoned; a fresh chat produced these briefs.

Decision-support briefs only. No owner decision is made here; each brief ends with a recommended default for the owner to rule on.

## Brief 1 - Decision 1: Adopt the six identities as the design direction?

Decision under support: Whether the six merged identities become the design direction: Voidsworn armored broadside line; Hegemony standard and shield-stripper; Corsairs close-range raiders paid in salvage; Chorus swarm that eats; Ithar elite glass skirmishers; Deathless attrition engine.

### Options and trade-offs

Option A - Adopt the six identities as the design direction.
- Cost: Locks narrative and design language early; creates expectation that the identities will survive sim and playtest; may force later rework if one identity proves unexpressible in the current engine.
- Buys: A single design target for all later data passes; aligns the three audits; gives the owner a legible answer to "what is each faction for?"; makes prohibitions, price ladder, and economy hooks coherent instead of ad hoc.
- Breaks if wrong: The project spends time building around archetypes that do not produce different per-activation decisions; factions remain costumes with better copy. The owner's stated benchmark is faction rules, not palette, so this is the expensive failure mode.

Option B - Reject or defer the six identities.
- Cost: Preserves the measured sameness; leaves the first-three order without a design rationale; wastes the convergence evidence.
- Buys: Avoids premature lock; keeps options open if the owner believes the current six factions should be re-conceived.
- Breaks if wrong: The game continues to read as one faction in six costumes; the audits' central finding is ignored; later data passes lack a target.

Option C - Pilot one or two identities only.
- Cost: Slower; produces partial asymmetry; risks inconsistent faction language across the roster.
- Buys: Cheaper evidence before full commitment; lets the owner test whether one archetype actually changes turn-by-turn decisions.
- Breaks if wrong: The pilot faction may not generalize; the other factions remain undifferentiated while design attention is concentrated.

### Evidence that would settle it
- Audit convergence: OBSERVED (decision page): "the three audits converged on the same six playstyles." This is strong support that the identities are not arbitrary.
- Measured sameness: OBSERVED (decision page): "The sameness is real and measured, not a feeling." The direction is a response to a measured problem, not a taste preference.
- Proof standard: OBSERVED (decision page): "The proof is distributions, not win rates." Adoption should be judged by whether faction metric vectors diverge, not by win-rate alone.
- Owner playtest: The cheapest human check is one battle as Chorus and one as Ithar; if the same opening moves feel correct in both, the direction has not landed.
- Data-pass preview: A small data-only price and roster-gate pass can show whether the identities are legible in fleet-building before engine work.

### Recommended default (support only)
Adopt the six identities as the design direction, not as final balance or final mechanics. Reasoning: the convergence is the strongest audit signal, the problem is measured, and the direction is cheap to state but expensive to replace later. This decision requires no engine work by itself; the next decisions determine which parts are data-only and which need code. If the owner wants a lower-risk version, adopt the direction but require the distribution test and owner playtest before locking presentation and narrative.

## Brief 2 - Decision 2: Approve the merged first-three order?

Decision under support: Approve the merged first-three order: break the shared price ladder and gate the rosters; enforce the hard prohibitions; add the per-faction economy hook.

### Options and trade-offs

Option A - Approve all three as one order.
- Cost: The economy hook is the one clear engine change; it will take longer than the data-only ladder and roster gates. Approving all three together risks the engine item delaying visible progress.
- Buys: A complete first identity pass: prices and rosters differ, prohibitions become rules, and Corsair/Chorus economies stop being fiction.
- Breaks if wrong: If the economy hook is underspecified, it can destabilize shipyard, repair, and reward code while the cheaper identity work is already live; debugging becomes harder because multiple systems changed at once.

Option B - Approve the data-only first two now; defer the economy hook.
- Cost: Corsair capture/salvage and Chorus feed remain design intent, not systems; the faction economies stay fiction.
- Buys: Fast, visible, low-risk asymmetry in fleet-building and prohibitions; clean attribution of sim changes.
- Breaks if wrong: The owner may conclude the first pass did not go far enough because economy identity is missing; Corsairs and Chorus remain partly costume.

Option C - Approve only the price ladder and roster gates.
- Cost: Prohibitions remain soft or implicit; identity is weaker than the audits recommend.
- Buys: Cheapest possible pass; almost immediate fleet-building differentiation.
- Breaks if wrong: Prohibitions are the cheapest identity move; skipping them wastes the best low-cost lever.

Option D - Reject or reorder the merged list.
- Cost: Delays the first visible answer to the sameness finding.
- Buys: Avoids engine work and preserves current balance.
- Breaks if wrong: The owner's charge remains unmet; later work has no first-pass foundation.

### Evidence that would settle it
- Price ladder: OBSERVED (decision page): "Frigates stop costing 70 everywhere." This is the most legible sameness and is data-only.
- Roster gating: OBSERVED (decision page): "each faction loses access to something." This converts identity into fleet-building decisions.
- Prohibitions: OBSERVED (decision page): "making them rules costs a handful of boolean checks." This is cheap code, not a large engine feature.
- Economy hook: OBSERVED (decision page): "DeepSeek flags this as the one true ENGINE CHANGE." This is the item that needs separate scoping.
- Implementation split: INFERRED: price ladder and roster gates are data-only; prohibitions are small code/boolean checks unless the existing gates are data-exposed; the economy hook is engine work. Opus should confirm exact file and data-schema cost.
- Settling evidence: a fixed-seed harness comparing engagement-range histogram, hull counts, damage mix, and economy ledger before/after the data-only pass; then a separate engine spike for the economy hook.

### Recommended default (support only)
Approve the merged order as a sequence, but split execution: run the data-only price ladder and roster gates plus the hard prohibitions first; approve the economy hook as a scoped engine spike, not as part of the same data pass. Reasoning: the first two buy visible identity cheaply and test the design direction; the economy hook is the only true engine change and should not delay or contaminate that test. If the owner wants one verdict, the default is "approve all three in principle, gate the engine item behind a small Opus scope."

## Brief 3 - Decision 3: Ithar shield recharge - new rule now, or sim first with no-Brace alone?

Decision under support: Whether Ithar gets a new shield-recharge rule now, or whether the sim first tests Ithar with the no-Brace prohibition alone.

### Options and trade-offs

Option A - Add shield recharge now.
- Cost: New rule, likely engine work; adds a second Ithar variable at the same time as the no-Brace prohibition; makes sim attribution harder.
- Buys: Stronger "get through the shields before they return" identity; directly supports the elite glass-skirmisher fantasy; gives Ithar a signature mechanic, not just stat outliers.
- Breaks if wrong: Ithar becomes overtuned or frustrating; recharge masks whether no-Brace alone was sufficient; the owner spends engine time on a rule the sim did not need.

Option B - Sim first with no-Brace alone.
- Cost: Delays the recharge decision; Ithar may feel incomplete for one test cycle.
- Buys: Clean causal evidence: if no-Brace alone produces distinct Ithar distributions, recharge is unnecessary; if not, the sim justifies it. Cheaper because no-Brace is already the recommended prohibition.
- Breaks if wrong: Ithar remains too plain for a cycle; the owner may perceive slow progress on the most distinctive Ithar mechanic.

Option C - Defer both recharge and no-Brace.
- Cost: Gives up the cheapest identity move in the audits; Ithar remains a stat package.
- Buys: No new code; no balance risk.
- Breaks if wrong: Ithar stays a costume; the owner loses the clearest low-cost prohibition.

### Evidence that would settle it
- Contested status: OBSERVED (decision page): "Shield recharge is the contested mechanic." The audits do not unanimously require it.
- No-Brace cost: OBSERVED (decision page): "Qwen's prohibition is the cheapest identity move in any of the three audits." This is the low-cost lever to test first.
- Sim-first recommendation: OBSERVED (decision page): "let the sim judge whether recharge is also needed." This is already the decision page's proposed sequencing.
- Settling evidence: fixed-seed Ithar runs measuring shield-vs-hull damage ratio, time-to-shield-drop, survival after shield drop, engagement range at death, and whether Ithar wins by alpha/fade rather than by brawling. If no-Brace alone produces a distinct Ithar vector, defer recharge. If Ithar still collapses into the same decision pattern, recharge has a case.
- Implementation: INFERRED: the no-Brace prohibition is a small code/boolean check; shield recharge is a new rule and should be treated as engine work until Opus says otherwise.

### Recommended default (support only)
Sim first with the no-Brace prohibition alone; do not add shield recharge now. Reasoning: no-Brace is the cheapest identity move, recharge is contested, and adding both at once destroys attribution. The default is not "never recharge"; it is "recharge only after the sim shows no-Brace alone does not create the Ithar decision pattern."

## Brief 4 - Decision 4: Chorus feed mechanic - in or out?

Decision under support: Whether Chorus gets the feed mechanic: no shipyard repair, and nearby kills restore hull.

### Options and trade-offs

Option A - Put the full feed mechanic in now.
- Cost: Balance risk: a swarm that heals from kills can snowball; implementation may touch repair, kill, and economy code; if generalized, it becomes part of the engine economy hook.
- Buys: A unique Chorus economy and a reason to stay in the fight; reinforces "the swarm that eats"; differentiates Chorus from Deathless's no-shield attrition.
- Breaks if wrong: Chorus becomes unkillable in casual play or runaway in sim; burst-damage counterplay fails; the faction's lose condition ("loses to burst") erodes.

Option B - Leave it out.
- Cost: Chorus remains the swarm with regrow and cheap bodies but no distinct economy; less differentiation from a generic cheap faction.
- Buys: No new balance or code risk; preserves current repair rules.
- Breaks if wrong: Chorus loses the strongest consensus concept in the audits; the reference swarm is less distinctive than intended.

Option C - Stage it: no shipyard repair as a prohibition/data rule first; kill-heal only if the existing avenge hook supports it cheaply.
- Cost: Partial implementation; needs Opus confirmation that the avenge logic can be repurposed without engine work.
- Buys: Captures most of the identity at low risk; keeps the snowball mechanic behind a verified hook; avoids building a new economy system prematurely.
- Breaks if wrong: If the existing hook is unsuitable, the kill-heal half stalls; Chorus gets the no-repair half but not the feed loop.

### Evidence that would settle it
- Consensus: OBSERVED (decision page): "The strongest consensus of the three audits." Chorus's swarm identity is the least contested.
- Mechanic description: OBSERVED (decision page): "Qwen's feed mechanic (no shipyard repair at all; nearby kills restore hull, repurposing the existing avenge logic)." This is the specific proposal under decision.
- Adoption recommendation: OBSERVED (decision page): "Chorus becomes the reference swarm." The decision page already frames Chorus as the reference implementation.
- Settling evidence: sim damage absorbed by regeneration, hull-count curve, win/loss causes, and whether Chorus wins by attrition or by unkillable snowball. If Chorus already wins long fights without feed, the kill-heal half may be unnecessary; if it lacks a reason to stay engaged, feed has a case.
- Implementation: INFERRED: no shipyard repair is a prohibition/data-or-small-code rule; kill-heal via existing avenge logic may be data-only if the hook is exposed, otherwise small code; a generalized faction economy table is engine work per Decision 2.

### Recommended default (support only)
Put Chorus feed in as a staged design intent: enforce no shipyard repair first, and implement kill-heal only through the existing avenge logic if Opus confirms it is cheap and safe. Reasoning: the consensus is strong, but the snowball risk is real; staging preserves the identity while avoiding a new economy system before the engine hook exists. If the owner wants a binary verdict, the default is "in, staged," not "full feed immediately."

## Brief 5 - Decision 5: Deathless reanimate - Opus to report what the existing rule actually does before design builds on it?

Decision under support: Whether Opus should report what the existing Deathless reanimate rule actually does before any design builds on it.

### Options and trade-offs

Option A - Yes: Opus reports code truth first.
- Cost: Small delay; one code investigation; design work on Deathless waits for the report.
- Buys: Prevents building on a false premise; resolves the audit conflict; tells the owner whether Deathless's signature is already built, quiet, broken, or absent.
- Breaks if wrong: Almost nothing beyond delay; this is the cheapest way to avoid a costly design error.

Option B - No: design on the current assumption.
- Cost: May design around a rule that does not exist or does not work; later rework.
- Buys: Speed; no waiting on code investigation.
- Breaks if wrong: Deathless design is built on fiction; the owner pays twice.

Option C - Parallel design with guardrails.
- Cost: Coordination overhead; design may still outrun code truth.
- Buys: Some speed while awaiting the report.
- Breaks if wrong: Design churn if the reanimate branch turns out different from the assumption.

### Evidence that would settle it
- Audit conflict: OBSERVED (decision page): "DeepSeek reports a reanimate rule already exists on Deathless hulls." Also OBSERVED (decision page): "Rey's audit treated a return-from-wreck rule as an engine ask." These are incompatible premises.
- Decision-page recommendation: OBSERVED (decision page): "Opus confirms what reanimate currently does." This is already the proposed factual check.
- Factual status: OBSERVED (decision page): "it is a factual question with a definite answer in the code." The owner does not need a design debate to settle it.
- Settling evidence: Opus code report: where reanimate is defined, which hulls carry it, what triggers it, whether it is gated by a condition that never fires, whether it is data-exposed, and what telemetry records it.

### Branches and design implications

Branch A - Reanimate exists and works.
- Implication: Deathless's signature may already be built and merely quiet. The design question becomes visibility, tuning, and feedback, not engine work.
- Recommended handling: Do not fund a new return-from-wreck rule; use data-only tuning and presentation to make the existing rule legible. Verify it appears in telemetry and in the sim's win/loss causes.
- If wrong: If it exists but is too weak to matter, the fix is tuning, not a new system.

Branch B - Reanimate exists but is quiet or broken.
- Implication: The rule is present but not functioning as described; this is a bug/activation/data issue, not a design invention.
- Recommended handling: Fix or activate first; then decide whether the repaired rule is the Deathless signature. This is likely small code or data work, but Opus must scope it.
- If wrong: Designing around a broken rule produces misleading sim results and false balance conclusions.

Branch C - Reanimate does not exist as described.
- Implication: Rey's engine ask is correct; Deathless's return-from-wreck signature is not built.
- Recommended handling: Treat it as a real engine ask and defer it behind the cheaper data-only identity work and the economy hook. Until then, Deathless can use reclaim, phase, armor, and no-shield prohibitions as its data-only identity.
- If wrong: If the owner assumes it exists and it does not, Deathless design is built on a missing system; if the owner funds it prematurely, it may delay cheaper identity work.

### Recommended default (support only)
Yes: Opus reports code truth first, and no Deathless design builds on reanimate until that report lands. Reasoning: the audits conflict on a factual question with a definite answer; the investigation is cheaper than rework. This is not an engine change by itself. If Branch A or B holds, the follow-up is data/tuning or a small fix; if Branch C holds, the follow-up is a scoped engine ask that should not block the data-only first pass.

## Not specified
- Exact current implementation of reanimate, the avenge hook, repair, shipyard, and reward code; these require Opus code truth.
- Exact file locations, data schema, and whether existing boolean gates are data-exposed or require code checks.
- Exact engine effort for the per-faction economy hook, shield recharge, and any missing return-from-wreck rule.
- Numeric tuning: Chorus feed heal rate, Ithar recharge rate, price-ladder values, salvage multipliers, and roster-gate lists.
- Acceptance thresholds for "beyond noise" metric divergence and "roughly balanced" mirror win rates.
- Whether the owner will adopt the six identities fully, pilot them, or reject them.
- Any campaign/map-layer faction asymmetry beyond the economy notes; Rey's audit explicitly does not cover it.
- Final owner verdicts on all five decisions; these briefs recommend defaults only.

End of briefs.
