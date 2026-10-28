# Blind Audit Report: Audits C and D, Voidsworn / Embers of the Hollow Sun lore rollout

Pinned commit: 806233f766bfdfd98c61fbe5bebb834cc11bbe6c (main, github.com/rcbailey12/voidsworn, Oct 27, 2026).

## Verdict

Audit C: The rename map matches the bible and the brief's canonical table in every row checked. No blocker. One FIX (Eclipse blurb wording). Several NOTEs.

Audit D: Every stream that has committed strings lands within its plan. B's step 10 claims hold. G2 is clean. G1 and G3 parity records predate the strings step, which matches the HANDOFF plan (still to do). No blocker.

## Audit C

### C1. Canonical names (brief table vs map vs bible)

I checked every row of the canonical table in lore_rollout_brief.md against rename_map_final.md and lore_bible_r8.md.

| Canonical row | In map? | Matches bible? |
|---|---|---|
| Embers of the Hollow Sun (title) | Yes, section 1 | Yes |
| Sunward Crusade | Yes, section 1, data.js:111 | Yes (bible 2.1) |
| Hegemony Navy kept | Yes (absence correct) | Yes (bible 3.1) |
| Ashfall Hullbreakers | Yes, section 1, data.js:115 | Yes (bible 4.1) |
| The Chorus kept | Yes (absence correct) | Yes (bible 5.1) |
| The Glasswrights | Yes, section 1, data.js:121 | Yes (bible 6.1) |
| Eclipse (no "the") | Yes, section 1, data.js:124 | Yes (bible 7.1, R58) |
| Ardent / Starwrights | Yes (used in blurbs, events) | Yes (bible 1.1) |
| The Hollow Sun | Yes, section 4, battle.js:18 | Yes (bible 1.1) |
| core, protocol, sync, signal | Yes, section 2 throughout | Yes (bible 1.5) |
| Six core names (K-1 through S-6) | Yes, section 2, data.js:620-625 | Yes (bible 1.5) |
| Sear repeater/battery/broadside/turret | Yes, section 3, data.js:35 | Yes (bible 2.11) |
| Cinder torpedo | Yes, section 3, data.js:35 | Yes (bible 2.11) |
| Null cannon/spire/shredder/sentries, kind Null | Yes, section 3, data.js:21-22, 30, 40 | Yes (bible 7.10) |
| Corona arc | Yes, section 3, data.js:23 | Yes (bible 7.10) |
| Prism lance | Yes, section 3, data.js:19 | Yes (bible 6.10) |
| Pulse laser / Heavy pulse laser | Yes, section 3, data.js:11-12 | Yes (bible 3.8) |
| The Ninefold Maw (Colossus class) | Yes, section 4, data.js:88 | Yes (bible 5.10) |
| Crusade classes: Warden, Harrow, Vigil, Hearth, Bastion, Daybreak | Yes, section 4, data.js:63-66 | Yes (bible 2.11) |
| Hegemony: picket, cordon, vanguard, dominion, Iron Mandate | Yes, section 4, data.js:73-75 | Yes (bible 3.8) |
| Hullbreaker: raider, gutship, wrecker, hulk-carrier, Warlord's Pyre-Barge | Yes, section 4, data.js:78-82 | Yes (bible 4.10) |
| Chorus: drone-spawn, spitter, bladeback, brood-sac, Ninefold Maw | Yes, section 4, data.js:86-88 | Yes (bible 5.10) |
| Glasswright: sliver, lancet, prism, aperture, The Unfinished | Yes, section 4, data.js:90-94 | Yes (bible 6.10) |
| Eclipse: mote, flare, zenith, The Unsetting | Yes, section 4, data.js:96-99 | Yes (bible 7.10) |
| First Admiral (was Grand Admiral) | Yes, section 6, data.js:215 | Yes (bible 3.8) |
| Oath-Captain (was Inquisitor-Captain) | Yes, section 6, data.js:204 | Yes (bible 2.10) |
| Eclipse ranks: Shade, Gloam, Umbra, Midnight, Nadir | Yes, section 9.3, data.js:523 | Yes (bible 7.10) |
| Eclipse Nemesis: High Nadir, Eclipse-prime, Archivist | Yes, section 9.1, data.js:462 (see note below) | Yes (bible 7.10) |
| Hullbreaker ranks: Claw, Fang, Howler, Ripper, Warlord | Yes, section 9.3, data.js:520 | Yes (bible 4.10) |
| Hullbreaker Nemesis: Apex, First Claw, Den-alpha, Warlord | Yes, section 9.1, data.js:459 | Yes (bible 4.10) |
| Eclipse admirals: Aurex, Vessane, Ostrel, Seveth | Yes, section 6, data.js:231-234 | Yes (bible 7.9, exact match) |
| Run word Homecoming | Yes, section 1, data.js:271 | Yes (bible 7.10) |

