# Outside Review of PR #1914: Opt-in Brisk Camera with Sticky Skip

**Verdict: 1 blocking bug before merge (confirmed independently of Artoo).** Pressing `K` during a protected cruiser, capital, or flagship kill hold still calls `_kill_skip()` and cuts the big-kill slow-motion beat (`battle.gd:4019-4022`), contradicting issue #1871 ("the big-kill slow-mo and section damage stay exactly as today").

**Direct answers to the three review questions:**

1. **Overlap with `main` (PR #1890 `88c21aca7` / `b35fd854` lineage, PR #1892 `f23f4c5b4`) and PR #1445 (`98926849`):** Clean merge with no lost behaviour. `git merge-tree --write-tree` merges `main` + PR #1914 (`f6aaaaf89`) and `main` + PR #1914 + PR #1445 (`609e68ca3`) with zero conflicts. In `battle.gd`, PR #1890's `_deployment_api` guard stays at the top of `_unhandled_input`, PR #1445's sliced load stays in `_begin` below PR #1914's camera resets, and PR #1445's `main.gd` retains all three `_settings_to_battle(b)` calls. In headless Godot 4.7.2 on both merged trees, `brisk_camera_check.gd`, `skill_target_picker_test.gd`, `front_end_test.gd` (all 22 Settings rows fit 1920x1080 Larger without scrolling, plus narrow scroll), and `save_quit_handoff_check.gd` all pass (exit 0, 0 `SCRIPT ERROR`).
2. **Off by default and sticky across battles and reloads?**
   - **Off by default: YES** in the live game (`main.gd:21` sets `"brisk_camera": false`, `_load_settings` at `main.gd:206` overlays saved JSON keys onto defaults so older `settings.json` files stay `false`, `main.gd:319` uses `settings.get("brisk_camera", false)`, `battle.gd:167` defaults to `false`). One minor hardening gap: `title.gd:539-540` defaults any missing toggle key in `main.settings` to `true` (not hit by real `main.gd`).
   - **Sticky across battles and reloads: YES for the `Brisk camera` setting, NO for the `K` per-kind skip.** `brisk_camera` persists to `user://settings.json` from Title Settings (`title.gd:547`) and the in-battle menu (`battle.gd:5504` -> `main.gd:327-329`). The `K` per-kind skip (`_skipped_camera_kinds`) is battle-local in memory only: it is cleared in `_begin(a)` (`battle.gd:544`), lost on every new battle (matching issue #1871 item 2's "for the battle"), and also lost on mid-battle `Save and quit to title` -> `Continue run` reload because `campaign_host.gd:204` saves only the rules snapshot.
3. **Does `brisk_camera_check.gd` drive the live battle path or a test-only branch?** There is **no test-only branch** in `battle.gd` (`_cine_wants`, `_follow_enemy_activation`, `_skip_current_camera_kind`, `_play_fire`, `_unhandled_input`, `_on_key` are live code), **but** `brisk_camera_check.gd` bypasses the live battle event loop (`_runner` / `_play_batch` / `_play_death`) and disk `settings.json` I/O. It drives private helpers directly with synthetic `VU` entries and a zero-shot fire dict (`shots: []`) with no `ShipView`, never testing `KEY_K` during a kill hold, during volley flight, during the 900 ms tail wait, or across a real `settings.json` reload.

- **Reviewer:** Neon
- **Date:** 2026-11-23
- **PR / commit reviewed:** PR #1914 (`codex/issue-1871`) at `86049dda` (full `86049ddac3297e7d1e5bae5327bc30f63906c553`)
- **Comparison heads:** `origin/main` at `b20601525` (includes PR #1890 merge `88c21aca7`, PR #1892 `f23f4c5b4`, PR #1900 `b35fd854c`), PR #1445 (`opus/issue-1434`) at `98926849`
- **Engine (headless checks):** Godot `4.7.2.stable.official.ed1daf0bf` (Windows console exe, `--headless`, throwaway `APPDATA`)

---

## Proof of Reading (`docs/REVIEW_PROTOCOL.md`)

| File | Commit | Total lines | Ranges read | First 40 chars of last line |
|---|---|---|---|---|
| `docs/REVIEW_PROTOCOL.md` | `b20601525` | 35 | 1-35 | `- Claude checks every claim against the ` |
| `godot/main/main.gd` | `86049dda` | 741 | 1-741 | `	return str(v)` |
| `godot/main/title.gd` | `86049dda` | 691 | 1-691 | `	_reveal_tw.tween_property(_shade, "colo` |
| `godot/scenes/battle/battle.gd` | `86049dda` | 7144 | 140-215, 530-620, 1245-1420, 1495-1620, 2180-2520, 2730-2965, 3980-4170, 5390-5530, 7125-7144 | `	get_tree().quit(code)` |
| `godot/scenes/battle/test/brisk_camera_check.gd` | `86049dda` | 153 | 1-153 | `	quit(1 if failures != 0 else 0)` |
| `godot/ui/battle/hud.gd` | `86049dda` | 1536 | 470-490, 1525-1536 | `	ledger.mark()` |
| `godot/ui/test/front_end_test.gd` | `86049dda` | 356 | 1-160, 345-356 | `	mp.queue_free()` |
| `godot/tools/ci/godot_checks.txt` | `86049dda` | 255 | 95-110, 245-255 | `headless|render/test/hull_age_check.gd|-` |
| `godot/rules/battle_api.gd` | `86049dda` | 1217 | 260-265, 1105-1155 | `	return why` |
| `godot/main/campaign_host.gd` | `86049dda` | 455 | 164-240 | `	run_over.emit({"result": "win" if won e` |
| `godot/main/main.gd` | `98926849` | 1020 | full diff vs `0631c3e1` | `	return str(v)` |
| `godot/main/title.gd` | `98926849` | 692 | full diff vs `0631c3e1` | `	_reveal_tw.tween_property(_shade, "colo` |
| `godot/scenes/battle/battle.gd` | `98926849` | 7580 | diff vs `0631c3e1` (hunks in `_ready`, `_begin`, `_exit_tree`) | `	get_tree().quit(code)` |
| `godot/ui/battle/hud.gd` | `98926849` | 1557 | full diff vs `0631c3e1` | `	ledger.mark()` |
| `godot/scenes/battle/battle.gd` | `b20601525` | 7143 | full diff vs `0631c3e1` | `	get_tree().quit(code)` |
| `godot/main/title.gd` | `b20601525` | 699 | full diff vs `0631c3e1` | `	_reveal_tw.tween_property(_shade, "colo` |
| `godot/ui/test/front_end_test.gd` | `b20601525` | 715 | 1-45, 135-260 | `	mp.queue_free()` |

---

## Findings

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence (high/med/low) |
|---|---|---|---|---|---|---|---|
| 1 | **BLOCKING:** Pressing `K` during a protected big-kill slow-mo hold calls `_kill_skip()` and cuts the kill beat (and `K` during opening calls `_end_opening()`). Live headless probe confirmed `hold_before=1.91 hold_after=-1.00 cine_after=false` and `opening before=true after=false`. | OBSERVED | `godot/scenes/battle/battle.gd:4019-4022` | `_kill_skip()` / `if e is InputEventKey and e.keycode == KEY_K:` | Issue #1871 requires big-kill slow-mo to stay untouched, and `hud.gd:481` documents `K` as routine shot/follow skip only. A late `K` press as a shot turns lethal cancels `gfx.skip_death_slowmo()` (`battle.gd:2824`). Lines 4021-4022 only stop `K` from falling through to `_on_key`. | Exclude `e.keycode == KEY_K` from the `kill_hold_until > 0.0` (and `opening`) dismissal guards in `_unhandled_input`, and assert in `brisk_camera_check.gd` that `KEY_K` leaves an active kill hold intact. | high |
| 2 | `K` per-kind skips (`_skipped_camera_kinds`) are in-memory per battle only: cleared on next battle and lost on mid-battle `Save and quit` / `Continue` reload (whereas `brisk_camera` persists in `user://settings.json`). | OBSERVED | `godot/scenes/battle/battle.gd:544` and `godot/main/campaign_host.gd:204` | `_skipped_camera_kinds.clear()` / `return C.save_battle_round(api_now.take_round_snapshot())` | Clearing on next battle matches issue #1871 item 2 ("for the battle"), not cross-battle stickiness. Even within one battle, a player who presses `K` ("skipped for this battle"), saves and quits, and resumes via Continue loses their skip. | Confirm single-battle scope for `K`; if mid-battle reload or cross-battle stickiness is wanted, persist `_skipped_camera_kinds` in round-save metadata or `user://settings.json`. | high |
| 3 | `brisk_camera_check.gd` bypasses the live battle event loop (`_play_batch` / `_play_death`) and disk `settings.json` persistence, calling private helpers with synthetic `VU` rows and an empty-shot fire dict. | OBSERVED | `godot/scenes/battle/test/brisk_camera_check.gd:90,132,139` | `b.VU.merge({` / `var shot := {"unit": "escort", "target": "cruiser", "kind": "lance"` / `await b._play_fire(shot, [])` | Because `shot` has `shots: []` and fake unit IDs not in `views`, and `_key_skip()` fires via `call_deferred()` only during the 320 ms lead wait, the test misses finding #1 (`K` during kill hold), mid-volley and 900 ms tail `K` skips, and `settings.json` save/load round-trip. It also tests `"nova"` (`brisk_camera_check.gd:8`), which `_play_fire` (`battle.gd:2300`) never passes. | Add a live-unit `_play_batch` / `_play_death` + `KEY_K` kill-hold case and a throwaway-profile `save_settings()` + `_load_settings()` check to `brisk_camera_check.gd`. | high |
| 4 | `_flagship_camera` checks `VU[id]["flagship"]`, which protects enemy flagships and bosses only, not the player's campaign flagship (`pflag`). | OBSERVED | `godot/scenes/battle/battle.gd:2216` and `godot/rules/battle_api.gd:263` | `return bool(VU.get(a_id, {}).get("flagship", false)) or bool(VU.get(t_id, {}).get("flagship", false))` / `"flagship": R.jt(u.get("flagship")) or R.jt(u.get("boss")),` | Matches pre-existing `_cine_wants` (`battle.gd:2203`) and issue #1871's "boss beats", so not a regression. Noted because the helper name and PR summary ("keeping flagship beats") could mislead reviewers into assuming player flagship shots are exempt from `brisk_camera`. | Keep current enemy-flagship/boss behaviour unless Ryan wants player `pflag` shots exempt too; clarify comment or helper name if touched. | high |
| 5 | `title.gd:_toggle` initializes any missing key in `main.settings` to `true`, relying on `main.gd:21` always pre-populating `"brisk_camera": false`. | OBSERVED | `godot/main/title.gd:539-540` | `if not main.settings.has(key):` / `main.settings[key] = true` | Safe on the live `main.gd` path (old `settings.json` merges onto `main.gd:21`, so `"brisk_camera"` stays `false`), but any test or caller omitting `"brisk_camera"` from `main.settings` silently defaults the toggle to `On`. | Optional hardening: pass an explicit default (or read a defaults map) in `_toggle` so opt-in flags default to `false` even when absent. | high |

---

## Recommended Next Step

Send PR #1914 back for one small fix before merge: exclude `KEY_K` from the `kill_hold_until > 0.0` (and `opening`) dismissal branches in `battle.gd:4017-4022`, and add a `KEY_K`-during-kill-hold assertion plus a disk `settings.json` round-trip check to `brisk_camera_check.gd`. No merge-conflict work is needed for `main` (PR #1890 / #1892) or PR #1445.

---

## Not Checked

- Windowed / GPU rendering, visual framing of cut-ins, actual `gfx.death()` slow-motion timing on real exported ship hulls, and audio cues (headless only per scope).
- `main/test/showcase_quiet_check.gd` on the 3-way `git archive` tree (`main+1914+1445`) failed on kit-hull worker counts (`0 of 7` kit hulls) because the archive lacked imported `.godot/` / built `gen/` assets; PR #1445's asset-backed sliced load was not re-timed here.
- Full `godot/tools/ci/run_checks.sh` suite locally (PR #1914's GitHub Actions `All checks` run on `86049dda` passed all 3 Godot game check shards, Godot rules, Standing checks, and A16 death seam).
- Mid-volley (during `total * sp` flight) and 900 ms tail `_wait_shot_cut` `KEY_K` timings were traced by code reading (`battle.gd:2239-2260,2306,2447,2488-2492`), not timed in a separate headless probe.
