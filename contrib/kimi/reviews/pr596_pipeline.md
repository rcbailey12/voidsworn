# Outside review of PR 596 (issue 592): the ship pipeline repairs

Reviewer: Kimi Code workhorse (issue 603, trial job 1 of 4). Date: 2026-11-13.
Scope: the merge `cf519b72` ("Merge pull request #596"), checked against the code at main (`810a68c`).
Every file PR 596 touched is byte-identical between `810a68c` and current `origin/main` (`afed0f21`),
so each finding below holds at main. Where a later commit already repaired something the merge got
wrong, it is named under "Caught at merge, fixed since" instead of the findings.

## Verdict

The eight repairs do what the PR body says. The R226 seam rule, the env.bat quoting, the stage 7
install cache refresh and the engine bell rule were re-run here and reproduce. Three findings,
ranked worst first, are below; only the first is worth a fix before the route widens past the
corsair Battle-barge.

## The eight repairs, checked

1. **env.bat and stages 3, 4, 5 FOR quoting.** Holds. Every `for /f` line that runs ship.py wraps
   its command in the extra pair of quotes (env.bat:22-42; 3_trace_hull.bat:17; 4_parts_kit.bat:28;
   5_paint_bake.bat:22). Run on real cmd.exe here:
   `SHIP=corsair_A16` gives `HULL=sheet_hull CELL=A16 CODE=C19_51 SHEET=corsair_A16 LEN=26.0 BAKE=none`;
   `SHIP=C15s_23` gives `HULL=armA8 CELL=Ab8 CODE=C15s_23 SHEET= LEN=14.5 BAKE=bakeAb6.py`.
   No filename-syntax errors, no empty vars. The new SHEET and LEN reads work, LEN through the
   sheet's LENGTH by ship.py's AST read.
2. **corsair_A16.json and the sheet route.** Holds. The json names game `c_boss`, folder `C19_51`,
   `"sheet": "corsair_A16"`, hull `sheet_hull`, `"bake": "none"`, yaw null (tools/recipe/ships/corsair_A16.json).
   The concept it names exists. Stage 1 and 2 read the concept from the json (1_concept_in.bat:8-9,
   2_shape_ref.bat:13-15; ship.py concept squaring and the raw mode for TRELLIS.2 read clean).
3. **The build contract.** Holds, re-run here: `sheet_contract_selftest.py` on A16 prints PASS with
   all 10 rows (length one, LENGTH 26.0, 3 transverse seams, 40 muzzles in their data.js slots,
   8 turret pivots, 6 engine exits, 24 interiors, the skin modifier, both broken inputs refused by name).
4. **The turrets.** Holds, re-run here: stage 7's export writes 8 `turret_<n>` nodes (11,436
   triangles), and the self-test's `turret_merged` and `turret_no_mesh` cases are refused (lines pasted below).
5. **audit.py, optional longitudinal seam, part = its grp.** Holds, re-run here on a fresh sheet build:
   audit PASS, 306 parts, 17 guns, nothing across a seam, structure across B1, HB1, HB2, L0p, VF2p, VF2s,
   exactly the PR body's list. The self-test passes all 9 cases including `machine_across` (refused)
   and `structure_across` (allowed).
6. **The engine bell rule.** Holds, re-run here: a fresh unbaked export passes `check_export.py
   unbaked=1` at the default 0.012 tolerance, and the self-test's `bell_radius` and `bell_plane` cases
   are refused, each named as "not the centre of an open engine bell" (lines pasted below).
7. **Stage 6 as analysis product.** Holds. bench209r3.gd refuses to run without `length=` and
   6_lod.bat fails without LEN and passes `length=%LEN%`. export3.py's `clean()` removes the
   degenerate faces after decimate. The LOD chain being analysis-only is written into RECIPE.md,
   6_lod.bat and export3.py's header.
8. **The stage 7 install cache refresh.** Holds. 7_export.bat:58-61 runs `build_assets.gd
   --ships-only` then `installed_ship_check.gd %CODE%`, and either failing fails the stage. The
   headless route proof passes here: `INSTALL REFRESH PASS` (all 8 ok lines).

Also checked: `authored_interiors_check.gd` moves its seam by at most half the gap to the next
(authored_interiors_check.gd:93-110). Every recipe .bat is CRLF (`file` says so for all eight).
`sil_dump.py` and `bakeAb6.py` read `shape_ref_yaw` from the ship json; the only remaining `22.0`
alignments are in the dormant bakeAb3/4/5 scripts, which no ship json, stage bat or live module names.

## The brief's look-fors, one line each