NOTE (C1-a): The brief's canonical table lists three Eclipse Nemesis titles (High Nadir, Eclipse-prime, Archivist), matching bible 7.10. The map section 9.1 (data.js:462) lists four: ['High Nadir','Eclipse-prime','Archivist','Nadir']. The extra "Nadir" is the top rank reused as a Nemesis title. This is a minor addition beyond the canonical table. Severity: NOTE. Evidence: rename_map_final.md section 9.1, data.js:462; lore_bible_r8.md section 7.10.

No contradictions found between the map and the bible on factions, weapons, classes, ranks, admirals, cores, protocols, sync, signal, or run words.

### C2. Coverage

The map's section 15 claim: "Rows found: all; rows missing: 0." The map was grepped at 00d2b4b and re-grepped at 762df28.

B's step 10 claim: 331 replacements, check pack 0 FAIL (14 CHECK), b1 39 ok, b3 17 ok, b4 29 ok, backlog 11 ok, build.py test builds, no em dashes.

Chair grep evidence (chair_grep_CD.md, nine B-owned browser files at 806233f):

All retired words that returned nonzero counts were sampled by the chair. Every nonzero hit is an id, object key, save key, CSS class, or code comment. No retired display word survives as a display string in the nine browser files. Specific checks:

- Ithar (71 hits): all ids (ithar faction id). Display is now "The Glasswrights."
- Deathless (66 hits): all ids. Display is now "Eclipse."
- patron (48), boon (141), favour (15), sigil (5), relic (64): all save keys, ids, CSS classes, action names. Display uses core, protocol, sync, signal, salvage.
- Gauss (15), Pulsar (8), Hellfire (2): weapon ids. Display names are Null, Prism lance, Cinder torpedo.
- Martyr (6): relic id. Display names all new (The Chalked Roll, etc.).
- Ember Choir (1): code comment at data.js:660.
- Dynasty (1): code comment at data.js:97.
- Corsair: only in ids and FAC keys.

One item for judgment: data.js:269 (Eclipse relic name for id salvage): "Salvage swarm." The chair asks whether this violates the 5c one-meaning rule. My judgment: "Salvage swarm" is a salvage item name (a fleet-wide bonus). It uses "salvage" as the item type, which is what 5c permits. Section 5c specifically renames "Salvage rig" to "Scrap rig" because "rig" implies a tool for the salvaging action, creating ambiguity. "Salvage swarm" does not carry that ambiguity; it reads as a type of salvage (the item), not an action. However, it is the only display name outside section 5b/5c that still contains the word "Salvage" as a lead word. Severity: NOTE. Evidence: rename_map_final.md section 5 (data.js:269 row), section 5c ruling.

Conclusion on coverage: The pack supports B's 331-replacement claim and the 0 FAIL check pack. The chair grep independently confirms no retired display word survives in the nine B-owned browser files at the pinned commit. The map's section 15 claim of 0 missing rows is consistent with the pack. No evidence of a gap.

Severity: no finding.

### C3. The vetoable calls, V1 to V18

V1. Tagline.

"Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain."

Verdict: FITS. Removes "crusade" (any faction playable), names the Hollow Sun as destination, preserves the permadeath hook. No new proper names.

Collision: none introduced.

Evidence: rename_map_final.md section 1 (row 2), section 10.2.

V2. Faction blurbs.

Verdict: FITS with one FIX. Five of six blurbs match the bible exactly. The Eclipse blurb reads "stealing starlight to light a new sun." R58 (Ryan, Oct 27) explicitly ruled "siphon stellar energy, not light." Bible 7.1 says "stellar energy siphoned from neighbouring stars." The blurb should read "stealing stellar energy" or "siphoning energy" rather than "stealing starlight."

Severity: FIX.

