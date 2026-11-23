# Embers of the Hollow Sun: Fresh Holistic Game Audit

> [!IMPORTANT]
> This audit evaluates the live Godot 4 game in `godot/` completely fresh, ignoring past design history. Every critique is tested against one standard: **what makes a tactics roguelike genuinely fun, memorable, and impossible to put down?**

---

## 1. What Makes Tactics / Strategy Roguelikes Beloved

The games players sink hundreds of hours into (FTL, Into the Breach, Slay the Spire, XCOM 2, Hades, Battle Brothers, Cobalt Core) share six non-negotiable pillars:

1. **Readable puzzles with real agency:** You can hold the core rules in your head, read enemy threats before they hit, spot a clever line of play, and watch it work because of *your* decision, not a mystery spreadsheet or coin flip.
2. **Power fantasy and build pivots:** Run upgrades change *how* you play, not just `+8%` math. When you assemble a smart combo, the game lets you **feel** strong and stomp fights you earned.
3. **Snappy cadence and high decision-to-chore ratio:** Fast animations, stable camera framing, minimal post-fight paperwork. Almost every click is an interesting tactical or strategic decision.
4. **Honest risk, reward, and climactic bosses:** Hard nodes pay off clearly, failures feel earned (never hidden-rule traps), and sector bosses are unforgettable mechanical exams with signature patterns.
5. **Distinct identity out of the box:** Picking a new faction or commander immediately changes your turn-to-turn verbs on Battle 1, not after 15 hours of grinding.
6. **Earned "one more run" pull:** Losses feel exciting because they unlock new toys, reveal new strategies, or advance a rivalry that actually escalates.

### What Is Already Working Well (Keep This)

Before diagnosing what breaks, the game has genuinely strong bones:
- **Tactical naval DNA:** Directional firing arcs, turn-radius inertia, shared shield pool with quadrant coverage, six faction movement rules (`MOVE_RULES`), alternating activations, plan-on-ghost commit flow, and automatic enemy rout at `<= 35%` CP so fights skip tedious mop-up.
- **Audio/visual craft:** 45 bespoke hull meshes, layered SFX mix with capital-death ducking (`sfx.gd` (`godot/audio/sfx.gd:112-199`)), adaptive battle music (`music_player.gd` (`godot/music/music_player.gd:1-50`)), and a 3D sector chart.

**The core diagnosis:** The game does not lack features, content, or visual craft. Its problem is the opposite: **its own systems actively fight against player agency, power fantasy, clarity, and tempo.**

---

## 2. Where the Game Falls Apart (With Exact Source & Logic)

### 1. Dynamic rubber-banding steals your power fantasy and punishes playing well
**Why it hurts:** The core joy of a roguelike is out-building the curve. Here, playing smart, upgrading ships, collecting boons/relics, and even **repairing your hull before a fight** secretly makes the next enemy fleet bigger, while stumbling shrinks enemy fleets and bosses.

- **Source:** `fleetPower()` (`godot/rules/rules.gd:1372-1383`), `genEnemyFleet()` (`godot/rules/rules.gd:1631-1644`), `startBattle()` (`godot/rules/rules.gd:1459-1473`), mirrored in `map_intel.gd` (`godot/ui/campaign/map_intel.gd:21-58`).
- **Exact logic:**
  - `fleetPower()` scores your fleet from every ship's CP, **current HP fraction** (`0.4 + 0.6 * hp`), Mk level (`+12%` each), fitted refits (`+3%` each), captain rank (`+4%` each), hangars, rarity-weighted boons (`+3.5%` each), and relics (`+2.5%` each).
  - `genEnemyFleet()` scales every enemy budget by `clamp((fleetPower() / RAMP.refP[s])^0.6, 0.75, 1.30)` (`RAMP.refP = [0, 7, 12, 20]`).
  - `startBattle()` scales Sector Boss HP by `bossFit = clamp(playerStrength() / [0, 6, 9, 12][s], 0.55, 1.0)` on top of `BOSS_SCALE = [0, 0.5, 0.55, 0.7]`. A weak Sector 1 fleet can fight a boss at **27.5% base HP**, while a strong fleet is taxed with **+30% larger enemy fleets** everywhere.
  - Even permanent meta upgrades (`War chest I-III`, `Command authority I-II`, `Veteran officers`, `Founders' cache`, Mastery IV Mk II flagship in `newRun()` (`godot/campaign/campaign.gd:1394-1437`)) inflate `fleetPower()` on Turn 1 and trigger enemy scaling against you.
  - Meanwhile, non-boss enemies are secretly thinned to `62%-73%` HP and damage (`RAMP.thin = [0, 0.73, 0.67, 0.62]` at `rules.gd:1469-1473` (`godot/rules/rules.gd:1469-1473`)). Instead of readable, fixed enemy threats that reward mastery, the math runs an invisible treadmill.

