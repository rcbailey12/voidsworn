# Admiral tree effects: plan (issue #305, FINDINGS R143)

Plan only. No game code, data or tests change in this PR. Written Nov 9 2026 by an Opus worker thread from main at 5cd6947.

## 0. The answer in five lines

1. Of the 216 tree texts, 18 map onto an effect the battle already has (bucket a), 127 need one of 17 small shared hooks plus the plumbing (bucket b), 10 need a new mechanic (bucket c), and 61 cannot work as written (bucket x: they describe something the game already does, contradict a rule, or use a term the game does not have). 22 of the 61 have a one-line fix that lands them in a or b; the other 39 do nothing at all today and need a new effect written.
2. So more than a quarter of the texts go back to Muse for a rewrite before anyone codes them (12 of the 36 Glasswrights texts, so the pilot starts with a rewrite pass). Most of the rest share a small set of hooks, built once in the Glasswrights pilot and reused by every later faction.
3. A pick reaches battle through a snapshot: the run copies the flown admiral's build into the run save at run start, the battle turns it into a list of live skills at battle start, and every number passes the progression step 1 caps by only filling the room left under each cap.
4. Proof is one parity fixture per skill (browser oracle and Godot, record for record), plus a check that the skill fired and changed the fight. Ryan sees a coloured callout over the ship, a log line, and a count in the after-battle recap.
5. Job split: plumbing plus the Glasswrights pilot first (DeepSeek, two to three runs, two review rounds), then one faction per job, then the bucket c mechanics as separate jobs once Ryan rules on them.

## 1. What the battle has today (read from battle.js, core.js, data.js, godot/rules)

### Effect kinds that already exist

- **Summed effects (fx keys), capped since progression step 1.** core.js `FX_CAPS` (line 178) and `sumFx` (192); Godot `rules.gd` `sumFx` (295) reads the same table. The keys a tree skill can use directly: `dmgPct`, `aim`, `ev`, `crit`, `rearPct`, `lancePct`, `torpPct`, `broadPct`, `sqPct`, `stillPct`, `huntPct`, `ramPct`, `boardPct`, `lanceRange`, `hullRegenPct`, `speed`, `turns`, `sqIgnite`, `armor`. `derive` (core.js 237, rules.gd 395) folds them into each ship at battle start.
- **The six Commands.** battle.js `runCommand` (1119; rules.gd 3179), once per battle, power grows by the round you hold it (`CMD_POW`, tiers 0 to 2):
  - `barrage` (Vex, Saro, Kassar, Voice, Umbra): every ship fires a free volley right now, each gun at its own best target (`B.volleyMul`).
  - `hunt` (Malek, Vorn, Sable, Ostrel): torpedoes reload at once, every ship +30% to +60% damage this round.
  - `scramble` (Ashgrove, Reyes, Mott, Matriarch, Tamsa): every launch ship makes one extra wing (two at full power), then every wing strikes again at +50% to +100%. **The extra wings stay on the field for the rest of the battle** like any other wing.
  - `iron` (Thale, Maren, Brin, Seveth): all shields refill **to full**, hull damage -40% to -60% this round (`cmdTaken`, 1115; shieldless hulls get 10 points more).
  - `restore` (Vesh, Mending Throng, Nadir): every ship repairs 25% to 45% of hull and repairs every section, broken ones too (`repairSection`, 745).
  - `surge` (Grax, Razormaw, Vell): +2 to +4 movement, +1 or +2 turns, enemy fire -20 accuracy this round.
- **State the battle already tracks** (so a condition on it needs no new state): hexes moved this turn (`hexMoved`, "did not move"), rear arc hits (shield quadrant 2), distance to any ship, the player flagship (`pflag`), target hull below half, `B.mark` (one marked enemy per round gives +10 aim, the Marked for Death boon), `evBuff` (evasion until the ship's next turn), wing orders (`strike` a chosen enemy, `guard` a friend) and wing stances (strike, screen, hunt; screen wings intercept torpedoes), the flak gauntlet (each flak ship intercepts two wing attacks a turn: this is the game's "point defence"), ignite and acid statuses, section breaks that switch weapons off (`w.off`), Hegemony synchronized fire (`syncR`, `syncOn`, the anchor is the flagship), boarding (the Board order, `boardUnit` 924, `boardPct`, Hullbreakers board at 1.45x, the best in the game) and ramming (`ramUnit` 894, `ramPct`, `ramBoost`).

### Facts that decide many rows below

- **Turn order.** Alternating activations is the default (ui3d.js `SETUP.alt:true`; Godot `battle_api.gd` `_prep`, line 186): the player activates first each round, then the sides alternate one ship at a time. Classic (whole fleet, then theirs) is the option. The Command can be used at any point in the player's activations, so "declare it at the start of the round, before any ship moves" and "declare it after movement" are both already possible.
- **Friendly ships never block movement or line of sight** (`passable` 424 blocks only enemy hulls; `los` 650 is blocked only by terrain). Any ship can already dive under an enemy hex for +1 movement (v50 thrusters).
- **Rams never roll to hit.** A ram needs movement left and a straight run-up of at least one hex (`ramInfo` 880), so a ship that has spent its movement next to an enemy cannot ram.
- **Torpedoes travel** (B3): they launch now and strike at the start of the firing side's next turn. Under Malek (`torpCd 1`) torpedoes are already ready again every round.
- **Glasswright hulls already move after firing** (half their remaining movement, `canFade`/`postFireMp` 488).
- **No player deployment step exists.** `deploy` (256; rules.gd 845) places every ship automatically. The only mid-battle arrival code is the reinforcement event (`edgeHex` 27, `eventTick` 30).
- **Eclipse has no shields** (every `d_` hull has `sh:0`) and no torpedoes or carriers. Hegemony has no torpedoes, and its launch ships are a cruiser and a battleship (no "carrier" class). The Chorus has no shields. Hullbreakers have no lances.
- **lineageBuild is read only by the campaign screens today.** Nothing in battle.js, core.js `derive` or godot/rules reads it (R143 confirmed: grep shows only campaign_meta.js, core.js, campaign.gd and campaign_ui.gd).

### Text source check (data.js against the finalized Muse files)

A script compared all 216 texts in data.js `LINEAGE_TREES` with contrib/muse/design/admiral_trees_2026_11. Eleven differ; four are punctuation or spelling only. The seven real ones:

- **Glasswrights in data.js still carry five Oct 29 draft texts** (the first Glasswrights test slice was built from skill_tree_phase1_assembled_2026_10_29.md, the data.js comment says so): Tamsa T3b Every Lens Aloft, Tamsa capstone 1 (data.js "Flight Remembered Perfectly", final "Flight Cast Perfectly"), Saro T3b Long Light (final adds the no-turn condition), Vell capstone 2 A Hundred False Hulls (final: first two enemy attacks automatically miss), Brin capstone 1 (data.js two-round ward, final "enemy that fires at a warded ship loses 20 accuracy on its next shot"). The pilot job updates these five texts in data.js first, then builds the final versions. This plan sorts the final texts.
- **Eclipse: data.js is right and the Muse file is wrong.** eclipse.md still says "and its shields refill" (Nadir capstone 2) and "the first time each ship shields reach zero" (Seveth T3a). data.js already dropped both. Eclipse has no shields, so the build uses the data.js text and Muse corrects eclipse.md (listed in section 7).

## 2. How a pick reaches battle

