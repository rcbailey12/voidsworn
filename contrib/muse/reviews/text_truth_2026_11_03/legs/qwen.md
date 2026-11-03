Qwen leg, issue #88, run 2026-11-03 from the main chat. Gates: Gate 1 passed (selector showed Qwen3.8-Max before the prompt was submitted); Gate 2 passed (the chat header still showed Qwen3.8-Max after generation). All four pack files were attached to the send message itself. Single response, no preference picker. Chair note: the response ends abruptly at the final UNVERIFIED table row ("LINEAGE_TREES (all"), as returned; nothing follows it.

---

# Issue #88 - Text Truth Pass: Qwen Leg Mismatch Report

## Mismatch Table

| ID | Quoted text | Code truth | Proposed corrected text | Verdict |
|---|---|---|---|---|
| WTRAITS:spines | "hull hits strip 3 armor points, up to 15" | The record's own function sets `w.shred=.03`. The text states a flat "3 armor points" but the code value is the fraction 0.03; these are not the same unless the shred application multiplies by 100, and no such application code is given in the pack. | "hull hits strip armor: 3% of the ship's armor per hit, up to 15 points stripped in total." | AMBIGUOUS - .03 reads as a fraction (3%) while the text says "3 armor points"; without the shred application code (e.g. `armor -= shred * 100` or similar, the text is fine as written. |

No other CERTAIN mismatches were found.

## Coverage Statement

| Category | Count examined |
|---|---|
| ABILITIES (13 present in data.js; pack states 14 - see Not Checked) | ~13 (all present) |
| CAMPAIGN | ~8 |
| COMMAND | ~24 |
| TIPS (browser) | ~10 |
| TIPS (Godot) | ~10 |
| WTRAITS | ~10 |
| FLEET_ROLES | ~5 |
| SHIPS | ~8 |
| WEAPONS | ~24 |
| MODULES | ~13 |
| RELICS | ~13 |
| NODE_MODS | ~9 |
| SECTOR_CONDS | ~9 |
| CREW | ~18 |
| FLEET_MODIFIERS | ~6 |
| HEAT | ~7 |
| WING_STANCES | ~3 |
| WING_PERKS | ~6 |
| LINEAGE_TREES | ~6 |
| c_tree | ~1 |
| TUTORIAL | ~6 |
| OTHER | ~6 |

Total player-facing rule texts examined: ~261. Flagged: 1 (AMBIGUOUS).

## UNVERIFIED Texts (no implementation fact available in the pack; text not contradicted by any stated fact)

| ID / location | Reason |
|---|---|
| CAMPAIGN:2-3 | No scenario generation implementation in pack. |
| CAMPAIGN:5 | Bounty, damage, and reward values not in pack facts. |
| CAMPAIGN:6-7 | No campaign objective/reward implementation in pack. |
| RELICS:deflect - "no weapons" | `deflect:1` implementation not provided. |
| RELICS:phylactery - "restarts at 25% hull" | `revive:1` implementation not provided. |
| RELICS:salvage - "gain 15 credits and repair 8% hull" | `salvage:1` implementation not provided. |
| MODULES:flakplus - "+2 shots and +1 range" | `flakPlus:1` application code not provided. |
| 22 of 24 Admiral Command texts (all except Vex barrage and Malek hunt, which the pack verifies) | No implementation facts given; texts are internally consistent and consistent with cooldown/torpedo rules. |
| All 7 HEAT entries | No Heat implementation facts in the pack. |
| WING_STANCES (3) and WING_PERKS (6) | No wing doctrine implementation facts. |
| NODE_MODS:bounty - "+50% credits, 10% more ships"; NODE_MODS:veteran | No implementation facts. |
| SECTOR_CONDS:dark - "-15 to hit inside"; SECTOR_CONDS:wreck - "-10 to hit inside" | Terrain to-hit modifiers not in pack facts (the cred and repair multipliers are verified). |
| TIPS select: "+10 to their hit chance" / "-5" stationary/movement modifiers | No pack fact for these specific values. |
| c_tree (both browser and Godot); "+2 experience to the admiral you fly and +1 to your faction's shared pool" | No Heat XP implementation fact. |
| LINEAGE_TREES (all | |
