# Findings-to-tests ledger (Voidsworn, wave 5 slate item 4)

Every BLOCKER and FIX-level finding from the audit programs, mapped to either a working harness regression test or an explicit no-test row with a reason. Code pin: 264f441d (the pin every Oct 28 and Oct 29 program verified against).

Run the tests: `node findings_tests.js` (optionally with a repo path). The campaign-layer tests load through `campaign_loader.js`, which sits beside this file and extends the shared game loader with campaign_meta.js and campaign_run.js. Round 2 added two sibling harnesses in the same folder: `battle_probe.js` (sim3d-style animation hooks, so aiUnit-driven battles run headlessly) and `ui_loader.js` (ui3d.js behind a registry DOM stub, so its state functions run headlessly). The file exits 1 while any pinned defect is unfixed. That is the point of it: a failing test here is a correct regression test, not a broken one. Tests were not weakened to pass. When a fix lands, the matching test should flip to PASS without edits; if a fix takes a different shape than the finding assumed, update the test and its ledger row together.

## Status key

- TESTED: a test in findings_tests.js asserts the desired state today. Its current result is in the run table below.
- TESTABLE-NOT-WRITTEN: an automated test is possible and the route is named, but writing it needs infrastructure not yet built, or a design decision that fixes the assertion shape. The campaign loader named here as future infrastructure was built on Oct 30, 2026 (campaign_loader.js) and converted 24 of the 41 rows in this class; the battle probe and the UI-state harness followed the same day (battle_probe.js, ui_loader.js) and converted 8 of the remaining 17. The 9 rows left in this class all wait on a design decision, not on infrastructure.
- NOT-TESTABLE: no automated assertion honestly captures the defect. The reason is stated per row (visual composition, text judgment, semantic name matching, comment text, design questions with no ruled target state, or a standing ruling that accepts the current state).

## Scope

Covered: the Oct 27 program (kit coherence, admirals, events, HUD, text), the Oct 28 progression program (progression, rewards, loop, variety), the Oct 28 battle-layer program (battlefield, fights, nemesis, roster), the Oct 29 audit program (weapons, squadrons, modules, AI, boons, economy, firstrun, faction shape, drift, battle UI), wave 1 open checks and the ruled fixes spec (folded into their parent findings), wave 3 deep QA, and the wave 5 patch pack and measurements.

Excluded, with reasons: the tree validation synthesis (its defects were in a chair draft document and were fixed in the final proposal filed alongside it; no shipped code was involved); the Oct 28 validation synthesis (fiction and learning-frame coherence, no code findings); the Oct 27 balance and economy evidence packs (measurements against tuning claims, not defect findings; the one hard claim there, a capture-value leak, was verified absent at the pin); measurements item M1 (Nemesis snowball, verdict: keeping pace, not a defect); the Oct 26 migration review (outside the commissioned program set); and items the chairs explicitly discounted or graded below FIX (hull-down telegraphing, kill credit, the discounted legacy migration weight is kept as NEM-7 because two legs filed it as a defect). Duplicate findings across programs are counted once, at the row named in the cross-reference index.

## Coverage

| Program | Rows | TESTED | TESTABLE-NOT-WRITTEN | NOT-TESTABLE |
|---|---|---|---|---|
| Oct 27 program | 29 | 14 | 1 | 14 |
| Oct 28 progression program | 17 | 12 | 0 | 5 |
| Oct 28 battle-layer program | 29 | 23 | 4 | 2 |
| Oct 29 audit program | 48 | 25 | 4 | 19 |
| Wave 3 deep QA | 1 | 1 | 0 | 0 |
| Wave 5 patch pack (new rows only) | 1 | 1 | 0 | 0 |
| **Overall** | **125** | **76** | **9** | **40** |

76 of 125 findings (61%) have a working regression test today. Of the rest, 9 are testable but wait on design decisions that fix their assertion shape, and 40 are not honestly automatable.

## Test run at the pin (80 tests: 8 pass, 72 fail)

