Gemini (Argon High) blind leg, Oct 28 program item 1 (progression audit). Filed as a single reviews copy per house rule, with this chair header. Em dashes in the original normalized to hyphens; wording otherwise verbatim. Method note from the run: fresh Gemini chat signed in as rcbailey12@gmail.com (Pro), 4 Argon selected with Thinking level High, prompt bar verified "Argon High" before sending; both files uploaded together with no error tiles; first chat completed with no retry, no rate limit and no traffic check.

1. Proof of Reading & Overall Verdict

- data.js: lines 195-280 (FACTIONS tail, ADMIRALS (note the cost field), LEGACY, name pools)
- data.js: lines 545-616 (HULL_VARIANTS, MASTERY_XP, MASTERY_PERKS, FAVOUR_TIERS, HEAT, ARCHETYPES, NODE_MODS)
- core.js: lines 45-70 (defaultMeta and the first-load progression credit)
- campaign3d.js: lines 25-35 (runRenown)
- main3d.js: lines 1-20 (boot, including the unlock grant)
- campaign_meta.js: FULL (216 lines) (title, admiral select, run options, aspect screen, Progression screens (variants, mastery, favour, heat, fallen), buy actions, help, end-of-run carry-forward)

OVERALL VERDICT: BYPASSED - Boot code automatically unlocks all 12 LEGACY upgrades (635 renown) and all 24 ADMIRALS (930 renown) while legacyScreen() omits any UI to buy them, eliminating 86.2% of the game's 1,815 total renown sinks and leaving only 250 renown of hull variants before renown becomes permanently useless.

2. Findings (Ranked Most Severe First)

[BLOCKER] Boot grant and rewritten Progression UI bypass 1,565 of 1,815 total renown sinks (LEGACY and ADMIRALS).

OBSERVED: main3d.js runs if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true; for(const k in ADMIRALS) META.admirals[k]=true; } on boot.

OBSERVED: legacyScreen() defines only five tabs: [['variants','Hull variants'],['mastery','Admiral mastery'],['favour','Core sync'],['heat','Heat'],['fallen','Hall of the fallen']], with no UI rendering LEGACY or ADMIRALS purchases.

INFERRED: Bypassing LEGACY (635 renown) and ADMIRALS (930 renown) leaves only the 12 purchasable HULL_VARIANTS (250 renown total, 40-45 renown per faction) as live sinks, causing renown to become a dead currency after ~2.5 winning runs or ~6 Sector-2 runs.

[BLOCKER] Setting unlockAll: false soft-locks all non-Vex admirals and LEGACY items because purchase UI was removed.

OBSERVED: defaultMeta() initializes admirals:{vex:true}, while admiralScreen() renders <span class="muted">Unlock for ${a.cost} renown in Legacy</span> for locked admirals, and ACT.buyLegacy / ACT.buyAdmiral have no buttons calling them in legacyScreen().

INFERRED: If META.opts.unlockAll is set to false, players have no screen to spend renown on LEGACY items or ADMIRALS, and even the five other factions' cost:0 starter admirals (kassar, grax, matriarch, aelith, nekhet) render as .locked without a Select button.

[FIX] Post-win Heat rewards only +10% renown per level, a currency that is already nearly or completely exhausted when Heat unlocks.

OBSERVED: Heat requires (META.stats.wins||0)>0 to unlock and scales only renown via ren=Math.round((typeof runRenown==='function'?runRenown():0)*(1+.1*hl)) in endRun().

INFERRED: At a ~17% win rate (~5 losses and 1 win), a player typically accumulates ~200-250 renown by the time they win their first run - already enough to buy almost or literally all 250 renown of purchasable hull variants, leaving Heat's sole mechanical reward (+10% renown) with nothing left to buy.

[FIX] Title screen Progression notification dot stays lit permanently once renown reaches 15, even when nothing can be bought.

OBSERVED: titleScreen() renders Progression${(META.renown||0)>=15?' <span class="gilt num">●</span>':''} without checking whether any unowned HULL_VARIANTS are affordable or remaining.

INFERRED: Once a player buys the five 15-renown variants (leaving only 20, 25, and 30-renown variants) or buys all 12 purchasable variants (250 renown), holding >=15 renown causes a permanent false-positive notification dot on the title screen.

[FIX] End-of-run carry-forward summary (carryHtml) omits Core Sync (favour) gains and tier-up notifications.

OBSERVED: endRun() constructs carryHtml displaying +<cy.ren> renown and +<cy.mxGain> mastery, but never reads or renders META.favour or FAVOUR_TIERS.

