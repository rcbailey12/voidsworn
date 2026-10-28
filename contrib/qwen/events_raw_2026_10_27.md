BLIND AUDIT REPORT: EVENTS AND BEVENTS
Leg: Voidsworn / Embers of the Hollow Sun
Pack pinned to commit 68b42ce406286eb95ea7df6aaf3f683c1231b51d

FINDINGS, WORST FIRST

1. BLOCKER - Seer event: ithar-gated option is unreachable

OBSERVED. The seer event carries not:['ithar'] in its header, excluding the ithar faction from ever seeing the event. The same event then carries a blue option with need:{fac:'ithar'}: "Answer her tone in glass." Because the event is hidden from ithar players by the not-array, no ithar player can ever be presented with this option. The gate is dead code. OBSERVED, event id 'seer', header and option k:'song'.

INFERRED. This appears to be a design collision: the event is framed as meeting an external Glasswright ("A lone Glasswright vessel matches your course"), so excluding ithar from the encounter makes narrative sense. But the blue option was then added for ithar without removing the not-array, or the not-array was added after the blue option without updating the option. Either way, the option cannot fire in any game state.

Additionally, the option's reward (free salvage, no module lost) is the faction's payoff for the encounter, so ithar players lose both the option and the intended faction interaction.

2. FIX - Chorus spawn option conflicts with the "Chorus gets no repair" asymmetry ruling

OBSERVED. The spawn event's chorus-gated option (k:'feed', need:{fac:'chorus'}) returns r:{healAll:.3}, described as "Every ship regrows 30% of its hull." The October 2026 ruling states "Chorus gets no repair." OBSERVED, event id 'spawn', option k:'feed'.

OBSERVED. The same healAll key is used by the shrine event (healAll:.3 and healAll:1) from which Chorus is correctly excluded via not:['chorus','deathless']. OBSERVED, event id 'shrine', header.

INFERRED. The ruling and the data are in tension. The Chorus faction identity is built on biological regrowth: the FAC_VERB 'gorge' restores hull, the Nemesis trait pool includes 'regrowth', and the Nemesis adaptation special is 'hunger' (extra hull regrowth). If "no repair" is read as "no hull restoration of any kind," then spawn, gorge, and multiple Nemesis traits all violate it. If "no repair" means "no mechanical or external repair" (distinguished from biological feeding), then the implementation should use a distinct key or flag so the ruling is enforceable in code. As written, the same healAll key that the shrine uses for generic repair is what spawn hands to Chorus, making the ruling unenforceable without further code context.

I read the ruling as intending the second meaning (no mechanical repair; regrowth is the Chorus-specific alternative), but flag the implementation because the data does not distinguish.

3. FIX - Beacon ambush is undertelegraphed

OBSERVED. The beacon event's "Seize the cargo" option reads: "+100 credits. Their escort might remember your colours." The result is r:{cred:100,ambush:true}. OBSERVED, event id 'beacon', option l:'Seize the cargo'.

OBSERVED. By contrast, the bait event's equivalent option reads: "+80 credits, but your next fight starts as an ambush." The word "ambush" appears in the player-facing text. OBSERVED, event id 'bait', option k:'loud'.

INFERRED. "Their escort might remember your colours" reads as a reputation consequence or a vague future threat. It does not tell the player that the next encounter will mechanically begin as an ambush (enemies on both sides, surprise positioning). A player choosing this option cannot price the risk from the text the data provides. The bait event demonstrates the pack's own standard for ambush telegraphing; beacon falls below it.

4. FIX - Four faction-gated options create solved choices (strictly dominant option)

OBSERVED. In each of the following, the faction-gated option delivers the same or better reward as a neighbouring option at zero cost, making the neighbouring option dead for that faction:

(a) merc, voidsworn. k:'oath' returns r:{ship:'harrow',vet:1}. The paid option returns r:{cost:80,ship:'harrow',vet:1}. Identical reward, 80 credits cheaper. A voidsworn player would never select the paid option. OBSERVED, event id 'merc'.

(b) veterans, voidsworn. k:'oath' returns r:{xp:25}. The paid option returns r:{cost:50,xp:25}. Same experience, no cost. OBSERVED, event id 'veterans'.

