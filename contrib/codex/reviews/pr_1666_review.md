# PR 1666 review

**Return for fixes.** The batch marks preserve the raw rules causes and clear on a later volley, but a kill-triggered action can clear them before their own death is played. The new effects override the acid death, interrupt the Meridian Directorate strain animation and add Glasswright smoke. The new check can miss a broken beat.

Refs #1586. PR head `522f6f5e7e25c30d7541f29469fb29f1ad908bdf`. Compared with local `origin/main` at `8a3c5d026f82b921675ab09b111e59417fb7bb8b`, merge base `e0c8b4076e330adea720313d1ee8e307a95fb710`. The exact PR head was already present locally.

## Findings

| # | Finding | Evidence | File and line | Exact quote | Effect | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | A kill-triggered volley or wing launch clears its parent death mark | OBSERVED | `godot/scenes/battle/battle.gd:2758` | `marks.clear()` | `killUnit` can fire Rolling Fire at a different enemy or create a Brood Tithe wing before emitting its original `death` (`rules.gd:3996–4029,4058`). Both `fire` and `wing` clear all marks. A valid ram or scuttle then plays the generic `big` or `dark` death, even though its own kill is still being resolved. | Keep a pending mark through nested events that cannot own its death. Match death unit, raw cause and killer to the initiating ram or board, and invalidate on an actual competing action or a batch boundary. Test the nested volleys and wing launches alongside both stale-mark cases. | High |
| 2 | Acid deaths pick up faction beats, fire or vapour | OBSERVED | `godot/fx/fx_death.gd:3589` | `BEATS.on_break(fx, s, wreck, cause, center, xf)` | The hook also runs for `melt`. A Hullbreaker cruiser schedules two fire and smoke cook-offs at lines 358–362 of `fx_death_beats.gd`. Other factions can schedule vents or their signatures and small hulls can acquire a drive flare. R398 reserves this death for the acid hit patches. | Skip both new break and tell beats for `melting(s)`. Keep the existing acid path and exercise acid kills of each metal faction. | High |
| 3 | The Directorate blackout stops the strained hull’s animation clock | OBSERVED | `godot/fx/fx_death.gd:2555` | `(mats[i] as ShaderMaterial).set_shader_parameter("death_age", 0.0 if lit else 99.0)` | The hull’s vertex deformation reads `death_age` at line 2391. The tear overlay uses `scene_t` in `fx_shaders.gd:2231`. Directorate plating stays unstrained until the blackout jumps it to full strain, while the crack grows on the normal timeline. | Use a separate blackout uniform for light emission and keep real `death_age` on the Directorate hull and its overlay. | High |
| 4 | Glasswrights emit smoke on the new clean-collapse path | OBSERVED | `godot/fx/fx_death_beats.gd:449` | `0.22, L * 0.004, L * 0.025, 7` | Glasswright afterlife always takes this branch because `ember` is false. Kind 7 goes to the smoke pool (`fx.gd:701,723`). Flay also emits kind 7 on Glasswright hulls at line 138, including just before the nominal split. The existing texture-smoke exclusion cannot filter either call. | Keep Glasswright afterlife and flay cues as translucent light or glitter using a non-smoke emitter. | High |
| 5 | Chorus bypasses ram, tidal and boarding-scuttle routing | OBSERVED | `godot/fx/fx_death.gd:2281` | `fx.later(T + otl.cut, func l_break_up() -> void: _break_up_when_ready(fx, s, "rupture",` | The organic branch returns before `board` is recognized as a cold hulk or ram and tidal reach `BEATS.on_death`. The rules permit scuttling an eligible enemy flagship or transport without a faction restriction (`rules.gd:3894–3917`). A Chorus scuttle therefore ruptures and a Chorus ram or tidal kill loses its cause cues. | Handle the cold scuttle before organic rupture. Pass the ram or tidal cue alongside the approved Chorus rupture on breaking kills, with a headless case for each precedence decision. | High |
| 6 | Physical shreds can allocate new bodies and disappear on Low | OBSERVED | `godot/fx/fx_death_beats.gd:314` | `_death().spawn_debris(fx, p, vel + s.get_meta("death_velocity", Vector3.ZERO), n,` | `fx_death.gd:529–565` returns with physics off and creates a body, collision shape and mesh node while the shared pool is below cap. Extra flay, tether and snap shreds add work on the break frame. The marker is still recorded when the low-quality call emits nothing. | Use the existing `fx.shd` pool for the cosmetic extra shreds, or reserve physical slots before battle and give Low a pooled shard fallback. | High |
| 7 | Ram recoil sparks can start at the last unrelated hit | INFERRED | `godot/fx/fx_death_beats.gd:149` | `var sh := _shot(fx, s)` | Playback sends the ram hit only to the target at `battle.gd:1591–1593`, while the rules can kill the rammer from recoil. The rammer’s `_shot` can therefore use an unrelated recent hit or fall back to its core, even though its contact was at the prow. | Pass a ram-specific contact and direction for both endpoints, or choose the rammer’s prow explicitly on recoil deaths. | High |
| 8 | The check accepts missing fracture effects and partial blackouts | OBSERVED | `godot/fx/test/death_variety_1586_check.gd:52` | `_has(res["ithar"]["beats"], "web") and _has(res["ithar"]["beats"], "shafts")` | Both strings are recorded before the ribbon is emitted. Line 188 saves the ribbon count but no assertion reads it. The Directorate check at line 180 accepts any one dark surface, and the box fixture has one. Chorus similarly tests a scheduling marker instead of two or three rotations. | Assert actual emissions in separate tell and break windows and observe two or more surfaces switching off together. Require the check to fail when a beat’s emission is removed with its marker intact. | High |
| 9 | The capture manifest leaves tidal and strike craft unseen | OBSERVED | `godot/bench/look_moments_1586.json:509` | `"id": "dv_cause_dark",` | The four cause rows are flay, ram, board and dark. The remaining rows cover faction signatures and small hulls. There is no tidal row with a finite well or a strike-craft death row, so this sheet cannot verify those looks. | Add those two rows and the small harness inputs they need for the well and squadron flag. Keep camera 170 as the first proof. | High |
| 10 | The playbook promises archetypes and afterlife on excluded hulls | OBSERVED | `docs/playbooks/deaths_and_hits.md:223` | `Frigates and destroyers die` | The archetype paragraph includes all frigates and destroyers, although dark and board hulks and Chorus take other routes. Line 226 promises afterlife for a big wreck, although the hook excludes Chorus and hulks. | State the exclusions or extend the implementation and its checks if the promise is intended to cover them. | High |

