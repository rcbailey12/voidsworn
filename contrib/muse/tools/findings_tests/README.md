# Findings-to-tests ledger (Voidsworn, wave 5 slate item 4)

Every BLOCKER and FIX-level finding from the audit programs, mapped to either a working harness regression test or an explicit no-test row with a reason. Code pin: 264f441d (the pin every Oct 28 and Oct 29 program verified against).

Run the tests: `node findings_tests.js` (optionally with a repo path). The file exits 1 while any pinned defect is unfixed. That is the point of it: a failing test here is a correct regression test, not a broken one. Tests were not weakened to pass. When a fix lands, the matching test should flip to PASS without edits; if a fix takes a different shape than the finding assumed, update the test and its ledger row together.

## Status key

- TESTED: a test in findings_tests.js asserts the desired state today. Its current result is in the run table below.
- TESTABLE-NOT-WRITTEN: an automated test is possible and the route is named, but writing it needs infrastructure this pass did not build (usually a loader extension for the campaign files, which game_loader.js does not load, or a battle probe in the sim3d driver).
- NOT-TESTABLE: no automated assertion honestly captures the defect. The reason is stated per row (visual composition, text judgment, semantic name matching, comment text, design questions with no ruled target state, or a standing ruling that accepts the current state).

## Scope

Covered: the Oct 27 program (kit coherence, admirals, events, HUD, text), the Oct 28 progression program (progression, rewards, loop, variety), the Oct 28 battle-layer program (battlefield, fights, nemesis, roster), the Oct 29 audit program (weapons, squadrons, modules, AI, boons, economy, firstrun, faction shape, drift, battle UI), wave 1 open checks and the ruled fixes spec (folded into their parent findings), wave 3 deep QA, and the wave 5 patch pack and measurements.

Excluded, with reasons: the tree validation synthesis (its defects were in a chair draft document and were fixed in the final proposal filed alongside it; no shipped code was involved); the Oct 28 validation synthesis (fiction and learning-frame coherence, no code findings); the Oct 27 balance and economy evidence packs (measurements against tuning claims, not defect findings; the one hard claim there, a capture-value leak, was verified absent at the pin); measurements item M1 (Nemesis snowball, verdict: keeping pace, not a defect); the Oct 26 migration review (outside the commissioned program set); and items the chairs explicitly discounted or graded below FIX (hull-down telegraphing, kill credit, the discounted legacy migration weight is kept as NEM-7 because two legs filed it as a defect). Duplicate findings across programs are counted once, at the row named in the cross-reference index.

## Coverage

| Program | Rows | TESTED | TESTABLE-NOT-WRITTEN | NOT-TESTABLE |
|---|---|---|---|---|
| Oct 27 program | 29 | 11 | 4 | 14 |
| Oct 28 progression program | 17 | 6 | 6 | 5 |
| Oct 28 battle-layer program | 29 | 13 | 14 | 2 |
| Oct 29 audit program | 48 | 12 | 17 | 19 |
| Wave 3 deep QA | 1 | 1 | 0 | 0 |
| Wave 5 patch pack (new rows only) | 1 | 1 | 0 | 0 |
| **Overall** | **125** | **44** | **41** | **40** |

44 of 125 findings (35%) have a working regression test today. Of the rest, 41 are testable with named infrastructure and 40 are not honestly automatable.

## Test run at the pin (48 tests: 8 pass, 40 fail)

