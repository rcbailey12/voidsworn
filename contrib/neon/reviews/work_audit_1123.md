# Full Audit of Open, Planned, and Running Work (Nov 23, 2026)

Snapshot taken Nov 23, 2026 around 22:42 to 22:56 UTC via `gh api` REST on `rcbailey12/voidsworn`.
Main head at start of audit: `f2340c9d` (`neon/issue-1898` base); during the audit PR #1782 merged to `main` at `0da3790b` (22:46 UTC, followed by R445 at `844decbd`), leaving **30 open PRs** (26 ready, 4 drafts) and **90 open issues** (#1361 closed with #1782).

**Lead call:** Fix the 6 active blockers before the next GPU runs and merges (PR #1445 just became dirty on `main` right before `LOAD29`; PR #1861 is dirty, red, and has a ribbon-overlap bug; PR #1890 duplicates every 3D ship view on deployment; PR #1876 still has an unfixed Thorne turn-planner bug on a green head; PR #1755 stamps `fx_wreck_t0` at precompute instead of death; issue #1779 was closed by mistake on a docs-only PR, dropping R420's entire Wave C cinematic post-FX track). Then close 9 already-done/superseded issues and 5 dead/superseded PRs, and file the missing issues for R428/R429, R430 (D1, D5 to D8), R437 look-bench clips, and the NTFS hard-link TEMP cleanup.

---

## Priority 0: Immediate Blockers (Active GPU Line, Running Lanes, and Missed Real Bugs)

### 1. PR #1445 (`opus/issue-1434`, queued next as `LOAD29`): just went dirty on `main` AND head `b521b3a1` is unreviewed (R407)
- **What is wrong:** PR #1782 merged at 22:46 UTC (`0da3790b`), immediately making PR #1445 (`b521b3a1`) non-mergeable (`mergeable: false`, `mergeable_state: dirty`) on `godot/world/world_rocks.gd`, `godot/world/world.gd`, `godot/tools/ci/godot_checks.txt`, and `godot/tools/ci/godot_check_times.txt` (PR #1893 also edited `godot_checks.txt`). Separately, the Board's R407 review comment on PR #1445 was on `c331e1a2` (19:24 UTC), before commit `b521b3a1` (21:40 UTC) renamed static `ShipView.hull_res` to `ShipView.hull_path` to clear issue #1410's new field. Neither Artoo nor the Board has reviewed `b521b3a1`.
- **Evidence (OBSERVED):** REST `pulls/1445` at 22:49 UTC returns `mergeable: false, mergeable_state: "dirty"`; `commits/0da3790b` overlaps `godot/world/world_rocks.gd`, `godot/world/world.gd`, `godot/tools/ci/godot_checks.txt`, `godot/tools/ci/godot_check_times.txt`; last review comment on PR #1445 (19:24 UTC) cites `c331e1a2`, while head is `b521b3a1`.
- **Suggested fix:** Hold `LOAD29` if it pins `b521b3a1`, merge `main` (`0da3790b`+) into `opus/issue-1434`, confirm `world_rocks.gd` takes PR #1782's retired crystal factory cleanly (as Artoo noted on #1782), get green checks plus a quick R407 check on the new head, then run `LOAD29`.

### 2. PR #1890 (`codex/issue-1870`, Wave 1 D4 skill target picker, running fix on Lane C): **NEW MISSED BUG** duplicates every 3D ship view on deployment end AND lets HUD buttons fall through during deployment
- **What is wrong:** Separate from Artoo's two open findings (`rules.gd:1400` breaks `sim_battle.gd:33` override; synchronous build path bypasses PR #1445), PR #1890 @ `3a1f8553` has two unflagged runtime bugs in `godot/scenes/battle/battle.gd`:
  1. **Duplicate 3D ship views and orphaned hulls:** In `_begin()` (`battle.gd:607-614`), when `api.phase == "deployment"`, it calls `board.build(api)` and `_draw_starting_fleet()`, which calls `_make_view(u)` (`battle.gd:870-878`: `var sv = ShipView.new(); add_child(sv); views[u["id"]] = sv; _register_fx_ship(u, sv)`). When the player completes or skips the pick, `_pick_skill_target()` (`battle.gd:5380`) calls `_start_battle_view()` (`battle.gd:617-653`), which calls `board.build(api)` and `_draw_starting_fleet()` a **second time** without freeing or reusing the existing `views[u["id"]]` nodes. Every ship gets two overlapping 3D `ShipView` children (the first batch orphaned forever at the pre-swap hexes) and duplicate `gfx.add_ship()` registrations.
  2. **Unblocked HUD actions during deployment:** In `_on_action()` (`battle.gd:5170-5178`), `if _skill_picker_ready():` only returns for `name == "pick"` and `name == "ask" and arg == "skip_skill_target"`. Any other action (`end`, `brace`, `command`, `undo`, `ability`, etc.) falls through into the live-battle `match name:` block during `"deployment"`.
- **Evidence (OBSERVED):** PR #1890 `godot/scenes/battle/battle.gd:607-614` (`if api.phase == "deployment": ... _draw_starting_fleet()`), `:650` (`_draw_starting_fleet()` called again inside `_start_battle_view()`), `:870-878` (`_make_view` unconditionally calls `ShipView.new()` and `add_child(sv)`), `:5170-5178` (`if _skill_picker_ready():` has no catch-all `return`).
- **Suggested fix:** Add both fixes to the #1870 fix run (or a follow-up before merge): in `_start_battle_view()`, reuse and resync existing `views` (creating views only for newly spawned wings/units not in `views`, and never rebuilding the board or existing ships twice); in `_on_action()`, add an unconditional `return` at the end of `if _skill_picker_ready():`. Add a headless test asserting `views.size()` and `ShipView` child count stay equal after completing a swap.

### 3. PR #1861 (`opus/issue-1777-glass`, R431 round 3 GP1): dirty on `main`, ALL checks RED, old #1786 ancestor, AND ribbon-overlap geometry bug
- **What is wrong:** Head `3f016cb5` (pushed 22:42 UTC) is `mergeable: false (dirty)` against `main`, all 8 CI check runs concluded `failure`, it embeds an older head of PR #1786 (`65be1865`, missing `6dba5c9a` which merged R433 fleet lighting default-on), and Artoo just caught an index math defect at `tools/blender/kits/ithar/hull.py:255` (`j = (k * field.n) // leaves + (k % 2)` with `field.n=12, leaves=12` yields indices `0, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10, 0`, doubling swells on half the ribbons and leaving the other half bare).
- **Evidence (OBSERVED):** REST `pulls/1861` (`mergeable: false, mergeable_state: "dirty"`); check-runs on `3f016cb5` (all 8 jobs `failure`); commit list stops #1786 ancestry at `65be1865`; Artoo comment on PR #1861 at 22:44 UTC citing `tools/blender/kits/ithar/hull.py:255, 295-311` and `ithar_GP1.py:132-136`.
- **Suggested fix:** Fix the ribbon index formula in `hull.py:255`, bring in PR #1786 head `6dba5c9a` (or merge `main`), verify green checks, and re-pin GP1 before un-holding the rest of `OPUS431C`.

### 4. PR #1876 (`opus/issue-1651`, Build variety Part D: Command riders, green and mergeable): **UNFIXED HIGH BUG** in Thorne's turn planner on green head `09759ea6`
- **What is wrong:** PR #1876 is green (`All checks: success`) and `mergeable: true`, so it looks ready to merge, but it never fixed Artoo's High Finding 1 from `3c6f611a` (19:29 UTC): `godot/scenes/battle/battle.gd:4161-4185` (the player turn planner) still deducts MP for Thorne's free turn (`v["mp"] = v["mp"] - 1`) instead of honoring `riderFace(u)` as `rules.gd:2080` (`canRotate` / `_rotateUnit_raw`) does. Paginating all 361 files of PR #1876 confirms `battle.gd` has only a 1-line edit at line 5794 (`_command_tip`). With Thorne active and 1 MP left, Q/E rejects a two-step turn when there is no legal shot at the intermediate facing. No review exists on current head `09759ea6`.
- **Evidence (OBSERVED):** Paginated `pulls/1876/files` shows `godot/scenes/battle/battle.gd (+1/-0)` at line 5794 only; `battle.gd:4161-4185` on `main` checks `treeFreeTurn` and `freePivot` only, not `riderFace`; commits `5f48c8d1` to `09759ea6` never touch `battle.gd`.
- **Suggested fix:** Hold merge of PR #1876 until `battle.gd:4161-4185` shares Thorne's `riderFace(u)` turn-cost rule and a test covers a 2-step Q/E plan at 1 MP with Thorne active. Also remove the stale `running` label from issue #1651 once done.

### 5. PR #1755 (`opus/issue-1741`, Wounds V2, green, queued for `JOINT_E`): **NEW MISSED BUG** stamps `fx_wreck_t0` at precompute time, disabling the 4-second wreck settle
- **What is wrong:** To answer Fable review M2 (smooth 4-second wreck settle instead of a one-frame snap), PR #1755 added `uniform float fx_wreck_t0` (`godot/fx/fx_shaders.gd:2327`) with `smoothstep(0.0, 4.0, scene_t - fx_wreck_t0)` and set `fx_wreck_t0` inside `fx.wreck_interior()` (`godot/fx/fx.gd:1458-1462`: `var t0 := snappedf(now, 0.1)`). However, `fx.wreck_interior()` is called from `fx_death.gd:1494, 1527` (`_piece_materials`) during precomputation (`build_meshes()` runs on battle load / first hit, seconds to minutes before the ship dies), and `_break_up_inner()` never updates `fx_wreck_t0` when the ship actually breaks. On every precomputed death, `scene_t - fx_wreck_t0` is already `>> 4.0` on frame 1 of death, so the transition snaps immediately to 100% settled.
- **Evidence (OBSERVED):** PR #1755 `godot/fx/fx.gd:1458-1462` (`var t0 := snappedf(now, 0.1)` / `m.set_shader_parameter("fx_wreck_t0", t0)`); `godot/fx/fx_death.gd:1490-1504` (`# The opaque slag surface is built here with the piece, before death when possible.` calling `_piece_materials` -> `fx.wreck_interior`); full diff search of PR #1755 shows zero references to `fx_wreck_t0` in `fx_death.gd` or `_break_up_inner`.
- **Suggested fix:** Update `fx_wreck_t0` to `fx.now` on the wreck pieces' interior materials inside `_break_up_inner()` (or per-wreck material instance at break time), not at precompute time.

### 6. Issue #1779 (R420 Wave C: Godot 4.7 Cinematic Post-FX) was closed by mistake on a docs-only PR (#1781)
- **What is wrong:** Issue #1779 (`Godot 4.7 Cinematic Post-FX: per-region battle 3D LUT, kill-cam Depth-of-Field, selective SSR benchmark, CompositorEffect, and Forward+ Decals`) is an approved R420 Law 6 track still cited as live in `docs/RULEBOOK.md:545-549` and `contrib/opus/FINDINGS.md` R420. It was closed on Nov 23 with the comment `"Board hygiene (Nov 23 audit, R288): scope delivered by merged PR 1781. Closing."` In reality, PR #1781 only edited 3 documentation files (`contrib/opus/FINDINGS.md`, `contrib/opus/plans/global_cohesion_standard.md`, `docs/RULEBOOK.md`) and zero Godot code.
- **Evidence (OBSERVED):** REST `issues/1779` (`state: "closed"`, closing comment citing PR #1781); REST `pulls/1781/files` lists only `contrib/opus/FINDINGS.md (+1/-1)`, `contrib/opus/plans/global_cohesion_standard.md (+36/-19)`, `docs/RULEBOOK.md (+14/-10)`; `docs/RULEBOOK.md:545-549` still lists `#1779`.
- **Suggested fix:** Reopen issue #1779 (with label `opus` and a note that PR #1781 was audit docs only) unless Ryan explicitly decides to drop Wave C post-FX.

---

## Priority 1: Before Merge or Queued GPU Runs (Dirty PRs, Unfixed Review Findings, Inherited Stray Files)

### 7. PR #1784 (`codex/issue-1693`, Wave 2B, queued in `WAVE2AB2`): dirty on `main`
- **What is wrong:** PR #1784 @ `97387d35` is `mergeable: false (dirty)` against `main` because `godot/tools/ci/godot_checks.txt` (PRs #1705, #1864, #1893, #1782), `godot/rules/rules.gd` (#1866, #1893), `godot/rules/battle_api.gd` (#1866, #1873), and `godot/scenes/battle/battle.gd` (#1873) changed on `main` after its base. Also note that its companion PR #1758 (`codex/issue-1692`, head `90953201`) still carries pre-R437 Chorus tendril shader/weapon edits (`fx_shaders.gd:815-824`, `fx_weapons.gd:578-589`) plus an unused `_beam_end` wrapper (`fx_weapons.gd:658-663`), even though R437 scrapped tendrils.
- **Evidence (OBSERVED):** REST `pulls/1784` (`mergeable: false, mergeable_state: "dirty"`); PR #1758 diff `godot/fx/fx_shaders.gd:815-824` and `godot/fx/fx_weapons.gd:578-589, 658-663`.
- **Suggested fix:** Merge `main` into `codex/issue-1693` (and confirm `WAVE2AB2` pins the merged head, not pre-1782 `bc820fde` if merging soon). Decide whether to revert the pre-R437 tendril hunk in PR #1758 before merge or let issue #1877's replacement overwrite it cleanly.

### 8. PR #1724 (`opus/issue-1680`) and PR #1763 (`opus/issue-1743`): PR #1763 embeds an OLD buggy commit of PR #1724, AND `check_export.py:image_size()` has a new JPEG parser bug plus Artoo's unfixed silent-skip finding
- **What is wrong:** Three linked problems:
  1. **Stale ancestor in PR #1763:** PR #1763 (`663d481f`) merged `opus/issue-1680` at `4cbcc3ce`, missing PR #1724's critical fix `d7a258c8` (strike-craft 1024 check, both-sides check, over-target check). When PR #1724 merges first (as PR #1763's HOLD title requires), PR #1763 will immediately conflict on `tools/recipe/check_export.py` and `check_export_selftest.py`; merging #1763 first would ship the buggy pre-`d7a258c8` gate.
  2. **Unfixed Artoo High finding on PR #1724 @ `d7a258c8`:** `check_export.py:394` (`if wh: sizes[u] = tuple(wh)`) silently skips any atlas whose header `image_size()` cannot read.
  3. **NEW MISSED BUG in `tools/recipe/check_export.py:151-160` (`image_size`, present in both PR #1724 and PR #1763):** The hand-rolled JPEG parser reads `ln = struct.unpack('>H', m[2:4])[0]` and runs `f.seek(ln - 2, 1)` with no `ln < 2` guard (a malformed segment with `ln == 0` seeks `-2` and loops infinitely), no length check before `struct.unpack('>xHH', f.read(5))` (truncated SOF raises uncaught `struct.error`), and no handling of JPEG `0xFF` fill bytes or standalone markers (`0xFF 0x01`, `0xFF 0xD0..0xD7`).
- **Evidence (OBSERVED):** Commit lists for PR #1724 (`d7a258c8` absent from PR #1763); PR #1763 `check_export.py:502-511`; PR #1724 `check_export.py:151-160, 391-396`; Artoo comment on PR #1724 at 18:53 UTC.
- **Suggested fix:** Fix `check_export.py` on PR #1724 first (use Pillow or guard `ln < 2`, `len(sof) < 5`, fill bytes, AND fail loudly when `wh is None`), merge PR #1724, then merge `main` into PR #1763 before `JOINT_E`.

### 9. PR #1725 (`opus/issue-1412`, queued as `H7N`): Artoo's `hegemony_H7.py:255` plate-inventory bug is STILL unfixed on `61ef5beb`
- **What is wrong:** Commit `61ef5beb` (22:32 UTC) fixed the break-table parsing failure in `feature_table.md`, turning CI green, but did NOT fix Artoo's earlier finding on `beb89846` (`tools/blender/build_sheets/ships/hegemony_H7.py:248-256`): all three inventory entries (`deck_panels`, `flank_panels`, `belly_panels`) pass `detailed=laid_total > 0` instead of per-surface counts, so a missing deck, flank, or belly plate surface passes silently. Also no review exists on `61ef5beb` (R407).
- **Evidence (OBSERVED):** PR #1725 @ `61ef5beb` `tools/blender/build_sheets/ships/hegemony_H7.py:248-256` (`for inv in ('deck_panels', 'flank_panels', 'belly_panels'): K.built.append(... detailed=laid_total > 0 ...)`).
- **Suggested fix:** Track laid plate counts per surface (`deck`, `flank`, `belly`) in `hegemony_H7.py` before running `H7N` or merging PR #1725.

### 10. Issue #1897 (running on Lane A) uses `Base: codex/issue-1887` (PR #1896), inheriting stray out-of-scope files
- **What is wrong:** Issue #1897's fixed block sets `Base: codex/issue-1887`. PR #1896 (`codex/issue-1887` @ `ded6dbf3`) contains four extra files outside its brief's `Deliver to` (`docs/shots/issue-1887-codex/{anuket,sable}.png` and `.provenance.json`, flagged by Artoo at 21:57 UTC) plus the 2-picture test directory `contrib/codex/portraits_test/`. When #1897 opens its PR against `main`, it will carry all 7 files from PR #1896 unless cleaned up or rebased onto `main`. Meanwhile PR #1896 itself and issue #1887 are already superseded by R444 + issue #1897.
- **Evidence (OBSERVED):** Issue #1897 body `Base: codex/issue-1887`; PR #1896 file list includes `docs/shots/issue-1887-codex/*`; Artoo comment on PR #1896 (21:57 UTC).
- **Suggested fix:** When #1897 delivers, drop `docs/shots/issue-1887-codex/` (and decide whether to keep `contrib/codex/portraits_test/` or close PR #1896 + issue #1887 unmerged once #1897 carries `sable.png`).

### 11. PR #1892 (`codex/issue-1883`, fix running on Lane B) and PR #1890 (`codex/issue-1870`, fix running on Lane C): both currently RED on `All checks`
- **What is wrong:** PR #1892 (`3aa5bcdb`) fails `Godot game checks (2 of 3)` and `Godot rules (saved results)` because `3aa5bcdb` took `main`'s saved campaign results without re-saving after merging `main` (fix run already on Lane B). PR #1890 (`3a1f8553`) fails all 3 Godot game check shards because `rules.gd:1400` broke `sim_battle.gd:33`'s `startBattle` signature (fix run already on Lane C; see Item 2 above for the additional missed `battle.gd` bugs).
- **Evidence (OBSERVED):** Check runs on `3aa5bcdb` and `3a1f8553`; Artoo comments on PR #1892 (21:28 UTC) and PR #1890 (22:13 UTC).
- **Suggested fix:** Verify Lane B's next push on #1883 turns `All checks` green (then close superseded PR #1811 and issue #1802); feed Item 2's missed bugs into #1870 before merge.

### 12. Open PRs queued for GPU with unreviewed latest heads (R407 check)
- **What is wrong:** Under R407 (`RULEBOOK 3.12`), heavy GPU captures wait for green checks AND a review on the exact current head commit. Several PRs in the GPU line have code commits after their last review comment:
  - **PR #1445** (`b521b3a1`, last reviewed `c331e1a2`; also dirty now, Item 1).
  - **PR #1874** (`8caeab8a`, queued as `1582 RUN4`; last Board review was `ad7dfa6b`, `8caeab8a` was a manual conflict-resolving merge of `main` in `ship_view.gd`).
  - **PR #1737** (`76cd9245`, queued as `WRECK5`; last review was `fbceb98a`, `76cd9245` added `_joint_gap`). Also note a minor **MISSED DEFECT** in PR #1737 (`godot/fx/fx_death.gd:928-934, 1045, 1089-1105`): for `"late"` breakups, `_throw_frags()` calls `_hold_chip()` to glue seam chips onto the nearest main piece, and `_snap()` 0.95s later never releases those held chips; additionally `death_glued_break` is never cleared in `_death_inner` (unlike `death_crack` at line 777), though `battle.gd:1746` revive creates a fresh `fx_ship` only if `add_ship` replaces it (INFERRED risk if `fx_ship` is ever reused).
  - **PR #1858** (`0a95e335`, queued as `1394J`; last review was `bc6d39d7`, `0a95e335` modified `fx_shaders.gd`, `capture.gd`, `sheet.py`).
  - **PR #1772** (`7c734f53`, queued as `PROPS_N`; last Artoo review was `deddb79b`, commits `7c7ae555` and `380e61c4` changed `a4_props.gd` and `board.gd` after it).
  - **PR #1755** (`83dbdddd`, queued for `JOINT_E`; last Artoo review was `4b375459`, commits `546410f5` and `83dbdddd` followed; plus missed bug in Item 5).
  - **PR #1763** (`663d481f`, queued for `JOINT_E`; last Artoo review was `e1153b84`, commit `663d481f` added `thick_shell` smoked back lining).
  - **PR #1776** (`00b0f1fa`, pushed 22:45 UTC during audit, checks still running; `[HOLD]` title still says replacement coming).
- **Evidence (OBSERVED):** Comparison of `pulls/<N>.head.sha` against every review comment SHA on each PR.
- **Suggested fix:** Have Artoo or the Board glance at the post-review delta commits before each GPU job starts (especially PR #1445 `b521b3a1` after rebase, PR #1874 `8caeab8a`, PR #1737 `76cd9245`, and PR #1725 `61ef5beb`).

---

## Priority 2: Merge Conflicts Between Open PRs and Safe Merge Order

Exact hunk-level comparison (base line ranges within 4 lines) across all active non-hold PRs found **13 real multi-PR conflict clusters** (excluding `godot_checks.txt`, which 11 open PRs append to and always needs a trivial merge/rebase).

### Real Code/Doc Conflict Pairs (OBSERVED from PR file patches)

| Cluster | PR Pair | Conflicting Files & Regions | Safe Merge Order & Why |
|---|---|---|---|
| **A. Loading vs World & Battle** | **#1445** vs **#1776** | `godot/world/world_bake.gd` (`_queue`, `clear_static`, `bake`), `godot/world/world_planet.gd` (`install_rocky`), `godot/render/board.gd` (`_planet`, `build`), `godot/render/static_caches.gd`, `godot/scenes/battle/battle.gd` (`_warmup`), `godot/tools/ci/godot_checks.txt` | **#1445 first**, then merge `main` into **#1776** (which is already on `[HOLD]` for Ryan's coastline/lava re-review). |
| **B. Loading vs Exteriors V2** | **#1445** vs **#1786** | `godot/render/ship_view.gd` (`clear_static`/`manifest`, `setup`/`_look`), `godot/render/static_caches.gd`, `godot/scenes/battle/battle.gd` (`_build_world`), `godot/tools/ci/godot_checks.txt` | **#1445 first**, then **#1786** (which is held for R431 via #1861 anyway). |
| **C. Loading vs Movement Stage 2** | **#1445** vs **#1874** | `godot/render/board.gd` (`build`), `godot/render/ship_view.gd` (`clear_static`/`manifest`, `setup`), `godot/scenes/battle/battle.gd` (`_make_view`/`_register_fx_ship`) | **#1445 first**, then merge `main` into **#1874** so #1445's sliced roster calls `_register_fx_ship()` and gets altitude bands (Board noted this on #1874). |
| **D. Loading vs Skill Picker** | **#1445** vs **#1890** | `godot/scenes/battle/battle.gd` (`_begin` lines 598 to 707), `godot/main/campaign_host.gd`, `godot/tools/ci/godot_checks.txt` | **#1445 first**, then **#1890** routes deployment view setup through #1445's sliced path. |
| **E. Loading vs Round 2 Hitch** | **#1445** vs **#1852** | 28 shared files (**#1852** embeds an old #1445 head and is dirty) | **#1445 first**, then rebase **#1852** onto `main` (already marked `[HOLD]` on #1852). |
| **F. Exteriors V2 vs World Props V2** | **#1786** vs **#1772** | `contrib/opus/FINDINGS.md` (L448-454: #1786 adds R426; #1772 adds R423 and R425), `docs/RULEBOOK.md` (L560-565), `godot/render/static_caches.gd`, `godot/tools/ci/godot_checks.txt` | **#1772 first** (only waits on `PROPS_N`), then merge `main` into **#1786** keeping R423, R425, and R426 in order (and keeping both RULEBOOK 3.14 blocks). |
| **G. Map Bands vs Interior Kit V2 vs Wounds V2** | **#1724** vs **#1763** vs **#1755** | **#1724 <-> #1763:** 9 shared files (`export7.py`, `check_export.py`, `check_export_selftest.py`, `hardpoints.py`, `RECIPE.md`, `7_export.bat`, `C19_51_unbaked.*`). **#1763 <-> #1755:** `godot/fx/faction_looks.json` (`_fields` + all 6 factions) | Strict order: **#1724** (after Item 8 fix) -> **#1763** (rebase/merge `main` to pull `d7a258c8`) -> **#1755** (using the combined `faction_looks.json`). Also note **#1786** and **#1755** share `godot/fx/fx_hull.gd` and `look_bench.gd` (`b183963a` coat/backlight carry). |
| **H. Deaths & Acid Tell vs Wrecks vs Wounds** | **#1737** vs **#1858** vs **#1755** | **#1737 <-> #1858:** `godot/fx/fx_death.gd` (`_arcs`, `_break_up_inner`), `docs/playbooks/deaths_and_hits.md` (L149-158). **#1858 <-> #1755:** `godot/fx/fx_shaders.gd` (L2097-2108). **#1755 <-> #1445:** `fx_death.gd` (L10-15), `fx_hull.gd` (L1-4), `fx_ship.gd` (`_dmg_request`) | **#1737** (after `WRECK5`) -> **#1858** (after `1394J`, merge `main`) -> **#1755** (after `JOINT_E`). |
| **I. FX Wave 2B vs Wounds vs Riders vs Skill Picker** | **#1784** vs **#1755**, **#1876**, **#1890**, **#1445** | **#1784 <-> #1755:** `godot/fx/fx_weapons.gd` (`_impact` L2075-2101). **#1784 <-> #1876:** `godot/rules/rules.gd` (`applyHit` L3358-3370). **#1784 <-> #1890:** `godot/rules/battle_api.gd` (`_i_view` L255-269). **#1784 <-> #1445:** `godot/audio/sfx.gd` (L50-65). **#1784 <-> #1758:** `fx_weapons.gd`, `fx_shaders.gd` (different regions, clean). | **#1758** + **#1784** together after `WAVE2AB2` (rebase #1784 first); keep **#1876** and **#1890** re-saving `rules.gd` / `battle_api.gd` after #1784 (or vice versa, regenerating saved results on the final combined tree). |
| **J. Movement Stage 2 vs Exteriors/Props/Skill Picker** | **#1874** vs **#1786**, **#1772**, **#1890** | **#1874 <-> #1786:** `godot/render/ship_view.gd` (`clear_static` L55-63). **#1874 <-> #1772:** `godot/render/board.gd` (`_terrain` L897-912). **#1874 <-> #1890:** `godot/scenes/battle/battle.gd` (`_on_hover` L4334-4359). | **#1874** after `1582 RUN4` (and after #1445), then #1786 and #1890 bring `main` in. |
| **K. Campaign UI duplicate** | **#1892** vs **#1811** | 24 identical files (**#1811** is superseded by **#1892**) | Close **#1811** once **#1892** passes; never merge #1811. |

**Recommended overall merge backbone:**
1. **Immediate (independent / zero-conflict):** #1880 (ready now), #1881 (fix PR body first), #1724 (after Item 8 fix), #1845 (review doc, or close once 1836 r7 finishes).
2. **Core engine/loading first:** **#1445** (rebase over #1782 -> `LOAD29` -> merge), then **#1852** (rebase after #1445).
3. **World & look wave:** **#1772** (`PROPS_N`), **#1737** (`WRECK5`), **#1874** (`1582 RUN4`), **#1758 + #1784** (`WAVE2AB2`), **#1858** (`1394J`), **#1725** (`H7N`, after Item 9 fix).
4. **Exteriors + Interiors + Wounds pack (after R431 GP1..GW4 and `JOINT_E`):** **#1786** (incorporating #1861; close #1861), then **#1763**, then **#1755**, then **#1776** (after coastline/lava approval).
5. **Rules & UI wave (re-save Godot results on the final combined tree):** **#1892** (close #1811), **#1876** (after Item 4 Thorne fix), **#1890** (after Item 2 + Artoo fixes).

---

## Priority 3: Open PRs That Are Ready, Stale, Red, Duplicated, or Drafts to Close

### 13. Ready PRs sitting unmerged or waiting with no active owner
- **PR #1880 (`opus/issue-1407`, green, clean):** Board already signed off on scope at 20:14 UTC (`"This PR's admiral-voice slice is the whole words change for 1407"`), yet it is still unmerged and issue #1407 still carries the `running` label. **Fix:** Merge #1880 and remove `running` from #1407.
- **PR #1881 (`muse/issue-1877`, green, clean):** Delivered 4 Chorus tendril replacement options (19:48 UTC), but auto-generated PR body starts with `"Issue 1854: PC checks"` (Artoo flagged at 19:45 UTC). **Fix:** Fix the PR body, merge #1881, and file/queue the 4 look-bench clips promised by R437 (see Item 20).
- **PR #1845 (`codex/issue-1836`, green, clean, 0 comments):** Holds Astra's audit of PR #1835 (run 6), which the daemon thread already acted on at 22:18 UTC; run 7 is queued next. **Fix:** Keep open only until 1836 run 7 updates `astra_audit_1835.md` and merges with or before PR #1835.
- **PR #1835 (draft, `claude/project-thread-wug77i`, green):** Active Node PC daemon draft waiting on 1836 run 7 (in Codex queue). Keep as draft until 1836 run 7 passes.

### 14. Superseded, broken, or stale PRs that should be closed (or explicitly re-owned)
- **PR #1811 (`codex/issue-1802`, dirty):** Superseded by issue #1883 / PR #1892 (`"Run 3 moved to issue 1883"`), has **no `[HOLD]` tag** in its title. **Fix:** Add `[HOLD: superseded by #1892]` now and close #1811 (and issue #1802) once #1892 merges.
- **PR #1896 (`codex/issue-1887`, green, Artoo flagged stray `docs/shots/`):** Two-picture portrait test already judged by Ryan (R444) and replaced by issue #1897 (12 portraits). **Fix:** Do not merge #1896 as-is; close #1896 and #1887 once #1897 finishes and strips the stray `docs/shots/issue-1887-codex/` files.
- **PR #1837 (draft, `claude/project-thread-wws9qu`, `checks: NONE`):** Pin branch for `OPUS1603_RUN_B`. `LOOP.md` 14:30 UTC already records `1603 RUN_B PASS (c1d4b03b): old saves resume, no clipping`. **Fix:** Verify #1603's evidence is archived and close both draft PR #1837 and issue #1603.
- **PR #1833 (draft, `claude/project-thread-vr81nj`, `checks: NONE`):** `"Review pack, Nov 23: pictures waiting on Ryan's look (do not merge)"` from 13:25 UTC (pre-R430/R432). **Fix:** Close once Ryan/Board no longer need the link (never merges).
- **PR #1442 (draft, `claude/project-thread-8hcjwy`, `checks: NONE`, untouched since Nov 21 02:57 UTC):** Stale 2.5-day-old draft for blocked issue #1439, touches `godot/main/main.gd` (conflicts with #1445). **Fix:** Close draft PR #1442 (keep branch if needed for future 4K campaign pass) until #1439 unblocks.
- **PR #1720 (`opus/open-work-nightly`, `checks: NONE`):** Nightly bot PR that never gets merged (`OPEN_WORK.md` on `main` is stuck at Nov 17), and Artoo (21:32 UTC) observed `gen_open_work.js:9` drops the `neon` seat completely (`const SEATS = ['codex', 'muse', 'opus', 'ryan']`). Meanwhile open issue #1506 exists to retire `OPEN_WORK.md` and its nightly workflow altogether. **Fix:** Either execute #1506 and retire the workflow (recommended, closes #1720), or add `'neon'` to `SEATS` and merge nightly.
- **PR #1718 (`muse/issue-1572`, RED on `Standing checks`, untouched since Nov 22 17:07 UTC):** Sound redo research from Muse; red on Standing checks, Artoo flagged missing official price/licence links (`synthesis.md:115-131`), and already overtaken in practice by Gate 2 sound pack (PR #1753 + Waves A to D running on #1752). Nobody owns fixing it. **Fix:** Either close PR #1718 and issue #1572 as overtaken by #1752, or have a quick docs fix strip em dashes / mark unsourced ranges unverified and merge as archive research.
- **PR #1163 (`muse/issue-1145`, RED on `Standing checks` + `Godot game checks`, 4 days old):** Sunward starter concepts; Artoo (Nov 22 17:04 UTC) flagged stale PR body (`"Hearth and Bastion still undrawn"`) and failed Hearth objective checks (`designs.md:204-214`). Waiting on nobody. **Fix:** Decide whether to dispatch Muse run 4 on #1145 or split/close #1163.

---

## Priority 4: Open Issues Hygiene (Already Merged, Stale `running`, Unlabelled, Missing Fixed Block, Contradicting Rulings)

### 15. Open issues whose work ALREADY MERGED (close under RULEBOOK 2.4 / R288)
All 9 verified via `gh api` REST against merged PRs (OBSERVED):
- **#1854** (`opus`, NTFS hard-link fallback): **MERGED in PR #1855** (Nov 23 19:42 UTC). Close.
- **#1667** (`codex, blocked`, move remaining readers off frozen JS): **MERGED in PR #1815** (run 7, Nov 23 13:47 UTC; FINDINGS R422 says `"issue 1667 run 7 completes the ship-data migration in R405"`). Close.
- **#1649** (`opus`, Build variety Part E): **MERGED in PR #1665** (Nov 22 20:34 UTC) plus follow-up **PR #1770** (Nov 22 22:06 UTC, addressing Artoo's review). Close.
- **#1490** (NO labels, Public repo tidy): **MERGED in PR #1697** (run 1) and **PR #1820** (run 2, Nov 23 06:58 UTC). Close.
- **#1456** (`blocked`, NO owner label, Astra pass 2 findings only): **MERGED in PR #1469** (Nov 21 02:06 UTC); all 8 findings split to #1466, #1467, #1468 and ALL merged. Artoo asked to close it on Nov 21. Close.
- **#1155** (`opus`, Chorus brood-sac carrier B22_11): **MERGED in PR #1172** (Nov 21 01:48 UTC, published in `manifest.json`; Artoo asked to close it on Nov 21). Close.
- **#1603** (`opus`, Story text on Windows): **PR #1624 merged** + `LOOP.md` 14:30 UTC records `1603 RUN_B PASS (c1d4b03b): old saves resume, no clipping`. Verify and close with draft PR #1837.
- **#1739** (`opus`, Codex lane runner checks exit 1): **11 PRs merged** (#1740, #1748, #1757, #1769, #1773, #1787, #1793, #1796, #1804, #1812, #1813); root cause proven and deployed. Close (or state what single remaining check keeps it open).
- **#1887** (`codex, blocked`, 2-picture portrait test) and **#1802** (`codex, blocked`, UI audit B2/B3/C): superseded by #1897 and #1883 respectively; close once #1897 and #1892 land.

### 16. Open issues with stale `running` labels
- **#1407** (`opus, running`): PR #1880 finished and Board signed off at 20:14 UTC.
- **#1651** (`opus, running`): PR #1876 pushed its last commit at 20:51 UTC and is idle/green (though blocked by Item 4).
- **#1582** (`opus, running`): PR #1874 pushed its last commit at 21:38 UTC and is idle/green waiting for GPU `1582 RUN4`.
- **Evidence (OBSERVED):** REST `issues?state=open` labels vs PR update timestamps and Board active-lane list.
- **Suggested fix:** Clear `running` on #1407, #1651, and #1582 so dispatch tools and audits see true live claims.

### 17. Open issues with no owner label, missing fixed block, or placeholder `Branch:` / prose `Base:`
- **No owner label (OBSERVED):** **#1490** (`[]`, already merged), **#1456** (`[blocked]`, already merged), **#906** (`[]`, Artoo standing sweep; intentional, not a dispatch seat).
- **Missing fixed block (OBSERVED):** **#1239** (`opus`, `Ship damage audit: held items (backlog)`) lacks `Deliver to:`, `Branch:`, and `Done when:` lines (RULEBOOK 2.4).
- **Multiple `Base:` lines:** None observed across all 90 open issues.
- **Placeholder `Branch:` / non-branch `Base:` prose (OBSERVED):** **#1899** (`neon`, Sound Wave D) has literal `Branch: neon/issue-NUMBER (this issue's number)` instead of `neon/issue-1899` (low risk for T3, fix before launch if not yet pushed). Four `opus` issues put prose after `Base: main` (`#1582`, `#1661`, `#1662`, `#1791`: e.g. `Base: main (after PR 1772 merges...)`); harmless for cloud Opus threads, but would break a PC runner if ever relabelled `codex`.
- **Open issues with NO open PR and NO queue spot (partial merges or unscheduled backlog):**
  - **#1357** and **#1352** (`opus`, PRs #1805 and #1806 merged at 17:57 UTC): kept open for one non-blocking Artoo follow-up each (`LOOP.md` 17:58 UTC), but currently have no PR and no queue spot.
  - **#1705** (`codex, blocked`, in Codex queue for run 2): note Artoo's comment at 21:58 UTC observed run 2 had a failed local pickup on `bc820fde` with no delivery yet; confirm the queued run 2 picks up cleanly.
  - **#1849** (`opus`, picture stamp pre-merge + bench cell overlap), **#1875** (`opus`, big hulls cook off before break), **#1791** (`opus`, small teaching station rig after #1772), **#1780** (`opus`, Godot 4.7 perf/VRAM/stutter), **#1778** (`opus`, Blender PBR after #1724), **#1766** (`opus`, World Sky V2 after #1765), **#1681 / #1684 / #1685 / #1422 / #1423** (ship detail P2/P3 and Eclipse repaint/battleship), **#1661 / #1664 / #1506** (governance docs / local tools / retire OPEN_WORK), **#1518 / #1519 / #1645 / #1436 / #1438** (perf/polish), **#1401 to #1406** (Council remaining slices), **#1145 / #1146 / #1328** (Muse concepts & gas floor), **#1153 / #1291** (Chorus hulls; C10 to C14 are on the GPU line), **#545** (Nov 12 sweep follow-up tracker, untouched since Nov 19): all carry owner labels, none are in the immediate lanes/GPU queue; worth verifying #545 and #1463 (largely superseded by #1765/#1777/#1679) can be closed or pruned.

### 18. Open issues whose brief contradicts a newer ruling (without a current override note)
All verified in live issue bodies (OBSERVED):
- **#1582** (`opus`, Battle movement Stage 2) and **PR #1874 title:** Both still say `"arcing munitions"` / `"torpedo cold-launch arcs"`, contradicting **R435** (`"Keep them flat"`). The worker followed R435 in code, so update the title/body so nobody re-introduces arcs later.
- **#1764** (`opus`, World V2 tracker): Body still specifies `"faceted Blender multi-crystal"` and `crystal_0`, contradicting **R434** and **R445** (crystals scrapped and deleted, replaced by ice comets in PR #1782).
- **#1453** (`opus`, Build Variety umbrella) and **#1649** (`opus`, Part E, already merged): Bodies still instruct edits to `data.js`, `core.js`, `battle.js`, and `sim3d.js` with no R405 override note (unlike #1401 to #1407, #1423, #1651, #1652).
- **#1145** and **#1146** (`muse`, ship class families): Still cite `data.js` instead of `godot/rules/data/tables.json` (contradicting **R405** and **R422**).
- **#256** (`muse`, standing outside check): Still requires checking `"the JS and Godot twins"` (retired by **R405**) and lists only `"DeepSeek and Qwen write"` (missing Grok and Google Flash required by **R231 / RULEBOOK 2.8**).
- **#1153** (`opus`, Chorus B19_11): References the `"tendril"` weapon scrapped by **R437**.

---

## Priority 5: Rulings (R420 to R444) and LOOP / HANDOFF Work With No Issue, PR, or Queue Spot

### 19. R428 and R429 (Neon runs in T3 Code on auto-approve) never landed in `docs/RULEBOOK.md`
- **What is wrong:** Both FINDINGS rows R428 and R429 say `"the RULEBOOK 2.6/2.7 Neon line waits on a doc PR held by the R427 freeze."` R432 lifted the R427 freeze at 17:15 UTC, yet `docs/RULEBOOK.md` still has zero mention of Neon, T3 Code, R428, or R429, and there is no open issue, PR, or queue spot to land them (violating RULEBOOK 0.2).
- **Evidence (OBSERVED):** `contrib/opus/FINDINGS.md:453-454`; grep of `docs/RULEBOOK.md` returns 0 matches for `T3 Code`, `R428`, `R429`, and only mentions Neon as a reviewer in 3.13 / 11.7; 0 open issues/PRs for landing R428/R429.
- **Suggested fix:** Add the Neon / T3 Code / auto-approve seat rules to `docs/RULEBOOK.md` sections 2.6 and 2.7 in the next docs PR (or fold into #1506 / #1661).

### 20. R430 approved Waves 2 to 3 (`D1`, `D5`, `D6`, `D7`, `D8`), and R437 promised 4 look-bench clips, with NO issues or queue spots
- **What is wrong:**
  1. **R430 (`"yes on all, a to start"`):** Wave 1 items D2 (#1857 merged), G3 (#1859 merged), D4 (#1870 running), and D3 (#1871 queued) all have issues. The remaining approved items from `synthesis_1123.md` (**D1, D5, D6, D7, D8**) have **zero open issues, PRs, or queue spots**.
  2. **R437 (Chorus tendril replacement):** Muse delivered the 4 options in PR #1881 (`#1877`), but there is no follow-up issue or GPU queue spot yet for the 3D look-bench clips R437 promised (`"the Board builds a 3D look-bench clip of each for Ryan to pick"`).
  3. **R436 (Council picks C4, C12, C16, C19, C26, C37):** C28 merged (#1884) and C40 is in PR #1880; the remaining 6 Ryan picks (title Hollow Sun C4, orders-style reward card mockup C12, Battle 1 7-hex opening C16, lifepods truth C19, themed Hollow Sun icon variations C26, flagship pick screen + better background options C37) sit inside open omnibus issues #1402, #1403, #1405, #1406 with no PRs or queue spots yet.
- **Evidence (OBSERVED):** `contrib/opus/FINDINGS.md:455` (R430), `:461` (R436), `:462` (R437); full scan of all 90 open issues shows no issues for D1, D5, D6, D7, D8 or the R437 look-bench clips.
- **Suggested fix:** File tracked issues (labelled `opus` or `codex, blocked`) for R430 Waves 2 to 3 (D1, D5 to D8) and for the R437 4-option look-bench clip build (blocked on merging #1881) so they cannot drop out of context.

### 21. Dropped work and stale state in `LOOP.md` and `HANDOFF.md` section 0
- **Sandbox-owned NTFS hard-link TEMP cleanup (dropped):** Issue #1854 and `LOOP.md` 16:58 UTC note `node.exe` has ~1,020 of the 1,023 NTFS hard-link limit trapped in old sandbox-owned TEMP scratch, and #1854 explicitly says `"The sandbox-owned leftovers themselves need an admin cleanup (Ryan's OK), tracked separately."` **No separate issue exists**, and `LOOP.md` 16:58 UTC's `"idle TEMP cleanup watcher waits for no node.exe"` never reported completion in later LATEST lines. Any new tool creating 3+ hard links on `node.exe` will still hit the NTFS limit.
- **HANDOFF.md section 0 (7 days stale, Nov 16 18:15 UTC):**
  - Line 30 (`"Still open: the issue 211 Foley probe (close or keep)."`): **Issue #211 is already closed** (OBSERVED via REST `issues/211`).
  - Line 24 (`"Running now. See contrib/opus/OPEN_WORK.md"`): `OPEN_WORK.md` on `main` is frozen at Nov 17 (6 days stale).
  - Lines 10 to 18: omits Neon/T3 Code (R428/R429) and ElevenLabs sound work.
- **LOOP.md non-LATEST sections (6 to 7 days stale):**
  - Lock (`LOOP.md:7-9`): stuck at `2026-11-16 16:35`.
  - The seats (`LOOP.md:46-47`): still claims Claude API arms are OFF until Nov 21 and Codex is paused until Nov 22 (R342), and omits Neon/T3 Code completely.
  - Known traps (`LOOP.md:147, 152`): still carries an open ruling on `damage_surface_check.gd` citing closed issue #405, and still describes `board/pc-out-1119<letter>` on the main repo (retired by R410 / RULEBOOK 3.3a in favor of `rcbailey12/voidsworn-relay`).
- **Evidence (OBSERVED):** `HANDOFF.md:1, 10-30`; `contrib/opus/LOOP.md:7-9, 46-47, 88, 147, 152`; `contrib/opus/OPEN_WORK.md:3`; REST `issues/211` (`state: "closed"`), `issues/1854`.
- **Suggested fix:** File a small issue (or Morning Pick Sheet item) for Ryan's admin TEMP hard-link cleanup; refresh `HANDOFF.md` section 0 and `LOOP.md` "The seats" / "Known traps" (or execute issue #1506).

---

## Not checked:

- **Local PC queue state and disk logs:** Did not inspect `Downloads\voidsworn_test\queue\`, `board\`, or live PC process logs (read-only audit stayed inside the `t3_neon` clone and GitHub REST API).
- **Private relay repo (`rcbailey12/voidsworn-relay`) and `/mnt/project-files/`:** Did not inspect screenshots, videos, `board/neon_1123/synthesis_1123.md`, or `board/review_1123/` packs outside this repo.
- **Full line-by-line review of every open PR diff:** Read full non-test code diffs for PRs #1876, #1874, #1890, #1758, #1784, #1858, #1737, #1724, #1786 (`look.gd`/battle/world), #1772, #1755 (core FX files), #1763 (`check_export.py`/`export7.py`), and latest-commit deltas for #1445 (`b521b3a1`), #1776 (`00b0f1fa`), #1725 (`61ef5beb`), and #1861 (`3f016cb5`). Did not read every line of PR #1892's 24-file UI diff (actively being fixed on Lane B), PR #1835's 1,983-line Node daemon (actively under Astra audit #1836 run 7), PR #1755's full 4,355-line shader/breach diff, PR #1763's full Blender room geometry scripts, or generated `.jsonl.br` saved-result binaries.
- **Runtime execution:** Did not run Godot, Blender, or Node test suites against open PR branches.
