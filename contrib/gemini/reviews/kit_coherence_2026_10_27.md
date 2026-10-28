Chair header: Argon leg of the faction kit coherence audit (Oct 27 program item 3, pack pinned to 68b42ce406286eb95ea7df6aaf3f683c1231b51d). Fresh Gemini chat, Argon High verified in the model picker button and the prompt bar dropdown before submitting (4 Argon selected, Thinking level set to High). Both pack files (pack.txt and leg_prompt.md) were attached via Upload files. Session signed in as rcbailey12@gmail.com (Google AI Pro). Ran Oct 27, 2026, 6:33-7:13 PM PDT (39m, harness measured). The first chat produced a partial report and then showed an error; exactly one fresh chat was opened and the report below is from that second chat, complete. The text below is the model's complete return, verbatim. The browser agent's method notes are not model text and live in the chair screening note instead. Per leg convention for Gemini, this single reviews copy is the filed record; there is no separate raw file.

---

FACTION KIT COHERENCE AUDIT: VOIDSWORN / EMBERS OF THE HOLLOW SUN
Pinned commit: 68b42ce406286eb95ea7df6aaf3f683c1231b51d

OVERALL VERDICT: FAIL (HOLD FOR BLOCKERS)
OBSERVED: Across the six factions, data.js lines 1 to 275 contain unimplemented October 2026 asymmetry rulings (Hegemony synchronized fire and flagship-anchor loss, Chorus repair prohibition, Glasswrights Brace prohibition, and the Voidsworn carrier gate conflict), dead anti-shield weapons and abilities against the two shieldless factions (chorus and deathless, both at sh:0 across all hulls), non-functional faction module mappings in MOD_NAMES (for weapon kinds and shields that chorus, ithar, and deathless do not field), missing cost and slots fields on all non-Voidsworn hulls in HULLS (lines 74 to 101), and unremoved Necron green/tomb styling on deathless (line 126). INFERRED: The faction kits cannot be playtested sensibly as six distinct playable rosters until these blockers and mechanical mismatches are resolved.

========================================================================

SUNWARD CRUSADE (id: voidsworn)
========================================================================
FACTION VERDICT: PASS WITH FIXES (1 BLOCKER, 4 FIX, 2 NOTE)

Finding 1.1 [BLOCKER] [4. Rulings compliance / 2. Hulls] Unresolved Carrier Gate Conflict and Missing Faction Squadron Type

OBSERVED: price_ladder_synthesis.md (Headline and Agreements) states "the Voidsworn carrier gate" is triple-confirmed and "Voidsworn loses the carrier class in all three drafts".

OBSERVED: lore_bible_r8.md section 2.7 states "carriers kept" and section 2.11 lists "Hearth (carrier, was Reliquary)".

OBSERVED: data.js keeps reliquary at line 66 ("n:'Hearth-class carrier',cls:'Carrier',fac:'voidsworn'"), includes 'reliquary' in FACTIONS.voidsworn.roster at line 113, and assigns ADMIRALS.ashgrove a carrier doctrine starting with 'reliquary' at lines 207 and 214.

OBSERVED: FACTIONS.voidsworn (line 113) omits the sq property entirely, whereas every other carrier-capable faction explicitly defines sq in FACTIONS (hegemony sq:'fighter' at line 116, corsair sq:'bomber' at line 119, chorus sq:'spore' at line 122, ithar sq:'fighter' at line 125, and deathless sq:null at line 128).

INFERRED: Either the October 24 carrier gate ruling was superseded by round 8 of the bible without updating the rulings record, or data.js is in breach of the carrier gate; in addition, omitting sq on FACTIONS.voidsworn leaves Hearth-class carriers without an explicit faction squadron key in data.js.

Finding 1.2 [FIX] [1. Weapons / 2. Hulls] Faction Drive Rule and Line-of-Battle Admiral Passive Are Dead on Half the Roster

OBSERVED: MOVE_RULES.voidsworn (data.js line 106) sets "rake:.4,n:'Broadside doctrine',d:'Port and starboard guns hit 40% harder after moving 2+ hexes (others get 10%).'" and ADMIRALS.vex (line 205) grants "fx:{broadPct:.15}".

OBSERVED: In HULLS (data.js lines 63 to 68), warden (line 63, w:[['autocannon','F'],['flak','T']]), harrow (line 64, w:[['torp','F'],['turret','T']]), and reliquary (line 66, w:[['turret','T'],['flak','T']]) mount only 'F' and 'T' arc weapons; only penitent (line 65), cathedral (line 67), and ascendant (line 68) mount 'P' and 'S' weapons.

OBSERVED: ADMIRALS.malek starts with "start:['harrow','harrow','warden','warden']" (line 206) and ADMIRALS.ashgrove starts with "start:['reliquary','harrow','warden']" (line 207).

INFERRED: Half of the Voidsworn hull roster and the entire starting fleets of two out of four Voidsworn admirals gain zero benefit from the faction's defining Broadside doctrine drive rule.

Finding 1.3 [FIX] [1. Weapons] Lance Array and Cinder Torpedo Shield Pierce Are Dead Against Two Whole Factions

OBSERVED: W.lance (data.js line 7, mounted on penitent line 65 and cathedral line 67) has "pierce:.6", and W.torp (line 8, mounted on harrow line 64) has "pierce:.3".

OBSERVED: Every hull in chorus (data.js lines 86 to 90) and every hull in deathless (lines 98 to 101) has "sh:0,rg:0".

OBSERVED: FAC_WTRAIT.voidsworn (line 54) assigns traits to autocannon, battery, hbattery, turret ('las'), and torp ('hellfire'), but assigns no faction trait to lance ('Oath lance').

