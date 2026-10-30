<!-- Chair filing note, Oct 29, 2026: Qwen relics audit leg, run 9:31-9:37 PM CDT, Qwen3.8-Max verified at both gates, single response. Filed verbatim except em dashes, the en dash and the multiplication sign, which are normalized to ASCII hyphens and x per the standing filing rule. -->

# Relics (Salvage) System Audit

## Proof of Reading

The pack documents 12 relics (data.js:188-201). They operate through two effect channels: fx, which are fleet-wide stat modifiers pushed into the same additive list as admiral doctrine and boon fx and summed by sumFx, and run, which are battle- or campaign-level triggers summed separately by runFx. One acquisition path: after an elite win, the player chooses 1 of 2 randomly offered unheld relics (campaign_run.js:410).

Verdict: MOSTLY DISTINCT

## Findings

1. [NOTE] fx-channel relics are additive increments on shared keys, not standalone mechanics. READ. The pack states relic fx objects are "pushed into the SAME list as the admiral's fx and every boon's fx, then summed by sumFx." Five relics (lattice, spore, compass, coils, armourweave) therefore function as flat bonuses on keys (shPct, hullRegen, speed, cdMod, armor) that other systems already modify. They are distinct from each other but not distinct in kind from a boon that grants the same key.

2. [NOTE] Avenge is uncapped; revive is once-per-battle. READ. Avenge triggers "on EVERY player ship destruction (no per-battle cap in this code)." Revive checks !B.reviveUsed, a "per battle" flag. The asymmetry is explicit in the code. INFERRED: in a six-ship fleet losing five ships sequentially, the last survivor accumulates 5 x 15% = 75% healing across the battle, which is a large passive swing with no decision attached.

3. [FIX] Phylactery's base name embeds another faction's identity. READ. The base name is "Eclipse backup frame" and "its Eclipse display name is 'Second Ignition'." Every non-Eclipse faction that lacks a phylactery rename (Hegemony, Chorus, Glasswrights) falls back to a name containing the word "Eclipse," breaking factional voice.

4. [FIX] payRelic removes the last-acquired relic without player choice. READ. "payRelic removes the LAST relic in the list (campaign_run.js:368, splice(RUN.relics.length-1,1)); the player does not choose which." A player who earned a cornerstone relic early can lose it to a late event cost with no agency.

5. [NOTE] The key "cogitator" exists in both RELICS and MODULES. READ. MODULES has "a cogitator key ('Targeting reckoner', +10% crit, cost 75)" while RELICS has cogitator as "Founders' rangefinder." The pack confirms "keep() validation on saves checks relics against RELICS and inventory against MODULES independently."

6. [NOTE] Coils (cdMod) can be a dead pick. INFERRED. The pack gives no exclusion rule beyond lattice for shieldless fleets. A fleet composition with no cooldown-gated abilities receives zero benefit from "ability cooldowns -1 across the fleet," yet the relic can still be offered.

7. [NOTE] Banner (bloodied) is weak in low-kill strategies. INFERRED. Bloodied requires "every enemy ship one of your ships destroys" to grant +15% damage, capped at three stacks. A fleet that wins through attrition, hull regen, or outlasting the enemy without scoring kills never triggers it.

8. [FIX] Eclipse-fleet + phylactery interaction is underspecified. READ. The pack says revive is "Separate from the Eclipse faction reanimate mechanic (:519), which is a hull/faction system with its own conditions." INFERRED: if both can fire on the same destruction event, an Eclipse ship could reanimate via faction, die again, then revive via phylactery-effectively two extra lives. The pack does not state whether reanimate consumes the phylactery's B.reviveUsed flag or vice versa.

9. [NOTE] No decline-for-credits option on the relic step. READ. "No decline-for-credits option on the relic step (boons have one; relics do not)." This is a forced binary (or ternary) choice. Whether it is a defect depends on whether any offer can be actively harmful; given the no-duplicate rule and the narrow useless cases (finding 6, 7), the cost is low.

10. [NOTE] Glasswrights cover only 8 of 12 relic display names. READ. "Glasswrights 8 (no spore, phylactery, compass, or salvage)." Four relics fall back to base names, the largest gap of any faction, and one of those fallbacks is the faction-leaking "Eclipse backup frame" (finding 3).

## Checks

### a. Effect Audit (all 12 relics)

Each relic occupies a unique effect key; no two relics share a key. Distinctness among relics is clean. The concern is distinctness from the rest of the additive fold:

