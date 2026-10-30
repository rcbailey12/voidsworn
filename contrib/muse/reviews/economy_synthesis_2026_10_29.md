# In-run economy audit - synthesis (Oct 29 program)

Four prongs: Qwen MIXED, Argon MIXED, DeepSeek MIXED, Rey (blind) MIXED. Unanimous.

## Verdict: MIXED (4 of 4), with one blocker all four prongs share

Prices are honest, capture math is sound, and the credit pinch is real but brief. The economy's failure is concentrated in one place: repair is priced so far below every alternative that the post-boss regroup Ryan ruled for on Oct 28 cannot happen.

## The blocker: paid repair cannot carry the Q11 regroup ruling

Ryan's Oct 28 Q11 ruling: after a boss, the player regroups by choosing among repair, upgrade, or buying ships, at real cost. The shipped numbers make the choice a formality (4 of 4 legs; chair confirmed and strengthened):

- Paid repair costs half the missing hull in credits. The real mid-game cruiser (hp 120, cost 200) cures a half-hull for 30 credits, 15% of replacement. DeepSeek's hypothetical and Argon's proof agree with Qwen's real-hull arithmetic: repair from 1 HP is still cheaper than net replacement at every damage level, so replacement is never the right answer on credits.
- Free healing pre-empts the decision anyway: winning any battle patches every survivor 15% of max hull free, the post-boss transit patches 40% free, drydock nodes repair the whole fleet free, and field repair nodes patch 20% free. The regroup choice competes with several free versions of itself.
- The repair modifiers never reach the paid price (chair, resolving Argon's headline): repairMult is live code at four call sites, all scaling FREE repair amounts, and ported to Godot; the shipyard's paid price (missing/2 x priceMult) never passes through it. The pointed consequence: the h_repair Heat condition at 0.5 halves free healing, functioning as a penalty where a discount was presumably intended. Whether the paid price SHOULD carry the repair modifiers is the one designer question below.

## The flow trace (chair, from code the pack omitted)

The pack carried prices but not income (chair pack defect, owned in the Qwen screening). The full circuit: starting credits 120. Node rewards pay no credits for elites or bosses (always a boon); normal battles pay a boon 62%, a module 16%, a credit node 12%, repairs 10%. Credit income actually arrives through battle salvage and prize money, event rewards (+30 to +80, with a relic fallback at +80), capture (ransom 55% of value decaying per capture, scrap 35%), the Corsair prize bonus (+20), and sector-condition bonuses on battle pay (wreck +15%, war +20%, scarce +25%). The Rey leg's shape verdict on the result: the pinch is sector 1 only; from the sector 2 yard onward, shopping replaces scarcity, and credits stop being a decision.

## Findings that stand

1. Price spread is wide and mostly honest: 45 credits per CP (Chorus frigate) to 100 (Eclipse frigate; Rey), per-HP 0.98 to 3.22 with Ithar highest (about a third of that honestly shields and evasion). Qwen's 2.38x spread direction and ranking hold; its per-CP figures ran about 10% low against the explicit cost table (65-70 per CP, not a flat 60). DeepSeek's 2.23x figure is an internal slip against its own table and is not carried.
2. The Chorus carrier at 370 is the most expensive carrier in the game (Rey), an odd place for the swarm discount to vanish; small-class Chorus is discounted, the capstone is not.
3. The capture triangle flips as designed: ransom beats strip early (about 66 vs about 43 on a first capture at full hull) and strip catches up as the decay factor (floored at 0.4, binding from about the sixth capture) erodes ransom. Add-when-room beats both when CP fits (3 of 4 legs), and add-then-decommission at a flat 35% can beat a late-decay ransom (Argon). Decommission pays the same 35% regardless of ship condition (Qwen, chair verified).
4. Prize valuation ignores priceMult (Argon): ransom and strip are denominated in base ship value while shop prices scale, so under the coffers Heat condition capture income loses about 20% of its purchasing power, and under the wrights discount it gains. Class track costs are gated by priceMult but not FAC_PRICE (Qwen, DeepSeek), so faction price identity stops at hull purchases.
5. Stacking is bounded in shipped data despite being uncapped in code (chair, correcting Qwen's finding 6): sector conditions carry exactly one price field (scarce at 1.2), so the real stack range is 0.85 to about 1.275, or 1.5 without the wrights discount. No downward condition exists.

## Chair corrections applied

Argon's "repairMult is dead code" BLOCKER is false as stated and is replaced by the narrower truth in the blocker section above. Its "add contradicts the census" finding was a chair census wording defect (the pack compressed two Oct 24 capture rulings); add is legal and ruled, and the code matches. Eclipse's rising class prices are NOT a defect: elite attrition is the ruled faction identity (Oct 24), and mild escalation expresses it (chair, against Qwen's finding 3 framing).

## Designer questions

One, for Ryan, in the program report: repair intent. Should the paid repair price carry the repair modifiers (making h_repair a real discount and sector repair conditions meaningful at the yard), or should the base rate rise so the Q11 tradeoff exists without the modifiers, or both? The stakes are the regroup ruling itself; the legs agree the current 0.5-per-hull rate cannot carry it under any modifier story.

## Addendum: designer's clarification (Ryan, Oct 29, 2026, evening) - the blocker is reframed

Ryan corrected the premise the legs (and this synthesis) used. Repair should ALWAYS be better than scrapping a ship and buying new; replacement never being right on a per-ship basis is the intended design, not a defect, and Argon's proof of it is a proof that the system works as meant. The tradeoff his Oct 28 Q11 ruling actually intends is a budget allocation under scarcity: with limited credits in hand, do you repair the damaged ship, or spend the same credits on a new ship and sail on with a vulnerable unrepaired one? His illustration (numbers his, explicitly illustrative): repair at 50 with 100 in hand and keep the change, or spend the full 100 on a new ship and accept the risk.

The blocker therefore restates, narrower and still real: the intended budget tension rarely binds at current numbers, because repair is cheap relative to both income and hull prices (30 credits cures half of a 200 credit cruiser), and free healing (15% after every win, 40% after a boss, free repair nodes) shrinks the paid decision further. The lever for Opus is the repair rate relative to income and ship prices, tuned until the repair-versus-new-ship spend actually competes for the same credits at the regroup beat, while repair stays strictly better than scrap-and-replace for any single hull. The modifier-routing question (whether the paid price should pass through repairMult) is demoted to an implementation detail under that tuning goal, not a design decision.