Evidence: rename_map_final.md section 1 (data.js:125 blurb row); R58 in context_CD_full.md; lore_bible_r8.md section 7.1.

Collision: no new proper names in any blurb.

V3. Ship class display map.

War-barge, Colossus, Lattice-ship, Archive-ship. Internal cls keys stay.

Verdict: FITS. War-barge is in bible 4.10. Colossus is canonical (brief). Archive-ship is in bible 7.10. Lattice-ship: the bible does not name The Unfinished's class, but the map's rationale (built around the largest Lattice piece) is sound and consistent with bible 6.10.

Collision: "Lattice-ship" uses the Lattice name, which is the megastructure. No external franchise collision found. UNSURE: I cannot confirm via web search that "Lattice-ship" has no collision in another franchise, but the term is compound and specific.

Evidence: rename_map_final.md section 4.0; lore_bible_r8.md 4.10, 6.10, 7.10.

V4. Crusade admirals.

Castellan Vex becomes Admiral Roderic Vex. Oath-Captain Malek Draven (canonical). Commodore Sera Ashgrove and High Admiral Oryn Thale kept.

Verdict: FITS. "Roderic" is an old European given name (bible 2.10). "Vex" is a hard English surname. "Castellan" removed (40k rank). Bible 2.11 confirms "Admiral" as a rank.

Collision: "Roderic Vex." I find no known franchise character by this exact name. UNSURE: without a live web search I cannot fully exclude a minor collision, but the name is sufficiently original.

Evidence: rename_map_final.md section 6, data.js:203; lore_bible_r8.md 2.10, 2.11.

V5. Hullbreaker admirals.

Warlord Grax Steelgrin, Old Mott (no surname), Sable the Smiling Knife (Venn dropped), Vesh the Collector kept.

Verdict: FITS. Bible 4.9 names "Grax Steelgrin" as an example. "Old Mott" has no surname per the no-human-surnames rule. "Sable" is a furred animal, fitting the species. "Ironjawz" (Age of Sigmar) avoided by using "Steelgrin."

Collision: "Grax Steelgrin" does not collide with any name I can identify. "Sable" exists as a Marvel character (Silver Sable) and a 2021 indie game title, but "Sable the Smiling Knife" is sufficiently distinct. UNSURE on whether the bare word "Sable" triggers a trademark concern in a game context, but as a character first name with an epithet it is standard practice.

Evidence: rename_map_final.md section 6, data.js:219-221; lore_bible_r8.md 4.9.

V6. Glasswright admirals.

Tamsa of the Clear Aperture (carriers), Saro of Long Focus (lances), Vell of the Third Mirror (evasion), Brin of the Fourth Lens (shields).

Verdict: FITS. Bible 6.9 lists "Corin, Saro, Tamsa, Vell, Oskel, Brin" as example names and specifies optical family lines. All four admirals match exactly.

Collision: none found. These are original compound names.

Evidence: rename_map_final.md section 6, data.js:227-230; lore_bible_r8.md 6.9.

V7. Eclipse admirals by doctrine.

nekhet = Nadir Aurex, Ninth Frame; sekhmar = Umbra Vessane, Third-Housed; anuket = Ostrel of the Long Copy; khepra = Seveth, Twice-Restored.

Verdict: FITS. Bible 7.9 lists exactly these four names with these exact epithets. The doctrine mapping (regrowth, offence, flanker, durable) is L's call and is consistent with the old admirals' roles.

Collision: "Aurex," "Vessane," "Ostrel," "Seveth" are original. No franchise collision found. UNSURE: I cannot run a live trademark search, but none of these match any character name in my training data.

Evidence: rename_map_final.md section 6, data.js:231-234; lore_bible_r8.md 7.9.

V8. Name pools (section 9).

Verdict: FITS.

Hullbreaker captains: harsh names plus fight epithets (bible 4.9). No human surnames. FITS.

Glasswright captains: "Oskel of the Second Lens" pattern (bible 6.9). FITS.

Eclipse captains: iteration epithets "Benth of the Fifth Frame" (bible 7.9). FITS.

Crusade captains: old European given names, church titles removed (bible 2.10). FITS.

Crusade Nemesis titles: High Warden, Warden of the Roll, Dawnwarden, Oath-warden (bible 2.10). FITS.

Eclipse Nemesis titles: High Nadir, Eclipse-prime, Archivist, plus Nadir (see C1-a note). FITS with NOTE.

