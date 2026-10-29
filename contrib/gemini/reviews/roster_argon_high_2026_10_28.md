# Argon blind leg: hull roster identity audit (Oct 28, 2026)

Chair note: filed from the model's reply (Gemini, 4 Argon, Thinking level High; picker verified "Argon High" before sending and still Argon High immediately after; inline citation chips omitted per instruction). Em dashes and en dashes normalized to hyphens per house rule; wording otherwise unchanged. Chat: https://gemini.google.com/app/ (roster leg, Oct 28 evening; the picker showed a limit reset notice for 8:10 PM only after the completed response). Evidence pack: the Oct 28 battle program roster pack (code slices pinned to main 264f441d). Method notes and screening live outside this file.

## 1. Proof of Reading

Pack Sections Read:

EVIDENCE PACK title line: EVIDENCE PACK: hull roster identity audit (code slices from the shipped browser build, main 264f441d; the Godot port mirrors this design).

THE COMMISSIONER'S QUESTION: Audit scope covering role readability, duplication, and battle-distance intent across the hull roster.

CHAIR CENSUS (verified from the code in this pack): Structural rules for hull attributes, weapon facings, 20-ship/CP fleet caps, five-ship ladders plus flagship bosses, 18 variants, and silhouette/stat readability.

WHAT TO JUDGE: The six evaluation criteria (Role clarity, Duplication, The ladder, Abilities, Variants, Boss hulls).

Code slice - === data.js 61-135: HULLS and FACTIONS ===: Full HULLS dictionary (30 ship hulls and 3 squadrons), MOVE_RULES, FACTIONS, SECTOR_POOL, and the first three entries of ABILITIES.

Code slice - === data.js 545-580: hull variants ===: Default cost/slot derivation, HULL_VARIANTS (12 renown variants and 6 story-arc variants), ARC_VARIANT, FIT_SLOTS, the variant hydration loop, and FAC_WPOOL.

Overall Verdict: DUPLICATES WITH PAINT - While the six factions establish distinct defensive and thruster rules on paper, five of the six factions are missing one to two base ladder hulls in code, multiple frigates, destroyers, carriers, and bosses duplicate stats or weapon kits, and several variants and flagship bosses either strip core mechanics or act as pure stat sponges.

## 2. Findings

### [BLOCKER] Five of Six Factions Are Missing Base Ladder Hulls Claimed in the Census

READ: The Commissioner states "five per faction in the base roster, plus a boss hull each", and the Census states "Each faction's five-ship ladder (frigate to dreadnought) shares a visual identity... and a faction flagship boss beyond it."

READ: In FACTIONS, only voidsworn lists five hulls in roster (['warden','harrow','penitent','reliquary','cathedral']), while ascendant (cls:'Dreadnought', cp:8, unique:true) occupies FACTIONS.voidsworn.boss with no 10-12 CP boss hull beyond it.

READ: hegemony, corsair, chorus, and ithar each have only four hulls in roster, and deathless has only three (['d_scythe','d_jackal','d_harvester']), yielding 24 base roster hulls + 6 boss-slot hulls + 3 squadrons + 18 variants in HULLS.

INFERRED: Four enemy factions lack any Dreadnought (and corsair, chorus, ithar, and deathless lack any Battleship), creating a 6-to-8 CP roster gap between 4-5 CP Cruisers/Carriers and 10-12 CP Bosses.

### [BLOCKER] Deathless Boss (d_boss) Costs 3x the CP of Its Cruiser (d_harvester) for Identical Offensive Guns and Loses Reanimation

READ: d_harvester (cp:4, hp:145, sp:2, regen:4, reanimate:true) mounts w:[['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T']].

READ: d_boss ('The Unsetting', cp:12, hp:480, sp:1, regen:8) mounts w:[['gauss','T'],['gauss','T'],['doom','F'],['flak','T']] and omits reanimate:true.

INFERRED: d_boss charges 12 CP for the exact same three offensive weapons (2x gauss T + 1x doom F) as a single 4-CP d_harvester, moves half as fast (sp:1, crippling its fixed 'doom','F' arc), and drops the faction's signature "wrecks rebuild themselves" (reanimate:true) trait; three d_harvesters for the same 12 CP provide 3x the firepower, 435 HP, 12 regen/round, and three reanimations.

