# Outside check: PR 635 (issue 633), Hullbreaker build sheets A18, A19, A20

Refs #256. Check of the merged PR 635 (head and Board merge state 68b86ff1), run Nov 13, 2026.
Council per R231: blind Rey leg first, then DeepSeek (DeepThink on, Search off, both ends), Qwen (Qwen3.8-Max in the selector before and in the header after), Grok (free, Fast), Flash (picker "Quick answers 3.5 Flash-Lite" before and after). All five legs read the same evidence pack chaired from the PR diff, the sheet files and the merged tree. Leg files: this delivery's workspace record (pack and legs kept by the chair).

## Verdict: GO WITH CONDITIONS

Four legs GO outright; the blind Rey leg GO WITH CONDITIONS. No BLOCKING from any leg. The conditions are two cheap hardening notes on the self-test, agreed in substance by four legs; both are follow-up material for the Board since the PR is merged.

## The centres

1. **Manifest routes for the new kit kinds (layout.py KITK). PASS, chair-verified.** KITK gains exactly 'hangar', 'craft', 'spare' and nothing else. The builders exist: hangar_mouth and craft in tools/blender/kits/hullbreakers/parts.py, and the spare bell emitted through the kit in corsair_A20.py (feature SB1, kind 'spare'), so 'spare' is honestly a kit route. The chair recomputed all three delivered manifests against the new KITK: zero route mismatches across A18, A19, A20; A20's H1, H2 (hangar), C1, C2 (craft) and SB1 (spare) all read route 'kit'. Unanimous.

2. **check_export_selftest.py turret-muzzle path. PASS on the shipped ships; two conditions below.** first()'s fallback reaches a turret's muzzles among the grandchildren; backward() composes the aft rotation correctly through the turret frame (local = Rp.T @ Raft; Qwen re-derived the inverse composition independently); breach_near() now converts the muzzle into the ship frame before placing the anchor (the old one-liner copied local coordinates, wrong frame for a turret muzzle); the old direct-child path is preserved for ships with a gun on the ship node. The PR reports the self-test PASS on A18, A19, A20 and the A16 regression passing; no leg found a wrong refusal or a false pass.

3. **A20's recipe-forced changes. PASS, arithmetic re-derived.** The anchor rule is 0.03 of length from every part: 0.03 x 16.5 = 0.495 (stated 0.5). The old 0.6 plate leaves at most 0.3 clearance, so no valid anchor site existed amidships; the 1.4 plate (mouths 3.6 and 3.0 narrowed to 3.2 and 2.6, total span 7.2 unchanged) leaves 0.7, and the anchor and boarding origin sit on it at x -0.65 (Qwen's derivation, chair agrees). Bay points sit on the mouth floors at the lip because the mouth centre is open air and check_export refuses off-mesh points. The three seam paths in corsair_A20.py run 4.2 to -4.2 as stated (paths stopped at 3.0 left 26 inside triangles outside their piece). The aft fighter sits mid shorter mouth. Both mouths port side per Ryan's ruling. Minimal changes that satisfy the export rules.

4. **The merge at 68b86ff1. PASS, chair-verified.** build_sheets/README.md gained exactly the three rows and all six linked files exist in the PR. The KITK union adds only the three kinds. The fixture record: the chair recomputed sheet_fixture_hash.py's digest over its seven files at the merged head and got 132eef32f9180ef3c32aa722a5c4ba5befcd6b35110faadc8b4a387777872437, an exact match to the record in C19_51_unbaked.sheet.txt, consistent with the byte-identical A16 glb claim. kit.py course plating is opt-in only (courses=True in A18, A19, A20 only; A16, A17, E11, E12, C10, C11 have none), so earlier sheets' geometry is untouched at source level. ships.md 2c carries the two Board rules with the work (R214).

## Conditions (follow-up, not merge blockers; the PR is already merged)

1. **off_mesh through a turret is frame-mixed.** off_mesh is unchanged text, but first() now hands it turret muzzles, so it applies the ship-frame numbers (top(g), 5 percent of length) as a translation in the muzzle's local frame. It still lands off the mesh on today's near-identity turret layouts, so the case proves refusal, but the offset a reader expects from the comment is not the offset a rotated turret would get. Fix by displacing in world space and re-expressing locally, or comment the limitation and add a rotated-turret self-test ship. (Blind Rey, DeepSeek, Qwen, Grok in substance.)
2. **first()'s fallback is one level deep.** A muzzle nested under a turret's turning mesh (a great-grandchild) would make the fallback's next() raise instead of breaking the case. No current export nests that way. A short depth walk closes it. (Blind Rey, DeepSeek, Qwen.)

## Notes

1. audit_selftest.py's one-gun one_normal_missing case duplicates the gun record without its normal; the audit may then refuse for the duplicate rather than the missing normal the case names. The self-test asserts refusal only, so the case can pass while proving slightly less than its name. The multi-gun behaviour is unchanged. (Blind Rey only; DeepSeek and Qwen read the case as correct as written.)
2. in_turret(), backward() and breach_near() locate nodes with list index() over node dicts, which compares by value; two value-identical nodes would misindex. Hard-point nodes carry unique names and extras, so this is theoretical on real exports. (Blind Rey only.)
3. Leg slips recorded for the record, nothing rests on them: Flash's leg credited A19 as a non-turret ship for the old path (A19 has two turrets; the example of record is A16); DeepSeek's leg mentioned a second anchor point at x +0.65 that the pack does not record (the anchor and boarding origin are both at x -0.65).

## Not checked

The sandbox and PC runs themselves (fit, stage 4, export, install) were read from the PR's tables, not re-run by the council; the check is source and record level. The round 2 look (outlines, course plating as rendered) was not re-judged; the Board's review already covered it and Ryan accepted the concepts in PR 625.
