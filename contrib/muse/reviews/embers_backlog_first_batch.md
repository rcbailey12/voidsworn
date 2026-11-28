# Embers full-backlog council: first batch for Claude

Chair: Rey (Muse). Pack pulled Sat Nov 28, 2026, about 05:15 to 06:00 CT. Main head at pull: 4a6c1c18b2b1a84991ac48bf9cceb97220179faa (verified unchanged at chair time).
Legs in for this batch: blind Rey (file reads verified), DeepSeek (evidence only, no repo access, 3 INFERRED items), Qwen4-Max (two comparison responses, evidence only, 10 findings + 10 leads). Still running: Grok, ChatGPT (GPT-6.2 Sol at High), Gemini (Hydrogen, sign-in in progress). Full council synthesis follows when they land.
Rule: every chair-verified claim below was read by the chair against the exact commit named. Anything marked UNVERIFIED is a leg claim the chair has not yet checked. No Neon or Astra material was read by any leg.

## What can move

1. PR #2235 (LOAD39, hull analysis off main thread, head 5a54132022, GREEN, mergeable clean). The code is in good shape. The one open item is a PC proof, not a code fix: Artoo asked for one close while a geometry task is confirmed in flight on a heavy hull, reporting the build-task join time. Chair verified the code the risk sits on: battle.gd:1338-1345 signals cancellation, fx_hull.gd:1036 builds the BVH inside the worker, ship_view.gd:146 joins tasks synchronously at quit ("WorkerThreadPool.wait_for_task_completion(int(e[\"tid\"]))"). Merge when the PC rerun exists; do not merge on CI green alone.

2. PR #2271 (issue 2248, FX tint leaks follow-up, head 30f8a8439a, GREEN, base current main). Qwen flagged it as a possible duplicate of merged PR #2265 (same issue, identical title). Chair checked: not a duplicate. #2265 merged Nov 27 from base 061f626865 with fx_ship.gd, fx_special.gd and the death-style check; #2271 is the same branch rebased onto current main 4a6c1c18 and carries only the still-unmerged files (capture.bat, API.md, fx_death.gd, the 2248 check, godot_checks.txt). One check remains before merge: confirm the fx_death.gd hunks in #2271 are new work, not a re-application of #2265's hunks.

## What needs work

3. PR #2188 (effects kind registry, head 66ab69a100, GREEN) has a real gap in its own gate. Chair verified at the head: the symbol regex in godot/fx/test/fx_kind_registry_check.gd:154 accepts at most one qualifier, and a non-match is skipped at lines 171-173. The playbook rule at docs/playbooks/effects.md:82 says "Use the registry name at new call sites". An inline FX.StreakKind.SPARK_KIND in a sprite kind slot is skipped instead of checked. DeepSeek and Qwen both reached the same point from the pack. Fix: check the enum family and member for qualified inline arguments, with one correct-family and one wrong-family fixture, before the registry is used to clear follow-on FX PRs.

4. PR #2106 (bake worker, head b93ef2856a, GREEN, mergeable clean) and LOAD38 still disagree on cache accounting. Chair verified: world_bake.gd:144 on the #2106 head trims with _trim(CACHE_MAX - _entry_images(maps).size()), while main:142 in the same remember function trims with _trim(CACHE_MAX). Neon's COMBINE FIRST verdict was on the older head 3630cc89, which GitHub then reported conflicting; the current head reports clean against the same main, so that verdict is stale. The underlying ask is not: name one integration head and merge order, preserve both the bake service and the LOAD38 work, and rerun the bake checks plus the windowed LOAD38 and rocky-quit proof on that exact combined SHA. Neither branch's green CI proves the combined state.

5. PR #1852 (round 2 hitch, 150 to 190 ms pipeline compile in every battle, head ff9a3f7333, GREEN) is stuck behind a lapsed hold. Its title says "[HOLD: contains an old 1445 head; rebase after 1445 merges]". Chair verified PR #1445 merged Nov 24, 2026 at 20:11 UTC. The hold condition is met. Rebase #1852 onto current main and take a merge decision; the hold tag in the title is the only thing stopping a playtest-relevant hitch fix.

6. PRs #2169 and #2247 edit the same single file. Both are GREEN and both touch only tools/pc/lane_tools_refresh_selftest.js (#2169 fixes the ready-file race, #2247 fixes flaky timing). Whichever merges second will conflict or silently overwrite the other's fix. Name the merge order and run the combined selftest (20 runs per #2150, 10 per #2242) on the merged result.