The 76 TESTED rows are covered by 80 tests, because VAR-1 is one row backed by five sweep assertions. The first 48 tests were written in the original pass; 24 more were added on Oct 30, 2026 by the campaign-loader extension (campaign_loader.js, same folder: it runs campaign_meta.js and campaign_run.js in the harness context behind a DOM stub whose #app element records what the screens render). Eight more were added later the same day behind the round 2 harnesses (battle_probe.js: sim3d-style animation hooks so aiUnit runs headlessly; ui_loader.js: ui3d.js behind a registry DOM stub so its state functions run headlessly), converting BF-1, AI-1, AI-3, AI-4, AI-5, UI-5, UI-6 and UI-8. Round 1 probed BF-1 and BF-5 and did not convert them; round 2 took the mechanism hunt further and BF-1 now reproduces and is converted, while BF-5's hunt closed with negative evidence (see its row and the honesty notes). Every one of the 32 tests added on Oct 30 fails at the pin, each for the defect its row names. The eight passes are the healthy signs in the set: five generator guarantees, one non-reproduction (FGT-4), one guard the weapons synthesis proposed (WPN-3), and one feared defect that does not reproduce (RWD-9). Every other test fails because its defect is still in the code, and each failure message names the defect as found.

| Test | Result | Note |
|---|---|---|
| KIT-1 | FAIL | FAC_GATES has no chorus entry |
| KIT-2 | FAIL | ionpulse dead against chorus and deathless |
| KIT-3 | FAIL | banned glow, trim and style all present |
| KIT-4 | FAIL | turbo and hturbo renamed as lances, kind battery |
| ADM-1 | FAIL | thale = maren; mott = matriarch = aelith; mending = nekhet |
| ADM-2 | FAIL | torpedo clause promised by Malek and Sable, not Vorn and Anuket |
| ADM-5 | FAIL | khepra only |
| ADM-6 | FAIL | ashgrove, reyes, mott, matriarch, aelith |
| EVT-2 | FAIL | seer song option can never fire |
| EVT-3 | FAIL | beacon 'Seize the cargo' hides ambush and clock |
| EVT-5 | FAIL | haven only |
| RWD-2 | FAIL | exactly the eight protocols the synthesis named |
| RWD-3 | FAIL | L_storm ungated |
| RWD-4 | FAIL | duo survived 0 of 300 offers |
| RWD-8 | FAIL | 378 of 600 backfill picks rolled Common at favour tier 3 |
| RWD-9 | PASS | feared module-pool fall-back does not reproduce (see row) |
| BF-3 | FAIL | rock = hulk, station = planet |
| BF-6 | FAIL | hold excludes strip entirely |
| BF-9 | FAIL | debris 10 vs nebula 15 |
| BF-10 | FAIL | Engagement lists archipelago twice |
| FGT-1 | FAIL | flagship rolled in 91 of 400 boss encounters |
| FGT-4 | PASS | effArch resolves the preview correctly; defect does not reproduce |
| ROS-1 | FAIL | ascendant speed 1 |
| ROS-2 | FAIL | d_harvester_t, i_song_w, plus b_razor_s (see row) |
| ROS-3 | FAIL | h_vanguard_g, c_hulk_g |
| ROS-4 | FAIL | no reanimate; 3 of 4 mounts repeated at 3x CP |
| ROS-5 | FAIL | h_picket_i, c_reaver_t, d_scythe_s, exactly the synthesis set |
| ROS-6 | FAIL | warden and h_picket agree on every compared axis |
| ROS-9 | FAIL | focus, ionpulse, frenzy each on one hull |
| WPN-1 | FAIL | flak = gsentry, the only identical pair |
| WPN-2 | FAIL | one damage line, split by pierce only |
| WPN-3 | PASS | guard holds: no hull mounts both battery and hbattery |
| WPN-5 | FAIL | Rear arc defined; startorp evMult present |
| SQ-1 | FAIL | sporeb and bombs share every delivery field |
| MOD-2 | FAIL | cogitator collision plus four duplicate pairs |
| MOD-4 | FAIL | damcon 85 vs prow 70 |
| BN-1 | FAIL | three ram boons, one key pool |
| BN-2 | FAIL | legendary 40 flat vs epic 40 plus burning |
| BN-5 | FAIL | hunger in one duo |
| ECO-2 | FAIL | b_brood 370, the highest carrier price |
| FS-2 | FAIL | battleship fallback 370 vs cruiser 390 |
| W3-1 | FAIL | elite guarantee broke on 25 of 900 maps in the compact sweep |
| VAR-1a | PASS | exactly one boss in the final column, 900 of 900 |
| VAR-1b | PASS | shipyard in column 3, 900 of 900 |
| VAR-1c | PASS | pre-boss column all rest stops, 900 of 900 |
| VAR-1d | PASS | a fight in every fight column, 900 of 900 |
| VAR-1e | PASS | encounter variety guarantees, 900 of 900 |
| PP-2 | FAIL | pure-hive fleet armed no point-defense adaptation |
| EVT-1 | FAIL | ransom outcome satisfies the saboteur need and the Hegemony free verb |
| TXT-2 | FAIL | wright pay option repairs the third ship, not the second |
| TXT-8 | FAIL | shipyard renders Decommission (+NaN) for a cost-less hull |
| PROG-2 | FAIL | no rendered call site for buyAdmiral or buyLegacy |
| PROG-5 | FAIL | one elite battle pays 3 mastery against a stated 2 |
| PROG-6 | FAIL | newRun launches an unowned admiral |
| RWD-5 | FAIL | credit node premium over the decline value is 5 at sector 2 (bar 15) |
| RWD-6 | FAIL | reroll charges 25 and returns the same three at pool depth 3 |
| RWD-7 | FAIL | prow, drive, gyro and regen are unreachable as salvage |
| BF-2 | FAIL | boss board keeps 46% of the rock over 12 seed pairs |
| BF-7 | FAIL | lanes barrier: 12.1 rock on the middle row vs 2.7 in the best column |
| BF-8 | FAIL | reinforcement spawns average 118 degrees off the approach direction |
| NEM-2 | FAIL | revealed ion earns shields; revealed torp earns pd |
| NEM-3 | FAIL | two adaptations granted inside one sector 3 visit |
| NEM-4 | FAIL | duel, swarm, reinforce and challenge strikes return empty |
| NEM-5 | FAIL | warning promised nothing to take; the strike towed the crippled ship |
| NEM-6 | FAIL | noFlee flagship kill at sector 1 does not register as a death |
| NEM-7 | FAIL | migration zeroes the loot state and drops the held ship |
| FR-2 | FAIL | a lost meeting reveals 0 weaknesses |
| MOD-3 | FAIL | lance crystal fitted to a ship with no lance |
| ECO-3 | FAIL | decommission pays 25 at full hull and 25 at 30% hull |
| ECO-4 | FAIL | ransom 39 against the priceMult-scaled 48 under the coffers heat |
| DRIFT-5 | FAIL | movement tip renders in the single-tap wording on touch |
| UI-7 | FAIL | keysHelp omits r, t, f, x and g |
| BF-1 | FAIL | ring center keeps 31% of its rock under ambush (line control 100%); lanes barrier keeps 34% |
| AI-1 | FAIL | veteran ship moved, fired nothing, ended unbraced under 32 expected threat |
| AI-3 | FAIL | death-cliff switch point identical (kill worth 40) for a cp1 and a cp5 hull |
| AI-4 | FAIL | a ship with only a reloading torpedo closed 10 to 6 against unarmed targets |
| AI-5 | FAIL | wing launched into 9 expected threat while threat-free launch hexes existed |
| UI-5 | FAIL | wingSel survives selectUnit, rosterPick and the full Escape chain |
| UI-6 | FAIL | 'Nothing left to do' with movement remaining, and again with Brace unspent |
| UI-8 | FAIL | gun-count tie keeps the facing exposing the 4-point shield; ACT.arm leaves reach stale |

## The ledger

### Oct 27 program: kit coherence (kit_coherence_synthesis_2026_10_27.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| KIT-1 | Approved Chorus shipyard repair prohibition is coded nowhere: FAC_GATES has no chorus entry and the repair actions check nothing | FIX | TESTED (KIT-1, fails) |
| KIT-2 | ionpulse, the Cordon destroyer's signature ability, only strips shields, and Chorus and Eclipse have no shielded hulls | FIX | TESTED (KIT-2, fails) |
| KIT-3 | Eclipse still renders in the bible-banned green glow and tomb styling (glow #3dff6a, trim #1fbf4a, style tomb) | FIX | TESTED (KIT-3, fails) |
| KIT-4 | Hegemony renames its battery-kind turbolasers 'Plasma lance' and 'Heavy plasma lance', so lance-kind buffs (crystal lens, Lance Adept) silently miss them | FIX | TESTED (KIT-4, fails) |

### Oct 27 program: admirals (admirals_synthesis_2026_10_27.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| ADM-1 | Three duplicate-passive collisions: Thale = Maren, Matriarch = Mott = Aelith, Nekhet = the Mending Choir | FIX | TESTED (ADM-1, fails) |
| ADM-2 | The 'hunt' Command id carries two different effects: Malek and Sable promise a torpedo reload, Vorn and Anuket do not | FIX | TESTED (ADM-2, fails) |
| ADM-3 | Vorn's doctrine is named Interdiction but nothing in his kit interdicts | FIX | NOT-TESTABLE: name-to-kit semantic match; no mechanical assertion exists |
| ADM-4 | Grax's doctrine is named Ram and board but his own kit has no ram or board effect (the fleet's hulls supply both) | FIX | NOT-TESTABLE: same semantic class as ADM-3 |
| ADM-5 | Khepra's Command text promises a full shield refill to the only shieldless fleet in the game | FIX | TESTED (ADM-5, fails) |
| ADM-6 | All five carrier admirals carry a hidden fx.sqHp of .25 that no card text mentions | FIX | TESTED (ADM-6, fails) |
| ADM-7 | Chorus Nemesis lines are written first-person singular against the bible's 'we' rule | FIX | NOT-TESTABLE: voice and text judgment; the fix is a line edit, not a state assertion |

### Oct 27 program: events (events_synthesis_2026_10_27.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| EVT-1 | eventFlags stores the chosen option key, but needMet and verbFree test flag presence only, so five choice-specific free options can fire on the wrong outcome | FIX | TESTED (EVT-1, fails): the campaign loader asserts per-outcome gating; the ransom outcome satisfies both the saboteur need and the Hegemony free verb, the question outcome is the passing control |
| EVT-2 | The seer event excludes ithar while its spliced song option requires ithar, so the option can never fire | FIX | TESTED (EVT-2, fails) |
| EVT-3 | Beacon 'Seize the cargo' conceals an ambush and a Nemesis clock advance its text never discloses | FIX | TESTED (EVT-3, fails) |
| EVT-4 | Repair gating is inconsistent across events: wright, dock and quiet repair with no Chorus gate while shrine gates chorus and deathless | FIX | TESTABLE-NOT-WRITTEN: enforcement sits in campaign event resolution; pair with the KIT-1 fix. Event data differs by design intent, so no pure data assertion is honest. Re-confirmed Oct 30 round 2: the repair options still sit in event data with no Chorus gate at option level (wright repairOne behind a module need, dock repairOne and quiet healAll ungated, shrine healAll ungated) while the faction-flavoured heals live in their own events (reactor gated to deathless, spawn gated to chorus) |
| EVT-5 | Haven is the only fight-start event with no free exit (raid, a 40-credit tribute, or a corsair-only recruit). Ruled Oct 28: every fight-start event guarantees a free exit | FIX | TESTED (EVT-5, fails) |

### Oct 27 program: HUD (hud_synthesis_2026_10_27.md)

All seven were verified from captures of the Godot build; each defect is screen composition, and no rules-code or data assertion captures it. The regression surface for this family is Ryan's eye on captures, or the future Godot screenshot suite.

| ID | Finding | Severity | Status |
|---|---|---|---|
| HUD-1 | In the start and threat camera views the enemy is not in frame (start view is friendly hulls only; threat view frames one friendly stern) | FIX | NOT-TESTABLE: visual framing |
| HUD-2 | Nameplates of adjacent ships merge into one unreadable string | FIX | NOT-TESTABLE: visual layout |
| HUD-3 | The symbol legend ships collapsed and unlabeled, so a first-time player cannot decode map symbols | FIX | NOT-TESTABLE: visual presentation |
| HUD-4 | The tutorial card says Command makes the button glow; on screen every button glows | FIX | NOT-TESTABLE: text against rendered state |
| HUD-5 | The move preview omits threat range, turns to face, and the path taken | FIX | NOT-TESTABLE: preview rendering |
| HUD-6 | The right column clips: the wing panel is cut off and wing orders sit below the fold | FIX | NOT-TESTABLE: visual layout |
| HUD-7 | Toggle buttons (auto-resolve, speed, camera) and wing stances show no active state | FIX | NOT-TESTABLE: visual state indication |

### Oct 27 program: text (text_synthesis_2026_10_27.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| TXT-1 | The help screen contradicts the game on four points (content available from run 1, the shipyard locked behind flagship kills, three aspects, three rarity tiers) | FIX | NOT-TESTABLE: the strings live in campaign_meta.js; correctness is a cross-file editorial check, not a runtime state |
| TXT-2 | Shipwright repair heals the wrong ship when a same-name or same-hull stablemate sits at a lower fleet index (the handler takes the first match, not the clicked ship) | FIX | TESTED (TXT-2, fails): the campaign loader drives the wright event's spliced pay option (upgradeOne + repairOne) through applyOutcome over a three-ship fixture; repairOne re-sorts after the upgrade heal, so the repair lands on the third ship, not the second most damaged |
| TXT-3 | Purchase surfaces render base weapon names while ship cards render faction names, so a bought weapon looks like a different weapon | FIX | NOT-TESTABLE: two DOM rendering paths in the campaign UI files |
| TXT-5 | The Crusade RANKS table is hardcoded for every faction across promotion notices, blue-option requirements, and the shipyard lede | FIX | NOT-TESTABLE: screen text in campaign files |
| TXT-7 | The Nemesis card claims 'He never retreats' although nothing sets noFlee and escape is a coded outcome; a second line hardcodes 'His fleet is coming' around the nemSay path | FIX | NOT-TESTABLE: text-versus-behaviour semantics in campaign files |
| TXT-8 | The decommission button label computes NaN for hulls with no cost field (campaign_run.js:174) | FIX | TESTED (TXT-8, fails): shipyardScreen rendered into the loader's DOM stub with a cost-less hull (h_boss) in the fleet; the label path still computes NaN where shipValue guards the value itself |

Numbering note: the text program's variant-card batch is counted once as ROS-2, and its locked-card finding is counted once as PROG-2.

### Oct 28 progression program: progression (progression_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| PROG-1 | The boot grant in main3d.js hands over all 12 legacy unlocks and all 24 admirals (1,565 renown of sinks) unless an option defaults the other way; progression is bypassed as shipped | BLOCKER | NOT-TESTABLE: main3d.js is browser shell code outside the rules harness. The same grant in the Godot parity oracle is DRIFT-1 |
| PROG-2 | The purchase path is doubly dead: ACT.buyLegacy and ACT.buyAdmiral are implemented with zero UI call sites, and locked admiral cards point to a 'Legacy' screen that no longer exists under that name | FIX | TESTED (PROG-2, fails): static call-site scan over the campaign, shell and HTML sources, in the wave 2 validator style; no rendered data-act call site exists for either handler. Merges the text program's locked-card finding |
| PROG-3 | The unlock-everything settings toggle is dead code: the handler exists but no settings button renders it | FIX | NOT-TESTABLE: DOM rendering in the shell files |
| PROG-4 | The end-of-run summary omits core sync entirely (renown and mastery only), so the learning frame's central quantity is invisible where it should pay off | FIX | NOT-TESTABLE: summary screen rendering. See also LOOP-1 |
| PROG-5 | Mastery XP double-counts elites and bosses: the battles counter includes them and endRun pays battles + elites x2 + bosses x5 on top, so an elite pays 3 and a boss 6 against a stated 2 and 5 | FIX | TESTED (PROG-5, fails): endRun loaded with DOM stubs; a fixture of one elite battle pays 3 mastery against the stated 2 |
| PROG-6 | Admiral ownership is unenforced at launch: with the grant off, selection auto-assigns the faction's first admiral and neither Launch nor newRun checks ownership, so the lock is decorative in both directions | FIX | TESTED (PROG-6, fails): the campaign loader calls newRun with META.admirals owning only the starter; the unowned admiral launches |

### Oct 28 progression program: rewards (rewards_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| RWD-1 | The prize screen pre-computes the optimal default for every captured ship (add, strip, or ransom by the code's own valuation), so the capture decision is solved before the player sees it | FIX | NOT-TESTABLE: whether a default may be optimal is the design question itself; no pass/fail assertion survives either answer |
| RWD-2 | Eight of 36 core protocols ignore or cap the rarity multiplier (i_wall, s_chain, h_brood, a_mark, r_slip, e_spread ignore it; h_hatch and e_reload cap at Rare). Ruled Oct 28: numeric rarity scaling | FIX | TESTED (RWD-2, fails on exactly those eight) |
| RWD-3 | L_storm is missing from BOON_NEED while its shield siblings are gated, so a shieldless fleet can be offered a shield legendary | FIX | TESTED (RWD-3, fails). Also the boons program's gate finding; counted once here |
| RWD-4 | Once two patron boons are held, the patron legendary deterministically takes offer slot 3, overwriting any duo rolled there, on every reroll. Ruled Oct 28: weighted roll between duo and legendary | FIX | TESTED (RWD-4, fails: duo survived 0 of 300 offers) |
| RWD-5 | Declining a boon offer pays 30 + 10 per sector against a credit node's 35 + 10 per sector, so the boon node dominates by solved arithmetic. Ruled Oct 28: rebalance credit nodes | FIX | TESTED (RWD-5, fails): paired rewardFlow runs differing only in node reward kind put the credit node's premium over the decline value at exactly 5 credits (sector 2). The test bars the premium at 15 or more: a chair-set threshold from the synthesis's gap shape, not a ruled number; re-bar it if a margin is ruled |
| RWD-6 | The reroll never checks pool depth: with three or fewer eligible protocols it charges an escalating price and returns the same three | FIX | TESTED (RWD-6, fails): with the patron pool held to exactly three eligible protocols, boonReroll charges 25 and returns the same three |
| RWD-7 | Salvage is deterministic: the wreck module is always the first match on a fixed nine-module list (four modules can never drop), and ransom decays 0.85 per prior ransom in fixed battle order | FIX | TESTED (RWD-7, fails, salvage half): every-module-reachable assertion over salvageYield; prow, drive, gyro and regen can never drop. The ransom order-dependence half stays unwritten (arithmetic on prizeRansom; no loader needed) |
| RWD-8 | The spillover rarity tax: off-patron backfill picks roll rarity without the patron argument, so they get no favour bonus and no tier-3 Rare floor. Ruled Oct 28 (Q7); specified in the ruled fixes spec, Fix 1; measured in wave 5 (M2) | FIX | TESTED (RWD-8, fails) |
| RWD-9 | modulePool's fall-back to offering all modules when fewer than three are useful | FIX | TESTED (RWD-9, passes, with a note): the fall-back does not reproduce at this pin, because six of thirteen modules carry no kit need, so the useful pool can never drop below three. The test confirms a narrow fleet is offered only usable modules. The dead branch stays in code; the feared offers do not occur |

### Oct 28 progression program: loop (loop_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| LOOP-1 | After a loss, nothing on the run-end path shows what the loss bought or what the next generation inherits; the loop's payoff is invisible at the moment of failure | FIX | NOT-TESTABLE: screen flow in the shell files; overlaps PROG-4, which covers the summary half |

### Oct 28 progression program: variety (variety_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| VAR-1 | The genSector guarantee set mostly holds (boss, shipyard, rest column, a fight per column, encounter variety) | FIX | TESTED (VAR-1a to VAR-1e, all pass over 900 maps). The one failing guarantee in the set is the elite guarantee, counted as W3-1. The program's FIT_SLOTS item is counted once as MOD-5 |

### Oct 28 battle-layer program: battlefield (battlefield_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| BF-1 | clearSpawns deletes terrain within radius 2 of player ships and radius 1 of enemies plus a 6-hex corridor, erasing the shape-defining center terrain on ring, archipelago, belt and lanes maps | BLOCKER | TESTED (BF-1, fails): same-seed terrain diff per shape through startBattle (round 2, battle probe). The Oct 30 round 1 probe tested only line deployment on the strip, where the ring center genuinely survives (the test's line control keeps 100% of it); round 2 drove the deployments that start near the middle and the defect reproduces: under ambush deployment the ring center keeps only 31% of its defining rock, and the lanes barrier keeps only 34% under plain line deployment, its lost hexes sitting exactly at the two deployment ends while the middle survives. clearSpawns is the only post-generation terrain deleter in a non-boss battle, so the A/B isolates it. The test's 90% survival bar is chair-set (like RWD-5's); the Q11 shape-aware clearing design decides the final bar |
| BF-2 | Boss fights additionally delete 45% of rock at setup, so the biggest fights happen on the emptiest boards | FIX | TESTED (BF-2, fails): same probe family as BF-1; 12 seed pairs on dense/storm, and the boss board keeps 46% of the rock a normal board has |
| BF-3 | Terrain colors collide in exact pairs: rock and hulk share #bda088; station and planet share #9a948a | FIX | TESTED (BF-3, fails) |
| BF-4 | The gravity well never appears in the terrain legend: terrainPresent reads only B.terrain, and the well is not a terrain entry | FIX | NOT-TESTABLE: legend presentation; the well's absence from the table is by construction |
| BF-5 | Deployment fallbacks erase flank and ambush: a single-centroid scorer collapses ambush into a blob, and the general half-board fallback erases flank on narrow shapes | FIX | TESTABLE-NOT-WRITTEN: the mechanism hunt is closed on negative evidence (Oct 30 round 2). The flank fallback never fired: 0 ships deployed outside the flank zone across corridor, compact, lanes, ring, dense and open shapes on storm, belt and graveyard maps, with fleets of 6 and 11 on both sides (132 player and 264 enemy ship placements sampled per sweep cell). The narrowest flank zone still offers roughly twice the free hexes the caps+1 trigger needs, so the branch exists in deploy() but is not reachable in any tried configuration. Ambush likewise held both deployment bands in 96 of 96 trials (fleet sizes 6 and 10, open, dense and ring shapes) with no ship outside the bands, extending the round 1 probe's 12 of 12; round-arena fleets land in tight approach clusters, and the pincer spreads are the approach design, not scatter. The row stays open on the strength of the code path, not on any observed behaviour; no guard test was written, per the round 2 rule for a closed hunt |
| BF-6 | ENC_ARENA weights gate strip shapes out entirely for hold encounters (round .6, square .4, no strip entry) | FIX | TESTED (BF-6, fails) |
| BF-7 | On lanes, the barrier line runs parallel to the advance axis instead of across it, so the shape's defining feature does not block the advance | FIX | TESTED (BF-7, fails): shape geometry probe over generated lanes terrain; the barrier averages 12.1 rock on the middle row against 2.7 in the best single column. Chair-verified by this test, superseding the leg's unverified status |
| BF-8 | Reinforcement edges are hardcoded left and right, which is wrong on rotated arenas | FIX | TESTED (BF-8, fails): battle probe on round arenas (headon approach, direct eventTick); reinforcement spawns average 118 degrees off the approach direction, 8 of 12 in the wrong half. Chair-verified by this test, superseding the leg's unverified status |
| BF-9 | Debris is strictly dominated by nebula: same rule shape, 10 points of to-hit penalty against nebula's 15 | FIX | TESTED (BF-9, fails; the assertion reads the penalties from TERRAIN_INFO, the player-facing statement of the rule) |
| BF-10 | The Engagement shape list names archipelago twice, silently double-weighting it | FIX | TESTED (BF-10, fails) |

### Oct 28 battle-layer program: fights (fights_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FGT-1 | The boss objective roll is rout, rout, ambush, flagship, so Decapitation makes the hand-built boss escort irrelevant in about a quarter of boss fights. Ruled Oct 29: boss fights get their own objective table | BLOCKER | TESTED (FGT-1, fails: 91 of 400) |
| FGT-2 | The rout mirror problem: on a rout roll the boss can flee alive, while the CP-weighted rout threshold forces a near-wipe anyway | FIX | TESTABLE-NOT-WRITTEN: battle-outcome probe; the fix rides on FGT-1's new boss table. Re-confirmed Oct 30 round 2: the rout branch at battle.js:1026 still ends the fight as a win at 35% of starting CP with the boss alive (bossDown is only the other disjunct), ENCOUNTERS still has no boss-specific objective table, and FGT-1's test still fails, so the table this fix rides on has not landed |
| FGT-3 | Objective previews hide the operative thresholds (Breakthrough's escape count, Hold's station integrity) | FIX | NOT-TESTABLE: preview text surfaces in the campaign UI |
| FGT-4 | Reported defect: Deathless nodes preview a carrier the roster does not have | FIX | TESTED (FGT-4, passes): the defect does not reproduce. Both preview surfaces already resolve through effArch, which maps a Deathless carrier roll to heavy; verified again by the wave 5 patch pack, section 6. The test pins the correct behaviour |

### Oct 28 battle-layer program: nemesis (nemesis_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| NEM-2 | nemAdapt filters only by not-yet-taken and never checks the revealed weakness set, so the Nemesis can adapt into a direct counter to a revealed weakness. Ruled Oct 29 (Q4): a clash check is required | FIX | TESTED (NEM-2, fails): two clash fixtures through the campaign loader; with ion revealed, heavy lance and ion fire earns shields, and with torp revealed, heavy torpedo fire earns pd |
| NEM-3 | The adaptation cap is cumulative (max(0, sector-1), plus Chorus adaptFast terms) rather than one per sector as designed, and the fallback always fires when the cap allows | FIX | TESTED (NEM-3, fails): the same loader extension grants two adaptations inside a single sector 3 visit |
| NEM-4 | Only two of six nemStrike faction strikes (raid, tithe) return map effects; duel, swarm, reinforce and challenge return empty | FIX | TESTED (NEM-4, fails): duel, swarm, reinforce and challenge return an empty string and change nothing; raid and tithe are the passing controls |
| NEM-5 | The raid warning can lie two ways: nemWarnLine evaluates the crippled condition before the clock fight resolves while nemStrike re-evaluates after, and loud event choices fill the clock and fire the strike immediately, not after the next win | FIX | TESTED (NEM-5, fails): with the warning computed over a healthy fleet and 10 credits, a ship crippled in the clock fight is then towed by the strike the warning said would find nothing |
| NEM-6 | Nemesis death registers only at sector 3 or later, leaving open how noFlee factions survive flagship destruction in sectors 1 and 2 | FIX | TESTED (NEM-6, fails): a noFlee (voidsworn) flagship kill at sector 1 leaves dead=false and the debrief prints the escape line |
| NEM-7 | ensureNemesis's legacy migration copies only 10 fields and filters adaptations to the generic set, dropping faction loot state | FIX | TESTED (NEM-7, fails): a pre-persona nem fixture through ensureNemesis loses loot (500 to 0), riches, fed, honed, the held ship, and its faction special adaptation. One-time legacy edge; the synthesis discounts its weight |

Numbering note: the nemesis program's top finding, the intel drought, is counted once as FR-2, its ruled form.

### Oct 28 battle-layer program: roster (roster_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| ROS-1 | The ascendant moves 1 hex and can never trigger Broadside doctrine, which needs a 2+ hex move, though it mounts two broadsides as its whole armament. Ruled Oct 29: speed 2 | BLOCKER | TESTED (ROS-1, fails) |
| ROS-2 | Renown variants silently delete primary weapons: d_harvester_t drops a gauss turret and i_song_w drops a pulsar, with no disclosure in either description | FIX | TESTED (ROS-2, fails). The test also surfaces a third instance the synthesis did not list, b_razor_s dropping its bioplasma, flagged here as not chair-verified. Merges the text program's variant-card batch |
| ROS-3 | The gunship variants h_vanguard_g and c_hulk_g delete the hull ability itself (mod ab:null) and disclose only the hangar loss | FIX | TESTED (ROS-3, fails) |
| ROS-4 | d_boss repeats the d_harvester gun package at 3x the CP and is the only Deathless hull without reanimate | FIX | TESTED (ROS-4, fails on both halves) |
| ROS-5 | Three strict-upgrade variants carry no trade: d_scythe_s, h_picket_i, c_reaver_t. Ruled Oct 29: every variant carries a real trade | FIX | TESTED (ROS-5, fails on exactly those three) |
| ROS-6 | warden and h_picket are the same ship: identical CP, shields, range, armour, speed, turns, ability and weapon kinds; only HP, evasion and the battery weapon's name differ | FIX | TESTED (ROS-6, fails) |
| ROS-7 | Launch is concentrated on eight hulls and Hegemony's two line ships carry a token hangar 1 with no dedicated carrier | FIX | TESTABLE-NOT-WRITTEN: the data check is trivial, but the assertion waits on the unanswered design question (dedicated Hegemony carrier or deliberate distributed shape). Re-confirmed Oct 30 round 2: 9 hulls carry launch or a hangar at this pin (the audit's eight plus the i_carrier_a variant); Hegemony's h_vanguard and h_dominion still carry the token hangar 1 and no Hegemony hull is a dedicated carrier |
| ROS-8 | Three of six boss hulls recycle roster kits with no boss-exclusive weapon or ability | FIX | TESTABLE-NOT-WRITTEN: a similarity assertion needs the overlap threshold the audit did not set. Re-confirmed Oct 30 round 2 with the overlap measured: no boss hull's exact weapon kit plus ability matches any roster hull; the closest weapon-multiset overlaps run 50 to 80% (h_boss vs h_dominion 80%; ascendant, c_boss and i_boss 60%), and only i_boss shares its ability with its closest roster hull (i_song). Where 'recycled' begins is still the unset threshold |
| ROS-9 | Four orphan abilities sit on exactly one hull each (focus, ionpulse, frenzy, reclaim). Ruled Oct 29: spread the first three; reclaim stays the harvester's signature | FIX | TESTED (ROS-9, fails; the test covers only the three the ruling spreads) |