---

### 2. Fake player agency: dozens of Admiral Lineage skills lie to the player and play themselves
**Why it hurts:** The 24 Admiral Lineage Trees (`288` nodes, `214` unique `TREE_FX` effects) contain the game's most exciting, bespoke tactical promises ("name one enemy", "place one of your ships anywhere in your deployment zone", "swap any two ships", "hold one ship in reserve"). In real gameplay, **the player never gets to make those choices**, and several skills are hollow auto-shuffles.

- **Source:** `treeChoice()` (`godot/rules/rules.gd:4800-4850`), `treeDeployMove()` & `treeBattleStart()` (`godot/rules/rules.gd:5476-5528`), `runCommand()` (`godot/rules/rules.gd:5778-6008`).
- **Exact logic:**
  - `treeChoice(kind)` checks `B.get("treeChoices")`, which **no UI in the entire game ever sets** (it is only supplied by headless test fixtures in `godot/rules/test/scenarios.json`).
  - All **41 calls to `treeChoice(...)`** in `rules.gd` silently fall back to hardcoded heuristics (`enemy` = highest `maxHp`, `ship`/`reserve` = lowest HP%, `carrier` = largest hangar).
  - `swornDeploy` / `deployRead` (*"after seeing the enemy deployment, place one of your ships anywhere in your deployment zone"*) silently moves your lowest-HP ship **1 hex to the nearest open hex** (`rules.gd:5476-5489` (`godot/rules/rules.gd:5476-5489`)).
  - `castCorrected` / `iterationSwap` (*"after deployment, swap the positions of any two of your ships"*) blindly swaps your first two ships `l[0]` and `l[1]` before you even see the board (`rules.gd:5494-5507` (`godot/rules/rules.gd:5494-5507`)).
  - `debtsReserve` / `broodReserve` silently yank a ship off the board for Round 1 without asking which ship or which entry edge (`rules.gd:5508-5519` (`godot/rules/rules.gd:5508-5519`)).
  - Only the 10 binary yes/no prompts in `TREE_MAY` and the Chorus `roles` picker ever open the HUD prompt (`rules.gd:4856-4896` (`godot/rules/rules.gd:4856-4896`)).

---

### 3. Invisible modifier soup, stacked RNG, and no enemy intent telegraphing
**Why it hurts:** Tactical games feel brilliant when outcomes are legible and earned. Here, combat math buries the player under dozens of microscopic conditional modifiers, stacks four layers of randomness on top of big cooldowns, and hides what enemies are about to do next.