### [BLOCKER] Voidsworn's Flagship Dreadnought (ascendant) Cannot Trigger Its Own Faction Drive, and Most Voidsworn Hulls Lack Broadsides

READ: MOVE_RULES.voidsworn defines 'Broadside doctrine': "Port and starboard guns hit 40% harder after moving 2+ hexes (others get 10%)."

READ: ascendant (cp:8) carries ['hbattery','P'] and ['hbattery','S'], but has sp:1 and ab:'nova'. Meanwhile, warden, harrow, reliquary, and arc variant vs_penitent_l carry only 'F' and 'T' weapons.

INFERRED: Because ascendant has sp:1 and no movement ability, it is physically incapable of moving 2+ hexes on its own to trigger Broadside doctrine, leaving only 2 of the 6 Voidsworn hulls (penitent and cathedral) able to use their faction's defining mechanic.

### [FIX] Variants d_harvester_t and i_song_w Silently Delete Primary Weapons Not Mentioned in Their Descriptions

READ: d_harvester_t (cost:30) states "Its corona arc sits on a turret: it no longer has to turn to fire" and overwrites d_harvester's four mounts [['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T']] with three mounts [['gauss','T'],['doom','T'],['gsentry','T']].

READ: i_song_w (cost:25) states "One lance on a turret, 30% more shields" and overwrites i_song's [['pulsar','F'],['pulsar','F'],['turret','T']] with [['pulsar','T'],['turret','T']] and mod:{sh:34}.

INFERRED: Both variants silently delete an entire primary weapon (['gauss','T'] and ['pulsar','F'], respectively), turning the highest-cost renown unlocks into hidden firepower traps.

### [FIX] Renown Variants d_scythe_s, h_picket_i, and c_reaver_t Are Strict Upgrades With Zero Downside

READ: The Census states variants operate via "stat trades and ability swaps against the base hull".

READ: d_scythe_s (cost:15) adds ['gsentry','T'] to d_scythe's [['gauss','T']] with no mod penalty; h_picket_i (cost:15) upgrades ['laser','F'] to ['laser','T'] and raises ev from 18 to 24 with no penalty; c_reaver_t (cost:15) upgrades ['scatter','S'] to ['scatter','T'] with no penalty.

INFERRED: None of these three variants makes a trade; they are pure renown taxes that strictly obsolete their base hulls.

### [FIX] Gunship Variants h_vanguard_g and c_hulk_g Delete Their Active Ability Altogether

READ: Both h_vanguard_g and c_hulk_g set mod:{ab:null,hangar:0}, and line 577 executes if(HULLS[id].ab===null) delete HULLS[id].ab;.

INFERRED: Every other non-squadron ship in HULLS possesses an active ability; deleting ab instead of replacing launch with a combat ability (focus, overburn, surge) leaves both variants ability-less and makes c_hulk_g a severe downgrade (losing hangar:2, ab:'launch', and one 'turret','T' for short-range P/S scatter guns on a sp:2, tn:1 hull and +20 HP).

### [FIX] Cross-Faction and Same-Faction Clones (warden/h_picket, reliquary/c_hulk, d_scythe/d_jackal) Fail Role Separation

READ: warden (size:.5, cp:1, hp:45, sh:10, rg:5, ar:.1, sp:5, tn:3, ev:20, w:[['autocannon','F'],['flak','T']], ab:'evasive') and h_picket (size:.5, cp:1, hp:40, sh:10, rg:5, ar:.1, sp:5, tn:3, ev:18, w:[['laser','F'],['flak','T']], ab:'evasive') share identical size, CP, shields, regen, armor, speed, turn, mount facings, flak, and ability.

READ: In Deathless, d_scythe (cp:1, hp:56, ar:.2, sp:4, tn:2, ev:14, w:[['gauss','T']]) and d_jackal (cp:2, hp:110, ar:.25, sp:3, tn:2, ev:6, w:[['gauss','T'],['gauss','F']]) share sh:0, rg:0, tn:2, ab:'phase', regen:3, reanimate:true.

INFERRED: warden and h_picket are functionally the same ship, while two 1-CP d_scythes strictly outclass one 2-CP d_jackal across total HP (112 vs 110), regeneration (6 vs 3), turret arcs (2 T vs 1 T + 1 F), speed (4 vs 3), evasion (14 vs 6), and reanimation bodies (2 vs 1).

