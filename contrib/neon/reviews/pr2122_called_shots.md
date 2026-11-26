# Neon (audit): PR 2122 (Issue 2033, called shots and Veteran AI)

Reviewed commit: `fce825be` (`fce825be4bc9600111230fd33ff07919eb158300`, diff `origin/main...origin/codex/issue-2033`, merge-base `e6e1fbc3d`, compared against `origin/main` at `b0cf5ce12`).

## Plain-words verdict for Ryan

**Hold before merge (one short fix and reseal pass needed).**

The core feature plays cleanly and fits the game well: once you click an enemy to aim, the target bar adds a clean `Any / Weapons / Midship / Engines` strip that trades `-10` to hit for `+15` crit chance and focused section damage, updates the target-bar odds right away, works with Backspace undo, leaves shields as one pool, and leaves Standard AI and Commands untouched. None of the 379 saved battles flipped win/loss outcomes, and all 3 Standard battles stayed identical.

Two things block merging as-is:
1. **Main moved ahead (PR 2105 step 0 data):** 278 saved-results files conflict with `main`, so the saved baseline must be rebuilt from the combined branch.
2. **A multi-gun rule leak:** if gun 1 breaks the called section, guns 2+ in the same committed volley still pay `-10` to hit for an already-broken section (and can still trigger off-section weapon crits).

Three smaller playability fixes are also worth folding into the same pass: the left weapon list forgets the `-10` penalty when you fire without moving, Veteran AI wastes `-10` aim on shield-only shots that cannot reach hull, and Veteran AI never tells you on screen or in the log when it calls a section on your ship.

---

## 1. Files read (REVIEW_PROTOCOL.md section 1)

All files read directly at commit `fce825be` (`origin/codex/issue-2033`). Big files (over 1,500 lines or 60 KB) list the exact line ranges inspected.

| File | Total lines | First 40 chars of LAST line | Line ranges read (big files) |
|---|---:|---|---|
| `godot/rules/rules.gd` | 7,969 | `\tB["aiActive"] = null; u["activated"] = ` | 1348-1405, 2730-2865, 3205-3550, 3545-3625, 3620-4170, 7255-7715, 7910-7969 (plus full PR diff) |
| `godot/rules/data/tables.json` | 1 | `{"sha256":"0ac5938ea308dae892e7236e4d35d` | Full JSON parsed and key-diffed vs merge-base `e6e1fbc3d`; all `HULLS` and `W` entries inspected |
| `godot/rules/test/rules_2033_test.gd` | 153 | `\treturn [a == null, str(a)]` | 1-153 (full file) |
| `godot/rules/test/scenarios.json` | 11,995 | `}` | Full JSON parsed (379 scenarios: 376 Veteran default, 3 Standard) plus all 8 seed-change hunks in diff |
| `godot/scenes/battle/battle.gd` | 8,160 | `\tget_tree().quit(code)` | 217-226, 5465-5660, 5980-6030, 6080-6130, 6565-6635, 6880-6935, 7360-7570 (plus full PR diff) |
| `godot/scenes/battle/test/plan_commit_check.gd` | 501 | `\tquit(0 if fails == 0 else 1)` | Diff hunks 122-160, 465-501 |
| `godot/scenes/battle/test/round4_hullbreaker_check.gd` | 61 | `\tbattle._quit(0 if ok else 1)` | 1-61 (full diff + tail) |
| `godot/tools/ci/godot_checks.txt` | 286 | `headless\|main/test/export_ship_check_tes` | Diff hunk 85-98 + tail |
| `godot/ui/battle/ledger.gd` | 1,136 | `\t\t\t\tact.emit(h.act, h.arg)` | 615-765 (full `_target_block` and called-shot helpers) |
| `godot/ui/battle/test/ledger_readability_test.gd` | 562 | `\treturn e` | Diff hunks 299-305, 471-520 |
| `godot/ui/campaign/campaign_ui.gd` | 2,827 | `\t\t\t\tKit.play(Kit.press_cue(cue_role(str(` | Diff hunk 2097-2106 (`HELP` table) |
| `godot/rules/test/saved/changes.txt` | 1,112 | `FAIL: saved Godot results; 379 battles c` | Lines 1-120 and 1083-1112 |
| `godot/rules/test/saved/results.json` | 2,701 | `}` | Full JSON parsed and compared vs merge-base `e6e1fbc3d` (379 battles) |
| `docs/shots/issue-2033-codex/CS-2033-target-bar.png.provenance.json` | 107 | `}` | Lines 1-107 (plus `CS-2033-target-bar.png` viewed directly: 1280x578 px) |

