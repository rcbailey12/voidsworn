# Surface-detail floors per faction (issue 1517, Nov 21 2026)

Stage 5's detail check (tools/recipe/detail_check.py) measures three numbers over a ship's visible outside skin. That means
every outside object on the hull atlas and on the parts atlas: skin, plates, armour, cargo containers, guns and engines. Glow
and insides are left out. So is any surface that has another surface straight out from it within 3 percent of the ship's
length, such as the bare hull shell under authored panels or the touching faces of stacked containers. It reads the baked
images inside the painted blend, the bake stage 7 exports, never a file on disk. Every atlas is read at 1024 px whatever the
bake size.

- **normal**: relief in the detail normal map (mean degrees from the local average): rivets, seams, wrinkles, pores.
- **albedo**: the colour's local contrast (mean luminance difference from the local average, over mean luminance).
- **rough**: the roughness map's spread (standard deviation).

A ship fails when any number is under its faction's floor. Every faction is gated; until Nov 21 only Chorus was.

## The floors

Each floor is 80 percent of the least-detailed ship Ryan accepted in game, rounded down. Chorus keeps its issue 1291 floors,
which are lower.

| Faction | normal | albedo | rough | Set from |
|---|---|---|---|---|
| Chorus (`chorus`) | 3.5 | 0.04 | 0.08 | issue 1291 floors, kept (C10, C12 least 7.02 / 0.065 / 0.158) |
| Sunward (`voidsworn`) | 0.94 | 0.26 | 0.13 | S8, S9, S10, S11: least 1.18 / 0.328 / 0.165 |
| Navy (`hegemony`) | 0.95 | 0.15 | 0.12 | H10, IM5: least 1.19 / 0.193 / 0.151 |
| Hullbreakers (`hullbreakers`) | 1.31 | 0.24 | 0.11 | A18, A19, KF1 L: least 1.64 / 0.302 / 0.146 |
| Eclipse (`eclipse`) | 0.62 | 0.37 | 0.13 | E11: 0.78 / 0.466 / 0.162 |
| Glasswrights (`ithar`) | 0.6 | 0.02 | 0.01 | CD5, GV2, GW4: least 0.76 / 0.030 / 0.016 (smooth pearl glass by design) |
| any other | 0.95 | 0.15 | 0.12 | the Navy floor |

**What tells clay from finished.** On the Navy, colour contrast is the number that separates. O2 and O3, the ships Ryan
caught looking like clay, measure 0.120 and 0.074. The accepted Dominion and Iron Mandate measure 0.193 and 0.202. O2 and O3
have as much relief (1.46, 1.52) as the accepted ships (1.19 to 1.47).

## Every ship measured (Nov 21 2026, with the floors above)

All numbers come from cloud bakes: stage 5's own bake_sheet.py at 1024 px and 8 samples (pip bpy 4.5.4), measured inside the
blend. Ships that Ryan accepted were baked at the commit of their accepted run, where that run's commit is known. The others
were baked at main (c2c6795e).

The PC's own atlases were tried first and dropped. Matching them to a cloud rebuild's UVs held for the hard-plate ships but
not for the Chorus or Glasswright ones, whose unwraps differ between the two builds (Artoo on PR 1521, second round).

