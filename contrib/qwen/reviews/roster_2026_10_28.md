# HULL ROSTER IDENTITY AUDIT - BLIND REVIEW

## 1 · PROOF OF READING

Sections read: EVIDENCE PACK title line (main 264f441d); THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE (six numbered criteria); data.js 61-135: HULLS and FACTIONS (all six faction blocks, three squadrons, MOVE_RULES, FACTIONS table, SECTOR_POOL, partial ABILITIES); data.js 545-580: hull variants (12 renown variants, 6 arc variants, FIT_SLOTS schema, variant-injection loop, FAC_WPOOL).

Overall verdict: DUPLICATES WITH PAINT.

Five of six factions field a carrier whose boss hull shares the same ability and hangar count, and two factions field two launch-carriers in the same ladder; the fiction names change but the decision the player makes does not.

## 2 · FINDINGS (most severe first)

### F-1 · [BLOCKER] - Roster counts contradict the commissioner's premise and the chair census

READ. The commissioner states "five per faction in the base roster." The census echoes "each faction's five-ship ladder (frigate to dreadnought)." The code disagrees: voidsworn roster has 5 entries; hegemony, corsair, chorus, and ithar each have 4; deathless has 3. The deathless are missing a Carrier and a Battleship/Dreadnought entirely. Four other factions are each one hull short of the stated five. The census claims verification "from the code in this pack," so either the census was checked against a different commit or the verification missed the roster arrays. The commissioner's total of "45 hulls" also does not reconcile: the code defines 33 base entries (including 3 squadrons) and injects 18 variants, totalling 51.

### F-2 · [BLOCKER] - Boss hulls in Corsair and Chorus are reskinned carriers, not new roles

READ. c_boss (Battle-barge, cp 10) carries ab:'launch', hangar:2 - identical ability and hangar to c_hulk (Carrier, cp 4). b_boss (Bio-titan, cp 12) carries ab:'launch', hangar:3 - identical to b_brood (Carrier, cp 5). In both cases the boss adds weapons and raw stats but does not change the decision the player makes: park a large hull and launch squadrons. The boss is the carrier with "bigger numbers," exactly the failure the commissioner asked about.

### F-3 · [FIX] - Hegemony fields two launch-carriers in the same ladder with the same hangar

READ. h_vanguard (Cruiser, cp 4) and h_dominion (Battleship, cp 6) both carry ab:'launch', hangar:1, turbo-lance weapons, and an ion weapon. The +2 cp buys +90 hp, +8 shields, and -1 speed. No new ability, no larger hangar, no new weapon facing. A player choosing between them is choosing a stat line, not a role. The faction blurb promises "carriers launch fighter screens," but two ships doing the same screen job at different price points is a rounding error, not a decision.

### F-4 · [FIX] - Four abilities are orphaned: one hull, no family

READ. focus appears only on penitent. ionpulse appears only on h_interdictor. frenzy appears only on b_razor. reclaim appears only on d_harvester. Each is a one-off with no sibling hull sharing it, so the ability cannot form a readable faction keyword the way regrow (two Chorus hulls), blink (two Ithar hulls), or phase (two Deathless hulls) can. A player meeting reclaim for the first time has no prior context for what it does.

### F-5 · [FIX] - d_scythe_s variant is a strict upgrade, not a sidegrade

READ. Base d_scythe mounts [['gauss','T']]. Variant d_scythe_s mounts [['gauss','T'],['gsentry','T']] at cost 15 renown. No stat is reduced, no weapon is removed, no ability is swapped. The variant adds a weapon for free. Every other variant in the pack trades something (a facing, a hangar, a stat); this one only adds. INFERRED: if gsentry is niche (anti-squadron only), the upgrade is small, but it is still not a choice - there is no reason to keep the base hull once the variant is purchased.

### F-6 · [FIX] - Cross-faction near-duplication: warden and h_picket

READ. Both are cp 1 frigates with ab:'evasive', one forward weapon + one turret flak, speed 5, turn 3, shields 10, armor .1. Stats differ by ≤ 5 in every field (hp 45 vs 40; evasion 20 vs 18). The only mechanical distinction is autocannon vs laser, and the weapon damage table is not in this pack, so the difference may be zero in practice. INFERRED: at battle distance a player sees "small fast screen ship with evasive" in both fleets and cannot read a factional intent from the hull alone.

