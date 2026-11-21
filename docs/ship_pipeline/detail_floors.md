# Surface-detail floors per faction (issue 1517, Nov 21 2026)

Stage 5's detail check (tools/recipe/detail_check.py) measures three numbers over a ship's outside skin: every hull-role
object on the hull atlas (the skin and every plate, rib and armour shell painted there) and the Chorus soft flesh on the parts
atlas. Guns, engines, glow and insides do not count. Every atlas is read at 1024 px whatever the bake size.

- **normal**: relief in the detail normal map (mean degrees from the local average): rivets, seams, wrinkles, pores.
- **albedo**: the colour's local contrast (mean luminance difference from the local average, over mean luminance).
- **rough**: the roughness map's spread (standard deviation).

A ship fails when any number is under its faction's floor. Every faction is gated (until Nov 21 only Chorus was).

## The floors

| Faction | normal | albedo | rough | Set from |
|---|---|---|---|---|
| Chorus (`chorus`) | 3.5 | 0.04 | 0.08 | unchanged from issue 1291 (round G C10, C12 pass at 5.2 / 0.17 / 0.25) |
| Sunward (`voidsworn`) | 1.3 | 0.30 | 0.12 | S8, S9, S10, S11 accepted: least 1.56 / 0.39 / 0.16 |
| Navy (`hegemony`) | 0.6 | 0.20 | 0.10 | H10, IM5 accepted: least 1.12 / 0.24 / 0.13 (cloud bakes) |
| Hullbreakers (`hullbreakers`) | 0.6 | 0.30 | 0.12 | A18, A19 accepted: least 1.00 / 0.51 / 0.28 (cloud bakes) |
| Eclipse (`eclipse`) | 0.6 | 0.30 | 0.10 | E11: 1.06 / 0.62 / 0.15 (cloud bake) |
| Glasswrights (`ithar`) | 0.1 | 0.15 | 0.03 | CD5, GV2, GW4 accepted: least 0.19 / 0.19 / 0.04; smooth pearl glass by design |
| any other | 0.6 | 0.20 | 0.10 | the Navy floor |

**What tells clay from finished.** On the hard-plate factions the colour contrast is the number that separates. Navy O2 and
O3, the ships Ryan caught looking like clay, measure 0.18 and 0.14; the accepted Dominion and Iron Mandate 0.27 and 0.24. Their
normal relief (1.25 and 1.43) is no lower than accepted ships' (IM5 1.12, A19 1.00), so the normal floor only catches a skin
with no relief at all. The old check measured only the one `<ship>_hull` object (6695 texels of O2; 2288 of O3) and its 3.5
normal floor was the Chorus number, which no hard-plate ship reaches (Sunward's accepted skins measure 1.6 to 1.9).

## Every ship measured (with the floors above)

PC: the PC run's own 4096 atlases, measured over the skin texels of the same build's UVs rebuilt in the cloud at that run's
commit. Cloud: a cloud bake of today's main at 1024 px, 8 samples (normal relief reads about 0.3 higher in the cloud than on
the PC for O2 and the same for S10; colour contrast within 0.05).

| Ship | Faction | Source | normal | albedo | rough | Status in game | Verdict |
|---|---|---|---|---|---|---|---|
| S8 Daybreak | Sunward | PC opus1158e8 | 1.56 | 0.394 | 0.157 | accepted | PASS |
| S9 Warden | Sunward | PC opus1158e9 | 1.80 | 0.466 | 0.178 | accepted | PASS |
| S10 Vigil | Sunward | PC 1157 shipjob9 | 1.62 | 0.460 | 0.161 | accepted | PASS |
| S11 Harrow | Sunward | PC opus1414d | 1.90 | 0.463 | 0.172 | accepted | PASS |
| H10 Dominion | Navy | cloud main | 1.55 | 0.267 | 0.153 | accepted | PASS |
| IM5 Iron Mandate | Navy | cloud main | 1.12 | 0.241 | 0.133 | accepted | PASS |
| O2 Convoy | Navy | PC opus1413o2c (pin-1413c) | 1.25 | 0.178 | 0.165 | sent back as clay | FAIL |
| O3 Relay | Navy | PC opus1413o3c (pin-1413c) | 1.43 | 0.140 | 0.184 | sent back as clay | FAIL |
| HB1 bomber | Navy | PC opus1373q (pin-1373d) | 1.17 | 0.182 | 0.123 | published Nov 21 in a "rest are good" batch | FAIL |
| A18 Raider | Hullbreakers | cloud main | 1.08 | 0.510 | 0.282 | accepted | PASS |
| A19 Gutship | Hullbreakers | cloud main | 1.00 | 0.558 | 0.330 | accepted | PASS |
| KF1 fighter | Hullbreakers | PC opus1373r (pin-1373d) | 1.12 | 0.426 | 0.151 | "looks unfinished" | PASS |
| E11 | Eclipse | cloud main | 1.06 | 0.616 | 0.146 | in game | PASS |
| CD5 Unfinished | Glasswrights | PC publish I8_37 | 0.73 | 0.477 | 0.043 | accepted | PASS |
| GV2 fighter | Glasswrights | PC opus1373gv2i | 0.19 | 0.191 | 0.079 | accepted, published | PASS |
| GW4 bomber | Glasswrights | PC opus1373gw4i | 0.25 | 0.276 | 0.068 | accepted, published | PASS |
| GS1, GL1 | Glasswrights | PC pin-1415e | 0.37, 0.48 | 0.309, 0.197 | 0.078, 0.047 | waiting on changes | PASS |
| C10 Ninefold Maw | Chorus | PC opus1291c10g | 5.15 | 0.166 | 0.251 | accepted | PASS |
| C12 Drone-spawn | Chorus | PC opus1291c12d | 5.26 | 0.167 | 0.254 | accepted | PASS |

Known limits: HB1 measures like O2 and fails its next rebake until the Navy paint stack gives the plates more colour detail (a
stack fix reaches O2, O3 and HB1 together, R333) or Ryan opts it out. KF1's "unfinished" look is not a flat skin by these
numbers (its colour contrast is Sunward-level); the check does not judge shape. The Navy margin is thin: IM5 is 0.04 over
the albedo floor, measured in the cloud. GP1 is left out: its pin-1415e relay failed at fetch and holds an
earlier run's files (Artoo on PR 1521, issue 1516), so its numbers are not proved. Torpedo and rocket bodies have no stage 5 bake and are not measured.

## How the numbers and the self-test fixtures were made

tools/recipe/test/detail_fixtures/ holds three of these PC bakes for the standing self-test
(tools/recipe/test/detail_check_selftest.py): O2 whole, C12 and S10 a quarter of their skin (every other 128 px tile both
ways). Each is the PC atlas box-downsampled to 1024 with every texel more than 3 away from the skin zeroed (the measure only
looks 3 texels round each skin texel, so the numbers are the full atlas's), plus the skin mask from the cloud rebuild's UVs.
contrib/opus/tools/issue1517/blender_proof.sh repeats the O2, C12 and S10 checks inside Blender (pip bpy 4.5.4), the way
stage 5 runs them.
