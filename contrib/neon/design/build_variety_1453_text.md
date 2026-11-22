# Build Variety Pack: Section 11 Text (Issue 1453, PR 1635)

**Written for:** `contrib/opus/design/build_variety_1453/PLAN.md` (commit `b56c67e7`, branch `opus/issue-1453`)  
**Author:** Neon (`neon/issue-1636`)  
**Conventions:** Every text cell is pure, copy-paste-ready game copy written against the fixed mechanics in `contrib/neon/reviews/build_variety_1453_review.md`. Uses current display names (`Sunward Crusade`, `Meridian Directorate`, `Ashfall Hullbreakers`, `The Chorus`, `The Glasswrights`, `Eclipse`) and `salvage` for player-facing relic prose. No em dashes. Every cell is strictly within its Section 11 character cap.

---

## 1. Mastery Step Titles (3 slots, max 24 chars)

| Step | Title (<=24) |
| --- | --- |
| Mastery I (320 XP) | Proven Doctrine |
| Mastery II (440 XP) | Seasoned Command |
| Mastery III (600 XP) | Signature Evolution |

---

## 2. Mastery I and II Lines (2 slots, max 120 chars)

| Step | Tooltip Line (<=120) |
| --- | --- |
| Mastery I | Raises this admiral's doctrine bonus by one step (removes penalties and strengthens paired stats). |
| Mastery II | Once per battle, your first Command fires one tier stronger than the current round allows (up to tier 2). |

---

## 3. Mastery III Names and Lines (48 + 48 slots, max 32 / 140 chars)

Written in exact `PLAN.md` Section 4 table order. The `Spec` column flags rows revised by `build_variety_1453_review.md`.

