# Neon Review: Build Variety Plan (Issue 1453, PR 1635)

**Commit reviewed:** `b56c67e7` (`b56c67e7a41a8acd5a5932f605055a8e93845d05`, branch `opus/issue-1453`)  
**Reviewer:** Neon (`neon/issue-1636`)  
**Protocol:** Follows `docs/REVIEW_PROTOCOL.md` and `PLAN.md` section 12.

---

## 1. Files Read (Proof of Read)

| File | Total Lines | First 40 chars of LAST line | Ranges read (for files > 1,500 lines / 60 KB) |
| --- | --- | --- | --- |
| `contrib/opus/design/build_variety_1453/PLAN.md` | 258 | `5. Then the text in section 11, written ` | Full file (1-258) |
| `contrib/opus/compute/rename_map_final.md` | 607 | `Every Old cell was searched as an exact ` | 1-250 (factions, weapons, hulls, salvage rename 5b) |
| `data.js` | 5350 | `};` | 1-278 (weapons, hulls, factions, abilities, modules, relics, admirals), 1410-1445 (`saboteur` chain), 2807 (`FAC_GATES`), 2870-5025 (`CAPSTONE_MASTERY_*`, all 24 `LINEAGE_TREES`, `TREE_FX`, `TREE_MAY`), plus full structured parse of `HULLS`, `ADMIRALS`, `LINEAGE_TREES`, `EVENTS` |
| `core.js` | 535 | `function findNode(id){ for(const c of RU` | 240 (`LATE_SHOP`), 250-335 (`runFx`, `derive`, `canFitModule`, `relicUseful`), 410-535 (mastery, lineage, respec, `altCommand`, `newRun`) |
| `battle.js` | 2399 | `}` | 115-156, 280-316 (`deploy`), 440-457 (turn start, shield clamp, acid/fire), 766-965 (hit, evasion cap, `hitArmor`, `dmgMult`, `applyHit`, `tempHp`, `shredded`), 1040-1075 (ward/falseHulls/flak/PD), 1205-1282 (ram, board), 1400-1499 (`canOrder`, `braceCover`, `braceMul`, `abilityCd`, `COMMANDS`, `cmdTier`, `cmdDesc`, `treeStepToward`), 1565-1590 (`treeShieldOver`, sync), 1704-1751 (`treeDeployMove`, `refraction`), 1787-2029 (`commandFor`, `canCommand`, `useCommand`), 2109-2150 (`useAbility`), 2294-2322 (AI ability hooks) |
| `campaign_run.js` | 868 | `}` | 151-256 (`LATE_SHOP`, yard equip), 310-351 (event selection, `needMet`, `flagIs`, `eventFlags`), 577-651, 706-847 (relic choices, rewards) |
| `godot/rules/rules.gd` | 7328 | `\tB["aiActive"] = null; u["activated"] = ` | 903 (`deploy`), 4389-4435 (`abilityCd`, `cmdTier`, `treeBuild`), 5432 (`useCommand`), 6551-6585 (`_useAbility_raw` `phase`/`frenzy`), 7094-7112 (AI `phase`/`frenzy`) |
| `godot/campaign/campaign.gd` | 4071 | `\t\t"events": tel_log.slice(max(0, tel_log` | 918-945 (`relicUseful`, `canFitModule`), 1167-1241 (`capstoneMastery*`, `lineageRespec`), 1734-1744 (respec XP preservation), 2090-2110 (`LATE_SHOP`), 2358-2392 (`flags`) |

---

