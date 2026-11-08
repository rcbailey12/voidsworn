1. Check lists

Issue 120 checks

120-1 - seeded sim - draw shape and hard constraints

Procedure: extend godot/campaign/test/node/nem_scenarios.js with a setup that starts a real run and records RUN.nemAssign, RUN.foes[3], and RNG_S immediately after run start. Run 1,000 seeds per player faction, seeds 201000000 + 1000*pIndex + i, i=0..999, pIndex over the six factions named in the pack. Expected exact: every RUN.nemAssign has length 3; H2 != H1; H3 != H2; no Hk equals the player faction; the same seed produces the same assignment. Covers: "RUN.nemAssign is drawn once at run start from the run RNG (five non-player factions per story point, no consecutive repeats)" shape part.

120-2 - seeded sim - marginal enumeration

Procedure: run 20,000 seeds per player faction, total 120,000 runs, seeds 201100000 + 20000*pIndex + run. For each player faction, story point k, and non-player faction f, count Hk=f. Expected derived: 4,000 per cell = 20,000/5. Expected exact: player's own faction count is 0 in every cell. Tolerance INFERRED: absolute deviation <= 108 counts per cell, taken from the pack section 5 observed largest matrix cell deviation 0.0054 * 20,000 = 108. Total hunts per faction across the full 360,000 slots expected derived 60,000 = 360,000/6; tolerance INFERRED +/- 600. Covers: "seed enumeration test reproduces the synthesis section 5 marginals (each hunter about 1/5 per story point, never the player's own faction)" and R85 Q1 marginals.

120-3 - seeded sim - SP1 return rate

Procedure: use the same 120,000 runs as 120-2. Count H3 == H1, H2 == H1, H3 == H2. Expected derived: H3 == H1 count 30,000 = 120,000 * 1/4. Tolerance INFERRED: +/- 600, from 4 * sqrt(120,000 * 0.25 * 0.75) = 600. Expected exact: H2 == H1 count 0; H3 == H2 count 0. This directly catches sampling without replacement at SP3. Covers: "SP1 returns at SP3 about 1/4 of runs".

120-4 - scenario step - lazy registry and active resolution

Procedure: add scenario nem120_registry_lazy in nem_scenarios.js. Start a real run, record assignment A. Assert the faction-keyed registry has zero entries before sector 1. Enter sector 1; assert active fac equals A[0] and the registry now has exactly one entry, for A[0], created through newNemesis(fac) with the identity shape named at campaign_run.js:250: name, title, persona, two traits, portrait, two weaknesses. Enter sector 2; assert active fac equals A[1] and registry has two entries. Enter sector 3; assert active fac equals A[2]. If A[2] equals A[0] assert the sector 3 entry is the same object as sector 1, not a second object. Expected exact. Covers: "a faction-keyed commander registry replaces a single RUN.nem, lazy creation through the existing newNemesis", and "active commander per sector resolves from the assignment".

120-5 - scenario step - draw once and run RNG use

Procedure: in nem120_registry_lazy, immediately after run start record assignment A0 and RNG_S S0. Call a read that must not redraw, nemNodeIs at sector 1, and assert RUN.nemAssign deep-equals A0 and RNG_S equals S0. Enter sector 1 and resolve active commander; assert RUN.nemAssign still deep-equals A0. Expected exact. Covers: "drawn once at run start from the run RNG".

120-6 - save/load - old mid-run save migration

Procedure: add scenario nem120_migrate_midrun. Build an old-shape state: RUN.nem = newNemesis(facA), set weak, revealed, one adapt entry, clock = 2, met = 1, one scar; delete RUN.nemAssign and the registry; JSON round-trip; load under the new build and run ensureNemesis() migration at campaign_run.js:259. Expected exact: RUN.nemAssign has length 3; the SP-current entry equals old RUN.nem.fac; active commander for the save's current sector is the migrated old object; NEM_CARRY fields weak, revealed, adapt, clock, met, scars at campaign_run.js:256 equal the old values. Also run existing scenario 8 pre-persona save shape; expected its state survives the ensureNemesis normalisation at campaign_run.js:259-261. Covers: "old saves migrate (an existing RUN.nem becomes the SP-current entry)" and the old-saves trap.