- **Source:** `_hitChance_raw()` (`godot/rules/rules.gd:2858-2936`), `applyHit()` (`godot/rules/rules.gd:3258-3376`), `damageSection()` (`godot/rules/rules.gd:3396-3423`), `_landVolley_raw()` (`godot/rules/rules.gd:3724-3875`), `_overlay()` (`godot/scenes/battle/battle.gd:3319-3452`).
- **Exact logic:**
  - **25+ stacked hit modifiers:** A single shot adds base acc, unit aim, range falloff, capped evasion times `evMult`, squadron penalty (`-15`), nebula (`-15`), debris (`-10`), storm (`-10`), two crew-loss penalties (`-10` under 50% crew, `-20` under 25%), stationary/motion modifiers, sync aim, Nemesis weakness, wing stance, adjacent evasion, marks, surge (`-20`), plus **19 conditional admiral-lineage branches**.
  - **Layered RNG misery:** Every shot rolls hit (`5%-95%`, `rules.gd:3621` (`godot/rules/rules.gd:3621`)), damage variance (`0.85 + rnd() * 0.3`, `rules.gd:3823` (`godot/rules/rules.gd:3823`)), crit (`1.5x+`, `rules.gd:3316` (`godot/rules/rules.gd:3316`)), and point-defense/wing intercepts (`rules.gd:2736` (`godot/rules/rules.gd:2736`)). A flagship torpedo (`shots: 1, dmg: 42, acc: 64, evMult: 2, cd: 2`) has just **24% base hit** against a standard frigate before flak even rolls: pure feast-or-famine coin-flipping.
  - **Mid-battle death spirals from section breaks:** Each ship's prow (`30%` maxHp), mid (`45%`), and engine (`25%`) track separate HP (`rules.gd:1367` (`godot/rules/rules.gd:1367`)). Breaking a section permanently disables all forward weapons (`off = 999`), all flank weapons + shields, or drops speed to 1 and evasion to 0 (`rules.gd:3409-3420` (`godot/rules/rules.gd:3409-3420`)), turning damaged ships into helpless bricks before they die.
  - **Zero tactical enemy intent:** Aside from the 1-round boss Command warning (`rules.gd:5752` (`godot/rules/rules.gd:5752`)), enemies choose which ship activates and what it does on the fly (`aiPickActivation()` (`godot/rules/rules.gd:7266`), `aiUnit()` (`godot/rules/rules.gd:7499`)). The board only shows generic reachable danger hatching (`danger_on` / `R` threat map), never which enemy activates next or which target it intends to focus, ram, or board.

---

### 4. Camera hijacking and sluggish cadence break flow during battle
**Why it hurts:** Great tactics games keep your eyes anchored on the board and let turns snap along at your brain's speed. Here, the camera repeatedly rips away from your view mid-fight and enemy turns drag out into passive watching.

- **Source:** `_cine_wants()` & `_play_fire()` (`godot/scenes/battle/battle.gd:2179-2240`), `MOVE_HEX` / `MOVE_CAP` (`godot/scenes/battle/battle.gd:64-67`), `_play_batch()` (`godot/scenes/battle/battle.gd:1239-1378`), `swarmPhase()` (`godot/rules/rules.gd:6764-6772`).
- **Exact logic:**
  - Under the default `cine = "key"` setting (`battle.gd:165` (`godot/scenes/battle/battle.gd:165`)), `_cine_wants` returns `true` for **every single lance, torpedo, and nova attack in the battle** (`"lance", "torp", "nova": return true`), plus capital volleys on flagships or low-HP targets and almost all ship kills (`size >= 0.6`). Each cut-in swings the camera side-on, adds letterbox bars, pauses `320ms` before firing, and snaps back. A single fight involving Glasswrights, Eclipse, or Crusade cruisers/destroyers hijacks the player's camera **10 to 20 times**.
  - Ships move one at a time at `560-860ms` per hex plus `250-450ms` lead-in (up to `7.0s` per move), and enemy move time is explicitly excluded from the round speedup budget (`battle.gd:1329` (`godot/scenes/battle/battle.gd:1329`)). Large Sector 3 enemy turns still take 12+ seconds of waiting unless the player repeatedly presses Space/Enter to hurry, because `skip` resets to `false` at the end of every single enemy activation batch (`battle.gd:1370` (`godot/scenes/battle/battle.gd:1370`)).
  - Carrier squadrons fly and attack completely automatically in `swarmPhase` (`rules.gd:6764-6772` (`godot/rules/rules.gd:6764-6772`)), removing moment-to-moment agency from carrier fleets and adding extra passive watch time every round.

---

