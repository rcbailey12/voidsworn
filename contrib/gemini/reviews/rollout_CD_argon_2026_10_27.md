# Blind audit leg: rollout audit, Audits C and D, Argon leg

Filed by the chair from the model's verbatim answer. Model: Gemini 4 Argon, thinking level High, verified in two places by the running agent (prompt bar button read Argon High; the open picker showed Selected 4 Argon and Selected High). Fresh chat, signed in as rcbailey12@gmail.com. Run Oct 27, 2026; prompt sent 4:21 PM PDT, generation complete 4:31 PM PDT, first chat, no retry. Chat: https://gemini.google.com/app/fb99dac1f9e769bf. Pinned main HEAD: 806233f766bfdfd98c61fbe5bebb834cc11bbe6c.

Attachments (all 9 granted files attached): leg_prompt_CD.md, brief.md, context_CD_full.md, lore_rollout_brief.md, rename_map_final.md, lore_bible_r8.md, port_notes_steps_CD.md, parity_records.md, chair_grep_CD.md.

Method notes and screening live outside this file. Gemini citation badges and embedded-video expansions are interface artifacts, not model wording, and are excluded. The text below is the model's answer, verbatim.

---

Blind audit report for [github.com/rcbailey12/voidsworn](https://github.com/rcbailey12/voidsworn) pinned to main commit 806233f766bfdfd98c61fbe5bebb834cc11bbe6c (Oct 27, 2026).

Verdict

Audit C (rename map against lore bible round 8): FIX (0 BLOCKER, 8 FIX, 5 NOTE) because every canonical row from lore_rollout_brief.md lands in rename_map_final.md, but the map introduces one direct lore round 8 contradiction (stealing starlight in the Eclipse blurb), leaves one How-to-Play Godot line unmapped (campaign_ui.gd:1018), introduces a "the the Chorus" / "the Eclipse" template bug in make_batches.py, leaves two "Salvage" strings violating Section 5c, and keeps several external franchise collisions and internal name duplicates.

Audit D (rollout landing across streams): FIX (0 BLOCKER for browser play; 2 FIX, 3 NOTE for Godot parity and rollout) because Stream B (90aaf85) and Stream G2 (49f0d85, 239fdeb, ef5cab2) landed their string steps cleanly, while Streams G1 (bdb1a9d) and G3 (9711a7e) still have their parity records and exported tables pinned to pre-step-10 commits (cb55ec9 and d8b47c6), and G3 faces an unrouted Step 9 RAMP gap when it re-pins.

Audit C: The Rename Map Against the Bible
Job C1: Canonical Names and Bible Consistency

Every row of the canonical table in lore_rollout_brief.md:16-47 appears in rename_map_final.md with the exact same new display text:

Game title and factions (lore_rollout_brief.md:18-24): Embers of the Hollow Sun (rename_map_final.md:27, 29-32, Section 1), Sunward Crusade (data.js:111, rename_map_final.md:33), Hegemony Navy kept (rename_map_final.md:334, Section 14), Ashfall Hullbreakers (data.js:115, rename_map_final.md:34), The Chorus kept (rename_map_final.md:333, Section 14), The Glasswrights (data.js:121, rename_map_final.md:35), and Eclipse with no "the" (data.js:124, rename_map_final.md:36).

Star, people, black hole, and run words (lore_rollout_brief.md:25-26, 47): Ardent and Starwrights appear across Sections 1, 5, 7, and 9.4 (rename_map_final.md:42, 166, 167, 208, 217, 218, 273); Fleshwrights is deferred to L's story rewrite in Section 11 (rename_map_final.md:289); the Hollow Sun maps deadstar and gravity logs in Section 4 (battle.js:18, 283, 355, 925; ui3d.js:15; godot/rules/rules.gd:969, 1257, rename_map_final.md:124-128); Homecoming replaces reclamation in Section 1 (data.js:271, rename_map_final.md:43).

Core vocabulary and names (lore_rollout_brief.md:27-28): core, protocol, sync, and signal replace patron, boon, favour, and sigil in Section 2 (rename_map_final.md:46-91) and Section 10.2 (rename_map_final.md:280-285). All six core designations (K-1 Kharon, the Unbent, V-2 Vyre, the Storm Queen, H-3 Crucible, "the Hunger Below", A-4 Astra, the Silent Star, R-5 Rook, the Breaker, S-6 Seren, the Last Flame) match lore_rollout_brief.md:28 in Section 2 (data.js:620-625, rename_map_final.md:50-56).

Weapons (lore_rollout_brief.md:29-35): Sear repeater, Sear battery, Heavy sear broadside, Sear turret, and Cinder torpedo (data.js:35, rename_map_final.md:107); Null cannon, Null spire, Null shredder, Null sentries, and kind label Null (data.js:21, 22, 30, 40, rename_map_final.md:102, 103, 106, 109); Corona arc (data.js:23, 40, rename_map_final.md:104, 109); Prism lance (data.js:19, 39, rename_map_final.md:101, 108); Pulse laser and Heavy pulse laser (data.js:11, 12, rename_map_final.md:97, 98); and The Ninefold Maw with Colossus class via CLS_NAME (data.js:88, rename_map_final.md:115, 133) all match.

Ship classes (lore_rollout_brief.md:36-41): Crusade Warden, Harrow, Vigil, Hearth, Bastion, Daybreak (data.js:63-66, rename_map_final.md:119-122, 332); Hegemony picket, cordon, vanguard, dominion, The Iron Mandate (data.js:73-75, rename_map_final.md:123-125, 334); Hullbreaker raider, gutship, wrecker, hulk-carrier, Warlord's Pyre-Barge with War-barge class (data.js:78-82, rename_map_final.md:115, 126-130); Chorus drone-spawn, spitter, bladeback, brood-sac, The Ninefold Maw (data.js:86-88, rename_map_final.md:131-133, 333); Glasswright sliver, lancet, prism, aperture, The Unfinished (data.js:90-94, rename_map_final.md:134-138); and Eclipse mote, flare, zenith, The Unsetting with Archive-ship class (data.js:96-99, rename_map_final.md:115, 139-142) all match.

Ranks, titles, and admirals (lore_rollout_brief.md:42-46): Hegemony First Admiral (data.js:215, 471, rename_map_final.md:182, 251); Crusade Oath-Captain (data.js:204, rename_map_final.md:181); Eclipse ranks Shade, Gloam, Umbra, Midnight, Nadir and Nemesis titles High Nadir, Eclipse-prime, Archivist (data.js:462, 523, rename_map_final.md:242, 264); Hullbreaker ranks Claw, Fang, Howler, Ripper, Warlord and Nemesis titles Apex, First Claw, Den-alpha, Warlord (data.js:459, 520, rename_map_final.md:240, 261); and Eclipse admirals Nadir Aurex, Ninth Frame, Umbra Vessane, Third-Housed, Ostrel of the Long Copy, and Seveth, Twice-Restored (data.js:231-234, rename_map_final.md:198, 200, 202, 204) all match.

Mismatches and contradictions between rename_map_final.md and lore_bible_r8.md:

[FIX] Eclipse faction blurb says "stealing starlight" instead of "stellar energy"

Evidence: rename_map_final.md:42 (Section 1, data.js:125) vs lore_bible_r8.md:14 (Round 8 "What changed") and context_CD_full.md:82 (FINDINGS.md R58).

Detail: In Round 8, Ryan explicitly ruled that Eclipse siphon "stellar energy, not light" (context_CD_full.md:82; lore_bible_r8.md:14, 30, 58, 464). While Section 7 of the map correctly writes drinking its energy at data.js:366 (rename_map_final.md:221), Section 1 of the map sets the main Eclipse faction blurb at data.js:125 (rename_map_final.md:42) to Starwright minds in machine bodies, stealing starlight to light a new sun..

[FIX] Portrait batch template produces "the the Chorus" and "the Eclipse"

Evidence: rename_map_final.md:303 (Section 12, tools/portraits/make_batches.py:193,205) vs lore_bible_r8.md:12 and lore_rollout_brief.md:24.

Detail: The old Python line is 'A Nemesis of the %s, a rival enemy war-organism: %s. %s' % (_fac.capitalize(). Row 12 (rename_map_final.md:303) instructs P to use a display name map: chorus "the Chorus", deathless "Eclipse" without removing the  from 'A Nemesis of the %s'. Substituting "the Chorus" yields "A Nemesis of the the Chorus", and substituting "Eclipse" yields "A Nemesis of the Eclipse", violating the Round 8 rule that Eclipse takes no article (lore_bible_r8.md:12).

[NOTE] Possessive apostrophes in new salvage and unlock names vs Bible Rule 1.4.4

Evidence: rename_map_final.md:149, 152, 160, 162, 174 (Sections 5 and 5b, data.js:188, 193, 247, 266) vs lore_bible_r8.md:114 (Section 1.4 rule 4: No apostrophes inside names) and rename_map_final.md:267 (Section 9.4 note: no apostrophes).

Detail: L stripped possessive apostrophes from all ship names in Section 9.4 (rename_map_final.md:267, changing Saint Vesper's Wrath and Martyr's Resolve), citing Rule 1.4.4, but introduced five new possessive apostrophes in Sections 5 and 5b: Founders' rangefinder (data.js:188), Founders' compass (data.js:193), Dead captain's harness (data.js:266), Warlord's kill tally (data.js:266), and Founders' salvage (data.js:247). (Note that Warlord's Pyre-Barge at data.js:82 is canonical in lore_bible_r8.md:319.)

[NOTE] Core quotation mark formatting in data.js:620-625 vs lore_bible_r8.md:31-36, 123-128

Evidence: rename_map_final.md:50-56 (Section 2, data.js:620-625) vs lore_bible_r8.md:31-36, 123-128.

Detail: In lore_bible_r8.md:31-36, five cores have quotes around their whole name (K-1 "Kharon, the Unbent", V-2 "Vyre, the Storm Queen", A-4 "Astra, the Silent Star", R-5 "Rook, the Breaker", S-6 "Seren, the Last Flame") while H-3 Crucible, "the Hunger Below" quotes only the nickname because Crucible is its working name (lore_bible_r8.md:130). Following lore_rollout_brief.md:28, rename_map_final.md:50-56 omits quotes on five cores and keeps literal quotes only on n:'H-3 Crucible, "the Hunger Below"' (data.js:622).

[NOTE] Four-element Nemesis title arrays vs three canonical titles for Eclipse and Glasswrights

Evidence: rename_map_final.md:242, 245 (Section 9.1, data.js:462, 465) vs lore_bible_r8.md:439, 503 and lore_rollout_brief.md:44.

Detail: Because NEM_FAC[f].titles in data.js has four slots, L padded the three canonical Eclipse Nemesis titles (High Nadir, Eclipse-prime, Archivist, lore_bible_r8.md:503) with captain rank 'Nadir' (data.js:462, matching sample rival Nadir Halvane at lore_bible_r8.md:500), and padded the three Glasswright Nemesis titles (Lens-keeper, First Mirror, Keeper of Astra, lore_bible_r8.md:439) with 'Duelist' (data.js:465, matching lore_bible_r8.md:421).

[NOTE] Kept traits Zealots and Undying foes and Glasswright phase jumps in Section 14 and Section 10.1

Evidence: rename_map_final.md:278, 332 (Section 10.1 campaign_meta.js:165; Section 14) vs lore_bible_r8.md:150, 421, 470.

Detail: Section 8 (rename_map_final.md:237, data.js:592) renames Zealot flotilla to Frontier flotilla because the Crusade is "not a church" (lore_bible_r8.md:150), yet Section 14 (rename_map_final.md:332) keeps Zealots as a Nemesis trait name and Undying foes as a Heat toggle label (even though "Undying" was stripped from all Deathless names), and Section 10.1 (rename_map_final.md:278) keeps Glasswright phase jumps where lore_bible_r8.md:421 calls them short jumps.

Job C2: Coverage of Retired Display Words

[FIX] Missing Godot location godot/ui/campaign/campaign_ui.gd:1018 in Section 10.1 row 2

Evidence: rename_map_final.md:83 (Section 2) vs rename_map_final.md:278 (Section 10.1).

Detail: Every line of the How-to-Play screen in campaign_meta.js:150-169 is duplicated in godot/ui/campaign/campaign_ui.gd:1008-1020 (rename_map_final.md:32, 80-83, 186, 277, 279). In Section 2 (rename_map_final.md:83), the ram rule at the end of campaign_meta.js:165 (without boons. to without protocols.) is mapped to both campaign_meta.js:165 and godot/ui/campaign/campaign_ui.gd:1018 (Owners B, G3). However, in Section 10.1 (rename_map_final.md:278), the first half of that very same paragraph at campaign_meta.js:165 (Hegemony ion pulses, Corsair overburn, Chorus regrowth and frenzy, Ithar phase jumps, Deathless reanimation beams, and the Voidsworn's burns, reloads and shield surges) is mapped ONLY to campaign_meta.js:165 (Owner B), omitting godot/ui/campaign/campaign_ui.gd:1018 (Owner G3). Unless added to G3's list, godot/ui/campaign/campaign_ui.gd:1018 will continue displaying Corsair, Ithar, Deathless, and Voidsworn's after G3 applies its 29 rows. (Tagged UNSURE on exact line formatting in campaign_ui.gd:1018 since the full file is not in the pack.)

[FIX] Surviving retired display words across unapplied G1 and G3 Godot files at 806233f

Evidence: context_CD_full.md:29, 31 (HANDOFF section 0), rename_map_final.md Sections 1 to 10, and parity_records.md:9, 27, 124.

Detail: Per HANDOFF section 0, G1 and G3 string application and table re-exports are marked "Still to do" after B's strings step (context_CD_full.md:29, 31), so they are on track with the rollout plan rather than going the wrong way. However, at pinned commit 806233f766bfdfd98c61fbe5bebb834cc11bbe6c, all G1-owned and G3-owned retired display strings still survive in the Godot tree:

G1 (godot/rules/rules.gd): :969 (dead star's gravity), :1256 (on the auspex), :1257 (A dead star warps this field), :2733 (The phylactery hums... reawakens, "Reawakens"), :2736 ("Reanimating"), :3477 (" reanimates "), :3530 (Nova blast hits), plus godot/rules/data/tables.json (exported from cb55ec9).

G3 (godot/ui/campaign/campaign_ui.gd, map3d.gd, godot/campaign/campaign.gd): campaign_ui.gd:29 (TERMS still maps patron, sigil, boon, favour to themselves), :301 (crusade of gothic capital ships), :435 (Devoted), :442 (Patrons watching, sigil, boons), :504 (relic), :573 (watching, with a), :582 (Boon of), :660 (with a), :664 (Relics), :937 (Patron favour), :976 (boon, patron's favour), :1008 (Voidsworn), :1009 (patrons, boons), :1015 (gauss), :1018 (boons, plus unmapped Corsair, Ithar, Deathless, Voidsworn), :1019 (Patrons, boons, sigil, duo boon), :1020 (Relics), :1114 (auspex), :1118 (Auspex), :1125 (patron's sigil, boons), :1159 (No boon, Fleet boons), :1164, 1197 (Salvage the field), :1165 (offers a boon), :1209 (Salvaged refits); map3d.gd:812 (in its favour, relic 4), :817 (relic%s); campaign.gd:1504 (a relic), :1920 (The seer smiles), :1924 (Relic gained), :1926 (No relics), :1952 (The saint answers), :2075 (Salvage: +); plus godot/campaign/data/campaign_tables.json (exported from d8b47c6).

G2/G3 (CLS_NAME consumers in Row 4.0): godot/ui/battle/hud.gd:384, :448, godot/scenes/battle/battle.gd ship panel class lines, godot/ui/campaign/campaign_ui.gd:631, :1198, and godot/ui/campaign/map3d.gd tooltips (rename_map_final.md:115) still show raw cls strings (Battle-barge, Bio-titan, Ark, Tomb-ark) until tables are re-exported and clsName is wired in GDScript.

[NOTE] Critical assessment of chair_grep_CD.md and battle.gd custom tooltip strings (UNSURE)

Evidence: chair_grep_CD.md:3-9, lore_bible_r8.md:86-96, and parity_records.md:24.

Detail: chair_grep_CD.md provides strong evidence that the 33 specific retired words from brief.md:21-27 were cleared from display strings in the 9 B-owned browser files at 806233f. However, three limitations make chair_grep_CD.md incomplete as proof of zero surviving retired words (UNSURE):

First, the chair grep only sampled the 443+ nonzero hits (Ithar 71; Deathless 66; Dynasty 1; Hellfire 2; Gauss 15; Pulsar 8; patron 48; boon 141; favour 15; sigil 5; relic 64; Ember Choir 1; Martyr 6, plus uncounted Corsair hits) rather than auditing every hit exhaustively (chair_grep_CD.md:7, 9).

Second, the chair grep did not search for the other retired 40k/Aeldari/Necron/Tyranid never-say words in lore_bible_r8.md:86-96, 340, 399, 470 (warp, auspex, cogitator, void shield, astropath, psyker, archeotech, xeno, rite, heresy, tithe, seer, wraithbone, shuriken, tomb, necropolis, living metal, scarab, phylactery, reanimate, hive, synapse, razorfiend, song).

Third, parity_records.md:24 states that for battle tooltip and legend helpers (factionTraitLines, cantFireReason, cmdNext, ramFrom, terrainPresent, TERRAIN_INFO, FAC_RULES, CMD_HOLD, WING_PERKS), "G2's battle scene writes its own text". Yet rename_map_final.md maps only two strings in godot/scenes/battle/battle.gd (:2884 Endless legion and :2956 Fleet boons, rename_map_final.md:72, 153), while battle.js:478, 481, 1109 (Ithar hulls cannot Brace, Corsairs field no lance weapons, Imperial broadside, Hive regrowth, Rise again) have no corresponding battle.gd rows in the map (UNSURE whether battle.gd hardcodes any of those strings, as battle.gd is not in the pack).

Job C3: Vetoable Calls (V1 to V18, V14 Ruling, and Section 5c)

V1 (Tagline, rename_map_final.md:28, 281, 308):

Verdict: Fits the bible (lore_bible_r8.md:54, 61). Replaces "Command a crusade of gothic capital ships..." with faction-neutral "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain.".

Collision check: None (descriptive sentence).

V2 (Faction blurbs, rename_map_final.md:37-42, 309, data.js:111-125):

Verdict: Problem (FIX) on the Eclipse blurb at data.js:125 (rename_map_final.md:42); the other five blurbs fit lore_bible_r8.md. As detailed in C1 Finding 1, data.js:125 says "stealing starlight to light a new sun", contradicting the Round 8 change (lore_bible_r8.md:14, context_CD_full.md:82 R58: "Energy, not light. Eclipse siphon stellar energy").

Collision check: None.

Alternative: Change data.js:125 (rename_map_final.md:42) to: blurb:'Starwright minds in machine bodies, siphoning stellar energy to light a new sun. Null weapons cut through shields and armor, and wrecks rebuild themselves.'.

V3 (Ship classes display map, rename_map_final.md:115, 310):

Verdict: Fits the bible (lore_bible_r8.md:319, 382, 444, 504). Keeping cls as an internal key and mapping 'Battle-barge':'War-barge', 'Bio-titan':'Colossus', 'Ark':'Lattice-ship', and 'Tomb-ark':'Archive-ship' via CLS_NAME avoids breaking model/FX lookups while giving The Unfinished (lore_bible_r8.md:444) a fitting class name (Lattice-ship).

Collision check: No franchise collisions found for Lattice-ship, War-barge, Colossus, or Archive-ship.

V4 (Crusade admirals, rename_map_final.md:180-181, 311, data.js:203-204):

Verdict: Fits the bible (lore_bible_r8.md:207-212). Admiral Roderic Vex replaces the 40k rank Castellan, Oath-Captain Malek Draven is canonical, and Commodore Sera Ashgrove and High Admiral Oryn Thale fit Section 2.10.

Collision check: No collisions found for "Roderic Vex", "Malek Draven", "Sera Ashgrove", or "Oryn Thale".

V5 (Hullbreaker admirals, rename_map_final.md:185-187, 312, data.js:219-221):

Verdict: Fits the bible (lore_bible_r8.md:273, 309). Warlord Grax Steelgrin, Old Mott, Sable the Smiling Knife, and Vesh the Collector remove human surnames (Venn, Brannigan) and Age of Sigmar Ironjaw, while Sable fits a furred predator species.

Collision check: No collisions found for "Grax Steelgrin", "Sable the Smiling Knife", "Old Mott", or "Vesh the Collector".

V6 (Glasswright admirals, rename_map_final.md:191-196, 313, data.js:227-230):

Verdict: Fits the bible (lore_bible_r8.md:438). Tamsa of the Clear Aperture, Saro of Long Focus (Command Burning glass), Vell of the Third Mirror (Command Scatter the light), and Brin of the Fourth Lens use the exact personal names and optical family lines from Section 6.9 and skip Corin to avoid colliding with Hegemony Admiral Corin Reyes.

Collision check: No collisions found for "Tamsa of the Clear Aperture", "Saro of Long Focus", "Vell of the Third Mirror", or "Brin of the Fourth Lens".

V7 (Eclipse admirals by doctrine, rename_map_final.md:197-205, 314, data.js:231-234):

Verdict: Fits the bible (lore_bible_r8.md:472, 499). Maps nekhet to Nadir Aurex, Ninth Frame (regrowth/broken ring mind, Command Release the repair swarms), sekhmar to Umbra Vessane, Third-Housed (corona-arc offence, Command Noon volley), anuket to Ostrel of the Long Copy (silent flanker, Command Out of the shadow), and khepra to Seveth, Twice-Restored (armour/durability, Command Sunshade wall).

Collision check: No collisions found for "Nadir Aurex", "Umbra Vessane", "Ostrel of the Long Copy", or "Seveth, Twice-Restored".

V8 (Name pools: Nemesis parts, captains, and ship names, rename_map_final.md:239-274, 315, Section 9):

Verdict: Problem (FIX) due to external franchise collisions in the ship-name pools (lore_bible_r8.md:111, 340), one Section 5c "Salvage" clash (ui3d.js:20), and Hegemony Captain/Nemesis first-name overlap (data.js:471, 519).

Collision check (with primary sources):

Thornback (ui3d.js:21, Chorus skirmish ship pool, rename_map_final.md:271): Direct collision with the Warhammer 40k Tyranid Carnifex sub-species/biomorph Thornback (Lexicanum: Thornback), violating lore_bible_r8.md:111, 340.

Shrieker (ui3d.js:21, Chorus skirmish ship pool, rename_map_final.md:271): Direct collision with the StarCraft II Zerg bio-structure Shrieker (StarCraft Wiki: Shrieker) and Warhammer 40k Eldar Shrieker (Lexicanum: Shrieker).

Everwatch (data.js:252, Crusade ship pool, rename_map_final.md:267, also in lore_bible_r8.md:209): Collides with the Warhammer 40k Ordo Xenos spacecraft The Everwatch in Kill Team: Into the Dark (Lexicanum: Everwatch (Ordo Xenos)).

Unyielding Oath (data.js:252, Crusade ship pool, rename_map_final.md:267, also in lore_bible_r8.md:209): Collides with the Assault class Prestige Perk Unyielding Oath in Warhammer 40,000: Space Marine 2 (r/Spacemarine: How does the Unyielding Oath Work?).

Oathkeeper (data.js:252, Crusade ship pool, rename_map_final.md:267): Collides with the Warhammer 40k Space Marine Warlord Trait Oathkeeper (New Recruit 40k Wiki: Oathkeeper) and xenos prisoner Oathkeeper (Lexicanum: Oathkeeper).

Moonveil (ui3d.js:22, Glasswright skirmish ship pool, rename_map_final.md:272): Famous katana in Elden Ring (Steam Elden Ring Discussion: Moonveil).

Moonsorrow (data.js:528, Glasswright campaign ship pool, rename_map_final.md:269): Finnish pagan metal band (Wikipedia: Moonsorrow).

Alternatives:

In ui3d.js:21 (Chorus): replace 'Thornback' with 'Spineback' and 'Shrieker' with 'Rasp-throat'.

In ui3d.js:22 and data.js:528 (Glasswrights): replace 'Moonveil' with 'Prismveil' and 'Moonsorrow' with 'Cold Spectrum'.

In ui3d.js:20 (Hullbreakers): replace 'Salvage Right' (which violates Section 5c) with 'First Claim'.

In data.js:252 (Crusade, if replacing the 40k echoes): replace 'Everwatch' with 'Cold Watch', 'Unyielding Oath' with 'Unbroken Oath', and 'Oathkeeper' with 'Sworn Roll'.

In data.js:519 (Hegemony captains): replace 'Konrad' and 'Marit' (which duplicate NEM_FAC.hegemony.pre at data.js:471) with 'Lukas' and 'Anke'.

V9 (Cores: sync tiers and renamed protocols, rename_map_final.md:56-64, 316, data.js:588, 625, 631, 659, 660, 666, 677):

Verdict: Fits the bible (lore_bible_r8.md:119-131). Listening, Partial sync, Synced, Full sync and protocol names Unbent Plating, Incendiary Warheads, Hot Tubes, Brood Harvest, and Fortress (freeing Bastion for the Crusade battleship) fit the hardware theme.

Collision check: Generic military/hardware phrases; no proprietary collisions.

V10 (Faction-power strings, rename_map_final.md:151-153, 219-227, 317):

Verdict: Fits the bible (lore_bible_r8.md:49, 159, 200, 412, 434, 464, 481). A wall of names + Keep the dawn watch, answered the tone, Back up the fleet, A siphon array / A dormant hull yard, and Archive restore cleanly replace void-shrine, joined the song, Waken the legion, tomb-world, and Endless legion.

Collision check: None.

V11 (Events, rename_map_final.md:208-226, 318):

Verdict: Fits the bible (lore_bible_r8.md:86-96, 399, 439). Replaces astropath with signals officer and founders' beacon, Ithar seer with Glasswright wanderer and keeper, tithe vault with toll vault, pirate haven with raider den, and "The saint answers" with "Luck holds".

Collision check: None.

V12 (Nova cannon to Spinal cannon, rename_map_final.md:110-112, 319, data.js:136; ui3d.js:449; battle.js:1211; godot/rules/rules.gd:3530):

Verdict: Fits the bible (lore_bible_r8.md:111). Removes Battlefleet Gothic's Nova cannon in favor of generic sci-fi Spinal cannon.

Collision check: Generic sci-fi naval term (used across Traveller, The Expanse, and Machineries of Empire: Machineries of Empire Wiki: Spinal cannon); no franchise lock.

V13 (Battle shapes, rename_map_final.md:124-129, 320, 332, battle.js:18; ui3d.js:15):

Verdict: Fits the bible with minor tension (NOTE). Hollow Sun (canonical) and Giant wreck (freeing Colossus for The Ninefold Maw) fit cleanly, while Rock shoals and kept Archipelago retain mild nautical/island metaphors against lore_bible_r8.md:112 (Rule 1.4.2: "Space, not sea").

Collision check: None.

Alternative: If strict "Space, not sea" wording is preferred for terrain shapes, use Shard belt and Rock clusters (battle.js:18).

V14 (Vetoed by Opus: relic becomes salvage, Section 5b, rename_map_final.md:172-189, 321):

Verdict: Fits the bible (lore_bible_r8.md:96, 271). Consistently replaces the forbidden display word relic with uncountable salvage or a piece of salvage across all 24 rows in Section 5b while keeping internal ids unchanged (minor NOTE on the apostrophe in Founders' salvage at data.js:247, rename_map_final.md:174).

Collision check: None.

Section 5c (Keep salvage to one meaning, rename_map_final.md:190-200):

Verdict: Problem (FIX) because while the 10 rows in Section 5c (Strip, Strip the wrecks, Recovered refits, Scrap rig, Spoils: +N credits) are sound, two other rows in the map still use "Salvage" in the old wreck-stripping sense: salvage:'Salvage swarm' (data.js:269, rename_map_final.md:169; data.js:271 at 806233f per chair_grep_CD.md:7) and ship name 'Salvage Right' (ui3d.js:20, rename_map_final.md:271).

Collision check: None.

Alternative: Rename salvage:'Salvage swarm' (data.js:269) to salvage:'Stripper swarm' (or salvage:'Matter collector') and 'Salvage Right' (ui3d.js:20) to 'First Claim'.

V15 (Arc unlocks, rename_map_final.md:237-242, 287-292, 322, data.js:564-569; godot/story/data/arcs.json:9-49):

Verdict: Fits the bible (lore_bible_r8.md:166, 213, 260, 284, 319, 382, 444, 446, 504). Vigil lance-cruiser, Cordon column escort, Trophy wrecker, Sun-eater bladeback, Ringing aperture, and Archive guard flare remove lantern-cruiser (forbidden by lore_bible_r8.md:166) and align data.js:569 with godot/story/data/arcs.json:49.

Collision check: No ship/unit collisions (only a trivial Battlefield 4 achievement named "Trophy Wrecker": YouTube: Battlefield 4 Trophy Wrecker Guide).

V16 (Run-end headlines, rename_map_final.md:44, 323, campaign_meta.js:178):

Verdict: Fits the bible (lore_bible_r8.md:305, 435, 495). Strongest keeps it, The light is kept, and Noon returns directly echo each faction's bible saying.

Collision check: None.

V17 (Refits and salvage items not named in the bible, rename_map_final.md:144-171, 324, Section 5):

Verdict: Problem (FIX) on two specific items in data.js:269 (rename_map_final.md:169): salvage:'Salvage swarm' violates Section 5c's one-meaning rule for "salvage", and logbook:'The Archive' collides with the Eclipse civilization's central mind repository the Archive (lore_bible_r8.md:477, 506, see Job C4). All other V17 refits and salvage items fit their faction motifs.

Collision check: No external franchise collisions.

Alternative: At data.js:269 (rename_map_final.md:169), change salvage:'Salvage swarm' to salvage:'Stripper swarm' and logbook:'The Archive' to logbook:'Archive index' (or logbook:'Copy ledger').

V18 (Small ones, rename_map_final.md:170, 184, 190, 268, 270, 325):

Verdict: Fits the bible (lore_bible_r8.md:107, 119, 256, 339). Shield wall order, Recovery crews, Spitting volley, Acid tide, and Hegemony ship names HNS Optimal, HNS Consensus, HNS Projection, HNS Punctual, HNS Comptroller, HNS Allocation, and HNS Forecast match the bible.

Collision check: None.

Job C4: Internal Clashes (Bible Rule 1.4: One Name, One Owner)

[FIX] Five new strings used identically for both a Player Refit/Salvage/Weapon and a Nemesis Adaptation (NEM_ADAPT_FAC)

Evidence: rename_map_final.md:107, 154, 155, 159, 165 vs rename_map_final.md:257-260 (data.js:35, 261, 262, 263, 268 vs data.js:481, 482, 483, 485).

Detail: Five display strings are assigned to two different game mechanics (a player-equippable weapon/refit/salvage item AND an enemy Nemesis counter-adaptation in NEM_ADAPT_FAC):

'Prism matrix': Glasswright lattice salvage item (data.js:268, rename_map_final.md:165) AND Glasswright Nemesis shields adaptation (data.js:482, rename_map_final.md:259).

'Waveguide spine': Glasswright prow refit module (data.js:262, rename_map_final.md:155) AND Glasswright Nemesis armor adaptation (data.js:482, rename_map_final.md:258).

'Tasting pores': Chorus auspex refit module (data.js:261, rename_map_final.md:154) AND Chorus Nemesis aim adaptation (data.js:483, rename_map_final.md:259).

'Long-memory sight': Eclipse auspex refit module (data.js:263, rename_map_final.md:159) AND Eclipse Nemesis aim adaptation (data.js:481, rename_map_final.md:257).

'Spark flak': Crusade flak weapon (data.js:35, rename_map_final.md:107) AND Crusade Nemesis pd adaptation (data.js:485, rename_map_final.md:260). (In addition, 'Null spire' at data.js:40 and 'Interferometer lens' at data.js:262 differ only by plural 's' from 'Null spires' at data.js:481 and 'Interferometer lenses' at data.js:482.)

[FIX] The Archive used for both an Eclipse salvage item and the Eclipse civilization's central mind repository

Evidence: rename_map_final.md:169 (data.js:269) vs lore_bible_r8.md:477, 506 and rename_map_final.md:151, 160, 218, 224.

Detail: data.js:269 renames the Eclipse logbook piece of salvage to 'The Archive', which is the exact name of the civilization-wide backup megastructure in the Ardent system (lore_bible_r8.md:477, 506).

[FIX] Hegemony first names Konrad and Marit shared between player Captain pool and Nemesis pool

Evidence: rename_map_final.md:250 (data.js:471, NEM_FAC.hegemony.pre) vs rename_map_final.md:259 (data.js:519, CAPTAINS.hegemony.first) and lore_bible_r8.md:113 (Rule 1.4.3).

Detail: L replaced 'Ilsa' with 'Marit' in both NEM_FAC.hegemony.pre (data.js:471) and CAPTAINS.hegemony.first (data.js:519), and left 'Konrad' in both lists, so Hegemony captains and Hegemony Nemeses roll the same given names Konrad and Marit.

[FIX] 'The Unbroken' shared between Hegemony Nemesis scar and Eclipse skirmish ship name

Evidence: rename_map_final.md:253 (data.js:472, NEM_FAC.hegemony.scars) vs rename_map_final.md:273 (ui3d.js:23, FNAMES.deathless).

Detail: L removed 'the Unbroken' from Eclipse captain epithets at data.js:523 (rename_map_final.md:264), but kept 'the Unbroken' in NEM_FAC.hegemony.scars (data.js:472) while also keeping 'The Unbroken' as an Eclipse ship name in ui3d.js:23.

[FIX] Salvage swarm and Salvage Right clash with Salvage the item type (Section 5c)

Evidence: rename_map_final.md:169, 190, 271 (data.js:269, ui3d.js:20) and chair_grep_CD.md:7.

Detail: As noted under Job C3 (Section 5c), both strings retain "Salvage" in the old wreck-stripping sense that Section 5c retired.

[NOTE] Duplicate ship names across campaign and skirmish pools and shared rank/Nemesis titles

Evidence: rename_map_final.md:240, 242, 245, 251, 261, 263, 264, 269, 272 (data.js:459, 462, 465, 471, 520, 522, 523, 528; ui3d.js:22).

Detail: Glasswright ship name 'Starfall' appears in both data.js:528 and ui3d.js:22. Also, per the bible and map, Warlord (Hullbreakers), Nadir (Eclipse), Lens-keeper (Glasswrights), and First Admiral (Hegemony) appear in both captain/admiral ranks and NEM_FAC Nemesis title pools.

Audit D: Rollout Landing Verification by Stream
Stream B (Commit 90aaf85, port_notes.md Step 10)

Claims vs map and chair grep (port_notes_steps_CD.md:29-37, chair_grep_CD.md:3-9): Hold. Step 10 applied all B-owned rows across data.js, battle.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, and head.html (331 replacements covering Sections 1 to 10, including 5b and 5c), added CLS_NAME and clsName(c) to data.js with display call-sites in ui3d.js and campaign_run.js, kept all internal ids and PRNG draws unchanged (SEED=5 ADMS=grax bossmatrix 4 identical at 85% r8.3), and passed the check pack with 0 FAIL (14 CHECK); b1 39 ok, b3 17 ok, b4 29 ok, backlog 11 ok. chair_grep_CD.md:5-9 confirms 0 hits for 21 of the brief's retired words across the 9 browser files at 806233f and confirms sampled hits on the remaining 13 words are ids, keys, CSS classes, or code comments.

Changes beyond display strings (port_notes_steps_CD.md:33-34): Step 10 added the CLS_NAME dictionary and clsName(c) helper function in data.js (plus call-sites in ui3d.js and campaign_run.js per Row 4.0, rename_map_final.md:115) and updated expected display strings in b1_tests. No rules, data shapes, or save keys changed. (Full line-by-line git diff of 90aaf85 is not in the pack, so any unmentioned diff lines are UNSURE.)

Stream G2 (Commits 49f0d85, 239fdeb, ef5cab2)

Tagline vs V1 (rename_map_final.md:28, 281, 308): Matches V1 word-for-word (const TAGLINE := "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." marked applied: godot/ui/battle/brand.gd:11 at rename_map_final.md:281). All other G2 table rows in Sections 2, 4, 5b, 9.4, and 10.2 are also marked applied: (godot/main/FEATURES.md:15, godot/scenes/battle/battle.gd:2884, 2956, godot/main/campaign_fallback_ui.gd:7, 12, godot/scenes/campaign/campaign_scene.gd:59).

[NOTE] Unapplied G2 class display lookups (rename_map_final.md:115): Row 4.0's GDScript locations for G2 (godot/ui/battle/hud.gd:384, :448 and godot/scenes/battle/battle.gd ship panel class lines) are not marked applied: because CLS_NAME awaits G1's table re-export.

Changes outside display strings (context_CD_full.md:30, rename_map_final.md:287): Commit 49f0d85 updated project.godot and export_presets.cfg window title and product metadata while keeping Voidsworn.exe and the user://voidsworn_* save folder unchanged; ef5cab2 ran the exe launch test (context_CD_full.md:30). (Raw git diffs for 49f0d85, 239fdeb, and ef5cab2 are not in the pack: UNSURE.)

Streams G1 and G3 (parity_records.md: G1 Parity README and Campaign RECORD)

Do the parity records name a commit after B's strings step (90aaf85)? No.

G1 (contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md, parity_records.md:7-20): Names commit bdb1a9d (with seed 9 sweep at 803f72d per context_CD_full.md:29), pinned to JS oracle cb55ec9 (stream B steps 0 to 7b). At bdb1a9d, all checks pass (48 of 48 golden battles, 316,090 maths values with 0 diffs, PRNG 3/3, threat overlay 3/3, threads PASS, and 200-battle sweep seed 9 with 200 of 200 identical across 38,235 records). However, bdb1a9d predates both B's Step 9 (d551697) and B's Step 10 (90aaf85).

G3 (godot/campaign/test/RECORD.md, parity_records.md:122-145): Names commit 9711a7e (with Godot campaign rules last changed at ae6073b), pinned to JS oracle d8b47c6 (Oct 26, stream B steps 0 to 4). At 9711a7e, all checks pass (30 of 30 seeded runs on PC and cloud, 64 Nemesis records, save_test.gd, arc_hook_test.gd). However, 9711a7e and its oracle d8b47c6 predate B's Steps 5 to 7b (cb55ec9), Step 9 (d551697), and Step 10 (90aaf85).

Does this match the plan in HANDOFF section 0? Sequencing G1 and G3 after B's strings step matches the "Still to do" column in context_CD_full.md:29, 31. However, there is one concrete cross-stream routing flaw in that plan:

[FIX] Unrouted Step 9 RAMP and Steps 5-7b gap in G3's campaign parity plan (port_notes_steps_CD.md:13, parity_records.md:25, 27, 124, context_CD_full.md:29, 31): Step 9 (d551697, port_notes_steps_CD.md:13) modified battle.js RAMP (grow, thin, boss budgets for campaign enemy fleets) and labeled the rule change G1: battle.js RAMP, campaign enemy fleets only, and HANDOFF.md section 0 (context_CD_full.md:29) assigned "Port step 9" only to G1. However, G1's parity README (parity_records.md:25) states that battle.js campaign encounter functions (fitEncounter, rollEncounter, bossEncounter) are JS-only for G1 and are ported by G3 in godot/campaign/campaign.gd. Furthermore, G3's oracle is still at d8b47c6 (Step 4) and has not yet been tested against Steps 5 to 7b (parity_records.md:27). When G3 re-pins its oracle from d8b47c6 to 90aaf85 as instructed in context_CD_full.md:31, G3 will pick up Steps 5 to 9 simultaneously and will fail parity unless G3 also ports any Step 5-9 campaign/encounter changes (including RAMP if hardcoded in campaign.gd).

Stream L (Story and Portraits Steps: Commits 1e65076, 257de44, 7fb50db and Map Sections 11 and 12)

Commit log lines for 1e65076, 257de44, 7fb50db: NOT CHECKED (UNSURE) because context_CD_full.md ends its status table at 144dc71 (context_CD_full.md:22) and does not include the commit log lines or diffs for 1e65076, 257de44, or 7fb50db.

Contradictions found in rename_map_final.md Sections 11 and 12 against the pack:

[NOTE] Commit attribution mismatch on e243729 vs 494c000 (rename_map_final.md:295 vs context_CD_full.md:34): Section 12 of the map (rename_map_final.md:295) states "P landed the round 8 prompts in e243729", whereas HANDOFF section 0 (context_CD_full.md:34) states e243729 was the six faction crests (crests/faction_<id>.svg) and 494c000 was the round 8 prompts and scar prompts.

[FIX] "the the Chorus" / "the Eclipse" template bug in Section 12 (rename_map_final.md:303, tools/portraits/make_batches.py:193,205): As detailed in Job C1 Finding 2, substituting "the Chorus" and "Eclipse" into 'A Nemesis of the %s...' without removing the  produces "A Nemesis of the the Chorus" and "A Nemesis of the Eclipse".

[NOTE] Incomplete feminine pronoun fallback list in Section 11 (rename_map_final.md:294, godot/story/tokens.gd:19): Row 11 (rename_map_final.md:294) instructs L to drop 16 old feminine names from tokens.gd:19 (const FEMININE), but omits Siriel (dropped from CAPTAINS.ithar.first at data.js:522, rename_map_final.md:263) and Mirelle (replaced by Brin of the Fourth Lens at data.js:230, rename_map_final.md:196), and does not add Brin (or Vessane / Ostrel if feminine) to FEMININE (UNSURE on tokens.gd contents at 806233f).

Not Checked

Commit lines and diffs for L's story and portraits commits (1e65076, 257de44, 7fb50db): NOT CHECKED because context_CD_full.md was snapshotted at 144dc71 and does not include those commit log lines or file diffs.

Raw git diffs for B's commit 90aaf85 and G2's commits 49f0d85, 239fdeb, ef5cab2: NOT CHECKED beyond the summaries in port_notes_steps_CD.md, context_CD_full.md, rename_map_final.md, and chair_grep_CD.md because the raw commit patches and source files are not attached in the pack.

Direct repo grep of godot/, tools/, and the 9 browser files for retired words outside the chair's 33-word list: NOT CHECKED directly because only the 9 evidence markdown files are attached; evaluated from rename_map_final.md and chair_grep_CD.md.

Audit E items in brief.md (G4 20-ship bench, Stream B balance pass, A4 pass 5 ship shots, G2 movement clips, portrait and crest contact sheets): NOT CHECKED as this leg prompt (leg_prompt_CD.md) scopes this report strictly to Audits C and D.

For additional context on the Warhammer 40,000: Space Marine 2 perk name collision flagged under V8 (Unyielding Oath at data.js:252), see this Space Marine 2 Unyielding Oath perk breakdown discussing how the perk operates in that game.