### [FIX] Hegemony Duplicates Hybrid 1-Wing Cruisers/Battleships (h_vanguard, h_dominion) and Mislabels Class vs Name

READ: FACTIONS.hegemony states "Ion cannons strip shields; carriers launch fighter screens", yet Hegemony has no cls:'Carrier' hull; instead, both h_vanguard (cls:'Cruiser', cp:4) and h_dominion (n:'Dominion dreadnought', cls:'Battleship', cp:6) have ab:'launch' and hangar:1.

INFERRED: Giving both upper-ladder ships hangar:1 and ab:'launch' blurs their roles, leaves Hegemony with weaker fighter output per hull than every other carrier faction (hangar:2 or 3), wastes a 6-CP Battleship's ability slot on a single 18-HP fighter wing, and creates UI confusion by naming a cls:'Battleship' hull 'Dominion dreadnought'.

### [FIX] Boss Hulls (b_boss, i_boss, h_boss, c_boss) Recycle Cruiser/Carrier Kits With Inflated HP

READ: b_boss (cp:12) copies b_brood's (cp:5) exact sp:2, tn:1, ev:0, ab:'launch', hangar:3 carrier package; i_boss (cls:'Ark', cp:11) has no hangar and repeats i_song's ab:'surge' and [['pulsar','F'],['pulsar','F'],['turret','T']] core; h_boss (cp:12) has lower shield regen (rg:10) than h_dominion (rg:12).

INFERRED: Outside c_boss's 'htorp' mount, none of the bosses introduces a boss-exclusive weapon or ability; they scale encounter difficulty via raw HP (470-650) rather than distinct flagship mechanics.

### [NOTE] Four Abilities Are Orphaned on Single Hulls and FACTIONS.voidsworn Omits the sq Property

READ: focus (penitent), ionpulse (h_interdictor), frenzy (b_razor), and reclaim (d_harvester) appear on only one hull each across the entire HULLS table, and FACTIONS.voidsworn has no sq key despite reliquary having hangar:2.

INFERRED: Orphaning four mid-tier abilities while sharing nova across three unrelated factions (voidsworn, hegemony, deathless) dilutes faction ability identity, and the missing sq key on voidsworn relies on an implicit fallback outside the pack.

## 3. Explicit Checks

### 1. ROLE CLARITY

Because five of the six factions do not actually have five base hulls in FACTIONS[fac].roster, each faction's base roster slots and boss slot are listed below from the data alone:

Voidsworn (roster: 5 hulls; boss: ascendant):

warden (Frigate, 1 CP): Fast forward-gun picket and anti-squadron flak screen (sp:5, ev:20, autocannon F, flak T, evasive).

harrow (Destroyer, 2 CP): Reloading forward-torpedo striker with turret backup (torp F, turret T, reload).

penitent (Cruiser, 3 CP): Moving broadside-and-prow-lance line gunship (battery P/S, lance F, focus).

reliquary (Carrier, 4 CP): Slow two-wing pocket carrier and flak escort (sp:2, hangar:2, turret T, flak T, launch).

cathedral (Battleship, 5 CP): Moving heavy broadside-and-prow-lance line gunship with flak (hbattery P/S, lance F, flak T, surge).

(Boss slot / 6th hull) ascendant (Dreadnought, 8 CP): Flagged - Contradictory/Unstatable Coherent Job. Its weapons (hbattery P/S) say "broadside line dreadnought," but its sp:1 prevents it from triggering Voidsworn's 2-hex Broadside doctrine (rake:.4).

Same-Faction Collision: penitent (3 CP) and cathedral (5 CP) share the same one-line job (advancing P/S broadside + F lance gunship), differing only in tier scale.

Hegemony Navy (roster: 4 hulls; 5th hull in HULLS is h_boss):

h_picket (Frigate, 1 CP): Fast forward-laser picket and anti-squadron flak screen (sp:5, ev:18, laser F, flak T, evasive).

h_interdictor (Destroyer, 2 CP): Shield-stripping forward-ion destroyer with turret support (ion F, turbo T, ionpulse).

h_vanguard (Cruiser, 4 CP): Hybrid ion-and-turret gun-cruiser with a one-wing fighter bay (turbo T x2, ion F, hangar:1, launch).

