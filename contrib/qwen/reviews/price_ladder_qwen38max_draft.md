# Price Ladder and Roster Gate Draft - Qwen

Model: Qwen3.8-Max, Thinking ON, Search OFF. Filed verbatim from the Qwen chat report (existing thread, Oct 25, 2026 retry); em dashes normalized to hyphens if any, wording otherwise unchanged. Run notes: the model selector was found on Qwen3.7-Plus and changed to Qwen3.8-Max before sending; no new limit notice was triggered. Qwen answered in a side-by-side comparison view with two parallel drafts and no preference was selected, so BOTH responses are filed below, verbatim in wording, with tables rendered as lines. No preference between Response 1 and Response 2 is expressed here; that choice belongs to the chair synthesis and to Ryan.

Status: DRAFT. Nothing here is decided until Ryan rules. PC-only.

--- RESPONSE 1 ---
Title: Voidsworn draft: price ladder and roster gate pass
For: Ryan (ruling), Opus (verification)
Status: DRAFT. Nothing here is decided. PC-only.
Scope: costs and availability only. No cp changes, no hull stat changes, no weapon stat changes, no admiral cost changes. No economy hook design. The Corsair salvage loop and the Chorus feed economy stay in the separate engine spike.

0. Observed baseline
OBSERVED: data.js:329 gives a hull with no explicit cost h.cost = Math.round((60*cp+10)/5)*5.
OBSERVED: this yields 70 for every cp-1 frigate and 130 for every cp-2 destroyer, across all factions.
OBSERVED: all Deathless hulls have sh:0. This is a roster fact, not a new gate, and this draft does not touch it.
APPROVED (context, not re-proposed here): Ithar cannot Brace; Chorus has no shipyard repair. Repair scope across shipyard, Drydock and Field is OPUS TO CONFIRM.
Everything numbered below is PROPOSED.

1. Pricing convention
PROPOSED: keep the existing cp formula as the shared base, then apply one faction-and-class multiplier and round once: cost = roundTo5( baseLadder(cp) * factionClassMultiplier ) where roundTo5(x) = Math.round(x/5)*5. This preserves the current five-point granularity while letting factions break the shared ladder.
OPUS TO CONFIRM: whether the current cost resolver can read a faction/class multiplier field or an explicit per-hull cost override. If it cannot, this becomes NEEDS CODE rather than DATA-ONLY. Do not assume the field exists.
For cruiser, carrier and battleship-and-above, the draft proposes multipliers only. Their current base costs are not in the supplied facts, so no absolute current price is claimed and none is invented. OPUS TO CONFIRM: the base ladder values for those classes before any absolute price is printed.

Hegemony
Frigate - 1.00 - 70 - The reference body against which every other faction's discount or premium is read.
Destroyer - 1.00 - 130 - The reference line hull stays unmarked so faction deltas stay legible.
Cruiser - 1.00 - base unconfirmed - No identity surcharge is justified while the Hegemony trait is still open.
Carrier - 1.00 - base unconfirmed - Baseline projection pricing, not a new trait claim.
Battleship+ - 1.00 - base unconfirmed - Price stays flat even where access is gated; the gate carries the identity load, not the number.
Worked: frigate 70 * 1.00 = 70; destroyer 130 * 1.00 = 130.
Implementation: DATA-ONLY candidate if a multiplier/override field is readable; otherwise NEEDS CODE. OPUS TO CONFIRM.
Hegemony paragraph: Hegemony stays at 1.0 across the ladder. Its trait is still open, and the questioned shield-stripper reading cannot be assumed when two factions are already shieldless. Giving it a price identity now would smuggle a trait ruling into a cost table. The baseline is also the measurement instrument: every other faction's number is a statement about distance from Hegemony, so moving Hegemony would move all six arguments at once. Keep the price flat and let the access gate below be the only Hegemony-specific burden, pending Ryan's trait ruling.

