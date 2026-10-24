# Price Ladder and Roster Gate Synthesis (chair, SINGLE LEG)

Legs: contrib/deepseek/reviews/price_ladder_deepseek_draft.md (DeepSeek).
Qwen leg PENDING: blocked Oct 24 by the Qwen3.8-Max daily limit, retry
scheduled Sun Oct 25 ~9:45 AM CDT. This synthesis will be updated to two
legs when the Qwen leg lands. Nothing in it is a ruling.

Chair verdict: GO WITH CONDITIONS (single-leg caveat applies throughout:
a second leg may move the multipliers, the gates, or both).

## Headline
The price table is coherent and the math checks out, and the gates map
cleanly onto the approved prohibitions. The table tells a distinct story
per faction: Chorus swarms cheap and prices capitals out (0.70 frigate to
1.60 BB+), Deathless inverts that shape for elite attrition (1.35 small
hulls, 1.15 BB+), Ithar taxes everything (1.25 to 1.35), Corsairs go cheap
small and expensive heavy (0.85 to 1.40). Every worked frigate and
destroyer example recomputes correctly under the stated nearest-5,
ties-up convention against the OBSERVED bases (70 and 130).

## Staleness warning: read the Hegemony passages as out of date
The DeepSeek draft was written from a brief that predates Ryan's Hegemony
ruling. Where the draft says the Hegemony defining trait is "still open"
and "until Ryan rules," that is no longer true. Ryan ruled Oct 24 ~11:50:
synchronized fire primary, pinning secondary (waves of fire).
- What survives: the Hegemony 1.0 price row. The ruling changes no
  prices, and the brief's baseline stands.
- What is stale: the Hegemony gate row (OPEN) and the fleet-sketch line
  about Hegemony claiming no specialist identity.
- What remains genuinely open: the Hegemony LOSS to pair with
  synchronized fire, under the each-faction-loses principle. The ruling
  sets the definer, not the loss. The Qwen leg (written from the same
  pre-ruling brief) will carry the same staleness, so the loss question
  should be settled by Ryan, not by either leg.

## Conditions
1. Opus data-model confirmations (the implementation unlock): whether
   per-faction per-class multipliers are supportable without code, and
   whether class availability flags (Voidsworn carrier gate) and
   weapon-kind availability flags (Corsair gate) exist or need code.
   The price table is DATA-ONLY only if the multiplier field exists.
2. Voidsworn carrier branch: the table prices Voidsworn carriers at 1.25
   while the gate list removes the carrier class. If the gate is
   adopted, drop the carrier multiplier; if the gate is rejected, the
   multiplier is the fallback. State the branch when adopting.
3. BB+ bucket and Squadron: BB+ lumps Battleship and above without
   saying which classes it covers, and Squadron hulls are unaddressed.
   Opus to confirm the BB+ mapping and where Squadron prices sit
   against the real cls taxonomy.
4. Corsair gate pick: "long-range missile or bombard weapon kind" names
   two candidate kinds without picking one. Opus to confirm which kinds
   exist as flaggable availability; then the kind (or both) gets picked.
5. Chorus repair scope and Ithar Brace gate stand as the draft states
   them: repair gate NEEDS CODE with scope across shipyard, Drydock,
   and Field repairs OPUS TO CONFIRM; Brace gate is a NEEDS CODE boolean
   in canOrder. Deathless no-shield is correctly an OBSERVED roster
   fact, not a new gate.

## Recommended next step
Opus confirms the data-model questions in condition 1 (multiplier field,
class flag, weapon-kind flag). That confirmation decides whether the
table lands as data-only or needs code, and it is the blocker for every
other item above. The Hegemony loss pairing with synchronized fire is
Ryan's call and can be ruled in parallel.

## Not checked
- The Qwen leg (pending retry) and any multiplier or gate it proposes.
- Whether explicit h.cost overrides already exist anywhere that would
  collide with a multiplier field.
- The economy hook, which remains separately scoped and out of this
  draft by design.
