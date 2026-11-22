# Build variety: the full plan (issue 1453)

Status: **approved by Ryan (Nov 22, 11:59 UTC) with the recommended picks**; no code yet. Every pick still marked OPEN below is
now the approved pick. Ryan asked for many balance passes so every option is worth taking: section 13. Ryan (Nov 22, 08:53
UTC) asked for a full plan that Neon could review end to end and then write the names, lines and text for; Neon did (PR 1640).

**Neon review folded in (Nov 22, PR 1640).** Neon reviewed commit b56c67e7
(contrib/neon/reviews/build_variety_1453_review.md) and wrote every text slot
(contrib/neon/design/build_variety_1453_text.md). This version takes all ten of Neon's top findings: an authored Mastery I
table, seven Mastery III rows replaced and seven clarified, seven riders replaced or capped, riders follow a swapped Command,
relic, refit and ability edge cases settled, event chains need a small scheduler, and a new build order (Part E first). The
picks are still OPEN for Ryan. Rows Neon changed are marked (N).

Sources: data.js, battle.js, campaign_run.js at main 2eef4dd5 (Nov 22); the Neon player audit
(audits/neon_player_experience_1121.md, findings 7 and 9); RULEBOOK sections 1, 3.1 and 11. Line numbers move; names do not.

## 1. What Ryan will see when this is done

1. An admiral who reaches level 8 and keeps flying earns three real rewards at 320, 440 and 600 XP. None of them says
   "Placeholder".
2. Elite and boss fights, and the Sector 3 late market, offer relics that change how a fleet wants to fight, not only make
   it bigger.
3. Two admirals with the same Command button play differently from their first battle, because each Command carries a
   one-line rider in that admiral's voice.
4. Eclipse Fold skip and Chorus Blood frenzy each do their own thing, readable on screen.
5. (Later, optional) a few events that carry over two or three stops.

## 2. Ground truth today

| Area | Today | Where |
| --- | --- | --- |
| Capstone mastery | 3 steps at 320, 440, 600 XP; all three texts are "Placeholder: the mastery effect for this evolution is not written yet." No effect behind them. | data.js `CAPSTONE_MASTERY_XP`, `CAPSTONE_MASTERY_PERKS` |
| Capstones | 24 admirals, 2 capstones each (48). Each has a name, a line, and an effect key in `TREE_FX` (`<admiral>:cap:<0 or 1>`). | data.js `LINEAGE_TREES`, `TREE_FX` |
| Relics | 12 (`RELICS`). Elite fights offer a choice of 2, boss fights 3 (`_relicChoice`). The Sector 3 late market sells 2 (`LATE_SHOP`, skipping the economy ones). Mostly flat boosts. | data.js `RELICS`; campaign_run.js reward and late market |
| Refits | 13 (`MODULES`), 11 of them flat stat bumps. | data.js `MODULES` |
| Commands | 6 engines (barrage, hunt, scramble, iron, restore, surge), once per battle from round 1, stronger in later rounds (`cmdTier`, `CMD_POW`). 24 admirals: barrage 5, scramble 5, hunt 4, iron 4, restore 3, surge 3. | battle.js `useCommand`, `cmdDesc`; data.js `ADMIRALS` |
| Admiral trees | Each admiral's skill tree already changes their Command as they level (`TREE_FX`, `TREE_MAY` yes/no prompts). The "same button" problem is real only in an admiral's first runs. | data.js `LINEAGE_TREES`, `TREE_FX`, `TREE_MAY` |
| Copied abilities | Eclipse `phase` (Fold skip, on d_scythe, d_jackal and their variants) = `evasive`. Chorus `frenzy` (Blood frenzy, on b_razor and variants) = `focus`. The audit's note that `phase` is Glasswright is wrong: Glasswrights have their own `blink` (Phase jump). | data.js `ABILITIES`; rules.gd `useAbility`, AI at the `focus`/`evasive` checks |
| Event chains | 1 of 33 events carries to a later stop. | data.js `EVENTS` |

## 3. Design rules for every new effect