Voidsworn
Frigate - 1.00 - 70 - The screen is disposable; the armored identity is not paid for in pickets.
Destroyer - 1.15 - 150 - The line hull that holds a broadside is what the Voidsworn bill actually buys.
Cruiser - 1.15 - base unconfirmed - The same line premium continues into the anchor, so the core of the fleet stays expensive.
Carrier - GATED - n/a - A broadside line does not buy its damage from a carrier slot.
Battleship+ - 1.10 - base unconfirmed - The apex is the payoff of the line, so it carries a smaller premium than the hulls that hold it open.
Worked: frigate 70 * 1.00 = 70; destroyer 130 * 1.15 = 149.5 -> 150.
Implementation: DATA-ONLY candidate for the multipliers; carrier gate is NEEDS CODE if no availability flag exists. OPUS TO CONFIRM.

Corsairs
Frigate - 0.85 - 60 - The close-range raider body is cheap because it is expected to reach the target and not come back tidy.
Destroyer - 1.00 - 130 - The raid's anchor is not discounted; only the reaching arm is.
Cruiser - GATED - n/a - A salvage raider has no standardized mid-line anchor to stand behind.
Carrier - 0.90 - base unconfirmed - A raider carrier is a support shell for the run, not a battle-line investment.
Battleship+ - 1.20 - base unconfirmed - Buying an apex hull with a raiding doctrine is a mismatch and is priced as one.
Worked: frigate 70 * 0.85 = 59.5 -> 60; destroyer 130 * 1.00 = 130.
Implementation: DATA-ONLY candidate for multipliers; cruiser gate NEEDS CODE absent an availability flag. OPUS TO CONFIRM. No salvage income is modeled here.

Chorus
Frigate - 0.65 - 45 - The swarm is bought in bodies, so the smallest body carries the deepest discount.
Destroyer - 0.70 - 90 - The next body size stays cheap, keeping "many" available rather than trading up out of the swarm.
Cruiser - 0.85 - base unconfirmed - A mid-size body is a weaker deal than more small ones, so the discount narrows.
Carrier - 1.10 - base unconfirmed - A large platform is against the grain of a eating swarm and pays a premium.
Battleship+ - 1.25 - base unconfirmed - The swarm has no apex answer; the price refuses to offer one cheaply.
Worked: frigate 70 * 0.65 = 45.5 -> 45; destroyer 130 * 0.70 = 91 -> 90.
Implementation: DATA-ONLY candidate for multipliers. The repair prohibition is a separate NEEDS CODE item below. OPUS TO CONFIRM. No feed heal values are proposed.

Ithar
Frigate - 1.30 - 90 - The glass skirmisher is the identity unit, and elite bodies are paid for per hull.
Destroyer - 1.30 - 170 - The same elite premium holds at destroyer scale, so scaling the skirmish line hurts.
Cruiser - 1.15 - base unconfirmed - Outside the skirmish role the elite premium relaxes.
Carrier - 1.00 - base unconfirmed - A carrier is not the glass-skirmish argument, so it is left at baseline.
Battleship+ - 1.10 - base unconfirmed - Elite still applies at the apex, but the sharp premium belongs to the light line.
Worked: frigate 70 * 1.30 = 91 -> 90; destroyer 130 * 1.30 = 169 -> 170.
Implementation: DATA-ONLY candidate for multipliers; Brace gate and the proposed weapon-kind gate are NEEDS CODE items below. OPUS TO CONFIRM.

Deathless
Frigate - 1.45 placeholder, GATED - 100 counterfactual only - The last of their kind do not spend themselves on expendable small hulls.
Destroyer - 1.40 - 180 - The smallest purchasable Deathless hull is already a major commitment.
Cruiser - 1.45 - base unconfirmed - The relic anchor is rarer than a production line hull and priced accordingly.
Carrier - 1.50 - base unconfirmed - Old machines at projection scale are fewer and dearer.
Battleship+ - 1.60 - base unconfirmed - The apex is nearly unobtainable because it is a last survivor, not a class of ship.
Worked: frigate is gated, so the only honest example is the counterfactual 70 * 1.45 = 101.5 -> 100, which the engine must never charge because no purchase is legal. Destroyer 130 * 1.40 = 182 -> 180.
Implementation: DATA-ONLY candidate for multipliers, but the frigate placeholder must not become a purchasable row; frigate availability gate is NEEDS CODE absent a flag. OPUS TO CONFIRM.

