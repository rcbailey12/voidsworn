Verdict: Audit C finds the map broadly faithful but with four FIX-level mismatches (Steelgrin collision, starlight versus energy, Salvage swarm, Nadir title). Audit D finds B's strings step landed at 90aaf85, G2's tagline matches V1, and the G1/G3 parity records predate the strings step exactly as HANDOFF section 0 says they should; no blocker.

Pinned commit: 806233f766bfdfd98c61fbe5bebb834cc11bbe6c.

Audit C
C1 Canonical names

Every row of the canonical table in lore_rollout_brief.md appears in rename_map_final.md with the same new display text. I checked the title, all six factions, the star and people, the black hole, cores and protocols and sync and signal, all six patron names, the Las family, Hellfire, Gauss, Doom arc, Pulsar, Turbolaser, Hive Leviathan, the Crusade, Hegemony, Hullbreaker, Chorus, Glasswright and Eclipse class rows, the Hegemony rank, Malek's title, the Eclipse and Hullbreaker ranks, the four Eclipse admirals and the run words.

One contradiction with the bible:

FIX, OBSERVED. The Eclipse blurb in rename_map_final.md section 1 says "stealing starlight to light a new sun" (data.js:125 row). lore_bible_r8.md, "What changed", says "Energy, not light. Eclipse siphon stellar energy". The map uses light where the bible explicitly rules out light. Alternative: "siphoning stellar energy to light a new sun".

No other canonical row contradicts the bible on factions, weapons, classes, ranks, admirals, cores, protocols, sync, signal or run words. The use of "Starwright" and "Ardent" in map rows is consistent with bible sections 1.1 and 6.1.

C2 Coverage

The chair grep at 806233f covers the nine B-owned browser files and reports no retired display word surviving as a display string in its sample. I checked the examples the chair gives and they hold: data.js:21 gauss is a weapon id whose display is "Null cannon"; data.js:19 pulsar is an id whose display is "Prism lance"; data.js:97 and 660 are comments; campaign_meta.js:120 favour is a tab key whose label is "Core sync"; campaign_run.js:490 sigil is a CSS class.

One surviving display string does break the 5c one-meaning rule:

FIX, OBSERVED. data.js:271 has the Eclipse refit display name "Salvage swarm" (map row salvage:'Harvest engine' becomes salvage:'Salvage swarm'). Section 5c says "salvage" should only mean the item type, and this is a refit name, not the item type. Alternative: "Scrap swarm". The chair flagged this row for judgement and the judgement is that it fails 5c.

The 331-replacement claim in port_notes step 10 is not independently counted in the pack. The map's section 15 says every Old cell was found and 0 missing, and B's step 10 says 331 replacements and check pack 0 FAIL. I treat those as OBSERVED from the notes but not verified row by row. NOTE.

The chair grep does not cover godot/ or tools/, so full-repo coverage is NOT CHECKED. The chair says so itself.

C3 Vetoable calls

V1 Tagline: fits the bible. G2's brand.gd:11 carries the same sentence. No named collision found. No alternative needed.

V2 Faction blurbs: problem in one blurb. The Eclipse blurb says "stealing starlight" where the bible says energy, not light. FIX, OBSERVED. Alternative: "siphoning stellar energy". The other five blurbs fit their bible sections.

V3 Ship classes: fits. cls stays as the key and the display map gives War-barge, Colossus, Lattice-ship and Archive-ship. Bible 7.10 gives Colossus to the Ninefold Maw and archive-ship to The Unsetting; bible 4.10 gives the War-barge class; bible 6.10 says The Unfinished is built around the largest Lattice piece, so Lattice-ship is consistent. No named collision found. No alternative needed.

V4 Crusade admirals: fits bible 2.10 (old European given names plus hard English surnames). No named collision found. No alternative needed.

V5 Hullbreaker admirals: problem. "Grax Steelgrin" introduces the surname Steelgrin, and Warhammer Fantasy has Kaskitt Steelgrin, a skaven engineer, at https://breeze.hostux.net/warhammerfantasy/wiki/Bonestash. Bible 1.4 forbids names lifted from Warhammer, Battlefleet Gothic and other known franchises. FIX, OBSERVED. Alternative: "Grax Ironmaw" (keeps the harsh two-syllable front and a body word, without the Warhammer surname). "Old Mott" and "Sable the Smiling Knife" fit bible 4.9; "Vesh the Collector" is kept.

