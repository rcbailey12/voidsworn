Chair note: filed verbatim from the DeepSeek run of Oct 29, 2026 (DeepThink and Search on, toggles verified), except em dashes and en dashes in the model's text are normalized to hyphens.

1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; data.js 153-203: MODULES plus adjacent PERKS/RELICS/RANKS; data.js 545-548: hull cost and slot derivation; data.js 570-586: variant hydration and the FIT_SLOTS reserve.

Overall verdict: MOSTLY DISTINCT - the 13 modules cover mostly distinct stat/weapon niches, but free refit movement and the 1/2/3 slot ladder flatten them into a per-battle loadout checklist rather than builds.

2. Findings

1. [BLOCKER] Free refit movement collapses build commitment.
READ: "Refits can be moved between ships freely"; modules arrive through rewards and salvage.
INFERRED: Once owned, a module can be reassigned per battle; no hull commits to a fit. The remaining decision is inventory count and current assignment, which is a pre-battle checklist, not a build system. Quote: "Refits can be moved between ships freely."

2. [BLOCKER] The flagship reserve is pointed at a parallel module/weapon/trim layer, not a distinct flagship layer.
READ: FIT_SLOTS reserves "one module slot (flagship only)", a "swappable weapon pod", and one trim; it is "schema only, nothing reads it for rules yet"; every hull already has 1-3 module slots; HULL_VARIANTS already change weapons and stats.
INFERRED: A flagship module slot on top of normal hull slots either stacks as an extra slot or duplicates normal slots. The pod overlaps variant weapon arrays and FAC_WPOOL; the trim overlaps variant mods such as {hangar:3,sh:22,sp:3}. Quote: "one module slot (flagship only)" and "schema only, nothing reads it".

3. [FIX] The slot ladder makes cp5+ the only real build platforms.
READ: "1 slot at cp 1-2, 2 at cp 3-4, 3 at cp 5 and above"; hull cost formula is Math.round((60*cp+10)/5)*5; modules cost 55-90.
INFERRED: Arithmetic gives cp1 hull cost 70, cp3 190, cp5 310. A one-slot frigate can take one module but cannot combine synergies; a cp1 hull plus an 80-credit module costs more than the hull. Frigates are not locked out of customization, but they are locked out of builds. Quote: "1 slot at cp 1-2".

4. [FIX] Scanner array is the nearest strict take.
READ: Auspex gives "+10 aim for every weapon" at cost 80.
INFERRED: On any hull with a weapon, it improves every attack; unless the hull is a carrier where hangar adds a squadron, or a dedicated torpedo/lance platform where the family module is better, auspex is the default. It is not literally strict because those specialist cases exist, but it compresses generic ships toward one pick. Quote: "+10 aim for every weapon."

5. [NOTE] Overlapping jobs exist, but no exact duplicate at different prices.
READ: Capacitor gives "+30% shield strength"; regen gives "+50% shield regeneration"; prow gives "+15% hull, +5% armor"; damcon repairs "4% hull"; auspex gives "+10 aim"; cogitator gives "+10% critical chance"; loaders/crystal/magazine are battery/lance/torpedo-specific.
INFERRED: These are different axes - shield pool vs recovery, burst hull vs sustain, hit vs crit, weapon family - so no pair is the same job at different prices. Quote: "+30% shield strength" vs "+50% shield regeneration."

6. [FIX] Weapon/PD modules are conditional and become dead slots without filtering.
READ: Only hangar has only:'launch'; loaders says "Battery weapons", crystal says "Lance", magazine says "Torpedo", flakplus says "Point defense".
INFERRED: On a hull without the relevant weapon or PD, those effects are worth zero. Free movement lets the player avoid the mistake, but the refit UI/rules must filter or mark compatibility or these are traps. Quote: "Battery weapons fire +1 shot."

7. [NOTE] The price band is too tight for the effect spread.
READ: Costs run from flakplus 55 to hangar 90; prow/regen 70, auspex/capacitor/crystal 80, magazine/damcon 85, loaders/hangar 90.
INFERRED: Slot opportunity and hull compatibility dominate credit cost; 55-90 credits does not meaningfully price the difference between "+1 speed" and "+1 squadron in flight." Quote: "+1 squadron in flight."

8. [NOTE] No module is globally dead; the dead cases are conditional.
READ: Flakplus is cheapest at 55 with PD volume/range; gyro gives turn+evasion at 60; damcon gives 4% hull/turn at 85; hangar gives +1 squadron at 90 on carriers.
INFERRED: Every module has at least one hull/weapon context where its effect is live. "Never worth its slot at any price" is false globally; only incompatible installations are dead. Quote: "Repair 4% hull".