The 44 TESTED rows are covered by 48 tests, because VAR-1 is one row backed by five sweep assertions. The eight passes are the healthy signs in the set: five generator guarantees, one non-reproduction (FGT-4), one guard the weapons synthesis proposed (WPN-3), and one feared defect that does not reproduce (RWD-9). Every other test fails because its defect is still in the code, and each failure message names the defect as found.

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
| EVT-1 | eventFlags stores the chosen option key, but needMet and verbFree test flag presence only, so five choice-specific free options can fire on the wrong outcome | FIX | TESTABLE-NOT-WRITTEN: campaign_run.js is not loaded by the harness; extend game_loader with the campaign files and assert per-outcome gating |
| EVT-2 | The seer event excludes ithar while its spliced song option requires ithar, so the option can never fire | FIX | TESTED (EVT-2, fails) |
| EVT-3 | Beacon 'Seize the cargo' conceals an ambush and a Nemesis clock advance its text never discloses | FIX | TESTED (EVT-3, fails) |
| EVT-4 | Repair gating is inconsistent across events: wright, dock and quiet repair with no Chorus gate while shrine gates chorus and deathless | FIX | TESTABLE-NOT-WRITTEN: enforcement sits in campaign event resolution; pair with the KIT-1 fix. Event data differs by design intent, so no pure data assertion is honest |
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
| TXT-2 | Shipwright repair heals the wrong ship when a same-name or same-hull stablemate sits at a lower fleet index (the handler takes the first match, not the clicked ship) | FIX | TESTABLE-NOT-WRITTEN: campaign loader extension; assert the repaired ship is the selected one |
| TXT-3 | Purchase surfaces render base weapon names while ship cards render faction names, so a bought weapon looks like a different weapon | FIX | NOT-TESTABLE: two DOM rendering paths in the campaign UI files |
| TXT-5 | The Crusade RANKS table is hardcoded for every faction across promotion notices, blue-option requirements, and the shipyard lede | FIX | NOT-TESTABLE: screen text in campaign files |
| TXT-7 | The Nemesis card claims 'He never retreats' although nothing sets noFlee and escape is a coded outcome; a second line hardcodes 'His fleet is coming' around the nemSay path | FIX | NOT-TESTABLE: text-versus-behaviour semantics in campaign files |
| TXT-8 | The decommission button label computes NaN for hulls with no cost field (campaign_run.js:174) | FIX | TESTABLE-NOT-WRITTEN: campaign loader extension; shipValue in core.js already guards the value itself, the label path is the gap |

Numbering note: the text program's variant-card batch is counted once as ROS-2, and its locked-card finding is counted once as PROG-2.

### Oct 28 progression program: progression (progression_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| PROG-1 | The boot grant in main3d.js hands over all 12 legacy unlocks and all 24 admirals (1,565 renown of sinks) unless an option defaults the other way; progression is bypassed as shipped | BLOCKER | NOT-TESTABLE: main3d.js is browser shell code outside the rules harness. The same grant in the Godot parity oracle is DRIFT-1 |
| PROG-2 | The purchase path is doubly dead: ACT.buyLegacy and ACT.buyAdmiral are implemented with zero UI call sites, and locked admiral cards point to a 'Legacy' screen that no longer exists under that name | FIX | TESTABLE-NOT-WRITTEN: static call-site scan in the style of the wave 2 validators. Merges the text program's locked-card finding |
| PROG-3 | The unlock-everything settings toggle is dead code: the handler exists but no settings button renders it | FIX | NOT-TESTABLE: DOM rendering in the shell files |
| PROG-4 | The end-of-run summary omits core sync entirely (renown and mastery only), so the learning frame's central quantity is invisible where it should pay off | FIX | NOT-TESTABLE: summary screen rendering. See also LOOP-1 |
| PROG-5 | Mastery XP double-counts elites and bosses: the battles counter includes them and endRun pays battles + elites x2 + bosses x5 on top, so an elite pays 3 and a boss 6 against a stated 2 and 5 | FIX | TESTABLE-NOT-WRITTEN: endRun lives in campaign_meta.js; load it with DOM stubs and assert XP for a fixed stats fixture |
| PROG-6 | Admiral ownership is unenforced at launch: with the grant off, selection auto-assigns the faction's first admiral and neither Launch nor newRun checks ownership, so the lock is decorative in both directions | FIX | TESTABLE-NOT-WRITTEN: campaign loader extension around the launch path |

