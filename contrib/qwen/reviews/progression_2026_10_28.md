Filed copy note (chair): en and em dashes in the original normalized to hyphens; wording otherwise verbatim.

# PROGRESSION AUDIT - LEG REPORT: Voidsworn (commit 264f441d)

## PROOF OF READING

| Slice | Line span as stated in pack |
|---|---|
| data.js - FACTIONS tail, ADMIRALS, LEGACY, name pools | lines 195-280 |
| data.js - HULL_VARIANTS, MASTERY_XP, MASTERY_PERKS, FAVOUR_TIERS, HEAT, ARCHETYPES, NODE_MODS | lines 545-616 |
| core.js - defaultMeta and the first-load progression credit | lines 45-70 |
| campaign3d.js - runRenown | lines 25-35 |
| main3d.js - boot, including the unlock grant | lines 1-20 |
| campaign_meta.js - title, admiral select, run options, aspect, Progression screens, buy actions, help, end-of-run carry-forward | FULL (216 lines) |
| CHAIR SHEET | end of pack, labelled |

All six slices and the chair sheet received and read.

## OVERALL VERDICT

LIVE BUT MISPRICED. Three of the five progression clocks (mastery, favour, Heat) are live and internally coherent, but the boot-time bypass hands every player all LEGACY items and all 24 admirals for free, collapsing 1,565 of 1,815 renown-sink value and reducing renown to a shallow 250-point variant shop that exhausts itself within a handful of runs.

## FINDINGS (ranked most severe first)

1. BLOCKER - Boot bypass guts the renown economy. OBSERVED. main3d.js boot reads: if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true; for(const k in ADMIRALS) META.admirals[k]=true; }. Because defaultMeta() initialises opts:{}, a fresh save has o.unlockAll === undefined, which satisfies !==false. Every LEGACY node and every admiral is granted on first boot. The LEGACY tree (635 renown) and the full admiral cost ladder (930 renown) become dead purchases. The only remaining renown sink is 250 renown of hull variants.

2. BLOCKER - Renown has no meaningful long-term sink. OBSERVED. With LEGACY and admirals free, the entire renown economy is 12 hull variants totalling 250 renown (costs range 15-30 each). At the chair's ~100 renown per win, a player can buy every variant in roughly three wins. After that, renown accumulates with nothing to spend it on. Heat adds +10 % per rule to a currency that has no outlet.

3. FIX - Admiral cost ladder and buyAdmiral are dead code paths. OBSERVED. ADMIRALS carry cost:0/30/45/80 per faction; ACT.buyAdmiral checks META.admirals[id] and deducts META.renown. The admiral-select UI renders "Unlock for ${a.cost} renown in Legacy" for locked admirals. None of this can fire because boot already sets every META.admirals[k]=true. The lock state, the cost field, and the buy handler are unreachable.

4. FIX - Help text contradicts the admiral-lock UI. OBSERVED. The help screen states "every faction, admiral and ship is available from the start", which matches the bypass outcome. But the admiral-select screen still renders locked cards with "Unlock for ${a.cost} renown in Legacy". A player who somehow sets unlockAll:false would see a lock/cost UI; everyone else sees a help text that describes a state produced by what appears to be a dev default. INFERRED: the help copy was likely written to describe the bypass state rather than the intended release state.

5. FIX - Heat's reward shape is misaligned with the live economy. OBSERVED. Each Heat rule adds +10% renown (campaign_meta.js: +${hl*10}% renown). At max Heat (weight sum 9) that is +90 % on a base of ~100 for a win, yielding ~190 renown. But with only 250 renown of variants to buy, a player who already owns a few variants has nothing left to earn. INFERRED: Heat rewards a currency that the bypass has already devalued.

6. FIX - Heat's difficulty-to-reward ratio is poor at a 17 % win rate. INFERRED. Heat rules like "Enemy fleets are 15% larger" (h_hunted, w:2) and "Any enemy ship may reassemble once" (h_undying, w:2) are substantial difficulty spikes. At a baseline 17 % win rate, adding even one Heat rule drops the expected win rate further, and the +10 % renown bonus only applies on a win. On a loss the player earns the reduced base (~8-44 renown) plus a trivial Heat bonus. The risk-reward is inverted for the majority of runs.

7. NOTE - First-load backfill caps at 60 renown and silently computes mastery/favour. OBSERVED. migrateMeta contains a one-time backfill: m.renown=(m.renown||0)+Math.min(60,m._back||0). This grants up to 60 renown and retroactive mastery/favour from telemetry for pre-progression saves. It is a migration path, not a design flaw, but it stacks on top of the bypass: a returning player gets all LEGACY, all admirals, and up to 60 bonus renown.