### F-7 · [NOTE] - Deathless ladder is three hulls plus a boss; two classes absent

READ. d_scythe (Frigate, cp 1), d_jackal (Destroyer, cp 2), d_harvester (Cruiser, cp 4), d_boss (Tomb-ark, cp 12). No Carrier, no Battleship/Dreadnought. The cp jump from 4 to 12 is the largest gap in any faction. A Deathless player has no carrier option and no mid-tier heavy; fleet composition is locked into small-ship swarms or a single boss anchor. The faction blurb promises "wrecks rebuild themselves," which the reanimate tag delivers, but the roster cannot express a Deathless battleline above cruiser tonnage.

### F-8 · [NOTE] - Command-point ladder gaps create uneven fleet-building texture

READ. Voidsworn climbs 1-2-3-4-5-8. Hegemony jumps 1-2-4-6-12 (no cp 3). Corsair jumps 1-2-3-4-10 (no cp 5-9). Chorus climbs 1-2-3-5-12. Ithar climbs 1-2-4-5-11. Deathless climbs 1-2-4-12. The large gaps in corsair (4→10) and deathless (4→12) mean those factions have no "heavy" tier between cruiser and boss; a player either fields small ships or commits to the boss, with no intermediate step. INFERRED: in a 20-ship, cp-capped battle this makes corsair and deathless fleets structurally bimodal.

### F-9 · [NOTE] - Ithar boss shares its ability with a cruiser; distinction is numerical

READ. i_song (Cruiser, cp 4) has ab:'surge'. i_boss (Ark, cp 11) also has ab:'surge'. The boss adds pulsar mounts, a turret, flak, and higher stats, but the active ability is the same. Compare to the Hegemony, where the boss swaps launch for nova, creating a genuine role shift. The Ithar boss reads as "a bigger prism," not a new class of ship.

### F-10 · [NOTE] - Ten of thirteen abilities lack definitions in the pack

READ. The ABILITIES table in the pack defines only evasive, reload, and focus. The remaining ten (launch, surge, nova, ionpulse, overburn, regrow, frenzy, blink, phase, reclaim) are referenced in hull rows but their mechanical descriptions are absent. This limits my ability to judge whether an ability "fights" a hull's stats (e.g., whether surge on the immobile cathedral is wasted depends on what surge does). Findings that touch those mechanics are marked INFERRED where applicable.

## 3 · EXPLICIT CHECKS

### ROLE CLARITY

Voidsworn (Sunward Crusade):
- warden (Frigate) - Fast screen; autocannon + flak, evasive to survive picks.
- harrow (Destroyer) - Torpedo strike boat; reload lets it re-fire tubes.
- penitent (Cruiser) - Broadside gun platform with a prow lance; focus for burst.
- reliquary (Carrier) - Launches two squadrons; turrets/flak for self-defence.
- cathedral (Battleship) - Heavy broadside + lance; surge for a damage spike.
- ascendant (Dreadnought/Boss) - Super-heavy broadside; nova for a fleet-scale burst.
Flag: penitent, cathedral, and ascendant all resolve to "fire broadside guns, optionally spike damage." The one-liners for cathedral and ascendant are near-identical; the distinction is nova vs surge and a +150 hp gap. Within the faction, three of six hulls want the same manoeuvre (present the side, fire).

Hegemony Navy:
- h_picket (Frigate) - Laser screen; evasive to hold a lane.
- h_interdictor (Destroyer) - Ion shield-stripper; ionpulse for area denial.
- h_vanguard (Cruiser) - Light carrier (hangar 1) + turbo gunship.
- h_dominion (Battleship) - Heavy carrier (hangar 1) + turbo broadside.
- h_boss (Super-dreadnought) - Nova gunship; heavy turbo broadsides + ion.
Flag: h_vanguard and h_dominion produce the same one-liner: "launch one squadron, fire turbo lances." Pair flagged.

Ashfall Corsairs:
- c_raider (Frigate) - Fast harass; turret autocannon, overburn to reposition.
- c_reaver (Destroyer) - Torpedo gutship; reload for repeat volleys.
- c_marauder (Cruiser) - Scatter broadside + prow torp; overburn to close.
- c_hulk (Carrier) - Launches two squadrons; twin turrets for defence.
- c_boss (Battle-barge) - Launches two squadrons; scatter broadsides + heavy torp.
Flag: c_hulk and c_boss both read "launch two squadrons." The boss adds guns but the job statement is unchanged.

