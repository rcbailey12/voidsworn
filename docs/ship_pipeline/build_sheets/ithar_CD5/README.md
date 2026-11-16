# Glasswright flagship CD5: The Unfinished

Issue 912, R298. Stage: **sheet built**, revision r1. The approved CD5 concept guides this
hand-built Blender design. It keeps the long flowing leaf, both long forward lances,
silver veins, amber/violet/green inner glass and the three stern drive optics. The three
secondary optics now sit at equal intervals on the centreline. No game source or other
ship is changed.

![CD5 concept beside the Blender sheet](compare.jpg)

Review: [balanced top view](top.jpg), [camera 170 at original pixel size](camera170.jpg),
[five true views at one scale](sheet.jpg), [inside](inside.jpg), [fit view](fit_view.jpg).
Every review picture is 1280 by 720 with its revision and stage burned in and a checked
provenance record. [concept.jpg](concept.jpg) is the whole approved reference, copied
first as a 1536-pixel-wide JPEG. It includes the small inset ship in the original image.

## Method

Design: [ithar_CD5.py](../../../../tools/blender/build_sheets/ships/ithar_CD5.py).
[Build manifest](manifest.json), [feature table](feature_table.md), [inventory](inventory.md).
Every visible part is hand-built in that design file. Blender 4.5.14 LTS, Cycles CPU,
48 samples, eight render threads. The shared sheet kit supplies records, transforms,
turret hierarchy and contract plumbing only. No Hullbreaker shapes or materials are
used. There is no Glasswright kit or paint stack yet. The materials describe physical
glass and the approved colour zones; the inner triangle glints are small panes inside
the smooth glass, not crystal objects on the hull or projected concept paint.

One continuous, thickened surface forms the leaf and the raised secondary lens roots.
Longitudinal ridges, pearly streams and silver filaments carry its flow. The stern stays
broad enough to grow directly into the three drive optics. Their light sits inside the
glass and ends in a soft white bloom, without a flame mesh. Silver filaments continue
over the drive shoulders. The two forward lances are long drawn-glass waveguides with
silver veins and colour panes inside, each with a visible optical exit.

## Game and optic match

`data.js i_boss`, **The Unfinished**, faction `ithar`, class **Ark**, size 1.26. The same
entry is in the committed Godot rules table. Class length is 26.0 from
`godot/render/hull_table.gd`; the board draws it at 26.0 x SHIP_K 1.6 = **41.6**.
The size field is not substituted for class length. Measured mesh dimensions and all
hard points are in [model.json](model.json).

| Slot | Game weapon | Built optic | Placement and arc |
|---|---|---|---|
| 0 | `pulsar F`, Prism lance | L1 | Long port forward waveguide; forward +/-60 degrees |
| 1 | `pulsar F`, Prism lance | L2 | Long starboard forward waveguide; forward +/-60 degrees |
| 2 | `pulsar T`, Prism lance | O1, amber | x=-6, centreline; inner lens turns through 360 degrees |
| 3 | `turret T`, Needle beam | O2, violet | x=0, centreline; inner lens turns through 360 degrees |
| 4 | `flak T`, Mirror veil | O3, green | x=+6, centreline; inner lens turns through 360 degrees |
| Drive | No weapon slot | E1, E2, E3 | Stern optic cluster, aft-facing soft white bloom |

This follows the Board's reading of the three small points as the secondary weapons,
with the stern cluster separate as propulsion. Each weapon owns one muzzle; there are
five muzzles, five game slots and three turret pivots. The turning lens and its internal
light are children of its pivot. The clear root stays with the hull. No pod, bracket,
traverse ring or other faction's gun housing is used. The `pulsar` row added to the shared
weapon-match table allows this game's fixed and turning lance mounts; its self-test
also refuses a Prism lance shown as a launcher.

The three secondary stations are **6 units apart**, on the centreline rather than
left-heavy. Their saddles rise smoothly from the skin. Their moving parts stay above
it and can turn completely. Fit records retain the clear firing elevation at every
5-degree bearing, rather than claiming unobstructed horizontal fire through another
optic. The forward waveguides keep their forward rest aim.

## Inside and breaks

Two shaped glass decks, 15 annealed frames, three braided light cores through almost
the full leaf and three optic reservoirs give it a constructed inside. The outer shell
is 0.065 units thick. The cutaway shows the actual geometry with the outer skin hidden.

Five jagged transverse paths separate the stern and the aft/middle lens bays. The fore
optic has an upper peel at z=1.66, above both forward lances and below its whole root.
Every optic is its own named machine mesh group, including its internal light. The
manifest names each whole group as a break piece. The hull fracture paths leave those
machines whole; the audit confirms zero machines crossing a seam. This is authored
sheet data, not a claim that this asset's shatter effect is installed in the game.
Seven breach anchors follow Ark base 8 minus the Glasswright adjustment of 1; there
are also one core, two RCS and two boarding origins.

## Checks and budget

See [checks.json](checks.json) for results and commands, [fit_report.md](fit_report.md)
for the corrections, [weapon_match.json](weapon_match.json) for the game slot match,
[contract_selftest.json](contract_selftest.json) for the contract and its broken-input
tests, [audit.json](audit.json) for seam clearance and [density_mesh.json](density_mesh.json)
for measured detail density. [manifest_check.json](manifest_check.json) checks the
actual mesh groups, routes, breach count and design digest.

The sheet has **232,002 outside triangles and 37,312 inside triangles**, 269,314 total.
There are **120 outside material surfaces and 23 inside surfaces** before joining, so
143 material draw submissions if exported in that unjoined form. The outside uses
13 materials; the whole ship uses 14 unique materials. Those are reported costs,
not caps. Joining static surfaces could reduce submissions, but turning lenses must
retain their pivots. No exported Godot draw count or scene frame time is claimed.

## Design decisions and limits

- The secondary optics move to x=-6, 0, +6; amber maps to the all-round Prism lance,
  violet to the Needle beam and green to the Mirror veil. The stern cluster stays the drive.
- The unseen underside, cross-section, internal structure and shatter paths are designed
  from the faction guide. The leaf's main skin mirrors about the long axis.
- Both long forward lances remain. Their roots are drawn into the skin and their tips
  reach beyond the bow, rather than becoming separate metal guns.
- Compared with the concept, the sheet's curls are simpler, the coloured panes follow
  regular longitudinal flows, and the glow is softer and paler under the review lights.
  These are visible differences for the Board to judge, not a claim of visual acceptance.
- No Glasswright paint stack, texture bake, game export, install, game capture, measured
  scene gate or owner acceptance is part of this sheet job. Other ships are untouched.

Reproduce with Blender on the CPU: run this design with `-- review TEMP_OUT`, then
run `python docs/ship_pipeline/build_sheets/ithar_CD5/review_layout.py TEMP_OUT`.
The first command writes a blockout blend, the normalized contract blend and source
renders to the temporary output folder. The second builds the review pictures, feature
table, manifest and top/side fit overlay. Keep those pictures beside this README for review. The Board's
issue-912 shots folder holds identical copies plus the Blender source artifact.