1. **It changes a decision**, not only a number: where to stand, what to shoot first, when to press the Command.
2. **Both rule copies** (browser and Godot, R312), with parity scenarios and campaign parity.
3. **Fair across sides.** A faction ability changes for player and enemy alike, and the enemy AI learns to use it (Ryan,
   Nov 20). Relics, riders and mastery are the player's own.
4. **Faction identity holds:** Glasswrights elite, never a swarm; Eclipse has no green; Chorus is the swarm and the
   feeding body.
5. **Readable.** Each effect has a floating word or a short log line when it fires, and its card text fits the card (limits
   in section 11).
6. **Balance by measurement.** The bot sims' win rate is already at its ceiling, so judge by rounds, hull left and ships lost
   (playtest-and-balance skill). Every number here is a draft until the sims back it.
7. **Saves.** New run fields default to absent, so old saves load unchanged (campaign save tests).

## 4. Part A: capstone mastery (OPEN: option C)

The three steps apply to whichever capstone the admiral chose at level 8.

| Step | XP | Effect (draft) | Why this shape |
| --- | --- | --- | --- |
| Mastery I (N) | 320 | The admiral's doctrine bonus (their always-on passive) goes up one step, from the authored table below. | A plain 1.25x breaks whole-number bonuses and makes Kassar's -5% worse, so each admiral gets a written row. |
| Mastery II (N) | 440 | The first Command each battle is given one tier stronger than the round allows, capped at the top tier. | Uses the existing tier system (`cmdTier`); every Command already prints its tier text. |
| Mastery III | 600 | A signature effect for the chosen capstone (table below). | The top step should feel like that admiral's own. |

Rules: Mastery III adds to the capstone; it never replaces it. Mastery II never applies to a second Command (the `spare`
relic). A respec that changes the capstone keeps the mastery steps earned and moves III to the new capstone.

### Mastery I table (N)

The rule behind the rows: a percent or flat bonus grows by about a quarter, rounded to a whole point; whole-number bonuses
(`torpCd`, `hangar`, `battShots`, `speed`) stay as they are, because their paired bonus grows instead; a penalty goes to 0;
Thorne, whose only bonus is evasion, gets +4. Evasion stays inside the 45 cap. Values from data.js `ADMIRALS` at main.

| Admiral | Today (`fx`) | Mastery I |
| --- | --- | --- |
| vex | broadPct .15 | broadPct .19 |
| malek | torpCd 1, rearPct .50 | torpCd 1, rearPct .63 |
| ashgrove | sqPct .40, hangar 1, sqHp .25 | sqPct .50, hangar 1, sqHp .31 |
| thale | hpPct .10, shPct .10 | hpPct .13, shPct .13 |
| kassar | battShots 1, dmgPct -.05 | battShots 1, dmgPct 0 |
| vorn | aim 10, crit 10 | aim 13, crit 13 |
| reyes | sqPct .10, hangar 1, sqHp .25 | sqPct .13, hangar 1, sqHp .31 |
| maren | hpPct .15, shPct .10 | hpPct .19, shPct .13 |
| grax | speed 1, dmgPct .10 | speed 1, dmgPct .13 |
| sable | rearPct .50, crit 10 | rearPct .63, crit 13 |
| mott | sqPct .25, hangar 1, sqHp .25 | sqPct .31, hangar 1, sqHp .31 |
| vesh | hullRegenPct .05, armor .10 | hullRegenPct .06, armor .13 |
| matriarch | sqPct .25, hangar 1, sqHp .25 | sqPct .31, hangar 1, sqHp .31 |
| razormaw | speed 1, rearPct .15 | speed 1, rearPct .19 |
| mending | hullRegenPct .04 | hullRegenPct .05 |
| voice | dmgPct .15 | dmgPct .19 |
| aelith | sqPct .25, hangar 1, sqHp .25 | sqPct .31, hangar 1, sqHp .31 |
| vaelen | lancePct .20, aim 10 | lancePct .25, aim 13 |
| thorne | ev 8 | ev 12 |
| mirelle | shPct .15, regenPct .20 | shPct .19, regenPct .25 |
| nekhet | hullRegenPct .04 | hullRegenPct .05 |
| sekhmar | lancePct .20, dmgPct .10 | lancePct .25, dmgPct .13 |
| anuket | rearPct .20, ev 10 | rearPct .25, ev 13 |
| khepra | hpPct .20 | hpPct .25 |

