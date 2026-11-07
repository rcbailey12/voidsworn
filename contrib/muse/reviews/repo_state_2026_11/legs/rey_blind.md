# Blind Rey leg: Voidsworn repo state audit (Nov 7, 2026)

Written blind from PACK.md only. Every claim cites an issue number, a PR number, or a file name from the pack. Inferences are marked INFERRED.

## 1. Verdict (Q1)

READY WITH CONDITIONS.

The three facts that most determine this verdict:

1. The delivered work is real, identified, and waiting in one place. PRs #203, #204, #205 are open, and the pack maps each one to its job (PR #203 is the #200 delivery, PR #204 is the #201 delivery with owner rulings pushed Nov 6, PR #205 is the #202 delivery). The Nov 6 audit stack was ruled by the owner the same day and filed as issues #207 to #215, plus tooling notes #206 and #214 and the Nov 7 note #216. Nothing in the pack shows lost or duplicated deliveries.
2. The top layer an incoming agent reads first is stale in load-bearing places. AGENTS.md still opens with "Voidsworn is a Babylon.js hex fleet-tactics roguelite built into one HTML file" and "he plays on a Pixel 10 XL and a Windows PC", while CLAUDE.md records the Oct 24 ruling "PC-only" and the standing rule in section 5.4 requires Godot parity work in godot/rules and godot/campaign. LOOP.md's current state is dated 2026-11-05 03:50 UTC and still reports "Codex: #187 (Pyre-Barge round 6) running since 03:29Z", a job LOOP.md's own log shows merged as PR #196.
3. Two live tripwires sit directly in Opus's first hour: issues #198 and #199 are labeled codex and NOT blocked while Codex is down and the PC watcher auto-queues unblocked codex issues, and the #207 benchmark gates the Nov 6 settlement stack, so the first session has to be triage and unblocking, not building. Both are fixable inside one Opus session, which is why this is not NOT READY.

## 2. Conflict map (Q2), ranked by damage if Opus walks in cold

C1. PR titles misdescribe their contents: PR #203 and PR #204, two different jobs, both carry the title "R109: station detail pass #199, Muse #200 to #202; LOOP.md". Per the pack, PR #203 is the #200 surface detail standard and PR #204 is the #201 Nemesis checks; neither is the #199 station detail pass, which is a separate codex job whose PR is held for Ryan. If Opus reviews or merges by title, it can merge the wrong thing, or think the held #199 work has landed. Both titles also name LOOP.md, so the two PRs may both edit contrib/opus/LOOP.md and conflict on merge (INFERRED: the pack gives titles, not diffs). Damage: wrong merge on the board's own state file in the first session.

C2. Issues #198 and #199 are unblocked codex jobs with no Codex. The snapshot shows #198 and #199 labeled codex with no blocked label, while every other codex queue item (#139, #140, #120, #121, #122, #169, and the rest) carries blocked. AGENTS.md states the PC watcher "checks the board every 10 minutes and queues each new codex issue", and LOOP.md's traps confirm the board queues any unblocked open codex issue with no open PR, and that a duplicate run "force-pushes the branch and auto_pr opens a new PR". LOOP.md's Nov 5 header gives the counter-instruction: "Opus owns the board and does the codex jobs itself; relabel an issue `opus` before starting it so the PC watcher skips it". That relabel has not happened. Damage: dead Codex runs queued every poll, duplicate runs when Opus starts the same jobs, or round 7 simply never starting while the board believes it was released (LOOP.md queue item 1: "#198 Pyre-Barge round 7 (R108; released 14:32Z, no PR yet, Codex out of usage)").

C3. AGENTS.md and CLAUDE.md disagree about the project itself, despite AGENTS.md ending "`CLAUDE.md` holds the same rules for Claude. Keep the two in step." AGENTS.md describes a Babylon.js one-file game built with python3 build.py and phone play; CLAUDE.md says "Read HANDOFF.md first", records PC-only, and section 5.4's standing rule assumes a Godot port with oracle copies. AGENTS.md's own audit pointer chain (docs/REVIEW_PROTOCOL.md, then docs/ship_pipeline/TEXTURE_PASS.md, then docs/ship_pipeline/AUDIT_BRIEF.md) never mentions HANDOFF.md. Damage: any fresh agent session, Opus's included, that starts from AGENTS.md works from the wrong engine, the wrong build command, and a retired platform. This is issue #216's subject, and it is still unfixed on main.

