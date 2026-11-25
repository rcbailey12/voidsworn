# Full Audit of Recent, Running, and Planned Work (Nov 24, 2026 Morning)

Snapshot taken Nov 24, 2026 around 13:05 to 13:28 UTC via `gh api` REST on `rcbailey12/voidsworn` and local Git reads in the `t3_neon` clone.
Scope: everything since the 1926 audit (`main` `60bdaed5c`, PR #1931, 04:28 UTC) up to `main` `5524078e2` (12:58 UTC `LOOP.md`), plus a full recheck of all 17 items in `contrib/neon/reviews/work_audit_1124.md`.
Live counts at audit close: **33 open PRs** (30 ready, 3 drafts) and **80 open issues**.

**Lead call:** Act on 5 urgent items before running more GPU or Codex work on top of them:
1. **Fix `godot/rules/sim/sim_run_policy.gd:177-185` before accepting active Codex Lane B run #1992:** the balance sim bot buys Chorus refits with biomass (`campaign.gd:904-909`) and then checks `if run.credits < credits` to decide whether to fit them, leaving Chorus refits unfitted in the hold and skewing `SHOP_DISCOUNT` tuning.
2. **Trim active paid Claude API run #1463 (`work/issue-1463-opus`):** its brief still orders two already-merged look items (`SG` superseded by PR #1863/#1786; `PL` merged in PR #1776), burning paid tokens and GPU work unless narrowed to `ER` and `AB`.
3. **Fix the systemic `.import` stripper in `tools/pc/work_issue.ps1:468-469` and commit the 3 missing storm `.png.import` files on PR #1986 (`#1360`):** the runner unconditionally strips every `.import` file even when explicitly allowlisted in `.gitignore`, which already broke PR #1961 (`#1779` run 2), just broke PR #1986's storm bolt linear atlases, and will break future `#1943` `.glb.import` deliveries.
4. **Update two stale GPU pins before they run (`LOAD35` on PR #1445 and `opus1939b` on PR #1983) and fix unaddressed bugs on PR #1980 and #1995:** `LOAD35` is pinned to conflicted `9c015f43` (PR #1445 moved to green `81368f70`, and still keeps `title.gd`'s unneeded TAA backdrop restart); `opus1939b` is pinned to buggy `62590eb4` (PR #1983 already fixed the cloud bug and pushed green `6eb7f1f95`); Board-passed PR #1980 still scorches a permanent hull wound on a zero-damage standalone crit/ion hit; and active Lane D run #1995 risks reusing hull-cut caches across ships with different seeds, poses, or damage.
5. **Fix `#1990` before it starts next on the `opus` API arm, add `[HOLD]` to stacked PR #1998 (which carries all 12 files of unmerged PR #1772), and mark shelved `#1943` / `#1988` as shelved in their issue bodies:** `#1990` points the PC API arm at two files that do not exist on `main` (`docs/shots/issue-1887-codex/sable.png` and `board/review_1124/fable_lore_holistic.md`).

Note on two defects fixed while this audit was running: PR #1784 (`codex/issue-1693`) was red on `hull_lift_check` at `e92b6687` because its `main` merge kept two deleted shield-bob lines in `godot/fx/fx_ship.gd:555-556`, and PR #1904 (`opus/issue-1877`) was missing `acid_thorn_check.gd` from `godot/tools/ci/godot_checks.txt` at `9db58723`. Both pushed fixes at 13:22 to 13:23 UTC (`f808d7a99` and `019d3f46f`), and CI is currently running on both heads.

---

## Priority 0: Immediate Blockers (Active Runs, Runner Bug, Real Code Bugs, GPU Pin Skew)

### 1. Active Codex Lane B run #1992 (`codex/issue-1992`, Balance pass): tuning `SHOP_DISCOUNT` on a broken Chorus refit bot (`godot/rules/sim/sim_run_policy.gd:177-185`, merged in PR #1946)
- **What is wrong:** `sim_run_policy.gd:180-185` (landed in PR #1946) decides whether the sim bot can afford a refit with `credits - cost >= 120` and only fits the purchased refit `if run.credits < credits: _fit_module(id)`. Because `godot/campaign/campaign.gd:904-909` charges Chorus biomass first (R382 / `RULEBOOK 11.9`), the sim bot (a) skips buying Chorus refits whenever biomass is high and credits are low, and (b) when both cover the cost, buys with biomass so `run.credits` never drops and leaves the bought refit unfitted in the hold forever. Artoo flagged this on PR #1946 (`7123229172`) and repeated it on issue #1992 at `12:58Z` (`7132183062`), 3 minutes before Lane B started at `13:01Z`. Under `RULEBOOK 2.4` (R281), the PC runner reads only the issue body, so Lane B never saw the warning and will bake a bot-only Chorus handicap into `SHOP_DISCOUNT`.
- **Evidence (OBSERVED):** `godot/rules/sim/sim_run_policy.gd:177-185` (`if credits - cost < 120: continue`, `if run.credits < credits:`); `godot/campaign/campaign.gd:904-909` (Chorus biomass spent before credits); issue #1992 comment `7132183062` (12:58:26Z) and runner start comment (`13:01Z`); PR #1946 comment `7123229172`.
- **Suggested fix:** Fix `sim_run_policy.gd:177-185` (use `campaign.shopCan(cost)` / Chorus `hullFunds()` and check inventory/refit count instead of `run.credits < credits`), add a Chorus refit buy-and-fit sim test, and rerun both the before and after 240-seed balance runs before merging any `SHOP_DISCOUNT` changes on #1992.

### 2. Active paid Claude API run #1463 (`work/issue-1463-opus`): spending paid tokens and GPU work on two already-merged look items (`SG` and `PL`)
- **What is wrong:** Issue #1463 started on the paid `opus` API arm at `12:36Z`, one minute after PR #1786 merged. Its current `THIS IS THE JOB NOW` body still orders all four look sheets:
  1. `1. SG: sun glints on metal hulls`, citing pre-V2 `world_sky.gd` and `look.gd`, even though merged PR #1863 (R433) and merged PR #1786 (Ship Exteriors V2, `12:35Z`) already replaced that specular/IBL lighting path.
  2. `2. PL: the 8K rocky board planet`, claiming `"install_rocky() has no caller"`, even though PR #1776 already merged `install_rocky()` live on `main` at `05:10Z` (flagged by Artoo in comment `7122968180` at `05:27Z`, which the API runner ignores under R281).
  Only items `3. ER` (Eclipse revive) and `4. AB` (ability effects) are still unbuilt.
- **Evidence (OBSERVED):** REST `issues/1463` body (`1. SG: sun glints...`, `2. PL: the 8K rocky board planet... install_rocky() has no caller`); issue #1463 comment `7122968180` (Artoo, `05:27Z`) and runner start comment (`12:36Z`); PR #1776 merged `05:10Z` and PR #1786 merged `12:35Z`.
- **Suggested fix:** Stop or trim #1463's next pass to `ER` and `AB` only, marking `SG` and `PL` superseded by merged PRs #1786 and #1776 in the issue body.

### 3. Systemic PC runner bug (`tools/pc/work_issue.ps1:468-469`) strips explicitly allowlisted `.import` files, breaking PR #1986 (`#1360` Storm lightning) right after PR #1961 (`#1779`)
- **What is wrong:** `tools/pc/work_issue.ps1:468-469` (used by both `work_issue.bat` and `codex_issue.bat:189`) unconditionally rejects every added or modified `.import` file:
  `if ($lp.EndsWith('.import') -and $st -eq 'M') { return ... }` and `if ($lp.EndsWith('.import') -and $st -eq 'A') { return 'a new .import file (Godot makes these)' }`.
  That check ignores explicit `.gitignore` allowlists (`!**/*.png.import` / `!**/*.glb.import`). It already stripped all 6 `godot/assets/luts/*.png.import` files on PR #1961 (`#1779` run 2, forcing manual commit `4ce74de7`, Artoo `7127752756`). It just happened a second time on **PR #1986** (`work/issue-1360-opus` @ `5087a901`): `tools/blender/vfx/bake_storm_bolts.py` wrote all 3 `godot/fx/atlases/storm/bolt_{a,b,c}.png.import` files (`fix_alpha_border=false`, `mipmaps/generate=true`) and added `godot/fx/atlases/storm/.gitignore` (`!**/*.png.import`), yet the runner stripped all 3 `.png.import` files before commit! Without them, Godot defaults to `process/fix_alpha_border=true` (corrupting the packed linear RGB core/fork/near-glow channels wherever far-glow alpha `A == 0`) and `mipmaps/generate=false` (Artoo `7131705787`). This will hit `#1943` run 2 (`*.glb.import`) and any future linear atlas job unless fixed globally (`RULEBOOK 2.10`).
- **Evidence (OBSERVED):** `tools/pc/work_issue.ps1:468-469`; `tools/pc/codex_issue.bat:189`; PR #1986 diff (`godot/fx/atlases/storm/.gitignore` allows `!**/*.png.import`, `bake_storm_bolts.py` emits `.png.import`, yet 0 `.png.import` files exist in `5087a901`); PR #1986 comment `7131705787`; PR #1961 comment `7127752756`.
- **Suggested fix:** Update `tools/pc/work_issue.ps1:468-469` so a `.import` file is allowed whenever `git check-ignore -q <path>` returns non-zero (meaning `.gitignore` explicitly un-ignores it for checked-in import settings). Commit the 3 `bolt_{a,b,c}.png.import` files on PR #1986, and add a `storm_bolt_check.gd` assertion checking that all 3 `.png.import` files exist with `fix_alpha_border=false` and `mipmaps/generate=true`.

### 4. Active Codex Lane D run #1995 (`codex/issue-1995`, Faster battle start): brief invites an unsafe hull-cut cache across ships
- **What is wrong:** Issue #1995 started on Codex Lane D at `13:05Z`. Its body asks to reuse cut results across ships of the same hull class to speed up battle start. As Artoo warned at `13:12Z` (`7132511996`), `godot/fx/fx_death.gd:1399-1436` keys cuts on per-ship `hash(s.id) + 3` seeds, current `mi.global_transform` pose, and damaged hull geometry, so sharing cuts across ships of the same hull class will put wrong seeds, stale poses, or mismatched damage onto other ships. In addition, `_lanes_lock` at `godot/fx/fx_death.gd:1754-1767` exists specifically to keep worker lanes from starving Jolt physics during active play. Because Lane D cannot read comments posted after launch (R281), check the resulting PR diff for both hazards before passing it.
- **Evidence (OBSERVED):** REST `issues/1995` body and comment `7132511996` (Artoo, `13:12Z`); `godot/fx/fx_death.gd:1399-1436, 1754-1767`.
- **Suggested fix:** When PR #1995 opens, verify it does not reuse another ship's seeded/posed/damaged cut across ships (or only shares pure immutable hull-mesh prep) and preserves the `_lanes_lock` Jolt physics guard during combat frames.

### 5. Unfixed bug in Board-passed PR #1980 (`codex/issue-1974` @ `a3fd7125`): zero-damage standalone `crit` or `ion` hit leaves a permanent hull wound
- **What is wrong:** In PR #1980 (`godot/fx/fx_weapons.gd:2074-2090`), `standalone_hit` guards entry with:
  `if not hull_damage and not shield_contact and not ion and not bool(hit["crit"]): return`
  When a standalone hit has `hull == 0` and `shield == 0` (for example, Filed Armor reducing a critical hit's hull damage to 0 in `godot/rules/rules.gd:3409-3418`, or a zero-damage ion effect), `shield_contact` is `false`, so execution falls through to `_target(..., force_shield=false)` and `_impact()`, scorching a permanent hull wound mark onto an undamaged hull. Artoo flagged this at `12:10Z` (`7131064528`), and the Board posted PASS at `12:26Z` (`7131444562`) without addressing or answering Artoo's comment (`RULEBOOK 2.7`).
- **Evidence (OBSERVED):** `git diff origin/opus/issue-1434...origin/codex/issue-1974 -- godot/fx/fx_weapons.gd` (`standalone_hit` lines 2074-2090); PR #1980 comments `7131064528` (Artoo) and `7131444562` (Board PASS).
- **Suggested fix:** Only call `_impact()` / hull wound stamping when `hull_damage` is true (or route zero-damage `ion` to an ion flash only, and return early on zero-hull zero-shield `crit`); add a regression check in `standalone_hit_check.gd` before merging #1980 after #1445.

### 6. GPU queue pin skew on `LOAD35` (PR #1445) and `opus1939b` (PR #1983), unfixed TAA bug on PR #1445, and unreviewed GPU heads (R407)
- **What is wrong:** Three GPU-line problems right in front of the PC queue:
  1. **`LOAD35` (PR #1445, `opus/issue-1434`) pinned to conflicted `9c015f43` + unfixed TAA restart bug:** `LOOP.md:83` queues `LOAD35` at `9c015f43`, which conflicts with `main` after PR #1984 (Artoo `7132126550`). PR #1445 already merged `main` cleanly at green **`81368f70`** (no review comment on `81368f70` yet). Separately, Artoo's bug on `title.gd:553-558` (`7131859574`: toggling TAA in settings restarts the title backdrop even though `battle.gd:543-560` deliberately ignores TAA in backdrop mode) is still unfixed in `81368f70`.
  2. **`opus1939b` / `PC_B` (PR #1983, `opus/issue-1939`, planets) pinned to buggy `62590eb4`:** `LOOP.md:83` pins `opus1939b` to `62590eb4`, which carries Artoo's cloud-thickness scale bug (`7131735129`: `(cloud - c_sun)` mixes reshaped and raw cloud density). PR #1983 already pushed `cc22349be` (fixing that bug and skipping faded octaves) and green **`6eb7f1f95`** (Terran pass 3 for Ryan, 0 review comments on `6eb7f1f95`).
  3. **Queued/running GPU PRs without a review comment on their latest code head (`RULEBOOK 3.12` / R407):** running `WRECK5d` (**PR #1737** @ `dbc79f32`, smallest-enclosing-circle `_hex_fit` answering Artoo `7130280292`; math diff looks sound), running `1582 RUN7` (**PR #1874** @ `867efa81`, `stage2_shots.gd` fix after Artoo `7130177964`), plus queued **PR #1755** (`7eb04d11`), **PR #1763** (`59503332`), **PR #1725** (`3f32695b`), **PR #1858** (`0a95e335`), **PR #1910** (`b103606c`, 0 comments), **PR #1925** (`6cd6be42`), and freshly pushed **PR #1784** (`f808d7a99`, CI running) and **PR #1904** (`019d3f46f`, CI running).
- **Evidence (OBSERVED):** `contrib/opus/LOOP.md:83`; PR #1445 head `81368f70a` (`All checks: success`, job `138471371215`) and comments `7131859574`, `7132126550`; PR #1983 head `6eb7f1f95` (`All checks: success`, job `138470617949`) and comment `7131735129`; REST `pulls/<N>.head.sha` vs `issues/<N>/comments` on all 33 open PRs.
- **Suggested fix:** Repin `opus1939b` to `6eb7f1f95` and `LOAD35` to `81368f70` (or fix `title.gd:553-558` first if `LOAD35` has not started), and log brief head-delta reviews on the unreviewed GPU heads before each capture runs.

### 7. PR #1904 (`opus/issue-1877` @ `019d3f46f`, Acid Thorns): carryover `build_b` launcher bug in `OPUS1877_ACID_THORN.bat:10-11`
- **What is wrong:** Just like the earlier Chorus-close bat flagged in the 1926 audit (Item 2), the renamed launcher `tools/pc/jobs/OPUS1877_ACID_THORN.bat:10-11` sets `LB_ARGS=--part moments --moments res://bench/look_moments_acid_thorn.json` and calls `"%VT%\build_b\tools\pc\jobs\look_bench.bat" origin/opus/issue-1877 none`. On `main` (`5524078e2`), `tools/pc/jobs/look_bench.bat` still has **no** `LB_ARGS` support and copies only `look_moments.json` (not `look_moments*.json`), because those edits live only on unmerged PR #1904. Running `OPUS1877_ACID_THORN.bat` against `build_b` before `look_bench.bat`'s `LB_ARGS` plumbing merges to `main` will silently ignore `LB_ARGS` and run the whole default bench (code mismatch OBSERVED; whether any hand-written PC queue bat bypasses this is INFERRED/not checked).
- **Progress noted:** `019d3f46f` (pushed `13:23Z`) fixed the missing `godot_checks.txt` registration for `acid_thorn_check.gd`; wait for its running CI jobs to go green before running any GPU capture.
- **Evidence (OBSERVED):** `git show origin/opus/issue-1877:tools/pc/jobs/OPUS1877_ACID_THORN.bat` lines 10-11; `git show origin/main:tools/pc/jobs/look_bench.bat` (`LB_ARGS` absent); `git show 019d3f46f` (`godot/tools/ci/godot_checks.txt` +1 line).
- **Suggested fix:** Either invoke `opus/issue-1877`'s own `look_bench.bat` (or merge the tiny 5-line `LB_ARGS` / `look_moments*.json` plumbing from `tools/pc/jobs/look_bench.bat` to `main` and refresh `build_b` first).

### 8. PR #1998 (`opus/issue-1791` @ `caa68b4de`, small teaching station) is non-draft and missing `[HOLD]` while carrying all 12 files of unmerged PR #1772 (`PROPS_P`)
- **What is wrong:** PR #1998 is green and non-draft with no `[HOLD]` in its title and 0 comments, yet it branches from PR #1772 (`opus/issue-1767`) and carries all 12 of PR #1772's unmerged files (`battle.gd`, `board.gd`, `static_caches.gd`, `a4_props.gd`, `blocker_visuals.gd`, `look_bench.gd`, `RULEBOOK.md`, `FINDINGS.md`, `global_cohesion_standard.md`, tests). Merging PR #1998 first would silently land PR #1772 ahead of `PROPS_P` and Ryan's look. Similarly, **PR #1975**, **PR #1976**, and **PR #1980** target `main` carrying all 39 files of unmerged PR #1445 with no `[HOLD]` in their titles (relying only on Board hold comments).
- **Evidence (OBSERVED):** REST `pulls/1998` (`draft: false`, 0 comments, 13 files: 12 identical to PR #1772 + `tools/blender/kits/hegemony_station/outpost.py`); REST `pulls/{1975,1976,1980}` (`draft: false`, titles without `[HOLD]`, 39 files shared with PR #1445).
- **Suggested fix:** Add `[HOLD: stacked on PR 1772]` (or switch to Draft) on PR #1998 until PR #1772 merges, and add `[HOLD: stacked on PR 1445]` to PRs #1975, #1976, and #1980 titles.

### 9. Three real defects already merged into `main` since `60bdaed5` (PRs #1913, #1949, #1959) plus dropped Vigil turret scope when #1685 closed
- **What is wrong:** Four unfixed items from PRs merged since `60bdaed5` (verified on `origin/main` `5524078e2`):
  1. **`godot/campaign/campaign.gd:3536-3551` (PR #1913, Wave 2 D5):** Spread Pattern torpedo splash kills (`godot/rules/rules.gd:2827-2833`) set `killCause = "big"` on neighbor ships without naming those neighbors in the torpedo hit log line, so `_heavy_wreck_cause`'s reverse text search can still miscredit an earlier weapon hit on the reward card (Artoo `7119253355`, carried from 1926 Item 4).
  2. **`godot/tools/picture_provenance.gd:127-128` (PR #1949, Picture stamp):** `_pre_merge()` returns `false` solely when `git merge-base --is-ancestor <sha> main` succeeds and never checks `record.get("source_dirty", false)`, so a capture taken on a dirty `main` checkout is still stamped `"installed in game"` instead of pre-merge (Artoo `7123643915`).
  3. **`godot/fx/fx_idle.gd:180-188` (PR #1959, Living ships):** the comfort check sums `1.0 / period` (long-run average rate) instead of checking worst-case simultaneous starts inside any 1-second window (Artoo `7125579753`).
  4. **Dropped Vigil (`V16_37`) turret scope on closed issue #1685 (PR #1959):** Issue #1685 explicitly included `"the missing turrets on Vigil and Flare"`. PR #1959 only shipped the idle motions and closed #1685. Flare (`D20_23`) is tracked by #1422, but Artoo (`7126244005`, post-merge) noted **no open hull-rebuild issue tracks the missing Vigil (`V16_37`) turret** (#1145 is a Muse concept-sheet issue, not a Vigil rebuild/export issue).
  *(Verified NOT a bug on `main`: `LOOK._fit_cache` in `godot/render/look.gd:181` IS cleared via `ShipView.clear_look_cache()` after PR #1786 merged.)*
- **Evidence (OBSERVED):** `godot/campaign/campaign.gd:3536-3551` and PR #1913 comment `7119253355`; `godot/tools/picture_provenance.gd:127-128` and PR #1949 comment `7123643915`; `godot/fx/fx_idle.gd:180-188` and PR #1959 comments `7125579753`, `7126244005`; REST `issues/1685` (`state: "closed"`), `issues/1145` (`labels: ["muse"]`).
- **Suggested fix:** File one short follow-up issue (or add to the next small Codex sweep) for the three small code fixes (`campaign.gd`, `picture_provenance.gd`, `fx_idle.gd`), and open a tracking note or issue for the missing Vigil (`V16_37`) turret so it is not lost.

---

## Priority 1: Morning Picks Brief Gaps, Unclosed Issues, Queue Problems, and Governance Drift

### 10. Ryan's morning picks (`#1943`, `#1988`, `#1990`, `#1991`): missing files in `#1990`, unlabelled shelf state on `#1943` and `#1988`, wrong path in `#1991`
- **What is wrong:** Checking all six morning-pick issues (`1943`, `1988` shelved on purpose; `1989`, `1990`, `1991`, `1992` new):
  1. **Issue #1990 (`opus`, Story, queued NEXT on the PC `opus` API arm after #1463):** its brief tells the worker to read two paths that **do not exist on `main`**: `docs/shots/issue-1887-codex/sable.png` (exists only on unmerged PR #1896 / PR #1903, and PR #1903's clean copy is `contrib/codex/portraits_v1/sable.png`) and `board/review_1124/fable_lore_holistic.md` (a Claude Project file outside the git repository, unreachable by the PC API arm).
  2. **Issues #1943 and #1988 (shelved on purpose by Ryan, `LOOP.md:83`):** neither issue body says it is shelved or parked in the backlog. `#1943` still opens with `## THIS IS THE JOB NOW (run 2, Board Nov 24 2026)` ordering the `sonnet` arm to build 3 torpedo GLBs, and `#1988` opens with `## THIS IS THE JOB NOW (run 1)` quoting `"Actually build and incorporate the torpedoes now."` (and `#1988`'s `codex` + `blocked` labels look identical to a normal queued Codex job). Any operator reading the board without `LOOP.md` could easily dispatch either one.
  3. **Issue #1991 (`codex, blocked, running`, active on Codex):** fixed block and body cite `godot/render (faction_looks.json)` instead of the real path `godot/fx/faction_looks.json` (minor; Codex will locate the file, worth noting if a run 2 is ever needed).
- **Evidence (OBSERVED):** REST `issues/{1990,1943,1988,1991}` bodies; `git ls-tree origin/main docs/shots/issue-1887-codex/sable.png` (empty) and `git ls-tree origin/main board/review_1124/fable_lore_holistic.md` (empty); `git ls-tree origin/main godot/fx/faction_looks.json` (exists, `godot/render/faction_looks.json` does not); `contrib/opus/LOOP.md:83`.
- **Suggested fix:** Before starting #1990 on the `opus` API arm, paste the needed Fable lore excerpts directly into #1990's body (or commit the review doc to `contrib/` on `main`) and remove or fix the missing `sable.png` path. Add a top-line `SHELVED (Ryan, Nov 24 2026)` banner (removing `THIS IS THE JOB NOW`) on both #1943 and #1988.

### 11. Merged or delivered work whose issues or PRs are still open (`#1692`, `#1777`, `#1779`, `#1936`/PR `#1993`, `#1989`/PR `#1996`)
- **What is wrong:** Five issues/PRs have landed or delivered without being closed or updated (`RULEBOOK 2.4` / R288):
  - **Issue #1692 (`blocked, codex`):** PR #1758 merged at `12:44Z`, yet #1692 is still open with no remaining scope.
  - **Issue #1779 (`blocked, codex`):** PR #1961 merged at `10:28Z`, yet #1779 is still open with its stale `run 2` brief (`"Commit the six .png.import files"`) at the top; only the GPU capture `opus1779fx` remains.
  - **Issue #1777 (`opus`):** PR #1786 (`12:35Z`) and PR #1861 (`12:36Z`) both merged; only the green 1-file manifest publish **PR #1987** (`opus/issue-1777-pub`, GV2/GW4 hashes) remains open.
  - **Issue #1936 (`neon, running`) + PR #1993 (`43706b722`, green):** already routed in `LOOP.md:83` (into #1995), yet PR #1993 is still open and #1936 still carries `running`. Note Artoo `7132160032` before merge: `performance_1124.md:83-85` cites the older 1.6 s pre-LUT cold-load baseline instead of 385 to 423 ms.
  - **Issue #1989 (`neon, running`) + PR #1996 (`acec5286c`, green):** Wave M1 music notes delivered and green; ready for Board review/merge and clearing `running`.
- **Evidence (OBSERVED):** REST `issues/{1692,1777,1779,1936,1989}` (`state: "open"`); REST `pulls/{1758,1786,1861,1961}` (`merged_at` on Nov 24); REST `pulls/{1987,1993,1996}` (`All checks: success`); PR #1993 comment `7132160032`.
- **Suggested fix:** Close #1692 now; update #1779's body to note PR #1961 landed (awaiting `opus1779fx` only); close #1777 in the same step as merging PR #1987; review/merge PR #1993 and PR #1996 and close #1936 / #1989 (clearing `running`).

### 12. Stale governance docs and rulings drift (R414 vs #1992, `FINDINGS.md`, `RULEBOOK.md`, `LOOP.md`)
- **What is wrong:** Several binding documents contradict rulings that already landed or are actively running:
  1. **R414 vs #1992 equal-win-rate target:** `contrib/opus/FINDINGS.md:442` (R414) and `docs/playbooks/balance.md:16-39` still mandate staggered per-faction win-rate targets (`Sunward Crusade 50%..`, `Chorus 38%..`), contradicting #1992's new target (`"every faction wins about the same at each difficulty"`). `LOOP.md:83` says FINDINGS gets the new row on #1992's merge; make sure #1992's PR also updates `docs/playbooks/balance.md:16-39` in the same PR (`RULEBOOK 0.2` / R214). (Confirmed no other open issue besides #1992 and #1994 references R414.)
  2. **`contrib/opus/FINDINGS.md:466` (R441):** still says `"waits on PR 1861"` even though PR #1861 merged at `7c542ab89` (`12:36Z`). R428/R429 (Neon in T3 Code / auto-approve) still have zero mentions in `docs/RULEBOOK.md`.
  3. **`docs/RULEBOOK.md`:** line 275 still says `"AI rules in battle.js and rules.gd together"` (contradicts R405); line 308 still says `"The balance simulator (node sim3d.js) plays the frozen browser rules, so it measures nothing new until its Godot port (issue 1656) lands"` (PR #1946 landed the Godot full-run balance sim at `06:18Z`!); line 539 still states `"walls at most 0.11 linear"` (R448 Glasswright pale-pearl `0.45` update waits on PR #1755, whose `global_cohesion_standard.md:58` is already updated).
  4. **`contrib/opus/LOOP.md`:** line 29 still says `"battle.js and rules.gd together"` (Artoo `7123659736` on PR #1951); lines 46-47 still say API arms are `OFF until Nov 21` and Codex is `paused (R342)`; line 83 says PR #1784 is `"on green"` (it was red at `e92b6687` and is currently running CI at `f808d7a99`).
- **Evidence (OBSERVED):** `contrib/opus/FINDINGS.md:442, 466`; `docs/playbooks/balance.md:16-39`; `docs/RULEBOOK.md:275, 308, 539`; `contrib/opus/LOOP.md:29, 46-47, 83`; PR #1951 comment `7123659736`.
- **Suggested fix:** Land the R414 replacement in both `FINDINGS.md` and `docs/playbooks/balance.md` with #1992's PR; update R441 to `"Landed (PR 1861)"`; fix `RULEBOOK.md:275, 308` and add R428/R429; update `LOOP.md:29, 46-47`.

### 13. Queue tracking and hygiene items carried over from 1926 (plus items confirmed clean)
- **Still open from 1926:**
  1. **Three active GPU-line items still lack open tracking issues, and #1908 still has no GPU slot:** `WRECK5d` (PR #1737) has closed `#1236`; `WAVE1B3` has closed `#1691`; `C14` has closed `#1155`/`#1683` while `#1291` covers only `C10 to C13`. Issue **#1908** fixed its `Branch:` to `opus/issue-1908`, yet still has no slot in the Board's GPU queue after `JOINT_G`.
  2. **Split ownership on `#1877` / PR `#1881`:** green PR #1881 (`muse/issue-1877`) is still unmerged with its wrong `"Issue 1854: PC checks"` body (`7112202634`), and issue #1877 still carries only the `muse` label while Opus builds Acid Thorns in PR #1904.
  3. **Stray files on PR #1903 + superseded PR #1896 / issue #1887 still open:** PR #1903 still carries 9 out-of-scope files (7 from unmerged PR #1896 + 2 in `docs/shots/issue-1897-codex/`, Artoo `7116669639`), and #1896 / #1887 remain open.
  4. **Placeholder `Branch:` lines and stale issue briefs:** 26 open `opus`/`muse` issues still carry `Branch: opus/issue-<this>` / `<this number>` / `<number>` placeholders, `#1239` still lacks a fixed block, and 7 open issues still contradict newer rulings (`#1582` + PR `#1874` title say `"arcing munitions"` vs R435; `#1764` says multi-crystal vs R434/R445; `#1145`, `#1146`, `#1453`, `#256` cite retired JS twins vs R405; `#1153` cites `"tendril"` vs R437).
- **Confirmed CLEAN on this sweep:** Zero open `codex` issues are missing `blocked`; zero open issues have more than one `Base:` line; zero closed issues retain the `running` label (all 7 from 1926 were cleared); zero PC-runner issues have more than one `THIS IS THE JOB NOW` line (only #1994 quotes the phrase in prose); zero running issues have gone stale without a live active lane.
- **Evidence (OBSERVED):** Full scan of all 80 open issues and 200 recent closed issues via REST (`issues_open.json`, `issues_closed.json`), PRs #1881, #1896, #1903, #1904, and `LOOP.md:83`.
- **Suggested fix:** Add #1908 right after `JOINT_G` in the GPU queue; fix PR #1881's body and merge it (switching #1877 to `opus`); strip the 9 stray files from PR #1903 and close #1896/#1887; add short tracking notes for `WRECK5d`, `WAVE1B3`, and `C14`.

---

## Priority 2: Lost Work, Unmerged Branches, Closed PRs, and Stale Open PRs

### 14. Remote branches with commits ahead of `main` and no open PR, plus closed-unmerged PR check
- **Unmerged branches with no PR:**
  - `origin/neon/holistic-and-looks-1123` (`1faa0fa71`, Nov 23): 363 lines of Nov 23 review docs (`combined_fable_astra_review_1123.md`, `holistic_game_audit_1123.md`) still not archived on `main`.
  - `origin/codex/issue-1648` (`57ee0cacd`): 148-line `contrib/codex/reviews/pr_1643_review.md`, no PR.
- **Verified NOT lost:**
  - `origin/opus/wip-1519-sliced` (`7fc1efd74`, flagged in 1926 Item 14): now picked up into open Codex **PR #1950** (`codex/issue-1519`, currently red and conflicted on `main` while waiting for PR #1445).
  - `origin/opus/issue-1560` (`175496d8d`): PR #1564 (`"merged": true`, Nov 22 01:32Z) already landed on `main` (stale branch left behind).
  - `origin/claude/project-thread-kzjmk5` (`JOINT_G` stack pin; its `interior_kit.py` fixes are in PR #1763 `59503332`), `origin/claude/project-thread-q7nudv` (`WRECK5d` pin), `origin/claude/project-thread-lnk6bv` (`WAVE2AB2` pin), and `origin/opus/issue-1415-sat` (0-file diff vs `main`).
- **Closed-unmerged PRs since `60bdaed5`:** Only **PR #1720** (`opus/open-work-nightly`, closed `05:35Z` intentionally when PR #1951 retired `OPEN_WORK.md`). Zero lost code from closed PRs.
- **Evidence (OBSERVED):** Local `git branch -r` scan against `origin/main` + open PR heads; REST `pulls/1564` (`merged: true`); REST `pulls?state=closed` since `03:40Z`.
- **Suggested fix:** Decide whether to archive `neon/holistic-and-looks-1123` and `codex/issue-1648` or delete those stale branches; after PR #1445 merges, rebase PR #1950 (`#1519`) cleanly onto `main`.

### 15. Ready or stale open PRs to act on (`#1964`, `#1987`, `#1993`, `#1996`, `#1881`, `#1833`, `#1442`, `#1718`, `#1163`)
- **Ready / near-ready green PRs:**
  - **PR #1987** (`opus/issue-1777-pub` @ `40b0b0255`, green, 1 file `godot/assets/ships/manifest.json`): GV2/GW4 manifest publish; review and merge once GV2/GW4 publish finishes, then close #1777.
  - **PR #1964** (`codex/issue-1406` @ `dfa5e5aa6`, green, 1 file): Council ships-read-at-camera follow-up; review and merge.
  - **PR #1993** (`neon/issue-1936`, green) and **PR #1996** (`neon/issue-1989`, green): Neon reports ready for Board merge/close (Item 11).
  - **PR #1881** (`muse/issue-1877`, green): fix wrong PR body and merge (Item 13).
- **Stale/red PRs still open from earlier audits:**
  - **PR #1950** (`codex/issue-1519`, RED on `All checks` and 3 conflicts with `main`): hold for PR #1445, then rerun/rebase.
  - **PR #1833** (draft Nov 23 review pack, do not merge) and **PR #1442** (draft blocked #1439, touches `main.gd`): close drafts unless still linked.
  - **PR #1718** (`muse/issue-1572`, RED on `Standing checks`, overtaken by #1752) and **PR #1163** (`muse/issue-1145`, RED on `Standing checks` + `Godot game checks`, 1,940 commits behind `main`): close or decide disposition.
- **Evidence (OBSERVED):** REST `pulls/{1987,1964,1993,1996,1881,1950,1833,1442,1718,1163}` check runs and status.
- **Suggested fix:** Merge the clean ready PRs (`#1987`, `#1964`, `#1993`, `#1996`, `#1881`) and close the stale unmergeable PRs (`#1833`, `#1442`, `#1718`, `#1163`).

---

## Priority 3: Merge Clashes Between Open PRs and Safe Merge Order

Verified against `origin/main` (`5524078e2`) using `git merge-tree --write-tree` and pairwise file-overlap analysis across all 33 open PRs.

### Six Open PRs Currently Conflict with `main` (OBSERVED via `git merge-tree`)
1. **PR #1852** (`codex/issue-1843`, `[HOLD]`, 13 conflicting files: `fx.gd`, `board.gd`, `line_style.gd`, `ship_view.gd`, `squadron_craft.gd`, `squadron_wing.gd`, `static_caches.gd`, `battle.gd`, `godot_checks.txt`, `world_bake.gd`, `world_living.gd`, `world_planet.gd`, `world_rocks.gd`): old PR #1445 ancestor. Rebase after PR #1445 merges.
2. **PR #1960** (`codex/issue-1780`, Board CHANGES, 11 conflicting files: `board.gd`, `line_style.gd`, `squadron_craft.gd`, `squadron_wing.gd`, `static_caches.gd`, `battle.gd`, `nebula_hulls.gd`, `world.gd`, `world_living.gd`, `world_rocks.gd`, `world_sky.gd`): also partially superseded by PR #1967 (`shader_cache.gd` on `main`). Rebase after PR #1445 merges.
3. **PR #1950** (`codex/issue-1519`, RED on `All checks`, 3 conflicting files: `fx.gd`, `main.gd`, `battle.gd`): holds until PR #1445 merges.
4. **PR #1975** (`codex/issue-1971`, 3 conflicting files: `static_caches.gd`, `battle.gd`, `godot_checks.txt`): stacked on older PR #1445 head.
5. **PR #1976** (`codex/issue-1970`, 3 conflicting files: `static_caches.gd`, `battle.gd`, `godot_checks.txt`): stacked on older PR #1445 head.
6. **PR #1980** (`codex/issue-1974`, 3 conflicting files: `static_caches.gd`, `battle.gd`, `godot_checks.txt`): stacked on older PR #1445 head.

*(Routine CI list conflict: 14+ open PRs append to `godot/tools/ci/godot_checks.txt` and will need trivial rebases as each merges.)*

### Real Code/Doc Clash Pairs Between Open PRs (OBSERVED from local diffs)

| Cluster | PR Pair | Conflicting Files and Regions | Safe Merge Order and Why |
|---|---|---|---|
| **1. Engine Backbone (CRITICAL)** | **#1445** vs **#1975, #1976, #1980, #1852, #1950, #1960** | 39 shared files with `#1975`/`#1976`/`#1980`; 28 with `#1852`; 17 with `#1960`; 4 with `#1950` (`main.gd`, `battle.gd`, `fx.gd`, `static_caches.gd`) | **#1445 first** (after `LOAD35` on green `81368f70`), then merge `main` into `#1975`, `#1976`, `#1980` and rebase `#1852`, `#1950`, `#1960`. |
| **2. Wreck Fallback Rewrite (KNOWN CLASH)** | **#1772** (and **#1998**) vs **#1976** | `godot/scenes/battle/battle.gd` (`_lay_wreck` fallback callback: `#1772` L1826-1836 passes live `views[unit].fac`; `#1976` L2332-2356 replaces `create_timer` with `_await_fx` + `wreck_settled` guards) | **#1772** -> **#1998** -> **#1976** (or **#1445 -> #1976** then merge `main` into **#1772**); either way, the second merge MUST keep BOTH `#1976`'s `_await_fx`/guards AND `#1772`'s `views.get(unit).fac` argument to `board.add_wreck(..., fac)` (Artoo `7131767264`). |
| **3. Storm Lightning Timing (NEW CLASH)** | **#1976** vs **#1986** | `godot/world/world_living.gd` (both edit storm bolt timer / `_process` clock and `_bolts`) | **#1986** (after fixing the 3 missing `.png.import` files, Item 3) -> **#1976** (merging `main` into `#1976` so paced `clock` drives the new baked storm bolts, Artoo `7131705787`), or `#1976` first then rebase `#1986`. |
| **4. Station Stack (UNMARKED)** | **#1772** vs **#1998** | 12 identical files (`battle.gd`, `board.gd`, `static_caches.gd`, `a4_props.gd`, `blocker_visuals.gd`, `RULEBOOK.md`, `FINDINGS.md`, `look_bench.gd`) | **#1772 first** (after `PROPS_P`), then **#1998** (Item 8). |
| **5. Wounds + Interiors Stack** | **#1763** vs **#1755** vs **#1997** (draft) | `#1763 <-> #1755`: `godot/fx/faction_looks.json` (`ithar` block, both set `wall_max: 0.45`); `#1755 <-> #1997`: 15 stacked files (`fx.gd`, `fx_death.gd`, `fx_hull.gd`, `fx_ship.gd`, `faction_looks.json`, `RULEBOOK.md`) | **#1763** -> **#1755** (keeping combined `faction_looks.json`) -> **#1997** (after `JOINT_G` and `opus1741defa` pictures). |
| **6. Planet Shimmer vs Planet Detail** | **#1975** vs **#1983** (and **#1445**) | `godot/world/world_planet.gd`, `godot/world/world_shaders.gd`, `godot/world/test/planet_v2_check.gd` | **#1983** (after `opus1939b` on `6eb7f1f95`) -> **#1445** -> **#1975** (keeping `#1983`'s cloud/terrain pass 3 and `#1975`'s shimmer fix together). |
| **7. Death & Cut Pipeline** | **#1737** vs **#1755** vs **#1858** vs **#1997** (and active **#1995**) | `godot/fx/fx_death.gd` (all 4 + `#1445`), `docs/playbooks/deaths_and_hits.md` (`#1737`, `#1858`, `#1997`) | **#1445** -> **#1737** (`WRECK5d`) -> **#1755** -> **#1997** -> **#1858** (`1394J`); merge `#1995` after `#1445` (and re-check `fx_death.gd` against `#1737`/`#1755`). |
| **8. Weapons & Ship FX** | **#1784** vs **#1874**, **#1755**, **#1980**, **#1904** | `godot/fx/fx_weapons.gd` (`#1755`, `#1784`, `#1874`, `#1904`, `#1980`), `godot/fx/fx_ship.gd` (`#1445`, `#1755`, `#1784`, `#1975`/`#1976`/`#1980`), `godot/fx/fx_shaders.gd` (`#1755`, `#1784`, `#1858`) | **#1874** (`1582 RUN7`) and **#1784** (once `f808d7a99` turns green) -> **#1980** (after Item 5 fix + `#1445`) -> **#1755** -> **#1904** (only after Ryan's pick). |
| **9. Blind Warden Pair** | **#1910** vs **#1925** | Both target `game_code: V14_23` and edit `docs/ship_pipeline/FLEET.md` | **Hold both**; merge at most one only if Ryan picks it over shipping S9. |
| **10. Portrait Trial vs Production** | **#1896** vs **#1903** | 7 identical files (`portraits_test/*`, `docs/shots/issue-1887-codex/*`) | Close **#1896** unmerged; strip its 7 files (and `docs/shots/issue-1897-codex/`) from **#1903**. |

**Recommended merge backbone:**
1. **Immediate zero-conflict merges:** `#1987` (GV2/GW4 manifest), `#1964` (`#1406`), `#1993` (`#1936`), `#1996` (`#1989`), `#1881` (after body fix), `#1983` (after `opus1939b` on `6eb7f1f95` + head review).
2. **Engine backbone:** `#1445` (after `LOAD35` on `81368f70` + `title.gd` TAA check), then bring `main` into `#1975`, `#1976`, `#1980` (with Item 5 fix), and rebase `#1950`, `#1852`, `#1960`.
3. **World, Storm, and FX wave:** `#1986` (after committing the 3 `.png.import` files), `#1772` (`PROPS_P`, preserving `#1976` `_lay_wreck` contract) -> `#1998`, `#1737` (`WRECK5d`), `#1874` (`1582 RUN7`), `#1784` (once `f808d7a99` is green), `#1858` (`1394J`), `#1725` (`H7N`).
4. **Interiors + Wounds pack:** `#1763` -> `#1755` -> `#1997` (after `JOINT_G` and `opus1741defa`).

---

## Recheck of the 1926 Audit (`work_audit_1124.md`)

| 1926 Item | Topic | Status | Evidence (OBSERVED) |
|---|---|---|---|
| **1** | PR #1925 (`Astra 1889 S9A`) red `FLEET.md`, out-of-scope shots, 404 link, missing `[HOLD]` | **FIXED** | PR #1925 at `6cd6be42` has `[HOLD]` in title, updated `FLEET.md` (`All checks: success`), moved shots into `contrib/codex/warden_astra_1124/shots/`, and fixed `REPORT.md:17` links (needs head review comment before `Astra 1889`, Item 6). |
| **2** | PR #1904 (`1877`) `build_b` `look_bench.bat` `LB_ARGS` bug + unreviewed head | **OPEN** | Renamed `OPUS1877_ACID_THORN.bat:10-11` still calls `%VT%\build_b\tools\pc\jobs\look_bench.bat` with `LB_ARGS`, which `origin/main:tools/pc/jobs/look_bench.bat` still lacks; `019d3f46f` just pushed `godot_checks.txt` fix and awaits green CI + review (Item 7). |
| **3** | PR #1929 (`#1907` janitor) `--nightly` bypassed `gpu_solo` deferral | **FIXED** | Fixed and merged at `05:38Z` (PR #1929 closed/merged; `#1907` closed). |
| **4** | PR #1913 (`#1905` Wave 2 D5) red `reward_flow_test` + Spread Pattern splash-kill bug | **FIXED (CI) / OPEN (bug)** | Lane C fixed CI and PR #1913 merged at `05:43Z`, but `godot/campaign/campaign.gd:3536-3551` still uses the reverse log-string search that can miscredit Spread Pattern splash kills (Item 9). |
| **5** | PR #1776 vs PR #1445 `world_bake.gd:clear_static()` conflict + `PC_M` pin skew | **FIXED** | PR #1776 merged at `05:10Z` and PR #1445 merged `main` cleanly (`81368f70`, `CLEAN`, `All checks: success`). |
| **6** | PR #1784 and PR #1852 conflicted with `main` | **FIXED (#1784) / OPEN (#1852)** | PR #1784 merged `main` cleanly (hit a temporary `hull_lift_check` regression at `e92b6687`, just patched in `f808d7a99`, CI running); PR #1852 (`[HOLD]`) still conflicts with `main` in 13 files while waiting for #1445 (Priority 3). |
| **7** | Eight GPU PRs (plus #1910) unreviewed on latest head (R407) | **OPEN (partial)** | PR #1861 merged (`12:36Z`); PRs #1755 (`7eb04d11`), #1763 (`59503332`), #1874 (`867efa81`), #1725 (`3f32695b`), #1858 (`0a95e335`), #1910 (`b103606c`), #1925 (`6cd6be42`), #1737 (`dbc79f32`), #1983 (`6eb7f1f95`), and #1904 (`019d3f46f`) still lack a review comment on their latest head (Item 6). |
| **8** | `WRECK5b`, `WAVE1B3`, `C14` missing open issues; #1908 missing GPU slot + placeholder `Branch:` | **OPEN (mostly)** | Issue #1908 fixed `Branch: opus/issue-1908`, but still has no GPU queue slot; `#1236` (`WRECK5d`), `#1691` (`WAVE1B3`), and `#1155`/`#1683` (`C14`) remain closed (Item 13). |
| **9** | Issue #1911 `THIS IS THE JOB NOW` inside code fence + long quiet runs on #1911 and #1705 | **FIXED** | Both finished and merged cleanly: PR #1938 (#1911, `06:07Z`) and PR #1946 (#1705, `06:18Z`); both issues closed. |
| **10** | PR #1903 carries 9 out-of-scope files; PR #1896 and issue #1887 still open | **OPEN** | PR #1903 (`5c16ab24`) unchanged (23 files); PR #1896 and issue #1887 still open (Item 13). |
| **11** | Issue #1877 (`muse`) and PR #1881 wrong body / split ownership | **OPEN** | PR #1881 (`661a4f6a`) still open with `"Issue 1854: PC checks"` body; issue #1877 still labelled `muse` (Item 13). |
| **12** | Governance docs contradict R405 / R446 (`RULEBOOK.md:275`, `LOOP.md:29, 46-47`, `HANDOFF.md`) | **OPEN (partial)** | PR #1951 (`06:41Z`) retired `OPEN_WORK.md` and refreshed `HANDOFF.md`, but `RULEBOOK.md:275` (plus `:308`) and `LOOP.md:29, 46-47` still carry the stale text (Item 12). |
| **13** | 7 closed issues retained `running`; 29 open issues used placeholder `Branch:` | **FIXED (running) / OPEN (placeholders)** | Zero closed issues now carry `running` (all 7 cleared); 26 open `opus`/`muse` issues still keep literal `Branch: opus/issue-<this>` placeholders (Item 13). |
| **14** | Unmerged `opus/wip-1519-sliced` (no PR) and `neon/holistic-and-looks-1123` | **FIXED (#1519) / OPEN (archive)** | `#1519` now has open Codex PR #1950 (rebased/held for #1445); `neon/holistic-and-looks-1123` (and `codex/issue-1648`) remain unmerged (Item 14). |
| **15** | Unrecorded Glasswright pale-pearl ruling; stale R434/R443; R428/R429 not in `RULEBOOK.md`; R430 D1/D6-D8 & NTFS TEMP unfiled | **OPEN (partial)** | Pale-pearl recorded as **R448** (`FINDINGS.md:473`), and R434/R443 updated to Landed; **R441** is now stale (`waits on PR 1861`), R428/R429 still absent from `RULEBOOK.md`, and R430 D1/D6-D8 + NTFS TEMP remain unfiled (Item 12). |
| **16** | Ready/stale open PRs (`#1928`, `#1930`, `#1902`, `#1720`, `#1833`, `#1442`, `#1718`, `#1163`) | **OPEN (partial)** | `#1928`, `#1930`, and `#1902` merged and `#1720` closed; `#1833`, `#1442`, `#1718`, and `#1163` remain open (Item 15). |
| **17** | Open issues contradicting newer rulings (`#1582`, `#1764`, `#1453`, `#1145`, `#1146`, `#256`, `#1153`, `#1239`) | **OPEN** | All 8 remain unchanged on live GitHub issues (Item 13). |

---

## Not checked:

- **Local PC queue files, live runner logs, and `board/` Claude Project docs:** Read-only audit stayed inside the `t3_neon` Git clone and GitHub REST API (`gh api` REST only). Did not inspect `Downloads\voidsworn_test\queue\`, `build_b\`, `board/review_1124/fable_lore_holistic.md`, or live PC lane logs (Codex lanes B/C/D, API arm #1463, or running `WRECK5d`/`1582 RUN7` logs).
- **Final CI outcomes of just-pushed PR #1784 (`f808d7a99`) and PR #1904 (`019d3f46f`):** Both commits were pushed at 13:22 to 13:23 UTC while this audit closed; their CI jobs were still `in_progress` at snapshot time.
- **Full line-by-line review of large unchanged PR diffs and binary assets:** Audited new/updated code diffs since `60bdaed5` (PRs #1913, #1946, #1949, #1953, #1959, #1961, #1962, #1963, #1967, #1969, #1972, #1981, #1984 and open PRs #1445, #1737, #1755, #1763, #1772, #1784, #1874, #1904, #1975, #1976, #1980, #1983, #1986, #1987, #1997, #1998). Did not audit unchanged Blender mesh build sheets, `.png`/`.glb`/`.jsonl.br` binary blobs, or live Godot/Blender runtime execution.