- **A check reading one old ship's shape (RULEBOOK 0.9, R225):** yes, one remains: finding 1.
- **A second copy of a fact the sheet holds:** yes, one: finding 2 (the seam's x and its path).
- **Seam rule 5.17 (R226):** holds. Part kinds come from the faction kit (kit.py:470 stamps
  `part_kind` and `machine` from the kit's MACHINES on every part placed through emit); the audit
  fails only `crossing_break_lines` (machines) and lists `structure_across_seams` without failing
  (audit.py:49, plumbing.py audit); a part with no kind mark is held to the machine rule.
- **env.bat FOR quoting:** holds, proven on real cmd.exe (repair 1 above).
- **Stage 7 install cache refresh:** holds (repair 8 above).
- **Engine bell rule in check_export.py:** holds (repair 6 above); the 0.012 limit is not loosened
  for any point.
- **Windows cmd with PowerShell 5.1:** nothing breaks. The only PowerShell in the route is the
  pre-existing `Get-Date -Format yyyyMMdd_HHmmss` stamp line (7_export.bat:45), valid 5.1. The new
  `goto` flows in stages 3, 5 and the `:audit` label in stage 4 parse as written.

## Findings, ranked worst first

### 1. installed_ship_check.gd sets ShipView up as the corsair Battle-barge whatever ship it checks (medium)

- File and line: godot/render/test/installed_ship_check.gd:64
- Quoted line: `sv.setup({"id": "readback", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "code": code}, Vector3.ZERO)`
- Why it matters: RULEBOOK 0.9(c) (R225): a check reads the item's own numbers. Stage 7 calls this
  check with only the folder code (7_export.bat:60), so for any installed ship the readback feeds
  ShipView a fixed faction and class. ShipView turns the class into its draw length
  (`L = HT.CLS_LEN.get(cls, 10.0) * HT.SHIP_K`, ship_view.gd:75) and the faction into its look fix
  and engine colour (ship_view.gd:71-73, 162-164, 213). The readback's own assertions (the `a4`
  flag and the hard point node names) do not depend on either, so on the next non-corsair,
  non-Battle-barge sheet ship an install that would draw at the wrong size or with the wrong look
  still prints INSTALL READBACK PASS. Today only C19_51 (corsair Battle-barge) goes through the
  route, so nothing is wrong yet; the wart is inherited by every later sheet ship (A17's C15s_23
  install is the next one).
- The fix: hand the check the ship's own fac and cls (7_export.bat knows SHIP; env.bat can read
  them from the ship json the way it reads CODE) and pass them into the setup dict, or read them
  from the installed manifest entry.
- How sure: high that the line is hardcoded and what fac and cls drive in ShipView; low present-day
  impact (only C19_51 is installed through this route at main).

### 2. A sheet seam's station lives in two places: the break line's x and its plan path (low)

- File and line: tools/blender/build_sheets/contract.py:106-107
- Quoted lines:
  `t_lines = [r['x'] * s for r in trans]`
  `t_paths = [[[px * s, py * s] for px, py in r['path']] if r.get('path') else None for r in trans]`
- Why it matters: RULEBOOK 0.9(b): one home per fact. The sheet writes both (for example
  corsair_A16.py:240-245: B-2 keeps `x=-2.5` while its path wanders -2.9 to -1.7). The audit tests
  along the path, but the GLB seam's point `p` comes from x (export7.py writes `p=[x, 0, 0]` plus
  the path), and since issue 600 the runtime death cut follows the path. A sheet edit that moves
  one and forgets the other leaves the audit and the game disagreeing with no error anywhere.
  A16's three seams are consistent today (each x sits inside its path's x range; checked by hand).
- The fix: in the contract, derive the seam's nominal x from the path (the mean of its xs) instead
  of reading `r['x']`, or refuse the sheet when x lies outside its own path's range.
- How sure: high that the two copies exist and can drift; low impact today (the current sheet is
  self-consistent, and the contract self-test would still pass a drifted one).

### 3. _template.json still seeds every new ship with C15s_23's shape reference yaw (low)

- File and line: tools/recipe/ships/_template.json:9
- Quoted line: `"shape_ref_yaw": 22.0,`
- Why it matters: repair 2's route and R225 make each ship carry its own yaw, with null meaning
  "measure it" (common.shape_ref_yaw passes None through to ai_align, which measures the long
  axis). But `ship.py new` copies the template, so a ship started from scratch still inherits
  C15s_23's 22.0 silently and stage 3 would align its shape reference at the wrong yaw with no
  warning. corsair_A16.json itself does it right (`"shape_ref_yaw": null`); the template's own
  note says "do not keep 22.0", but nothing enforces it. Pre-existing, not introduced by PR 596,
  but it sits inside the exact seam the PR repaired.
- The fix: default the template to null so a new ship is measured, as A16 is.
- How sure: high that the value and the copy path exist; low to medium future impact (one wrong-yaw
  bake for the next hand-started ship, caught at the stage 3 overlay by eye).

## Caught at merge, already fixed at main

- As merged, the Hullbreaker kit's MACHINES did not include `claw_arm`, the kind `kit.claw_arm`
  builds (kit.py:611-621), so a grabber arm across a seam would have been listed as structure and
  allowed, against R226's "claws ride whole". Commit `6897549a` (issue 532) added it;
  `tools/blender/kits/hullbreakers/parts.py:438` at main is complete and covers every machine kind
  the kit produces (checked against the Part kinds list). The Eclipse kit's MACHINES covers every
  machine kind it produces. No action left.

