# Outside check: PR 786 (records of Ryan's 785 picks, R259) and PR 789 (DeepSeek arm debrief follow-up, issue 728)

Refs #256

## Verdict: GO WITH CONDITIONS

PR 786 records Ryan's three finals accurately, with two record defects to repair in a follow-up: the Chorus round 3 file carries no owner's ruling, and the Hullbreakers round 3 file overstates the council lean as unanimous. PR 789's two build-time choices are both defensible, the progress rule more than the rank rule; the check's conditions ask the Board to pin the intended readings into the design record, because as shipped neither rule's meaning is written down anywhere a future editor will find it. DeepSeek returned NO-GO; its textual findings are largely right and are carried as conditions, but the chair does not adopt the verdict: every defect it names is a record or labelling defect in merged work, none is a wrong pick, a wrong figure, or a behaviour that contradicts a ruling.

Council: blind Rey GO WITH CONDITIONS. DeepSeek (DeepThink on, Search off, verified both ends) NO-GO. Qwen (Qwen3.8-Max, verified both ends) GO WITH CONDITIONS. Flash (Flash-Lite, verified both ends) GO WITH CONDITIONS. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS. Grok (Fast) GO WITH CONDITIONS, its first filled seat after 46 consecutive empties (route note at the end).

## Part 1: PR 786, the records

**The finals are recorded accurately.** The chair compared the merged notes against Ryan's messages of Nov 15, 2026. Hegemony round 3 carries the merge ruling, the slimming amendment in sheet terms, and the final ruling ("HF1D with the slimmed prow is good to go"). Hullbreakers round 3 records KB1C-C, the Wide Glacis, with Ryan's words quoted ("the best by far") and the council lean recorded as not taken. Chorus round 4 records CS1B-A2, the Sealed Gills sleek, as the pick with CS1B-C2 as the recorded second. No file settles or claims the replace-vs-variant question, which Ryan has not ruled; the "direction settles" phrasing is the set's standing direction language, though see condition 3.

### Conditions

1. **The Chorus round 3 file has no owner's ruling section.** design_notes_785_round3.md for Chorus ends at Production notes. Ryan's ruling (A, the Sealed Gills, gills sealed, and sleeker) survives only in the round 4 file's header, paraphrased as "CS1B-A and CS1B-C are very close to right, but the craft needs to be a bit sleeker", which widens his pick of A into an A/C shortlist (C was a council minority lean in round 3, Qwen's, against DeepSeek and the blind leg on A). The outcome was unaffected, since round 4 was a proportion pass on A and C and Ryan picked A2, but the record should carry the ruling as given: add the owner's ruling section to the Chorus round 3 file, and correct the round 4 header to match it. (Blind Rey, DeepSeek, Qwen, Flash, ChatGPT; Grok alone found nothing missing, recorded as its miss.)
2. **"Unanimous" overstates the Hullbreakers council record.** The round 3 file's chair's lean says "KB1C-A, unanimous among the seated legs and the blind leg", and the owner's ruling repeats "the council's unanimous lean for KB1C-A". The council record in the same file gives Flash as "KEEP A and C; DROP B", with no lean stated; DeepSeek, Qwen and the blind leg leaned A. Three leans and one keep-both is a strong majority, not unanimity. The chair of that round wrote the overstatement and owns it; correct both sentences in a records pass. (DeepSeek, alone in catching it; the other legs repeated "unanimous" uncritically.)
3. **Record replace-vs-variant as expressly open in the three final notes.** No file settles it, but the closing lines ("the direction is settled on this craft and this sheet", "the direction settles on the sleek sealed-gill craft") could be misread by a future implementer as replacement. One sentence per faction, on ChatGPT's suggested wording ("The owner has not ruled whether this winner replaces the base design or stands alongside it as a variant; that decision remains open"), removes the ambiguity at no cost. (DeepSeek, ChatGPT.)

Cosmetic, no condition: PR 786's title still says "(R253, round 1)" though it carries rounds 1 to 4, and its body is two lines with no contents summary.

## Part 2: PR 789, the two unsourced choices

The Board's question: the candidate rank rule and the most-progress faction rule, made without a design source, are they sound?

**Chair groundings from the repo** (the pack did not carry these; DeepSeek, Qwen and ChatGPT each flagged them as unverifiable, so the chair checked): the CAPTAINS rank tables in data.js are ordered ascending in every faction (Lieutenant to Rear admiral; Claw to Warlord; Spawn-mind to Great throat; Glimmer to Lens-keeper; Shade to Nadir), so ranks[ranks.length-1] is in fact the faction's top rank. Mastery XP is capped per admiral (230 base, raised by capstone levels), and shadow XP is credited into the same mastery pool, inside the flown faction only, at quarter rate (half for the heir). So facProgress includes shadow earnings, and all of it accrued within the faction it measures.