Kassar's row is the weakest step (a penalty removed). If the sims show it lagging, give Kassar battery aim +5 as well.

### Mastery III drafts (48)

Mechanics are drafts for Neon to review; names and lines are Neon's (section 11).

| Capstone key | Capstone | Mastery III mechanic (draft) |
| --- | --- | --- |
| aelith:cap:0 | Flight Cast Perfectly | The first wing strike each battle cannot miss and ignores shields. |
| aelith:cap:1 | The Forge Casts Ahead | The extra wing strike repeats at the start of the round after, at the same bonus. |
| vaelen:cap:0 | Sun Through One Lens | The concentrated target loses 10% armor for the rest of the battle. (N) Its own armor strip, clamped at 0 and separate from the 15% shred cap; does nothing to 0-armor hulls. |
| vaelen:cap:1 | The Flaw, Corrected Forever | The +15% applies to every weapon against that target, not only lances. |
| thorne:cap:0 | The Fleet Is Elsewhere | It triggers again on the first enemy shot of round 3. |
| thorne:cap:1 | A Hundred False Hulls | The false images also draw the first enemy torpedo of the scatter round. |
| mirelle:cap:0 | Ward of Clear Glass | The accuracy loss covers every shot that enemy fires that round, not only the next one. |
| mirelle:cap:1 | Every Facet Lit | (N) At round end while warded, leftover temporary hull also adds the same amount of overshield, up to 25% over max shields. The temporary hull is not removed. |
| vex:cap:0 | The Vesper Roll | The chosen enemy cannot brace this round. |
| vex:cap:1 | Final Reckoning | A second kill from the extra shot earns one more shot (once per ship). |
| malek:cap:0 | Salvo Without End | The second torpedo hits at full damage if it strikes a rear arc. |
| malek:cap:1 | The Named Prey Falls | If the prey survives, its mark carries into the next round at half strength. |
| ashgrove:cap:0 | The Roll of Wings | The fire spreads to one section next to the struck one. |
| ashgrove:cap:1 | Oath of Unbroken Wings | The escort wall intercepts two torpedoes per escorted ship, not one. |
| thale:cap:0 | Iron Standing Order | The wall holds a third round at half strength. |
| thale:cap:1 | The Wall That Moves | Ships may also turn once for free while the wall stands. |
| kassar:cap:0 | Living Relay | One other synced ship also projects sync, at normal radius. |
| kassar:cap:1 | Single Fire Solution | (N) The named target also loses 15% armor for the rest of the round (floor 0). Was point defense off, which copied reyes:cap:0 and barely helps batteries. |
| vorn:cap:0 | Interdiction, Permanent File | The carried bonus lasts two rounds, not one. |
| vorn:cap:1 | One Order, Every Gun | The second shot is at full damage when it hits the same target as the first. |
| reyes:cap:0 | One Target, Every Wing Filed | The designated enemy's point defense is off this round. |
| reyes:cap:1 | Standing Strike Group | The patrol wing may strike twice a round. (N) Up to 2 triggers a round, one per enemy move, never twice on the same move. |
| maren:cap:0 | The Standard Covers All | Half of the extra reduction stays for the round after the wall. |
| maren:cap:1 | The Flagship Holds the Standard | The overshield does not fade while the flagship lives. (N) Turn-start shield regen keeps the higher value (`Math.max`) instead of clamping to max. |
| grax:cap:0 | Burn Until the Hulls Meet | Rams in the carried round deal +25% damage. |
| grax:cap:1 | Run of the Warlord | Each successful board by the flagship repairs it 10%. |
| sable:cap:0 | Dark Full of Knives | That first rear-arc shot is always a critical hit. |
| sable:cap:1 | The Cut That Feeds the Pack | (N) Ships that make the 2-hex move also turn free toward the nearest foe and gain +10 aim this round. Was "ignores turn limits", which the move already does. |
| mott:cap:0 | Swarm Over the Scrap Field | The second launch's wings strike at +15% damage. |
| mott:cap:1 | Old Mott's Private Wing | The private wing survives the first hit that would destroy it. |
| vesh:cap:0 | Welded Whole | A restored section gets +20% armor for the rest of the battle. |
| vesh:cap:1 | Nothing Stays Broken | It works twice per battle. (N) Counted fleet-wide, not per ship. |
| matriarch:cap:0 | Nine Throats, One Hunger | The chosen enemy cannot move on its next turn. (N) No normal move and no ram; it can still turn, fire and blink. |
| matriarch:cap:1 | The Brood Does Not Stop | A swarm may chain twice, not once. |
| razormaw:cap:0 | The Throat Turns Red | The bonus covers every shot those ships fire next round. |
| razormaw:cap:1 | One Prey, Every Mouth | Ships that end the move next to the prey get +15% damage against it this round. |
| mending:cap:0 | Tide Without End | The second heal is at full strength. |
| mending:cap:1 | What Was Torn Grows Back | (N) A ship with a restored section regrows 2% max hull each round, once per ship, not per section. |
| voice:cap:0 | The Volley That Grows | The follow-up burst is at full damage against targets under half hull. |
| voice:cap:1 | Mouth of the Deep | The chosen ship's acid also strips 10% armor from its target. (N) Clamped at 0 and separate from the shred cap, like vaelen:cap:0. |
| nekhet:cap:0 | Tenth Frame | The chosen ship also gains +10 evasion next round. (N) Inside the 45 cap. |
| nekhet:cap:1 | The Earlier Copy Returns | (N) The repaired ship also resets its ability cooldown and takes 25% less hull damage until next round. Was full shields, which does nothing on Eclipse (no shields). |
| sekhmar:cap:0 | Noon That Does Not Pass | The echo fires a third round, at quarter damage. |
| sekhmar:cap:1 | One Sun, Copied | The copy lands on the two enemies with the least hull, not one. |
| anuket:cap:0 | Out of Every Shadow | (N) Ships covered by the bonus also gain +10% crit chance. Was +10 evasion, which mostly wastes into the 45 cap for Anuket. |
| anuket:cap:1 | The Long Copy Strikes | (N) Ships that made the move cannot be targeted from beyond range 3 until they fire or the round ends (the `refraction` pattern), so the enemy AI always has a target. |
| khepra:cap:0 | Wall of Ten Thousand Copies | Damage stopped by the cap returns as repair next round, at half. |
| khepra:cap:1 | The Restored Fleet | The kept reduction lasts two rounds. |

