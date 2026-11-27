# Outside review: the four effects PRs together (2007, 2049, 2021, 2055)

Issue 2063. Advice only, the Board decides. Read-only review, no code was changed.
Council: Rey blind leg first, then DeepSeek (DeepThink on, Search off), Qwen (Qwen3.8-Max, the standing gate), Gemini on Hydrogen (the Flash seat). Grok's seat is empty (bot wall on grok.com, Nov 25, 2026, about 9:49 AM CT; nothing was submitted). Legs verbatim in legs/ beside this file.

Protocol check (docs/REVIEW_PROTOCOL.md, read in full before any diff): 2,340 bytes, 28 lines, read at commit 3629e733 on main, Nov 25, 2026. Its rules applied here: at most 10 findings, most important first; every finding carries a file:line, an exact quote under 20 words, and OBSERVED or INFERRED; the review ends with "Not checked:".

## Heads reviewed (pinned Nov 25, 2026; every head had moved since the issue was written)

| PR | Branch | Head | Check state on its own head |
|---|---|---|---|
| 2007 | codex/issue-1991 | 16bc0005dc7dddd7d29d2119aeefcc86e85b31e2 | Four Godot game checks SUCCESS; "Standing checks (rules, text, saves)" FAILURE; "All checks" failure. The earlier death-plane failure is gone at this head. |
| 2049 | codex/issue-2018 | 838263aed0b6d2a4948a21b282170f4448f724f8 | All checks success. |
| 2021 | codex/issue-1693 | 207f5d71c00245cc3558bb8c5fa704dabeaa0c32 | Nearly every check FAILURE, including Godot game checks. |
| 2055 | neon/issue-2042 | d987c0536f1f54d12eca3e02c4b39b2254826128 | All checks success. |

Main at review time: 3629e733 (Merge PR 2146). Per Artoo's note on the issue: PR 2007's standing-check failure is pre-existing on its own head and is kept separate from combined-PR clashes below; it is not counted as a clash, but it is a gate. PR 2007's head is a retry of the head named in the issue body, so this review is evidence about the retry, and the Board should recheck 2007 once more before treating any of this as merge evidence.

## Verdict