### Oct 29 program: weapons (weapons_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| WPN-1 | flak and gsentry are the same weapon field for field, including kind | FIX | TESTED (WPN-1, fails; they are the only identical pair) |
| WPN-2 | turbo and gauss share one expected-damage line (13.32); gauss weakly dominates on pierce alone | FIX | TESTED (WPN-2, fails) |
| WPN-3 | hbattery strictly dominates battery on the table, but mounts separate them in practice (open check 4) | FIX | TESTED (WPN-3, passes as a guard): the test is the checkpack rule the synthesis proposed, no hull mounts both |
| WPN-4 | The torpedo design comment in battle.js promises range 6 and 10/25 ring penalties; the live constants are range 5 and TORP_RING [0,5,15] | FIX | NOT-TESTABLE: the defect lives in a comment; no runtime assertion reads intent. Also the drift program's oracle-drift item; counted once here |
| WPN-5 | Dead data in the weapon table: startorp carries evMult:2, overwritten by the Ithar trait in live play, and ARC_NAME defines a Rear arc no weapon uses | FIX | TESTED (WPN-5, fails on both halves) |

### Oct 29 program: squadrons (squadrons_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| SQ-1 | The Chorus spore wing is a bomber reskin: same delivery fields across the board, near-identical hull numbers | FIX | TESTED (SQ-1, fails) |
| SQ-2 | The carrier archetype branch seeds one carrier then fills generically, and is skipped entirely for boss fights, so carrier identity washes out of the fleets built around it | FIX | TESTABLE-NOT-WRITTEN: genEnemyFleet composition probe; needs a role-composition definition the audit did not formalize. Re-examined Oct 30: the assertable slice (exactly one launch hull in generated carrier fleets) is arguably correct design, so a test written now would pin a chair guess, not the finding. Re-confirmed Oct 30 round 2 in the genEnemyFleet source: the carrier branch still seeds exactly one carrier (the highest-CP launch hull), strips carriers from the fill roster, and is skipped entirely for kind boss |
| SQ-3 | The torpedo screen's one-kill-per-wing-per-salvo cap is never stated in the stance text | FIX | NOT-TESTABLE: the finding as graded is the missing text |
| SQ-4 | Wing veterancy perks are random grants on the 3/8/15 XP ladder and cannot be steered; enemy wings cannot reach the ladder at all | FIX | NOT-TESTABLE: steerability is a UI flow property, not a data state |