120-7 - parity/process - oracle copy, export, parity, browser/Godot twins

Procedure: run node godot/campaign/test/node/export_campaign.js; diff godot/campaign/test/oracle/ copies of campaign_run.js, data.js, core.js against browser files; run godot/campaign/test/node/compare_campaign.js and golden_campaign.js through godot/campaign/test/parity_campaign.gd and tools/pc/parity_campaign.bat; run godot/campaign/test/run_nem_scenarios.sh. Expected exact: export exits 0; oracle diff is empty; parity prints PASS; scenario diff has zero lines. Covers: "browser and Godot land together; campaign parity PASS" and "oracles re-copied, tables re-exported".

120-8 - parity/process - PR checks

Procedure: run the repo PR checks. Expected: pass. The exact PR check command is not named in the pack. Covers: "PR checks pass".

Issue 121 checks

121-1 - scenario step - once-per-sector meeting per commander

Procedure: add scenario nem121_meeting_per_commander. Set assignment [A, B, A]. Sector 1 active A; force a strike pending with nemClockAdd so nemNodeIs at campaign_run.js:290 is true; run a meeting. Assert A.met = 1, A.strike = false, B has no met flag. Call nemNodeIs again in sector 1; assert false. Sector 2 active B; force strike; assert nemNodeIs true; run meeting; assert B.met = 2 and A.met remains 1; nemNodeIs for B false. Sector 3 active A; before meeting A.met = 1 < RUN.sector = 3; force strike; assert nemNodeIs true; run meeting; assert A.met = 3. Expected exact from scripted steps. Covers: "once-per-sector meeting targets the active commander (nemNodeIs) with per-commander met-this-sector flags". In scripted steps, exact means the named invariant values exactly match.

121-2 - scenario step - run-level clock pace by active commander

Procedure: add scenario nem121_clock_pace. Set assignment [Eclipse, Crusade, Glasswright]. Sector 1 active Eclipse; clock = 0; call nemClockAdd(2) at campaign_run.js:280; expect clock = 1, derived 2 * 0.5. Sector 2 active Crusade; clock = 0; call nemClockAdd(2); expect clock = 3, derived 2 * 1.5. Sector 3 active Glasswright; clock = 0; call nemClockAdd(2); expect clock = 2, derived 2 * 1.0. Clamp case: active Crusade, clock = 3; nemClockAdd(2) expected 4, derived min(3 + 2*1.5, NEM_CLOCK=4 at data.js:428). Expected exact. Covers: "one run-level clock paced by the active commander's beh.clock".

121-3 - scenario step - strike brings meeting forward without changing hunter

Procedure: in nem121_meeting_per_commander, choose a sector 1 node outside the last three columns and no strike; assert nemNodeIs false. Record assignment and active fac. Call nemClockAdd to reach NEM_CLOCK = 4 with met < sector and no strike pending; assert strike pending true and nemNodeIs true on the same non-late node; assert RUN.nemAssign unchanged and active fac unchanged. Run meeting; assert strike cleared, met = 1, nemNodeIs false, no second meeting. Expected exact. Covers: "a strike brings the sector's meeting forward without changing the hunter".

121-4 - scenario step and process - nemAdapt per commander and clash check

Procedure: add scenario nem121_adapt_per_commander. Set assignment [A, B, A]. Meet A sector 1 and reveal weakness wA. Advance to sector 2 active B, meet B and reveal wB; assert A.adapt length unchanged, B.adapt length = 1 for wB. Advance to sector 3 active A; adapt A once; assert A.adapt length = 2, B.adapt length = 1. Extend contrib/opus/tools/nemesis_clash_tests.js with per-commander cases. Run extended contrib/opus/tools/nemesis_clash_tests.js with per-commander cases. Expected exact: scenario invariants hold; clash test file prints PASS. Covers: "nemAdapt runs per commander on sector advance with the clash check preserved and nemesis_clash_tests.js extended".