(c) well, ithar. k:'sails' returns r:{cred:35}. The sling option returns r:{dmgAll:.05,cred:35}. Same credits, no hull damage. OBSERVED, event id 'well'.

(d) reactor, deathless. k:'metal' returns r:{}. The other three options each impose a cost (20% hull damage, a refit, or 45 credits) to resolve the same problem. The deathless option resolves it free with no downside. OBSERVED, event id 'reactor'.

INFERRED. Each event still presents a choice between "take the free faction perk" and "decline," so the event is not fully solved (the player can always walk away). But within the "engage" branch, the faction option is strictly dominant and the alternative is a dead button. This reduces the event to a single meaningful click for that faction. If the intent is a faction perk, the alternative option should either be removed or given a distinct reward that competes.

5. FIX - tombhome double-gates deathless redundantly

OBSERVED. The tombhome event carries not:['hegemony','voidsworn','corsair','chorus','ithar'], which excludes every faction except deathless. The event's k:'wake' option then adds need:{fac:'deathless'}. OBSERVED, event id 'tombhome', header and option k:'wake'.

INFERRED. Because the event is already deathless-only, the faction gate on the option can never filter anyone out. It is redundant. It does not break anything, but it signals a possible copy-paste error (perhaps the not-array was meant to be shorter, or the option gate was added before the not-array). If the not-array is ever loosened in a future edit, the option gate would silently become the only filter, which might not be intended.

6. NOTE - spawn option fl:{fed:1} flag has no visible consumer in the pack

OBSERVED. The spawn chorus option writes fl:{fed:1}. The FAC_VERB gorge description references feeding: "30% if the fleet has fed at a spawning field." OBSERVED, event id 'spawn', option k:'feed'; FAC_VERBS, chorus entry.

INFERRED. The flag is presumably consumed by the gorge verb's logic (in code not in this pack) to upgrade the heal from 20% to 30%. This is consistent. However, the flag name in the option is 'fed' while the verb's description says "has fed." If the code checks for a flag named 'fed' this works; if it checks 'feed' or 'gorge_fed' it would not. Cannot verify without the verb-resolution code. Noting for completeness.

7. NOTE - BEVENTS flare text and the Eclipse no-shields ruling

OBSERVED. The flare BEVENT warns: "every ship on both sides loses its shields for that round" and fires: "Solar flare! Every shield on the field is down this round." The October 2026 ruling states "Eclipse fields no shields." OBSERVED, battle.js, BEVENTS.flare.

INFERRED. If a deathless (Eclipse) fleet is present, the flare has no mechanical effect on their ships. The text's universal phrasing ("every ship," "every shield") is misleading in that context. This is cosmetic, not mechanical, but it could confuse a deathless player who sees the warning and expects something to happen. A NOTE, not a FIX, because the effect is simply a no-op on shieldless ships rather than an incorrect application.

8. NOTE - Beacon ambush also writes nemClock:1 on the "Seize the cargo" option

OBSERVED. The pack's B4 splice adds fl:{greed:1} and r.nemClock=1 to the beacon's "Seize the cargo" option. The base option already carries r:{cred:100,ambush:true}. OBSERVED, data.js splice for beacon.

INFERRED. The option now carries both an ambush and a Nemesis clock advance. Combined with the vague telegraph (finding 3), a player who picks this option is signing up for an ambush and accelerating the Nemesis timer without clear warning of either. The clock advance is not mentioned in the option text ("Their escort might remember your colours" does not communicate a Nemesis clock tick). This compounds finding 3.

9. NOTE - astropath variant text for deathless references "Ardent" without context in the pack

OBSERVED. The astropath deathless variant reads: "Something of Ardent is still out there." OBSERVED, event id 'astropath', v.deathless.b.

INFERRED. "Ardent" appears to be a proper noun from the lore (likely a person, place, or ship). The lore bible has no event section, so this name cannot be verified against canon. Noting only because the pack cannot confirm it matches an established name.

10. NOTE - derelict event text references "Starwright script" and "founders' tech"

OBSERVED. The derelict event body reads: "its hull etched with Starwright script no one has read in a thousand years." The astropath event references "old founders' beacon" and "old salvage." The ithar variant of astropath references "old Starwright glass." OBSERVED, event ids 'derelict' and 'astropath'.

