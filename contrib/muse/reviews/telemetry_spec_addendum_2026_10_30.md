# Telemetry spec addendum: the clash audit joins across run lineage (Oct 30, 2026)

Addendum to contrib/muse/reviews/telemetry_spec_2026_10_29.md. Chair-owned defect, found by the Argon engineer leg (finding 8 of its red team engineer report) and accepted by the chair on Oct 30, 2026. This document amends the spec; it does not rewrite it. Apply the changes in section 2 to the spec text. A runnable reference implementation of both the old and the amended audit sits at contrib/muse/tools/telemetry_reference/ and demonstrates the defect and the fix on synthetic data.

## 1. The defect

The spec's nemesis_adaptation bullet defines the Q4 clash audit like this: "The clash audit joins this event to the same run's earlier weakness_revealed events: the adaptation id names its category, and the revealed set at application time is exactly those earlier rows." The spec's amendments list restates the same join as adopted amendment 4 ("the revealed set is reconstructable from the same run's earlier weakness_revealed rows").

The same-run scope is wrong. Under the Q5 ruling (battle-layer Q5, Oct 29, 2026), a lost Nemesis meeting still teaches a weakness on the loss debrief, and that knowledge carries into later runs: the same Nemesis identity persists across runs, and the player's revealed-weakness knowledge for that Nemesis persists with it. A weakness revealed by a loss debrief in run 1 is part of the revealed set when that Nemesis adapts in run 2. The Q4 rule (an adaptation may not directly counter a revealed weakness) covers it. The same-run join cannot see it, because the weakness_revealed row sits in run 1, outside the join's scope. Result: the audit reports no clash where a real Q4 violation happened. A false negative on the one audit whose whole job is to prove the clash check held.

This is a defect in the audit definition, not in the events. Every row needed to catch the violation is already logged; the join was scoped too narrowly.

## 2. The amendment

### 2.1 One new field: nemesis_lineage

No field the spec currently emits carries lineage, and this addendum says so plainly rather than pretending otherwise:

- run is a per-run id; it changes every run by construction.
- run_number is an ordinal (which run this is on the install), not a grouping key.
- session is per launch.
- nemesis id is emitted on the Nemesis events, but the spec never defines its scope. It does not say the id is assigned once at a Nemesis's creation, nor that it is stable across the runs that Nemesis appears in. An audit key cannot rest on an undefined property.
- The random install id in the Shape section is described as a merge aid and is never assigned a field name in the envelope, so as specified it cannot serve as a join key either.

Minimal new field, additive under the spec's own versioning rule:

- nemesis_lineage: a string id generated once when a Nemesis is created, immutable for that Nemesis's whole life, and never reused. A successor Nemesis (new weaknesses, new identity) gets a fresh value. Emitted on exactly three events: nemesis_meeting, nemesis_adaptation, weakness_revealed. No other event gains a field.

The lineage key for analysis is nemesis_lineage on its own; generation makes it unique per Nemesis creation, so no install scoping is needed to keep lineages apart in merged files.

One conditional: if Opus can guarantee that the game's nemesis id is already unique per Nemesis creation and stable across runs, he may use nemesis id as the lineage key and skip the new field. The join semantics in 2.2 are unchanged either way. Absent that guarantee, the field is required.

### 2.2 The clash audit, redefined

Replace the join definition in the nemesis_adaptation bullet with:

"The clash audit joins this event to the lineage's earlier weakness_revealed events: every weakness_revealed row with the same nemesis_lineage and an earlier timestamp, across all runs, is in the revealed set at application time. The adaptation id names its category; the adaptation clashes if the weakness its category counters is in that set. The boolean logged on the event should be computed by the game against the same lineage-wide revealed set (the player's actual knowledge, inherited reveals included); the audit recomputes it independently from the weakness_revealed rows and does not trust the logged value."

