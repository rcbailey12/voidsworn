# Preservation archive index (Oct 31, 2026)

Two bodies of Voidsworn work product were deliberately excluded from the GitHub pushes and are preserved here instead, so a workspace reset cannot lose them. The reports, syntheses, and aggregates derived from these artifacts are on GitHub main (repo rcbailey12/voidsworn, contrib/muse/); this archive holds the bulky primary material behind them.

## Location

~/workspace/archives/voidsworn_preservation_2026_10_31/ (durable home storage for this workspace; survives VM replacement). This index is also filed on GitHub at contrib/muse/reviews/preservation_archive_index_2026_10_31.md so the archive can be found from the repo.

## Contents

1. montecarlo_raw_shards_2026_10_31.tar.gz
   - What: the raw per-run simulation shards behind the Oct 30, 2026 Monte Carlo evidence, tuning grids, and policy sensitivity programs (the voidsworn-montecarlo/raw folder: grid shards, boon grid outputs, policy shards, logs).
   - Files: 100. Uncompressed: 308 MB. Compressed: 30 MB.
   - SHA-256: 8b0c2683e46ae424b3e6e324ed4b41f4e5c7122a06068331d5bb3d250edc9812
   - Why not on GitHub: per-run intermediates at a size the public repo should not carry; the derived reports, aggregates (aggregate.json, profiles_aggregate.json), and the harness itself are filed on main under contrib/muse/reviews/ and contrib/muse/tools/montecarlo/.
   - Caution: the price-grid shards in this archive were produced by the harness with the compounding bug (see canonical_corrections_2026_10_31.md section 5). They are preserved as the record of what was measured, not as valid price evidence. Corrected shards from the Oct 31 rerun live with that rerun's working folder and are named in price_grid_correction_2026_10_31.md.

2. wave5_phase2_visuals_2026_10_31.tar.gz
   - What: the complete wave 5 phase 2 visual deliverables from the Voidsworn graphics goal workspace (files/wave5_phase2): crest rounds v1 to v5 with rationale documents, nebula plates, material boards, the 12 relic icons, the 3 battleship silhouettes, the 4 HTML UI mockups, the playtest sign-off kit, and the effects performance budget.
   - Files: 153. Uncompressed: 27 MB. Compressed: 27 MB.
   - SHA-256: 9adcbe8bcfcf48ea46e4928ae3ac5248e47dbeec7abd78784cc565ee7baa2efd
   - Why archived: these are Opus's to mine or discard (crests were parked to Opus on Oct 30, 2026 after five feedback rounds). The goal workspace copy remains the working copy; this tarball is the reset-proof copy. The crest handoff note in the Opus readiness pass points here.


3. montecarlo_corrected_shards_2026_10_31.tar.gz and montecarlo_fix_workdir_2026_10_31.tar.gz
   - What: the corrected price-grid rerun of Oct 31, 2026: the fixed harness workdir (patched driver.js with the cost snapshot-and-restore, the probe script, the correction addendum source) and its corrected raw shards (raw/fix_*.json: chorus p80, chorus p80+cp, chorus cp control, eclipse p125, eclipse p125+cp; 1,504 runs total including probe and control).
   - SHA-256: shards 3e7b727716464cb43473fa1c379f8aeb5e76f54a6df88562d343a8f2be0fa906; workdir 01b26aee34459ccf7185ac16590faa5cd9a3ac8e76a87179ed1bc3c3aa67b71b.
   - The addendum itself is filed on GitHub at contrib/muse/reviews/price_grid_correction_2026_10_31.md and the patched driver at contrib/muse/tools/montecarlo/driver.js; these tarballs preserve the primary outputs behind it.

## Verification and restore

- Verify: cd into the archive folder and run: sha256sum -c SHA256SUMS.txt (both entries must report OK; verified at creation on Oct 31, 2026).
- Restore the shards: tar -xzf montecarlo_raw_shards_2026_10_31.tar.gz (recreates the raw/ folder).
- Restore the visuals: tar -xzf wave5_phase2_visuals_2026_10_31.tar.gz (recreates the wave5_phase2/ folder).

## Provenance

Created Oct 31, 2026 by Rey (Muse) on Ryan's instruction to preserve the excluded artifacts before resets. Sources: ~/workspace/voidsworn-montecarlo/raw and ~/workspace/goals/voidsworn-aaa-graphics-overhaul/files/wave5_phase2, archived byte-for-byte (tar of the live folders, counts taken before compression: 100 and 153 files).