INFERRED: Against chorus and deathless (including Voidsworn's primary lore enemy, Eclipse, in lore_bible_r8.md section 2.6), the .6 shield pierce on Oath lance and .3 shield pierce on Cinder torpedo do nothing, and Oath lance lacks a faction weapon trait.

Finding 1.4 [FIX] [3. Abilities, orders, modules, perks] Default Relic Names Bleed Alien/Enemy Identities Into Sunward Crusade Runs

OBSERVED: lore_bible_r8.md section 2.4 states "Not allowed: saints, relics, an emperor's light, beacons that guide ships, lanterns, cathedrals, singing".

OBSERVED: RELIC_NAMES (data.js lines 266 to 271) defines faction-specific relic names for hegemony, corsair, chorus, ithar, and deathless, but has no voidsworn key, forcing voidsworn to use the base RELICS names (lines 188 to 201).

OBSERVED: Base RELICS includes lattice ("n:'Alien shield matrix'", line 191), spore ("n:'Tamed spore culture'", line 192), phylactery ("n:'Eclipse backup frame'", line 193), and logbook ("n:'Log of Admiral Rhel'", line 199, a name not present in lore_bible_r8.md section 2.10 or 2.11).

INFERRED: While every other faction receives localized relic names for most items, Sunward Crusade fleets receive raw alien and Eclipse item names by default.

Finding 1.5 [FIX] [3. Abilities, orders, modules, perks] Duplicate Abilities and Commands Shared Across Factions

OBSERVED: ABILITIES.evasive on warden (line 63, line 133: "d:'+25 evasion until your next turn and +2 movement now.',cd:3") is mechanically identical to ABILITIES.phase (line 145).

OBSERVED: ABILITIES.focus on penitent (line 65, line 135: "d:'All of this ship’s weapons deal +30% damage this turn.',cd:3") is word-for-word identical in effect and cooldown to ABILITIES.frenzy (line 142).

OBSERVED: ADMIRALS.thale (lines 208, 215) has the exact same passive ("fx:{hpPct:.15,shPct:.1}") and command ("cmd:{id:'iron',n:'Iron wall',d:'All shields refill and your ships take 40% less hull damage this round.'}") as Hegemony's ADMIRALS.maren (line 220).

INFERRED: Voidsworn's frigate ability, cruiser ability, and Iron doctrine admiral duplicate other factions' entries rather than giving the Crusade unique tools.

Finding 1.6 [NOTE] [2. Hulls] Daybreak-class Dreadnought Mounts No Lance Despite Faction Blurb and Bible

OBSERVED: lore_bible_r8.md section 2.7 and FACTIONS.voidsworn.blurb (data.js line 113) highlight "heavy armor, lances, and broadsides", yet ascendant (line 68, Daybreak-class dreadnought) mounts "w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']]" with no 'lance', relying on "ab:'nova'" instead.

INFERRED: A player buying crystal ("Lance damage +25%", line 161) or PERKS.lanceadept (line 177) for the flagship dreadnought gets zero benefit on ascendant.

Finding 1.7 [NOTE] [2. Hulls / 3. Perks] Internal Keys and Captain Surnames Retain Pre-Round-8 Leftovers

OBSERVED: HULLS (lines 65 to 68) and FACTIONS.voidsworn (line 113) still use internal keys 'penitent', 'reliquary', 'cathedral', 'ascendant' and "style:'gothic'", though display names were updated.

OBSERVED: CAP_LAST (data.js line 256) includes 'Ostrava', 'Marchetti', 'Ferro', 'Vashti', 'Serrano', 'Lachance', 'Okonkwo', and 'Salo', departing from lore_bible_r8.md section 2.10 ("hard English surnames (Varrow, Harrowgate, Ashdown, Holloway, Blackwood)").

INFERRED: Cosmetics and captain name generation do not strictly match the round 8 naming specification.

========================================================================
2. HEGEMONY NAVY (id: hegemony)

FACTION VERDICT: FAIL (4 BLOCKERS, 3 FIX, 1 NOTE)

Finding 2.1 [BLOCKER] [4. Rulings compliance] Hegemony Synchronized Fire Definer and Flagship-Anchor Loss Are Missing From data.js

OBSERVED: price_ladder_synthesis.md (Staleness warning) states: "Ryan ruled Oct 24 ~11:50: synchronized fire primary, pinning secondary (waves of fire)".

OBSERVED: OPUS_HANDOFF.md section 1 states: "Hegemony definer: synchronized fire (Kassar doctrine faction-wide) PRIMARY, pinning (Vorn interdiction) SECONDARY. Ion suppression not adopted. Shield-stripping drops to ion weapon flavor, not the identity" and "Hegemony loss: formation dependence, flagship-anchor version TO START. Synchronized fire counts only for ships within a radius of the flagship; losing the anchor collapses sync".

OBSERVED: lore_bible_r8.md section 3.5 states: "Formation around the flagship. Fire syncs near the flagship (the network), ion cannons strip shields, cruisers launch fighter screens, retro thrusters make backing off cheap".

OBSERVED: In data.js, FACTIONS.hegemony.blurb (line 115) still reads "The Registry’s navy: linked crews, wedge hulls and drone escorts. Ion cannons strip shields; carriers launch fighter screens", MOVE_RULES.hegemony (line 107) only sets "rev:1", neither FACTIONS.hegemony (lines 114 to 116) nor HULLS (lines 74 to 78) defines any synchronized-fire or flagship-anchor rule, and ADMIRALS.kassar (line 217) keeps "doc:'Fire discipline'" ("fx:{battShots:1,dmgPct:-.05}") and "cmd:{id:'barrage',n:'Synchronized broadside',...}" isolated to a single admiral.

OBSERVED: Neither ADMIRALS.vorn (line 218, "fx:{aim:10,crit:10}", "cmd:{id:'hunt',...}"), nor h_interdictor (line 75, "ab:'ionpulse'"), nor W.ion (line 13) contains any pinning or movement-impairment mechanic in data.js.

INFERRED: data.js has not been updated to implement the October 24 Hegemony ruling; the faction still presents shield-stripping ion weapons and carrier screens as its core kit rather than flagship-anchored synchronized fire and secondary pinning.

Finding 2.2 [BLOCKER] [1. Weapons / 3. Abilities] Ion Cannon, Ion Pulse, and Plasma Trait Are Dead or Near-Dead Against Chorus and Eclipse

OBSERVED: Every hull in chorus (lines 86 to 90) and deathless (lines 98 to 101), as well as all squadrons (lines 70 to 72), has "sh:0,rg:0".

OBSERVED: W.ion (data.js line 13) has "shots:1,dmg:12,r:6,opt:5,acc:80,fall:6,ion:2.5,crit:4", has no entry in FAC_WTRAIT.hegemony (line 54), and is mounted on 4 of the 5 Hegemony hulls: h_interdictor (line 75), h_vanguard (line 76), h_dominion (line 77), and h_boss (line 78).

OBSERVED: ABILITIES.ionpulse (line 140, mounted on h_interdictor at line 75) reads "d:'Every enemy ship within 4 hexes loses half of each shield facing.',cd:3".

OBSERVED: WTRAITS.plasma (line 46, applied via FAC_WTRAIT.hegemony at line 54 to laser, turbo, and hturbo) reads "d:'a quarter burns through shields',f:w=>{ w.pierce=Math.max(w.pierce||0,.25); w.dmg+=1; }".

INFERRED: Against one-third of the factions in the game (chorus and deathless), ABILITIES.ionpulse does literally zero, W.ion loses its entire ion:2.5 payoff and drops to an under-statted 12-damage single shot (versus 20 damage on W.lance at line 7 or 24 total damage on W.pulsar at line 19), and WTRAITS.plasma loses its .25 shield pierce. INFERRED: Even against shielded targets, Hegemony's kit works against itself because W.ion and ABILITIES.ionpulse strip shields early, rendering WTRAITS.plasma's .25 shield pierce useless once shields fall.

Finding 2.3 [BLOCKER] [1. Weapons / 3. Modules & Perks] Battery Weapons Renamed "Plasma lance" and "Heavy plasma lance" Mislead Lance Module and Perk Selection

OBSERVED: W.turbo (line 11) and W.hturbo (line 12) both have weapon category "k:'battery'", while W.ion (line 13) has weapon category "k:'lance'".

OBSERVED: FAC_WNAMES.hegemony (line 36) renames turbo to "'Plasma lance'" and hturbo to "'Heavy plasma lance'".

OBSERVED: KIND_NAME (line 30) defines "battery:'Battery',lance:'Lance'", MODULES.crystal (line 161, renamed "'Ion focus lens'" in MOD_NAMES.hegemony at line 261) gives "Lance damage +25%" ("fx:{lancePct:.25}"), and PERKS.lanceadept (line 177) gives "Lance and torpedo damage +15%" ("fx:{lancePct:.15,torpPct:.15}").

INFERRED: A player selecting Lance perks or modules to buff "Plasma lance" and "Heavy plasma lance" actually buffs only Ion cannon (k:'lance'), whereas "Plasma lance" and "Heavy plasma lance" are secretly buffed by Battery loaders ("Pulse cyclers", k:'battery', lines 160, 261).

Finding 2.4 [BLOCKER] [2. Hulls] All Non-Voidsworn Hulls Lack cost and slots Properties in HULLS

OBSERVED: Every voidsworn hull in HULLS (warden through ascendant, lines 63 to 68) defines explicit "slots" (1 to 3) and "cost" (70 to 520) fields.

OBSERVED: None of the hegemony hulls in HULLS (h_picket through h_boss, lines 74 to 78), nor any corsair, chorus, ithar, or deathless hulls (lines 80 to 101), define "slots" or "cost" fields in data.js.

INFERRED: Unless another file outside pack.txt synthesizes fallback costs and module slots by class, non-Voidsworn playable ships cannot be priced in shipyards or equip modules cleanly from HULLS data.

Finding 2.5 [FIX] [2. Hulls / 3. Legacy & Modules] Hegemony Launch Ships Are Cruiser and Battleship Class, Breaking Carrier Class Hooks

OBSERVED: FACTIONS.hegemony.blurb (line 115) states "carriers launch fighter screens", and ADMIRALS.reyes.cmd (line 219) states "Every carrier launches an extra wing", while ADMIRALS.reyes.d (line 219) states "Squadrons deal +10% damage and cruisers hold +1 wing".

OBSERVED: Hegemony has no hull with cls:'Carrier'; instead, h_vanguard (line 76, "cls:'Cruiser',...,ab:'launch',hangar:1") and h_dominion (line 77, "n:'Dominion dreadnought',cls:'Battleship',...,ab:'launch',hangar:1") carry hangars.

OBSERVED: MOD_NEED (line 259) sets "hangar:'carrier'" whereas MODULES.hangar (line 165) sets "only:'launch'", and LEGACY.u_carrier (line 240) unlocks "Carrier hulls appear in shipyards".

OBSERVED: Furthermore, h_dominion (line 77) is named "'Dominion dreadnought'" while its class is "cls:'Battleship'".

INFERRED: Any code checking cls === 'Carrier' (such as LEGACY.u_carrier or MOD_NEED.hangar:'carrier') will fail to recognize Hegemony's hangar ships (h_vanguard and h_dominion), and calling h_dominion a dreadnought in its display name while typing it as a Battleship creates class confusion.

Finding 2.6 [FIX] [3. Admirals] Fleet Marshal Reyes and Commodore Vorn Have Strictly Dominated or Weakened Admiral Kits

OBSERVED: ADMIRALS.reyes (line 219, cost:45) grants "fx:{sqPct:.1,hangar:1,sqHp:.25}", whereas at the same cost:45, Voidsworn's ashgrove (line 207) grants "sqPct:.4" and Corsair's mott (line 223) grants "sqPct:.25" (and at cost:0, Chorus's matriarch line 225 and Ithar's aelith line 229 both grant "sqPct:.25").

OBSERVED: ADMIRALS.vorn (line 218, cost:30) uses "cmd:{id:'hunt',n:'Interdiction strike',d:'Every ship deals +30% damage this round.'}", whereas ADMIRALS.malek (line 213) and ADMIRALS.sable (line 222) use the same "id:'hunt'" to both reload all torpedoes AND grant +30% damage.

OBSERVED: No Hegemony hull mounts any 'torp' weapon (lines 74 to 78), yet MOD_NAMES.hegemony (line 261) defines "magazine:'Fusion magazine'" for MODULES.magazine (line 162, torpedo reload/damage).

INFERRED: Reyes's passive squadron bonus (+10%) is strictly weaker than every other carrier admiral in the game (+25% to +40%), Vorn gets only half of the 'hunt' command effect because Hegemony has no torpedoes, and 'Fusion magazine' is an unequipable dead module name for Hegemony.

Finding 2.7 [NOTE] [4. Lore compliance] Forbidden Star Wars Terms Remain in Internal Identifiers

OBSERVED: lore_bible_r8.md section 3.8 states: "Avoid: ... Interdictor, Star Destroyer, Commissar, Turbolaser".

OBSERVED: data.js retains internal keys W.turbo (line 11), W.hturbo (line 12), and HULLS.h_interdictor (line 75), and ADMIRALS.vorn uses "doc:'Interdiction'" and "n:'Interdiction strike'" (line 218).

INFERRED: While hull and weapon display names were changed, Vorn's visible doctrine and command strings still use "Interdiction".

========================================================================
3. ASHFALL HULLBREAKERS (id: corsair)

FACTION VERDICT: PASS WITH FIXES (0 BLOCKERS, 5 FIX, 2 NOTE)
(Note: Finding 2.4 regarding missing cost/slots on non-Voidsworn HULLS also applies to corsair at lines 80 to 84.)

Finding 3.1 [FIX] [1. Weapons / 5. Cross-faction] Corsair Accuracy Penalty and Rocket Evasion Multiplier Fail to Deliver the Bible's Anti-Glasswright Counter

OBSERVED: lore_bible_r8.md section 4.1 casts Hullbreakers as the Glasswrights' opposite, and section 4.7 states of Glasswrights: "Pretty little ships. They shatter well".

OBSERVED: FAC_WTRAIT.corsair (data.js line 55) applies WTRAITS.scrap (line 47: "w.shots+=1; w.acc-=12; w.crit=(w.crit||0)+3;") to autocannon, scatter, and turret, and applies WTRAITS.rockets (line 48: "w.shots*=3; w.dmg=Math.round(w.dmg/2.9); w.acc+=2; w.evMult=1.5; w.rockets=1;") to torp and htorp.

OBSERVED: Glasswright ships have the highest base evasion in HULLS (i_wisp ev:28 at line 92, i_blade ev:24 at line 93, i_song ev:16 at line 94) plus MOVE_RULES.ithar (line 110: "After moving 2+ hexes, enemies get −18 to hit it") and ADMIRALS.thorne (line 231: "+8 evasion for every ship").

INFERRED: Against an i_wisp (ev:28) that moved 2+ hexes (-18 to hit), Corsair rockets (base acc:64 + 2 = 66, evMult:1.5) suffer 28 * 1.5 = 42 evasion plus 18 vane penalty (leaving 6% accuracy before range/perks), and Scrap scatter guns (base acc:78 - 12 = 66, r:3, opt:2, fall:10) suffer 28 + 18 = 46 hit penalty. INFERRED: Rather than shattering Glasswrights, Corsair's -12 accuracy scrap guns and 1.5x evasion-multiplied rockets are mathematically hard-countered by Glasswright evasion and speed.

Finding 3.2 [FIX] [3. Admirals / 5. Cross-faction] Admiral Vesh Intrudes on Chorus/Eclipse Hull-Regeneration Identity and Strictly Dominates Their Regen Admirals

OBSERVED: ADMIRALS.vesh (data.js line 224, fac:'corsair', cost:80) has "d:'Ships patch 5% of their hull each round and have +10% armor.',fx:{hullRegenPct:.05,armor:.1},start:['c_hulk','c_reaver']" and "cmd:{id:'restore',n:'Patch and weld',d:'Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones.'}".

OBSERVED: Chorus's ADMIRALS.mending (line 227) and Eclipse's ADMIRALS.nekhet (line 233) both have only "fx:{hullRegenPct:.04}" (with no armor bonus) and the exact same "cmd.id:'restore'".

OBSERVED: ADMIRALS.vesh (line 224, cost:80, doc:'Scrap armor') has the exact same starting fleet ("start:['c_hulk','c_reaver']") as Corsair carrier admiral ADMIRALS.mott (line 223, cost:45, doc:'Junkyard carriers').

INFERRED: Giving a Corsair admiral 5% per-turn hull regeneration plus +10% armor out-regenerates the dedicated regeneration admirals of the two biological/self-repairing factions (chorus and deathless at 4%), while duplicating mott's carrier starting fleet.

Finding 3.3 [FIX] [1. Weapons / 3. Abilities] Promised Boarding Kit Is Missing From Corsair Weapons, Abilities, and Admiral Grax

OBSERVED: lore_bible_r8.md section 4.3 describes "boarding claws at the bow, chains between hull sections", section 4.5 specifies "rams and boarding. No lances", section 4.8 cites "chains running out as the boarding claws fire, and the pack's howl over open comms", and ADMIRALS.grax (data.js line 221) has "doc:'Ram and board'".

OBSERVED: In data.js, corsair has no boarding weapon (W.tendril at line 16 is exclusive to chorus at line 38), ABILITIES.overburn (line 141) buffs movement and ramming ("+3 movement now, and a ram this turn hits 50% harder") only on c_raider (line 80) and c_marauder (line 82), c_boss (line 84) has "ab:'launch'" instead of "ab:'overburn'", and ADMIRALS.grax (line 221) has "fx:{speed:1,dmgPct:.1}" and "cmd:{id:'surge',...}" with no ram or boarding bonus.

INFERRED: The boarding half of "Ram and board" does not exist in data.js for corsair, and neither Warlord Grax's passive/command nor the Warlord's Pyre-Barge (c_boss) has a ramming ability.

Finding 3.4 [FIX] [1. Weapons / 3. Modules] Dead Lance Module Rename ("Cracked lens array") Despite Bible's "No lances" Rule

OBSERVED: lore_bible_r8.md section 4.5 explicitly states "No lances", and no corsair hull in HULLS (lines 80 to 84) mounts a 'lance' weapon.

OBSERVED: MOD_NAMES.corsair (data.js line 262) defines "crystal:'Cracked lens array'" for MODULES.crystal ("Lance damage +25%", line 161, gated by MOD_NEED.crystal:'lance' at line 259).

INFERRED: MOD_NAMES.corsair.crystal is dead data because no Corsair ship mounts a lance.

Finding 3.5 [FIX] [2. Hulls] Corsair Carrier (c_hulk) Has More Hull and Armor Than Voidsworn and Glasswright Carriers

OBSERVED: lore_bible_r8.md section 4.5 describes Hullbreakers as "Fast, thin shields", while section 2.5 describes Sunward Crusade as "heavy armor".

OBSERVED: HULLS.c_hulk (line 83) has "hp:170,sh:16,rg:6,ar:.2", whereas Voidsworn's reliquary (line 66) has "hp:130,sh:22,rg:9,ar:.15".

INFERRED: c_hulk is tougher in both hull (170 vs 130) and armor (.20 vs .15) than the heavy-armor faction's carrier.

Finding 3.6 [NOTE] [1. Weapons / 2. Hulls] c_reaver Has an Asymmetric Starboard-Only Scatter Gun Mount

OBSERVED: HULLS.c_reaver (data.js line 81) mounts "w:[['torp','F'],['scatter','S']]" with no port ('P') weapon.

INFERRED: Unlike every other broadside ship in data.js (which pairs 'P' and 'S'), c_reaver can only fire its scatter cannon to starboard; this fits lore_bible_r8.md section 4.3 ("Lopsided") if intentional, but should be verified so players are not surprised by a dead port arc.

Finding 3.7 [NOTE] [3. Ranks] No Faction Rank Table for Hullbreaker Ranks

OBSERVED: lore_bible_r8.md section 4.10 specifies Hullbreaker ranks "Claw, Fang, Howler, Ripper, Warlord", whereas data.js line 185 defines only one global RANKS array ("['Lieutenant','Commander','Captain','Commodore','Fleet captain']").

INFERRED: Hullbreaker captains use human naval ranks unless overridden outside data.js.

========================================================================
4. THE CHORUS (id: chorus)

FACTION VERDICT: FAIL (3 BLOCKERS, 3 FIX, 2 NOTE)
(Note: Finding 2.4 regarding missing cost/slots on non-Voidsworn HULLS also applies to chorus at lines 86 to 90.)

Finding 4.1 [BLOCKER] [4. Rulings compliance] Approved Chorus Repair Prohibition Is Missing From data.js, and Chorus Has Post-Battle Repair Relics

OBSERVED: price_ladder_synthesis.md (Headline and Agreements) states "the approved Ithar Brace and Chorus repair prohibitions" and "Chorus no shipyard repair (approved, NEEDS CODE, scope across shipyard, Drydock, and Field repairs OPUS TO CONFIRM) in all three drafts".

OBSERVED: Neither FACTIONS.chorus (data.js lines 120 to 122) nor chorus hulls in HULLS (lines 86 to 90) contain any repair-prohibition flag.

OBSERVED: RELIC_NAMES.chorus (line 269) explicitly renames RELICS.salvage (line 197: "d:'After each battle, gain 15 credits and repair 8% hull.',run:{salvage:1}") to "'Scavenger gut'".

INFERRED: The Chorus repair prohibition is not represented in data.js, and giving Chorus a faction rename for the post-battle hull-repair relic contradicts a no-repair rule if field/post-battle repairs are included in scope.

Finding 4.2 [BLOCKER] [3. Modules, perks, relics] Five of Thirteen Chorus Modules ("Membrane bloom", "Membrane regrowth", "Spine glands", "Venom lens", "Spore bladders") Plus Shield/Broadside/Lance Perks and Relics Are Completely Non-Functional on Chorus

OBSERVED: Every Chorus hull in HULLS (b_drone, b_spitter, b_razor, b_brood, b_boss, lines 86 to 90) has "sh:0,rg:0", mounts only 'T' and 'F' weapon arcs (zero 'P' or 'S' arcs), and mounts only weapons with k:'bio' (tendril line 16, bioplasma line 17) and k:'flak' (spores line 18), plus k:'sq' (sporeb line 27 on spore squadrons).

OBSERVED: MOD_NEED (line 259) sets "{loaders:'batt',crystal:'lance',magazine:'torp',flakplus:'flak',capacitor:'shields',regen:'shields',hangar:'carrier'}".

OBSERVED: MOD_NAMES.chorus (line 263) defines:

"capacitor:'Membrane bloom'" (MODULES.capacitor, line 158: "+30% shield strength", gated by shields; Chorus has sh:0).

"regen:'Membrane regrowth'" (MODULES.regen, line 159: "+50% shield regeneration", gated by shields; Chorus has rg:0).

"loaders:'Spine glands'" (MODULES.loaders, line 160: "Battery weapons fire +1 shot", fx:{battShots:1}, gated by MOD_NEED.loaders:'batt'; Chorus has zero k:'battery' weapons because bioplasma / 'Spine volley' has k:'bio' at line 17).

"crystal:'Venom lens'" (MODULES.crystal, line 161: "Lance damage +25%", gated by MOD_NEED.crystal:'lance'; Chorus has zero k:'lance' weapons).

"magazine:'Spore bladders'" (MODULES.magazine, line 162: "Torpedo reload time −1 turn, +15% torpedo damage", gated by MOD_NEED.magazine:'torp'; Chorus has zero k:'torp' weapons).

OBSERVED: RELIC_NAMES.chorus (line 269) defines "lattice:'Swallowed shield cells'" for RELICS.lattice (line 191: "Shields +15% across the fleet", fx:{shPct:.15}), which gives +15% of 0 shields on Chorus.

OBSERVED: PERKS.deflector (line 172, "+40% shield regeneration"), PERKS.broad (line 176, "Broadside weapons +15% damage"), and PERKS.lanceadept (line 177, "Lance and torpedo damage +15%") have zero valid targets across the entire Chorus faction.

INFERRED: Because Chorus weapons use k:'bio' instead of k:'battery'/'lance'/'torp' and Chorus ships have sh:0 and no 'P'/'S' mounts, 5 of the 13 modules in MOD_NAMES.chorus (including "Spine glands", obviously intended to buff "Spine volley"), 1 Chorus-renamed relic ("Swallowed shield cells"), and 3 captain perks are completely dead or unequipable on Chorus.

Finding 4.3 [BLOCKER] [1. Weapons / 5. Cross-faction] Chorus Weapons Pay for Shield Pierce That Is Dead Against Primary Lore Target Eclipse, and Weapon Traits Swap Acid and Spines Against Bible Names

OBSERVED: lore_bible_r8.md sections 5.1 and 5.4 state that the Chorus was grown specifically to destroy Eclipse ("finish the war it was grown for: Eclipse").

OBSERVED: W.tendril (line 16) has "pierce:.5", W.bioplasma (line 17) has "pierce:.2", and W.sporeb (line 27) has "pierce:.6" (shield pierce), while every Eclipse hull (lines 98 to 101) has "sh:0" and high armor ("ar:.2" to "ar:.35").

OBSERVED: In data.js, W.bioplasma (base name "'Bile spray'" at line 17) is renamed "'Spine volley'" in FAC_WNAMES.chorus (line 38) and given trait "'spines'" (line 55), whereas W.tendril ("'Boarding tendrils'", range 1, line 16) is given trait "'acid'" (line 55).

OBSERVED: Meanwhile, Eclipse's MOVE_RULES.deathless (line 111, "over:0", passes through enemy ships at no extra cost) bypasses Chorus range-1 melee blockers, and Eclipse's WTRAITS.gauss (line 53, "armorPierce:.5") ignores half of Chorus's armor.

INFERRED: Chorus's shield-pierce budget on tendril, bioplasma, and sporeb is completely wasted against shieldless Eclipse, non-carrier Chorus ships have no ranged acid weapon because acid was placed on range-1 Boarding tendrils while Bile spray was renamed Spine volley, and Eclipse's kit counters Chorus rather than Chorus countering Eclipse.

Finding 4.4 [FIX] [2. Hulls] Frigate (b_drone) Has Only a Range-1 Weapon at Speed 5 With No Mobility Ability, and Cruiser (b_razor) Has Less Ranged Firepower Than Destroyer (b_spitter)

OBSERVED: HULLS.b_drone (line 86, cp:1) has "sp:5", "w:[['tendril','T']]" (where W.tendril at line 16 has "r:1,opt:1"), and "ab:'regrow'".

OBSERVED: HULLS.b_spitter (line 87, Destroyer, cp:2) mounts two range-4 bioplasma weapons ("w:[['bioplasma','T'],['bioplasma','F']]"), whereas HULLS.b_razor (line 88, Cruiser, cp:3) mounts only one prow-locked range-4 bioplasma and one range-1 tendril ("w:[['tendril','T'],['bioplasma','F']]").

INFERRED: At sp:5 with no gap-closing ability, b_drone is slower than or equal in speed to opposing frigates/destroyers (c_raider sp:6, i_wisp sp:7, i_blade sp:6, warden sp:5, h_picket sp:5) and deals zero damage unless adjacent; meanwhile, the 3-CP Cruiser b_razor has half the ranged firepower of the 2-CP Destroyer b_spitter at ranges 2 to 4.

Finding 4.5 [FIX] [3. Abilities / Admirals] ABILITIES.frenzy Duplicates ABILITIES.focus and Collides in Name With Razormaw's Command

OBSERVED: ABILITIES.frenzy (line 142, on b_razor at line 88) has "n:'Blood frenzy',d:'All of this ship’s weapons deal +30% damage this turn.',cd:3", which is identical in effect and cooldown to Voidsworn's ABILITIES.focus (line 135).

OBSERVED: ADMIRALS.razormaw.cmd (line 226) is also named "n:'Blood frenzy'", but uses "id:'surge'" with a completely different effect ("d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'").

INFERRED: Using the exact name "Blood frenzy" for both b_razor's +30% damage ship ability and Razormaw's movement/evasion fleet command in the same faction is confusing, especially since Razormaw starts with b_razor ("start:['b_razor','b_spitter','b_drone']", line 226).

Finding 4.6 [FIX] [3. Modules & Relics] Generic Module damcon and Relic spore Give Every Faction Chorus's Hull-Regeneration Identity

OBSERVED: MODULES.damcon (line 164, cost:85) grants "fx:{hullRegenPct:.04}", which is the exact same 4% per-turn hull regeneration passive as Chorus Admiral ADMIRALS.mending (line 227, "fx:{hullRegenPct:.04}").

OBSERVED: RELICS.spore (line 192) grants "Every ship regenerates 3 hull per turn" ("fx:{hullRegen:3}") across any fleet.

INFERRED: Any ship in any faction can buy a single 85-credit module to match The Mending Throng's entire admiral passive.

Finding 4.7 [NOTE] [3. Admirals] Four of Five Carrier Admirals Omit sqHp:.25 From Their Description Text

OBSERVED: ADMIRALS.matriarch (line 225, along with ashgrove line 207, reyes line 219, mott line 223, and aelith line 229) has "fx:{sqPct:.25,hangar:1,sqHp:.25}", but its description string "d:'Spore swarms deal +25% damage and broods hold +1 swarm.'" omits the +25% squadron HP bonus.

INFERRED: Players cannot see the +25% squadron HP bonus in the UI text for any of the five carrier admirals.

Finding 4.8 [NOTE] [3. Ranks] No Faction Rank Table for Chorus Ranks

OBSERVED: lore_bible_r8.md section 5.10 specifies Chorus ranks "Spawn-mind, Node, Throat, Elder throat, Great throat", which are absent from RANKS (data.js line 185).

INFERRED: Chorus nodes use human naval officer ranks unless overridden outside data.js.

========================================================================
5. THE GLASSWRIGHTS (id: ithar)

FACTION VERDICT: FAIL (2 BLOCKERS, 4 FIX, 2 NOTE)
(Note: Finding 2.4 regarding missing cost/slots on non-Voidsworn HULLS also applies to ithar at lines 92 to 96.)

Finding 5.1 [BLOCKER] [4. Rulings compliance / 3. Orders, perks, admirals] Approved Glasswright Brace Prohibition Is Missing From data.js, and Admiral Brin's Command Grants Fleet-Wide Brace Damage Reduction

OBSERVED: price_ladder_synthesis.md (Agreements) states "Ithar cannot Brace (approved, NEEDS CODE boolean in canOrder)" and lore_bible_r8.md section 6.5 states "Blindingly fast, heavily shielded, fragile once the shields fall. They cannot brace".

OBSERVED: Neither FACTIONS.ithar (data.js lines 123 to 125), nor ORDERS.brace (line 149), nor ithar hulls in HULLS (lines 92 to 96) contain any flag prohibiting Brace.

OBSERVED: PERKS.stubborn (line 178: "d:'Brace for impact blocks an extra 15%.',fx:{bracePlus:.15}") is not excluded for ithar in data.js.

OBSERVED: ADMIRALS.mirelle (line 232, Brin of the Fourth Lens) has "cmd:{id:'iron',n:'Prism ward',d:'All shields refill and your ships take 40% less hull damage this round.'}", granting the exact "-40%" hull damage reduction of ORDERS.brace (line 149) across the entire Glasswright fleet.

INFERRED: data.js contains no Brace prohibition flag for ithar, leaves PERKS.stubborn as a trap perk if Brace is blocked in battle code, and undercuts the "fragile once the shields fall / cannot brace" identity via Admiral Brin's -40% hull damage command.

Finding 5.2 [BLOCKER] [1. Weapons / 2. Hulls / 3. Modules] Zero Playable Glasswright Hulls Mount Point Defense ("Mirror veil"), Making "Shard screen" (MODULES.flakplus) Unequipable Across the Entire Roster

OBSERVED: FAC_WNAMES.ithar (data.js line 39) defines "flak:'Mirror veil'" and MOD_NAMES.ithar (line 264) defines "flakplus:'Shard screen'" for MODULES.flakplus (line 163, gated by MOD_NEED.flakplus:'flak' at line 259).

OBSERVED: In HULLS (lines 92 to 96), none of the four playable hulls in FACTIONS.ithar.roster (i_wisp line 92, i_blade line 93, i_song line 94, i_carrier line 95) mount 'flak'; only the non-playable boss hull i_boss (line 96, "boss:true") mounts "['flak','T']".

INFERRED: Playable Glasswright fleets never field their named point-defense weapon ("Mirror veil"), can never equip their named point-defense module ("Shard screen"), and have zero turret point defense against Corsair rockets or enemy bomber/spore squadrons.

Finding 5.3 [FIX] [2. Hulls] "Heavily Shielded" Glasswright Destroyer, Cruiser, and Boss Have Equal or Lower Shields Than Hegemony Counterparts

OBSERVED: lore_bible_r8.md section 6.5 and FACTIONS.ithar.blurb (data.js line 124) define Glasswrights as "heavily shielded, fragile once the shields fall".

OBSERVED: HULLS.i_blade (line 93, Destroyer) has "hp:60,sh:16,rg:8,ar:0", whereas Hegemony's h_interdictor (line 75, Destroyer) has "hp:74,sh:18,rg:7,ar:.15" (2 more shield, 14 more HP, and 15% more armor).

OBSERVED: HULLS.i_boss (line 96, The Unfinished) has "hp:470,sh:34,rg:14,ar:.2", whereas Hegemony's h_boss (line 78, The Iron Mandate) has "hp:560,sh:40,rg:10,ar:.3" (6 more shield, 90 more HP, and 10% more armor).

INFERRED: Hegemony out-shields the "heavily shielded" Glasswrights at both Destroyer and Flagship tiers while also having far higher hull and armor.

Finding 5.4 [FIX] [1. Weapons / 3. Modules] "Needle beam" Is Typed as a Battery Weapon, and Prism Lance / Star Torpedo Shield Pierce Is Dead Against Chorus and Eclipse

OBSERVED: FAC_WNAMES.ithar (line 39) renames W.turret (line 9, "k:'battery'") to "'Needle beam'".

OBSERVED: W.pulsar ('Prism lance', line 19) has "pierce:.6" and no faction trait in FAC_WTRAIT.ithar (line 56), and W.startorp ('Star torpedo', line 20) has "dmg:38,r:5,opt:5,acc:66,fall:0,pierce:.4" (4 less damage and 1 hex shorter range than standard W.torp at line 8).

INFERRED: Players cannot tell from the name "'Needle beam'" that it is a 'battery' weapon buffed by "'Shard hoppers'" (MODULES.loaders, line 264) rather than "'Starlight focus'" (MODULES.crystal, line 264); additionally, against unshielded chorus and deathless (Glasswrights' primary sibling enemy in lore_bible_r8.md sections 6.1 and 6.4), the .6 shield pierce on Prism lance and .4 shield pierce on Star torpedo are completely dead.

Finding 5.5 [FIX] [3. Perks] PERKS.broad ("Broadside specialist") Is Completely Dead on Glasswrights

OBSERVED: None of the Glasswright hulls in HULLS (i_wisp, i_blade, i_song, i_carrier, i_boss, lines 92 to 96) mount any 'P' or 'S' broadside weapon (all weapons are 'F' or 'T').

INFERRED: PERKS.broad (line 176, "Broadside weapons +15% damage") does nothing on any Glasswright ship.

Finding 5.6 [FIX] [3. Relics] RELIC_NAMES.ithar Omits Four Relics, Exposing Voidsworn/Default Names

OBSERVED: RELIC_NAMES.ithar (line 270) defines only 8 of the 12 keys in RELICS (lines 189 to 200), omitting compass ("Founders’ compass"), salvage ("Scrap rig"), spore ("Tamed spore culture"), and phylactery ("Eclipse backup frame").

INFERRED: Glasswright fleets acquiring compass or salvage receive Sunward Crusade or Corsair-flavored default names.

Finding 5.7 [NOTE] [4. Lore compliance] Forbidden "song" Motif Appears in Cruiser Hull ID i_song

OBSERVED: lore_bible_r8.md section 6.2 states "No faction sings", yet HULLS line 94, FACTIONS.ithar.roster line 125, and ADMIRALS lines 230 and 232 use the hull key "i_song" (and lines 229 to 232 retain old elvish keys aelith, vaelen, thorne, mirelle).

INFERRED: While display names were updated, internal IDs retain pre-round-8 naming.

Finding 5.8 [NOTE] [3. Ranks] No Faction Rank Table for Glasswright Ranks

OBSERVED: lore_bible_r8.md section 6.10 specifies Glasswright ranks "Glimmer, Glint, Facet, Mirror, Lens-keeper", which are absent from RANKS (data.js line 185).

INFERRED: Glasswright captains use human naval ranks unless overridden outside data.js.

========================================================================
6. ECLIPSE (id: deathless)

FACTION VERDICT: FAIL (4 BLOCKERS, 3 FIX, 1 NOTE)
(Note: Finding 2.4 regarding missing cost/slots on non-Voidsworn HULLS also applies to deathless at lines 98 to 101.)

Finding 6.1 [BLOCKER] [4. Rulings compliance / 3. Modules & Admirals] Eclipse Fields No Shields (sh:0), But Admiral Seveth's Command Refills Shields and Five Eclipse-Named Modules Are Dead or Unequipable

OBSERVED: price_ladder_synthesis.md (Headline and Agreements) confirms "Deathless no-shield is correctly an OBSERVED roster fact", lore_bible_r8.md section 7.5 states "No shields, heavy armour", and every deathless hull in HULLS (d_scythe, d_jackal, d_harvester, d_boss, lines 98 to 101) has "sh:0,rg:0".

OBSERVED: ADMIRALS.khepra (line 236, Seveth, Twice-Restored) has "cmd:{id:'iron',n:'Sunshade wall',d:'All shields refill and your ships take 40% less hull damage this round.'}".

OBSERVED: Eclipse hulls mount only weapons with k:'gauss' (gauss line 21), k:'lance' (doom line 23), and k:'flak' (gsentry line 22, flak line 4), and FACTIONS.deathless (line 128) has "roster:['d_scythe','d_jackal','d_harvester']" and "sq:null" with zero carriers or torpedoes.

OBSERVED: MOD_NEED (line 259) gates capacitor and regen on 'shields', loaders on 'batt', magazine on 'torp', and hangar on 'carrier'.

OBSERVED: Despite this, MOD_NAMES.deathless (line 265) defines:

"capacitor:'Corona-ward node'" (MODULES.capacitor, line 158: "+30% shield strength"; Eclipse has sh:0).

"regen:'Corona-ward regenerator'" (MODULES.regen, line 159: "+50% shield regeneration"; Eclipse has rg:0).

"loaders:'Null accelerators'" (MODULES.loaders, line 160: "Battery weapons fire +1 shot", gated by MOD_NEED.loaders:'batt'; Eclipse has zero k:'battery' weapons because W.gauss / 'Null cannon' has k:'gauss' at line 21).

"magazine:'Arc capacitors'" (MODULES.magazine, line 162: "Torpedo reload time −1 turn, +15% torpedo damage", gated by MOD_NEED.magazine:'torp'; Eclipse has zero k:'torp' weapons because W.doom / 'Corona arc' has k:'lance' at line 23).

"hangar:'Drone bay'" (MODULES.hangar, line 165: "Carriers only: +1 squadron in flight", gated by only:'launch' and MOD_NEED.hangar:'carrier'; Eclipse has zero carriers and sq:null).

INFERRED: Half of Admiral Seveth's command ("All shields refill") is dead on a shieldless faction, and 5 out of 13 modules in MOD_NAMES.deathless (including "Null accelerators" for Null cannon and "Arc capacitors" for Corona arc, plus "Corona-ward node" and "Drone bay" which are even listed in lore_bible_r8.md section 7.10) do not function on any Eclipse ship because of weapon kind and shield/carrier gates.

Finding 6.2 [BLOCKER] [4. Lore compliance] FACTIONS.deathless Still Uses Forbidden Necron Green Colours and 'tomb' Style

OBSERVED: lore_bible_r8.md section 7.2 states: "Avoid every Necron tell: tomb, dynasty, overlord, cryptek, necropolis, living metal, gauss, doom, scarab, canoptek, monolith, phylactery, reanimation protocols, crowns, thrones, Egyptian names, green glow".

OBSERVED: lore_bible_r8.md section 7.3 states: "Colours: dark violet-black plates, a white-gold eclipse corona, violet-white inner glow".

OBSERVED: FACTIONS.deathless (data.js line 126) is set to "hull:'#1d2220',trim:'#1fbf4a',glow:'#3dff6a',style:'tomb'".

OBSERVED: data.js also retains internal keys and comments: "// ---- The Deathless Dynasty" (line 97), "gauss" (lines 21, 30, 53, 56), "doom" (line 23), "cls:'Tomb-ark'" (line 101), "reanimate:true" (lines 98 to 100), "phylactery" (lines 193, 271), and Egyptian deity admiral keys "nekhet", "sekhmar", "anuket", "khepra" (lines 233 to 236).

INFERRED: While internal keys are invisible to players, FACTIONS.deathless.trim ('#1fbf4a'), glow ('#3dff6a'), and style ('tomb') at line 126 directly render Eclipse in bright Necron green and tomb styling in violation of round 8 of the bible.

Finding 6.3 [BLOCKER] [2. Hulls / 3. Legacy] Eclipse Roster Has Only Three Playable Hulls (No Carrier, No Battleship, No Dreadnought), Making All Three Shipyard Legacy Upgrades Dead

OBSERVED: FACTIONS.deathless.roster (line 128) contains only three hulls: "['d_scythe','d_jackal','d_harvester']" (Frigate cp:1, Destroyer cp:2, Cruiser cp:4, lines 98 to 100), whereas every other faction has 4 or 5 hulls in roster.

OBSERVED: LEGACY (lines 240 to 242) defines only three Shipyards upgrades: u_carrier ("Carrier hulls appear in shipyards", cost:30), u_battleship ("Battleship-class hulls appear in shipyards", cost:60), and u_dread ("Sunward Crusade fleets may take one Daybreak-class dreadnought", cost:120).

INFERRED: An Eclipse player gets zero benefit from the entire 'Shipyards' legacy upgrade group (u_carrier, u_battleship, u_dread) and has no heavy line hull above Cruiser (4 CP).

Finding 6.4 [BLOCKER] [5. Cross-faction / 2. Hulls / 3. Admirals] Eclipse's Passive Hull Regeneration Blurs Directly Into Chorus's Identity

OBSERVED: lore_bible_r8.md section 5.5 defines Chorus as "No shields at all; flesh regrows every round", whereas section 7.5 defines Eclipse as "No shields, heavy armour, and the fallen come back: repair swarms rebuild each hull once while its crew's minds re-stream from their last Archive backup".

OBSERVED: In HULLS (lines 98 to 101), every Eclipse hull has passive per-turn regeneration ("regen:3" on d_scythe and d_jackal, "regen:4" on d_harvester, "regen:8" on d_boss) alongside "sh:0,rg:0", just like Chorus hulls ("regen:4" to "regen:20" with "sh:0,rg:0", lines 86 to 90).

OBSERVED: Eclipse's starting cost:0 admiral ADMIRALS.nekhet (line 233, Nadir Aurex, Ninth Frame) has "d:'Ships regrow 4% of their hull each round.',fx:{hullRegenPct:.04}" (using the biological word "regrow") and "cmd:{id:'restore',...}", which is mechanically 100% identical to Chorus's ADMIRALS.mending (line 227).

INFERRED: Giving Eclipse passive per-turn hull regen on every hull plus an identical "regrow 4% / restore 25%" admiral makes Eclipse play as a second unshielded regenerating faction rather than differentiating Chorus (continuous biological regrowth) from Eclipse (heavy armor + one-time backup reanimation).

Finding 6.5 [FIX] [1. Weapons / 5. Cross-faction] Null Cannon and Corona Arc Armor-Piercing Trait Is Near-Dead Against Glasswrights, and Shield Pierce Diverges From Bible 7.5

OBSERVED: lore_bible_r8.md section 7.5 states "Null weapons ignore half of armour; the Corona arc lands one heavy blow every other turn", whereas FACTIONS.deathless.blurb (line 127) says "Null weapons cut through shields and armor".

OBSERVED: W.gauss (line 21) and W.doom (line 23) both have "pierce:0.6" (shield pierce) and receive WTRAITS.gauss (line 53, "armorPierce:.5", ignores half of armor) via FAC_WTRAIT.deathless (line 56).

OBSERVED: Glasswright playable hulls (lines 92 to 95) have "ar:0" on i_wisp and i_blade and "ar:.05" on i_song and i_carrier.

INFERRED: Against Eclipse's primary sibling rivals, the Glasswrights, WTRAITS.gauss ("ignores half of armor") does zero against i_wisp and i_blade (ar:0) and only 2.5% against i_song and i_carrier (ar:.05), while against Chorus (sh:0), the .6 shield pierce on gauss and doom is completely dead.

Finding 6.6 [FIX] [1. Weapons] W.gsentry and W.flak Are Duplicate Weapon Entries on d_harvester and d_boss

OBSERVED: W.gsentry (line 22: "shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6") has the exact same stats as W.flak (line 4: "shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6").

OBSERVED: FAC_WNAMES.deathless (line 40) names gsentry "'Null spire'" (mounted on d_harvester, line 100) and flak "'Null shredder'" (mounted on d_boss, line 101).

INFERRED: gsentry is a redundant duplicate of flak in W with a different name on the cruiser versus the flagship.

Finding 6.7 [FIX] [3. Abilities / Perks] Fold Skip Duplicates Evasive Burn, Spinal Cannon Duplicates Human Boss Ability, and Shield/Broadside/Wing Perks Are Dead on Eclipse

OBSERVED: ABILITIES.phase (line 145, on d_scythe and d_jackal, lines 98 and 99) has the exact same text and cooldown as ABILITIES.evasive (line 133: "+25 evasion until your next turn and +2 movement now.", cd:3), and d_boss (line 101) uses "ab:'nova'" ("Spinal shell: 40 damage...", line 138) identical to ascendant and h_boss.

OBSERVED: Because Eclipse hulls have sh:0, no 'P'/'S' broadside arcs, and no squadrons (lines 98 to 101, 128), PERKS.deflector (line 172), PERKS.broad (line 176), and PERKS.wing (line 180) are 100% dead on Eclipse captains.

INFERRED: Eclipse frigates/destroyers and flagship lack distinct active abilities, and three of the fourteen captain perks in PERKS are dead draws for Eclipse.

Finding 6.8 [NOTE] [3. Ranks] No Faction Rank Table for Eclipse Ranks

OBSERVED: lore_bible_r8.md section 7.10 specifies Eclipse ranks "Shade, Gloam, Umbra, Midnight, Nadir", which are absent from RANKS (data.js line 185).

INFERRED: Eclipse officers use human naval ranks unless overridden outside data.js.

========================================================================
CROSS-FACTION SUMMARY (AUDIT ITEMS 3, 4, AND 5)

A. Rulings Compliance Summary (Prompt Item 4)

Hegemony synchronized fire primary, pinning secondary, ion as weapon flavor only, flagship-anchor loss (price_ladder_synthesis.md; OPUS_HANDOFF.md section 1): BREACHED in data.js (Finding 2.1). Synchronized fire and flagship-anchor formation do not exist at the faction level in data.js; pinning does not exist on Vorn or h_interdictor; ion weapons and ionpulse remain central to Hegemony's hulls and blurb (lines 75 to 78, 115, 140).

Chorus gets no repair (price_ladder_synthesis.md): BREACHED in data.js (Finding 4.1). No repair-prohibition property exists on FACTIONS.chorus (lines 120 to 122), and Chorus has a named post-battle repair relic ('Scavenger gut', line 269).

Glasswrights get no Brace (price_ladder_synthesis.md; lore_bible_r8.md 6.5): BREACHED in data.js (Finding 5.1). No Brace prohibition property exists on FACTIONS.ithar (lines 123 to 125) or ORDERS.brace (line 149), PERKS.stubborn (line 178) is not gated, and Admiral Brin's 'iron' command (line 232) grants -40% hull damage fleet-wide.

Eclipse fields no shields (price_ladder_synthesis.md; lore_bible_r8.md 7.5): COMPLIANT on HULLS (all deathless hulls have sh:0,rg:0 at lines 98 to 101), but BREACHED in supporting kit (Finding 6.1: Admiral Seveth's command at line 236 refills shields, and MOD_NAMES.deathless at line 265 names shield capacitor and shield regenerator modules).

Voidsworn carrier gate (price_ladder_synthesis.md): CONTRADICTED by lore_bible_r8.md 2.7/2.11 and data.js lines 66, 113, 207, 214 (Finding 1.1).

B. Duplicated or Strictly Dominated Entries Across Factions (Prompt Item 3)

Duplicate ship abilities: ABILITIES.evasive (line 133) and ABILITIES.phase (line 145) are identical; ABILITIES.focus (line 135) and ABILITIES.frenzy (line 142) are identical.

Duplicate weapons: W.flak (line 4) and W.gsentry (line 22) have identical stats.

Duplicate admiral commands: All 24 admirals (lines 212 to 236) share just 6 command IDs (barrage, hunt, scramble, iron, surge, restore), with cmd.id:'surge' colliding with ABILITIES.surge's key name (line 137) and ADMIRALS.razormaw.cmd ('Blood frenzy', line 226) colliding with ABILITIES.frenzy's display name (line 142).

Strictly dominated admirals:

Hull regen: Corsair's vesh (line 224, fx:{hullRegenPct:.05,armor:.1}, cmd:'restore') strictly dominates the passive of Chorus's mending (line 227, fx:{hullRegenPct:.04}, cmd:'restore') and Eclipse's nekhet (line 233, fx:{hullRegenPct:.04}, cmd:'restore').

Carrier: At cost:45, Hegemony's reyes (line 219, sqPct:.1) is strictly weaker in squadron damage than Voidsworn's ashgrove (line 207, sqPct:.4) and Corsair's mott (line 223, sqPct:.25), and weaker than cost:0 matriarch (line 225, sqPct:.25) and cost:0 aelith (line 229, sqPct:.25).

Tank: At cost:80, Eclipse's khepra (line 236, cmd:'iron') gets a half-dead command ('All shields refill') compared to Voidsworn's thale (line 208/215) and Hegemony's maren (line 220).

Hunter: At cost:30/45, Hegemony's vorn (line 218, cmd:'hunt') and Eclipse's anuket (line 235, cmd:'hunt') get only +30% damage from 'hunt', whereas Voidsworn's malek (line 213) and Corsair's sable (line 222) get instant torpedo reload plus +30% damage from the same command ID.

Non-Voidsworn Legacy dead-ends: LEGACY.u_battleship (line 241) is dead for 4 of 6 factions (corsair, chorus, ithar, deathless have no cls:'Battleship' hull in roster), and LEGACY.u_carrier (line 240) is dead for deathless and hegemony (whose hangar hulls are Cruiser and Battleship class).

C. Cross-Faction Identity Blurs and Unfulfilled Counter Relationships (Prompt Item 5)

Chorus vs Eclipse identity blur: Both play as zero-shield (sh:0) rosters with passive per-turn hull regeneration on every hull (lines 86 to 90, 98 to 101) and identical 4% hull-regen / 25% restore admirals (mending line 227, nekhet line 233).

Voidsworn vs Hegemony line blur: In data.js (without Hegemony's flagship-sync rule), both share evasive frigates, nova dreadnoughts, identical +15% hull / +10% shield 'iron' admirals (thale and maren), and barrage/scramble admirals.

Voidsworn Malek vs Corsair Sable blur: Both admirals (lines 206, 222) cost 30, grant rearPct:.5, start with 2 reload-torpedo destroyers + 2 frigates, and fire the exact same 'hunt' command.

Unfulfilled counters:

Chorus vs Eclipse (Bible 5.1/5.4 promises Chorus was grown to eat Eclipse): Chorus weapons waste budget on shield pierce (.2 to .6, lines 16, 17, 27) against sh:0 Eclipse, while Eclipse ignores half of Chorus's armor (WTRAITS.gauss, line 53) and slips past Chorus range-1 drones (MOVE_RULES.deathless, line 111).

Hullbreakers vs Glasswrights (Bible 4.1/4.7 promises Hullbreakers shatter Glasswrights): Corsair's -12 accuracy scrap guns and 1.5x evasion-multiplied rockets (lines 47, 48) are mathematically countered by Glasswright high evasion and -18 Crystal vanes hit penalty (lines 92 to 94, 110).

Hegemony vs Chorus/Eclipse: Hegemony's ion cannon (line 13), ionpulse (line 140), and plasma shield-pierce trait (line 46) collapse against both sh:0 factions.

========================================================================
NOT CHECKED

The following items could not be verified from pack.txt because their code or data lies outside the excerpted files (data.js lines 1 to 275, lore_bible_r8.md lines 131 to 518, price_ladder_synthesis.md excerpt, and OPUS_HANDOFF.md section 1 excerpt):

data.js from line 275 onward (EVENTS definitions, shipyard generation, module eligibility filtering using MOD_NEED, and whether captain/ship name or rank tables exist for non-Voidsworn factions below line 275).

battle.js and campaign/UI scripts:

Whether Glasswrights (ithar) are blocked from using ORDERS.brace in canOrder() inside battle.js.

Whether Chorus (chorus) is blocked from shipyard, drydock, or field repairs in campaign/shop code.

Whether Hegemony synchronized fire and flagship-anchor loss are hardcoded in battle.js outside data.js.

How battle.js resolves W.ion's "ion:2.5" property, WTRAITS.rockets point-defense interception ("w.rockets=1"), WTRAITS.spines armor shred stacking ("w.shred=.03"), WTRAITS.acid damage-over-time ("w.acid=1"), and "reanimate:true" on deathless hulls.

How FACTIONS.voidsworn resolves squadron launches from reliquary when FACTIONS.voidsworn.sq is undefined (line 113).

Whether non-Voidsworn hull costs and module slot counts (missing from HULLS lines 74 to 101) are computed dynamically by class or CP in another file.

Nemesis behaviors promised in lore_bible_r8.md (sections 2.7, 3.5, 4.5, 5.5, 6.5, 7.5) and balance win-rate telemetry referenced in data.js line 203 (port_notes.md and bossmatrix).