9. [NOTE] The reserve is still cheap to change because nothing reads it.
READ: "schema only, nothing reads it for rules yet"; FIT_SLOTS is data.
INFERRED: There is no live collision yet; the design can still integrate the flagship layer into normal slots and variant rules before it ships. Quote: "nothing reads it for rules yet."

3. Explicit checks

1. MODULE IDENTITY

Reinforced prow - raw hull/armor buffer; defensive stat stick for any ship.

Scanner array - universal accuracy booster for every weapon.

Plasma drive - flat speed/mobility increase.

Gyro-stabilisers - maneuverability via turn allowance plus evasion.

Screen capacitor - increases shield pool strength.

Shield regenerator - increases shield recovery rate.

Battery loaders - battery-specific rate of fire, +1 shot.

Lance focusing crystal - lance-specific damage multiplier.

Torpedo magazine - torpedo-specific reload/damage improvement.

Flak batteries - point-defense volume and range.

Damage control crews - hull sustain over time.

Hangar expansion - carrier-only squadron capacity.

Targeting reckoner - critical chance increase.

Duplicate flag: no exact duplicate job at different prices. Closest overlaps are capacitor/regen (shield pool vs recovery), prow/damcon (burst hull/armor vs regen), auspex/cogitator (aim vs crit), and loaders/crystal/magazine (weapon-family-specific offense). They are not the same job because they act on different axes or weapon families.

2. STRICT TAKES AND DEAD SLOTS

Strict take: none literally, but Scanner array is the nearest. It gives "+10 aim for every weapon" at 80 credits; on any weapons-carrying hull it improves every attack. It is not strictly correct on every ship because a carrier can prefer hangar's "+1 squadron in flight" and a dedicated torpedo/lance ship can prefer its family module. But on generic gun hulls it is the default pick.

Dead slot: none globally. The dead cases are conditional: loaders on a no-battery hull, crystal on a no-lance hull, magazine on a no-torpedo hull, and flakplus on a no-PD hull are worth zero. Hangar is explicitly carrier-only via only:'launch'. Because refits move freely, those are compatibility traps rather than permanently dead modules; the fix is filtering, not deleting the modules.

3. SLOT ECONOMY

The ladder is steep: cp1-2 gets one slot, cp3-4 gets two, cp5+ gets three. The hull cost formula makes cp1 cost 70, cp3 cost 190, and cp5 cost 310, while modules cost 55-90. That means a one-slot frigate can afford one module, but it cannot combine modules into a build; a cp1 hull with an 80-credit module is paying more than its hull cost. The real build platforms are cp5+ hulls with three slots. Frigates are not fully locked out of customization, but they are locked out of build construction; they become single-module pickets or bare hulls.

4. FREE REFIT MOVEMENT

If modules move freely, the remaining decision is which modules you own and how you assign them before each battle. That is a pre-battle checklist, not a build system. For a roguelite fleet-tactics game, the module layer should create run identity and hull commitment; free movement should be constrained by refit cost/time, hull compatibility, or scarcity, or the modules will not produce builds.

5. THE FLAGSHIP RESERVE

Pod and trim are the right shape for flagship identity; the module slot is the wrong layer. The flagship already has normal hull slots, so a reserved "one module slot (flagship only)" either stacks as an extra slot or duplicates the existing module system. The pod collides with HULL_VARIANTS weapon arrays and FAC_WPOOL; the trim collides with variant mods that already trade stats. The reserve should borrow the zero-sum discipline of trims and the faction-filtered pod pool, but avoid duplicating the module slot; either integrate the flagship module into normal slots or make it a genuinely unique flagship-only category.

4. Not checked

This pack does not let me judge actual hull weapon arrays for all hulls, base shield/PD incidence, accuracy and crit formulas, shield regeneration baselines, point-defense prevalence, battle length, credit economy, reward/salvage rates, UI filtering, whether free movement has hidden costs, Godot parity, doctrine/admiral-skill interactions, or whether the future ship.fit resolver will stack with variants or replace them.

5. Questions for the designer

1. Is free refit movement intended to be unlimited per battle, or should moving a module cost time/credits and commit it to a hull? Stakes: this determines whether modules are a build system or a pre-battle checklist.

2. Does the flagship's reserved module slot stack on top of its normal hull slots, and how do pod/trim interact with authored variants? Stakes: this prevents flagship double-dipping and variant overlap.

3. How common are shields, point defense, batteries, lances, and torpedoes across hulls, and will weapon-specific modules be filtered by compatibility? Stakes: this decides whether conditional modules are meaningful specialization or trap/dead slots.