2. Roster gate list
Each entry is PROPOSED unless marked APPROVED. Losses are deliberately different per faction so each one forces a different fleet-building question.
Hegemony - No battleship-and-above class band. PROPOSED. - Win with the mid ladder, or accept a hard capital ceiling; no apex endpoint to save a slow game. - NEEDS CODE unless a per-faction class availability flag already exists. OPUS TO CONFIRM.
Voidsworn - No carrier class. PROPOSED. - Spend the carrier slot on another line hull, and accept that the line has no organic carrier answer. - NEEDS CODE absent an availability flag. OPUS TO CONFIRM.
Corsairs - No cruiser class. PROPOSED. - Run the raid on frigates and destroyers, or jump to a capital; there is no mid-line anchor to fall back on. - NEEDS CODE absent an availability flag. OPUS TO CONFIRM.
Chorus - No shipyard repair. APPROVED prohibition. - Sustain bodies at contact or accept permanent loss; there is no repair-queue fallback behind the swarm. - NEEDS CODE. OPUS TO CONFIRM whether the same flag must cover Drydock and Field repairs, or only the shipyard path.
Ithar - Cannot Brace. APPROVED prohibition. - Fight by positioning instead of by bracing a line; the command option is not in the kit. - NEEDS CODE: boolean gate in canOrder. OPUS TO CONFIRM the existing flag/name.
Ithar - No stand-off / long-range precision weapon kind. PROPOSED. - Build the elite skirmish line for contact and disengage, not for a reach advantage it is not allowed to buy. - OPUS TO CONFIRM the weapon-kind taxonomy and whether an availability flag exists; otherwise NEEDS CODE. Do not invent a kind name.
Deathless - No frigate class. PROPOSED. - Every hull is a relic commitment; choose destroyer-scale attrition or a capital, and solve screening some other way. - NEEDS CODE absent an availability flag. OPUS TO CONFIRM.
Not a new gate: Deathless sh:0 is OBSERVED and unchanged.

3. Fleet sketches
All orders of battle below are PROPOSED illustrations, not budget tests and not measured balance. No campaign budget figure was supplied, so no total-credit claim is made. Price shape is relative to the Hegemony baseline.
Hegemony: 6 frigates, 4 destroyers, 2 cruisers, 1 carrier = 13 hulls. Flat baseline price shape with a broad middle and no apex tail. Cannot finish a stalled fight by dropping a battleship-tier anchor into it.
Voidsworn: 4 frigates, 5 destroyers, 2 cruisers, 1 battleship = 12 hulls. Cheap screen, expensive center, one paid apex; the bill concentrates in the destroyer/cruiser band. Cannot field a carrier slot at any price.
Corsairs: 8 frigates, 3 destroyers, 1 carrier = 12 hulls. A deep cheap tip over a small paid anchor, with the capital end either absent or deliberately overpriced. Cannot form a cruiser-line anchor; cannot hold a mid-line by buying the missing class.
Chorus: 12 frigates, 4 destroyers, 1 cruiser = 17 hulls. The lowest per-body bill and the tallest hull count, with almost no spend at the top. Cannot fall back on a repair queue, and cannot buy an economical apex answer.
Ithar: 4 frigates, 2 destroyers, 1 cruiser, 1 carrier = 8 hulls. A high per-hull bill and a thin roster; the premium sits on exactly the hulls that want to be numerous. Cannot Brace, and under the proposed weapon gate cannot buy a stand-off solution to being thin.
Deathless: 3 destroyers, 2 cruisers, 1 carrier, 1 battleship = 7 hulls. The smallest roster and the most rear-loaded bill; there is no cheap entry rung at all. Cannot screen with pickets, cannot replace a lost hull casually, and cannot hide a weak center behind body count.

