# Research batch 4: wings plus tactics UI for Voidsworn

Read-only synthesis. No posts, votes, messages, or repo writes. Sources are ranked by usefulness to Voidsworn, not by popularity. Sourced claims are tied to a listed source; anything else is labeled [Inference]. Summaries are in my own words; no code and no long passages are pasted. Note on scope: wing doctrines (Screen, Strike, Hunt, changeable per round, plus veterancy perks) are already ruled YES, so this report covers how to do them well, not whether to do them.

## Priority 1: Stance and doctrine systems

**1. Homeworld manual and Homeworld 2 guides (tactics: Aggressive, Defensive, Evasive, Neutral, plus Guard)**
https://www.scribd.com/doc/97870330/Homeworld-Manual-PC
https://www.gamespot.com/articles/homeworld-2-walkthrough/1100-6075729/
https://strategygamers.com/walkthrough/homeworld-cataclysm
Substance: Homeworld's tactics are per-unit stances with real trade-offs, not just aggression sliders. Aggressive strike craft shunt power from engines into weapons, so speed and agility drop while firepower rises; they will not dodge and will attack nearby enemies without orders. Evasive strike craft dodge, break formation, fire only when sure of a hit, and return to the nearest support ship for repair when badly damaged. Neutral is the default: attack only when attacked first. Guard is a separate order: stick to a named ship. Homeworld 2 pairs stance with formation shape: aggressive switches a strike group into claw formation, defensive into delta formation, so the stance is visible in how the group flies, not only in an icon.
Relevance: ADOPT the shape. One line why: Screen, Strike, and Hunt should each change wing behavior, positioning, and formation shape together, so the stance reads at a glance from the geometry of the wing itself.

**2. Battlefleet Gothic: Armada special orders (Lock On, Reload, Brace for Impact, shared cooldown)**
https://en.namu.wiki/w/Battlefleet%20Gothic:%20Armada
https://steamcommunity.com/app/573100/discussions/0/1796278072845347795/?l=hungarian
Substance: Every ship has three special orders sharing one cooldown (about 45 seconds duration, 120 seconds cooldown): Lock On raises accuracy and doubles crit chance, Reload cuts reload and aircraft cooldowns by about 20 percent, Brace for Impact raises armor by about 20 percent. Player discussion shows a switching cadence, not a single best stance: Lock On at long range where accuracy matters, then switch to Reload once everything is in range and accuracy stops being the problem. Brace for Impact is the instructive failure: players call it lackluster as a general turtle stance, and the better players use it narrowly, just before ramming or being rammed, where its real job is preventing mutiny from the collision.
Relevance: ADAPT the cadence and the warning. One line why: a stance that is only ever right in one narrow situation still earns its slot if that situation is legible (ramming, torpedo wave inbound), but a stance meant as a general defensive posture must actually feel protective or players will never touch it.

**3. Stellaris combat computers (behavior as preferred range)**
https://stellaris.fandom.com/wiki/Space_warfare
Substance: A ship's combat computer sets its behavior, which is mostly a preferred range plus a small bonus: Swarm charges to the shortest weapon range, Picket and Line hold the median weapon range, Artillery and Carrier hold the longest weapon range and back off if an enemy closes inside half that range. The behavior is chosen at ship design time, not switched in battle, and the ship then orbits its target at its preferred range. The lesson is architectural: a doctrine can be a positioning rule (where do I stand relative to my target) rather than a stat modifier, and positioning rules compose cleanly with any weapon loadout.
Relevance: ADAPT the positioning rule. One line why: Screen, Strike, and Hunt are most cleanly defined as positioning plus targeting rules (stay near the carrier and intercept, attack the assigned target, range ahead for crippled targets), not as damage percentages.

