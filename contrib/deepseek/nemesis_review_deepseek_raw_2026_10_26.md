# Nemesis behaviour review, DeepSeek leg (brief muse_2026-10-26c, Job 2)

Model: DeepSeek web chat, DeepThink ON and Search ON (verified by toggling), fresh chat, Oct 26, 2026. All five pack files attached (leg prompt, evidence pack, port_notes_b4.txt, port_notes_r42.txt, data_nemesis.txt). Filed verbatim below; the model's citations appear as bracket numbers whose reference list was not included in the return, so those claims are leg-stated, not chair-verified.

---

Job 2: Nemesis faction behaviour review (blind leg)

Research findings

Shadow of Mordor / Shadow of War. The Nemesis system generates orc captains procedurally with names, appearances, personalities, strengths and weaknesses, and lets them remember encounters, gain traits, return from death and taunt the player about specific past events. Defeated enemies can be promoted and return stronger; enemies you lose to remember that too, level up and comment on it. The memory is made visible through dialogue that references past fights and through scars and changed appearance. Warner Bros. patented the system (US10,926,179 / US10926179B2, granted 2021, running to 2036), which is why the comparison matters and why no other game can copy it wholesale. Shadow of War widened the system to followers who remember how you treated them, and to more procedural variety in behaviour and abilities. The design lesson is that memory only lands when the player can see and hear it: a taunt about the exact weapon you used, a scar from the fight, a promotion that changes the silhouette. Invisible stat changes do not create rivalry. [3] [4]

XCOM 2: War of the Chosen. The Chosen are persistent rivals explicitly inspired by Shadow of Mordor. They remember previous battles, reference what happened, develop procedural strengths and weaknesses across encounters, taunt soldiers they dislike and can kidnap your units. The design goal was to force the player to change tactics each time and to give the enemy personality where there was previously a void. This is the closest comparison for a single named rival who adapts between fights, and it shows the value of a clear pre-fight identity plus mid-fight adaptation that the player can attribute to the rival. [30]

Hades. Hades uses memory differently: the cast remembers your runs, reacts to victories and defeats, and turns failure into relationship progress. It is not a Nemesis system, but it sharpens one judgement: memory that is only a stat multiplier is weaker than memory that is spoken back to the player. A rival who says "last time you beat me with torpedoes" does more work than a hidden +20% shield value.

Warframe Kuva Liches. The Lich system is often cited as a rival system, but it is widely criticised for a formula where the Lich wins until you win once and then disappears forever, with little memory in between. That is a useful negative example for the Deathless faction: a single revive is fine, but it needs to change the relationship visibly or it becomes a scripted step rather than a rivalry.

Six faction verdicts

Corsair: raids and flees

What is implemented. NEM_FAC.corsair.beh sets clock:1, flee:{hull:.35}, strike:'raid', fleet:'swarm'. A full clock triggers nemStrike(): take 25% of credits if you have 30 or more, else cut out the lowest-hull non-flagship ship under 25% hull if you have three or more ships, and riches increases by one. In battle, nemFleeCheck() makes him flee when his flagship hull is at or below 35%, and riches adds one cheapHull ship per level plus one for the riches special.

Match to the ruling. Both verbs are present. "Raids" is the map strike, "flees" is the battle check. The implementation is direct.

Readability before the fight. The data comment says the raid is "always announced on his card first", but the pack does not establish what the card looks like in the Godot port or whether the player sees it before the strike resolves. The flee condition is readable in the battle UI once you know his hull threshold, but the pack does not describe a pre-fight telegraph for the flee rule. UNSURE on both.

Fairness. The raid can take a ship under 25% hull if you have fewer than 30 credits. That is a ship loss. The "announced on his card first" note is a mitigation only if the card is actually shown and understood before the strike. The pack does not establish that. The flee rule itself steals no control and loses no ship, so it is fair.

Distinctness. The flee-and-return-hire loop is meaningfully distinct from the other five in play: he is the only faction that leaves a losing fight and comes back with more ships. The raid is also the only strike that touches credits or ships directly. Distinct.

Deathless: returns once after death