The Chorus:
- b_drone (Frigate) - Melee tendril swarm; regrow 4 to outlast picks.
- b_spitter (Destroyer) - Ranged bioplasma; regrow 5.
- b_razor (Cruiser) - Melee/ranged hybrid; frenzy for burst; regrow 7.
- b_brood (Carrier) - Launches three spore squadrons; regrow 8.
- b_boss (Bio-titan) - Launches three spore squadrons; regrow 20.
Flag: b_brood and b_boss both read "launch three spore squadrons." Pair flagged.

The Ithar (Glasswrights):
- i_wisp (Frigate) - Fast scout/skirmisher; blink to evade.
- i_blade (Destroyer) - Fast torpedo boat; blink to reposition.
- i_song (Cruiser) - Shield tank / burst; surge for damage spike.
- i_carrier (Carrier) - Launches two squadrons; pulsar + turret defence.
- i_boss (Ark) - Shield tank / burst; surge; heavier pulsar array.
Flag: i_song and i_boss both read "shield tank with surge." No battleship or dreadnought class exists in this faction.

The Deathless Dynasty:
- d_scythe (Frigate) - Slow armour screen; phase + reanimate to outlast.
- d_jackal (Destroyer) - Slow gauss gunboat; phase + reanimate.
- d_harvester (Cruiser) - Slow heavy gunship with doom weapon; reclaim wrecks.
- d_boss (Tomb-ark) - Super-slow gauss/doom platform; nova burst.
Flag: No carrier and no battleship. Cannot state a carrier or heavy-line job for this faction because neither exists.

### DUPLICATION - three closest pairs

Pair 1: b_brood (Chorus Carrier) vs b_boss (Chorus Bio-titan)
Stat distance: +450 hp, +12 regen, +2 weapon mounts, +7 cp. Ability: both launch. Hangar: both 3. Speed: both 2. Evasion: both 0.
Verdict: rounding error. The boss is the carrier with more hit points and regen. The player decision ("park and launch") is identical. The extra weapons (bioplasma F ×2 vs ×1, extra tendril/spore) are stat additions, not a new decision.

Pair 2: h_vanguard (Hegemony Cruiser) vs h_dominion (Hegemony Battleship)
Stat distance: +90 hp, +8 sh, -1 sp, -4 ev, +2 cp. Ability: both launch. Hangar: both 1. Weapon families: both turbo + ion.
Verdict: rounding error. No new ability, no larger hangar, no new weapon type. The +2 cp buys a stat line, not a role.

Pair 3: warden (Voidsworn Frigate) vs h_picket (Hegemony Frigate)
Stat distance: hp 45 vs 40, ev 20 vs 18, everything else within ±1. Ability: both evasive. Weapon layout: one forward gun + one turret flak.
Verdict: rounding error across factions. The autocannon-vs-laser swap may matter if the damage tables differ, but that data is not in the pack. At battle distance, both read as "small fast evasive screen."

### THE LADDER

Is the escalation faction-flavoured or one template six times?
The ladders are faction-flavoured in shape but not always in content. Each faction bends the progression around its identity:
- Voidsworn is the only faction with a full six-step ladder (1-2-3-4-5-8 cp), adding broadside weight and armour as it climbs. The broadside-doctrine move rule rewards the lateral positioning the weapons demand. This is the cleanest ladder.
- Hegemony bends toward carriers: launch appears at cp 4 and persists through cp 6 and 12. Ion weapons thread every tier. The retro-thruster rule rewards the kite-and-gun style the turbo weapons imply. But the two launch hulls at cp 4 and 6 flatten the mid-ladder.
- Corsair is a speed ladder: overburn on the frigate and cruiser, bolted-burner sideslip, torpedoes at every tier. The jump from cp 4 (hulk) to cp 10 (boss) skips an entire tier.
- Chorus is a regen ladder: 4→5→7→8→20. No shields anywhere. The living-hull free-pivot rule supports the swarm-melee identity. Clean escalation.
- Ithar is a shield/speed ladder: blink at the bottom, surge at the top, crystal-vane evasion after moving. The drop from speed 7 (wisp) to speed 3 (boss) is steep but reads as "fewer, heavier, still hard to hit."
- Deathless is a grind ladder: phase/reanimate throughout, fold drive ignoring terrain. But it stops at three hulls. The cp 4→12 jump is a cliff, not a ladder.

