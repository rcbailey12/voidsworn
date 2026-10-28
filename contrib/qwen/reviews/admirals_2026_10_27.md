BLIND AUDIT REPORT: ADMIRAL COHERENCE, VOIDSWORD / EMBERS OF THE HOLLOW SUN
Reviewer leg: 1 of 4. Pinned to main commit 68b42ce406286eb95ea7df6aaf3f683c1231b51d.
Sources: data.js lines 185-275 (ADMIRALS), data.js lines 428-505 (Nemesis tables), lore bible r8 sections 1.3, 1.4, 2.9, 3.8, 4.9, 5.9, 6.9, 7.9.
Standing rule applied: "admirals should match their special abilities in some way, so that who an admiral is on the page reflects what their Command and doctrine do in a battle" (author ruling, October 2026).
================================================================
FACTION: HEGEMONY
Finding H-1. BLOCKER. OBSERVED.
Bible section 3.8, Avoid list, states verbatim: "Interdictor." The data assigns Vorn the starting fleet "start:['h_interdictor','h_interdictor','h_picket','h_picket']." The ship class name "Interdictor" is a direct hit on the franchise-avoidance list (Star Wars). Every instance of h_interdictor in the pack violates the bible. Rename the class.
Finding H-2. FIX. OBSERVED.
Bible section 3.8, People: "Germanic, Nordic and Dutch names (Konrad Reiter, Sanne Achterberg, Gerold Haldane, Katrin Falk)." The admiral at cost 45 is "Fleet Marshal Corin Reyes." "Reyes" is Spanish. Neither element appears in the naming pattern the bible mandates for Hegemony personnel. INFERRED: this name was likely carried over from an earlier draft before the naming rule was tightened.
Finding H-3. FIX. OBSERVED.
Command id "hunt" produces two different mechanical effects across the roster. Malek and Sable: "Torpedoes reload at once and every ship deals +30% damage this round." Vorn: "Every ship deals +30% damage this round." The torpedo-reload clause is absent. Same id, different payload. If any code path keys off cmd.id to apply effects, the result is faction-dependent and undocumented. INFERRED: the intent is that Vorn's interdiction kit has no torpedo component, so the reload clause was dropped, but the shared id obscures this.
Finding H-4. FIX. OBSERVED.
Vorn's doctrine is "Interdiction" with passive "+10 aim and +10% critical-hit chance." His Command, "Interdiction strike," reads "Every ship deals +30% damage this round." The passive tells a precision story (aim, crits). The Command tells a brute-force story (flat damage, no aim or crit interaction). Under the standing rule, the Command does not reflect the doctrine's identity. INFERRED: an interdiction Command that, say, extended aim bonuses or stripped enemy evasion would tell the same story as the passive.
Finding H-5. NOTE. OBSERVED.
Vorn's first name "Dace" is an English fish name. The bible's examples (Konrad, Sanne, Gerold, Katrin) are all Germanic, Nordic, or Dutch. "Dace" does not fit that pattern. Less severe than "Reyes" because "Dace" is at least a plausible short name, but it sits outside the stated pool.
Finding H-6. NOTE. OBSERVED.
Maren's passive, "All ships +15% hull and +10% shields" with fx:{hpPct:.15,shPct:.1}, is mechanically identical to Thale's passive in the Voidsworn block. Both Commands produce the same effect ("All shields refill and your ships take 40% less hull damage this round"). Different faction, different starting fleets (h_dominion + h_picket vs cathedral + warden), different doctrine names ("Armored column" vs "Iron doctrine"). INFERRED: this is a deliberate mirror across factions, but it means two cost-80 admirals are functionally the same buy. If cross-faction comparison matters for draft or balance, a player choosing between them sees no mechanical difference.
Hegemony doctrine coverage: Fire discipline, Interdiction, Strike group, Armored column. Four distinct. No doubling. No missing archetype flagged.
VERDICT HEGEMONY: FAIL. One BLOCKER (Interdictor), two FIX items (naming, command id collision), one FIX for doctrine-Command mismatch. The faction's admirals tell coherent stories individually, but the data carries a franchise name the bible explicitly bans.
================================================================
FACTION: VOIDSWORD (VOIDSWORN)
Finding V-1. NOTE. OBSERVED.
Thale's passive fx:{hpPct:.15,shPct:.1} and Command effect are mechanically identical to Maren's (see H-6). Within the Voidsworn chapter this is not a problem; Thale reads as a Voidsworn admiral ("High Admiral," "Iron doctrine," cathedral start). Flagged here only because the duplication exists.
Finding V-2. NOTE. OBSERVED.
Ashgrove's Command is named "Scramble all wings." The description says "Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round." The doctrine is "Carrier doctrine" and the passive boosts squadrons and hangar capacity. All three elements tell the carrier story. No issue found. Coherent.
Finding V-3. NOTE. OBSERVED.
Malek's title is "Oath-Captain." Section 2.9 motifs include "oath, chalk names, dawn and dusk, burning, cold, brands." The title fits. His doctrine "Hunter-killer," torpedo-reload passive, rear-arc bonus, and Command "Hunter's salvo" (torpedo reload + damage) all tell the same pursuit-and-kill story. Coherent under the standing rule.
All four Voidsworn admirals pass the one-story check. Doctrine coverage: Line of battle, Hunter-killer, Carrier doctrine, Iron doctrine. Four distinct. No admiral could be moved to another faction without changing ships or names.
VERDICT VOIDSWORD: PASS. No BLOCKER or FIX. Two NOTEs, both cosmetic or cross-faction.
================================================================
FACTION: CORSAIR
Finding C-1. NOTE. OBSERVED.
Sable's doctrine is "Knife work" with passive "+50% damage on rear-arc hits and +10% crit chance." Her Command, "Knife in the dark," reads "Torpedoes reload at once and every ship deals +30% damage this round." The passive never mentions torpedoes. INFERRED: torpedoes are the natural sneak-attack weapon and fit "knife in the dark" as a metaphor, so the story holds, but the doctrine text does not set up the torpedo element of the Command. A player reading only the doctrine line would not expect torpedo interaction in the Command.
Finding C-2. NOTE. OBSERVED.
Sable's Command uses id "hunt," shared with Malek (identical effect) and with Vorn/Ostrel (reduced effect). Within the Corsair block this is not a mechanical problem, but it means Sable's Command carries a torpedo-reload clause that her doctrine does not advertise (see C-1). Same underlying id-collision issue as H-3.
Corsair doctrine coverage: Ram and board, Knife work, Junkyard carriers, Scrap armor. Four distinct. Naming follows bible 4.9: harsh syllables plus earned epithets (Grax Steelgrin, Sable the Smiling Knife, Old Mott, Vesh the Collector). No human surnames. All admirals read as Corsairs.
VERDICT CORSAIR: PASS. Two NOTEs, no FIX or BLOCKER.
================================================================
FACTION: CHORUS
Finding Ch-1. NOTE. OBSERVED.
Bible 5.9 naming rule: "a body or sense word plus a body part or tide word: Seventh Mouth, Gnawing Tide, Wet Whisper, Hollow Gut, Brine Mouth." The cost-45 admiral is "The Mending Throng." "Mending" is an action, not a body or sense word. "Throng" is a collective noun, not a body part or tide word. INFERRED: the intent is biological regeneration (mending tissue, which the Chorus MOD_NAMES list as "Mending tissue" for damcon), so the concept fits the faction, but the name does not follow the stated formula.
Finding Ch-2. NOTE. OBSERVED.
Matriarch's passive fx:{sqPct:.25,hangar:1,sqHp:.25} is identical to Tamsa's passive in the Ithar block at the same cost (0). Matriarch starts three ships (b_brood, b_drone, b_drone); Tamsa starts two (i_carrier, i_wisp). INFERRED: the Ithar carrier hull may be individually stronger, which would justify the smaller fleet, but the pack does not include ship stats to confirm. The identical passive at the same cost across factions is noted for the cost-band check below.
Chorus doctrine coverage: Brood swarm, Hunter pack, Regrowth, Acid tide. Four distinct. Naming follows bible 5.9 for the most part (see Ch-1 exception). The Matriarch's title format matches the Nemesis title register (Spawn-mother, Maw-mother). All admirals read as Chorus.
VERDICT CHORUS: PASS. Two NOTEs, no FIX or BLOCKER.
================================================================
FACTION: ITHAR
Finding I-1. NOTE. OBSERVED.
Tamsa's passive is identical to Matriarch's (see Ch-2). Tamsa starts two ships at cost 0 where Matriarch starts three. INFERRED: if i_carrier is not meaningfully stronger than b_brood plus two b_drones combined, Tamsa is the weaker cost-0 admiral. Cannot confirm without ship stats.
Finding I-2. NOTE. OBSERVED.
Bible 6.9 lists Nemesis titles as "Lens-keeper, First Mirror, Keeper of Astra." The data's Ithar Nemesis title pool adds a fourth: "Duelist." This title is not in the bible's list. INFERRED: "Duelist" may have been added to support the Ithar Nemesis behaviour (beh.strike is "duel"), but it was not added to the bible in round 8. Either update the bible or remove the title.
Ithar doctrine coverage: Wing-mistress, Focused lances, Refraction tactics, Prism hulls. Four distinct. Naming follows bible 6.9 exactly: short first name plus optical family line (Tamsa of the Clear Aperture, Saro of Long Focus, Vell of the Third Mirror, Brin of the Fourth Lens). All admirals read as Glasswrights.
VERDICT ITHAR: PASS. Two NOTEs.
================================================================
FACTION: DEATHLESS
Finding D-1. NOTE. OBSERVED.
Ostrel's Command, "Out of the shadow," reads "Every ship deals +30% damage this round." It uses id "hunt" but omits the torpedo-reload clause present in Malek's and Sable's versions. Same id-collision issue as H-3. Ostrel's doctrine "Silent hunters" with rear-arc and evasion fits the stealth story. The Command's flat damage is a weaker expression of "silent hunter" than a precision-strike effect would be, but it does not contradict the doctrine. NOTE only.
Finding D-2. NOTE. OBSERVED.
Seveth's doctrine is "Layered plates" and her passive is "All ships +20% hull" (fx:{hpPct:.2}). Her Command, "Sunshade wall," reads "All shields refill and your ships take 40% less hull damage this round." The passive is hull-only (no shield component). The Command leads with shield refill. INFERRED: the 40% hull-damage reduction does protect the hull, so the Command is not unrelated to the doctrine, but the shield-refill clause is not set up by "Layered plates." Under the standing rule, a player reading "Layered plates" expects hull armour, not a shield event. Minor mismatch.
Deathless doctrine coverage: Endless restoration, Corona strikes, Silent hunters, Layered plates. Four distinct. Naming follows bible 7.9 exactly: Starwright name plus iteration epithet (Nadir Aurex Ninth Frame, Umbra Vessane Third-Housed, Ostrel of the Long Copy, Seveth Twice-Restored). All admirals read as Eclipse.
VERDICT DEATHLESS: PASS. Two NOTEs.
================================================================
NEMESIS TABLES (data.js lines 428-505)
Finding N-1. BLOCKER. OBSERVED.
Rule 1.4.3: "One name, one owner: no captain pool may roll an admiral's first name or surname; no Nemesis pool may roll a boss name." The Voidsworn Nemesis post-name pool is: "['Varrow','Ashdown','Quell','Harrowgate','Vane','Stroud','Draeger','Holloway','Blackwood','Corvane']." The captain surname pool CAP_LAST contains every one of these ten entries: Varrow, Ashdown, Quell, Harrowgate, Vane, Stroud, Draeger, Holloway, Blackwood, Corvane. A generated captain can share a surname with a generated Nemesis. This breaks the one-name-one-owner rule for the Voidsworn faction. No other faction's Nemesis pool overlaps CAP_FIRST or CAP_LAST.
Finding N-2. FIX. OBSERVED.
The Ithar Nemesis title pool includes "Duelist," which is absent from bible 6.9's Nemesis title list ("Lens-keeper, First Mirror, Keeper of Astra"). See I-2.
Finding N-3. NOTE. OBSERVED.
The Deathless Nemesis title pool includes "Archivist." Bible 1.3 assigns "Memory, the archive, the lost sun, warmth remembered" to Eclipse, and explicitly notes "the Hegemony keeps data, not memory." The Deathless relic name for the logbook is "The Archive." INFERRED: "Archivist" sits within the Deathless identity as the keeper of the Archive, not as a Hegemony data-role. No violation found, but the word is close to the boundary the bible draws.
Finding N-4. NOTE. OBSERVED.
Nemesis faction trait pools, persona pools, scar pools, and behaviour blocks were checked against faction identity. Corsair traits (boarders, swift, rockets, deadeye, gunnery, veterans) fit the violence-and-scrap motif. Chorus traits (regrowth, brood, veterans, swift, boarders, deadeye) fit the biological motif. Ithar traits (veil, shielded, swift, deadeye, gunnery, artillery) fit the light-and-evasion motif. Deathless traits (undying, armored, veterans, regrowth, gunnery, deadeye) fit the persistence motif. Hegemony traits (artillery, shielded, gunnery, armored, veterans, deadeye) fit the formation-fire motif. Voidsworn traits (zeal, boarders, armored, veterans, gunnery, artillery) fit the oath-and-charge motif. No cross-faction trait contamination found.
Finding N-5. NOTE. OBSERVED.
Nemesis name generation was checked against admiral names per rule 1.4.3 ("no Nemesis pool may roll a boss name"). For each faction, no combination of pre + post pool entries can produce an admiral's name. Example: Deathless pre pool has no entry "Aurex," "Vessane," "Ostrel," or "Seveth" as a complete token, and post pool entries combine with pre entries to form new names (e.g., "Mar" + "eth" = "Mareth"). Clear.
Finding N-6. NOTE. OBSERVED.
NEM_ADAPT_FAC entries were checked for faction-appropriate language. Corsair adaptations use scrap/stolen language. Deathless adaptations use corona/null/sunshade language. Ithar adaptations use prism/mirror/starwind language. Chorus adaptations use membrane/spore/chitin language. Hegemony adaptations use drill/formation language. Voidsworn adaptations use oath/rivet/spark language. No cross-faction vocabulary found.
================================================================
COST-BAND CHECK (cross-faction, same cost)
Cost 0:
Vex (broadPct .15, 3 ships), Kassar (battShots +1 / dmgPct -.05, 2 ships), Grax (speed +1 / dmgPct .1, 3 ships), Matriarch (sqPct .25 / hangar +1 / sqHp .25, 3 ships), Tamsa (sqPct .25 / hangar +1 / sqHp .25, 2 ships), Nadir Aurex (hullRegenPct .04, 2 ships).
NOTE. OBSERVED. Tamsa carries the same passive as Matriarch with one fewer starting ship. Nadir Aurex's passive (4% hull regen) is the thinnest cost-0 passive in the roster. INFERRED: the Deathless and Ithar base hulls may compensate, but the pack does not include ship stats. Flagged for the balance team.
Cost 30:
Malek (torpCd 1 / rearPct .5, 4 ships), Vorn (aim 10 / crit 10, 4 ships), Sable (rearPct .5 / crit 10, 4 ships), Razormaw (speed 1 / rearPct .15, 3 ships), Saro (lancePct .2 / aim 10, 2 ships), Umbra (lancePct .2 / dmgPct .1, 3 ships).
NOTE. OBSERVED. Razormaw's passive (speed +1, rearPct .15) is the lightest cost-30 package. Malek's (torpedo cooldown reduction, rearPct .5) is the heaviest. INFERRED: the gap is wide but may be closed by the Chorus ship roster. Cannot verify without ship stats.
Cost 45:
Ashgrove (sqPct .4 / hangar +1 / sqHp .25, 3 ships), Reyes (sqPct .1 / hangar +1 / sqHp .25, 3 ships), Mott (sqPct .25 / hangar +1 / sqHp .25, 2 ships), Mending Throng (hullRegenPct .04, 2 ships), Vell (ev 8, 4 ships), Ostrel (rearPct .2 / ev 10, 4 ships).
FIX. OBSERVED. Ashgrove's squadron bonus is +40%. Reyes' is +10%. Same cost, same hangar and sqHp values, same fleet size. INFERRED: Reyes is the weakest carrier admiral at this band by a wide margin. The retuning note in the data comment ("stream B, Oct 27") lists Reyes as retuned, so this may be intentional, but a 4-to-1 gap in the primary passive stat at equal cost is an outlier worth a second look.
NOTE. OBSERVED. Mending Throng's passive (4% hull regen, 2 ships) is the thinnest cost-45 package. Ostrel's (rearPct .2, ev 10, 4 ships) is the fullest. INFERRED: the Mending Command (25% heal, section repair) is strong, but the passive alone does not carry the cost band.
Cost 80:
Thale (hpPct .15 / shPct .1, 2 ships), Maren (hpPct .15 / shPct .1, 2 ships), Vesh (hullRegenPct .05 / armor .1, 2 ships), Voice (dmgPct .15, 3 ships), Brin (shPct .15 / regenPct .2, 3 ships), Seveth (hpPct .2, 3 ships).
NOTE. OBSERVED. Thale and Maren start 2 ships. Voice, Brin, and Seveth start 3. INFERRED: the cathedral and dominion hulls may be large enough to compensate, but the pack does not include ship stats.
================================================================
DUPLICATE AND DOMINATION CHECK
Identical passives across factions at the same cost:
Thale (voidsworn, 80) and Maren (hegemony, 80): identical fx and identical Command effect. See H-6. NOTE.
Matriarch (chorus, 0) and Tamsa (ithar, 0): identical fx, different fleet sizes. See Ch-2 / I-1. NOTE.
Same command id, different effects:
id "hunt": torpedo-reload variant (Malek, Sable) vs damage-only variant (Vorn, Ostrel). See H-3. FIX.
Same command id, same effect, different display names (intentional faction reskins):
"barrage": Fire for effect / Synchronized broadside / Burning glass / Spitting volley / Noon volley. Same effect. No issue.
"scramble": five admirals. Same effect. No issue.
"iron": four admirals. Same effect. No issue.
"surge": three admirals. Same effect. No issue.
"restore": three admirals. Same effect. No issue.
These are faction-flavoured reskins and read as intended. No finding.
No admiral is strictly dominated by another admiral within the same faction (all four cost slots within each faction are unique). Cross-faction domination is not applicable because starting fleets and faction mechanics differ.
================================================================
NOT CHECKED
The pack did not let me verify the following:
Ship-class statistics (hull, shield, speed, weapon arcs, hangar capacity) for any hull referenced in starting fleets (penitent, harrow, warden, cathedral, reliquary, h_vanguard, h_picket, h_interdictor, h_dominion, c_marauder, c_reaver, c_raider, c_hulk, b_brood, b_drone, b_razor, b_spitter, i_carrier, i_wisp, i_song, i_blade, d_harvester, d_jackal, d_scythe). Cost-band and fleet-power findings are therefore INFERRED.
The bossmatrix balance targets referenced in the stream B retuning comment. I cannot confirm that every admiral sits in the stated 55-to-85% window.
Battle resolution code. Whether fx keys such as broadPct, torpCd, battShots, and hullRegenPct are wired to the battle engine is outside the pack.
Whether "h_interdictor" is a data key only or also a player-visible display string. If display strings are generated from a separate table, the visible name may already differ. The pack does not include a ship display-name table.
Portrait assignments (nem_faction_1 through 6) and whether they match final species art per the note in 4.9.
Wing doctrine data (the file excerpt cuts off at the B4 wing-doctrine header).
Whether the NEM_LINES placeholder pools have been replaced by the story helper's final rival lines.
The full text of lore bible chapters 2 through 7 beyond the x.9 subsections provided. Faction-identity checks rest on those subsections and on section 1.3.
Whether "Corin Reyes" was a deliberate exception to the Hegemony naming rule or an oversight. I have treated it as an oversight per the instruction to state my reading and proceed.
================================================================
VERDICTS
Voidsworn: PASS. No BLOCKER. No FIX. Two NOTEs.
Hegemony: FAIL. One BLOCKER (Interdictor). Three FIX items. Two NOTEs.
Corsair: PASS. Two NOTEs.
Chorus: PASS. Two NOTEs.
Ithar: PASS. Two NOTEs.
Deathless: PASS. Two NOTEs.
Nemesis tables: One BLOCKER (Voidsworn post-pool / CAP_LAST overlap). One FIX (Duelist title). Four NOTEs.
OVERALL VERDICT: FAIL. Two BLOCKERS must be cleared before the pack can ship. The Hegemony ship class "Interdictor" violates the franchise-avoidance list in bible 3.8. The Voidsworn Nemesis post-name pool is drawn entirely from the captain surname pool, breaking the one-name-one-owner rule in 1.4.3. Four FIX items (Hegemony naming, command id "hunt" collision, Vorn doctrine-Command mismatch, Ithar Nemesis title "Duelist") should be resolved in the same pass. The remaining NOTEs are balance observations and minor naming-pattern observations that do not block.
END OF REPORT.
