Chair note: filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed), except em dashes, en dashes, and unicode minus signs in the model's text are normalized to hyphens.

# MODULES AND FITTING AUDIT - BLIND REVIEW

## 1 · PROOF OF READING

Sections read from the pack:

1. EVIDENCE PACK title line - "modules and fitting audit (code slices from the shipped browser build, main 264f441d…)"
2. THE COMMISSIONER'S QUESTION - the five-point audit brief.
3. CHAIR CENSUS - 13 modules, slot derivation, free refit movement, FIT_SLOTS reserve, doctrine/admiral standing rule.
4. WHAT TO JUDGE - five numbered questions.
5. Code slices - data.js 153-203 (MODULES, PERKS, RANKS, RELICS), data.js 545-548 (slot derivation line), data.js 570-586 (variant hydration, FIT_SLOTS schema, FAC_WPOOL).

Overall verdict: MOSTLY DISTINCT.

The thirteen modules mostly hold separate jobs, but free refit movement and a coarse slot ladder prevent any of them from becoming a build; they remain loadout seasoning rather than identity.

## 2 · FINDINGS (ranked most severe first)

### F-1 [BLOCKER] - Free refit movement collapses the module layer into a pre-battle checklist

READ. The census states "Refits can be moved between ships freely." No cost, no cooldown, no lock is mentioned anywhere in the pack. INFERRED. If a player can reshuffle all modules across the fleet between every engagement, the question "what does this ship do?" is answered seconds before combat, not during the run. Modules become a sorting problem, not a design decision. The commissioner asks whether modules create builds; under free movement they cannot, because no ship keeps a module long enough for it to define that ship.

### F-2 [BLOCKER] - Five admiral perks duplicate five module effects verbatim

READ. PERKS in data.js 153-203: gunnery "+10 aim" mirrors auspex "+10 aim"; killer "+10% critical chance" mirrors cogitator "+10% critical chance"; ironhull "+15% max hull" mirrors prow "+15% hull"; helm "+1 speed" mirrors drive "+1 speed"; deflector "+40% shield regeneration" overlaps regen "+50% shield regeneration." The census records a standing rule: "tree skills may not duplicate doctrine effects." INFERRED. The constitution is silent on modules, but the spirit of that rule is that two progression layers should not sell the same number. A player stacking ironhull + prow gets +30 % hull from two systems that feel identical; that is stat confetti by another pipeline. The module layer's identity is diluted before the player even installs anything.

### F-3 [FIX] - The slot ladder (1 / 2 / 3) is too coarse to create a real economy

READ. "1 slot at cp 1-2, 2 at cp 3-4, 3 at cp 5 and above." INFERRED. A cp-1 frigate and a cp-2 frigate both get one slot; a cp-4 cruiser and a cp-3 destroyer both get two. There is no intermediate step, no way to earn a second slot on a small hull or trade something for a third on a large one. The ladder is three rungs for presumably a dozen-plus hulls. Frigates are locked to a single binary choice ("which one module?") while cp-5+ hulls pick three from thirteen, a combinatorial gap of 13 vs 286. Small hulls are not just poorer; they are effectively excluded from the customization system.

### F-4 [FIX] - Generic stat modules (prow, drive, gyro, capacitor, regen, damcon, cogitator, auspex) are "correct everywhere" and therefore create no build tension

READ. prow "+15% hull, +5% armor" and auspex "+10 aim for every weapon" carry no weapon-type, hull-class, or role restriction. INFERRED. A +15 %-hull module is never wrong on any ship. A +10-aim module is never wrong on any ship that fires weapons. When a module is universally correct, it does not create a decision; it creates a tax. On a one-slot frigate the tax is invisible (you just pick the best stat). On a three-slot flagship it means two of three slots default to prow and auspex and only the third slot is a real choice. The system's design space shrinks to (13 choose 1) effective options instead of 13.

### F-5 [FIX] - Weapon-type modules (loaders, crystal, magazine, flakplus) are strong in concept but their conditional value is invisible to the player at install time

READ. loaders "Battery weapons fire +1 shot" cost 90; crystal "Lance damage +25%" cost 80; magazine "Torpedo reload time -1 turn, +15% torpedo damage" cost 85; flakplus "Point defense +2 shots and +1 range" cost 55. INFERRED. These modules are only valuable if the host ship mounts the matching weapon. The pack shows no UI or cost adjustment for installing a battery module on a lance boat. A player who installs loaders on a ship with no battery guns gets a 90-credit paperweight. Because refits move freely (F-1), the player will eventually notice, but the initial install is a trap. The modules should be the build-defining layer, but nothing in the pack enforces or telegraphs the weapon-module pairing.

