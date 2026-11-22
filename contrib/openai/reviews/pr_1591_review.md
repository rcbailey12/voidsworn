# PR 1591 technical review: battle movement stage 1

PR head `58441d7`; main `fa458e3`; three-dot diff base `1a00081`.

**Hold for fixes.** The tested routes preserve their end hex and facing at 30, 60 and 144 fps. The ignition flash can disappear at lower frame rates when hurried, and the drive goes cold during straight cruise. Burn and Fire keeps the event order, but it neither guarantees the gun is ready at the stop nor measures when the shot actually fires.

## `contrib/opus/briefs/movement_spec.md`

**OBSERVED, defect (F7).** Line 59: `the hull is drawn 60 percent of the way onto the leg's straight line` conflicts with the 85 percent value in section 1b and the implementation. Mark the older numbers as the issue 521 baseline or update the live instructions in sections 1a, 2, 3 and 4 to agree with 1b.

## `contrib/opus/motion_1581/capture_motion.gd`

**OBSERVED, defect (F2).** `fire_t` records the first increment of `fired_in_act`, which occurs before the volley is even scheduled. It cannot establish when the first shot leaves the muzzle. See the evidence table below. The direct edits to movement points and enemy coordinates are confined to this capture fixture; its output is not an unmodified rules replay.

## `godot/fx/fx.gd`

**INFERRED, defect (F3).** Pre-aim selects all reachable turrets, while the volley selects mounts for its actual slot and releases only those used. An unrelated turret can slew and stay off its resting bearing indefinitely. Pre-aim also uses a different target point from the volley and applies the current hull nod and bob to the future root pose. Share the volley mount selection and target point, and cancel aims that are not consumed. See F1 for the timing side of the hand-off.

## `godot/fx/fx_ship.gd`

**INFERRED, defect (F4).** Cold trail aging uses the commanded engine level, but new ribbon points still use the eased level. During the fade the ship can add new points to the very braking trail that is supposed to disappear. See the evidence table below.

## `godot/fx/test/attach_check.gd`

**OBSERVED, sound.** Lines 281-287 feed both signs of `lift` through the same `ShipView.jet_aims` and `h.jet` path as the other movement jets. This checks the attachment points the service returns; skips are counted, so it is not evidence that every built hull emits every lift puff.

## `godot/render/ship_view.gd`

**OBSERVED, defects (F5, F9).** The root path samples elapsed time and snaps to the same endpoint at 30, 60 and 144 fps in the headless probe. Ignition and RCS do not share that guarantee: effect envelopes use the current frame's sample for the whole delta and jet puffs reset a frame-quantized cooldown. Coasting also gates its glow on acceleration, which cuts it even when a ship is flying straight at cruise speed.

## `godot/scenes/battle/battle.gd`

**INFERRED, defects (F1, F6).** Move playback is awaited before fire playback and the new path only reads event and view data. The pre-aim trigger nevertheless does not budget turret traverse time (F1), and the battle writes the Reduce motion flag to a process-wide ShipView static shared with the campaign map (F6).

## `godot/scenes/battle/test/nose_first_check.gd`

**OBSERVED, defect (F8).** Its new skid checks pass at 60 fps. It records `cold` but only asserts ShipView thrust, never the engine level that the battle sends to FX. It covers neither the other requested frame rates nor the production move-to-fire hand-off.

## Findings, highest impact first