### Oct 29 program: modules (modules_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| MOD-1 | Fitting is free, instant and fully reversible, which collapses modules into a pre-battle checklist | BLOCKER | NOT-TESTABLE: the defect is absent friction in campaign UI flow, and no target state has been ruled; a test written now would assert a design nobody chose |
| MOD-2 | Five modules duplicate five captain perks effect for effect through one additive pool, and MODULES.cogitator collides with RELICS.cogitator on the same key | FIX | TESTED (MOD-2, fails: the collision plus four pairs). The fifth pair, regen vs deflector, shares the regenPct key at .5 vs .4, a near-duplicate the subset rule does not flag |
| MOD-3 | Weapon-kind modules can be fitted for zero effect with no warning: only hangar carries an `only` guard, and the campaign fit guard keys on ability, not weapon kind | FIX | TESTED (MOD-3, fails): the campaign loader drives ACT.equip; the Lance focusing crystal fits a lance-less warden. Patch pack section 3 carries the diff and acceptance check; enforcement sits at campaign_run.js:128 |
| MOD-4 | damcon (85 credits) is mathematically dominated by prow (70 credits) | FIX | TESTED (MOD-4, fails) |
| MOD-5 | The FIT_SLOTS schema has no mechanical consumer anywhere (dead data audit: DEAD EVERYWHERE), and its flagship reserve collides with the universal slot ladder | FIX | NOT-TESTABLE: absence of a consumer across the whole codebase, including the Godot port, cannot be proven from the three files the rules harness loads; the collision itself is a design decision. Also filed by the variety program; counted once here |