4. Open items for Opus
1. Can the cost resolver at the current ladder site read a faction/class multiplier or an explicit cost override, or is a new read path required? OPUS TO CONFIRM.
2. Confirm the unrounded base ladder values for cruiser, carrier and battleship-and-above before any absolute price is committed. OPUS TO CONFIRM.
3. Confirm the round-once convention above does not double-round with the existing Math.round(.../5)*5 site. OPUS TO CONFIRM.
4. Does a per-faction class availability flag exist, and does the roster UI read the same flag the order/purchase path reads? OPUS TO CONFIRM.
5. Chorus repair prohibition scope: shipyard only, or Drydock and Field as well? OPUS TO CONFIRM.
6. Ithar Brace: confirm the canOrder flag name and that the gate is boolean, not a stat change. OPUS TO CONFIRM.
7. Ithar stand-off weapon gate: confirm the actual weapon-kind names before any flag is drafted. OPUS TO CONFIRM.
Least sure item: the Hegemony no-battleship-and-above gate. It is a structural tax with no ruled trait behind it, added only because the gating principle says every faction loses something, and it may over-constrain a faction whose identity is still open. What settles it: Ryan either rules the Hegemony trait and lets the loss follow from that, or explicitly rules that Hegemony takes a neutral baseline access tax and confirms which band should carry it.

--- RESPONSE 2 ---
Title: Voidsworn Design Draft - Price Ladder and Roster Gates
Status: DRAFT. Nothing here is decided until Ryan rules.
Prepared for: Ryan (owner/ruling authority), Opus (coder/verifier).
Scope: Data-only price ladder, roster gates, and prohibitions. The economy hook (Corsair salvage loop, Chorus feed kill-heal) is a separate scoped engine spike and is explicitly excluded.
Platform: PC-only.

1. Per-Faction Price Table
1a. Baseline formula (current state)
OBSERVED (data.js:329): any hull without an explicit cost field receives: h.cost = Math.round((60 * cp + 10) / 5) * 5
This yields, for the two confirmed tiers: Frigate cp 1 base 70; Destroyer cp 2 base 130.
OBSERVED: every cp-1 frigate costs 70 and every cp-2 destroyer costs 130, regardless of faction. This shared ladder is the thing the approved first change breaks.
For higher tiers I infer costs from the same formula. These are NOT confirmed in the brief and are marked accordingly: Cruiser cp (assumed) 3 inferred base 190 OPUS TO CONFIRM; Carrier 4 250 OPUS TO CONFIRM; Battleship 5 310 OPUS TO CONFIRM; Above BS 6+ 370+ OPUS TO CONFIRM.

1b. Proposed per-faction multiplier
PROPOSED: each faction gets a flat cost multiplier applied to the base formula result, rounded to the nearest 5. The multiplier is the single data field added per faction. No cp values, hull stats, weapon stats, or admiral costs change.
Hegemony 1.0 - Baseline standard; the reference point every other faction deviates from.
Voidsworn 1.20 - Armored broadside hulls are material-heavy and slow to fit out; you pay for the plate.
Corsairs 0.90 - Close-range salvage raiders run light, fast, and cheap; they expect to recoup losses through salvage (economy hook handles the recoup, not this table).
Chorus 0.65 - Swarm doctrine: many bodies, each one expendable; the cheap cost IS the identity.
Ithar 1.45 - Elite glass skirmishers: precision-built, few hulls, each one a significant investment.
Deathless 1.70 - Old machines, last of their kind; you are not building a ship, you are maintaining a relic.

1c. Worked examples - Frigate (cp-1, base 70)
Hegemony 70 x 1.0 = 70 cost 70 - Standard issue.
Voidsworn 70 x 1.20 = 84, round to 85 cost 85 - Armored frigate costs a premium for its plate.
Corsairs 70 x 0.90 = 63, round to 65 cost 65 - Light raider hull, cheap to lose and replace.
Chorus 70 x 0.65 = 45.5, round to 45 cost 45 - Expendable swarm body; you buy these in bulk.
Ithar 70 x 1.45 = 101.5, round to 100 cost 100 - A skirmisher frigate is a precision instrument, not a disposable.
Deathless 70 x 1.70 = 119, round to 120 cost 120 - Even the smallest Deathless hull is an irreplaceable artifact.