What is implemented. NEM_FAC.deathless.beh sets clock:.5, revive:1, strike:'tithe', fleet:'heavy'. Clock gains are halved and rounded to halves. nemAfterBattle sets revived on the first flagship death if beh.revive is set and he has not yet revived, adds a scar, and in sector 3 drops met back one so he can meet you again. The tithe strike takes 6% maximum hull from every ship. He never flees (revive is separate from flee, and Deathless has no flee block).

Match to the ruling. "Returns once after death" is implemented exactly: one revive, then the second death is final. The halved clock is a tuning choice that makes the return slower, not a second verb.

Readability before the fight. The revive is not readable before the fight in any way the pack establishes. The player may infer it from the faction name or the scar after the first death, but there is no pre-fight line or card text in the pack that says "he will come back once". The tithe is a map strike; whether it is announced is UNSURE from the pack.

Fairness. No control is stolen. The tithe drains hull but does not kill ships outright, so no ship loss without warning. The revive is a fair surprise because it is bounded to one and the player can see the scar afterwards.

Distinctness. The once-only revive is a strong identity hook, but in play it is a single scripted second appearance. Once the player has seen it, the faction's distinct behaviour is spent unless the return fight feels different. The halved clock makes him slower, which is a number, not a new verb. Moderately distinct.

Ithar: duels and withdraws

What is implemented. NEM_FAC.ithar.beh sets clock:1, flee:{shields:1,hull:.6}, strike:'duel', fleet:'duel'. applyNemesis builds a duel fleet: keep the flagship and the three biggest ships, all elite with +6 aim and +5 crit. nemFleeCheck() makes him and all capital escorts flee when every flagship shield is at or below 0.5 and hull is at or below 60%. The duel strike is listed in the data but the pack does not describe a separate map action for it beyond the fleet build and the flee condition.

Match to the ruling. "Duels" is carried by the small elite fleet and the withdrawal test; "withdraws" is the nemFleeCheck block. The verb "duel" is more of a fleet shape and AI posture than a distinct challenge mechanic. The pack does not show a formal duel rule (for example a flagship-only engagement). This is a partial match.

Readability before the fight. The elite fleet composition is visible once the battle starts. The withdraw condition is readable from shield and hull bars. There is no pre-fight card or line in the pack that tells the player he will leave when his shields are down and hull is under 60%. UNSURE on pre-fight telegraph.

Fairness. Withdrawal loses you nothing and steals no control, so it is fair. The elite fleet is a difficulty spike, not a fairness violation.

Distinctness. The shield-and-hull withdraw test is different from the Corsair's hull-only test, and the small elite fleet is a different fight shape from the swarm or the heavy line. Distinct enough in play.

Chorus: feeds on your losses

What is implemented. NEM_FAC.chorus.beh sets feeds:1, adaptFast:1, strike:'swarm', fleet:'swarm'. nemFeedLosses(n) increments fed (max 8) for every battle with player losses. In applyNemesis, Chorus hull is multiplied by 1 + .04 * fed, capped at .32. adaptFast makes nemAdapt() run after every meeting, not just every sector, and the cap includes beaten and scars.

Match to the ruling. "Feeds on your losses" is implemented literally: your ship losses make his hull tougher. The adaptation acceleration is an extra layer, not the feeding verb itself.

Readability before the fight. The pack does not establish any line, card or UI element that tells the player "he is fed 3, so his hull is 12% higher." The only visible signal is that his ships are harder to kill, which is ambiguous. Invisible state. This is the weakest readability of the six.

Fairness. No control stolen and no ship lost without warning, so the fairness constraints are technically met. But invisible scaling is a fairness problem in spirit: the player cannot learn why the fight is harder.

Distinctness. The swarm fleet and the loss-fed toughness are distinct in numbers, but the player may not perceive the cause. Without a visible fed counter or a taunt about your losses, it collapses into "his ships are tanky." Distinct in data, weak in felt play.

Hegemony: reinforces

What is implemented. NEM_FAC.hegemony.beh sets strike:'reinforce', formation:1, fleet:'heavy'. The reinforce strike forces the reinforcement event at round 3 in campaign3d.js battleScreen. formation gives his synchronized fire one hex further reach. Traits and the heavy fleet build around an artillery line.

Match to the ruling. "Reinforces" is implemented as a guaranteed round-3 reinforcement event. That is a direct match at the battle level. The formation special is an adaptation flavour, not a second verb.