### Oct 28 progression program: rewards (rewards_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| RWD-1 | The prize screen pre-computes the optimal default for every captured ship (add, strip, or ransom by the code's own valuation), so the capture decision is solved before the player sees it | FIX | NOT-TESTABLE: whether a default may be optimal is the design question itself; no pass/fail assertion survives either answer |
| RWD-2 | Eight of 36 core protocols ignore or cap the rarity multiplier (i_wall, s_chain, h_brood, a_mark, r_slip, e_spread ignore it; h_hatch and e_reload cap at Rare). Ruled Oct 28: numeric rarity scaling | FIX | TESTED (RWD-2, fails on exactly those eight) |
| RWD-3 | L_storm is missing from BOON_NEED while its shield siblings are gated, so a shieldless fleet can be offered a shield legendary | FIX | TESTED (RWD-3, fails). Also the boons program's gate finding; counted once here |
| RWD-4 | Once two patron boons are held, the patron legendary deterministically takes offer slot 3, overwriting any duo rolled there, on every reroll. Ruled Oct 28: weighted roll between duo and legendary | FIX | TESTED (RWD-4, fails: duo survived 0 of 300 offers) |
| RWD-5 | Declining a boon offer pays 30 + 10 per sector against a credit node's 35 + 10 per sector, so the boon node dominates by solved arithmetic. Ruled Oct 28: rebalance credit nodes | FIX | TESTABLE-NOT-WRITTEN: the decline payout lives in campaign reward code; assert node-versus-decline values once loaded |
| RWD-6 | The reroll never checks pool depth: with three or fewer eligible protocols it charges an escalating price and returns the same three | FIX | TESTABLE-NOT-WRITTEN: the reroll handler lives in campaign files |
| RWD-7 | Salvage is deterministic: the wreck module is always the first match on a fixed nine-module list (four modules can never drop), and ransom decays 0.85 per prior ransom in fixed battle order | FIX | TESTABLE-NOT-WRITTEN: salvageYield and the prize code live in campaign_run.js |
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
| BF-1 | clearSpawns deletes terrain within radius 2 of player ships and radius 1 of enemies plus a 6-hex corridor, erasing the shape-defining center terrain on ring, archipelago, belt and lanes maps | BLOCKER | TESTABLE-NOT-WRITTEN: startBattle terrain-diff probe per shape; the assertion needs a per-shape definition of the defining hexes, which the Oct 29 Q11 ruling (shape-aware clearing) leaves to the fix design |
| BF-2 | Boss fights additionally delete 45% of rock at setup, so the biggest fights happen on the emptiest boards | FIX | TESTABLE-NOT-WRITTEN: same probe family as BF-1 (rock count before and after startBattle on boss kind) |
| BF-3 | Terrain colors collide in exact pairs: rock and hulk share #bda088; station and planet share #9a948a | FIX | TESTED (BF-3, fails) |
| BF-4 | The gravity well never appears in the terrain legend: terrainPresent reads only B.terrain, and the well is not a terrain entry | FIX | NOT-TESTABLE: legend presentation; the well's absence from the table is by construction |
| BF-5 | Deployment fallbacks erase flank and ambush: a single-centroid scorer collapses ambush into a blob, and the general half-board fallback erases flank on narrow shapes | FIX | TESTABLE-NOT-WRITTEN: startBattle deployment probe per mode and shape |
| BF-6 | ENC_ARENA weights gate strip shapes out entirely for hold encounters (round .6, square .4, no strip entry) | FIX | TESTED (BF-6, fails) |
| BF-7 | On lanes, the barrier line runs parallel to the advance axis instead of across it, so the shape's defining feature does not block the advance | FIX | TESTABLE-NOT-WRITTEN: shape geometry probe over generated lanes terrain. Argon leg; plausible, not chair re-verified line by line |
| BF-8 | Reinforcement edges are hardcoded left and right, which is wrong on rotated arenas | FIX | TESTABLE-NOT-WRITTEN: battle probe on rotated arena shapes. Argon leg; plausible, not chair re-verified line by line |
| BF-9 | Debris is strictly dominated by nebula: same rule shape, 10 points of to-hit penalty against nebula's 15 | FIX | TESTED (BF-9, fails; the assertion reads the penalties from TERRAIN_INFO, the player-facing statement of the rule) |
| BF-10 | The Engagement shape list names archipelago twice, silently double-weighting it | FIX | TESTED (BF-10, fails) |

### Oct 28 battle-layer program: fights (fights_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FGT-1 | The boss objective roll is rout, rout, ambush, flagship, so Decapitation makes the hand-built boss escort irrelevant in about a quarter of boss fights. Ruled Oct 29: boss fights get their own objective table | BLOCKER | TESTED (FGT-1, fails: 91 of 400) |
| FGT-2 | The rout mirror problem: on a rout roll the boss can flee alive, while the CP-weighted rout threshold forces a near-wipe anyway | FIX | TESTABLE-NOT-WRITTEN: battle-outcome probe; the fix rides on FGT-1's new boss table |
| FGT-3 | Objective previews hide the operative thresholds (Breakthrough's escape count, Hold's station integrity) | FIX | NOT-TESTABLE: preview text surfaces in the campaign UI |
| FGT-4 | Reported defect: Deathless nodes preview a carrier the roster does not have | FIX | TESTED (FGT-4, passes): the defect does not reproduce. Both preview surfaces already resolve through effArch, which maps a Deathless carrier roll to heavy; verified again by the wave 5 patch pack, section 6. The test pins the correct behaviour |

