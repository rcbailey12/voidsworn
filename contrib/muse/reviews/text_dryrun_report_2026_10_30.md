# Text overhaul dry run, Oct 30, 2026

Dress rehearsal for the text overhaul pack (text_overhaul_pack_2026_10_30.md). Every one of the pack's 96 replacements, plus the CODE-9 haven leave option, was applied to a scratch copy of the shipped game code at pin 264f441d43a54e3679950dcc4457133b40811807, exactly as written, and the result was loaded, runtime-verified string by string, and run through the findings-to-tests suite and both data validators. The clone was never modified; the staged pack was never modified. Scratch copy and working scripts: ~/workspace/voidsworn-text-dryrun/.

## Verdict

The pack is safe to apply as written, with four rows held back. 92 of the 96 replacements applied and verified. The 4 blocked rows are blocked by defects in the pack rows themselves (wrong placeholder tokens, an apostrophe that breaks the target literal, a replacement that ignores the shipped markup), not by the game code, and each has a one-line pack correction, listed below. The CODE-9 haven data addition applied cleanly alongside. No applied string broke anything: the test suite gained exactly the four passes the text fixes were supposed to produce and lost none.

## Counts

| Outcome | Count |
|---|---|
| Applied clean | 74 |
| Applied with note | 18 |
| BLOCKED as written | 4 |
| Total pack rows | 96 |
| CODE-9 haven leave option (data addition) | Applied |

## The 4 blocked rows

1. **T-21** (FACTIONS.hegemony.blurb, data.js:115). The replacement contains a straight apostrophe ("Registry's") destined for a single-quoted JS literal. A verbatim paste is a syntax error, demonstrated in rehearsal: node --check fails at data.js:115, "Unexpected identifier 's'". The anchor mismatches too: the shipped string encodes the apostrophe as a curly U+2019 while the pack Current uses a straight quote. Pack fix: escape the apostrophe in the replacement, or use the curly form the file already uses.
2. **T-84** (corsair prize toast, campaign3d.js:93). The pack Current and Replacement interpolate ${mod} and ${prize}; the shipped template interpolates ${modName(m)} and ${p.name}. The anchor therefore does not exist in the source, and the replacement pasted verbatim would reference two undefined variables and throw when a Corsair capture pays out. The inventory row (INV-1675) carries the same transcription error. Pack fix: correct the tokens in Current and Replacement to the shipped ones; the wording change itself (her to it) is unaffected.
3. **T-90** (help screen keys line, campaign_meta.js:171). The shipped string is HTML: each key is wrapped in its own kbd element (<kbd>Tab</kbd> next ship, <kbd>Q</kbd>/<kbd>E</kbd> turn, and so on). The pack Current is only the rendered text content (its own cell admits "rendered with kbd tags"), so no plain-text anchor exists in the source, and pasting the plain-text replacement would strip the kbd markup from the keys line. Pack fix: supply the replacement in markup-carrying form, one kbd element per key, following the shipped pattern.
4. **T-95** (Nemesis flagship flee log, battle.js:586). The pack Current and Replacement interpolate ${fl.name}; the shipped log interpolates ${f.name} (the flagship variable in nemFleeCheck is f; fl exists only in other functions). The anchor does not exist in the source, and the replacement pasted verbatim would throw a ReferenceError when a Nemesis flagship flees. Pack fix: change fl to f in both cells.

Pattern worth noting: T-84 and T-95 are the same failure class. The hand-curated inventory rows for template literals in the non-data files paraphrased the interpolation tokens, and the pack inherited the paraphrase. The data.js rows, extracted by execution, have no such errors. Any future hand-curated row should be checked token-for-token against the source template.

## Rehearsal incident (caught, fixed, recorded)