**4. BattleTech Vigilance and Guarded (per-turn defensive posture bought with a resource)**
https://battletech.fandom.com/wiki/Skills
Substance: Vigilance is a morale ability, usable as a free action alongside moving and firing, that grants the Guarded state (damage reduction), Entrenched, clears stability damage, and adds initiative next round. Guarded is a visible state on the unit, and the Bulwark skill deepens it. The cost is morale, a resource earned by killing and lost over time, so the defensive posture is a spend, not a toggle. Sensor Lock is the complementary spend: an action that reveals a target, strips two of its evasion charges, and lowers its accuracy for a round, but you cannot sensor lock and shoot in the same turn.
Relevance: ADAPT the spend model for stance switching costs. One line why: if per-round wing stance switching ever feels free and therefore fiddly, the BattleTech answer is to price the switch (a round of wing action, a carrier resource, or a one-round cooldown) rather than to remove the choice.

## Priority 2: Carrier and squadron management

**5. Starsector fighter mechanics (Engage/Regroup, replacement rate, roles, B-Deck)**
https://starsector.fandom.com/wiki/Fighter
Substance: Read in full. Fighters have two modes toggled with one key: Engage (attack, with behavior by role) and Regroup (stay near the carrier). Losses are replaced from a replacement rate that decays while wings sit at or below two-thirds complement, down to a 30 percent floor, and recovers when wings are back above that line; Regroup slows the decay and speeds recovery, and at zero combat readiness launches stop entirely. Roles are distinct: Fighters kite and shoot, Interceptors prioritize enemy fighters and missiles, Bombers ignore fighters, fly in, fire, and return to re-arm in seconds if they land (but count as dead for replacement rate if they spend their payload), and Support fighters cannot engage alone and must escort or stay home. Mixing roles beats stacking one role: a Broadsword wing's decoy flares distract point defense so a Piranha bomber wing's payload lands. Officer personalities tilt wings toward escort (timid, cautious) or attack (aggressive, reckless). The Drover's B-Deck hullmod is the one-time-save template: once per combat, when replacement rate hits 50 percent, it relaunches all wings to full strength and resets the rate to 100 percent.
Relevance: ADOPT the whole economy, ADAPT the numbers. One line why: Engage/Regroup is the proven two-mode version of Strike/Screen, the decaying replacement rate is the cost of losing wings, and B-Deck is exactly the shape of the ruled "one free re-launch" veterancy perk, except it should be earned by veterancy rather than built into a hull.

**6. Sins of a Solar Empire strike craft balance (hit and run, not slogging)**
https://forums.sinsofasolarempire.com/304193/page/2/
Substance: A player-run test series pits one carrier with a full fighter or bomber complement against 10 light or LRM frigates at near-equal cost. The carrier loses every straight fight, with 4 to 7 frigates surviving, and the thread's conclusion is that strike craft are for hit and run, not slogging it out, inside a rock-paper-scissors system: fighters kill siege craft and LRMs, bombers kill slow ships that cannot shoot back, flak kills fighters, and bombers keep flying for a hit or two even after their carrier dies. A carrier fleet held in reserve while a gun fleet fights head to head is called out as not a fair fight at all, since it is really two fleets for the price of one force.
Relevance: ADAPT the role discipline. One line why: wings must have a job they are good at and a counter that kills them (point defense and interceptors), or they collapse into either fire-and-forget damage or dead weight, and Hunt in particular must be a hit-and-run posture with real exposure, not a free damage aura.

**7. Carrier air defense doctrine, 1942 (three interlocking spheres)**
https://dougcflattop.substack.com/p/carrier-air-defense-1942
Substance: US carrier defense in mid-1942 worked in three spheres: carrier fighters intercepted incoming bombers as far from the carrier as possible under radar fighter direction, long-range heavy anti-aircraft fire engaged what got through, and medium and light automatic weapons were the last layer. The first sphere's whole point was distance: the intercept happened far out, so even a partial success bought the inner layers time and space.
Relevance: ADAPT as the Screen doctrine statement. One line why: Screen should be defined by an intercept band at range from the defended ship, with wings meeting craft and torpedoes out there, not by hovering on top of the carrier waiting to be hit.