### Oct 28 battle-layer program: nemesis (nemesis_synthesis_2026_10_28.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| NEM-2 | nemAdapt filters only by not-yet-taken and never checks the revealed weakness set, so the Nemesis can adapt into a direct counter to a revealed weakness. Ruled Oct 29 (Q4): a clash check is required | FIX | TESTABLE-NOT-WRITTEN: nemAdapt is a near-pure function in campaign_run.js; the cleanest campaign-loader candidate |
| NEM-3 | The adaptation cap is cumulative (max(0, sector-1), plus Chorus adaptFast terms) rather than one per sector as designed, and the fallback always fires when the cap allows | FIX | TESTABLE-NOT-WRITTEN: same loader extension as NEM-2 |
| NEM-4 | Only two of six nemStrike faction strikes (raid, tithe) return map effects; duel, swarm, reinforce and challenge return empty | FIX | TESTABLE-NOT-WRITTEN: assert each faction's strike returns a non-empty effect once campaign_run.js loads |
| NEM-5 | The raid warning can lie two ways: nemWarnLine evaluates the crippled condition before the clock fight resolves while nemStrike re-evaluates after, and loud event choices fill the clock and fire the strike immediately, not after the next win | FIX | TESTABLE-NOT-WRITTEN: campaign loader extension with clock-state fixtures |
| NEM-6 | Nemesis death registers only at sector 3 or later, leaving open how noFlee factions survive flagship destruction in sectors 1 and 2 | FIX | TESTABLE-NOT-WRITTEN: nemAfterBattle fixtures via the campaign loader extension |
| NEM-7 | ensureNemesis's legacy migration copies only 10 fields and filters adaptations to the generic set, dropping faction loot state | FIX | TESTABLE-NOT-WRITTEN: save-layer test in the save_fuzz pattern once ensureNemesis is loadable. One-time legacy edge; the synthesis discounts its weight |

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
| ROS-7 | Launch is concentrated on eight hulls and Hegemony's two line ships carry a token hangar 1 with no dedicated carrier | FIX | TESTABLE-NOT-WRITTEN: the data check is trivial, but the assertion waits on the unanswered design question (dedicated Hegemony carrier or deliberate distributed shape) |
| ROS-8 | Three of six boss hulls recycle roster kits with no boss-exclusive weapon or ability | FIX | TESTABLE-NOT-WRITTEN: a similarity assertion needs the overlap threshold the audit did not set |
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
| SQ-2 | The carrier archetype branch seeds one carrier then fills generically, and is skipped entirely for boss fights, so carrier identity washes out of the fleets built around it | FIX | TESTABLE-NOT-WRITTEN: genEnemyFleet composition probe; needs a role-composition definition the audit did not formalize |
| SQ-3 | The torpedo screen's one-kill-per-wing-per-salvo cap is never stated in the stance text | FIX | NOT-TESTABLE: the finding as graded is the missing text |
| SQ-4 | Wing veterancy perks are random grants on the 3/8/15 XP ladder and cannot be steered; enemy wings cannot reach the ladder at all | FIX | NOT-TESTABLE: steerability is a UI flow property, not a data state |

