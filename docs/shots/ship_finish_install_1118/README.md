# Satin finish installed in the shared PC build

Issue #1044 installed the 21 approved ships from PRs 1040, 1043 and 1041 against main at `4fd5e5203173`.

- Before installation, all 147 export files matched the size and SHA-256 in main's ship manifest.
- Stage 7 installed 71 changed maps. The old maps, both manifests and 63 generated ship scenes went to `sync_old\ships_finish_install_1118`. The other 76 export files already matched main.
- `render/build_assets.gd --ships-only` rebuilt the 21 affected cache entries. The refreshed cache contains 37 A4 entries.
- The playtest check printed `MANIFEST OK` for all 255 files. The shared build's ship manifest is byte-for-byte identical to main's.
- The standing checks exited 0. The findings and oracle drift checks stayed within their recorded baselines.

## Installed-game sheets

Each sheet uses native game pixels from the shared build at battle camera radius 170. Ship codes sit below their captures, with the `installed in game` stamp in a separate footer. The Navy sheet includes its transport, beacon, fighter and bomber at their look bench sizes.

| Faction | Battle camera sheet |
| --- | --- |
| Hegemony Navy | [7 ships](navy_installed_cam170.png) |
| Ashfall Hullbreakers | [4 ships](hullbreakers_installed_cam170.png) |
| Eclipse | [4 ships](eclipse_installed_cam170.png) |
| Sunward Crusade | [6 ships](sunward_installed_cam170.png) |

## Installed ship checks

`render/test/installed_ship_check.gd` confirmed the cache matches the installed files and checked the hard point and turret nodes loaded by `ShipView`.

| Faction | Ship | Result | Nodes checked |
| --- | --- | --- | ---: |
| Hegemony Navy | `H7_23` | PASS | 10 |
| Hegemony Navy | `H8_23` | PASS | 11 |
| Hegemony Navy | `H9_23` | PASS | 12 |
| Hegemony Navy | `O2_37` | PASS | 9 |
| Hegemony Navy | `O3_11` | PASS | 5 |
| Hegemony Navy | `S1_51` | PASS | 3 |
| Hegemony Navy | `S2_23` | PASS | 6 |
| Ashfall Hullbreakers | `C13s_23` | PASS | 15 |
| Ashfall Hullbreakers | `C14s_23` | PASS | 23 |
| Ashfall Hullbreakers | `C15s_23` | PASS | 46 |
| Ashfall Hullbreakers | `C16s_23` | PASS | 27 |
| Eclipse | `D9_23` | PASS | 7 |
| Eclipse | `D20_23` | PASS | 13 |
| Eclipse | `D21_23` | PASS | 13 |
| Eclipse | `D22_23` | PASS | 17 |
| Sunward Crusade | `V14_23` | PASS | 10 |
| Sunward Crusade | `V15_37` | PASS | 11 |
| Sunward Crusade | `V16_37` | PASS | 14 |
| Sunward Crusade | `V17_37` | PASS | 19 |
| Sunward Crusade | `V18_51` | PASS | 18 |
| Sunward Crusade | `V1b_r_23` | PASS | 22 |
