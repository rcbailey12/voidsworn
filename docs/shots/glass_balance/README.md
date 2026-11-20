# Glasswright balance: more hull on every Glasswright hull (issue 1298)

Ryan's pick (Nov 20 13:43 UTC): lever (b), more hull. Then (14:21 and 14:24 UTC): "every Glasswright ship so it's
consistent, like the rest of the game" and "glasswrights aren't supposed to be a swarm faction like chorus or even
hullbreakers. A little more elite". So enemy copies get the same hull, and the identity line is in
docs/playbooks/factions.md (Glasswrights section).

## The change (data.js, exported to both Godot tables)

| Hull | Before | After | Change |
| --- | ---: | ---: | ---: |
| i_wisp, Glasswright sliver (1 CP) | 30 | 36 | +20% |
| i_blade, Glasswright lancet (2 CP) | 60 | 68 | +13% |
| i_song, Glasswright prism (4 CP) | 90 | 108 | +20% |
| i_carrier, Glasswright aperture (5 CP) | 140 | 168 | +20% |

The boss, The Unfinished (i_boss, 470), is left unchanged on purpose: it is a fight every other faction faces, not a
Glasswright fleet ship. The Sliver lancer is a variant built from the sliver, so it takes the new 36 with no override of
its own. Nothing else changes. No armour,
shields, evasion or price changed, so they stay glassy: hull per command point over the four base hulls goes from 26.7 to
31.7, still the lowest of six (field 37.6 to 47.4 in the PR 1294 table). Ships per command point do not change (no command
point cost changed). At the Veteran final boss the bot fleet has 5.0 ships and 489 total hull (before 5.2 and 430; field
595 to 830): slightly fewer, stronger ships.

The game code is unchanged: core.js derive() and campaign.gd derive() both read HULLS hp from the tables, so the parity
change is data only (godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json re-exported).

## Measured: 240 paired seeds per faction, Standard and Veteran

Seeds 1 to 240 for each faction, admirals rotated, same bot and harness as PR 1294
(`FAC=<id> node tools/late_run_1178/sim_1178.js <checkout> <standard|veteran> 240 1 <out>`). Before = main 12178c07,
after = this branch. 2,880 runs per arm, 0 driver errors; timeouts 45 before, 36 after.

The sims run the browser rules copy through Muse's driver, which sets the difficulty before the run starts, so the
Standard fleets here are Standard sized. The Godot campaign bug in issue 1336 (Standard getting Veteran-sized fleets) is
not in these numbers.


### Standard
| Faction | Win before | Win after | Change | Flips win to loss / loss to win | Losses S1/S2/S3 before | after |
| --- | ---: | ---: | ---: | --- | --- | --- |
| Crusade | 68.8% (165) | 67.5% (162) | -1.2 | 22 / 19 | 35 / 24 / 16 | 36 / 24 / 18 |
| Hegemony | 68.3% (164) | 67.9% (163) | -0.4 | 22 / 21 | 28 / 20 / 28 | 28 / 22 / 27 |
| Hullbreakers | 75.4% (181) | 76.7% (184) | 1.3 | 14 / 17 | 26 / 14 / 19 | 25 / 13 / 18 |
| Chorus | 77.1% (185) | 74.2% (178) | -2.9 | 20 / 13 | 23 / 11 / 21 | 26 / 10 / 26 |
| Glasswrights | 62.1% (149) | 68.8% (165) | 6.7 | 26 / 42 | 33 / 30 / 28 | 31 / 16 / 28 |
| Eclipse | 82.9% (199) | 81.7% (196) | -1.3 | 17 / 14 | 20 / 11 / 10 | 24 / 15 / 5 |

