# Stale-claim audit of the entry docs (issue #257, #216 asks 1 and 4)

Auditor: Rey (chair). Legs: blind Rey (written first, from the full sources), DeepSeek (two runs: the first pack-limited, the second on full texts of AGENTS.md, CLAUDE.md, BACKLOG.md), Qwen (two runs: the first pack-limited, the second on full texts of NEXT.md and HANDOFF.md plus a LOOP.md excerpt; its second run returned two responses, both used, neither chosen between). Argon seat empty (blocked since Nov 5). Date: Nov 8, 2026. Snapshot: the docs as fetched at about 14:13 CST today; HANDOFF.md and FINDINGS.md are live files and may have moved since.

Method and scoping. FINDINGS.md wins over every entry doc; LOOP.md is the record for live seats and board state; where FINDINGS rows conflict with each other, the later row wins. Every UNAMBIGUOUS item below gives the doc location, a short exact quote, the winning source it conflicts with, and a proposed one-line fix Opus can apply without a decision. Flag status matters and is noted per item: a stale claim in text a doc presents as current can mislead a new reader today; a stale claim inside a section the same doc explicitly flags as history is listed only where the flag does not protect the reader (an unflagged block, a starter line, a section whose flag does not reach the correction). The remaining flagged-history bulk is handled by the section-level choices in NEEDS RYAN, not line by line.

Process note, recorded for the board: the first DeepSeek and Qwen runs received a pack that carried excerpts and the FINDINGS index but not the six docs in full. Both legs declined to invent line citations and audited only what they could see. The chair rebuilt the packs with full texts embedded and re-ran both legs per doc set. The blind Rey leg read the full sources from the start and is the spine of this report; its citations were spot-verified by the chair against the saved sources (HANDOFF.md:7, :9, :11; AGENTS.md:32, :43; PROGRESS.md:2, :473; FINDINGS R121, R132, R134, D3 all confirmed verbatim). Corroboration is marked where a second leg found the same item independently.

Headline counts: 48 UNAMBIGUOUS items, 5 NEEDS RYAN questions. The single most dangerous pattern is not the Babylon history (that is flagged) but current-facing text overtaken by today's own rulings: HANDOFF.md section 0 still describes the #120 head-to-head as running hours after R134 decided it, and AGENTS.md's seat map still offers Kimi a seat on a condition R134 has already settled the other way.

## UNAMBIGUOUS

### AGENTS.md

**A1. AGENTS.md:1** Quote: "rules for any AI agent (Claude, Argon, or another model)". Claim: Argon is a current agent this file speaks for. Conflicts with: LOOP.md:20 (council seats end "Argon blocked since Nov 5"). Fix: drop Argon from the title or mark it blocked since Nov 5.

**A2. AGENTS.md:32** Quote: "Rey writes a blind leg first, DeepSeek and Qwen write, Argon reviews only, Rey chairs". Claim: the standing Models line seats Argon as reviewer and omits the Flash and Grok seats. Conflicts with: LOOP.md:20 (seats are Rey, DeepSeek, Qwen, Flash ideation only, Grok; Argon blocked since Nov 5). Corroborated: DeepSeek run 2 (cited at :33 in its embedded copy). Fix: rewrite the Models line as: Rey writes a blind leg first, DeepSeek and Qwen write, Flash and Grok ideation only, Rey chairs; Argon blocked since Nov 5.