### Oct 29 program: AI (ai_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| AI-1 | The veteran brace bypass: on veteran difficulty the AI can be left permanently unbraced by the mid-move volley path returning before the brace decision (battle.js:1385-1387) | BLOCKER | TESTED (AI-1, fails): battle probe through aiUnit. A veteran ship at 63% hull with a spent gun moves 8 to 4 hexes toward the enemy line, fires nothing, and ends unbraced under 32 expected threat: the volley path returns before the veteran brace decision its own numbers satisfy (threat over 45% of hp, own offense nil), and the volley path's fallback brace demands hp under 50%. Patch pack section 1 carries the acceptance check; the port spec's correction stands, that the brace sites sit after movement (battle.js:1389-1399), which is the anatomy this test drives |
| AI-2 | genEnemyFleet's fill loop can strand budget at the CP ceiling | FIX | TESTABLE-NOT-WRITTEN: the stranding magnitude was measured by the CP sims; a pass/fail threshold waits on the CP mechanism chosen under the Oct 29 ruling. Re-examined Oct 30: in the fill sweep the stranded budget appears at the ship ceiling, which is the ceiling working as designed; a leftover-budget probe would test the wrong thing. Re-confirmed Oct 30 round 2 with fresh numbers: 2,160 generated fleets (6 factions, 3 sectors, 6 columns, archetypes rotating) stranded 1 CP or more in 135 cases, every one at the ship ceiling and none below it |
| AI-3 | The AI's death-cliff weight is a flat -25 unscaled to ship value, distorting target choice for cheap and expensive hulls alike | FIX | TESTED (AI-3, fails): battle-probe sweep. Two movers with identical normalised numbers (same gun, speed, hp, shields, armor, evasion) differing only in hull value (cp1 warden, cp5 cathedral) face the same death-cliff hex as the kill behind it grows: both first accept the hex at exactly the same kill value (40), so the flat weight is measured, not inferred. The test pins value scaling in the CP sense, with hull numbers held equal; a fix that scaled by maxHp alone would need the fixture split the other way (see the honesty notes) |
| AI-4 | The approach leash pulls a ship with no bearing guns toward the player at -4 per hex beyond minimum range instead of letting it kite | FIX | TESTED (AI-4, fails): battle probe. A ship whose only gun is a reloading torpedo closes 10 to 6 hexes against unarmed targets instead of holding or kiting: the leash runs off the spent gun's minimum range (computed over all weapons, spent or not) even when nothing can bear |
| AI-5 | The AI launches wings before moving, from launch hexes sorted only by distance, so launches can be baited into a kill zone | FIX | TESTED (AI-5, fails): battle probe. The carrier launches during its pre-move ability step into 9 expected threat on the launch hex nearest the enemy, while launch hexes with no incoming fire exist on the same carrier; the launch also happens from the pre-move position, so the wing is left behind when the carrier then moves |