| Capstone Key | Mastery III Name (<=32) | Mastery III Line (<=140) | Spec |
| --- | --- | --- | --- |
| `aelith:cap:0` | Unbroken Aperture | Your first wing strike each battle cannot miss and bypasses shields. | Plan |
| `aelith:cap:1` | Second Casting | The extra wing strike repeats at the start of the following round with the same damage bonus, if the wing still flies. | Plan |
| `vaelen:cap:0` | Scored Through the Core | The concentrated target loses 10% armor for the rest of the battle (down to 0%). | Clarified |
| `vaelen:cap:1` | Every Beam Aligned | The +15% damage mark applies to all your weapons against that target, not only lances. | Plan |
| `thorne:cap:0` | Mirror Twice Drawn | Triggers a second time on the first enemy shot of round 3. | Plan |
| `thorne:cap:1` | Veil of False Hulls | During the scatter round, the false images also draw away the first enemy torpedo volley. | Plan |
| `mirelle:cap:0` | Glare Across the Glass | The accuracy loss lasts for every shot that enemy fires this round, not only its next shot. | Plan |
| `mirelle:cap:1` | Stored in the Facets | At round end while warded, leftover temporary hull also adds equal overshield (up to +25% max shields). | Revised |
| `vex:cap:0` | No Shelter on the Roll | The enemy named on the roll cannot Brace this round. | Plan |
| `vex:cap:1` | Settled in Full | A second kill from that extra shot grants one final follow-up shot (once per ship). | Plan |
| `malek:cap:0` | Through the Stern Plates | The second torpedo hits at full damage whenever it strikes a rear arc. | Plan |
| `malek:cap:1` | Debt Carried Forward | If the named prey survives, its damage mark carries into the next round at half strength. | Plan |
| `ashgrove:cap:0` | Running Deck Fires | Wing fires spread to one adjacent hull section on the struck target. | Plan |
| `ashgrove:cap:1` | Double Escort Screen | The escort wall intercepts two torpedoes per covered ship this round, not one. | Plan |
| `thale:cap:0` | Third Watch Standing | Iron wall holds for a third round at half damage reduction. | Plan |
| `thale:cap:1` | Pivot in the Iron Line | Ships under the wall may also turn once for free each activation. | Plan |
| `kassar:cap:0` | Secondary Sync Node | One other synced ship also projects the sync net at normal radius. | Plan |
| `kassar:cap:1` | Breached Solution | The named target also loses 15% armor for the rest of the round (down to 0%). | Revised |
| `vorn:cap:0` | Standing Interdiction | The carried strike damage bonus lasts two rounds instead of one. | Plan |
| `vorn:cap:1` | Bracketed on File | The second shot deals full damage whenever it hits the same target as the first. | Plan |
| `reyes:cap:0` | Suppressed Escort Fire | The filed enemy's point defense is shut down for the rest of this round. | Plan |
| `reyes:cap:1` | Double Patrol Sortie | Each patrol wing may trigger twice per round (once per enemy move). | Clarified |
| `maren:cap:0` | Residual Line Order | Half of the extra hull damage reduction holds through the round after the wall ends. | Plan |
| `maren:cap:1` | Unbroken Standard | Overshield from the line does not decay at round start while the flagship lives. | Clarified |
| `grax:cap:0` | Steel on the Second Burn | Rams during the carried burn round deal +25% damage. | Plan |
| `grax:cap:1` | Blood on the Rail | Each boarding action the flagship lands repairs 10% of its hull. | Plan |
| `sable:cap:0` | Blade in the Wake | That carried first rear-arc shot is always a critical hit. | Plan |
| `sable:cap:1` | Turn of the Knife | Ships that make the 2-hex move also turn free toward the nearest foe and gain +10 aim this round. | Revised |
| `mott:cap:0` | Hot Off the Racks | Wings from the second launch strike at +15% damage. | Plan |
| `mott:cap:1` | Welded Together Again | Old Mott's private wing survives the first hit that would destroy it. | Plan |
| `vesh:cap:0` | Double-Riveted Seam | Every restored section gains +20% armor for the rest of the battle. | Plan |
| `vesh:cap:1` | Scrap Never Quits | Nothing Stays Broken triggers twice per battle across your fleet. | Clarified |
| `matriarch:cap:0` | Pinned in the Swarm | The chosen enemy cannot spend movement or ram on its next turn. | Clarified |
| `matriarch:cap:1` | Endless Feeding | Each extra swarm may chain its kill strike twice instead of once. | Plan |
| `razormaw:cap:0` | Red Tide Lingers | The +25% damage bonus covers every shot those ships fire next round. | Plan |
| `razormaw:cap:1` | Scent of the Pack | Ships ending that move adjacent to the named prey deal +15% damage to it this round. | Plan |
| `mending:cap:0` | Full Second Surge | The end-of-round regrowth heals at full Command strength. | Plan |
| `mending:cap:1` | Scar Tissue Knits | Any ship with a restored section regrows 2% max hull each round (once per ship). | Clarified |
| `voice:cap:0` | Deep Bile Follow-Up | The follow-up acid burst deals full damage to targets below half hull. | Plan |
| `voice:cap:1` | Corrosive Deluge | The chosen ship's acid hits also strip 10% armor for the battle (down to 0%). | Clarified |
| `nekhet:cap:0` | Archived Evasion | The chosen ship also gains +10 evasion next round (within the 45 cap). | Clarified |
| `nekhet:cap:1` | Hardened Restoration | The repaired ship also resets its ability cooldown and takes 25% less hull damage until next round. | Revised |
| `sekhmar:cap:0` | Third Noon Echo | Noon volley echoes a third round at quarter damage. | Plan |
| `sekhmar:cap:1` | Twin Sun Copies | The half-damage copy strikes the two enemies with the least hull, not one. | Plan |
| `anuket:cap:0` | Precision From Shadow | Ships covered by the carried bonus also gain +10% critical chance. | Revised |
| `anuket:cap:1` | Unseen Copy | Ships that made the 2-hex move cannot be targeted past range 3 until they fire or the round ends. | Revised |
| `khepra:cap:0` | Reclaimed Impact | Half the hull damage blocked by the 25% cap returns as repair at next round start. | Plan |
| `khepra:cap:1` | Enduring Shade Wall | Repaired ships keep the wall's hull damage reduction for two rounds after it ends. | Plan |

---

## 4. Relic (Salvage) Names, Effect Lines, and Flavour Lines (12 x 3 slots, max 28 / 110 / 90 chars)