### 5. "24 Admirals, 6 Buttons" and thin tactical verb diversity across hulls
**Why it hurts:** The roster looks huge on paper (6 factions, 24 admirals, 51 hulls), but turn-to-turn verbs repeat heavily across admirals, hulls, and factions.

- **Source:** `ADMIRALS`, `CMD_POW`, `ABILITIES`, `ORDERS`, `HULLS`, `LEGACY` in `tables.json` (`godot/rules/data/tables.json`); `canOrder()` (`godot/rules/rules.gd:4570-4582`); `canAbility()` (`godot/rules/rules.gd:6792-6811`).
- **Exact logic:**
  - All **24 admirals share only 6 Commands** (`barrage`, `hunt`, `scramble`, `iron`, `restore`, `surge`), differentiated at base level only by a small passive stat line (`+15% flank`, `+10% hull/shields`, `+8 evasion`).
  - All **51 hulls share only 13 abilities**, and `launch` is passive (`canAbility` returns `false` for players at `rules.gd:6796` (`godot/rules/rules.gd:6796`)). Two unlockable variants (`h_vanguard_g`, `c_hulk_g`) have `ab: null` (no active ability at all). Most hulls inside a faction copy the same button (`blink` on 4 Glasswright hulls, `phase` on 4 Eclipse hulls, `regrow` on 3 Chorus hulls), and most active abilities are pure self-stat buffs (`+30% dmg`, `+25 ev`, `restore 25% hull`) rather than spatial or combo tools.
  - Although `rules.gd:4570-4600` (`godot/rules/rules.gd:4570-4600`) still has code for 4 orders (`brace`, `full`, `lock`, `helm`), only **1 order (`brace`)** is exposed in `ORDERS`, and Glasswrights cannot use even that (`FAC_GATES.ithar.noBrace`).
  - **Lopsided rosters:** Sunward Crusade has 6 base hull classes (Frigate to Dreadnought). Eclipse has only **3** playable base hulls (Frigate, Destroyer, Cruiser: no Carrier, no Battleship, no Dreadnought). Hullbreakers, Chorus, and Glasswrights have no Battleship or Dreadnought. Yet `LEGACY` sells `u_battleship` (60 renown, usable by only 2 of 6 factions) and `u_dread` (120 renown, Crusade only).

---

### 6. Boss fights are oversized skirmishes with no boss patterns or phases
**Why it hurts:** Sector bosses and the run finale are supposed to be the climax that tests your build and delivers adrenaline. Right now they are just a big HP-bar ship using normal AI.

- **Source:** `bossEncounter()` (`godot/campaign/campaign.gd:1050-1054`), `bossCmdTick()` & `bossCmdFire()` (`godot/rules/rules.gd:5741-5763`), `checkEndRules()` (`godot/rules/rules.gd:4561-4567`), `BOSS_CMD` & `BOSS_ENC` in `tables.json` (`godot/rules/data/tables.json`).
- **Exact logic:**
  - `BOSS_ENC = ["rout", "rout", "ambush"]`: boss battles have no bespoke encounter mechanics; killing the boss hull immediately routes all escorts and ends the fight.
  - Every boss's sole special behavior is firing **one** of the exact same 5 player Commands (`barrage`, `surge`, `restore`, `iron`, `hunt`) **once per battle**, announced on round 2 (or below 60% HP) and firing the next round.
  - No multi-phase escalations, no telegraphed super-weapon lanes to dodge, no destructible sub-objectives or arena shifts, and no unique final-boss identity at the Hollow Sun.

---

### 7. Post-battle paperwork waterfall, unequipped loot chores, and a hidden salvage trap
**Why it hurts:** Winning a fight should feel fast and rewarding. Instead, victory launches a queue of modals, forces inventory housekeeping in another screen, uses the same word for two unrelated loot types, and secretly punishes factions for using their own weapons.