V6 Glasswright admirals: fits bible 6.9 (short crisp names plus optical family line). "Tamsa" is also a company name in the real world but not a named franchise character, so this is a NOTE rather than a collision. No alternative needed.

V7 Eclipse admirals: fits bible 7.9 (old Starwright name plus iteration epithet). No named collision found. No alternative needed.

V8 Name pools: problem in the Eclipse Nemesis titles. The map puts "Nadir" in titles:['High Nadir','Eclipse-prime','Archivist','Nadir'] (data.js:462). "Nadir" is also the top Eclipse rank in bible 7.10. Bible 7.10 lists Nemesis titles as High Nadir, Eclipse-prime and Archivist, not plain Nadir. This is a rank and title clash. FIX, OBSERVED. Alternative: drop plain "Nadir" from the title pool and keep High Nadir, Eclipse-prime and Archivist. The other pools fit bible 2.10, 4.9, 5.9, 6.9 and 7.9.

V9 Cores and sync tiers: fits bible 1.5. Listening, Partial sync, Synced and Full sync are hardware words. No named collision found. No alternative needed.

V10 Faction-power strings: fits bible 2.4, 5.3, 6.2 and 7.5. "A wall of names", "Keep the dawn watch", "answered the tone", "Back up the fleet", "A siphon array", "A dormant hull yard" and "Archive restore" all match the relevant faction's motifs. No named collision found. No alternative needed.

V11 Events: fits bible 1.2 and 2.4. The astropath becomes a signals officer, the Ithar seer becomes a Glasswright keeper, the tithe vault becomes a toll vault, the pirate haven becomes a raider den, and "The saint answers" becomes "Luck holds". No named collision found. No alternative needed.

V12 Nova cannon: fits bible 1.4 and 3.8. Nova Cannon is a Battlefleet Gothic word and Spinal cannon is neutral. No named collision found. No alternative needed.

V13 Battle shapes: fits. Hollow Sun is canonical; Colossus becomes Giant wreck because Colossus is now the Maw's class; Shoals becomes Rock shoals. No named collision found. No alternative needed.

V14 Relic becomes salvage: fits the bible, because "relic" is a never-say word in bible 1.2 and Opus vetoed L's V14. The item type label changes to salvage. No named collision found. No alternative needed at the V14 level.

Section 5c as applied: problem. The one-meaning rule is right in principle, but the map's own row for data.js:271 puts "Salvage swarm" into the Eclipse refit names, so salvage still has a second meaning. FIX, OBSERVED. Alternative: "Scrap swarm". The rest of 5c (Strip the wrecks, Scrap rig, Recovered refits, Spoils) fits the rule.

V15 Arc unlocks: fits bible 2.11, 4.10, 5.10 and 6.10. Vigil lance-cruiser, Cordon column escort, Trophy wrecker, Sun-eater bladeback, Ringing aperture and Archive guard flare all use the new class words. No named collision found. No alternative needed.

V16 Run-end headlines: fits bible 4.8, 6.8 and 7.8. "Strongest keeps it", "The light is kept" and "Noon returns" match the faction sayings. No named collision found. No alternative needed.

V17 Refits and relics the bible does not name: fits the motifs. The Chalked Roll (Crusade chalk names), Wake-tracker (Hullbreaker trail hunting), Tasting pores (Chorus no eyes), Annealing kilns (Glasswright glass), Long-count reckoner and Siphon ledger (Eclipse memory and siphoning), Long clock (Eclipse time) all fit. No named collision found. No alternative needed.

V18 Small ones: fits. Shield wall order removes protocol from a Command, Recovery crews removes protocol from a refit, Spitting volley and Acid tide remove music words, and the Hegemony ship names Optimal, Consensus, Projection, Punctual, Comptroller, Allocation and Forecast fit the Registry's data motif. No named collision found. No alternative needed.

