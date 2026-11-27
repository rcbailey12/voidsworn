# Neon Review Lane: Batch 3 (Nov 27, 2026)

- **Issue:** #2251 (batch 3, Board Nov 27 12:55 UTC)
- **Base tested against:** `origin/main` at `e23fe088f9b659037efc860db1eed072ed8417f4` (includes merged rules sequence `#2236` and `#2237`)
- **Tally:** **1 MERGE** (`#2265`), **2 FIX FIRST** (`#2257`, `#2260`). Every PR has a matching `Neon (review):` comment posted on GitHub.

## Verdicts

| PR | Issue | Branch @ Commit | Local Merge vs `origin/main` (`e23fe088f`) | Verdict | Findings / Notes | One-line Summary |
| --- | --- | --- | --- | --- | --- | --- |
| #2257 | #2249 | `codex/issue-2249` @ `d76b259f2509269315dd5f4d7d41091d80f8fa03` | Clean | **FIX FIRST** | OBSERVED `godot/rules/rules.gd:2795-2799` & `godot/fx/fx_weapons.gd:313-322` (`pd_ships` drops shot index `i`, so natural misses steal flak cues and multi-defender intercepts swap attribution); OBSERVED `godot/fx/fx_weapons.gd:789-793` (`_burst` trailing `seed_override` collides positionally with queued #2104/#2253 `book`); OBSERVED `godot/render/ship_view.gd:390,397,439-440` (`_guard_mix` uses wall-clock `dt` instead of FX delta). | Guard-wing orbit and PD-C cap are clean, but fix shot-index-to-defender attribution and coordinate `_burst` before merging. |
| #2260 | #1406 | `codex/issue-1406` @ `04aa42d80c9fb07879e17b411d8c8b5406dd48cd` | Clean | **FIX FIRST** | OBSERVED `godot/ui/test/front_end_shots.gd:51,94-95` vs `godot/tools/picture_provenance.gd:139`: Artoo's finding from `90f5507a` is still unfixed at `04aa42d8`; `_capture_flagship_c37` accepts any hex `tag` without matching `source_commit`, allowing mismatched caption vs provenance strip SHAs. | C37 A flagship podium, live Hollow Sun backdrop, and framing checks are clean; tie C37 caption commit to `PictureProvenance` before capturing. |
| #2265 | #2248 | `codex/issue-2248` @ `4c560a29e32e3bdad7dd963b4ac6f55594c26c7d` | Clean | **MERGE** | Clean game FX, API docs, and `faction_fx_2248_check.gd` (`All checks` green). Notes: INFERRED `godot/fx/fx_death.gd:184-185,1744-1746` fixes `scorch_tint` on cold caps (Hullbreaker lip ALBEDO `0.047 -> 0.012` should read at c26; Eclipse `0.018 -> 0.011` / recessed `0.007 -> 0.004` is very subtle on an already near-black cap and authored `D22_23` interiors use `fx.wreck_interior()`); OBSERVED `contrib/codex/issue-2248/capture.bat:43` checks exact equality `if not "%GPU_GO%"=="GPU cleared"`, which rejects `GPU cleared: <reason>` lines (pins `LB_BEFORE=061f6268...`, `LB_AFTER=%~1` or `HEAD`, `LB_TOOL_REF=%LB_AFTER%`, `D22_23`/`C19_51`, cameras `170,26`). | Cleanly fixes all four #2248 code/doc/check items; run `contrib/codex/issue-2248/capture.bat` (with exact `GPU cleared` or prefix check) to verify Eclipse/Hullbreaker cold cap contrast visually. |

## Not Checked

- Live RTX 5080 GPU captures for PR #2257 (camera 170 guard-wing/flak), PR #2260 (`C37, run 2, <commit>` Forward+ flagship pick), and PR #2265 (`contrib/codex/issue-2248/capture.bat` cold wreck cap contrast on installed `D22_23` and `C19_51`).