| Draft ID | Name (<=28) | Effect Line (<=110) | Flavour Line (<=90) | Spec |
| --- | --- | --- | --- | --- |
| `gunnery` | Anchored Fire Table | Ships that did not move this turn deal +15% damage. Turning in place counts; wings excluded. | Steady decks turn wild broadsides into clean kills. | Plan |
| `afterburn` | Overdriven Thruster Pins | A ship that spends all movement (at least 1 hex) gains +10 evasion until its next turn. | Push the nozzles past red and let their gunners shoot where you were. | Clarified |
| `flankmark` | Stern-Sight Beacon | Rear-arc hits mark the target; marked enemies take +15% damage from your fleet this round. | One crack in the stern and every gun on the line knows where to aim. | Plan |
| `spotter` | Forward Spotter Pods | Enemies hit by your wings take +10% damage from your ships for the rest of this round. | Small craft paint the weak plates before the heavy guns speak. | Plan |
| `lastlight` | Sinking Standard | Once your flagship drops below 30% hull or falls, all other ships deal +20% damage for the battle. | When the banner burns, nobody holds a shell back. | Clarified |
| `coolant` | Cracked Coolant Manifold | Active ability cooldowns -1 (min 1). Each active use costs 3% hull (cannot drop below 1). | Bleed the reactor straight into the hull frames and worry later. | Clarified |
| `spare` | Reserve Signal Key | Give your Command a second time each battle at tier 0, from next round on. No second rider or Mastery II. | Kept sealed in lead for the hour the first order runs dry. | Clarified |
| `ledger2` | Black Fleet Ledger | +1 fleet command point, but battles yield 10% fewer credits (or 10% less biomass for the Chorus). | Another hull on the line always takes its cut before port. | Revised |
| `ram` | Iron Ram Charter | Rams deal +50% damage (cap 50% target hull) and inflict zero recoil on the ramming ship. | Heavy prows were forged for one argument and nothing else. | Clarified |
| `mirror` | Feedback Lattice Core | First hull hit each ship takes per battle returns 50% hull damage to the attacker (10% boss cap). | Half the blow rides straight back down the firing line. | Revised |
| `beacon` | Jump-Slip Beacon | On round 1, every ship gains +2 movement and +1 turn allowance. | Drop hot off the drift vector and take the lane before they form up. | Revised |
| `quiet` | Cold-Hull Dampener | During round 1, enemies cannot target your ships from 6 or more hexes away (area blasts still hit). | Cut the radiators, coast dark, and let them shoot at empty space. | Plan |

---

## 5. Refit Names and Effect Lines (4 + 4 slots, max 28 / 110 chars)

Card prices sit in `MODULES[id].cost` as today (shown separately on the refit card, not inside `d`).

| Draft ID | Refit Name (<=28) | Effect Line (<=110) | Cost | Spec |
| --- | --- | --- | --- | --- |
| `locker` | Heavy Breach Lockers | Boarding strength +40%, ship speed -1 (minimum speed 2). | 65 credits | Clarified |
| `chaser` | Swivel Arc Mounts | Non-turret fore and flank weapons may fire one arc wider at -20% damage. | 85 credits | Revised |
| `spill` | Bleed-Off Capacitor | When this ship's shields fall to zero, its next weapon attack deals +30% damage. | 70 credits | Plan |
| `relay` | Brace Shield Relay | When this ship braces, one uncovered ally within 2 hexes takes 20% less hull damage until its next turn. | 75 credits | Revised |

---

## 6. Command Rider Lines (24 slots, max 70 chars)

Written in exact `PLAN.md` Section 7 admiral order. Six revised riders (`grax`, `mirelle`, `khepra`, `mott`, `nekhet`, `matriarch`) and capped `voice` follow `build_variety_1453_review.md`.

| Admiral | Command | Rider Line (<=70) | Spec |
| --- | --- | --- | --- |
| `vex` | `barrage` | Flank guns in the free volley deal +10% damage. | Plan |
| `kassar` | `barrage` | Battery shots in the free volley cannot miss. | Plan |
| `voice` | `barrage` | Volley hits strip 10% armor this round (once per target). | Revised |
| `vaelen` | `barrage` | Lances in the free volley strike each target's weakest section. | Plan |
| `sekhmar` | `barrage` | Targets hit by the volley lose 10 aim for 2 rounds. | Plan |
| `malek` | `hunt` | Torpedoes fired this round ignore point defense. | Plan |
| `vorn` | `hunt` | Each hit this round cuts target evasion by 5 until your next turn. | Plan |
| `sable` | `hunt` | Ships that land a rear-arc hit this round gain +10 evasion. | Plan |
| `anuket` | `hunt` | Ships that land a rear-arc hit this round gain +10% critical chance. | Plan |
| `ashgrove` | `scramble` | Launched wings start with +1 movement this round. | Plan |
| `reyes` | `scramble` | Bonus wing attacks focus the lowest-hull enemy in reach first. | Clarified |
| `mott` | `scramble` | Extra wings gain +10% critical chance this round. | Revised |
| `matriarch` | `scramble` | Swarm hits this round heal their parent brood 3% hull. | Revised |
| `aelith` | `scramble` | Your wings ignore flak this round. | Plan |
| `thale` | `iron` | The wall also repairs 5% hull on every ship. | Plan |
| `maren` | `iron` | Ships adjacent to the flagship take 10% less hull damage. | Plan |
| `mirelle` | `iron` | Warded ships gain +15% max shields for this round. | Revised |
| `khepra` | `iron` | Ships that hold still or brace repair 5% hull at round end. | Revised |
| `vesh` | `restore` | Each ship's worst damaged section is patched in full. | Plan |
| `mending` | `restore` | The ship that regrows the most hull gains +10% damage this round. | Plan |
| `nekhet` | `restore` | Repaired ships gain +5% armor until your next turn. | Revised |
| `grax` | `surge` | Ram recoil is cut in half this round. | Revised |
| `razormaw` | `surge` | Ships adjacent to a wounded enemy gain +1 movement. | Plan |
| `thorne` | `surge` | Each ship may turn to face any direction for free. | Plan |