Readability before the fight. The pack does not establish a pre-fight warning that reinforcements will arrive at round 3. The player may learn it by playing the fight once. UNSURE on pre-fight telegraph.

Fairness. Reinforcements are a difficulty increase, not a control theft. No ship is lost without warning. Fair.

Distinctness. The guaranteed round-3 reinforcement is a clear fight-shape difference from the other five. The artillery line and formation bonus support it. Distinct in battle rhythm.

Voidsworn: challenges

What is implemented. NEM_FAC.voidsworn.beh sets clock:1.5, noFlee:1, strike:'challenge', fleet:'line'. Clock gains are multiplied by 1.5. B.nemNoRout means the 35% rout rule never applies. dmgMult gives +.2 damage between his flagship and your pflag flagship, both ways. The challenge strike is listed in the data, but the pack describes the challenge primarily as the mutual +20% flagship damage, not as a separate map action or formal duel invitation.

Match to the ruling. "Challenges" is carried by the mutual flagship damage bonus and the no-rout rule. It is more of a damage modifier and a morale rule than a distinct challenge structure. The player is not offered a choice to accept or decline. Partial match: the verb is present as a fight condition, not as a challenge event.

Readability before the fight. The mutual +20% is not surfaced in the pack as a pre-fight line or card. The no-rout rule is also not telegraphed. UNSURE on readability.

Fairness. The mutual damage bonus is symmetric, so it is fair. No control stolen. No ship lost without warning.

Distinctness. The no-rout plus flagship duel damage is distinct, but it is close to "a normal fight with a damage buff". The fast clock is a number. It is less distinct in felt play than Corsair, Ithar or Hegemony.

Memory system

What he remembers. The pack gives him several memory stores: seen (the weapon kinds you used most, feeding nemAdapt()), beat (the weapon that beat him, used in the "again" line via {beat} and NEM_BEAT_WORD), scars and scarList (causes and epithet markers), fed (Chorus losses), riches (Corsair), revived (Deathless), and epithet (updated on each scar). Adaptations are drawn from what you leaned on: lances and ion lead to shields, torpedoes and wings lead to point defense, rams and boarding lead to armor, batteries and broadsides lead to evasion, and evasive play leads to aim.

What the player sees. The "again" line with {beat} is the strongest visible memory: "Last time you beat me with torpedoes. It will not work twice." Persona meet lines (NEM_LINES.meet) are faction and persona flavoured, not memory of the player. Scars add an epithet (nemScar picks an unused epithet) and a scar overlay, so the player can see that he survived. Adaptations are faction-worded in NEM_ADAPT_FAC, but the pack does not establish that the player sees a line explaining the adaptation ("you leaned on lances, so I reinforced shields"). The beat word is visible in the "again" line; the adaptation reason is not.

What stays invisible. fed (Chorus) is a hidden hull multiplier. riches (Corsair) adds ships, which is visible, but the causal link to your credits or his raids is not stated in the pack. The adaptation scores and the chosen counter are invisible unless a line surfaces them. The clock value itself is not described as a visible UI element. Scars buff his damage (dmg *= 1 + .1 * scars), but the player sees the scar, not the number.

Judgement. The memory is stronger than a pure stat system because the {beat} line and the scar epithets are visible. It is weaker than Shadow of Mordor or the XCOM Chosen because most of the adaptive state (fed, adaptation reasons, clock) is not spoken back to the player. The player will notice the "again" line and the scars; they will not reliably notice why his shields are suddenly tougher. [30]

Every-run difference

Variation space. The identity draws are wide on paper: faction fallback, nemName (pre plus post, retried up to 12 times against admiral names), title, persona (8), trait shuffle (first two of 14), portrait (6 per faction), weakness shuffle (two of 7, with anchor removed for Voidsworn and Deathless), scars, epithet and beat. Faction alone changes the behaviour block, the fleet archetype, the clock multiplier and the strike. Persona changes AI weights (tw, range, focusWeak, focusFlag, flagFront) and the meet line.