1d. Worked examples - Destroyer (cp-2, base 130)
Hegemony 130 x 1.0 = 130 cost 130 - Standard destroyer.
Voidsworn 130 x 1.20 = 156, round to 155 cost 155 - Broadside destroyer, heavy armor tax.
Corsairs 130 x 0.90 = 117, round to 115 cost 115 - Fast raider, still cheap enough to risk in a boarding action.
Chorus 130 x 0.65 = 84.5, round to 85 cost 85 - A Chorus destroyer is still a swarm unit, just a bigger bug.
Ithar 130 x 1.45 = 188.5, round to 190 cost 190 - Glass-cannon destroyer; you will field very few of these.
Deathless 130 x 1.70 = 221, round to 220 cost 220 - A Deathless destroyer is a museum piece with guns. Losing one is a strategic event.

1e. Hegemony baseline note
Hegemony stays at 1.0. The brief flags that Hegemony's defining trait is still open (shield-stripper was questioned because Chorus and Deathless are shieldless). I am not inventing a replacement trait here. Hegemony's multiplier is 1.0 because it is the reference, not because it has no identity. When Ryan rules on Hegemony's identity, the multiplier or a roster gate can be revisited. No change proposed in this draft.

2. Roster Gate List
Each faction loses access to something. The loss converts identity into a fleet-building decision at the roster screen.
2a. Approved prohibitions (from Oct 24, 2026 ruling)
Ithar - Cannot Brace. Boolean gate in canOrder. - Ithar captains must commit to kiting or disengaging. They cannot hunker down and tank a volley. Every engagement is a positioning puzzle: if you get caught, you break. - NEEDS CODE. A boolean flag (e.g. canBrace: false) read by canOrder. The flag itself is data-only, but canOrder must check it. OPUS TO CONFIRM whether canOrder already reads per-faction booleans or needs a new branch.
Chorus - No shipyard repair. Feed mechanic replaces it. - Chorus players cannot dock and patch hulls between fights. They must feed (economy hook, out of scope here) or accept attrition. Fleet composition skews toward disposable volume because you cannot nurse a wounded ship back. - NEEDS CODE. Scope across shipyard, Drydock, and Field repair paths. OPUS TO CONFIRM the full list of repair entry points that need the gate.
Deathless - No shields. All Deathless hulls sh:0. - Already a roster fact, not a new gate. Deathless fleets must rely on armor and positioning. No shield-stripping weapons are "wasted" on them, which interacts with Hegemony's open trait question. - DATA-ONLY. Already in place. No change needed.

