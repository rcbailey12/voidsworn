# Price Ladder and Roster Gate Synthesis (chair, TWO LEGS)

Legs: contrib/deepseek/reviews/price_ladder_deepseek_draft.md (DeepSeek)
and contrib/qwen/reviews/price_ladder_qwen38max_draft.md (Qwen, Oct 25
retry). The Qwen leg contains TWO parallel responses from a comparison
view (Response 1: per-class multipliers; Response 2: flat multipliers)
with no preference selected in the run, so this synthesis treats them
as two Qwen variants alongside the DeepSeek leg and picks no winner
silently. Nothing in it is a ruling.

Chair verdict: GO WITH CONDITIONS (strong agreement on the core,
genuine open choices on the gates and the multiplier shape).

## Headline
The core is now triple-confirmed: Hegemony at 1.0, the Voidsworn
carrier gate, the approved Ithar Brace and Chorus repair prohibitions,
and Deathless no-shield as an observed roster fact, not a gate. The
price stories agree in shape even where the numbers differ: Chorus
swarms cheap and prices capitals out, Deathless inverts that shape for
elite attrition, Ithar taxes everything, Corsairs go cheap small and
expensive heavy. What the three drafts do not agree on is the loss
each faction takes beyond the approved prohibitions, and the multiplier
shape itself: Response 1 prices per faction per class, Response 2 and
DeepSeek price flat per faction. Those are Ryan's and Opus's choices,
not chair choices, and the synthesis below states each choice with its
deciding question instead of adopting one.

## Staleness warning: read the Hegemony passages as out of date
All three drafts were written from a brief that predates Ryan's
Hegemony ruling. Where any draft says the Hegemony defining trait is
"still open" and "until Ryan rules," that is no longer true. Ryan
ruled Oct 24 ~11:50: synchronized fire primary, pinning secondary
(waves of fire).
- What survives: the Hegemony 1.0 price row in all three drafts. The
  ruling changes no prices, and the baseline stands.
- What is stale: Response 1's Hegemony no-BB+ gate (which it names as
  its own least-sure item, justified only by the each-faction-loses
  principle), DeepSeek's Hegemony gate row (OPEN), and Response 2's
  Hegemony TBD/no gate.
- What remains genuinely open: the Hegemony LOSS to pair with
  synchronized fire, under the each-faction-loses principle. The ruling
  sets the definer, not the loss. Response 1's BB+ gate is a candidate
  loss, not a settled one, and it may over-constrain a faction whose
  identity is now defined. That pairing is Ryan's call.

## Agreements (adoptable as the core, with condition 1 below)
- Hegemony 1.0 across the ladder in all three drafts.
- Voidsworn loses the carrier class in all three drafts. Branch rule
  carried from the single-leg synthesis: if the gate is adopted, any
  Voidsworn carrier multiplier is moot. Response 1 already prints no
  carrier multiplier; Response 2's flat 1.20 still prices a carrier
  Voidsworn cannot buy, so state the branch when adopting.
- Ithar cannot Brace (approved, NEEDS CODE boolean in canOrder) and
  Chorus no shipyard repair (approved, NEEDS CODE, scope across
  shipyard, Drydock, and Field repairs OPUS TO CONFIRM) in all three
  drafts.
- Deathless no-shield is correctly an OBSERVED roster fact in all
  three drafts, not a new gate.
- Worked frigate and destroyer math recomputes correctly under
  nearest-5 rounding in all three drafts, with one correction: Response
  2's illustrative Deathless battleship at cp-5 should read 525, not
  530 (310 x 1.70 = 527, which rounds to 525). Do not copy 530 into any
  table.