- **Source:** `rewardFlow()` through `promotionsStep()` (`godot/campaign/campaign.gd:3415-3742`), `salvageYield()` (`godot/campaign/campaign.gd:3472-3490`), `killCauseOf()` (`godot/rules/rules.gd:4163-4170`), `TERMS` (`godot/ui/campaign/campaign_ui.gd:39`).
- **Exact logic:**
  - **Modal queue:** One victory can chain up to **6 sequential modals**: Prize disposal -> Victory/Wreck salvage -> Protocol or Refit pick -> Relic pick (elite/boss) -> Captain promotions -> Story/Sector transition.
  - **Unequipped hold chore:** Refit modules stripped from wrecks (`campaign.gd:3582` (`godot/campaign/campaign.gd:3582`)), picked as node rewards (`campaign.gd:3611` (`godot/campaign/campaign.gd:3611`)), or bought at shipyards (`campaign.gd:2241` (`godot/campaign/campaign.gd:2241`)) drop into `RUN["inventory"]` unequipped, forcing a separate trip to the Fleet/Refits screen. Worse, if a ship dies in combat (`campaign.gd:3978-3985` (`godot/campaign/campaign.gd:3978-3985`)), its fitted modules vanish forever instead of returning to salvage.
  - **Hidden faction anti-synergy trap:** `KILL_CAUSES` marks `big` (torpedoes, bombs, rams), `flay` (Eclipse null weapons), `melt` (Chorus bio-weapons), and `tidal` with `"scrap": 1`. In `salvageYield()` (`campaign.gd:3486-3490` (`godot/campaign/campaign.gd:3486-3490`)), `"scrap": 1` sets `intact = false`, which **destroys the wreck's refit module (`m = null`) AND disables Hullbreaker towing (`tow = false`)**. Result: **Hullbreakers cannot tow or strip enemies they ram or torpedo** (their own core kit), and **Eclipse and Chorus almost never get intact modules from wrecks** because their entire faction arsenals trigger `flay`/`melt`. None of this is warned in battle.
  - **Term collision:** `TERMS` renames fleet-wide relics to **"salvage"**, while `REWARD_DEF` also calls post-battle wreck stripping **"salvage"**.

---

### 8. Upgrade bloat (stat soup over build pivots) and muted run tension
**Why it hurts:** Players juggle **11 separate in-run upgrade/economy tracks** (Credits/Biomass, CP, Ship Mk I-III, Class Tracks, Modules, Captain Perks, Wing Perks, Flagship Aspect, Protocols, Relics, Faction Verbs), yet most choices are small passive percentages (`+6%` to `+15%`), capped by 74 `FX_CAPS`, while the genuinely exciting combos are too rare to assemble in a short run.

- **Source:** `rollBoonOffer()` & `legendaryFor()` (`godot/campaign/campaign.gd:724-770`), `genSector()` (`godot/campaign/campaign.gd:1071-1191`), `finishBattle()` (`godot/campaign/campaign.gd:3992-3995`), `checkEndRules()` (`godot/rules/rules.gd:4528-4548`).
- **Exact logic:**
  - **Stat soup:** Ship Mk (`+20% hp/sh, +15% dmg`), Class Tracks (`+6% hp/dmg`), 13 of 14 Captain Perks (`+10 aim`, `+10% crit`, `+15% hp`), and 13 of 17 Modules are flat spreadsheet math with zero change to how you fly a turn.
  - **Synergy bottlenecks:** Only 62% of normal battles offer a Protocol (`campaign.gd:769` (`godot/campaign/campaign.gd:769`)), spread across 4 random cores. Legendaries (the actual build-defining capstones like chain explosions or shield-piercing lances) require `minR >= 1` (**elites and bosses only**), **2+ prior protocols from that specific core**, AND still lose a **45% coin flip** to a Duo (`campaign.gd:738,751-762` (`godot/campaign/campaign.gd:738`)). In a 3-sector run with only 4 branching columns per sector, you rarely get to enjoy a completed synergy engine for more than 2 or 3 fights.
  - **Softened stakes:** Every victory auto-heals **15% max HP** (`campaign.gd:3994` (`godot/campaign/campaign.gd:3994`)) and every sector transition auto-heals **40%** (`campaign.gd:3765` (`godot/campaign/campaign.gd:3765`)). Worse, **failing Hunt or Intercept still awards a `"win"`** (`B["over"] = "win"; B["partial"] = true`, `rules.gd:4531,4543` (`godot/rules/rules.gd:4531`)), keeping full salvage, protocols, XP, and map progress while only halving credit pay. Meanwhile, retreating costs only `10%` hull and drops you back on the previous node (`campaign.gd:3988,4042` (`godot/campaign/campaign.gd:3988`)). Attrition feels soft until a ship suddenly dies permanently and wipes its fitted gear.

