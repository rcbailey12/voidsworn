Admiral coherence audit, pinned to main commit 68b42ce406286eb95ea7df6aaf3f683c1231b51d

Reading notes

OBSERVED: The pack contains 24 admirals, four per faction, and six Command ids reused across factions: barrage, hunt, scramble, iron, surge, restore.

INFERRED: I treat "boss name" as an admiral display name or its first or surname. I treat the same command id with different text as a defect even when the difference is small. Cost and power calls are textual, not simulated, because the pack does not include ship stats or battle code.

VOIDSWORN

Admirals walked: Vex coherent; Malek coherent; Ashgrove coherent; Thale coherent but generic.

Findings ranked:

1. FIX, OBSERVED: Thale and Hegemony Maren share the exact passive and Command. Thale has fx:{hpPct:.15,shPct:.1} and cmd id iron "Iron wall"; Maren has fx:{hpPct:.15,shPct:.1} and cmd id iron "Shield wall order". Both cost 80. INFERRED: the two are the same kit with different names; Thale could move to Hegemony without changing a word except the display name. This is a cross-faction duplicate.

2. NOTE, OBSERVED: Vex's Command is barrage, "Every ship fires a free volley at the best target its guns can reach, right now." The same barrage effect appears on Kassar, Vaelen, Voice and Sekhmar under different names. INFERRED: Vex is coherent, but his Command is not unique.

3. NOTE, OBSERVED: Malek and Corsair Sable both cost 30, both have rearPct:.5, and both use hunt with "Torpedoes reload at once and every ship deals +30% damage this round." Malek adds torpCd:1; Sable adds crit:10. INFERRED: near-duplicate hunter kit across factions.

Verdict: coherent faction with no internal story blocker; Thale is a generic duplicate and the Command pool is shared.

HEGEMONY

Admirals walked: Kassar coherent; Vorn mismatched; Reyes coherent but underpowered; Maren coherent but duplicated.

Findings ranked:

1. FIX, OBSERVED: Vorn's doc is "Interdiction", but his passive is "+10 aim and +10% critical-hit chance" and his Command "Interdiction strike" only says "Every ship deals +30% damage this round." INFERRED: nothing in the passive or Command interdicts, slows, blocks or controls movement. The label promises a playstyle the data does not deliver. This is the worst story mismatch in the faction.

2. FIX, OBSERVED: Reyes and Voidsworn Ashgrove both cost 45 and both use scramble, but Reyes has sqPct:.1 while Ashgrove has sqPct:.4. Both also have hangar:1 and sqHp:.25. INFERRED: at the same cost and with the same Command, Reyes is a textual outlier downward against Ashgrove.

3. NOTE, OBSERVED: Maren is identical to Thale in passive and Command, as noted under Voidsworn. INFERRED: Maren is coherent as a tank but not distinct.

4. NOTE, OBSERVED: Kassar's barrage is the same effect as Vex's. Kassar starts with two ships, h_vanguard and h_picket; Vex starts with three. INFERRED: the extra battery shot and -5% damage passive may compensate, but the pack does not show that it does.

Verdict: fix Vorn's doctrine mismatch and Reyes's cost-band weakness; Maren is a generic duplicate.

CORSAIR

Admirals walked: Grax mismatched; Sable coherent but near-duplicate; Mott coherent; Vesh coherent.

Findings ranked:

1. BLOCKER, OBSERVED: Grax's doc is "Ram and board", but his passive is "+1 speed for every ship and +10% damage" and his Command "Full burn" gives "+2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round." INFERRED: there is no ram effect and no boarding effect in the passive or Command. The text promises a playstyle the data cannot deliver.

2. FIX, OBSERVED: Sable and Malek are near-duplicates at cost 30. Both have rearPct:.5 and hunt with the torpedo reload clause. Sable adds crit:10; Malek adds torpCd:1. INFERRED: the two read as the same hunter choice under different faction skins.

3. NOTE, OBSERVED: Mott uses scramble, the same Command as Ashgrove, Reyes, Matriarch and Aelith. His passive is sqPct:.25, hangar:1, sqHp:.25. INFERRED: Mott is coherent but shares the carrier Command verb.

4. NOTE, OBSERVED: Vesh uses restore, the same Command as Mending and Nekhet. His passive adds hullRegenPct:.05 and armor:.1, so he is not identical to either. INFERRED: Vesh is the strongest of the restore users on text.

Verdict: blocker on Grax; Sable is a near-duplicate; the rest is coherent.

CHORUS