INFERRED: Because Core Sync is incremented mid-run on boon_pick rather than in endRun(), players receive no end-of-run feedback when a core crosses the 4 (Partial sync), 12 (Synced), or 25 (Full sync) thresholds.

[FIX] Mastery XP formula in endRun() double-counts elites and bosses relative to migrateMeta() backfill.

OBSERVED: migrateMeta() awards e.kind==='boss'?5:e.kind==='elite'?2:1 per battle won, whereas endRun() computes mxGain=s.battles+s.elites*2+s.bosses*5+(victory?10:0).

INFERRED: If s.battles counts all battles won (as displayed by tile(s.battles,'battles won') in runRecap()), endRun() awards 3 XP for an elite (1+2) and 6 XP for a boss (1+5), yielding 43 XP on a 12-battle win versus 37 XP under migrateMeta()'s mutually exclusive formula.

[FIX] Switching factions on admiralScreen() does not reset runOpt.alt or runOpt.cmdAlt.

OBSERVED: ACT.pickAdmiral resets if(pickedAdmiral!==a){ runOpt.alt=false; runOpt.cmdAlt=false; }, whereas ACT.pickFaction updates pickedFaction and calls admiralScreen(), which reassigns pickedAdmiral directly without resetting runOpt.

INFERRED: If a player enables Alternate fleet or a second Command on one admiral and then clicks another faction whose default admiral also has ml>=1 or ml>=3, those toggles remain silently active for the new faction's admiral.

[NOTE] A first-run victory with a fresh admiral awards 43 Mastery XP (7 XP shy of Level 4) while endRun() prompts switching factions.

OBSERVED: MASTERY_XP=[0,6,16,30,50], a standard 12-battle win awards 43 XP (12+6+15+10), and endRun() renders <button class="primary" data-act="nextFac" data-arg="${nf}">Play as ${esc(NF.n)}</button> on victory.

INFERRED: Winning on a fresh admiral stops at Level 3 (43/50 XP), creating friction between the primary UI prompt to rotate to an un-won faction and the need to play a second run with the same admiral to unlock Level 4 (Flag captain).

[NOTE] Core Sync (FAVOUR_TIERS) and Mastery Level 4 (Flag captain) grant compounding vertical power without requiring Heat.

OBSERVED: FAVOUR_TIERS grants "Its protocols are rare more often." at 4, "If it is in range of your run, you start with one of its protocols." at 12, and "Its protocols are never common." at 25, while Mastery 4 grants "Your flagship starts at Mk II, its captain a Captain with a perk.".

INFERRED: Because rare and epic protocols grant 2x and 3x sync (1+(e.r||0) in migrateMeta()), reaching Tier 1 (4 favour) accelerates reaching Tier 2 (12) and Tier 3 (25), steadily inflating baseline player power across runs.

3. Explicit Audit Checks

a. THE BYPASS

Granting all LEGACY items (635 renown) and all ADMIRALS (930 renown) on boot via if(o.unlockAll!==false) strips 86.2% (1,565 / 1,815) of the game's renown sinks, reducing renown to a minor currency that only buys 12 hull variants (250 renown total) before becoming completely useless. It completely flattens the 0/30/45/80 renown admiral cost ladder across all six factions, so a new player on Run 1 is immediately presented with all 6 factions and all 24 admirals (plus every LEGACY perk if gameplay code still checks META.unlocked) rather than a guided onboarding ramp starting from Admiral Vex (admirals:{vex:true} in defaultMeta()). Evidence in the pack shows this bypass is a deliberate design change that left vestigial code behind rather than an accidental debug toggle: helpScreen() explicitly states "every faction, admiral and ship is available from the start" and "renown buys hull variants for your shipyards", and legacyScreen() was purposefully built with tabs only for variants, mastery, favour, heat, and fallen - leaving LEGACY, ADMIRALS[k].cost, ACT.buyLegacy, and ACT.buyAdmiral as unreferenced dead code.

b. PACING