**A3. AGENTS.md:43** Quote: "Kimi K3.1 Pro in the same runner, if it wins the #120 head-to-head". Claim: the seat map still offers Kimi the hard-coding seat on a decided condition. Conflicts with: FINDINGS R134 (FINDINGS.md:162, Flash beats V4 Pro and Kimi on #120; Kimi stays off) and R132 (FINDINGS.md:160, Opus threads take the hardest jobs; Kimi only for a real job both DeepSeek models fail). Corroborated: DeepSeek run 2. Fix: replace the row's seat with Opus threads, and note Kimi is off except a real job both DeepSeek models fail (R132).

**A4. AGENTS.md:44** Quote: "Codex on the PC (when ChatGPT is back); until then Opus PC threads". Claim: Codex returns when ChatGPT returns. Conflicts with: LOOP.md:18 ("Codex: DOWN until Ryan says") and FINDINGS R112 (FINDINGS.md:140, ChatGPT down to about Nov 10 and Codex down until Ryan says, as two separate states). Fix: change the parenthesis to "(when Ryan un-parks Codex)".

**A5. AGENTS.md:16** Quote: "Agents deliver by pushing a branch named codex/issue-<number> or muse/issue-<number>. Never push to main." Claim: only two branch shapes exist and nothing goes straight to main. Conflicts with: FINDINGS R102 (FINDINGS.md:130, LOOP.md and FINDINGS are committed straight to main as a docs-only exception) and LOOP.md:121 (work/issue-N and work/issue-N-arm branches also auto-open PRs; opus/ branches are the board's own pattern). Fix: add the work/ and opus/ branch shapes and the LOOP.md plus FINDINGS docs-only exception to the rule.

**A6. AGENTS.md:19-20** Quote: "checks the board every 10 minutes and queues each new codex issue on lane B". Claim: the Codex watcher flow is the live delivery route, with no down state and no keep-blocked rule. Conflicts with: LOOP.md:18 (Codex down until Ryan says; watcher runs on unblocked codex issues die on the usage limit; keep every codex issue blocked). Corroborated: DeepSeek run 2. Fix: add one sentence: Codex is down until Ryan says, so every codex issue stays blocked and the watcher queue is inert.

**A7. AGENTS.md:53** Quote: "Do not edit files outside it: no game source, no tools, no docs". Claim: every outside agent may only work inside contrib/<agent>/ and propose changes as copied files. Conflicts with: FINDINGS R81 (FINDINGS.md:109, Muse may deliver low-code fixes in text, data, tests, tools and docs as PRs, not only research). Fix: add the R81 exception for Muse low-code fix PRs; keep the copy-in-folder rule for the other outside agents.

**A8. AGENTS.md:64** Quote: "The hand-built parts script is tools/blender/hs/c19_kit.py". Claim: c19_kit.py is the live hand-built parts script for the Pyre-Barge worked example. Conflicts with: FINDINGS D3 (FINDINGS.md:264, c19_kit.py "keeps the naval parts as history and is not the live kit path"; the live build is tools/blender/a1/barge_v15.py). Fix: point the worked example at the live a1 builder and mark c19_kit.py as history.

**A9. AGENTS.md:72** Quote: "full detail is compressed (meshoptimizer .vsm), not decimated, on desktop". Claim: the current ship pipeline ships hulls as meshoptimizer .vsm files. Conflicts with: FINDINGS R32 and R33 (FINDINGS.md:57-58, the product is the Godot 4 port, the browser build is frozen) and G-9 and G-11 (FINDINGS.md:176, 180, Godot ship exports are glb copied into the PC build). Fix: describe the Godot glb asset path as current and mark the .vsm format as the frozen browser game's.

### CLAUDE.md

**A10. CLAUDE.md:19** Quote: "tools/blender/hs/c19_kit.py is the worked example". Same conflict as A8 (FINDINGS D3). Fix: name the live a1 builder as the worked example and mark c19_kit.py as history.

**A11. CLAUDE.md:22** Quote: "Every cell gets a verdict: clean, or rebuild by hand". Claim: the nine-cell sweep is a mandatory pass bar with rebuild verdicts. Conflicts with: FINDINGS R121 (FINDINGS.md:149, the 7 of 9 and 9 of 9 nine-cell bars are removed; the sweep survives as a viewing instrument for Ryan's eye), superseding R105. Fix: reword the sweep as a viewing instrument for Ryan's eye, with no clean-or-rebuild pass bar.

**A12. CLAUDE.md:31** Quote: "the old 0.3 paint self-light now defaults to 0 (ships3d.js:790)". Claim: the pipeline gotchas are current working knowledge, stated in the frozen browser build's files with no frozen note. Conflicts with: FINDINGS R32 and R33 (FINDINGS.md:57-58). Fix: head the gotchas as browser-oracle history, or move them behind the plan and FINDINGS pointers CLAUDE.md already gives at its top.

DeepSeek run 2 checked CLAUDE.md's owner rulings and PC statements against R1 to R4, R59, R98, R99 and R111 and found no other conflicts; its clean read is recorded here so the coverage is explicit.

### HANDOFF.md, section 0 (current, unflagged; the text every new session reads first)

**A13. HANDOFF.md:7** Quote: "DeepSeek V4 Pro is running #120 now as the last contender (started 12:05 CST)". Claim: the V4 Pro arm is still running. Conflicts with: FINDINGS R134 (FINDINGS.md:162, Nov 8: the head-to-head is decided, Flash wins, PR #255 closed) and LOOP.md:35 ("#120 head-to-head done (R134)"). Corroborated: Qwen run 2, both responses. Fix: state the result: Flash won #120, the Pro arm is closed, Pro is a second try only on a job Flash fails.

**A14. HANDOFF.md:11** Quote: "PR #248 (Flash, plus the board's two fixes) held until the V4 Pro arm lands". Claim: #248 waits on the V4 Pro arm. Conflicts with: FINDINGS R134 (FINDINGS.md:162, "#248 merges after Muse's outside check (#256, R132)") and LOOP.md:35. Corroborated: Qwen run 2, both responses. Fix: change the hold reason to the #256 outside check. (Chair note: that check has since been delivered as PR #261; the board's merge of #248 is the remaining step.)

**A15. HANDOFF.md:9 and :11** Quotes: "#246 Heat back-fill filed" and "Then: #121 and #122, #246, the self-check list in the runner's task file". Claims: #246 is freshly filed and still in the open queue, and the self-check list is still to be added to the runner. Conflicts with: LOOP.md:35 ("#246 merged (PR #254, Flash)") and LOOP.md:12 with PR #253 (the R129 self-check list is already carried by every workhorse task). Corroborated: Qwen run 2, both responses. Fix: move #246 to Done as merged in PR #254, drop it from Open now, and state the self-check list as landed (PR #253).

**A16. HANDOFF.md:1** Quote: "handoff (updated Nov 7, 2026, 23:10 CST)". Claim: the file was last updated Nov 7, while its own section 0 is dated Nov 8, 2026, 12:10 CST (internal conflict). Fix: update the title date to Nov 8, 2026, 12:10 CST.

### HANDOFF.md, section 0a (flagged "superseded by section 0 where they differ")

**A17. HANDOFF.md:19** Quotes: "The #217 workhorse (OpenCode on the PC, Kimi primary, DeepSeek second)" and "it waits on Ryan's top-ups, then WORKHORSE_SETUP.bat and WORKHORSE_TRIAL.bat". Claim: Kimi is the primary workhorse seat and the trial still waits on top-ups. Conflicts with: FINDINGS R127 (FINDINGS.md:155, the trial ran; DeepSeek is the primary coding seat) and R134. Corroborated: Qwen run 2 response 2. Flag status: inside flagged section 0a. Fix: mark both clauses as the pre-trial state, or cut them now that section 0 carries the outcome.

### HANDOFF.md, section 0b (flagged "superseded by section 0 where they differ")

**A18. HANDOFF.md:35** Quote: "The hourly 'Voidsworn board loop' scheduled task (trig_01AYQAMdwD6BZHsizYS6EZdE) stays disabled". Claim: the hourly task is disabled but exists, to be revisited once things are steady. Conflicts with: LOOP.md:5 (the task is DELETED, Ryan, Nov 7 22:06 CST) and FINDINGS R119 (FINDINGS.md:147, the Board thread in the Claude Code Project owns the board). Corroborated: Qwen run 2, both responses. Flag status: inside flagged section 0b; note section 0 is silent on the task, so the flag's "superseded by section 0" does not actually reach this correction. Fix: replace "stays disabled; revisit once steady" with "deleted Nov 7 (R114); the Board thread owns the board (R119)".

**A19. HANDOFF.md:38** Quote: "Use Sonnet subagents for routine coding, log reading and capture jobs (R102)". Claim: Sonnet subagents do routine coding. Conflicts with: FINDINGS R132 (FINDINGS.md:160, no Opus sub-agents for coding; a coding job gets its own thread; Sonnet for mechanical work only). Flag status: inside flagged section 0b. Fix: change to Sonnet subagents for mechanical work only, never coding.

**A20. HANDOFF.md:45** Quote: "Muse PRs to review: #203 (#200 close-range surface detail standard)". Claim: PRs #203, #204 and #205 still wait for review. Conflicts with: FINDINGS R110 (FINDINGS.md:138, PRs #203 to #205 reviewed by diff, retitled and merged on Nov 7). Flag status: inside flagged section 0b. Fix: delete the item or move it to a done list.

**A21. HANDOFF.md:46** Quote: "V3 gets mounted detail back up to the R96 ceiling plus the reference's outline features". Claim: #198 round 7 works to the R96 triangle ceiling. Conflicts with: FINDINGS R111 (FINDINGS.md:139, the R96 ceiling is retired; costs are reported, never capped) and LOOP.md Holds (#198 re-specced, blocked until a coding seat is live). Flag status: inside flagged section 0b. Fix: rewrite the item in the re-specced form: costs reported, no ceiling, blocked until a coding seat is live, held for Ryan's round 7 pick.

**A22. HANDOFF.md:47** Quote: "#197 is merged as the base paint. Hold for Ryan's look." Claim: the same item says #199 will use the #200 standard "once merged", as if #200 were still open. Conflicts with: FINDINGS R110 (FINDINGS.md:138, PR #203 merged #200 on Nov 7; the standard binds hull and station detail work). Flag status: inside flagged section 0b. Fix: state that the #200 standard is merged and binding, and that #199 is re-specced under R113 and blocked with #198.

**A23. HANDOFF.md:49** Quote: "Parked: #193 (Tripo test; paid cloud service, needs Ryan's call; house rule is free and local only)". Claim: the Tripo evaluation still needs Ryan's call. Conflicts with: FINDINGS R110 (FINDINGS.md:138, Ryan granted the paid-service exception for the #193 evaluation only, Nov 7) and LOOP.md Holds (local first; Tripo only if the local routes leave the question open). Flag status: inside flagged section 0b. Fix: replace "needs Ryan's call" with the granted exception and the local-first order.

### HANDOFF.md, the Nov 1 block (dated header only, no superseded note)

**A24. HANDOFF.md:58** Quote: "the job board is run by one hourly scheduled task, 'Voidsworn board loop'". Claim: an hourly scheduled task runs the board and is its only owner. Conflicts with: LOOP.md:5 (DELETED) and FINDINGS R119 (FINDINGS.md:147). Corroborated: Qwen run 2, both responses. Flag status: no superseded flag on this block, so a reader who stops here takes it as current. Fix: add a superseded note to the block header pointing at section 0 and LOOP.md, or correct the sentence in place.

**A25. HANDOFF.md:60** Quote: "Claude is the orchestrator and final reviewer only. Coding, tests and read-heavy reports go to Codex". Claim: Claude does not code and Codex does the coding. Conflicts with: LOOP.md:18 (Codex down until Ryan says) and FINDINGS R132 (FINDINGS.md:160, Opus takes the hard coding jobs itself until Codex is back). Corroborated: Qwen run 2, both responses. Flag status: no superseded flag on this block. Fix: add the same superseded note, or rewrite the seat sentences to the R132 shape.

**A26. HANDOFF.md:66** Quote: "Exe e991dc6 is on Ryan's PC; a rebuild with the layout fix is in progress". Claim: e991dc6 is the current playtest exe. Conflicts with: LOOP.md:48 ("Latest playtest exe: g2_pt_d03ac22"). Corroborated: Qwen run 2 response 2. Flag status: no superseded flag on this block. Fix: update the exe id to g2_pt_d03ac22 or date-stamp the sentence as the Nov 1 build.

Also in this block, per Qwen run 2 response 1: the owner-label list at about :63 omits the ryan label that FINDINGS R75 (FINDINGS.md:103) includes. The A24 superseded note covers the block; the one-line fix is to add ryan to the list.

### HANDOFF.md, sections 1 to 6 (flagged as history at HANDOFF.md:131)

**A27. HANDOFF.md:133** Quote: "Voidsworn: Fleet Tactics, a Babylon.js 8.20 single-HTML hex fleet-tactics roguelite". This is the issue's known first catch. Claim: the game is a Babylon.js 8.20 single-HTML build. Conflicts with: FINDINGS R32 (FINDINGS.md:57, Godot 4.7), R33 (browser frozen), R22 (FINDINGS.md:47, even the Babylon test half moved to 9.30.0, so the history is inaccurate on its own terms) and R59 (FINDINGS.md:86, the game is Embers of the Hollow Sun). Flag status: inside the sections flagged at :131, which warns the Babylon details are stale; a careful reader is warned. Corroborated: every leg. Location correction to the issue block: the catch is not in AGENTS.md (its opening at :3-5 is already correct) but here. Fix: replace the sentence with the Godot 4 port and rules-oracle wording AGENTS.md:3-5 already uses.

**A28. HANDOFF.md:137** Quote: "Work goes straight to main." Claim: work is pushed directly to main. Conflicts with: FINDINGS R75 (FINDINGS.md:103, outside agents deliver PRs Opus reviews and merges), exception R102. Flag status: inside flagged sections 1 to 6. Fix: replace with the branch and PR delivery rule from AGENTS.md.

**A29. HANDOFF.md:135** Quote: "Live game (one link only)" and "Publish voidsworn-3d.html from python3 build.py publish". Claim: the browser artifact is the live game and publishing it is the release path. Conflicts with: FINDINGS R33 (FINDINGS.md:58). Flag status: inside flagged sections 1 to 6. Fix: relabel the link as the frozen rules oracle and drop the publish instruction.

**A30. HANDOFF.md:158** Quote: "A3 DECIDED with a proof running (R28). A4, A5 and B3 to B5 not started." Claim: the Godot proof is still running and later phases have not started. Conflicts with: FINDINGS R32 (FINDINGS.md:57, A3 decided, proofs passed) and G-14 (FINDINGS.md:91, sprint close-out Nov 1: 36 hulls repainted, portraits built, parity 48 of 48). Flag status: inside flagged sections 1 to 6. Fix: mark the phase list as the Oct 26 snapshot it is, with A3 decided at R32.

**A31. HANDOFF.md:192** Quote: "a 12 s target and 15 s limit per round". Claim: listed among decisions still standing. Conflicts with: FINDINGS R64 (FINDINGS.md:92, Nov 1: both numbers retired). The earlier F4 decision set the same numbers on Oct 25; the later row wins. Flag status: inside flagged sections 1 to 6. Fix: strike the line or annotate it retired by R64.

**A32. HANDOFF.md:206** Quote: "the proof results (side-by-side effects sheets plus parity PASS or FAIL), then the final switch". Claim: Ryan's next weigh-in is the engine proof and the final switch. Conflicts with: FINDINGS R32 (FINDINGS.md:57, decided Oct 26 on those results). Flag status: inside flagged sections 1 to 6. Fix: mark section 4's weigh-in list as answered by R32 and R59.

**A33. HANDOFF.md:166-167** Quote: "run each helper's milestone on the PC when it reports". Claim: section 5's next tasks run the G1 and G2 helpers toward a first Godot battle. Conflicts with: FINDINGS G-14 (FINDINGS.md:91, the sprint closed out with the full Godot game built and parity proven). Flag status: inside flagged sections 1 to 6. Fix: mark section 5 as completed history.

**A34. HANDOFF.md:277** Quote (the starter line): "Read HANDOFF.md section 0 … then FINDINGS R64 to R75" and "send coding to Codex on my PC". Claim: a new session starts from FINDINGS R64 to R75 and sends coding to Codex. Conflicts with: FINDINGS now runs to R134, and R132 plus LOOP.md:11-12 put coding with the Flash workhorse and Opus, Codex down. Flag status: the starter line sits after the section body and reads as live instruction to anyone copying it. Corroborated: Qwen run 2, both responses. Fix: update the range to the current registry and replace the Codex instruction with the R132 seat shape, or delete the starter line.

### NEXT.md (file-level banner declares it superseded)

**A35. NEXT.md:3** Quote (the file's own banner): "The build queue is now docs/archive/go-forward-plan.md". Claim: the banner retires this file by pointing at a plan file that is itself no longer the live queue. Conflicts with: LOOP.md (the live queue) and FINDINGS R35 (FINDINGS.md:60). Source: Qwen run 2 response 2. Fix: repoint the banner at contrib/opus/LOOP.md as the live queue, this file as historical reference only.

**A36. NEXT.md:9** Quote: "one battle on the Pixel for anything visual". Claim: the publish gate still includes a battle on the Pixel. Conflicts with: the Oct 24 PC-only rulings (CLAUDE.md:7) and FINDINGS D7 (FINDINGS.md:268, phone framing STALE). Flag status: NEXT.md's banner says the phone and Pixel gates below are retired; the line still sits in the operative gate sentence. Corroborated in substance: Qwen run 2 response 2. Fix: delete the Pixel clause from the gate line.

**A37. NEXT.md:95** Quote: "After v55, revisit the engine (owner agreed to circle back): port to Godot 4". Claim: the engine question reopens after v55, with phone frame rate as a trigger. Conflicts with: FINDINGS R32 (FINDINGS.md:57) and BACKLOG.md:5 (its banner already carries the corrected form). Flag status: covered by NEXT.md's banner, but the item is not a phone or Pixel gate, so the banner does not cover it by its own terms; the file is also kept alive as an effects reference (see NR3). Corroborated: Qwen run 2, both responses. Fix: delete the parking-lot engine item, or append "RESOLVED: Godot 4.7, Oct 26 (R32)".

The rest of NEXT.md's stale lines (the v53 to v55 build queue, Pixel gates, TRELLIS-era ship notes, the effects brief's pre-rename wording) sit inside the file's own superseded banner and are not listed line by line; Qwen run 2 response 2 catalogues about 38 of them with fixes if Opus wants the full sweep. Whether the file should keep living for its effects brief is NR3.

### PROGRESS.md (no flag anywhere in the file)

**A38. PROGRESS.md:2** Quote: "Live artifact: https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH". Claim: the browser artifact is the live product, in the header a new reader sees first. Conflicts with: FINDINGS R32 and R33 (FINDINGS.md:57-58). Flag status: PROGRESS.md has no superseded or history banner; its last entry is v53.8 (Oct 21). Fix: change the header line to name the Godot build as the product and the artifact as the frozen rules oracle, with the banner proposed in NR2.

**A39. PROGRESS.md:473** Quote: "Repo backed up to github.com/rcbailey12/voidsworn (private)." Claim: the repo is private. Conflicts with: FINDINGS R10 (FINDINGS.md:35, the repo stays public) and D19 (FINDINGS.md:280, the "repo private" claim is WRONG; HANDOFF.md was fixed Oct 24, this file was not). Fix: change "(private)" to "(public)".

**A40. PROGRESS.md:1-2 and :30** Quotes: the header at lines 1 to 2, and "Travel week (no home PC): phone first" at line 30. Claim: taken as a whole the file presents a phone-first Babylon project as the current state: no banner, no entry after Oct 21, phone framing throughout. Conflicts with: the Oct 24 PC-only rulings, FINDINGS R32, R33 and D7. Flag status: unflagged; this is the only entry doc with no self-warning at all. Fix: add a top banner: history through Oct 21, 2026; superseded by the PC-only ruling (Oct 24) and the Godot move (R32); current state lives in HANDOFF.md section 0 and LOOP.md. The file's future is NR2.

### BACKLOG.md (file-level banner at BACKLOG.md:5)

**A41. BACKLOG.md:9** Quote: "the 15 unmade portraits (the game has no portrait screen yet)". Claim: no portraits or portrait screen exist and 15 portraits are unmade. Conflicts with: FINDINGS G-14 (FINDINGS.md:91, 7 admirals and 36 Nemesis portraits built) and S-1 (story and career step 1 in Godot, with the Career screen); BACKLOG.md:17 itself carries the later Hullbreaker portraits round 2 item. Fix: rewrite the item to the remaining portrait work and drop the no-portrait-screen claim.

**A42. BACKLOG.md:13** Quote: "Option C long career (contrib/muse/reviews/career_story.md)". Claim: the long career option is still a near-backlog item. Conflicts with: FINDINGS R37 (FINDINGS.md:62, Ryan agreed the muse picks on Oct 26: story and career start small; "skip the long career option"). Fix: delete the item, or mark it skipped per R37.

**A43. BACKLOG.md:14** Quote: "Installable app wrapper, unless Godot wins". Claim: an installable wrapper for the web build pends on the engine outcome. Conflicts with: FINDINGS R32 (FINDINGS.md:57, Godot won) read with R5 (FINDINGS.md:30, a downloadable app is fine if Godot wins); the Godot path ships a native Windows exe (G-14). Corroborated: DeepSeek run 2. Fix: close the item as moot under the Godot exe.

**A44. BACKLOG.md:36** Quote: "Publish a test build for the Pixel and PC (live artifact)". Claim: a Pixel test build is an open task. Conflicts with: the file's own banner at :5 ("Phone and Pixel items are retired (PC-only)") and FINDINGS R33. Corroborated: DeepSeek run 2. Fix: delete the Pixel half; a PC test build is already the playtest exe flow in LOOP.md.

**A45. BACKLOG.md:51** Quote (DeepSeek run 2): "Gold selection ring too bright at close zoom on the Pixel". Claim: a Pixel visual defect is an open backlog item. Conflicts with: the :5 banner and FINDINGS R111 (FINDINGS.md:139, the measurement floor is Ryan's RTX 5080). Fix: retarget the item to PC and re-check on the RTX 5080 scene, or close it with the other retired Pixel items.

**A46. BACKLOG.md:74** Quote: "Performance on a real GPU and the Pixel: frame time per system, draw calls, texture memory, load time per battle, battery/heat". Claim: the whole-game health pass still includes Pixel performance and battery/heat. Conflicts with: the :5 banner and the PC-only rulings. Corroborated: DeepSeek run 2. Fix: drop "and the Pixel" and the battery/heat tail; PC performance is governed by the R116 scene gate (FINDINGS.md:144).

**A47. BACKLOG.md:80** Quote: "Engine: decided by the 6-ship Babylon vs Godot test before ship 2". Claim: stated as an open process item. Conflicts with: FINDINGS R32 (FINDINGS.md:57, the test ran and Godot won Oct 26). Corroborated: DeepSeek run 2 (which also flagged the :5 banner's process phrasing; the chair does not adopt that one, since the banner states the deciding test in past terms and BACKLOG.md:5 is the file's own correction of NEXT.md). Fix: mark the item done with the outcome: Godot 4.7 (R32).

**A48. BACKLOG.md:84** Quote: "Music style for the adaptive score." Claim: listed under Open questions for Ryan, as if the music style were still unpicked. Conflicts with: FINDINGS R37 (FINDINGS.md:62, music direction agreed Oct 26) and R40 (FINDINGS.md:65, free licensed tracks first). Minor. Fix: close the question or narrow it to the one part R37 left open, the specific track sourcing.

## NEEDS RYAN

Each item is a choice the winning sources do not settle. The Rey pick is marked on each, as the issue's Done when asks. (Qwen's first run framed the same five files as questions from metadata alone; where its pick differs from the pick below, that is noted.)

**NR1. HANDOFF.md's old text.** HANDOFF.md carries its Oct 26 to 27 record (sections 1 to 6) and the Nov 1 block in the file every agent reads first, and A24 to A26 plus A33 show the Nov 1 block misleads with no superseded note at all. What should happen to that old text?
A) Move sections 1 to 6 and the Nov 1 block into docs/archive, leaving section 0 plus a one-line pointer in HANDOFF.md. **(Rey pick)**
B) Keep everything in place and extend the line 131 history flag to a top-of-file banner covering the Nov 1 block too. (Qwen's first-run pick was this option, in its collapse-and-summarize variant.)
C) Delete sections 1 to 6 and the Nov 1 block outright; FINDINGS and the dated evidence files keep the record.

**NR2. PROGRESS.md's future.** It has no banner, ends Oct 21, and still calls the frozen browser artifact the live game (A38 to A40). What is it for, from here?
A) Add a superseded banner and freeze it as the pre-Godot history. **(Rey pick)**
B) Move it to docs/archive alongside the Oct 22 handoff.
C) Resume updating it as the progress log for the Godot era.