### Veteran
| Faction | Win before | Win after | Change | Flips win to loss / loss to win | Losses S1/S2/S3 before | after |
| --- | ---: | ---: | ---: | --- | --- | --- |
| Crusade | 33.3% (80) | 29.2% (70) | -4.2 | 27 / 17 | 95 / 41 / 24 | 103 / 41 / 26 |
| Hegemony | 30.0% (72) | 26.7% (64) | -3.3 | 29 / 21 | 92 / 48 / 28 | 90 / 64 / 22 |
| Hullbreakers | 38.3% (92) | 36.7% (88) | -1.7 | 22 / 18 | 94 / 38 / 16 | 95 / 41 / 16 |
| Chorus | 44.2% (106) | 46.3% (111) | 2.1 | 21 / 26 | 66 / 41 / 27 | 74 / 38 / 17 |
| Glasswrights | 26.7% (64) | 44.6% (107) | 17.9 | 19 / 62 | 100 / 58 / 18 | 66 / 39 / 28 |
| Eclipse | 52.9% (127) | 49.2% (118) | -3.8 | 22 / 13 | 71 / 28 / 14 | 81 / 29 / 12 |

Noise: one standard error of a 240-run rate is about 3 points; paired changes with 35 to 50 flips have about 2.5 to 3.

What it shows:
- **Glasswrights move into the field.** Veteran 26.7% to 44.6% (62 seeds turn to wins, 19 the other way), inside the 30
  to 50% target. Standard 62.1% to 68.8%: from last to fourth of six, a hair above Hegemony (67.9%) and Crusade (67.5%) and within noise
  of them, so near the bottom and not clearly separated; not overshooting.
- **The others dip a little at Veteran, as expected with tougher enemy Glasswrights** (Ryan accepted this, 14:24 UTC).
  Crusade -4.2, Eclipse -3.8, Hegemony -3.3, Hullbreakers -1.7, Chorus +2.1. Each is within about 1.5 standard errors on
  its own, but four of five lean down, so read it as a small real cost. Hegemony's Sector 2 losses rise 48 to 64.
  Crusade (29.2%) and Hegemony (26.7%) now sit just under 30% at Veteran; Hegemony was already at 30.0%. A later
  rebalance can lift them if Ryan wants (his words: "We can balance otherwise as needed").
- **Standard barely moves for the others** (-2.9 to +1.3, all within noise).

## The hull sets tried (Glasswrights only, 240 seeds, same seeds)

| Set (sliver / lancet / prism / aperture) | Veteran | Standard |
| --- | ---: | ---: |
| 30 / 60 / 90 / 140 (main) | 26.7% | 62.1% |
| 38 / 70 / 90 / 140 | 33.3% | |
| 42 / 72 / 90 / 140 | 33.3% | |
| 42 / 78 / 90 / 140 | 36.7% | |
| 42 / 78 / 108 / 168 | 53.3% (over the cap) | 76.7% |
| 38 / 70 / 100 / 154 | 45.4% | 65.0% |
| **36 / 68 / 108 / 168 (chosen)** | **44.6%** | **68.8%** |

The chosen set puts most of the gain on the big ships and keeps the small ones thinnest, which fits "a little more elite,
not a swarm". At the sliver and lancet alone (42 / 78) the other factions fell by a similar amount at Veteran (Eclipse
-5.0, Hegemony -3.7), so the enemy-side cost is not special to this set.

## Checks (cloud, Godot 4.7.2, Node 22)

- Rules parity, browser against Godot: all 284 battles PASS, seeds, math and data export PASS.
- Saved Godot results: 45 battles changed, every one's first difference a Glasswright hull value (for example prism
  90 to 108, aperture 140 to 168, sliver 30 to 36, enemy lancet 51 to 58 after scaling). Refreshed with
  `node godot/rules/test/saved/update.js`, then check.js PASS (godot/rules/test/saved/changes.txt has the list).
- Campaign parity: PASS on 30 seeds plus the cross-twin hand-off.
- Rules safety net (Godot only): PASS, ruled numbers 15 checks 0 failures.
- Check pack 0 FAIL; b1_tests 40 ok.

Rebuild: run sim_1178.js on main and on this branch for each faction and mode, then compare the paired records.