### F-6 [FIX] - Hangar expansion is the only class-locked module and its lock is soft

READ. hangar carries "only:'launch'" in its data entry. Cost 90. INFERRED. This is the single module that says "you must be a carrier." It is a good instinct, but it is the only module with a hard gate. If the design goal is modules-as-build, more modules need analogous gates (e.g., a module that only works on ships with armor above a threshold, or only on ships with a spinal weapon). One lock out of thirteen is a token, not a system.

### F-7 [NOTE] - FIT_SLOTS reserve collides with the existing module layer on the flagship

READ. FIT_SLOTS defines "one module slot (flagship only)." The flagship already receives modules through the normal cp-based slot derivation (3 slots at cp 5+). INFERRED. The reserve adds a fourth module slot to the flagship and a weapon pod that bypasses the normal weapon loadout. The collision is direct: a cp-5 flagship would carry three standard modules plus one fit module plus a pod weapon. The fit module pool is presumably the same MODULES table, so the flagship gets four picks from thirteen while a frigate gets one. The flagship becomes the only real build platform and the rest of the fleet becomes a stat block. The reserve should either borrow from a separate module pool or replace one of the three standard slots rather than adding to them.

### F-8 [NOTE] - Cost spread (55-90 credits) is narrow relative to the effect spread

READ. flakplus costs 55; loaders costs 90. The range is 35 credits across thirteen modules. INFERRED. A +1 speed module (drive, 75) and a +50 % shield-regen module (regen, 70) are within 5 credits of each other, yet their strategic impact is wildly different depending on fleet composition. The cost axis is too flat to act as a real tuning lever. Either widen the range or tie cost to slot tier so that expensive modules require cp-5+ hulls, giving the slot ladder a second dimension.

### F-9 [NOTE] - Capture/salvage pipeline feeds modules but the pack does not show player agency in the result

READ. The census says "strip a captured ship and its weapons decide the refit, per the capture code audited in the economy pack." INFERRED. If the captured ship's weapon list determines which refit you get, the player has no choice in the matter. Combined with free movement (F-1), modules arrive semi-randomly and can be shuffled anywhere. The acquisition layer and the equip layer are both low-agency, which compounds the checklist problem.

### F-10 [NOTE] - Doctrine / admiral / module boundary is undefined

READ. "Where modules sit in that constitution is undefined" (census, final bullet). INFERRED. Without a stated rule, the designer will face duplicate-effect pressure every time a new module or perk is added (see F-2 for five existing collisions). The constitution needs an explicit clause: modules own ship-scale numbers; perks own admiral-scale numbers; doctrine owns fleet-scale numbers. Until that clause exists, overlap is a feature-request magnet, not a bug.

## 3 · EXPLICIT CHECKS

### MODULE IDENTITY

| # | id | One-line job |
|---|---|---|
| 1 | prow | Bulk up hull HP and armor; the generic survivability slot. |
| 2 | auspex | Raise hit chance fleet-wide on the host ship; the generic accuracy slot. |
| 3 | drive | Add one hex of speed; the positioning/mobility slot. |
| 4 | gyro | Add one turn allowance and a small evasion bump; the maneuverability slot. |
| 5 | capacitor | Increase shield capacity by 30 %; the shield-tank slot. |
| 6 | regen | Increase shield regeneration by 50 %; the shield-sustain slot. |
| 7 | loaders | Give battery weapons one extra shot; the battery-DPS slot. |
| 8 | crystal | Boost lance damage by 25 %; the lance-DPS slot. |
| 9 | magazine | Cut torpedo cooldown by 1 and add 15 % damage; the torpedo-DPS slot. |
| 10 | flakplus | Add two PD shots and one range to point defense; the PD/anti-fighter slot. |
| 11 | damcon | Repair 4 % hull each turn; the attrition/heal slot. |
| 12 | hangar | Carriers only: launch one extra squadron; the carrier-power slot. |
| 13 | cogitator | Add 10 % critical chance; the burst-damage slot. |

