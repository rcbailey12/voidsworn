# Outside check: PR #286, issue #230 environment reconciliation and nebula motion spec

Standing outside check under #256 (R132). PR head opus/issue-230 @ 3b34bf8a47fe32c175066421c58140d4fdfc712e, draft. Checked against contrib/opus/briefs/environment_reconciliation.md and contrib/opus/briefs/nebula_motion_spec.md as added by the PR, the audit record they cite, and the R129 impact sweep standard. Five legs: blind Rey, DeepSeek (DeepThink on, Search off), Qwen (Qwen3.8-Max, gate passed before and after), Flash, Grok. Full council per the owner's Nov 9 direction. The chair verified every load-bearing leg claim against the pack before adopting it.

## Verdict: GO WITH CONDITIONS

The reconciliation itself is right. Every derived number in both documents of record was recomputed independently by at least three legs and the chair, and none is disputed. The shipped-default equivalence claim holds line by line. The conditions are about the guard, not the settlement: env_reconcile_tests.js, the file whose whole job is to stop the silent document-code disagreement the Nov 6 audit was filed over, pins the code side well and the document side barely at all, and it has three fail-open holes on the code side. Those are cheap to close and worth closing in this PR or as a tracked follow-up before #139 and #100 build on these documents.

## What was verified

Numbers (all recomputed from the shipped values in the pack; no leg disputes any of them):

- Base drift: |(0.012, 0.004, 0.007)| / 0.075 = 0.1928 u/s, stated 0.193; one hex (17.32 u) in about 90 s.
- Layer table: body 0.116 / 0.193 / 0.308 / 0.077 u/s and filament 0.196 / 0.327 / 0.523 / 0.131 u/s all follow from the multipliers (0.6 / 1.0 / 1.6 / 0.4) and the filament ratio 1.694 (stated 1.69, from 6.1 x drift over 0.27 cycles a unit against drift over 0.075).
- Storm: body 0.328, wisps 0.524, veil 0.131 reversed; storm filament speeds 0.555 and 0.889 u/s, one 3.7-unit cell in about 4 to 7 s.
- NB11: flash full within 8 u = 0.46 hex, gone at 12 u = 0.69 hex; sheet glow 1/e at 22.4 u = 1.3 hexes, a tenth at 33.9 u = 2.0 hexes.
- AS14: wreck cap periods 81.7 / 163.4 / 238.8 s at scales 1.3 / 2.6 / 3.8, stated 82 to 163 and hero 163 to 239.
- AS16: rock shares from s = 0.3 + 2.5 u^2.4: 21.2 percent at 3 to 5 units (stated 21), 26.3 percent at 3 or more (stated 26); plain path 13.9 percent at 3 or more (stated 14). The per-hex floor figures (54 and 74 percent) were the one set no leg could check on first pass; the DeepSeek leg derived them as a binomial average over 15 to 22 rocks per hex (54.7 and 73.6) and the chair's own recompute gives 54.5 and 73.3, so the record's 54 and 74 stand as honest derivations, with the small spread coming from the averaging method.
- AS18 maxima: living rock 5.6, plain rock 3.9, hero wreck 7.6 (at kit radius 1.0), all under the 8.66 cap.

Shipped-default equivalence: every leg traced the changed lines to their default paths and found the shipped behaviour: wreck_tumble and rock_tumble in cap mode return exactly the old expressions; the slot rate _install_chunks now reads is that same value; the wreck shader cap is the old literal carried by the tumble_k uniform; rock and crystal tumble_k default to 0.0; gas flat_rates defaults to 0.0 and is set only under VS_GAS_FLAT=1; the world.gd change is a comment only; no seeded random draw is added or moved. Saves, old profiles, rules, UI and the JS twin are untouched.