---

### 9. Meta-progression fails both new and veteran players (bypassed by default, brutal grind when off, and 6 unobtainable unlocks)
**Why it hurts:** Good roguelike meta-progression feeds the "one more run" hook with exciting horizontal unlocks every 1 to 2 runs. Here it breaks in three opposite ways at once.

- **Source:** `campaign_ui.gd:112` (`godot/ui/campaign/campaign_ui.gd:112`), `title.gd:165-177` (`godot/main/title.gd:165-177`), `campaign.gd:49` (`godot/campaign/campaign.gd:49`), `campaign.gd:1204-1280` (`godot/campaign/campaign.gd:1204-1280`), `campaign.gd:1748-1751` (`godot/campaign/campaign.gd:1748-1751`), `campaign.gd:1856-1865` (`godot/campaign/campaign.gd:1856-1865`), `campaign_ui.gd:908-944,1880` (`godot/ui/campaign/campaign_ui.gd:908-944`).
- **Exact logic:**
  - **Bypassed on launch:** `playtest_default = true` unlocks every admiral, carrier, battleship, hull variant, and all 8 lineage levels immediately on a fresh profile (and exposes a developer `"Test new battle maps..."` toggle in Run Options). A new player gets hit with maximum menu paralysis and zero unlock dopamine.
  - **Brutal grind when turned off:**
    - Full Renown unlock bill is **1,815 Renown** (`635` Legacy + `250` Variants + `930` for 18 Admirals), at `~101` Renown per full winning run and `~10-15` per Sector 1 loss.
    - **Respeccing an admiral's lineage tree between runs taxes permanent Renown** (`25 + 10 * respecs`, `campaign.gd:1273` (`godot/campaign/campaign.gd:1273`)), directly punishing build experimentation.
    - **Per-admiral XP wall:** A full winning run pays `~41` XP (`campaign.gd:1857` (`godot/campaign/campaign.gd:1857`)). First lineage pick = Level 5 (`75 XP`, ~2 wins). Capstone = Level 8 (`230 XP`, ~6 wins). Capstone Mastery III = **`600 XP` (~15 full wins with ONE admiral, across 24 admirals)**. The richest admiral identity mechanics are locked behind a massive grind wall.
  - **6 dead/unobtainable unlocks:** Progression tells players *"Finish the [Faction] story to unlock"* for 6 hull variants (`vs_penitent_l`, `h_interdictor_e`, `c_marauder_g`, `b_razor_e`, `i_carrier_a`, `d_jackal_h`), plus 6 flagship paints, medals, and Chronicle entries in `career.gd` (`godot/story/career.gd:69-91`). **But `arcs_on := false` (`campaign.gd:49` (`godot/campaign/campaign.gd:49`)) and `godot/story/data/arcs/` does not exist**, so those unlocks are unreachable without the playtest switch.
  - **Unrewarding difficulty ladder (`HEAT`):** UI text says *"Lose a run to unlock Threat"* (though `heatUnlocked()` (`godot/campaign/campaign.gd:1332-1334`) unlocks on any win or loss), and Threat only adds passive enemy/price inflation for `+10%` extra Renown, with no new encounters, boss phases, or real endgame milestone.

---

### 10. Front-loaded onboarding walls and an under-realized Nemesis / narrative loop
**Why it hurts:** The first 5 minutes should drop a new player straight into a crisp, thrilling skirmish and teach through play. Instead, they wade through setup choices they lack context for, walls of tip text, and a Nemesis system that stops short of true rivalry.

