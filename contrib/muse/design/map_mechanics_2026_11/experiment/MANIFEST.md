# Experiment manifest: map and mechanics package, Nov 17, 2026

Added after Artoo's review of the package at 35c61de8 (verdict GO WITH CONDITIONS, finding 4: not reproducible as landed). This folder freezes the experiment behind the docs: patch sets, run specs, and per-seed output rows for the sizing test, the feel test, the objective follow-ups, and the mechanics matrix.

## Provenance

The sim source files (data.js, core.js, battle.js, and the sim3d-derived measurement harness measure_map.js) were extracted from this repo for the issue 1004 job on Nov 17, 2026, and copied per test round. The code was measured at main db4885e1632f78ebed9fd54535c49e8678072da3 (Nov 17, 2026), as recorded in the issue 1004 design document's header. Correction: the first version of this manifest said the extraction SHA was not pinned; that was wrong, the chair checked the wrong job file. The tested copies may differ from current main where the game changed during Nov 17; treat the docs' numbers as measured on the tested copies, not on main.

## Contents

- mechanics/patch_mech.py: the full flag patch set for the mechanics matrix (21 gated patches to battle.js and measure_map.js; base behavior is untouched when the config global is unset). Applied to a copy of the 34x24 sim.
- mechanics/spec_*.json: run specifications (configs, fleets, seeds). mechanics/out_*.json: per-seed result rows, one object per battle. The medians in mechanics_results.md derive from out_matrixA.json and out_matrixB.json; the falloff matchup from out_asym2.json (out_asym.json is the discarded first attempt, kept for the record).
- sizing/patch_sites.py and sizing/<size>/: the plural-site prototype patch and the sizing run specs and rows for 30x22, 34x24, 38x26, 42x30.
- feel/<size>/: feel test specs and rows for 30x22, 34x24, 38x26.
- objectives/: the rent run (t34) and the pull-weight and majority-scoring diagnostic runs (t34w, t38w, t34m, t38m).
- sim_source/: the tested source itself, added after Artoo noted the referenced measure_map.js was not in the branch. data.js, core.js, battle.js and measure_map.js are the mechanics-matrix copy (all patch sets applied, exactly as run). measure_map_sites_feel_t34.js is the 34x24 harness at the earlier sizing and feel stage, before the mechanics patches. With these files plus the specs, the matrix, sizing and feel runs can be reconstructed without the chair's working folders.

## Battle count reconciliation (Artoo finding 4)

- Sizing test, 384 battles: 4 sizes x 12 seeds x 8 configs. The 8 configs are not the full grid: 3-relay hold ran under all five stat arms (base, speed x1.5, range x1.5, both, speed x2 + range x1.5); 1-relay hold ran under two (base, both); the rout reference ran at base only. A full 5-arm x 3-geometry grid would be 720; the reported 384 is the grid actually run, per sizing/<size>/spec_sites.json.
- Feel test, 180 battles: 3 sizes x 12 seeds x 5 configs (rout at base, 1.25 and 1.5; 3-relay hold at base and 1.25; no hold run at 1.5).
- Objective follow-ups, 72 battles: rent, pull-weight and majority arms at 34x24 and 38x26, 12 seeds each, against the 3-relay controls from the sizing run.
- Mechanics matrix, 384 battles: 16 configs x 24 seeds (out_matrixA 8 configs, out_matrixB 8 configs). Asymmetric falloff: 96 battles per attempt (4 configs x 24 seeds).

## Station clarification (Artoo code cross-check)

The defend station in both the tested copies and main is a 7-cell structure (centre plus ring at distance 1), with integrity pressure from enemy ships within 2 hexes of the centre. The package's phrase "19-hex station" was loose wording: 19 is the number of hexes inside that within-2 pressure footprint (1 + 6 + 12), not the station's structure. The defend timing results were measured on the same 7-cell construction Artoo found on main.

## Rerunning

With Node 22, in a sim copy with the relevant patch set applied: node measure_map.js <spec.json> <out.json>. Seeds are in each spec; battles are deterministic per seed and config.