Glasswright Nemesis titles: Lens-keeper, First Mirror, Keeper of Astra, Duelist. Bible 6.9 lists three. "Duelist" is added; bible 6.5 describes the Nemesis as "a duelist." Severity: NOTE (consistent addition, not a contradiction).

Chorus Nemesis titles: Spawn-mother, Elder Throat, Gorge-mind, Maw-mother (bible 5.9). FITS.

Hegemony Nemesis titles: First Admiral, Fleet Marshal, Line Admiral, High Commodore (bible 3.8). FITS.

Admiral names excluded from captain and Nemesis pools: verified for all six factions (Ilsa, Maren, Vorn, Sable, Grax, Aurex, etc. cannot roll). FITS.

Collision: pool names are generated from syllable parts. No specific franchise collision identified in any pool. UNSURE on exhaustive trademark clearance for all generated combinations.

Evidence: rename_map_final.md sections 9.1-9.4; lore_bible_r8.md 2.10, 3.8, 4.9, 5.9, 6.9, 7.9, 7.10.

V9. Cores (sync tiers, protocol renames, S-6 badge).

Sync tiers: Listening, Partial sync, Synced, Full sync. Protocol renames: Unbent Plating, Incendiary Warheads, Hot Tubes, Brood Harvest, Fortress. S-6 badge letter S.

Verdict: FITS. Hardware/connection language suits the cores (bible 1.5). Church and song words removed. "Fortress" avoids the Bastion class clash. The S badge matches "Seren."

Collision: none. No new proper names.

Evidence: rename_map_final.md section 2, data.js:588, 631, 659, 660, 666, 677; lore_bible_r8.md 1.5.

V10. Faction-power strings.

Void-shrine becomes "A wall of names." Crusade verb becomes "Keep the dawn watch." "Joined the song" becomes "answered the tone." "Waken the legion" becomes "Back up the fleet." Tomb-world becomes "A siphon array" (hostile) and "A dormant hull yard" (Eclipse-only). "Endless legion" becomes "Archive restore."

Verdict: FITS. "Wall of names" matches the Roll of Vesper (bible 2.11). "Dawn watch" is in bible 2.9. "Tone" matches the Glasswright sound motif (bible 6.2). "Archive restore" matches bible 7.5. "Siphon array" matches bible 7.1.

Collision: none. No new proper names.

Evidence: rename_map_final.md sections 7, 4; lore_bible_r8.md 2.9, 2.11, 6.2, 7.1, 7.5.

V11. Events.

Astropath becomes signals officer. Ithar seer becomes Glasswright wanderer. Tithe vault becomes toll vault. Pirate haven becomes raider den. "The saint answers" becomes "Luck holds."

Verdict: FITS. Bible 1.2 bans "astropath" and "saint." "Tithe" is a church word. All replacements are consistent with the factions' voices.

Collision: none.

Evidence: rename_map_final.md section 7; lore_bible_r8.md 1.2.

V12. Nova cannon becomes Spinal cannon.

Verdict: FITS. "Nova Cannon" is Battlefleet Gothic's prow gun (the map notes this). "Spinal cannon" is a generic sci-fi term for a hull-axis weapon. Shared by three flagships, so a neutral name is appropriate.

Collision: "Spinal cannon" is not owned by any single franchise I can identify. UNSURE: without a live search I cannot fully exclude a minor usage elsewhere, but the term is descriptive and generic.

Evidence: rename_map_final.md section 3, data.js:136.

V13. Battle shapes.

