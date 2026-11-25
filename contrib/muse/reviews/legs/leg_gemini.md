# Leg: Gemini on Hydrogen (the Flash seat), issue 2063

Gate record: New chat on gemini.google.com, signed in with the saved Google login. Model picker showed "Selected Everyday help 4 Hydrogen" before pasting and the composer still showed Hydrogen after generation. Brief pasted as plain text, no file attached. Chat: "Godot Space Tactics FX PR Review", https://gemini.google.com/app/82088fc54504195c

Response verbatim:

Findings (Q1 & Q2)

1. Sprite Kind 8 Collision (Eclipse Smoke vs. Shared Sparks)

File & Line: godot/fx/fx.gd:813 (and 822), godot/fx/fx_ship.gd:2623 (main) / 2571 (PR 2007)

Exact Quote: const SPARK_KIND := 8 and if kind in [1, 7, SPARK_KIND]:

Mark: INFERRED. PR 2049 hijacks kind 8 in stk() for flight_streak sparks, while main and PR 2007 use kind 8 for Eclipse ("deathless") dark smoke (spr()). If any Eclipse smoke emitter calls stk() instead of spr(), or if SMOKY in PR 2021 (godot/fx/fx.gd:760) treats kind 8 as smoke while PR 2049 treats it as a spark, Eclipse smoke and shared sparks share the same mask ID and conflict in status handling.

One-line fix: Assign SPARK_KIND a dedicated, unused sprite ID (not 8 or 7) and update PR 2049's stk() routing and tests.

2. Sprite Kind 7 Collision (Hegemony Fire/Vents vs. Shared Sparks)

File & Line: godot/fx/fx.gd:822 and godot/fx/fx.gd:760