## Priority 3: Wing veterancy and progression

**8. Zero-K developer case against veterancy bonuses (readability and slippery slopes)**
https://steamcommunity.com/app/334920/discussions/0/1696045708661224875/?l=dutch
Substance: A Zero-K developer gives two reasons the game has no veterancy bonuses. First, keeping units alive is already very beneficial, so further rewarding it creates slippery slopes: the player who is already winning gets stronger units for winning. Second, veterancy makes units unreadable: you cannot tell how powerful an enemy unit is at a glance, and small stat changes can flip a matchup breakpoint (a unit going from two-shot to three-shot) without anything visible changing.
Relevance: ADOPT as the constraint on all wing veterancy design. One line why: every wing perk must be either visible on the wing (a marker, a changed formation, a named trait shown on hover) or a new behavior rather than a hidden stat bump, and the total power gain must be capped so a veteran wing never becomes an auto-win.

**9. NoobsInCombat veterancy (flat, capped, kill-counted)**
https://noobsincombat.fandom.com/wiki/Features
Substance: Units gain a veterancy level per kill (infantry after one kill, vehicles after two), each level adds 10 percent damage reduction and a 1.1x damage multiplier, and veterancy stacks at most 3 times. Buildings cannot gain veterancy. The model is deliberately simple: one counter, one flat bonus per level, a hard cap.
Relevance: ADAPT only as the ceiling, not the template. One line why: a flat capped bonus is the simplest safe shape, but for wings it should be the weakest option, since behavior perks (free re-launch, kamikaze on death, extra strike damage on one target type) are both more readable and more characterful than a third stack of plus damage.

**10. XCOM 2: War of the Chosen bonds and fatigue (veterancy with a cost)**
https://cdn.2kgames.com/manuals/xcom2/wotc/na/2KGMKT_XCOM2_WOTC_MANUAL_SHEET_US.pdf
https://www.rockpapershotgun.com/xcom-2-war-of-the-chosen-preview
Substance: Soldiers who fight together form bonds with tactical benefits: at bond level 3, Advanced Teamwork grants a bondmate an extra action point (two charges per mission, shared), and Dual Strike is a combined shot that is a free action for the bondmate. The counterweight is Will and fatigue: soldiers who deploy repeatedly while tired can develop negative traits (an obsessive soldier sometimes spends an action reloading a non-empty weapon), and tired soldiers need rest before returning to combat. The system therefore rewards keeping a roster, not riding one elite squad forever.
Relevance: ADAPT the fatigue counterweight. One line why: if veteran wings snowball, the XCOM answer is not to weaken the perks but to price overuse (a wing that fights every battle without rest loses readiness, or replacement wings arrive green), which keeps veterancy as a story about a specific wing rather than a permanent buff.

**11. BattleTech pilot skills (forced specialization, behavior perks, lingering costs)**
https://battletech.fandom.com/wiki/Skills
Substance: Read in full. Pilots gain small stat growth per level but, more importantly, are forced to specialize: only two primary abilities (level 5) and one master ability (level 8). The abilities are behaviors, not just numbers: Bulwark deepens Cover and Guarded damage reduction, Sensor Lock strips evasion and reveals, Ace Pilot lets a unit move after shooting, and Coolant Vent removes 50 heat now but adds 8 heat per round for the next three rounds on a 4-round cooldown. The best perks have a shape: a new option, a lingering cost, or a cooldown that forces a decision about when to spend them.
Relevance: ADOPT the perk shape for wing veterancy. One line why: a wing veterancy tree should offer a small menu of behavior perks with costs or cooldowns (free re-launch once per battle, kamikaze on death for Chorus wings, extra strike damage against crippled targets for Hunt wings), picked from a forced choice, not a ladder of flat damage bonuses.

## Priority 4: Tactics readability in complex battles