---

## 7. Ability Names and Lines (2 + 2 slots, max 24 / 110 chars)

| Ability ID | Name (<=24) | Effect Line (<=110) | Spec |
| --- | --- | --- | --- |
| `phase` | Fold skip | Next weapon attack on this ship this round misses outright; +1 movement now. Cooldown 4. | Revised |
| `frenzy` | Blood frenzy | +20% damage this turn; regrow hull equal to 30% of hull damage dealt (max 20% hull). Cooldown 3. | Revised |

---

## 8. Floating Words (12 slots, max 14 chars)

| Trigger | Floating Word (<=14) | Color Note |
| --- | --- | --- |
| Eclipse `phase` dodge | Folded | Violet `#b894ff` (never green!) |
| `flankmark` / `spotter` mark | Marked | Amber `#f0b35a` |
| `lastlight` triggers | Last light | Amber `#f0b35a` |
| `mirror` damage return | Reflected | Pale gold `#ffe0a8` |
| `quiet` / `anuket:cap:1` stealth | Shrouded | Cool blue `#9fe3ff` |
| `relay` brace cover | Relay cover | Teal `#7fd6c8` |
| `spill` shield-break charge | Spill surge | Pale gold `#ffe0a8` |
| `coolant` hull drain | Coolant burn | Ember `#ff7a6e` |
| `matriarch:cap:0` root | Pinned | Bile `#c8e04a` |
| `vex:cap:0` no-brace | Exposed | Ember `#ff7a6e` |
| `mott:cap:1` wing survive | Held together | Amber `#f0b35a` |
| `spare` second Command | Second call | Gold `#f0b35a` |

---

## 9. Event Chain Text (4 Chains, 10 Cards Total)

Distinct from existing `EVENTS` (`beacon`, `bait`, `defector`, `derelict`). Designed for a lightweight `RUN.eventQueue` (`afterStops: 1..2`), matching the exact card style and length of `data.js` `EVENTS`.

### Chain 1: The Limping Tender (2 cards)

**Card 1A (`chain_tender_1`)**
- **Title:** `Ghost carrier on low power`
- **Body:** `A battered civilian tender drifts behind a dust ridge, its drive bell cracked and its transponder pulsing an old Sunward shipping code. Hullbreaker scouts are already sniffing the lane behind it.`
- **Choices:**
  1. `l`: `Escort the tender toward the next relay` | `s`: `Costs 15% hull on one escort from stray fire. Follow-up arrives in 2 stops.`
  2. `l`: `Cut its vault loose before the raiders arrive` | `s`: `Gain salvage now; Nemesis clock moves on 1. Ends the chain.`
  3. `l`: `Leave them to their drift` | `s`: `Nothing happens.`

**Card 1B (`chain_tender_2`, 2 stops later if escorted)**
- **Title:** `The tender makes port`
- **Body:** `The limping tender you screened clears the outer buoy under its own thrusters. Its quartermaster opens the sealed manifest before the yard clamps lock on.`
- **Choices:**
  1. `l`: `Take the yard credit note` | `s`: `+110 credits and repair 10% hull across your fleet.`
  2. `l`: `Claim the sealed crate from deck three` | `s`: `Gain a piece of salvage.`
  3. `l`: `Ask for their sensor logs instead` | `s`: `Reveal a Nemesis weakness and gain +40 credits.`

---

### Chain 2: The Factor's Note (3 cards)

**Card 2A (`chain_factor_1`)**
- **Title:** `Factor's line of credit`
- **Body:** `An armed Directorate trade factor hails from a fortified rock-barge. She offers hard coin upfront for war fleets short on hulls, stamped with a two-jump repayment clause.`
- **Choices:**
  1. `l`: `Sign the note for 120 credits` | `s`: `+120 credits now. Her gunboats find you in 2 stops.`
  2. `l`: `Take a smaller draw of 60 credits` | `s`: `+60 credits now. Easier terms when she collects.`
  3. `l`: `Refuse the ledger` | `s`: `Nothing happens.`