### Oct 29 program: boons (boons_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| BN-1 | One ram job is sold three times: r_prow, d_jugg and L_rook all draw exclusively on ramPct, ramCap and ramGuard | FIX | TESTED (BN-1, fails) |
| BN-2 | The legendary explosion duplicates the epic and loses to it at Epic tier: Pyre of Stars is a flat 40 with no rider, Chain Reaction at m=2 is 40 plus burning | FIX | TESTED (BN-2, fails) |
| BN-4 | h_board's description promises failed-boarding sabotage its fx never emits; open check 2 showed the sabotage lives in boarding resolution on the partial branch only, so the defect is the wording's scope | FIX | NOT-TESTABLE: text-versus-mechanism scope |
| BN-5 | Duo coverage is thin: six duos over fifteen patron pairs, and Hunger appears in only one, so four of its five directions can never bridge | FIX | TESTED (BN-5, fails) |

Numbering note: BN-3, the L_storm gate, is counted once as RWD-3.

### Oct 29 program: economy (economy_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| ECO-1 | Paid repair cannot carry the regroup tension at current prices, because the free-healing stack pre-empts it. Ryan clarified the design (repair should always beat scrap-and-replace; the tension is budget allocation) and, after sims showed the tension binding in 0.0% of 60,000 modelled regroups, ruled ACCEPT AS IS FOR NOW on Oct 29 | BLOCKER | NOT-TESTABLE: a test asserting the tension would contradict a standing ruling. The revisit trigger is play data (the telemetry spec's protected item); the measurement lives in the CP and repair sims |
| ECO-2 | The Chorus carrier is the most expensive carrier in the game (370) while small-class Chorus hulls are discounted | FIX | TESTED (ECO-2, fails) |
| ECO-3 | Decommission pays a flat 35% regardless of ship condition | FIX | TESTED (ECO-3, fails): the campaign loader renders the shipyard over two wardens; decommission pays 25 at full hull and 25 at 30% hull |
| ECO-4 | Prize valuation ignores priceMult: ransom and strip are denominated in base value while shop prices scale, and coffers Heat erodes capture income by about 20% on the same hulls | FIX | TESTED (ECO-4, fails): under the coffers heat (priceMult 1.25) a full-hull warden ransoms for 39 against the scaled expectation of 48 |