- **Source:** `campaign_ui.gd:673-1025` (`godot/ui/campaign/campaign_ui.gd:673-1025`), `story.gd:121-126` (`godot/story/story.gd:121-126`), `campaign_tips.gd:6-12` (`godot/ui/campaign/campaign_tips.gd:6-12`), `battle.gd:78-88` (`godot/scenes/battle/battle.gd:78-88`), `campaign.gd:2688-2883` (`godot/campaign/campaign.gd:2688-2883`).
- **Exact logic:**
  - **Pre-battle gauntlet:** Title -> Command Desk (6 factions, 24 admirals, mastery bars, Lineage links, Run Options) -> Flagship Podium (forced to pick 1 of 3 permanent Flagship Refits before knowing what firing arcs, wings, or Command tiers even are) -> Sector Intro modal -> **"Name your flagship"** dialog -> 3D Map -> `c_map` tip card -> `c_clock` tip card -> Battle 1 -> up to 9 dense text teaching cards (`TIPS` in `battle.gd`).
  - **Nemesis stops short of personal drama:** Each sector forces exactly one meeting by Column 4 (`campaign.gd:2688-2695` (`godot/campaign/campaign.gd:2688-2695`)), and Sector 2/3 can swap to different rival factions (`nemAssign`). When he adapts at sector end (`nemAdapt()` (`godot/campaign/campaign.gd:2715-2735`)), the payoff is mostly a quiet passive stat boost (`+20% shields`, `+8 evasion`, `+10% armor`) rather than a visible tactical counter-fleet that forces a fresh plan.
  - **Career isolation:** `career.gd:3-4` (`godot/story/career.gd:3-4`) explicitly isolates medals, titles, and history from campaign/battle rules, and with `arcs_on := false`, the narrative layer feels disconnected from the core run loop.

---

## 3. Recommended Fix Priority (Highest Impact on Fun First)

| Priority | Change | Why It Moves the Needle Most |
| :--- | :--- | :--- |
| **1. Kill dynamic rubber-banding** | Remove `fleetPower()` budget scaling (`rules.gd:1639`) and `bossFit` boss HP shrinking (`rules.gd:1461`). Tune fixed, honest sector/node enemy budgets. | Immediately restores the entire roguelike power fantasy: upgrades, repairs, and combos finally feel worth earning. |
| **2. Fix battle feel & clarity** | Default `cine` cut-ins to **kills and boss Commands only** (never routine lances/torps). Keep `skip`/fast-pace sticky across a round. Add clear **next enemy activation + target intent** markers on the board. | Eliminates camera whiplash and waiting fatigue, and turns alternating activations into a sharp readable puzzle. |
| **3. Cut fake agency & bloat; deepen real choices** | Either wire real UI picking for `treeChoice` skills or rewrite them into honest active/positional mechanics. Collapse redundant passive stat tracks (Class Tracks + flat Mk bumps + tiny perk bumps) into fewer, punchier **build-pivoting** upgrades, and let Duos/Legendaries appear earlier in a run. | Replaces spreadsheet clutter and broken promises with genuine "oh awesome, look at this combo!" moments. |
| **4. Fix hidden loot traps & post-battle chore tax** | Remove `"scrap": 1` from faction weapons and Hullbreaker rams/torps (or reward *cleaner* kills with bonus credits instead of deleting modules/towing). Consolidate post-battle modals into one clean debrief/reward screen, let players fit won refits directly on the reward card, and give relics a distinct name from wreck salvage. | Removes unfair hidden penalties and cuts tedious between-battle clicking in half. |
| **5. Make bosses real bosses & overhaul meta cadence** | Give each sector boss 1 to 2 distinct mechanical patterns (telegraphed area hazards, phase shift at 50% HP, destructible hardpoints/summons). Turn off `playtestAll` for normal profiles, drop Lineage respec cost to 0, cut Admiral Lineage XP thresholds by ~3-4x (or unlock trees on Run 1-2), and ship/enable the 6 faction arcs so arc unlocks actually exist. | Gives every run an unforgettable climax and turns meta-progression into an addictive "one more run" loop instead of a grind wall. |