C4 Internal clashes

FIX, OBSERVED. "Salvage swarm" (data.js:271) uses salvage for a refit, clashing with section 5c's one-meaning rule. Alternative: "Scrap swarm".

FIX, OBSERVED. "Nadir" is both the top Eclipse rank (bible 7.10) and a Nemesis title in the map's NEM_FAC pool (data.js:462). Bible 7.10's Nemesis titles do not include plain Nadir. Alternative: remove plain Nadir from the title pool.

NOTE, OBSERVED. "Warden" is a Crusade ship class (bible 2.11) and also appears in the Crusade titles "High Warden" and "Warden of the Roll" (bible 2.10). Both are Crusade words, so the player's overlap tolerance for related factions likely covers this, but it is still an overlap worth naming.

NOTE, OBSERVED. "Lattice-ship" uses Lattice, the megastructure name, as a class adjective. It is a compound rather than a second owner, but it is close enough to note.

No other new string is used for two different things in the map or bible. The old clashes the map fixes are real fixes: HNS Bastion becomes HNS Consensus, Colossus becomes Giant wreck, and Sable the captain surname becomes Sedley.

Audit D
B, commit 90aaf85, step 10

The step claims 331 replacements across data.js, battle.js, campaign_run.js, campaign_meta.js, campaign3d.js, ui3d.js and head.html, sections 1 to 10 including 5b and 5c, CLS_NAME and clsName added, ids unchanged, check pack 0 FAIL. OBSERVED in port_notes step 10.

What goes beyond display strings: CLS_NAME and clsName are new code, but they are a display mapping only, authorised by map row 4.0. NOTE. The step says "no id, key, rule, number or random draw changed" and gives a same-seed sim comparison. OBSERVED in the note, not independently re-run. The 331 count is not independently counted in the pack. NOTE.

G2, commits 49f0d85 title, 239fdeb tagline and rows, ef5cab2 exe launch

The tagline at godot/ui/battle/brand.gd:11 matches V1 word for word: "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." OBSERVED in the map row 10.2 and port notes.

No evidence in the pack that G2 changed anything outside display strings. The title commit changed title, window title, project name, product name and description, and kept the exe file name and save folder. NOTE, OBSERVED from HANDOFF section 0.

G1, parity README

The headline parity record is at bdb1a9d with oracle cb55ec9. B's strings step is 90aaf85. The G1 record predates the strings step. The README itself says the oracle files are byte-identical to the game at cb55ec9, which is before step 10. This matches HANDOFF section 0, which marks G1's port step 9 and the re-pin, re-export and re-run after B's strings step as "Still to do". NOTE, OBSERVED. Not a problem, but the parity pass does not yet prove the strings step.

G3, campaign RECORD

The newest campaign parity run is at 9711a7e, which predates 90aaf85. The record says the oracle is copied from d8b47c6. This also matches HANDOFF section 0, which marks G3's string port, its 29 map rows and section 5c, and the oracle re-pin as "Still to do" in one commit after B. NOTE, OBSERVED. Not a problem, but campaign parity does not yet cover the strings step.

L, story and portraits, commits 1e65076, 257de44, 7fb50db

NOT CHECKED. The pack does not contain the commit lines for these three commits in context_CD.md or elsewhere, so I cannot compare their claims against the pack. Map sections 11 and 12 describe what L and P should do, but the pack does not carry the actual commit text.

Not checked

Collision checks for C3 names other than Steelgrin were limited to quick searches and found no named collision. They are NOT CHECKED against a full trademark or franchise database.

Full-repo retired-word coverage in godot/ and tools/ is NOT CHECKED. The chair grep covers only the nine browser files at 806233f.

The exact 331-replacement count in B's step 10 is NOT CHECKED row by row.

The post-strings-step parity runs for G1 and G3 do not exist in the pack, so their post-90aaf85 pass state is NOT CHECKED.

L's story and portrait commits 1e65076, 257de44 and 7fb50db are NOT CHECKED because the pack lacks their commit lines.

I did not run the game or the check pack; all check pack and parity results are as reported in the pack, not re-executed.