Do not merge any of the four as they stand. The blocking problem is not textual: three of the four PRs assign different meanings to the same sprite kind numbers, and no merge resolution can fix that. Kind 8 is Eclipse dark smoke on main, a second Eclipse smoke emitter in PR 2007, the shared spark in PR 2049, and a smoke entry in PR 2021's status table. Kind 7 is Hegemony fire in PR 2007, a rerouted spark in PR 2049, and smoke in PR 2021. The fix is a one-time kind renumbering with a written registry, done before the merge train starts (Qwen's objection, adopted by the chair). After that: gate every PR on being green on its own head (DeepSeek's objection, adopted), then merge 2049, 2007, 2055, 2021, re-running the next PR's fx checks on the merged tree after each step.

## Findings

| # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | fix | confidence |
|---|---|---|---|---|---|---|---|
| 1 | Kind 8 is claimed by four systems at once: Eclipse dark smoke on main, a second Eclipse smoke emitter added by 2007, the shared spark constant in 2049, and a smoke entry in 2021's SMOKY table. The sprite system dispatches on the number, so after any merge the number cannot mean all four. 2007's new emitter feeds fx.spr, not stk (chair verified in the 2007 diff), so the clash is in the shared kind space itself, not only in 2049's reroute. | OBSERVED | godot/fx/fx.gd:813 (2049); godot/fx/fx_ship.gd:2623 (main); godot/fx/fx_ship.gd:2571 (2007); godot/fx/fx.gd:760 (2021) | "const SPARK_KIND:= 8" | Eclipse smoke and shared sparks share one mask number; which visual wins depends on write order, and no current check tests kind semantics. | Renumber before merging: move SPARK_KIND to a free number, write the kind registry into fx.gd, and audit every emitter against it. | High |
| 2 | Kind 7 is Hegemony fire and non-organic vents in 2007, is rerouted into the shared spark path by 2049, and is classified as smoke by 2021's SMOKY. Kind 20 (Chorus hatch and vents in 2007) is also in SMOKY, and kind 1 is rerouted by 2049 while 2007 reuses generic spark sprites. Three PRs edited the kind space with no shared registry. | OBSERVED (assignments); INFERRED (runtime consequences) | godot/fx/fx.gd:822 (2049); godot/fx/fx.gd:760 (2021); godot/fx/fx_ship.gd (2007, kinds 7 and 20) | "if kind in [1, 7, SPARK_KIND]:" | Hegemony fire can render as a damage_glow spark streak and Chorus organics can be treated as smoke; both are faction-rule breaks that only exist in combination. | Same registry fix as finding 1: settle kinds 1, 7, 20 in the registry, audit Chorus stk call sites so no Chorus effect enters flight_streak, and re-audit SMOKY against the final assignments. | High |
| 3 | PR 2007 and PR 2049 textually conflict in 8 files, including the same functions in fx.gd, fx_death.gd and fx_ship.gd. This is the worst pairwise clash in the set and it sits on top of findings 1 and 2. | OBSERVED | godot/fx/fx.gd, fx_death.gd, fx_death_beats.gd, fx_ship.gd, fx_weapons.gd, godot/fx/faction_looks.json, godot/fx/fx_death_variety_1586_check.gd, tools/pc/jobs/look_bench.bat (pairwise merge test, Nov 25, 2026) | "2007 x 2049 conflict in 8 files" | Any resolution order that does not settle the kind numbers first will encode the wrong meaning into the merged tree. | Resolve this pair only after the renumbering, with 2049 merged first and 2007 resolved on top of it. | High |
| 4 | None of the four PRs merges cleanly into today's main (2007: 3 files, 2049: 1 file, 2021: 2 files, 2055: 3 files, by merge test against main 3629e733). Separately, 2021 is broadly red on its own head and 2007 still fails the standing checks on its retry head. | OBSERVED | Merge tests and check states pinned in the table above | "Standing checks (rules, text, saves)" FAILURE (2007); nearly every check FAILURE (2021) | The set has drifted from main and two of the four are not merge candidates at all yet; an order alone does not cure a red head (DeepSeek). | Gate: each PR green on its own rebased head before it enters the train. 2021 and 2007 fix their own failures first; this is a gate, not a merge step. | High |
| 5 | PR 2021's capture launcher sets LB_MOMENTS to a Godot res:// path, which fails PR 2007's launcher existence check and exits the capture with code 2. PR 2055's launcher was explicitly written to dodge the same check, which proves the hazard is real. | OBSERVED | tools/pc/jobs/wave2b_run4.bat (2021); tools/pc/jobs/capture.bat (2007) | "LB_MOMENTS=res://bench/look_moments_1693_run4.json" | Once the launchers combine, 2021's before/after captures cannot run at all. | Point LB_MOMENTS at the Windows path of the same file, as 2055's launcher does. | High |
| 6 | The capture launchers in 2007, 2049 and 2055 default AFTER (and 2055 also BEFORE) to branch refs, not full commit SHAs. Only 2021 enforces a 40-character SHA for AFTER. | OBSERVED | tools/pc/jobs/capture.bat (2007, 2049); tools/pc/jobs/capture_2042_before_after.bat (2055) | "if not defined LB_AFTER set "LB_AFTER=origin/codex/issue-1991"" | Branch refs move, so the before/after evidence for the whole effects set is not reproducible. | Pin BEFORE and AFTER to full SHAs in all four launchers; keep 2021's 40-character validation. | High |
| 7 | faction_looks.json is edited by both 2007 (damage_glow retune) and 2049 (a _fields rewrite), and 2049's shared spark tints from damage_glow. Resolving the file wholesale either way silently drops one side. | OBSERVED | godot/fx/faction_looks.json (2007 and 2049) | "damage_glow" | Taking 2049's file wholesale reverts 2007's Directorate damage-light fix and changes the spark tint the Hegemony rule depends on. | Resolve field by field: keep 2007's retuned damage_glow values, take 2049's _fields structure, then re-run 2049's faction palette test. | High |
| 8 | fx_shaders.gd is edited by all four PRs (2055 alone is +215 -20) and conflicts pairwise 2007 x 2021 and 2007 x 2055. The other pairwise fx "conflicts" between 2049 x 2055 and 2021 x 2055 are partly merge-base staleness: their fx edits sit in disjoint regions and merge textually clean. | OBSERVED | godot/fx/fx_shaders.gd (all four) | "fx_shaders.gd: changed by 2007, 2049, 2021, 2055" | Shader resolutions are where a uniform or pass gets silently dropped; landing the big shader rewrite late means it resolves once, against settled values. | Land 2055 after 2049 and 2007, compile every shader after its merge, and do not trust the staleness-inflated pairwise counts for 2049 x 2055 or 2021 x 2055. | Medium |
| 9 | Eclipse acid: 2021 rewrites _acid_colour so deathless returns the faction damage_glow (violet) instead of the hardcoded green; 2049's branch still carries the old green line. The edits do not textually collide, so nothing forces a human to look at this spot during the merges. One correction to the Qwen leg: git will not keep both lines, since 2049 never edited that function; the hazard is a conflict resolution or rebase elsewhere in fx_ship.gd restoring the green line unnoticed. | INFERRED | godot/fx/fx_ship.gd:1908 (2021, at 207f5d71); godot/fx/fx_ship.gd:1886 (2049 branch, at 838263ae) | ""deathless": return fac["damage_glow"]" | A silent return of green acid breaks the Eclipse rule (violet, no green) with no failing check necessarily firing. | After the fx_ship.gd merges, grep the merged tree for the old green literal and run 2021's acid test, which asserts the violet. | Medium |
| 10 | Shield blocks: no textual clash was found in the diffs. 2049's shared_spark_check asserts quiet shield blocks and the shield_hit call sites in the shared fx_weapons.gd hunks are unchanged by 2007 and 2049. Whether 2021's side of the 2049 x 2021 fx_weapons.gd conflict touches shield_hit is unverified (flagged by DeepSeek and Qwen). | OBSERVED (2007, 2049); INFERRED (rest) | godot/fx/fx_weapons.gd; godot/fx/fx.gd shared_spark_check (2049) | "shield_hit(" | The one-pool, quiet-block rules are the kind of thing a weapons-file resolution can break without a textual alarm. | When 2021 lands, diff its fx_weapons.gd hunks against the merged tree for shield_hit specifically and re-run the quiet shield block assertions. | Medium |

## Faction rules in combination (summary)

- Eclipse (violet, no green or orange): broken by finding 1 (kind 8) and at risk from finding 9 (acid green). Both exist only in combination.
- Directorate / Hegemony (sparks follow damage_glow): broken by finding 2 (kind 7 fire rerouted as sparks) and finding 7 (damage_glow resolution).
- Chorus (organic effects, no metal sparks): at risk from findings 1 and 2 (SMOKY kind 20, rerouted kinds); no leg found a proven Chorus break in the diffs, and the chair does not claim one.
- Glasswrights (no orange fire, no soot, no white cold gas): no leg found a combined break in the evidence; the pack carried no Glasswrights-specific kind assignments. Not proven safe, only unindicted.
- Shield blocks (quiet, one pool per ship): no clash found; one unverified corner recorded as finding 10.

## Safe merge order (chaired)

Step 0, before any merge: renumber the sprite kinds once (findings 1 and 2) and write the registry into fx.gd. SPARK_KIND moves off 8; kinds 1, 7 and 20 are settled; SMOKY is re-audited against the final registry. No merge order substitutes for this step.

Gate, before the train: every PR green on its own rebased head. Today that means 2021 fixes its broad check failures and 2007 fixes its standing-check failure. A PR that is red alone does not enter the train.

1. PR 2049 first. It is green, defines the shared spark API the others consume, and its only conflict with main is faction_looks.json. Re-check after: all checks, the quiet shield block assertions, the faction palette test, and a grep that no kind 7 or kind 8 emitter enters flight_streak unintentionally.
2. PR 2007 second. Resolve the 8-file clash against the settled spark code; resolve faction_looks.json by field (finding 7); pin its launcher AFTER to a full SHA. Re-check after: all checks including standing checks, death_variety_1586_check.gd, the death-plane test, and 2049's palette test against the retuned damage_glow.
3. PR 2055 third. Its shader rewrite (+215 -20) resolves once against settled fx values; its conflicts with main (look_bench.gd, ship_view.gd, squadron_wing.gd) are render-side and do not interact with the kind registry. Re-check after: all checks, shader compilation, engine plume and trail captures, BEFORE and AFTER pinned to full SHAs.
4. PR 2021 last, and only once its own head is green. It carries the largest repair debt, its SMOKY table must be re-audited against the final registry, its acid line grep-verified (finding 9), its fx_weapons.gd hunks checked for shield_hit (finding 10), and its launcher path fixed (finding 5). Re-check after: all checks, the violet acid test, the kind 29 bio glob test against 2055's thrust sprites.

Where the chair departs from the blind Rey leg: the blind leg put 2021 first on footprint size. Three external legs and the check evidence outweigh that: a PR that is red on its own head goes last, behind a green gate. The blind leg's other findings stand as written in legs/leg_rey.md.

## Council record

- Rey blind leg: legs/leg_rey.md (written before the external legs were run).
- DeepSeek: legs/leg_deepseek.md. Chat: https://chat.deepseek.com/a/chat/s/e7185dd9-3648-4807-9777-2cfbbdbfbfa8
- Qwen (Qwen3.8-Max): legs/leg_qwen.md. Chat: https://chat.qwen.ai/c/70fc38eb-8572-4c78-99b6-1bb135819fae
- Gemini on Hydrogen (Flash seat): legs/leg_gemini.md. Chat: https://gemini.google.com/app/82088fc54504195c
- Grok: legs/leg_grok.md (seat empty, bot wall).

Not checked:
- Runtime behaviour of the merged tree: no combined build was run, so which kind-8 visual actually wins on screen is inferred from the buffer writes, not observed in a render.
- The root causes of PR 2021's check failures and PR 2007's standing-check failure; only their states at the pinned heads were read.
- Glasswrights-specific kind assignments and colours in the four PRs; the evidence pack carried none.
- The contents of fx_shaders.gd beyond the net diffs and conflict tests, so no specific uniform or pass collision is claimed.
- Save compatibility across the combined changes.
- Performance and frame-budget impact of the combined shader and particle load.
- Whether PR 2021's fx_weapons.gd conflict hunks touch shield_hit call sites (finding 10 records this as unverified, not as clear).