C4. LOOP.md's operating state is two days old and points at the wrong board owner. Its header says "Board owner right now: the lead chat (Ryan, Nov 4 21:33 CST)" and that the hourly board task stays off "until the weekly Claude usage reset"; the reset is the event Opus's return represents, and the same file's Nov 5 22:30 note says Opus owns the board after it. Its Muse section still lists "#200 surface detail standard, #201 Nemesis test checks, #202 playtest checklist" as open under "(R109, Claude usage capped)", although all three were delivered as PRs #203 to #205 on Nov 5. Damage: if Opus follows LOOP.md literally it either defers to a lead chat that has handed over, or re-triages delivered work as undelivered.

C5. The rulings registry's state cannot be confirmed from the pack's own evidence. Section 1 and CLAUDE.md make contrib/opus/FINDINGS.md the authority that overrides older docs, and section 5 sizes it at "about 106,000 (over 2,000 lines)". Section 5.5's scan of the same file reports "Total lines: 283. Ruling headings found: 0", and its tail is B, D, K and X tables with no R-numbered ruling headings at all. One of these descriptions is wrong, and the pack does not say which. Damage: every Nov 6 outcome issue (#207 to #215) instructs recording rulings in FINDINGS; if Opus cannot locate where R102 to R109 live, the whole settlement stack records into the wrong place or twice.