### Oct 29 program: modules (modules_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| MOD-1 | Fitting is free, instant and fully reversible, which collapses modules into a pre-battle checklist | BLOCKER | NOT-TESTABLE: the defect is absent friction in campaign UI flow, and no target state has been ruled; a test written now would assert a design nobody chose |
| MOD-2 | Five modules duplicate five captain perks effect for effect through one additive pool, and MODULES.cogitator collides with RELICS.cogitator on the same key | FIX | TESTED (MOD-2, fails: the collision plus four pairs). The fifth pair, regen vs deflector, shares the regenPct key at .5 vs .4, a near-duplicate the subset rule does not flag |
| MOD-3 | Weapon-kind modules can be fitted for zero effect with no warning: only hangar carries an `only` guard, and the campaign fit guard keys on ability, not weapon kind | FIX | TESTABLE-NOT-WRITTEN: patch pack section 3 carries the diff and acceptance check; enforcement sits at campaign_run.js:128 |
| MOD-4 | damcon (85 credits) is mathematically dominated by prow (70 credits) | FIX | TESTED (MOD-4, fails) |
| MOD-5 | The FIT_SLOTS schema has no mechanical consumer anywhere (dead data audit: DEAD EVERYWHERE), and its flagship reserve collides with the universal slot ladder | FIX | NOT-TESTABLE: absence of a consumer across the whole codebase, including the Godot port, cannot be proven from the three files the rules harness loads; the collision itself is a design decision. Also filed by the variety program; counted once here |

### Oct 29 program: AI (ai_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| AI-1 | The veteran brace bypass: on veteran difficulty the AI can be left permanently unbraced by the mid-move volley path returning before the brace decision (battle.js:1385-1387) | BLOCKER | TESTABLE-NOT-WRITTEN: patch pack section 1 carries the acceptance check; aiUnit is async and animation-coupled, so the probe belongs to the sim3d battle driver, not the data harness |
| AI-2 | genEnemyFleet's fill loop can strand budget at the CP ceiling | FIX | TESTABLE-NOT-WRITTEN: the stranding magnitude was measured by the CP sims; a pass/fail threshold waits on the CP mechanism chosen under the Oct 29 ruling |
| AI-3 | The AI's death-cliff weight is a flat -25 unscaled to ship value, distorting target choice for cheap and expensive hulls alike | FIX | TESTABLE-NOT-WRITTEN: battle probe comparing the cliff term across ship values; the constant is inline in AI scoring |
| AI-4 | The approach leash pulls a ship with no bearing guns toward the player at -4 per hex beyond minimum range instead of letting it kite | FIX | TESTABLE-NOT-WRITTEN: battle probe with a bearing-less ship at range |
| AI-5 | The AI launches wings before moving, from launch hexes sorted only by distance, so launches can be baited into a kill zone | FIX | TESTABLE-NOT-WRITTEN: battle probe over launch ordering |

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
| ECO-3 | Decommission pays a flat 35% regardless of ship condition | FIX | TESTABLE-NOT-WRITTEN: prize and decommission code in campaign_run.js |
| ECO-4 | Prize valuation ignores priceMult: ransom and strip are denominated in base value while shop prices scale, and coffers Heat erodes capture income by about 20% on the same hulls | FIX | TESTABLE-NOT-WRITTEN: campaign_run.js prize code |

### Oct 29 program: firstrun (firstrun_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FR-1 | The tip system structurally cannot teach the campaign layer: tutorialCheck returns whenever no battle object exists, and the map screen nulls it | BLOCKER | NOT-TESTABLE: the gating lives in UI shell files outside the rules harness; the defect is an absence across screens |
| FR-2 | A lost Nemesis meeting teaches nothing: the win branch of nemAfterBattle reveals a weakness, the loss branch reveals none. Ruled Oct 29 (battle Q5): a lost meeting still teaches, capped at one new reveal | FIX | TESTABLE-NOT-WRITTEN: the ruled fixes spec, Fix 2, carries acceptance checks (a) to (e); nemAfterBattle lives in campaign_run.js. Also the nemesis program's top finding; counted once here |
| FR-3 | Battle 1 can stack up to five modal tip cards 400ms apart, each carrying a permanent Hide tips kill switch, so teaching can be ended accidentally in the first minute | FIX | NOT-TESTABLE: modal UI behaviour |
| FR-4 | The map's boon badge never prints the word Boon or explains the star, so routing decisions are made blind | FIX | NOT-TESTABLE: map screen rendering |