R129 sweep: Qwen's independent caller table and the chair's reading agree with the PR body's sweep (tumble_rate, add_debris_rocks on both paths, WR.material including blocker_visuals.gd, WR.crystal_material, the hull-chunk path). DeepSeek is right that the sweep's Callers line names the functions loosely rather than the new surfaces (_gas's setter, the two new tumble functions, the world_shots motion functions) one by one; the defaults paragraph does cover their behaviour, so this is a record-thinness note, not a missed caller. No leg found a missing caller.

ST3 conversion: faithful. The removed asserts' predicates survive whole inside matches_r94, including the dorsal clearance sub-condition; mismatches print a REPORT: line; the correctness asserts and the R100 locked-primitive hashes are untouched; STATION_KIT.md's fail-versus-report split matches the code.

## Conditions

1. **Pin the documents of record in env_reconcile_tests.js (DeepSeek, chair-verified).** The test's only document-side checks are four strings in the motion spec ('0.193 units a second', '0.46 hex', '0.69 hex', '1.3 hexes') and one in the reconciliation ('0.10 / max(1, scale)'). The layer drift table, the storm values, the sheet glow's '2.0 hexes', the AS18 cap as written in the record (8.66), and the BD16 figures as written in the record (0.075, 0.065, 0.065) are unguarded: edit any of them in the document alone and the suite still passes. That is the audit's silent-disagreement pattern, one PR later, on the guard's own watch. Add document-side assertions for the values the test already pins on the code side.
2. **Close the three fail-open holes on the code side (DeepSeek, chair-verified by reading the test).** (a) The ST3 checks are negative only (old asserts absent); nothing checks that r94_shape, r94_heights, matches_r94 or the REPORT: line exist, so deleting the reporting would pass. (b) The flat_rates check pins the uniform's default declaration but not the _gas setter line, so an unconditional set would pass. (c) The test never names wreck_tumble or rock_tumble (zero occurrences), so the tumble laws' bodies could drift while TUMBLE_K and the mode string stay. Add presence pins for each.
3. **One sentence in nebula_motion_spec.md section 2 (chair).** With VS_GAS_FLAT=1 the flat assignment runs before the storm multiplier, so on a storm map the veil runs at -1.7 x base (0.328 u/s), not at its shipped storm speed of 0.131 u/s. The spec's wording (multiplier 1.0, "the storm's 1.7 and the veil's reversal kept") can be read either way, and the flat sheet is the one Ryan judges NB8 from. State the flat storm veil rate in the spec so the sheet is read correctly.

Tracked, not blocking: Qwen's further unguarded values (the band height windows in section 2, the section 5 values for old clouds, wisps, the gravity well and dust, the breathing phase spread, and the syntheses' Reconciled pointer lines) can ride with the condition 1 and 2 extension if it is cheap, or be picked up when #139 or #100 next touches the spec.

Standing steps, unchanged by this check: the PR stays draft until the board runs the PC motion capture (env230_motion.bat) and the sheets are judged; the rocks-turn question (A, B or C, Opus pick B) is Ryan's after the capture, per reconciliation section 9.

## Where the legs disagreed

Qwen reports "no fail-silent pattern found" in the test; DeepSeek lists the fail-open holes in condition 2. The chair sides with DeepSeek: each hole is checkable in the test text itself (the grep counts and the negative-only ST3 patterns are quoted above), and Qwen's own section 5 lists adjacent unguarded values. Flash and Grok land between the two and both flag the weakly pinned document claims. Verdicts: Rey GO, Flash GO, DeepSeek GO WITH CONDITIONS, Qwen GO WITH CONDITIONS, Grok GO WITH CONDITIONS.

## Not checked

- No in-game frame or motion sheet; the capture is the board's PC step and every look claim waits on it.
- kit.json and rocks.json contents (the hero maximum of 7.6 assumes the kit's maximum piece radius is 1.0, as the record states).
- board_look.gd's tint draw gating and the far field batches' stored rates (asserted in the record; the code is outside the diff).
- Whether run_all_checks.js picks up the new test file (asserted in the PR body; the runner is not in the pack).
- env230_motion.bat's behaviour on the PC (read as text only), and station_kit.py under Blender (py_compile only, as the PR states).