### Oct 29 program: firstrun (firstrun_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FR-1 | The tip system structurally cannot teach the campaign layer: tutorialCheck returns whenever no battle object exists, and the map screen nulls it | BLOCKER | NOT-TESTABLE: the gating lives in UI shell files outside the rules harness; the defect is an absence across screens |
| FR-2 | A lost Nemesis meeting teaches nothing: the win branch of nemAfterBattle reveals a weakness, the loss branch reveals none. Ruled Oct 29 (battle Q5): a lost meeting still teaches, capped at one new reveal | FIX | TESTED (FR-2, fails): a loss with both weaknesses unrevealed reveals none (spec check a), and the both-revealed control reveals no phantom (check c). The ruled fixes spec, Fix 2, carries the remaining acceptance checks. Also the nemesis program's top finding; counted once here |
| FR-3 | Battle 1 can stack up to five modal tip cards 400ms apart, each carrying a permanent Hide tips kill switch, so teaching can be ended accidentally in the first minute | FIX | NOT-TESTABLE: modal UI behaviour |
| FR-4 | The map's boon badge never prints the word Boon or explains the star, so routing decisions are made blind | FIX | NOT-TESTABLE: map screen rendering |

### Oct 29 program: faction shape (factionshape_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FS-1 | Credit shape never reaches enemy fleets: genEnemyFleet spends CP only and never consults FAC_PRICE | FIX | TESTABLE-NOT-WRITTEN: Ryan ruled the principle on Oct 29 (Eclipse stronger and pricier, Chorus the opposite, across stats, price and CP); the assertion shape depends on the mechanism chosen (budget multiplier or ladder re-base), sims first. Re-confirmed Oct 30 round 2: FAC_PRICE's only consumer is still the data.js cost fold (player-facing prices); genEnemyFleet reads budget, roster CP and RAMP only. The Oct 30 Monte Carlo grids inform the mechanism choice (price-first collapses Eclipse at x1.25; the Chorus discount expresses only with a CP allowance) but no mechanism has been picked |
| FS-2 | FAC_PRICE.deathless has no Battleship key, so the ruled cp6 Eclipse battleship prices by fallback at 370, below the faction's own cp4 cruiser at 390 | FIX | TESTED (FS-2, fails) |
| FS-3 | CP is symmetric at the ladder bottom: every frigate costs 1 CP and every destroyer 2 CP across factions | FIX | TESTABLE-NOT-WRITTEN: if the chosen mechanism is budget-level, hull CP stays symmetric by design, so a hull-CP assertion written now could be wrong by construction. Re-confirmed Oct 30 round 2: every faction's frigates cost exactly 1 CP and its destroyers exactly 2 CP at this pin, no exceptions |
| FS-5 | Chorus has regeneration but no feed or grow mechanic, so the swarm identity is numeric only | FIX | NOT-TESTABLE: absence of a mechanic is a design gap; the fix is new content, not an assertable state |

Numbering note: FS-4 is counted once as ROS-4.

### Oct 29 program: drift (drift_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| DRIFT-1 | The Godot parity oracle copy of the campaign shell carries the same unlockAll boot grant as PROG-1, so parity tests compare against a fully unlocked state | FIX | NOT-TESTABLE: the oracle is a Godot-side fixture the browser harness cannot load |
| DRIFT-2 | The retired mobile layer is live and can fire on real PCs (coarse pointer plus a small window), forcing quality medium and fxReduced off at boot | FIX | NOT-TESTABLE: the detection lives in scene3d.js and main3d.js, outside the rules harness; patch pack section 5 carries the diff and a browser-load acceptance check |
| DRIFT-4 | The guidance documents are a stratigraphy: NEXT.md carries superseded phone-era gates, PROGRESS.md describes a 'mobile map' and an old working directory, BACKLOG.md sits mid-retirement | FIX | NOT-TESTABLE: repository documents, not runtime state; the fix is editorial |
| DRIFT-5 | touchWords carries regexes that can never match, because the generic Click-to-Tap replacement runs before the specific one in the same chain | FIX | TESTED (DRIFT-5, fails): touchWords over the shipped movement tip under the mobile flag returns the single-tap wording; the double-tap variant is unreachable |

Numbering note: DRIFT-3 is counted once as WPN-4. DRIFT-6 (the flash-window figure) is an audit-record discrepancy with no code surface and is excluded.