**12. Into the Breach (hide nothing: telegraphs, previews, attack order)**
https://www.pcgamesn.com/slay-the-spire/slay-the-spire-vs-into-the-breach
https://www.noobfeed.com/reviews/into-the-breach-pc-review
Substance: Into the Breach's core design commitment is transparency: every enemy's next attack is telegraphed during the player's turn (who attacks what, how much damage, in what order), hovering an enemy highlights its target and damage, a key shows the full attack order, and before confirming any move the player sees a preview of exactly what will happen. The argument, made explicitly in the PCGamesN piece, is that this transparency is what makes the difficulty fair: the challenge is solving the board, not guessing hidden information. One reviewer caveat carries over: with many enemies on screen, the UI itself can get busy and block the view even with highlights available.
Relevance: ADOPT as the readability test for the whole battle UI. One line why: before a player commits a wing order, the game should answer what will happen (which wing goes where, what it intercepts or hits, what it risks) in the same way Into the Breach answers it, and the busy-board caveat is the reason wing orders need a declutter mode, not more overlays.

**13. Fire Emblem danger zone (enemy reach overlay, mark by type, pre-combat preview)**
https://www.resetera.com/threads/exemplary-ui-design-in-games-warning-gifs.4080/
https://gamefaqs.gamespot.com/boards/643003-fire-emblem-awakening/66875829
Substance: Fire Emblem's strategy overview offers a toggleable overlay showing everywhere enemies can reach, plus the ability to mark specific enemies (or enemy types, for example all archers) with a different color overlay, so a player can see at a glance which areas are unsafe for which of their units. Selecting a unit highlights its movement and attack ranges, hovering a tile shows ground effects, and choosing a target pops a compact overlay comparing stats, weapon advantage, and equipment options. The forum debate is instructive: some players say the overlay "breaks the game" by making it easier, others answer that it stops players losing units to silly errors like missing one enemy off screen, which is frustration, not difficulty.
Relevance: ADAPT the overlay pattern, with a Voidsworn color constraint. One line why: wings need the same three overlays (wing intercept band for Screen, torpedo and craft threat arcs, and a per-wing-type danger marking), drawn in non-cyan, non-gold colors per the standing colour law, toggled rather than always on so the battle stays visible.

## Priority 5: Anti-patterns and warnings

**14. World of Warships carriers (practically infinite planes)**
https://steamcommunity.com/app/552990/discussions/0/3082124889517666593/
Substance: The long-running carrier complaint has a precise shape: planes are effectively infinite, so by the end of a match every other ship has lost its anti-aircraft mounts while the carrier still flies full squadrons; the fighter consumable meant to counter them is called a joke because the fighters spin in circles instead of engaging; and carriers survive far too long at the end of a match relative to their vulnerability. The failure is not that carriers are strong, it is that their resource never depletes while everyone else's does.
Relevance: ADOPT as the hard rule for wing replacement. One line why: wing replacement must deplete something real across a battle (the Starsector replacement rate, a carrier readiness meter, or a per-battle launch budget), or wings become the one infinite resource on a board where everything else runs down.

