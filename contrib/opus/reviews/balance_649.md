# Issue 681: balance check for PR 662 (issue 649), the Chorus frigate's new forward gun

Seat: kimicode (Kimi Code CLI), branch work/issue-681-kimicode. 2026-11-14.
Report only. The only file this job adds is this report; no game file was changed.

## Answer first

The new gun makes the Chorus frigate about right, on the strong side of it, and the Chorus faction moves from weak to mid. It is not too strong and not too weak. One recommendation: keep the bioplasma forward gun as PR 662 shipped it, and re-check the frigate's death rate (it fell from 83% to 65% of fieldings) at the next balance pass instead of tuning now.

Why this call:

- The frigate itself clearly improved: damage per fielding rose about 39% (40 -> 56 per battle, fmatrix) and its share of Chorus damage rose from 13% to 16%. It now contributes at range 4 instead of only at boarding range 1.
- Chorus win rates rose several points as a player faction (fmatrix row average 51.7% -> 59.8%) and fell for the player against Chorus in the two elite cells (sector 2 elite 92% -> 80%, sector 1 elite 90% -> 82%). Those sit at or just past the Board's ten point guide from R179, but they start from low baselines: Chorus was the soft faction in its pools, and the sector 2 elite cell still favors the player 4 out of 5.
- Fight length did not move: campaign rounds changed by at most half a round per cell, fmatrix battles are 0.4 rounds shorter, and no cell gained a meaningful wait.
- In the shipped mix (Chorus fields only in sector 2 and 3 pools, one of three factions each) the expected campaign impact is about one third of the forced-Chorus deltas, a few points on elite cells only. The published campaign envelope does not move.

## What PR 662 changed

`data.js` b_drone (Chorus drone-spawn, the 1 CP frigate): weapons went from `['tendril','T']` alone to `['bioplasma','F'],['tendril','T']`. The bioplasma ("Spine volley" in the Chorus name table) is 2 shots, 10 damage, range 4, accuracy 74, pierce 20%, crit 8. The frigate kept its stats (46 hull, speed 5, evasion 15, regrow 3). The Godot tables were re-exported and two parity scenario seeds moved with the new RNG stream. Baseline for every number below: main at PR 662's parent, commit 6191d04b.

## Chorus win rates by sector and difficulty (campaign cells, enemy forced to Chorus)

Driver: a byte-verified copy of the shipped `campaignSim` with the enemy faction fixed to Chorus (the one shipped line `pick(SECTOR_POOL[sec-1])` replaced) and per-hull damage tracking added; same reference fleets, bot, enemy AI and stats. 50 battles per cell, SEED=777, paired (the same battles run before and after). Player is the voidsworn reference fleet, so "player win" is the complement of the Chorus win.

| Cell | Player win before -> after | Delta | Rounds before -> after | b_drone damage per battle before -> after | b_drone share of Chorus damage |
|---|---|---|---|---|---|
| s1 battle (col 1) | 100 -> 100 | 0 | 3.3 -> 3.3 | 20 -> 20 | 33% -> 33% |
| s1 battle (col 4) | 96 -> 96 | 0 | 4.4 -> 4.6 | 36 -> 34 | 31% -> 26% |
| s1 elite | 90 -> 82 | -8 | 5.1 -> 5.4 | 26 -> 44 | 18% -> 25% |
| s1 boss | 96 -> 100 | +4 | 8.9 -> 9.2 | 12 -> 18 | 14% -> 22% |
| s2 battle (col 1) | 100 -> 100 | 0 | 4.5 -> 4.1 | 18 -> 31 | 13% -> 21% |
| s2 battle (col 4) | 100 -> 96 | -4 | 5.0 -> 5.0 | 31 -> 57 | 17% -> 24% |
| s2 elite | 92 -> 80 | -12 | 6.3 -> 6.1 | 26 -> 47 | 10% -> 17% |
| s2 boss | 98 -> 98 | 0 | 10.5 -> 10.0 | 16 -> 22 | 8% -> 11% |
| s3 battle (col 1) | 100 -> 100 | 0 | 3.9 -> 4.1 | 21 -> 31 | 11% -> 16% |
| s3 battle (col 4) | 96 -> 96 | 0 | 5.3 -> 5.8 | 42 -> 64 | 13% -> 18% |
| s3 elite | 100 -> 100 | 0 | 5.7 -> 5.9 | 43 -> 58 | 12% -> 14% |
| s3 boss | 100 -> 98 | -2 | 11.8 -> 11.7 | 18 -> 43 | 4% -> 9% |

