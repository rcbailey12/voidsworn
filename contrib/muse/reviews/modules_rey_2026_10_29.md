# Modules and fitting audit - Rey leg (blind)

## 1. Proof of reading

Pack sections read: the EVIDENCE PACK title line ("modules and fitting audit (code slices from the shipped browser build, main 264f441d)"); THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE (all five questions); and the code slices: data.js 153-203 (MODULES, PERKS, RELICS), data.js 545-548 (hull cost and slot derivation), data.js 570-586 (variant hydration and the FIT_SLOTS reserve). Claims below marked READ come from the pack or from code I read directly in the repo at the same pin (derive and sumFx in core.js, mkWeapon in core.js, the equip and unequip handlers and shipyard stock in campaign_run.js, MOD_NEED in data.js); claims marked INFERRED are my reasoning from those reads.

**Overall verdict: MOSTLY DISTINCT** - the 13 modules mostly do separable jobs, but five of them duplicate captain perks key for key, and costless reversible fitting turns placement into a pre-battle checklist rather than a build.

## 2. Findings

1. [BLOCKER] Five modules are captain perks sold a second time, in the same effect currency. READ: derive() folds module fx, captain PERKS, relic fx, admiral fx and aspect fx into one flat object through sumFx, so identical keys are literally the same stat. The pairs, from the pack tables: auspex {aim:10} vs perk gunnery {aim:10}; cogitator module {crit:10} vs perk killer {crit:10}; prow {hpPct:.15, armor:.05} vs perk ironhull {hpPct:.15}; drive {speed:1} vs perk helm {speed:1}; regen {regenPct:.5} vs perk deflector {regenPct:.4}. INFERRED: the census notes the standing no-duplication rule covers tree skills vs doctrine and leaves modules undefined; this is where the undefined layer bites. A module that copies a perk makes captain progression feel buyable, and because sumFx adds, the pair stacks to double effect (aim +20) rather than colliding, so the duplication is invisible in play.

2. [BLOCKER] Fitting is free, instant and fully reversible, so there is no build decision to protect. READ: the equip and unequip handlers (campaign_run.js ACT.equip / ACT.unequip) move a module between the hold and a ship with no credit cost, no cooldown and no restriction beyond a free slot, and the fleet screen offers refitting between nodes ("Manage fleet and refits"). READ: changeShip adjusts current hull by the max-hull delta, so swapping a prow on or off costs nothing in effective health either. INFERRED: with zero friction, optimal play is to refit the whole fleet before every battle for the enemy at hand. Placement is a checklist executed at the fleet screen, not a commitment made at purchase.

3. [FIX] Weapon-specific modules are gated at the fleet level but wasted at the ship level, with no warning. READ: modulePool and MOD_NEED (data.js:259) keep loaders, crystal, magazine, flakplus, capacitor, regen and hangar out of offers when the FLEET lacks the matching kit. READ: the equip UI (campaign_run.js:128) filters candidate ships only by free slots and the module's `only` field, which exists only on hangar (`only:'launch'`). READ: mkWeapon applies battShots, lancePct-class effects, torpCd and flakPlus per weapon kind on the fitted ship itself. INFERRED: on any mixed fleet, a lance crystal can be fitted to a ship carrying no lance and does exactly nothing, and the UI never says so. The gating was built for offers and never extended to fitting.

4. [FIX] Auspex is a strict take on every armed ship, which flattens the slot decision it should create. READ: auspex is "+10 aim for every weapon" at cost 80, it has no MOD_NEED entry, and aim feeds every weapon the ship fires through the shared fx pool. INFERRED: unlike the weapon-kind modules it needs no matching hull, unlike prow it scales with the ship's whole armament, and +10 aim on every shot is worth more on the multi-weapon hulls that also have the most slots. The only reason not to fit it is not owning one.

5. [FIX] Damage control crews are dominated by reinforced prow at both price and effect. READ: damcon costs 85 and repairs 4% of max hull at the start of each of your turns (fx hullRegenPct:.04, applied in derive as a per-turn amount); prow costs 70 and gives +15% hull immediately plus +5% armor. INFERRED: damcon needs roughly four of your turns under fire merely to return the buffer prow grants before the battle starts, it gives no armor, and it does nothing for a ship killed from full in fewer turns. At 15 credits more than prow it is the closest thing in the table to a never-install.

