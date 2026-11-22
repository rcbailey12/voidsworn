# PR 1596 technical review

PR head `1ecbc9c3e`, fetched main `f7f356813`, merge base `1a0008134`. Scope: wreck reach worker safety and Eclipse-only scene dim.

**Verdict: fix the shared cut dictionary before merging.** The new reach math stays on the worker's vertex arrays, and the dim change leaves the other death cues in place. The timing write adds a key to a dictionary the main thread can still read during a cold kill.

## `docs/playbooks/deaths_and_hits.md`

**Defect (OBSERVED), finding 3.** The capital section correctly records R389, but the same playbook still asks for an on/off comparison that the PR removes.

## `godot/bench/look_bench.gd`

**Sound (OBSERVED).** Comment-only change. `_moment` still reads `row.get("fx", {})` and applies each supplied key, so the bench can still set reduced flashing.

## `godot/bench/look_moments.json`

**Sound (OBSERVED).** The obsolete opt-in comparison is gone; the Hegemony `d_capital_beats` row still captures the same death and the same eight times. Tracked references to the removed row point to historical results, not an active bench invocation.

## `godot/fx/fx.gd`

**Sound (OBSERVED).** Removing the general option leaves the dim's depth, duration, camera checks and reduced-flashing guard intact. Scene exit still calls `release(false)`: unfinished tasks retire with their inputs held, are reaped after completion, and are drained on quit. The headless exit test reaped a real A16 cut after battle teardown.

## `godot/fx/fx_death.gd`

**Defect (INFERRED), finding 1.** The added job timer changes a shared dictionary's size while the main thread can read it. The piece dictionaries themselves stay private through both cut group joins and the reach calculation. `_piece_reach` reads the exact surface and cap vertex arrays, without reading a mesh or accessing a scene node. The existing private `ArrayMesh` upload is unchanged. Both the normal result handoff and the previous-cut fallback avoid consuming a live worker's pieces. Reach is passed as a scalar in mesh units and scaled by the existing leash code; missing metadata retains the old face-read fallback.

The `_big_core` diff only changes the dim call. Capital flash sizing, smoke and spark decisions, kill pacing, Glasswright glitter, and the rest of the faction effects are unchanged by the dim removal. `peel` is assigned only to Eclipse in the live faction looks. Small deaths, Chorus rupture and the no-pieces fallback are outside the existing big-core dim path.

## `godot/fx/test/approved_effects_check.gd`

**Sound (OBSERVED).** The probe verifies the old property and environment hook are absent, exercises the dim helper on a camera, and checks the single production call is gated on `peel`. Actual faction behavior is covered by `faction_death_style_check.gd`.

## `godot/fx/test/death_cost_check.gd`

**Defect (OBSERVED), finding 2.** Good coverage of whether A16 pieces get a reach value and whether it agrees with the old face read. The check prints the speed of the cached path but never asserts that the code uses the cached value. The headless A16 fixture run measured reach work at 54.58 ms on the worker; the worst face read was 108.53 ms versus 0.007 ms with the cache, and the worst radius gap was 0.0021%. These are single-run CPU readings.

## `godot/fx/test/faction_death_style_check.gd`

**Sound (OBSERVED).** The new assertions check the plain control and four other metal factions for no dim, while keeping the positive Eclipse assertion and the original fire, tear, debris and arc checks. The probe uses cruisers; the capital path was traced in code.

## `godot/tools/ci/godot_checks.txt`

**Sound (OBSERVED).** The new script is on the headless manifest used by `godot/tools/ci/run_checks.sh` in the GitHub Godot job. The standing Node runner is a separate job and does not launch these scripts.

## Findings, highest impact first

| # | Finding | Evidence | File:line at PR head | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Worker inserts a timing key into a dictionary the main thread still reads | INFERRED | `godot/fx/fx_death.gd:1401`, `:2279` | `job["hulls_usec"] = Time.get_ticks_usec() - th`; `var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())` | A kill during a live cut can look up the seeds and break plan without joining. The worker adds `hulls_usec` to that same dictionary, which [Godot's thread rules](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html#gdscript-arrays-and-dictionaries) require synchronizing. The older `cut_usec` and windowed `geo` insertions already use this unsafe pattern; adding the timer extends it. No crash was reproduced. | Put worker results and timings in a separate result dictionary only read after the join. Alternatively, predeclare `cut_usec`, `hulls_usec` and `geo` before submitting so the worker never changes the shared dictionary's size. | High |
| 2 | The headless gate can pass even if the face-read hitch returns | OBSERVED | `godot/fx/test/death_cost_check.gd:144-145` | `pre_worst = maxf(pre_worst, _ms(p0))`; `worst_gap = maxf(worst_gap, absf(float(pre) - faces) / maxf(faces, 1e-4))` | The result of the second `_measure_reach` call is never checked. Removing only its `reach_pre` shortcut would leave the cached-count and numeric-agreement assertions green because they compare the saved metadata to the fallback read. | Keep the A16 comparison, and call `_measure_reach` on a meshless `Node3D` with a nonzero `reach_pre` sentinel. Assert `leash_rad` equals that sentinel, so the face-read fallback would fail without imposing a time limit. | High |
| 3 | The playbook still promises a removed comparison | OBSERVED | `docs/playbooks/deaths_and_hits.md:310` | `A capital death: the same, with the scene-dim proposal on and off.` | The bench row and switch required for that comparison are gone; the instruction contradicts the revised capital section. | Ask for the normal capital strip and an Eclipse core-flash strip instead. | High |