Build notes: one new data table (`CAPSTONE_MASTERY_FX`, keyed like `TREE_FX`), the three perk rows rewritten in
`CAPSTONE_MASTERY_PERKS`, effects in battle.js and rules.gd where each capstone already lives. Tests: one parity scenario per
faction with Mastery III on, plus a campaign test that the XP steps unlock and show.

## 5. Part B: new relics (OPEN: all 12)

Offer rules: all 12 join the elite and boss relic choice. The late market keeps skipping economy relics (Black ledger is
economy). `relicUseful` gets a line for each relic that needs a fleet shape (Spotter drones needs a launch ship; Ram
charter needs a ship that can ram).

| Draft id | Effect (draft numbers) | Play it rewards | Edge cases to settle |
| --- | --- | --- | --- |
| gunnery | Ships that did not move this turn deal +15% damage. | Hold a line and shoot | Turning in place counts as not moving. Wings excluded. (N) "Did not move" is `hexMoved` 0: being pushed by a tree effect does not count as moving. |
| afterburn | (N) A ship that spends all its movement (at least 1 hex) gains +10 evasion until its next turn. | Hit and run | (N) "All movement" is `mp` 0 with `hexMoved` at least 1, so engine damage does not block it. Inside the 45 cap. |
| flankmark | A rear-arc hit marks the target; marked ships take +15% damage from all your ships this round. | Flanking | One mark per target; marks clear at round end. (N) Adds to other mark bonuses; wing hits count. |
| spotter | An enemy hit by one of your wings takes +10% damage from your ships this round. | Wings and guns together | Needs a launch ship to be offered. (N) Needs a landed hit, not a miss; adds to flankmark. |
| lastlight | When your flagship drops below 30% hull or is destroyed, every other ship deals +20% damage for the rest of the battle. | Risky flagship play | Once per battle; does not stack with itself. (N) Stays on if the flagship is repaired; never offered to a 1-ship fleet. |
| coolant | Active ability cooldowns 1 shorter; each active use costs that ship 3% hull. | Trading hull for power | Stacks with Hand-wound plasma coils to a floor of 1. Cannot kill a ship (hull floor 1). (N) Carrier auto-launch never pays or counts; offered only when a ship has an active ability. |
| spare | The Command can be given a second time each battle, at tier 0. | Command-heavy admirals | Second use never earlier than the round after the first. (N) The second use gets no rider, no Mastery II and does not reopen once-per-battle capstones (`grandUsed`, `treeOneVoiceUsed`). Neon flags it as the likely strongest relic: measure first, drop it if it dominates. |
| ledger2 | +1 command point; (N) 10% fewer credits from battles, or 10% less biomass for the Chorus. | Bigger fleet over a richer one | Economy relic: skipped by the late market. (N) Without the biomass cut the Chorus paid nothing. |
| ram | Rams deal +50% damage and the rammer takes none of the recoil. | Ramming and boarding | (N) Offered only to a ram faction (`RAM_FAC`: Sunward, Hullbreakers, Chorus) or a fleet with an overburn ship; every hull can technically ram, so "a ship that can ram" was always true. Ram damage cap goes from 40% to 50% of target hull with this relic. |
| mirror | (N) The first hull hit each ship takes in a battle sends 50% of the hull damage back to the attacker. | Bait and tank | Reflected damage cannot be reflected again. (N) Ships only, never wings; hull damage only, after shields and armor; resolves after the volley and cannot kill (floor 1); bosses take at most 10% of their max hull per reflect. |
| beacon | (N) On round 1, every ship gains +2 movement and +1 turn. | Setting up the opening | (N) Was a free move before round 1, but deployment is fully automatic in both copies; this needs no new battle step. |
| quiet | Enemies cannot target your ships 6 or more hexes away during round 1. | Closing in safely | Does not block area effects or mines. (N) The AI must still advance normally; an AI sim with this relic checks no round-1 stall. |