C6. Two build queues compete. NEXT.md is a v53-era queue ("v53: solid and readable", with an Oct 21 ship-shapes section covering "desktop and phone") that predates the Nov 2 job board. LOOP.md carries a different, newer queue order derived from the backlog check (R106). The issue labels match neither cleanly: LOOP.md queue positions 3 to 16 (#139, #140, #120, #121, #122, #24, #26, #27, #29, #30, #92, #100, #169, #41, #42, #44) are almost all blocked-labeled, so the queue cannot simply be executed top to bottom; each item must be unblocked one at a time under LOOP.md step 4. And position 15, #169, is gated on "Ryan's round 7 pick", which waits on #198 landing, which is stuck per C2. Damage: Opus follows the wrong queue, or starts a blocked chain out of order.

C7. The standing leg composition names a reviewer who cannot serve. AGENTS.md instructs: "Write the Models line as: Rey writes a blind leg first, DeepSeek and Qwen write, Argon reviews only, Rey chairs." The standing rule repeats that Argon "reviews and proposes ideas only". Pack section 0 states Argon is blocked (Google AI Pro lapsed Nov 5) and Flash runs ideation only, never as a reviewer; it also states ChatGPT is down for 3 days with Opus covering the checker seat, a change no standing doc records. Damage: new audit or review jobs commissioned from the standing text staff an empty reviewer seat and wait for a checker who is not coming.

C8. One workstream is split across two opus issues. Section 6 records that #208 (graphics red team) "now also carries the environment audit's station assert fixes", while #213 is the environment and backdrop audit's own rulings and settlement issue. Damage: the station assert work can be implemented twice, or the two settlements can diverge, unless Opus deliberately works #208 and #213 as one item.

C9. Muse's scope is stated two incompatible ways. AGENTS.md tells any non-main agent: "Do not edit files outside it: no game source, no tools, no docs". The muse standing rule (section 5.4, FINDINGS R81) authorizes muse to deliver low-code fixes including changes to battle.js, core.js, data.js and campaign files with Godot parity. Damage is lower because the standing rule is the more specific document (INFERRED), but a returning Opus reviewing a muse PR against AGENTS.md alone could reject in-scope work or accept out-of-scope work.

C10. Branch sprawl: 103 branches (codex 47, muse 33, opus 10, plus legacy names), and the pack states "Most agent branches persist after their PRs merge or close." Combined with the LOOP.md duplicate-run trap in C2, stale branches are the raw material for accidental duplicate PRs. Damage: hygiene and confusion rather than immediate breakage, but it grows with every job.

## 3. Overwhelm triage (Q3)

Seventeen issues carry the opus label in the snapshot. Classified:

Jobs (rulings to record in FINDINGS plus a settlement program or a build to run):
- #207 ceiling rulings plus benchmark scene job. The only one whose output other settlements wait on.
- #208 graphics red team rulings and settlement (work together with #213 per C8).
- #209 build-route comparison: a real two-arm build, not paperwork.
- #210 FX audit rulings and settlement (includes the consolidated movement spec and the S15 listen pass, which needs the owner).
- #211 HunyuanVideo-Foley probe: one self-contained local probe run.
- #212 destruction, physics feel and camera audit settlements.
- #213 environment and backdrop audit settlements.
- #215 UI and campaign map audit settlements.

Notes (read, absorb, no build):
- #206 Kamome harness tooling note.
- #214 Kensei pipeline tooling note.
- #216 repo memory hygiene note: a note with follow-on asks; its first consolidation run matters, its full program does not belong in session one.

Parked:
- #193 Tripo challenger: parked until the weekly reset per LOOP.md Holds, and blocked behind the owner's paid-service call (house rule is free and local tools only). The reset arriving does not unpark it; only the owner does.
- #194 ideation outcome: five screened proposals, parked with #193; a backlog, not a job.
- #43 Eclipse portraits: opus and blocked; stays blocked behind its chain.

Close, merge or defer candidates:
- #96 and #98 (owner rulings on the #76 and #81 research, filed Nov 3): INFERRED candidates to verify against FINDINGS and close, since their content is rulings that belong in the registry, not standing work. One verification pass, not a session.
- #48 Glasswright species design (filed Nov 2, never updated since): defer, or close if later portrait work superseded it (INFERRED; the pack does not establish supersession).
- #216's implementation asks: defer behind the #207 to #215 stack; Opus sequences its own hygiene.

Smallest set Opus must touch in its first session (three items):
1. LOOP.md: rewrite state, queue, holds and waiting-on-owner (one docs-only push, the file Opus is explicitly allowed to commit to main). This single edit defuses C2, C4 and C6 for every later session.
2. PRs #203, #204, #205: review by diff and merge or send back. This closes muse issues #200, #201, #202 and unblocks the #120 to #122 edits that #204's rulings feed.
3. #207: confirm it as the first job in the queue. Everything else can be read-only triage in session one.

## 4. Execution order (Q4)

For the opus queue, with the board handoff at the end:

1. LOOP.md refresh, including relabeling #198 and #199 to opus. Reasoning: the board's state file is the coordination point for every agent, it is currently two days stale, and the relabel is the documented guard against the watcher queueing dead Codex runs.
2. Review PRs #203, #204, #205 by diff; merge #204 first, then #203, then #205. Reasoning: they are finished work blocking three open issues; #204's #201 rulings feed the edits to #120 to #122 per LOOP.md, #203's corrected standard is cited by the Nov 6 settlements, and #205's checklist has no dependents. Read all three diffs before merging any, per the possible LOOP.md overlap in C1.
3. #207 benchmark scene job. Reasoning: pack section 7 itself flags that the #207 benchmark gates several things; the graphics and FX settlements cannot set their frame numbers until it reports.
4. Record #208 and #213 into FINDINGS and schedule their settlements as one workstream. Reasoning: C8; one recording pass prevents the station assert fixes from being built twice.
5. #210 settlements, starting with the consolidated movement spec. Reasoning: the spec is document work Opus can finish without the benchmark, while its sound items wait on the owner's S15 sitting, which is already outstanding.
6. #212, then #215 settlements. Reasoning: both are Nov 6 settlement programs recorded after #207 and #210 so FINDINGS receives one audit at a time and owner review rounds stay small.
7. #209 build-route comparison. Reasoning: it is the largest single build in the stack and should start with the benchmark's cost picture from #207 and the #206 and #214 harness notes already absorbed.
8. #211 Foley probe. Reasoning: self-contained, one local run on the RTX 5080, and its adopt or drop judgement rides the same owner listen pass as #210's S15 items.
9. Notes #206, #214, #216 absorption, with #216's consolidation pass becoming the recurring hygiene slot and its first run fixing the AGENTS.md engine and phone lines (C3). Reasoning: notes change how jobs run, not what ships, so they land after the queue is moving.
10. Older and parked opus items: one verification pass over #96 and #98 (close if recorded, INFERRED), defer #48 and #194, leave #193 parked for the owner's call and #43 blocked. Reasoning: none of them gate anything in the Nov 6 stack.
11. Codex queue handoff, in LOOP.md order: run #198 (PR held for Ryan's pick, with the comparison sheet and greyscale check), then #199 (PR held for Ryan's look), then unblock one at a time: #139, #140, #120, #121, #122, #24, #26, #27, #29, #30, #92, #100, #169, then #41, #42, #44. Reasoning: LOOP.md's header assigns these to Opus while Codex is down, its queue order already respects the dependencies (#121 before #24, #24 and #122 before #92, #198's pick before #169), and the holds protect the two judgements only Ryan can make.

## 5. Draft briefing prompt for Opus (Q5, 399 words)

You are Opus, back online after the usage reset (about 18:40 CST, Nov 7). While you were capped, Rey ran the board. Read this first, then LOOP.md, then act.

What happened Nov 5 to 7: Rey delivered muse jobs #200, #201, #202 as PRs #203, #204, #205 on Nov 5. On Nov 6 an audit stack ran and Ryan ruled it the same day: ceiling pressure test and benchmark job (#207), graphics red team (#208), build-route comparison (#209), FX audit with the S15 sound listen pass and a movement spec (#210), HunyuanVideo-Foley probe (#211), destruction, physics and camera audit (#212), environment audit (#213), UI audit (#215), and two tooling notes (#206, #214). On Nov 7, #216 (repo memory hygiene and council memory) was filed to you. Owner rulings on #201 were pushed to PR #204 on Nov 6; #201 has no open questions left.

Cast changes: ChatGPT is down until its reset in about 3 days (about Nov 10). You cover the checker and red-team seat until then; do not wait for it. Codex is down for a while: per LOOP.md's Nov 5 header you do the codex jobs yourself, relabeling each issue opus before you start so the PC watcher skips it. Argon is blocked (Google AI Pro lapsed); Flash is ideation only, never a reviewer.

PRs: #203, #204, #205 are open and unmerged. Their titles are wrong. #203 is the #200 surface detail standard, #204 is the #201 Nemesis checks with the owner rulings, #205 is the #202 playtest checklist. Judge them by their diffs, not their titles.

Proposed first moves (a proposal; re-sequence as you see fit): 1) Rewrite LOOP.md's state, queue and holds; it is dated Nov 5 and still shows Codex-era state, and AGENTS.md still describes a Babylon one-file game and phone play, both stale. 2) Review PRs #203 to #205; #204 first, because its rulings feed the #120 to #122 edits. 3) Run the #207 benchmark scene job; the #208 and #210 settlements wait on its numbers. 4) Work the opus queue in audit order, keeping #193 parked: Tripo is a paid service and Ryan has not made that call. Two owner items are outstanding and not yours to decide: the #193 paid-service call and the S15 listen pass (one sitting, Ryan's ear). #198 and #199 are labeled codex and unblocked; their PRs are held for Ryan's pick and look when they land.

