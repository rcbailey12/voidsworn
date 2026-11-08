# Qwen leg, issue 201

Gates: PASSED both ends. Gate 1: fresh chat defaulted to Qwen3.7-Plus; the runner selected Qwen3.8-Max and verified the selector showed it before attaching and before sending. An Access Verification slider appeared during the send attempt; after it was cleared, the runner re-verified the selector still showed Qwen3.8-Max and the pack was still attached. Gate 2: the chat header still showed Qwen3.8-Max after generation completed. Chat: https://chat.qwen.ai/c/1434d766-3047-45a4-a42e-f60bcb7f1e14. Filed raw below; multiplication dots lost in a few rendered formulas (for example "sqrt(200000.20.8)") are the chat rendering's, and the intended arithmetic is recoverable from the values given. Screening is in the chair synthesis.

---

ISSUE 201 TEST-CHECK REPORT (QWEN LEG)
Pack: issue 201, evidence pack for Nemesis redesign checks (issues 120, 121, 122).
Rulings in force: R85, R101, R106. Sequencing per R106: 120 first, then 121, then 122.
================================================================
SECTION A: CHECKS FOR ISSUE 120
(hunter draw per story point and commander registry)
Done-when clauses (verbatim, numbered for cross-reference):
DW120-A: RUN.nemAssign is drawn once at run start from the run RNG (five non-player factions per story point, no consecutive repeats).
DW120-B: A faction-keyed commander registry replaces the single RUN.nem, with lazy creation through the existing newNemesis(fac) identity logic.
DW120-C: The active commander per sector resolves from the assignment.
DW120-D: Old saves migrate (an existing RUN.nem becomes the SP-current entry).
DW120-E: A seed enumeration test reproduces the synthesis section 5 marginals (each hunter about 1/5 per story point, never the player's own faction, SP1 returns at SP3 about 1/4).
DW120-F: Browser and Godot land together.
DW120-G: Campaign parity PASS.
DW120-H: PR checks pass.
Check 120-1
Kind: seeded sim (enumeration).
Covers: DW120-A, DW120-E.
Harness: a new node script in the pattern of contrib/opus/tools/nemesis_clash_tests.js (one-time script build, per-run seconds). The script seeds the run RNG via rndSeed (core.js:3), executes only the assignment draw (the new draw call that replaces or precedes the old RUN.nem assignment), and records RUN.nemAssign. No map generation, no identity rolls, no battle. This isolates the draw from downstream RNG consumers.
Seed set: seeds 1 through 120,000. For each seed, iterate player faction over all six RUN_FACTIONS members (20,000 runs per player faction, 120,000 total), matching the synthesis section 5 enumeration.
Procedure: for each (seed, playerFaction) pair: call rndSeed(seed); execute the assignment draw; record the three-element array RUN.nemAssign.
Expected results (all exact from the synthesis section 5, confirmed by R85):
(a) RUN.nemAssign has exactly 3 elements. (Exact: three story points, synthesis section 1.)
(b) No element equals the player's own faction. (Exact: draw is from the five non-player factions.)
(c) RUN.nemAssign[1] != RUN.nemAssign[0]. (Exact: no consecutive repeats.)
(d) RUN.nemAssign[2] != RUN.nemAssign[1]. (Exact: no consecutive repeats.)
(e) RUN.nemAssign[2] MAY equal RUN.nemAssign[0]. (Exact: SP3 excludes only SP2; R85 Q1, synthesis section 1.)
(f) Marginal frequency per (playerFaction, storyPoint, hunterFaction) cell: expected count 4,000 out of 20,000 (probability 0.200). Tolerance: +/- 0.010 absolute on the proportion (i.e. count between 3,800 and 4,200). INFERRED tolerance: at p=0.2, n=20,000, binomial SD = sqrt(20000 x 0.2 x 0.8) = sqrt(3200) ~ 56.6; +/- 200 is ~3.5 sigma. The synthesis observed max cell deviation was 0.0054, well inside this band.
(g) Aggregate hunts per faction across all 360,000 slots: expected 60,000 each. Tolerance: +/- 600. INFERRED: binomial SD for 360,000 trials at p=1/6 per faction-slot... actually the marginal is 1/5 per story-point but aggregated across 3 story points and 6 player factions the expected count per hunter faction is 360,000/6 = 60,000 (derived: 18 story-point slots / 6 factions = 3 hunts per faction per full set; 3 * 20,000 runs = 60,000). SD ~ sqrt(360000 * (1/6) * (5/6)) ~ sqrt(50000) ~ 224. +/- 600 is ~2.7 sigma. The synthesis observed range was 59,906 to 60,113.
(h) SP1-return rate: fraction of runs where RUN.nemAssign[2] == RUN.nemAssign[0], computed over the subset of runs where RUN.nemAssign[0] != RUN.nemAssign[2] is not forced. Expected: 0.25 (exact: 1/4, R85 Q1, synthesis section 1). Tolerance: +/- 0.01 absolute. INFERRED: n=120,000, p=0.25, SD = sqrt(120000 x 0.25 x 0.75) = sqrt(22500) = 150; as proportion 150/120000 ~ 0.00125; +/- 0.01 is 8 sigma. Synthesis observed 25.1%.
(i) Fraction of runs with three distinct hunters: expected 0.75 (derived: 1 - 1/4). Tolerance: +/- 0.01. INFERRED, same basis as (h). Synthesis observed 74.9%.
Check 120-2
Kind: seeded sim (draw isolation, small seed set).
Covers: DW120-A.
Harness: same script as 120-1, reduced seed set.
Seed set: seeds 1 through 20, player faction fixed to one value (e.g. the first entry of RUN_FACTIONS).
Procedure: for each seed, execute the assignment draw and record RUN.nemAssign. Then re-seed with the same seed and re-execute. Compare.
Expected result: the two RUN.nemAssign arrays are identical for every seed. (Exact: the draw is deterministic given the RNG state; core.js:2 comment confirms seed-plus-same-calls replays.) This confirms the draw consumes the run RNG exactly once at run start and is reproducible.
Check 120-3
Kind: seeded sim (RNG stream shift detection).
Covers: DW120-A; also trap: RNG stream coupling.
Harness: extension of the nem_scenarios.js setup pattern. In the current code, setup(seed, fac) calls rndSeed(seed), starts a run, forces RUN.foes[3] = fac, calls newNemesis() (campaign_run.js:250), then records canonJ state including the raw RNG_S. Under the redesign, the assignment draw consumes RNG calls before map generation.
Seed set: seed 42, player faction fixed.
Procedure:
Step 1: run the current (pre-redesign) setup, record the full canonJ state line after setup (call this GOLDEN_OLD).
Step 2: run the redesigned setup with the same seed and player faction. Record canonJ after setup (call this GOLDEN_NEW).
Step 3: compare GOLDEN_OLD and GOLDEN_NEW. The RNG_S values will differ (the draw consumed extra RNG calls). This is expected and correct.
Step 4: verify that the scenario invariants still hold in GOLDEN_NEW: the state structure is well-formed, RUN.nemAssign exists with 3 elements, the registry is keyed by faction.
Expected result: RNG_S differs between OLD and NEW (exact: the draw adds RNG consumption). Invariants hold. The canonical state lines are re-pinned to GOLDEN_NEW. This check explicitly distinguishes "stream shifted" from "behaviour changed." If any invariant (e.g. number of weaknesses = 2, portrait pattern) fails, that is a behaviour bug, not a stream shift.
Check 120-4
Kind: scenario step.
Covers: DW120-B (lazy creation).
Harness: nem_scenarios.js pattern.
Setup: setup(seed, fac) modified for the redesign: seed the RNG, start a run, force RUN.foes[3] = fac. Do NOT pre-create all commanders.
Steps:
state("run_start"): record RUN.nemAssign and the registry keys. Assert: the registry is empty or contains only the SP1 faction's entry if the implementation creates it eagerly. The pack says "created lazily when that faction is first drawn" (synthesis section 2), so at run start the registry should contain zero entries OR at most the entry for RUN.nemAssign[0] if the sector-1 meeting triggers creation. The exact timing of first creation depends on when the sector-1 meeting resolves; the pack says "lazy creation through the existing newNemesis(fac) identity logic" (issue 120 Done-when). INFERRED: at run start, before any meeting, the registry has 0 entries.
Advance to the first meeting node at sector 1 (force nemNodeIs to true by advancing map columns).
state("sp1_meeting"): record the registry. Assert: exactly 1 entry, keyed by RUN.nemAssign[0]. That entry has the fields produced by newNemesis(fac) at campaign_run.js:250: name, title, persona, two traits, portrait matching 'nem_<fac>_1..6', two weaknesses from NEM_WEAK (data.js:429) with the clash exclusion at campaign_run.js:252.
Advance to sector 2 meeting.
state("sp2_meeting"): registry now has 2 entries. The SP2 entry is newly created; the SP1 entry is unchanged (compare canonJ of the SP1 entry between the two state tags).
Advance to sector 3.
state("sp3_meeting"): if RUN.nemAssign[2] != RUN.nemAssign[0] and RUN.nemAssign[2] != RUN.nemAssign[1], registry has 3 entries. If RUN.nemAssign[2] == RUN.nemAssign[0], registry has 2 entries and the SP1 commander carries any scars from sector 1 (synthesis section 2: "An escaped SP1 commander who returns at SP3 carries his scars").
Expected result: registry size and key set as stated. Identity fields match newNemesis output. Lazy creation confirmed: no commander exists before its faction is first drawn. (Trap: lazy creation order.)
Check 120-5
Kind: scenario step.
Covers: DW120-B (newNemesis identity logic reuse).
Harness: nem_scenarios.js pattern.
Setup: setup(7, <fixed faction>). Force RUN.nemAssign to a known value by seeding appropriately (use a seed found by check 120-1 that gives a desired assignment, or force the assignment directly if the harness allows; the pack does not name a forcing mechanism for nemAssign, so: if no forcing hook exists, this is "not named in the pack" and the check uses a seed that produces the desired assignment).
Steps: trigger the SP1 meeting. Record the commander's identity via state("sp1_identity").
Expected result: the commander has exactly 2 traits from NEM_TRAITS (data.js:450), exactly 2 weaknesses from NEM_WEAK (data.js:429), a name from the nemName pools (campaign_run.js:249), a persona from NEM_PERSONA (data.js:456), and a portrait string matching 'nem_<fac>_1..6'. The weakness pool excludes counters to the commander's own traits per the clash map at campaign_run.js:252 (slow vs swift, board vs boarders, ion vs shielded) and excludes 'anchor' for factions that cannot flee or that revive. All exact from code facts section 6.
Check 120-6
Kind: scenario step.
Covers: DW120-C (active commander per sector resolves from assignment).
Harness: nem_scenarios.js pattern.
Setup: setup(seed, fac). Force or find a seed where RUN.nemAssign has three distinct factions.
Steps:
At sector 1, call nemNodeIs (campaign_run.js:290) at a battle node. Assert: the active commander resolved is the registry entry for RUN.nemAssign[0].
At sector 2, same. Assert: active commander is registry[RUN.nemAssign[1]].
At sector 3, same. Assert: active commander is registry[RUN.nemAssign[2]].
Expected result: at each sector k, the meeting targets registry[RUN.nemAssign[k-1]] (synthesis section 2: "the active commander for sector k is the registry entry for RUN.nemAssign[k-1]"). Exact.
Check 120-7
Kind: save/load.
Covers: DW120-D (old save migration, mid-run).
Harness: nem_scenarios.js pattern. The existing scenario 8 (pre-persona old save) already exercises ensureNemesis() at campaign_run.js:259. This check extends that pattern.
Steps:
state("pre_save"): construct a save object in the OLD shape: has RUN.nem (a single commander object with the NEM_CARRY fields at campaign_run.js:256), no RUN.nemAssign, no registry. Set RUN.sector = 2, N.met = 1, N.clock = 2, N.adapt = ['shields'], N.revealed = [0], N.scars = ['fled'].
state("post_load"): pass this save through the migration path (the redesigned ensureNemesis or equivalent; the pack names ensureNemesis at campaign_run.js:259 as the existing migration surface).
Expected result: after migration, RUN.nemAssign exists with 3 elements. The registry contains at least the SP-current entry. The SP-current entry (sector 2, so RUN.nemAssign[1]) carries the NEM_CARRY fields from the old RUN.nem: weak, revealed, adapt, clock, met, beaten, scars, dead, strike, seen, loot, riches, fed, honed, held, revived, gloat, last_beat (exact list from campaign_run.js:256). Specifically: clock = 2, met = 1, adapt = ['shields'], revealed = [0], scars = ['fled']. The old RUN.nem key is removed or deprecated. Exact, from the issue 120 Done-when: "the existing RUN.nem becomes the SP-current entry."
Check 120-8
Kind: save/load.
Covers: DW120-D (pre-persona old save, regression).
Harness: nem_scenarios.js pattern, scenario 8 replay.
Steps: run the existing scenario 8 (pre-persona old save keeping its state through ensureNemesis) under the redesigned code.
Expected result: the scenario's existing canonical state lines still hold after re-pinning for the RNG stream shift. The NEM_CARRY fields survive. If the scenario's exact canonJ lines change due to the RNG stream shift (trap: RNG stream coupling), the invariants (field presence, values of carried fields) must hold even though exact RNG_S values are re-pinned.
Check 120-9
Kind: parity/process.
Covers: DW120-F, DW120-G, DW120-H.
Harness: the existing parity pipeline: godot/campaign/test/node/compare_campaign.js and golden_campaign.js, driven by godot/campaign/test/parity_campaign.gd and tools/pc/parity_campaign.bat. Oracle copies at godot/campaign/test/oracle/. Table export via node godot/campaign/test/node/export_campaign.js. Godot mirror at godot/campaign/campaign.gd. Godot scenario twin at godot/campaign/test/nem_scenarios.gd, run via godot/campaign/test/run_nem_scenarios.sh.
Steps:
(a) Confirm campaign_run.js changes are mirrored in godot/campaign/campaign.gd.
(b) Re-copy oracles: campaign_run.js, data.js, core.js into godot/campaign/test/oracle/.
(c) Run node godot/campaign/test/node/export_campaign.js to re-export tables.
(d) Run the Godot nem_scenarios.gd twin and compare line-by-line with the JS nem_scenarios.js output via run_nem_scenarios.sh (no tolerance).
(e) Run compare_campaign.js / golden_campaign.js for campaign parity.
Expected result: all comparisons PASS with zero diff. (Exact: the parity harness uses line-by-line comparison with no tolerance, per pack section 6.) PR checks pass. (Trap: parity drift; oracle copies are copies, not links.)
Check 120-10
Kind: seeded sim (SP3 exclusion rule).
Covers: DW120-A, DW120-E; also trap: the draw itself (SP3 excludes only SP2).
Harness: same script as 120-1.
Seed set: full 120,000-run enumeration.
Procedure: from the recorded RUN.nemAssign arrays, count runs where RUN.nemAssign[2] == RUN.nemAssign[0] (SP1 return). Count runs where RUN.nemAssign[2] == RUN.nemAssign[1] (should be zero). Count runs where all three are distinct.
Expected result:
(a) Count of H3 == H1: expected 30,000 out of 120,000 (derived: 120,000 * 1/4 = 30,000). Tolerance +/- 600. INFERRED: SD = 150 (computed above); +/- 600 is 4 sigma.
(b) Count of H3 == H2: exactly 0. (Exact: no consecutive repeats.)
(c) Count of three-distinct: expected 90,000 (derived: 120,000 * 3/4). Tolerance +/- 600. INFERRED, same basis.
This check directly measures the return rate rather than inferring it, catching an implementation that incorrectly excludes both previous hunters at SP3.
Coverage map for issue 120:
DW120-A: checks 120-1, 120-2, 120-10.
DW120-B: checks 120-4, 120-5.
DW120-C: check 120-6.
DW120-D: checks 120-7, 120-8.
DW120-E: checks 120-1, 120-10.
DW120-F: check 120-9.
DW120-G: check 120-9.
DW120-H: check 120-9.
================================================================
SECTION B: CHECKS FOR ISSUE 121
(meetings, clock, adaptation, lessons, NEM_VOICE)
Done-when clauses:
DW121-A: The once-per-sector meeting targets the active commander (nemNodeIs) with a per-commander met-this-sector flag.
DW121-B: One run-level clock paced by the active commander's beh.clock, and a strike brings the sector's meeting forward without changing the hunter.
DW121-C: nemAdapt runs per commander on sector advance with the clash check preserved and contrib/opus/tools/nemesis_clash_tests.js extended to per-commander cases.
DW121-D: Weaknesses, scars, epithets and debrief lessons attach to the commander.
DW121-E: Behaviour packages unchanged.
DW121-F: Browser and Godot land together.
DW121-G: Campaign parity PASS.
DW121-H: PR checks pass.
DW121-I: (R101 addition) NEM_VOICE pasted into data.js beside NEM_LINES; re-pin both oracles; re-export tables; wire through nemSay including Eclipse fall_final key; persona reads not in the table.
Check 121-1
Kind: scenario step.
Covers: DW121-A (once-per-sector, per-commander met flag).
Harness: nem_scenarios.js pattern.
Setup: setup(seed, fac) with a seed giving three distinct hunters.
Steps:
Advance to sector 1. Trigger nemNodeIs (campaign_run.js:290) at a battle node. Record state("s1_meeting_pre"). The met flag for the SP1 commander should be unset (or < RUN.sector).
Resolve the meeting (win or lose; use a win for simplicity). Record state("s1_meeting_post"). The SP1 commander's met flag should now equal RUN.sector (campaign_run.js:306, nemAfterBattle sets N.met = RUN.sector).
Attempt a second meeting in sector 1: advance to another battle node and call nemNodeIs.
state("s1_second_node"): nemNodeIs returns false. (Exact: nemNodeIs at campaign_run.js:290 returns false if N.met >= RUN.sector; now per-commander, the active commander's met flag blocks the second meeting.)
Advance to sector 2. The active commander changes to registry[RUN.nemAssign[1]]. nemNodeIs should return true at a battle node because the SP2 commander's met flag is unset, even though the SP1 commander's met flag is set.
state("s2_meeting"): meeting proceeds with the SP2 commander.
Expected result: exactly one meeting per sector per commander. The met flag is per-commander, not global.
Check 121-2
Kind: scenario step.
Covers: DW121-B (run-level clock, beh.clock pacing).
Harness: nem_scenarios.js pattern.
Setup: setup(seed, fac) where the SP1 hunter is Eclipse (beh.clock = 0.5, from NEM_FAC at data.js:461) and the SP2 hunter is Crusade (beh.clock = 1.5). Use a seed that produces this assignment, or note "not named in the pack" if no forcing mechanism exists and rely on seed search.
Steps:
At sector 1 (Eclipse active), call nemClockAdd (campaign_run.js:280) with a base step of 1. Record N.clock.
state("s1_clock_step1"): N.clock should advance by 1 * 0.5 = 0.5, clamped to NEM_CLOCK = 4 (data.js:428), half-step rounding per campaign_run.js:280. Expected N.clock = 0.5. (Derived: 1 * 0.5 = 0.5.)
Call nemClockAdd again with step 1. N.clock = 1.0. Repeat until N.clock = 4.0. That takes 8 calls of step 1. (Derived: 4.0 / 0.5 = 8.)
At sector 2 (Crusade active), call nemClockAdd with step 1.
state("s2_clock_step1"): N.clock advances by 1 * 1.5 = 1.5. (Derived.) Half-step rounding: 1.5 is already a half-step multiple.
Expected result: clock pacing scales by the active commander's beh.clock. The clock is a single run-level value (NEM_CLOCK = 4, exact from data.js:428), not per-commander. R85 Q5: "one run-level clock paced by the active commander." Exact.
Check 121-3
Kind: scenario step.
Covers: DW121-B (strike brings meeting forward, does not change hunter).
Harness: nem_scenarios.js pattern.
Setup: setup(seed, fac). Record RUN.nemAssign.
Steps:
At sector 1, advance the clock to full (N.clock = NEM_CLOCK = 4) without meeting the commander. nemClockAdd at campaign_run.js:280 should set strike and call nemStrike (campaign_run.js:283) when N.clock is full, met < sector, and no strike pending.
state("s1_strike"): strike is set. The assigned hunter for sector 1 is unchanged: RUN.nemAssign[0] is the same value as before.
Advance to a battle node. nemNodeIs returns true because strike is pending (campaign_run.js:290: "true if a strike is pending").
Resolve the meeting. nemAfterBattle (campaign_run.js:306) clears strike, resets clock to 0, sets met.
state("s1_post_strike_meeting"): strike cleared, clock = 0, met = RUN.sector. The hunter is still RUN.nemAssign[0]. No extra meeting was created; the strike brought the existing meeting forward. (Exact: synthesis section 2, "A strike brings the sector's assigned meeting forward inside the sector; it never changes the hunter and never creates an extra meeting.")
Expected result: hunter unchanged, one meeting only, strike mechanism works.
Check 121-4
Kind: scenario step.
Covers: DW121-C (nemAdapt per commander, clash check).
Harness: nem_scenarios.js pattern plus contrib/opus/tools/nemesis_clash_tests.js.
Steps (nemesis_clash_tests.js extension):
The existing clash tests verify that an adaptation may not directly counter a REVEALED weakness (campaign_run.js:294, clash check). Extend to per-commander cases:
Case A: commander X has revealed weakness 'slow'. Attempt nemAdapt for commander X. Any adaptation that counters 'slow' (i.e. 'swift' per the clash map at campaign_run.js:252: slow counters swift) must be blocked.
Case B: commander Y (a different registry entry) has NOT revealed 'slow'. nemAdapt for commander Y may select 'swift'. The clash check runs against commander Y's own revealed set only.
Case C: commander X has revealed weakness 'board'. Adaptation 'boarders' is blocked for X (board counters boarders). Commander Y with no revealed weaknesses can still get 'boarders'.
Expected result: clash check is per-commander, reading only that commander's revealed set. (Exact: synthesis section 4, "the check is not duplicated into telemetry"; issue 121 Done-when, "the clash check preserved and contrib/opus/tools/nemesis_clash_tests.js extended to per-commander cases.")
Check 121-5
Kind: scenario step.
Covers: DW121-C (nemAdapt on sector advance).
Harness: nem_scenarios.js pattern.
Steps:
At sector 1, resolve a meeting. Advance to sector 2. nemAdapt (campaign_run.js:294) should fire for the SP2 commander on sector advance. Record the SP2 commander's adapt list.
state("s2_adapt"): the SP2 commander's adapt list has grown by one entry (or zero if the cap formula blocks it; the cap at campaign_run.js:294 uses RUN.sector and, for fast adapters, beaten + scars). The SP1 commander's adapt list is unchanged.
Expected result: nemAdapt runs per commander, keyed to the active commander on sector advance. The Chorus adaptFast behaviour (also after every meeting) is unchanged. (Exact: synthesis section 4.)
Check 121-6
Kind: scenario step.
Covers: DW121-D (weaknesses, scars, epithets, debrief lessons per commander).
Harness: nem_scenarios.js pattern.
Steps:
Sector 1: meet commander A. Lose the meeting. nemAfterBattle (campaign_run.js:306) on a loss: clock set to 1, gloat set, found weaknesses merged. The debrief teaching (lost meeting teaches a weakness) attaches to commander A.
state("s1_loss"): commander A's weaknesses list has the taught weakness. Commander B (SP2) does not.
Sector 2: meet commander B. Win. Commander B flees. nemScar (campaign_run.js:304) adds scar 'fled'. Signature 'flee' via nemSignature (campaign_run.js:273).
state("s2_flee"): commander B has scars = ['fled']. Commander A's scars are unchanged.
Sector 3: if commander A returns (RUN.nemAssign[2] == RUN.nemAssign[0]), commander A carries scars from sector 1 if any were earned.
Expected result: all state (weaknesses, scars, epithets, lessons) is per-commander in the registry, not on a single RUN.nem. (Exact: synthesis section 2, "State attaches per commander, not per run.")
Check 121-7
Kind: scenario step.
Covers: DW121-E (behaviour packages unchanged).
Harness: nem_scenarios.js pattern. Replay the existing scenarios.
Steps: run every existing scenario in nem_scenarios.js under the redesigned code:
Eclipse sector 2 scar, sector 3 revive, sector 3 death.
Corsair tow/flee/loot return.
Glasswright flee and honed.
Chorus feeding cap and fast adaptation.
Crusade adaptation counter after a lance loss.
Weakness discovery merge.
Pronoun swaps.
Every faction's warning line at clock 3 plus the tithe.
Lost meeting teaching a weakness.
Pre-persona old save (scenario 8).
Expected result: all scenario invariants hold. Exact canonical lines may need re-pinning due to the RNG stream shift (trap: RNG stream coupling), but the behavioural invariants (revive once, death in sector 3, feeding cap at 8 with hull bonus per campaign_run.js:306 and nemPanel at :72, Eclipse never retreats, Chorus adaptFast) must hold unchanged. The six NEM_FAC[fac].beh packages (data.js:461) are byte-identical before and after. (Exact: synthesis section 4, "Behaviour packages unchanged"; issue 121 Done-when.)
Check 121-8
Kind: text.
Covers: DW121-I (NEM_VOICE in data.js, nemSay wiring, Eclipse fall_final).
Harness: direct inspection of data.js after the build. One-time script to validate structure (agent terms: single script, per-run seconds).
Steps:
(a) Confirm NEM_VOICE is present in data.js beside NEM_LINES (data.js:490). Exact location: adjacent to NEM_LINES. (Exact: R101, issue 121 Done-when.)
(b) Confirm NEM_VOICE is keyed by faction, then by persona. Each persona has meet, win, flee, fall (arrays), again and remember (single strings with {beat} placeholder). Per-faction adapt lines keyed by adaptation name (shields, pd, armor, evasion, aim, special). Per-faction lessons keyed by weakness. (Exact: pack section 6, NEM_VOICE description.)
(c) Confirm Eclipse's flee array is empty. (Exact: "Eclipse never retreats (flee is empty)".)
(d) Confirm Eclipse's fall has two sub-keys: fall (destroyed early; the copy reassembles) and fall_final (destroyed in the last sector; rises once more for one final fight). (Exact: pack section 6.)
(e) Confirm Chorus lines contain no gendered pronouns (no he, she, him, her, his, hers in any Chorus line) and no song or choir words. (Exact: R101 pick, pack section 6: "Chorus lines carry no gendered pronouns and no song or choir words.")
(f) Confirm no persona read text appears in NEM_VOICE. (Exact: R101, "persona reads stay OUT of the table.")
(g) Confirm all text is single-quoted, unquoted keys, ASCII only, data.js style. (Exact: pack section 6, table header rules.)
(h) Confirm {beat} placeholder is present in again and remember lines. (Exact: pack section 6.)
Expected result: all structural and content checks pass.
Check 121-9
Kind: text (nemSay wiring).
Covers: DW121-I (nemSay wiring including Eclipse fall_final).
Harness: nem_scenarios.js pattern, extended with NEM_VOICE lines.
Steps:
(a) Trigger a meeting with a male-gendered commander. Call nemSay (campaign_run.js:269) on a NEM_VOICE line containing 'he', 'his', 'him'. Record output.
state("nemsay_male"): pronouns unchanged (nemSay swaps pronouns only for non-male; male or unset returns text unchanged, exact from campaign_run.js:269).
(b) Trigger a meeting with a female-gendered commander (if the identity logic can produce one; nemGender at campaign_run.js:267). Call nemSay on the same line.
state("nemsay_female"): 'he' swapped to 'she', 'his' to 'her', 'him' to 'her', capitalised forms likewise. (Exact: nemSay swaps pronouns.)
(c) Call nemSay on a Chorus line. Assert: output is identical to input (no pronouns to swap, since Chorus lines carry none).
(d) Trigger Eclipse fall_final. Confirm the line is drawn from NEM_VOICE.eclipse.<persona>.fall_final and spoken through nemSay. (Exact: R101, "wire it through nemSay, including the Eclipse fall_final key.")
(e) Confirm adaptation lines are spoken through nemSay. (Exact: R101, "adaptation lines spoken through nemSay.")
(f) Confirm lesson lines are pronoun-free (no nemSay swap needed; verify the raw text has no gendered pronouns). (Exact: R101, "lessons pronoun-free.")
Expected result: nemSay correctly processes NEM_VOICE lines. Eclipse fall_final is reachable and wired.
Check 121-10
Kind: parity/process.
Covers: DW121-F, DW121-G, DW121-H, DW121-I (oracle re-pin, table re-export).
Harness: same parity pipeline as check 120-9.
Steps:
(a) Confirm NEM_VOICE is present in data.js and mirrored in godot/campaign/campaign.gd.
(b) Re-copy oracles (campaign_run.js, data.js, core.js) into godot/campaign/test/oracle/.
(c) Run node godot/campaign/test/node/export_campaign.js.
(d) Run nem_scenarios.js and nem_scenarios.gd; compare via run_nem_scenarios.sh.
(e) Run campaign parity (compare_campaign.js, golden_campaign.js, parity_campaign.gd, parity_campaign.bat).
Expected result: all PASS, zero diff. Oracles re-pinned. Tables re-exported. (Trap: parity drift.)
================================================================
SECTION C: CHECKS FOR ISSUE 122
(telemetry, Nemesis panel, tests)
Done-when clauses:
DW122-A: nemSignature tags events with the commander's faction.
DW122-B: A run-level escape counter and a per-commander compounding counter.
DW122-C: The Nemesis panel shows the current sector's assigned hunter and, on a return, that commander's scars and lessons, with earlier commanders still readable.
DW122-D: Tests for once-per-sector meetings and telemetry.
DW122-E: Before and after captures of the Nemesis panel.
DW122-F: Browser and Godot land together.
DW122-G: Campaign parity PASS.
DW122-H: PR checks pass.
Check 122-1
Kind: scenario step.
Covers: DW122-A (nemSignature faction tag).
Harness: nem_scenarios.js pattern.
Steps:
Trigger a meeting with the SP1 commander. Cause a flee event. nemAfterBattle (campaign_run.js:306) calls nemSignature with kind 'flee'. nemSignature (campaign_run.js:273) pushes onto N.signatures (capped at 40) and emits tel('nem_signature', {fac, kind, sector}).
state("s1_sig"): record N.signatures. Assert: the last entry's fac field equals the SP1 commander's faction (RUN.nemAssign[0]). The kind is 'flee'. The sector is RUN.sector.
Trigger a second signature event with the SP2 commander (e.g. a raid event for Hullbreakers). Record.
state("s2_sig"): the new entry's fac equals RUN.nemAssign[1].
Expected result: every nemSignature event is tagged with the active commander's faction. (Exact: issue 122 Done-when, "nemSignature tags events with the commander's faction.")
Check 122-2
Kind: scenario step.
Covers: DW122-A (signature cap).
Harness: nem_scenarios.js pattern.
Steps: force 41 signature events (by scripting repeated flee/raid/duel outcomes across sectors, or by directly calling nemSignature 41 times if the harness permits; the pack does not name a direct-call harness for nemSignature, so use scripted battle outcomes).
state("sig_cap"): N.signatures.length == 40. The oldest entry was shifted out. (Exact: campaign_run.js:273, "capped at 40, oldest shifted out.")
Expected result: cap holds at 40.
Check 122-3
Kind: scenario step.
Covers: DW122-B (run-level escape counter).
Harness: nem_scenarios.js pattern.
Steps:
Sector 1: meet the SP1 commander. Win, commander flees (flagship dead before sector 3, per campaign_run.js:306: "flagship dead earlier (scar, escapes"; R49 comment at :311). Escape counter increments.
state("s1_escape"): escape counter = 1.
Sector 2: meet the SP2 commander. Win, commander flees. Escape counter increments.
state("s2_escape"): escape counter = 2.
Sector 3: meet the SP3 commander. Win, flagship dead in sector 3. Commander dies (or revives for Eclipse). Escape counter does NOT increment.
state("s3_no_escape"): escape counter = 2. (Exact: synthesis section 4, "at most two per run: SP1 and SP2.")
Expected result: escape counter is per-run, max value 2. It counts commanders who escaped, not deaths.
Check 122-4
Kind: scenario step.
Covers: DW122-B (per-commander compounding counter).
Harness: nem_scenarios.js pattern.
Steps: use a Chorus hunter (Chorus growth is the named example, synthesis section 4). Chorus grows from the player's losses anywhere (NEM_FAC at data.js:461, beh package).
Trigger two player losses in sectors where Chorus is the active commander. Record the Chorus commander's compounding counter after each.
state("chorus_compound_1"): counter = 1 (or the initial increment value; the exact increment is "not named in the pack" beyond "compounding counter is per commander").
state("chorus_compound_2"): counter = 2 (or doubled, depending on the compounding rule; the pack says "compounding" but does not specify the formula; mark INFERRED if a specific value is needed).
Trigger a player loss in a sector where a different commander is active. The Chorus commander's compounding counter does not change (it is per-commander, not global). However, Chorus beh "grows from the player's losses anywhere" (data.js:461) may mean the growth triggers regardless of active commander. The pack says the compounding counter is per-commander where the behaviour is commander-specific. INFERRED: the Chorus growth counter increments on any player loss (per the beh package), but the counter is stored on the Chorus commander's registry entry, not on a global field.
Expected result: the compounding counter is stored per-commander in the registry. It is not merged with the run-level escape counter. (Exact: synthesis section 4, "The two counters are not merged.")
Check 122-5
Kind: scenario step.
Covers: DW122-C (Nemesis panel, current hunter, return display, earlier commanders).
Harness: nem_scenarios.js pattern, extended to capture nemPanel (campaign_run.js:72) output.
Steps:
Sector 1: meet SP1 commander. Record nemPanel output.
state("panel_s1"): panel shows the SP1 commander's name, title, faction, traits, weaknesses (revealed named, unrevealed as 'unknown'), adaptations, clock dots against NEM_CLOCK = 4, last_beat memory line, behaviour lines. (Exact: nemPanel at campaign_run.js:72 renders these fields.)
Sector 2: meet SP2 commander. Record nemPanel.
state("panel_s2"): panel now shows the SP2 commander as the current sector's assigned hunter. The SP1 commander is still readable (earlier commanders accessible). (Exact: issue 122 Done-when, "earlier commanders still readable.")
Sector 3: if SP1 returns (RUN.nemAssign[2] == RUN.nemAssign[0]), record nemPanel.
state("panel_s3_return"): panel shows the SP1 commander with scars and lessons from sector 1. (Exact: issue 122 Done-when, "on a return, that commander's scars and lessons.")
Expected result: panel correctly displays current hunter, return state, and earlier commanders.
Check 122-6
Kind: scenario step (before/after capture).
Covers: DW122-E.
Harness: nem_scenarios.js pattern.
Steps:
Before any meeting: capture nemPanel output (state "panel_before").
After sector 1 meeting: capture (state "panel_after_s1").
After sector 2 meeting: capture (state "panel_after_s2").
After sector 3 meeting or finale: capture (state "panel_after_s3").
Expected result: the before capture shows no meeting data (no adaptations, no scars, no met history). Each after capture shows the accumulated state. These captures serve as the before/after evidence required by the Done-when. The exact content depends on the seed; state the invariant: each successive capture contains all information from the prior capture plus new sector data.
Check 122-7
Kind: scenario step.
Covers: DW122-D (tests for once-per-sector meetings).
Harness: nem_scenarios.js pattern. This check verifies that issue 122's own test suite includes the once-per-sector meeting test. Since issue 122 delivers tests, this check validates those tests exist and pass.
Steps: run the tests delivered by issue 122 (these are the "tests for once-per-sector meetings" in the Done-when). The tests should be in the nem_scenarios.js pattern or an extension.
Expected result: the delivered tests pass. They verify: (a) nemNodeIs returns false for a second meeting attempt in the same sector with the same active commander; (b) nemNodeIs returns true in a new sector for a new commander; (c) the per-commander met flag is what enforces this, not a global flag. (Exact: issue 122 Done-when, "tests for once-per-sector meetings.")
Check 122-8
Kind: scenario step.
Covers: DW122-D (tests for telemetry).
Harness: nem_scenarios.js pattern.
Steps: run the telemetry tests delivered by issue 122. They should verify: (a) nemSignature events carry the correct faction tag; (b) the signature cap at 40 holds; (c) the escape counter increments correctly; (d) the compounding counter is per-commander.
Expected result: all delivered telemetry tests pass. (Exact: issue 122 Done-when, "tests for ... telemetry.")
Check 122-9
Kind: parity/process.
Covers: DW122-F, DW122-G, DW122-H.
Harness: same parity pipeline as checks 120-9 and 121-10.
Steps: (a) mirror in campaign.gd; (b) re-copy oracles; (c) re-export tables; (d) run nem_scenarios.js / nem_scenarios.gd comparison; (e) run campaign parity.
Expected result: all PASS, zero diff.
================================================================
SECTION D: COVERAGE NOTES
All Done-when clauses for issues 120, 121, and 122 are covered by at least one check above. Two notes:
DW120-H, DW121-H, DW122-H ("PR checks pass"): these are process gates, not behavioural checks. Checks 120-9, 121-10, 122-9 include them as part of the parity/process step, but the actual PR check suite is whatever the repo's CI runs. The pack does not name the specific CI checks beyond "PR checks pass." If the CI configuration is not named in the pack, the exact list of PR checks is "not named in the pack."
DW122-C ("earlier commanders still readable"): the nemPanel function at campaign_run.js:72 currently renders only RUN.nem (a single commander). The redesign must extend it to render multiple registry entries. The check (122-5) verifies the output, but the exact UI mechanism for reading earlier commanders (scroll, tab, list) is not specified in the pack. The check verifies data presence, not UI layout.
The compounding counter formula for Chorus growth is not specified beyond "compounding" and "grows from the player's losses anywhere." Check 122-4 marks the specific increment value as INFERRED. If the build implements a specific formula, the check should be updated to the exact value from the code.
================================================================
SECTION E: GAPS AND CONFLICTS
Gap 1: RUN.nemAssign field name.
The synthesis section 1 says the name RUN.nemAssign is "suggested; Opus owns the final field name." Issue 120's Done-when uses RUN.nemAssign. If the build uses a different name, every check referencing RUN.nemAssign must be updated. This is not a conflict but a dependency. No edit proposed; the checks use RUN.nemAssign as written in the issue text and note the dependency.
Gap 2: Sector vs story point indexing.
The assignment is indexed by story point (RUN.nemAssign[0], [1], [2] for SP1, SP2, SP3). The met flag, clock, and nemAfterBattle key off RUN.sector (campaign_run.js:290, :306). The synthesis says "the active commander for sector k is the registry entry for RUN.nemAssign[k-1]." This implies a 1-to-1 mapping between sector number and story point index. If sectors and story points can diverge (e.g. optional sectors, side sectors), the mapping breaks. The pack does not describe any such divergence, so the checks assume sector k maps to story point k. No conflict found under the pack's stated facts, but flagged as a fragility. No edit proposed since the pack's facts do not describe the divergence.
Gap 3: Chorus compounding vs beh package.
The synthesis section 4 says "Chorus grows from the player's losses anywhere" and the compounding counter is per-commander. But the beh package for Chorus (NEM_FAC, data.js:461) already defines the growth behaviour. Issue 122 says the compounding counter is per-commander "where the behaviour is commander-specific (Chorus growth is the named example)." If Chorus growth triggers on losses anywhere (not just in Chorus's sector), the counter increments even when Chorus is not the active commander. The counter is stored on the Chorus registry entry. This is consistent but subtle. No conflict; no edit needed.
Gap 4: Eclipse fall_final and revive interaction.
Eclipse's beh package includes "returns once after death in sector 3 only" (synthesis section 4, behaviour packages). NEM_VOICE gives Eclipse a fall_final key for "destroyed in the last sector; rises once more for one final fight." The existing revive logic at campaign_run.js:306 handles "flagship dead in sector 3 or later with revive behaviour and not yet revived (revive once, N.met set back to sector - 1)." The fall_final voice line should play on the second death (after revive), not the first. The pack does not explicitly state which code path triggers fall_final vs fall. INFERRED: fall_final is triggered on the second flagship death in sector 3 (after the revive), and fall is triggered on a flagship death before sector 3 or on the first sector-3 death before revive. If the build wires fall_final to the wrong event, check 121-9(d) would catch it only if the scenario reaches the second death. I note this as a potential ambiguity but not a conflict with the pack's text. No edit proposed; the check covers the wiring.
Gap 5: nemReveal per commander.
nemReveal at campaign_run.js:271 "reveals the first unrevealed weakness on the active single commander." Under the redesign, it must reveal on the active commander resolved from the assignment. The issue 121 Done-when does not explicitly mention nemReveal, but it is part of the meeting flow (weakness discovery merge scenario in nem_scenarios.js). Check 121-6 covers weakness attachment. No gap; the existing scenario covers it.
No conflicts found between the three issues, the design synthesis, and the rulings R85, R101, R106. The issues are consistent with the rulings and the synthesis as stated in the pack.
================================================================
SECTION F: TRAPS
Trap 1: RNG stream coupling.
Caught by: check 120-3 (explicitly distinguishes stream shift from behaviour change), check 121-7 (replays existing scenarios, separates invariants from canonical lines), checks 120-9, 121-10, 122-9 (re-pin oracles and goldens as an explicit step).
Design: check 120-3 runs the same seed before and after, expects RNG_S to differ but invariants to hold. Check 121-7 requires that behavioural invariants (revive once, feeding cap, Eclipse never retreats) hold even when exact canonJ lines are re-pinned.
Trap 2: Lazy creation order.
Caught by: check 120-4 (asserts registry is empty or minimal at run start, commanders appear only when their faction is first drawn).
Design: the check records registry state at run_start and at each meeting, verifying no pre-creation.
Trap 3: The draw itself (SP3 excludes only SP2, not SP1).
Caught by: check 120-10 (directly measures the SP1 return rate; an implementation that excludes both previous hunters at SP3 would produce a return rate of 0 instead of 1/4).
Design: the check counts H3 == H1 directly over 120,000 runs and asserts the rate is 0.25 +/- 0.01.
Trap 4: Sector vs story point indexing.
Caught by: check 120-6 (verifies the active commander at sector k is registry[RUN.nemAssign[k-1]]).
Design: the check explicitly steps through sectors 1, 2, 3 and asserts the mapping.
Trap 5: Old saves.
Caught by: checks 120-7 (mid-run save migration) and 120-8 (pre-persona save, scenario 8 regression).
Design: 120-7 constructs an old-shape save with specific NEM_CARRY values and verifies they survive migration. 120-8 replays the existing scenario 8.
Trap 6: Parity drift.
Caught by: checks 120-9, 121-10, 122-9 (all include explicit oracle re-copy and table re-export steps, and run the Godot twin comparison).
Design: the checks make re-copy and re-export explicit steps, not assumed.
Trap 7: Text (nemSay pronoun swap, Chorus constraints, Eclipse flee).
Caught by: checks 121-8 (structural validation of NEM_VOICE) and 121-9 (nemSay wiring).
Design: 121-8 asserts Eclipse flee is empty, Chorus lines have no gendered pronouns and no song/choir words, persona reads are absent. 121-9 asserts nemSay handles male/female correctly and Chorus lines pass through unchanged.
Additional trap found: Eclipse fall_final vs fall ambiguity.
Caught by: check 121-9(d), which triggers the Eclipse fall_final path and verifies the correct key is drawn. If the code triggers fall_final on the first sector-3 death instead of the second (post-revive), the voice line will be wrong. The check should script both the first death (revive) and the second death (final) and verify fall plays on the first and fall_final on the second. INFERRED: this sequencing is the intended behaviour based on the NEM_VOICE description.
================================================================
SECTION G: OWNER QUESTIONS (at most three)
Question 1: Registry creation timing.
The pack says commanders are "created lazily when that faction is first drawn" (synthesis section 2). Does "first drawn" mean at run start when RUN.nemAssign is generated, or at the first meeting in that commander's sector? If at run start, all three identities consume RNG immediately and the RNG stream shift is fixed. If at first meeting, identity RNG consumption is deferred and depends on sector progression.
Pick: at first meeting (true lazy creation). This matches the pack's emphasis on lazy creation and the trap warning about lazy creation order.
Cost of the other option: if creation is at run start, checks 120-4 must be rewritten to expect all three registry entries at run_start. The RNG stream shift is deterministic and simpler to re-pin, but the lazy-creation invariant check is lost. Agent cost: one check rewrite, per-run seconds.
Question 2: Chorus compounding trigger scope.
The pack says Chorus "grows from the player's losses anywhere" (synthesis section 4) and the compounding counter is per-commander (synthesis section 4). Does the Chorus growth counter increment on every player loss in the run, or only on losses in sectors where Chorus is the active commander?
Pick: every player loss in the run (matches "anywhere" in the beh description). The counter is stored on the Chorus registry entry.
Cost of the other option: if the counter increments only in Chorus-active sectors, check 122-4 must be rewritten to remove the cross-sector loss test. The beh package description would need a clarification note. Agent cost: one check rewrite and one synthesis annotation, per-run seconds.
Question 3: Panel display of earlier commanders.
Issue 122 says "earlier commanders still readable" in the Nemesis panel. The current nemPanel (campaign_run.js:72) renders a single commander. The pack does not specify the UI mechanism for reading earlier commanders (list, tabs, scroll). Should the check verify only data presence (all commanders' data is in the panel's data model), or also the rendering mechanism?
Pick: data presence only. The check verifies that the panel's data model includes all registry entries and that the current sector's hunter is displayed. The rendering mechanism is a UI detail not specified in the pack.
Cost of the other option: if the check must verify a specific rendering mechanism, the pack must name that mechanism. Without it, the check would assert something "not named in the pack." Agent cost: one additional UI inspection step per panel capture, per-run seconds.
END OF REPORT