## Open choices (decide explicitly, do not let the synthesis decide)
1. Multiplier shape: per-class (Response 1: Chorus 0.65 frigate rising
   to 1.25 BB+, Deathless 1.45 frigate to 1.60 BB+, Ithar 1.30/1.30/
   1.15/1.00/1.10) vs flat per faction (Response 2: Chorus 0.65,
   Deathless 1.70, Ithar 1.45; DeepSeek: Chorus 0.70 to 1.60, Deathless
   inverted 1.35 to 1.15, Ithar 1.25 to 1.35). Per-class expresses the
   faction story better; flat needs only one field per faction.
   Deciding question for Opus: does a per-faction per-class
   multiplier field or explicit override exist, and does the round-once
   convention double-round with the existing Math.round site?
2. Corsair loss: cruiser class (Response 1) vs battleship-and-above
   (Response 2) vs long-range weapon kind (DeepSeek, which names two
   candidate kinds without picking one). Deciding question: which
   loss best expresses "close-range salvage raider" without breaking
   the faction's fleet shape, and which kinds/classes exist as
   flaggable availability?
3. Deathless loss: no frigates (Response 1, and Response 2's own
   fallback) vs a hard fleet cap of 8 hulls (Response 2's primary).
   The cap is the only gate in any draft that constrains fleet size
   rather than filtering a class or system, and it needs a roster-build
   enforcement point Opus must confirm. No-frigate is the simpler path
   to the same "few, powerful hulls" shape. Response 2's own least-sure
   item is the cap; test whether 1.70 pricing alone limits fleet size
   through budget pressure before adding a cap.
4. Chorus top end: Response 1 prices BB+ at 1.25 with no class gate,
   Response 2 gates cruiser-and-above, DeepSeek prices BB+ at 1.60
   with no class gate. Deciding question: does the swarm need a hard
   class ceiling, or does the price curve alone keep it out of
   capitals?
5. Ithar additions: Response 1 adds a stand-off weapon-kind gate,
   Response 2 adds a heavy-armor module gate, DeepSeek adds neither.
   Both additions need their taxonomy confirmed (weapon kinds,
   module loadout filtering) before any flag is drafted.

## Conditions
1. Opus data-model confirmations (the implementation unlock): whether
   per-faction per-class multipliers are supportable without code,
   whether class availability flags (Voidsworn carrier gate) and
   weapon-kind availability flags (Corsair gate, Ithar weapon gate)
   exist or need code, and whether a fleet-size cap has a clean
   roster-build enforcement point. The price table is DATA-ONLY only
   if the multiplier field exists.
2. Higher-tier bases: Response 1 correctly prints no absolute prices
   above destroyer. Response 2's inferred bases (cruiser 190, carrier
   250, battleship 310, above-BS 370+) assume cp values 3, 4, 5, 6+
   that are not in the brief facts. Opus must confirm the real cp
   taxonomy and bases before any absolute price above destroyer is
   committed. BB+ lumps Battleship and above without saying which
   classes it covers, and Squadron hulls are unaddressed. Opus to
   confirm the BB+ mapping and where Squadron prices sit against the
   real cls taxonomy.
3. Chorus repair scope and Ithar Brace gate stand as the drafts state
   them: repair gate NEEDS CODE with scope across shipyard, Drydock,
   and Field repairs OPUS TO CONFIRM; Brace gate is a NEEDS CODE
   boolean in canOrder. Deathless no-shield is correctly an OBSERVED
   roster fact, not a new gate.

## Recommended next step
Opus confirms the data-model questions in condition 1 (multiplier
field shape, class flag, weapon-kind flag, fleet-cap enforcement).
That confirmation decides whether the table lands as data-only or
needs code, and it is the blocker for every other item above. The
Hegemony loss pairing with synchronized fire is Ryan's call and can
be ruled in parallel, as can the Corsair and Deathless loss choices in
the open-choices list.

## Not checked
- Whether explicit h.cost overrides already exist anywhere that would
  collide with a multiplier field.
- The economy hook, which remains separately scoped and out of this
  draft by design.
- The model badge on the Qwen generating responses beyond the
  run report (selector changed from Qwen3.7-Plus to Qwen3.8-Max
  before sending, Thinking ON, Search OFF).