Sample: 600 battles per side across the 12 cells (7,200 battles total in the table). With paired seeds, one flipped battle is 2 points; the -8 and -12 cells are 4 and 6 net flips, the rest are 0 to 2.

Replication on a second seed set (SEED=4242, 40 battles per cell, 960 battles per side): the frigate's damage rises again in every cell (for example s2 elite 29 -> 51, s3 battle col 4 35 -> 67). Outcome deltas are noisier: s2 elite 90 -> 85 and s3 elite 95 -> 85 repeat the direction, s1 elite flips to +8 and s1 boss to +13, the rest move 0 to 3 points. Pooled over both seeds (90 battles per side): s1 elite about even, s2 elite about -9, s3 elite about -4. The sector 2 elite cell is the one consistent mover; nothing approaches the low end of the published envelope for that node.

Reading:

- The gun works everywhere: b_drone damage per battle rises in all 12 cells, typically +40% to +90% (for example s2 elite 26 -> 47, s3 boss 18 -> 43).
- Outcomes move only where the fights are close. The reference fleet wins s1/s2/s3 battles and bosses almost always, so extra frigate damage changes nothing there. The two elite cells (the close fights) drop 8 and 12 points, and both still favor the player.
- Chorus as an enemy was the easy faction in its pools before this change (a 92% player win at s2 elite against a published mixed-pool baseline of 52% for that node). The gun narrows that gap instead of overshooting it.

## The frigate's share of damage and Chorus as a player faction (fmatrix)

Shipped `fmatrix` with FROWS=chorus (Chorus is the player faction, random Chorus admiral, 8 command point fleets, sector 2), 24 battles per enemy cell, 144 per side, SEED=777, paired.

Chorus row win rate before -> after, per enemy: voidsworn 46 -> 46, hegemony 38 -> 63, corsair 42 -> 54, chorus 63 -> 63, ithar 50 -> 75, deathless 71 -> 58. Row average 51.7 -> 59.8.

| Hull | Damage per fielding before -> after | Per command point | Death rate before -> after |
|---|---|---|---|
| b_drone (frigate, 1 CP) | 40.2 -> 56.0 (+39%) | 40.2 -> 56.0 | 83% -> 65% |
| b_spitter (2 CP) | 72.1 -> 74.4 | 36.1 -> 37.2 | 72% -> 65% |
| b_razor (3 CP) | 99.8 -> 97.8 | 33.3 -> 32.6 | 64% -> 63% |
| b_brood (5 CP) | 224.3 -> 229.5 | 44.9 -> 45.9 | 53% -> 48% |

b_drone share of all Chorus damage: 13% -> 16%. Fights: 7.76 -> 7.35 rounds per battle, 0 timeouts both sides. The +12 to +25 cells (hegemony, ithar) start from 38% and 50% baselines and land at 63% and 75%, mid table, not dominant; deathless went down 13, which reads as seed noise at 24 battles per cell.

Two things stand out for the recommendation:

- The frigate is now the best damage per command point in the Chorus roster (56 per CP, ahead of the 5 CP brood at 46). For a 1 CP hull that folds to any focused fire, that is acceptable; it is not the top of the whole table.
- The defensive gain is as big as the offensive one: the frigate dies less (83% -> 65%) because it shoots at range 4 instead of closing to range 1 to board. That survival bump, more than the damage, is what to watch.

