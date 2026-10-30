# Relics audit, Rey leg (savings pass fresh sweep, Oct 29, 2026)

## 1. Proof of reading and verdict

The pack lists 12 relics (martyr, cogitator, lattice, spore, phylactery, ledger, compass, banner, salvage, coils, logbook, armourweave). Effects travel through two channels: an fx channel, summed additively into ship stats alongside the admiral's doctrine and every boon's fx, and a run channel, summed separately and consumed by battle and campaign triggers. One acquisition path in my own words: winning an elite fight offers a choice of one relic from two random unheld ones, and a boss fight widens the same choice to three.

Verdict: MOSTLY DISTINCT

## 2. Findings

1. [FIX] READ (code). The pack's naming coverage counts are wrong for three factions and omit a fourth. Recounting RELIC_NAMES at data.js:267-271: Hegemony renames 11 of 12 (spore IS renamed, "Captured Chorus culture"), Ashfall Hullbreakers rename 10 (phylactery and spore both fall back), Eclipse renames 10 (lattice and spore both fall back), The Chorus 11 and The Glasswrights 8 match the pack. The Sunward Crusade has no RELIC_NAMES row at all, so all 12 base names are its display names. Pack quote: "Hegemony 10 of 12 (no phylactery, no spore)".

2. [FIX] READ (code). Two fx relics are exact value copies of a captain perk and a module on the same key. Compass is fx:{speed:1} (data.js, RELICS), identical to PERKS.helm fx:{speed:1} and MODULES.drive fx:{speed:1}. Coils is fx:{cdMod:1}, identical to PERKS.rapid fx:{cdMod:1}. fleetFxList (core.js:172) pushes relic fx into the same list as admiral and boon fx, so the relic versions differ only in scope (fleet-wide, run-long), not in kind.

3. [NOTE] READ (code). Lattice (shPct .15) and armourweave (armor .06) sit on the same keys that boons write with rarity scaling and that modules write per ship (MODULES.capacitor shPct .3, MODULES.prow armor .05). They are smaller or mid-sized copies in effect, made fleet-wide. Nothing about them behaves differently from a boon on the same key once folded by sumFx (core.js:171).

4. [FIX] READ (code). Phylactery pre-empts the Eclipse legion rather than stacking on the same death, and the interaction is stronger than the relic text suggests. In killUnit, the phylactery branch (battle.js:936) fires first and returns: the ship restarts at 25% hull immediately, the legion budget is not spent, the ship is not marked reanimated, and neither avenge nor bloodied pays out for that death. A legion-bound death later in the same battle does pay avenge (battle.js:943), because the legion branch (battle.js:940) does not return before it.

5. [FIX] READ (code). Avenge has the loosest trigger discipline in the system. Pack quote: "on EVERY player ship destruction (no per-battle cap in this code)". Code confirms it at battle.js:943: every non-squadron, non-transport player death heals every other living non-squadron ship by 15% of its own max hull, capped only by missing hull. Revive by contrast is hard-capped by B.reviveUsed at one per battle.

6. [FIX] READ (code). The usefulness filter is one hard-coded exception while a general system exists next door. relicUseful (core.js:239) excludes only lattice for a shieldless fleet; boons use boonUseful with a BOON_NEED map over the fleet kit (core.js). Dead and near-dead relic cases exist (finding 7 and check d) and are offered anyway.

7. [NOTE] READ (code). Two relics have real dead states the filter misses. Coils pays nothing when no ship has a cooldown ability, and nothing again when every ability cooldown is already 1, because abilityCd floors at 1 (battle.js:1052). The cogitator relic pays nothing through squadrons, because firstSure requires a non-squadron attacker (battle.js:651: "a player ship's first attack each battle"), so a carrier-led fleet gets a fraction of its value.

8. [FIX] READ (code). payRelic removes the last relic with no player choice (campaign_run.js:368: splice(RUN.relics.length-1,1)). List order is acquisition order, so the cost is always your newest relic. It is knowable, but never choosable, and it is the only place in the system where the player loses a relic.

9. [NOTE] READ (code). The one sharp naming edge is phylactery. Only Eclipse renames it ("Second Ignition", data.js:271); the other five factions see the base name, which carries Eclipse's name in it ("Eclipse backup frame", data.js:190 area of the RELICS table). The battle log hardcodes the Eclipse flavor for everyone: battle.js:936 logs "Second ignition." on any fleet's phylactery restart.

## 3. Explicit checks

### a. Effect audit, relic by relic