## 2. Top 10 Findings (Most Important First)

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Your fix | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `nekhet:cap:1` Mastery III refills shields on Eclipse, a shieldless faction | OBSERVED | `PLAN.md:109` (vs `data.js:117`) | `The repaired ship also returns to full shields.` | Every Eclipse hull (`d_scythe`, `d_jackal`, `d_harvester`, `d_boss`) has `sh:0,rg:0`. This 600 XP Mastery III does literally nothing and breaks Eclipse identity. | Replace `nekhet:cap:1` Mastery III with: repaired ship resets its ability cooldown and takes 25% less hull damage until next round. | High |
| 2 | `sable:cap:1` Mastery III ("ignores turn limits") is a literal no-op on `treeStepToward` | OBSERVED | `PLAN.md:95` (vs `battle.js:1494`) | `The 2-hex move ignores turn limits.` | `cutFeeds` (`battle.js:1866`) calls `treeStepToward`, which steps greedily in any of the 6 `DIRS` without checking `facing` or `turnsLeft`. Mastery III adds zero behavior. | Replace `sable:cap:1` Mastery III with: each ship that moves this way also turns free to face the nearest enemy and gains +10 aim this round. | High |
| 3 | Mastery I (+25% doctrine passive) breaks integer keys and actively nerfs Kassar (`dmgPct: -.05`) | OBSERVED | `PLAN.md:55` (vs `data.js:236`) | `The admiral's doctrine bonus (their always-on passive) grows by a quarter.` | `kassar` has `fx:{battShots:1,dmgPct:-.05}`. Scaling by 1.25 cannot increment integer `battShots` (`1`) and makes `-5%` worse (`-6.25%`). Eight other admirals have integer `speed:1`, `torpCd:1`, or `hangar:1`. | Use an authored per-admiral Mastery I bonus table instead of a blind 1.25x multiplier: remove Kassar's `-5%` penalty (to `0%`), and boost paired pct/flat stats for integer doctrines. | High |
| 4 | Command riders ignore Mastery 3 `altCommand` (`RUN.cmdOverride`) | OBSERVED | `PLAN.md:158` (vs `core.js:517`) | `A rider is one extra effect added when that admiral gives their Command, from level 1.` | `core.js:517` swaps `RUN.cmdOverride` to another faction admiral's Command (`battle.js:1787`). Every section 7 rider assumes the admiral's default Command (e.g. Vex's free volley), so swapped Commands get dead or mismatched riders. | Bind each rider to the Command's owning admiral (taking `cmdAlt` brings that Command's rider), and add a parity test with `RUN.cmdOverride` set. | High |
| 5 | Six Command riders duplicate Tier 3/Capstone/faction effects or badly overpower level 1 (`grax`, `mirelle`, `khepra`, `mott`, `nekhet`, `matriarch`) | OBSERVED | `PLAN.md:185` (vs `data.js:4935`) | `Rams this round deal +30% damage.` | `grax` rider duplicates `grax:A:2:1` (`mawOpens`, +30% ram dmg), making T3 dead under PLAN.md:160. `mirelle` blocks 1 hit/ship at lvl 1 (Khepra T3); `khepra` adds +1 wall round (Thale capstone, making 4-round walls with `cap:1`); `nekhet` revives an escort (Eclipse faction rule); `mott` clones `wholeYard`; `matriarch` teleports swarms across the board, making `sporeTide` obsolete. | Replace all 6 with distinct level-1 tactical riders (exact replacements in Section 3.2 below and used in Section 11 text). | High |
| 6 | Refit `relay` breaks MOD-3 on Glasswrights (`noBrace`) and collides with Sunward `braceCover`; `chaser` only fits 8/42 hulls | OBSERVED | `PLAN.md:152` (vs `battle.js:1411`) | `When this ship braces, one ally within 2 hexes also takes 20% less hull damage` | `FAC_GATES.ithar.noBrace` (`data.js:2807`) bars Glasswrights from Bracing, so "Fit rule: Any ship" violates MOD-3. On Sunward ships, `braceCover` (`battle.js:1424`) already uses `coverBy` for 40% cover, so `relay` can overwrite or collide with it. Only 8/42 hulls (0 Chorus/Glasswright/Eclipse) carry flank batteries (`P`/`S`), and `canFitModule` (`core.js:310`) does not check arcs. | Gate `relay` on `!FAC_GATES[fac].noBrace` with its own `relayCover` field (non-overlapping with `braceCover`). Widen `chaser` to non-turret fore/flank weapons firing one arc wider at -20% (fits all 6 factions) or add an arc check to `fleetKit`/`canFitModule`. Give `locker` an explicit credit cost plus `-1` speed (floor 2). | High |
| 7 | `beacon` relic assumes an interactive pre-round-1 deployment phase that does not exist | OBSERVED | `PLAN.md:139` (vs `battle.js:1706`) | `Uses the deployment step; no move into hazards or enemy-adjacent hexes.` | `deploy` (`battle.js:282`), `approachDeploy` (`battle.js:303`), and `treeDeployMove` (`battle.js:1706`) are fully automatic. There is no interactive multi-ship pre-round-1 move UI in browser or Godot; building one balloons Part 2 scope. | Change `beacon` to: "On round 1, every ship gains +2 movement and +1 turn." Same tactical setup payoff, zero new battle phase UI. | High |
| 8 | `ledger2` gives Chorus free +1 CP; `ram` relic gate is always true; `spare` / `mirror` / `quiet` miss critical edge cases | OBSERVED | `PLAN.md:136` (vs `core.js:510`) | `+1 command point; 10% fewer credits from battles.` | Chorus uses `RUN.bio` (biomass), not `RUN.credits` (`core.js:510`), so `ledger2` has zero downside for Chorus. `ramInfo` (`battle.js:1209`) lets every non-sq hull ram, so `relicUseful('ram')` would offer Ram charter to Glasswrights. `spare` collides with `B.tr.grandUsed` (`battle.js:1820`), `B.treeOneVoiceUsed` (`battle.js:1852`), and once-per-battle riders; `mirror` lacks boss-AoE/shield/mid-volley-kill rules; `quiet` can leave AI with zero targets on round 1. | Apply `ledger2` -10% to both credits and Chorus biomass. Gate `ram` on `RAM_FAC` or `overburn`. Define `spare` (tier 0, no second rider/Mastery II, respects once-per-battle caps), cap `mirror` to hull damage only (once per ship, non-lethal or post-volley, exclude wings), and cap `quiet` so AI always advances into range. | High |
| 9 | `maren:cap:1` overshield persistence and `mirelle:cap:1` temp-hull conversion clash with live round-start math; `phase` still prints green text on Eclipse | OBSERVED | `PLAN.md:91` (vs `battle.js:445`) | `The overshield does not fade while the flagship lives.` | `battle.js:445` clamps `u.shp=Math.min(u.shMax,(u.shp||0)+rg)` every turn start, silently deleting overshield unless regen preserves `Math.max(u.shp, ...)`. Meanwhile `t.tempHp` (`battle.js:933, 1887`) never expires at ward end, so converting leftover `tempHp` into shields on a Glasswright whose `ithChargeTurn` already snaps shields to full can *lose* durability. Also `battle.js:2130` and `rules.gd:6574` draw Eclipse `phase` text in green (`#7dff9b`), breaking section 3 rule 4. | Guard `battle.js:445` with `Math.max(u.shp, Math.min(u.shMax, ...))` while `maren:cap:1` Mastery III holds; for `mirelle:cap:1` Mastery III, convert leftover `tempHp` into overshield (up to `1.25 * shMax`) only when shields are full or add shield charge without deleting `tempHp`; recolor Eclipse `phase` callout from `#7dff9b` to violet (`#b894ff`) with text `Folded`. | High |
| 10 | Part F event chains assume a chain scheduler that does not exist in `campaign_run.js` or `campaign.gd`, and repeat 4 existing event premises | OBSERVED | `PLAN.md:204` (vs `campaign_run.js:320`) | `Four candidates, each 2 or 3 stops, using the one chain that exists today` | Today's 1 link (`defector` -> `saboteur`, `data.js:1428`) is only an optional blue `need.flag` choice inside a random draw, not a scheduled "two stops later" chain (`campaign_run.js:320` has no follow-up queue). All 4 draft chains also overlap existing `EVENTS` ids (`beacon`/`bait`, `defector`, `derelict`). | Add a lightweight `RUN.eventQueue` (`[{evId, afterStops}]`) in both campaign twins when Part F is built, and give the 4 chains distinct war stories that do not duplicate `beacon`, `bait`, `defector`, or `derelict`. | High |

---

## 3. Section 12 Checklist Verdicts

### 3.1 Checklist Point 1: Mechanics unclear, too strong, too weak, or breaking faction identity

- **Mastery I (320 XP):** **Needs rework.** As written (`PLAN.md:55`), scaling `adm.fx` by 1.25 breaks 9 of 24 admirals (`kassar` penalty gets worse; integer `battShots`, `speed`, `torpCd`, `hangar` cannot take 1.25x; `thorne` gets only +2 evasion). **Fix:** Explicit per-key upgrade rule (negative keys move toward 0, integer keys gain a defined +10% secondary boost or +4 flat evasion for Thorne).
- **Mastery II (440 XP):** **Approve with one clarity note.** Granting +1 Command tier once per battle (capped at tier 2) is clean, readable, and uses `cmdTier`. Clarify interaction with `spare` relic: Mastery II boosts only the **first** Command each battle (never the tier-0 second use).
- **Mastery III (600 XP, 48 drafts):** **36 of 48 are strong and clean; 12 need fixes or clarifications:**
  1. `nekhet:cap:1`: **Broken (dead on Eclipse, `sh:0`).** Fix -> Repaired ship also resets its ability cooldown and takes 25% less hull damage until next round.
  2. `sable:cap:1`: **Broken (no-op; `treeStepToward` ignores turn limits).** Fix -> Ships that make the 2-hex move also turn free toward the nearest enemy and gain +10 aim this round.
  3. `kassar:cap:1`: **Weak/misaligned + duplicates `reyes:cap:0`.** Shutting off point defense barely helps Directorate batteries/lances. Fix -> Named target also loses 15% armor for the rest of the round (floor 0).
  4. `mirelle:cap:1`: **Clashes with non-expiring `tempHp` and Glasswright `ithChargeTurn`.** Fix -> At round end while warded, leftover temporary hull also adds equal overshield (up to 25% above max shields) without deleting the temporary hull.
  5. `maren:cap:1`: **Clashes with `battle.js:445` shield regen clamp.** Fix -> Preserve overshield across turn-start regen while the flagship lives (`Math.max(u.shp, ...)`).
  6. `anuket:cap:1`: **AI softlock risk.** Making every moving ship untargetable can leave the enemy AI with zero legal targets. Fix -> Clarify: untargetable beyond range 3 (using the proven `treeDeepBlocks` pattern from `refraction`, `battle.js:1751`) until they fire or round ends, so close enemies still engage cleanly.
  7. `matriarch:cap:0`: **Boss/blink edge case.** "Cannot move on its next turn" must clarify: cannot use normal movement or rams (still turns in place, fires, and uses `blink` if a boss/Glasswright).
  8. `vaelen:cap:0` and `voice:cap:1`: **Zero-armor + shred-cap note.** Specify a separate armor-strip modifier clamped `>= 0` (not capped by `t.shredded <= 0.15` at `battle.js:937`), and note it does nothing to 0-armor Glasswright escorts (`i_wisp`, `i_blade`).
  9. `anuket:cap:0` and `nekhet:cap:0`: **Evasion cap (`45`, `battle.js:774`).** Anuket already stacks +10 passive +15 `silentArchive` +25 `phase`; clarify both stay inside the 45 cap (or swap `anuket:cap:0` to `+10% crit chance` on covered ships so it never wastes into the 45 cap!). **Pick:** Change `anuket:cap:0` Mastery III to **"+10% crit chance while covered by the bonus"** so Anuket's evasion cap is not wasted.
  10. `khepra:cap:1`: **Duration stacking.** Once `khepra` rider no longer adds +1 wall round, "kept reduction lasts two rounds" is clean and balanced (3 rounds max on repaired ships, not 4 fleet-wide).
  11. `reyes:cap:1`: **Patrol double-strike cap.** Clarify "may strike twice a round" means up to **once per enemy trigger**, max 2 triggers per round (not double-hitting one moving ship simultaneously).
  12. `vesh:cap:1`: **Clean (`works twice per battle`)**, just specify `u.treeNothingBroken < 2` fleet-wide (not per ship).
  13. `grax:cap:0`: **Clean once `grax` rider drops +30% ram dmg** (carried-round rams deal +25% damage, stacking cleanly with `mawOpens` on the first ram).
  14. `mending:cap:1`: **Small typo/clarification:** "Restored sections also regrow 2% hull each round" -> clarify "A ship with a restored section regrows +2% max hull each round (once per ship, does not stack per section)."
- **Part E (`Fold skip` & `Blood frenzy`):**
  - **Fold skip (`phase`):** **Too frustrating on enemy Eclipse swarms as drafted, and ambiguous on multi-shot weapons.** Every `d_scythe` and `d_jackal` carries `phase`. Guaranteed 100% auto-miss on all shots of a weapon every 3 turns on 4-5 enemy hulls will blank player flagships constantly (`battle.js:2130` already warns Eclipse is the strongest faction). **Recommended fix:** Keep the core fantasy (guaranteed evade + 1 movement, violet after-image, `Folded` in `#b894ff`, NO green!), **but** make it **Cooldown 4** (so `coils`/`rapid` lowers it to 3, not 2), define "next attack" cleanly as **the next weapon attack (`fireWeapon`, including torpedoes and wing strikes, not `nova` AoE or mines)**, and update the AI rule to fire **`aim`/`post-move` (or `pre` only when an enemy can reach its destination hex and has a ready weapon, NOT blindly before moving away)**.
  - **Blood frenzy (`frenzy`):** **Strong approve with one cap.** +20% damage this turn and regrow 30% of **hull damage dealt** (capped at 20% of `maxHp` per turn so one battleship alpha does not full-heal a `b_razor`, wings excluded or capped inside the same 20% ceiling). Cooldown 3. AI rule is sound (use at `aim` when a ready gun can fire and `hp < maxHp * 0.95`, else like `focus`).
- **Live Display Names Check (`rename_map_final.md` & `data.js:132-137`):**
  - `hegemony` is **Meridian Directorate** (`data.js:133`), not "Hegemony".
  - Player-facing relic text uses **salvage** / **piece of salvage** (`rename_map_final.md:231`, `campaign_run.js:343-345`). Section 11 text below follows both rules strictly.

### 3.2 Checklist Point 2: Riders and Mastery III repeating existing tree skills or Commands

Verified overlaps found across all 24 admirals and 48 capstones, with clean non-overlapping replacements used in `build_variety_1453_text.md`:

| Slot | Overlap Found in Live `data.js` | Replacement Mechanic (Non-Overlapping) |
| --- | --- | --- |
| `grax` rider | Exact duplicate of `grax:A:2:1` (`mawOpens`, +30% ram dmg) | **Ram recoil is cut in half this round.** |
| `mirelle` rider | Copies `khepra:A:2:0` (`noLayer`, block 1st hit/ship) at lvl 1 | **Warded ships gain +15% max shields for the round.** |
| `khepra` rider | Copies `thale:cap:0` (+1 wall round) at lvl 1; breaks `khepra:cap:1` | **Ships that brace or hold still repair 5% hull at round end.** |
| `mott` rider | Clones `mott:A:2:0` (`wholeYard`); hardcodes "hulk" | **Extra wings gain +10% critical chance this round.** |
| `nekhet` rider | Clones Eclipse `Archive restore` faction rule; far above lvl-1 power | **Repaired ships gain +5% armor until your next turn.** |
| `matriarch` rider | Makes `matriarch:A:0:1` (`sporeTide`) obsolete; map-wide teleport | **Swarm hits this round heal their parent brood for 3% hull.** |
| `voice` rider | Uncapped per-hit `-10%` armor strips 100% armor in 1 volley | **Volley hits strip 10% armor for the round (once per target).** |
| `kassar:cap:1` M-III | Exact copy of `reyes:cap:0` M-III (PD off), weak for batteries | **Named target loses 15% armor for the rest of the round.** |
| `sable:cap:1` M-III | No-op (`treeStepToward` already ignores turn limits) | **Moved ships turn free toward the nearest foe and gain +10 aim.** |
| `nekhet:cap:1` M-III | Dead on Eclipse (`sh:0` on all Eclipse hulls) | **Repaired ship resets ability cooldown and takes 25% less hull dmg this round.** |
| `anuket:cap:0` M-III | Wastes into the 45 evasion cap (`battle.js:774`) | **Ships covered by the bonus also gain +10% crit chance.** |
| `anuket:cap:1` M-III | Full untargetable can softlock enemy AI | **Moved ships cannot be targeted past range 3 until they fire or round ends.** |

Also note two minor polish items on clean riders:
- `ashgrove` (`scramble`) and `reyes` (`scramble`) are both distinct and clean (`+1 movement` vs `bonus attacks focus same target first`). Clarify for `reyes`: *"focus the target with the least remaining hull first"* so deterministic parity in both twins is unambiguous.
- `vex` (`barrage`) rider ("Flank guns in the free volley deal +10% damage") stacks cleanly with `vex:A:0:0` (`ledgerArcs`, +15%) without repeating it; confirm in code that `vex` rider adds `+0.10` alongside `ledgerArcs` rather than being suppressed by `PLAN.md:160`.

### 3.3 Checklist Point 3: Section 5 (Relics) & Section 6 (Refits) edge cases missed

| Item | Missed Edge Case(s) | Recommended Ruling |
| --- | --- | --- |
| `gunnery` | Does forced displacement (`cutFeeds`, `longCopy`, `drillRevision`, `rotation`, `layersShift`) count as moving? | Check `!(u.hexMoved > 0)` (voluntary move only), matching `stillPct` (`battle.js:875`) and `inheritedAim` (`battle.js:823`). |
| `afterburn` | Evasion hard cap at 45 (`battle.js:774`); what if `speed` was reduced by engine damage (`u.st.engine`)? | Full speed means `u.mp === 0 && (u.hexMoved || 0) > 0` (spent all available movement, moved at least 1 hex); stacks inside the 45 cap. |
| `flankmark` | Does it stack with `malek:cap:1` (`namedPrey`), `vorn:A:2:0` (`totalInterdiction`), and apply to wings? | Additive with other mark multipliers; applies to ship weapons and wings; one mark per enemy; clears at round end. |
| `spotter` | Does it stack with `flankmark`? Does a wing miss still mark? | Requires at least 1 landed hit (`res.hits > 0`); stacks additively with `flankmark`; `relicUseful` checks `fleetKit().carrier`. |
| `lastlight` | Lone-ship fleet; flagship killed from >30% in one shot; flagship repaired above 30% later. | `relicUseful('lastlight')` requires `F.length > 1`. Triggers when flagship drops below 30% OR is destroyed; once triggered, stays on for the battle even if repaired. |
| `coolant` | Carriers have `ab:'launch'` (`cd:1`, auto-fires at round start). Also `nova` / `blink` cancelled targets (`battle.js:2124`). | Charge 3% hull ONLY on active `useAbility` calls (never auto-`launch`). `relicUseful('coolant')` checks a hull with `ab && ab !== 'launch'`. Hull floor 1 (never kills). |
| `spare` | **Dominance + once-per-battle caps!** `B.tr.grandUsed`, `B.treeOneVoiceUsed`, `mott`/`nekhet` riders, Mastery II, and `cmdDesc` UI. | **Likely S-tier; measure carefully in sims.** Second use is strictly tier 0, does NOT re-trigger Mastery II or once-per-battle capstones (`grandUsed`, `treeOneVoiceUsed`), and does NOT fire the Command rider a second time. |
| `ledger2` | **Chorus biomass economy (`core.js:510`).** Also what happens if acquired in late game? | Cut `-10%` from battle credits AND Chorus battle biomass; keep in `LATE_SHOP.skip` (`core.js:240`). |
| `ram` | `ramInfo` (`battle.js:1209`) lets all hulls ram; ram dmg hits the 40% `maxHp` cap (`battle.js:1222`). | Gate `relicUseful('ram')` on `RAM_FAC[RUN.fac]` (`voidsworn`, `corsair`, `chorus`) or a hull with `ab === 'overburn'`. Raise `ramCap` by `+0.10` (to 50% maxHp) or keep 40% cap explicitly documented so +50% isn't silently clipped on escorts. |
| `mirror` | Boss `nova` (40 AoE), wings reflecting free flak damage, shield vs hull damage, killing attacker mid-volley. | **Exclude wings** (ships only; carrier swarms reflecting 50% of flak/guns is degenerate). Reflect 50% of **hull damage taken** (after shields/armor), direct hull hit to attacker, cannot kill below 1 HP OR resolves after the volley ends (avoid re-entrant `killUnit` inside `applyHit`). Bosses take reflected damage capped at 10% of boss `maxHp` per trigger. |
| `beacon` | No interactive deployment phase exists (`battle.js:282, 1706`). | Replace with: **"On round 1, every ship gains +2 movement and +1 turn."** Clean, parity-safe, zero new UI phase. |
| `quiet` | Round-1 AI softlock if all player ships stay >= 6 hexes; escort/hold objectives; enemy `nova` (AoE). | Reuse `treeDeepBlocks` pattern; verify in AI sims that enemy ships advance normally when no target is within 5 hexes on round 1. Clarify range is `>= 6` (shots from 5 or closer hit normally) and AoE/mines/wings adjacent still work. |
| Refits (`locker`, `chaser`, `spill`, `relay`) | `locker` lacks credit cost and speed floor; `chaser` fits only 8/42 hulls (0 Chorus/Glasswright/Eclipse); `spill` on shieldless factions; `relay` on Glasswrights (`noBrace`) + Sunward `braceCover` clash. | `locker`: `65 credits`, `+40% board, -1 speed (min speed 2)`. `chaser`: `85 credits`, widen to **any non-turret fore or flank weapon fires one arc wider at -20% damage** (fits every faction, gate `canFitModule` on any `F`/`P`/`S` weapon!). `spill`: `70 credits`, `MOD_NEED.spill = 'shields'` (excludes Chorus & Eclipse), next weapon attack (`fireWeapon`) deals +30% (clears at battle end, does not stack with itself). `relay`: `75 credits`, exclude `noBrace` (Glasswrights), separate `relayCover` slot so it never overwrites Sunward 40% `braceCover`, auto-picks most-damaged ally within 2 hexes not already braced/covered. |

### 3.4 Checklist Point 4: Verdict on Build Order, Checks, and OPEN Picks

- **Build order verdict (Section 10):** **Reorder slightly: move Part E (Fold skip & Blood frenzy) to Order #1 (or #2 right after Capstone Mastery), and keep Part F (Event chains) optional/last.**
  - **Why:** Part E is tiny (1 run + 1 review), fixes two copied faction abilities that players see in every Eclipse/Chorus battle right now (including the green Eclipse callout bug!), and gives immediate balance signal before relics/riders pile extra power onto player fleets.
  - **Recommended order:**
    1. **Part E: Fold skip & Blood frenzy** (fast win, fixes copied abilities + AI + Eclipse green text bug).
    2. **Part A: Capstone mastery** (replaces live "Placeholder" text on the lineage screen; uses the fixed Mastery I table and fixed Mastery III drafts).
    3. **Part D: Command riders** (makes all 24 admirals feel distinct from run 1, with `cmdAlt` binding cleanly tested).
    4. **Part B + C: Relics and refits** (split or paired; simplified massively once `beacon` becomes Round 1 +2 move/+1 turn instead of a new deployment UI phase).
    5. **Part F: Event chains** (optional later PR; requires the new `RUN.eventQueue` scheduler in both campaign twins).
- **Coverage checks verdict (Section 10):** Artoo's two added checks (exhaustive key coverage across 48 Mastery III + 24 riders + 12 relics + 4 refits, and earn-save-respec-reload) are essential. Add two more cheap assertions:
  1. **`altCommand` rider parity check:** start a run with `cmdAlt: true` (`RUN.cmdOverride`) and prove the active rider matches the overridden Command, never firing a dead rider.
  2. **MOD-3 / `relicUseful` faction-gate check:** prove `relay` is never offered to Glasswrights, `spill` never to Chorus/Eclipse, `ram` never to Glasswrights, `coolant` never to a launch-only fleet, and `lastlight` never to a 1-ship fleet.
- **Verdicts on every OPEN pick:**
  - Section 4 (`OPEN: option C` for Capstone mastery): **Yes, keep option C**, with the authored Mastery I table instead of blind 1.25x.
  - Section 5 (`OPEN: all 12` relics): **Keep 11 as revised; simplify `beacon` to Round 1 +2 move/+1 turn** and watch `spare` closely in sims (if `spare` dominates, drop it or limit to tier 0 without capstones/riders).
  - Section 6 (`OPEN: all 4` refits): **Keep all 4** with the `relay` (`!noBrace`), `chaser` (non-turret arc widening), and `locker` (credit price + min speed 2) fixes.
  - Section 7 (`OPEN: yes, one rider per admiral`): **Strong yes**, after fixing the 6 overlapping/overpowered riders and binding riders to `commandFor('player')` under `cmdAlt`.
  - Section 8 (`OPEN: option 1 for both` Fold skip & Blood frenzy): **Yes to Option 1 for both**, with Fold skip tuned to **Cooldown 4** (plus violet `Folded` callout and post-move/destination-threat AI rule) and Blood frenzy capped at **20% `maxHp` regrowth per turn** on hull damage dealt.
  - Section 9 (`OPEN: later` event chains): **Keep as optional Part 5 (later)**, since it needs a real `RUN.eventQueue` scheduler in both campaign twins.

---

## 4. Recommended Next Step

Fold the 10 findings above into `contrib/opus/design/build_variety_1453/PLAN.md` (updating Mastery I's rule, the 6 replaced riders, the 5 replaced/clarified Mastery III rows, the `beacon`/`relay`/`chaser`/`ledger2`/`mirror`/`spare` edge cases, and Fold skip cooldown 4), then present the clean summary + `contrib/neon/design/build_variety_1453_text.md` to Ryan for his pick on the OPEN items before opening Part E / Part A implementation issues.

---

## 5. Not Checked

- **Godot UI layout and pixel font wrapping:** Did not open or run Godot UI scenes (`lineage`, `reward`, `shipyard`, `hud.gd`) to measure exact rendered pixel width of cards; text lengths in `build_variety_1453_text.md` are verified strictly against `PLAN.md` Section 11 character caps.
- **Bot balance simulations:** No headless Node or Godot balance sims were executed (there is no implementation code on `opus/issue-1453` yet); all dominance warnings (`spare`, `mirror`, `phase` CD 3) are inferred from live formulas in `battle.js`.
- **Full line-by-line read of `godot/rules/rules.gd` (7,328 lines) and `godot/campaign/campaign.gd` (4,071 lines):** Only the specific corresponding functions listed in Section 1 were inspected to confirm parity with the browser JS files.
- **Campaign save/reload migration tests:** Verified `campaign.gd:1734-1736` preserves earned XP across respec; did not run full campaign save test suites.
- **Existing `RELIC_NAMES` / `MOD_NAMES` per-faction overrides (`data.js:279-291`):** Section 11 requests the base 12 relic names and 4 refit names (Crusade/neutral spine); faction-specific alias tables for the 12 new relics and 4 new refits were not requested in Section 11 and are not written.