## Fight length

Unchanged. Campaign cells moved at most half a round either way (see the table), fmatrix 0.4 rounds shorter, and the real-clock waits printed by the cells move by seconds only (for example s2 elite 74s -> 72s). The waits are presentation, not a balance target (R64, RULEBOOK 7.3), and they did not grow.

## How the change reaches the rest of the game

- Callers: no function, constant or save field was changed by this job. The gun PR 662 added is read through the normal path: `derive`/`newShip` in core.js builds the weapon list, battle.js fires it through the shared `canFire`/`fireWeapon` code, the faction weapon name table shows it as "Spine volley", and the Chorus roster entry and the four admiral start fleets that field b_drone (matriarch 2, razormaw, mending, voice) pick it up automatically. No hull variant builds on b_drone.
- Saves: b_drone weapons are not stored in saves. A profile or run save written before PR 662 stores ships as tpl plus mods, marks and captain; `derive` rebuilds the weapons from the table at load, so old saves field the frigate with both guns and need no migration. The only replay-visible effect is that seeded battle replays diverge, which is why PR 662 moved two parity scenario seeds (31713 -> 31730, 38217 -> 38234). save_fuzz, b1_tests and softlock_sweep all pass in the standing checks.
- Twins: PR 662 changed only data.js on the JS side and re-exported both tables (godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json). I changed neither root file, and the exported tables on main already carry the gun. oracle_copy_test passes in the standing checks and both parity runs pass (below).
- UI: every screen that lists ship weapons reads the same derive() on the JS side and the same campaign tables in Godot: the battle ledger card, the shipyard fleet cards and the hulls-for-sale cards. Proof shot: out/shots/b_drone_ship_card.png, captured from this checkout, shows the drone-spawn card with "Spine volley Prow 2x10, range 4" above "Boarding tendrils Turret 2x11, range 1". No screen shows a raw weapon table.
- CI: no new test file was added, so contrib/opus/tools/run_all_checks.js needs no new entry. GitHub runs the standing checks, the no-em-dash check on changed files, Godot rules parity and the Godot game checks on this PR.

## Checks run

- Sims (this job): chorus-forced campaign cells, before and after, N=50 per cell with SEED=777 and N=40 per cell with SEED=4242 (1,080 campaign battles per side in total); fmatrix chorus row, before and after, n=24 per cell with SEED=777 (144 battles per side); fuzz 200 on the after build: `fuzz 200 battles: exceptions 0, invariant breaks 0 (0 distinct), avg rounds 7.1`.
- `node contrib/opus/tools/run_all_checks.js`: every row PASS or KNOWN, no FAIL. The KNOWN rows are the seven listed findings_tests failures (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5) and the twelve baseline oracle_drift_guard differences, both present before this job.
- `PASS oracle_copy_test` (inside the pack): no oracle folders exist and both committed tables equal a fresh export from the root game files.
- `cmd.exe //c "tools\pc\parity.bat nopause`: `PASS: the Godot port matches the game's rules exactly.` (all seeded scenarios, threat overlay and thread checks included) and `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Em dash scan of this report: 0.

## What I skipped and why

- I did not re-run the full 36-cell fmatrix or the all-faction matrix. The question is the Chorus frigate; the chorus row and the campaign cells answer it, and the PC was already running other jobs, so the sims ran about six times slower than the cloud baseline. The two-seed campaign design and the paired fmatrix rows carry the load.
- I did not run the shipped `campaign` mode with the random faction mix. The job asks for Chorus win rates by sector and difficulty, which the forced-Chorus cells state directly; the shipped mix would only dilute them (Chorus is one of three factions in the sector 2 and 3 pools, absent in sector 1).
- No in-battle screenshot: this checkout has no built 3D hulls (godot/gen is generated on Ryan's PC, not committed), and the project's placeholder guard correctly refuses to save pictures of placeholder ships, on the battle map and the campaign map alike. The card shot above is the in-game UI rendered with the game's own builders.