| # | Finding | Evidence | PR file:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| F1 | Final-brake trigger cannot ensure a settled shot | INFERRED | `godot/scenes/battle/battle.gd:1826` | `if not aimed and sv.glide and float(sv.gl_p) >= _pre_aim_at(sv):` | The trigger is a fraction of flight, not time needed by the selected turret. A short or hurried move can leave less time than the traverse needs, or pass the threshold on the frame that ends the glide. The normal volley still waits for the mount's `arrive` (`godot/fx/fx_weapons.gd:225-235`) and a cinematic cut can add another wait (`battle.gd:2187-2191`). No early rules fire was found. | Work backward from the end pose and required traverse for the first volley, trigger earlier if needed, and keep the normal wait when the mount cannot be ready. Test time to the first muzzle cue against the stop. | High |
| F5 | Ignition disappears at some frame rates | OBSERVED | `godot/render/ship_view.gd:1479` | `var igniting := gl_ign_u > 0.0 and tm < gl_tm0 and tm > gl_tm0 - gl_ign_u` | Only frame samples inside the window can light the flash. Fast plus hurry and Reduce motion can step over it entirely at 30 and 60 fps (probe below). The lift and turning puffs add another sampling dependency: `_emit_jet` resets the interval at line 1520 and discards time past the intended emission. | Integrate the short envelope over the elapsed interval or use an explicit timed flash. Preserve the fractional remainder for scheduled puffs and evaluate at the emission time. | High |
| F9 | Main drive goes cold at straight cruise | OBSERVED | `godot/render/ship_view.gd:1486` | `GL_COAST * smoothstep(0.0, 0.3, maxf(v_fwd, 0.0)) * on_nose` | `on_nose` uses acceleration direction (1475-1476), which is undefined at constant speed and easily dominated by rounding. In an eight-hex straight glide with no turn, `drive_cold` was true in 51 of 89 mid-cruise samples at 60 fps. | Keep the acceleration gate for burn. Use velocity direction and speed for cruise glow, with separate braking and thruster-only guards. | High |
| F3 | Pre-aim can move turrets the volley never uses | INFERRED | `godot/fx/fx.gd:1660` | `for k in (sh.hull.turrets as Array).size():` | Bearing alone does not select the weapon slot. Only mounts actually used are released (`godot/fx/fx_weapons.gd:226,254,289-298`). Unused turrets can be left aimed. Also, the volley aims at the target hull's transformed centre (187), whereas pre-aim gets a fixed offset above the target view and uses the attacker's current hull motion (1658); the volley can need to correct the aim. | Pass the first fire event's slot, weapon and shot count. Use the same mount selection and target centre as the volley with the predicted settled pose, and release stale aims when the hand-off is dropped. | High |
| F2 | Capture calls volley entry the first shot | OBSERVED | `contrib/opus/motion_1581/capture_motion.gd:296` | `var fired := int(battle.fired_in_act.get(sid, 0))` | This counter advances at `battle.gd:2203`, before `gfx.volley` at 2255. The resulting `fire_t` can look on time while the visible shot still waits for the turret or weapon delay. | Record the first scheduled muzzle time from the volley's `fires` on the FX clock, or capture the actual emission callback. Record the stop on the same clock and fail a Burn and Fire sample that has no shot. | High |
| F4 | A cold drive can still lay fresh trail points | INFERRED | `godot/fx/fx_ship.gd:426` | `if not dead and lvl > 0.12:` | `lvl` is eased `_eng_cur` (417), but extra aging starts immediately from the commanded level (404-405). On the frames before the eased level falls under 0.12, the ship can deposit new exhaust samples while its drive is commanded cold. | Gate emission on the cold command as well as on the eased level; keep easing the visible core and aging the existing trail. | High |
| F6 | Battle comfort state leaks to the map | INFERRED | `godot/scenes/battle/battle.gd:4867` | `ShipView.calm = reduce_motion` | This is a static on the shared class. The map creates its own ShipView and sets `campaign_map` (`godot/ui/campaign/map3d.gd:225-232`), but bob checks the static before the map guard (`ship_view.gd:1739-1740`). Changing the setting outside battle does not update the static until another battle writes it. | Make comfort state per view. Set battle views from the battle setting and give map views an explicit policy from the current settings. | High |
| F7 | Live spec has conflicting movement settings | OBSERVED | `contrib/opus/briefs/movement_spec.md:59` | `the hull is drawn 60 percent of the way onto the leg's straight line` | Section 1b says 85 percent. Old drive, turn and clearance instructions also remain in live sections, and line 118 omits the exceptions in RULEBOOK 7.9. | Update the live sections and label the old measurements as historical. Refer to 7.9 without stating a blanket rule. | High |
| F8 | The CI check does not test the new FX contract | OBSERVED | `godot/scenes/battle/test/nose_first_check.gd:188` | `if float(x.thrust) > 0.02:` | A cold-drive assertion can pass while the battle still sends a warm engine command. The test manually steps ShipView at 60 fps (116-125) and has no production volley. | Reuse the route check at 30, 60 and 144 fps; assert commanded and displayed drive state on the battle path and check the actual first-shot cue after the move. | High |

**Recommended next step:** Fix the drive and pre-aim paths, then rerun one real turret-equipped Burn and Fire with muzzle-time telemetry and the movement probes at all three rates before merging.

## Integration checks