7. Three open PRs edit the same CI shard machinery: #2196 (issue 2179, 5-shard rework), #2220 (issue 2174, shard plan path fix), and draft #2223 (issue 2149, CI speed). Chair verified heavy file overlap: #2196 and #2223 share the guard hooks, workflows.patch, run_all_checks, godot_shard_tests and run_checks.sh; #2220 touches godot_shard_tests.js and run_checks.sh as well. Merge order needed: #2196 first, then #2220's plan.txt path fix confirmed surviving, then #2223 out of draft.

8. The A16 death-seam check is one shared stale fixture, not three broken PRs. Chair verified the failing check-runs: A16 fails on PR #1960 (1780 perf), PR #2021 (Wave 2B) and draft PR #2222 (FX id table), alongside their Godot game check failures. The #2188 body already records the cause: the check "needs CI's fresh bake because the committed fixture is stale". Refresh the fixture once and re-read all three PRs before fixing any of them around it.

9. The Acid Thorns rename still has no vehicle. Chair verified on main: docs/playbooks/factions.md:287 names the weapon "Close-in weapon: Acid Thorns", while godot/rules/data/tables.json contains no "Acid Thorns" string and the rules id is still tendril. PR #2276 (issue 2161, "Dropped-work fixes A") lists "Acid Thorns name" in its title, but its files are only sfx.gd, the sfx parse-once check, rival_lines.json, the rival-memory check and godot_checks.txt. It does not touch the rules table. Qwen's second response suggested #2276 covers the rename; the chair checked and it does not. The rename needs a named owner.

## What is genuinely blocking the playtest

10. The live playtest build predates a day of merges. LOOP.md newest LATEST line (Nov 26, 17:10 UTC) says "playtest live (157746b7, g2_pt_157746b_1126b)". Ten PRs merged Nov 27 after that line, including PR #2236 (Ryan's R460 rules picks), PR #2237, PR #2104 (AAA UI plates) and PR #2221 (Astra audit). If Ryan playtests on 157746b7 he is not playing the R460 rules or the latest UI. Refresh the build before his session, or label the session as testing the older build.

11. The red PRs that matter most are #2021 (Wave 2B, dirty, all four Godot game checks plus A16 failing on head 8626d8277c) and #1725 (1412 escorts, unstable, game checks 1 of 3 and 3 of 3 failing on head fc7116cc1e). #2021 blocks the FX train's sprite 29 reservation; #1725 is doubly blocked, red CI plus Ryan's per-ship picks from the 1146 run 3 redraw still open. Neither is a quick merge.

## Patterns the individual legs missed

- Merge-then-fix is now a documented pattern, and it needs a ruling. PR #2007 merged Nov 26 at 20:47 UTC after Artoo's Nov 24 preflight said it still failed full checks on the death-plane test; PR #2265 (merged Nov 27) and open PR #2271 then fixed the "FX faction tint leaks left after #2007". Whether the death-plane check was green at the merge moment is UNVERIFIED from the pack; the Board should confirm that state and say plainly whether merge-then-fix is accepted for effects work, because the next effects PR will be judged by it. R452 ("the Board may merge its own PRs once checks are green") is the ruling in question.
- Two registries are still open at once: #2188 (step 0, green) and draft #2222 (FX id table, red, mergeable false). The #2188 body says "#2222 Remains held. No second registry." A held draft is still a live second registry effort; one of them needs a close-or-rebase decision before the merge train moves.
- Issue #1328 (outside look at the soft gas floor, PR 1301) is stale: opened Nov 20, zero comments, never delivered, PR 1301 since merged. It needs Ryan's word (run against current main, or close), not a quiet run.
- Issue #1572 (sound redo research) is stranded: delivered Nov 22, PR #1718 closed unmerged Nov 25, the pack lives only on branch muse/issue-1572. Sound work (#2034, #2039) cannot reference it until it lands somewhere.

## Disagreements kept visible

- Qwen response 2 refuses to present pack-derived items as OBSERVED findings and issues zero findings, only leads. Response 1 presents the same material as findings. The chair treats both as triage input; the chair-verified items above are the ones that survived a file read.
- DeepSeek and Qwen both worked from evidence.md only and could not read repo files. Their convergence with the blind leg on the registry gap and the #2106 integration head is meaningful precisely because the chair then verified both against the commits.

## Not checked (chair)

- Contents of the failing Godot game check logs on PRs 1725, 1960, 2021, 2185, 2209, 1163 and 2222 (check names and conclusions only).
- Whether the death-plane check on PR 2007 was green at its merge moment.
- Whether a newer playtest build than 157746b7 exists.
- The remaining legs (Grok, ChatGPT, Gemini) and the rest of the 62 PRs and 100 issues beyond the items above. Full synthesis follows.