h_dominion (Battleship, 6 CP): Hybrid ion-and-broadside gunship with a one-wing fighter bay (hturbo P/S, ion F, flak T, hangar:1, launch).

Base Roster Slot 5: Flagged - Missing Hull in Code (h_boss, 12 CP Super-dreadnought, is the boss:true flagship: a sp:1 broadside/ion/turret siege platform with nova).

Same-Faction Collision: h_vanguard (4 CP) and h_dominion (6 CP) come out to the same muddled hybrid job ("direct-fire ion/plasma warship that spends its ability on launch for hangar:1"), leaving Hegemony with neither a dedicated multi-wing Carrier nor a pure gunship Battleship.

Ashfall Corsairs (roster: 4 hulls; 5th hull in HULLS is c_boss):

c_raider (Frigate, 1 CP): High-speed, high-evasion turret harasser (sp:6, ev:28, autocannon T, overburn).

c_reaver (Destroyer, 2 CP): Reloading forward-torpedo striker with starboard scatter gun (torp F, scatter S, reload).

c_marauder (Cruiser, 3 CP): Fast close-range scatter-broadside and forward-torpedo brawler (sp:4, scatter P/S, torp F, flak T, overburn).

c_hulk (Carrier, 4 CP): Slow, heavy-hulled two-wing bomber carrier with dual turrets (sp:2, hp:170, turret T x2, hangar:2, launch).

Base Roster Slot 5: Flagged - Missing Hull in Code (c_boss, 10 CP Battle-barge, is boss:true).

Same-Faction Collision: If c_boss is evaluated as the 5th hull, its role is a direct paste of c_marauder's weapon kit (scatter P/S, htorp F, flak T) onto c_hulk's carrier frame (sp:2, tn:1, ev:0, ab:'launch', hangar:2).

The Chorus (roster: 4 hulls; 5th ship hull in HULLS is b_boss):

b_drone (Frigate, 1 CP): Fast regenerating turret-melee swarm screen (sp:5, tendril T, regrow, regen:4).

b_spitter (Destroyer, 2 CP): Regenerating speed-4 two-gun bioplasma skirmisher (sp:4, bioplasma T, bioplasma F, regrow, regen:5).

b_razor (Cruiser, 3 CP): Regenerating speed-4 two-gun bioplasma-and-tendril brawler (sp:4, tendril T, bioplasma F, frenzy, regen:7).

b_brood (Carrier, 5 CP): Slow three-wing spore-carrier with forward bioplasma and spore turret (sp:2, hangar:3, bioplasma F, spores T, launch, regen:8).

Base Roster Slot 5: Flagged - Missing Hull in Code (b_boss, 12 CP Bio-titan, is boss:true).

Same-Faction Collision: b_spitter (2 CP) and b_razor (3 CP) are both speed-4, turn-2 regenerating two-gun skirmishers with ['bioplasma','F'] + one 'T' weapon (and b_razor_e gives b_razor the exact [['bioplasma','T'],['bioplasma','F']] loadout of b_spitter), while b_brood (5 CP) and b_boss (12 CP) share the exact same three-wing carrier package (sp:2, tn:1, ev:0, ab:'launch', hangar:3).

The Ithar (roster: 4 hulls; 5th hull in HULLS is i_boss):

i_wisp (Frigate, 1 CP): Unarmored, blink-teleporting forward-shard hit-and-run scout (ar:0, sp:7, ev:28, shard F, blink).

i_blade (Destroyer, 2 CP): Unarmored, blink-teleporting forward-shard and star-torpedo hit-and-run striker (ar:0, sp:6, ev:24, shard F, startorp F, blink).

i_song (Cruiser, 4 CP): Fast twin-forward-pulsar sniper cruiser with turret backup (sp:5, ev:16, pulsar F x2, turret T, surge).

i_carrier (Carrier, 5 CP): Fast two-wing fighter carrier with forward pulsar (sp:4, ev:12, pulsar F, turret T, hangar:2, launch).

Base Roster Slot 5: Flagged - Missing Hull in Code (i_boss, 11 CP Ark, is boss:true).

Same-Faction Collision: i_wisp (1 CP) and i_blade (2 CP) share the same one-line job ("unarmored blink forward-arc hit-and-run striker"); i_song (4 CP) and i_boss (11 CP) also share the same job ("twin-forward-pulsar surge gunship").