**NR3. NEXT.md's effects brief.** NEXT.md's banner keeps the file alive for one thing, the per-weapon effects brief, written for the Babylon effects pass. Does that brief still bind?
A) Retire NEXT.md entirely and move the per-weapon effects brief into the current effects work (the #232 stress pack and the FX stack under R122). **(Rey pick)**
B) Keep NEXT.md frozen with its banner, brief included, as the reference Opus consults.
C) Rewrite NEXT.md as a live queue again, duplicating the GitHub board in prose.

**NR4. The AGENTS.md and CLAUDE.md pair.** AGENTS.md:86 orders that CLAUDE.md hold the same rules and the two be kept in step, but they have already drifted: CLAUDE.md has no seat map, no R99 estimate rule and no post-Nov-2 board rules, while AGENTS.md has none of the ship-kit detail. How should the pair work?
A) Make CLAUDE.md a short file that points at AGENTS.md and keeps only Claude-specific notes. **(Rey pick)**
B) Keep both files full and re-sync them line by line in the #216 restructure.
C) Merge everything into AGENTS.md and delete CLAUDE.md.

**NR5. BACKLOG.md's role.** It mixes live items (the Nov 1 section 0a gaps) with dead plan-phase tags and answered questions (A41 to A48), while the GitHub board is now the queue of record (R75). What is BACKLOG.md for, from here?
A) Freeze it as the pre-board record with a banner; live work lives only in GitHub issues. **(Rey pick)**
B) Re-tag every open item against the current board and keep maintaining it. (Qwen's first-run pick, as a one-pass reconciliation.)
C) Delete it; anything still live gets filed as an issue first.

