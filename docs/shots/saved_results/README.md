# Saved-results review pilot

Issue 990. Source base `2efb76f845abe675db5c26cc9d996a3825775cb6`, plus this
job's test tools. Godot 4.7.2, Node 22.11.0, Ryan's Windows PC, November 17, 2026.
No production rule was changed. All fault and historical copies ran under TEMP.

**Recommendation: worth it only for some changes as a required detailed review.**
Keep the automatic saved-results gate on every run beside parity. Require the
short report to be judged when rules or data change play, or battles change
without explanation. Group pure stored-field changes under one explanation.
The pilot suggests one review round for a simple value and two for a boundary,
geometry or weapon change. An unchanged report adds no review round. This is a
recommendation from a small pilot, not a new standing rule.

## Main pilot cases

Both faults pass browser parity on every changed battle and fail the saved
Godot-results gate. The checker names each changed battle and preserves its
first turn, unit, field and values, plus the count of later changed records.

| Case | Battles checked | Battles changed | Report length | Estimated review cost | Bug caught? |
|---|---:|---:|---|---|---|
| [F2](f2.txt): Eclipse flare base hull 100 to 90, both tables re-exported | 281 | 44 | 179 lines, 8,074 bytes | 1 review round | Yes. The first changed field is the flare's hull at turn 0 in every case, contradicting R265. |
| [F5](f5.txt): Long Focus applies at exactly half range in both twins | 281 | 3 | 15 lines, 738 bytes | 2 review rounds | Yes. The report exposes increased damage; the second round checks the range boundary against the rule. |
| [PR 442](pr442.txt): preserve defining terrain and place reinforcements on their own side | 271 | 5 | 23 lines, 1,057 bytes | 2 review rounds | Yes for a regression. It flags the exact terrain and placement symptoms, which still need checking against the geometry rule. |
| [PR 797](pr797.txt): Eclipse flare hull, weapons and Silent Archive memo fix | 280 | 44, plus one threat map | 181 lines, 8,193 bytes | 2 review rounds | Yes for an accidental regression. It reveals the hull and battle changes; the source and weapon state still establish the intended values. |

The brief's 42 for F2 counts scenarios that explicitly name `d_jackal`. The
complete run also catches `s9` and `s39`, whose generated Eclipse fleets include
that hull. All 44 still pass browser parity. Several hull values are scaled by
the scenario, so the report includes 77 to 69 and 120 to 108 as well as 100 to 90.
The scenario file is unchanged between the review's `7d4db9de` and this base.
The existing ruled-number safety net also catches F2; this is useful overlap.

F5 changes precisely `t_recordedangle`, `t_burnflaw`, and `t_flawforever`.
The first field is cumulative damage dealt, not a direct statement about range.
Inspecting those first-difference snapshots gives:

| Battle | First turn | First damage dealt change | Firing distance | Weapon range |
|---|---:|---|---:|---:|
| t_recordedangle | 47, round 3 | x04, 80 to 86 | 3 | 6 |
| t_burnflaw | 31, round 2 | x06, 30 to 33 | 2 | 4 |
| t_flawforever | 45, round 3 | x05, 81 to 87 | 3 | 6 |

Each is exactly half range. The rule requires farther than half range, so those
extra points are wrong. This is the valuable case: both twins agree and the
saved report still directs the reviewer to a real boundary bug.

Review rounds here are estimates from inspecting the actual reports and rule
context, not a timed study of independent reviewers. One round means read the
report and compare its first changes with the requested rule. A second round
means inspect the source and saved state to settle an unclear cause. Later
differences are counts of changed records at matching turn indexes; they are
not counts of independent bugs or an instruction to review every later action.

## Historical battlefield fix