1. **Snapshot at run start.** `newRun` (core.js 411; campaign.gd 1081) copies `lineageBuild(admiral)` into the run as `RUN.lineage = {id, picks, capstone}`. Picks can only change between runs (`lineageBetweenRuns`), so a snapshot is exact for the whole run. An old save without the field flies with no skills until its next run (no crash, no silent change mid-run). The battle never reads META, so the battle parity harness needs no META.
2. **Battle start.** `startBattle` (battle.js 306; rules.gd 1084) builds `B.tree` for the player side only: the live skill keys (the pick keys already used by lineageBuild, for example `vaelen:A:2:1` and `vaelen:cap:0`) plus their numbers from a new data table `TREE_FX` in data.js, right under `LINEAGE_TREES`, exported to both Godot table files by the existing exporters. The text stays in `LINEAGE_TREES`; the numbers live in `TREE_FX`; a lint check fails if a `TREE_FX` number does not appear in its text.
3. **Gate on the right Command.** Every skill tied to a Command checks `cmdActive(side, id)` against the admiral's own Command id. If the run uses the mastery Second Command (`RUN.cmdOverride`), Command skills stay quiet, because the texts are written for the primary Command only (Muse index: "authored against the admiral's primary Command only").
4. **Enemies never get tree effects.** Sector flagships keep their own Command (`BOSS_CMD`).
5. **Through the step 1 caps.** Two routes:
   - Unconditional parts (rare) join `fleetFxList` (core.js 195; rules.gd 303) as one more fx entry, so `sumFx` caps them like any relic or boon.
   - Situational parts (almost all) go through one helper, `treeAdd(u, key, v)`, which returns `min(v, FX_CAPS[key] - u.fx[key])` (never below 0). A skill can only fill the room left under the cap for that key. Damage bonuses use `dmgPct` room, aim uses `aim`, evasion `ev` (and the hard 45 evasion ceiling in `hitChance` still applies), crit `crit`, rear hits `rearPct`, rams `ramPct`, boarding `boardPct`, range `lanceRange`.
   - A skill with no matching key (Command power, shield overcharge, temporary hull, extra wings) gets a new FX_CAPS entry in the same PR, so the cap table stays the single list of ceilings: proposed `treeShOver:.25` (shield above max), `treeTempHp:.2` (temporary hull share), `treeWings:2` (extra wings per launch ship from tree skills), `treeHullCut:.75` (largest hull damage cut). The step 1 cap test (`effect_caps_test.gd` plus `contrib/opus/tools/effect_caps_tests.js`) gets one sum fixture per new key.

## 3. The hooks (bucket b), each listed once

Line numbers are battle.js unless marked; the Godot twin is the same function in godot/rules/rules.gd.

| Hook | What it adds | battle.js | Godot twin | Rows using it |
|---|---|---|---|---|
| H0 plumbing | `RUN.lineage` snapshot, `B.tree`, `TREE_FX`, `treeAdd`, `treeFx(u, key, text)` callout plus log line, `B.treeStats` counts for the recap | core.js `newRun` 411, `startBattle` 306 | campaign.gd `newRun` 1081, rules.gd `startBattle` 1084 | every skill |
| H1 choice | a player choice at Command time or battle start (name an enemy, pick a ship, a carrier or a brood), passed as `useCommand(side, opts)`; a default picker in the rules (best expected value) so the bot, the sims and the frozen browser game always have an answer | `useCommand` 1116, `runCommand` 1119 | rules.gd 3134 and 3179, `battle_api.gd command()` 434 plus a pick prompt in the Godot battle scene | 26 |
| H2 counters | once per battle, once per round, first N per round, hits per target this round, hit or targeted this battle or last round; reset in `startSideTurn` | `fireWeapon` 777, `landVolley` 816, `startSideTurn` 386 | rules.gd 2490, 2543, 1400 | 31 |
| H3 next round | bonuses, debuffs, second heals and recharges that land at the next round start; a Command that lasts two rounds (`B.cmd.until`) | `startSideTurn` 386, `cmdActive` 1113 | rules.gd 1400, 3150 | 22 |
| H4 extra shot | fire a weapon again outside the normal flow (half damage, new target, held volley, reroll a miss), on the free volley pattern | `runCommand` barrage, `fireWeapon` 777 | rules.gd 3179, 2490 | 15 |
| H5 Command targeting | change how the free volley picks targets (named enemy, nearest, per ship), retarget travelling torpedoes | `runCommand` barrage, `resolveTorps` 873 | rules.gd 3179, 2176 | 5 |
| H6 Command wings | tag extra wings (`sq.extra`), change counts per launch ship, launch from a non-carrier, hold wings to next round, wider launch hexes, remove a wing after its strike | `runCommand` scramble, `makeWing` 1170, `launchHexes` 1213 | rules.gd 3179, 3250, 3486 | 16 |
| H7 shield variants | overcharge above max, a second recharge, refill when a facing is emptied, shields block the first section hit | `runCommand` iron, `startSideTurn`, `applyHit` 720 | rules.gd 3179, 1400, 2386 | 5 |
| H8 hull cut variants | per-ship conditions in `cmdTaken`, a stacked cut on one ship, a per-round damage ceiling, absorb one hit | `cmdTaken` 1115, `applyHit` 720 | rules.gd 3153, 2386 | 3 |
| H9 repair variants | repair aimed at one section or one ship, a share given away, section max +20%, a section that cannot break again | `runCommand` restore, `repairSection` 745, `damageSection` 752 | rules.gd 3179, 2422, 2441 | 11 |
| H10 temporary hull | `u.tempHp` taken before hull, cleared at the next round start | `applyHit` 720, `startSideTurn` | rules.gd 2386, 1400 | 2 |
| H11 movement and facing | dive under enemies free, free facing, move after a trigger, auto-move N hexes toward a rear arc or a prey at Command time, a second move for the flagship, +1 movement toward a ship | `computeReach` 432, `postFireMp` 489, `canRotate` 491, `rotateUnit` 492 | rules.gd 1494, 1601, 1589, 1590 | 15 |
| H12 reposition | once per battle: move one ship to a free hex in its deployment zone, swap two ships, or move one ship up to 2 hexes; `deploy` stores the zone in `B` | `deploy` 256, new `repositionUnit` | rules.gd 845, new twin, `battle_api.gd` action | 6 |
| H13 reserve | hold one ship off the field, bring it in at round 2 on the deployment edge | `edgeHex` 27, `eventTick` 30 reinforcement code | rules.gd 496, 505 | 2 |
| H14 arc and target rules | fire out of arc once, cannot be targeted from beyond range 6, forced miss on a false image, a missed shot rerolled | `canFire` 653, `hitChance` 657 | rules.gd 2231, 2244 | 4 |
| H15 status on hit | accuracy -20 next round, struck section's weapons off for a round on a crit, acid scaled to damage taken, point defence -1, 25% splash to an adjacent enemy, cleared effects | `applyHit` 720, `damageSection` 752, flak gauntlet in `fireWeapon` | rules.gd 2386, 2441, 2490 | 9 |
| H16 interception | a wing or the flagship takes a whole hit aimed at a nearby friendly | `fireWeapon` 777 before `landVolley` | rules.gd 2490 | 3 |
| H17 extra activation | one extra player activation right after the flagship's (Alternating mode) | not in battle.js: ui3d.js `endActivation` 565, sim3d.js loop | `battle_api.gd` phase flow | 1 |

H0 is the price of entry and goes in the pilot. H1, H2 and H3 are used by every faction and also go in the pilot. The rest are built by the first faction that needs them and reused after.

## 4. Bucket c: new mechanics