## Not checked

- Currency of docs outside the six: docs/ship_pipeline/TEXTURE_PASS.md (called "current" at AGENTS.md:11), docs/ship_pipeline/SHIP_QUEUE.md and its hull count, docs/REVIEW_PROTOCOL.md, docs/archive/go-forward-plan.md phase states, and contrib/opus/briefs/muse_standing_rule.md. None were in the pack, and FINDINGS and LOOP do not settle their current wording.
- PC facts in CLAUDE.md:15-17 (RTX 5080 16 GB, 32 GB RAM, disk space, ComfyUI portable version, Blender path). FINDINGS confirms only the RTX 5080 as the measurement floor (R111); the rest has no counterpart in the winning sources.
- Display-name details beyond what FINDINGS itself uses (for example "Hegemony Navy" at CLAUDE.md:13): the authority is the lore bible and rename map, which were not in the pack.
- HANDOFF.md:23 says the repo state audit sits on branch muse/repo-state-2026-11. Whether that branch was later merged is not recorded in FINDINGS or LOOP, so the line was not called stale.
- HANDOFF.md section 0's "Waiting on Ryan: #48 calls" line was considered and not called stale: the design read, Brin's pronoun and package question 2 are still genuinely Ryan's, even though the design text itself was delivered Nov 8 and the visuals moved to #250.
- Build-log numbers inside PROGRESS.md and NEXT.md (frame times, draw calls, version-by-version change lists) were treated as dated records of their builds, not as current-state claims; only header, framing and still-open claims were audited.
- BACKLOG.md:17 and the rest of its section 0a coverage gaps: FINDINGS records the R63 ruling but not the Eclipse battleship's build status, so these could be neither confirmed nor refuted from the winning sources.
- LOOP.md lines 71 to 140 reached only the chair and the blind leg (the Qwen supplementary pack carried lines 1 to 70); no leg checked the entry docs against the tail of LOOP's queue and holds in full, beyond the holds the blind leg cites.
- Whether CI or any reader actually opens PROGRESS.md or NEXT.md first in practice: the audit judges mislead-risk from the files' own presentation, not from measured reader behaviour.

## Rulings on the NEEDS RYAN questions (Ryan, Nov 8, 2026)

Ryan ruled on all five questions the same day, in the main chat, agreeing with the Rey pick on each:

- NR1: (A) Move HANDOFF.md sections 1 to 6 and the Nov 1 block into docs/archive, leaving section 0 plus a one-line pointer in HANDOFF.md.
- NR2: (A) PROGRESS.md gets a superseded banner and is frozen as the pre-Godot history.
- NR3: (A) NEXT.md is retired entirely; the per-weapon effects brief moves into the current effects work (the #232 stress pack and the FX stack under R122).
- NR4: (A) CLAUDE.md becomes a short file that points at AGENTS.md and keeps only Claude-specific notes.
- NR5: (A) BACKLOG.md is frozen as the pre-board record with a banner; live work lives only in GitHub issues.

Opus applies these together with the UNAMBIGUOUS fixes above.