Duplicates of job at different prices: capacitor (80 cr, shield tank) and regen (70 cr, shield sustain) are both "shield module" but address different stats (capacity vs regen rate), so they are adjacent, not true duplicates. The real duplicates are across systems: auspex ≈ gunnery perk (both +10 aim); cogitator ≈ killer perk (both +10 % crit); drive ≈ helm perk (both +1 speed); prow ≈ ironhull perk (both +15 % hull). Within the MODULES table itself, no two entries share an identical job, but prow and damcon both serve "keep the ship alive longer" and would compete for the same "survivability" mental slot on a one-slot frigate.

### STRICT TAKES AND DEAD SLOTS

Strict take (correct on every ship that can hold it): prow (+15 % hull, +5 % armor, 70 cr). Every ship in the game has hull and armor. There is no build in which +15 % HP is wrong. On a one-slot frigate, prow is the default and the only rational pick unless the player has a specific weapon-module match. auspex is a close second: every ship fires at least one weapon, and +10 aim is universally valuable. Neither module has a conditional, a class gate, or a trade-off. They are correct at every price, on every hull, in every fleet composition.

Dead slot (never worth installing at any price): INFERRED - no module is strictly dead, but loaders (90 cr, "Battery weapons fire +1 shot") is the closest. If the host ship mounts zero battery weapons, the module does literally nothing and there is no in-pack mechanism to warn the player. It is not globally dead because battery ships exist, but on any non-battery ship it is a 90-credit blank. The same conditional risk applies to crystal, magazine, and flakplus, but loaders has the highest cost and the narrowest weapon-type match, making it the most likely mis-install.

Defence from the numbers: prow's +15 % hull at 70 cr beats ironhull perk's identical +15 % hull for "free" (perk costs no credits but consumes a perk pick); a ship with both gets +30 % hull, which is a 30 % effective HP increase from two systems that feel like one. loaders at 90 cr is the most expensive module in the table and does nothing unless the weapon loadout cooperates, a condition the pack does not surface at install time.

### SLOT ECONOMY

The ladder is: 1 slot (cp 1-2) → 2 slots (cp 3-4) → 3 slots (cp 5+).

INFERRED assessment: The ladder is three rungs for the entire hull roster. A cp-1 scout and a cp-2 frigate get the same single slot; the player's entire customization decision is "pick one of thirteen." A cp-5 battleship picks three, giving 286 unordered combinations. The combinatorial gap (13 vs 286) means frigates and destroyers are effectively locked out of the customization system. They have a slot, but one slot is not a build; it is a single toggle. The real build platforms are cp-5+ hulls, and if the flagship reserve (F-7) adds a fourth slot, the flagship becomes the only platform with meaningful combinatorial depth.

Frigates are not just poor; they are irrelevant to the module system as a design space. A player running a wolfpack of frigates has zero interesting module decisions. That may be intentional (frigates are disposable), but if so the game should say so and stop calling module slots a feature of every hull.

### FREE REFIT MOVEMENT

READ. "Refits can be moved between ships freely."

INFERRED. If modules can be reshuffled at will between battles (or even within the fleet screen before each engagement), the decision the player faces is not "what is this ship's build?" but "which three modules do I assign to my flagship right now?" The module layer becomes a pre-battle checklist, not a build system. The distinction matters:

- A build system asks: "Given that I chose the lance crystal for this cruiser three sectors ago, how do I play around its identity?"
- A pre-battle checklist asks: "I have thirteen modules; which three go on the ship that will see combat next?"

The first creates attachment, planning, and trade-offs. The second creates a spreadsheet. For a roguelite fleet-tactics game where ships are acquired, captured, and lost, some degree of module portability is healthy (it prevents a dead module on a dead ship). But free movement with no cost, no cooldown, and no lock removes the only friction that would force a decision. The pack shows no such friction.

Which should it be? For this game - a roguelite where fleet composition shifts every run - modules should lean toward build system with moderate portability. A small credit cost to move a refit, or a one-battle cooldown after removal, would preserve the decision without punishing the player for losing a ship. Free movement as shipped makes the layer decorative.

### THE FLAGSHIP RESERVE

READ. FIT_SLOTS: "pod: one swappable weapon pod (flagship only; its spinal weapon stays), module: one module slot (flagship only), trim: one of four zero-sum section trims (flagship only)." Schema only; nothing reads it for rules yet.

Where the two systems collide:

