# Neon Review Lane Routing (Nov 26, 2026)

- **Issue:** #2251 (follow-up, Ryan Nov 26 20:23 UTC)
- **Sources:** Merged `contrib/neon/reviews/review_lane_1126.md` on `main` (`c3aeb58d4`) and Artoo's queue corrections on PR #2254 (`1ccbeba10`).
- **Result:** **22 existing issues edited** (covering 23 PRs, with PRs #1910 and #1925 both routed on issue #1889); **1 active issue skipped** (#1974 / PR #1980, Run 3 actively running on Lane E since 2026-11-26T18:46:01Z); **1 preferred PR noted without code edit** (#2242 / PR #2247, preferred over #2169, pending 10x Linux CI timing proof per Artoo on PR #2254). Zero new issues opened, zero code edited, zero PRs merged or closed.
- **Head movement check:** Only PR #1852 (issue #1843) moved since `review_lane_1126.md` (`ebbe0263b` -> `5d710fddd`); its brief routes only the remaining current-head launcher aggregate-verdict finding from Artoo's review on PR #1852 plus the solo RTX 5080 replay gate. All other 23 PRs remained at their reviewed heads.

## Routing Table (Blockers First)

| Issue | PR | Owner | Dependency | Edited |
| --- | --- | --- | --- | --- |
| #2063 | #2164 | muse | Blocks/collides add/add with #2173 (#2152) and #2177 (#2156) on 5 `contrib/muse/reviews/legs/leg_*.md` files | yes (run 2) |
| #2152 | #2173 | muse | Blocks/collides add/add with #2164 (#2063) and #2177 (#2156) on 5 `contrib/muse/reviews/legs/leg_*.md` files | yes (run 2) |
| #2156 | #2177 | muse | Blocks/collides add/add with #2164 (#2063) and #2173 (#2152) on 5 `contrib/muse/reviews/legs/leg_*.md` files | yes (run 2) |
| #2150 | #2169 | deepseek | Superseded by preferred PR #2247 (#2242) on `tools/pc/lane_tools_refresh_selftest.js`; hold and retire once #2247 merges | yes (run 2, hold) |
| #2242 | #2247 | deepseek | Preferred over #2169; pending 10-in-a-row Linux CI timing proof per Artoo on PR #2254 (no code change) | no (CI repeat gate) |
| #2142 | #2166 | codex | Conflicts with `origin/main` in `fx.gd`, `fx_shaders.gd`, `fx_weapons.gd`; overlaps #2230 (#2191) and #2239 (#2200); stale `running` label from Nov 25 | yes (run 3) |
| #2191 | #2230 | deepseek | Conflicts with `origin/main` in `fx_death.gd`; overlaps `fx.gd`/`fx_shaders.gd` with #2166 (#2142) | yes (run 2) |
| #1990 | #2020 | opus | Wait for queued #2205 run 3 sequence (#2237/#2205, #2236/#2206) before regenerating 22 `godot/campaign/test/saved/` files | yes (run 4) |
| #2033 | #2122 | codex (Board picks seat) | Wait for #2205 run 3 sequence before regenerating 278 `godot/rules/test/saved/` files; PC runner refused due to `work/issue-2033-opus-partial` from another seat | yes (run 4) |
| #2103 | #2106 | neon | Reconcile multi-base conflict on 6 world/render/main files against post-LOAD38 `origin/main`; drop duplicate issue-2023 files | yes (run 2) |
| #1843 | #1852 | codex | Head moved (`ebbe0263b` -> `5d710fddd`); fix launcher aggregate verdict first, then Board queues solo RTX 5080 replay | yes (run 4) |
| #1394 | #1858 | opus | Fix `sheet.py` column shift first, then Board queues 1394J PC capture for Ryan's look pick | yes (run 2) |
| #1889 | #1910, #1925 | codex (Astra S9A; Opus leg S9O) | HOLD for Ryan's pick: both target `V14_23` and overlap `FLEET.md:14`; fix S9A Stage 2 PC crash and run PC stages 1 to 7 + matched S9/S9O/S9A sheets | yes (run 2) |
| #1974 | #1980 | codex | Run 3 actively running on Lane E since 2026-11-26T18:46:01Z (run 3 brief already covers `godot_checks.txt` and Neon findings on PR #1980) | no (active run 3) |
| #2035 | #2050 | neon | Fix 1080p nebula frame time (13.343 ms vs 12.5 ms) and `world_living.gd:1395` `cv.y` hash, then Board queues `GAS5` PC capture | yes (run 4) |
| #2034 | #2071 | sonnet | Fix `sfx.gd:578-580` delayed rollback and provide/stage Sound settings panel picture; stale `running` label from Nov 25 | yes (run 4) |
| #1403 | #2140 | codex (label `opus`, branch `work/issue-1403-opus`) | None (item 16 stays deferred until saved-results queue finishes) | yes (run 2) |
| #1766 | #2210 | codex | Fix `world_rocks.gd:328` rock-haze blur first, then Board queues 1080p battle sheets for Ryan's pick | yes (run 2) |
| #2199 | #2213 | codex | None (fix `_dmg_drawn_surfs` sync and main-thread `BREACH.prepare_surfaces` risk) | yes (run 3) |
| #2174 | #2220 | deepseek | Overlaps `godot/tools/ci/run_checks.sh` and `contrib/opus/tools/godot_shard_tests.js` with open PR #2196 (#2179) | yes (run 2) |
| #2160 | #2221 | codex | None (docs-only: fix 2 broken image links in `astra_full_audit_1125.md`) | yes (run 2) |
| #2180 | #2224 | deepseek | None (re-sync `LOOP.md` against current `origin/main` and match unbulleted `LATEST` lines) | yes (run 2) |
| #2200 | #2239 | deepseek | Overlaps `fx_weapons.gd` and `fx_acid_thorn.gd` with #2166 (#2142) | yes (run 2) |
| #2217 | #2240 | deepseek | None (PR #2192 already merged on `origin/main`) | yes (run 2) |

## Skipped Per Brief (Handled Elsewhere)

- `#2007` / `#1991`: held for Ryan's capture; remaining smoke/plume/API items belong to `#2248` (reconciled per Artoo on PR #2254).
- `#2104` / `#2079` and `#2253` / `#2194`: Codex combine already queued.
- `#2236` / `#2206` and `#2237` / `#2205`: sequence already queued.
- `#2167` / `#2144`, `#2196` / `#2179`, `#2207` / `#2181`, `#2225` / `#2081`, `#2226` / `#1405`: Board checkpoints already in progress.
