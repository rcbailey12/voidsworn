# Full Audit of Recent, Running, and Planned Work (Nov 24, 2026)

Snapshot taken Nov 24, 2026 around 03:48 to 04:14 UTC via `gh api` REST on `rcbailey12/voidsworn` and local Git reads in the `t3_neon` clone.
Scope: everything since `main` `88c21aca` (PR #1890, 00:11 UTC) up to `main` `91b79b037` (PR #1927, 03:45 UTC), plus a full recheck of the 21 items in the 1898 audit (`contrib/neon/reviews/work_audit_1123.md`).
Live counts at audit close: **31 open PRs** (28 ready, 3 drafts; PRs #1929 and #1930 opened during the audit at 03:49 and 03:53 UTC) and **81 open issues**.

**Lead call:** Stop or fix 4 active blockers before their queued GPU runs or merges: (1) PR #1925 (`Astra 1889 S9A`) is RED on `Standing checks` (`FLEET.md` stale), has 4 out-of-scope `docs/shots/` files, a 404 `.blend` link, and no `[HOLD]` title, yet sits in the GPU queue; (2) PR #1904 (`1877 RUN2`) has a `.bat` bug (`OPUS1877_CHORUS_CLOSE.bat` calls `build_b`'s `look_bench.bat`, which on `main` ignores `LB_ARGS` and skips `look_moments_chorus_close.json`); (3) newly opened PR #1929 (`#1907` janitor task) lets `--nightly` bypass the solo GPU deferral (`janitor.ps1:151`); (4) PR #1776 (`PC_M`) and PR #1445 (`LOAD30d`) both rewrite `world_bake.gd:clear_static()` in incompatible ways, and PR #1784 (`WAVE2AB2`) still conflicts with `main`. Next, fix the 3 GPU-queue items that have no open issue (`WRECK5b`, `WAVE1B3`, `C14`), slot issue #1908 (`R411` re-export) into the GPU line, rescue the unmerged `opus/wip-1519-sliced` branch (`#1519`), and record Ryan's Nov 24 pale-pearl Glasswright interior pick in `FINDINGS.md` and `RULEBOOK.md`.

---

## Priority 0: Immediate Blockers (Active GPU Line, Red Checks, New Code Bugs)

### 1. PR #1925 (`codex/issue-1889` @ `fee505f3`, queued on GPU as `Astra 1889 S9A`): RED on `All checks`, out-of-scope files, broken link, and missing `[HOLD]`
- **What is wrong:** Four stacked problems on a PR already sitting in the GPU queue:
  1. **RED on `Standing checks` (`All checks: failure`):** `node contrib/opus/tools/fleet_list.js --check-page` fails with `PROBLEM: docs/ship_pipeline/FLEET.md is stale` because Astra added `tools/recipe/ships/voidsworn_S9A.json` without regenerating `docs/ship_pipeline/FLEET.md` (Opus's PR #1910 updated `FLEET.md` in `b103606c`). Running `Astra 1889 S9A` on `fee505f3` violates R407 (`RULEBOOK 3.12`).
  2. **Out-of-scope files:** Issue #1889's `Deliver to` specifies `contrib/codex/warden_astra_1124/` plus the four `voidsworn_S9A` recipe files, but PR #1925 also committed 4 files under `docs/shots/issue-1889-codex/`.
  3. **Broken artifact link and no `[HOLD]` guard:** As Artoo flagged (`7120830391`), `contrib/codex/warden_astra_1124/REPORT.md:17` links `S9A_painted.blend`, which returns 404 on GitHub. The auto-opened non-draft PR has no `[HOLD]` title even though `tools/recipe/ships/voidsworn_S9A.json:5` targets `"game_code": "V14_23"` (the same install slot as shipping S9 and Opus's PR #1910).
- **Evidence (OBSERVED):** CI job `138187502774` (`Standing checks`: `PROBLEM: docs/ship_pipeline/FLEET.md is stale`); `git diff --stat origin/main...origin/codex/issue-1889` lists `docs/shots/issue-1889-codex/voidsworn_S9A_{battle_170,three_quarter}.png` and `.provenance.json`; PR #1925 comment `7120830391`; `tools/recipe/ships/voidsworn_S9A.json:5` (`"game_code": "V14_23"`).
- **Suggested fix:** Add `[HOLD: blind build pair 2, never merge unless Ryan picks it]` to PR #1925's title, run `node contrib/opus/tools/fleet_list.js --write` on `codex/issue-1889`, drop `docs/shots/issue-1889-codex/`, point `REPORT.md:17` at the real relay/PC path, wait for green `All checks`, then pin `Astra 1889 S9A` to the green commit.

### 2. PR #1904 (`opus/issue-1877` @ `757b67aa`, queued on GPU as `1877 RUN2`): **NEW MISSED BUG** in `OPUS1877_CHORUS_CLOSE.bat` plus unreviewed head
- **What is wrong:** `tools/pc/jobs/OPUS1877_CHORUS_CLOSE.bat:9-11` sets `LB_ARGS=--part moments --moments res://bench/look_moments_chorus_close.json` and calls `"%VT%\build_b\tools\pc\jobs\look_bench.bat" origin/opus/issue-1877 none`. However, `build_b` runs `main`'s installed copy of `tools/pc/jobs/look_bench.bat`, and on `main` (`91b79b037`) `look_bench.bat:182` only copies `look_moments.json` (not `look_moments*.json`) and `look_bench.bat:193` never passes `%LB_ARGS%`. Those two edits exist only on PR #1904's unmerged branch. If `1877 RUN2` runs `OPUS1877_CHORUS_CLOSE.bat` before PR #1904's `look_bench.bat` changes reach `build_b`, `look_bench.bat` will silently ignore `LB_ARGS` and run the entire default `look_moments.json` instead of the 4 Chorus clips (code mismatch OBSERVED; whether the PC queue's local `1877 RUN2` bat works around this is INFERRED/not checked). Separately, latest commit `757b67aa` (which added `var failed` and `_shutdown(4)` after Artoo's comment `7118485137` on `cb2940b0`) has no review comment yet (R407).
- **Evidence (OBSERVED):** PR #1904 `tools/pc/jobs/OPUS1877_CHORUS_CLOSE.bat:9-11` (`set "LB_ARGS=--part moments --moments res://bench/look_moments_chorus_close.json"` / `call "%VT%\build_b\tools\pc\jobs\look_bench.bat" origin/opus/issue-1877 none`); `origin/main:tools/pc/jobs/look_bench.bat:182,193` has zero occurrences of `LB_ARGS` and copies only `look_moments.json`; PR #1904 comments stop at `cb2940b0`.
- **Suggested fix:** Verify the queued `1877 RUN2` PC bat calls `opus/issue-1877`'s own `look_bench.bat` (or merges the `look_bench.bat` `LB_ARGS` plumbing to `main` and refreshes `build_b` first), fix `OPUS1877_CHORUS_CLOSE.bat` not to rely on unmerged `build_b` flags, and review `757b67aa` before `1877 RUN2` starts.

### 3. PR #1929 (`codex/issue-1907` @ `e94fb71f`, PC janitor scheduler, opened 03:49 UTC, green): scheduled `--nightly` task bypasses solo GPU deferral
- **What is wrong:** To keep after-job disk scans from skewing solo frame-time runs, PR #1929 added `Test-AfterJobGpuClaim -SoloOnly` (`tools/pc/janitor.ps1:150-161`). Because line 151 returns `$false` for every trigger except `--after-job` (`if ($trigger -ne '--after-job') { return $false }`), the new 3:30 AM Windows Scheduled Task (`& $janitor --nightly`, `janitor.ps1:20`) and `--low-space` ignore `gpu_solo` and can run full disk scans on top of an overnight solo frame-time capture (contradicting `RULEBOOK 3.4` and the PR's own timing rationale in `docs/playbooks/pc.md:92`). Confirmed independently alongside Artoo's comment `7121473506`.
- **Evidence (OBSERVED):** PR #1929 `tools/pc/janitor.ps1:20` (`& $janitor --nightly`), `:150-151` (`function Test-AfterJobGpuClaim([switch]$SoloOnly) { if ($trigger -ne '--after-job') { return $false }`), `:698-715`; PR #1929 comment `7121473506`.
- **Suggested fix:** Check `gpu_solo` for `--nightly` (and `--low-space` above the emergency floor) before consuming the nightly date stamp in `Reserve-AutomaticRun`, so the task's 15-minute retry window picks up once the solo run finishes; add a `runner_cleanup_tests.js` case for `--nightly` under `gpu_solo` followed by a same-night retry.

### 4. PR #1913 (`codex/issue-1905` @ `7060e622`, Wave 2 D5, running run 2 on Lane C): RED on `Godot game checks (2 of 3)` and unfixed Spread Pattern splash-kill bug
- **What is wrong:** Commit `7060e622` merged `main` into `codex/issue-1905` keeping `main`'s `campaign.gd`/`campaign_ui.gd` (PR #1892 claim guard) while retaining `reward_flow_test.gd`, so `Godot game checks (2 of 3)` is currently RED (`SCRIPT ERROR: Invalid call. Nonexistent function '_heavy_wreck_cause' in base 'RefCounted (campaign.gd)'`). Lane C started run 2 at 03:52 UTC to re-apply D5 cleanly over PR #1892. Make sure run 2 also addresses Artoo's High finding (`7119253355` on `99b78c4b`): Spread Pattern torpedo splash kills (`godot/rules/rules.gd:2827-2833`) set `x["killCause"] = "big"` on neighbor ships without naming those neighbors in the torpedo hit log line, so `campaign.gd`'s reverse log-string search can miscredit an earlier weapon hit on the reward card.
- **Evidence (OBSERVED):** CI job `138190993973` (`reward_flow_test: FAIL`); `git show --stat 7060e6223`; PR #1913 comment `7119253355` (`rules.gd:2827-2833`, `campaign.gd:3536-3551`).
- **Suggested fix:** Confirm Lane C's run 2 push turns `All checks` green, keeps PR #1892's one-grant claim guard, and passes a structured fatal-hit cause from `rules.gd` (tested with a Spread Pattern splash kill).

### 5. PR #1776 (`opus/issue-1765` @ `5cf7a614`, queued as `1765 PC_M`) vs PR #1445 (`opus/issue-1434` @ `ffc4ead9`, queued as `LOAD30d`): incompatible `world_bake.gd:clear_static()` shutdown paths plus `PC_M` pin skew
- **What is wrong:** Two issues on the two highest-priority engine PRs in the GPU queue:
  1. **Dual shutdown conflict (OBSERVED code overlap; combined runtime INFERRED):** Both PR #1776 (`godot/world/world_bake.gd:123-133`, freeing unattached `_pending` via deferred `_attach`) and PR #1445 (`godot/world/world_bake.gd:68-95`, calling `_stop_worker()` to join an attached worker thread) modify `clear_static()` for different crash bugs. Merging either cleanly over the other without keeping BOTH cleanup paths will reintroduce a Windows exit crash (Artoo `7121131615`).
  2. **`PC_M` pinned to a red commit:** PR #1776 comment `7120917874` (03:15 UTC) notes `PC_M stays pinned to 9de7f81a` even though `9de7f81a` failed `Standing checks` (`picture_provenance_tests`), fixed in `5cf7a614`. While the delta is only a 1-line test allowlist in `picture_provenance_selftest.py`, R407 requires green checks on the pinned head.
- **Evidence (OBSERVED):** PR #1776 comment `7120917874` and `7121131615`; `git diff 69563a9d..origin/opus/issue-1765 -- godot/world/world_bake.gd`; local `git merge-tree` / pairwise hunk check showing 7 shared files between #1445 and #1776.
- **Suggested fix:** Merge PR #1445 first (after `LOAD30d` on `ffc4ead9`), then merge `main` into PR #1776 keeping BOTH `_stop_worker()` and `_pending.free()`/`_attach`, and add one combined test covering close-before-attach and close-during-active-bake before merging #1776. Note the `9de7f81a` -> `5cf7a614` test-only delta when grading `PC_M`.

### 6. PR #1784 (`codex/issue-1693` @ `97387d35`, queued in `WAVE2AB2`) and PR #1852 (`codex/issue-1843` @ `8ecd3b53`, `[HOLD]`): still CONFLICT with `main`
- **What is wrong:** Verified locally against `origin/main` (`91b79b037`) with `git merge-tree --write-tree`:
  - **PR #1784** (87 commits behind `main`, untouched since Nov 23 20:23 UTC) conflicts on `godot/tools/ci/godot_checks.txt` while still queued for `WAVE2AB2`.
  - **PR #1852** (150 commits behind `main`, properly `[HOLD]`ed) conflicts on `godot/render/ship_view.gd` and `godot/world/world_rocks.gd` because it carries an old PR #1445 ancestor.
- **Evidence (OBSERVED):** `git merge-tree --write-tree --name-only origin/main origin/codex/issue-1693` -> `CONFLICT (content): Merge conflict in godot/tools/ci/godot_checks.txt`; `git merge-tree` on `origin/codex/issue-1843` -> conflicts in `godot/render/ship_view.gd`, `godot/world/world_rocks.gd`.
- **Suggested fix:** Merge `main` into `codex/issue-1693` before merging PR #1784 (and confirm `WAVE2AB2` pins the merged head if not already run); keep PR #1852 held until PR #1445 merges, then rebase #1852 onto `main`.

### 7. Eight open PRs in the GPU line (plus PR #1910) have code commits AFTER their last PR review comment (R407 / `RULEBOOK 3.12`)
- **What is wrong:** Comparing every open PR's `head.sha` against every review comment SHA on that PR shows the following queued GPU PRs still lack a review comment on their current head:
  - **PR #1861** (`020b5295`, R431 round F): last reviewed `3f016cb5`; `2f47b1af` fixed the ribbon index bug and `11c3f3eb`/`020b5295` merged #1786 and `main`.
  - **PR #1904** (`757b67aa`, `1877 RUN2`): last reviewed `cb2940b0` (also see Item 2).
  - **PR #1755** (`a4592180`, `JOINT_G`): last reviewed `8361e0c8`; `a4592180` moved Glasswright `wall_max: 0.45` into the wound profile and material check.
  - **PR #1763** (`58b12e88`, `JOINT_G`): last reviewed `663d481f`; `71dfd7f5` and `58b12e88` added pale pearl Glasswright rooms and `wall_max: 0.45`. Title is also stale (`[HOLD: merge 1724 first; joint E after R431]` though #1724 already merged).
  - **PR #1874** (`8caeab8a`, `1582 RUN4`): last reviewed `ad7dfa6b` (`8caeab8a` was a manual merge in `ship_view.gd`).
  - **PR #1772** (`7c734f53`, `PROPS_N`): last reviewed `deddb79b`.
  - **PR #1858** (`0a95e335`, `1394J`): last reviewed `bc6d39d7`.
  - **PR #1725** (`3f32695b`, `H7N`): last reviewed `beb89846` (`61ef5beb` and `3f32695b` fixed the break-line table and per-surface plate count).
  - Also **PR #1910** (`b103606c`, Opus S9O blind leg): 0 comments.
- **Evidence (OBSERVED):** REST `pulls/<N>.head.sha` compared against `issues/<N>/comments` on all 31 open PRs.
- **Suggested fix:** Have Artoo or the Board log a short head-delta check on each PR before its GPU capture runs (highest urgency: #1904, #1755, #1763, #1874, #1725).

---

## Priority 1: Queue, Dispatch, and Hygiene Problems

### 8. Three active GPU-queue items have NO open issue carrying them, while Issue #1908 (`R411` rollout) is missing from the GPU queue
- **What is wrong:** Checking every entry in the current GPU line against GitHub issues:
  1. **`WRECK5b (PR 1737)` has no open issue:** Issue **#1236** (`Wrecks that block a hex should sit in that hex`) was CLOSED on `2026-11-20T06:04:06Z` (and still carries the `running` label!). No open issue tracks PR #1737 or `WRECK5b`.
  2. **`WAVE1B3` (in `C10 + WAVE1B3`) has no open child issue:** Issue **#1691** (`Wave 1B`) was CLOSED on `2026-11-22T19:51:34Z` (merged in PR #1736), and #1690 is closed; only the umbrella tracker #1689 is open.
  3. **`C14` (in `C11 to C14`) has no open issue:** Open issue **#1291** covers `C10 to C13` (`Deliver to: ... the C10 to C13 build sheets and recipes`), while `C14` (`B22_11`, Brood-sac carrier) was tracked by **#1155** (CLOSED Nov 23 23:03 UTC) and `#1683` (`Chorus: restrained glow`) was CLOSED Nov 22 17:39 UTC.
  4. **Issue #1908 (`R411 fleet rollout`, left from #1680) is NOT in the GPU line:** Issue #1908 explicitly states `"Runs on the PC GPU line after the current joint stack (JOINT_F) so it re-exports the final Glasswright shells"`, yet it has no slot in the Board's GPU queue (and `JOINT_F` is becoming `JOINT_G`). Its fixed block also uses placeholder `Branch: opus/issue-<this>` instead of `opus/issue-1908`.
- **Evidence (OBSERVED):** REST `issues/1236` (`state: "closed"`, `labels: ["opus", "running"]`), `issues/1691` (`state: "closed"`), `issues/1155` (`state: "closed"`), `issues/1683` (`state: "closed"`), `issues/1291` (`Deliver to: ... the C10 to C13 build sheets`), `issues/1908` (`Branch: opus/issue-<this>`, `"Runs on the PC GPU line after the current joint stack (JOINT_F)"`); `docs/ship_pipeline/FLEET.md:48-52`.
- **Suggested fix:** Reopen or file short tracking notes for `WRECK5b` (reopen #1236 or link PR #1737 on #1239), note `WAVE1B3` on #1689, extend #1291's `Deliver to` to `C10 to C14` (if C14 is getting the same recess-glow/rebuild pass), fix #1908's `Branch:` to `opus/issue-1908`, and place #1908 in the GPU line right after `JOINT_G`.

### 9. Issue #1911 (`opus, running`, C27 double hail): `THIS IS THE JOB NOW` placed inside a code fence, plus long quiet runs on #1911 and #1705
- **What is wrong:**
  1. In issue **#1911**'s body, `## THIS IS THE JOB NOW (run 1, Board Nov 24 2026; opus API arm)` sits on line 15 **inside** the triple-backtick log-excerpt code fence, splitting the sample battle log. Under `RULEBOOK 2.4` (`"exactly one line outside code fences containing THIS IS THE JOB NOW"`), run 1 still started because #1911 has no run history so the runner passed the whole body, but adding a run 2 brief later will break parser selection unless moved outside the fence.
  2. **Long quiet `running` claims (watch for stalls/ceiling):** Issue **#1911** (`work/issue-1911-opus`) has been `running` since `2026-11-24T02:06:47Z` (~2 hours, no remote branch yet). Issue **#1705** (`codex/issue-1705`, Lane B) has been `running` since `2026-11-23T23:28:31Z` (~4.5 hours, no remote branch yet; 6-hour `CODEX_CAP` expires around `05:28 UTC`).
- **Evidence (OBSERVED):** REST `issues/1911` body lines 13-20 (code fence opens before `## THIS IS THE JOB NOW`); runner status comments on #1911 (`Started (UTC): 2026-11-24T02:06:47Z`) and #1705 (`Started (UTC): 2026-11-23T23:28:31Z`); `git ls-remote origin` shows neither `work/issue-1911-opus` nor `codex/issue-1705` pushed yet.
- **Suggested fix:** Move #1911's `## THIS IS THE JOB NOW` heading outside the code fence before any run 2 edit; check Lane B (#1705) and the opus API slot (#1911) on the next Board check so neither times out silently.

### 10. PR #1903 (`codex/issue-1897` @ `5c16ab24`, 12 admiral portraits) carries 9 out-of-scope files, while superseded PR #1896 and Issue #1887 stay open
- **What is wrong:** Because issue #1897 set `Base: codex/issue-1887`, PR #1903 carries 23 files: 14 requested in `contrib/codex/portraits_v1/`, **7 inherited from unmerged PR #1896** (`contrib/codex/portraits_test/*` and `docs/shots/issue-1887-codex/*`), and **2 new files** in `docs/shots/issue-1897-codex/` outside `"no files outside contrib/codex/portraits_v1/"` (Artoo `7116669639`). Meanwhile PR #1896 and issue #1887 remain open even though R444 + #1897 replaced the 2-picture trial.
- **Evidence (OBSERVED):** `git diff --stat origin/main...origin/codex/issue-1897` (23 files, including `docs/shots/issue-1887-codex/*`, `contrib/codex/portraits_test/*`, `docs/shots/issue-1897-codex/*`); PR #1903 comment `7116669639`; REST `pulls/1896` and `issues/1887` both `state: "open"`.
- **Suggested fix:** Strip the 7 trial files from PR #1903 (keeping `contrib/codex/portraits_v1/sable.png` unchanged) and decide whether to drop `docs/shots/issue-1897-codex/` before merge; close PR #1896 and issue #1887 as superseded by #1897.

### 11. Issue #1877 (`muse`) and PR #1881 (`muse/issue-1877`) still open with wrong PR body and split ownership
- **What is wrong:** Muse delivered the 4 Chorus tendril replacement concepts in PR #1881 (green, clean, Nov 23 19:48 UTC), and Opus already built the 4 3D look-bench options in PR #1904 (`opus/issue-1877`). Yet PR #1881 is still unmerged with an auto-generated body that begins `"Issue 1854: PC checks"` (Artoo `7112202634`), and issue #1877 still carries only the `muse` label while Opus owns the active clip build.
- **Evidence (OBSERVED):** REST `pulls/1881` (`state: "open"`, `All checks: success`), comment `7112202634`; REST `issues/1877` (`labels: ["muse"]`); REST `pulls/1904` (`head.ref: "opus/issue-1877"`).
- **Suggested fix:** Fix PR #1881's body text, merge PR #1881, and switch issue #1877's owner label to `opus` (or file a dedicated clip/implementation issue for PR #1904) so Muse's watcher cannot treat #1877 as pending Muse work.

### 12. Standing governance docs still contradict R405 and R446 (`RULEBOOK.md:275`, `LOOP.md:29, 46-47`, `HANDOFF.md`)
- **What is wrong:**
  1. `docs/RULEBOOK.md:275` (`"AI rules in battle.js and rules.gd together"`) and `contrib/opus/LOOP.md:29` (`"battle.js and rules.gd together"`) still instruct workers to edit the retired browser `battle.js`, contradicting R405 (`RULEBOOK 3.1`; flagged by Artoo on PR #1902 comment `7119387200`).
  2. `contrib/opus/LOOP.md:46-47` still states Claude API arms are `OFF until Nov 21` and Codex is `paused (R342)`, contradicting R446 (`FINDINGS.md:471`) and live lanes; `LOOP.md:7-9` lock is frozen at Nov 16; `HANDOFF.md` section 0 is still Nov 16 (pointing at closed #211 and Nov 17 `OPEN_WORK.md`).
- **Evidence (OBSERVED):** `docs/RULEBOOK.md:275`; `contrib/opus/LOOP.md:7-9, 29, 46-47`; `HANDOFF.md:1, 24, 30`; PR #1902 comment `7119387200`.
- **Suggested fix:** Replace both `battle.js` cohesion examples with `godot/rules` + `RULEBOOK 3.1`, refresh `LOOP.md` "The seats" to reflect R446 and Neon/T3 Code, and schedule #1506 / #1661 to retire `OPEN_WORK.md` and refresh `HANDOFF.md`.

### 13. Minor queue hygiene: 6 closed Neon issues retain `running`, and 29 open `opus`/`muse` issues use placeholder `Branch:` text
- **What is wrong:** All 6 recently closed Neon issues (**#1899, #1909, #1915, #1918, #1920, #1924**) plus closed **#1236** still carry the `running` label after closure. Separately, 29 open `opus`/`muse` issues (including brand-new **#1908**) keep literal `Branch: opus/issue-<this>` or `opus/issue-<this number>` placeholders.
- **Confirmed clean (no defects found):** Zero open `codex` issues are missing `blocked`; zero open issues have more than one `Base:` line; zero open issues have more than one `THIS IS THE JOB NOW` heading (issue #1926 only quotes the phrase in prose).
- **Evidence (OBSERVED):** REST `issues?state=closed` labels on #1899, #1909, #1915, #1918, #1920, #1924, #1236; full scan of all 81 open issues in `open_issues.json`.
- **Suggested fix:** Clear `running` whenever closing a Neon issue (in the same step as merge/close under RULEBOOK 2.4); replace `Branch: opus/issue-<this>` with the real issue number when dispatching any PC/API job.

---

## Priority 2: Lost Work, Unrecorded or Stale Rulings (R440+), and PRs to Close or Merge

### 14. Unmerged branch with real unlanded code: `opus/wip-1519-sliced` (`7fc1efd74`, Nov 22) has no PR while Issue #1519 stays open
- **What is wrong:** Remote branch `origin/opus/wip-1519-sliced` holds a complete 167-line commit (`7fc1efd74`, Nov 22 05:09 UTC: `Issue 1519: leaving a battle shows the title first, the old battle is freed in slices behind it`), editing `godot/main/main.gd` (`retire_scene`), adding headless test `godot/main/test/retire_scene_check.gd`, and registering it in `godot/tools/ci/godot_checks.txt`. No PR was ever opened, `retire_scene` is absent from `main`, and issue #1519 (`opus`) is still open with no PR or queue spot.
- **Also unmerged (archive record only):** `origin/neon/holistic-and-looks-1123` (`1faa0fa71`, Nov 23 14:19 UTC) holds `contrib/neon/reviews/combined_fable_astra_review_1123.md` and `holistic_game_audit_1123.md` (363 lines, neither on `main`). Fable and Astra already reviewed them under R427/R430, so only the repo archive copy is missing.
- **Other non-pin branches ahead of `main` verified NOT lost:** `claude/project-thread-3i2fya` (`4e55e1524`) is an ancestor of open PR #1858; `claude/project-thread-o9ln9r` (`9b47498bf`) landed on `main`; `claude/project-thread-kzjmk5` (`5f5e01b23`) is the live `JOINT_G` stack pin; `opus/issue-1452` (`c1ec1cd75`), `neon/issue-1879` (`cc683e377`), and `codex/issue-1802` (`2e69539fd`) were intentionally superseded/closed under R440, R444, and PR #1892.
- **Evidence (OBSERVED):** `git show --stat origin/opus/wip-1519-sliced` (`3 files changed, 167 insertions(+), 3 deletions(-)`); `git grep retire_scene origin/main -- godot/main/` (0 matches); REST `issues/1519` (`state: "open"`), 0 PRs on `opus/wip-1519-sliced`; `git ls-tree origin/main contrib/neon/reviews/holistic_game_audit_1123.md` (empty).
- **Suggested fix:** Decide whether to rebase `opus/wip-1519-sliced` onto `main` after PR #1445 (they both touch `godot/main/main.gd`) and open a PR for #1519, or close/archive it if #1445 supersedes it.

### 15. Rulings and `FINDINGS.md` drift (R440 to R446 + unrecorded Nov 24 Glasswright pale-pearl pick)
- **What is wrong:**
  1. **Unrecorded Nov 24 ruling:** Ryan's Nov 24 decision (`LOOP.md:83-84`: `"Ryan: Glasswright insides to pale pearl (not dark grey)"`, raising Glasswright `wall_max` from R420's `0.11` to `0.45`) is already implemented across PR #1755 (`a4592180`), PR #1763 (`58b12e88`), and `5f5e01b2`, yet **no FINDINGS row exists for it** (FINDINGS stops at R446) and `docs/RULEBOOK.md:539` still states `"walls at most 0.11 linear"` with no Glasswright exception.
  2. **Stale `"waits on"` lines in `FINDINGS.md` (`LOOP.md:30`):** **R443** (`contrib/opus/FINDINGS.md:468`) still says `"waits on issue 1888"` even though PR #1900 (#1888) merged at `b35fd854c` (00:50 UTC), and **R434** (`contrib/opus/FINDINGS.md:459`) still says `"waits on PR 1782"` even though PR #1782 merged at `0da3790b` (22:46 UTC).
  3. **Still unfiled from earlier rulings:** R428/R429 (Neon in T3 Code / auto-approve) still have no `RULEBOOK.md` 2.6/2.7 edit; R430 Waves 2 to 3 items **D1, D6, D7, D8** still have no issues (only D5 got #1905); sandbox NTFS hard-link TEMP cleanup (noted on closed #1854) still has no issue.
- **Evidence (OBSERVED):** `contrib/opus/FINDINGS.md:459, 465-471`; `contrib/opus/LOOP.md:83-84`; `docs/RULEBOOK.md:538-539`; `git log --oneline` confirming PR #1782 (`0da3790b`) and PR #1900 (`b35fd854c`) are on `main`.
- **Suggested fix:** Add a FINDINGS row (R447) for Ryan's Nov 24 pale-pearl Glasswright interior ruling and land the `0.45` exception in `docs/RULEBOOK.md:539` with PR #1755/#1763; update R434 and R443 in `FINDINGS.md` from `"waits on"` to `"Landed"`; file issues for R430 D1, D6 to D8 and the NTFS TEMP cleanup.

### 16. Ready, superseded, or stale open PRs to act on (not yet closed or merged)
- **Ready / near-ready:**
  - **PR #1928** (`claude/project-thread-3riw5a`, draft, `40e59322`, green on `All checks`, Artoo finding answered with relay commit `1ca0c43` hashes): undraft and merge (Sound 1752 mastering fixes from #1924).
  - **PR #1930** (`codex/issue-1906`, `a3abb80d`, green on `All checks`, 0 comments): review diff and merge BEFORE PR #1914 (overlap in `battle.gd`, see Priority 3).
  - **PR #1902** (`neon/issue-1898`, `b88e4bd3`, green) and **Issue #1898**: Board already verified and routed it (`LOOP.md:86`), yet both remain open; merge (noting Artoo's Item 2 correction) or close as archived.
- **Still-open stale/red PRs carried from 1123 (unhandled):**
  - **PR #1833** (draft, Nov 23 review pack, do not merge) and **PR #1442** (draft, Nov 21, blocked #1439, touches `main.gd`): close drafts unless still actively linked.
  - **PR #1720** (`opus/open-work-nightly`, `OPEN_WORK.md` bot, drops `neon` seat): close via #1506.
  - **PR #1718** (`muse/issue-1572`, RED on `Standing checks`, overtaken by #1752) and **PR #1163** (`muse/issue-1145`, RED on `Standing checks` + `Godot game checks`, 5 days old): decide close vs rerun.
- **Evidence (OBSERVED):** REST `pulls/{1928,1930,1902,1833,1442,1720,1718,1163}` status and check runs.
- **Suggested fix:** Undraft/merge #1928, review/merge #1930, close or merge #1902/#1898, and clear #1833, #1442, #1718, #1720.

### 17. Open issues whose brief still contradicts a newer ruling (carried over from 1123, unchanged)
- **What is wrong:** Seven open issues still contradict later rulings with no override note: **#1582** (and **PR #1874** title) still say `"arcing munitions"` (contradicts R435 flat torpedoes); **#1764** still names `"faceted Blender multi-crystal"` (contradicts R434/R445); **#1453**, **#1145**, **#1146**, and **#256** still reference retired browser JS rules `data.js`/`core.js`/`battle.js`/`sim3d.js` (contradicts R405, and #256 omits Grok/Flash from R231); **#1153** still references the `"tendril"` weapon scrapped by R437. Also **#1239** still lacks a fixed block (`Deliver to:`, `Branch:`, `Done when:`).
- **Evidence (OBSERVED):** Live bodies in `open_issues.json` for #256, #1145, #1146, #1153, #1239, #1453, #1582, #1764; PR #1874 title.
- **Suggested fix:** Update the stale titles/notes before dispatching any of those issues.

---

## Priority 3: Merge Clashes Between Open PRs and Safe Merge Order

Verified against `origin/main` (`91b79b037`) using `git merge-tree` and hunk-level diff comparison (within 4 lines) across all 31 open PRs. Two PRs currently conflict with `main` (**#1784**, **#1852**); 12 open PRs append to `godot/tools/ci/godot_checks.txt` (**#1445, #1737, #1755, #1772, #1776, #1784, #1786, #1852, #1861, #1874, #1913, #1914**) and will need routine trivial rebases.

### Real Code/Doc Conflict Pairs (OBSERVED from local diffs)

| Cluster | PR Pair | Conflicting Files and Regions | Safe Merge Order and Why |
|---|---|---|---|
| **1. Picker Lock vs Brisk Camera (NEW)** | **#1930** vs **#1914** | `godot/scenes/battle/battle.gd` (`begin_with` L534-538 and `_input` L3957-3963) | **#1930 first** (already green), then merge `main` into **#1914** (run 2 on Lane A). |
| **2. Loading vs Brisk Camera (NEW)** | **#1445** vs **#1914** | `godot/main/main.gd`, `godot/scenes/battle/battle.gd` (plus shared `title.gd`, `hud.gd`) | **#1445 first**, then merge `main` into **#1914**. |
| **3. Loading vs Planets (CRITICAL)** | **#1445** vs **#1776** | `godot/world/world_bake.gd` (`clear_static` dual-path hazard, Item 5), `world_planet.gd`, `board.gd`, `static_caches.gd`, `battle.gd` | **#1445 first** (after `LOAD30d`), then merge `main` into **#1776** preserving both `_stop_worker()` and `_pending.free()`/`_attach`. |
| **4. Loading vs Exteriors / Movement / Wounds / Props / Wave 2B / Hitch** | **#1445** vs **#1786**, **#1874**, **#1755**, **#1772**, **#1784**, **#1852** | `#1786`: `ship_view.gd`, `static_caches.gd`, `battle.gd`; `#1874`: `board.gd`, `ship_view.gd`, `battle.gd`; `#1755`: `fx_death.gd`, `fx_hull.gd`; `#1772`: `static_caches.gd`; `#1784`: `sfx.gd`; `#1852`: 28 files (dirty) | **#1445 first** as the engine backbone, then bring `main` into each downstream PR (and rebase `#1852`). |
| **5. R431 Glasswright Kit vs Interior Kit V2 vs Wounds V2 (NEW overlap)** | **#1786/#1861** vs **#1763** vs **#1755** | `#1861 <-> #1763`: 8 Glasswright files, close hunks in `ithar_GS1.py` and `kits/ithar/hull.py`; `#1763 <-> #1755`: `godot/fx/faction_looks.json` (both now set `ithar` `wall_max: 0.45`); `#1786 <-> #1755`: `look_bench.gd`, `fx_hull.gd` | **#1786** (incorporating `#1861` after R431 round F; close `#1861`) -> **#1763** -> **#1755** (keeping combined `faction_looks.json` with both `interior` and `wound` entries). |
| **6. Exteriors V2 vs World Props V2** | **#1786/#1861** vs **#1772** | `contrib/opus/FINDINGS.md`, `docs/RULEBOOK.md`, `godot/render/static_caches.gd`, `look_bench.gd` | **#1772 first** (only waits on `PROPS_N`), then merge `main` into **#1786** keeping R423, R425, and R426 plus both `RULEBOOK 3.14` edits. |
| **7. Chorus Close Clips vs FX PRs (NEW)** | **#1904** vs **#1755**, **#1758**, **#1772**, **#1786/#1861** | `godot/bench/look_bench.gd` (`#1755`, `#1772`, `#1786`, `#1861`), `godot/fx/fx_weapons.gd` (`#1755`, `#1758`) | `#1904` is a test-switch clip branch until Ryan picks an option; keep unmerged until Ryan's pick (or lift only its `look_bench.bat` `LB_ARGS` fix if needed). |
| **8. Wrecks vs Acid Tell** | **#1737** vs **#1858** | `docs/playbooks/deaths_and_hits.md`, `godot/fx/fx_death.gd` | **#1737** (after `WRECK5b`) -> **#1858** (after `1394J`). |
| **9. Movement Stage 2 vs Exteriors** | **#1874** vs **#1786/#1861** | `godot/render/ship_view.gd` (`clear_static`), `godot/scenes/battle/battle.gd` | **#1874** (after `#1445` and `1582 RUN4`) -> **#1786**. |
| **10. Blind Warden Pair (NEW)** | **#1910** vs **#1925** | Both target `game_code: V14_23` and both will touch `docs/ship_pipeline/FLEET.md` once `#1925` fixes `fleet_list` | **Hold both** (`[HOLD]`); merge at most one only if Ryan picks it over shipping S9. |
| **11. Portrait Trial vs Production** | **#1896** vs **#1903** | 7 identical files (`portraits_test/*`, `docs/shots/issue-1887-codex/*`) | Close **#1896** unmerged; strip its 7 files from **#1903** before merging `#1903`. |

**Recommended merge backbone:**
1. **Immediate (zero-conflict):** `#1928` (undraft), `#1881` (fix PR body), `#1930` (after diff check), `#1929` (after solo-GPU nightly fix).
2. **Engine backbone:** `#1445` (after `LOAD30d`), then rebase `#1852` and merge `main` into `#1914` (after `#1930` + `#1445`) and `#1913` (after Lane C run 2).
3. **World and FX wave:** `#1772` (`PROPS_N`), `#1737` (`WRECK5b`), `#1874` (`1582 RUN4`), `#1758` + `#1784` (after rebase and `WAVE2AB2`), `#1858` (`1394J`), `#1725` (`H7N`, after head review).
4. **Exteriors + Interiors + Wounds + Planets pack:** `#1786` (carrying `#1861`), then `#1763`, then `#1755`, then `#1776` (preserving both `world_bake.gd:clear_static` paths).

---

## Recheck of the 1898 Audit (`work_audit_1123.md`) plus Issues #1908 and #1909

| 1898 Item | Topic | Status | Evidence (OBSERVED) |
|---|---|---|---|
| **1** | PR #1445 dirty on `main` + unreviewed `b521b3a1` | **FIXED** | `main` merged; Fable and Artoo (`7120240121`) reviewed up to `ffc4ead9`; PR #1445 is `CLEAN` and green (`LOAD30d` queued). |
| **2** | PR #1890 duplicate `ShipView` + unblocked HUD actions | **WRONG (part 1) / OPEN (part 2)** | Part 1 (duplicate `ShipView`) was **WRONG**: Artoo `7116469345` showed `battle.gd:894-905` at `3a1f8553` already guarded `if views.has(u["id"]):`, and #1890 merged at `88c21aca` opening the picker before view creation. Part 2 (input lock) was filed as **#1906** and just delivered green **PR #1930** (`a3abb80d`), awaiting review/merge. |
| **3** | PR #1861 dirty, red, old #1786 ancestor, ribbon bug | **FIXED** | Ribbon index fixed in `2f47b1af`, #1786 (`6dba5c9a`) merged in `11c3f3eb`, `main` merged in `020b5295`; now `CLEAN` and green (needs head review comment, Item 7). |
| **4** | PR #1876 unfixed Thorne turn-planner bug | **FIXED** | Fixed in `bba06874` (`R.spendTurn(v)` in `battle.gd:_turns_ok` + `plan_commit_check`), merged at `bf9b9652d`; #1651 closed. |
| **5** | PR #1755 `fx_wreck_t0` stamped at precompute | **FIXED** | Restamped at death in `cc11a096` and merged cleanly over #1831's prebuilt mesh path (`ebf6df93`..`a4592180`). |
| **6** | Issue #1779 closed by mistake on docs-only PR #1781 | **FIXED** | Reopened Nov 23 23:03 UTC with label `opus`. |
| **7** | PR #1784 dirty on `main`; PR #1758 tendril hunk | **OPEN** | PR #1784 (`97387d35`) still conflicts with `main` on `godot_checks.txt`; PR #1758 (`90953201`) untouched. |
| **8** | PR #1724 JPEG parser bug + silent skip; PR #1763 stale ancestor | **FIXED** | PR #1724 fixed both in `31cc7b4f` and merged at `0631c3e1a` (closing #1680; rollout moved to #1908); PR #1763 merged `main` and is `CLEAN` and green at `58b12e88`. |
| **9** | PR #1725 `hegemony_H7.py` per-surface plate count | **FIXED** | Commit `3f32695b` tracks `laid_by` per surface (`deck_panels`, `flank_panels`, `belly_panels`); needs head review before `H7N` (Item 7). |
| **10** | Issue #1897 inherits stray files from PR #1896 | **OPEN** | PR #1903 (`5c16ab24`) carries all 7 files from PR #1896 plus 2 in `docs/shots/issue-1897-codex/`; Artoo `7116669639` confirmed; #1896 and #1887 still open (Item 10). |
| **11** | PR #1892 and PR #1890 red on `All checks` | **FIXED** | Both fixed and merged (`f23f4c5b4` and `88c21aca`); #1883, #1802, PR #1811, and #1870 closed. |
| **12** | GPU PRs unreviewed on latest head + PR #1737 held chips | **OPEN (partial)** | PR #1737 held chips fixed (`33561155`) and Board-audited; #1445 and #1776 reviewed; 8 GPU PRs still lack head review comments (Item 7). |
| **13** | Ready unmerged PRs (#1880, #1881, #1845, #1835) | **OPEN (partial)** | #1880, #1835, and #1845 merged (#1407 and #1836 closed); **PR #1881** is still open with wrong PR body (Item 11). |
| **14** | Stale/superseded/red PRs (#1811, #1837, #1896, #1833, #1442, #1720, #1718, #1163) | **OPEN (partial)** | #1811 and #1837 closed; **#1896, #1833, #1442, #1720, #1718, #1163** remain open (Items 10 and 16). |
| **15** | Already-merged open issues to close | **FIXED (mostly)** | #1854, #1667, #1649, #1490, #1456, #1155, #1603, #1802 closed; #1887 still open; #1739 stays open for PC node-check failures. |
| **16** | Stale `running` labels (#1407, #1651, #1582) | **FIXED** | Cleared on #1407, #1651, and #1582 (new minor pattern: 6 closed Neon issues retain `running`, Item 13). |
| **17** | Missing fixed block (#1239), prose `Base:`, unqueued partials (#1357/#1352) | **OPEN (partial)** | #1490, #1456, #1899 closed; #1239, prose `Base:`, and unqueued #1357/#1352 unchanged (Item 13, 17). |
| **18** | Open issues contradicting newer rulings | **OPEN** | #1582, #1764, #1453, #1145, #1146, #256, #1153 still carry stale pre-ruling text (#1649 closed; Item 17). |
| **19** | R428/R429 not landed in `RULEBOOK.md` | **OPEN** | Zero matches for `T3 Code`, `R428`, or `R429` in `docs/RULEBOOK.md` (Item 15). |
| **20** | R430 D1/D5-D8, R437 clips, R436 slices | **OPEN (partial)** | D5 filed (#1905) and R437 clips built (PR #1904); **D1, D6, D7, D8** still unfiled (Item 15). |
| **21** | NTFS hard-link TEMP cleanup unfiled; stale `HANDOFF.md` & `LOOP.md` | **OPEN** | No issue for sandbox NTFS TEMP cleanup; `HANDOFF.md` and `LOOP.md` non-LATEST sections unchanged, plus `RULEBOOK.md:275` / `LOOP.md:29` still cite `battle.js` (Items 12 and 15). |

### Named Follow-up Checks Requested by Brief
- **Issue #1908 (R411 fleet re-export, left from #1680):** **FILED, OPEN (2 queue/block gaps).** Properly split out when #1680 closed with PR #1724 (`0631c3e1a`), keeping the re-export, `publish_ship.bat` readback, and camera-170 VRAM proof from being lost. Gaps: `Branch: opus/issue-<this>` placeholder instead of `opus/issue-1908`, and no slot in the Board's active GPU queue even though the body schedules it right after `JOINT_F` (now becoming `JOINT_G`).
- **Issue #1909 (C27 Nemesis double hail, PR #1912):** **FIXED / HANDED OFF.** PR #1912 (`contrib/neon/reviews/c27_double_hail.md`) confirmed the double hail on `main` (`d610eca2c`) and merged at `b20601525`; issue #1909 closed at 01:51 UTC (minor: still carries the `running` label). The fix is filed as **issue #1911** (Board pick A: `rival_lines.json` owns the hail), currently running on `work/issue-1911-opus` (watch Item 9: `THIS IS THE JOB NOW` inside the code fence, and ~2 hours running with no branch push yet).

---

## Not checked:

- **Board's `work_audit_verified_1123.md` and private relay artifacts:** `board/neon_1123/work_audit_verified_1123.md` was not present on any branch of `rcbailey12/voidsworn` or `rcbailey12/voidsworn-relay` accessible from this clone, so the 1898 recheck was verified directly against `origin/neon/issue-1898:contrib/neon/reviews/work_audit_1123.md`, `LOOP.md`, `main` commits, and live GitHub REST API state.
- **Local PC queue files and live runner logs:** Did not inspect `Downloads\voidsworn_test\queue\`, `board\`, `build_b\`, or live PC process logs (read-only audit stayed inside the `t3_neon` clone and GitHub REST API); therefore whether the PC queue's local `1877 RUN2` bat works around `OPUS1877_CHORUS_CLOSE.bat` is inferred/unchecked.
- **Full line-by-line review of large unchanged PR diffs and Blender geometry:** Read full diffs of new/changed PRs (#1900, #1904, #1913, #1923, #1928, #1929, #1930) and newest deltas of #1445, #1725, #1755, #1763, #1776, #1861, plus recipes/manifests of #1910 and #1925. Did not read every line of the 547-line `voidsworn_S9O.py` / 207-line `voidsworn_S9A.py` Blender build scripts, the merged 923-line Node daemon (`pc_daemon.js`, PR #1835, already audited across 7 Astra runs), or binary `.png`/`.jsonl.br` assets.
- **Runtime execution of Godot, Blender, or Node checks on open PR branches:** Relied on hosted CI check runs and local `git merge-tree` / static code inspection (except a read-only PowerShell `-Command` multiline test to avoid a false positive on PR #1929).