Where it collapses. The clock rhythm is largely fixed: NEM_CLOCK=4, and nemClockAdd multiplies by beh.clock, so Deathless is always slow, Voidsworn always fast, everyone else always normal. The fight shape is faction-fixed: Corsair always swarms, Ithar always duels, Hegemony always heavy line. The "again" line is one line with one {beat} slot, so the second meeting sounds similar across runs even when the beat word changes. The adaptation pool is the same five counters plus one special per faction, and nemAdapt() picks the highest-scoring counter, so a player who uses the same tactics will see the same adaptation. Persona meet lines are four to five fixed lines per faction, not procedural. Consecutive runs will feel most different at the identity layer (name, portrait, faction, weakness pair) and least different at the memory layer (same adaptation logic, same beat line structure, same clock thresholds).

Judgement. The variation space is sufficient for faction and persona to change how a run feels, but not sufficient for the memory conversation to feel new on the third or fourth meeting. The weakest point is that the player's own tactics drive the same counters every time if the player has a preferred weapon mix.

Ranked fixes

1. Surface the memory before and after the fight. Add a pre-fight card line that states the relevant behaviour in plain words ("He raids your lanes. He will flee below 35% hull." / "He has fed on three of your losses.") and an adaptation line that says why he changed ("You leaned on torpedoes, so he bolted on point defense"). This is the single highest-value fix for readability and fairness. The pack does not establish that any of this is currently surfaced, so this is a design requirement, not a bug fix. UNSURE on current UI.

2. Make Chorus's fed visible. A fed counter on his card or a taunt line ("Your losses feed me") would turn an invisible hull multiplier into a memory the player can read. Right now the strongest feeding verb is the least visible.

3. Give Voidsworn a real challenge structure, not only a damage buff. The mutual +20% is symmetric but thin. A formal flagship challenge with a visible accept/decline or a duel condition would match the ruling's verb more fully and make the faction distinct in play rather than only in numbers.

4. Broaden the {beat} memory beyond one line. Add persona-specific "again" variants and a second memory line for scars or adaptations. One line with one slot is not enough to carry repeated meetings across a run.

5. Make the Corsair raid warning concrete. If the raid can take a ship, the card must state the threshold and the consequence before the strike resolves. The pack's comment says it is announced, but the pack does not establish the card's content. Treat this as a fairness requirement.

6. Vary the clock rhythm by more than a multiplier. Deathless at .5 and Voidsworn at 1.5 are the only rhythm changes. A faction-specific clock pattern (for example Corsair filling on greedy choices rather than wins, or Ithar filling only when you refuse a duel) would widen every-run difference without adding state.

UNSURE list

• How the Godot port surfaces any of this to the player. The pack describes data, campaign and battle logic but does not establish the UI card, the pre-fight telegraph, the adaptation line, the fed counter, the clock display or the scar overlay in the Godot build. This is the largest gap.

• Whether the Corsair raid card is actually shown before the strike resolves. The data comment says "always announced on his card first", but the pack does not show the card.

• Whether the Ithar duel strike has a distinct map action or is only the duel fleet build and the flee test. The data lists strike:'duel', but the pack does not describe a separate duel event.

• Whether the Hegemony reinforcement at round 3 is telegraphed before the fight. The pack says it is forced, but not how the player learns it.

• Whether the Voidsworn challenge is offered as a choice or only applied as a damage rule. The pack describes the mutual +20% but not a challenge prompt.

• Whether adaptations are ever explained to the player in words. NEM_ADAPT_FAC gives faction names, but the pack does not establish that a line says "he adapted because you used X".

• Whether the clock value is visible. NEM_CLOCK=4 and nemClockAdd are specified, but the pack does not describe a clock UI.

• Whether the {beat} line plays on every second meeting or only under specific conditions. The pack says "the 'again' line" but does not specify the trigger.

• How nemFeedLosses counts losses across battles and whether the player sees the count. The pack says it is called for every battle with player losses, but not how the count is surfaced.

One-sentence verdict

The six faction behaviours are mostly present in the data and the battle logic, but the implementation is strongest where the verb is a battle rule (Corsair flee, Ithar withdraw, Hegemony reinforce) and weakest where the verb depends on visible memory (Chorus feeding, Voidsworn challenge, Deathless revive). The memory system has one good visible hook (the {beat} line and the scar epithets) and several invisible state changes that the player cannot read. The every-run variation is wide at the identity layer and narrow at the memory layer. The ranked fixes above focus on making the existing state legible before adding new state.