**Progress rule: sound, with the saturation caveat.** A deterministic most-invested-unwon pick is strictly more legible than the old random pick; it reads only existing save fields; ties break in RUN_FACTIONS order; the all-won fallback keeps the panel useful. The caveats the legs raised are real but bounded: capped admirals stop contributing signal, so two saturated factions tie and the fixed order decides (DeepSeek, Qwen, ChatGPT); and the sum measures admiral investment, not closeness to a faction win, so the panel should not be read as "nearest to winning" (all legs). Neither caveat makes the rule wrong for a next-run suggestion; they make its label matter.

**Rank rule: the weaker choice, sound only under one reading.** If design 4.5 means the heir row shows the office the candidate steps into, defaulting to the faction's top rank is coherent and the name-carried ranks are the anomaly. If it means the rank the candidate holds, the default invents a rank for most rows. The implementation mixes the two provenances invisibly: a name-carried rank and a defaulted top rank render identically, and two unranked candidates of one faction both show its top rank (Qwen's point). The code itself is careful (longest-first matching with a trailing space, so partial words cannot false-match), and ChatGPT's further point stands: the source table is CAPTAINS ranks applied to ADMIRALS, which the design does not sanction either way.

### Conditions

4. **Pin both readings in the design record.** Against design 4.5, record whether the heir row's rank is the office or the holder's rank; if the holder's, the top-rank default should come out and rows without an authored rank should show none (ChatGPT's recommendation). Against design 3.9/6, record that "progress" for the NEXT RUN panel means total mastery XP (the investment reading), so the metric stops being an orphan invention. No code change is required by this check under the office and investment readings, which the chair judges the more plausible intents; the condition is that the Board write them down. (All legs converge here in different words; DeepSeek and ChatGPT would go further and change the display, recorded below.)
5. **The colour has no committed test.** core_sync_tests now strips the PATRONS colour markup before asserting the copy, which is the right way to keep testing the text (Qwen, DeepSeek), but it means the committed suite no longer checks the colour at all; the only colour check was the arm's uncommitted scratch spot check. Add a committed assertion for the span, or accept the gap knowingly. (DeepSeek, ChatGPT.)

Notes: the same six captures are committed twice (docs/shots/debrief_92/ and docs/shots/issue-728-deepseek/); one canonical home, with the README, would do (all legs). The headline story slot's collapse rule (hidden when empty or when it duplicates the payoff line) matches the stated intent (all legs). Godot parity, the 50 PASS suite result and the load gate are taken as reported in the PR body; the runner output there is internally consistent.

## The DeepSeek NO-GO, answered

DeepSeek's blockers were its findings 2, 3, 5 and 6. Findings 2 and 3 are carried as conditions 1 and 2 above; on 2 it was the only leg to check the claim against the file, and it was right. On 5 and 6 it judged both rules not sound as shipped. The chair's groundings narrow 6 (the ordering, cap and shadow facts are now established, and the rule is sound under the investment reading), and on 5 the disagreement is over which reading design 4.5 intends, which only the Board can settle; condition 4 forces exactly that. A NO-GO would say the merged work should not stand; nothing in either PR misstates a ruling, breaks a check, or behaves against a design line, so GO WITH CONDITIONS is the proportionate verdict. The dissent is recorded in full in the leg file.

## Leg notes and slips

- Grok misnames HF1D as "the Reflined Shield" (the sheet says the Spined Shield), writes "run_all_tests" for run_all_checks, inverts the core_sync_tests change (it says the test now checks the markup before the copy assertion; the test strips the markup), and found no Chorus ruling missing. Recorded; nothing rests on them. Its Part 2 analysis converges with the council.
- ChatGPT and Flash both repeat the notes' "unanimous" wording without checking it against the council record in the same file. Recorded.
- Qwen dates its response Nov 16, 2026; the run was Nov 15 CST. Cosmetic.
- Qwen's first two sends bounced without creating a chat and the third needed a regeneration after an internal error; the gate held throughout. DeepSeek's pack paste initially landed as a file chip and was expanded to inline text before sending. Neither affects the responses.

## Route note (Grok)

The Grok seat filled for the first time in 47 rounds. grok.com/ still returns the block, but grok.com/chat loads; sending before sign-in raises the sign-up wall; Continue with Google plus the owner's phone approval completed sign-in on the cloud profile, and the leg then ran in Fast mode. If the profile keeps the sign-in, future Grok legs should start at grok.com/chat already signed in.

## Not checked

- The debrief captures at picture level (both folders); the PR's account of what they show is taken as reported.
- The Godot twin's heir label and story slot beyond the parity result reported in the PR body.
