# Outside check: PR 867 (issue 371, ion-lock catch fix)

Refs #256. PR 867 head cd064eff, base cc8d8dfa, checked Nov 18, 2026. Council: blind Rey (chair, own runs below), DeepSeek, Qwen, Flash. Grok seat not run for this batch (parked, bot wall).

## Verdict: GO WITH CONDITIONS

Unanimous that the fix is correct, minimal and mirrored. Flash GO; DeepSeek and Qwen GO WITH CONDITIONS, both conditions about evidence the chair could not produce locally, resolved or recorded below.

## What the chair verified directly (OBSERVED)

1. The diff is three files: battle.js (one line: syncShields(u) moved out of the if(!u.regenLock) block, still inside else if(u.shMax>0)), godot/rules/rules.gd (the same restructure; from the head file, syncShields sits at 3 tabs inside the 2-tab elif shMax>0 and outside the 3-tab regenLock if, whose body is only the shp assignment), and contrib/opus/tools/shield_pool_tests.js (one new JS check, one new twin fixture sequence).
2. Own runs, Node 22 (the pinned version): head tests against head battle.js: 11 ok, 0 FAIL. Head tests against BASE battle.js: 10 ok, 1 FAIL, the only failure being the new check. So the regression check fails without the fix, for the right reason, and nothing else in the suite moved.
3. Fixtures generated at head for the new twin sequence: step 2 catches [14,12,7,9] with the route still on starboard; step 3 (locked turn start, route cleared) [14,9,7,9]. The PR body's "step 3: 12 against 9" is exactly the starboard catch: stale 12 without the fix, 9 with it. Consistent.
4. CI check runs on head cd064eff, read through the API: Standing checks success, Godot rules parity success, Godot game checks success, open-pr success.

## Council agreement

All three legs: JS and GD implement the same fix at the same scope (syncShields now runs for shMax>0 ships whether or not regen is locked; still skipped when shieldOff>0 or shMax=0); the new JS check cannot pass vacuously (it asserts the routing boost was real, routed[1] > fresh[1], and that the pool did not regen, shp stayed 20); the base-vs-head run isolates battle.js as the only differing input; no behaviour change on the normal regen path, the shieldOff path, or shieldless ships. DeepSeek noted the sync now fires for any regenLock source, not only ion, which is the intended generality of the move.

## Conditions and notes

1. Godot twin runtime (DeepSeek, Qwen): the chair has no Godot binary and did not run shield_pool_test.gd locally, in either direction. At head this is covered by the green CI above (Godot rules parity and Godot game checks both success on cd064eff). The base-direction claim (old rules.gd fails the new sequence at step 3) rests on the static mirror and the fixture arithmetic, and is recorded as NOT CHECKED by execution in this check. If the Board wants it executed, it is a one-command run on the PC runner.
2. chainCut (raised as NOT CHECKED by all three legs; chair closes it from the diff): chainCut only scales the regen amount rg, which is computed before the lock check and applied only inside it. syncShields reads pool and route, never rg, so moving it cannot interact with chainCut. The suite's Chain Lightning check passed in both of the chair's runs.
3. shieldOff stale window (DeepSeek, Qwen): while shieldOff>0 the route still clears at turn start and the catches still go stale until the shields return, the same class as the fixed bug, pre-existing and outside this PR's scope. One line for the Board's tracking if it is not already tracked; not a merge condition.

## Method note

Pack carried the full diff, the GD tab structure, the chair's run outputs and the fixture table. Legs ran under their standing gates (DeepSeek DeepThink on and Search off, Qwen3.8-Max selector and header, Flash-Lite picker signed in), each verified before and after.
