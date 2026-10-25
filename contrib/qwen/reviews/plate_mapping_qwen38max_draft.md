# Plate-to-Terrain Mapping Draft - Qwen

Model: Qwen3.8-Max, Thinking ON, Search OFF. Filed verbatim from the Qwen chat report (existing thread, Oct 25, 2026 retry); em dashes normalized to hyphens if any, wording otherwise unchanged. The staged message first drew a reply that no file was visible to the model; the browser agent then opened the attachment preview in the same thread, copied the brief text shown there exactly, and pasted it into the same thread, after which Qwen produced this draft. No model switch, upgrade, payment, or new chat was used. A second browser check later found the same draft already in the thread and sent nothing further. See the screening note for a composer-header model discrepancy (Qwen3.7-Plus observed in the header on the later check) that leaves the draft's model attribution carrying a caveat.

Status: DRAFT / PROPOSAL. Nothing in this document is a ruling. All items require Ryan's sign-off before implementation.

Plate-to-Terrain Mapping Draft
Prepared for: Ryan (owner) and Opus (coder/verifier)
Status: DRAFT / PROPOSAL. Nothing in this document is a ruling. All items require Ryan's sign-off before implementation.
Scope: PC-only, Babylon build. No phone frame, phone tier, or phone acceptance check applies anywhere in this document.
Hard rules carried forward (not re-litigated here): four layers per plate; no background pixel inside the board area may exceed 40% of an unlit hull facet's luminance.

1. Mapping Table - All 18 Plates
Every plate is assigned to exactly one terrain kind or one explicit non-terrain role. No plate is left unmapped.

Anchors (6)
Belt - Terrain kind: belt - OBSERVED - direct name match to battle.js:193
Storm - Terrain kind: storm - OBSERVED - direct name match
Graveyard - Terrain kind: graveyard - OBSERVED - direct name match
Planet - Terrain kind: planet - OBSERVED - direct name match
Station - Terrain kind: station - OBSERVED - direct name match
Dead Star - No terrain kind exists. See Section 2. - OBSERVED gap (Pack J audit, verified)

Variants (6)
Belt Core - Terrain kind: belt (replaces Belt anchor; see Section 3) - OBSERVED parent link; trigger rule PROPOSED
Crimson Storm - Terrain kind: storm (replaces Storm anchor; see Section 3) - OBSERVED parent link; trigger rule PROPOSED
Fresh Battlefield - Terrain kind: graveyard (replaces Graveyard anchor; see Section 3) - OBSERVED - brief names it "graveyard variant"; trigger rule PROPOSED
Ring World - Terrain kind: planet (replaces Planet anchor; see Section 3) - OBSERVED - brief names it "planet variant"; trigger rule PROPOSED
Dockyard Dawn - Terrain kind: station (replaces Station anchor; see Section 3) - OBSERVED - brief names it "station variant"; trigger rule PROPOSED
Dead Star Companion - Dependent on Section 2 outcome. If Dead Star receives a sixth terrain kind, this maps to that kind. If Dead Star receives a non-terrain role, this inherits that role. - OBSERVED parent link; role PROPOSED, pending Section 2

Specials (6)
None of the six specials corresponds by name or description to any of the five existing terrain kinds. All six are assigned non-terrain roles. Every assignment below is PROPOSED; none follows from the code or the art pack descriptions provided.
Stellar Nursery - Home-ground seasoning - PROPOSED
Ice Field - Anomaly - PROPOSED
Shattered Moon - Boss fight - PROPOSED
Pulsar - Anomaly - PROPOSED
Solar Corona - Boss fight - PROPOSED
Void Rift - Finale - PROPOSED

Note on menu/backdrop: No plate in the current set of 18 is mapped to menu/backdrop. If Ryan wants a dedicated menu plate, that is a scope addition, not a remapping of anything above. Flagging it here so it is not silently forgotten.

2. Dead Star Recommendation
The problem (OBSERVED)
There are six anchors and five terrain kinds. Dead Star is the sixth anchor. No terrain kind called "dead star" (or any synonym) exists in battle.js:193. The Pack J audit verified this gap. The art pack description for the Dead Star plate reads: "the argument for the well mechanic on sight alone." No well mechanic is defined anywhere in the current codebase or design docs.

Primary recommendation: well mechanic (PROPOSED)
The plate art was evidently designed to showcase a well - a gravity-well or void-well interaction that would sit at the centre of the board and affect play. I recommend formalising that intent:
Dead Star becomes the anchor for a well encounter, a new encounter type distinct from the five terrain kinds.
Dead Star Companion is its variant (see Section 3).
Honest cost statement. This is not a mapping decision. It is new engine work. At minimum it requires:
A new encounter-type branch in battle.js alongside belt / station / planet / storm / graveyard.
New interaction logic for the well (pull radius, turn effects, or whatever the mechanic does). None of this is designed yet.
New AI behaviour so opponents interact with the well meaningfully.
A balance pass specific to well encounters.
QA time for a sixth encounter type on top of the existing five.
I cannot estimate effort beyond saying it is strictly more than adding a sixth terrain skin. It is a new system. If Ryan wants it, it should be scoped as its own work item, not folded into the plate-mapping task.