Admirals walked: Matriarch coherent but duplicated; Razormaw coherent; Mending coherent but overcosted; Voice coherent but weak at cost.

Findings ranked:

1. BLOCKER, OBSERVED: Matriarch and Ithar Aelith both cost 0 and both have fx:{sqPct:.25,hangar:1,sqHp:.25} and the same scramble effect. Matriarch starts with three ships, b_brood, b_drone and b_drone; Aelith starts with two, i_carrier and i_wisp. INFERRED: on the pack text Aelith is the same kit at the same cost with fewer starting hulls. This is a duplicate and a likely domination unless Ithar ships are materially stronger, which the pack does not show.

2. FIX, OBSERVED: Mending has hullRegenPct:.04 and restore, exactly like Deathless Nekhet, but Mending costs 45 and Nekhet costs 0. INFERRED: Mending is an outlier upward in cost against a same-kit admiral.

3. FIX, OBSERVED: Voice costs 80 and has only dmgPct:.15 plus barrage. Sekhmar costs 30 and has lancePct:.2 plus dmgPct:.1 plus barrage. INFERRED: Voice is weak in the 80 band against Sekhmar's cheaper and broader passive.

4. NOTE, OBSERVED: Razormaw uses surge, the same Command as Grax and Thorne. His passive is speed:1 and rearPct:.15. INFERRED: coherent as a fast flanker, but the Command is shared.

Verdict: blocker on the Matriarch and Aelith duplicate; Mending and Voice are cost-band outliers.

ITHAR

Admirals walked: Aelith duplicated; Vaelen coherent but low start; Thorne coherent but shared; Mirelle coherent.

Findings ranked:

1. BLOCKER, OBSERVED: Aelith duplicates Matriarch at cost 0 with the same passive and scramble, and starts with two ships against Matriarch's three. INFERRED: Aelith is the weaker half of a duplicate pair on the pack text.

2. FIX, OBSERVED: Vaelen costs 30 and starts with two ships, i_song and i_blade. At the same cost Malek starts with four ships and Sekhmar starts with three. Vaelen's passive is lancePct:.2 and aim:10 plus barrage. INFERRED: Vaelen is a starting-fleet outlier downward in the 30 band.

3. NOTE, OBSERVED: Thorne uses surge, the same Command as Grax and Razormaw. His passive is ev:8. Grax at cost 0 has speed:1 and dmgPct:.1 with the same surge. INFERRED: Thorne is coherent as an evasion admiral but looks expensive against Grax's cheaper package.

4. NOTE, OBSERVED: Mirelle uses iron, the same Command as Thale, Maren and Khepra. Her passive is shPct:.15 and regenPct:.2. INFERRED: coherent as a shield tank, but the Command is shared.

Verdict: blocker on Aelith; Vaelen is a cost-band outlier; the rest is coherent.

DEATHLESS

Admirals walked: Nekhet coherent; Sekhmar coherent; Anuket coherent but overcosted; Khepra mismatched.

Findings ranked:

1. FIX, OBSERVED: Khepra's doc is "Layered plates" and his passive is hpPct:.2, but his Command "Sunshade wall" is "All shields refill and your ships take 40% less hull damage this round." INFERRED: the Command is a shield and damage-reduction effect, not a layered-plate or hull effect. The doctrine and Command do not tell the same story.

2. FIX, OBSERVED: Nekhet and Mending share hullRegenPct:.04 and restore. Nekhet costs 0; Mending costs 45. INFERRED: Mending is the overcosted half of the pair.

3. FIX, OBSERVED: Anuket costs 45 and has rearPct:.2 and ev:10 with hunt text "Every ship deals +30% damage this round." Sable costs 30 and has rearPct:.5 and crit:10 with hunt text that also reloads torpedoes. INFERRED: Anuket is a cost-band outlier downward against Sable.

4. NOTE, OBSERVED: Sekhmar costs 30 with lancePct:.2 and dmgPct:.1 plus barrage. Voice costs 80 with only dmgPct:.15 plus barrage. INFERRED: Sekhmar is the cheaper benchmark that makes Voice look weak.

Verdict: fix Khepra's doctrine mismatch and Anuket's cost; Nekhet is coherent but duplicates Mending.

CROSS-FACTION COMMAND AND COST FINDINGS

