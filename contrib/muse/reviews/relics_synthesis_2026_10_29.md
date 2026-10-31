# Relics audit: chair synthesis (Oct 29 program, written Oct 30, 2026)

Four prongs: DeepSeek, Qwen, Argon, and a blind Rey leg that read the code directly. All four return the same verdict.

**Verdict: MOSTLY DISTINCT (4 of 4).**

Inside the pool, the 12 relics are clean: every relic owns a key no other relic uses, and the seven run-channel relics (avenge, firstSure, revive, credPct, bloodied, salvage, xpPct) each do a job nothing else in the pool does. The distinctness problem is across systems, not inside the pool. Six of the 12 relics write onto the exact additive key another system already owns, so a relic pick often reads as a second copy of something the player already has rather than a new rule. That is a lesser version of the weapons and boons verdicts, not the same one: the run-channel half of the pool is genuinely distinct, and the fix list below is short and mechanical.

## The duplication core (all four prongs)

Five fx relics (lattice, spore, compass, coils, armourweave) are pushed into the same fleetFxList as admiral fx and boon fx and summed by sumFx on shared keys (shPct, hullRegen, speed, cdMod, armor). A sixth, ledger, sums with the META salvagers unlock on the same credPct key in runFx, at a larger value (+25% vs +20%).

The Rey leg's code read sharpens two of the five from same-key to exact copies: compass is fx:{speed:1}, value-identical to the Born helmsman perk and to the Plasma drive module; coils is fx:{cdMod:1}, value-identical to the Rapid cycling perk. A player can hold the same +1 speed from three different systems at once, all of it landing in one additive pool. Lattice and armourweave are same-key copies of the shield and armor boons at relic-sized values.

## FIX list (consensus unless noted)

1. **Avenge is uncapped.** Martyr's heal fires on every qualifying player ship death, 15% of each surviving ship's max hull, no per-battle cap. Qwen's read is the careful one and the chair adopts its framing: this is a consolation mechanic, not a win-more snowball, because each trigger costs a ship. But the heal scales with the survivors' hull, not the dead ship's, so losing a cheap escort alongside damaged capitals returns more hull than was lost, and the Rey leg's feeding math shows the exchange can be net-positive in exactly that common case. A per-battle cap or a heal keyed to the dead ship's hull closes it without touching the consolation intent. Chair verification (Oct 30, killUnit in battle.js): the trigger excludes squadrons and transports both as triggers and as recipients, so Argon's squadron-farming case is closed by code; the uncapped capital-heal case is not.

2. **payRelic removes the most recently acquired relic, with no player choice.** Relics append on acquisition and payRelic splices the last element (campaign_run.js:368). The player is never told which relic an event will take. Taking a weak relic late shields a build-defining one; taking a boss relic last exposes it. Qwen's leg framed the victim as an early cornerstone relic; that direction is inverted and is superseded by this synthesis (the victim is the newest relic, as DeepSeek, Argon, and the Rey leg all had it). Remedies, in Argon's order of preference: let the player choose, or name the relic on the event button so the trade is informed.

3. **Relic rewards cannot be declined.** Boons offer decline-for-credits; relics do not, and the no-decline rule compounds finding 2 (a forced weak pick becomes either a shield or a future forced loss). The game already prices an unpicked relic: events grant +80 credits when the pool is empty (campaign_run.js:356). The decline button has a price on file.

4. **relicUseful filters one case and misses the guaranteed-zero ones.** The filter excludes only lattice for shieldless fleets (core.js:239). The hard structural cases the prongs agree on: coils in a fleet with no reducible cooldowns, logbook when every captain is at max level, martyr in a single-ship fleet with nothing to heal. These matter most on the 1-of-1 grants (Founder start, event grants) where there is no draft choice to soften them. Situational weakness (banner, spore, compass, armourweave) should stay unfiltered; judging fit is the draft's job. Argon's split between structural and situational is adopted.