121-5 - scenario step - weaknesses, scars, epithets, lessons attach to commander

Procedure: add scenario nem121_state_attach. Set assignment [A, B, A]. Sector 1 A loses a meeting; assert A has one lesson and A.revealed/weak list contains the taught weakness key; B has no lesson. Sector 2 B loses; assert B has one lesson, A lesson count unchanged at 1. Add one scar to A; assert A.scars length = 1, B.scars empty. Capture nemPanel() and epithet field after an A loss; assert the line shown is A epithet, not B. Sector 3 A returns; assert the panel still shows A scars and lessons, now with A met = 3. Expected exact. Covers: "weaknesses, scars, epithets and debrief lessons attach to the commander".

121-6 - scenario step - behaviour packages unchanged

Procedure: run existing behaviour scenarios for the six named behaviours: Hullbreaker raids; Glasswright duels and returns upgraded; Chorus grows from player losses anywhere; Eclipse never retreats, returns once after death in sector 3 only; Crusade duels flagship; Hegemony reinforces in round 3. Record the existing scenario tags as expected outcomes; also, from the pre-change tree, deep-compare NEM_FAC[fac].beh to the post-change tree, using the behaviour scenarios as authoritative. Expected exact: all six invariants hold and twin scenarios show zero diff. Covers: "behaviour packages unchanged". The direct diff to a specific pre-change commit is not named in the pack; see coverage note.

121-7 - text - NEM_VOICE table presence and style