INFERRED. "Starwright" and "founders" appear to be the same or related in-universe concepts. The derelict uses "Starwright script" and "founders' tech" interchangeably within one sentence. Consistent within the pack. No issue found; noting for completeness.

11. NOTE - Convoy corsair option and the "captured ships" ruling

OBSERVED. The convoy corsair option (k:'shake') reads "Shake them down" and returns r:{cred:100,nemClock:1}. The ruling states "captured ships are stripped and ransomed, never scuttled or left derelict." OBSERVED, event id 'convoy', option k:'shake'.

INFERRED. Shaking down a merchant convoy for credits is extortion, not ship capture. No ships are seized, scuttled, or left derelict. The ruling does not apply. No conflict. Noting to confirm the check was performed.

12. NOTE - BEVENTS reinforcement uses cheapHull for the ally ship

OBSERVED. The reinf_ally handler calls cheapHull(fac), which selects the cheapest non-boss, non-launch hull in the faction roster by cost then hull points. The spawned unit is described as "Garrison [name]." OBSERVED, battle.js, eventTick function and cheapHull function.

INFERRED. The ally reinforcement is always the weakest available ship. This is fair (it is a free bonus, not a player choice) and the text sets expectations ("a friendly ship"). No issue. Noting the design intent is clear.

REWARD AND PENALTY SANITY ACROSS ALL 33 EVENTS (SUMMARY)

OBSERVED. No event outside the four listed in finding 4 presents a strictly dominant option that makes its alternatives dead. Most events offer a genuine trade: credits vs. risk, time vs. hull, a module vs. a relic, experience vs. a Nemesis clock tick.

OBSERVED. The tithe event differentiates its three options cleanly: loud crack (credits + clock + greed + loud), quiet lance cut (credits + greed, needs lance), or leave (nothing). The lance option is better than crack only if you have a lance and want to avoid the clock, which is a real trade.

OBSERVED. The scout event's three options trade hull damage (hunt), weapon requirement (torp), or a free clock advance for the Nemesis (ignore). Each has a distinct cost shape. No solved choice.

OBSERVED. The quiet event (fallback) offers rest (10% healAll) vs. drill (10 xp). These are different currencies and neither dominates. Clean.

INFERRED. No option in the 33-event table delivers a reward wildly out of scale with its neighbours. The largest single rewards are the tombhome wake (a free ship) and the haven recruit (a free ship with veteran captain), both faction-gated and both in events with meaningful alternatives. The 120-credit auction bid for a relic is in line with the tithe vault's 70 credits and the broker's 60-credit intel. No outliers flagged beyond finding 4.

FIGHT-START FAIRNESS (5 EVENTS, SUMMARY)

OBSERVED. moon (r.fight:'chorus'): option text reads "Fight an elite Chorus battle. Win salvage." The word "Fight" is present. Telegraphed.

OBSERVED. tomb (r.fight:'deathless'): option text reads "Fight an elite Eclipse battle. Win salvage." Telegraphed.

OBSERVED. haven (r.fight:'corsair'): option text reads "Fight an elite Hullbreaker battle. Win salvage." Telegraphed.

OBSERVED. bait (r.ambush:true): option text reads "your next fight starts as an ambush." Explicit. Telegraphed.

OBSERVED. beacon (r.ambush:true): option text reads "Their escort might remember your colours." No mention of ambush, fight, or combat. Undertelegraphed. See finding 3.

INFERRED. Four of five fight-starts are clearly telegraphed. Beacon is the exception. A player who reads "might remember your colours" as a flavour line about future reputation rather than an immediate mechanical ambush cannot price the risk from the data provided.

DEAD OR UNREACHABLE OPTIONS (SUMMARY)

OBSERVED. The seer/ithar collision (finding 1) is the only unreachable option in the pack. All other need-conditions reference requirements that a valid fleet state can satisfy: weapon kinds (lance, torp, flak), shields, carrier, a module in the hold, credits, a veteran captain, a faction identity, a prior event flag, or a relic.

OBSERVED. The saboteur k:'face' option requires need:{flag:'defector'}. The pack header confirms that every event choice writes RUN.flags[event id], so encountering the defector event and choosing any option sets this flag. Reachable.

