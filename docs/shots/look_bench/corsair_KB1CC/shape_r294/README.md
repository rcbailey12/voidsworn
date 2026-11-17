# KB1CC run 2, R299, issue 903

The comparison shows the accepted concept, run 1 (PR 909, `ba3af366`),
and run 2 at the same saved `paint_full` camera (35 degrees azimuth,
30 degrees elevation, 52 mm). The revision and stage are printed on each picture.
This is a painted build proof. It has not been installed or accepted by Ryan.

- [Concept, run 1 and run 2](KB1CC_R299_compare.jpg)
- [Run 2 at paint_full](KB1CC_R299_paint_full.jpg)
- [Bomb tube mouth and corner armour](KB1CC_R299_tube.jpg)
- [Machinery bays and engines](KB1CC_R299_details.jpg)
- [Taper and ramp then plateau](KB1CC_R299_profile.jpg)
- [Run 1 and run 2 at camera 170](KB1CC_R299_cam170.jpg)
- [Measured results and source revision](checks.json)

The original sheet simplified four parts of the concept. Its R275 interpretation
made the upper body one continuous ramp to the stern, and retained nearly the
full beam at the bow toe. Its machinery parts had a depth of only 0.004 of the
length and sat on closed shoulder skins. The large round concept mouths were
interpreted as bomb tubes, leaving only the small row of drives at the stern.
These choices were in the geometry before the PR 898 repaint.

Run 1 restored those shapes but made the front weapons tiny. Ryan's R299 asks for
the concept's bomb and torpedo tube read back. Run 2 enlarges both mouths from
.026 to .064 LENGTH radius. Dark collars surround straight deep bores, with the
next bomb nose recessed behind dim red lining. Plated wedges join the drums to
the glacis corners; the bores cut both the wedges and the shoulder skins. These
remain the only weapons: `bombs T`, two shots, both mounts firing each volley.
The aft drives keep their orange flared throats and hot plugs. Their radii shrink
from .096/.090 to .078/.074 LENGTH, and their centres lower by .016/.014 LENGTH.
The five stern thrusters, sunken bays, piping, rails, tapered toe and plateau stay.

The PR 898 faction stack is unchanged. Only KB1CC's paint inputs change: the
rust/blood plate weight rises from 49 to 85 percent, plates grow, and the body and
shoulder skins take rust underpaint. Dark seams, worn rims and broad paint loss
still come from the same stack. Grey salvage stays a minority. The isolated pale
and violet square zones remain reassigned to weathered iron and blood red.
The magazine rows, crew cell, reactor, drive room and bay machinery stay.

Method: [KB1CC build sheet](../../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md),
[manifest](../../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json),
the existing sheet contract and the unchanged Hullbreaker stack. Budget counts,
fit, weapon matching, contract preservation, manifest agreement and the painted
surface check are recorded in `checks.json`. Counts are reported, never capped.
No frame-time claim is made.

Double-click [reproduce.bat](reproduce.bat) on Ryan's PC to rebuild the sheet,
run its checks, bake 2048 maps and make the proofs. [reproduce.py](reproduce.py)
uses the existing watchdog, GPU claims and `gpu_go.txt`. Scratch blends, maps,
renders and logs stay in `%TEMP%\voidsworn903_r299`. Review copies are also saved in
`C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-903\shots`.

Game export and installation are outside this job. The current squadron craft
renderer still needs its separate sheet-asset route; this proof does not claim
that the revised model is installed in game.

The preserved `KB1CC_R294_*` pictures are explicitly run 1 references. Their old
revision remains on them. Run 2 pictures use `KB1CC_R299_*` names and a design
hash in their revision label. The run 1 paint_full and camera crop come from the
saved PR 909 renders; `reproduce.py` uses those repo snapshots for comparisons.
