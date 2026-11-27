# PR 1772 hulks: K (before R425) vs M (R425, 60% of live paint)

Left is PROPS_K at e31cd839 (relay pc-out-opus1767propsk), right is PROPS_M at 7c7ae555 (relay pc-out-opus1767propsm,
5da8bea9, out_20261123_081615_11842, PASS). Same cameras and draws. Frames 01 to 07 are hulks; 08 to 10 are M-only station shots.

Measured on the pixels that changed between K and M (linear brightness; this overstates small shifts):
Chorus -38%, Hullbreakers -25%, Navy -25%, Sunward -21%, field -11%, Glasswright +1% (no change, as designed).
Eclipse's obsidian ring is unchanged by eye; its changed pixels are the Chorus hulk at the frame edge.

Read: Chorus is the clear win. Under K it read as a lit tan shell; under M it is a dry, dark brown wreck, and the eye glass
still catches light. Navy, Sunward and Hullbreakers are a touch darker and keep their colour. No hulk went to pure black.

Stations (Neon's "missing station_T2 shots"): 08 teaching 3 hex (rig), 09 big 19 hex (ring), 10 hole 1 hex (spire), each at
c170 and c26. The bench fails the run unless each of these frames draws exactly one station_T2 (look_bench.gd _props_part),
and the run passed, so these are station_T2 shots.