INFERRED. shipRaw:'d_scythe' (tombhome) and shipRaw:'c_raider' (haven) reference hull ids that are not defined in this pack. If those ids are missing from the HULLS table in the full codebase, the options would error at runtime. Cannot verify from the pack. Listed under Not checked.

INFERRED. modId:'damcon' (spawn, harvest option) references a specific module. Not defined in this pack. Cannot verify. Listed under Not checked.

BEVENTS VERDICT

OBSERVED. Three battle events: reinf_enemy, reinf_ally, flare. All are announced one round before they fire (warnR:2, fire round 3 or 4). All have clear warn and go text strings. None trigger during boss fights (rollBattleEvent returns null for kind==='boss'). Maximum one per battle (45% chance of none).

INFERRED. The warning system is fair. A player sees the warning in round 2 and can adjust before the event fires in round 3 or 4. No ambush-by-event.

The only ruling-adjacent issue is the flare text's universal phrasing when Eclipse (shieldless) ships are present (finding 7). This is cosmetic.

BEVENTS verdict: PASS. No blockers, no fixes required. One cosmetic note.

EVENTS VERDICT

One BLOCKER (unreachable option), four FIXes (ruling tension, undertelegraphed ambush, solved choices, redundant gate), and several NOTEs. The event table is broadly well-constructed: faction voices are distinct, rewards are proportionate, fights are telegraphed in four of five cases, and the flag system supports cross-event continuity (saboteur/defector). The BLOCKER is a single-event data collision that is straightforward to fix (remove the not-array entry or remove the gated option). The FIXes are balance and clarity issues, not structural breaks.

EVENTS verdict: CONDITIONAL PASS. One blocker must be resolved before the pack is clean. The four FIX items should be addressed but do not individually break a run.

OVERALL VERDICT

CONDITIONAL PASS. The event and battle-event systems are functional, internally consistent in voice, and largely fair. One unreachable option (seer/ithar) is a hard blocker. The Chorus repair ruling needs either a code-level distinction or a data change to resolve. The beacon ambush telegraph needs a text edit. The four solved faction choices are design-intent questions (perk vs. choice) that should be consciously resolved. BEVENTS pass cleanly.

NOT CHECKED

- The HULLS table is not in the pack. Cannot verify that shipRaw:'d_scythe', shipRaw:'c_raider', and ship:'harrow' resolve to defined hulls. Cannot verify that the 'harrow' hull is appropriate for both the voidsworn merc event and the generic merc hire.
- The module table is not in the pack. Cannot verify that modId:'damcon' is a defined refit or that r:{mod:1} results draw from a valid pool.
- The wingPerk:1 result (pilot event, k:'wing') references a carrier wing upgrade system. The pack's FAC_VERBS section ends before wing doctrine rules. Cannot verify the result is handled.
- The upgradeOne:1 result (wright, dock) references a Mark upgrade system not defined in the pack. Cannot verify it is implemented.
- The Nemesis system's strike behaviours (raid, tithe, duel, challenge, reinforce) are described in NEM_FAC but their resolution code is not in the pack. Cannot verify they execute correctly or interact fairly with events that write nemClock.
- The lore bible (round 8) has no event section. All faction-identity judgements in this report are drawn from the data itself (faction ids, gated options, FAC_VERBS, NEM_FAC descriptions, NEM_PERSONA, NEM_LINES) and the four asymmetry rulings. No bible text was available to confirm or contradict.
- The "Ardent" reference in the astropath deathless variant cannot be verified against any name table or lore source in the pack.
- The full flag-resolution code (how RUN.flags and fl:{} counters are read by downstream systems) is not in the pack. The saboteur/defector flag link is confirmed by the pack header's description of the flag system, but the actual lookup code is not visible.
- The battle.js pack covers lines 1 to 120 only. Encounter resolution, terrain generation, unit AI, and weapon resolution are not in scope. BEVENTS checks are limited to the three defined events and their trigger logic.
- The GAMBLE result on the shrine option (r:{gamble:true}) implies a coin-flip resolver. Its implementation is not in the pack. Cannot verify the "even odds" claim in the option text.
