# GOLD LAW REPAIR - DRAFT FOR RYAN AND OPUS

Model: Qwen3.8-Max, Thinking ON, Search OFF. Filed verbatim from the Qwen chat report (chat titled "Gold Law Repair Draft"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file could not be attached in chat (no usable file-input target); the brief's full verbatim text was pasted into the prompt instead. The browser agent's own deliverable-check paragraph is omitted here as non-draft meta text.

Status: PROPOSED. This is a draft for review, not a ruling. Nothing here is adopted until Ryan rules. Opus: please verify against the live files before any implementation.

Scope: PC-only. No phone frame, no phone tier, no phone acceptance check applies to any part of this document.

## 1. REPAIRED LAW TEXT
PROPOSED replacement paragraph for the art pack gold-law entry:
"Command Gold is a single reserved colour role, limited to the patron UI and the Command interface. It appears only as the selection ring (white state) and the faction-coloured chevron that replaces the old flagship marker. No other asset may use a colour, a material descriptor, or a rarity tag that a viewer at battle zoom could read as Command Gold. Faction trims, environmental palettes, mood plates, and rarity tiers must therefore avoid the word 'gold' in their spec language and must sit outside the Command Gold hue-and-value window (defined in the Command UI colour sheet). Where legacy text used 'gold' to describe a warm metallic, a chitin sheen, a pale filigree, or an atmospheric glow, that word is retired from the spec and replaced with a term that names the actual material or phenomenon. Epic rarity, which previously held a conditional gold-adjacent slot, is PROPOSED to move to a non-gold family entirely, because the condition 'only if gold is freed up' is now permanently false. After this repair, 'gold' in any Voidsworn document means one thing: the Command Gold reserved for patrons and the Command UI."

## 2. RULING TABLE
Each row addresses one OBSERVED contradiction from Pack J. The disposition column is PROPOSED, not decided.
- Chorus trim | OBSERVED: "dull gold #a4913a ... reads as chitin ridge, not metal" | PROPOSED disposition: RENAME | Reasoning: The spec already says it reads as chitin, not metal; PROPOSED rename to "chitin amber" or "chitin ochre" to match its own description and sever the word "gold" without touching the hex.
- Ithar trim | OBSERVED: "pale gold #d7c88a ... gold filigree inlay" on pearl hulls | PROPOSED disposition: RENAME | Reasoning: PROPOSED rename to "ivory filigree" or "pearl-brass filigree"; the hue sits on pearl hulls and functions as inlay, so a non-gold material name is more accurate and removes the rationing collision.
- Epic rarity | OBSERVED: "stays gold-adjacent only if gold is freed up" | PROPOSED disposition: RECOLOR | Reasoning: The condition is now permanently false under the repaired law, so the slot must leave the gold family. PROPOSED replacement colour family: cool silver-to-steel or deep violet-to-magenta, whichever Opus confirms does not collide with existing legendary or mythic tiers. Final hex is not set here.
- Belt plate mood | OBSERVED: "prospector gold over black" | PROPOSED disposition: RENAME | Reasoning: This is a mood-board descriptor, not a UI colour. PROPOSED rename to "prospector brass over black" or "prospector amber over black"; the visual target stays the same, only the word changes.
- Stellar Nursery gas | OBSERVED: "towering pillars of teal and gold gas" | PROPOSED disposition: RENAME | Reasoning: Environmental art note. PROPOSED rename to "teal and amber gas" or "teal and ochre gas"; the rendered nebula palette is unchanged, only the spec language is.
Note: no entry is marked KEEP. Every OBSERVED use of the word "gold" outside Command UI either loses the word (RENAME) or loses the colour family (RECOLOR). This is the minimum set needed to make the law self-consistent.

## 3. MIGRATION LIST
If Ryan adopts this repair, the following documents must be updated. Doc names are OBSERVED from the brief; the change descriptions are PROPOSED.
- Art pack - gold-law paragraph: Replace the current one-paragraph law with the repaired text in Section 1 above. Remove the sentence "Gold currently means five things; after this it means one" and substitute the explicit definition.
- Art pack - Chorus faction trim spec: Replace "dull gold" with "chitin amber" (or the RENAME term Ryan approves). Hex #a4913a stays. Add a cross-reference line: "Not Command Gold. See gold law."
- Art pack - Ithar faction trim spec: Replace "gold filigree inlay" with "ivory filigree" (or approved RENAME). Hex #d7c88a stays. Add the same cross-reference line.
- Art pack - Epic rarity spec: Remove the conditional "stays gold-adjacent only if gold is freed up." Insert the new RECOLOR family. Flag the old gold-adjacent swatch as deprecated.
- Art pack - Belt plate mood entry: Replace "prospector gold" with "prospector brass" or "prospector amber."
- Art pack - Stellar Nursery plate description: Replace "teal and gold gas" with "teal and amber gas" or "teal and ochre gas."
- Pack J consensus notes: Append a resolution note referencing this repair. Mark the five contradictions as addressed (pending Ryan's sign-off).
- visual_qa_pack: Update the gold-adjacency check: the three trims (Chorus, Ithar, epic rarity) are tested against Command Gold under the new naming. Add the viewer-test protocol from Section 4 below as the acceptance gate. Remove any language that permits "gold-adjacent" as a pass state outside Command UI.
- Any faction colour-sheet or UI colour-sheet doc: Add a "Command Gold reserved" callout at the top so a new artist sees the rationing rule before picking a palette.
Opus: please confirm whether any additional files (shader graphs, rarity icon sets, mood-board exports) reference the old "gold" language. The list above is built from what the brief names; there may be downstream files I cannot see.

## 4. VIEWER TEST (PC, battle zoom)
PROPOSED protocol. PC-only. No phone frame or phone-tier check.
- Who looks: Two reviewers minimum. One is an artist who did NOT work on the faction trims. One is Opus or a designated QA verifier. Neither should have read the spec names before the test (blind check).
- Zoom and conditions: Standard PC battle zoom (the default RTS camera distance at which a player issues commands). Monitor at native resolution, no colour-correction filters. The scene must contain at least one Command UI element showing Command Gold (selection ring or chevron) AND at least one instance of each renamed trim or recoloured tier in the same frame.
- What the reviewers do: Without being told which assets are Command and which are trim, each reviewer marks every element they believe is "the gold Command marker." They then mark every element they believe is "gold or gold-like" anywhere in the frame.
- What counts as confusion: If a reviewer flags a Chorus chitin-amber trim, an Ithar ivory-filigree trim, or an epic-rarity icon as a Command Gold element, that is a FAIL under the rationing rule. The finding is logged against the asset, not the viewer. If a reviewer flags Command Gold itself as "trim" or "rarity colour," that is also a FAIL (Command Gold must be unambiguous in the other direction).
- Pass condition: Zero cross-flags across both reviewers across three different battle scenes (one per faction trim context, one with epic-rarity loot visible, one with the Belt or Stellar Nursery environment in the background).
- Fail action: Any FAIL sends the offending asset back for RECOLOR or further value/hue separation from Command Gold. The RENAME alone is not a shield if the colour still reads as Command at distance.

## 5. THE CONFLICT THIS REPAIR HANDLES WORST
Epic rarity.
The RENAME fixes work because the underlying colours (#a4913a, #d7c88a) are already described as reading as chitin, pearl, or brass. Renaming the word aligns the spec with what the colour already does. The Stellar Nursery and Belt plate moods are likewise language-only fixes.
Epic rarity is different. Its OBSERVED text ties it to gold by conditional logic ("only if gold is freed up"), not by a specific hex. The PROPOSED RECOLOR to a silver-steel or violet-magenta family is a guess at a direction, but I cannot see the full rarity ladder, the legendary tier colour, or the mythic tier colour. If either of those already occupies silver or violet, the RECOLOR collides with a neighbour and the problem just moves. What would settle it: Ryan and Opus confirming the full rarity colour ladder (common through mythic) so the epic slot can be placed in a family that is provably free, and then a follow-up viewer test at loot-screen zoom (not just battle zoom) to confirm the new family reads as "rare and exciting" without borrowing any gold signal.
End of draft. Awaiting Ryan's ruling. Opus: flag any file-level contradictions before this goes further.
