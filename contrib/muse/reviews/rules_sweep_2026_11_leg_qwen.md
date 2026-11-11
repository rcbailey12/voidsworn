# #495 Qwen WRITER leg: the agent-facing documents

Chair header: run Nov 11, 2026, 11:09 to 11:23 CST, chat.qwen.ai, signed in as Ryan Bailey. Model gate: Qwen3.8-Max in the selector before both sends and in the chat header after the reply completed (re-selected when navigation reset it to Qwen3.7-Plus). Files: Qwen caps uploads at five documents per single-turn conversation, so with the chair's approval the runner used two turns: turn 1 carried PACK_QWEN.md, AGENTS.md, CLAUDE.md, HANDOFF.md and REVIEW_PROTOCOL.md with a holding message; turn 2 attached src_README.md, src_BLOB_SWEEP.md and src_go-forward-plan.md and sent the assigned prompt unchanged. An Access Verification slider appeared after turn 2's attachments and was cleared under Ryan's standing authorization; chat, model and files stayed intact. One response, not two, not cut off. Filed verbatim below.

Chair screening notes (not part of the leg): (1) B8 counts this leg's own PACK_QWEN.md as a third copy of the no-em-dashes rule; that is the pack restating the house rule for the leg, not a project document, and the chair discounts that one exhibit while keeping the AGENTS.md and go-forward-plan copies. (2) A1's blob sweep contradiction (BLOB_SWEEP's clean-or-rebuild verdicts against AGENTS.md's "no clean-or-rebuild pass bar (R121)") was verified at chair against both source files and stands; it converges with DeepSeek's R105/R121 item from the FINDINGS side. (3) The leg stayed inside its eight files as instructed; where it says a ruling is "not in the attached files" (A12), that is the leg marking its own evidence limit, which is correct behaviour.

---

Leg text for the Qwen WRITER seat, Voidsworn issue 495. Outside leg, built only from the eight attached files.

Part A: Rules I would challenge first

Fifteen rules, ranked most restricting or most misleading first.

A1. The blob sweep demands a clean-or-rebuild verdict per cell, but the live rules say there is no pass bar.
Where: src_BLOB_SWEEP.md, section 1 ("Review grid, 9 cells"). The contradicting ruling is in AGENTS.md, section "Ship models (the current big job)."
Who set it: The sweep itself is Ryan's call. AGENTS.md records: "Blob sweep for every AI ship (owner, Oct 21 2026)." The no-pass-bar ruling is cited as R121.
Reason recorded: BLOB_SWEEP says: "Each cell gets a verdict: clean or rebuild by hand, with the part named." AGENTS.md says: "The sweep is a viewing instrument for Ryan's eye, with no clean-or-rebuild pass bar (R121)."
What it stops: An agent reading BLOB_SWEEP first will treat the sweep as a gate that blocks a ship from being shown. It will halt work, flag rebuilds, and refuse to present a ship to Ryan until every cell says "clean." AGENTS.md says the sweep is only a way for Ryan to look. The two instructions cannot both be followed. A newcomer reading BLOB_SWEEP, which is the dedicated document for the sweep, will obey the stricter version.
Disposition: REWORD TO ITS PURPOSE. Strike the clean-or-rebuild verdict language from BLOB_SWEEP. Replace it with: "Each cell is annotated with what the agent sees, so Ryan can judge at a glance. There is no pass or fail bar." This is Ryan's own call (R121), so the rewording needs his confirmation only if the Board changes more than the wording.

