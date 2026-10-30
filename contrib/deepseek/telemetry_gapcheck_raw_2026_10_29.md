# Telemetry spec gap-check, DeepSeek leg (wave 5, Oct 29, 2026)

Filed verbatim from the DeepSeek run of Oct 29, 2026 (DeepThink and Search verified ON; chat "Telemetry spec gap check"). Em dashes and en dashes in the original are normalized to hyphens in this copy; wording is otherwise unchanged. Method notes and the chair screening live in the screening note, not in this file.

SPEC HAS GAPS

Q-A - regroup tension: The regroup_open fields are sufficient to compute full-menu affordability at the moment the regroup opens: credits, per-ship missing HP, per-ship repair quote, upgrade ids/prices, ship ids/prices. regroup_choice gives balance after and what was bought. The gap is repair granularity: if repairs can be partial, "repairs per ship" does not state HP repaired or credits paid per ship, so actual allocation cannot be reconstructed. If repairs are all-or-nothing, Q-A is answerable from the spec.

Q-B - Nemesis snowball: The spec captures meeting number, adaptation count, adaptation ids, weakness reveal source, battle fleets, and battle results. It does not capture a comparable enemy power metric: battle_start gives player fleetPower but enemy only faction/hull ids/CP total. Growth comparison is therefore a CP/hull proxy unless CP is accepted as the power metric. Also, nemesis_adaptation and weakness_revealed lack nemesis id/meeting number, so attribution depends on one-nemesis-per-run and timestamp ordering. The anti-clash check is logged as a precomputed boolean, not as adaptation target plus revealed weakness ids at application time.

Q-C - generational payoff: Not sufficient at the required run-number granularity. run_start has a meta snapshot but no run number/generation ordinal; run is an id, not an ordinal. tree_pick can show pick id/branch/tier within a run, but merged logs cannot place the first pick or capstone at run 5 or run 14-15 without an explicit run number. Add run_number to run_start and ideally to tree_pick / run_end.

Boon coverage: Sufficient to reconstruct offered ids, patron match on/off, rarity, picked id, and whether decline-for-credits was taken. It does not record the credit amount for decline-for-credits, so it cannot by itself assess the "real value" of an off-patron decline; offer/pick reconstruction is covered.

Findings

1. [BLOCKER] READ - Q-C lacks a run ordinal. run_start and tree_pick do not record run number/generation count; run is an id. The first tree pick and capstone cannot be placed against run 5 / run 14-15 predictions from merged logs.
2. [FIX] READ - Q-B lacks a comparable enemy power field. battle_start logs player fleetPower but enemy only faction, hull ids, and CP total; add enemy fleetPower or a Nemesis power snapshot at each meeting if CP is not the intended metric.
3. [FIX] READ - Q-B attribution is weak. nemesis_adaptation and weakness_revealed do not carry nemesis id or meeting number; add them, or state that exactly one Nemesis exists per run and timestamp ordering is authoritative.
4. [FIX] READ - Q-B anti-clash is only a boolean. nemesis_adaptation logs "whether it clashed" but not the adaptation target/category and the revealed weakness ids at application time.
5. [FIX] READ - Q-A repair choice granularity is ambiguous. regroup_choice says "repairs per ship" but not HP repaired or credits paid per ship; if partial repair exists, this blocks exact allocation reconstruction.
6. [NOTE] READ - Boon decline value is incomplete. boon_offer records decline-for-credits taken or not, but not the credit amount; offered/patron/rarity/picked/declined reconstruction is otherwise covered.
7. [NOTE] READ - nemesis_meeting weakness and adaptation counts can be derived from weakness_revealed and nemesis_adaptation, but the meeting-start snapshot is useful because reveals/adaptations can occur mid-meeting. Not a real duplicate problem.
8. [NOTE] READ - relic_offer and shop_visit / purchase exceed the three named questions, but they are small, local, and explicitly justified by pricing/relic-pattern checks; no restraint concern.
9. [NOTE] READ - Identifiers are limited to random install id, session, and run id; no names/network. Linking an install's runs across merged files is inherent to the install id and appears intentional/anonymous.
10. [NOTE] INFERRED - No listed field appears impossible to emit, but fleetPower may need to be computed at battle_start; enemy fleetPower is absent rather than impossible.

Not checked: I did not evaluate Godot implementation details beyond data availability, save/importer/fuzz isolation, file export UX, schema versioning mechanics, analysis-script correctness, id-to-effect/rarity/capstone mappings, or the game's design/tuning.
