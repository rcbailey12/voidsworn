# Build variety: the full plan (issue 1453)

Status: plan for review. No code yet. Ryan (Nov 22, 08:53 UTC) asked for a full plan that Neon can review end to end and then
write the names, lines and text for. Every pick marked **OPEN** is a working assumption (the Board's recommendation in the
short design pack), not a ruling. Ryan's earlier OK (Nov 21, "Yes on all" to call 4) covers doing this work as a design pack
first.

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
| Mastery I | 320 | The admiral's doctrine bonus (their always-on passive) grows by a quarter. Example: Vex's +15% flank damage becomes +19%. | One rule for all 24 admirals; it uses numbers that already exist, so nothing new to explain. |
| Mastery II | 440 | The Command is given one tier stronger than the round allows, once per battle. | Uses the existing tier system (`cmdTier`); every Command already prints its tier text. |
| Mastery III | 600 | A signature effect for the chosen capstone (table below). | The top step should feel like that admiral's own. |

Rules: Mastery III adds to the capstone; it never replaces it. Tier II caps at the top tier (no tier above the last). A
respec that changes the capstone keeps the mastery steps earned and moves III to the new capstone.

### Mastery III drafts (48)

Mechanics are drafts for Neon to review; names and lines are Neon's (section 11).

| Capstone key | Capstone | Mastery III mechanic (draft) |
| --- | --- | --- |
| aelith:cap:0 | Flight Cast Perfectly | The first wing strike each battle cannot miss and ignores shields. |
| aelith:cap:1 | The Forge Casts Ahead | The extra wing strike repeats at the start of the round after, at the same bonus. |
| vaelen:cap:0 | Sun Through One Lens | The concentrated target loses 10% armor for the rest of the battle. |
| vaelen:cap:1 | The Flaw, Corrected Forever | The +15% applies to every weapon against that target, not only lances. |
| thorne:cap:0 | The Fleet Is Elsewhere | It triggers again on the first enemy shot of round 3. |
| thorne:cap:1 | A Hundred False Hulls | The false images also draw the first enemy torpedo of the scatter round. |
| mirelle:cap:0 | Ward of Clear Glass | The accuracy loss covers every shot that enemy fires that round, not only the next one. |
| mirelle:cap:1 | Every Facet Lit | Temporary hull still left when the ward ends becomes shield strength. |
| vex:cap:0 | The Vesper Roll | The chosen enemy cannot brace this round. |
| vex:cap:1 | Final Reckoning | A second kill from the extra shot earns one more shot (once per ship). |
| malek:cap:0 | Salvo Without End | The second torpedo hits at full damage if it strikes a rear arc. |
| malek:cap:1 | The Named Prey Falls | If the prey survives, its mark carries into the next round at half strength. |
| ashgrove:cap:0 | The Roll of Wings | The fire spreads to one section next to the struck one. |
| ashgrove:cap:1 | Oath of Unbroken Wings | The escort wall intercepts two torpedoes per escorted ship, not one. |
| thale:cap:0 | Iron Standing Order | The wall holds a third round at half strength. |
| thale:cap:1 | The Wall That Moves | Ships may also turn once for free while the wall stands. |
| kassar:cap:0 | Living Relay | One other synced ship also projects sync, at normal radius. |
| kassar:cap:1 | Single Fire Solution | The named target's point defense is off for the rest of the round. |
| vorn:cap:0 | Interdiction, Permanent File | The carried bonus lasts two rounds, not one. |
| vorn:cap:1 | One Order, Every Gun | The second shot is at full damage when it hits the same target as the first. |
| reyes:cap:0 | One Target, Every Wing Filed | The designated enemy's point defense is off this round. |
| reyes:cap:1 | Standing Strike Group | The patrol wing may strike twice a round. |
| maren:cap:0 | The Standard Covers All | Half of the extra reduction stays for the round after the wall. |
| maren:cap:1 | The Flagship Holds the Standard | The overshield does not fade while the flagship lives. |
| grax:cap:0 | Burn Until the Hulls Meet | Rams in the carried round deal +25% damage. |
| grax:cap:1 | Run of the Warlord | Each successful board by the flagship repairs it 10%. |
| sable:cap:0 | Dark Full of Knives | That first rear-arc shot is always a critical hit. |
| sable:cap:1 | The Cut That Feeds the Pack | The 2-hex move ignores turn limits. |
| mott:cap:0 | Swarm Over the Scrap Field | The second launch's wings strike at +15% damage. |
| mott:cap:1 | Old Mott's Private Wing | The private wing survives the first hit that would destroy it. |
| vesh:cap:0 | Welded Whole | A restored section gets +20% armor for the rest of the battle. |
| vesh:cap:1 | Nothing Stays Broken | It works twice per battle. |
| matriarch:cap:0 | Nine Throats, One Hunger | The chosen enemy cannot move on its next turn. |
| matriarch:cap:1 | The Brood Does Not Stop | A swarm may chain twice, not once. |
| razormaw:cap:0 | The Throat Turns Red | The bonus covers every shot those ships fire next round. |
| razormaw:cap:1 | One Prey, Every Mouth | Ships that end the move next to the prey get +15% damage against it this round. |
| mending:cap:0 | Tide Without End | The second heal is at full strength. |
| mending:cap:1 | What Was Torn Grows Back | Restored sections also regrow 2% hull each round. |
| voice:cap:0 | The Volley That Grows | The follow-up burst is at full damage against targets under half hull. |
| voice:cap:1 | Mouth of the Deep | The chosen ship's acid also strips 10% armor from its target. |
| nekhet:cap:0 | Tenth Frame | The chosen ship also gains +10 evasion next round. |
| nekhet:cap:1 | The Earlier Copy Returns | The repaired ship also returns to full shields. |
| sekhmar:cap:0 | Noon That Does Not Pass | The echo fires a third round, at quarter damage. |
| sekhmar:cap:1 | One Sun, Copied | The copy lands on the two enemies with the least hull, not one. |
| anuket:cap:0 | Out of Every Shadow | Ships covered by the bonus also gain +10 evasion. |
| anuket:cap:1 | The Long Copy Strikes | Ships that made the move cannot be targeted until they fire or the round ends. |
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
| gunnery | Ships that did not move this turn deal +15% damage. | Hold a line and shoot | Turning in place counts as not moving. Wings excluded. |
| afterburn | A ship that used its full speed this turn gains +10 evasion until its next turn. | Hit and run | Speed boosts count toward "full". |
| flankmark | A rear-arc hit marks the target; marked ships take +15% damage from all your ships this round. | Flanking | One mark per target; marks clear at round end. |
| spotter | An enemy hit by one of your wings takes +10% damage from your ships this round. | Wings and guns together | Needs a launch ship to be offered. |
| lastlight | When your flagship drops below 30% hull, every other ship deals +20% damage for the rest of the battle. | Risky flagship play | Once per battle; does not stack with itself. |
| coolant | Ability cooldowns 1 shorter; each use costs that ship 3% hull. | Trading hull for power | Stacks with Hand-wound plasma coils to a floor of 1. Cannot kill a ship (hull floor 1). |
| spare | The Command can be given a second time each battle, at tier 0. | Command-heavy admirals | Second use never earlier than the round after the first. Tree "you may" prompts ask again. |
| ledger2 | +1 command point; 10% fewer credits from battles. | Bigger fleet over a richer one | Economy relic: skipped by the late market. |
| ram | Rams deal +50% damage and the rammer takes none of the recoil. | Ramming and boarding | Needs a ship that can ram to be offered. |
| mirror | The first hit each ship takes in a battle sends 50% of its damage back to the attacker. | Bait and tank | Reflected damage cannot be reflected again; wings reflect too. |
| beacon | Before round 1, every ship may move up to 2 hexes. | Setting up the opening | Uses the deployment step; no move into hazards or enemy-adjacent hexes. |
| quiet | Enemies cannot target your ships 6 or more hexes away during round 1. | Closing in safely | Does not block area effects or mines. |