Checking runRenown() (s.battles*2+s.elites*4+s.bosses*15+Math.floor(s.kills/4)+(RUN.sector-1)*5) against the chair sheet's assumptions confirms its arithmetic: a Sector 3 win (12 battles, 3 elites, 3 bosses, 48 kills, sector 3) pays 24 + 12 + 45 + 12 + 10 = 103 renown (chair: ~100); a Sector 2 loss (e.g., 6 battles, 1-2 elites, 1 boss, 24 kills, sector 2) pays 42-46 renown (chair: ~44); and a Sector 1 loss (e.g., 3 battles, 0 elites, 0 bosses, 8 kills, sector 1) pays 6 + 0 + 0 + 2 + 0 = 8 renown (chair: ~8). At those income rates (103 per win / 44 per Sector 2 loss / 8 per Sector 1 loss), filling each sink requires: LEGACY (635 renown, bypassed) = 6.2 wins (7 runs), 14.4 Sector-2 losses (15 runs), or 79.4 Sector-1 losses (80 runs); one faction's admiral ladder (155 renown = 0+30+45+80, bypassed) = 1.5 wins (2 runs), 3.5 Sector-2 losses (4 runs), or 19.4 Sector-1 losses (20 runs); all admirals (930 renown = 6 x 155, bypassed) = 9.0 wins (9 runs), 21.1 Sector-2 losses (22 runs), or 116.3 Sector-1 losses (117 runs); and bought hull variants (250 renown, the only live sink, 40-45 per faction) = 2.4 wins (3 runs), 5.7 Sector-2 losses (6 runs), or 31.3 Sector-1 losses (32 runs). Pacing breaks at both ends: in the live build, cutting 1,565 renown of sinks means a player exhausts the entire 250-renown variant pool in just ~6-8 mixed runs, while on Run 1 a player who dies in Sector 1 earns only ~8 renown (since bosses pay 15 and (RUN.sector-1)*5 is 0), which is not even enough to buy the cheapest 15-renown hull variant.

c. SINK QUALITY

Sorting all defined unlocks by reward type shows a split between bypassed vertical upgrades and live horizontal options: vertical power sits in the bypassed LEGACY economy/command perks (chest1/2/3 for +75/+150/+225 starting credits, cmd1/2 for +2/+4 CP, vets for Commander captains with a perk, founder for free salvage, wrights for -15% shipyard prices, salvagers for +20% battle credits), Admiral Mastery Level 4 (Flag captain: flagship starts at Mk II with a perked Captain), and Core Sync Tiers 1-3 (Partial sync for rarer protocols, Synced for a free starting protocol giftBoon, and Full sync eliminating common protocols); horizontal options sit in the 18 HULL_VARIANTS (12 bought for 15-30 renown and 6 story-arc sidegrades trading weapons, speed, shields, or hangars), the bypassed LEGACY hull classes (u_carrier 30, u_battleship 60, u_dread 120), the 24 ADMIRALS, and Mastery Levels 1 and 3 (Alternate fleet and Second Command); and draft consistency/convenience sits in Mastery Level 2 (Wider counsel: 4 flagship aspects offered instead of 3). Because u_dread (120 renown) and top-tier admirals (80 renown) are bypassed on boot, the most expensive purchasable item left in the entire game is a 30-renown hull variant (d_harvester_t), and the other 11 purchasable variants cost 15, 20, or 25 renown - meaning there is no multi-run aspirational renown sink left for a player to save toward, as a single Sector 2 loss (~44 renown) can buy any variant in the game outright.

d. MASTERY AND SYNC

