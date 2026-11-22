# PR 1593 review: effects audit and first-salvo torpedo stall

PR head `58a56ead5`; checkout main `7539aa9a3`; three-dot diff base `1a0008134`. Line numbers below are at the PR head. Review scope: the eight changed files, with related callers and checks traced for impact.

**Hold PR 1593.** The hit pause overruns on slow frames, and the delayed veil uses a stale wreck position. The shared meshes remove the reported allocation churn, but issue 1528's first-salvo limit and the approved looks still need rendered evidence.

## godot/fx/fx.gd

**OBSERVED, defect at long frame deltas.** The countdown now lives in runtime seconds and hurry clears it. Loading awaits the munition warm-up after both the starting fleet and known arrival previews are registered. The hit-pause step still applies its depth to a whole frame even if only a fraction of the requested pause remains.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | A long frame can overrun the requested hit pause | OBSERVED | `godot/fx/fx.gd:490` | `var dt = delta * _speed` | A local probe measured 66.7 ms at 30 fps and 100 ms during a hitch for a requested 50 ms. The effect clock drives visible hits, sound and HUD updates. | Split a step at the remaining pause time, then apply recovery to the rest; test 30 fps and a mixed sequence with a hitch. | High |

## godot/fx/fx_death.gd

**OBSERVED, defect on a moving wreck.** The delayed spawn now correctly shares its real birth time with the pool timer. The three fog opt-outs cover the named death materials. The veil still needs a live position at its new birth time.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 2 | The delayed veil uses the wreck's old pose | OBSERVED | `godot/fx/fx_death.gd:2939` | `_core_gas_veil.bind(fx, s, p, capital, s.get_meta("death_velocity", Vector3.ZERO) * 0.5, frame)` | Both `p` and `frame` come from the flash pose. Moving a stand-in piece by 2 units after the flash left the veil at the old point. The stale frame also lets the spawn-radius check miss that offset. | Bind the existing weak piece reference and local point. At birth, check that the piece is still valid and sample its current point and frame before spawning and recording. | High |

Integration note: Artoo's comment on PR 1593 identifies an overlap with PR 1583. If PR 1583 lands too, keep its `not melting(s)` guard around the delayed spawn.

## godot/fx/fx_shaders.gd

**OBSERVED, sound in the diff.** The kit variant retains the original fragment shader, fog opt-out, pixel width floor, colour and seed. Its neighbour difference points the same way as the old CPU mesh. The last valid edge and the first unused center are collinear, so the extra triangles have zero area; later pairs collapse to the same point. Shader execution and visual equivalence need a rendered check.

## godot/fx/fx_weapons.gd

**OBSERVED, shared-mesh lifetimes are sound; heat-ring defect below.** The quad and kit strip are retained in the FX cache and by the nodes drawing them. A hit or intercept transfers trail history to the fade list; only that trail node is queued for deletion once fewer than two live points remain. Hull heat updates the existing mesh buffer, with the damage root owning the node. Each non-kit round gets its own material values. The aspect replacement matches the inherited shader and leaves aspect-1 calls alone. The GLB cache keys and lit/dark materials match the launch code. The headless run measured 59.7 ms in warm-up and 0.74 ms to construct a warmed kit round; this is no proof of the rendered frame limit.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | A dense barrage can remove still-hot marks | INFERRED | `godot/fx/fx_weapons.gd:1936` | `const HEAT_RING := 24` | The old per-hit batches lived to their own timers. The new ring starts overwriting on sample 25 even if no mark has finished. The sizing comment assumes about 2 s; lance and torpedo spots last 3 and 4 s, and one sustained beam emits several spots. An active mark can blink off in focus fire. | Size the ring from peak overlapping spots measured on one target, or reuse expired slots first and give any forced eviction a fade. | Medium |

## godot/fx/test/fx_audit_1558_check.gd

**OBSERVED, defect in what the test proves.** The test passed locally. It covers data reuse and clock movement at 60/144 fps, but its white-box checks do not exercise several claimed outcomes.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 4 | The warm-up assertion counts nodes but claims a draw | OBSERVED | `godot/fx/test/fx_audit_1558_check.gd:239` | `_check(strips == 1, "1528: the kit trail strip is drawn in the warm-up in its own vertex format")` | The test calls the helper directly with no rendered frames. It would pass if the strip were culled or the pipeline first compiled during the salvo. The veil test likewise calls the spawn helper directly and checks source text for the delay, so it misses the stale-pose defect. | Label the warm-up test as structure only; use the PC timing run for draw/compile proof. Exercise the scheduled veil on a moving wreck, including the early window and pool return. | High |

## godot/fx/test/fx_audit_1558_shots.gd

**OBSERVED, defect in the evidence.**

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 5 | The jets never get their required battle-distance comparison | OBSERVED | `godot/fx/test/fx_audit_1558_shots.gd:72` | `var d := 170.0 if scene == "veil" else 60.0` | The probe's opening comment says 170, but only the veil is shot there. Issue 1558 and the effects playbook require the comparison where the game is played. Its synthetic setup also cannot prove the muzzle still reads on a real hull. | Capture the actual muzzle at 170 first; use 60 as an extra detail view. | High |

## godot/render/squadron_wing.gd

