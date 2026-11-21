# Surface-detail floors per faction (issue 1517, Nov 21 2026)

Stage 5's detail check (tools/recipe/detail_check.py) measures three numbers over a ship's visible outside skin. That means
every outside object on the hull atlas and on the parts atlas: skin, plates, armour, cargo containers, guns and engines. Glow
and insides are left out. So is any surface that has another surface straight out from it within 3 percent of the ship's
length, such as the bare hull shell under authored panels or the touching faces of stacked containers. It reads the baked
images inside the painted blend, the bake stage 7 exports, never a file on disk. Every atlas is read at 1024 px whatever the
bake size.

Every number is weighted by visible area (Board ruling, Nov 21): each triangle of the visible skin gets random sample points in
proportion to its world area, so a big plate counts for its size and a finely divided smooth part does not swamp it. O3's
lens rings (1216 triangles of smooth machined metal) outweighed its big plates when every triangle counted the same. A part
used twice counts twice.

- **normal**: relief in the detail normal map (mean degrees from the local average): rivets, seams, wrinkles, pores.
- **albedo**: the colour's local contrast (mean luminance difference from the local average, over mean luminance).
- **rough**: the roughness map's spread (standard deviation).

A ship fails when any number is under its faction's floor. Every faction is gated; until Nov 21 only Chorus was.

## The floors

Each floor is 80 percent of the least-detailed ship Ryan accepted in game, rounded down. Chorus keeps its issue 1291 floors,
which are lower.

| Faction | normal | albedo | rough | Set from |
|---|---|---|---|---|
| Chorus (`chorus`) | 3.5 | 0.04 | 0.08 | issue 1291 floors, kept (C10, C12 least 7.20 / 0.064 / 0.160) |
| Sunward (`voidsworn`) | 1.44 | 0.23 | 0.12 | S8, S9, S10, S11: least 1.81 / 0.290 / 0.152 |
| Navy (`hegemony`) | 1.34 | 0.13 | 0.14 | H10, IM5: least 1.68 / 0.174 / 0.175 |
| Hullbreakers (`hullbreakers`) | 1.26 | 0.16 | 0.07 | A18, A19, KF1 L: least 1.58 / 0.201 / 0.088 |
| Eclipse (`eclipse`) | 0.88 | 0.40 | 0.11 | E11: 1.11 / 0.502 / 0.139 |
| Glasswrights (`ithar`) | 0.47 | 0.02 | 0.01 | CD5, GV2, GW4: least 0.59 / 0.030 / 0.013 (smooth pearl glass by design) |
| any other | 1.34 | 0.13 | 0.14 | the Navy floor |

**What tells clay from finished.** On the Navy, colour contrast is the number that separates. O2 and O3, the ships Ryan
caught looking like clay, measure 0.095 and 0.070. The accepted Dominion and Iron Mandate measure 0.174 and 0.222. O2 and O3
have as much relief (1.80, 1.71) as the accepted ships (1.68, 1.71).

## Every ship measured (Nov 21 2026, area weighted, with the floors above)

All numbers come from cloud bakes: stage 5's own bake_sheet.py at 1024 px and 8 samples (pip bpy 4.5.4), measured inside the
blend. Ships that Ryan accepted were baked at the commit of their accepted run, where that run's commit is known. The others
were baked at main (c2c6795e).

The PC's own atlases were tried first and dropped. Matching them to a cloud rebuild's UVs held for the hard-plate ships but
not for the Chorus or Glasswright ones, whose unwraps differ between the two builds (Artoo on PR 1521, second round).