8. NOTE - Mastery and favour are live, well-shaped clocks, but spread thin. OBSERVED. Mastery thresholds are 0/6/16/30/50; favour tiers at 0/4/12/25. Both progress per-run and are not bypassed. However, 24 admirals x 4 mastery levels and 6 cores x 3 favour tiers create a very wide matrix. INFERRED: a focused player will chase depth on 1-2 admirals and 1-2 cores; the remaining entries become background noise.

9. NOTE - FIT_SLOTS is schema-only, no rules read it. OBSERVED. Comment in data.js: "schema only, nothing reads these for rules yet". The field ship.fit = {pod, module, trim} is reserved. This is flagged future content, not a current bug, but it occupies pack space and could confuse a reviewer into expecting a live system.

10. NOTE - Arc variants sit outside the renown economy cleanly. OBSERVED. Six variants carry arc:'<faction>' and cost:0, with the comment "earned by finishing that story arc (its Nemesis's last fight), never sold for renown". ACT.buyVariant guards with if(v.arc) return. This is a clean separation: 12 renown variants, 6 story variants. No issue, but it means the renown variant pool is even smaller than the raw 18-variant table suggests.

## EXPLICIT CHECKS

### a. THE BYPASS

The boot line in main3d.js grants every LEGACY node (META.unlocked[k]=true for all k in LEGACY) and every admiral (META.admirals[k]=true for all k in ADMIRALS) unless the saved option unlockAll is literally false. Because defaultMeta() sets opts:{}, the field is undefined on any fresh or migrated save, and undefined !== false is true, so the grant fires unconditionally.

Effect on renown as a currency: LEGACY (635) and admirals (930) account for 1,565 of 1,815 total renown-sink value. Removing them leaves 250 renown of hull variants. Renown goes from a multi-run currency to a two-run currency. The buyLegacy and buyAdmiral handlers exist in campaign_meta.js but are unreachable; the LEGACY screen tab is absent from the progression UI (tabs are variants, mastery, favour, heat, fallen), so there is no visible shop for LEGACY items at all.

Effect on the admiral cost ladder: The 0/30/45/80 ladder per faction (155 per faction, 930 total) is dead. All 24 admirals are selectable from the first session. The admiral-select screen's lock rendering ("Unlock for ${a.cost} renown in Legacy") can never display for any admiral.

Effect on a new player's first-run experience: The player opens the game with every option already unlocked. There is no first aspirational purchase, no "one more run to unlock X." The first session's progression feedback is limited to mastery XP and favour ticks, which are slow and invisible without checking the Progression screen. The help text reinforces this by stating "every faction, admiral and ship is available from the start", framing the bypass as the intended state.

Deliberate or leftover? INFERRED: ambiguous. Two pieces of evidence pull in different directions. (1) The help text explicitly says admirals are available from the start, suggesting the bypass is a design philosophy (content access is open; progression is depth, not gating). (2) The admiral cost fields, the buyAdmiral handler, the lock-state UI code, and the LEGACY item table with costs all exist and are maintained, suggesting an intended lock system that the bypass overrides. No comment in the pack explains the bypass as intentional design. The opt-out check (!==false rather than ===true) is a pattern more common in dev convenience toggles than in release design. The balance of evidence leans toward leftover dev default that the help text was then written around, but I cannot confirm intent from the pack alone.

### b. PACING

Arithmetic check against runRenown. The formula in campaign3d.js is:
s.battles*2 + s.elites*4 + s.bosses*15 + Math.floor(s.kills/4) + (RUN.sector-1)*5

Chair's winning-run estimate (12 battles, 3 elites, 3 bosses, 48 kills, sector 3):
12x2 + 3x4 + 3x15 + floor(48/4) + 2x5 = 24 + 12 + 45 + 12 + 10 = 103. Chair says "roughly 100." Checks.

Sector-2 death estimate (~8 battles, 1 elite, 1 boss, 30 kills):
16 + 4 + 15 + 7 + 5 = 47. Chair says "roughly 44." Close; the small gap is within the assumed stat range. Checks.

Sector-1 death estimate (~4 battles, 0 elites, 0 bosses, 15 kills):
8 + 0 + 0 + 3 + 0 = 11. Chair says "roughly 8." Reasonable if kills are lower. Checks.

Runs to fill each sink (at ~100/win, ~44/sector-2 loss, ~8/sector-1 loss, 17 % win rate):

