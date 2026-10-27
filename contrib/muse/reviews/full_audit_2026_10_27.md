# Full catch-up audit, Oct 27, 2026

Chair synthesis of the blind legs run against the brief at contrib/opus/briefs/muse_2026-10-27b_full_audit.md. All legs pinned to main HEAD 172f019e7f8b9eba60e8c3947ffbac5e82885c43 at leg start.

Legs: Rey (contrib/muse/reviews/full_audit_A_rey.md and full_audit_B_rey.md), DeepSeek (contrib/deepseek/), Argon (contrib/gemini/), Qwen (contrib/qwen/). Raw returns are filed in each model's folder; this file is the merged read. Every claim is tagged CONFIRMED BY 2+ LEGS, SINGLE LEG, or UNSURE. Severities: BLOCKER (Ryan cannot test on return), FIX (wrong but not blocking), NOTE (polish). Opus verifies every claim before acting, per the brief.

Top summary:

- The sprint is on track for you to test on return. No leg found a BLOCKER. Two cheap things should close first: the Windows exe has never actually been launched (FEATURES.md still says smoke test pending), and 2 of the 36 faction bot runs came back not clean with no written explanation anywhere.
- The G1 parity record is strong but its headline overstates itself: the sweep is 1,300 unique random battles, not 1,500 (the README's own table shows seed 4 counted twice), and no parity run names the current commit, so the DONE claim cannot be traced to the tree you will test.
- Campaign: the rebuilt map does read as a Sins 2 star system at the wide view, but HANDOFF says DONE while FEATURES.md still shows every screen on fallback drawing, and one of them is stale. At zoom the map is not decluttered yet, and the sidebar has two plain text bugs (a doubled "Admiral: Admiral" title and a duplicated Nemesis weakness line).
- Lore round 6 landed: all eight of your R54 asks are delivered (four legs, unanimous), and most round 4 rulings are applied clean. The leftovers are small and specific: the old patron words survive inside section 1.5 itself, "ascended" survives at line 458, and the lore's broadside number (30%) contradicts the game's 40%.
- Ten short questions for you at the end, all multiple choice with a recommendation first. The biggest: the bible describes the Totality as one merged mind in two places and as billions of separate minds everywhere else. Audit B raised no questions for you; everything it found is Opus-lane work.

# Audit A: lore bible round 6

Audit A verdict: GO WITH CONDITIONS (all four legs independently). Round 6 landed almost everything it was asked to land. What is left is a short list of rewrite leftovers and three genuine either/or questions, all listed below. Nothing in Audit A blocks the Godot sprint.

## A1. Were the round 4 rulings and Opus calls applied?

Mostly yes. Q1, Q2, Q5, Q6, Q7, Q9 (with the A4 wording slip below), Q11, Q12, Q13, Q14: APPLIED, CONFIRMED BY 2+ LEGS (in most cases all four). Opus calls 1, 2, 3, 5, 6a, 6b, 6c, 6d, 6e, 6f, 7, 8: APPLIED, CONFIRMED BY 2+ LEGS.

The exceptions:

1. [FIX] Q4 applied wrongly in section 1.5. CONFIRMED BY 2+ LEGS (all four). The section heading at lore_bible_r6.md line 116 still reads "The embers (the patrons)" and line 120 still runs "(the boons)" and "Favour is the core's model of you getting better", one paragraph after line 118 states the hardware words replace the old ones everywhere. Qwen's framing is the sharpest: a style guide cannot keep the banned words as glosses, because writers will read them as allowed. Fix is mechanical: delete the parentheticals, rephrase the Favour sentence with "Sync".

2. [FIX] Q3 has a one-word leftover. SINGLE LEG (Argon, chair verified). Line 458 opens the Totality section "The Ardenti who ascended", directly above the line 466 avoid list entry for "the Ascended". The noun swap to "the Upload" is applied everywhere; only this verb survives. One word fix.

3. [FIX] Q8 is breached in two small places. SINGLE LEG (Argon, chair verified both quotes; Rey independently flagged the second as a question). Line 339 puts "almost-Ardenti shapes" surfacing in Chorus flesh (a look, which Q8 reserves to pure organic), and line 374 lets "the oldest carry a remembered Ardenti name" (a name, also outside story and dialogue). Whether this is a slip or a deliberate softening now that the Chorus is officially the third Ardenti path is a Ryan question (Q-A3 below).

4. [FIX] Q10's generation count is now a three-way tension. CONFIRMED BY 2+ LEGS (Rey flagged the wording drift, Argon assembled the full tension, chair verified the quotes). The ruling said two or three generations removed. Line 395 says "many generations later". Line 429 has the Chorus speaking "with our grandmothers' voices". Line 73 sets the collapse about 1,000 years ago. All three cannot hold at normal lifespans. Ryan question Q-A2 (the long-lived Glasswrights option reconciles all three texts and the ruling).

5. [NOTE] Glasswright ship classes deviate from Opus's call. CONFIRMED BY 2+ LEGS (Rey, Argon, Qwen). Opus's call named needle, shard, prism, aperture; line 448 has sliver, lancet, prism, aperture. Qwen fairly notes needle and shard are already spent on weapons and refits nearby (lines 417, 449), so the swap may be deliberate and arguably better. Recorded as a deviation, not an error. No Ryan question; Opus confirms intent in its own doc.

6. [FIX] Opus's one-name-one-owner call is breached in the Glasswright and Totality lists. SINGLE LEG (Argon, chair verified every instance by grep). Mirror appears as a family line (line 441, "of the Third Mirror"), in the rank list and as a Nemesis title (line 442, "First Mirror"), and as a weapon (line 449, "Mirror veil"), where the call said Facet and Mirror are ranks only. Prism is a ship class (line 448), two weapons (line 449), and a ship name (line 443, "Quiet Prism"). Corona is a weapon and a refit on the same line (line 513, "Corona arc", "Corona-ward node"). Qwen's leg pronounced this call APPLIED after checking only the Totality ranks; that verdict is not sustained. Ryan question Q-A6 on whether to enforce or relax the rule.

7. [NOTE] Brood-node survives as a Chorus rank (line 380) against Opus's brood-word call (brood-sac and Maw-mother landed at lines 381, 376). CONFIRMED BY 2+ LEGS (Rey, Argon). One word fix if Opus wants the call applied in full.

## A2. Ryan's round 5 asks (R54)

All eight asks DELIVERED. CONFIRMED BY 2+ LEGS (all four legs, unanimous, no dissent on any ask): the Totality as present-tense machine faction with top rank Nadir; the Dimming renamed the Siphoning; Caelum/Caelans renamed Ardent/Ardenti (zero leftover instances found by any leg); the Crusade scaled to the Vesper Reach, forty-odd systems; the Hegemony's want explained through the Vyre capture 25 years ago; the Hegemony proudly cybernetic; the Chorus as the third Ardenti path (all four legs independently called this the strongest or deepest-delivered ask); Hullbreakers alien and the Glasswrights' opposite, eyeless heat-hunters.

Quality notes that survived screening: the Siphoning names an active crime rather than a passive fading (Argon, Qwen); the Chorus third-path framing is what makes Memory, the homecoming, and the sibling-faction opinions cohere (all legs); Hullbreaker feudal leftovers are the one soft spot in ask 8, carried in A5.

## A3. New names collision check

No new round 6 name is a REAL COLLISION. CONFIRMED BY 2+ LEGS (Rey, Argon, Qwen; DeepSeek's one REAL COLLISION call, a "Terran Totality" from a fan forum thread, was checked by the chair against Starsector's actual faction list and is NOT sustained; it is recorded in DeepSeek's screening note and not carried here as a finding).

MINOR ECHOs, no action recommended (all are Ryan's own R54 picks or locked names): Ardenti (Endless Legend's Ardent Mages per Argon; Warhammer 40k's Ardentites, a Thorian philosophy, per Rey with chair verification; two independent sources, same rating); the Totality (generic noun; DC Comics usage per Argon); Nadir (standard astronomical term, BattleTech jump-point usage); the Vesper Reach ("Reach" as a frontier noun, Jericho Reach and Halo's Reach per Argon); cortical link (Altered Carbon's cortical stack is the nearest neighbour, and the term exists to replace a Banks term); Pulse laser (generic weapon name in BattleTech and Elite Dangerous; locked by Q2); Skarn (Diablo Immortal's antagonist and a Dauntless behemoth share the name, also a real rock type; SINGLE LEG, Argon). CLEAR, CONFIRMED BY 2+ LEGS: the Siphoning, Meridian Yards, the K-1 to S-6 designations, Oath-warden and Roll-master, Rattlehold, brood-sac, Maw-mother, Bile spray, the optical refit names, the iteration epithets, the Homecoming.

One internal echo worth a look, SINGLE LEG (Rey): Listening Post K-7 shares its designation with the famous Star Trek tribble station (Deep Space Station K-7). Small, but the game's own avoid lists argue for moving it. Ryan question Q-A5.

## A4. Consistency

1. [FIX] The Totality is described as one mind and as billions of minds. SINGLE LEG (Argon, chair verified lines 12 and 45 verbatim). Lines 12 and 45 say every mind was "uploaded into one" / "became one". Lines 458, 480, 486 and 505 to 507 describe billions of individual minds in separate bodies, with personal backups, personal deaths ("gone dark"), and named admirals counting their own frame iterations. The second version is the one the mechanics and the admiral roster already assume. Ryan question Q-A1, with the fix (rewrite lines 12 and 45 as uploaded into machine bodies bound to one Archive) recommended.

2. [FIX] Heat motif ownership. CONFIRMED BY 2+ LEGS (Rey, Argon, Qwen; all three). The motif table (line 100) gives heat to the Chorus alone, while the round 6 Hullbreakers are heat hunters in their biology, senses, ship glow, speech and opinion lines (lines 259 to 293). Argon adds two flavour-line tensions of the same kind: line 293 has the Hullbreakers calling the Totality "No heat at all" while cores are the hottest things in the setting and Totality ships sit behind heat shields, and line 292 calls Glasswright ships "Cold little ships" two hundred lines before line 422 burns a casket with their stored light. Ryan question Q-A4 (the split: Chorus owns body heat and hunger, Hullbreakers own heat-sensing).

3. [FIX] Line 413 muddies the Astra ruling. CONFIRMED BY 2+ LEGS (Rey, Argon; Qwen quotes the same line as the Glasswright want without flagging it). "Recover all six cores, starting with Astra, which they already hold" reads against lines 38, 125 and 395 (Astra is the tool for hunting the other five and is shut down last). One-sentence rewrite settles it.

4. [NOTE] Where the cores went. CONFIRMED BY 2+ LEGS (Rey, Argon). Line 73 says all six cores "were flung out" on escape orbits; the core table and faction sections have K-1 never leaving the dead Ardent system (lines 35, 122) and H-3 seized in the collapse itself (lines 37, 124, 329). The facts agree everywhere except line 73's summary sentence. Fix the sentence to four flung out, one stayed, one seized.

5. [NOTE] The Hegemony spends the Crusade's signature word. CONFIRMED BY 2+ LEGS (Rey, Argon). Line 233 has Hegemony dead "entered in the Roll", where the Roll belongs to the Crusade (lines 193, 201), and the same line's "the Registry keeps a model of each one" sits against line 101 (the Hegemony keeps data, not memory) and line 142 (the Registry deleted Vesper's dead from its projections). One-line fix to a loss ledger wording.

6. [NOTE] Dusk is spent twice. CONFIRMED BY 2+ LEGS (Rey, Argon). The Crusade motif cell (line 103) claims dawn and dusk (and cold, which several factions also spend in text), while Dusk is a Totality rank (line 511) under Opus's own rank call. Created by the rank call itself, so it is Opus's to reconcile: either the motif cell drops dusk and cold, or the rank becomes Penumbra.

7. [NOTE] Hegemony timeline phrasing. SINGLE LEG (Argon). Lines 16 and 209 compress the 70-year write-off of Vesper and the 25-year-ago Vyre capture so they can read as one event. The dated timeline (lines 74 to 76) is correct; the two summary lines want a clause each.

8. [NOTE] The Chorus holds a hardware core with no hardware anywhere else. SINGLE LEG (Argon). H-3 is a ship-sized Lattice core (lines 37, 124) held by a faction whose ships have "no panels or pipes" (line 340) and who want to eat the other cores (line 346). The leg's own one-sentence fix (the swarm grew around H-3 and feeds on it) closes it; flagged so the sentence exists before a reader asks.

Timeline, faction wants, and who-did-what otherwise check out: Qwen's Job 4 pass over all six core whereabouts, all thirty opinion lines, and all four dates found no further contradictions, and no other leg contradicted that pass outside the items above.

## A5. Fantasy drift and 40k echoes still left

The bible is largely clean on this axis (all four legs). What remains:

1. [NOTE] Core nicknames lean mythic. SINGLE LEG (Argon, chair verified all three at lines 35 to 37). K-1 "Kharon" is the Greek ferryman of the dead, respelled (Qwen independently rates it MINOR ECHO with the same root). V-2 "Vyre, the Storm Queen" reads as a fantasy monarch for a hardware core. H-3 "the Hunger Below" reads as a dungeon demon, and as Argon notes, it cannot have been the core's Ardenti-era name, since nothing was below or hungry before the Chorus took it. Ryan question Q-A7 offers grounded renames, with the survivor-nickname framing (the bible already says the titles are nicknames survivors gave them, line 129) as the cheap defence of keeping them.

2. [NOTE] Hullbreaker feudal titles against the new alien biology. SINGLE LEG (Argon). Line 311 still runs Breaker-king, Scrap-baron, Den-lord, Warlord for an eyeless species with 20-year lives, and line 312 keeps War-barge and the flagship name Pyre-Barge. The chair's read differs from the leg's recommendation: Pyre-Barge is a shipped, named flagship with an A4 redesign in flight, and outsider-translation is a standard framing the bible can state in one line. Ryan question Q-A8.

3. [NOTE] "Eclipse-lord" (line 511). CONFIRMED BY 2+ LEGS (Argon COSMETIC, Qwen MATTERS). A feudal suffix in the faction whose avoid list bans Necron lord titles (line 466). One-word swap to Eclipse-prime or First Index; folded into Q-A8.

4. [NOTE] "Grand Admiral" (line 248) sits oddly in the Hegemony lists next to that faction's own Star Wars avoid list. SINGLE LEG (Rey). One-word swap to First Admiral; folded into Q-A8.

5. [NOTE] Chorus mother titles (Matriarch, Maw-mother). SINGLE LEG (Argon, COSMETIC). Recorded for completeness; the chair does not carry this as a problem: Maw-mother was Opus's own call in the brood-word fix, and the Matriarch is an established admiral. No question.

6. [NOTE] Totality destroyer class "flare" (line 512). SINGLE LEG (Qwen, chair verified). A light word on the darkness faction, spending the Glasswrights' light motif. One-word rename (veil) recommended; folded into Q-A6.

## A6. Gameplay fit

1. [FIX] The broadside number contradicts the game. CONFIRMED BY 2+ LEGS (all four). Bible line 173 says broadsides hit 30% harder after moving two hexes. data.js sets the Crusade doctrine at 40% after moving 2+ hexes (rake .4, tuned up from .3 in balance pass 3). The lore is the cheap fix, and Qwen adds the wording point: "two or more hexes", not "two hexes". Near-unanimous leg verdicts name this the single most important Audit A fix. Ryan question Q-A9 only because the alternative (tuning the game down) exists; every leg recommends fixing the lore.

2. [FIX] Three current faction-verb strings in data.js break round 6's own bans, and the bible lists no replacements. SINGLE LEG (Argon, chair verified data.js lines 497 to 502 verbatim). The Crusade verb's free condition is an offering at a "void-shrine" (church furniture, banned at bible lines 137, 142, 158); the Glasswright verb's is "joined the song" (no faction sings, lines 98, 400); the Totality verb is "Waken the legion" with a "tomb-world" free condition (tomb is a banned Necron tell, line 466). Scope note from the chair: these are pre-rename data strings, not bible errors; the finding is that the rename map (the still-pending 26c Job 1 subject) needs rows for them. For Opus's rename map, not a Ryan question.

3. [NOTE] Hullbreaker riches wording. SINGLE LEG (Argon). Line 259 says the Hullbreakers do not want riches; line 280 has their Nemesis raiding your credits and data.js line 499 has the faction verb gaining credits. One clarifying phrase (they raid salvage and scrap, which the game counts as credits) reconciles the three. NOTE.

Everything else checked matches the settled rulings: R42 Nemesis behaviours and adaptation (all legs), R46 light blue plasma at line 250, R49 comeback rules (Totality sector 3 only at line 481, stolen ship returned at line 280, Glasswright Nemesis returning with the same upgraded fleet at line 417), Hegemony formation sync and ion, Chorus feed and shieldless regen, Glasswright no-Brace, Totality Archive reanimation and fold drive. CONFIRMED BY 2+ LEGS. Qwen additionally confirms the unrenamed data.js strings (Hullbreaker ranks at data.js line 520, "Phase drive" at line 10) are pre-rename code state, not lore contradictions; the chair agrees, and they belong to the same rename map as item 2 above.

# Audit B: Godot port and travel sprint

Audit B verdict: ON TRACK for Ryan to test on return (Rey, Qwen; DeepSeek and Argon phrase it more cautiously, as "close, with gaps to close during the sprint"). No leg found a BLOCKER under the brief's definition (Ryan cannot test on return). Argon tagged two items BLOCKER (campaign wiring, exe smoke test); the chair carries both as the top two FIXes below, because on pack evidence a Windows build exists with only its launch check outstanding, and the campaign question is which document is stale, which the pack cannot settle. The helpers are still working; several FIXes may close before Ryan is home.

## B1. G1 rules port

The parity design is strong. CONFIRMED BY 2+ LEGS (all four legs on the mechanism): whole battle state in canonical form plus the battle log, a SHA-256 of the state, and the PRNG state, compared after every action point, integers exact and doubles bit-exact with no tolerance. The maths sweep (316,090 values, 0 diffs), the PRNG seeds, and the 200-seed style coverage in the record are real checks, not summaries.

1. [FIX] The sweep headline overstates the count. SINGLE LEG (Argon, chair verified in the parity README itself). The README's running record claims "1,500 different random battles" (line 79 of contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md), but its own per-run table says the PC seed 4 sweep is "the same battles and the same record count as the cloud run of seed 4" (line 43). Seed 4 is counted twice: unique battles are 1,300, not 1,500. Qwen's leg cross-checked the claim against the README summary and marked it a match; the arithmetic does not support it. This is a wording overstatement inside an otherwise solid record, not a parity failure: 1,300 unique battles with 0 differences is still a strong result. Fix the sentence so the record says what it means.

2. [FIX] The DONE claim is not traceable to the pinned tree. CONFIRMED BY 2+ LEGS (Rey, DeepSeek, Argon). The PC record is 43 of 43 golden battles at commit 61c57fa; scenarios s44 to s47 (Stream B step 6 arc hulls, compact field) are verified cloud-only at 48638ef; no run in the pack names the pinned HEAD 172f019e. Nothing suggests the port is broken at HEAD; the gap is that the record cannot prove it from its own pages. One named run at a current commit closes it.

3. [FIX] Two pass-while-wrong mechanisms for Opus to check. SINGLE LEG (Argon, mechanisms verified against the rules test README by the chair's read of the pack). (a) Oracle pinning drift: the test oracle is pinned at battle.js and core.js d8b47c6 and data.js 6b1571e, behind HEAD; if Stream B edits the live JS and the oracle is not re-pinned, parity passes against a stale snapshot. (b) The table scanner in node/export_data.js only checks tables the GDScript side references, so a JS table nothing in Godot asks for yet is invisible to it. Qwen's framing is the correct limit on both: parity proves Godot matches the pinned JS, never that the JS is right.

4. [NOTE] "Nothing NOT PORTED" is broader than its own qualification. CONFIRMED BY 2+ LEGS (Rey, Argon, Qwen all quote the qualification): G-12 itself excepts non-rule tooltip helpers and G3-owned encounter rolls, which remain JS-only. The headline should carry the exception or the exception should close.

5. [NOTE] Thin corners in an otherwise deep record. CONFIRMED BY 2+ LEGS (Rey, Argon): threat overlay parity covers 3 scenarios; the thread test covers 2 scenarios and, except for threat_map, compares helper calls against GDScript itself rather than the JS oracle (Argon); seed 4 endings include 11 "no result" runs (README line 14). Also on record inside the README (DeepSeek, Argon, chair verified): an earlier PC run at 2b91ea4 had a worst enemy think of 0.585 s, over the roughly 0.5 s bar, attributed to a busy PC, and s32 plus the thread test were killed by an external SIGTERM on their first full pass and passed on rerun. None of this undermines the 61c57fa record (worst think 0.406 s, inside the bar); it belongs in the open so the record is not read as cleaner than it is.

## B2. G2 whole game

1. [FIX] The Windows exe has never been launched. CONFIRMED BY 2+ LEGS (all four; the audit's only full-house FIX). FEATURES.md line 15: the build is "done on the PC" with "exe smoke test pending", and --check-export passes. The sprint's own definition of done (R35) is a build Ryan starts from a .bat, and play_godot.bat runs this exe. Until someone launches it, the single most important artifact of the sprint is unverified. This is the first thing to close; it is also the cheapest.

2. [FIX] The bot record misses the sprint's own 0-errors bar, unexplained. CONFIRMED BY 2+ LEGS (all four legs flag the gap; Rey and Qwen rate FIX, DeepSeek NOTE). HANDOFF section 0 line 8: "100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean." No document in the pack says what happened in the other 2 runs: no cause, no error class, no log pointer, and the plan table cites only the 100-run figure. If the 2 are known and benign, a one-line disposition closes this. If they are uninvestigated, they are exactly what the bot program exists to catch.

3. [NOTE] The pace claim needs a worst-round figure. CONFIRMED BY 2+ LEGS (Rey, DeepSeek in part, Qwen's table). The only played pace number in the pack is a 13.4 s mean for a 20-ship sector 3 fight (down from 30.1 s, a real improvement) against a 15 s worst-round target. A mean under the bar does not prove the worst round is. The parity think times DeepSeek cited (about 1.5 s) are not played pace.

4. [NOTE] Movement (R54, IN PROGRESS, judged on approach only per the brief). All legs that could see the strips agree the approach is sound; the evidence for the new behaviour is thin: Rey found the Before and After rows near-identical at strip scale with no clearly readable sidestep or RCS puff; DeepSeek read RCS puffs in the dreadnought strip where Rey could not (UNSURE detail); Argon observed, and the chair verified on the s9 strip, that in the After row the stern flares stay bright at 0.80 s, 1.30 s and 2.00 s while the ship already sits in its destination hex. If the main drive should cut when translation ends, that is an approach point worth the G2 helper's eye while the work is still open. Not missing work; an approach note, as the brief asks.

## B3. G3 campaign

1. [FIX] Campaign completion rests on one unsupported line, and the documents disagree about the screens. CONFIRMED BY 2+ LEGS (all four legs, with different framings the chair reconciles here). HANDOFF section 0 calls G3 DONE with the R51 star-system map rebuilt. The parity record claims campaign 30 of 30 with no campaign test record, scenario list, or godot/campaign/ listing anywhere in the pack (Rey, Argon). FEATURES.md (Oct 26 evening) still shows every campaign screen drawn by the fallback UI, sector map included ("no map picture"). Qwen's read, which the chair adopts: the fallback table most likely describes G2's shell before or beside G3's own UI, not the current state of the map; but on pack evidence alone nobody can tell which document is stale. Opus settles it with one line in HANDOFF or FEATURES.md naming which is current, plus the campaign test record. What Ryan will actually see on return depends on the answer, which is why this is a FIX and not a NOTE.

2. The map itself, where legs could see it, delivers R51 at the wide view. CONFIRMED BY 2+ LEGS (Rey, Argon; DeepSeek positive on the wide shot): the wide campaign shot genuinely reads as a Sins 2 style star system, with the Hollow Sun central and stops placed as bodies, not as a flat node graph.

3. [FIX] The zoom view is not decluttered, and the sidebar has two text bugs. CONFIRMED BY 2+ LEGS (Rey, Argon; chair verified on the shots and a 2x crop). At zoom, stop cards overlap labels and the ASTEROID BELT label repeats; service stops still read cheap in places (a wireframe shipyard, plain rings). The sidebar literally prints "Admiral: Admiral Castellan Vex" (title doubled, chair verified on the crop), and the Nemesis weaknesses line prints its "unknown (win against him to learn it)" entry twice, separated by a semicolon. Small, concrete, fixable; R51's declutter clause is the standard they fail.

4. [NOTE] The flat map question stays open from the Oct 26 audit: the flat map view (map_view.gd) had no danger bands, routes, or hover card then; no leg could confirm from this pack whether the rebuilt map replaces it everywhere. UNSURE.

## B4. G4 effects and world

1. faction_looks.json is genuinely data-driven for colours and styles. CONFIRMED BY 2+ LEGS (Rey, Argon, Qwen): shield colours are distinct for the four shielded factions; Chorus and Totality shield entries are null by design (shieldless factions). The Oct 24 faction-colour ruling is backed by the data.

2. [NOTE] Damage glow is one orange for five of six factions. CONFIRMED BY 2+ LEGS (Rey; Argon notes the same uniform fields): damage_glow is [1.0, 0.45, 0.12] for five factions, and shield_edge and accent are null across all six (unused fields, or unfinished ones; the file does not say which).

3. [FIX] Per-weapon marks are weak at battle camera distance. CONFIRMED BY 2+ LEGS (Rey, Argon; DeepSeek reads the same shot positively, a genuine split recorded here). On the frigate marks shot, flak, acid, ion and ram marks do not read as distinct signatures at the distance battles are actually watched from. Flak readability is already IN PROGRESS per HANDOFF, so part of this is known; the audit's point is that the gap is wider than flak alone.

4. [NOTE] The Compatibility renderer draws no hull decals at all (Rey, Qwen; from the FEATURES and fx documents), so the "marks carry to the battle camera" claim needs its qualifier wherever it is stated: true on the main renderer, absent on the safe-mode path Ryan might use on a weaker machine.

5. [NOTE] The black hole disc reads flat in closeup (Rey, from the dead star board shot). The Doppler beaming claim is in the documents; the closeup does not sell it yet. Polish, after the effects pass.

6. [UNSURE] No 20-ship performance record exists in the pack. CONFIRMED BY 2+ LEGS (all four legs, same conclusion): pace is proven (B2 item 3), frame rate at 20 ships with full effects is not measured anywhere the legs could see. Not a finding of a problem; a missing measurement, flagged because the effects pass will spend against it.

## B5. A4 ships

Judged from the shots by the three image legs (Qwen NOT CHECKED by design). No leg found a BLOCKER; the Pyre-Barge and the V17 gothic peaks are IN PROGRESS per R54 and HANDOFF, and are carried as watch items, not defects.

1. [FIX] The V1b Ascendant's lit window rows read as the banned porthole row. SINGLE LEG (Rey, from the voidsworn_lineup shot). CLAUDE.md bans porthole rows; a regular lit grid on a capital hull reads as exactly that at lineup distance.

2. [FIX] The Warden frigate's turret sits in a rippled blob basin. SINGLE LEG (Rey). The one clear blob read in the lineup, against CLAUDE.md's no-blobs rule.

3. [NOTE] Corsair upright pipe clusters sit close to the smokestack read. CONFIRMED BY 2+ LEGS with a chair arbitration: Rey rated NOTE (clusters are real, near the funnel read), Argon rated FIX ("smokestack funnels"), DeepSeek read the lineup clean. The chair viewed corsair_lineup.webp directly: the clusters on C13s, C15s and C16s are real and sit near the funnel read, but they read as junk-mechanical stacks rather than clean funnels; Rey's NOTE register is the accurate one. Watch item while pass 3 polish continues.

4. [NOTE] Pyre-Barge: visibly smoother and more boat-shaped than its line mates, with a thin mast and a thin dangling underside line with a lit tip in the true-size side view (Rey; Argon agrees it does not match the line, in stronger language the chair does not adopt: the hulls read as detailed junk-mechanical, not melted). The redesign is IN PROGRESS (R54); the audit records the gap the redesign already aims at.

5. [NOTE] The repeated bow claw on C14s to C16s (Argon) reads to the chair as a shared faction boarding tool, not a copy-paste defect. Recorded so the disagreement is visible; no action.

6. [NOTE] A4 pass 3 is called done for Corsairs while their flagship is queued for redesign (Rey, cross-stream): both things are true in the documents, and the done label would be clearer scoped to the line ships.

## B6. Stream B rules

1. [FIX] Steps 4 to 6 have parity coverage but no before-and-after balance sims in the pack. CONFIRMED BY 2+ LEGS (Rey, DeepSeek, Argon). The admiral band, start fleet changes, and the six arc hull variants are proven to match between JS and Godot; they are not shown to be balanced, because no sim before-and-after accompanies them in the pack. Qwen's counterpoint is credited and reconciles the record: the earlier B steps do carry before-and-after figures in the plan table (sector 3 enemy waits 21.8 s to 8.0 s; sector 1 boss spread to 57 to 89% after the S6 fix; fuzz 2000 with 0 exceptions). The gap is specific to the newest steps, and the PC confirmation set is still running per HANDOFF, so this may close itself; the audit flags that, as of the pinned commit, the newest balance work has the least balance evidence.

2. [NOTE] Step 5's start fleets are campaign data that no battle rule reads (Rey): worth Opus confirming the fleets actually reach battles through the campaign path the parity scenarios use, or the change is inert in the mode that matters.

## B7. Music and portraits

Music is the cleanest claim in the audit. CONFIRMED BY 2+ LEGS (all four on the documents; Rey additionally spot-checked five OpenGameArt source pages live and all matched): godot/music/CREDITS.md lists 24 tracks, 16 CC0, 4 CC BY 3.0, 4 CC BY 4.0, no NC, ND, or SA anywhere, with per-track attribution text. Two NOTEs, both CONFIRMED BY 2+ LEGS: keep the Fanfares CC BY 4.0 election explicit in the credits (the source page also offers SA terms; the election is documented, and it needs to stay that visible), and the fac_deathless entry's compressed author line in the summary table is a summary only; the per-track attribution is the credit of record (the mix and all its sources are CC0 as listed on the mix page, verified live by Rey).

Portraits: the claim of 24 Nemesis portraits in game is UNSURE from the pack. CONFIRMED BY 2+ LEGS (all four): godot/portraits/index.json exists at 21,749 bytes and the nemesis/ directory exists, but no listing in the pack shows the files themselves, so the count cannot be confirmed. Same, more weakly, for the 24 music track files. A directory listing in the next HANDOFF update closes both.

## B8. Cross-stream

1. [NOTE] godot/render/ has two owners. CONFIRMED BY 2+ LEGS (all four): the plan gives the folder to G2 and the look.gd file inside it to G4, explicitly. It is a planned split, not an accident, and it is the one place two streams can collide in the same directory.

2. [NOTE] G5 means two things. SINGLE LEG (Rey): FEATURES.md titles itself the checklist "against the Godot version (G5)" while the plan lists G5 as NOT STARTED. One of the labels should move.

3. [NOTE] Trails and RCS ownership is split across G2 and G4 documents (Argon): movement trails are claimed in both streams' sections. Harmless while the helpers coordinate; worth one owner line in the plan.

4. [NOTE] Campaign UI code appears in both G2's host and G3's own UI (Argon): consistent with the fallback arrangement in B3, and another reason the B3 documentation fix matters.

5. Everything else the legs checked across HANDOFF, the plan, FINDINGS and the stream READMEs agreed, including the folder ownership table outside the items above. The disagreements that exist are the ones already carried in B1 to B3 (the parity count wording, the campaign documents, the plan table omitting the 36-run bot set and its 2 unclean runs, Qwen and Rey both NOTE).

# Questions for Ryan

Audit B produced no Ryan questions: everything it found sits in Opus's lane under the decision split (launch the exe, disposition the 2 bot runs, fix the parity count wording, settle the campaign documents). The ten below are all Audit A. Recommended answer first in each, per the brief.

Q1. Are the Totality one merged mind, or billions of separate minds? (A1 item via A4.1: lines 12 and 45 say every mind was uploaded "into one"; lines 458 onward describe billions of individual minds with personal backups, deaths, and names.)
A (Recommended): Billions of individual minds backed up in one shared Archive. Fix lines 12 and 45 to match; admirals keep their personalities and frame counts, which the roster already assumes.
B: One merged mind; admirals are facets of a single intelligence. (Would need the roster and Archive wording rewritten instead.)

Q2. How many generations separate the living Glasswrights from the collapse? (A1.4: your round 4 pick was two or three generations; line 395 says "many generations", line 429 says "grandmothers' voices", line 73 sets the collapse 1,000 years back.)
A (Recommended): Make the Glasswrights long-lived (300 to 400 years). Then all three texts and your ruling are true at once: today's Glasswrights really are the grandchildren of the Lattice engineers.
B: Keep normal lifespans and "many generations", and change line 429 to "our ancestors' voices". (Softens your round 4 pick.)

Q3. How strict is the Chorus surface rule (Q8)? (A1.3: line 339 lets almost-Ardenti shapes surface in Chorus flesh; line 374 lets the oldest carry a remembered Ardenti name. Your ruling put Memory in story and dialogue only.)
A (Recommended): Keep it strict. Cut the shapes from the look line and the names from the naming rules; Memory speaks in dialogue, nowhere else.
B: Allow these two as the stated exception, now the Chorus is officially the third Ardenti path.

Q4. Who owns heat in the motif table? (A4.2: the table gives heat to the Chorus alone; the new Hullbreakers sense, speak, and judge by heat everywhere.)
A (Recommended): Split it. Hullbreakers own heat-sensing and thermal signatures; the Chorus keeps body heat, taste, smell, teeth, hunger.
B: Leave the table as is and let context sort it.

Q5. Listening Post K-7 (A3): the designation matches the famous Star Trek tribble station.
A (Recommended): Rename it (K-12, or another unused number). One word, no echo.
B: Keep K-7; it is a generic designation.

Q6. Enforce the one-word-one-owner rule where round 6 broke it? (A1.6 and A5.6: Mirror in a family line, a rank, a Nemesis title and a weapon; Prism in a class, two weapons and a ship name; Corona in a weapon and a refit on the same line; the Totality destroyer class "flare" spends the Glasswrights' light.)
A (Recommended): Enforce it with the cheap renames: Mirror veil becomes Refraction veil, Corona-ward node becomes Penumbra node, flare becomes veil. Family lines and ship names keep their words.
B: Relax the rule; repetition across slots is fine.

Q7. Ground the three core nicknames? (A5.1: Kharon the Greek ferryman, Vyre "the Storm Queen", H-3 "the Hunger Below".)
A: Ground them: Anvil the Unbent, Vyre the Surge, and Crucible, called the Hunger Below only after the Chorus took it.
B (Recommended): Keep them as they are. The bible already frames all six titles as nicknames survivors gave the cores (line 129); mythic survivor nicknames are characterization, not the cores' real names.

Q8. Hullbreaker titles and the Pyre-Barge (A5.2): Breaker-king, Scrap-baron, Den-lord, Warlord, and the flagship class name, against the new eyeless alien biology.
A: Replace with pack and heat-hunter words (Apex, Pit-boss, First Claw, Den-alpha; flagship class Siege-hulk).
B (Recommended): Keep them, and add one bible line saying these are outsider translations of Hullbreaker rank-words. Pyre-Barge is a shipped named flagship with a redesign in flight; renaming costs more than it buys.

Q9. Two lord-titles (A5.3, A5.4): "Eclipse-lord" (line 511) next to the Totality's own Necron-lord ban, and "Grand Admiral" (line 248) next to the Hegemony's Star Wars avoid list.
A (Recommended): Swap both: Eclipse-prime (or First Index), and First Admiral.
B: Keep both; the bans target specific franchises' words, not suffixes or ranks in general.

Q10. The broadside number (A6.1): the lore says 30% (line 173); the game says 40% after moving 2+ hexes.
A (Recommended): Fix the lore to 40%, "two or more hexes". All four legs recommend this; the game's number was tuned deliberately in balance pass 3.
B: Keep 30% in the lore and tune the game down to match later.

# Ryan's rulings on the ten questions (Oct 27, 2026)

Recorded by the chair from Ryan's answers in chat on Oct 27, 2026. His words are quoted where the answer carried new direction beyond the letter. Opus: these rulings change two things the audit treated as settled (Q4 and Q6 below); read those two carefully.

Q1 (Totality minds): A. Billions of individual minds backed up in one shared Archive; fix bible lines 12 and 45. Ryan's reason: "Otherwise it stretches into Chorus a bit too much." A merged single mind is Chorus territory; the Totality stays individual.

Q2 (Glasswright generations): A. The Glasswrights are long-lived (300 to 400 years), so the 1,000 year collapse, the two or three generations from his round 4 ruling, and line 429 "grandmothers' voices" all hold at once.

Q3 (Chorus surface rule): A, keep Q8 strict; cut the Ardenti shapes at line 339 and the remembered names at line 374. Ryan's framing, which goes further than the question: "I don't think of them as people but creations of rogue glasswrights who worked with flesh, not glass." Chair note for Opus: this touches the r6 origin. Round 6 tells the Chorus as a third Ardenti movement that rewrote its own biology; Ryan's framing makes them a made thing, built by rogue Glasswright flesh-workers. Reconcile the two before the next bible round; the third-path structure can survive if the flesh-workers were a Glasswright splinter, but who made the Chorus, and whether they were ever people, is now a Ryan-stated position, not a detail.

Q4 (heat motif and the Hullbreakers): the question's premise is REJECTED and R54 ask 8 is superseded in part. Ryan: "I don't really want the hullbreakers to be eyeless hear seaking. I think of them as more violent, hairy/furry monsters. Weird mix of bears/wolves/mammals" (his "hear seaking" read as heat-seeking). Rulings that follow: the Hullbreakers are not eyeless and not heat-hunters; they are violent furry mammal monsters on a bear/wolf pattern. The r6 Hullbreaker biology built on heat pits, eyelessness, and thermal judgement (lines 259 to 293 and everything downstream of it) needs rework, not a motif patch. The motif question itself dissolves: heat is the Chorus's, unshared. Chair inference, marked as such: a bear/wolf read points their senses toward scent, hearing, and pack behaviour; that is the chair's gloss, not Ryan's words, and the rework is Opus's to draft with Ryan's veto.

Q5 (Listening Post K-7): rename it to a different letter and number. The specific replacement was not picked; any designation that is not K-7 and carries no franchise echo works.

Q6 (one word, one owner): A MIX. Enforce where it is cheap, tolerate overlap where factions are related. Ryan: "a mix of a and b. I don't like penumbra node at all. Some overlap is okay, especially with related factions like humans and glass right/eclipse/totality" (read: Glasswrights, and the Eclipse/Totality pairing). So: the Corona-ward node rename to Penumbra node is REJECTED by name; find another word or leave the refit. Mirror and Prism overlaps among sibling factions are acceptable. Separately, and bigger: the faction name itself is reopened. Ryan: "I don't love totality, it should be back towards the sun theme with eclipse." The name "the Totality" is NOT settled anymore; Ryan wants the machine faction's name moved back toward the sun and eclipse theme. No final name was picked in this answer. Names already on record from the r6 pick list (line 45) are "the Eclipse" and "the Occlusion". For Opus: treat the name as open, propose against the sun/eclipse direction, Ryan keeps the pick. Everything else named Totality in the bible and this audit reads as a placeholder until he picks.

Q7 (core nicknames): SPLIT, as offered. Keep Kharon and Vyre, the Storm Queen as survivor nicknames. Fix H-3: its original name becomes Crucible, and "the Hunger Below" is the nickname survivors gave it after the Chorus took it.

Q8 (Hullbreaker titles and Pyre-Barge): B is acceptable (keep, with the outsider-translation line), but Ryan notes he is "looking for a rework of them anyway". Read together with Q4: the Hullbreaker rank and title set is slated for rework alongside the species change, so B is the interim state, not the final one. Pyre-Barge keeps its name.

Q9 (lord-titles): A. Swap both: Eclipse-lord becomes Eclipse-prime or First Index, and Grand Admiral becomes First Admiral.

Q10 (broadside): A. Fix bible line 173 to 40% after moving two or more hexes, matching data.js. The game does not change.
