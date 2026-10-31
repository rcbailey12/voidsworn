# Monte Carlo evidence: provenance (Oct 31, 2026)

Purpose: one page that states, for every Monte Carlo program on file, the exact source it ran against, the tool version, and where its seeds and configurations are recorded, so any figure in the evidence pack can be traced and reproduced. Filed with the corrected price-grid addendum (price_grid_correction_2026_10_31.md) and the corrections record (canonical_corrections_2026_10_31.md section 5).

## Source (identical for all programs)

- Game code pin: 264f441d43a54e3679950dcc4457133b40811807 (the shipped browser build state all audits since Oct 28, 2026 are pinned to; no root JS or Godot runtime files changed between the pin and main cc2d35fd, per the Oct 31 closing review).
- The harness loads the game files from the local clone at that pin state and drives the shipped campaign loop (newRun, genSector, the shipped reward, shop, and battle code) with a documented bot policy. The bot is an instrument, not a player model; all win rates are bot-relative.

## Tool (the harness)

- Filed on GitHub main at contrib/muse/tools/montecarlo/ in commit 8c7567d8 (Oct 31, 2026), except driver.js, which is corrected in the same batch as this document: the filed driver now includes the Oct 31 cost snapshot-and-restore fix. The pre-fix driver is preserved in commit 8c7567d8's tree and in the archived fix workdir (preservation_archive_index_2026_10_31.md).
- Harness files: loader.js / loader_main.js (game load), driver.js (campaign driver and per-run configuration), bot.js (battle policy), policies.js (campaign policies), shard.js (per-shard runner), aggregate.js / aggregate_profiles.js (aggregation), boongrid.js (boon offer sampling), gen_tables.js (report tables).

## Programs, seeds, and configurations

1. Baseline evidence (montecarlo_evidence_2026_10_30.md). 12,600 full campaign runs: six factions, Veteran (n = 1,800 per faction) and Standard, shipped prices and CP, paired seed bases recorded in each raw shard's meta block. Headline: 63.0 percent Veteran, 80.0 percent Standard (bot-relative). Raw shards: archived (montecarlo_raw_shards_2026_10_31.tar.gz).
2. Tuning grids (tuning_grids_2026_10_30.md). 300 runs per row, Veteran, one knob per row, seed bases in grid_shards.sh and in each shard's meta: grid (a) A1 seed0 22000, A2 20000, A3 21000, A4 23000, A5 24000; grid (b) healing rows by exact-once source replacement in the harness's in-memory copy (the loader throws if a pattern does not occur exactly once; shipped files never edited); grid (c) boon rows by direct offer sampling. Grid (a) price rows A2 to A5 are superseded by the correction rerun below.
3. Policy sensitivity (policy_sensitivity_2026_10_30.md). 26,400 runs: four campaign policies (baseline, rusher, economy turtle, Nemesis hunter) x six factions x 1,100 runs, Veteran, paired seed bases shared across policies so policy is the only difference, recorded per shard in its meta block. Raw shards: archived with program 1.
4. Correction rerun (price_grid_correction_2026_10_31.md). 1,504 runs: a 4-run fix probe (Eclipse x1.25, d_scythe cost constant at 125), the A1 control (300 runs, seed0 22000, reproduced the original shard bit-identically: 261/300 wins, same timeouts), and the four corrected price rows A2 (20000), A3 (21000), A4 (23000), A5 (24000) at the original n = 300, same factions, admiral rotation, difficulty, and bot policy as their original shards. Eclipse rows run under the harness faction id deathless. Corrected shards: raw/fix_chorus_p80.json, raw/fix_chorus_p80cp.json, raw/fix_chorus_cp.json, raw/fix_eclipse_p125.json, raw/fix_eclipse_p125cp.json in the fix workdir, archived Oct 31, 2026 (preservation index entries 3 and 4).

## Reproduction

- Baseline, policy, and grid figures aggregate from the archived raw shards with aggregate.js; the correction addendum's aggregation first reproduced all five original grid (a) rows' published figures from the original raw files before being applied to the corrected shards.
- Any figure in the Balance and Design Bible that traces to these programs carries its source in line; grid-dependent Bible text was rewritten Oct 31, 2026 from the corrected rows.
