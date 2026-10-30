# Boons and counsel audit - synthesis (Oct 29 program)

Four prongs: DeepSeek DUPLICATES WITH PAINT, Argon DUPLICATES WITH PAINT, Rey (chair leg, code-first) DUPLICATES WITH PAINT, Qwen MOSTLY DISTINCT.

## Verdict: DUPLICATES WITH PAINT (3 of 4; Qwen's split is calibration)

Qwen counts 20 distinct jobs and 42 of 48 boons clean. The other three prongs count fewer jobs (DeepSeek 18, Argon 15) and price the overlaps as the story. Nobody disputes the pool map's shape: six patrons with readable silhouettes, a rule-changing boon and a legendary each, six duos, and a normal tier where the duplication lives.

## The mechanism is now fully priced (chair, from code)

Three answers the evidence pack did not contain, all verified at the pin:

1. Aggregation is purely additive. One function folds relics, the admiral, and every boon into a single effect object by adding numbers; no caps, no overwrites. So the pool's duplicates do not cannibalize each other; they stack. This downgrades the scariest form of two findings (see below) from dead picks to value defects, and it means the duplication problem is about what a slot buys, not whether it works.
2. The rarity roll is exact: Common m=1, Rare m=1.5, Epic m=2, Legendary flat. At sector 1 with no favour, an offer rolls 70% Common, 24% Rare, 6% Epic; favour adds to the rare and epic chances and floors at Rare from tier 3. Duos always enter at m=1.
3. BOON_NEED has now produced one verified defect of each kind: a missing gate (L_storm is absent from the table, so a shieldless fleet holding two ungated storm boons can be offered Eye of the Storm, a full shield refill for ships with no shields; Argon, chair verified) and a near-miss gate (h_feast's 'sq' gate derives from the same hangar fact its payoff needs, so DeepSeek's wrong-gate catch downgrades to a note; chair Rey leg).

## Findings that stand

1. The ram block is one job sold three times (Argon, Qwen's BLOCKER, DeepSeek in substance). r_prow, d_jugg, and L_rook share the ramPct/ramCap/ramGuard keys. With additive stacking they pile into a single build path with three checkpoints instead of branching (splash, chain-ram, momentum are Qwen's suggested directions). Qwen's stricter claim, that each strictly dominates the last, does not survive the numbers: at epic rarity the basic prow boon's ram percentage (0.70) exceeds the legendary's flat 0.50 on that key, though the legendary still leads on cap and guard. Carry the job collapse, not the dominance ladder.
2. The legendary explosion duplicates the epic (Argon, Qwen). Pyre of Stars is a flat 40 chain explosion; an epic Chain Reaction already gives 40 plus burning. Additively they stack to 80, so the legendary is not a no-op; it is the same effect bought a second time at the legendary slot, the pool's most expensive real estate.
3. The generic stat trio dilutes both identity and spillover (Qwen, its best section). s_ev, a_aim, and i_plate are the weakest boons in their own patrons' slices and the most likely off-patron offerings, which loads the spillover problem below.
4. Strict takes converge across legs: Unbreakable and the iron legendary family, Chain Reaction, Killing Light, and Qwen adds r_slip (move after firing, the pool's only activation-order change) and i_wall. Dead and weak picks converge too: s_ion, h_chitin, e_kindle, i_plate appear on multiple lists.
5. h_board's description promises failed-boarding sabotage its effect never emits in the sliced data (Argon); whether boarding resolution implements it elsewhere is an Opus check.
6. Duo coverage is thin where it matters (Argon): six duos over fifteen patron pairs, Iron in three, Hunger in one, so four of Hunger's five off-patron directions can never bridge to a duo. Duos also only surface once both patrons are held, and always at m=1 (chair).

## The spillover ruling (Oct 28 Q7) against the shipped code

Ryan ruled on Oct 28: off-patron offers stay, but off-patron picks must retain real value; the hidden rarity tax on fillers is the defect. The shipped offer code (read by the chair for this synthesis) violates that ruling twice over. First, structurally: an offer is built from the patron's own useful pool first, and off-patron boons backfill only when that pool runs short, so an off-patron pick can never compete head-to-head with a full on-patron offer. Second, numerically: backfill picks roll their rarity without the patron argument, so they get no favour bonus and no Rare floor; they are systematically weaker rolls of whatever they are. Qwen, which could not see the offer code and said so honestly, still located the symptom: the fillers that do leak through are the weakest universal-stat boons, so the surviving spillover value is real but capped at the pool's floor.

This is not a new designer question. It is an existing ruling the code does not implement, and the fix shapes are implementation choices for Opus: let off-patron picks compete in the main pool, and roll them with the same favour treatment.

## Chair corrections applied

Argon's a_long dead-tier claim is an arithmetic error (floor(2.25) is 2, not 1) and is not carried. Its L_storm "exact duplicate" overstates magnitude; the defect is the missing gate and the wasted prerequisite, per the mechanism section. DeepSeek's m assumption was INFERRED in its leg and is now confirmed with numbers.

## Designer questions

None new. Q7's implementation is Opus's work under an existing ruling.