5. **The phylactery base name leaks the wrong faction.** The base name is "Eclipse backup frame." Eclipse itself renames it ("Second Ignition"); every other faction without an override displays the base string, so Hegemony, Hullbreakers, Chorus, and Glasswrights all carry a relic named for Eclipse. Either the base name should be neutral or the overrides should be written; as shipped it reads as a rename pass that stopped halfway.

## Settled by code (not open questions)

**Revive order.** DeepSeek flagged the phylactery vs Eclipse reanimate interaction as a blocker because the pack did not state the order. The Rey leg read the code and the chair re-verified it Oct 30 in killUnit: lastStand first, then the phylactery branch, which returns immediately, so a phylactery-saved ship spends no legion budget and pays no avenge. The legion and random-reanimate branches come after; a legion-bound death does pay avenge (it truly dies, then rises next round), a phylactery-saved one does not. Net: Eclipse gets both revive systems at full value across separate deaths, with the fleet-wide once-per-battle revive spent FIRST, before the faction's own reassembly is consulted. Qwen's leg guessed the opposite order (reanimate first); its conclusion that Eclipse benefits from both systems happens to match, by a different mechanism, and its mechanism is superseded by this synthesis. What remains is intent, not mechanism: whether phylactery should be spent before legion on an Eclipse death is designer question 1 below.

**Cogitator collision: CLEAN.** The key exists in both RELICS and MODULES. The Rey leg checked every consumer: all are namespace-explicit, save validation checks each table independently, and campaign_run.js:428 uses the key strictly as a module. Argon concurs it is currently isolated. No action required; a rename stays available as belt-and-braces if a shared lookup helper is ever written.

## Naming coverage (chair pack correction)

The evidence pack's RELIC_NAMES counts were wrong, a chair error the Rey leg caught and the validator confirmed. Corrected: Hegemony 11 of 12, Ashfall Hullbreakers 10, the Chorus 11 (no phylactery), Eclipse 10 (lattice also falls back), the Glasswrights 8 (missing spore, phylactery, compass, salvage), and the Sunward Crusade has no RELIC_NAMES row at all, meaning every Crusade relic displays its base name. The Glasswrights gap and the missing Crusade row are flavor debt, not defects; finding 5 is the only naming item with a wrong-faction string in it. Qwen's check f repeated the pack's wrong grouping and is superseded by these counts.

## Note for the economy file (Argon, adopted as a note only)

Ledger (+25% credits), the salvagers unlock (+20%), and salvage (+15 credits and 8% hull repair per battle) stack, and the economy audit priced repair and credits without isolating relic income. Salvage's repair component is part of the free-healing stack behind the Oct 29 accept-as-is ruling. The chair flags the interaction for Opus and does not reopen the ruling: the ruling was about the stack's generosity, and this is one more named contributor to it, not new evidence against it.

Argon also notes the identifier "salvage" is triple-loaded (system display word, one relic's id, one runFx key). No prong found a live bug from it; recorded as a tooling and analytics confusion risk for the Godot port, where the rename is cheap.

## Designer questions

1. On an Eclipse death, phylactery is spent before the legion budget is consulted. Intended priority, or should the faction's own reassembly absorb the first death and save the fleet-wide revive?
2. Should the five fx relics stay flat additive boosts on keys other systems own, or should each gain a unique hook the way the run-channel relics have? This is the same question the gamedev seat asks about the whole additive fold, at relic scale.
3. payRelic: player choice, or an informed button that names the newest relic? And should relic rewards gain the decline-for-credits option boons already have, at the +80 price events already use?

## Not checked

No prong priced the relics against each other (offer-rate or win-rate value per relic); the audit judged distinctness and mechanics, not balance. Cooldown clamping under stacked cdMod (whether coils plus perks can reach 0-turn cooldowns) was raised by Argon and not settled by any leg's code read; it belongs with the findings-to-tests ledger if Opus wants it chased.