**15. Homeworld: Cataclysm multiplayer guide (tactics AI fighting the player's intent)**
https://gamefaqs.gamespot.com/pc/303756-homeworld-cataclysm/faqs/8861
Substance: The guide warns that under the AI-driven tactics settings, units develop "a mind of their own," and that is a bad thing when the player wants total control: aggressive tactics will engage nearby enemies at exactly the moment the player is trying to retreat, and evasive tactics will send a ship off to dock when the shortest path to safety does not involve docking at all. The recommendation is blunt: keep ships on neutral unless the player lacks attention to spare for that unit, because a stance that overrides an explicit order (retreat, hold, move) breaks trust in the whole system.
Relevance: ADOPT as the trust rule for wing AI. One line why: a wing stance must never override an explicit player order, and Hunt in particular must not auto-chase a crippled target into a trap after the player ordered a retreat, or players will stop using stances entirely and just babysit every wing.

Cross-cutting takeaway [Inference, built on sources 1-15]: the three stances are cleanest as a small decision the player makes once per round per carrier, with Strike as the default so a player who never touches the system still plays a complete game. Screen is an intercept band plus a targeting priority (craft and torpedoes first, nearest to the defended ship), shown as a band overlay and a tightened formation. Strike is current behavior plus a target priority. Hunt is a forward wedge with a crippled-target priority and an exposure cost (out of support range, or a return leg that leaves the wing vulnerable). Veterancy should be three behavior perks at most per wing, chosen from a forced menu, each visible on the wing, with replacement cost (rate decay or readiness) doing the balancing work that flat stat caps cannot. Readability should be layered: stance shown by formation shape, threat shown by toggleable overlays, outcomes shown by pre-commit previews, and detail available on hover rather than on screen all at once.

## Flagged for live-browser read (top 8, in priority order)

1. https://starsector.fandom.com/wiki/Fighter - Replacement-rate math, Engage/Regroup, role combinations; the carrier economy template.
2. https://battletech.fandom.com/wiki/Skills - Forced specialization plus Coolant Vent's lingering-cost perk shape; the veterancy template.
3. https://www.pcgamesn.com/slay-the-spire/slay-the-spire-vs-into-the-breach - The "hide nothing" transparency argument; the readability test.
4. https://www.resetera.com/threads/exemplary-ui-design-in-games-warning-gifs.4080/ - Fire Emblem danger overlay plus mark-by-type; the overlay pattern.
5. https://steamcommunity.com/app/573100/discussions/0/1796278072845347795/?l=hungarian - BFG stance cadence (Lock On at range, Reload up close, Brace for ramming); the switching lesson.
6. https://forums.sinsofasolarempire.com/304193/page/2/ - Strike craft as hit and run, not slogging, with costed test fights; the role discipline.
7. https://steamcommunity.com/app/334920/discussions/0/1696045708661224875/?l=dutch - The Zero-K anti-veterancy case (readability plus slippery slopes); the constraint.
8. https://gamefaqs.gamespot.com/pc/303756-homeworld-cataclysm/faqs/8861 - Tactics AI fighting player intent; the trust rule.

## What could NOT be verified or accessed

- No Reddit thread was read in full. Direct text fetch of reddit.com is blocked from this side, and this round's searches surfaced wikis, articles, and forums rather than specific reddit.com threads with verifiable URLs, so no Reddit thread is cited above and none is in the live-read list. A follow-up live-browser search of r/gamedesign and r/TacticalRPG for stance and squadron discussion is still worthwhile, but its URLs are not verified here.
- No dedicated source was found for wing or squadron veterancy as a named system in space games; the veterancy material comes from ground tactics games (BattleTech, XCOM, NoobsInCombat, Zero-K) and must be translated to wings, which is inference, not sourcing.
- No source was found for per-round stance switching in a turn-based space game specifically. Homeworld and Battlefleet Gothic are real-time, Stellaris behaviors are loadout choices, and BattleTech postures are per-unit actions, so the per-round cadence for Voidsworn is synthesized from those patterns, not quoted from any one of them.
- The Homeworld manual is cited via a Scribd copy, not an official source, and the Battlefleet Gothic numbers come from a secondary wiki plus player discussion, not the game files.
- The Starsector wiki is a fan wiki; the replacement-rate numbers above match the page as read, but version drift is possible.
- The Sins of a Solar Empire test fights are from 2008 (the original game), not current Sins II balance, and are player-run tests, not developer data.
- XCOM bond details come from the official War of the Chosen manual; fatigue and negative-trait specifics are corroborated by previews and forum summaries, not re-verified against game files.
- The carrier air defense piece is historical doctrine, not game design, and is used here as a framing source for Screen, not as evidence about any game's mechanics.
