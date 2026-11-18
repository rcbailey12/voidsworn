# Outside check: PR 980 (R312 Path D, RULEBOOK 3.1 rewrite)

Refs #256. PR 980 head b1f633e2, checked Nov 18, 2026. Council: blind Rey (chair, own verification below), DeepSeek, Flash, and a Qwen seat that returned an unattributed A/B pair (see method note). Grok seat not run for this batch (parked, bot wall).

## Verdict: GO WITH CONDITIONS

The brief's central worry is clean: no skip rule and no coverage reduction crept in. The new 3.1 says parity is "never skipped and never cut (no skip rule)", retirement stays gated on verification plus "a separate recommendation to Ryan", and the ten-item mark is "a progress checkpoint, not approval to retire parity". Every standing commitment in R312 is present, and the ruling's work instructions are correctly parked in the FINDINGS row and issues 978 and 979 rather than the rulebook. The conditions are editorial fidelity items, all cheap.

## What the chair verified directly (OBSERVED)

1. Clause map: the chair compared R312's text (read from FINDINGS at the PR head) against the new 3.1 line by line before the legs ran. Every standing clause has a counterpart; the absences (equivalence and planted-failure checks, PC workflow and timing preservation, whole-check time reporting) are work instructions, and the R312 row added by this same PR carries them in its consequence column (issue 978: byte-identical proof, planted faults, parity.bat kept, timing shown; issue 979; the pilot). DeepSeek's condition 6 is discharged by that read.
2. "on every push" (flagged by DeepSeek and the Qwen pair as an addition beyond the ruling): verified accurate in practice. checks.yml runs on every push to the agent branch families, one run per push since issue 359, and Godot rules parity is one of its jobs. The phrase adds cadence the ruling did not state, but it describes the standing trigger and hardens, not softens, the coverage promise. Not a blocker; noted so the Board knows it is an addition.
3. CI on head b1f633e2: Standing checks success (the suite that runs the doc and memory lint tests the PR body cites), Godot rules parity success, Godot game checks success. Flash's condition on the doc tests is discharged.
4. Leftover wording: AGENTS.md at head has no "frozen" left. RULEBOOK 5.12 still says ".vsm belongs to the frozen browser game", a different sense (ship-asset pipeline), not the rules-oracle claim; flagged under notes so a future reader is not confused.

## Conditions (council consensus; DeepSeek and both Qwen responses, Flash concurring on 4 and 5)

1. "Ten rules PRs" should be Ryan's unit, "ten rules changes". A PR can bundle several rules changes or one change can span PRs, so the checkpoint count moves. It is a checkpoint, not a gate, which is why this is a condition and not a block.
2. The retirement gate narrows Ryan's words: "the ported tests and the PC tools" replaces "relevant tests and tools". "Ported" swaps a relevance test for a provenance test (it can exclude a newly written Godot test that was never a port, and can be read to require porting everything). The entry's own Why quote reproduces "relevant tests and tools" verbatim, so the body currently contradicts its citation. Restore the ruling's words; "a Godot balance simulator" and "replacement data home" are harmless clarifications and can stay.
3. The pilot clause drops Ryan's qualifier "with meaningful differences". Without it, a pilot run over no-op battles could report a falsely cheap review burden, which is the number Ryan asked to see. Restore the qualifier in 3.1 or pin it in issue 979's spec.
4. "The browser game and pages ship nothing" has no source in R312 or the old 3.1. It is the one piece of new content beyond the ruling. Confirm it as a factual description, soften it to intent, or take it out of this PR.
5. "Every new rule since went into both copies" is attributed in the text to the round 2 review (Nov 17) and is the stated basis for calling the old "frozen" wording wrong. This check did not re-audit git history; recorded as attributed, NOT independently verified here.

## Notes

- "not approval" for the ruling's "not automatic approval" is a slight tightening in the owner's favour; restoring "automatic" costs nothing and keeps the quote exact (DeepSeek, Qwen pair).
- AGENTS.md's new line is consistent with 3.1 and the ruling. The Qwen pair suggested adding the no-skip clause to AGENTS.md as well; optional, the rulebook carries it.

## Method note

The Qwen seat for this check returned an A/B comparison in which neither response was identified as Qwen3.8-Max, so neither can be credited to the gated model. Both responses are recorded in the chair's working files; both returned GO WITH CONDITIONS with conditions convergent with DeepSeek's, and nothing in this verdict rests on that seat alone. Legs ran under their standing gates (DeepSeek DeepThink on and Search off, Flash-Lite picker signed in), verified before and after. Pack carried R312 verbatim, the old and new 3.1 texts, the AGENTS.md change, and the chair's notes separating work instructions from standing rules.