## `docs/playbooks/deaths_and_hits.md`

**Defect (OBSERVED), finding 10.** The new text gives the gauss shreds as the built fallback for the approved one-crack break. Its small-hull and afterlife statements omit the implementation’s exclusions.

Read proof. 358 lines. Last line starts with `Each is one or two Codex runs and one lo`.

## `godot/bench/look_bench.gd`

**Sound for the supplied rows (OBSERVED).** Lines 658–663 apply the override only on death rows that carry an `arch` key and have an FX ship. The supplied rows send 0 through 3. The override belongs to the row’s newly set up target.

Read proof. 735 lines. Last line starts with `	return true`.

## `godot/bench/look_moments_1586.json`

**Defect (OBSERVED), finding 9.** The manifest parses and has 14 unique rows at cameras 170 and 26. All rows use the death hook. There is no tidal setup or craft-loss row, so the sheet alone cannot cover those two looks.

Read proof. 753 lines. Last line starts with `}`.

## `godot/fx/fx_death.gd`

**Defect (OBSERVED), findings 2, 3 and 5.** The fracture plan and big-hull piece count are still owned by the existing breakup path. Extra flay shreds leave through a separate emitter. The Eclipse dim gate stays on the peel style. The new hooks bypass the acid and Chorus guards in different ways, and the Directorate clock override interrupts the one-crack deformation.

Read proof. 4200 lines. Last line starts with `		nd.global_position -= back`.

## `godot/fx/fx_death_beats.gd`

**Defect (OBSERVED), findings 2, 4, 6 and 7.** The sprite, streak, ribbon, shard and light calls use shared pools. New delayed callbacks generally resolve wreck references before use. Hullbreaker cook-offs check the stored node before reading it. No beat frees a pool node. The pools can still overwrite live slots under load, and the physical shreds can allocate new bodies and wake Jolt.

Read proof. 472 lines. Last line starts with `			_implode(fx, s, p, T - 0.25)`.

## `godot/fx/test/death_variety_1586_check.gd`

