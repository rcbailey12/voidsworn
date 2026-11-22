---
name: independent-audit
description: Pre-merge adversarial audit for Voidsworn PRs and systems. Catches silent visual, audio, physics, asset-pipeline, and cross-PR regressions that unit checks and happy-path tests miss. Use before merging any Godot FX, rendering, ship import, audio, or battle-feel PR.
---

# Voidsworn Independent Audit Checklist

Run this audit on any non-trivial PR diff (especially in `godot/fx/`, `godot/render/`, `godot/audio/`, `godot/rules/`, and `tools/pc/`) **before** merging or queuing expensive GPU comparison runs. Report only concrete, line-numbered findings observed directly in the diff or `origin/main`. Never invent issues; if a check passes cleanly, skip it.

House rules apply: only Ryan rules (propose changes, never self-merge), no em dashes, no human-hour estimates, `gh api` REST only.

## The 8 Silent-Bug Traps (Check Every PR Against These)

1. **Cross-PR uniform and state collisions:** Check `git log origin/main -n 10 --oneline` and grep every touched shader uniform (`fx_power`, `fx_flick`, `fx_weather`, `fx_scorch_*`, `gate`, `melt_*`) to ensure two PRs are not driving competing systems or overwriting each other.
2. **Audio vs VFX and faction-material contradictions:** Check all 6 factions (`voidsworn`, `corsair`, `ithar`, `deathless`, `chorus`, `hegemony`). Glasswrights (`ithar`, `hit_glass`) never get orange metal fire, soot smoke, red embers, metal wear darkening (R402), or white cold-gas RCS jets. Chorus (`chorus`, `hit_wet`) never gets metal plate debris, soot wear (R402), or mechanical RCS jets. Eclipse (`deathless`) uses its own `damage_glow` / violet accents, never hardcoded brass-orange sparks or green doom glow.
3. **Guard conditions on edge states:** Always trace (a) shield-absorbed hits (`absorbed and not breaking`): an ordinary shield block is quiet per R412 rule 4 (docs/playbooks/deaths_and_hits.md, "Weapon firing and hit reactions"): no brownout, stutter, RCS spam, or marks; read that rule for the reactions it keeps (shield breaks, crits and ion hits) before calling one a finding, (b) fresh stage-0 hulls (`ensure_damage_surfaces(fx)` needed before reading `_damage_surfaces`), (c) mid-effect `death()`, `teardown()`, and Eclipse `revive()` cleanup, and (d) specialty kill causes (`acid`, `ram`, `board`, `ion`) not firing default blast beats.
4. **Parent-node UI coupling and coordinate/unit sanity:** Keep `fx_marker` and `fx_ring` flat on `ShipView` root; put hit roll, pitch, yaw, drift, shudder, and `_list` on `hull_pivot`. Check helper units (`fx.stk` arg #6 is world length, not `length / speed`), continuous lever arms (no sign flip at `y = 0`), and base-heading drift rotation.
5. **Clock desyncs (`fx.now` vs real time vs battle speed):** Visual ship motion (`bob`, `nod`, `hit_react`, `turret_step`, `door_step`) must respect `fx.now` / `hit_pause` rather than unpaused `Time.get_ticks_msec()`, with clamped slow-frame integration (issue 1467).
6. **Asset-pipeline producer vs runtime loader names:** Verify exact filename patterns between builders (`build_assets.gd`, bakes) and loaders (`fx_fragments.gd`, ship loader), and confirm node-name walkers (`turret_*`, `*_turn`, `hp_*`) have safe fallbacks or hard CI checks.
7. **Silent fallbacks and zero-op branches:** Audit every `return`, `continue`, `.get(key, default)`, and `skipped` counter for weapons silently collapsing into defaults, missing hardpoints skipping volleys, or tests bypassing the live production path.
8. **Ruling and doc landing check (R214):** Confirm working rules, look standards, and API contracts land in `docs/RULEBOOK.md`, `docs/playbooks/*.md`, or `godot/fx/API.md` with zero em dashes. Rules edits change Godot only (RULEBOOK 3.1, R405: the browser rules files are retired) and pass the Godot saved-results check.

## Output Format

Post reviews as `<Seat> (audit):` naming the commit SHA read. This layers over the outside-review evidence contract (docs/REVIEW_PROTOCOL.md, RULEBOOK 2.11): every finding keeps its file:line, exact quote and OBSERVED or INFERRED label, and the review ends with `Not checked:`. Group the findings into:
1. **Blocking** (rule violations, visible regressions, or clashes with merged `main`).
2. **High / Medium** (unit mismatches, silent fallbacks, missing faction/edge handling).
3. **Ready / Verified** (1-line summary of what passed cleanly).