**OBSERVED, sound for the live sampling path.** Active wings remove expired points on the same step that adds one; the default shader already clamps expired samples to zero alpha. The renderer still owns the same `ImmediateMesh`; `clear_surfaces()` and the rebuild run together during the step rather than freeing the node or mesh. Teleport resets and inactive fade-out can still rebuild outside a sample step, intentionally. The live weapon path also has a separate `SH.CRAFT_TRAIL` material override; the wing's fog flag is for the fallback shader.

## godot/tools/ci/godot_checks.txt

**OBSERVED, sound.** Both new scripts are classified correctly. The headless regression at line 125 runs in GitHub's Godot game checks. The capture probe at line 197 is GPU-only and is not run by the headless job. GitHub's check runs for `58a56ead5` report success for All checks, Godot game checks, Godot rules parity and standing checks.

## Impact sweep

- Callers: repo-wide search traced the clock/hurry calls, initial fleet and arrival warm-up, pooled death materials and veil, live and attack-run wing trails, both projectile fade paths, and all heat-spot callers. Warm-up stores its count in runtime `dstate`; there is no caller reading that count.
- Saves: the profile and battle-round snapshot contain no FX cache or clock fields. Loaded a profile and run written by the pre-PR campaign script into the PR head; backup and round-resume checks also passed.
- Twins: no rules, JS oracle files or exported tables changed. No re-export applies. GitHub's PR-head rules-parity check is green; no local parity run.
- UI: campaign map, intel and panels read no changed fields. Battle HP, shield break, floating hit numbers and audio still use the shared arrival path; the hit timing check passed. Their pacing can still shift together on the long frame in finding 1.
- CI: the two new Godot entries belong in `godot/tools/ci/godot_checks.txt`, which `checks.yml` runs via `run_checks.sh`. Only the headless check executes in CI; the GPU probe is listed for coverage and the Node standing runner has no new JS test to register.

## Verification

- `git fetch origin pull/1593/head:pr1593` and three-dot diff: eight files. Dry merge with `git merge-tree --write-tree origin/main pr1593`: clean. `git diff --check origin/main...pr1593`: clean.
- Windows Godot 4.7.2, imported in a scratch copy of the PR. Local output:

```text
fx_audit_1558_check: PASS
MUNITION_BODY_CHECK PASS, 0 failures
KILL_SLOWMO cruiser core 1.66 beat 1.67-1.84 | capital core 2.28 beat 2.30-2.47 | failures=0
hit timing: PASS ([miss, miss, hit] on the effect clock under hit pause; shield break on the second of three hits; target ringed and named; lance cues on the effect clock; null lance, glass critical and ion lock combined)
save: PASS
PASS  Continue from disk starts round 2, the last round that reached the disk (got 2)
PASS: PR head loads a pre-PR profile and run (renown, faction, credits, fleet size)
FAIL: 50 ms pause applied at crawl for 66.7 ms ([0.03333333333333, 0.03333333333333])
FAIL: 50 ms pause applied at crawl for 100.0 ms ([0.1])
FAIL: veil birth x 0.0, live wreck lip x 2.0
```

- The hit timing run logged placeholder hulls and a ledger `Rect2` diagnostic. The local death-spawn probe stopped at `placeholder hull: 1 hull(s) had no built file; no picture written`; it is not counted as a pass. The scratch copy did not have the installed ships.

Raw Git blob record (`58a56ead5`): line count, final line clipped to 40 characters, and main review ranges for the large sources. `\t` represents a tab and `""` a blank line.

| File | Lines | Last line prefix | Review ranges |
|---|---:|---|---|
| `godot/fx/fx.gd` | 2097 | `\treturn hk` | 106-114, 207-272, 405-513, 618-656, 1179-1305, 1525-1715, 1885-2097 |
| `godot/fx/fx_death.gd` | 4054 | `\t\tnd.global_position -= back` | 120-209, 331-449, 2862-2971, 3425-3505, 3630-3667 |
| `godot/fx/fx_shaders.gd` | 2420 | `"""` | 100-157, 923-1042 |
| `godot/fx/fx_weapons.gd` | 2466 | `""` | 95-101, 618-812, 853-912, 1010-1424, 1441-1514, 1574-1738, 1913-1948, 2184-2223 |
| `godot/fx/test/fx_audit_1558_check.gd` | 254 | `\tt1.free(); t2.free(); t3.free()` | 1-254 |
| `godot/fx/test/fx_audit_1558_shots.gd` | 116 | `\treturn fx.ships["veil"]` | 1-116 |
| `godot/render/squadron_wing.gd` | 460 | `\tmesh.surface_end()` | 1-146, 355-460 |
| `godot/tools/ci/godot_checks.txt` | 211 | `headless\|main/test/player_path_map_ready` | 122-128, 193-200 |

**Recommended next step:** Correct the pause and veil, then run the pinned PC before/after review: RUN8 first salvo and `r4_x09` below 33 ms, plus camera-170 shots of the live effects on installed hulls.

**Not checked:** The capture attempt never got a shared GPU slot, so there are no new pictures or verified visual matches. The PR's cited cloud comparison sheets were not in the checkout. The PC RUN8 timing proof was not run; the staged timing launcher also names an earlier revision, so pin the reviewed head for new evidence. I did not rerun the full standing pack or campaign parity for this review-only delivery.