### Oct 29 program: faction shape (factionshape_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| FS-1 | Credit shape never reaches enemy fleets: genEnemyFleet spends CP only and never consults FAC_PRICE | FIX | TESTABLE-NOT-WRITTEN: Ryan ruled the principle on Oct 29 (Eclipse stronger and pricier, Chorus the opposite, across stats, price and CP); the assertion shape depends on the mechanism chosen (budget multiplier or ladder re-base), sims first |
| FS-2 | FAC_PRICE.deathless has no Battleship key, so the ruled cp6 Eclipse battleship prices by fallback at 370, below the faction's own cp4 cruiser at 390 | FIX | TESTED (FS-2, fails) |
| FS-3 | CP is symmetric at the ladder bottom: every frigate costs 1 CP and every destroyer 2 CP across factions | FIX | TESTABLE-NOT-WRITTEN: if the chosen mechanism is budget-level, hull CP stays symmetric by design, so a hull-CP assertion written now could be wrong by construction |
| FS-5 | Chorus has regeneration but no feed or grow mechanic, so the swarm identity is numeric only | FIX | NOT-TESTABLE: absence of a mechanic is a design gap; the fix is new content, not an assertable state |

Numbering note: FS-4 is counted once as ROS-4.

### Oct 29 program: drift (drift_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| DRIFT-1 | The Godot parity oracle copy of the campaign shell carries the same unlockAll boot grant as PROG-1, so parity tests compare against a fully unlocked state | FIX | NOT-TESTABLE: the oracle is a Godot-side fixture the browser harness cannot load |
| DRIFT-2 | The retired mobile layer is live and can fire on real PCs (coarse pointer plus a small window), forcing quality medium and fxReduced off at boot | FIX | NOT-TESTABLE: the detection lives in scene3d.js and main3d.js, outside the rules harness; patch pack section 5 carries the diff and a browser-load acceptance check |
| DRIFT-4 | The guidance documents are a stratigraphy: NEXT.md carries superseded phone-era gates, PROGRESS.md describes a 'mobile map' and an old working directory, BACKLOG.md sits mid-retirement | FIX | NOT-TESTABLE: repository documents, not runtime state; the fix is editorial |
| DRIFT-5 | touchWords carries regexes that can never match, because the generic Click-to-Tap replacement runs before the specific one in the same chain | FIX | TESTABLE-NOT-WRITTEN: touchWords is a pure string transform in campaign_meta.js; loadable with the campaign extension |

Numbering note: DRIFT-3 is counted once as WPN-4. DRIFT-6 (the flash-window figure) is an audit-record discrepancy with no code surface and is excluded.

### Oct 29 program: battle UI (battleui_synthesis_2026_10_29.md)

| ID | Finding | Severity | Status |
|---|---|---|---|
| UI-1 | Fire-on-click attack-move: clicking an out-of-range enemy moves the ship to a planner-chosen hex that is never previewed, with odds computed from the current hex. Ruled Oct 29: phased activation replaces this model | BLOCKER | NOT-TESTABLE in this harness: the defect is the interaction model in ui3d.js; regression assertions belong to the replacement's tests |
| UI-2 | Fire-all is the unarmed default and is irreversible; the only two-tap confirm in battle is the admiral Command | FIX | NOT-TESTABLE: same interaction model as UI-1 |
| UI-3 | Inspect and fire share one gesture: the roster and the board disagree on what clicking an enemy means | FIX | NOT-TESTABLE: same interaction model as UI-1 |
| UI-4 | The armed weapon resets after one shot and on every selection change, making sequenced salvos three manual steps per ship | FIX | NOT-TESTABLE: UI state handling in ui3d.js |
| UI-5 | Sticky wing selection escapes the cancel paths: Esc, selectUnit and rosterPick never clear wingSel; only order assignment does (ui3d.js:425) | FIX | TESTABLE-NOT-WRITTEN: needs a headless UI-state harness (DOM stubs) that does not exist yet |
| UI-6 | The hint line can declare a ship finished ('Nothing left to do') while it still has movement or an unspent Brace | FIX | TESTABLE-NOT-WRITTEN: the predicate is assertable once ui3d loads headlessly |
| UI-7 | keysHelp omits R, X, G, F, T and Home, several of them core combat inputs | FIX | TESTABLE-NOT-WRITTEN: static content check against the ui3d key handlers, in the wave 2 validator style |
| UI-8 | Auto-facing optimises gun count only: bestFacingReach (ui3d.js:393) never weighs the ship's own shield facings, and arming a single weapon does not recompute it | FIX | TESTABLE-NOT-WRITTEN: headless UI harness, or a battle probe if the helper moves into the rules files |
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