A2. Phone LOD, phone screenshots, and phone file sizes are still written as pipeline steps, but the game is PC-only.
Where: src_README.md, steps section ("Phone LOD: lod_make.py") and the game-format line ("phone about 3.5 MB at 250k"). src_BLOB_SWEEP.md, section 5 ("In-game check"): "Shots on desktop and phone, at zoom 1.0 and 0.5, on at least two maps." AGENTS.md, section "Owner rulings and lore": "Owner rulings of Oct 24 that override older docs: PC-only."
Who set it: The PC-only ruling is Ryan's, Oct 24. The phone instructions were written before that ruling.
Reason recorded: None for the phone instructions. The PC-only ruling is listed without further explanation beyond the ruling itself.
What it stops: An agent following the README will build a 250k-triangle phone LOD for every ship, a step that produces a file nobody uses. An agent following BLOB_SWEEP will try to take phone screenshots and may block the sweep on missing phone shots. Both waste PC queue time and agent effort on a platform that no longer exists in the project.
Disposition: RETIRE the phone steps. Replace with nothing. The PC-only ruling (Ryan's call) already covers it. Remove "Phone LOD" from the README steps, remove "and phone" from BLOB_SWEEP section 5, and remove the phone file-size figure. Mark these as Ryan's own call (PC-only, Oct 24).

A3. "Until the engine call, no new Babylon-only rendering work" remains in the plan, but the engine call is done.
Where: src_go-forward-plan.md, section 2 ("How work runs").
Who set it: The Board (Opus), as a technical holding rule during the engine evaluation.
Reason recorded: The plan says: "Until the engine call, no new Babylon-only rendering work beyond what the test and today's game need." The reason was to avoid sinking effort into a renderer that might lose the engine test.
What it stops: The engine call is recorded as done in the same document's phase table: "A3 Engine call: DONE Oct 26: GODOT (R32)." The conditional clause reads as a live prohibition. An agent parsing the plan literally might still refuse Babylon work or, worse, refuse Godot rendering work because the sentence's grammar ties "no new rendering work" to a condition that has already resolved. The sentence gives no instruction for the post-call state.
Disposition: REWORD TO ITS PURPOSE. Replace with: "The engine is Godot (R32, Oct 26). Babylon rendering work is limited to fixes for the frozen browser oracle." This is not Ryan's own call; it was the Board's holding rule, so the Board can reword it directly.

A4. The README describes the meshoptimizer .vsm format as the pipeline output, but AGENTS.md says .vsm belongs to the frozen browser game, not the Godot product.
Where: src_README.md, steps section: "node vsm_pack.mjs dir CODE packs the hull with meshoptimizer into CODE.vsm." AGENTS.md, section "Ship models": "the meshoptimizer .vsm format belongs to the frozen browser game, not the Godot product."
Who set it: The .vsm pipeline was the original build path. The reassignment to the frozen browser game is cited as G-9 and G-11 in AGENTS.md.
Reason recorded: AGENTS.md states: "The current Godot pipeline exports ship assets as glb copied into the PC build (G-9, G-11)." No further reason is given beyond the format belonging to the frozen game.
What it stops: An agent building a new ship will follow the README, pack a .vsm, and produce an asset the Godot game cannot load. The README is the dedicated pipeline document and the one a newcomer reads first. The correction lives in AGENTS.md, which is a general rules file, not a pipeline reference.
Disposition: REWORD TO ITS PURPOSE. The README needs a Godot export step replacing or superseding the .vsm step. Until then, add a note at the top of the README: "The .vsm path serves the frozen browser oracle. The Godot product loads glb assets; see AGENTS.md, Ship models." Not Ryan's call; this is a pipeline update the Board can make.

A5. "Free tools only" is stated as an absolute in three files, but the go-forward plan itself lists licence exceptions.
Where: AGENTS.md, section "Ship models": "Free tools only." src_README.md, header: "Free tools only." src_go-forward-plan.md, section 7 ("Out of scope"): "Paid assets of any kind." But section 3 of the same plan lists: "FLUX dev avoided (licence)" and "Quaternius: licence is QAL, not CC0," showing that "free" is not a single binary but a licence-by-licence judgment.
Who set it: Ryan. The go-forward plan records: "your free-only rule."
Reason recorded: The plan says: "your free-only rule" and lists it under Ryan's decisions. No further reason is recorded beyond the owner's preference.
What it stops: The bare phrase "free tools only" gives an agent no way to judge edge cases. Is a tool with a free tier but paid pro features allowed? Is a CC-BY asset (free to use, requires attribution) acceptable, or is only CC0 fine? The plan's own "Not used, and why" section shows the real test is licence compatibility, not price. An agent that reads only "free tools only" might reject a valid CC-BY asset or accept a tool with a restrictive licence.
Disposition: KEEP AND ADD THE REASON. Rewrite as: "Free tools and free-licence assets only. The test is the licence, not the price tag: CC0 and equivalent permissive licences pass; restrictive or paid licences do not. Edge cases go to the Board." This is Ryan's own call (the free-only rule), so any rewording needs his sign-off.

A6. "No Codex cloud tasks or cloud reviews: they run an older model than the local one" is a technical claim written as a permanent rule.
Where: AGENTS.md, section "The job board."
Who set it: Not recorded in the document as a specific ruling. It appears as a flat statement.
Reason recorded: The reason is embedded in the rule itself: "they run an older model than the local one."
What it stops: When the cloud model updates to match or exceed the local one, this rule will still block cloud use. No agent can override it because it reads as a standing prohibition, not a conditional. There is no review date, no condition for lifting it, and no pointer to who can reassess.
Disposition: REWORD TO ITS PURPOSE. Replace with: "Codex cloud tasks are off while the cloud model is older than the local one. The Board reviews this when the cloud model updates." Not Ryan's call as written; the Board can reword.

A7. "Max 10 findings, most important first" caps review thoroughness at an arbitrary number.
Where: REVIEW_PROTOCOL.md, section 2 ("Stay in scope").
Who set it: Not recorded. The protocol is presented as standing rules for outside agents.
Reason recorded: The document says: "Fewer good findings beat many weak ones." That is a quality preference, not a reason for the number 10.
What it stops: A reviewer who finds 14 real, evidenced problems must drop 4 or split them artificially. The cap is not tied to the size or complexity of the material reviewed. A 3,000-line rules file and a 200-line script get the same cap. For a project-wide sweep like issue 495, ten findings across eight documents is thin.
Disposition: REWORD TO ITS PURPOSE. Replace with: "Report findings in order of importance. If you have more than ten, the extra ones go in a clearly marked appendix. Fewer strong findings beat many weak ones." Not Ryan's call; this is a protocol the Board can adjust.

A8. "Before anything bigger than a quick fix, ask 3 to 5 plain-language multiple-choice scope questions in one batch."
Where: AGENTS.md, section "Owner preferences that apply to any agent."
Who set it: Attributed to owner preferences. The document does not give a specific date or ruling number.
Reason recorded: None beyond the heading "Owner preferences that apply to any agent."
What it stops: An agent with a clear brief and a well-defined issue must still stop and formulate scope questions before starting. For jobs where the issue's "Done when" block already defines scope, this adds a round trip that delays the work. The rule does not say what counts as "bigger than a quick fix," so agents must guess and may over-ask or under-ask.
Disposition: REWORD TO ITS PURPOSE. Replace with: "If the issue brief leaves real scope open, ask 3 to 5 plain-language multiple-choice questions in one batch before building. If the brief and the 'Done when' block already fix the scope, start work." This is an owner preference, so the rewording should go to Ryan.

A9. "Never push to main (R75)" with the exception buried in the next sentence.
Where: AGENTS.md, section "The job board": "Never push to main (R75). The only exception is LOOP.md and FINDINGS, which are committed straight to main as a docs-only exception (R102)."
Who set it: Ryan (R75), with the exception also recorded (R102).
Reason recorded: None for the prohibition. None for the exception. Both are cited by ruling number only.
What it stops: The prohibition is the first and loudest statement. An agent reading quickly, or one that reads only the first sentence, will refuse to update LOOP.md or FINDINGS.md on main, which are the two files the project needs updated there. The exception is grammatically subordinate to the rule it contradicts.
Disposition: REWORD TO ITS PURPOSE. Lead with the positive: "LOOP.md and FINDINGS.md go straight to main (R102). Every other change goes through a branch and pull request (R75)." Both are Ryan's rulings, so the rewording should be confirmed with him, though the substance does not change.

A10. Babylon-specific pipeline notes remain in the README as if they apply to all ships.
Where: src_README.md, "Gotchas learned on the Pyre-Barge": "Converted meshes come out inside-out for Babylon. The loader's faceOut() (ships3d.js) checks the winding against the stored normals and flips it." Also: "Babylon is left-handed, so conversions mirror and flip winding."
Who set it: Not recorded as a ruling. These are pipeline notes from the first ship build.
Reason recorded: None. They are observations from the Pyre-Barge build.
What it stops: An agent building a ship for the Godot pipeline will read these notes and apply Babylon-specific winding corrections that are irrelevant or wrong for Godot's renderer. The README does not mark these as Babylon-only history.
Disposition: REWORD TO ITS PURPOSE. Move these to a clearly marked subsection: "Browser-oracle history (Babylon). These notes apply to the frozen browser game, not the Godot product." Not Ryan's call; the Board can reorganise.

A11. The seat table hardcodes model names and versions that will change.
Where: AGENTS.md, section "Who does what (seat map)." The table names: "Fable 5.2," "Opus 5.5 worker threads," "DeepSeek V4.1 Flash," "Kimi," "Flash and Grok."
Who set it: "Ryan and Opus, Nov 8 2026, FINDINGS R128; Board seat moved to Fable 5.2 on Nov 9, R152."
Reason recorded: The table gives a "Why" column with brief reasons per seat.
What it stops: When any model is updated, renamed, or replaced, the table becomes false. An agent reading "DeepSeek V4.1 Flash" will look for that exact model. The table has no version date, no "current as of" line, and no instruction for who updates it. HANDOFF.md already shows the Board seat changing from Fable 5.2 to Opus (R169), but the AGENTS.md table still says Fable 5.2 in the parenthetical.
Disposition: REWORD TO ITS PURPOSE. Replace model names with role descriptions: "Board thread (current model named in LOOP.md)," "Workhorse (current model named in LOOP.md)," and so on. LOOP.md already tracks live state. The table should point there. Not Ryan's call; the Board can restructure.

A12. "Kimi is off except a real job both DeepSeek models fail (R132, R134)."
Where: AGENTS.md, seat table, "Hard or open-ended multi-file coding" row, parenthetical.
Who set it: Cited as R132 and R134. The rulings are not in the attached files, so the full context is not available here.
Reason recorded: The parenthetical says: "it was slower and 50x the price per job on the API."
What it stops: This is a very specific operational instruction embedded in a parenthetical inside a table cell. An agent that does not parse the parenthetical will miss it. An agent that does parse it must judge what "a real job both DeepSeek models fail" means. There is no definition of "fail" here (crash? wrong output? too slow?). The rule will outlive the specific cost comparison it was based on.
Disposition: REWORD TO ITS PURPOSE. Move it out of the parenthetical and into a plain sentence below the table: "Kimi is not used unless the Board assigns it a specific job that both DeepSeek models could not complete. The Board makes that call." Not Ryan's call as written; the Board can reword.

A13. "Sound stays as is, Sonniss clips included."
Where: src_go-forward-plan.md, section 1 ("What is decided"), under Ryan's Oct 24 answers.
Who set it: Ryan. The plan records it under "Ryan decided (Oct 24 answers)."
Reason recorded: None beyond the ruling itself.
What it stops: HANDOFF.md (Nov 10) records active sound work: "Sound: sources and palettes studied... the listening page for Ryan is still to build." The plan's "stays as is" reads as a prohibition on sound work, but the current status shows sound work happening. An agent reading the plan will think sound is closed. An agent reading HANDOFF.md will think sound is open. The plan's ruling has no sunset or "as of" date.
Disposition: REWORD TO ITS PURPOSE. Replace with: "Sound: the existing Sonniss clips stay in the game. New sound work follows the current plan and playbooks." This is Ryan's own call, so the rewording needs his confirmation.

A14. REVIEW_PROTOCOL tells outside agents to open files at a specific GitHub raw URL pattern.
Where: REVIEW_PROTOCOL.md, section 1 ("Prove you read it"): "Open files in raw view: https://github.com/rcbailey12/voidsworn/raw/main/<path>."
Who set it: Not recorded. The protocol is presented as standing rules.
Reason recorded: The document says: "Not the normal GitHub page (it folds long lines and loads in chunks)."
What it stops: The instruction assumes the agent is browsing GitHub in a web browser. Agents that work from local clones, from attached files (as this leg does), or from the Godot project tree cannot follow this instruction literally. The underlying purpose is "read the real file, not a rendered view," but the rule is written as a specific URL pattern. An agent that cannot open that URL might stop and report it cannot proceed.
Disposition: REWORD TO ITS PURPOSE. Replace with: "Read the file's full content, not a rendered or folded view. If you are browsing GitHub, use the raw view. If you have a local clone or attached files, read those. Record the commit hash you reviewed." Not Ryan's call; the Board can update the protocol.

A15. "Argon is blocked since Nov 5" is written into the title of the rules file.
Where: AGENTS.md, document title: "Voidsworn: rules for any AI agent (Claude or another model; Argon is blocked since Nov 5)."
Who set it: The block date is recorded. The document does not say who issued the block.
Reason recorded: None in the attached files.
What it stops: A personnel decision sits in the title of the file every agent reads first. It reads as a permanent structural fact, not a revocable decision. If the block is lifted, an agent would need to remember that the title is outdated. Titles are the last thing anyone thinks to update. It also primes every reader to treat Argon as an adversary before reading any rules.
Disposition: REWORD TO ITS PURPOSE. Remove the block from the title. Put it in the seat table or in LOOP.md where live status belongs: "Argon: blocked since Nov 5. Review date: [date or condition]." Not Ryan's call as written; the Board can move it.

Part B: Contradictions and duplicates

B1. Blob sweep verdict: pass/fail versus no pass bar.
Source 1: src_BLOB_SWEEP.md, section 1: "Each cell gets a verdict: clean or rebuild by hand, with the part named."
Source 2: AGENTS.md, "Ship models" section: "The sweep is a viewing instrument for Ryan's eye, with no clean-or-rebuild pass bar (R121)."
A newcomer reading BLOB_SWEEP first (it is the dedicated document) would enforce a pass/fail gate. A newcomer reading AGENTS.md first would treat the sweep as advisory. The documents give opposite instructions on the same question.

B2. Phone pipeline steps versus PC-only ruling.
Source 1: src_README.md, steps: "Phone LOD: lod_make.py (collapse decimate that keeps UVs) to 250k triangles." Also: "desktop about 11-14 MB... phone about 3.5 MB at 250k."
Source 2: AGENTS.md, "Owner rulings and lore": "Owner rulings of Oct 24 that override older docs: PC-only."
Also src_BLOB_SWEEP.md, section 5: "Shots on desktop and phone."
A newcomer reading the README would build phone assets. A newcomer reading AGENTS.md would skip them. The README has no note pointing to the PC-only ruling.

B3. The .vsm format: current pipeline versus frozen-browser artifact.
Source 1: src_README.md, steps: "node vsm_pack.mjs dir CODE packs the hull with meshoptimizer into CODE.vsm."
Source 2: AGENTS.md, "Ship models": "the meshoptimizer .vsm format belongs to the frozen browser game, not the Godot product."
A newcomer reading the README would produce .vsm files. A newcomer reading AGENTS.md would produce glb files. The README does not mention the Godot export path.

B4. Babylon rendering work: conditional hold versus engine decided.
Source 1: src_go-forward-plan.md, section 2: "Until the engine call, no new Babylon-only rendering work."
Source 2: src_go-forward-plan.md, phase table: "A3 Engine call: DONE Oct 26: GODOT (R32)."
The same document contains both the conditional prohibition and the record that the condition is resolved. A newcomer reading section 2 without the phase table would still treat the prohibition as live.

B5. "Free tools only" stated three ways.
Source 1: AGENTS.md, "Ship models": "Free tools only."
Source 2: src_README.md, header: "Free tools only."
Source 3: src_go-forward-plan.md, section 7: "Paid assets of any kind" (under "Out of scope").
All three say the same thing, but the plan's section 3 then lists licence-by-licence exceptions ("FLUX dev avoided (licence)," "Quaternius: licence is QAL, not CC0"). A newcomer reading only the bare rule gets no guidance on licence edge cases. A newcomer reading the plan's section 3 gets a different, more nuanced picture.

B6. Sound: closed versus open.
Source 1: src_go-forward-plan.md, section 1: "Sound stays as is, Sonniss clips included."
Source 2: HANDOFF.md, section 0: "Sound: sources and palettes studied... the listening page for Ryan is still to build."
A newcomer reading the plan would think sound is finished and closed. A newcomer reading HANDOFF.md would think sound work is active. The plan's ruling has no date-based sunset.

B7. Placement rules duplicated across two files with minor wording differences.
Source 1: src_BLOB_SWEEP.md, section 3: "Snapped onto the real hull surface: never floating, never sunk. On a visible mount: plate, ball, saddle or column."
Source 2: AGENTS.md, "Ship models": "snapped onto the real hull, on visible mounts; guns aimed forward or out to the side, never backward."
The content is the same. The wording differs slightly. If one is updated and the other is not, they will drift. A newcomer reading BLOB_SWEEP gets the list "plate, ball, saddle or column." A newcomer reading AGENTS.md does not. Neither document says which copy is authoritative.

B8. The "no em dashes" rule appears in at least three attached files.
Source 1: AGENTS.md, "Owner preferences": "no em dashes."
Source 2: src_go-forward-plan.md, section 10: "No em dashes anywhere (grep -c must be 0)."
Source 3: PACK_QWEN.md, house rules: "No em dashes anywhere in your text."
The rule is the same in all three. The risk is low here, but the duplication means three places to update if the rule ever changes, and the enforcement mechanism ("grep -c must be 0") appears only in the plan.

Part C: Stale documents

PACK_QWEN.md: Current. It is the instruction pack for this task (issue 495). It is purpose-built and will be superseded when the issue closes, but it is not stale now.
AGENTS.md: Current, with stale patches. The document is the live rules file, updated Nov 8 2026. Its structure and most rules are current. However, it contains stale specifics: the seat table model names (A11), the Kimi parenthetical (A12), the Argon block in the title (A15), and the Codex cloud claim (A6). These are patches layered on a current document. The document itself should not be archived, but those patches need updating.
CLAUDE.md: Current. It is a short pointer file, updated Nov 8 2026. It says: "All the rules for AI agents now live in AGENTS.md." It adds only Claude-specific notes. It does its job and is not stale.
HANDOFF.md: Current. Dated Nov 10, 2026. It is the live status document. Section 0 is the entry point. It will be superseded by the next update, but it is not stale now.
REVIEW_PROTOCOL.md: Partly stale. The review structure (table format, evidence rules, OBSERVED/INFERRED tags) is current and useful. The raw-URL instruction (A14) is stale: it assumes GitHub web browsing, which is not how most agents now work. The "Save it as contrib/<your-name>/reviews/" instruction is current. The file should stay live but needs the URL instruction updated.
src_README.md: Partly stale. The core pipeline steps (concept to views to mesh to paint to kit to detail to game) are still the working method. But the phone LOD step, the .vsm packing step, and the Babylon-specific gotchas are stale. The document describes one pipeline (browser-era) when the project now has two (frozen browser oracle and active Godot product). It should stay live but needs a Godot section and clear markers on which steps are browser-only history. It should not be archived yet because the Blender and ComfyUI steps are still current.
src_BLOB_SWEEP.md: Partly stale. The nine-cell grid concept is current and referenced by AGENTS.md. The "clean or rebuild" verdict language is contradicted by R121 (A1). The phone reference in section 5 is dead (A2). The "Rebuilt by default" list (section 2) and the "Space, not naval" section (3b) are current. The paint and detail sections (4, 4b) are current. The document should stay live but needs the verdict language and phone reference removed.
src_go-forward-plan.md: Partly stale, approaching history. Phases A0, B0, A1, A2, A3, G1 are all marked DONE. B1 is IN PROGRESS. B2 is BUILT. The engine call is resolved. The "Until the engine call" conditional is dead. The Babylon-specific pipeline notes are history. However, phases B3, B4, B5, G2 through G5, A4, A5, and the travel sprint are still live. The document is too large to archive whole, but its completed phases and Babylon-era instructions should be moved to an archive section or a separate history file, leaving the live phases in place. The plan's section 1 ("What is decided") is still the authoritative record of Ryan's Oct 24 calls and should stay current.

Part D: Rules that should exist and do not

D1. Contradiction resolution order. No document says which file wins when two attached documents disagree. BLOB_SWEEP says one thing; AGENTS.md says the opposite. The README describes .vsm; AGENTS.md says glb. An agent must guess. Rule I would write: "When two documents state the same matter differently, AGENTS.md wins over pipeline documents, and HANDOFF.md wins over both for current status. If the conflict is between two rulings of Ryan's, the later date wins and the Board records the resolution in FINDINGS."
D2. Sunset conditions for technical claims. Rules like "Codex cloud runs an older model" or "the official Blender server needs 5.1" are true today and false tomorrow. No document says who checks, when, or how the rule gets lifted. Rule I would write: "Any rule that rests on a technical fact (a model version, a tool limitation, a platform constraint) must name the condition that ends it. The Board reviews these conditions at each phase transition."
D3. How playbooks supersede older documents. HANDOFF.md points agents to docs/playbooks/ as the per-area recipes. But the older documents (go-forward-plan, README, BLOB_SWEEP) still carry instructions that may conflict with the playbooks. No document says the playbooks override them. Rule I would write: "Where a playbook and an older document disagree on method, the playbook wins. The older document's section should be marked 'superseded by [playbook name]' at the next edit."
D4. What "frozen" means for the browser game in practice. AGENTS.md says the browser game is "frozen except for rules fixes." No document defines what counts as a rules fix versus a change. Can an agent fix a typo in a data.js comment? Can it fix a rendering bug that affects the rules oracle's accuracy? Rule I would write: "The browser game is frozen. Permitted changes: bug fixes that affect rules correctness, and fixes that keep the headless sim running. Everything else, including rendering, UI polish, and new features, is off limits. The Board rules on edge cases."
D5. How an outside agent should handle a document that references a missing tool or file. Several documents reference tools (render_multi.py, project_paint.py, lod_make.py) and files (SHIP_QUEUE.md, FINDINGS.md, LOOP.md) that are not attached and may not be accessible to an outside agent. No document says what to do when a reference cannot be followed. Rule I would write: "If a document references a file or tool you cannot access, note the reference, state what you could not verify, and continue with what you have. Do not invent the missing content."
D6. Update ownership for duplicated rules. The placement rules, the free-tools rule, and the no-em-dashes rule each appear in multiple files. No document says which file owns the canonical copy or who updates the others when one changes. Rule I would write: "Each rule has one canonical home, listed in AGENTS.md. Other files may point to it but must not restate it in different words. When the canonical copy changes, the Board updates or removes the pointers."

Part E: How the Board writes rules

Six patterns in these documents that produce bare prohibitions, stale copies, or literal obedience to dead text.

E1. Conditional rules left in place after the condition resolves.
The go-forward plan says: "Until the engine call, no new Babylon-only rendering work." The engine call is done. The sentence remains. The pattern is: a holding rule tied to a future event is never revisited after the event passes. The "until" clause becomes a permanent prohibition because nobody deletes it.
E2. Rulings embedded in parentheticals that silently change the rule they sit inside.
AGENTS.md says: "with no clean-or-rebuild pass bar (R121)." This parenthetical overrides BLOB_SWEEP's core instruction, but it appears only in AGENTS.md, not in BLOB_SWEEP itself. The pattern is: a ruling changes a document's meaning, but the change is recorded in a different document, in a parenthetical, without updating the original. The original keeps instructing the old behaviour.
E3. One-time owner instructions fossilised as standing rules.
BLOB_SWEEP opens with: "Owner (Ryan, Oct 21 2026): 'ensure we catch all of those for all other ships.'" This was a reaction to specific problems on one ship. It became the title-level authority for a permanent document. The pattern is: a spoken instruction given in context is quoted verbatim and used as the founding rationale for a rule that outlives the context.
E4. Specific model names, versions, and prices written into rules text.
The seat table names: "Fable 5.2," "Opus 5.5 worker threads," "DeepSeek V4.1 Flash." The Kimi entry says: "it was slower and 50x the price per job on the API." The pattern is: operational details that change monthly are written into a rules file that changes rarely. The file becomes false within weeks, but reads as authoritative because it is the rules file.
E5. The same rule copied into multiple files with slight wording drift.
"Free tools only" appears in AGENTS.md, src_README.md, and the go-forward plan. The placement rules appear in BLOB_SWEEP and AGENTS.md. The no-em-dashes rule appears in at least three files. The pattern is: a rule is restated wherever it seems relevant, without a canonical source. Each copy drifts slightly. No copy says "see [other file] for the authoritative version."
E6. Prohibitions stated without reasons, so agents obey the letter past its purpose.
"Never push to main (R75)." No reason given. "Guns aimed forward or out to the side, never backward." The reason (no ship in the game fires backward) is stated, but for many other rules it is not. "No Codex cloud tasks or cloud reviews." The reason is embedded but not separated. The pattern is: a rule is written as a bare "never" or "no" with no stated purpose. When the purpose expires or the context changes, the prohibition remains, and agents follow the letter because they have no reason to test whether the spirit still applies.

Leg filed. Qwen, WRITER seat, issue 495.