2b. Proposed new roster gates - These are PROPOSED. Ryan rules.
Voidsworn - No carrier-class hulls. - Voidsworn cannot build or field carriers. No fighter wings, no launch bays. - Voidsworn must bring their own screening with frigates and destroyers. They cannot project power beyond gun range. A Voidsworn fleet is a wall of broadsides; if the enemy kites, Voidsworn must close the gap with hulls, not fighters. - DATA-ONLY if carrier hulls have an availability flag per faction. NEEDS CODE if the roster screen filters by class and no per-faction class exclusion exists yet. OPUS TO CONFIRM which.
Corsairs - No battleship-class or above. - Corsairs cannot build battleships or superheavies. - Corsairs win through speed, numbers, and closing distance. They cannot build a siege line. Against a Deathless or Voidsworn heavy fleet, Corsairs must swarm the flanks rather than trade broadsides. Fleet shape is wide and shallow, never tall. - DATA-ONLY if a per-faction class cap field exists. NEEDS CODE otherwise. OPUS TO CONFIRM.
Chorus - No cruiser-class or above. - Chorus cannot build cruisers, carriers, or battleships. - Chorus is locked into frigates and destroyers. The swarm is the strategy. Against a Hegemony cruiser line, Chorus must overwhelm with body count. This makes the Chorus price multiplier (0.65) load-bearing: if the discount is too small, Chorus simply cannot field enough hulls to matter. - DATA-ONLY if per-faction class cap exists. NEEDS CODE otherwise. OPUS TO CONFIRM.
Ithar - No Brace (approved, 2a above) AND no heavy-armor modules (PROPOSED addition). - Ithar cannot Brace and cannot equip heavy armor plating. - Reinforces glass-cannon identity. Ithar ships are fast and hit hard but cannot be built as tanks. Fleet-building decision: every Ithar hull is a DPS race. You invest in weapons and engines, never in survival. - Brace gate: NEEDS CODE (see 2a). Heavy-armor module gate: OPUS TO CONFIRM whether module loadout filtering exists per faction. If yes, DATA-ONLY. If no, NEEDS CODE.
Deathless - Hard roster cap of 8 hulls per fleet (PROPOSED). - Deathless cannot field more than 8 ships in a single fleet, regardless of cp budget. - "Last of their kind" made mechanical. Every Deathless ship lost is a crisis. The player must protect each hull, withdraw damaged ships, and avoid attrition fights. Against Chorus (many cheap hulls), Deathless must win through quality and positioning before numbers tell. - NEEDS CODE. A per-faction fleet-size cap does not exist in the current system as far as the brief indicates. OPUS TO CONFIRM. If the cap is too invasive for this pass, a DATA-ONLY alternative is marking Deathless as having no frigate-class hulls in their roster (they simply do not build small ships), which reduces fleet size naturally. OPUS TO CONFIRM which approach is feasible.
Hegemony - TBD. - No gate proposed. - Hegemony's identity is open. Assigning a gate now would be inventing a trait, which the brief prohibits. Hegemony gets all classes, all weapons, all systems until Ryan rules. - No implementation.

2c. Gate interaction note
Chorus loses cruisers-and-up AND loses shipyard repair. Together these mean Chorus fields large numbers of cheap, unrepairable frigates and destroyers. This is intentional and on-identity. However, it means Chorus is the faction most sensitive to the price multiplier. If 0.65 makes Chorus too dominant in hull count, Ryan should adjust the multiplier before adjusting the gate. The gate is the identity; the number is the tuning knob.

3. Fleet Sketches
These sketches show what a fleet looks like under the PROPOSED ladder and gates. They are illustrative, not prescriptive. Budget is assumed at a mid-game cp total; the shapes matter more than the exact counts.
Hegemony (multiplier 1.0, no gate) - Shape: balanced combined-arms fleet. 2 cruisers, 3 destroyers, 4 frigates, 1 carrier for screening. Price shape: flat and predictable. You pay the listed price. No surprises. What it cannot do anymore: nothing is removed. Hegemony is the control group. Its weakness is having no extreme strength. Note: fleet shape will shift once Ryan assigns Hegemony an identity.
Voidsworn (multiplier 1.20, no carriers) - Shape: 1 battleship, 2 cruisers, 3 destroyers, 3 frigates. No carrier, no fighters. A wall of armor and broadside guns. Price shape: everything costs 20% more than Hegemony equivalent. A Voidsworn battleship at cp-5 costs roughly 370 (310 x 1.20 = 372, round to 370). The fleet is expensive but each hull is tough. What it cannot do anymore: no fighter screen, no long-range projection. If the enemy stays at range, Voidsworn must close under fire. Against Corsairs, this is a chase problem. Against Ithar, it is a kiting problem.
Corsairs (multiplier 0.90, no battleships+) - Shape: 2 cruisers, 4 destroyers, 6 frigates. Fast, aggressive, close-range. No superheavies. Price shape: cheap across the board. A Corsair frigate at 65 and destroyer at 115 means you can field more hulls than Hegemony for the same budget. The 10% discount compounds across a large fleet. What it cannot do anymore: no battleship means no answer to a Deathless or Voidsworn heavy line except swarming the flanks. Corsairs must close to boarding/salvage range (economy hook handles what happens there; not in scope).
Chorus (multiplier 0.65, no cruisers+, no shipyard repair) - Shape: 6 destroyers, 12 frigates. Eighteen hulls. No heavy ships. No repair dock. Price shape: extremely cheap per hull. A Chorus frigate at 45 means you can field a dozen for what Hegemony spends on five. The fleet is wide, shallow, and disposable. What it cannot do anymore: no cruisers means no heavy firepower. No repair means attrition is permanent until the feed mechanic (separate spike) addresses it. Losing three frigates in a skirmish is acceptable. Losing a destroyer stings. Losing half the fleet is a reset.
Ithar (multiplier 1.45, no Brace, no heavy armor - PROPOSED) - Shape: 1 cruiser, 2 destroyers, 3 frigates. Six hulls. Every one a glass cannon. Price shape: expensive. An Ithar frigate at 100 costs more than a Hegemony destroyer. You field fewer hulls, each one loaded with weapons and engines, minimal armor. What it cannot do anymore: no Brace means no hunkering down. No heavy armor means no tanking. An Ithar fleet that gets caught in a corner dies fast. The fleet must kite, disengage, and re-engage on its own terms. Against Voidsworn, Ithar must stay at range and chip. Against Chorus, Ithar must pick targets carefully because every shot must count.
Deathless (multiplier 1.70, no shields, PROPOSED roster cap of 8) - Shape: 1 battleship, 1 cruiser, 2 destroyers, 2 frigates. Six hulls under the proposed cap. No shields. All armor and old guns. Price shape: brutally expensive. A Deathless destroyer at 220 costs more than an Ithar destroyer. A Deathless battleship at cp-5 would cost roughly 530 (310 x 1.70 = 527, round to 530). You field very few hulls and protect each one. What it cannot do anymore: no shields means every weapon that strips shields is irrelevant against them, but every kinetic and explosive weapon hits armor directly. No fleet depth; if you lose two hulls, you have lost a third of your fleet. Against Chorus, Deathless must avoid being surrounded. Against Corsairs, Deathless must not get swarmed at close range.