### Oct 29 program: battle UI (battleui_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| UI-1 | Fire-on-click attack-move: clicking an out-of-range enemy moves the ship to a planner-chosen hex that is never previewed, with odds computed from the current hex. Ruled Oct 29: phased activation replaces this model | BLOCKER | NOT-TESTABLE in this harness: the defect is the interaction model in ui3d.js; regression assertions belong to the replacement's tests |
| UI-2 | Fire-all is the unarmed default and is irreversible; the only two-tap confirm in battle is the admiral Command | FIX | NOT-TESTABLE: same interaction model as UI-1 |
| UI-3 | Inspect and fire share one gesture: the roster and the board disagree on what clicking an enemy means | FIX | NOT-TESTABLE: same interaction model as UI-1 |
| UI-4 | The armed weapon resets after one shot and on every selection change, making sequenced salvos three manual steps per ship | FIX | NOT-TESTABLE: UI state handling in ui3d.js |
| UI-5 | Sticky wing selection escapes the cancel paths: Esc, selectUnit and rosterPick never clear wingSel; only order assignment does (ui3d.js:425) | FIX | TESTED (UI-5, fails): the UI-state harness drives the game's own selectUnit, ACT.rosterPick and the real Escape key path with a wing selected; wingSel survives all three, including the full three-step cancelAction chain (mode, then armed, then selection) |
| UI-6 | The hint line can declare a ship finished ('Nothing left to do') while it still has movement or an unspent Brace | FIX | TESTED (UI-6, fails): the UI-state harness reads the real actionStrip hint in the two states the finding names: movement remaining (2 of 6 points, nothing in range) and an unspent Brace (fully moved, weapons unfired); both render 'Nothing left to do: tap Done with ship.' The hint chain checks ram, targets and first-move only |
| UI-7 | keysHelp omits R, X, G, F, T and Home, several of them core combat inputs | FIX | TESTED (UI-7, fails): static content check against the ui3d key handlers, in the wave 2 validator style; keysHelp omits r, t, f, x and g (Home is a named key, outside the letter-binding scan) |
| UI-8 | Auto-facing optimises gun count only: bestFacingReach (ui3d.js:393) never weighs the ship's own shield facings, and arming a single weapon does not recompute it | FIX | TESTED (UI-8, fails) on both halves: on a gun-count tie (turret ship, equal cost and turns) bestFacingReach keeps the facing that exposes the 4-point shield over the one presenting the 40-point shield, its score being gun count, cost and turns only; and ACT.arm leaves B.reach as the identical object, so after one weapon is armed the reach overlay still shows gun counts computed for the whole battery |
| UI-9 | The expected-damage line for a hovered move does not name its target | FIX | NOT-TESTABLE: tooltip text |

### Wave 3 deep QA (wave3_deepqa_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| W3-1 | The elite guarantee breaks when the approach column rolls all rest nodes: the guarantee finds no battle or event node to convert and silently does nothing | FIX | TESTED (W3-1, fails: 25 of 900 maps in this file's compact sweep; 84 of 4,500 in the full softlock_sweep.js, different seed sets). Patch pack section 4 carries the fix |

### Wave 5 patch pack (patch_pack_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| PP-2 | Pure-hive fleets count as zero carriers for the enemy point-defense adaptation, because the adaptation counts template hangars only while derive() folds the hive aspect's hangar in elsewhere (battle.js:326-327 vs core.js:214) | FIX | TESTED (PP-2, fails) |

Patch pack sections 1, 3, 4 and 5 are counted once as AI-1, MOD-3, W3-1 and DRIFT-2; section 6 is the non-reproduction counted as FGT-4.

## Cross-reference index (duplicates counted once)

- RWD-3 = the boons program's L_storm gate finding (BN-3).
- FR-2 = the nemesis program's intel drought (NEM-1) and ruled fixes spec Fix 2; RWD-8 = the Q7 spillover defect, ruled fixes spec Fix 1, and measurements item M2.
- ROS-2 = the text program's variant-card batch (TXT-4). PROG-2 includes the text program's locked-card finding (TXT-6). MOD-5 = the variety program's FIT_SLOTS item. ROS-4 = the faction shape program's FS-4. WPN-4 = the drift program's DRIFT-3.
- PP-1 = AI-1, PP-3 = MOD-3, PP-4 = W3-1, PP-5 = DRIFT-2, PP-6 = FGT-4. DRIFT-1 is PROG-1's grant on a second surface (the Godot oracle), kept as its own row because the fix and the test surface differ.
- Wave 1 open checks: item 2 resolved BN-4's mechanism, item 3 is MOD-3, item 4 shaped WPN-3's guard, item 5 is PP-2, item 6 is AI-2, item 7 is DRIFT-1.

## Honesty notes

- ROS-2's test surfaces one instance beyond its synthesis (b_razor_s). It is flagged in the row as not chair-verified; the chair may clear it if 'two tendril clusters' is judged to disclose the swap.
- RWD-9 and FGT-4 are findings whose tests pass because the defect does not reproduce at the pin. Both rows say why, so a future reader does not mistake them for padding: each pins behaviour a later edit could silently break.
- W3-1's two failure rates (25 of 900 here, 84 of 4,500 in softlock_sweep.js) come from different seed sets and are consistent with the same underlying rate of roughly 2 to 3 percent of maps.
- BF-9's test reads the to-hit penalties from TERRAIN_INFO text, because that table is the game's own published statement of the rule and the synthesis verified the same numbers against battle resolution. If the rule ever moves into a named constant, the test should read the constant instead.
- The Oct 30 extension probed BF-1 and BF-5 before writing anything: neither defect reproduced headlessly at the pin (the ring center survives startBattle; ambush holds both deployment bands in 12 of 12 trials). Both rows stayed TESTABLE-NOT-WRITTEN with the probe results recorded in their rows, rather than gaining tests that pass for the wrong reason. Round 2 (same day) took both hunts further: BF-1's round 1 probe had tested only the one deployment whose fleets start far from the center; with ambush deployment and the lanes barrier driven, the defect reproduces and BF-1 is converted, with the round 1 geometry kept in the test as the control case. BF-5's fallback trigger proved unreachable across a much wider sweep, so its hunt closed on negative evidence and the row stays open on the code path alone, with no guard test written.
- The round 2 suite caught its own harness flaw on its first run: the async battle-probe tests initially interleaved on one shared battle context, which made AI-1 report a scenario failure and AI-4 pass vacuously. The runner now executes tests strictly in file order; the vacuous pass is recorded here so the 8-pass line is never misread as including it.
- AI-3's test normalises the two movers' hull numbers (same hp, shields, armor, evasion, gun and speed) so the only difference is hull value in CP. It therefore pins value scaling in the CP sense the finding names. A fix that scaled the cliff weight by maxHp alone would not move this test; if Opus rules maxHp is the intended scale, the fixture should be re-split on maxHp instead, and the row updated with it.
- BF-1's 90% survival bar is chair-set, like RWD-5's 15 credits: it separates the observed defect (31 to 34%) from the control (100%) with room on both sides, and the Q11 fix design may set a different bar per shape.
- The battle-probe fixtures set some unit fields directly (a spent gun built through mkWeapon, shields stripped, an ability nulled) to isolate the scoring behaviour under test. The battles, movement, threat and AI decisions themselves are the game's own, driven through startBattle and aiUnit the way sim3d drives them; the animation hooks only commit the moves the rules already chose.
- The UI-state harness stubs two presentation edges and nothing else: bRefresh (the render fan-out, called by state functions purely as a repaint notification) and uWorld (camera coordinates). Every state transition asserted (selectUnit, cancelAction, onKey, ACT.arm, ACT.rosterPick, actionStrip, bestFacingReach) is the game's own function running unmodified. If a future UI fix moves state handling into the render pass, these tests should be retired rather than extended with more stubs.
- RWD-5's pass bar (a credit node must beat the decline value by at least 15) is a chair-set threshold, recorded in the row, not a Ryan ruling. PROG-5's test follows the progression synthesis's reading of the stated mastery rates as per-type totals (elite 2, flagship 5); if the rates are ruled additive, PROG-5 converts to the FGT-4 pattern and the test retires.
- BF-7 and BF-8 entered the ledger as Argon leg findings the chair had not re-verified. Their new tests verify both at the pin, so the rows now carry chair-grade evidence.
