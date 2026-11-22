---
name: playtest-and-balance
description: Use after any Voidsworn rules, balance, pacing or content change (godot/rules, godot/campaign and their table files). Runs the standing checks and the Godot rules checks against the saved results, then the balance sims, and reports only the deltas with the mode that produced them. Points at the PC job rules for heavy runs.
---

# Playtest and balance

Godot is the only rules source (R405, RULEBOOK 3.1). The root browser files (data.js, core.js, battle.js, campaign files)
are frozen history: never change them, except a ship's weapon list or hull entry until issue 1667 lands.

## Fast checks (cloud, every change)
1. `node contrib/opus/tools/run_all_checks.js --jobs 4`: no new FAIL (rows that need pwsh SKIP or fail in a container
   without it; CI runs them).
2. `GODOT=godot sh godot/rules/test/run_parity.sh`: every battle against the saved Godot results. An intended change fails
   by battle name; read `changed-battles.txt`, then update the saved results in the same pull request
   (`godot/rules/test/saved/README.md`) and say why each battle moved.
3. `GODOT=godot sh godot/campaign/test/run_campaign_checks.sh 1 30`: the 30 seeded campaign runs and the Nemesis
   scenarios against their saved results; after a reviewed change, `node godot/campaign/test/node/saved_campaign.js update 1 30`.
4. After editing `godot/rules/data/tables.json` or `godot/campaign/data/campaign_tables.json`, reseal their checksums:
   `godot --headless --path godot --script res://rules/tools/reseal_tables.gd`.
5. No em dashes in what you wrote (`node contrib/opus/tools/check_em_dashes.js`).

## Sims
- The balance sim `node sim3d.js <mode>` plays the frozen browser rules, so it measures nothing added since R405. Until its
  Godot port lands (issue 1656), say so in any balance report and do not present its numbers as the new rules.
- Modes: `campaign` (win rate, rounds, hull left, ships lost and waits per sector and kind; `real` timing model, FINDINGS
  S8), `bossmatrix N` (`BS=2` or `BS=3` for later sectors), `archmatrix`, `fmatrix`, `matrix`, `shipcount`, `fuzz N`
  (crash test; must show 0 exceptions). Big runs go to the PC.
- Baseline: `contrib/opus/compute/balance_reference.md` and its CSVs (`python3 contrib/opus/tools/mega_report.py`).

## Report
Only deltas against the baseline, in a table: cell, before, after, the mode and sample size. Flag exit criteria: no admiral
below 50% or above 90% against a sector 1 flagship; waits reported as the worst case per round (R64, RULEBOOK 7.3); no
crashes. Rules and outcomes must not change when only presentation time changes.

## Playtest
Ryan's own run is the exit. Give him a short list of what to feel for, and record what he says in FINDINGS.

## Heavy jobs on Ryan's PC
Helper threads never drive the PC: write a proof bat from `tools/pc/jobs/opus_job_template.bat` and send its path to the
Board, which queues it (R334; how: `docs/playbooks/pc.md`; rules: RULEBOOK section 3). GPU captures wait for green checks
and a passed review (R407, RULEBOOK 3.12). Results come back on the private relay repo (RULEBOOK 3.3a, after PR 1672).
