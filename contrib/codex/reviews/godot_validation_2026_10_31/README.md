# Godot validation: elite guarantee and shipwright repair

October 31, 2026. Source main: `17268efa081059a6923daa9e19e8b345a437714d`.

**Both prepared fixes now compile and pass their Godot behavior/parity checks.**
No further change to the proposed `campaign.gd` was needed. Main, the original
Godot files and the original oracle copies remain unchanged.

## Results

| Check | Original control | Candidate with both fixes |
|---|---|---|
| Godot compile, including campaign preloads | PASS | PASS |
| Existing campaign parity, seeds 1-30 | 30/30 match JS, 4,803 recorded steps | 30/30 match JS, 4,655 recorded steps |
| Existing Nemesis scenarios | 64/64 records match JS | 64/64 records match JS |
| Exact targeted map vectors | 4,500/4,500 match JS; 84 missing elites | 4,500/4,500 match JS; 0 missing elites |
| Targeted shipwright scenarios | 6/6 match JS; three reproduce the bug | 6/6 match JS; all six satisfy the repair contract |
| Previously valid map output/RNG | 4,416 valid maps | All 4,416 remain identical to the control |
| Campaign data checksum after re-export | Existing pinned tables | Unchanged; no generated-table replacement required |

The three failing control scenarios are three same-named ships, two ships and an
already max-Mark upgrade target. The single-ship, repair-only and upgrade-only
controls pass. The candidate fixes all three failures and retains the other cases.
Parity alone would have been insufficient: the unchanged port already matches the
buggy JS. These tests establish both exact JS/Godot agreement and the intended
repair contracts.

The candidate can legitimately change a campaign's path and number of recorded
steps when it repairs a map that previously lacked an elite. Each changed run
still matches its candidate JS oracle after every click. No records, comparison
tolerances or expected values were weakened to accept a divergence.

## What was executed

- Official Linux Godot **4.7.2.stable.official.ed1daf0bf**, matching the earlier
  campaign record's patch version. The downloaded archive SHA-256 was verified
  against the official release asset digest:
  `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.
- Node **v24.22.1**.
- Two isolated projects containing the repository's `project.godot`, campaign and
  battle-rule dependencies. No scene, audio, visual or export build is implied.
- The control uses the original `campaign.gd` and its existing campaign oracle.
  The candidate substitutes the proposed `campaign.gd` and applies only the exact
  elite and shipwright changes to that pinned oracle.
- Godot check-only compilation, the existing campaign parity scripts/comparator,
  existing Nemesis scenarios, and the new paired targeted vector scripts.
- Logs checked for script, parse and engine errors, and output counts/identities
  checked so an incomplete run cannot count as success.

Packaged text logs omit trailing empty lines only; reported results are otherwise retained.

The candidate campaign launcher transcript contains completed comparisons for
seeds 1-28. Its one engine run generated all 30 Godot files; seeds 29 and 30 were
then compared explicitly with the existing comparator, both exit 0, at 215 and
84 records respectively. Those results are preserved separately in
`candidate_parity_completion.log`. The summary counts these 28+2 verified
comparisons; it does not pretend the partial launcher transcript contains a
30-seed closing line. The original control launcher has its complete 30-seed log.

## Files and adoption

| File | Purpose |
|---|---|
| `summary.json` | Counts, targeted state records, runtime/source hashes and explicit completion scope. |
| `*_compile.log` | Original/candidate check-only compiler output. |
| `*_campaign_parity.log`, `candidate_parity_completion.log` | Existing campaign comparator results. |
| `*_godot_campaign.log` | The Godot engine's per-seed generation records. |
| `*_nemesis.log` | Existing 64-record Nemesis comparison result. |
| `*_vector_comparison.json` | Exact 4,506-vector comparison and expected contract results. |
| `*_vectors_gd.log` | Targeted engine run completion count. |
| `export.log` | Re-export output; the checksum is unchanged. |

Reproduction tools are in `contrib/codex/tools/godot_validation/`:
`fix_vectors.js`, `fix_vectors.gd` and `compare_vectors.js`. They run the actual
campaign functions, not a second implementation of the map/repair rules. The
vectors compare canonical full-state hashes and ending RNG states for maps, plus
uids, hull, Mark and maximum hull for shipwright cases. The comparator requires
exactly 4,500 unique seed/sector pairs and six unique repair cases. The complete
raw vector files are cheap to reproduce; their hashes are recorded in the summary.

The matching, narrow oracle proposals are now supplied under
`proposed/godot/campaign/test/oracle/`. Their README explicitly records the two
intentional exceptions to the existing campaign pin. This avoids a silent full
re-pin to root JS, which has unrelated differences. Adopt the selected browser
changes, matching Godot changes and matching oracle changes as one coherent set.
Do not overwrite newer work with these full-file copies; apply their small diffs.

The existing campaign table checksum does not move because these are function-only
changes. No battle-rule source, battle-rule oracle or generated data table is
modified by this packet. Existing Windows campaign parity launchers remain the
way to repeat the broad check on Ryan's PC after adoption; Windows execution was
not performed here.

## Reproduction outline for Opus

1. Copy the current Godot project into a temporary control checkout.
2. Make a candidate copy; substitute the proposed campaign script and the two
   proposed campaign oracle JS files. Keep its other pinned files and tables.
3. Run the existing `run_parity_campaign.sh 1 30` and `run_nem_scenarios.sh` with
   `GODOT` pointing at Godot 4.7.2. Check actual comparator identities and output
   counts, not just a process exit code.
4. Place `fix_vectors.gd` at `campaign/test/codex_fix_vectors.gd` in each temporary
   project. Run the Node generator with the temporary project path and output
   file, then the Godot generator headlessly with an output file and 1500 seeds.
5. Run `compare_vectors.js JS_OUTPUT GD_OUTPUT baseline` or `candidate`. Both
   modes demand exact cross-engine equality; only the control is expected to
   reproduce 84 elite-map failures and the three named shipwright failures.

## Not checked

Rendered gameplay, GPU performance, visual assets, audio, full application export,
Windows runtime, save migration after adoption, whole-main Godot parity, corrected
Monte Carlo balance or unrelated campaign defects. These results clear the prior
compilation/runtime/parity uncertainty for these two prepared changes only.