6. [FIX] Module prices ignore the slot ladder they live on. READ: module costs run 55 to 90 credits. READ: the hull cost formula in the pack slice, Math.round((60*cp+10)/5)*5, prices a cp 1 hull at 70 and a cp 5 hull at 310. INFERRED: the cheapest module (flakplus, 55) costs about four fifths of an entire frigate hull, and the joint most expensive modules (loaders, hangar, 90) cost more than the frigate itself, while on a cp 5 hull a module is under a third of hull price. Fitting a small hull is proportionally the most expensive customization in the game, on the hulls with the fewest slots to show for it.

7. [NOTE] The slot ladder concentrates all real builds on cp 5 and above. READ: "h.slots=cp<=2?1:cp<=4?2:3". READ: a count of the hull table at this pin gives most hull entries at cp 1 to 2, so the majority of hulls a player fields carry exactly one module. INFERRED: with one slot, a frigate's "build" is a single stat pick, usually the strict take from finding 4; two and three slot hulls are where combinations, and therefore builds, exist at all.

8. [NOTE] Two shield modules split one job along a line players cannot see before fitting. READ: capacitor is +30% shield strength (shPct) and regen is +50% shield regeneration (regenPct), both gated to shielded fleets in MOD_NEED. INFERRED: capacity vs regeneration rate is a real distinction, but both read as "shields better" at the reward screen, and regen's value depends on base regeneration values that the module text never shows. This is a presentation duplicate more than a mechanical one.

9. [NOTE] The hangar module is the only module with an equip restriction, and its plumbing has a silent edge. READ: hangar carries `only:'launch'` and the equip UI honors it. READ: derive computes hangar as t.hangar plus fx.hangar only when the hull already has a hangar value, otherwise only hive effects count. INFERRED: the restriction is doing real work and the pattern (a module that declares which ships may hold it) is exactly what finding 3 says the weapon-kind modules need; hangar proves the mechanism exists and was used once.

10. [NOTE] A cross-table id collision waits in the data: MODULES.cogitator and RELICS.cogitator share an id in different tables. READ: both tables define a `cogitator` key at this pin, with unrelated effects ({crit:10} vs a first-attack run effect). INFERRED: nothing breaks today because the tables are read separately, but any future unified inventory, fit resolver or save migration that keys items by id alone will collide here first.

## 3. Explicit checks

### 1. MODULE IDENTITY

One line per module, job only:

- prow (70): hull buffer plus a little armor; the generic survivability pick.
- auspex (80): flat aim for every weapon on the ship; the generic accuracy pick.
- drive (75): +1 speed; repositioning and chase/escape utility.
- gyro (60): +1 turn allowance plus +5 evasion; the maneuverability pick, cheapest module with two stats.
- capacitor (80): +30% shield capacity; bigger shield pool.
- regen (70): +50% shield regeneration; faster shield recovery over a long fight.
- loaders (90): battery weapons only, +1 shot per battery; battery hull firepower.
- crystal (80): lance weapons only, +25% lance damage; lance hull firepower.
- magazine (85): torpedo weapons only, reload one turn faster plus +15% torpedo damage; torpedo cycling.
- flakplus (55): flak weapons only, +2 shots and +1 range (fx flakPlus:1, applied in mkWeapon); point defense and anti-squadron cover, cheapest module.
- damcon (85): repairs 4% of max hull per turn; sustained hull recovery.
- hangar (90): launch ships only, +1 squadron in flight; carrier capacity.
- cogitator (75): +10% critical chance for the ship; the generic crit pick.

Duplicate jobs at different prices: capacitor vs regen is the only same-domain pair inside MODULES (shield capacity 80 vs shield regeneration 70; distinct mechanics, same shelf). The true duplicates sit across systems: auspex/gunnery, cogitator module/killer, prow/ironhull, drive/helm, regen/deflector (finding 1), and relic compass {speed:1} makes drive's job a three-way split across module, perk and relic.

### 2. STRICT TAKES AND DEAD SLOTS

Strict take: auspex. READ numbers: +10 aim, every weapon, no MOD_NEED gate, cost 80. INFERRED defense: every hull in the game shoots, aim helps every shot including the weapon-kind modules' boosted weapons, and it stacks with the gunnery perk rather than being replaced by it. On any ship with a free slot and no specific plan, auspex is correct; prow (+15% hull, +5% armor, 70) is the runner-up and the better pick only on a ship whose weapons rarely bear.