The Deathless Dynasty (roster: 3 hulls; 4th hull in HULLS is d_boss):

d_scythe (Frigate, 1 CP): Self-reanimating, phasing turret-gauss attrition escort (hp:56, gauss T, phase, regen:3, reanimate:true).

d_jackal (Destroyer, 2 CP): Self-reanimating, phasing twin-gauss attrition escort (hp:110, gauss T, gauss F, phase, regen:3, reanimate:true).

d_harvester (Cruiser, 4 CP): Slow, self-reanimating dual-gauss and forward-doom heavy line cruiser (sp:2, gauss T x2, doom F, gsentry T, reclaim, regen:4, reanimate:true).

Base Roster Slot 4: Flagged - Missing Hull in Code (no Carrier or Battleship).

Base Roster Slot 5: Flagged - Missing Hull in Code (no Dreadnought; d_boss, 12 CP Tomb-ark, is boss:true).

Same-Faction Collision: d_scythe (1 CP) and d_jackal (2 CP) have the exact same one-line job ("self-reanimating, phasing gauss attrition escort with regen:3"), and d_harvester (4 CP) and d_boss (12 CP) have the exact same weapon job (2x gauss T + 1x doom F + 1x point-defense T).

### 2. DUPLICATION

The three closest hull pairs in the entire roster by stat, mount, and ability distance are:

warden (Voidsworn Frigate, 1 CP) vs h_picket (Hegemony Frigate, 1 CP) - Rounding Error

READ: Both are cls:'Frigate', size:.5, cp:1, sh:10, rg:5, ar:.1, sp:5, tn:3, ab:'evasive', with one 'F' gun ('autocannon' vs 'laser') and ['flak','T'], separated only by 5 HP (45 vs 40) and 2 evasion (20 vs 18).

INFERRED: Neither frigate engages its faction's unique mechanics (warden has no P/S guns for Broadside doctrine; h_picket has no ion gun or hangar), making the difference a pure rounding error.

d_scythe (Deathless Frigate, 1 CP) vs d_jackal (Deathless Destroyer, 2 CP) - Rounding Error / Strict Dominated Scaling (Same-Faction)

READ: Both share fac:'deathless', sh:0, rg:0, tn:2, ab:'phase', regen:3, reanimate:true, and 'gauss' weapons; d_jackal costs 2 CP (2x), has 110 HP (1.96x of 56), adds a forward ['gauss','F'] to ['gauss','T'], gains .05 armor (.25 vs .2), and loses 1 speed (3 vs 4) and 8 evasion (6 vs 14).

INFERRED: Rather than a distinct tactical role, d_jackal is two d_scythes welded into one worse body (giving half the regeneration per CP, a narrower weapon arc on the second gun, lower speed/evasion, and one reanimation trigger instead of two).

reliquary (Voidsworn Carrier, 4 CP) vs c_hulk (Corsair Carrier, 4 CP) - Rounding Error (Runner-up cross-faction pair: harrow vs c_reaver, both 2-CP size:.6, tn:2, ab:'reload' ['torp','F'] destroyers)

READ: Both are cls:'Carrier', cp:4, sp:2, tn:1, ev:0, ab:'launch', hangar:2, with size:.84 vs .86 and two 'T' mounts ([['turret','T'],['flak','T']] vs [['turret','T'],['turret','T']]), trading 6 shield and 3 shield regen (22/9 vs 16/6) for 40 HP and .05 armor (130/.15 vs 170/.2).

INFERRED: Aside from spawning faction-default wings, the two hulls play identically on the board - and perversely invert their faction blurbs, giving the "Fast, thin shields" Corsair carrier heavier armor (.2 vs .15) and +40 HP over the "heavy armor" Voidsworn carrier.

### 3. THE LADDER

Escalation (Faction-Flavored vs One Template Six Times):

READ: All six ladders follow a single kinematic template: Frigates (cp:1, size:.46-.5, sp:4-7, tn:2-3, ev:14-28, 1-2 guns) -> Destroyers (cp:2, size:.58-.62, sp:3-6, tn:2-3, ev:6-24, 2 guns) -> Cruisers (cp:3-4, size:.74-.82, sp:2-5, tn:1-2, ev:0-16, 2-4 guns) -> Carriers (cp:4-5, size:.84-.9, sp:2 [Ithar 4], tn:1 [Ithar 2], ev:0 [Ithar 12], hangar:2-3, ab:'launch', 2 guns) -> Bosses (cp:10-12, size:1.22-1.3, sp:1-3, tn:1-2, ev:0-6, 4-5 guns).