- **Callers:** Searched the PR tree for the changed glide options and helpers, engine and trail fields, jet attachments, pre-aim and comfort state. The production path is `_play_batch` to `_play_event` to `_play_move`, then the normal `_play_fire`. The other direct `play_glide` callers are headless checks; their default options still work. No active users of removed `GL_POINT`, `GL_TRAIL`, `NF_POINT` or `NF_TRAIL` were found.
- **Saves and replay:** Reviewed `_round_capture` and `snapshot_fingerprint` in `godot/rules/battle_api.gd`. That payload saves the rules state and seeded RNG, not flight or FX state. Existing profile/legacy paths passed `run_resume_test.gd`; cold round Continue passed `round_save_entry_test.gd`. Packaged builds can still fall back to the map checkpoint when their existing build-commit fingerprint changes. The fixture's direct rules writes are capture-only; production visual replay is not frame-identical (F5).
- **Twins:** The three-dot diff has no changes to `battle.js`, `data.js`, `core.js`, `godot/rules/` or `godot/campaign/`. Production reads the path and post-command event stream but does not write hexes, facings, shots or rules RNG. No export or oracle refresh needed.
- **UI:** Rules-facing route, HUD and intel values are unchanged. The flight path and HUD aim/fire cues remain separate. The settings UI writes the existing `reduce_motion` key, but the map's shared renderer reads a stale static (F6).
- **CI:** PR 1591 changes existing tests. `godot/tools/ci/godot_checks.txt` already lists `attach_check.gd`, `nose_first_check.gd`, `movement_flight_check.gd` and the save checks. `.github/workflows/checks.yml` runs standing checks, rules and campaign parity, rules safety and Godot game checks for game changes. This review-only file takes the docs-only route.

## Checks run

- PASS: PR fetch, eight-file three-dot diff, `git diff --check`, and empty diff for the rules twins and campaign directories.
- `PASS PR head headless import` (resumed after the first import timed out at 90%). All Godot runs used an exported PR tree in system temp.
- `nose first: PASS` at 60 fps on the unmodified test. `nose first: PASS` at 30 and 144 fps with only `dt` changed in the temp copy. Worst reported skid across the three runs: 4.4 degrees.
- `movement flight: PASS`.
- `ATTACH_CHECK PASS: 3 hulls, 0 failures, 0 effects skipped by the walk`. Stand-ins only; the deliberately broken muzzle was rejected as expected.
- `PASS: 1 legacy: an already stranded story boss reopens with the chosen power`; `PASS: 9: a damaged Career primary and two blocked writes leave the last good copy readable` (`run_resume_test.gd`).
- `PASS  event: a cold Continue resumes round 2 (page battle)`; `PASS  failed write: Continue opens the map checkpoint, nothing settled (page map)` (`round_save_entry_test.gd`).
- `PASS endpoint at 30/60/144 fps` in a manual-delta headless escort probe with Reduce motion. At normal speed the pre-motion ignition had 1, 3 and 7 positive samples respectively. With Fast (0.45) and the in-flight hurry multiplier (0.18), it had 0, 0 and 1. The separate straight-cruise probe printed `Straight mid-cruise: 51/89 cold frames` at 60 fps. Endpoints passed; the ignition and cruise observations fail the visual intent.
- `PASS: 9 exact quotes, 8 line-count and last-line records, ASCII only`.
- `PASS: docs_only=true; all 1 changed file(s) are docs or pictures`. The first CLI attempt could not open `/dev/stdin` on Windows; the same classifier passed when called directly.

## Source read record

Line numbers and last lines are from raw Git blobs at `58441d7`. Below are the first 40 characters of the last line (or the whole line if shorter), with tabs escaped.

| PR file | Lines | Last line prefix | Ranges for large files |
|---|---:|---|---|
| `contrib/opus/briefs/movement_spec.md` | 189 | `"- Ryan's eye: the motion strips at the b"` | |
| `contrib/opus/motion_1581/capture_motion.gd` | 376 | `"\treturn [{\"cls\": cls, \"kind\": kind, \"tar"` | |
| `godot/fx/fx.gd` | 2108 | `"\treturn hk"` | 1645-1668, 1721-1845, 2108 |
| `godot/fx/fx_ship.gd` | 2094 | `"\t\t_dmg_request(fx)"` | Diff hunks, 105-135, 353-454, 2094 |
| `godot/fx/test/attach_check.gd` | 529 | `"\treturn n"` | |
| `godot/render/ship_view.gd` | 1759 | `"\t\tring.rotation.y = -rotation.y"` | Diff hunks, 598-667, 928-1141, 1241-1281, 1318-1386, 1409-1550, 1759 |
| `godot/scenes/battle/battle.gd` | 6415 | `"\tget_tree().quit(code)"` | Diff hunks, 1210-1229, 1280-1382, 1403-1512, 1729-1885, 2180-2310, 3619-3641, 6415 |
| `godot/scenes/battle/test/nose_first_check.gd` | 196 | `"\t\tfails.append(\"%s: flown on thrusters, "` | |

**Not checked:** Real-hull gameplay clips or capture images, actual muzzle emission on a built turret, full seeded replay/log comparison, or the full standing and parity suites. This was a technical review of the pinned PR and its affected paths, not a review of unrelated ranges in the large files. The runner handles the delivery branch checks.