| Ship | Faction | Baked at | normal | albedo | rough | covered | Status in game | Verdict |
|---|---|---|---|---|---|---|---|---|
| S8 Daybreak | Sunward | main | 1.18 | 0.328 | 0.181 | 0.55 | accepted | PASS |
| S9 Warden | Sunward | main | 1.47 | 0.365 | 0.170 | 0.53 | accepted | PASS |
| S10 Vigil | Sunward | main | 1.33 | 0.359 | 0.170 | 0.55 | accepted | PASS |
| S11 Harrow | Sunward | main | 1.47 | 0.353 | 0.165 | 0.53 | accepted | PASS |
| H10 Dominion | Navy | main | 1.46 | 0.193 | 0.159 | 0.55 | accepted | PASS |
| IM5 Iron Mandate | Navy | main | 1.19 | 0.202 | 0.151 | 0.58 | accepted | PASS |
| O2 Convoy | Navy | pin-1413c and main (same) | 1.46 | 0.120 | 0.154 | 0.62 | sent back as clay | FAIL (albedo) |
| O3 Relay | Navy | main | 1.52 | 0.074 | 0.196 | 0.53 | sent back as clay | FAIL (albedo) |
| HB1 bomber | Navy | main | 1.34 | 0.153 | 0.109 | 0.35 | published Nov 21, then named by Ryan for the Navy paint fix with O2 and O3 | FAIL (rough) |
| A18 Raider | Hullbreakers | main | 1.64 | 0.387 | 0.223 | 0.76 | accepted | PASS |
| A19 Gutship | Hullbreakers | main | 1.77 | 0.375 | 0.256 | 0.78 | accepted | PASS |
| KF1 L fighter | Hullbreakers | 237fd5b2 (pin-1373l) | 7.45 | 0.302 | 0.146 | 0.79 | accepted Nov 21 | PASS |
| E11 | Eclipse | main | 0.78 | 0.466 | 0.162 | 0.57 | in game | PASS |
| CD5 Unfinished | Glasswrights | 6b69276a (published run) | 1.48 | 0.034 | 0.016 | 0.55 | accepted | PASS |
| GV2 fighter | Glasswrights | 84b6e3f4 (pin-1373i) | 0.76 | 0.030 | 0.042 | 0.45 | accepted | PASS |
| GW4 bomber | Glasswrights | 84b6e3f4 (pin-1373i) | 0.84 | 0.057 | 0.038 | 0.29 | accepted | PASS |
| C10 Ninefold Maw | Chorus | de238779 (pc-out-1291c10g) | 7.02 | 0.065 | 0.169 | 0.52 | accepted | PASS |
| C12 Drone-spawn | Chorus | 392b9468 (opus1291c12d) | 7.58 | 0.074 | 0.158 | 0.58 | accepted | PASS |

"covered" is the share of outside triangles left out as covered.

**Known limits:**
- HB1 fails on roughness spread (0.109 against 0.12). It is not counted as an accepted ship: Ryan put it in the Nov 21 Navy
  paint fix with O2 and O3, and the Navy stack fix reaches all three (R333). Otherwise Ryan can opt it out.
- KF1 L (Ryan's OK Nov 21, "Engines slightly bigger again and then go") is the least-detailed accepted Hullbreaker on
  colour and roughness, so it sets those two floors. An earlier KF1 build at main (c2c6795e) measured 1.52 / 0.301 / 0.127
  and passes them too. The check does not judge shape.
- The Navy colour margin is thin: H10 is 0.04 over its floor.
- Cloud and PC bakes of the same ship differ: normal relief read about 0.3 higher in the cloud on O2's old hull-only sample,
  and colour contrast was within 0.05. A floor near a ship's number can therefore flip between the two.
- Torpedo and rocket bodies have no stage 5 bake and are not measured.

## How the self-test fixtures were made

tools/recipe/test/detail_fixtures/ holds three of these bakes for the standing self-test
(tools/recipe/test/detail_check_selftest.py): O2 at pin-1413c whole, and C12 and S10 each a quarter of their skin (every other
128 px tile both ways). Each fixture holds the blend's baked images at 1024 px, with every texel more than 3 away from the skin
zeroed. The measure only looks 3 texels round each skin texel, so the numbers equal the full atlas's. Each also holds the skin
mask from `skin_texels`.

contrib/opus/tools/issue1517/blender_proof.sh repeats O2, C12, S10, GV2 and KF1 inside Blender. It deletes every atlas file
from the job folder first, so the check reads the bake inside the blend, as stage 5 does on the PC.
