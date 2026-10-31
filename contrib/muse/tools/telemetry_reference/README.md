# Telemetry reference implementation: the clash-audit lineage join

Reference code for the Voidsworn Godot telemetry spec
(contrib/muse/reviews/telemetry_spec_2026_10_29.md) and its Oct 30, 2026
addendum (contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md).
Node, no dependencies. This is a demonstration artifact, not game code: it
exists so the spec defect and its fix are executable and checkable instead
of prose.

## The defect in one paragraph

The spec's Q4 clash audit (does a Nemesis adaptation directly counter a
revealed weakness, which the Q4 rule forbids) joins each nemesis_adaptation
event to the same run's earlier weakness_revealed events. But weakness
knowledge persists across runs: under Q5, a lost meeting's loss debrief
reveals a weakness, and that reveal is part of the player's knowledge when
the same Nemesis adapts in the next run. The same-run join cannot see a
prior run's reveal, so it reports no clash where a real violation happened:
a false negative. The addendum fixes the audit by joining across the
Nemesis lineage instead, keyed on one new field, nemesis_lineage.

## Run it

    node run_demo.js

from this folder. It builds the synthetic dataset, writes dataset.jsonl,
runs both audits, prints a per-adaptation verdict table scored against
ground truth, and exits 0 only if the pattern matches: old join misses the
violation, new join catches it, neither raises a false positive.

## What is in here

- logger.js: a reference logger emitting spec-shaped envelopes (v, ts,
  session, run, run_number, event) plus event fields. Its emitNemesis
  helper stamps nemesis_lineage on the three Nemesis events and throws if
  it is missing. Note: the spec says every event carries the event name
  without naming the key; the logger uses "event". Timestamps are
  deterministic increments so the dataset is reproducible; a real build
  stamps unix seconds, and only ordering matters to the audits.
- dataset.js: the synthetic two-run dataset and its ground truth. Run 1
  loses a Nemesis meeting; the loss debrief reveals weak_rear_arc. Run 2
  (same lineage, new run, new session) applies adapt_rear_screen, which
  counters that inherited weakness (a true Q4 violation), and
  adapt_ion_plating, which counters a weakness never revealed (clean).
  ADAPTATION_COUNTERS pins which weakness each adaptation counters; in real
  analysis that relation comes from game data, since the adaptation id
  names its category.
- audit.js: both audits. oldJoinAudit scopes the revealed set to the same
  run id, as the filed spec does. newJoinAudit scopes it to the same
  nemesis_lineage with an earlier timestamp, across all runs, per the
  addendum. Both recompute the clash from weakness_revealed rows and ignore
  the boolean logged on the adaptation event.
- dataset.jsonl: the generated dataset, regenerated on every demo run, kept
  here so the data can be eyeballed without running anything.

## What it proves, and what it does not

It proves the scoping defect is real and the lineage join removes it, on
data shaped exactly like the failure case: the only difference between the
two audits is the join scope, and flipping that one scope flips the verdict
on the violation from missed to caught while the clean adaptation stays
clean under both.

It does not prove anything about the game's runtime clash check itself.
The logged clashed booleans in the synthetic data are false for both
adaptations by construction, to model the audit's job as independent
recomputation; whether the shipped Q4 check uses lineage-wide knowledge at
runtime is a game-code question for Opus, and addendum section 2.2 states
that it should.