4. Implementation Notes Summary
Per-faction cost multiplier field - DATA-ONLY - Add a multiplier field (e.g. faction.costMult) read by the cost formula in data.js. The formula becomes Math.round((60 * cp + 10) * mult / 5) * 5. Opus to confirm whether the rounding should apply before or after the multiplier.
Explicit per-hull cost override - DATA-ONLY - Hulls with an explicit h.cost already skip the formula (OBSERVED). This path is unchanged. If Ryan later wants a specific hull to break the multiplier, the explicit cost field handles it.
Ithar cannot Brace - NEEDS CODE - Boolean flag on faction (data), but canOrder must read it. OPUS TO CONFIRM whether canOrder currently accepts faction-level booleans or needs a new check.
Chorus no shipyard repair - NEEDS CODE - Gate must cover shipyard, Drydock, and Field repair paths. OPUS TO CONFIRM the full list of repair entry points. The flag is data; the check at each entry point is code.
Deathless no shields - DATA-ONLY - Already in place (all Deathless hulls sh:0). No work needed.

Least sure item: The item I am least sure about is the Deathless hard roster cap of 8 hulls. It is the only PROPOSED gate in this draft that introduces a new mechanical constraint (a fleet-size cap) rather than filtering an existing class or system. Every other gate says "you cannot have X thing." The Deathless cap says "you can have at most N things," which is a different kind of rule and may interact with the fleet-UI, the cp-budget display, and any future admiral abilities that grant bonus hulls. I do not know whether the current codebase has a clean injection point for a per-faction fleet-size limit, and I suspect it does not. What would settle it: Opus confirms whether a fleet-size cap can be enforced at roster-build time without touching the economy or cp-budget logic. If it cannot, the fallback (remove frigate-class hulls from the Deathless roster entirely, DATA-ONLY) achieves a similar "few, powerful hulls" shape without new code. Ryan then decides whether the cap or the fallback better serves "last of their kind." Alternatively, if Ryan feels the Deathless multiplier of 1.70 already limits fleet size through budget pressure (you simply cannot afford many hulls), the cap may be unnecessary and should be dropped. A quick playtest with 1.70 pricing and no cap would settle whether the price pressure alone is sufficient.
End of draft. All PROPOSED numbers and gates are subject to Ryan's ruling. No implementation begins until Ryan approves and Opus confirms code paths.
