# Balance re-check, 2026-11-03 (issue #87)

Chair synthesis, Rey. Inputs: the chair's own re-run of the shipped Monte Carlo on current main, the DeepSeek and Qwen reader legs, and the Argon ideas leg. Models per the issue: Rey runs and chairs, DeepSeek and Qwen read the numbers, Argon ideas only (R81).

## Verdict: GO, no action needed

The faction spread is still in shape. Nothing that landed since balance v2 (effect caps #38, the Glasswright tree #63, shadow XP #83, the teaching gate) knocked it out. The spread moved from 12 points to 14, entirely from one flipped run in 300, and 14 is below the issue's trigger of over 15, so no data.js changes are proposed. Balance numbers are the owner's in any case.

## 1. The measurement

The chair re-ran the shipped runner on current main (HEAD 23da027) with the exact Nov 2 settings: node contrib/opus/tools/run_montecarlo.js --runs 50 --seed 1. 50 runs per faction, 300 total, seeds 1 to 50 per faction, veteran AI, baseline bot policy, fresh profile per run. Run time 442 seconds. Driver errors: 0. Battle timeouts: 4. The runner's full raw output is filed beside this report as sim_results.md.

Faction | v2 win % | Now win % | Shift | v2 deaths S1/S2/S3 | Now deaths S1/S2/S3 | Now 95% CI
Sunward Crusade | 64.0 | 64.0 | 0 | 8/8/2 | 8/8/2 | 50.1 to 75.9
Hegemony Navy | 70.0 | 70.0 | 0 | 4/10/1 | 4/10/1 | 56.2 to 80.9
Ashfall Hullbreakers | 60.0 | 58.0 | -2 (one run) | 11/5/4 | 12/5/4 | 44.2 to 70.6
The Chorus | 64.0 | 64.0 | 0 | 8/6/4 | 8/6/4 | 50.1 to 75.9
The Glasswrights | 68.0 | 68.0 | 0 | 5/10/1 | 5/10/1 | 54.2 to 79.2
Eclipse | 72.0 | 72.0 | 0 | 9/4/1 | 9/4/1 | 58.3 to 82.5
Overall | 66.3 | 66.0 | -0.3 | - | 46/43/13 | 60.5 to 71.1

Five of six factions reproduce v2 exactly, win rate and sector death split alike. The runner is deterministic per seed, so exact reproduction on unchanged code paths is expected; the size of the reproduction (299 of 300 runs with identical outcomes) is the finding: the landed changes touched almost nothing this instrument plays.

## 2. The one flipped run

Exactly one Hullbreakers run changed outcome: 30 wins became 29, and the death split moved by one sector 1 loss (11/5/4 to 12/5/4). What can be concluded: at least one Hullbreakers seed now traverses a changed code path and loses in sector 1 where it previously won. What cannot: that Hullbreakers are weaker (one run is the smallest possible nonzero shift at n of 50, and the v2 value sits well inside the new 95 percent interval, 44.2 to 70.6), or which landed change caused it. Of the four, only the effect caps alter battle mathematics, so the caps are the plausible source (a stacked effect clipped in one sector 1 fight), but that is an inference, not a trace. The filed v2 record keeps no per-seed or per-admiral output, so the flipped run cannot be isolated after the fact. This job files the runner's full output for exactly that reason; future re-checks should keep doing so.

## 3. Attribution, change by change

Effect caps (PR #38, core.js sumFx caps): the only battle-math change. No differential signature in the table. Either the caps do not bind at the effect magnitudes the baseline bot reaches, or they bind symmetrically. The one flipped run is consistent with a cap interaction and proves nothing on its own.

Glasswright tree (PR #63): no signature. Glasswrights are bit-identical to v2 (68.0, deaths 5/10/1). Two readings, both INFERRED: the in-run XP the bot earns does not reach perks that change battle outcomes under the baseline policy, or the perks it reaches are too small to move a rate at n of 50. This measurement cannot distinguish them, and it cannot see the tree's cross-run effect at all.

Shadow XP (PR #83): structurally invisible here. The driver calls defaultMeta() before every run, so cross-run shadow earnings never exist in the sample. Nothing in this table speaks for or against shadow XP's balance effect in real profiles.

Teaching gate: structurally invisible for the same reason. The driver does not enable the everything-unlocked state, so gated progression content does not appear in these numbers.

## 4. The trigger, and what to watch instead

The trigger reading is procedural and correct: spread 14, trigger over 15, not fired, no proposals. Both reader legs add the same caution, and the chair adopts it as a watch note rather than a question: at n of 50 the trigger is within one run of firing (one more Hullbreakers loss or one more Eclipse win makes 16) while every faction's interval is about plus or minus 13 points, so the trigger at this sample size measures the instrument's resolution as much as the game's balance. If a future re-check trips it on a one or two run margin, the right response is a larger run (n of 200 per faction narrows intervals to roughly plus or minus 7) before any data.js proposal.

Watch items adopted for the next re-check (from the legs, chair-filtered):
1. Hullbreakers at 56 or below next time would be a pattern (two or more further runs lost); a snap back to 60 closes the question.
2. Per-admiral splits remain far wider than the faction spread (Crusade: Thale 100.0 over 12 runs against Ashgrove 33.3 over 12; Hullbreakers: Vesh 83.3 against Sable 38.5). Small samples, but the pattern persists across both measurements; it is the widest open balance fact in the game and it is admiral-level, not faction-level.
3. Whether future lineage tree slices for the other five factions also produce a zero shift on this instrument. If they do, the fresh-profile runner cannot see tree balance at all, and a progression-enabled companion pass becomes the real instrument for tree work.
4. Battle timeouts: 4 this run. Track the count across re-checks.

## 5. Screening notes

DeepSeek leg: filed raw. Its verdict, table read, one-run analysis and trigger sections are sound and agree with Qwen's. Its section 3 attribution is SCREENED OUT: it attributes against a change list that is not the issue's (a shield-venting cap, a Hullbreakers anti-swarm change, a hull threshold change), apparently assembled from search results rather than the pack, and it omits shadow XP and the teaching gate entirely. Its per-item "no signature" conclusions are not relied on; the chair's attribution in section 3 above is written from the pack and the PR records. Its section 6 suggestion (a larger re-run before treating 14 as stable) is carried into section 4 as a conditional watch note, not an owner question.

Qwen leg: filed with its gate line. Used in full. One wording slip: its section 1 calls the flipped run "stochastic"; its own section 4 has the correct framing (deterministic per seed, changed code path), which the chair follows.

Argon leg: ideas only, filed with a chair header. Used: the one-run buffer analysis (arithmetic verified: one run is 2 points at n of 50, so the trigger margin is under one run), the sector mortality concentration note, the zero-shift signature watch for future tree slices, and the timeout count watch. Not used: its follow-up measurement designs that need runner changes (everything-unlocked and chained-profile variants). Those are real ideas but they are new instruments, not this re-check; they belong to whoever scopes the next balance pass, and the chair lists them here so they are on record: an everything-unlocked seed-for-seed diff, and a chained-profile run that lets shadow XP accrue. Its single-seed isolation idea is not executable against the filed v2 record (no per-seed v2 output exists), which is the process gap section 2 already notes.

## 6. Owner questions

None. Both reader legs state none are needed, and the chair agrees: the trigger did not fire, and balance numbers are the owner's to move only on a fired trigger or a pattern, neither of which exists here.

## Not checked

- The Godot port's balance was not measured; the runner plays the browser rules and data, with the Godot tables exported from the same source.
- Human play rates; every figure is one bot under one policy, and the absolute rate is known to be policy-sensitive even when ordering holds.
- Whether the effect caps bind anywhere in these 300 runs (no per-battle effect logging in the runner output).
- Per-admiral v2 splits (the v2 record does not carry them; this report files the full current output so the next re-check can).
- The 4 battle timeouts were not attributed to factions or sectors; the runner's summary does not expose them per run.
