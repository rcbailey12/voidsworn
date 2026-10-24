# Screening: Packs F, H, I (DeepSeek returns)

Screener: Rey (Muse), Oct 23, 2026. Attribution confirmed by Ryan: the first F/H/I returns are DeepSeek's. Method: every decisive claim spot-checked with grep against the local clone at HEAD (51337c2 lineage); quotes compared character for character where quoted. Filing the model's file does not verify it; this doc records what the spot-checks found. Code truth remains Opus's to confirm.

## Pack F (save-integrity sweep): clean, zero errors in sample

Every decisive dereference and line number checked out exactly: derive (core.js:164), makeUnit (battle.js:97), modName and relicName (core.js:190-191), the unguarded RARITY index (core.js:136, campaign_run.js:22), giftBoon and PATRONS (campaign_meta.js:98-99), FACTIONS (campaign_run.js:27; battle.js:133, 341), ADMIRALS (campaign_run.js:60; campaign_meta.js:196), PERKS (campaign_run.js:102, 130), RELICS (campaign_run.js:46), NODE_INFO and SHAPES (campaign_run.js:39, 55), saved stock hulls (campaign_run.js:150, 174). The validation-layer finding is exact: saneRun checks fleet array plus map.cols and nothing else, and the cloud-merge quotes at core.js:98 and 104 match.

Assessment: this is the exhaustive enumeration of the save-brick class the three councils already converged on, plus rows the councils never listed (boon rarity index, giftBoon, META.stats.wonFacs, saved stock hulls and mods, NODE_INFO/SHAPES). It converts chair item 1 from a class into a checklist. Treat the table as the work list for the fix, subject to Opus's confirmation.

## Pack H (repairs rematch): verdict MIXED, accepted; one citation slip

Route claims all exact: COLS=7 (core.js:207), drydocks converted out of columns 1-4 (core.js:228), the c5 rest guarantee (core.js:215, 225), the guaranteed c3 shipyard (core.js:224), the offered-not-forced c4 elite (core.js:222). Repair sizes all exact: drydock 60% of missing (campaign_run.js:185), field 20% (campaign3d.js:41), node reward 25% (campaign_run.js:245), win patch 15% (campaign3d.js:80), sector transition 40% (campaign_run.js:313). Income formula and repair price verified (campaign_run.js:237, 164). The break-even arithmetic (fleet max hull ~252 / ~255 / ~390 for S1/S2/S3 elites) was recomputed from the annex rows and holds.

Citation slip: Finding 6 cites the elite/boss boon line as campaign_run.js:153; the line is core.js:153. Content quoted correctly; conclusion unaffected. The filed copy carries a parenthetical correction.

Assessment: this settles the D-round repairs contest. DeepSeek's earlier "squeezed" and Qwen's earlier "coddled" were both artefacts of pricing repairs without the route. With the route modelled, the answer is conditional: paying is correct only in the c3 window before a deliberate elite (or at a shipyard-only c5), and a trap at a free c5 and after a boss. See the round-2 screening for Qwen's H, which adds a verified heat/condition branch to this verdict.

## Pack I (enemy AI): strong; one citation slip

Spot-checks all verified: aiObjScore veteran gates on intercept and hold (battle.js:747-748), hunt flagship saturating at 9 hexes (battle.js:740), FACTION_AI consumption (battle.js:1114-1116), sector stat scaling (battle.js:310) and budget (battle.js:133), the 35% CP auto-rout and its guard (battle.js:784-786), the Intercept escape branch setting a win (battle.js:778, with o.need at battle.js:722), boarding's three gates (battle.js:653, 685, 675), flak excluded from offensive fire (battle.js:456, 1047), player-only Commands and the cancellable boss Command (battle.js:846, 868), the boss encounter pool and column-0 rout (battle.js:68-69), terrain fallback to open (battle.js:302-303), the unused dead-star assist (battle.js:273 vs 277), escorts breaking at 50% boss hull (battle.js:349), the two per-faction code branches (battle.js:912, 318), and SECTOR_CONDS.war defined at data.js:372 with no reader found in the pack files.

Citation slip: Finding 2 places FACTION_AI at data.js:985-991; the table is at battle.js:985-991 (values quoted exactly; data.js is 448 lines, so the cite could never have resolved).

Assessment: convergence where expected (faction doctrine lives in data, difficulty is stat scaling, Intercept re-derives the council QA item already verified still open, now with the mechanism: need = total - 1 makes the escape branch reachable). Genuinely new and worth Opus's attention: (a) the 35% CP auto-rout bypasses Hold, Break and Relay outright, since checkEndRules excludes only intercept and hunt; (b) boarding is structurally near-impossible for the AI (post-move adjacency, 70% floor, no movement-score term), not merely rare; (c) the objective pull is straight-line hdist while pathField is computed only for foes, so terrain walls break objective play on dense maps.

## Net for the chair

1. F turns the save-brick class into an 87-row fix list. Highest value of the three.
2. H closes the repairs contest: MIXED, conditions in the filed report.
3. I's items (a) and (b) are new design-level findings, not balance noise.
4. Reliability note: DeepSeek's citation accuracy across F/H/I was two wrong-file slips in roughly 140 cited lines, both with correct line numbers and verbatim content. That is a materially better citation profile than its council transcripts suggested.