Balance target: each relic, held alone, moves rounds, hull left or ships lost by about as much as today's middle relics
(Founders' compass, Alien shield matrix), measured in the campaign-rewards sim mode.

## 6. Part C: rule-bending refits (OPEN: all 4)

| Draft id | Effect | Cost | Fit rule |
| --- | --- | --- | --- |
| locker | Boarding actions +40%; (N) -1 speed, never below 2. | (N) 65 credits | Any ship that can board |
| chaser | (N) Any non-turret fore or flank weapon may fire one arc wider, at -20% damage. | 85 credits | (N) Ships with a fore or flank weapon. The flank-battery version fit only 8 of 42 hulls and none of three factions. |
| spill | When this ship's shields drop to zero, its next weapon attack deals +30%. | 70 credits | Ships with shields (not Chorus or Eclipse). (N) Does not stack with itself; clears at battle end. |
| relay | When this ship braces, one ally within 2 hexes not already covered also takes 20% less hull damage until its next turn. | 75 credits | (N) Ships that can brace (never Glasswrights, `noBrace`). Uses its own `relayCover`, so it never overwrites Sunward's 40% brace cover. Picks the most damaged ally. |

`canFitModule` gets one line per refit so an unusable refit is never offered to a ship (MOD-3 test).

## 7. Part D: Command riders (OPEN: yes, one per admiral)

A rider is one extra effect added when that admiral gives their Command, from level 1. It shows as one line under the
Command name on the button and in the Command tooltip. It does not grow with tiers. Where a rider and a tree skill touch the
same thing, the tree skill wins and the rider still applies (no double counting of the same bonus). A rider that adds to a
different bonus (Vex's +10% flank volley next to the tree's +15%) adds, and is not suppressed.

(N) **A rider follows the Command, not the admiral in the chair.** When Mastery III's `altCommand` swaps in another
admiral's Command (`RUN.cmdOverride`), that Command's own rider comes with it, so a swapped Command never carries a dead
rider. A parity test covers a run with `cmdOverride` set.

| Admiral | Command | Rider (draft mechanic) |
| --- | --- | --- |
| vex | barrage | Flank guns in the free volley deal +10% damage. |
| kassar | barrage | Battery shots in the free volley cannot miss. |
| voice | barrage | (N) Each volley hit strips 10% armor from its target for the round, once per target (was uncapped, which could strip all armor in one volley). |
| vaelen | barrage | Lances in the free volley strike the target's weakest section. |
| sekhmar | barrage | Targets hit by the volley lose 10 aim for 2 rounds. |
| malek | hunt | Torpedoes fired this round ignore point defense. |
| vorn | hunt | Each hit this round lowers its target's evasion by 5 until your next turn. |
| sable | hunt | Ships that hit a rear arc this round gain +10 evasion. |
| anuket | hunt | Ships that hit a rear arc this round gain +10% crit chance. |
| ashgrove | scramble | Launched wings start with +1 movement. |
| reyes | scramble | (N) Every wing's bonus attack strikes the enemy with the least hull left first (exact, so both rule copies agree). |
| mott | scramble | (N) Extra wings gain +10% crit chance this round. Was one more wing per hulk, which copies Mott's tree skill `wholeYard`. |
| matriarch | scramble | (N) Swarm hits this round heal their parent brood 3% hull. Was spawning next to the nearest enemy, which made the tree skill `sporeTide` pointless. |
| aelith | scramble | Wings ignore flak this round. |
| thale | iron | The wall also repairs 5% hull on every ship. |
| maren | iron | Ships next to the flagship take a further 10% less hull damage. |
| mirelle | iron | (N) Warded ships gain +15% max shields for the round. Was blocking the first hit, which is Khepra's tree skill at level 1. |
| khepra | iron | (N) Ships that brace or hold still repair 5% hull at round end. Was one more wall round, which is Thale's capstone. |
| vesh | restore | Each ship's worst section is fully patched. |
| mending | restore | The ship that regrows most also gets +10% damage this round. |
| nekhet | restore | (N) Repaired ships gain +5% armor until your next turn. Was rebuilding a destroyed escort, which copies an Eclipse faction rule and is far too strong at level 1. |
| grax | surge | (N) Ram recoil is cut in half this round. Was +30% ram damage, which is Grax's tree skill `mawOpens`. |
| razormaw | surge | Ships next to a wounded enemy gain +1 movement. |
| thorne | surge | Each ship may also turn to face any direction. |

Checked against today's Command text: Sunward and Eclipse hunt already reload torpedoes, and Sunward and Directorate iron already
refill shields, so no rider repeats those. (N) Neon's check against the live trees found seven more overlaps or overreaches,
now replaced above.

## 8. Part E: Fold skip and Blood frenzy (OPEN: option 1 for both)

| Ability | Today | New (draft) | AI rule (draft) | On screen |
| --- | --- | --- | --- | --- |
| Fold skip (Eclipse `phase`) | +25 evasion until next turn, +2 movement (same as Evasive burn) | The next weapon attack on this ship this round misses outright; +1 movement now. (N) Cooldown 4. | (N) Use after moving, or before moving only when an enemy that can reach the destination hex has a ready weapon, or when under half hull. | A violet after-image on the old hex; the missed shot reads "Folded" in violet `#b894ff`. |
| Blood frenzy (Chorus `frenzy`) | +30% damage this turn (same as Concentrated fire) | +20% damage this turn, and the ship regrows hull equal to 30% of the hull damage it deals, (N) at most 20% of its max hull per turn. Cooldown 3. | (N) Use at aim when a ready gun can fire and hull is below 95%; otherwise like focus. | The floating word stays "Blood frenzy"; regrowth shows as the usual Chorus regrow tick. |

(N) Why cooldown 4: every Scythe and Jackal carries Fold skip, so at cooldown 3 a group of them would blank the player's big
guns too often, and the Hand-wound plasma coils would drop it to 2. "Next weapon attack" includes torpedoes and wing
strikes, not area blasts or mines.

(N) Eclipse colour fix that rides along: today `phase` prints "Phase shift" in green `#7dff9b` (battle.js `useAbility`, rules.gd
`_useAbility_raw`). Eclipse has no green anywhere (Ryan, Nov 21). The Board also found green `#7dff9b` on the Eclipse revive
callouts ("Reassembled", "Reassembling: rises next round", battle.js near the revive and legion code). Part E recolours every
Eclipse callout in both copies, not only Fold skip.

Alternatives kept for review: Fold skip as "swap places with another Eclipse ship within 4" (harder for the AI); Blood frenzy
as "+30%, +10% per enemy within 2 hexes, takes +15% damage until its next turn".

## 9. Part F: event chains (OPEN: later)

(N) Today's one link (defector to saboteur) is an optional choice inside a random draw, not a follow-up that waits a set
number of stops. Part F therefore adds a small queue in both campaign copies (`RUN.eventQueue`, entries
`{evId, afterStops}`), absent in old saves. The first draft premises repeated four events that already exist (beacon, bait,
defector, derelict), so Neon wrote four new ones (10 cards, text file section 9):

1. The Limping Tender (2 cards): escort a crippled tender now; two stops later it pays out (credits and repair, salvage, or
   a Nemesis weakness), or strip it at once for salvage and a faster Nemesis clock.
2. The Factor's Note (3 cards).
3. The Coded Chart (2 cards).
4. The Silent Vault-Hulk (3 cards).

## 10. Build order, checks and size

(N) Neon's order, taken: the small faction-ability fix goes first, because players see the copied abilities (and the green
Eclipse text) in every Eclipse and Chorus fight today, and it gives a balance read before new player power piles on.