| Mechanic | Texts | Why it is new | Simpler rewrite that would drop it to b |
|---|---|---|---|
| C1 combined strike (many ships' damage summed, shields applied once) | Vex cap 1, Saro cap 1, Kassar cap 2, Tamsa cap 1 | every hit today resolves alone through `applyHit`; summing changes crit, pierce and armor maths | "every ship that can reach it fires at it, and its shields stop only the first hit" (H2 counter plus pierce) |
| C2 interrupt in the enemy's activation | Vell cap 1, Vesh cap 2, Reyes cap 2 | the player can only act in the player phase; reacting to enemy fire needs a pause and prompt inside the enemy step, in both twins and the Godot UI | make it automatic: "the first time an enemy fires at your fleet this battle, ..." (H2) |
| C3 formations | Hegemony B1a, Eclipse B1a | no formation shapes exist | "ships that end their movement next to two friendly ships gain +10 aim (Hegemony) or +10 evasion (Eclipse)", bucket a |
| C4 ship roles | Chorus B1a | ships have no roles; strike, screen and mend have no defined effect for capital ships | give each role one number, or replace with a wing-stance-like order |
| C5 recorded wing paths | (in bucket x: Tamsa T1a) | wings path themselves; nothing records a planned path | see the Tamsa rows |
| C6 deployment step | (none left after H12) | the six Branch B "after deployment" texts are built as H12 at round 1, before any ship acts | n/a |

Count of bucket c rows: 10 (C1 4, C2 3, C3 2, C4 1).

## 5. The sort, faction by faction

Columns: slot (T = Branch A tier, a or b = first or second choice; B1 and C1 are the shared faction sets; Cap = capstone), skill, bucket, the effect kind or hook, and any wording problem. Bucket x means it cannot work as written; "x to a" or "x to b" gives the bucket the proposed rewrite would land in. Numbers in the effect column are the ones the text gives.

### The Glasswrights (pilot)

Final texts sorted (five differ from data.js, see section 1). Commands: Tamsa scramble (Starling flight), Saro barrage (Burning glass), Vell surge (Scatter the light), Brin iron (Prism ward).

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Tamsa | T1a Flight Paths in the Glass | x to a | +15% for an extra wing that "follows its recorded path" | wings path themselves; nothing plans or records a path. Rewrite to a tracked condition, for example "an extra wing striking the target its carrier last fired at gains +15%" |
| Tamsa | T1b Cast Twice in Light | b | H1 pick a carrier, H6 tag its extra wing, H4 strike again at half damage if the target is still on the same hex | none |
| Tamsa | T2a The Replay Corrects | x | wings already pick a new best target for the strike again | no effect as written; needs a number |
| Tamsa | T2b Starlings in Formation | x | +10 aim | "strike in the same order as their carriers are arranged" has no meaning in the game |
| Tamsa | T3a Flaw in the Flight Removed | b | H1 pick an enemy; its flak skips the gauntlet against your wings this Command | say "flak" or "point defence" consistently (data.js spells "defense", the Muse file "defence") |
| Tamsa | T3b Every Lens Aloft (final) | b | H6: a launch ship with 0 hexes moved makes one more extra wing that strikes this round at the strike-again bonus | data.js has the old draft text |
| Tamsa | Cap1 Flight Cast Perfectly (final) | c | C1 combined wing strike, ignores flak, +25% to the most damaged section | data.js has the old draft "Flight Remembered Perfectly" (a memory word) |
| Tamsa | Cap2 The Forge Casts Ahead | x to b | extra wings already stay and strike every round; only "repeats its recorded strike" (same target next round, H3) is new | rewrite so the payoff is the new part |
| Saro | T1a Focus Drawn Long | a | free volley + target beyond half the weapon's range: +20% (dmgPct room) | say "the weapon's range", not "the firing ship's range" |
| Saro | T1b One Lens, One Target | x | +25% | unclear: one gun firing at +25% is worse than every gun; if it means all guns merged into one hit, it is C1. Muse to pick one |
| Saro | T2a Light Arrives Together | x | none | the Command can already be used after every ship has moved, and the volley already fires ship by ship |
| Saro | T2b The Recorded Angle | b | H11 one free turn per ship before the volley, auto-faced to bring its best lance on target | none |
| Saro | T3a Burning the Flaw Out | b | H2 hits per target in the volley; third and later hits pierce shields | none |
| Saro | T3b Long Light (final) | a | free volley: lances +2 range (lanceRange room) for a ship that has not turned this round | data.js lacks the no-turn condition |
| Saro | Cap1 Sun Through One Lens | c | C1 combined strike, ignores range falloff | none |
| Saro | Cap2 The Flaw, Corrected Forever | b | H2 record the target the volley hit most; lances +15% against it for the battle | none |
| Vell | T1a Two Images Appear | b | H2 first enemy shot at each ship this round: -20 more accuracy | none |
| Vell | T1b Angles Recorded | b | H2 facing at activation start; ends the scatter facing elsewhere: +10 evasion (evBuff) | none |
| Vell | T2a The Mirror Steps Aside | x to b | H11 dive under one enemy hex at no extra cost | ships can already pass under an enemy hex for +1 movement; rewrite as "at no extra cost" |
| Vell | T2b Light Split Three Ways | x to b | H11 full remaining movement after firing | Glasswright hulls already move half their remaining movement after firing |
| Vell | T3a Refraction Deepens | b | H14 a ship that spent all its movement cannot be targeted from beyond range 6 until next round | define "moves its full distance" as "spends all its movement" |
| Vell | T3b Every Mirror Turns | b | H11 free facing at the end of movement | none |
| Vell | Cap1 The Fleet Is Elsewhere | c | C2 interrupt: Command declared after the first enemy ship fires | index flag 9 |
| Vell | Cap2 A Hundred False Hulls (final) | b | H2 first two enemy attacks in the scatter round automatically miss | data.js says "volleys" and "each round"; the final says "attacks" |
| Brin | T1a Light Bent to the Weak Side | x | none | contradiction: Prism ward refills every ship to full, so giving one ship's refill to another adds nothing |
| Brin | T1b Prisms Face the Fire | x to b | H7 overcharge: +25% shield above max for a ship facing its nearest enemy | the refill already goes to full; "+25% more" only works as shield above max (needs the treeShOver cap) |
| Brin | T2a Recharge While Lit | b | H3 a second recharge at the next round start | none ("round end" lands at the next round start in both turn modes) |
| Brin | T2b The Lens Rotates | x | none | turning or moving never cancels the ward's reduction today |
| Brin | T3a Flaw in the Glass Corrected | b | H7 + H2: first ship whose shield facing is emptied refills to 15%, once per battle | say "a shield facing": shields are four facings |
| Brin | T3b Hard Light | b | H7 during the ward, a ship with shield left on the struck facing takes no section damage from its first hit | say which facing |
| Brin | Cap1 Ward of Clear Glass (final) | b | H15 an enemy ship that fires at a warded ship: -20 accuracy on its next shot, once per enemy ship | data.js has the old two-round text |
| Brin | Cap2 Every Facet Lit | x to b | H10 temporary hull up to +20% | the refill goes to full, so nothing is "refilled beyond maximum"; rewrite as "each warded ship gains temporary hull equal to 20% of its max shields" |
| shared | B1a Deployment Read from the Shards | b | H12 move one ship to a free hex in your deployment zone, round 1 before any ship acts | none |
| shared | B1b Casting Corrected Before Battle | b | H12 swap two ships, round 1 before any ship acts | none |
| shared | C1a The Flagship Lens | b | H1 + H2 once per round, choose an enemy (the `B.mark` pattern): your lances +10 aim against it | none |
| shared | C1b First Light Recorded | b | H2 record the first enemy ship to fire; fleet +10 evasion against it for the battle | none |

### The Sunward Crusade

Commands: Vex barrage (Fire for effect), Malek hunt (Hunter's salvo), Ashgrove scramble (Scramble all wings), Thale iron (Iron wall).

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Vex | T1a Ledger of Arcs | x | none | the free volley already aims every gun at its own best target, so a broadside can already split between targets |
| Vex | T1b Held in the Account | b | H1 pick a ship; H4 its free volley is held and fired after it moves this round | none |
| Vex | T2a Named in the Ledger | b | H1 name an enemy; H5 every gun that can reach it aims at it | none |
| Vex | T2b Inherited Aim | a | free volley from a ship with 0 hexes moved: +15% (dmgPct room) | none |
| Vex | T3a Every Gun Sworn | b | H5 per-ship target choice (H1); ships sharing a target +10 aim | needs a per-ship pick in the Godot UI; default picker for the bot |
| Vex | T3b Debt Comes Due | x | none | the player already acts first each round, so firing "before any enemy ship acts" next round is the same as using the Command next round (at higher power) |
| Vex | Cap1 The Grand Ledger | c | C1 combined strike, shields once | none |
| Vex | Cap2 The Last Account | x | none | "before movement" is already possible, and "each ship picks its own target" restates T3a (the Argon dissent in index split 5 stands) |
| Malek | T1a Prey Entered by Name | b | H1 mark an enemy; torpedoes launched at it this round +15% (taken at launch, B3 rule) | none |
| Malek | T1b Salvo in Two Hands | b | H1 pick up to half the ships; H3 their hunt bonus moves to next round | none |
| Malek | T2a Torpedoes Run First | x to b | H4 torpedoes fired in the salvo round strike at once instead of travelling | contradicts travelling torpedoes (they strike next turn), so they cannot resolve before this round's guns |
| Malek | T2b Rear Arc Reckoning | x to a | rear hits +15% in the salvo round (rearPct room) | the rear-arc bonus already covers every weapon, not only torpedoes |
| Malek | T3a The Debt Hunts | b | H2 the ship closest to its target at activation start: side hits on that target count as rear hits | none |
| Malek | T3b Two Salvos Sworn | b | H3 the hunt bonus also covers each ship's first torpedo next round | none |
| Malek | Cap1 Salvo Without End | x to b | H4 torpedoes may fire a second time in the salvo round | under Malek torpedoes already reload every round (cooldown 1), so "reload again at round end" does nothing |
| Malek | Cap2 The Named Prey Falls | b | H1 name an enemy; H5 retarget every travelling torpedo to it; it takes +25% from all hits this round | none |
| Ashgrove | T1a Escort Sworn to a Name | b | H6 one extra wing gets a guard order on a named friend (wing orders exist); H16 it takes the first hit aimed at that friend | wings intercept torpedoes today, not gunfire; "intercepting fire" needs H16 |
| Ashgrove | T1b First Wave Owes the Second | b | H1 pick a launch ship; its extra wing +20% | launch order has no effect in the game; say "choose one launch ship" |
| Ashgrove | T2a The Account Splits | x | none | every wing already picks its own target |
| Ashgrove | T2b Held in Reserve | b | H6 hold one extra wing; H3 it launches at the next round start and strikes | none |
| Ashgrove | T3a Every Generation Aloft | b | H6 a launch ship with 0 hexes moved makes one more extra wing | none |
| Ashgrove | T3b Wings Settle the Debt | b | H2 an extra wing striking the target its launch ship's guns hit this round: +30%, once per launch ship | "screened at half effect" is undefined (enemy screen wings? flak?) |
| Ashgrove | Cap1 The Roll of Wings | b | sqIgnite during Scramble (fx key exists); H15 struck ship's flak intercepts -1 for the battle | fire burns a ship, not a section: say "ignites the struck ship" |
| Ashgrove | Cap2 Oath of Unbroken Wings | b | H16 escort wall; screen-style torpedo interception for ships within 2 of a launch ship | "+25% screen refill": Scramble refills no shields, and "screen" is also a wing stance. Muse to say what refills |
| Thale | T1a Hold and Be Counted | b | H3 a ship with 0 hexes moved keeps the wall's cut one more round | none |
| Thale | T1b Screens Where the Debt Falls | x | none | contradiction: Iron wall refills every ship to full (same as Brin T1a) |
| Thale | T2a Wall Declared Early | x | none | the Command can already be used before any ship acts; the cut already covers the whole round |
| Thale | T2b Oath of Stillness | b | H3 a ship with 0 hexes moved recharges shields again at half strength at the next round start | none |
| Thale | T3a Unpaid and Unbroken | a | `cmdTaken`: ships below half hull take 60% less instead of 40% | Command power grows by tier (40/50/60%); say "20 points more" so it scales |
| Thale | T3b The Wall Answers | b | H4 + H2: a ship whose shield facing is emptied fires its smallest weapon at the attacker, once per ship per battle | the return shot happens in the enemy's activation; fire it after that enemy shot resolves |
| Thale | Cap1 Iron Testament | b | H3 the wall lasts two rounds; half refill at the start of the second | none |
| Thale | Cap2 The Wall That Moves | x | none | moving never cancels the reduction today |
| shared | B1a Sworn Deployment | b | H12 move one ship to a free hex in your zone, round 1 | none |
| shared | B1b Debts in Reserve | b | H13 hold one ship; it enters at round 2 on the deployment edge | none |
| shared | C1a Flagship Keeps the Ledger | b | H4 once per battle, another ship that already fired fires one weapon again at half damage | needs an order button on the flagship in Godot |
| shared | C1b Standard of the First Crusade | b | H14 + H2 once per round, a ship within 2 hexes of the flagship rerolls a missed shot (automatic on the first miss) | none |

### The Hegemony Navy

Commands: Kassar barrage (Synchronized broadside), Vorn hunt (data.js "Reload and strike", the texts say "Interdiction strike"), Reyes scramble (Launch the strike group), Maren iron (Shield wall order). Hegemony fields no torpedoes and has no carrier class: its launch ships are the Vanguard cruiser and the Dominion battleship.

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Kassar | T1a Wide Net | a | sync radius +1 (`B.syncR`, read by `syncR` 515) | none |
| Kassar | T1b Second Volley | b | H14 + H2 the first synced target each round: one more synced ship may fire at it out of arc | none |
| Kassar | T2a Shared Solution | x to b | synced ships use the best aim among synced ships | "best aim modifier" is undefined |
| Kassar | T2b Cold Drill | x | none | sync never depends on the flagship moving |
| Kassar | T3a Rolling Fire | b | H4 + H2 a kill by a synced ship lets another synced ship fire one weapon at once, once per round | say which ship and whether it may have fired already |
| Kassar | T3b Iron Tempo | x to b | when the anchor is lost the first time, the next largest Hegemony ship becomes the anchor | sync is lost only when the anchor dies or is captured; "crippling hit" is undefined |
| Kassar | Cap1 Living Relay | a | sync radius doubled (`B.syncR`) | the line-of-sight half does nothing: sync never needs sight of the flagship |
| Kassar | Cap2 One Voice | c | C1 combined strike by every synced ship | none |
| Vorn | T1a Target Filed in Triplicate | b | H1 name an enemy; your hits on it +10 crit (crit room) | Command name mismatch, see below |
| Vorn | T1b Strike by the Book | b | H2 a ship whose speed is not below the last ship that fired this round: +15% | buildable but reads as a puzzle; Muse may want a plainer trigger |
| Vorn | T2a Cross-Referenced Fire | b | H2 second and later hits on the same target this round +15% | none |
| Vorn | T2b Filed Before Movement | x | none | the Command can already be used before moving, and the bonus covers the whole round |
| Vorn | T3a Total Interdiction | b | H2 a target hit by three or more ships this round takes +30% from every hit | "split their fire freely" does nothing; ships already choose targets |
| Vorn | T3b Standard Seven Breach | b | H15 a crit switches off the struck section's weapons for one round (`w.off`) | none |
| Vorn | Cap1 Interdiction, Permanent File | b | H3 targets hit during the strike take the strike bonus from your fire next round | none |
| Vorn | Cap2 One Order, Every Gun | x | none | the player already activates first every round, in both turn modes |
| Reyes | T1a Cruisers Filed as Carriers | x to b | H6 one ship without a hangar launches a wing | the Hegemony cruiser (Vanguard) already is a launch ship |
| Reyes | T1b Launch Order Published | b | H2 the first wing to strike this Command: +20% | none |
| Reyes | T2a Second Wave on Schedule | b | H6 + H3 hold all extra wings; they launch at the next round start and strike | "at full effect": say whether the +50% strike bonus carries over |
| Reyes | T2b Procedure Rehearsed | x | none | wings already pick a new best target for the strike again |
| Reyes | T3a Full Group Assembled | b | H6 + H1: if every launch ship launches, each launches one more; all extra wings get a strike order on one named enemy | none |
| Reyes | T3b Registry of Escorts | b | H6 extra wings take the screen stance; enemy wing damage -25% this round | none |
| Reyes | Cap1 One Target, Every Wing Filed | b | H1 name an enemy; extra wings get a strike order on it; it takes +35% from wing hits this round | none |
| Reyes | Cap2 Standing Strike Group | c | C2 a wing that strikes during the enemy's activation when an enemy enters range | extra wings already stay on the field; only the reactive strike is new |
| Maren | T1a Column Filed Straight | x to b | H7 overcharge +25% for ships in a straight line of three | the refill already goes to full (as Brin T1b); the line check itself is simple |
| Maren | T1b Overflow by Regulation | x | none | contradiction: a refill to full never overflows |
| Maren | T2a Wall at the Bell | x | none | no effect, as Thale T2a |
| Maren | T2b Standard Rotation | b | H12 swap with an adjacent friendly ship during the wall | "without losing the damage reduction": nothing loses it today |
| Maren | T3a The Column Endures | b | H7 + H2 first ship each round with an emptied shield facing refills it to 25% | say "facing" |
| Maren | T3b Filed in Armor | a | `cmdTaken`: a ship that has not fired yet this round takes 15 points less | in Alternating mode a ship may fire after being hit; say "has not fired yet when hit" |
| Maren | Cap1 The Standard Covers All | x | none | the wall already refills every ship |
| Maren | Cap2 The Flagship Holds the Standard | x to b | flagship counts as part of any line; ships in its line +10% overcharge | depends on T1a's line and on overcharge |
| shared | B1a Formation Filed Before Battle | c | C3 formations | rewrite to bucket a: "ships that end their movement next to two friendly ships gain +10 aim" |
| shared | B1b Drill Revision One | b | H12 once per battle, after an enemy activation, move one ship up to 2 hexes | none |
| shared | C1a Flagship Registry Beacon | b | H1 + H2 once per round stamp an enemy (`B.mark` pattern): +10 aim | none |
| shared | C1b Standard Borne Forward | b | H11 +1 movement for a move that ends closer to the flagship | the bonus depends on the move it pays for; build as "+1 movement if every hex of the move is no further from the flagship" |

Vorn's Command: the texts call it Interdiction strike (index flag 7) and data.js shows "Reload and strike". Pick one before the Hegemony job.

### The Ashfall Hullbreakers

Commands: Grax surge (Full burn), Sable hunt (Knife in the dark), Mott scramble (Release the swarm), Vesh restore (Patch and weld). No lances; the Hulk is the carrier.

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Grax | T1a Run at the Biggest Thing | b | H2 distance to the largest enemy at activation start; ends closer: +15% this round | none |
| Grax | T1b Ram First | x to a | boarding version: a ship that moved 4 or more hexes in the burn boards at +25% strength (boardPct room) | rams never roll to hit, so "no accuracy penalty" does nothing. Read better on boarding |
| Grax | T2a The Pack Closes | x | none | friendly ships never block movement |
| Grax | T2b Ram Rush | x to b | boarding version: a ship that ends its burn next to an enemy may board even after firing (`boardTargets` relaxed) | a ram needs movement left and a run-up, so a ship that ended its move adjacent cannot ram; ramming never needed "instead of firing". Read better on boarding |
| Grax | T3a All Scars Forward | b | H11 +1 movement per enemy passed adjacent, up to +2 | the reach preview must count the bonus along each path; the hardest move hook in the set |
| Grax | T3b The Maw Opens | a | first ram per ship in the burn +30% (ramPct room) | works as a ram; works equally as boarding (+30% boardPct), which fits the faction better |
| Grax | Cap1 Burn Until the Hulls Meet | b | H3 the surge movement, turn and -20 accuracy carry into the next round | "movement phase" does not exist; say "next round" |
| Grax | Cap2 Run of the Warlord | b | H11 the flagship regains its movement once after its first move, and may ram (or board) after each move | read better on boarding: "may board after each move" |
| Sable | T1a Knife Finds the Back | a | hunt round: rear hits +15% (rearPct room) | none |
| Sable | T1b Torpedoes in the Dark | x to b | H15 enemy screen wings and flak intercept this round's torpedoes at half chance | "screened at -20 effect" is undefined |
| Sable | T2a Cut and Turn | b | H11 a free turn after a rear-arc hit, even though firing ended its movement | none |
| Sable | T2b Second Knife | b | H2 a torpedo that misses at impact sets its tube ready (cooldown 0) | none |
| Sable | T3a The Smile Before the Cut | x | none | the player already chooses which ship activates; no enemy acts "before" a chosen player ship in a way this changes |
| Sable | T3b Every Knife at Once | b | H2 three or more ships hit one target's rear this round; H15 its weapons -20 accuracy next round | none |
| Sable | Cap1 Dark Full of Knives | b | H3 the hunt bonus also covers each ship's first rear-arc shot next round | none |
| Sable | Cap2 The Cut That Feeds the Pack | b | H11 at Command time each ship auto-moves up to 2 hexes toward the nearest enemy's rear arc | same as Ostrel cap 2 (cross-faction duplicate) |
| Mott | T1a Patched Wing | b | H1 pick a launch ship; H6 its extra wing +25% and removed after its strike | none |
| Mott | T1b Hulk Holds More | b | H6 one of the largest non-carrier ships launches one wing | the title says Hulk but the Hulk is the carrier; non-carriers have no "held wing space" |
| Mott | T2a Re-Tasked Mid-Flight | x | none | wings already pick a new best target for the strike again |
| Mott | T2b Launched from the Wreck Line | b | H6 a launch ship with 0 hexes moved: its extra wings +15% | none |
| Mott | T3a The Whole Yard Flies | x | none | only launch ships have hangar space, so this is the base Command |
| Mott | T3b Wings Come Back Screaming | x | none | the +50% already applies to every wing hit that round, any target |
| Mott | Cap1 Swarm Over the Scrap Field | b | H6 the extra wings launch again at the end of the player's activations this round | "end of your turn" means nothing in Alternating mode; say "after your last activation this round" |
| Mott | Cap2 Old Mott Private Wing | x | none | extra wings already stay all battle and strike every round at full damage; as written it is a penalty |
| Vesh | T1a Weld What Matters | b | H9 one ship's section repair goes all to its most damaged section | none |
| Vesh | T1b Patch Over the Guns | x | none | the Command repairs every section at once; the order changes nothing |
| Vesh | T2a Scrap to the Front | b | H1 pick a ship; H9 the flagship's repair goes to it, doubled | none |
| Vesh | T2b Welded While Fighting | x | none | a repaired section already works at once |
| Vesh | T3a Double-Bolted Plate | b | H9 a section the Command repaired gets +20% section max for the battle | none |
| Vesh | T3b The Pack Bites On | b | H3 a ship lifted from below to above half hull: +15% next round | none |
| Vesh | Cap1 Welded Whole | b | H9 one broken section per ship restored to full | none |
| Vesh | Cap2 Nothing Stays Broken | c | C2 interrupt at the start of the enemy's turn | there is no enemy turn in Alternating mode; rewrite to an automatic trigger ("the first time one of your ships would lose a section") to drop to b |
| shared | B1a Prey Chosen by Scent | b | H1 name an enemy at battle start; +10 aim against it all battle | none |
| shared | B1b Loose Pack, Wide Lanes | x | none | friendly ships never block movement or fire |
| shared | C1a The Flagship Takes the First Scar | b | H16 once per battle, the flagship takes a hit aimed at an adjacent friendly (automatic on the first) | none |
| shared | C1b Trophy Standard | b | H11 after a flagship kill, every friendly ship gets one free turn | none |

Grax and boarding: the Muse finalization (index flag 1) restated Grax's boarding skills as rams because it believed "the battle rules do not have" boarding. They do: the Board order is shipped (`boardUnit`, `boardPct` is a live capped key, the Boarding Frenzy boon `h_board` uses it, and Hullbreakers board at 1.45x, the best in the game). Ram First and Ram Rush cannot work as rams at all and both read better on boarding. Run of the Warlord reads better on boarding. The Maw Opens works as a ram; boarding fits the faction better. Pick in questions file, question 3.

### The Chorus

Commands: Matriarch scramble (Spawning surge, even past the limit), Razormaw surge (Blood frenzy), Mending Throng restore (Regrowth tide), Voice barrage (Spitting volley). No shields.

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Matriarch | T1a Choose the Brood That Swells | b | H1 pick a brood; H6 it releases one more than the Command's count, the others none extra | at full power every brood already releases two; say "one more than the Command gives" |
| Matriarch | T1b Spores on the Tide | b | H6 extra swarms placed up to 2 hexes from the brood | none |
| Matriarch | T2a The Brood Splits | x | none | every swarm already picks its own target |
| Matriarch | T2b Spawned Before the Strike | x | none | the Command can already be used before moving; "screen your movement" is undefined |
| Matriarch | T3a Every Throat Opens | b | H6 a brood with 0 hexes moved: its extra swarms +25% | none |
| Matriarch | T3b The Second Throat Bites | b | H2 a swarm striking a target another swarm hit this round: +25% | none |
| Matriarch | Cap1 Nine Throats, One Hunger | x | none | only broods carry swarms (plus the Hive aspect), so this is the base Command |
| Matriarch | Cap2 The Brood Does Not Stop | x | none | extra swarms already stay and strike every round; "before fading" makes it a penalty |
| Razormaw | T1a Run Down the Slowest | a | frenzy round: +20% against a target slower than the attacker (dmgPct room) | none |
| Razormaw | T1b Teeth at the Throat | x to a | a ship behind an enemy already hits its rear arc; rewrite as a number on that first shot | no effect as written |
| Razormaw | T2a One Prey in Both Throats | b | H1 name a prey; H11 +1 movement for a move ending closer to it | same build note as Hegemony C1b |
| Razormaw | T2b Scent in the Dark | x | none | the frenzy accuracy protection is never lost today |
| Razormaw | T3a Frenzy Feeds the Throat | b | H11 a rear-arc hit in the frenzy: 2 more hexes of movement even after firing | none |
| Razormaw | T3b Breath Before the Bite | a | frenzy round: an enemy next to two or more of your ships -20 accuracy (hitChance term) | none |
| Razormaw | Cap1 The Throat Turns Red | b | H3 ships ending the round next to an enemy: +25% on their first shot next round | none |
| Razormaw | Cap2 One Prey, Every Mouth | b | H1 name a prey; H11 every ship may move straight toward it ignoring its turn limit once | none |
| Mending | T1a Grow Where It Hurts | b | H9 one ship's repair goes to one damaged section | none |
| Mending | T1b Skin Grown Thick | b | H10 a ship takes its regrowth as temporary hull, up to +15% | none |
| Mending | T2a The Tide Comes Early | x | none | the Command can already be used before any fire is taken |
| Mending | T2b Growth Holds the Wound | x to b | H3 sections healed by the tide heal again next round | sections never regrow by themselves today, so "double rate" has no base |
| Mending | T3a Flesh Knit for War | b | H3 a ship lifted above three quarters hull: +20% next round | none |
| Mending | T3b The Throat Refuses Holes | b | H3 round-start tick: while any ship is below half, the most damaged regrows 10% until it passes half | a passive skill (no Command needed), like Kassar's sync skills |
| Mending | Cap1 Tide Without End | b | H3 a second heal at half strength at the next round start | none |
| Mending | Cap2 What Was Torn Grows Back | b | H9 broken sections restored to full and cannot break again this battle | none |
| Voice | T1a Acid Before Aim | b | H5 volley target rule: nearest enemy instead of best | as a choice it is almost always worse; consider a number |
| Voice | T1b Every Throat Spits | b | H14 + H4 a ship with no gun bearing spits once at half damage at the nearest enemy in range, ignoring arc | none |
| Voice | T2a The Burn Stays | b | H15 acid at the next round start equal to 15% of the volley damage taken | the acid status today is a fixed 4 a turn; this needs an amount |
| Voice | T2b Spat in Two Rounds | x to b | H4 half the ships hold their spit until after they move this round | the title says "two rounds", the text says "after your ships move" |
| Voice | T3a Acid Finds the Seams | a | volley hits ignore armor on targets below half hull (`armorPierce` exists per weapon) | none |
| Voice | T3b Many Mouths at Once | b | H2 four or more ships spit at one target; H15 it gets -20 accuracy next round | "switch its target once" does nothing: volley targets are automatic |
| Voice | Cap1 The Volley That Grows | b | H4 every ship whose first spit hit spits again at half damage | none |
| Voice | Cap2 Mouth of the Deep | b | H1 pick a ship; H4 it fires every weapon twice at one target in range | say whether arcs still apply |
| shared | B1a Roles Assigned at Hatching | c | C4 ship roles | strike, screen and mend have no effect for capital ships; needs numbers |
| shared | B1b Broods in Reserve | b | H13 hold one brood; it enters at round 2 | "grown and ready" is undefined (with its swarms?) |
| shared | C1a The First Throat Opens | b | H17 once per battle, one more player activation right after the flagship's | in Classic mode it does nothing |
| shared | C1b Throat of the Deep | a | ships within 2 hexes of the flagship +10 aim (hitChance term, aim room) | none |

### Eclipse

Commands: Nadir restore (Release the repair swarms), Umbra barrage (Noon volley), Ostrel hunt (Out of the shadow; Eclipse has no torpedoes, so it is +30% damage), Seveth iron (Sunshade wall: hull cut only, no shield refill). Eclipse has no shields: no effect below grants, reads or touches an Eclipse shield. data.js texts are used (the Muse file still mentions shields twice).

| Admiral | Slot and skill | Bkt | Effect kind or hook | Wording problem |
|---|---|---|---|---|
| Nadir | T1a Restore from the Ninth Frame | b | H1 pick a ship; H9 it gets the full repair, the others half | "for the full repair amount" is unclear (100% hull, or the Command's normal amount?) |
| Nadir | T1b Copies Triage the Damage | x to b | H15 a section repaired to full also clears fire and acid | the order of repair changes nothing; fire and acid are ship statuses, not section ones |
| Nadir | T2a Iteration Runs During Fire | x | none | repair never delays fire |
| Nadir | T2b The Archive Answers First | x | none | the Command can already be used before any ship acts |
| Nadir | T3a Restored Beyond the Original | b | H9 a rebuilt section +20% section max for the battle | same effect as Vesh T3a |
| Nadir | T3b Every Copy Contributes | b | H1 + H9 the flagship's repair split among chosen ships (default: the most damaged) | "divided" how: evenly? |
| Nadir | Cap1 Tenth Frame | b | H1 + H9 one ship's repair tripled and one broken section back to full | none |
| Nadir | Cap2 The Earlier Copy Returns | b | H1 + H9 one ship repaired by the full amount on every section | data.js text is right; eclipse.md still adds "and its shields refill" |
| Umbra | T1a Arcs Written Warm | b | H15 a corona arc volley hit splashes 25% to one enemy next to the target | none |
| Umbra | T1b Noon Is a Choice | a | free volley +15% if no ship of yours has moved or fired yet this round | the timing half is already possible; keep only the condition and the number |
| Umbra | T2a The Copy Fires Again | b | H4 a ship whose volley kills its target fires one weapon at a new target | none |
| Umbra | T2b Target Archived Mid-Flight | x to b | H5 per-ship target choice | volley targets are automatic, so "switch once" does nothing without a pick; duplicates Vex T3a |
| Umbra | T3a Corona Without Shadow | a | volley ignores the nebula and debris accuracy penalties (hitChance terms) | "cover" has no meaning in the game beyond terrain |
| Umbra | T3b Every Frame at Noon | a | free volley from a ship with 0 hexes moved: +25% damage and +10 aim | none |
| Umbra | Cap1 Noon That Does Not Pass | b | H3 + H4 the free volley fires again at the next round start at half damage | none |
| Umbra | Cap2 One Sun, Copied | b | H4 each ship's volley is copied at half damage onto the enemy with the least hull | say whether range and arc apply |
| Ostrel | T1a Copied from Behind | a | hunt round: rear hits +20% (rearPct room) | none |
| Ostrel | T1b Unseen in the Archive | b | H2 a ship not targeted last round: +15% in the hunt round | none |
| Ostrel | T2a The Shadow Is a Position | x | none | the Command can already be used after movement |
| Ostrel | T2b Strike the Uncopied Target | b | H2 hits on an enemy not yet hit this battle: +15% | none |
| Ostrel | T3a Iteration of the Kill | b | H2 after a rear hit, the next hit on that target this round +20% | none |
| Ostrel | T3b Silent in the Archive | a | hunt round: a ship outside every enemy's front arc +15 evasion (checked live in hitChance) | none |
| Ostrel | Cap1 Out of Every Shadow | b | H3 the hunt bonus covers a second round for ships that end the round in an enemy's rear arc or untargeted | "in a rear arc" of what: say "an enemy's" |
| Ostrel | Cap2 The Long Copy Strikes | b | H11 at Command time each ship auto-moves up to 2 hexes toward an enemy's rear arc | same as Sable cap 2 |
| Seveth | T1a Plates over Shadow | b | H1 pick a ship; H8 it takes 75% less, the others 25% less | the wall grows each round held (50/60/70%); fixed numbers ignore that. Say "25 points more, the others 25 points less" |
| Seveth | T1b The Twice-Restored Order | b | H2 a ship repaired earlier this battle takes 15% less more | say what counts as repaired (Command, regrowth ticks, legion rise?) |
| Seveth | T2a Wall Archived in Advance | x | none | the Command can already be used first, and covers every shot that round |
| Seveth | T2b Layers Shift | b | H11 at the next round start each ship may shift 1 hex toward the flagship | none |
| Seveth | T3a No Layer Falls Alone | b | H8 the first hit each ship takes while the wall is active is absorbed, once per ship | data.js says "the first hit each ship takes in a battle", which never fires for a ship hit before the wall; say "while the wall is active". eclipse.md still has the shield version |
| Seveth | T3b Stillness Counted | b | H3 a ship with 0 hexes moved: +20 aim on its first shot next round | none |
| Seveth | Cap1 Wall of Ten Thousand Copies | b | H8 hull damage per ship per round capped at 25% of max hull | none |
| Seveth | Cap2 The Restored Fleet | b | H3 a ship repaired this round keeps the wall's cut into the next round | none |
| shared | B1a Formation Loaded from Archive | c | C3 formations | rewrite to bucket a: "ships that end their movement next to two friendly ships gain +10 evasion" |
| shared | B1b Iteration Swap | b | H12 once per battle, swap two ships | none |
| shared | C1a The Flagship Hosts the Index | b | H2 once per round, the flagship's shots at a target another ship fired at this round: +15% | none |
| shared | C1b Frame Zero | b | H4 + H2 the flagship's first missed shot each battle fires again at half damage | none |

## 6. Counts

| Faction | a | b | c | x | x with a one-line fix | Total |
|---|---|---|---|---|---|---|
| Glasswrights | 2 | 19 | 3 | 12 | 6 | 36 |
| Sunward Crusade | 2 | 23 | 1 | 10 | 3 | 36 |
| Hegemony Navy | 3 | 18 | 3 | 12 | 5 | 36 |
| Ashfall Hullbreakers | 2 | 21 | 1 | 12 | 3 | 36 |
| The Chorus | 4 | 22 | 1 | 9 | 3 | 36 |
| Eclipse | 5 | 24 | 1 | 6 | 2 | 36 |
| **All** | **18** | **127** | **10** | **61** | **22** | **216** |

After the one-line fixes: 22 in a, 145 in b, 10 in c, and 39 that need a new effect written. Each faction has between 6 and 12 texts with no working effect today, so every faction job starts with its own rewrite list.

Why so many x: the Muse finalization checked the texts against the data and effect names in data.js and core.js, but not against battle.js turn flow (index "Not checked": "No code was run"). Five patterns cover all 61:

1. **Timing that is already free** (14 texts): "declare at the start of the round", "after movement", "before any ship moves", "act before that enemy", "repair never delays fire". The Command can be used at any of your activations, its effect covers the whole round, and the player activates first.
2. **Refill or overflow beyond full** (8): every Brin and Maren refill text, Thale T1b. Iron refills every shield to full, so "give your refill to another ship", "+25% more refill" and "overflow" add nothing unless the game gets shield above max.
3. **Things wings and swarms already do** (11): they pick their own targets, retarget for the strike again, keep the +50% on any target, and Command extra wings stay all battle and strike every round.
4. **Things movement and fire already allow** (15): friendly ships never block movement or fire, enemy hexes can be passed for +1, Glasswrights already move after firing, nothing cancels the wall's cut, rams never roll to hit, the rear bonus already covers every weapon, Malek's torpedoes already reload every round, sync never needs the flagship to move.
5. **Undefined terms or a clash with a rule** (13): recorded paths, launch order, "crippling hit", "best aim modifier", "screened at -20 effect", "double rate" for sections, torpedoes that must strike before guns although they travel.

## 7. Text problems by owner

For Muse (wording, one job, blind Rey leg first per R89):

- Rewrite the 39 texts with no effect (every row marked plain x) so each pays a number on a condition the battle tracks. Section 6's five patterns are the brief.
- Apply the 22 one-line fixes (rows marked "x to a" or "x to b").
- Tighten the wording notes on bucket b rows (facing, "repaired", tiers that grow, arcs, Alternating mode).
- Correct eclipse.md: remove "and its shields refill" (Nadir cap 2) and use the data.js Seveth T3a, reworded to "while the wall is active". Eclipse has no shields; no Eclipse text may mention them.
- Cross-faction duplicates to keep or split on purpose: Vesh T3a and Nadir T3a (+20% section), Sable cap 2 and Ostrel cap 2 (2-hex move toward a rear arc), Vex T3a and Umbra T2b (per-ship volley target).
- Hegemony launch ships are not "carriers"; the Hulk is the Hullbreaker carrier (Mott T1b).
- "Point defence" in the game is the flak gauntlet: one spelling, one meaning.

For Ryan (picks, in the questions file): bucket c (build or rewrite), the playtest switch for trees, Grax boarding, how visible a skill is in battle, Vorn's Command name.

For the pilot job (data, no wording change): copy the five final Glasswrights texts into data.js (section 1).

## 8. Proof

### One parity fixture per skill

- **Shape.** One golden per skill in `godot/rules/test/scenarios.json` (the existing format: seed, admiral, fleet, enemies, map, `bot: "full"`), plus three new fields: `lineage` (the picks and capstone, copied into `RUN.lineage` by the harness), `cmdRound` (the round the bot uses the Command, so the skill's moment is certain) and `treeChoices` (the H1 answers; absent means the rules' default picker). The fleet and enemies are chosen so the skill's condition happens (for example a Tamsa fixture fields two Glasswright carriers; a Seveth T3a fixture puts an enemy in range on round 1).
- **Pass bar.** (1) Node (`node/golden.js` on the pinned oracle) and Godot write identical records, every number to the exact double, as today. (2) `B.treeStats[key] >= 1`, so the skill fired. (3) The same fixture without the pick differs from the one with it at or after the Command record, so the skill changed the fight. (2) and (3) go in a small node check beside `golden.js` and run in CI with the parity job (#283 added the campaign parity and Nemesis scenarios to CI; this adds a `tree` group).
- **Count.** 216 fixtures when every text is buildable; each faction job adds its own 36 (fewer while x texts wait for rewrites). The 200-battle sweep (`sweep_gen.js`) gets a `lineage` field drawn at random from the flown admiral's tree, so skills also meet each other and the boons.
- **Caps.** One sum fixture per new FX_CAPS key in `effect_caps_tests.js` and `effect_caps_test.gd`. A fixture that stacks a tree skill on a boon at the cap proves `treeAdd` adds nothing past it.
- **Campaign side.** `lineage_test.gd` and the campaign parity get one case: a run started with picks carries `RUN.lineage`, an old save without it loads and flies with no skills, and a respec between runs changes the next run only.
- **Balance.** After each faction lands, run the playtest-and-balance pack (admiral band, faction matrix) with every pick combination the bot can draw; report deltas only.

### What Ryan sees in a battle

- A callout over the ship in the faction colour, with the skill name and what it did ("Hard Light: section held"), the same way boons show today (`boonFx`).
- A log line: "Brin's lineage: Hard Light. The Lantern's shields hold its prow section."
- The after-battle recap lists each skill that fired and how often (from `B.treeStats`, like `B.boonStats`).
- In the Godot Command button tooltip, the picked skills that change this Command.
- For the pick skills (H1), a short prompt when the Command is used ("Name the prey"), with the default already highlighted.
- First screenshot round: the Glasswrights pilot, one shot per Glasswright admiral with a picked skill firing (callout plus log), through the screenshot-verdict pack on the PC.

## 9. Job split for the DeepSeek workhorse

One faction per job, both twins in the same PR (battle.js plus its oracle copy, core.js, data.js `TREE_FX`, rules.gd, the Godot export, the fixtures). Every job carries the R129 self-check list and gets the board's diff review plus impact sweep. Estimates are in workhorse runs (one run is one capped OpenCode session) and board review rounds, from the board's own history (LOOP.md, Nov 9): progression steps #27 (PR #302) and #29 (PR #304) each landed as one DeepSeek PR with one board review round plus small board fixes; the Nemesis job #120 needed a head-to-head of three arms before one merged. The pilot is larger than either because it carries the plumbing.

| Order | Job | Owner | What is in it | Runs | Review rounds | Waits on |
|---|---|---|---|---|---|---|
| 0 | Text pass | Muse (blind Rey leg first) | rewrites for all 61 x texts, the wording notes, eclipse.md shield fix, duplicates | 1 Muse job | 1 board read, then Ryan's read of the changed texts | Ryan's answers to questions 1 and 3 |
| 1 | Plumbing plus Glasswrights pilot | DeepSeek | H0 to H3 (snapshot, `B.tree`, `TREE_FX`, `treeAdd`, callout, recap counts, choice with default pickers, counters, next-round carry), the five data.js text updates, the Glasswrights a and b skills with fixtures, the Godot pick prompt and callouts | 2 to 3 | 2 | job 0 for the 12 Glasswrights x rewrites (its 21 a and b rows can start before it) |
| 2 | Sunward Crusade | DeepSeek | its a and b rows; new hooks H4, H6, H12, H13, H16 | 1 to 2 | 1 to 2 | job 1 merged |
| 3 | Eclipse | DeepSeek | its a and b rows; H8, H9, H11 | 1 to 2 | 1 to 2 | job 1 |
| 4 | The Chorus | DeepSeek | its a and b rows; H10, H17 | 1 to 2 | 1 to 2 | job 1 |
| 5 | Hullbreakers | DeepSeek | its a and b rows, boarding versions if Ryan picks them; H15 | 1 to 2 | 1 to 2 | job 1, question 3 |
| 6 | Hegemony Navy | DeepSeek | its a and b rows; sync hooks; Vorn's Command name | 1 to 2 | 1 to 2 | job 1, question 5 |
| 7 | Bucket c | Opus thread (C1 combined strike), Opus thread (C2 interrupt, touches the turn flow and Godot UI) | the 10 c texts, or none if Ryan picks rewrites | 1 each | 1 to 2 each, plus Rey's outside check (Opus code, R132) | Ryan's answer to question 1 |
| 8 | Balance pass | board | sims across all six factions with picks | 1 PC run | 1 | jobs 1 to 6 |

Jobs 2 to 6 can run two at a time on the PC once job 1 has merged, because each touches its own rows in `TREE_FX` and adds hooks in separate functions; the board merges them one at a time and reruns parity between merges. Order after the pilot follows the hook reuse: the Crusade builds the most shared hooks, Eclipse and the Chorus reuse them, Hullbreakers and Hegemony wait on Ryan's two picks.

If DeepSeek fails a job twice, V4 Pro gets one try (R134), then it goes to an Opus thread.

## 10. Risks

- **Parity cost.** Every hook touches a hot function (`hitChance`, `dmgMult`, `applyHit`, `startSideTurn`). Each term must be placed in the same order in both twins, or parity fails on the exact-double check. Mitigation: one helper per hook in each twin, called from one place.
- **Bot and sims.** The bot must make every H1 choice and the sims must not slow down. Default pickers live in the rules, so the browser oracle, the sims and Godot all pick the same way.
- **Frozen browser game.** The browser is the rules oracle and frozen except for rules fixes; tree effects are new rules, so they go into battle.js the same way progression step 1 went into core.js. Browser UI for picks is not built: the browser uses the default picker.
- **Power creep.** All 216 texts are bonuses. The step 1 caps bound each key, but not the sum of many keys. The balance pass (job 8) is the check; a faction that moves the admiral band by more than the noise gets its numbers trimmed in `TREE_FX`, never in the text first.
- **Playtest switch.** R69's switch unlocks admirals and hulls but not mastery, so today Ryan cannot pick a tree skill without about 75 XP on that admiral (230 for a capstone). See question 2.