## 6. Owner questions (Q6)

1. Does the board go back to Opus now, including switching the hourly board loop task back on, or does the lead chat keep it? LOOP.md says the task stays off until you revisit it, and names the lead chat as board owner. Cost of leaving it unanswered: either two board owners issuing releases, or none; that is exactly the duplicate-run failure LOOP.md's traps describe.
2. Is Tripo (#193) approved as a paid service, against the free-and-local house rule? Cost of leaving it unanswered: #193 stays parked indefinitely and #209's comparison runs without its paid challenger route, so the build-route verdict lands with one arm missing.
3. When does the S15 sound listen pass happen (one sitting, your ear)? Cost of leaving it unanswered: #210's sound settlements and #211's adopt-or-drop judgement cannot be decided, and two opus issues stay open carrying work that is finished except for that sitting.

## 7. Not established

- Whether PRs #203 and #204 actually edit the same files. Both titles name LOOP.md, but the pack contains no diffs; the merge-conflict half of C1 is INFERRED.
- The true size and structure of contrib/opus/FINDINGS.md. The pack contradicts itself (about 106,000 bytes and over 2,000 lines in section 5; 283 lines and 0 ruling headings in section 5.5), so C5 is a conflict inside the evidence, not a verified fact about the file.
- Whether the rulings in #96 and #98 are already recorded in FINDINGS, and whether #48 has been superseded by later work. Both close candidates in Q3 are INFERRED from dates and titles only.
- The contents of issues #206 to #216 beyond their titles and the section 6 one-line summaries, including their fixed blocks, branches, and internal dependencies, beyond the pack's statement that the #207 benchmark gates several things.
- Whether the PC watcher is still running and has queued #198 or #199 since Nov 5, and whether any Codex run started before the usage ran out. The snapshot shows no PRs from them; their run state on the PC is not in the pack.
- The contents of HANDOFF.md section 0 and of NEXT.md beyond their heading maps; the C6 ranking rests on headings, dates, and LOOP.md's newer queue.
- ChatGPT's exact reset time and whether Opus covering the checker seat changes any Models line already written on open muse issues #200 to #202 (all three are delivered, so the point is moot for them; it is not established for future jobs).
- Whether Ryan wants the hourly board loop task restored at all; LOOP.md records that it was switched off by Ryan on Nov 4 and that its runs "kept stopping for approvals and were refused merges", but no later instruction is in the pack.