The first mechanical splice of the T-04 removal produced a malformed array ('Archivist'' with a doubled quote, SyntaxError at data.js:465), caught by node --check before any test ran. The pack row says only REMOVE, so the splice mechanics are the editor's risk: the safe form is to delete the element together with its preceding comma. The corrected removal is what the scratch carries and what the runtime checks below verify. This was the only syntax break in 97 edits, and it is exactly the class of accident this rehearsal exists to catch.

## Test suite comparison

Findings-to-tests suite (72 tests), run from an identical copy of the staged suite, baseline against the untouched clone, then against the edited scratch.

| Run | Pass | Fail |
|---|---|---|
| Baseline (clone, pin) | 8 | 64 |
| After text application (scratch) | 12 | 60 |

Exactly four tests flipped, all FAIL to PASS, each one the direct, intended effect of a text change. No test flipped PASS to FAIL, and no other test's result or failure message changed anywhere in the suite.

| Test | Flipped by | Mechanism |
|---|---|---|
| ADM-6 hidden squadron-hull bonus disclosed in admiral text | T-10 to T-14 | The five admiral cards now disclose the hidden sqHp bonus ("Squadron hull +25%"), which is what the test asserts. |
| EVT-3 ambush and clock outcomes disclosed in option text | T-78 | The beacon "Seize the cargo" text now discloses the ambush and the Nemesis clock move. |
| EVT-5 every fight-start event has a free exit | CODE-9 | Haven gained the leave option (r:{}), so eventOptOk passes for it. |
| ROS-2 variant weapon deletions are disclosed | T-15, T-16, T-17 | The three variant descriptions now disclose the removed weapons. |

## Validator comparison

- table_xref.js (structural cross-references): exit 0 against both clone and scratch, output byte-identical. No new warnings.
- naming_lint.js (old-name lint over the six text-bearing files): HARD hits go from 1 (Steelgrin at data.js:221) to 0, which is T-03 landing; lint exit flips 1 to 0. CANDIDATE hits are unchanged at 43 (all in code comments, untouched); three of them report line numbers one higher in the scratch because the CODE-9 addition adds a line above them in data.js. Same hits, shifted lines.

## Runtime verification

Every applied data.js row was verified at its data path through the shared game loader, clone value against scratch value: 95 checks, 0 failures (73 data-path checks for the applied data.js pack rows, the haven option check, 19 non-data replacement presence checks, and two guards). The guards matter:

- T-81 sibling guard: Nekhet's card now reads "rebuild", and exactly one admiral (the Chorus mending admiral) still holds the identical "Ships regrow 4% of their hull each round." sentence. The line-targeted swap did not touch the sibling string it had to preserve.
- T-28 span guard: the old "carrier's launch" sentence is gone from campaign_meta.js in every encoding (curly character, backslash-u escape, straight quote).
- Removals verified as data: SHIP_NAMES loses "Acceptable Loss" and shrinks 28 to 27; the Eclipse Nemesis titles lose the plain "Nadir" element and keep "High Nadir".
- CODE-9 verified as data: haven has 4 options, and the new one deep-equals {k:'leave', l:'Leave the den alone', s:'Nothing happens.', r:{}}.

## Mechanical checks

- Placeholder tokens: pack Current against pack Replacement, all 96 rows: 0 mismatches. The pack is internally consistent everywhere, including the ${c} and ${cand.name} rows (T-70, T-71). The two token failures (T-84, T-95) are pack-against-source mismatches, caught in the blocked list above, not pack-internal ones.
- Em dashes in replacements: 0. En dashes: 0. Empty replacements: 0 (the two REMOVE rows are array-element removals, not empty strings).
- Length growth (UI-fit proxy; length is the honest headless proxy, not a pixel judgment): no replacement exceeds the 2.5x flag line. The three longest: T-77 at 2.30x (23 to 53 chars, a weapon trait suffix), T-73 at 2.22x (27 to 60), T-78 at 1.95x (55 to 107, the beacon disclosure). All three are short strings in wrapping text surfaces; nothing in the set is a fixed-width label except the keys line (T-90, blocked on other grounds).

## Notes from the 18 noted applications

- Line drift (6 rows): the inventory's cited lines are stale by 1 to 10 lines for T-27, T-28, T-29, T-92, T-93, T-94. The pack's own how-to-apply already says the data path is the reliable locator and the line is a courtesy; the rehearsal confirms that ordering. Each swap was applied at the string's real location.
- Shared strings (6 rows): T-22 to T-25 are one identical Command string carried by four admirals, and T-42/T-51 are one identical sentence in two Nemesis tables. Each row was swapped at its own cited line; after all rows, no occurrence of the old wording remains in any of them.
- Sentence-level swap (1 row): T-02's Current is the first sentence of a two-sentence blurb. Applied as a sentence swap; the remainder of the blurb is preserved, verified at the data path.
- Apostrophe-tolerant anchor (1 row): T-79's shipped string encodes the apostrophe as U+2019 where the pack uses a straight quote; the swap applied and the replacement (which contains no apostrophe) landed byte-for-byte as written. T-21 is the same encoding mismatch plus the literal-breaking replacement apostrophe, which is why one is a note and the other is a block.
- Pack-flagged wordings (4 rows): T-06, T-07, T-82 are chair PROPOSAL wordings and T-85 is the optional NOTE row; all four were applied in the rehearsal so their effect is visible. They remain Ryan's one-word vetoes, exactly as the pack frames them.

## What Opus must decide or fix before the real application

1. Four pack-row corrections (above): T-21 apostrophe, T-84 tokens, T-90 markup form, T-95 token. All are edits to the pack, not to game code. With those four rows corrected, the pack applies 96 of 96.
2. CODE-9 is proven, not just specified: the haven leave option applies as a pure data addition and flips EVT-5 to PASS. Apply it in the same pass as the text.
3. None of the pack's other CODE flags blocks application. The rehearsal downgrades two of them on evidence: CODE-3 (Nemesis pronoun routing) is now demonstrably optional, because the neutral section D swaps all verify cleanly at runtime; routing through nemSay is a feature choice, not a fix. CODE-1 (admiral purchase not wired) does not block T-91; the pointerless card text lands as designed and stays honest until the purchase is wired.
4. Removal mechanics: the two REMOVE rows (T-01, T-04) are the only edits in the pack that can break the file syntactically if spliced carelessly (see the rehearsal incident). Delete each element with its preceding comma, then node --check data.js.

## Per-string disposition table

| Row | Location | Disposition | Note |
|---|---|---|---|
| T-01 | data.js SHIP_NAMES[23] | Applied | Array element removed at cited line 254; pool shrinks by one, later indices shift (intended for a name pool). |
| T-02 | data.js FACTIONS.deathless.blurb | Applied, note | Pack Current is a segment of the full shipped string (sentence-level swap); the remainder of the string is preserved. |
| T-03 | data.js ADMIRALS.grax.n | Applied |  |
| T-04 | data.js NEM_FAC.deathless.titles[3] | Applied, note | Array element removed at cited line 464; pool shrinks by one (intended). REHEARSAL INCIDENT: the first mechanical splice of this removal (pattern ,'Nadir'] replaced with ']) pro... |
| T-05 | data.js FAC_VERBS.deathless.d | Applied |  |
| T-06 | data.js RELIC_NAMES.deathless.salvage | Applied, note | Replacement is a chair PROPOSAL wording in the pack. |
| T-07 | data.js RELICS.phylactery.n | Applied, note | Replacement is a chair PROPOSAL wording in the pack. |
| T-08 | data.js ADMIRALS.kassar.d | Applied |  |
| T-09 | data.js ADMIRALS.vaelen.d | Applied |  |
| T-10 | data.js ADMIRALS.ashgrove.d | Applied |  |
| T-11 | data.js ADMIRALS.reyes.d | Applied |  |
| T-12 | data.js ADMIRALS.mott.d | Applied |  |
| T-13 | data.js ADMIRALS.matriarch.d | Applied |  |
| T-14 | data.js ADMIRALS.aelith.d | Applied |  |
| T-15 | data.js HULL_VARIANTS.d_harvester_t.d | Applied |  |
| T-16 | data.js HULL_VARIANTS.b_razor_s.d | Applied |  |
| T-17 | data.js HULL_VARIANTS.i_song_w.d | Applied |  |
| T-18 | data.js MASTERY_PERKS[4].d | Applied |  |
| T-19 | data.js MODULES.hangar.d | Applied |  |
| T-20 | data.js ABILITIES.launch.d | Applied |  |
| T-21 | data.js FACTIONS.hegemony.blurb | BLOCKED | Replacement contains an unescaped straight apostrophe destined for a single-quoted JS literal (data.js:115, blurb:'...'). A verbatim paste is a SyntaxError (demonstrated: node --check fails at data.js:115, "Unexpected identifier 's'"). The anchor also mismatches: the shipped string encodes the apostrophe as a curly U+2019 while the pack Current uses a straight quote. Pack row needs the apostrophe escaped or the curly form. |
| T-22 | data.js ADMIRALS.ashgrove.cmd.d | Applied, note | String occurs 4 times in data.js; swapped only the occurrence on the cited line 214 (the other occurrences belong to sibling rows or, for T-81, to the Chorus admiral whose ident... |
| T-23 | data.js ADMIRALS.reyes.cmd.d | Applied, note | String occurs 3 times in data.js; swapped only the occurrence on the cited line 219 (the other occurrences belong to sibling rows or, for T-81, to the Chorus admiral whose ident... |
| T-24 | data.js ADMIRALS.mott.cmd.d | Applied, note | String occurs 2 times in data.js; swapped only the occurrence on the cited line 223 (the other occurrences belong to sibling rows or, for T-81, to the Chorus admiral whose ident... |
| T-25 | data.js ADMIRALS.aelith.cmd.d | Applied |  |
| T-26 | data.js ASPECTS.hive.d | Applied |  |
| T-27 | campaign_meta.js:165 | Applied, note | Line drift: inventory says 163, the string sits at line 165 in the shipped file. Swapped at the real location. |
| T-28 | campaign_meta.js:165 | Applied, note | Line drift: inventory says 163, the string sits at line 165 in the shipped file. Swapped at the real location. Anchor matched only apostrophe-tolerantly: the shipped source enco... |
| T-29 | ui3d.js:535 | Applied, note | Line drift: inventory says 545, the string sits at line 535 in the shipped file. Swapped at the real location. |
| T-30 | data.js NEM_WEAK.flank.d | Applied |  |
| T-31 | data.js NEM_WEAK.ion.d | Applied |  |
| T-32 | data.js NEM_WEAK.torp.d | Applied |  |
| T-33 | data.js NEM_WEAK.board.d | Applied |  |
| T-34 | data.js NEM_WEAK.brawl.d | Applied |  |
| T-35 | data.js NEM_WEAK.anchor.d | Applied |  |
| T-36 | data.js NEM_WEAK.slow.d | Applied |  |
| T-37 | data.js NEM_TRAITS.gunnery.d | Applied |  |
| T-38 | data.js NEM_TRAITS.armored.d | Applied |  |
| T-39 | data.js NEM_TRAITS.swift.d | Applied |  |
| T-40 | data.js NEM_TRAITS.veterans.d | Applied |  |
| T-41 | data.js NEM_TRAITS.deadeye.d | Applied |  |
| T-42 | data.js NEM_TRAITS.shielded.d | Applied, note | String occurs 2 times in data.js; swapped only the occurrence on the cited line 451 (the other occurrences belong to sibling rows or, for T-81, to the Chorus admiral whose ident... |
| T-43 | data.js NEM_TRAITS.boarders.d | Applied |  |
| T-44 | data.js NEM_TRAITS.regrowth.d | Applied |  |
| T-45 | data.js NEM_TRAITS.brood.d | Applied |  |
| T-46 | data.js NEM_TRAITS.undying.d | Applied |  |
| T-47 | data.js NEM_TRAITS.veil.d | Applied |  |
| T-48 | data.js NEM_TRAITS.artillery.d | Applied |  |
| T-49 | data.js NEM_TRAITS.zeal.d | Applied |  |
| T-50 | data.js NEM_TRAITS.rockets.d | Applied |  |
| T-51 | data.js NEM_ADAPT.shields.d | Applied |  |
| T-52 | data.js NEM_ADAPT.pd.d | Applied |  |
| T-53 | data.js NEM_ADAPT.armor.d | Applied |  |
| T-54 | data.js NEM_ADAPT.evasion.d | Applied |  |
| T-55 | data.js NEM_ADAPT.aim.d | Applied |  |
| T-56 | data.js NEM_ADAPT_FAC.corsair.special.n | Applied |  |
| T-57 | data.js NEM_ADAPT_FAC.corsair.special.d | Applied |  |
| T-58 | data.js NEM_ADAPT_FAC.deathless.special.d | Applied |  |
| T-59 | data.js NEM_ADAPT_FAC.ithar.special.d | Applied |  |
| T-60 | data.js NEM_ADAPT_FAC.chorus.special.d | Applied |  |
| T-61 | data.js NEM_ADAPT_FAC.hegemony.special.d | Applied |  |
| T-62 | data.js NEM_ADAPT_FAC.voidsworn.special.d | Applied |  |
| T-63 | data.js NEM_PERSONA.patient.d | Applied |  |
| T-64 | data.js NEM_PERSONA.proud.d | Applied |  |
| T-65 | data.js NEM_PERSONA.methodical.d | Applied |  |
| T-66 | data.js NEM_FAC.deathless.beh.d | Applied |  |
| T-67 | campaign_run.js:80 | Applied |  |
| T-68 | campaign_run.js:274 | Applied |  |
| T-69 | campaign_run.js:294 | Applied |  |
| T-70 | campaign_run.js:278 | Applied |  |
| T-71 | campaign_run.js:279 | Applied |  |
| T-72 | campaign_run.js:279 | Applied |  |
| T-73 | data.js WTRAITS.las.d | Applied |  |
| T-74 | data.js WTRAITS.scrap.d | Applied |  |
| T-75 | data.js WTRAITS.needle.d | Applied |  |
| T-76 | data.js WTRAITS.plasma.d | Applied |  |
| T-77 | data.js WTRAITS.hellfire.d | Applied |  |
| T-78 | data.js EVENTS.beacon.o[2].s | Applied |  |
| T-79 | data.js EVENTS.derelict.o[2].s | Applied, note | Anchor matched only apostrophe-tolerantly: the shipped source encodes the apostrophe as U+2019 or a \u2019 escape where the pack Current uses a straight quote. The pack Replacem... |
| T-80 | data.js EVENTS.astropath.v.corsair.b | Applied |  |
| T-81 | data.js ADMIRALS.nekhet.d | Applied, note | String occurs 2 times in data.js; swapped only the occurrence on the cited line 233 (the other occurrences belong to sibling rows or, for T-81, to the Chorus admiral whose ident... |
| T-82 | data.js MORE_SHIP_NAMES.corsair[9] | Applied, note | Replacement is a chair PROPOSAL wording in the pack. |
| T-83 | ui3d.js:650 | Applied |  |
| T-84 | campaign3d.js:92 | BLOCKED | Placeholder tokens in the pack Current and Replacement (${mod}, ${prize}) do not exist in the shipped template at campaign3d.js:93, which interpolates ${modName(m)} and ${p.name}. The Current anchor therefore does not exist in the source, and the Replacement pasted verbatim would reference two undefined variables and throw when the Corsair prize toast fires. Pack row needs its tokens corrected to the shipped ones. |
| T-85 | data.js RUN_WORD.deathless | Applied, note | Pack marks this row NOTE/optional; applied in the rehearsal so its effect is visible, Ryan can veto the one word. |
| T-86 | campaign_meta.js:150 | Applied |  |
| T-87 | campaign_meta.js:151 | Applied |  |
| T-88 | campaign_meta.js:167 | Applied |  |
| T-89 | campaign_meta.js:167 | Applied |  |
| T-90 | campaign_meta.js:171 | BLOCKED | The shipped string is not plain text: at campaign_meta.js:171 each key is wrapped in its own <kbd> element (<kbd>Tab</kbd> next ship, <kbd>Q</kbd>/<kbd>E</kbd> turn, ...), and the pack Current is only the rendered text content (its own cell admits "rendered with kbd tags"). No plain-text anchor exists in the source, and pasting the plain-text Replacement would strip the kbd markup from the keys line. Pack row needs a markup-carrying form of the replacement. |
| T-91 | campaign_meta.js:68 | Applied |  |
| T-92 | ui3d.js:64 | Applied, note | Line drift: inventory says 62, the string sits at line 64 in the shipped file. Swapped at the real location. |
| T-93 | campaign3d.js:116 | Applied, note | Line drift: inventory says 120, the string sits at line 116 in the shipped file. Swapped at the real location. |
| T-94 | campaign3d.js:23 | Applied, note | Line drift: inventory says 22, the string sits at line 23 in the shipped file. Swapped at the real location. |
| T-95 | battle.js:586 | BLOCKED | Placeholder mismatch: the pack Current and Replacement interpolate ${fl.name}, but the shipped flee log at battle.js:586 interpolates ${f.name} (the flagship variable in nemFleeCheck is f; fl exists only in other functions). The Current anchor does not exist in the source, and the Replacement pasted verbatim would throw a ReferenceError when a Nemesis flagship flees. Pack row needs fl corrected to f. |
| T-96 | battle.js:600 | Applied |  |
| CODE-9 | data.js: | Applied | Fourth haven option added with the pack's exact data values (k:'leave', l:'Leave the den alone', s:'Nothing happens.', r:{}), formatted to the file's style. This is a data addit... |
## Method and artifacts

Scratch copy: ~/workspace/voidsworn-text-dryrun/ (the clone's root .js and .html files, copied Oct 30, 2026, edited in place; the clone at ~/workspace/voidsworn-fresh was never written to, and the staged pack and staged suite were never modified). The findings suite was run from a byte-identical copy of the staged files in the dry run's own run/ folder, because the staged suite resolves its loader by relative path; the copy was verified identical with cmp before use. Working scripts and evidence in the same folder: parse_pack.js, probe.js, apply.js, verify.js, mechanical.js, application_log.json, verify_results.json, baseline_clone.txt, after_scratch.txt, xref_clone.txt, xref_scratch.txt, lint_clone.txt, lint_scratch.txt. Baseline suite result (72 tests, 8 pass, 64 fail) was reproduced against the clone before any edit, matching the staged README.

Not covered: visual fit of any string in the rendered UI (length ratios are the stated proxy), the Godot tree's text state, and the four DEC items in the pack, which are Ryan's decisions and were not rehearsed.
