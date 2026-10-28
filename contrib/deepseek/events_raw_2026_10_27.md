BLIND AUDIT REPORT: EVENTS AND BEVENTS
Commit 68b42ce406286eb95ea7df6aaf3f683c1231b51d

Scope reading: I read r.ambush as a fight-start flag per the prompt. I read need.flag as a presence check on RUN.flags, per the data comment that every choice writes RUN.flags[event id] = the option's key. I did not use lore_bible_r8.md because the pack states it has no event section.

FINDINGS, WORST FIRST

1. BLOCKER. OBSERVED: the seer event excludes ithar with not:['ithar'], but its blue option requires ithar with need:{fac:'ithar'}. INFERRED: no run can satisfy both conditions. The option song, text Answer her tone in glass, is unreachable in every game state. This also means the known count of 12 faction-gated events includes a dead gate.

2. BLOCKER. OBSERVED: the Chorus-gated spawn option feed has need:{fac:'chorus'},r:{healAll:.3} and text Every ship regrows 30% of its hull. OBSERVED: FAC_VERBS chorus gorge says every ship regrows 20% of its hull and uses the fed flag from spawn. INFERRED: both are Chorus repair effects and directly contradict the October 2026 ruling that Chorus gets no repair.

3. FIX. OBSERVED: the data comment says every choice writes RUN.flags[event id] = the option's key. OBSERVED: FAC_VERBS free conditions are free:'shrine', free:'defector', free:'lament', free:'tombhome', with text free after an offering at a wall of names, free once a defector has briefed you, free once you have answered the tone, free once a dormant yard has woken a hull for you. OBSERVED: saboteur face uses need:{flag:'defector'} and text The defector you questioned named him. INFERRED: if flag checks are presence checks, any resolution of those events unlocks the later free option, and saboteur face is available after a defector outcome that did not involve questioning him.

4. FIX. OBSERVED: beacon Seize the cargo gives +100 credits with r:{cred:100,ambush:true} but its text only says Their escort might remember your colours. OBSERVED: bait loud explicitly says your next fight starts as an ambush before the choice. INFERRED: beacon hides the ambush consequence and also hides the nemClock increase attached to the same option. A player cannot price the risk from the event text as written.

5. FIX. OBSERVED: many qualifying blue options strictly dominate a sibling option for the fleet that can see them: merc oath gives the same ship and veteran captain as the 80-credit hire for free; veterans oath gives the same 25 experience as the 50-credit payment for free; broker debt gives the same Nemesis intel as the 60-credit purchase for free; reactor metal gives no damage at no cost against a 45-credit repair; well sails gives the same +35 credits as the sling with no hull damage; defector enlist adds 50 experience to the same Nemesis intel as question; cache both gives a refit and 45 credits against either one alone; tithe lance gives the same +70 credits without the Nemesis clock; bait sweep gives the same +80 credits without the ambush; scout torp gives the same clock reduction and intel without the 5% fleet damage; moon flak gives +60 credits and +15 experience without the elite fight, while Bombard gives only +20 experience; squall shield and storm shields give no damage plus experience against damage or fuel cost; astropath shield gives the relic without the 30% hull damage; battlefield wings gives the refit without the 12% hull damage; mutiny talk is free and gives 15 experience while the other options cost credits or captain experience; lament join gives a relic and moves the Nemesis clock back at no cost. INFERRED: for the qualifying fleet these are solved choices, and several make a sibling option pointless.

6. NOTE. OBSERVED: auction swap requires a relic, pays one relic, then gives a relic and 40 credits, while bid costs 120 credits for a relic. INFERRED: for a fleet holding a relic, swap is close to strictly better than bid unless the specific relic identity matters. The pack does not define relic identity or value.

7. NOTE. OBSERVED: tombhome has not:['hegemony','voidsworn','corsair','chorus','ithar'], so only Deathless can see it. OBSERVED: its wake option requires fac:'deathless' and gives shipRaw:'d_scythe'; the alternative gives 60 credits. INFERRED: a free full-hull ship is likely far better than 60 credits, so the only faction that sees the event has a likely solved choice. The pack does not include HULLS, so the ship value cannot be checked.

8. NOTE. OBSERVED: BEVENTS are announced with warnR:2,r:ri(3,4) and text such as enemy reinforcements will jump in at the start of round {r}. INFERRED: the visible warning design is fair and readable. No BEVENTS finding rises above NOTE.

GATED EVENT REVIEW

merc: OBSERVED oath requires voidsworn and gives ship:'harrow',vet:1 for free. It expresses Voidsworn oath-taking. It is still a solved free version of the paid hire for Voidsworn. Finding 5.

seer: OBSERVED song requires ithar inside an event with not:['ithar']. It expresses ithar glass tone thematically but is unreachable. Finding 1.

reactor: OBSERVED metal requires deathless and has r:{} with text No cost. It expresses Deathless repair drones. It is a free no-damage option against a 45-credit repair. Finding 5.