- martyr (avenge): distinct in kind. READ (pack and code). A triggered fleet heal on a ship death exists nowhere else in the fold; the Chorus feed pays carriers on kills, which is a different trigger and a different side of the exchange.
- cogitator (firstSure): distinct mechanic. READ (code, battle.js:651). An aim floor of 95 on each ship's first attack (75 while surging) is not a stat copy of anything. Its only collision is the shared key with the module (check g), whose effect (+10% crit) is unrelated.
- lattice (shPct .15): a copy in effect. READ (code). Same key as shield boons and MODULES.capacitor; see finding 3.
- spore (hullRegen 3): same job, different form. READ (code). derive folds flat hullRegen and hullRegenPct into one regen value (core.js:215); MODULES.damcon pays 4% of max hull per turn, spore pays a flat 3 fleet-wide, so spore is stronger on hulls under 75 max hull and weaker above. Distinct enough in behavior, same pool in code.
- phylactery (revive): distinct from its relatives. READ (code). PERKS.laststand keeps a captain's ship at 1 hull instead of dying; the Eclipse reanimate is a hull trait with a legion budget; phylactery is a run-level once-per-battle restart at 25%. Three different mechanisms around one event.
- ledger (credPct .25): distinct item, shared key. READ (code). The only other credPct source is the META salvagers unlock (+.2) in runFx (core.js:196); they stack to +.45. No boon or doctrine writes credPct.
- compass (speed 1): exact copy, wider scope. READ (code). See finding 2.
- banner (bloodied): distinct in kind. READ (code, battle.js:944 and :681). A per-ship kill stack (+15% damage, max 3 stacks) applied inside the damage calculation alongside Command multipliers; nothing in the fx fold does this.
- salvage: distinct in form. READ (code, campaign_run.js reward flow). A flat 15 credits plus an 8% fleet repair after every battle overlaps the job of repair reward nodes and of ledger, but its flat, unconditional shape is its own.
- coils (cdMod 1): exact copy, wider scope. READ (code). See finding 2.
- logbook (xpPct .3): distinct. READ (code). It is the sole xpPct source; addXp multiplies through it (core.js:231).
- armourweave (armor .06): a copy in effect, and the smallest of its set. READ (code). Same armor key as MODULES.prow and rarity-scaled armor boons.

Summary of (a): the run channel is genuinely varied (seven triggered or economy effects, none a copy of another system). The fx channel is where the duplication lives: of its five relics, two are exact perk/module copies and two are same-key stat copies; only spore's flat-versus-percent form gives its copy a different feel.

### b. The two revive systems

READ (code, battle.js killUnit). They collide in ordering and stack across a battle; they never double-pay on the same death.

- Eclipse fleet holding phylactery: the first non-squadron death each battle is taken by phylactery (battle.js:936), restarting at 25% hull immediately. The legion budget (battle.js:490, max 1 or 2 depending on how many reanimate hulls are fielded) is untouched, and the restarted ship is not marked reanimated, so if it falls again it can still reassemble through the legion and rise next round (battle.js legionRise). Net effect: an Eclipse fleet gets phylactery's full value plus the legion's full value in the same battle, and phylactery quietly upgrades the first legion rise from next-round to immediate. Phylactery can also save the flagship or a transport, which legionCan explicitly excludes (battle.js:513).
- One asymmetry worth naming: a phylactery-saved death pays no avenge and no bloodied (the branch returns), while a legion-bound death pays both, because the ship truly dies that round.
- Non-Eclipse fleet: no interaction at all. Phylactery is the fleet's only return mechanic, reviveUsed caps it at one per battle, and the enemy-side reanimate roll (battle.js:938, for reanimating hulls such as Undying heat foes) is a separate path that never touches runFx.

### c. Avenge: decision, snowball, or perverse incentive

READ (code) for the mechanics; the classification is INFERRED. It is attrition insurance with a snowball shape and a bounded perverse edge; it is not a decision at trigger time, since nothing is chosen when it fires.

- Snowball shape: its payout scales with fleet size and with losses taken, and it pays in the currency (hull) that keeps the rest of the fleet alive to lose again. A wide fleet that trades hulls converts each loss into up to 15% of every survivor's max hull.
- Perverse edge: because the heal is capped by each survivor's missing hull, deliberately feeding a cheap ship is hull-positive only when the fleet is already carrying more than 15% damage spread across several ships and the fed ship is worth less than the total healed. In a permadeath roguelite that trade still costs a hull, a captain, and command points for the rest of the run, so the incentive is real but narrow; swarm fleets with 1-CP hulls are where it is widest.
- Trigger discipline versus revive: revive is once per battle behind a flag; avenge is uncapped and fires on the second, third, and fourth death at full strength. If any relic in the set was going to get a cap or a decay, the code's own contrast with revive says it is this one.

### d. Offer fairness

READ (code) for the filter; fleet-state judgments are INFERRED unless a line is cited.

- lattice: filtered for shieldless fleets (core.js:239). Correct and sufficient.
- coils: dead when no ship carries a cooldown ability, and dead again ship by ship when an ability's cooldown is already 1 (abilityCd floors at 1, battle.js:1052, READ code). A fleet of plain gun hulls can be offered a relic that does literally nothing.
- cogitator: near-dead in a carrier-led fleet, because firstSure excludes squadrons (battle.js:651, READ code) and the fleet's damage arrives by wing.
- banner: starved in low-kill play. It pays only on ship kills by your ships, and squadron targets are excluded (battle.js:944 requires a non-squadron victim), so objective and rout fights and wing-versus-wing fights feed it little.
- martyr: dead in a clean run until the first loss, then strong. Situational rather than dead.
- spore: regen applies every round (battle.js:381) but is wasted at full hull, so it is near-dead in short, one-sided fights and strong in long ones.
- compass: the pack's example of a fleet that cannot use speed has no instance I
...[truncated 4377 chars]