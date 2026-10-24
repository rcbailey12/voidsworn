# Plate-to-Terrain Mapping Draft - Voidsworn (PC-only)

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report (chat titled "Plate terrain mapping draft"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file was attached to the chat. Process note from the run: the first send hit a DeepSeek-side error and the chat had not persisted after reload, so the prompt was re-sent in a new chat and DeepSeek completed the draft there.

Status: DRAFT for Ryan and Opus. Not a ruling. Nothing here is decided until Ryan rules.
This draft does not change any plate art or description. Scope is PC-only. No phone frame, phone tier, or phone acceptance check is part of this draft.

## Status key
- OBSERVED = follows from the brief facts above.
- PROPOSED = I am inventing the mapping or rule.
- Where a variant parent is stated in the brief, it is noted as OBSERVED even if the terrain mapping itself is PROPOSED.

## 1. Mapping table: all 18 plates
| # | Plate | Group | Mapping | Status | Notes |
| 1 | Belt | Anchor | belt terrain kind | PROPOSED | Direct name match, but the brief does not explicitly state the one-to-one mapping. |
| 2 | Storm | Anchor | storm terrain kind | PROPOSED | Direct name match, same caveat. |
| 3 | Graveyard | Anchor | graveyard terrain kind | PROPOSED | Direct name match, same caveat. |
| 4 | Planet | Anchor | planet terrain kind | PROPOSED | Direct name match, same caveat. |
| 5 | Station | Anchor | station terrain kind | PROPOSED | Direct name match, same caveat. |
| 6 | Dead Star | Anchor | finale, non-terrain role | PROPOSED | Dead Star has no terrain kind. That gap is OBSERVED. Recommendation below. |
| 7 | Belt Core | Variant | belt terrain kind, Belt variant | PROPOSED | Parent inferred from name only. |
| 8 | Crimson Storm | Variant | storm terrain kind, Storm variant | PROPOSED | Parent inferred from name only. |
| 9 | Fresh Battlefield | Variant | graveyard terrain kind, Graveyard variant | PROPOSED | Parent OBSERVED: brief says graveyard variant. |
| 10 | Ring World | Variant | planet terrain kind, Planet variant | PROPOSED | Parent OBSERVED: brief says planet variant. |
| 11 | Dockyard Dawn | Variant | station terrain kind, Station variant | PROPOSED | Parent OBSERVED: brief says station variant. |
| 12 | Dead Star Companion | Variant | finale, non-terrain role, Dead Star variant | PROPOSED | Parent inferred from name. Maps to same non-terrain role as Dead Star. |
| 13 | Stellar Nursery | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |
| 14 | Ice Field | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |
| 15 | Shattered Moon | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |
| 16 | Pulsar | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |
| 17 | Solar Corona | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |
| 18 | Void Rift | Special | anomaly, non-terrain role | PROPOSED | Trigger below. |

No plate is left unmapped. Every plate has exactly one terrain kind or one explicit non-terrain role.

## 2. Dead Star recommendation
Recommendation: non-terrain role, finale. PROPOSED.
Dead Star should be the finale plate, not a sixth terrain kind in this draft. This keeps the five code terrain kinds unchanged: belt, station, planet, storm, graveyard. Dead Star Companion is then the finale variant of Dead Star. This is a mapping and role decision only. It does not add a well mechanic.

Why this is the safer draft: the brief records that Dead Star has no terrain kind and that no well mechanic is defined anywhere. A sixth terrain kind or a well mechanic is new engine work, not a mapping decision. The finale role uses the plate without pretending the gap is solved by art language.

Optional well mechanic alternative (not recommended now): PROPOSED. If Ryan wants the Dead Star art to carry a well mechanic on sight, the honest cost is new engine work: a well zone or terrain state, movement or pull or visibility rules, AI handling, UI/readability work, balance, and verification. It is not a plate mapping change. The fallback if the well mechanic is rejected is this draft's recommendation: Dead Star as non-terrain finale, with Dead Star Companion as the phase 2 finale variant.

## 3. Variant rules: when the variant shows instead of its anchor
| Variant | Parent | One rule | Status |
| Belt Core | Belt | Home ground: shows instead of Belt when Belt terrain is in a faction's home belt sector. | PROPOSED |
| Crimson Storm | Storm | Rotation: shows instead of Storm on the storm rotation slot marked crimson in that sector's rotation cycle. | PROPOSED |
| Fresh Battlefield | Graveyard | Sector position: shows instead of Graveyard when that graveyard sector had a battle within the last 3 turns. | PROPOSED |
| Ring World | Planet | Home ground: shows instead of Planet when planet terrain is in a faction home sector flagged as a ring world. | PROPOSED |
| Dockyard Dawn | Station | Home ground: shows instead of Station when station terrain is a faction home dockyard. | PROPOSED |
| Dead Star Companion | Dead Star | Other trigger: shows instead of Dead Star when the finale boss enters phase 2. | PROPOSED |

## 4. Special trigger rules
| Special | Mapping | Trigger event or fight type | Status |
| Stellar Nursery | anomaly | Anomaly fight in an unowned planet sector. | PROPOSED |
| Ice Field | anomaly | Anomaly fight in a storm sector during the cold rotation slot. | PROPOSED |
| Shattered Moon | anomaly | Anomaly fight in a graveyard sector that contains a destroyed planet marker. | PROPOSED |
| Pulsar | anomaly | Anomaly fight in a storm sector when the pulse timer event fires. | PROPOSED |
| Solar Corona | anomaly | Anomaly fight in a planet sector during a solar flare event. | PROPOSED |
| Void Rift | anomaly | Anomaly fight in a sector with no terrain owner after a boss fight. | PROPOSED |

## Three least sure mappings
1. Belt anchor to belt terrain kind. The name match is strong, but the brief does not explicitly state that anchors map one-to-one to same-named terrain kinds. Ryan's ruling or an Opus code/data check on how anchors are referenced would settle it.
2. Dead Star to non-terrain finale instead of a sixth terrain kind or well mechanic. This depends on engine budget and owner intent, not on the plate list alone. Ryan's ruling on whether the well mechanic gets new engine work, plus an Opus estimate, would settle it.
3. Specials mapped to anomaly with event triggers. The brief lists specials but does not define an anomaly event system or fight type table. Ryan's event-system ruling or an Opus check of the event/fight enum would settle it.

END OF DRAFT
