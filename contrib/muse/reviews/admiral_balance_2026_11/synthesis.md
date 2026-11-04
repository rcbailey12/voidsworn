# Admiral balance: 200-run Monte Carlo with per-admiral splits (issue #125)

Chair synthesis. Legs: legs/deepseek.md and legs/qwen.md (readers), legs/rey_leg.md (blind Rey reader, run per the owner's standing instruction of 2026-11-03), legs/argon_review.md (Argon review and ideas only, largely screened; see section 8). Raw runner output: sim_results.md. No data.js edits were made or are made by this document; every proposed change is an owner question in section 6.

## 1. Verdict

GO. The run the issue asked for is done and verified: 200 runs per faction, 50 per admiral, veteran AI, baseline bot, fresh profile, on main at cad86f04, the same code as the issue #87 re-check. Exactly two admirals clear the outlier test, both Sunward Crusade: Ashgrove below her faction and Thale above his. Every faction-level movement against the earlier baselines is inside the noise of those baselines. Four owner questions follow (two per outlier), with chair picks.

## 2. Method and verification (chair)

The runner writes its output file only when a run completes. The chair's first combined launch died instantly on an output path outside the repo folder; the relaunch died after two factions with no file written. The delivered numbers come from a third run: six per-faction invocations with identical settings (node contrib/opus/tools/run_montecarlo.js --runs 200 --seed 1 --faction <id>), each writing its own file, run detached so the session could not reap it. Total: 1,200 runs, driver errors 0, battle timeouts 13.

Equivalence check (chair): after the per-faction runs, the chair re-ran seeds 1 to 50 for Crusade and Hegemony as single-faction 50-run passes. They reproduce issue #87's 50-run numbers exactly (Crusade 64.0, Hegemony 70.0), so the per-faction invocation measures the same thing the combined invocation measured in #87, and #87's sample is the seed 1 to 50 subset of this one. That makes the fresh-sample rates over seeds 51 to 200 computable: Hegemony 58.0, Glasswrights 58.7, Hullbreakers 70.0, Eclipse 66.7.

Timeouts: the runner counts timeouts per battle across all battles in all runs (run_montecarlo.js:119) and counts wins per run independently, so a timeout is not scored as a lost run in the runner's own accounting (INFERRED from that accounting structure; runOne internals not read). 13 timeouts across roughly 13,500 battles is a 0.1 percent battle rate. Qwen's caution that Hegemony's 5 timeouts could cost it up to 2.5 points assumes each timeout kills its run, which the accounting does not support.

## 3. Results

Faction table (200 runs each; Wilson 95 percent intervals from the runner):

| Faction | Win % | Interval | v2 (n=50) | #87 (n=50) |
| --- | --- | --- | --- | --- |
| Sunward Crusade | 64.0 | 57.1 to 70.3 | 64 | 64.0 |
| Hegemony | 61.0 | 54.1 to 67.5 | 70 | 70.0 |
| Ashfall Hullbreakers | 67.0 | 60.2 to 73.1 | 60 | 58.0 |
| The Chorus | 64.0 | 57.1 to 70.3 | 64 | 64.0 |
| The Glasswrights | 61.0 | 54.1 to 67.5 | 68 | 68.0 |
| Eclipse | 68.0 | 61.2 to 74.1 | 72 | 72.0 |

Pooled: 770 wins in 1,200 runs, 64.2 percent (descriptive only; the seed range is shared across factions). Faction spread: 7 points, down from 12 (v2) and 14 (#87).

Per-admiral table (50 runs each; full tables with sector splits are in sim_results.md): Crusade: Vex 80.0, Draven 50.0, Ashgrove 42.0, Thale 84.0. Hegemony: Kassar 74.0, Vorn 52.0, Reyes 68.0, Maren 50.0. Hullbreakers: Grax 58.0, Sable 62.0, Mott 64.0, Vesh 84.0. Chorus: Matriarch 70.0, Razormaw 74.0, Mending 58.0, Voice 54.0. Glasswrights: Tamsa 78.0, Saro 66.0, Vell 46.0, Brin 54.0. Eclipse: Nadir 84.0, Umbra 68.0, Ostrel 66.0, Seveth 54.0.

## 4. Outlier screen (unanimous across all three reader legs)

Test: an admiral is a clear outlier when their interval does not overlap their own faction's interval at all.

- Ashgrove (Crusade): 42.0, interval 29.4 to 55.8, against the faction's 57.1 to 70.3. Clear below by 1.3 points.
- Thale (Crusade): 84.0, interval 71.5 to 91.7, against 57.1 to 70.3. Clear above by 1.2 points.

No other admiral clears. Leaning near misses (overlap of about 6 points or less): Vesh high (1.6), Nadir high (2.6), Tamsa high (2.7), Vex high (3.3), Vell low (5.5), Seveth low (5.8), Draven low (6.3). Both clears are narrow, and with 24 comparisons the screen is a screen, not proof (DeepSeek's caveat, carried). What raises these two above the multiple-comparisons background is that they are the same two admirals #87 flagged on 12-run samples, now confirmed in the same direction at four times the sample, and both have a coherent kit story (section 5).

## 5. Kit drivers

Ashgrove (data.js:207; Command at data.js:214). Carrier doctrine with the family's strongest paper payoff (sqPct .4, the highest of any scramble admiral) on its frailest platform: the reliquary (data.js:66) is speed 2, evasion 0, armed with turret and flak only, escorted by one harrow and one warden. Her losses are the most front-loaded in the table: 16 of 29 in sector 1, and her average battle count (9.52) is the lowest in her faction. The scramble family comparison is decisive against a doctrine problem: Reyes 68.0, Mott 64.0, Matriarch 70.0, Tamsa 78.0, Ashgrove 42.0. She dies before the squadron engine pays. This is also the starting-fleet question left open in the Job 3 balance package (recomposition versus accept the indirect lift); the 200-run data answers the factual half: the weakness is real and it is early.

Thale (data.js:208; Command at data.js:215). Iron doctrine (hpPct .15, shPct .1) stacked on the cathedral (data.js:67: battleship, hull 220, shields 30, armour .3), plus a warden. His 8 losses skew late (4 in sector 3) and his average battle count (12.88) is his faction's highest: a survival profile, not a snowball. The family comparison cuts the other way from Ashgrove's: Maren carries the identical passive line and the same iron Command in Hegemony and sits at 50.0; Brin, a variant, sits at 54.0. So the doctrine numbers alone do not explain Thale; the multiplier landing on the strongest hull in the game does (cathedral effective hull 253, shields 33 before the Command's refill and 40 percent hull-damage cut).

Scoping note (chair): the iron Command is a shared definition (thale, maren, and brin's variant all call cmd id iron), and scramble is shared by five admirals. Any change to a shared Command moves admirals who are not outliers. Changes on an admiral's own data.js line (starting fleet, doctrine fx) move only that admiral. The owner questions in section 6 are ordered with that in mind.

## 6. Owner questions (chair picks first)

Ashgrove, pick one or both:
- Q1 (chair pick): add one Warden to her starting fleet at data.js:207 (reliquary, harrow, warden, warden). Targets the diagnosed failure directly: sector 1 durability around the carrier. Expected shift +5 to +9 points, estimate (blind Rey leg). It also settles the open Job 3 recomposition question with data behind it.
- Q2: raise her sqHp from .25 to .35 at data.js:207. Squadron durability so the scramble payoff survives to land. Expected shift +4 to +7 points, estimate (DeepSeek +4 to +7, Qwen +4 to +6). Convergent across both writer legs, and compatible with Q1.
- Considered and not carried: raising scramble's strike bonus from +50 to +65 percent (DeepSeek's second proposal). Scramble is a shared Command across five admirals, and a bigger late payoff does not treat an early-death problem. Raising the reliquary's speed from 2 to 3 (Qwen's second proposal) is a hull-line change touching every reliquary in the game, not an admiral fix; it belongs to the ship pipeline conversation, not this one.

Thale, pick one or both:
- Q3 (chair pick): trim his passive line at data.js:208, hpPct .15 to .10 (Qwen and the blind leg converge on .10; DeepSeek proposed .12). Thale-scoped, always on, and aimed at the multiplier-on-the-biggest-hull driver. Expected shift -3 to -6 points, estimate. Optionally pair with shPct .10 to .05 (Qwen, -2 to -3, estimate) if a stronger trim is wanted.
- Q4: reduce the iron Command's hull-damage reduction from 40 to 30 percent at data.js:215. Expected shift -2 to -8 points, estimate (the legs disagree on size: DeepSeek -5 to -8, blind leg -2 to -4). Carried second because iron is shared: this also nerfs Maren (50.0) and Brin (54.0), who are inside their factions' bands, unless Opus scopes the Command per admiral first.

All expected shifts are leg estimates from interval widths and family spacing, not measurements. If the owner prefers evidence over estimates, the cheap confirmation is a targeted rerun of Crusade only at 200 runs per admiral after any change, using the same harness.

## 7. Faction movement and watch list

Faction movement is noise, unanimously. Every difference interval against the 50-run baselines contains zero (DeepSeek's computation, Argon-verified), the code is unchanged from #87, and the fresh-sample rates over seeds 51 to 200 (Hegemony 58.0, Hullbreakers 70.0) show the movement is sample composition, not drift. Hullbreakers' rise is mostly Vesh: the other three average 61.3, on the old baseline. No faction changes are proposed. If the owner wants the faction question settled rather than bounded, a disjoint-seed block (seeds 201 to 400) pooled to 400 per faction is the follow-up; it is not a blocker for the admiral questions.

Watch list for the next scheduled re-check (issue #87's watch-note discipline): Vesh, Nadir, and Tamsa leaning high; Vell leaning low with the table's highest sector 2 death count (15); and the R77 tension the blind leg surfaced: free starter Vex at 80.0 sits above paid Draven (50.0) and Ashgrove (42.0) in the same faction, which is exactly the cheap-and-stylish failure mode the owner priced admirals to avoid. Crusade's internal spread is 42 points against a 7-point faction spread; treat Crusade admiral-by-admiral, not as a faction, until Q1 to Q4 land.

## 8. Screening notes

Argon's review is filed with a chair header and used only in part: its arithmetic verifications of the reader legs check out, but it repeatedly describes four factions and 20 admiral screens (this job has six and 24), quotes leg text that does not exist in the filed legs, and reports an Eclipse delta with the wrong sign; its HOLD recommendation exceeds its lane and is not adopted, because the issue's done-when requires the outlier proposals to reach the owner as questions, which sections 4 to 6 do with the statistical caveats stated. One Argon catch is adopted: DeepSeek's "#87 Sable 39% over 12" cannot have n of 12 (39 percent implies 5 of 13; the 50-run rotation splits 13/13/12/12), so #87's per-admiral denominators were 12 or 13 depending on rotation order. DeepSeek's screen, drivers, and proposals are unaffected. All four legs' remaining arithmetic was spot-checked by the chair against sim_results.md.

## 9. Not checked

The Godot port's numbers (this harness drives the browser rules build, as in #87 and the v2 baseline). Human play: the baseline bot's use of scramble timing and carrier positioning is a known weak proxy for a human carrier player, which cuts toward Ashgrove being less weak in human hands, by an amount this job cannot measure. Eclipse admiral kits were not excerpted at line level in the pack; no Eclipse admiral is an outlier or a proposal target, so no line-level claim was needed. Per-seed raw outputs are not retained by the runner beyond the summary tables filed here.