- lattice (shPct), compass (speed), armourweave (armor), spore (hullRegen), coils (cdMod): All five are fx-channel additions to keys that admiral doctrines and boons also populate. They are not smaller or larger copies of a specific named boon (the pack does not enumerate individual boons), but they are mechanically identical in how they apply: a flat additive term on a shared key. INFERRED: any boon that grants, say, shPct +10% makes lattice simply "+15% more of the same number."
- martyr (avenge), phylactery (revive), banner (bloodied): Unique run-channel triggers with no equivalent boon or doctrine key mentioned. Distinct in kind.
- cogitator (firstSure): Unique accuracy-floor mechanic. Distinct.
- ledger (credPct), salvage (salvage), logbook (xpPct): Economy/progression keys. Salvage overlaps thematically with ledger (both produce credits) but through a different mechanism (flat 15 + 8% hull repair vs. percentage multiplier). Distinct enough.

No relic is a strict smaller or larger copy of another relic. The five fx relics are additive copies in method of what boons and doctrines do on the same keys, which is the main distinctness concern.

### b. The Two Revive Systems

READ: phylactery triggers at battle.js:936 via runFx().revive with a B.reviveUsed per-battle flag. Eclipse reanimate is at battle.js:519, described as "a hull/faction system with its own conditions" and explicitly "Separate from" phylactery.

Eclipse fleet holding phylactery: INFERRED. Because the two are coded separately with separate conditions, the most likely behaviour is sequential: the Eclipse reanimate fires first (as a faction/hull mechanic), the ship re-enters, and if it is destroyed again in the same battle, phylactery's revive check fires, setting B.reviveUsed. This yields two extra lives on separate death events. However, the pack does not state whether the Eclipse reanimate itself sets or checks B.reviveUsed, so a double-fire on the same destruction event cannot be ruled out from the pack alone.

Non-Eclipse fleet: The Eclipse reanimate is a faction mechanic and does not apply. Phylactery operates alone, once per battle. No collision.

Non-Eclipse fleet fighting Eclipse enemies: The reanimate is described as applying to the player's own ships ("a player ship's destruction"), so enemy reanimation is a separate question the pack does not address.

### c. Avenge (martyr) - Decision, Snowball, or Perverse Incentive?

READ: "on EVERY player ship destruction (no per-battle cap in this code), every other living non-squadron player ship heals 15% of its max hull."

INFERRED analysis:

- Not a perverse incentive. The destroyed ship is gone. Healing survivors does not offset the loss of a combatant, so a rational player never wants to lose a ship. There is no exploit loop.
- Partially a snowball dampener. In a losing battle, each successive death heals the remaining ships, extending the fight. The last ship standing in a six-ship fleet receives up to 75% cumulative healing. This is a catch-up mechanic that makes total wipes slower.
- Contrast with revive: Revive is gated by B.reviveUsed (once per battle). Avenge has no gate. The design intent appears to be "every loss matters but is softened," yet the uncapped trigger means the softening scales with fleet size and loss count, which the designer may not have tuned for large fleets.
- Verdict: It is a design decision (consolation mechanic) whose uncapped scaling is an unexamined edge case rather than a deliberate snowball. Tag it as a balance risk, not a logic bug.

### d. Offer Fairness

READ: "relicUseful (core.js:239) excludes ONLY lattice for a shieldless fleet."

INFERRED dead or near-dead picks among the other 11:

| Relic | Dead-pick scenario |
|---|---|
| coils (cdMod) | Fleet has no abilities with cooldowns |
| banner (bloodied) | Fleet wins by outlasting, never destroys enemy ships |
| compass (speed) | Possibly always relevant (initiative), but untestable from pack |
| cogitator (firstSure) | Always useful if ships attack; hard to dead-pick |
| spore, armourweave, lattice | Always relevant if hull/armor/shields exist |
| ledger, salvage, logbook | Always relevant (economy/XP) |
| martyr, phylactery | Always relevant (trigger on destruction) |

The two clear candidates for filter extension are coils (no cooldown abilities) and banner (no kill strategy). Whether the filter should grow is a design call: a random offer with occasional weak picks is standard roguelite variance, but a guaranteed-zero pick (coils with no cooldowns) feels worse than a low-value pick. The current filter handles the guaranteed-zero case for shields (lattice) but not for cooldowns.

### e. Acquisition and Loss

