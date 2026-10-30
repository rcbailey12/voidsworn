# Telemetry spec gap-check, Qwen leg (wave 5, Oct 29, 2026)

Filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed; chat e0141ecf-20ed-461e-89e4-d65e514a99b4, "Telemetry Spec Gap Check"). En dashes and em dashes in the original are normalized to hyphens in this copy; wording is otherwise unchanged. Method notes and the chair screening live in the screening note, not in this file.

Verdict: SPEC COMPLETE

All three ruling questions (Q-A, Q-B, Q-C) and the boon-offer check are answerable from the events and fields as specified. No finding below blocks an answer; the items are join-clarity, redundancy, and scope observations.

Q-A - Regroup tension

Sufficient. regroup_open captures credits balance, every per-ship repair price, every upgrade offer price, and every ship-for-sale price. regroup_choice captures what was actually bought and the remaining balance. Joining the two lets an analyst compute whether the sum of the full menu exceeded the purse and, when it did, which category the player prioritised. The 0.0 %-of-60 000 sim result can be confirmed or contradicted directly.

One minor join note (Finding 1 below): regroup_open does not itself carry a sector/column/node-type tag, so confirming the regroup is post-boss requires joining backward to the immediately preceding battle_end (node kind = boss) or node_enter. In an append-only sequential log this is deterministic, but it is an implicit join the spec does not call out.

Q-B - Nemesis snowball

Sufficient. nemesis_meeting records adaptations count and weaknesses-known count at each meeting; battle_start (node kind = nemesis) records both fleets' hull ids, CP totals, and the player's fleetPower. Across meetings within one run (the meeting number this run field orders them), an analyst can plot Nemesis CP / adaptation count against player CP / fleetPower and compute relative growth rates. The anti-clash invariant is checked by nemesis_adaptation.clashed_with_revealed_weakness (expected always false; any true is a bug flag). The Q5 loss-reveal acceptance is confirmed by the existence of any weakness_revealed row whose source is "loss debrief."

One join note (Finding 2): nemesis_meeting carries no explicit node-id or battle-id linking it to the subsequent battle_start; the join is sequential + sector.

Q-C - Generational payoff

Sufficient. tree_pick records admiral, level reached, pick id, branch, and tier, so the first-ever pick and the capstone (identified by tier/branch) are directly locatable. Run number is derivable by counting run_start events in the append-only file (Finding 3 notes the fragility). xp_grant, level_up, boon_offer, relic_offer, and respec cover within-run and cross-run progression. Lost-run learning is visible through run_end and debrief_shown, which record lesson ids and the nothing-learned line.

Boon-offer coverage (Q7 play-data half)

Sufficient. boon_offer logs: offered ids, patron-match on/off per pick, rarity per pick, the picked id, and whether decline-for-credits was taken. An analyst can reconstruct the full offer slate, filter on-patron vs. off-patron, bucket by rarity, and measure pick/decline rates. No missing field identified.

Findings (7)

1. [NOTE] - INFERRED - regroup_open has no explicit trigger context (sector, node type, or "post-boss" flag). Confirming the regroup follows a boss requires joining backward to the preceding battle_end or node_enter. Deterministic in an append-only log, but the spec's Q-A paragraph ("at post-boss regroups") implies a filter the event itself does not carry.

2. [NOTE] - INFERRED - nemesis_meeting lacks a node-id or battle-id that would link it directly to the corresponding battle_start (node kind = nemesis). The analyst must join on sequence + sector. Adding a shared node-id to both events would make the join explicit and robust to any future out-of-order write.

3. [NOTE] - READ - run_start carries no cumulative run counter ("this is the player's Nth run"). Run number is derivable by counting run_start lines, which works while the JSONL file is intact but is silently reset if the file is ever cleared or a new file begins. The meta snapshot (renown, mastery levels) partially compensates but does not give an ordinal.

4. [NOTE] - READ - run_end includes "lessons named on the final debrief (count and ids), whether the nothing-learned line was shown," which debrief_shown already records with additional fields (core sync change, nemesis adaptation revealed). If the debrief only fires at run end, the run_end copy is redundant and risks double-counting in a naive script. If mid-run debriefs exist, the distinction should be stated.

5. [NOTE] - INFERRED - battle_start field fleetPower: the spec does not clarify whether this is a value the Godot build already computes and caches (e.g., for UI or AI) or whether it must be derived at emit time. If derived, the formula must be pinned to schema version v so that cross-session comparisons remain valid. Not impossible to emit, but the implementation path is ambiguous.

6. [NOTE] - READ - relic_offer is justified speculatively ("if players start wishing for one") rather than by Q-A, Q-B, or Q-C. It is a single lightweight event and harmless, but it sits outside the three stated ruling questions and the boon check.

7. [NOTE] - READ - shop_visit's parenthetical - "Also catches pricing anomalies like the capital-class fallback if one ever becomes purchasable" - names a diagnostic use beyond the three questions. Again lightweight and economy-adjacent, but worth acknowledging as scope creep relative to the spec's stated purpose.

No [BLOCKER] or [FIX] findings. No field was identified that the Godot build could not know at the described moment (Finding 5 is a clarity note, not an impossibility). No field duplicates another in a way that would corrupt analysis (Finding 4 is a redundancy, not a conflict). No data collected could identify a player beyond the anonymous random install id; there are no names, network calls, hardware fingerprints, or account references.

Not checked

- Whether the three design questions (Q-A, Q-B, Q-C) are well-formed or whether the rulings themselves are sound. The prompt restricts judgment to the spec's fitness for the questions as stated.
- Godot engine implementation details beyond emit-ability (e.g., whether user:// writes are atomic, whether the append-only assumption holds across OS-level file locking, the mechanics of the "copy telemetry" button).
- The browser build's Copy-report precedent and whether the telemetry export path reuses it correctly.
- The analysis scripts the chair will later write; only the data's theoretical sufficiency is assessed here.
- The JSONL schema-versioning policy ("additive only during playtest; rename to change meaning") beyond noting it exists and is stated.
- The save-file separation constraint ("keep the log out of the save file") against the actual importer/fuzz harness code.
- Volume and rotation: the spec states volume is trivial and no rotation is needed; I did not independently model line counts.
- Whether the random install id and per-launch session id provide sufficient entropy for the stated merge use case.