[PR 442](https://github.com/rcbailey12/voidsworn/pull/442), merged as
`5120c90325f48943f0d132746412abe6b30d7389`, was compared with its real parent
`f770d56c4c2813db17139bfd79424a60d372af57`. Both runs completed their entire
271-battle suite. The changed battles are s9, s17, s25, s35 and s38.

The report first shows a clearing count of 3 to 0 in s17. Inspecting the states
confirms that the ring's rocks at 10,10; 9,10; and 9,11 survive after the fix.
The four other first differences are enemy ship coordinates, at setup or when
reinforcements arrive. The source diff explains why: edge placement follows
the fleet's bearing on angled arenas instead of assuming left and right edges.
This is a useful two-round review: the short report locates the effects, then
the saved state and rule settle whether the effects are intended. A stored
post-fix baseline catches reintroducing these real bugs even if both twins
are changed together. The report alone does not prove a new placement is valid.

## Historical hull and weapon change

[PR 797](https://github.com/rcbailey12/voidsworn/pull/797), merged as
`67b1894912560ccb0eac1ae7d5199713fbafb808`, is compared with its real parent
`1b9aa298a47ac4e3904c05efcb56dd6556503280`. It makes the Eclipse flare a
glass cannon and fixes the Godot hit-chance memo's facing key under Silent
Archive. Both arms run all 280 merged fixtures with identical inputs, including
the eight fixture seeds that the PR itself changed.

This case changes actual play. In s28 the flare goes from 110 hull and two
gauss weapons (range 5, three shots of 6 each) to 100 hull and one null lance
(range 6, three shots of 15). Actions, random state or damage diverge by record
15. The battle ends in a loss in both versions, but lasts 8 versus 11 rounds
and writes 285 versus 317 records. Keeping only the final win/loss would miss
these differences. The short first-field report still needs the rule diff
and weapon snapshot to judge the whole change; it cannot approve every weapon
number by itself.

Its report flags 44 battles and the s19 threat map. The first field is hull,
so the weapon change needs that second inspection round. This is why reading
the first field cannot replace reviewing the rules diff or balance evidence.

## Extra control: a changed record without changed play

[PR 449](https://github.com/rcbailey12/voidsworn/pull/449), protocol tuning,
compares `3e0e015d8c50b6920beeb73514bb56151f7e5d41` with its parent
`2f816d0bfc7e94a0595e0d073ba869de49bb20a5`. Its [report](pr449.txt) flags two
of 271 battles in 11 lines, 577 bytes. This is an extra control, not one of the
two meaningful historical changes required by this pilot.

Review cost: two rounds. The first field in s9 is an added `spareWings: 0`;
all 306 records are otherwise identical after removing just that unused zero.
In s10, only the stored `torpCd` and `torpPct` effect values differ. Normalizing
those two fields makes all 190 state records, actors and random states identical.
These particular battles do not demonstrate the changed protocols affecting
play. The report correctly detects exact record changes but is not evidence
that a real combat bug was caught. The existing balance work is still needed.

This is real review noise: the later-difference counts are 305 and 189, yet they
all repeat stored fields. A reviewer must judge one cause rather than treat
each differing record as a new gameplay change. The two main historical cases
are PR 442 and PR 797, which do change play.

## Reproduction and evidence

`pilot.json` gives the exact source revisions, battle counts, report lengths,
comparison times and the full lists of changed battles that also pass parity.
`godot/rules/test/saved/pilot.js` reproduces both faults and the historical pairs
without touching this checkout's rule files. Historical pairs use the real
parent and merged commit, with the merged PR's suite held identical in both arms. Only
batch start/result print lines are added to old harnesses, since the completion
guard needs them; rules, bot, scenario setup and snapshot writing are unchanged.

PR 797 reseeded eight fixtures as part of its change. Both historical arms use
those merged seeds, so the pilot measures the rule changes. This changes only
the before arm's scenario inputs, not its rules, data, bot or snapshot writer.

The saved results themselves are in `godot/rules/test/saved`: a plain manifest
and compressed exact Godot records, 5,277,069 bytes at the initial baseline.
The gate shares parity's Godot batches, writes a short report in the run folder,
and the explicit updater carries that report as the PR's tracked `changes.txt`.
The PC launcher is `tools/pc/saved_results.bat`. The existing CI parity step
enforces the new gate and prints both comparison and whole-step time in the
GitHub step summary. No parity coverage or parity comparison was removed.

## Validation and PC time

The final real double-click launcher path, invoked with `nopause`, passed all
281 parity comparisons and all saved results, including the PRNG draws, math,
three threat maps, threads and hard stop. It discovered the bundled tools with
no `GODOT` override and returned exit 0. The whole rules step took **555.145 s**;
the saved comparison within it took **19.304 s**. The earlier bootstrap parity
run took 476.920 s, followed by an 18.405 s saved comparison. CPU load was shared
with pilot work, so these are observed run times, not a speed comparison.
[PC evidence](pc_check.txt) and [machine-readable timings](timings.json) preserve
the results without machine paths.

The full `node contrib/opus/tools/run_all_checks.js` passed: 63 PASS, two accepted
KNOWN rows, zero FAIL and zero SKIP, exit 0. The accepted rows remain seven known
findings and twelve known oracle constant differences. The new saved-results
self-test passes 21 cases, including missing/truncated/damaged records, unfinished
batches, wrong state hashes, random-stream changes, new/removed battles, failed
math, partial/failed updates, CI summary writing and deterministic updates that
preserve the review report. A separate Windows launcher fixture returns 0 on
success and preserves failure exit 17.
An explicit update from the completed full PC run was also byte-identical to
the initial manifest and preserved its existing review report.

CI has not run this uncommitted job: commits, pushes and workflow edits are
forbidden here. The existing parity command already invokes this gate, and
whole-step and comparison time will appear in its CI log and step summary.
The saved README gives the exact optional artifact-upload step for the Board;
no workflow edit is needed to enforce the gate. No GPU capture or frame-time
measurement was needed for this file and rules-test job.