**Card 2B (`chain_factor_2`, 2 stops later if signed)**
- **Title:** `The factor comes to collect`
- **Body:** `Two heavy Meridian Directorate customs cutters drop across your jump lane, weapons cold but locks active. The factor transmits your stamped chit with interest added.`
- **Choices:**
  1. `l`: `Pay the note in full` | `s`: `Pay 150 credits (or 75 on the small draw). Gain a refit for good standing.`
  2. `l`: `Hand over a piece of salvage instead` | `s`: `Lose a piece of salvage. Debt cleared cleanly.`
  3. `l`: `Break formation and run the blockade` | `s`: `Fight an elite Directorate patrol; keep the coin. Follow-up if you escape.`

**Card 2C (`chain_factor_3`, 1 stop later if blockade beaten)**
- **Title:** `Blacklisted by the factors`
- **Body:** `Word of the burned debt chits reached the sector yards ahead of you, though a rival broker quietly applauds anyone willing to stiff Directorate collectors.`
- **Choices:**
  1. `l`: `Take the rival broker's back-channel deal` | `s`: `Gain a refit and +35 credits; Nemesis clock moves on 1.`
  2. `l`: `Clear the bounty quietly` | `s`: `Pay 45 credits to keep local lanes clear.`

---

### Chain 3: The Coded Chart (2 cards)

**Card 3A (`chain_chart_1`)**
- **Title:** `Split cipher plate`
- **Body:** `An Ashfall Hullbreaker scout ship offers half a brass star-plate pulled from a dead Meridian Directorate courier. The coordinates point two jumps ahead, toward either an intact supply cache or a trap.`
- **Choices:**
  1. `l`: `Buy the plate for 40 credits` | `s`: `-40 credits. Follow the heading in 1 stop.`
  2. `l`: `Demand the plate at gunpoint` | `s`: `Free plate, but Nemesis clock moves on 1. Follow in 1 stop.`
  3. `l`: `Wave the scout off` | `s`: `Nothing happens.`

**Card 3B (`chain_chart_2`, 1 stop later)**
- **Title:** `End of the cipher heading`
- **Body:** `Your fleet drops onto the marked shoal. Half-buried in drifting slag sits an old supply pod, flanked by cold mines and two patrol hulks powering up their sensors.`
- **Choices:**
  1. `l`: `Push through the patrol and claim the pod` | `s`: `Fight an elite battle. Win a piece of salvage and +80 credits.`
  2. `l`: `Send fast cutters to snatch the outer crates` | `s`: `+65 credits and +15 XP across the fleet; avoid the fight.`
  3. `l`: `Burn out before their locks settle` | `s`: `Escape cleanly with no loss.`

---

### Chain 4: The Silent Vault-Hulk (3 cards)

**Card 4A (`chain_vault_1`)**
- **Title:** `Starwright drift coordinates`
- **Body:** `A cracked navigation core salvaged from an asteroid shadow still spits one clean vector: a pre-Siphoning vault-hulk resting two stops off the main lane, guarded by automated Eclipse sentries.`
- **Choices:**
  1. `l`: `Lock the vector into your charts` | `s`: `Marks the vault-hulk 2 stops ahead. Costs nothing now.`
  2. `l`: `Sell the vector to a passing merchant` | `s`: `+55 credits now. Ends the chain.`
  3. `l`: `Wipe the core and move on` | `s`: `Nothing happens.`

**Card 4B (`chain_vault_2`, 1 stop later, en route)**
- **Title:** `Outer sentry picket`
- **Body:** `A single dark Eclipse scout crosses your bow along the vault vector, sweeping the dust field with cold scanners. If it transmits, the vault guard will be awake when you arrive.`
- **Choices:**
  1. `l`: `Silence it with a short burst` | `s`: `Random ship takes 8% hull damage; vault guards stay cold at the next stop.`
  2. `l`: `Run dark and slip past its cone` | `s`: `No damage; the vault guard arrives alert next stop.`

**Card 4C (`chain_vault_3`, 1 stop later, at the vault)**
- **Title:** `The Starwright vault-hulk`
- **Body:** `The shattered vault-hulk hangs motionless against the pale gas cloud, its inner chamber split open like a cracked bell. Eclipse hulls drift across its shadow, holding the breach.`
- **Choices:**
  1. `l`: `Clear the Eclipse guard and take the vault` | `s`: `Fight a boss-grade Eclipse detachment (weaker if picket silenced). Win salvage and a refit.`
  2. `l`: `Rake the outer hull from long range` | `s`: `+70 credits, no battle.`
  3. `l`: `Leave the vault to the dark` | `s`: `Withdraw cleanly.`