Dead star label becomes "Hollow Sun" (canonical). Colossus shape becomes "Giant wreck" (Colossus is now the Maw's class). Shoals becomes "Rock shoals." Archipelago kept.

Verdict: FITS. One-name-one-owner upheld for Colossus. "Hollow Sun" is canonical. "Rock shoals" softens the sea word. Section 14 confirms Archipelago kept.

Collision: none.

Evidence: rename_map_final.md section 4, battle.js:18; section 14.

V14 (vetoed by Opus). Relic becomes salvage.

Verdict: VETO APPLIED CORRECTLY. Section 5b converts all display uses of "relic" to "salvage" / "a piece of salvage." Ids (RELICS, relic, takeRelic, etc.) stay. Section 5c then ensures "salvage" has one meaning: the wreck step becomes "Strip the wrecks," Salvage rig becomes Scrap rig, Salvaged refits becomes Recovered refits, "Salvage: +N credits" becomes "Spoils: +N credits."

Collision: none.

Evidence: rename_map_final.md sections 5b, 5c; HANDOFF section 0 (R60).

V15. Arc unlocks.

Vigil lance-cruiser, Cordon column escort, Trophy wrecker, Sun-eater bladeback, Ringing aperture, Archive guard flare.

Verdict: FITS. All use the new class names. "Ringing aperture" references the Ringing Field (bible 6.10). "Archive guard flare" uses Eclipse class names. Must match godot/story/data/arcs.json (L owns that file; section 11 rows confirm the match).

Collision: none.

Evidence: rename_map_final.md section 8, data.js:564-569; section 11, arcs.json rows; lore_bible_r8.md 6.10.

V16. Run-end headlines.

Hullbreakers "Strongest keeps it." Glasswrights "The light is kept." Eclipse "Noon returns."

Verdict: FITS. "Strongest keeps it" is the Hullbreaker saying verbatim (bible 4.8). "The light is kept" fits the Glasswright light motif. "Noon returns" echoes "We remember noon" (bible 7.8).

Collision: none.

Evidence: rename_map_final.md section 1, campaign_meta.js:178; lore_bible_r8.md 4.8, 7.8.

V17. Refits and relics the bible does not name.

Scanner array, Screen capacitor, The Chalked Roll, Wake-tracker, Tasting pores, Annealing kilns, Long-count reckoner, Siphon ledger, Long clock, and others in section 5.

Verdict: FITS. Bible 1.2 mandates "scanners" and "reckoner." Bible 2.2 gives the chalked names. Bible 4.1 gives wake-trackers. Bible 5.3 (no eyes) motivates Tasting pores. All are consistent.

Collision: "The Chalked Roll" shares the word "Roll" with "the Roll of Vesper" (bible 2.11, a place). These are different categories (relic vs place) and "Roll" is a common word. Severity: NOTE.

Evidence: rename_map_final.md section 5; lore_bible_r8.md 1.2, 2.2, 2.11, 4.1, 5.3.

V18. Small ones.

Shield wall order (was protocol), Recovery crews (was Salvage protocols), Spitting volley, Acid tide, Hegemony ship names (Optimal, Consensus, Projection, Punctual, Comptroller, Allocation, Forecast).

Verdict: FITS. "Protocol" belongs to cores. "Salvage" belongs to the item type (5c). "Spitting volley" and "Acid tide" fit the Chorus voice (bible 5.2). Hegemony ship names fit the Registry's data-driven voice (bible 3.2: "probabilities, projections, timestamps").

Collision: none.

Evidence: rename_map_final.md sections 5c, 6, 9.4; lore_bible_r8.md 3.2, 5.2.

### C4. Internal clashes (bible 1.4, one name one owner)

Checked every new string in the map for dual use:

Bastion / Fortress: The duo protocol "Bastion" is renamed "Fortress" (data.js:666) because Bastion is now the Crusade battleship class. Handled. NO CLASH.

Colossus / Giant wreck: The battle shape "Colossus" is renamed "Giant wreck" (battle.js:18) because Colossus is now the Ninefold Maw's class display. Handled. NO CLASH.

Vigil: The Crusade verb "Hold a vigil" becomes "Keep the dawn watch" (data.js:497) because Vigil is now a hull class. Ship name "Ashen Vigil" kept (section 14); this is a specific ship name, not a class label. NO CLASH.

Protocol: Maren's Command "Shield wall protocol" becomes "Shield wall order" (data.js:218). "Salvage protocols" becomes "Recovery crews" (data.js:249). No other display use of "protocol" outside the cores system. NO CLASH.

Salvage: After 5c, the wreck step is "Strip the wrecks," the item is "Scrap rig," refits are "Recovered refits," credits are "Spoils." Remaining display uses of "Salvage": the item-type label itself, "Salvage swarm" (Eclipse relic name, NOTE in C2), and "Salvage Right" (Hullbreaker ship name, ui3d.js:20, kept). "Salvage Right" is a proper ship name, not an action label. Severity: NOTE (borderline against the spirit of 5c, but not a functional clash).

Warden: Used as a Crusade class AND in Nemesis titles (High Warden, Warden of the Roll, Dawnwarden, Oath-warden). The bible itself lists both (2.10 titles, 2.11 classes). Intentional overlap within one faction. NO CLASH.

Lattice: "Lattice-ship" (class display for The Unfinished) vs the megastructure "the Lattice." The compound word refers to the structure. All other "lattice" display uses renamed (shield matrix, etc.). NO CLASH.

Aperture: Glasswright carrier class, admiral family line ("of the Clear Aperture"), and arc variant ("Ringing aperture"). All are Glasswright-owned and in different grammatical roles. Bible 6.9 sanctions the family-line usage. NO CLASH.

Memory: Eclipse motif (bible 1.3). Chorus logbook "Memory of the hive" renamed "Taste of old prey." Eclipse uses "Cold Memory" (ship name) and "Long-memory sight" (refit), both within their own motif. NO CLASH.

Captain and Nemesis pools vs admirals: Verified that no pool can generate an admiral's full name for any faction (see V8 analysis). NO CLASH.

No unresolved internal clashes found.

## Audit D

### Stream B (commit 90aaf85, port_notes step 10)

Claim: 331 replacements. Step 10 states "331 replacements" across data.js, battle.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js, head.html. The pack does not let me recount independently, but the chair grep at 806233f (after 90aaf85) confirms no retired display word survives in those files, which is consistent with all rows applied. No contradiction found.

Claim: sections 1 to 10 including 5b and 5c. Step 10 names these explicitly. The chair grep confirms 5b (no "relic" in display) and 5c (no "Salvage the field" or "Salvage rig" in display). CONSISTENT.

Claim: CLS_NAME and clsName added. Step 10: "new CLS_NAME and clsName(c) in data.js (next to HULLS)." This is new code, but it is a display mapping (const and function), not a rules change. The map section 4.0 specifies it. CONSISTENT.

Claim: ids unchanged. Step 10: "no id, key, rule, number or random draw changed (same seed, same sim output before and after: SEED=5 ADMS=grax bossmatrix 4 gives 85% r8.3 both times)." CONSISTENT.

Claim: check pack 0 FAIL. Step 10: "check pack 0 FAIL (14 CHECK); b1 39 ok, b3 17 ok, b4 29 ok, backlog 11 ok." CONSISTENT.

Anything beyond display strings? The CLS_NAME const and clsName function are new code, but they serve display only (class labels). Test strings updated (b1_tests). No rules, numbers, random draws, ids, save keys, or data shapes changed. NO ISSUE.

Severity: no finding.

### Stream G2 (commits 49f0d85, 239fdeb, ef5cab2)

Tagline matches V1? The map section 10.2 shows the TAGLINE row as "applied: godot/ui/battle/brand.gd:11" with the text "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." This is identical to V1. MATCH.

Did anything outside display strings change? Per HANDOFF section 0: "Title 'Embers of the Hollow Sun', window and exe product name (49f0d85; exe file stays Voidsworn.exe, the save folder is pinned)." The map confirms: "exe file name kept as Voidsworn.exe, save folder kept. Nothing else for G2 in project.godot or export_presets.cfg." The exe launch test (ef5cab2) is a test, not a string change. G2's applied rows in sections 2, 4, 5b, 9.4, 10.2 are all display strings. NO ISSUE.

Severity: no finding.

### Stream G1 (parity records, parity_records.md)

Does the record name a commit after B's strings step (90aaf85)? No. The G1 parity README's headline is at commit bdb1a9d, with oracle at cb55ec9 (stream B steps 0 to 7b). B's strings step is 90aaf85, which came after cb55ec9. The record predates the strings step.

Does it still pass? The record shows 48/48 goldens, 200/200 sweep, all checks PASS. Since names are not in the parity canon (per the rollout brief: "names are not in the parity canon"), the strings step should not break parity. But G1 has not re-run parity post-strings.

Does this match the plan? Yes. HANDOFF section 0 marks G1's strings work as "Still to do: Port step 9, then B's strings step: re-pin, re-export, godot/rules rows, re-run parity." This is planned future work, not a missed step.

Severity: no finding. Per house rules, work marked "Still to do" is not a finding unless going the wrong way. It is not going the wrong way.

### Stream G3 (campaign RECORD, parity_records.md)

Does the record name a commit after B's strings step (90aaf85)? No. The campaign RECORD's latest run is at commit 9711a7e, with oracle pinned at d8b47c6 (stream B steps 0 to 4). B's strings step (90aaf85) came after this. The record predates the strings step.

Does it still pass? Yes: 30/30 on PC and cloud at 9711a7e. All Nemesis scenarios, save test, arc hook test pass.

Does this match the plan? Yes. HANDOFF section 0 marks G3's strings work as "Still to do: B's strings step, then in ONE commit: oracle re-pin, campaign.gd string port, its 29 map rows and section 5c (parity compares event text and button lists, so they can't land apart). Re-run parity, re-shoot the map." The plan explicitly says G3 must re-run parity after its strings land because event text is compared. Until then, the current record is valid for rules.

Severity: no finding.

### Stream L (story and portraits steps, commits 1e65076, 257de44, 7fb50db)

The pack (context_CD_full.md, port_notes_steps_CD.md, rename_map_final.md, parity_records.md, chair_grep_CD.md) does not contain commit lines or descriptions for 1e65076, 257de44, or 7fb50db. The HANDOFF names L's rename map commits as 1695ea4 to 144dc71 and the portraits crests as e243729. The three commits named in the audit question do not appear anywhere in the provided files.

The map's sections 11 and 12 describe what L and P own, and the HANDOFF says L's Job 2 (story rewrite) and Job 3 (final sweep) are "Still to do." Nothing in the pack contradicts any claim about these commits, but nothing confirms them either.

Severity: NOT CHECKED. The pack does not contain evidence for or against commits 1e65076, 257de44, 7fb50db.

## Not checked

- L's story and portraits commits 1e65076, 257de44, 7fb50db: not present in the pack. Cannot verify or contradict.
- Godot-side string application (G1, G3, L rows): these streams have not yet applied their map rows per HANDOFF section 0. No committed Godot strings to audit beyond G2's.
- tools/portraits/make_batches.py display names (P rows): the map lists them, the HANDOFF says portraits has landed crests (e243729) and prompts (494c000) but admiral/Nemesis repaints are still to do. The pack does not include the file contents at the pinned commit.
- Collision checks requiring live web search: all collision verdicts above are based on training knowledge. I have not performed live trademark or franchise database searches. Flagged UNSURE where relevant.
- B's 331 replacement count: cannot be independently recounted from the pack. Accepted as stated, cross-checked against the chair grep (which is consistent).
- The 41 tables nothing in godot/rules reads (mentioned in the G1 parity README): not in scope for this audit.
- Audit E items (G4 bench, stream B win rate, A4 ships, G2 movement, portraits/crests visual checks): not in scope for this leg.

## Findings summary

| # | Severity | Job | Finding |
|---|---|---|---|
| 1 | FIX | C3 V2 | Eclipse blurb says "stealing starlight"; R58 ruled "siphon stellar energy, not light." Change to "stealing stellar energy" or equivalent. Evidence: rename_map_final.md section 1, data.js:125 blurb row. |
| 2 | NOTE | C1 | Eclipse Nemesis titles in map have four entries (adds "Nadir") vs three in the brief and bible 7.10. Evidence: map section 9.1, data.js:462. |
| 3 | NOTE | C2 | "Salvage swarm" (Eclipse relic name, data.js:269) is the one remaining display name leaded with "Salvage" outside 5b/5c. Judged acceptable (item-type sense) but close to the 5c boundary. |
| 4 | NOTE | C3 V8 | Glasswright Nemesis title "Duelist" added beyond bible 6.9's list of three. Consistent with bible 6.5 description. |
| 5 | NOTE | C4 | "Salvage Right" (Hullbreaker ship name, ui3d.js:20) kept. Borderline against 5c spirit but is a proper name, not an action label. |
| 6 | NOTE | C4/V17 | "The Chalked Roll" (relic) shares "Roll" with "the Roll of Vesper" (place). Different categories; common word. No functional clash. |
| 7 | NOTE | C3 V3 | "Lattice-ship" collision check: UNSURE, no live search performed. Term is compound and specific. |
| 8 | NOTE | C3 V12 | "Spinal cannon" collision check: UNSURE, no live search performed. Term is generic and descriptive. |

No BLOCKERs found.

Report ends. Pinned commit: 806233f766bfdfd98c61fbe5bebb834cc11bbe6c.