1. Module slot stacking. A cp-5 flagship already gets 3 standard module slots. The reserve adds a 4th, flagship-only module slot drawn from the same MODULES table. The flagship now picks 4-of-13 while a frigate picks 1-of-13. The reserve widens the build-platform gap identified in the slot-economy check. The flagship becomes the only ship with a real build; everything else is a stat block with one bonus.
2. Pod vs. weapon loadout. The pod lets the flagship swap a weapon without changing hull. But the existing capture/salvage system already lets the player acquire ships with different weapon loadouts. If the pod is drawn from FAC_WPOOL (the faction weapon pool), it effectively gives the flagship access to every faction weapon without capturing ships, undermining the capture pipeline as the source of weapon variety.
3. Trim vs. variants. HULL_VARIANTS already provide authored hull variants with different weapons, mods, and stats (e.g., i_carrier_a trades shields and speed for a third wing). The trim system ("zero-sum section trims") risks becoming a lighter, less interesting version of variants. If a trim can shift armor-to-speed, that is a micro-variant; the player now has two variant systems (authored hull variants + trims) operating at different granularities on the same ship.

What the reserve should borrow or avoid:

- Borrow the variant system's philosophy of authored, named trade-offs rather than free-form stat sliders. If the four trims are hand-authored like variants, they feel like design choices; if they are generic ±5 % sliders, they feel like stat confetti.
- Avoid adding the module slot on top of the standard three. Either the flagship's reserve module replaces one standard slot (keeping the total at 3 but making one slot flagship-exclusive with a separate pool) or the reserve draws from a separate flagship-only module pool so it does not compete with the 13 fleet modules.
- Avoid letting the pod bypass the capture/salvage pipeline. If pods are freely swappable, the incentive to capture ships for their weapons evaporates.

## 4 · NOT CHECKED

This pack does not let me judge:

- Actual hull roster and cp distribution. I can see the derivation formula but not how many hulls sit at cp 1, 2, 3, 4, 5+. The slot-economy finding is therefore structural, not census-level.
- The capture/salvage code itself. The census references "the capture code audited in the economy pack," but that code is not in this pack. I cannot verify how weapon-to-refit mapping works or whether the player has any choice.
- Balance of the numbers in combat. +10 aim, +15 % hull, +1 speed - whether these are meaningful or negligible depends on base stats, weapon damage curves, and battle length, none of which are in this pack.
- The four trims. FIT_SLOTS says "one of four zero-sum section trims" but does not name or define them. I cannot assess whether they are interesting.
- The Godot port. The title line says "the Godot port mirrors this design," but no port code is in the pack. I assume parity but cannot verify it.
- Doctrine (renown) effects. The standing rule mentions doctrine but no doctrine table is in this pack, so I cannot check module-vs-doctrine overlap.
- UI / player-facing presentation. Whether the game warns a player before installing loaders on a ship with no battery weapons is a UX question the code pack does not answer.

## 5 · QUESTIONS FOR THE DESIGNER

1. Is the module layer meant to define a ship's role across a run, or to be optimised fresh before each battle? The free-movement rule and the 13-module pool currently answer "fresh each battle." If the answer is "across a run," movement needs friction; if "fresh each battle," the slot ladder and module costs need to support rapid re-planning without becoming a spreadsheet. Stakes: getting this wrong means the module system is either a chore (spreadsheet) or a fiction (no attachment), and the flagship reserve will inherit whichever failure mode you ship.
2. Should the five perk-module duplicates (aim, crit, speed, hull, shield regen) be resolved by removing the module versions, the perk versions, or by splitting the numbers so each layer owns a different magnitude? The constitution bans perk-doctrine duplication but is silent on modules. Stakes: leaving the overlap in place means every future module or perk risks a silent collision, and the player perceives the systems as one undifferentiated stat stream rather than three distinct progression axes.
3. Is the FIT_SLOTS reserve intended to make the flagship a separate game from the fleet, or to make it the most customisable ship in the same game? A flagship with pod + module + trim + 3 standard slots is playing a different game from a frigate with 1 slot. Stakes: if the flagship is a separate game, the fleet module system becomes vestigial for every non-flagship hull; if it is the same game, the reserve must borrow from the same design space without outclassing it, and the four trims need to be as interesting as a full hull variant to justify existing alongside them.

End of report. All claims marked READ are drawn directly from the pack text; all claims marked INFERRED are reasoning from that text. No systems outside the pack were invoked.