Also inspected on `origin/main` (`b0cf5ce12`) for clash analysis: PR 2105 (`bdc26dab6`), PR 2141 (`3a2d46ba4`), PR 1755 (`6f88a9338`), PR 2052 (`6ea1d3bf1`), PR 2102 (`c53d44941`), `godot/rules/combat_records.gd`, `godot/rules/API.md`, and `godot/rules/battle_api.gd` (at `fce825be`).

---

## 2. Four review checks

### 2.1 Spec (Issue 2033)
- **Delivered:** 3-way priority section pick (`Weapons = prow`, `Midship`, `Engines`, default `Any`/none) in the plan-commit target bar (`battle.gd`, `ledger.gd`), `-10` aim for `+15` crit trade-off stored in `TB.CALLED_SHOT` (`tables.json`), shown in target preview and committed on Enter; Veteran AI calls Engines on runners (`fullAhead` or Breakthrough `break`) and Weapons on `aiTopThreat()` while skipping kills and broken sections; Standard AI unchanged; one short Help entry added in `campaign_ui.gd:2100`; shields remain one pool; Commands untouched; zero em dashes added in changed files.
- **Gaps against spec / done-when:** (a) the weapon list preview omits `-10` when no move is planned (Finding #3); (b) the target-bar picture is a CPU layout mock (`cloud direction check`) from a dirty tree rather than an installed-build capture (Finding #7); (c) the PR body still says `"Not all green yet... Nothing was committed or pushed"` even though GitHub's `All checks` passed on `fce825be`.

### 2.2 Rules (R405, saved results, AI fairness, faction parity)
- **Godot only (R405):** Verified. Zero browser rules files at repo root were touched; all rules edits live in `godot/rules/rules.gd`, `godot/rules/data/tables.json`, and `godot/rules/test/`.
- **Saved results:** 276 of 379 battles and `threat_s4.json.br` changed because `AI_LEVEL` defaults to `"veteran"` (376 Veteran scenarios, 3 Standard). All 3 Standard battles are unchanged (`0` diffs), and `0` of the 379 battles flipped win/loss outcomes. Eight tree fixtures in `scenarios.json` and `round4_hullbreaker_check.gd` (seed 7 -> 16) were reseeded and explained.
- **Hidden information:** None observed. `aiRunning(t)` reads `fullAhead` and `B["obj"].type == "break"`; `aiTopThreat()` reads `alive("player")` weapon stats (`dmg`, `shots`, `off`); `calledOk` reads live section HP/broken state. All of these are public board state visible to the player.
- **Symmetry across ships and factions:** Section mechanics (`prow`, `mid`, `eng`) apply identically to player and enemy capital ships across all 6 factions via `makeUnit` (`rules.gd:1385`) and `damageSection` (`rules.gd:3503`). One asymmetry is structural: `aiVolley` only runs for enemies and `aiCalledSec` explicitly checks `t["side"] != "player"` (`rules.gd:7289`), so player-side station fire (`stationFire`) never calls shots, which is expected. A real faction/hull parity issue exists in how `prow` ("Weapons") and `mid` behave on hulls without `"F"` or `"P"/"S"` weapons or shields (Finding #6).

### 2.3 Feel (Readability and balance)
- **Target bar:** Clean and scannable in `CS-2033-target-bar.png` (1280x578 px): `Any  Weapons  Midship  Engines` sits inline on the `Target` header, drops `94% -> 84%` and `19 -> 17 damage`, and shows `Engines: -10 to hit, +15 crit` clearly below. At tight widths (`1152x1024` at `1.3x`), `ledger.gd` wraps the buttons to two rows and moves `-10 aim, +15 crit` inline next to the hit percentage without overlapping.
- **Readability gaps:** (1) Without a planned move, the weapon list still shows `94%` while the target bar shows `84%` (Finding #3). (2) Veteran AI called shots produce zero on-screen float or log cue, so players cannot tell when the AI called a section (Finding #5).
- **Strength / tuning:** `-10` to hit for `+15` crit plus targeted section damage is sensible and not oppressive (0 win/loss flips across 376 Veteran fixtures), though Veteran AI currently weakens itself slightly by paying `-10` aim on shield-absorbed shots (Finding #4) and on non-fore hulls (Finding #6). Note Artoo's earlier preflight on issue 2033: a paired Veteran balance check on the merged head is still needed to confirm the tight faction-gap margin from PR 2038.

### 2.4 Clashes with `origin/main` (`b0cf5ce12`)
`git merge-tree --write-tree --name-only origin/main origin/codex/issue-2033` reports **278 merge conflicts** (2 text + 276 binary), ALL caused by **PR 2105 (`bdc26dab6`, issue #2078, AAA UI step 0 data)**:
- **Direct merge conflicts (278 files, PR 2105 only):**
  - `godot/rules/test/saved/changes.txt` (text conflict)
  - `godot/rules/test/saved/results.json` (text conflict)
  - All **276** modified battle records in `godot/rules/test/saved/records/*.jsonl.br` (binary conflicts: PR 2105 updated all 379 `.jsonl.br` files to record step 0 combat/captain state; only `godot/rules/test/saved/records/threat_s4.json.br` does not conflict).
- **Cleanly auto-merged file overlaps with recent merges:**
  - **PR 2105 (`bdc26dab6`, step 0 data):** also touched `godot/rules/rules.gd`, `godot/scenes/battle/battle.gd`, `godot/tools/ci/godot_checks.txt`, `godot/ui/campaign/campaign_ui.gd`. All 4 auto-merge cleanly with no semantic conflict (`CombatRecords.hit` records applied shield/hull damage independently of `_calledSec`).
  - **PR 2141 (`3a2d46ba4`, issue #2095 splash kill credit):** touched only `godot/rules/rules.gd` (1 line in `legionRise`, `u.erase("splashKill")`). Auto-merges cleanly, zero semantic clash.
  - **PR 1755 (`6f88a9338`, issue #1741 Wounds V2):** touched only `godot/tools/ci/godot_checks.txt` among PR 2122's files (1 new check row). Auto-merges cleanly. In `godot/fx/fx_ship.gd` and `godot/fx/fx_breach.gd`, Wounds V2 reads per-section damage fractions (`section_fraction[i]`), so routing hull damage to a called section drives the matching section wound ladder cleanly.
  - **Other recent merges (auto-merged cleanly):** PR 2052 (`6ea1d3bf1`, Sound Gate 3) overlaps in `battle.gd`, `godot_checks.txt`, `campaign_ui.gd`; PR 2102 (`c53d44941`, AAA quick fixes) overlaps in `godot_checks.txt`, `ledger_readability_test.gd`, `campaign_ui.gd`.

---

## 3. Findings

### Blocking

| # | Finding | OBSERVED/INFERRED | file:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | 278 saved-results files conflict with `origin/main` after PR 2105 (step 0 data) merged. | OBSERVED | `godot/rules/test/saved/changes.txt:1` (plus `results.json` and 276 `records/*.jsonl.br`) | `Saved manifest before: 4fcf972525e3d7fd79e6e2bdd39d7bfcf2d0afaf4d7dc0635fe40d69685d089c` | PR 2105 (`bdc26dab6`) rewrote all 379 `.jsonl.br` battle records, `results.json`, and `changes.txt`. Picking either branch's binaries drops one PR's rules/data changes. | Merge `origin/main` into `codex/issue-2033`, regenerate saved results from the combined head, and verify `changes.txt` and `results.json`. | High |
| 2 | `fireWeapon` and `torpSalvoOf` never validate `calledOk(t, called)`, so broken sections and `firstScar` redirects still pay `-10` aim. | OBSERVED (validation); INFERRED (multi-gun play) | `godot/rules/rules.gd:3649` (also `rules.gd:2774`, `rules.gd:3508`, `battle.gd:5647`) | `var called = opts["called"] if jt(opts.get("called")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")) else null` | A committed multi-gun volley passes the same `sec` to every gun (`battle.gd:5647`); if gun 1 breaks the section (or `firstScar` redirects at `rules.gd:3646`), later guns still pay `-10` aim while `damageSection` returns early on `s["hp"] <= 0`, and a `prow` crit still knocks out flank/turret guns (`rules.gd:3537`). | Validate `called` with `calledOk(t, called)` inside `fireWeapon` (after `firstScar` and `treeEscortWing`), `torpSalvoOf`, and `previewVolley`, and add a two-gun section-break test in `rules_2033_test.gd`. | High |

### High / Medium

| # | Finding | OBSERVED/INFERRED | file:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 3 | Weapon-card hit odds omit the `-10` called-shot penalty whenever no move is planned. | OBSERVED | `godot/scenes/battle/battle.gd:7378` (caller `battle.gd:6903`) | `return _volley_preview(id, [wi], tid)[wi]` | `_fire_preview_at` (`battle.gd:7388-7389`) passes `_aim_sec(tid)` when a move is planned, but `_fire_preview` does not; stationary aiming shows e.g. `94%` on every weapon row beside `84%` on the target bar. | Change `_fire_preview` to `return _volley_preview(id, [wi], tid, null, _aim_sec(tid))[wi]` and check weapon-row odds in `plan_commit_check.gd`. | High |
| 4 | Veteran AI pays `-10` to hit on shield-absorbed shots with zero expected hull damage. | OBSERVED (code); INFERRED (combat impact) | `godot/rules/rules.gd:7290` | `if expectedVs(u, w, t).hull >= t["hp"]: return null` | `aiGunOrder` (`rules.gd:7626`) fires shield-stripping weapons first; when `expectedVs(...).hull == 0.0`, `aiCalledSec` still calls a section and pays `-10` aim even though zero hull hits, section damage, or crits can land. | Return `null` in `aiCalledSec` when `expectedVs(u, w, t).hull <= 0.0` as well as when `>= t["hp"]`. | High |
| 5 | Veteran AI called shots give zero on-screen or combat-log cue to the player. | OBSERVED | `godot/rules/rules.gd:3767` (also `rules.gd:4128`) | `emit({"t": "fire", "unit": u["id"], "weapon": wi, "weapon_id": w["id"], "kind": w["k"], "arc": w["arc"], "name": w.get("n"),` | Neither the `fire` event, `hit` event, float text, nor `logm` (`rules.gd:4128`) mentions that the enemy called Engines or Weapons, so players cannot read why Veteran AI is targeting a section. | Include `"called": called` on the `fire` event and note called sections in the combat log (plus a brief float cue when an enemy calls a section). | High |
| 6 | Calling `prow` ("Weapons") on hulls with no forward guns (or `mid` on unshielded hulls) disables zero systems on break. | OBSERVED (tables + rules); INFERRED (play feel) | `godot/rules/rules.gd:3518-3520` (also `ledger.gd:723-724`) | `if sec == "prow":` / `for w in t["weapons"]:` / `if w["arc"] == "F": w["off"] = 999` | 13 capital hulls across all 6 factions (including `ascendant`, `vs_penitent_g`, `c_hulk_g`, `i_song_w`, `d_harvester_t`) have zero `"F"` weapons, and 15 Chorus/Eclipse hulls have `sh == 0` and no `"P"/"S"` guns; Veteran AI calling `prow` on them pays `-10` aim for a no-op section break (only crits knock out guns via `systemDamage`). | In `aiCalledSec`, only call `"prow"` when the target has at least one live `"F"` weapon, and note in the section tooltip when a section has no forward guns or shields. | Med |
| 7 | Delivery hygiene: target-bar picture is a dirty-tree CPU mock, PR body is stale, and `godot/rules/API.md` omits the aim-cost contract. | OBSERVED | `docs/shots/issue-2033-codex/CS-2033-target-bar.png.provenance.json:6` | `"stage": "cloud direction check",` | The image (`1280x578`, valid height under R185) came from a dirty pre-commit tree (`source_dirty: true`) rather than an installed build, the PR body still says `"Nothing was committed or pushed"`, and `godot/rules/API.md` does not document `TB.CALLED_SHOT` or the `-10` aim cost (R214). | Update `godot/rules/API.md`, refresh the PR body after resealing, and capture one installed-build target-bar screenshot for Ryan before merge. | Med |

### Ready / Verified

- **R405 (Godot-only rules) and R450 (single shield pool, no Commands changes):** Clean; zero browser rules files modified, shields remain one pool, and Commands are untouched.
- **No hidden information in Veteran AI:** Clean; `aiRunning`, `aiTopThreat`, and `calledOk` read only public board state, and Standard AI stays 100% unchanged (0 of 3 Standard saved battles changed).
- **Target-bar layout and readability (`ledger.gd`, `CS-2033-target-bar.png`):** Clean; default desktop and tight/1.3x widths keep hit %, damage split, and `-10 to hit, +15 crit` readable without overlap, and `campaign_ui.gd:2100` teaches the rule in one short Help entry.
- **Clean auto-merges with PR 2141, PR 1755, PR 2052, PR 2102, and PR 2105 code files:** Verified via `git merge-tree`; zero em dashes introduced across changed files, and GitHub's `All checks` is green on `fce825be`.

---

## 4. Recommended next step

Merge `origin/main` into `codex/issue-2033`, fold in the small fixes for Findings #2, #3, #4, #5, and #6 (validate `calledOk` in `rules.gd`, pass `_aim_sec` in `_fire_preview`, skip zero-hull / no-fore-gun AI calls, add a called-shot log/event cue, update `godot/rules/API.md`), regenerate the saved-results baseline once on the combined head, run a paired Veteran balance check (per Artoo's preflight on issue 2033), and take one installed-build screenshot of the target bar for Ryan before merging.

---

## Not checked:
- Did not run Godot locally, execute headless checks, or run a paired Veteran balance sim (read-only audit per brief).
- Did not inspect live rendering, GPU captures, or hover tooltips in an installed Windows build (only the static CPU layout image `CS-2033-target-bar.png` was available in the PR).
- Did not decompress or diff the contents of the 276 binary `.jsonl.br` battle records beyond `results.json` outcomes, `changes.txt` first-diff summaries, and `git merge-tree` conflict detection.
- Did not read unrelated sections of `rules.gd`, `battle.gd`, `campaign_ui.gd`, `scenarios.json`, or `ledger.gd` outside the line ranges listed in Section 1.