Exact Quote: if kind in [1, 7, SPARK_KIND]: and const SMOKY := {3: true, 7: true, 8: true,

Mark: INFERRED. PR 2007 assigns kind 7 to Hegemony fire and non-organic vents, and PR 2021 marks 7 in SMOKY, whereas PR 2049 reroutes kind 7 streaks (stk()) into the shared spark path (flight_streak). Combining them mixes fire/smoke status logic with spark streak rendering on ID 7.

One-line fix: Remove 7 from PR 2049's stk() spark reroute list and migrate Hegemony fire/vent streaks to a dedicated fire/vent kind.

3. Eclipse Acid Green Regression Risk in Silent Non-Conflicting Merge

File & Line: godot/fx/fx_ship.gd:1908 (PR 2021) vs. godot/fx/fx_ship.gd:1886 (PR 2049)

Exact Quote: "deathless": return fac["damage_glow"]

Mark: INFERRED. PR 2021 changes Eclipse acid from green Color(0.5, 0.9, 0.2) to violet fac["damage_glow"], while PR 2049's branch still holds the old green line at a different line offset without a textual merge conflict. A careless conflict resolution in fx_ship.gd (which conflicts across 2007, 2049, 2055, and main) could silently drop PR 2021's hunk and break the Eclipse "violet, no green" faction rule.

One-line fix: Ensure godot/fx/fx_ship.gd:1908 retains PR 2021's fac["damage_glow"] return and run PR 2021's violet acid test after merging fx_ship.gd.

4. Chorus Organic Rule Risk on Shared Sparks and Kind 20

File & Line: godot/fx/fx.gd:822 and godot/fx/fx.gd:760

Exact Quote: if kind in [1, 7, SPARK_KIND]: and const SMOKY := {3: true, 7: true, 8: true, 15: true, 20: true,

Mark: INFERRED. PR 2007 assigns kind 20 to Chorus hatch and vent sprites (which PR 2021 marks SMOKY), while PR 2049 routes stk() kinds [1, 7, 8] into a unified spark path (flight_streak) with roles for hull, death, shield, engine, and weapon sparks. If Chorus emitters still trigger stk() on kinds 1, 7, or 8, or rely on damage_glow sparks without a Chorus override, it breaks the "Chorus: organic effects, no metal sparks" rule.

One-line fix: Audit all Chorus stk() call sites in fx_ship.gd, fx_weapons.gd, and fx_death.gd to bypass flight_streak or use organic bio-globs (kind 29).

5. Directorate (Hegemony) Spark Tint Desync Across faction_looks.json Conflicts

File & Line: godot/fx/faction_looks.json (merge test evidence) and godot/fx/fx.gd:813

Exact Quote: 2007 x 2049 conflict in 8 files (fx.gd, fx_death.gd, fx_death_beats.gd, fx_ship.gd, fx_weapons.gd, faction_looks.json

Mark: OBSERVED (the merge conflict and rule dependency are explicitly stated). PR 2007 retunes Directorate's damage_glow in faction_looks.json, and PR 2049's shared spark defaults to damage_glow while also editing faction_looks.json (and both conflict with main). Merging 2049's faction_looks.json over 2007's values will revert Directorate's retuned spark color.

One-line fix: Keep PR 2007's damage_glow values in faction_looks.json when resolving the 2007 x 2049 x main conflict, then re-run PR 2049's faction palette test.

6. Capture Launcher LB_MOMENTS Path Crash (res:// vs. Windows Path)

File & Line: PR 2021 wave2b_run4.bat vs. PR 2007 capture.bat

Exact Quote: LB_MOMENTS=res://bench/look_moments_1693_run4.json and if not exist "%LB_MOMENTS%" exit /b 2

Mark: INFERRED. PR 2007's launcher (and look_bench.bat, which conflicts between 2007 and 2049) enforces a Windows if not exist "%LB_MOMENTS%" check. PR 2021 sets LB_MOMENTS to a Godot res:// path, which fails Windows file existence checks and exits with code 2 once combined with 2007's launcher logic.

One-line fix: Change LB_MOMENTS in wave2b_run4.bat (and any legacy LB_ARGS in capture_2042_before_after.bat if parsed by 2007) to a relative Windows filesystem path.

7. Capture Launcher Unpinned Branch Refs (AFTER / BEFORE) Violating Capture Rules

File & Line: PR 2007 capture.bat, PR 2049 capture.bat, PR 2055 capture_2042_before_after.bat

Exact Quote: if not defined LB_AFTER set "LB_AFTER=origin/codex/issue-1991" and BEFORE defaults to "origin/main"

Mark: OBSERVED. Only PR 2021 enforces a 40-character commit SHA for AFTER. PRs 2007, 2049, and 2055 default AFTER (and 2055 defaults BEFORE) to mutable branch refs (origin/...), violating the capture rule that AFTER must pin to a full commit SHA.

One-line fix: Require 40-character hex commit SHAs for both BEFORE and AFTER in all four .bat launchers and reject branch names.

8. Eight-File Merge Collision Between PR 2007 and PR 2049

File & Line: godot/fx/fx.gd, fx_death.gd, fx_death_beats.gd, fx_ship.gd, fx_weapons.gd, faction_looks.json, death_variety_1586_check.gd, tools/pc/jobs/look_bench.bat

Exact Quote: 2007 x 2049 conflict in 8 files (fx.gd, fx_death.gd, fx_death_beats.gd, fx_ship.gd, fx_weapons.gd, faction_looks.json, death_variety_1586_check.gd, look_bench.bat).

Mark: OBSERVED. Both PRs heavily rewrite death beats, weapon hits, ship effects, and faction_looks.json. Combining them without sequential rebasing risks breaking PR 2007's wreck cap/death-plane fixes or PR 2049's quiet shield block and shared spark routing.

One-line fix: Merge PR 2049 first, rebase PR 2007 onto it, and verify both death_variety_1586_check.gd and PR 2049's shield/spark tests pass.

9. Render & Engine Trail Overlap Between PR 2049 and PR 2055

File & Line: godot/render/ship_view.gd, godot/fx/fx_ship.gd, godot/fx/fx_shaders.gd

Exact Quote: godot/render/ship_view.gd: 2049 and 2055 and 2007 x 2055 conflict in look_bench.gd, fx_shaders.gd, fx_ship.gd.

Mark: INFERRED. PR 2049 introduces engine sparks (flight_streak) while PR 2055 adds RCS cone jets, engine plumes, and trails across ship_view.gd, fx_ship.gd, and fx_shaders.gd (+215/-20 lines). If both attach emitters to the same engine/thruster hooks in ship_view.gd or fx_ship.gd, engine visuals will double-emit or shader uniforms in fx_shaders.gd will collide.

One-line fix: Rebase PR 2055 after 2049 and 2007, separate shader uniform blocks in fx_shaders.gd, and visually inspect engine plumes plus engine sparks in look_bench.

10. PR 2021 Failing State and Breach/Shader Conflicts

File & Line: godot/fx/fx_breach.gd and godot/fx/fx_shaders.gd

Exact Quote: Nearly every Godot check fails on its own head. and 2021 in godot/fx/fx_breach.gd and fx_shaders.gd

Mark: OBSERVED. PR 2021 is broken on its own head and conflicts with main in fx_breach.gd and fx_shaders.gd (which also conflicts with 2007 and 2055). Merging 2021 before fixing its standalone Godot failures will break the combined branch's test suite.

One-line fix: Hold PR 2021 out of the merge train until its standalone Godot checks pass and its fx_breach.gd/fx_shaders.gd conflicts are resolved against the updated main.

Faction Rules Breaking Only on Combination (Q2)

Eclipse ("violet, no green or orange"): Breaks on combination if kind 8 Eclipse smoke (fx_ship.gd:2623 / 2571) is routed through PR 2049's SPARK_KIND := 8 (fx.gd:813), or if PR 2049's stale green acid line (fx_ship.gd:1886) overwrites PR 2021's violet acid fix (fx_ship.gd:1908) during fx_ship.gd conflict resolution.

Directorate / Hegemony ("sparks follow damage_glow"): Breaks on combination when resolving the faction_looks.json conflict between PR 2007 (which retunes damage_glow) and PR 2049 (which ties shared spark colors to damage_glow), or because PR 2007 assigns kind 7 to Hegemony fire while PR 2049 routes kind 7 streaks into shared sparks (fx.gd:822).

Chorus ("organic effects, no metal sparks"): Breaks on combination if PR 2049's shared spark system (fx.gd:822) catches Chorus streaks (kinds 1, 7, 8) or interacts with PR 2007's kind 20 Chorus hatch/vent sprites via PR 2021's SMOKY table (fx.gd:760).

Glasswrights ("no orange fire, no soot, no white cold gas"): Not enough info in the evidence pack to see how Glasswrights' specific sprite kinds or colors are touched by these four PRs.

Shield blocks ("stay quiet; one shield pool per ship"): Does not break when combining 2007 and 2049 (the evidence confirms shield_hit call sites in fx_weapons.gd are unchanged by 2007 and 2049); not enough info for 2021 and 2055 on shield call sites.

Safe Merge Order & Re-Checks (Q3)

First: PR 2049 (Shared spark effect), after resolving SPARK_KIND := 8 and kind 7 collisions. Why first: All checks already pass on its head, and it only conflicts with main in faction_looks.json. It establishes the shared spark API that 2007 and 2055 interact with. Re-check after merge: Reassign SPARK_KIND off 8 and remove 7 from fx.gd:822 so Eclipse smoke and Hegemony fire are not hijacked; re-run all Godot checks, PR 2049's quiet shield block test, and its faction palette test.

Second: PR 2007 (Faction colour leaks, wreck cap), rebased onto main + 2049. Why second: Its four Godot game checks pass; only "Standing checks (rules, text, saves)" fails, which must be fixed on rebase. Resolving the 8-file conflict with 2049 now locks in faction_looks.json, fx_death.gd, and look_bench.bat before shader-heavy PRs land. Re-check after merge: Fix the "Standing checks (rules, text, saves)" failure, verify Directorate sparks use 2007's retuned damage_glow in faction_looks.json, run death_variety_1586_check.gd, confirm the death-plane test still passes, and pin LB_AFTER to a 40-char SHA in capture.bat.

Third: PR 2055 (RCS cone jets, engine plumes, trails), rebased onto main + 2049 + 2007. Why third: All checks pass on its head, and its fx edits are largely disjoint from 2049/2021, though it conflicts with 2007 in fx_shaders.gd, fx_ship.gd, and look_bench.gd (plus ship_view.gd and squadron_wing.gd on main). Re-check after merge: Verify fx_shaders.gd (+215/-20) merges cleanly without breaking 2007/2049 uniforms, check ship_view.gd so engine plumes do not double-spawn over 2049's engine sparks, and pin BEFORE/AFTER SHAs in capture_2042_before_after.bat.

Fourth (Hold until fixed): PR 2021 (Persistent acid and bio contact), rebased onto main + 2049 + 2007 + 2055. Why last: Nearly every Godot check currently fails on its own head, and it conflicts with main in fx_breach.gd and fx_shaders.gd. Re-check after merge: Fix its failing Godot checks, confirm BIO_CONTACT_GLOB := 29 stays clear of thrust sprites and SMOKY (fx.gd:760) does not conflict with 2007/2049 kinds, verify Eclipse acid stays violet (fx_ship.gd:1908), and change LB_MOMENTS in wave2b_run4.bat from res:// to a Windows path.

Strongest Objection to the Chair's Likely Synthesis

The chair will likely treat PR 2049 as the safest, cleanest anchor to merge untouched because "All checks pass" on its head and it only conflicts with main in one file (faction_looks.json), while treating PR 2021 as the main blocker because its checks fail. My strongest objection: merging PR 2049 as-is silently breaks the game's sprite kind registry (fx.gd:813, 822) by claiming kind 8 (SPARK_KIND) and kind 7, which main and PR 2007 actively use for Eclipse dark smoke (fx_ship.gd:2623, 2571) and Hegemony fire, and which PR 2021 registers in SMOKY (fx.gd:760). Passing CI on 2049's isolated branch is a false green because its tests do not catch cross-PR sprite ID collisions that corrupt Eclipse and Directorate faction visuals the moment the branches meet.

Not checked:

Exact sprite mask assignments for Glasswrights (fire, soot, cold gas) and whether any PR violates Glasswrights' faction rules.

Exact contents of godot/fx/fx_breach.gd, godot/render/squadron_wing.gd, godot/fx/fx_death.gd, godot/fx/fx_death_beats.gd, and godot/tools/ci/godot_checks.txt beyond conflict file lists.

Specific root causes of why "Standing checks (rules, text, saves)" fails on PR 2007 and why nearly every Godot check fails on PR 2021.

Exact shader uniform names and pass structures inside the +215/-20 diff of godot/fx/fx_shaders.gd in PR 2055 and its overlap with PRs 2007, 2049, and 2021.

Whether PR 2021 or PR 2055 modifies shield_hit call sites or shield pool logic in godot/fx/fx_weapons.gd or godot/fx/fx_ship.gd.