Procedure: one-time script build check_nem_voice.js, run per scenario batch in seconds. Load data.js via env.js; read contrib/muse/design/nemesis_writing_2026_11/text_table.md. Expected exact: NEM_VOICE exists beside NEM_LINES at data.js:490; top-level faction keys are the five non-player factions; persona keys match the table (for example meet, win, flee, fall arrays; again and remember are single lines with exactly one {beat} placeholder; adapt keys are exactly shields, pd, armor, evasion, aim, special; lessons keys are a subset of NEM_WEAK at data.js:429; file text is ASCII and data.js style single quotes and unquoted keys. Persona reads are absent from the table: no top-level fitness, briefing or debrief keys. Covers: R101 paste NEM_VOICE into data.js beside NEM_LINES, and re-pin both oracles.

121-8 - text - NEM_VOICE content rules and nemSay wiring

Procedure: same script, plus scenario calls. Expected exact: Chorus lines contain no gendered pronouns or gendered nouns; Chorus again and remember contain at least one of taste, heat, smell, teeth. Eclipse flee is empty; fall and fall_final both exist and fall_final is non-empty. Lessons contain no gendered pronouns. For each adaptation line, the line returned by the nemSay applied to the table line, via nemAdaptName, nemAdaptDesc, nemAdaptWhy at campaign_run.js:300-302 equals nemSay applied to the table line with the same commander gender. Covers: R101 Chorus and Eclipse picks, "adaptation lines are spoken through nemSay".

121-9 - scenario step - Eclipse fall_final wiring

Procedure: add scenario nem121_eclipse_fall_final. Set sector 3 active Eclipse; force final flagship death; capture the spoken line. Expected exact: line is NEM_VOICE.eclipse.<persona>.fall_final, not fall; {beat} is replaced by the matching NEM_BEAT_WORD value at data.js:495; output equals the table line after substitution and nemSay. Covers: "including the Eclipse fall_final key".

121-10 - parity/process - oracle re-pin, export, parity, browser/Godot twins

Procedure: same as 120-7, plus re-pin both oracles after NEM_VOICE lands and re-export tables. Expected exact: exit 0, oracle diff empty, parity PASS, twin scenario diff zero lines via run_nem_scenarios.sh zero diff. Covers: "browser and Godot land together; campaign parity PASS"; R101 re-pin both oracles.

121-11 - parity/process - PR checks

Procedure: run repo PR checks. Expected: pass. Command not named in the pack. Covers: "PR checks pass".

Issue 122 checks

122-1 - scenario step - nemSignature faction tag

Procedure: add scenario nem122_signature_fac. Set assignment [A, B, A]. Sector 1 active A; call nemSignature('test_kind') at campaign_run.js:273; capture the telemetry event and N.signatures last entry. Expected exact: event is tel('nem_signature', {fac: A.fac, kind: 'test_kind', sector: 1}); N.signatures last entry corresponds to A; after 41 calls the list is capped at 40 and the oldest is shifted out. Covers: "nemSignature tags events with the commander's faction".

122-2 - scenario step - run-level escape counter

Procedure: add scenario nem122_escape_counter. Set assignment [A, B, A]. Make A escape early via the campaign_run.js:306 flagship-dead-earlier branch; assert run escape counter = 1. Make B escape early; assert counter = 2. Make A escape again in sector 3 (returning commander); assert the counter stays 2 for the distinct-commander pick (see Q2). Expected exact. Covers: run-level escape counter and "at most two per run".

122-3 - scenario step - per-commander compounding counter

Procedure: add scenario nem122_compound_counter. Active Chorus commander; script three player losses; assert Chorus commander compounding counter = 3. Active a Chorus commander in a sector where he is not active; assert his compounding counter = 0. Expected exact. Covers: per-commander compounding counter.

122-4 - scenario step - Nemesis panel current and return

Procedure: add scenario nem122_panel. Set assignment [A, B, A]. Sector 1 capture nemPanel() at campaign_run.js:72; assert it contains A name/title and no B name. Sector 2 capture; assert it contains B name and earlier commander A still readable with scars and lessons. Sector 3 capture; assert it shows A name and A scars/lessons, and the sector 1 A record is the same object. Expected exact. Covers: "Nemesis panel shows the current sector's assigned hunter and, on a return, that commander's scars and lessons" and "earlier commanders still readable".

122-5 - parity/process - tests for meetings and telemetry

Procedure: run node nem_scenarios.js out.txt with new tags nem121_meeting_per_commander, nem122_signature_fac, nem122_escape_counter, nem122_compound_counter; run Godot twin via run_nem_scenarios.sh. Expected exact: both outputs contain the tags and diff has zero lines. Covers: "tests for once-per-sector meetings and telemetry".

122-6 - parity/process - before and after panel captures

Procedure: one-time script build capture_nem_panel.js, run per scenario batch in seconds. Use fixed seeds from 120-1; capture nemPanel() before the 122 change and after. Expected exact: before file exists; after file exists; diff contains the current-sector hunter name change and the earlier-commander record; no other panel text changes. See coverage note for format.

122-7 - parity/process - browser/Godot, parity, PR

Procedure: same as 120-7 and 121-10. Expected exact: export exits 0; oracle diff empty; parity PASS; scenario diff zero lines; PR checks pass. Covers: "browser and Godot land together; campaign parity PASS; PR checks pass".

2. Coverage note

- "PR checks pass" in issues 120, 121 and 122: the pack does not name the PR check command or list. Checks 120-8, 121-11 and 122-7 call the repo PR checks as a process step; the command must be taken from the repo at run time and the result recorded as-is.
- "behaviour packages unchanged" in 121: the pack gives no pre-change snapshot of NEM_FAC[fac].beh. Check 121-6 verifies the six named behaviour invariants and parity, but exact deep equality cannot be run from the pack alone, it needs the pre-change tree at run time.
- "before and after captures" in 122: capture format is not specified. Check 122-6 defines text capture of nemPanel() as the runnable interpretation.
- "earlier commanders still readable" in 122: readability is not specified as a UI shape. Check 122-4 uses the panel string containing the earlier commander name, scars and lessons as the runnable interpretation.
- "browser and Godot land together" is a process clause, not a code fact. Checks 120-7, 121-10 and 122-7 define it as export plus oracle diff plus parity plus twin scenarios, all passing together.

3. Gaps and conflicts

Gap 1 - sector to story point map for sectors beyond 3.

Issue 120 Done-when says "the active commander per sector resolves from the assignment", and R85 Q4 says "SP assignments and sector alignment" is open, with the pack not giving a map for sectors 4 and 5, or for an old save whose current sector is 4 or 5. Proposed edit: Issue 120, Done-when, after "the active commander per sector resolves from the assignment", insert "using active fac = RUN.nemAssign[min(k,3)-1] where k is the story point for the current sector; sectors 4 and 5 use SP3". In agent terms, the edit adds the map to the Done-when text; the test that enforces it is 120-4/121-1, extended to sectors 4 and 5.

Gap 2 - escape counter counts commanders or events.

Issue 122 Done-when says "a run-level escape counter and a per-commander compounding counter". Synthesis section 4 says "escapes are tracked... two at most per run", but does not say whether a returning SP1 commander who escapes again counts as a second escape. Proposed edit: Issue 122, Done-when, after "a run-level escape counter", insert "(distinct commanders, capped at 2)". See owner question Q2.

Gap 3 - "about" in issue 120 conflicts with exact marginals.

Issue 120 Done-when says "each hunter about 1/5 per story point, never the player's own faction, SP1 returns at SP3 about 1/4 of runs", while synthesis section 5 gives exact marginals, for example 0.1791 to 0.2244 range per cell and max deviation 0.0054, and the RNG stream is exact. Proposed edit: Issue 120, Done-when, after "seed enumeration test reproduces the synthesis section 5 marginals", insert "(each cell count within +/- 108 of 4,000 over 20,000 runs per player faction; SP1 return count within +/- 600 of 30,000 over 120,000 runs)" and use checks 120-2 and 120-3 as the acceptance test. The tolerance values are INFERRED from the pack section 5 numbers; see 120-2 and 120-3.

No other conflict with R85, R101, the synthesis or the section 6 code facts was found.

4. Traps

- RNG stream coupling: caught by 120-5 for assignment stability, 120-7 and 121-10 parity re-pin, and 122-5 scenario rerun.
- Lazy creation order: caught by 120-4 and 121-1. The registry is empty before sector 1 resolution and a commander is not created until its sector is entered.
- Draw itself: caught by 120-3 directly measuring H3 == H1 at 1/4. A sampling-without-replacement implementation fails 120-3 while passing 120-2.
- Sector vs story point: caught by 120-4 and 121-1 for the map in use, and flagged in Gap 1.
- Old saves: caught by 120-6 for mid-run and existing scenario 8 for pre-persona shape.
- Parity drift: caught by 120-7, 121-10 and 122-7 through export, oracle diff, parity and twin scenarios.
- Text: caught by 121-7, 121-8 and 121-9. Chorus deny list, Eclipse empty flee, Eclipse fall_final, no persona reads.
- Additional trap found: panel can regress to single RUN.nem and lose earlier commanders. Caught by 122-4.
- Additional trap found: escape counter double-counts a returning SP1 commander. Caught by 122-2.

5. Owner questions

Q1 - What is the sector to story point map for sectors 4 and 5 and old-save SP-current?

Chair pick: use RUN.nemAssign[min(k,3)-1], so sectors 4 and 5 use SP3 and old-save SP-current uses the same map. Other option: extend the assignment to five entries with a new draw per sector, which changes the RNG stream and invalidates 120-2/120-3. Cost of the other option: re-run enumeration and re-pin oracles.

Q2 - Does the escape counter count distinct commanders or escape events?

Chair pick: count distinct commanders once, capped at 2, per synthesis section 4. Other option: count every escape event, so a returning SP1 commander escaping again counts as a second escape. Cost of the other option: "at most two per run" can be reached by one commander, and 122-2 must be re-written.

Q3 - What exact word list defines the Chorus "no song or choir words" rule?

Chair pick: use the INFERRED deny list song, choir, sing, melody, harmony, tune, hymn, and allow taste and heat memory words. Other option: treat only the two words in the rule text, song and choir, as banned. Cost of the other option: sing, melody and hymn lines pass 121-8, and the text check must be re-run after the list is fixed.