Command-point honesty - best and worst value:
Best value: d_scythe (cp 1). 56 hp, .20 armour, phase, regen 3, reanimate. Compare warden at the same cp 1: 45 hp, .10 armour, evasive, no regen. The Deathless frigate is tankier, self-repairing, and reanimating for the same single command point. INFERRED: in a 20-ship battle, spamming d_scythe at 1 cp each is disproportionately efficient.
Worst value: h_dominion (cp 6). It provides launch, hangar:1 - the exact same carrier capability as h_vanguard at cp 4. The extra 2 cp buys +90 hp and +8 shields, but no new ability, no larger hangar, no new weapon type. In a cp-capped fleet, spending 6 cp on a ship that does the same job as a 4 cp ship is a tax. Compare cathedral at cp 5 (220 hp, surge, four weapon mounts) or b_brood at cp 5 (200 hp, hangar 3, regen 8): both offer more per point.

### ABILITIES

Distribution map:
- evasive - warden, h_picket - 2
- reload - harrow, c_reaver - 2
- focus - penitent - 1 (orphan)
- launch - reliquary, h_vanguard, h_dominion, c_hulk, c_boss, b_brood, b_boss, i_carrier - 8
- surge - cathedral, i_song, i_boss - 3
- nova - ascendant, h_boss, d_boss - 3
- ionpulse - h_interdictor - 1 (orphan)
- overburn - c_raider, c_marauder - 2
- regrow - b_drone, b_spitter - 2
- frenzy - b_razor - 1 (orphan)
- blink - i_wisp, i_blade - 2
- phase - d_scythe, d_jackal - 2
- reclaim - d_harvester - 1 (orphan)

Orphaned abilities: focus, ionpulse, frenzy, reclaim - four abilities with no family. Each sits on a single hull with no sibling to teach the player what the ability means before they encounter it.
Ability fighting stats (INFERRED, because 10 of 13 ability definitions are absent from the pack):
- cathedral carries surge with speed 2, turn 1, evasion 0. If surge is a timed burst, the ship cannot reposition to bring its broadsides into optimal range before firing. The ability rewards timing; the stats punish movement. Potential conflict.
- c_marauder carries overburn with speed 4 and broadside scatter weapons. Overburn presumably rewards fast movement, but broadsides need the ship to hold a lateral facing. The ability pulls toward speed; the weapons demand a stable firing solution. Mild tension.
Hull that most wastes its ability:
h_dominion (INFERRED). Its ability is launch with hangar:1. A cp 6 battleship launching a single squadron is a carrier in the most minimal sense. The ability is technically present but mechanically negligible compared to the ship's turbo broadsides. The player will use h_dominion as a gunship and ignore the launch button. The ability is dead weight.

### VARIANTS AND BOSSES