| Ship | Faction | Baked at | normal | albedo | rough | covered | Status in game | Verdict |
|---|---|---|---|---|---|---|---|---|
| S8 Daybreak | Sunward | main | 1.82 | 0.348 | 0.158 | 0.55 | accepted | PASS |
| S9 Warden | Sunward | main | 1.95 | 0.292 | 0.154 | 0.53 | accepted | PASS |
| S10 Vigil | Sunward | main | 1.81 | 0.342 | 0.157 | 0.55 | accepted | PASS |
| S11 Harrow | Sunward | main | 2.10 | 0.290 | 0.152 | 0.53 | accepted | PASS |
| H10 Dominion | Navy | main | 1.71 | 0.174 | 0.175 | 0.55 | accepted | PASS |
| IM5 Iron Mandate | Navy | main | 1.68 | 0.222 | 0.182 | 0.58 | accepted | PASS |
| O2 Convoy | Navy | pin-1413c and main (same) | 1.80 | 0.095 | 0.177 | 0.62 | sent back as clay | FAIL (albedo) |
| O3 Relay | Navy | main | 1.71 | 0.070 | 0.149 | 0.53 | sent back as clay | FAIL (albedo) |
| HB1 bomber | Navy | main | 1.44 | 0.101 | 0.109 | 0.35 | published Nov 21, now in the Navy paint fix with O2 and O3 | FAIL (albedo, rough) |
| A18 Raider | Hullbreakers | main | 1.58 | 0.307 | 0.139 | 0.76 | accepted | PASS |
| A19 Gutship | Hullbreakers | main | 1.62 | 0.304 | 0.146 | 0.78 | accepted | PASS |
| KF1 L fighter | Hullbreakers | 237fd5b2 (pin-1373l) | 7.26 | 0.201 | 0.088 | 0.79 | accepted Nov 21 | PASS |
| E11 | Eclipse | main | 1.11 | 0.502 | 0.139 | 0.57 | in game | PASS |
| CD5 Unfinished | Glasswrights | 6b69276a (published run) | 1.01 | 0.063 | 0.013 | 0.55 | accepted | PASS |
| GV2 fighter | Glasswrights | 84b6e3f4 (pin-1373i) | 0.59 | 0.030 | 0.039 | 0.45 | accepted | PASS |
| GW4 bomber | Glasswrights | 84b6e3f4 (pin-1373i) | 0.68 | 0.048 | 0.039 | 0.29 | accepted | PASS |
| C10 Ninefold Maw | Chorus | de238779 (pc-out-1291c10g) | 7.42 | 0.064 | 0.160 | 0.52 | accepted | PASS |
| C12 Drone-spawn | Chorus | 392b9468 (opus1291c12d) | 7.20 | 0.065 | 0.169 | 0.58 | accepted | PASS |

"covered" is the share of outside triangles left out as covered.

**Known limits:**
- HB1 fails on colour contrast and roughness spread (0.101 and 0.109 against 0.13 and 0.14). It is not counted as an
  accepted ship: it is in the Nov 21 Navy paint fix with O2 and O3, and the Navy stack fix rebakes all three (R333).
  Otherwise Ryan can opt it out.
- KF1 L (Ryan's OK Nov 21, "Engines slightly bigger again and then go") is the least-detailed accepted Hullbreaker on
  colour and roughness, so it sets those two floors. The check does not judge shape.
- The Navy colour margin is thin: H10 is 0.044 over its floor.
- Cloud and PC bakes of the same ship differ: normal relief read about 0.3 higher in the cloud on O2's old hull-only sample,
  and colour contrast was within 0.05. A floor near a ship's number can therefore flip between the two.
- An atlas with visible skin must have all three baked maps in the blend. If one is missing the check fails and names it,
  and an opt-out does not excuse it (Artoo on PR 1521). An atlas with no visible skin is skipped.
- Torpedo and rocket bodies have no stage 5 bake and are not measured.

## How the self-test fixtures were made

tools/recipe/test/detail_fixtures/ holds three of these bakes for the standing self-test
(tools/recipe/test/detail_check_selftest.py): O2 at pin-1413c whole, and C12 and S10 each a quarter of their skin (every other
128 px tile both ways). Each fixture holds the blend's baked images at 1024 px, with every texel more than 3 away from the skin
zeroed. The measure only looks 3 texels round each skin texel, so the numbers equal the full atlas's. Each also holds the
area weight per texel from `skin_texels` (CELL_ATLAS_weight.npz, scaled by the ship's largest texel weight).

contrib/opus/tools/issue1517/blender_proof.sh repeats O2, C12, S10, GV2 and KF1 L inside Blender, plus S10 with one map taken out. It deletes every atlas file
from the job folder first, so the check reads the bake inside the blend, as stage 5 does on the PC.
