# Method audit: did rulings R201 to R218 land in the working documents?

Issue 558, Part B. Muse outside audit, Nov 12, 2026. Basis: the main branch after PR 555 merged (Nov 12, 2026, 03:47 UTC), so the tree read here already includes the issue 492 cleanup. Documents read in full: docs/RULEBOOK.md, docs/playbooks/ships.md, factions.md, concepts_round2.md, deaths_and_hits.md, effects.md, screens.md, sound.md, PROGRAM.md, docs/ship_pipeline/RECIPE.md, AGENTS.md, HANDOFF.md, contrib/opus/FINDINGS.md (R201 to R218). PR 555 is spot-checked at the end, as the issue asked. Every claim below cites the file it was checked in; anything not checked says so.

## Summary

Fourteen rulings landed, three landed partly, one is contradicted by a live document, none is missing outright.

| Verdict | Count | Rulings |
|---|---|---|
| LANDED | 14 | R201, R202, R203, R204, R205, R206, R207, R208, R209, R212, R213, R214, R216, R217 |
| PARTLY | 3 | R211, R215, R218 |
| CONTRADICTED | 1 | R210 |
| MISSING | 0 | |

The ship method is in good shape: R203 to R209 and R212 to R217 are stated, with Ryan's words quoted, in the documents a builder reads first, and R218's ship half is the model case of a ruling written as a general rule. The failures cluster on screens. The screens playbook on main still teaches the retired lime system as live and leaves the battle HUD question open a day after Ryan ruled it, and the second half of R218 (the narrowed battle sheet) is written in no working document at all. Two smaller wording drifts (RECIPE.md's retired outline gate, sound.md's takes count) are fixed in Part D of this same delivery. One live contradiction between playbooks (Hegemony "parts cleanly") is carried below as an exact fix wording, because PR 524's branch owns that file today.

## The eighteen rulings

