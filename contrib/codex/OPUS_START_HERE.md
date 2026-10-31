# Opus: start here

Prepared October 31, 2026 against main `17268efa081059a6923daa9e19e8b345a437714d`.
This page is a proposed integration order, not a new owner ruling.

**First repair the verification tools, then land small proved fixes. Keep the large
content and balance changes behind those checks.** The complete review is
`reviews/post_upload_closing_2026_10_31.md`; use its current claim ledger to
interpret failing tests.

## Ownership and parallel work

| Owner | Work | Completion evidence |
|---|---|---|
| Muse | Monte Carlo harness correction and affected price reruns | Immutable source/tool pins, exact seeds/configuration, constant starting prices across runs, corrected A2/A3/A4/A5 outputs, report/bible amendments. Preserve the original raw shard archive. |
| Muse | Canonical summary reconciliation | Remove the false missing-feed, oracle-boot-grant, lost-price and universal damcon-dominance conclusions; preserve the earlier boarding counterexample. Mark superseded measurements and completed tooling tasks. Correcting the copies in Codex does not update Muse's canonical documents. |
| Codex packet | Loader/gate/portability repairs, consolidated text and Nemesis corrections, shipwright candidate and validation evidence | Ready as proposed copies in this PR. Main and Muse's originals are unchanged. |
| Opus | Adopt selected repairs, mirror gameplay changes into Godot, integrate and playtest | One bounded change per commit with acceptance checks; explicit oracle updates when behavior changes. |

Muse owns the Monte Carlo replacement now. The Codex driver copy is a reference
repair, not a competing implementation to overwrite Muse's forthcoming work.
Do not rerun baseline/policy batches merely because a non-default price branch
was broken. First establish which archived configurations actually used it.

## Integration queue

| Order | Job | Ready material | Acceptance and stop condition |
|---|---|---|---|
| 1 | Make verification runnable from the committed layout | `proposed/contrib/muse/tools/findings_tests/`, shared harness copies and `tools/cutover_gate/` | All 80 assertions run; baseline is 8 PASS / 72 FAIL. Missing required checks outrank improvements. A disappeared tracked check is not a fix. Parity corpus remains NOT RUN, so the gate remains INCOMPLETE. Do not refresh the baseline to conceal missing checks. |
| 2 | Fix shipwright's second repair | `proposed/campaign_run.js`; `reviews/opus_ready_2026_10_31/shipwright_suite.txt` | TXT-2 flips to PASS, the other 79 assertion results stay unchanged: 9 PASS / 71 FAIL. The upgraded ship and repaired companion are distinct by uid when a companion exists. Six browser edge cases pass, including identical names, one/two ships, standalone outcomes and max Mark. Repeat their equivalents when porting. The combined Godot candidate includes job 3. Godot compilation, 30-seed campaign parity, 64 Nemesis records and 4,506 focused cross-engine vectors now pass. Matching narrow oracle changes are prepared. Reconcile and adopt a coherent set; repeat checks after integration. |
| 3 | Restore the elite-map guarantee | `proposed/core.js`; combined Godot candidate; `reviews/opus_ready_2026_10_31/elite_candidate.md` | Browser candidate repairs all 84 failures in 4,500 maps; 4,416 previously valid full maps and RNG states are identical; 1,920 battle setups pass. W3-1 is the only changed assertion in the elite-only run. The current field conversion excludes elites, so the red-team extra-guard premise is rejected. Scoped Godot compilation/runtime/parity now passes; see reviews/godot_validation_2026_10_31/README.md. Broader main drift is not cleared. |
| 4 | Enforce useful module fitting at mutation time | MOD-3 fixture, proposed Muse kind-fit guard, existing Codex ledger | Invalid fitting is refused by the action itself, not just hidden by UI. Preserve slot and ability gates; cover weapon kinds and shieldless hulls. Valid fits still work. Do not rename namespaced ids or redesign fitting costs in this bug fix. |
| 5 | Implement the ruled Nemesis learning behavior | Ruled-fixes spec, FR-2 and NEM-2 tests, telemetry addendum, corrected Nemesis lines | A lost meeting supplies honest debrief learning; adaptations cannot directly counter known weaknesses. FR-2 currently assumes exactly one reveal: identify that cap as the chair's recommendation, not a separately confirmed owner ruling. Preserve exhausted-weakness behavior and record what carries across loss/run boundaries. Port and oracle changes are part of the job. |
| 6 | Repair boon offer construction | RWD-8 and RWD-4 tests; ruled Q7/Q6 spec and correction notes | Backfill retains favour treatment. Legendary and duo compete by the ruled selection policy. Keep these independent from duo rarity labels: relabeling a fixed-value effect does not scale its power. Do not choose a new weighting merely to make a test green. |
| 7 | Apply corrected text in a scratch build first | Consolidated proposed text pack and Nemesis assembly | Use the four corrected source anchors. Syntax-check edits, run all assertions and data checks, then inspect affected UI. The earlier dry run covered 72 tests; it is historical evidence, not a fresh 80-test acceptance result. Keep proposal wordings distinguished from explicit corrections. |

Jobs 4-6 are implementation briefs with existing evidence. Jobs 2-3 have verified browser candidates and a combined Godot candidate whose scoped compilation/runtime/parity now passes. Matching oracle files are prepared with explicit pin exceptions. None is adopted into main.

## Things that must not become accidental jobs

- Build a new Chorus feeding system: existing kill-feed and bite healing are real.
- Delete damcon because price alone supposedly proves mathematical dominance.
- Add faction price multipliers a second time to already-derived exported costs.
- Remove a dormant oracle settings handler as though it executed at boot.
- Widen the event exit ruling beyond fight-start events without recording a decision.
- Install the drafted skill trees, new event pool or battleship entry as already validated content.
- Reopen accepted repair generosity using bot measurements alone.
- Declare the port ready because a baseline-tracking gate returns a known state.

## Safe adoption

Every path under `proposed/` mirrors its intended target after stripping
`contrib/codex/proposed/`. Apply only a selected job's changes against the current
target, rather than copying the entire folder. The copies are pinned to the source
above and may become stale after Muse or Opus changes main. In particular, the
whole `campaign_run.js` copy contains only the shipwright candidate; use its small
diff when combining it with text, Nemesis or other campaign work.

Keep the original baseline outputs. Expected-failing design assertions retain
their ledger dispositions until their premise is accepted. A changed count alone
is not sufficient evidence: compare test identities and preserve unrelated results.

## Deferred verification

Scoped headless Godot validation for jobs 2-3 is now complete. No Windows launcher, GPU, audio, complete content/lore, corrected large Monte Carlo, rendered gameplay or text-pack sign-off was performed here. Existing double-click
gate launcher is supplied as a proposed copy; no new terminal workflow for Ryan
is required. The raw Monte Carlo shards and phase 2 visuals remain Muse's deliberately
excluded artifacts, not files this PR claims to preserve.