| Sink | Cost | Status | Runs to fill (win only) | Runs at 17 % WR |
|---|---|---|---|---|
| LEGACY | 635 | BYPASSED | 0 | 0 |
| One faction admirals | 155 | BYPASSED | 0 | 0 |
| All admirals | 930 | BYPASSED | 0 | 0 |
| Bought variants | 250 | Live | ~3 wins | ~5-6 mixed runs |

Where pacing breaks: It breaks at the top. Once the 250 variant renown is spent (about 3 wins or about 6 mixed runs), renown has zero sinks. Every subsequent run adds renown that cannot be spent. Heat's +10 %-per-rule bonus accelerates this wall. The mastery and favour clocks continue, but they are time-gated, not renown-gated, so renown income becomes pure surplus. The chair sheet's "18+ winning runs for the full 1,815" figure is technically correct against the listed sinks but is fiction: the bypass removes 86 % of that total before the player's first session ends.

### c. SINK QUALITY

Power sinks: LEGACY contains power items (Battleship hulls at 60, Dreadnought at 120, +2 fleet command points at 35/70). All are bypassed. No live renown sink grants raw power.

Option sinks: Admirals (bypassed) and hull variants (live) are option sinks. Variants swap weapon loadouts and occasionally a stat (e.g. "No hangar; scatter broadsides, a turret and 20 more hull" on c_hulk_g). They give tactical shape, not stat inflation. Mastery perks are also options: alternate fleet, wider aspect choice, second Command, veteran flag captain.

Convenience sinks: War chests (+75 credits x 3 tiers), Master shipwrights (-15 % prices), Recovery crews (+20 % battle credits) are convenience/economy accelerators. All in LEGACY, all bypassed.

Is there a multi-run save-up sink? No. The most expensive live variant is d_harvester_t at 30 renown. No single variant requires more than one good run to afford. LEGACY's Dreadnought at 120 would have been a multi-run save, but it is free. Mastery and favour are time-gated, not renown-gated, so they cannot serve as a "save up" target. INFERRED: the pack contains no sink that produces the roguelite feeling of "three more runs and I can finally buy X."

### d. MASTERY AND SYNC

Three clocks:

- Renown: per-run currency, spent on variants. Cheap, exhausts in ~3 wins.
- Mastery: per-admiral XP, thresholds 0/6/16/30/50. A win earns ~43 XP (12 battles + 6 elite + 15 boss + 10 victory). Level 1 (Alternate fleet) at 6 XP is one run. Level 4 (Flag captain) at 50 XP is ~2 wins or ~3-4 sector-2 losses. x24 admirals.
- Core sync (favour): per-core protocol count, tiers at 0/4/12/25. A run offers limited protocol picks split across 4 in-range cores. Full sync at 25 is a many-run commitment per core. x6 cores.

Complement or cannibalise? INFERRED: they complement in design intent - renown shapes what hulls you can field, mastery shapes how deep your admiral toolkit goes, favour shapes which protocols are available and how rare. Three different axes. In practice they cannibalise attention because all three progress simultaneously and the player cannot focus on one without the others ticking in the background. The renown clock finishes so quickly that by run 5 it is background noise, leaving mastery and favour as the only active chases.

Run 1 vs. Run 5 chase:

- Run 1: The player has everything (bypass). No mastery, no favour, no variants. The chase is purely learning the game. There is no progression target to name.
- Run 5: The player likely has mastery 1-2 on a favourite admiral (alternate fleet unlocked, maybe wider counsel), 3-6 favour with a preferred core, and 2-4 variants bought. The chase shifts to mastery level 3 (Second Command) and favour tier 2 (Synced: start with a protocol). These are meaningful but small steps. The big-ticket feeling of "run 1 vs. run 5" is blunted because the bypass removed the most visible unlock milestones (new admirals, LEGACY items).

### e. HEAT

Heat unlocks after the first win (if((META.stats.wins||0)>0) gates the Heat UI). Each rule adds +10 % renown at end-of-run: Math.round(runRenown()*(1+.1*hl)). Seven rules are available with weights summing to 9 (max +90 %).

Is +10 % per rule the right reward shape at 17 % win rate? INFERRED: no, for two compounding reasons.

1. The reward is too small relative to the risk. At 17 % baseline, adding even a w:2 rule like h_hunted ("Enemy fleets are 15% larger") materially drops the win probability. The expected renown gain from the Heat bonus is P(win|Heat) x bonus minus P(win|no Heat) x 0, and if the bonus causes the player to lose runs they would otherwise have won, the net is negative. On a loss, the Heat bonus applies to a small base (~8-44 renown), adding 1-4 renown - functionally invisible.

