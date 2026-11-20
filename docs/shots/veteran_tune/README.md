# Veteran tune: Crusade and Navy shop prices (issue 1354)

PR 1353 gave every Glasswright fleet hull more hull. Tougher enemy Glasswrights pushed Crusade to 29.2% and Hegemony to
26.7% at Veteran. The Board asked for a small tune back to about 30% or more without moving the Glasswrights (Ryan, Nov 20:
"We can balance otherwise as needed").

## The change (data.js FAC_PRICE, exported to both Godot tables)

Shop prices only, so it touches only the player's own fleet. Enemy Crusade and Navy ships are unchanged, so no other
faction's fights change.

| Shop hull | Before | After |
| --- | ---: | ---: |
| Warden frigate | 70 | 65 |
| Harrow destroyer | 130 | 125 |
| Vigil cruiser | 200 | 190 |
| Hearth carrier | 285 | 270 |
| Bastion battleship | 340 | 325 |
| Hegemony picket | 70 | 55 |
| Cordon destroyer | 130 | 105 |
| Vanguard cruiser | 250 | 200 |
| Dominion dreadnought | 370 | 295 |

Crusade 5% off (the carrier keeps its 10% premium over the others), Navy 20% off. Refits, repairs and modules are unchanged.
Captured hulls sold at the Crusade's Cinder Line yards use their original price times the Crusade multiplier, so they are
5% cheaper too.

## Measured: 240 paired seeds per faction, Standard and Veteran

Same harness as PR 1353 (`FAC=<id> node tools/late_run_1178/sim_1178.js <checkout> <standard|veteran> 240 1 <out>`).
Before = PR 1353 head 4f701b65 (no game-file change between it and main cf942f36), after = this branch. 2,880 runs, 0
driver errors, 28 timeouts (36 before). Browser rules copy; the Godot fleet-size bug in issue 1336 is not in these numbers.


### Standard
| Faction | Win before | Win after | Change | Flips win to loss / loss to win | Losses S1/S2/S3 before | after |
| --- | ---: | ---: | ---: | --- | --- | --- |
| Crusade | 67.5% (162) | 67.9% (163) | 0.4 | 11 / 12 | 36 / 24 / 18 | 36 / 22 / 19 |
| Hegemony | 67.9% (163) | 72.1% (173) | 4.2 | 14 / 24 | 28 / 22 / 27 | 26 / 15 / 26 |
| Hullbreakers | 76.7% (184) | 76.7% (184) | 0.0 | 1 / 1 | 25 / 13 / 18 | 25 / 13 / 18 |
| Chorus | 74.2% (178) | 73.8% (177) | -0.4 | 1 / 0 | 26 / 10 / 26 | 26 / 10 / 27 |
| Glasswrights | 68.8% (165) | 68.8% (165) | 0.0 | 0 / 0 | 31 / 16 / 28 | 31 / 16 / 28 |
| Eclipse | 81.7% (196) | 81.7% (196) | 0.0 | 0 / 0 | 24 / 15 / 5 | 24 / 15 / 5 |

### Veteran
| Faction | Win before | Win after | Change | Flips win to loss / loss to win | Losses S1/S2/S3 before | after |
| --- | ---: | ---: | ---: | --- | --- | --- |
| Crusade | 29.2% (70) | 32.5% (78) | 3.3 | 12 / 20 | 103 / 41 / 26 | 99 / 41 / 22 |
| Hegemony | 26.7% (64) | 35.4% (85) | 8.8 | 11 / 32 | 90 / 64 / 22 | 85 / 51 / 19 |
| Hullbreakers | 36.7% (88) | 35.8% (86) | -0.8 | 2 / 0 | 95 / 41 / 16 | 96 / 41 / 17 |
| Chorus | 46.3% (111) | 46.3% (111) | 0.0 | 0 / 0 | 74 / 38 / 17 | 74 / 38 / 17 |
| Glasswrights | 44.6% (107) | 44.6% (107) | 0.0 | 0 / 0 | 66 / 39 / 28 | 66 / 39 / 28 |
| Eclipse | 49.2% (118) | 49.2% (118) | 0.0 | 0 / 0 | 81 / 29 / 12 | 81 / 29 / 12 |

- **Both are back above 30% at Veteran.** Crusade 29.2% to 32.5% (about where it was before PR 1353, 33.3%), Hegemony 26.7%
  to 35.4% (it was 30.0%). Hegemony gains more than Crusade; at 20% off it sits mid-field beside the Hullbreakers (35.8%).
- **Glasswrights and Eclipse do not move at all** (0 flips at either difficulty). Chorus and Hullbreakers move by 1 or 2
  seeds, which is the Navy and Crusade hulls they capture and sell (prize values follow the shop price).
- **Standard:** Hegemony +4.2 (within about 1.5 standard errors), Crusade +0.4.

## Prices tried (Veteran, 240 seeds, same seeds)

| Faction | Full price (PR 1353) | 5% off | 10% off | 15% off | 20% off | 25% off |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Crusade | 29.2% | **32.5%** | 35.8% | 36.7% | | |
| Hegemony | 26.7% | | 29.2% | 30.4% | **35.4%** | 35.0% |

Navy at 15% off clears 30% by only 0.4 points, inside the noise; 20% off is the smallest cut that clears it with a margin.

## Checks (cloud, Godot 4.7.2, Node 22)

- Rules parity, browser against Godot: all 284 battles PASS ("the Godot port matches the game's rules exactly").
- Saved Godot results: PASS, 0 battles changed (battles do not read shop prices).
- Campaign parity: PASS on 30 seeds plus the cross-twin hand-off.
- Check pack 0 FAIL; b1_tests 40 ok.