1. FIX, OBSERVED: Six Command effects cover 24 admirals. Barrage appears on Vex, Kassar, Vaelen, Voice and Sekhmar. Hunt appears on Malek, Vorn, Sable and Anuket. Scramble appears on Ashgrove, Reyes, Mott, Matriarch and Aelith. Iron appears on Thale, Maren, Mirelle and Khepra. Surge appears on Grax, Razormaw and Thorne. Restore appears on Vesh, Mending and Nekhet. INFERRED: the admiral Command pool is heavily duplicated across factions.

2. FIX, OBSERVED: The hunt id does not always produce the same effect. Malek and Sable say "Torpedoes reload at once and every ship deals +30% damage this round." Vorn and Anuket say only "Every ship deals +30% damage this round." INFERRED: the same command id carries two different effects.

3. FIX, OBSERVED: Identical passives exist across factions. Thale and Maren are exact. Matriarch and Aelith are exact. Nekhet and Mending are exact. INFERRED: these are not distinct admiral identities at equal cost.

4. NOTE, OBSERVED: RANKS in data.js is ['Lieutenant','Commander','Captain','Commodore','Fleet captain']; bible section 3.8 lists "Rear admiral" and the admiral ranks "Line Admiral, Fleet Marshal, First Admiral, High Commodore." INFERRED: the rank vocabulary is inconsistent, though no admiral uses "Fleet captain."

5. NOTE, OBSERVED: No exact collision was found between the 24 admiral display names and CAP_FIRST or CAP_LAST. INFERRED: the direct admiral-to-captain name rule is clean in the pack.

6. NOTE, OBSERVED: Generic admirals that could move factions without a word change include Thale and Maren, Matriarch and Aelith, and Nekhet and Mending. INFERRED: faction fit is weak where the kit is identical.

NEMESIS TABLES

Findings ranked:

1. FIX, OBSERVED: Deathless NEM_FAC titles are ['High Nadir','Eclipse-prime','Archivist','Nadir']. ADMIRALS has nekhet n:'Nadir Aurex, Ninth Frame'. Bible 7.9 says "iteration language, not poetic titles." INFERRED: 'Nadir' and 'High Nadir' reuse a boss first name, and 'Eclipse-prime' is not iteration language. This violates the no-boss-name rule and the section 7.9 naming rule.

2. FIX, OBSERVED: Voidsworn NEM_FAC post is ['Varrow','Ashdown','Quell','Harrowgate','Vane','Stroud','Draeger','Holloway','Blackwood','Corvane'], and every entry is also in CAP_LAST. Bible 1.4 says "One name, one owner." INFERRED: the Nemesis pool mixes with the captain surname pool. My reading is that this violates the one-name-one-owner heading even though the bullet explicitly names only boss names.

3. NOTE, OBSERVED: Hegemony NEM_FAC titles are ['First Admiral','Fleet Marshal','Line Admiral','High Commodore'], which are ranks from bible 3.8 and also titles or ranks used by Hegemony admirals. INFERRED: this is not a banned cross-faction title, but it repeats boss ranks in the Nemesis title pool.

4. NOTE, OBSERVED: Corsair NEM_FAC titles include 'Warlord', and ADMIRALS grax is n:'Warlord Grax Steelgrin'. Bible 1.4 says no epithet repeats across admiral, scar and persona. INFERRED: 'Warlord' repeats an admiral title.

5. NOTE, OBSERVED: Corsair, Chorus and Ithar Nemesis title pools match bible sections 4.9, 5.9 and 6.9: corsair body and tool names, chorus body and tide names, ithar Lens-keeper and First Mirror titles. INFERRED: those three pools are the cleanest in the pack.

6. NOTE, OBSERVED: Vorn's doc "Interdiction" and start id h_interdictor sit close to bible 3.8's avoid list entry "Interdictor." INFERRED: the id stays by rule, but the display string should be checked; the pack does not show it.

OVERALL VERDICT

INFERRED: The admiral set is not coherent enough to sign off. There is one clear story blocker on Grax, one duplicate and domination blocker on Matriarch and Aelith, several cost-band outliers (Reyes, Mending, Anuket, Voice, Vaelen, Khepra), heavy Command duplication across all factions, and two Nemesis naming fixes in Deathless and Voidsworn. Per faction: Voidsworn pass with caveat; Hegemony fix; Corsair blocker; Chorus blocker; Ithar blocker; Deathless fix.

NOT CHECKED

OBSERVED: The pack did not let me verify battle.js applyVerb, actual ship stats, hidden Command differences, ship display strings such as h_interdictor, Nemesis title roll weights, or whether CAP_LAST reuse in the Voidsworn Nemesis pool is intentional. INFERRED: numeric balance calls are therefore textual only. No other reviewer's work was available.
