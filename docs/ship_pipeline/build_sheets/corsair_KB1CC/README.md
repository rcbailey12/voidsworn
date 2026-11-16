# corsair_KB1CC: R294 shape restoration, issue 903

Revision: `0e9c791d+903-5e3378b9a2`. Stage: sheet built and paint proof, not installed or accepted.

The bomber now has two large round aft-facing main drives plus the five stern
thrusters, real sunken machinery bays with coupled pipes and hoists, a tapered
bow toe, higher framing rails, and a ramp that meets a level upper deck. The two
small forward bomb tubes preserve bombs T, two shots per volley. The old R275
sheet interpreted the top as one continuous ramp, kept the broad bow station,
mounted shallow machinery panels over closed skins, and interpreted the large
concept mouths as weapon tubes. These were geometry simplifications before PR 898.

The existing PR 898 Hullbreaker craft paint stack is unchanged. Isolated pale and
violet plate zones on this design were reassigned to weathered metal and blood red.
The nacelle mounts end aft of the existing seam so engines remain whole; the
inside room layout is retained, with dark walls and machinery in the new bays.

[Concept, previous and revised paint](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_compare.jpg)
uses the saved paint_full camera. [Feature proof](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_details.jpg)
also shows the aft engine openings. Those face aft for forward thrust, unlike the
concept's forward-visible glowing mouths. [Profile proof](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_profile.jpg)
shows the taper and plateau. Every current picture carries revision and stage and
is at most 720 pixels high.

Method: this sheet's [design](../../../../tools/blender/build_sheets/ships/corsair_KB1CC.py),
[manifest](manifest.json), the existing sheet contract and Hullbreaker craft stack.
The two new wells are hand-built in this design, recorded as such in the manifest.
[Rebuild and evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/README.md).

Budget: 60,936 exterior triangles, 153 outside mesh objects,
4 merged draw calls and 4 surfaces. These are
reported counts, not caps or measured frame times. No game export or install is included.

Checks: zero fit clashes, weapon match PASS, inventory PASS, sheet contract PASS,
shared mount/machine-seam audit PASS, manifest agreement PASS, texture licences PASS,
lights PASS. Six painted surface views found zero room-colour and zero bare pixels.
Outline overlap is 77.2 percent with the historical camera held
fixed; it is reported, not a pass bar. See [dimensions](checks.json),
[fit](fit.json), [weapons](weapon_match.json), [inventory](inventory.md),
[features](feature_table.md), and the [painted evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/checks.json).
