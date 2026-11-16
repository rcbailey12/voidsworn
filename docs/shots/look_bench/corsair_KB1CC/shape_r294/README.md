# KB1CC shape restoration, R294, issue 903

The comparison shows the accepted concept, the previous PR 898 painted build,
and the revised build at the same saved `paint_full` camera (35 degrees azimuth,
30 degrees elevation, 52 mm). The revision and stage are printed on each picture.
This is a painted build proof. It has not been installed or accepted by Ryan.

- [Concept, before and after](KB1CC_R294_compare.jpg)
- [Machinery bays and engines](KB1CC_R294_details.jpg)
- [Taper and ramp then plateau](KB1CC_R294_profile.jpg)
- [Camera 170 preview](KB1CC_R294_cam170.jpg)
- [Measured results and source revision](checks.json)

The original sheet simplified four parts of the concept. Its R275 interpretation
made the upper body one continuous ramp to the stern, and retained nearly the
full beam at the bow toe. Its machinery parts had a depth of only 0.004 of the
length and sat on closed shoulder skins. The large round concept mouths were
interpreted as bomb tubes, leaving only the small row of drives at the stern.
These choices were in the geometry before the PR 898 repaint.

The revised sheet narrows the bow toe, raises the glacis to a level upper deck,
and gives its framing rails more height. The shoulder skins now have actual
openings with dark walls and floors, coupled pipes, hoists and partial hinged
covers. Two large round nacelles join the five stern thrusters. Their mouths
face aft to provide forward thrust. The front comparison shows their housings;
the rear view shows their deep red-orange throats. This differs from the concept's
forward-visible glowing corner mouths. Two separate, smaller forward bomb tubes
preserve `bombs T`, two shots, both mounts firing each volley.

The PR 898 Hullbreaker craft stack is unchanged. This design assigns the isolated
small light grey and violet plate zones to weathered steel, iron and blood red,
so they no longer read as loose notes. The magazine rows, crew cell, reactor and
drive room remain; each new open bay has its own machinery and dark lining.

Method: [KB1CC build sheet](../../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md),
[manifest](../../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json),
the existing sheet contract and the unchanged Hullbreaker stack. Budget counts,
fit, weapon matching, contract preservation, manifest agreement and the painted
surface check are recorded in `checks.json`. Counts are reported, never capped.
No frame-time claim is made.

Double-click [reproduce.bat](reproduce.bat) on Ryan's PC to rebuild the sheet,
run its checks, bake 2048 maps and make the proofs. [reproduce.py](reproduce.py)
uses the existing watchdog, GPU claims and `gpu_go.txt`. Scratch blends, maps,
renders and logs stay in `%TEMP%\voidsworn903`. Review copies are also saved in
`C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-903\shots`.

Game export and installation are outside this job. The current squadron craft
renderer still needs its separate sheet-asset route; this proof does not claim
that the revised model is installed in game.