| Order | Part | Checks | Size (agent runs, from this board's history) |
| --- | --- | --- | --- |
| 1 | Fold skip and Blood frenzy (E) | parity scenarios, enemy AI sim, picture of each on screen | about 1 run + 1 review round |
| 2 | Capstone mastery (A) | rules parity scenario per faction, campaign parity, a mastery unlock test, picture of the three steps on the lineage screen | about 3 runs + 1 review round |
| 3 | Command riders (D) | one parity scenario per Command engine, the swapped-Command rider test, tooltip picture | about 2 runs + 1 review round |
| 4 | Relics and refits (B and C) | parity scenarios for the combat relics, campaign parity, MOD-3 and relic offer tests, sims (rounds, hull left, ships lost), quiet AI sim | about 3 runs + 1 review round |
| 5 | Event chains (F, if picked) | campaign parity, event distribution test, queue save and load | about 2 runs |

Each part is its own pull request, in both rule copies, with balance deltas reported.

Coverage checks on top of the scenarios (Artoo on PR 1635): the per-faction and per-engine parity scenarios exercise the
shared path, not every row, so each part also ships a cheap exhaustive check.

- **Key coverage:** every one of the 48 capstone keys has exactly one Mastery III row and a handler in both rule copies;
  every one of the 24 admirals has exactly one rider row, under the admiral who owns it, with a handler; every new relic
  and refit id has a handler and a text row. A missing, extra or misplaced key fails.
- **Earn, save, respec, reload:** one fixture earns Mastery III, saves, respecs to the other capstone, reloads, and checks
  that only the new capstone's Mastery III is active (never both, never neither).
- (N) **Swapped Command rider:** a run with `RUN.cmdOverride` set proves the rider that fires is the swapped Command's own.
- (N) **Offer gates:** `relay` is never offered to Glasswrights, `spill` never to Chorus or Eclipse, `ram` never to
  Glasswrights, `coolant` never to a fleet whose only ability is launch, and `lastlight` never to a 1-ship fleet.

## 11. Text (written by Neon)

(N) All the text is written: contrib/neon/design/build_variety_1453_text.md (PR 1640), against the mechanics as changed above.
It uses today's display names (Sunward Crusade, Meridian Directorate, Ashfall Hullbreakers, the Chorus, the Glasswrights,
Eclipse) and "salvage" for relics in player text, has no em dashes, and keeps every slot inside its limit. The build parts
copy their text from that file. Floating words came to 12, each with a colour (Folded is violet, never green).