## Checks I ran here, and their results

- `node contrib/opus/tools/run_all_checks.js --fast`: no FAIL row. Under --fast every non-gating
  row over 120 s skips by design; the one gating row ran:
  `nem_assign_enum | PASS | 0.52 | PASS: all issue 120 enumeration checks`
- `python tools/recipe/contract_tables_selftest.py`:
  `PASS the hard point contract tables and standing gate behave` (exit 0)
- `python tools/recipe/contract_selftest.py`:
  `PASS the hard point contract is proved on the round 7 ship` (exit 0)
- Godot 4.7.2 headless (after `--headless --path godot --import`), the render/ headless checks
  from godot/tools/ci/godot_checks.txt:
  - `render/test/install_refresh_check.gd`: 8 ok lines, then
    `INSTALL REFRESH PASS (C:/Users/rcbai/AppData/Roaming/Godot/app_userdata/Voidsworn/install_refresh_check/1794555490)`
  - `render/test/turret_check.gd`: `TURRET_CHECK PASS: 0 failures`
- Blender 4.5.14 (the PC's copy), repair chain end to end on A16:
  - `sheet_contract_selftest.py`: 10 ok lines, `PASS the build sheet contract keeps the sheet's data`
  - sheet_hull build: `[209] {"cell": "A16", "hull_objects": 96, "parts": 306, "interiors": 24, ...}`
  - `audit.py`: `[audit] PASS`, crossing [], structure ["B1", "HB1", "HB2", "L0p", "VF2p", "VF2s"]
  - `audit_selftest.py`: 9 ok lines including
    `ok   machine_across: AN1 on the seam is refused` and
    `ok   structure_across: B1 on the seam is allowed (structure)`
  - `export7.py ... unbaked=1`: `[export7] C19_51 triangles 135428 hard points {...} turrets 8 (11436 triangles)`
  - `check_export.py ... unbaked=1`: `PASS C19_51 game export: ...` at the default 0.012 tolerance
  - `check_export_selftest.py ... unbaked=1`: 20 ok lines including
    `ok   bell_radius: the check failed as it must | hp_eng_0 is 0.0178 off the mesh (limit 0.0120) and is not the centre of an open engine bell: its rim at radius 0.1062 on the exit plane covers 0 of 12 sectors`
    `ok   bell_plane: the check failed as it must | hp_eng_0 is 0.0444 off the mesh (limit 0.0120) and is not the centre of an open engine bell: its rim at radius 0.0531 on the exit plane covers 0 of 12 sectors`
    then `PASS the export check fails when it should`
- env.bat on real cmd.exe (both probes under repair 1 above).
- Fixture staleness guard: the sha256 of the five files sheet_fixture_hash.py lists, recomputed at
  main, equals the stored record (`07a35124...`), so PR 596's edits did not stale the A16 death fixture.

## Skipped, and why

- `render/test/installed_ship_check.gd C19_51` (godot_checks.txt gpu line): needs the PC's built
  ship cache (godot/gen with C19_51 installed); this checkout has no gen/manifest.json. The same
  script's logic is exercised headless inside install_refresh_check.gd step 3, which passed.
- The gpu-tagged checks and the parity runs: the runner runs those itself after I stop.
- PowerShell 5.1 itself: nothing in the PR runs PowerShell except the pre-existing stamp line, so
  there was nothing new to execute.

## How the change reaches the rest of the game

- **Callers:** every new symbol's callers checked: `shape_ref_yaw` (sil_dump.py, bakeAb6.py; the
  22.0 left in bakeAb3/4/5 has no live caller), `contract.to_recipe` (sheet_hull.py,
  sheet_contract_selftest.py), `source_stamp` (build_assets.gd, installed_ship_check.gd),
  `ShipView.manifest_path` (the two install test scripts only), `bench209r3 length=` (6_lod.bat),
  `ship.py get length_world` (env.bat LEN), `--ships-only/--gen/--ships` (7_export.bat,
  install_refresh_check.gd). All consistent.
- **Saves:** no profile or run save fields touched; the ship cache the install refreshes is
  regenerated from files, not saved data. Checked by reading the diff (no save code in it).
- **Twins:** the diff touches no root JS (battle.js, data.js, core.js untouched), so no table
  re-export and no oracle copy run is owed.
- **UI:** no screen changes; ShipView gained only the test hook `manifest_path`, default unchanged.
- **CI:** both new Godot tests are registered in godot/tools/ci/godot_checks.txt (headless line 62
  runs in checks.yml through run_checks.sh; gpu line 79 is PC-only). The Python self-tests run
  inside the recipe stages on the PC by design (they need bpy or a real export);
  contract_tables_selftest.py reaches GitHub through contrib/opus/tools/hardpoint_contract_tests.js
  in run_all_checks.js. No new file was left unregistered.