Timestamp order is the ordering because the log is append-only and a lineage spans sessions and runs; run boundaries and session boundaries are not ordering barriers. Rows at the same timestamp as the adaptation are not "earlier" and stay out of the set, matching the original same-run reading.

### 2.3 nemesis_meeting: weaknesses known count is lineage-cumulative

The meeting bullet's "weaknesses known count" had no stated scope. It is now defined as the player's total knowledge for that lineage at meeting start, including weaknesses revealed in earlier runs (a loss-debrief reveal from run 1 counts at a run 2 meeting). This is the only reading consistent with Q-B, which tracks knowledge and adaptations across meetings and runs.

### 2.4 Amendment 4 of the spec is superseded

Amendment 4 in the spec's amendments list recorded the same-run join as an adopted clarification (source: DeepSeek finding 4). That clarification is the defect. This addendum supersedes it: where the spec text and this addendum disagree about the clash audit's scope, this addendum governs. The rest of amendment 4's intent (the revealed set is reconstructable from logged rows, no duplicated inputs on every event) still holds; the reconstruction is just lineage-scoped now.

### 2.5 Schema version

Adding nemesis_lineage is an additive field addition, which the spec's versioning rule permits. The Godot telemetry this spec describes is not yet implemented, so the expected path is to fold the field in before first implementation and keep v at 1. If any v=1 logs exist by the time this lands, bump v to 2 instead, and note that v=1 logs cannot run the lineage audit at all (no lineage key was recorded), which is itself one more reason the field had to be added before play data exists.

## 3. What does not change

- The envelope: v, ts, session, run, run_number, and the event name ride on every event exactly as specified. nemesis_lineage is an event field on three events, not an envelope field.
- Every event name, and every other event's field list, is untouched. The Q-A regroup join (regroup_open to regroup_choice) and all Q-C progression reads are unaffected; neither involves Nemesis knowledge.
- weakness_revealed keeps its fields and its source enum (win, loss debrief, intel event, triggered in battle). Its rows now carry nemesis_lineage, nothing more.
- The logged clash boolean on nemesis_adaptation is still emitted. Only the set it is computed against, and the audit's reconstruction of that set, change scope.
- The one-Nemesis-per-run design statement stands. Lineage is about the same Nemesis across runs, not several within one.
- File shape (local JSONL under user://), the no-identifiers stance, and the not-in-scope list are all unchanged.

## 4. Reference implementation and demonstration

contrib/muse/tools/telemetry_reference/ contains a dependency-free Node reference: a logger emitting spec-shaped envelopes with nemesis_lineage, a synthetic two-run dataset, and both audit queries. The dataset is built to the defect's shape: run 1 loses a Nemesis meeting and the loss debrief reveals a weakness; run 2's Nemesis (same lineage) applies two adaptations, one countering the inherited weakness (a true Q4 violation) and one countering a weakness never revealed (clean).

Results on that data (reproduce with: node run_demo.js, from the telemetry_reference folder):

- Old same-run join: adaptation 1 (counters the inherited weakness), no clash found. False negative, the violation is missed. Adaptation 2 (clean), no clash. Correct.
- New lineage join: adaptation 1, clash found. The violation is caught. Adaptation 2, no clash. No false positive.

## 5. Inconsistencies the lineage change exposed

1. The adopted-amendments list itself carried the defect: amendment 4 states the same-run join as settled clarification, so the merged spec's own record of gap-check fixes had frozen the wrong scope in place. Handled in 2.4.
2. nemesis_meeting's weaknesses known count was scope-ambiguous (per-run or cumulative) until 2.3. Under the old silent reading, a run 2 meeting could log a known count that excludes run 1's loss-debrief reveal while the Q-B analysis treats that reveal as known, so meeting rows and reveal rows could disagree without either being wrong on its own terms.
3. The spec's hedge on nemesis id ("There is exactly one Nemesis per run in the current design; the id is logged anyway so merged analysis never has to assume it") quietly assumed the id was a safe analysis key while never defining it as one. The lineage field removes the assumption instead of leaning on it.