Variant trades - sidegrades or strict upgrades/downgrades?
Renown variants (12):
Most are clean sidegrades: vs_harrow_t trades a turret for a second torpedo tube; vs_penitent_g trades a lance for a turret battery; h_vanguard_g and c_hulk_g trade launch/hangar for gun loadouts; b_spitter_s and b_razor_s shift the melee/ranged balance; i_wisp_l and i_song_w swap weapon types or add shields. c_reaver_t rotates a scatter gun to a turret. d_harvester_t moves doom to a turret at the cost of one gauss. All of these present a genuine choice.
Worst offender (strict upgrade): d_scythe_s. Adds gsentry to the base gauss turret. No stat is reduced, no weapon is removed, no ability is swapped. Cost 15 renown for a free extra weapon. There is no decision; the variant is strictly better.
Worst offender (strict downgrade): None found. No variant removes capability without adding something in return. The closest is h_vanguard_g, which removes launch and hangar, but it adds a turbo turret - a role change, not a downgrade.
Arc variants (6):
All six are clean sidegrades with clear trade language: vs_penitent_l swaps broadsides for two prow lances; h_interdictor_e adds flak at the cost of 14 hp and 1 speed; c_marauder_g adds a second torp at the cost of flak and 1 speed; b_razor_e trades a tendril for a bioplasma turret and gains +2 regen but loses 1 speed; i_carrier_a gains +1 hangar at the cost of 6 shields and 1 speed; d_jackal_h moves guns to turrets and adds gsentry at the cost of 10 hp. Every trade is legible.
Boss hulls vs their faction's top non-boss hull:
- ascendant (nova) vs cathedral (surge) - Yes. Nova ≠ surge; different weapon loadout (no forward lance). Unique flag.
- h_boss (nova, no hangar) vs h_dominion (launch, hangar 1) - Yes. Boss is a pure gunship; dreadnought is a carrier. Clear role split.
- c_boss (launch, hangar 2) vs c_hulk (launch, hangar 2) - No. Same ability, same hangar. Boss adds scatter/htorp and stats. A bigger hulk.
- b_boss (launch, hangar 3, regen 20) vs b_brood (launch, hangar 3, regen 8) - No. Same ability, same hangar. Boss adds weapons and regen. A bigger brood-sac.
- i_boss (surge) vs i_song (surge) - Marginal. Same ability. Boss adds turrets and stats. No carrier or dreadnought to compare against.
- d_boss (nova, regen 8) vs d_harvester (reclaim, regen 4) - Yes. Nova ≠ reclaim. Different weapon set. But no dreadnought exists; comparison is to a cruiser.
Worst boss: c_boss and b_boss tie. Both are "the carrier but bigger." If forced to pick one: c_boss, because the corsair roster is already four hulls (no battleship), so the boss is the faction's only heavy option and it still reads as a carrier.

## 4 · NOT CHECKED

The pack does not let me judge:
- Weapon damage tables. Weapon IDs (autocannon, laser, torp, gauss, pulsar, etc.) are listed but their damage, range, and special rules are absent. I cannot confirm whether the autocannon/laser swap between warden and h_picket matters in practice.
- Ten of thirteen ability definitions. Only evasive, reload, and focus have mechanical descriptions. launch, surge, nova, ionpulse, overburn, regrow, frenzy, blink, phase, and reclaim are referenced but undefined.
- Module system. Hulls have slots (1-3) but the module definitions are not in the pack.
- Squadron combat resolution. Fighter, bomber, and spore stats are present, but how they engage, how hangar capacity limits deployment, and how flak interacts with them are not shown.
- Visual identity and silhouette. The commissioner asks whether a hull's role is "guessable from its name, class, and silhouette." The pack contains colour/trim/style keywords but no art, sprite data, or silhouette information.
- AI fleet composition and encounter design. SECTOR_POOL lists faction groupings, but how enemy fleets are built and whether the roster supports readable enemy intent is not testable from this pack.
- The Godot port. The pack states it "mirrors this design" but no Godot code is included.
- Playtest data, win rates, or balance metrics. None are in the pack.

## 5 · QUESTIONS FOR THE DESIGNER

1. The Hegemony fields two cp-tier launch carriers (h_vanguard at cp 4, h_dominion at cp 6) with identical hangar:1 and the same ability. Should h_dominion's hangar be raised to 2 or its ability swapped to something other than launch, so the +2 cp buys a new decision rather than a stat line? Stakes: if both carriers play identically, the Hegemony mid-game has no fleet-composition choice, and the faction's "carrier navy" identity collapses into one ship repeated at two price points.
2. The Deathless roster stops at three hulls (frigate, destroyer, cruiser) with no carrier and no battleship/dreadnought; the cp ladder jumps from 4 to 12. Is this an intentional asymmetry that the remaining content (reanimate, fold drive, reclaim) is supposed to carry, or are two hulls missing from the code? Stakes: if intentional, the Deathless player has no heavy-line or carrier option in a 20-ship battle, making the faction structurally incapable of certain fleet shapes; if unintentional, the shipped build is missing a third of a faction.
3. Four abilities (focus, ionpulse, frenzy, reclaim) appear on exactly one hull each. Are these meant to be unique signature abilities that define a single ship, or should they propagate to at least one sibling hull so the player learns the ability family before encountering its one-off? Stakes: orphan abilities are invisible in the player's mental model until they meet the one hull carrying them, which defeats the commissioner's requirement that a fleet's intent be readable at battle distance.
