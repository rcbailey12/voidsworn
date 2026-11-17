# corsair_KB1CC: R299 run 2, issue 903

Revision: `d832730e+903-r2-916bee04ad`. Stage: sheet built and paint proof, not installed or accepted.

Run 2 restores the concept's large forward bomb mouths in dark collars, with
real bores and dim red liners. Their radius is .064 LENGTH, up from .026 in run 1.
The drums blend into red corner armour; the bores cut that armour and the shoulder
skins. The next bomb sits deep inside, with no engine plug or flared throat.
Both mounts remain bombs T, two shots per volley. The stern nacelles are 19 and
18 percent smaller and .016/.014 LENGTH lower, with orange flared throats.
The five stern thrusters, sunken bays, pipes, rails, tapered bow and plateau stay.

Only KB1CC paint inputs change: larger physical plates, rust/blood weights raised
from 49 to 85 percent, rust underpaint on the body and shoulders. The existing
Hullbreaker stack supplies the same seams, grime, scrapes and worn metal edges.
Grey salvage is a minority; there are no pale or purple plate zones.
Measured red area is 21.9 percent in run 1 and
59.6 percent in run 2, using the threshold documented
in the evidence JSON. This reports the painted result, not just material weights.

The older R275 sheet simplified the top to one ramp, retained the broad bow toe,
and put shallow machinery panels on closed shoulder skins. Run 1 restored these
features but reduced the front tubes to tiny weapons. R299 corrects that tradeoff.

[Concept, run 1 and run 2](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_compare.jpg)
uses the saved paint_full camera. [Tube close view](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_tube.jpg)
shows the collar, real bore and integrated corner armour.
[Camera 170](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_cam170.jpg)
compares both runs at true pixel size. Every current picture names its revision
and stage and is at most 720 pixels high. These are paint proofs, not game installs.

Method: this sheet's [design](../../../../tools/blender/build_sheets/ships/corsair_KB1CC.py),
[manifest](manifest.json), the existing sheet contract and Hullbreaker craft stack.
The wells and the modified kit bomb tubes are recorded as hand-built in the manifest.
[Rebuild and evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/README.md).

Budget: 54,604 exterior triangles, 155 outside mesh objects,
4 merged draw calls and 4 surfaces. These are
reported counts, not caps or measured frame times. No game export or install is included.

Checks: zero fit clashes, weapon match PASS, inventory PASS, sheet contract PASS,
shared mount/machine-seam audit PASS, manifest agreement PASS, texture licences PASS,
lights PASS. Six painted surface views found zero room-colour and zero bare pixels.
Outline overlap is 79.3 percent with the historical camera held
fixed; it is reported, not a pass bar. See [dimensions](checks.json),
[fit](fit.json), [weapons](weapon_match.json), [inventory](inventory.md),
[features](feature_table.md), and the [painted evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/checks.json).