| Slot | How many | Where it shows | Limit |
| --- | --- | --- | --- |
| Mastery step titles (I, II, III) | 3 | Lineage screen, mastery row | 24 characters |
| Mastery I and II lines | 2 | Lineage screen tooltip | 120 characters |
| Mastery III names | 48 | Lineage screen, under the capstone | 32 characters |
| Mastery III lines | 48 | Lineage tooltip, battle log when it fires | 140 characters |
| Relic names | 12 | Reward cards, late market, fleet screen | 28 characters |
| Relic effect lines | 12 | Same cards | 110 characters |
| Relic flavour lines | 12 | Card footer | 90 characters |
| Refit names and lines | 4 + 4 | Refit cards | 28 / 110 characters |
| Command rider lines | 24 | Command button and tooltip | 70 characters |
| Ability names and lines | 2 + 2 | Ship panel, ability button | 24 / 110 characters |
| Floating words | 12 | Over ships in battle | 14 characters |
| Event chain text (if picked) | 4 chains, 10 cards | Event cards | as today's events |

Not written yet, and not asked for: per-faction name variants for the new relics and refits (today's `RELIC_NAMES` and
`MOD_NAMES` tables). The relic and refit part writes those, or uses the base names.

## 12. Review status

Neon reviewed the full plan (contrib/neon/reviews/build_variety_1453_review.md, commit b56c67e7) against the five checks this
section asked for, and every finding is folded in above. Neon did not run the game, the sims or the save tests, and did not
measure text on screen; each build part does those. What is left for Ryan is the OPEN picks.