- Elite offers 2, boss offers 3: Fine. Standard roguelite escalating reward. READ.
- No decline option on relic step: Acceptable as a design constraint, provided no relic can be actively harmful. Given the no-duplicate rule and the narrow dead-pick cases (check d), the worst case is a low-value forced pick, not a punishing one. The asymmetry with boons (which do allow decline-for-credits) is a consistency note, not a defect. READ.
- payRelic removes the last relic, not a chosen one: This is a real defect. READ: "the player does not choose which." The player has no agency to protect a high-value relic acquired early. INFERRED: because relics are never duplicated and acquisition order is fixed, the "last" relic is the most recently acquired, which the player may value least-but this is coincidence, not design. A player who acquires phylactery early and a minor fx relic late will lose phylactery. The fix is either player choice or removing the first relic (oldest = likely least integrated into current strategy), though even that is a guess. True fix: let the player choose.

### f. Naming Coverage

READ: Coverage ranges from Glasswrights (8/12) to Hullbreakers, Chorus, and Eclipse (11/12). Fallback is to the base name.

- Fallback as a defect: The fallback itself is a reasonable engineering default. The problem is not the fallback mechanism but one specific base name: "Eclipse backup frame" carries the Eclipse faction's name in it. For Hegemony, Chorus, and Glasswrights-who all lack a phylactery rename-the player sees a rival faction's branding on their own relic. READ: "The base name of phylactery is 'Eclipse backup frame' and its Eclipse display name is 'Second Ignition'."
- Flavor opportunity: The Glasswrights' four missing names (spore, phylactery, compass, salvage) and Hegemony's two (phylactery, spore) are gaps where faction-specific flavor text could deepen identity. This is a content opportunity, not a code defect.
- Verdict: Fallback is fine as a mechanism; the phylactery base name is a flavor defect for 3+ factions.

### g. Cogitator Key Collision (RELICS vs MODULES)

READ: "MODULES (data.js:166) also has a cogitator key ('Targeting reckoner', +10% crit, cost 75)." The two are in "separate objects." Save validation: "keep() validation on saves checks relics against RELICS and inventory against MODULES independently (core.js:81)."

INFERRED: No confusion path is evident from the pack. Save validation checks each table independently. Display names differ ("Founders' rangefinder" vs "Targeting reckoner"). Per-faction display names exist for both tables separately. The internal key "cogitator" is shared, but because the two objects are structurally separate (RELICS vs MODULES), any lookup is scoped to its parent table.

What would settle it: Inspect any code path that searches for a key string (e.g., a generic hasItem("cogitator") or a UI tooltip lookup) without specifying whether it queries RELICS or MODULES. The pack does not enumerate all consumers of the key string. A grep for bare "cogitator" across the codebase would confirm or deny a collision.

## Not Checked

The pack does not permit verification of the following:

1. Individual boon and admiral doctrine effect lists. The pack confirms additive folding on shared fx keys but does not enumerate which boons or doctrines populate shPct, speed, armor, hullRegen, or cdMod, so overlap magnitude cannot be quantified.
2. Eclipse reanimate's exact trigger conditions. The pack references battle.js:519 and "its own conditions" but does not state them, so the phylactery interaction (check b) remains partially unresolved.
3. Whether any code path queries the string "cogitator" without table scoping. The pack describes validation and display but not all runtime lookups.
4. Squadron interaction with avenge. Avenge heals "every other living non-squadron player ship." The pack does not define what squadrons are or whether their exclusion is intentional or incidental.
5. META salvagers unlock interaction with ledger. The pack notes "META salvagers unlock adds credPct +.2 on top" but does not specify whether this stacks multiplicatively or additively with the ledger's +.25.
6. Whether the firstSure 95% floor interacts with any hit-chance cap or evasion mechanic. The pack mentions "75 when surging" but not the broader accuracy system.
7. UI rendering of relic vs module if both are named "cogitator" internally. Display names differ, but tooltip or log code is not covered.

## Designer Questions

1. Should avenge have a per-battle cap like revive? Stakes: uncapped healing in large-fleet losses can make endgame battles feel interminable and undercut the tension of ship death.
2. Should payRelic let the player choose which relic to sacrifice, or at minimum remove the first-acquired relic? Stakes: the current last-in-first-out splice can silently destroy a run-defining relic the player earned several nodes ago, with no recourse and no warning.
3. Should the relicUseful filter extend beyond lattice to exclude coils for fleets with no cooldown abilities and banner for fleets with no kill-based win condition? Stakes: a guaranteed-zero-value forced pick in a no-decline offer feels like a bug to the player, even if it is technically valid, and erodes trust in the offer system.