broker: OBSERVED debt requires corsair and gives nemIntel:1 free. It expresses corsair old-debt leverage. It is a free version of the 60-credit buy. Finding 5.

spawn: OBSERVED feed requires chorus and gives healAll:.3. It expresses Chorus feeding, but it violates the Chorus no-repair ruling. Finding 2.

lament: OBSERVED join requires ithar and gives relic:1,nemClock:-1. It expresses answering a Glasswright tone. It is a free relic and clock reduction. Finding 5.

tombhome: OBSERVED wake requires deathless and gives shipRaw:'d_scythe'. It expresses Deathless waking an Eclipse hull. The event is Deathless-only, and the free ship likely dominates the 60-credit strip. Finding 7.

convoy: OBSERVED shake requires corsair, gives 100 credits, and moves the Nemesis clock on. It expresses corsair shakedown behaviour and carries a visible clock cost in text. No blocker observed.

defector: OBSERVED enlist requires hegemony and gives xpLow:50,nemIntel:1. It expresses a Hegemony commission. It strictly improves on question for Hegemony because it adds experience to the same intel. Finding 5.

well: OBSERVED sails requires ithar and gives +35 credits with no damage, while sling gives +35 credits with 5% fleet damage. It reads as ithar solar-wind flavour. It is a solved no-damage version for ithar. Finding 5.

veterans: OBSERVED oath requires voidsworn and gives 25 experience for free, while pay gives the same for 50 credits. It expresses a Voidsworn old oath. Finding 5.

haven: OBSERVED recruit requires corsair and gives shipRaw:'c_raider',vet:1. It expresses corsair recruiting from a raider den. The fight option is declared as Fight an elite Hullbreaker battle. No blocker observed.

FIGHT-START FAIRNESS

OBSERVED: moon, tomb, and haven use r.fight and state the fight in the option text: Fight an elite Chorus battle, Fight an elite Eclipse battle, Fight an elite Hullbreaker battle. INFERRED: these are declared fights and can be priced as risky choices.

OBSERVED: bait loud states your next fight starts as an ambush and has ambush:true. INFERRED: this is fair.

OBSERVED: beacon Seize the cargo has ambush:true and nemClock:1 but only says Their escort might remember your colours. INFERRED: this is not enough warning for an ambush and a Nemesis clock move. Finding 4.

BEVENTS

OBSERVED: BEVENTS are reinf_enemy, reinf_ally, and flare. Their warnings name the round and side or the shield effect. OBSERVED: rollBattleEvent skips boss fights and schedules at most one event. INFERRED: they read clearly mid-battle and do not ambush the player.

OBSERVED: no BEVENTS text contradicts the October rulings. Eclipse no-shields only means flare may do nothing to Eclipse ships, not that the text is wrong. Chorus no-repair, Glasswright no-Brace, Hegemony sync-fire, and captured-ship handling are not touched by these BEVENTS.

NOTE: the actual shield removal for flare, the removal of allied reinforcements after battle, and the effect handler for reinforcement units are not in the pack slice. I cannot verify those implementations.

TEXT QUALITY NOTES

OBSERVED: spawn feed uses repair language, Every ship regrows 30% of its hull, which conflicts with the Chorus ruling. Finding 2.

OBSERVED: beacon hides both ambush and Nemesis clock. Finding 4.

OBSERVED: saboteur face says The defector you questioned named him, but the flag can be set by any defector resolution. Finding 3.

OBSERVED: FAC_VERBS free text promises specific fictional acts, but the flag data only records event ids. Finding 3.

OBSERVED: naming in the events uses setting names such as Glasswright, Eclipse, Hullbreaker, and Hegemony consistently with the faction tables in the pack. No naming break was found in the included text.

NOT CHECKED

The lore bible has no event section, so no bible text was checked.

HULLS and ship values were not in the pack, so tombhome ship value and other ship rewards could not be priced.

Result handlers such as derelictBoard, modId:'damcon', wingPerk, and shipRaw values were not defined in the pack, so their correctness could not be verified.

The actual flag evaluation code was not in the pack. I checked flag findings against the data comment only.

The exact timing of r.ambush, whether it starts an immediate fight or marks the next fight, is not defined in the pack. I followed the prompt reading.

The BEVENTS effect code for flare shield removal and ally removal after battle is outside the slice.

Whether the blue-option dominance is intentional design or an audit defect is not stated in the pack. I treated strict dominance with no trade-off as a FIX.

VERDICTS

EVENTS: FAIL. There are two blockers: seer has an unreachable faction gate, and Chorus repair appears in spawn and FAC_VERBS chorus gorge against an explicit ruling. There are also several FIX-level solved blue options and flag-text mismatches.

BEVENTS: PASS WITH CAVEATS. The visible warning design is clear and fair, and no ruling contradiction is visible in the slice. Effect implementation remains unchecked.

OVERALL: EVENTS are not shippable as audited. BEVENTS are acceptable on the visible evidence, with implementation checks still outstanding.