INFERRED: Faction flavor lives almost entirely in the passive defense pool (chorus 0-shield + regen:4-20; deathless 0-shield + ar:.2-.35 + regen:3-8 + reanimate:true; ithar ar:0-.05 + sp:4-7 + evade:18), while the class chassis progression is one shared template - and as hulls scale up to sp:1-2 and ev:0 at 4-12 CP, they converge on generic ab:'launch' carriers and ab:'nova' slow bricks that stop interacting with movement-based faction drives.

Command Point Honesty (Best and Worst Value Picks):

Best Value Hull - d_scythe ('Eclipse mote', Deathless Frigate, 1 CP) (Runner-up mid-tier: c_marauder at 3 CP, packing 4 weapons, 120 HP, sp:4, and overburn):

READ: For cp:1, d_scythe brings hp:56, ar:.2, sp:4, tn:2, ev:14, w:[['gauss','T']], ab:'phase', regen:3, reanimate:true, and Deathless's over:0 drive.

INFERRED: d_scythe delivers Cruiser-tier armor (.20, matching 3-4 CP penitent, h_vanguard, c_hulk, b_razor), the highest raw HP of any 1-CP ship (56 vs 30-46), 3 regen/round (37.5% of a 12-CP d_boss's regen for 1/12th the CP), a 360-degree null-weapon turret, phase, and reanimate:true.

Worst Value Hull - d_boss ('The Unsetting', Deathless Boss, 12 CP) (Runner-up non-boss: ascendant at 8 CP or d_harvester at 4 CP):

READ: d_boss costs cp:12 for hp:480, ar:.35, sp:1, tn:1, ev:0, w:[['gauss','T'],['gauss','T'],['doom','F'],['flak','T']], ab:'nova', regen:8 (no reanimate:true), while 8-CP ascendant costs cp:8 (cost:520) for hp:370, sh:32, rg:15, ar:.35, sp:1, w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']], ab:'nova', slots:3.

INFERRED: d_boss costs 3x as much CP as d_harvester (cp:4) with zero increase in offensive weapon count (2x gauss T + 1x doom F), half the speed (sp:1), and no reanimate:true; meanwhile, 8-CP ascendant costs +60% more CP than 5-CP cathedral (cp:5, hp:220, sh:30, sp:2, slots:3) while gaining only +2 shield, downgrading 'lance','F' to 'turret','T', gaining zero module slots, and dropping to sp:1 (losing Voidsworn's +40% broadside bonus).

### 4. ABILITIES

Ability Distribution Across the 30 Base Ship Hulls (READ):

launch (8 hulls): reliquary, h_vanguard, h_dominion, c_hulk, c_boss, b_brood, b_boss, i_carrier.

nova (3 hulls): ascendant, h_boss, d_boss.

surge (3 hulls): cathedral, i_song, i_boss.

evasive (2 hulls): warden, h_picket.

reload (2 hulls): harrow, c_reaver.

overburn (2 hulls): c_raider, c_marauder.

regrow (2 hulls): b_drone, b_spitter.

blink (2 hulls): i_wisp, i_blade.

phase (2 hulls): d_scythe, d_jackal.

Orphaned Abilities (1 hull each, no family - 4 abilities): focus (penitent), ionpulse (h_interdictor), frenzy (b_razor), and reclaim (d_harvester).

Deleted Ability (ab undefined - 2 variants): h_vanguard_g and c_hulk_g (mod:{ab:null,hangar:0}).

Hulls Whose Ability or Drive Fights Their Stats:

ascendant (sp:1, ab:'nova' vs Voidsworn rake:.4): Carries ['hbattery','P'] and ['hbattery','S'] for a faction whose drive requires moving 2+ hexes, but has sp:1 and ab:'nova' (instead of a movement ability), so its stats lock it out of its own faction passive (READ/INFERRED).

penitent (ab:'focus' vs P/S/F split arcs): focus grants "All of this ship's weapons deal +30% damage this turn" (READ), but penitent's three weapons face three incompatible fixed directions (['battery','P'], ['battery','S'], ['lance','F']) on a sp:3, tn:2 hull, making it geometrically difficult to fire all three mounts in one turn without being flanked on both sides (INFERRED).

b_drone and b_razor_s (All-'T' weapons vs Chorus pivot:1): Chorus's drive ("The first turn each round costs no movement") rewards aligning fixed forward arcs, but b_drone ([['tendril','T']]) and b_razor_s ([['tendril','T'],['tendril','T']]) carry only 360-degree turrets (READ/INFERRED).

Hull That Most Wastes Its Ability:

h_dominion (Dominion dreadnought, 6 CP Battleship) (among base hulls) and h_vanguard_g / c_hulk_g (among variants):

READ: h_dominion is a 6-CP Battleship (w:[['hturbo','P'],['hturbo','S'],['ion','F'],['flak','T']]) whose sole active ability is ab:'launch' tied to hangar:1 (a single 18-HP fighter wing), while h_vanguard_g and c_hulk_g set ab:null and delete their ability slot entirely.

INFERRED: Locking a 6-CP capital gunship's active ability to launch for a 1-wing hangar (half to a third of true carriers' hangar:2-3) squanders its ability slot on minimal squadron output instead of capital gunnery.

### 5. VARIANTS AND BOSSES

Variant Trades (Sidegrades vs Strict Upgrades/Downgrades):

Genuine Sidegrades (9 of 18): vs_harrow_t (trades 'turret','T' for second 'torp','F', doubling reload burst), vs_penitent_g (trades 'lance','F' for 'battery','T'), vs_penitent_l (trades P/S batteries for 2x 'lance','F' + 'battery','T', though losing Voidsworn broadside synergy), b_spitter_s ('bioplasma','F' -> 'tendril','T'), b_razor_s ('bioplasma','F' -> 'tendril','T', +1 sp, +8 ev), h_interdictor_e (+'flak','T', -14 hp, -1 sp), c_marauder_g ('flak','T' -> 'torp','F', -1 sp), b_razor_e ('tendril','T' -> 'bioplasma','T', +2 regen, -1 sp, though duplicating b_spitter's guns), and i_carrier_a (+1 hangar, -6 sh, -1 sp) (READ/INFERRED).

Strict Upgrades / Near-Free Upgrades (5 of 18): d_scythe_s, h_picket_i, c_reaver_t, d_jackal_h (upgrades 'gauss','F' to 'gauss','T' and adds 'gsentry','T' for just -10 HP), and i_wisp_l ('shard','F' -> cruiser 'pulsar','F' with no stat penalty) (READ/INFERRED).

Worst Strict-Upgrade Offender: d_scythe_s ('Mote sentinel', cost 15) - keeps 100% of d_scythe's stats, ability, and ['gauss','T'], and simply adds a free second turret weapon (['gsentry','T']) with no mod trade-off whatsoever (READ/INFERRED).

Strict Downgrades / Traps (4 of 18): d_harvester_t, i_song_w, c_hulk_g, and h_vanguard_g (READ/INFERRED).

Worst Strict-Downgrade Offender: d_harvester_t ('Turreted zenith', cost 30) - charges the highest renown cost in the table (30) to move 'doom' from 'F' to 'T' while silently deleting the ship's second ['gauss','T'] turret (c_hulk_g is a close second, deleting hangar:2 and ab:'launch' for +20 HP and P/S scatter guns on a sp:2 hull).

Boss Hulls vs Faction Dreadnoughts (Mechanically Distinct vs Mainly a Bigger Number):

Voidsworn (ascendant, 8 CP Dreadnought): No Boss Hull Exists Beyond the Dreadnought. ascendant is FACTIONS.voidsworn.boss (cp:8, unique:true, no boss:true flag) (READ).

Hegemony (h_boss, 12 CP Super-dreadnought vs h_dominion, 6 CP Battleship): Mainly a Bigger Number. Keeps h_dominion's hturbo P/S + ion F + flak T, adds one 'turbo','T', drops hangar:1, swaps launch for generic nova, lowers rg from 12 to 10, drops to sp:1, and inflates HP from 230 to 560 (READ/INFERRED).

Corsair (c_boss, 10 CP Battle-barge vs c_hulk 4 CP & c_marauder 3 CP): Composite Kitbash + Bigger Number. Corsair has no base Dreadnought; c_boss staples c_marauder's four-mount layout (with 'htorp','F' in place of 'torp','F') onto c_hulk's sp:2, tn:1, ev:0, ab:'launch', hangar:2 chassis at 600 HP (READ/INFERRED).

Chorus (b_boss, 12 CP Bio-titan vs b_brood, 5 CP Carrier): Mainly a Bigger Number. Chorus has no base Dreadnought; b_boss has the exact same sp:2, tn:1, ev:0, ab:'launch', hangar:3 as 5-CP b_brood, adding +450 HP, +12 regen, and two small-ship guns (['bioplasma','F'], ['tendril','T']) (READ/INFERRED).

Ithar (i_boss, 11 CP Ark vs i_song, 4 CP Cruiser): Mainly a Bigger Number. Ithar has no base Dreadnought; despite cls:'Ark', i_boss has no hangar and simply scales up 4-CP i_song (ab:'surge', 2x 'pulsar','F' + 'turret','T') with +380 HP, 'pulsar','T', and 'flak','T' (READ/INFERRED).

Deathless (d_boss, 12 CP Tomb-ark vs d_harvester, 4 CP Cruiser): Mainly a Bigger Number (and Mechanically Worse). Deathless has no base Dreadnought; d_boss carries the exact same offensive weapons (2x gauss T + 1x doom F) as 4-CP d_harvester, loses reanimate:true, drops to sp:1, swaps reclaim for nova, and inflates HP from 145 to 480 (READ/INFERRED).

## 4. Not Checked

This evidence pack does not contain the code required to judge:

Weapon statistics (WEAPONS table): Damage, range, cooldown, accuracy, shield/armor piercing, or AoE values for any weapon ID (e.g., whether 'pulsar' out-values 'shard', or how 'doom', 'ion', 'tendril', and 'spores' resolve).

Truncated ABILITIES definitions (lines 136+): Exact cooldowns, durations, and mechanical effects for the 10 abilities omitted after line 135 (launch, surge, nova, ionpulse, overburn, regrow, frenzy, blink, phase, reclaim).

Combat and movement math in battle.js: Exact hit-chance formulas for ev and size, armor reduction (ar), how tn interacts with hex facing, whether launch has a replacement cap or cooldown limit relative to hangar, and how reanimate:true triggers (chance, HP percentage, one-time vs infinite).

Economy and encounter tables (FAC_PRICE, module definitions, AI fleet generator): How FAC_PRICE (referenced on line 546) modifies hull credit costs, what slots:1..3 equip, and whether AI boss fleets get extra CP budgets.

Visual silhouettes and art assets: Whether hull shapes, weapon hardpoints, and faction silhouettes are distinguishable at battle distance.

## 5. Questions for the Designer

1. Were the seven missing enemy base hulls (one 5th ladder ship each for Hegemony, Corsair, Chorus, and Ithar, plus Carrier and Battleship/Dreadnought rungs for Deathless, and a 12-CP boss for Voidsworn) cut from HULLS, or was the five-ship-plus-boss census structure abandoned without updating fleet progression? Stakes: If enemy factions are meant to field five-ship ladders plus a boss, five of six factions currently have a 6-to-8 CP hole at the top of their roster that forces mid-tier Cruisers/Carriers to carry late-sector fleets.
2. Are d_harvester_t (losing a 'gauss','T'), i_song_w (losing a 'pulsar','F'), and h_vanguard_g/c_hulk_g (delete HULLS[id].ab) intentional nerfs or data-entry bugs in HULL_VARIANTS, and should zero-downside variants (d_scythe_s, h_picket_i, c_reaver_t) carry stat trade-offs? Stakes: As written, players who spend renown on d_harvester_t, i_song_w, or c_hulk_g permanently pollute their shipyard pool with undocumented downgrades, while d_scythe_s and h_picket_i act as mandatory renown taxes.
3. How is Voidsworn's ascendant (sp:1, ab:'nova') expected to trigger MOVE_RULES.voidsworn (rake:.4 after moving 2+ hexes) for its ['hbattery','P'] and ['hbattery','S'] mounts, and why does d_boss (cp:12) carry the exact same offensive guns as d_harvester (cp:4) without reanimate:true? Stakes: When the player's 8-CP flagship dreadnought cannot activate its own faction's signature rule and a 12-CP boss hits no harder than a 4-CP cruiser, the apex ships of the roster fail both fantasy and command-point economy.