2. The reward feeds a dead currency. Renown's only live sink is 250 points of variants. A player who has bought 4-5 variants already has little left to buy. Heat accelerates renown income into a currency with no remaining outlet. The reward shape (more of a saturated currency) does not match the player's actual progression needs (mastery depth, favour tiers, or a new sink).

A better shape at 17 % would be: reward Heat on survival depth (sector reached, battles won) rather than only on victory, or feed Heat progress into mastery/favour rather than renown.

## RUN 1 / RUN 5 / RUN 10

RUN 1. The player has all 24 admirals and all 12 LEGACY items free. No mastery, no favour, no variants, no Heat. They pick an admiral (default Vex), choose an aspect, and launch. If they die in sector 1 (~8 renown), they cannot afford even the cheapest variant (15). If they die in sector 2 (~44 renown), they can buy one 15-cost variant. Verdict: completing run 1 feels unrewarded by the progression systems in this pack. There is no unlock moment, no "I earned this." The bypass removed the aspirational targets that would make a first run feel like a step toward something.

RUN 5. The player has ~1-2 mastery levels on their main admiral, ~4-8 favour with one or two cores, and 2-4 variants purchased. There is a ~58 % chance they have won at least once (1 - 0.83^5), which unlocks Heat. The active chase is mastery level 2-3 and favour tier 2 (Synced). Verdict: completing run 5 feels modestly rewarded if the player won (Heat opens, a mastery perk may have levelled up). If they have not won, the reward is a small variant purchase and slow mastery ticks. The progression is real but quiet.

RUN 10. The player likely has mastery 3-4 on their favourite admiral, favour tier 2-3 on a preferred core, and most or all 12 variants bought. Heat may be active but is feeding a saturated renown pool. The remaining chase is mastery across the other 23 admirals and favour toward Full sync (25) with a chosen core. Verdict: completing run 10 feels like grinding a wide matrix rather than climbing a ladder. The per-admiral and per-core depth is there, but the absence of any high-cost renown sink means the currency reward loop is closed. The systems that remain (mastery, favour) are the real long-term hooks, and they work - but they carry the full progression weight that LEGACY, admirals, and a deeper variant pool were meant to share.

## NOT CHECKED

- Encounter balance and the 17 % win-rate figure. The pack states it in the prompt but provides no simulation data or difficulty curve. I cannot verify whether Heat rules actually shift win probability as assumed.
- BOONS and PATRONS data. Referenced in campaign_meta.js and the backfill code but not included in the pack. I cannot judge protocol quality, patron balance, or how favour tiers change the boon pool.
- Hull stats, weapon numbers, and CP budgets. HULLS and W are referenced but not in the pack. I cannot judge whether variants are balanced sidegrades or strict upgrades/downgrades.
- Sector scaling and flagship tuning. The comment about admirals sitting "about 55 to 85% against a sector 1 flagship (bossmatrix)" references port_notes.md, which is not in the pack.
- Story-arc content and Nemesis fights. Arc variants are gated on "finishing that faction's story arc," but the arc missions, Nemesis encounters, and unlock flow are not in the pack.
- The FIT_SLOTS system. Explicitly schema-only; no rules read it. Cannot judge.
- Whether the bypass has been playtested. No telemetry schema, A/B flag, or design note in the pack addresses this.
- Multiplayer, leaderboards, or any social layer. Not present in the pack.

## QUESTIONS FOR THE DESIGNER

1. Is the unlockAll bypass a design statement or a dev leftover? If it is intentional (all content open, progression is depth not gating), then the admiral cost fields, the buyAdmiral handler, the LEGACY cost table, and the lock-state UI should be removed to avoid dead code and contradictory player-facing text. If it is a leftover, it should be flipped to ===true (opt-in) before release. This is a taste-and-intent call only the designer can make.

2. What should renown be for? With LEGACY and admirals bypassed, renown is a 250-point variant shop. Should Heat's reward be redirected to a new sink (mastery accelerators, favour boosts, cosmetic flags), should variant costs be raised to create a genuine multi-run save, or is renown meant to stay a small, quickly-exhausted currency? This is a priority call about what progression fantasy the game is selling.

3. At a 17 % win rate, should Heat reward survival, not just victory? The current shape pays +10 % renown only on a completed run's renown total, which is tiny on a loss. Would Heat feel more worthwhile if it paid a flat bonus per sector reached, per battle won, or per elite killed, independent of the final win/loss? This is a design-intent question about whether Heat is a victory celebration or a difficulty ladder for everyone.