Never install at any price: damcon, on the numbers in finding 5. INFERRED defense: strictly worse than prow for the first three turns of any fight, more expensive, and its niche (very long fights with steady chip damage) is already served fleet-wide by the spore relic's flat hull regeneration and by post-battle repair systems outside this pack. I name no module as literally zero-effect by design; the zero-effect outcomes in this system come from misfitting (finding 3), not from the table.

### 3. SLOT ECONOMY

READ: slots are 1 at cp 1-2, 2 at cp 3-4, 3 at cp 5 and above, and the hull table at this pin is bottom-heavy (most entries cp 1 to 2). INFERRED: the real build platforms are the cp 5 and above hulls, the only ships where two modules can interact (a weapon-kind module plus auspex, capacitor plus regen). Cp 3-4 hulls get a genuine but shallow choice. Frigates are not locked out of customization on paper (they can hold the strict takes, and gyro at 60 is priced for them), but in practice one slot plus module prices near their own hull price (finding 6) means a frigate's customization is a single expensive stat, decided once and rarely revisited. The ladder does make small hulls poor relations; whether that is wrong depends on whether frigates are meant to be disposable screens (then it is honest) or fleet members (then it starves them).

### 4. FREE REFIT MOVEMENT

READ: movement is free and reversible at the fleet screen, with no cost in credits or health (finding 2). INFERRED: the decision that remains is loadout-per-battle: read the next node, refit, fight. That is a pre-battle checklist, not a build system, because a build system requires a choice that is expensive or impossible to undo. For this game the chair's judgment is that a checklist is the wrong default for modules specifically: the run structure already gives free adaptation through boon offers and fleet purchases, and modules are the one layer that could carry commitment (fit at a shipyard, locked until the next shipyard) without new content. If free movement stays, the honest fix is to stop pricing and presenting modules as builds and treat them as fleet equipment, which also resolves finding 6's price absurdity.

### 5. THE FLAGSHIP RESERVE

READ: FIT_SLOTS reserves a swappable weapon pod, one module slot, and one of four zero-sum section trims, flagship only, schema only; the comment states a future fit resolver applies ship.fit on top of derive(). Collisions: (a) the reserve's module slot lands on the one ship that least needs it, since the flagship-class hull already sits at the top of the slot ladder (INFERRED: 3 slots at cp 5 and above), so the reserve either stacks to a fourth module slot or creates a second, parallel module namespace for one ship; (b) the pod competes with authored variants, which already swap whole weapon fits per hull (the pack's variant slice shows variants replacing the weapon list outright), so pod vs variant needs one owner for "what guns does this hull carry"; (c) the trims are the only zero-sum element anywhere in customization, while all 13 modules are pure upside, so the reserve would introduce tradeoffs exactly where the base system has none and the contrast will make modules feel free by comparison. What the reserve should borrow: the module system's plumbing (fx keys through sumFx and derive, and the `only` restriction pattern from hangar) so a fit is just another fx source, plus the FAC_WPOOL faction filtering already built beside it for the pod pool. What it should avoid: duplicating an existing module's effect as a "flagship module" (the finding 1 error, repeated at the flagship layer), and any second inventory; the flagship module slot should draw from the same MODULES table and the same hold.

## 4. Not checked

- Battle-length and damage data: how many turns fights last and how much shield regeneration or hull regeneration actually ticks, which decides capacitor vs regen and damcon's real value.
- The admiral skill tree contents and the LEGACY doctrine table: whether trees or doctrine also duplicate module fx beyond the PERKS overlap verified here.
- Enemy fleets: whether AI ships carry modules, and whether the player can read an enemy's fit before refitting against it.
- The Godot port's module implementation; this leg reads the browser build at the pin only.
- Save-format and migration handling of the cogitator id collision (finding 10).
- Whether refitting is reachable during a sector or only at specific nodes beyond the fleet screen text read here.

## 5. Questions for the designer

1. Should fitting modules cost anything, in credits, time, or shipyard access, or is the module layer officially fleet equipment rather than builds? Stakes: every other finding in this leg changes severity depending on the answer, because free reversible fitting is what turns distinct modules into a checklist.
2. May a module duplicate a captain perk's effect, yes or no, as a written rule next to the existing tree-versus-doctrine rule? Stakes: five of thirteen modules currently do, and the FIT_SLOTS flagship module slot will repeat the question the day it ships.
3. Are frigates supposed to be customizable fleet members or disposable screens? Stakes: the 1-slot ladder and near-hull module prices are either a bug starving small hulls or an honest signal of their role, and the fix runs in opposite directions.