**Defect (OBSERVED), finding 8.** The test covers the ordinary cause-to-metadata path and several delayed callbacks. The visible fracture web can be lost while the test still receives its marker. The Directorate fixture checks whether any surface went dark.

Read proof. 192 lines. Last line starts with `	return res`.

## `godot/scenes/battle/battle.gd`

**Defect (OBSERVED), finding 1.** Lines 1271 and 2752–2777 build fresh marks from the ungrouped event list and consume the matching death marker once. Both single-shot and grouped volleys have a `fire` boundary in that list. The rammer and target are both marked, scuttle marks only its target, and all other boarding outcomes clear prior marks. The view returns the raw cause when a mark is missing or incompatible. The clear is too broad when a kill itself inserts a follow-up action before its death event. The recoil position also needs a source, as shown in finding 7.

Read proof. 6590 lines. Last line starts with `	get_tree().quit(code)`.

## `godot/tools/ci/godot_checks.txt`

**Sound (OBSERVED).** Line 120 registers the new script in the headless roster with both optional input fields disabled. The adjacent existing death checks remain in place.

Read proof. 233 lines. Last line starts with `headless|main/test/player_path_map_ready`.

## Cross-checks

- **Rules (OBSERVED).** The three-dot path diff is empty for `godot/rules/` and `battle.js`. The rules still emit `big` for either ram death and `dark` for scuttle. The tags are picked up only in the battle view.
- **Eclipse (OBSERVED).** The normal implosion is violet with a dark core at `fx_death_beats.gd:399–410`. The afterlife uses the violet `damage_glow` in `faction_looks.json`. The existing scene dim remains gated on peel at `fx_death.gd:3044–3046`.
- **Frame work and lifetimes (OBSERVED).** The PR adds a branch and metadata reads to the existing dying-hull update. Other new work is bounded per death, but the common scheduler scans outstanding timers every step, including new corridor flickers and afterlife timers (`fx.gd:673–685`). The shared ribbon pool has 192 slots and wraps without checking the old slot’s end time (`fx.gd:375`, `fx_pool.gd:158–175`). **INFERRED.** Wrapping while a ribbon is still live can cut it short without freeing its node. Wreck-dependent callbacks guard against deleted wreck nodes.
- **Large-file read ranges.** Full blobs were loaded. Focused reads covered `fx_death.gd` 285–325, 350–390, 508–615, 842–880, 2200–2349, 2360–2402, 2415–2525, 2540–2638, 2756–2795, 3010–3072, 3328–3510, 3513–3641 and 3855–3991, plus the remaining changed hunks. For `battle.gd` they covered 96–105, 1269–1427, 1560–1633, 2441–2459 and 2747–2845.

## Checks

- **Godot 4.7.2 headless, unmodified PR head.** The new check returned exit 0 and `DEATH_VARIETY failures=0`. Godot’s dummy renderer logged null-material messages, so this run gives no rendered evidence.
- **Nested-action probe on the PR head.** Headless Godot returned exit 1. Plain ram and scuttle returned `ram` and `board`. Inserting a follow-up volley to another unit returned `big` for the original ram. Inserting a kill-triggered wing launch returned `dark` for the original scuttle. The probe replayed the producer’s order with synthetic events.
- **Broken-beat probe.** In the temporary copy, setting the Glasswright web loop to zero while keeping its marker still returned exit 0 and `DEATH_VARIETY failures=0`. The test printed that the web passed. Removing its marker as well made the script exit 1 with exactly one failed assertion.
- **Existing headless checks on restored PR source.** `faction_death_style_check.gd`, `death_story_check.gd` and `melt_death_check.gd` all returned exit 0.
- **Standing checks on the delivery checkout.** `node contrib/opus/tools/run_all_checks.js` exited 1 with 100 passes, two known-baseline rows and six failures. The failing rows were `doc_check_tests`, `gpu_slots_tests`, `picture_provenance_tests`, `publish_ship_tests`, `pysite_1535_tests` and `stage5_fail_selftest`. The documentation check passed on targeted retry after clearing the unreadable test fixtures. The full suite ran on the delivery checkout at the stated main commit.

## Recommended next step

Return PR 1666 for fixes to mark ownership and approved death looks, with tests that watch the actual effects.

## Not checked

Rendered appearance, authored-hull playback, saturated GPU pool behavior and frame-time measurements. Lane D is code-only, and R407 holds PR captures until the checks and review pass.