**Recommended next step:** Fix the job handoff and add the cache-use assertion before the queued solo A16 before/after run.

## Impact sweep

- **Callers:** Searched the PR tree for the changed helpers, metadata, timers, dim property and environment switch. Live paths are FX, bench and tests. The other `_piece_hulls` caller is the geometry test, which passes the same cut output. Removed bench/option references outside these paths are historical or absence checks.
- **Saves:** Checked by source and diff. `reach_pre`, `leash_rad` and the timing fields are live node/job data. The removed dim option was a setup override or environment value, not a saved preference. No profile or run load was exercised.
- **Twins:** No JS rules, Godot rules or campaign tables changed. Reach and scene dim are Godot render effects.
- **UI:** No campaign map, intel, panels or HUD reader uses these values. The battle effect remains a camera veil, and the bench still reads `reduce_flashing` by name.
- **CI:** GitHub's Godot headless manifest runs `death_cost_check`, `faction_death_style_check`, `approved_effects_check`, `cold_kill_check` and `exit_release_check`. Verified the manifest and ran all five through the same wrapper.

## Checks run

On a temporary export of `1ecbc9c3e`, Godot 4.7.2. The initial import timed out at 86%; its incremental retry completed.

```text
PASS Godot headless import (exit 0)
list: PASS (198 test scripts: 158 headless, 40 gpu, 0 retired)
faction_death_style_check: PASS (26 s)
cold_kill_check: PASS (18 s)
death_cost_check: PASS (9 s)
exit_release_check: PASS (5 s)
approved_effects_check: PASS (12 s)
PASS look moments JSON delta: exactly one row removed plus description updated
```

`git diff --check origin/main...pr1596`: PASS (exit 0, no output).

## Source record

Raw Git blobs at the pinned PR head, compared with the three-dot diff against main. Last-line prefixes below are JSON strings (`\t` represents a literal tab).

| File | Lines | First 40 characters of last line, or whole line if shorter |
|---|---:|---|
| `docs/playbooks/deaths_and_hits.md` | 327 | `"Each is one or two Codex runs and one lo"` |
| `godot/bench/look_bench.gd` | 709 | `"\treturn true"` |
| `godot/bench/look_moments.json` | 2273 | `"}"` |
| `godot/fx/fx.gd` | 2085 | `"\treturn hk"` |
| `godot/fx/fx_death.gd` | 4079 | `"\t\tnd.global_position -= back"` |
| `godot/fx/test/approved_effects_check.gd` | 351 | `"\treturn \"marked %s, shot down %s, body t"` |
| `godot/fx/test/death_cost_check.gd` | 191 | `"\tquit(0 if OS.get_environment(\"VS_1395_B"` |
| `godot/fx/test/faction_death_style_check.gd` | 208 | `"\treturn int(pool.get(\"emitted\"))"` |
| `godot/tools/ci/godot_checks.txt` | 210 | `"headless\|main/test/player_path_map_ready"` |

Large-file review ranges (plus repository caller searches):

- `godot/bench/look_moments.json`: 1-18, 1520-1608, 2210-2273; parsed and compared all rows programmatically.
- `godot/fx/fx.gd`: 140-373, 1317-1371, 1485-1549, 2080-2085.
- `godot/fx/fx_death.gd`: 292-312, 624-745, 1270-1515, 1700-1922, 1983-2000, 2264-2304, 2550-2580, 2658-2689, 2935-2979, 3285-3420, 3482-3527, 3687-3711, 3880-4079.

**Not checked:** No windowed GPU run or picture verdict; the solo installed-A16 performance run is still owed by the PR. Unchanged code outside the traced paths was not audited. Full standing checks and parity were left to the issue runner for this review-only delivery.