Fallback if the well mechanic is rejected (PROPOSED)
Assign Dead Star to a non-terrain role. My suggested fallback is boss fight, on the grounds that a dead star reads as a singular, high-stakes location rather than a recurring environment. Dead Star Companion would then also be a boss-fight plate. This requires zero engine work beyond adding a role tag.
A secondary fallback would be finale, if Ryan prefers to reserve boss-fight plates for other content. Either way, no new terrain kind is created and battle.js:193 stays at five entries.

What I am NOT recommending
I am not recommending a sixth terrain kind called "dead_star" with no new mechanic. That would put a sixth entry in battle.js that behaves identically to one of the other five, which solves the count mismatch but creates a dead label. If the well is rejected, a non-terrain role is cleaner than a hollow sixth kind.

3. Variant Trigger Rules
Each variant replaces its anchor plate when its trigger condition is met. Otherwise the anchor shows. One rule per variant. All trigger rules below are PROPOSED; the parent-link relationships are OBSERVED.
Belt Core - Belt - Sector position. The encounter takes place in a belt sector flagged as a core region (innermost ring or equivalent depth flag). If the flag is absent, Belt shows. - PROPOSED
Crimson Storm - Storm - Rotation / escalation. The storm encounter is the second or later storm in the same campaign arc (i.e., the storm has been encountered before and is recurring or escalating). First storm in an arc shows the Storm anchor. - PROPOSED
Fresh Battlefield - Graveyard - Session recency. The graveyard encounter occurs in the same sector and the same play session immediately after a player-fought battle. If no prior battle this session in that sector, the Graveyard anchor shows. "Fresh" means the wreckage is still warm. - PROPOSED
Ring World - Planet - Sector position / planet flag. The planet encounter is in a sector whose planet asset carries a ring designation. If the planet has no ring flag, Planet shows. - PROPOSED
Dockyard Dawn - Station - Home ground. The station encounter is at the player's home station or an allied/friendly station. Hostile or neutral stations show the Station anchor. "Dawn" reads as safety and return. - PROPOSED
Dead Star Companion - Dead Star - Paired encounter. The Dead Star encounter includes a secondary object or a two-phase structure (companion body present). Solo Dead Star encounters show the Dead Star anchor. Exact trigger depends on Section 2 outcome. - PROPOSED

4. Special Trigger Rules
Specials are not tied to terrain kinds. They appear based on event or fight type. All rules below are PROPOSED.
Stellar Nursery - The player is at a home-ground or safe-harbour scene that is not a combat encounter. Used as ambient seasoning for a friendly port, creation, or resupply moment. - PROPOSED
Ice Field - An anomaly-type encounter is triggered (unscripted, exploration-based, or environmental-hazard event). Ice Field is the anomaly plate for cold / desolate / low-activity anomaly events. - PROPOSED
Shattered Moon - A boss-type encounter is triggered. Shattered Moon is the boss plate for physical-destruction bosses (broken body, debris field). - PROPOSED
Pulsar - An anomaly-type encounter is triggered. Pulsar is the anomaly plate for high-energy, rhythmic, or radiation-based anomaly events. - PROPOSED
Solar Corona - A boss-type encounter is triggered. Solar Corona is the boss plate for energy / heat / star-adjacent bosses. - PROPOSED
Void Rift - The campaign finale or endgame encounter is triggered. One plate, one use per campaign. - PROPOSED

Selection within a shared role. Where two specials share a role (Ice Field and Pulsar are both anomaly; Shattered Moon and Solar Corona are both boss fight), the choice between them is determined by the encounter's sub-type tag (cold/desolate vs. energetic/radiation for anomalies; physical-destruction vs. energy/heat for boss fights). If sub-type tagging is not in the current data model, that is a small schema addition Opus would need to confirm.

5. Three Mappings I Am Least Sure About
1. Dead Star (Section 2, entire recommendation).
I do not know what the well mechanic is supposed to do. The art pack says the plate argues for it "on sight alone," but no design doc defines it. My recommendation is built on inference from a single description line. If Ryan has a separate well-mechanic design doc that I have not seen, my recommendation may be wrong in detail even if right in spirit.
What would settle it: Ryan confirms whether a well-mechanic design exists or is intended. If yes, scope it as engine work. If no, take the boss-fight fallback.
2. Dockyard Dawn as home-ground-only (Section 3).
I tied this variant to the player's home station or allied stations. But "Dockyard Dawn" could equally be a time-of-day or rotation trigger (the station is seen at dawn, i.e., early in a sector arc) rather than a faction/home-ground trigger. I chose home-ground because "dawn" reads as safety and return, but that is interpretation, not fact.
What would settle it: Ryan or the art lead confirms whether "Dawn" in the title refers to a narrative/faction context (home, friendly) or a temporal/rotation context (first visit, early encounter).
3. Void Rift as the sole finale plate (Section 4).
I gave Void Rift the finale role and no other plate. This means the finale backdrop is fixed for the entire campaign. If the game ever needs a second finale context (a secret ending, a bonus final fight, a different campaign path), there is no second finale plate assigned. I also considered Solar Corona for finale and moved it to boss fight, but I am not confident that is the right split.
What would settle it: Ryan confirms whether the game has exactly one finale moment or more than one. If more than one, a second plate needs the finale tag, and Solar Corona is the natural candidate.

End of draft. All items above are proposals for Ryan's review. No mapping, trigger rule, or role assignment is final until Ryan rules.
