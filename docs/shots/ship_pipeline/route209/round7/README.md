# Issue 209 round 7: Ab6 becomes Ab7 (work in progress)

Ryan on round 6 (Nov 9 2026, 18:16 CST, FINDINGS R156): "I agree with all of your takes. The front is still very much off from the
concept but the rest looks pretty good today with details. Now it's a texture and paint pass it seems."

This file grows one step at a time; each step is pushed on its own so partial work can be reviewed.

## Step 1: the casemate barrels are level

![Casemates at the concept camera: concept, round 6's last aim, Ab7](step1_casemate_aim.jpg)

**Outline score with the level barrels: 90.1 percent** (the gate is 90; Ab6 with lowered barrels was 90.1).

The barrels now point out to the side and 8 degrees forward of the beam, dead level (`aim` 0.14, 0.99, 0.0 in
`tools/recipe/ships/C15s_23.json`). How that number was picked: in the concept the barrels run to the right and about 23 degrees
below level on screen. Through the fitted concept camera that is what a level, straight-out-to-the-side gun looks like (the camera
sits forward of the ship and above it). Round 6's last commit set them 33 degrees forward of the beam; that is level too, but at the
concept camera a gun aimed that far forward draws as pointing straight down the screen, so it would still have read as "down". No
gun is aimed aft of the beam (owner rule); 8 degrees forward keeps a margin.

| Casemate aim | Outline overlap | Concept covered | Ship outside the concept |
|---|---:|---:|---:|
| Ab6, lowered 9 degrees (round 6 sheets) | 90.1% | 96.6% | 7.0% |
| 33 degrees forward, level (round 6 last commit) | 89.8% | 96.6% | 7.3% |
| **Ab7: 8 degrees forward, level** | **90.1%** | 96.6% | 7.0% |

Scored in the sandbox from the built geometry, same scorer and camera as rounds 4 to 6 (round 6's 90.1 from the PC glb reproduces
here). The guns were not bent to the score: the aim comes from the concept, and the score happens to hold.