Balance target: each relic, held alone, moves rounds, hull left or ships lost by about as much as today's middle relics
(Founders' compass, Alien shield matrix), measured in the campaign-rewards sim mode.

## 6. Part C: rule-bending refits (OPEN: all 4)

| Draft id | Effect | Cost | Fit rule |
| --- | --- | --- | --- |
| locker | Boarding actions +40%. | -1 speed | Any ship that can board |
| chaser | The flank battery may also fire into the rear arc at -20% damage. | 85 credits | Ships with a flank battery |
| spill | When this ship's shields drop to zero, its next shot deals +30%. | 70 credits | Ships with shields |
| relay | When this ship braces, one ally within 2 hexes also takes 20% less hull damage until its next turn. | 75 credits | Any ship |

`canFitModule` gets one line per refit so an unusable refit is never offered to a ship (MOD-3 test).

## 7. Part D: Command riders (OPEN: yes, one per admiral)

A rider is one extra effect added when that admiral gives their Command, from level 1. It shows as one line under the
Command name on the button and in the Command tooltip. It does not grow with tiers. Where a rider and a tree skill touch the
same thing, the tree skill wins and the rider still applies (no double counting of the same bonus).

| Admiral | Command | Rider (draft mechanic) |
| --- | --- | --- |
| vex | barrage | Flank guns in the free volley deal +10% damage. |
| kassar | barrage | Battery shots in the free volley cannot miss. |
| voice | barrage | Each volley hit strips 10% armor from its target for the round. |
| vaelen | barrage | Lances in the free volley strike the target's weakest section. |
| sekhmar | barrage | Targets hit by the volley lose 10 aim for 2 rounds. |
| malek | hunt | Torpedoes fired this round ignore point defense. |
| vorn | hunt | Each hit this round lowers its target's evasion by 5 until your next turn. |
| sable | hunt | Ships that hit a rear arc this round gain +10 evasion. |
| anuket | hunt | Ships that hit a rear arc this round gain +10% crit chance. |
| ashgrove | scramble | Launched wings start with +1 movement. |
| reyes | scramble | Every wing's bonus attack strikes the same target first. |
| mott | scramble | Each hulk launches one more wing, once per battle. |
| matriarch | scramble | New swarms spawn next to the enemy nearest them. |
| aelith | scramble | Wings ignore flak this round. |
| thale | iron | The wall also repairs 5% hull on every ship. |
| maren | iron | Ships next to the flagship take a further 10% less hull damage. |
| mirelle | iron | The first hit on each ship this round is blocked. |
| khepra | iron | The wall lasts one more round. |
| vesh | restore | Each ship's worst section is fully patched. |
| mending | restore | The ship that regrows most also gets +10% damage this round. |
| nekhet | restore | One destroyed escort rebuilds at 20% hull (once per battle). |
| grax | surge | Rams this round deal +30% damage. |
| razormaw | surge | Ships next to a wounded enemy gain +1 movement. |
| thorne | surge | Each ship may also turn to face any direction. |

Checked against today's Command text: Sunward and Eclipse hunt already reload torpedoes, and Sunward and Hegemony iron already
refill shields, so no rider repeats those.

## 8. Part E: Fold skip and Blood frenzy (OPEN: option 1 for both)

| Ability | Today | New (draft) | AI rule (draft) | On screen |
| --- | --- | --- | --- | --- |
| Fold skip (Eclipse `phase`) | +25 evasion until next turn, +2 movement (same as Evasive burn) | The next attack on this ship this round misses outright; +1 movement now. Cooldown 3. | Use before moving when an enemy that can reach it has a ready weapon, or when under half hull. | A violet after-image on the old hex; the missed shot reads "Folded". |
| Blood frenzy (Chorus `frenzy`) | +30% damage this turn (same as Concentrated fire) | +20% damage this turn, and the ship regrows hull equal to 30% of the damage it deals. Cooldown 3. | Use when it can fire at a target this turn and is below full hull; otherwise like focus. | The floating word stays "Blood frenzy"; regrowth shows as the usual Chorus regrow tick. |

Alternatives kept for review: Fold skip as "swap places with another Eclipse ship within 4" (harder for the AI); Blood frenzy
as "+30%, +10% per enemy within 2 hexes, takes +15% damage until its next turn".

## 9. Part F: event chains (OPEN: later)

Four candidates, each 2 or 3 stops, using the one chain that exists today as the pattern:

1. The quiet distress call: answer a beacon; later escort the crippled ship home (credits) or strip it (a relic).
2. The debt collector: borrow credits now; two stops later pay, fight or bribe the collector.
3. The defector: an enemy captain offers intel; at the next stop it proves true or a trap.
4. The old wreck: a map fragment points to a derelict two stops on, holding a boss-grade relic and a guard fleet.

## 10. Build order, checks and size

| Order | Part | Checks | Size (agent runs, from this board's history) |
| --- | --- | --- | --- |
| 1 | Capstone mastery | rules parity scenario per faction, campaign parity, a mastery unlock test, picture of the three steps on the lineage screen | about 3 runs + 1 review round |
| 2 | Relics and refits | parity scenarios for the combat relics, campaign parity, MOD-3 and relic offer tests, sims (rounds, hull left, ships lost) | about 3 runs + 1 review round |
| 3 | Command riders | one parity scenario per Command engine, tooltip picture | about 2 runs + 1 review round |
| 4 | Fold skip and Blood frenzy | parity scenarios, enemy AI sim, picture of each on screen | about 1 run + 1 review round |
| 5 | Event chains (if picked) | campaign parity, event distribution test | about 2 runs |

Each part is its own pull request, in both rule copies, with balance deltas reported.

Coverage checks on top of the scenarios (Artoo on PR 1635): the per-faction and per-engine parity scenarios exercise the
shared path, not every row, so each part also ships a cheap exhaustive check.

- **Key coverage:** every one of the 48 capstone keys has exactly one Mastery III row and a handler in both rule copies;
  every one of the 24 admirals has exactly one rider row, under the admiral who owns it, with a handler; every new relic
  and refit id has a handler and a text row. A missing, extra or misplaced key fails.
- **Earn, save, respec, reload:** one fixture earns Mastery III, saves, respecs to the other capstone, reloads, and checks
  that only the new capstone's Mastery III is active (never both, never neither).

## 11. Text Neon writes

Tone: the game's own voice (short, concrete, no jokes that break the war). No em dashes. Card limits are what fits today's
cards without wrapping past three lines.

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
| Floating words | about 10 (Folded, Marked, Last light, and so on) | Over ships in battle | 14 characters |
| Event chain text (if picked) | 4 chains, about 10 cards | Event cards | as today's events |

## 12. What Neon should check

1. Any mechanic that is unclear, too strong, too weak, or breaks a faction's identity.
2. Any rider or Mastery III that repeats what the admiral's tree or Command already does.
3. Any edge case section 5 missed (stacking, wings, bosses, the enemy side).
4. Whether the build order is right.
5. Then the text in section 11, written against the final mechanics.