- R201 (round 8 picks, A16 and A17 accepted): LANDED. factions.md's concept table carries the accepted references, concepts_round2.md and HANDOFF.md section 0 repeat them. Two legs (DeepSeek, Grok) graded PARTLY because the round's job order and cleanup closures live only as status in HANDOFF, not in a working document; the chair grades the ruling landed, since the picks and references are what a builder needs and they are in place.
- R202 (the Board owns the codebase and runs the build): LANDED. RULEBOOK 2.1 quotes Ryan ("you own the codebase and github. you are my orchestrator and control the building"); PROGRAM.md and HANDOFF.md section 0 state the same.
- R203 (build sheet first, passing the concept standard): LANDED. ships.md section 0 item 5 and section 2 inputs (the sheet's contents, step D owned by Opus at line 130); RULEBOOK 5.1; RECIPE.md's method statement.
- R204 (Chorus accepted, colour fixed in the build, H12 fails, shape-locked route): LANDED. concepts_round2.md line 25 (rule 5, with Ryan's quote); factions.md's table; HANDOFF.md section 0.
- R205 (every Blender build is an Opus worker's): LANDED. RULEBOOK 2.6's seat table quotes Ryan; ships.md section 8; PROGRAM.md lines 64 and 114; AGENTS.md defers seats to RULEBOOK 2.6. No live document hands a Blender build to Codex. One history note: deaths_and_hits.md's build-order list still names Codex for issues 365 and 366a-d, but the section frames itself as the original plan and states those issues are closed (R201), so it reads as history, not instruction. NOTE only.
- R206 (E11 and E12 accepted, station T2, Codex and DeepSeek free up Opus): LANDED. factions.md, PROGRAM.md, HANDOFF.md section 0, RULEBOOK 2.6.
- R207 (the concept guides the build, the builder designs): LANDED. ships.md 2a quotes Ryan twice and states the designer of record rule and the departure list; RULEBOOK 5.2.
- R208 (hits pushed harder, torpedo 140 px, neighbour light faint): LANDED. deaths_and_hits.md line 31 and effects.md line 27 state all three picks with Ryan's words; the 140 figure is what the code builds (Part A of this issue). Grok graded PARTLY on build state; the audit's scope is documents, so that grade is not adopted.
- R209 (build the insides, no empty husks): LANDED. ships.md 2b and the job template's Inside line (line 187); factions.md line 26 and its per-faction "How it breaks".
- R210 (battle screen E1 Ledger, Glacier for shield readouts only): CONTRADICTED on main. Finding 1 below.
- R211 (second sweep for dropped context): PARTLY. Finding 6 below.
- R212 (rocks turn slowly by default): LANDED. PROGRAM.md line 166 and RULEBOOK line 489; PR 548 merged the code default.
- R213 (builds barely look like the concepts; the concept guides, guns must make sense): LANDED, with the labelling condition in Finding 4. ships.md 2c and the section 2 inputs (weapon slots from data.js, line 51); RULEBOOK 5.2.
- R214 (the method is binding in the working documents; a ruling lands with its document): LANDED for ships (ships.md section 0, eight numbered lines each with its source; RECIPE.md line 12 and the manifest at line 18; AGENTS.md lines 47 to 51; contrib/opus/briefs/muse_standing_rule.md). The screens playbook is the standing exception, recorded under R210: there the ruling's document edit is still inside unmerged PR 544 a day later, while the ship method PRs 549 and 551 landed the same evening.
- R215 (comprehensive insides; R99 Q2's fixed break-line count superseded): PARTLY. Finding 5 below. The supersession half is fully landed: RULEBOOK line 271 retires the count, ships.md line 26 repeats it, and no live document states the old count as a rule (grep checked).
- R216 (the rulebook batch, eleven items): LANDED, with the propagation note in Finding 7. RULEBOOK carries every item (2.7, 2.16, 3.10, 6.14, 6.15 retired, 6.16, 7.8, 9.13, 10.8, 10.9, 10.10); no playbook restates the retired section tint (grep checked).
- R217 (parts read as what they are; the fit check): LANDED. ships.md 2c lines 70 to 90 (part shapes named part by part, the fit check with its fit view and fit report, a clash left in is blocking); RULEBOOK 5.15. The fit check is qualitative, with no numeric clearance; its teeth are the fit view and the report, which is how Ryan judges. Accepted as written.
- R218 (fidelity is whole-ship and general, not a patch; the battle sheet narrowed): PARTLY. The ship half is LANDED and is the model case (ships.md 2c lines 88 to 108; RULEBOOK 5.16). The screen half is landed nowhere a worker reads: Finding 2.

## Findings, worst first

### 1. screens.md on main contradicts R191, R210 and the 17 px floor

docs/playbooks/screens.md is still the pre-orders-sheet playbook. Its section 2 teaches the retired system as live: line 16, "Lime means the next action and what it acts on"; line 18, "One filled button per screen: the lime one"; lines 19 to 21 give a type ladder ending "Nothing under 12", against RULEBOOK 9.4's floor of 17 px. Section 8 (line 91) leaves the battle HUD open: "Whether the battle HUD takes the map's calmer treatment (program decision 8). Until he rules, the HUD keeps its slabs", although Ryan ruled E1 Ledger and Glacier in R210 on Nov 11, 2026, at 18:40 CST, and retired lime in R191 before that. A grep of the file finds no Glacier and no E1 Ledger. The fix exists only inside unmerged PR 544, whose screens.md rewrite carries the ruling. Until 544 merges, the first document a screen builder reads instructs the opposite of two rulings and a retired text floor. Verdict for R210: CONTRADICTED on main; it becomes LANDED when 544 merges, except for the width rule in Finding 2. Section 9's seat line (lines 93 to 96, "Codex or an Opus helper builds") is also stale against RULEBOOK 2.6; PR 544's rewrite covers the file, so no separate fix is proposed.

### 2. R218's screen half is in no working document

The narrowed battle sheet (about a fifth of the screen width, detail only for the current decision, the 17 px floor kept) exists today only as constants and comments in godot code (ledger.gd, checked in Part A2 of this issue) and as the FINDINGS row. RULEBOOK has no width rule for the sheet, and screens.md, including PR 544's rewrite of it, states the layout, Glacier and the readability floor but never the width discipline. This is the exact failure R218 was made to stop: the next screen built from the playbook can drift wide again and no document would say it broke a rule. FIX wording for the Board, to fold into PR 544 or its follow-up (not applied in Part D, because 544 rewrites this file and a parallel edit invites a conflict):

- In screens.md's battle screen section, add: "The orders sheet takes about a fifth of the screen width, never more than a quarter. It shows detail only for the decision in front of the player; everything else waits behind a key or a hover (R218)."
- In screens.md's system section, add: "Sheet and panel widths are set by the decision the screen holds, not by how much data exists. When Ryan rules a width on one screen, write it here as the rule for every sheet (R218)."

### 3. Two wording drifts, fixed in Part D of this delivery

Both catches are DeepSeek's, verified verbatim by the chair.

- RECIPE.md still states the retired outline gate as a gate: stage 3's table row (line 38), the stage notes (line 56) and the checks table (line 154) say "Gate: 90 percent overlap" with PASS or FAIL, against RULEBOOK 5.8 (line 281: the overlap is reported, not a pass bar, since R147). ships.md section 4 already acknowledges the transitional state (the stage still exits non-zero below 0.90 until the workhorse fix lands). Part D delivers the corrected RECIPE.md wording, citing RULEBOOK 5.8 and R147, leaving the lines that describe actual code behaviour untouched.
- sound.md line 29 says "At least four takes of anything heard often", against RULEBOOK 8.4 (lines 426 to 427), where Ryan's rewording made four the starting count, not a floor ("four takes is the starting count"). Part D delivers the corrected sound.md line, citing RULEBOOK 8.4.

### 4. RIGHT, R213: Board mechanisms are stated as ruling text without a label

Ryan's R213 words describe failures: guns randomly placed and not making sense, builds flat and blocky, "barely looks like the concepts". The mechanisms now binding in ships.md 2c (guns taken from the hull's data.js slots as paired batteries, the blockout built over the stage 2 shape reference, heights carried tier by tier against a side view) are the Board's constructions. Qwen's leg isolated the two exact spots: the data.js gun source is the Board's remedy, not Ryan's instruction (he named the failure, not the source), and "carries every tier" turns a flatness complaint into a positive mandate, where the word "every" is the Board's. The direction was endorsed by Ryan's follow-up the same evening, and nothing here contradicts him; but under R214 these documents bind, so a future dispute cannot tell which lines are Ryan's words and which are Board method under R202 unless the document says so. FIX wording for the Board (ships.md, not touched by Part D because the audit cannot rule on its own condition):

- At the head of ships.md 2c, add: "Ryan's words in this section are quoted. The mechanisms (gun slots from data.js, the blockout over the stage 2 reference, heights against a side view) are the Board's method under R202, written to answer the failures he named in R213."

Whether Board method lines should carry a label wherever they sit beside a ruling number is Ryan's call, offered in the delivery note.

### 5. RIGHT, R215: landed in substance, with two residuals

ships.md section 0 item 4 states comprehensive insides and quotes Ryan's caveat in the same item ("better to be comprehensive with internal if we can without performance issues"), so a worker who reads the item gets both. Two residuals, both small:

- The item's heading states the rule flatly ("Breakable by design, comprehensive insides"), so heading-only reading drops the condition. Proposed heading: "Breakable by design, comprehensive insides (performance permitting, R215)".
- The same item asserts the mechanism as settled fact: "they stay hidden until a piece breaks away, so they cost memory, not frame time". That is the Board's engineering claim, not Ryan's words, and no measurement is cited for it. DeepSeek and Qwen both caught this independently. If a measurement later shows insides costing frame time, this sentence reads as a promise the documents never verified. Proposed wording: "they stay hidden until a piece breaks away; their cost is reported per build (R111), and the measured scene gate decides whether the full set ships (R215)".

Verdict PARTLY on these two points only; the rule and its caveat are in the document.

### 6. R211: the sweep happened; the standing duty is written nowhere

R211 ordered a second sweep for dropped context. It was discharged as an event: issue 540 ran, closed with follow-ups 545, 546 and 557, and this audit is part of the same discharge. RULEBOOK 0.2's Why line (line 22) even names R211 among its reasons. What no working document states is the sweep as a standing practice: nothing a worker reads says the sweep repeats, or who runs it, and HANDOFF.md's open-issues table never listed issue 540 at all (grep checked). DeepSeek graded R211 MISSING on exactly this ground, Qwen and Grok PARTLY; the chair adopts PARTLY. If the Board wants the sweep to recur, one line in RULEBOOK 0.2 or AGENTS.md would land it; if it was a one-time order, the FINDINGS row plus issue 540's closure is a complete record and no fix is owed.

### 7. R216's gameplay items live only in the rulebook (Grok's catch, adopted as a note)

The batch's gameplay items (6.14 hull opens near-dead, 6.16 death cost, 7.8 strike craft, 9.13 prize screen, 10.8 battle opens on both fleets, 10.9 nebula colour) appear in none of deaths_and_hits.md, effects.md, screens.md or PROGRAM.md; they are carried only in RULEBOOK.md (grep checked; the one 14-second hit in deaths_and_hits.md is coals cooling, a different number). R216 stays LANDED, because the batch ordered the rules into force and the rulebook is read first and wins. The note is for the Board: either carry the gameplay items into their area playbooks, where a worker in that area will meet them, or record rulebook-only as the accepted landing for batch items, so the next audit does not re-raise it.

### 8. The newest ship rules are missing from both summaries a builder reads first (Qwen's catch, adopted)

ships.md section 0 presents itself as the settled method, each line with its source named, but its eight lines do not include R217 or R218; both live only in section 2c (the R217 heading at line 70, R218 at line 89). RECIPE.md cites neither ruling anywhere (grep checked), though both change how a build is done, and RECIPE's method paragraph defers to ships.md section 0, which also omits them. A builder who reads section 0 and RECIPE.md, the two summaries, would miss the fit check and the parts inventory. Recommendation: add one line to section 0 pointing at 2c for R217 and R218, and one citation line to RECIPE.md's method paragraph. Not applied in Part D; the Board owns both files' structure.

### 9. Consistency notes, minor

- PROGRAM.md's track tables still name Fable seats (lines 86 to 122: "Fable helper", "Fable options", "Fable reviews") while its budget section states "No Fable helpers (R180)" (line 77). The document's own "Who does what" preamble discloses the reading (Fable in the tables means the Board or an Opus worker), so this is staleness, not contradiction. Caught by Flash, verified by the chair.
- HANDOFF.md section 0 is stamped Nov 11, 2026, 20:30 CST and points readers at FINDINGS R183 to R215, so it predates R216, R217 and R218 (20:58, 21:24 and 21:34 CST) and cannot serve as live status for them. Normal for a dated snapshot; noted so nobody cites it for those three.
- ships.md's sections run 2a, 2c, 2b (2c at line 70 before 2b at line 110), because 2c was added after 2b. Renumbering would break RULEBOOK and FINDINGS citations to "ships.md 2c". Leave the numbers; NOTE only.
- factions.md's cruiser breach anchor count and RECIPE.md's C15s_23 worked example disagree (the export carries 6, the contract gives 5); RECIPE.md documents the discrepancy itself and the stage 7 re-export it is owed. Known and self-documented; not a rules contradiction.
- deaths_and_hits.md line 128 says Hegemony "Parts cleanly at the module joints", against factions.md lines 31 to 32 ("not that it parts cleanly") and R186's torn, scorched rims. DeepSeek's catch, verified verbatim. FIX wording for the Board (not applied in Part D, because PR 524's branch owns deaths_and_hits.md today): replace the line 128 phrase with "Breaks at the module joints, the rims torn and scorched (R186)".

## The three questions the issue asked

- RIGHT (does the document go past Ryan's words?): twice, in the two places the issue named. R213's mechanisms are Board constructions stated beside the ruling number without a label (Finding 4). R215's mechanism sentence asserts the performance question away where Ryan left it conditional (Finding 5). Nowhere else in the set does a document state more than Ryan ruled; R207's "designer of record" is a formal title over his own words ("Opus should have final decision making as the designer") and is recorded here as faithful.
- GLOBAL NOT A PATCH: R218's ship half is the model case, written as a general rule for every ship, every faction and the station in both ships.md 2c and RULEBOOK 5.16. Its screen half is the counterexample (Finding 2). No other ruling in the set landed as a local patch.
- CONSISTENT: the live disagreements are Findings 1, 3 and 9 (screens.md against R191, R210 and the floor; RECIPE.md's gate wording; sound.md's takes; deaths_and_hits.md against factions.md), plus the minor notes in Finding 9. No other pair of live documents disagrees on this set.

## PR 555 spot-check (the issue's "review if still open")

PR 555 merged at Nov 12, 2026, 03:47 UTC, before this audit read main, so there was nothing open to review; the audit instead spot-checked the merged result. AGENTS.md is slimmed as claimed, with the archive pointer at docs/archive/AGENTS_2026-11-11.md and the note that every rule the old file held is in the rulebook; nothing this audit needed was missing from the live documents. No separate findings.

## Council record

Seats per the issue block, as amended by Ryan on Nov 11, 2026: blind Rey leg first (written from FINDINGS and RULEBOOK alone, before the playbooks were read), DeepSeek and Qwen writing, Flash and Grok in the ideation seat, Argon off (R216). All legs ran under their model gates: DeepSeek with DeepThink on and Search off, Qwen on Qwen3.8-Max (selector verified before the run, header verified after).

- Blind Rey leg: set the expectations the audit tested (filed with the working papers). Its failure tests all resolved the way the chair's verdicts record.
- DeepSeek (writing): LANDED 14, PARTLY 1 (R201), MISSING 1 (R211), CONTRADICTED 2 (R210, R218). Agrees with the chair on every headline except R218, where its CONTRADICTED grades the screen half against main's screens.md; the chair's PARTLY credits the ship half's full landing. Its three new catches (RECIPE.md's gate, sound.md's takes, deaths_and_hits.md's "cleanly") were all verified verbatim and are Findings 3 and 9. Chat: https://chat.deepseek.com/a/chat/s/877d0c3b-dc79-442a-a775-3d5626c017ea
- Qwen (writing): LANDED 16, PARTLY 2 (R211, R218), CONTRADICTED 0. Its RIGHT analysis (Findings 4 and 5) and its two summary-omission catches (Finding 8) are adopted and credited. One provenance fault, established by the chair: the leg received two different screens.md texts in its chat (main's version and PR 544's ember rewrite), so its screens.md evidence and its R210 LANDED grade rest on the unmerged rewrite, not on main. Every screens-dependent Qwen finding is set aside in this audit, with the chair's own full read of main's file supplying the evidence instead. Chat: https://chat.qwen.ai/c/20197f66-8dbd-4f80-b02a-41599504c27a
- Grok (ideation): LANDED 12, PARTLY 5, MISSING 1 (R216), CONTRADICTED 0. Recorded dissents: it grades R210 and R218's screen half PARTLY on trajectory (PR 544 carries the fix) where the writing legs grade main as it stands; it dissents on RIGHT at both R213 and R215, holding the documents operationalise Ryan's words without going past them; it grades R208 PARTLY on build state, outside the audit's document scope. Its R216 propagation catch is adopted as Finding 7 (its MISSING grade is not: the batch is in force in the rulebook). Chat: https://grok.com/c/077008ce-39ff-436c-bfff-fcb0d6339e00
- Flash (ideation): counts as delivered LANDED 12, PARTLY 3, CONTRADICTED 2, MISSING 1. Its citations largely failed chair verification (ruling topics scrambled, and its screens.md quotations describe a document that is not in the pack), so none of its verdicts are adopted. One observation survived verification and is in Finding 9 (PROGRAM.md's Fable seat rows). Chat: https://gemini.google.com/app/b7272f38320d4dcd

Chair's verdict: the method landed where the builders of ships read. It did not land where the builders of screens read, and one half of the newest ruling is written nowhere. Findings 1 and 2 are the ones that will bite first.