## 13. Balance passes (Ryan, Nov 22)

Ryan approved the whole plan with the recommended picks (Nov 22, 11:59 UTC: "Yeah I like it all, I just think we'll need to do
a ton of balance passes and checks on it because some seem great and others seem relatively meaningless like +1 to arc but
reduce damage"). The rule that follows: **every option must be worth taking**. A relic, refit, rider or Mastery step that a
player would skip is as much a failure as one that dominates.

How each build part proves it, on fresh sims (the balance sim was fixed on the morning of Nov 22, so older numbers do not
count):

1. **Measure every option alone**, against a run without it, in `node sim3d.js campaign` (rounds, hull left, ships lost; win
   rate is at its ceiling and is not the measure), with the sample size in the report.
2. **A band, not a single number.** Today's middle relics (Founders' compass, Alien shield matrix) set the band. An option
   below the band is buffed or redesigned in the same part; one above it is cut back. Nothing ships outside the band.
3. **Weak-looking options first.** Each part names the options that look thin on paper and measures them first, so a
   redesign lands before text and pictures. Already flagged:
   - `chaser` (one arc wider at -20% damage): Ryan's example. If it measures low, drop the penalty (full damage in the wider
     arc) before adding anything new.
   - `gunnery`, `afterburn`, `spotter`, `quiet` and `beacon` (small or round-1-only effects); `locker` (boarding only);
     Kassar's Mastery I row (a penalty removed); every "+10 aim" or "+5% armor" rider.
4. **Strong-looking options get the same check from the other side:** `spare`, `mirror`, `lastlight`, `coolant`, Mastery II.
5. **A second pass after all parts land**, with every new option in the pool together, to catch pairs that stack badly
   (for example `flankmark` with `spotter`, or `spare` with Command-heavy admirals).
6. **Report** as the playtest-and-balance skill says: deltas only, one row per option, the mode and sample size. The
   report goes in the part's pull request and the option table in this plan gets a "measured" column.

Size: each part gains about one more run for its balance pass; the final pass is about 1 run plus a PC sim job if the
cloud sim is too slow.
