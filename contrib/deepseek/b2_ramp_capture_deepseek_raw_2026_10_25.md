# Raw return: B2 ramp and capture sanity check, DeepSeek, Oct 25, 2026

Source: fresh DeepSeek chat (chat.deepseek.com), DeepThink ON, Search ON, no sign-in needed, no other chat opened or referenced. Filed verbatim below; the working copy is reviews/b2_ramp_capture_deepseek_2026_10_25.md.


Design sanity check: 10 / 14 / 20 ship enemy fleets vs a 4 to 7 ship player fleet

Context respected: battles grow over a run toward about 10, 14 and 20 ships on the board by sector as a guide, not a cap; the player fleet stays small and elite at 4 to 7 ships; the ramp replaces an 8-ship enemy cap; capture after a win lets each prize be added to the fleet, stripped for parts or modules, or ransomed for credits; full fleet means prizes auto-scrap; sector flagships can never be captured; nothing was invented beyond this.

## 1. Design risks of a 3x to 4x enemy ship-count advantage

Tempo and activation economy. This is the biggest risk. In most turn-based tactics games, ship count is close to activation count, and activation count is tempo. If the enemy gets 20 activations to your 5, the enemy can act four times between each of your moves. That produces a "wait through the enemy turn" feel, and it also means the player cannot respond to threats as they develop. Comparable games handle this by separating "units on the board" from "things that act per turn." Into the Breach does this most cleanly: the player has 3 mechs and the Vek can number 6 to 10+, but every Vek telegraphs its attack on the prior turn, so the player's three activations are spent solving a readable puzzle rather than reacting to unseen moves (Into the Breach, Subset Games, 2018). The lesson is that outnumbering is survivable when enemy intent is fully telegraphed and each enemy has one clear attack you can pre-empt. If your 20-ship fleet has hidden or reactive behavior, 3 to 4 activations of downtime per player move will feel bad.

Focus fire and alpha strike. With many more enemy ships, the enemy can concentrate fire on one player ship. Because the player fleet is small and elite (4 to 7), losing even one ship is a large fraction of your force, so focus fire is disproportionately punishing. Conversely, a player alpha strike that deletes 2 to 3 enemy ships per turn is much less meaningful against 20 than against 6, so the enemy count ramp quietly nerfs player alpha strike as a strategy. BattleTech (Harebrained Schemes, 2018) handles the mirror problem with the initiative and phase system: units act in initiative order, and lighter units reserve their action to act later, so a numerically superior enemy cannot simply dump all damage before the player responds (BattleTech, initiative and "reserve" mechanics). Battlefleet Gothic: Armada (Tindalos, 2016) uses a different brake: its ships have broadside firing arcs and a "firing solution" facing requirement, so a large enemy fleet cannot all bring guns to bear on one target in the same turn. You likely need one of these structural brakes (phases, arcs, or per-turn action budgets) rather than relying on raw counts.

Turn length and readability. Twenty enemy ships each doing a move and an attack is a lot of animation and a lot of board state to track. Into the Breach limits the board to a small grid and telegraphs exactly one action per enemy per turn, which keeps a 10-enemy turn readable in seconds. Battlefleet Gothic: Armada keeps fleet sizes in the mid single digits and compensates with ship class and abilities. If you go to 20, you need compression: group identical ships into squadrons that move and fire as one, or batch-resolve enemies with the same order. Otherwise the 20-ship sector will be the sector players quit in.

Mental load and target prioritization. With 20 targets, the player must triage, and triage is only fun if the threats are distinguishable. If 20 ships are 20 copies of the same frigate, the board is noise. If they are 4 squadrons of 5 with distinct roles, it is a puzzle. Into the Breach and BattleTech both make enemies visually and mechanically distinct so that prioritization is a real decision.

Summary of comparable approaches: Into the Breach = small player force vs larger enemy count made fair by full telegraphing and one action per enemy. BattleTech = initiative phases and reserve actions so numbers do not equal tempo. Battlefleet Gothic: Armada = small fleets, firing arcs, and facing rules as the brake on focus fire. None of them simply lets raw count triple without a structural counterweight.

## 2. How the ramp should scale, and how difficulty settings should shift it

Both count and quality, but not at the same rate. Count is the cheap lever and the one your plan already uses. Quality is the lever that keeps the player's small elite fleet meaningful. If you scale only count, the player's elite ships become irrelevant because the answer is always "more hulls." If you scale only quality, the ramp toward 20 ships in the plan is not happening. A workable split: count carries the sector-to-sector ramp (10, 14, 20), while quality carries the within-sector escalation (later waves in a sector bring better ships). That way the player's elite 4 to 7 ships always have a quality edge that is being squeezed, not erased.

Battlefleet Gothic: Armada is the closest model: it escalates by adding ship classes and tonnage rather than by flooding the board, and its point-buy fleet construction means a "bigger" enemy is a better-composed enemy, not just a longer list. BattleTech escalates by lance composition and pilot skill (veteran and elite pilots), not by raw mech count, which keeps the player's lance of 4 meaningful against numerically similar or slightly larger opposition.

Difficulty settings should shift the mix, not just the number. A clean structure:

- Easy: lower the count ramp (for example 8, 11, 15) and keep quality flat.
- Normal: the planned 10, 14, 20 with the intended quality curve.
- Hard: keep the count ramp but raise quality one tier earlier, and add enemy coordination (focus-fire behavior, squadron stacking) rather than more hulls.

Shifting quality and behavior instead of count preserves turn length and readability on higher difficulties, which is where count inflation usually breaks the experience. Into the Breach's difficulty modes add enemy types and behaviors rather than simply adding more Vek, which is the same principle (Into the Breach difficulty design, Subset Games).

Practical guardrail: cap simultaneous activations per turn even as total ships grow, by using squadrons or a per-turn "active enemy" budget. The plan says the ramp replaces an 8-ship cap, so the cap is already being lifted; lifting the board cap is fine, lifting the activation cap is the dangerous part.

## 3. Capture economy pitfalls and guardrails

Snowballing. If adding a prize to the fleet is usually correct, the fleet grows, wins more, and captures more. That is a compounding loop, and it directly fights the "small and elite, 4 to 7 ships" design goal, because the optimal play drifts toward a big fleet. Guardrails: make adding a prize cost something recurring (upkeep, crew, a fleet-slot cost that pushes out a better ship), make captured ships start damaged or under-crewed, and make the "add" option weakest for the ships the player most wants (sector flagships are already uncapturable, which is a good instinct). BattleTech handles salvage with a cost: salvage is limited by contract salvage rights and by the mechbay's capacity and repair time, so a bigger stable of mechs is a logistics burden, not a free power spike (BattleTech salvage and mechbay systems).

Credit floods. If ransoming prizes is the safe default, every battle ends in a shower of credits and the economy inflates. Prices then have to rise, and the player's choices stop mattering. Guardrails: make ransom value scale down with fleet size or with repeats (diminishing returns), make ransom a delayed payout (credits arrive after the sector), and keep strip-for-parts as the option that converts to specific modules rather than generic currency, so the three options are not all secretly "money." Battlefleet Gothic: Armada's post-battle rewards are gated by campaign structure and ship upkeep, which keeps a single battle from being an economic windfall.

Decision fatigue after every battle. Three choices after every one of many battles across a run is a lot of prompts. Guardrails: auto-resolve the trivial cases (your plan already auto-scraps when the fleet is full, which is good), present the three options with a clear "recommended" default and a one-click "take the best" for players who do not want to engage, and batch the decision if multiple prizes drop in one battle. Into the Breach avoids this entirely by not having a between-battle loot choice, which is a reminder that fewer, higher-stakes capture decisions (for example, only certain battles yield prizes) may be better than a prompt after every fight.

Guardrail summary: make "add" carry recurring cost, make "ransom" diminish or delay, make "strip" convert to specific value rather than generic currency, auto-resolve trivial drops, and consider gating prizes to non-trivial battles so the decision stays interesting.

## 4. Five things to measure in the simulation

1. Player activation share per battle. Average player activations as a fraction of total activations per turn, by sector. If the player's share drops below roughly one in three, tempo complaints are likely. Track it against the 10, 14, 20 ramp. (Comparable benchmark: Into the Breach keeps player activation share high by design; watch for yours drifting down.)

2. Focus-fire loss rate. How often a player ship dies in a single enemy turn, and the average number of enemy ships that can target one player ship per turn. A rising curve as sector count grows is the early warning for the "lose one ship and the run is over" problem.

3. Player alpha-strike effectiveness. Average enemy ships destroyed per player turn as a fraction of total enemy ships. If this fraction falls sharply from sector 1 to sector 3, the player's elite-fleet fantasy is being eroded by count, and quality scaling needs to compensate.

4. Capture option distribution and fleet-size drift. What fraction of prizes are added vs stripped vs ransomed, and the resulting average player fleet size at each sector. If "add" is chosen most of the time and fleet size creeps above 7, snowballing is confirmed. Also track credit income per battle and total credits at sector end to catch floods.

5. Turn duration and decision time. Median and 90th-percentile time for the enemy turn and for the capture decision, by sector. This is the direct proxy for turn-length and decision-fatigue risk, and it is the cheapest thing to instrument.

A useful sixth if you have room: readability proxy, such as the number of distinct enemy ship types on the board at once. If sector 3 fields more than a handful of types, the 20-ship board is probably noise rather than a puzzle.

Sources (from the chat's Search results):

- Into the Breach (Subset Games, 2018): small player squad vs larger Vek count, full attack telegraphing, one action per enemy per turn, difficulty via enemy types and behavior. https://subsetgames.com/itb.html and https://into-thebreach.fandom.com
- BattleTech (Harebrained Schemes, 2018): initiative phases, reserve actions, salvage limited by contract rights and mechbay capacity, escalation via lance composition and pilot skill. https://battletech.fandom.com/wiki/Initiative and https://battletech.fandom.com/wiki/Salvage
- Battlefleet Gothic: Armada (Tindalos Interactive, 2016): small fleets, firing arcs and facing as a brake on focus fire, escalation via ship classes and point-buy composition, campaign-gated rewards and upkeep. https://battlefleetgothic.fandom.com and https://www.tindalos-interactive.com

Note on precision: the specific numeric behaviors above (for example, Into the Breach's enemy counts, BattleTech's initiative order details) are drawn from the games' documented mechanics and community wikis; exact tuning values vary by patch, so treat the numbers as directional rather than exact.