Renown (global currency spent on any faction's hull variants), Core Sync (semi-global favour at 0/4/12/25 across 6 cores, 4 of which are in range each run), and Admiral Mastery (strictly local XP at 0/6/16/30/50 across 24 individual admirals) complement each other in granularity during early runs, because every run advances global/semi-global progress while levelling the current admiral. However, they cannibalise each other's incentives after a few runs: Renown hits its 250-point ceiling long before Mastery (1,200 total XP across 24 admirals) or Core Sync (150+ total favour across 6 cores), and endRun() on a victory pushes a primary button (nextFacPick()) to switch to an un-won faction, which directly pulls players away from running the same admiral a second time to finish Mastery Level 4 (50 XP). Consequently, on Run 1 a player is chasing their first 15-25 renown for a hull variant, Mastery Level 1 (6 XP) on their starting admiral, and Partial sync (4 favour) on any core, whereas by Run 5 (with most desired variants already owned) the player is deliberately routing across sector map nodes to target specific Core signals for Synced (12 favour for a starting giftBoon) or Full sync (25 favour) and targeting Second Command (30 XP) or Flag captain (50 XP) on a chosen admiral.

e. HEAT

Unlocking Heat after the first win ((META.stats.wins||0)>0) and paying +10% renown per Heat weight (ren=Math.round((typeof runRenown==='function'?runRenown():0)*(1+.1*hl))) is the wrong reward shape for a game with a ~17% win rate. A player winning roughly 1 in 6 runs will typically play ~5 losing runs before winning on Run 6, earning ~200-250 renown along the way - which already buys nearly or literally every purchasable hull variant in the game (250 renown total) before Heat ever opens. Furthermore, Heat modifiers add substantial difficulty (up to weight 9 / +90% renown across 7 rules, including weight-2 rules like h_hunted for +15% enemy fleet size and h_undying where enemies reassemble on death), yet Heat grants zero bonus to Admiral Mastery XP (mxGain) or Core Sync (favour) and unlocks no unique hulls or cosmetics, offering only a per-faction text label (Heat X via META.heatBest[f]) and bonus renown that the player can no longer spend.

4. Milestone Check: Run 1 / Run 5 / Run 10

RUN 1: A typical Sector 1 loss earns ~8 renown, ~3-4 Mastery XP, and ~2-3 Core Sync - leaving the player short of the cheapest 15-renown hull variant, short of Mastery Level 1 (6 XP), and with no Core Sync summary in endRun(), so a Sector 1 loss on Run 1 feels unrewarded (whereas reaching Sector 2 for ~44 renown and ~8-12 Mastery XP immediately unlocks 1-2 hull variants and Mastery Level 1 Alternate fleet).

RUN 5: By Run 5 (~130-180 cumulative renown across mixed Sector 1/2 runs), the player owns 6-8 of the 12 purchasable hull variants, has reached Mastery Level 2 (Wider counsel, 16 XP) or Level 3 (Second Command, 30 XP) on a preferred admiral, and has crossed Partial sync (4+) or Synced (12+, granting a starting giftBoon) on 1-3 cores; completing Run 5 feels strongly rewarded as all three progression clocks deliver tangible options and power.

RUN 10: By Run 10 (with 1-2 wins and ~350-450 cumulative renown), the player has bought all 12 purchasable hull variants (hitting the 250-renown ceiling), opened Heat, reached Mastery Level 3-4 on 1-2 admirals, and hit Synced or Full sync (25) on multiple cores; completing Run 10 feels only partially rewarded, as endRun() prominently celebrates +<ren> renown (and Heat's +10% renown bonus) for a currency with zero remaining sinks while omitting Core Sync gains from the recap screen.

5. NOT CHECKED

Whether META.unlocked (LEGACY) is still read by gameplay code: The pack does not include shipyard generation, run initialization (newRun), or battle credit calculation, so it cannot be verified whether u_carrier, u_battleship, u_dread, chest1-3, cmd1-2, vets, founder, wrights, and salvagers are actively applied to every run via the boot grant or ignored by run logic.

How the 6 story-arc hull variants (ARC_VARIANT) are granted: data.js defines 6 variants with cost:0 and an arc field ("earned by finishing that faction's story arc (its Nemesis's last fight)"), and ACT.buyVariant blocks buying them, but neither endRun() nor migrateMeta() in the pack writes them to META.variants.

Whether RUN.stats.battles includes elites and bosses: The pack does not show the battle-win increment site for RUN.stats, which determines whether endRun()'s mxGain=s.battles+s.elites*2+s.bosses*5+(victory?10:0) awards 1/3/6 XP for normal/elite/boss fights versus migrateMeta()'s 1/2/5 XP.

Protocol (BOONS) offer frequency and rarity weights per run: The pack does not show sector map generation or protocol draft code, so the exact number of protocol picks per run and the magnitude of Partial sync ("Its protocols are rare more often.") cannot be numerically verified.

Tactical balance of variants, aspects, alternate fleets, and alternate Commands: The pack does not include HULLS, W, ASPECTS, MODULES, altFleetPlan(), or altCommand(), so the combat balance of unlocked sidegrades cannot be judged.

6. QUESTIONS FOR THE DESIGNER

Is the removal of LEGACY and ADMIRALS from renown progression permanent? Since helpScreen() and legacyScreen() treat all factions, admirals, and ship classes as unlocked from the start, do you want to delete LEGACY and admiral costs entirely and add a new long-term renown sink beyond the 250-renown variant pool, or restore subsets of LEGACY/admirals as mid-to-late renown goals?

What should Heat reward once all 250 renown of hull variants are bought? Because a player at a ~17% win rate typically earns enough renown to buy nearly or all 12 purchasable variants before winning their first run and unlocking Heat, should Heat instead multiply Admiral Mastery XP / Core Sync or unlock Heat-gated cosmetics/variants, or should it remain a pure bragging-rights ladder (META.heatBest) without a currency payout?

Should a single victorious run fully master an admiral (Level 4), or should players stay with one admiral before rotating factions? Right now, winning a run with a fresh admiral grants ~43 Mastery XP (stopping 7 XP short of Level 4's 50 XP threshold) while endRun()'s primary button urges the player to switch to a new faction - do you prefer players to rotate across all 6 factions first, or should the victory bonus be raised so a win completes Level 4 in one run?
