# Glasswright flagship CD5: The Unfinished

Issue 912, R298, run 3. Stage: **sheet built**, revision **r3**. Built from run 2,
commit `23f61877`, with six twisting poured-glass strands, deep grooves, rolled
strand edges and 216 narrow amber, green and violet light slivers under clear glass.
The two forward lances, three round secondary optics and three large stern lenses
retain run 2's geometry, placement, materials and weapon records.

![CD5 concept beside the Blender sheet](compare.jpg)

Review: [top and optic spacing](top.jpg), [side and depth](side.jpg),
[camera 170 at original pixel size](camera170.jpg), [true views](sheet.jpg),
[full inside](inside.jpg), [fit](fit_view.jpg). Every review page is 1280 by 720,
labelled r3, design digest and sheet stage, with verified provenance.
[concept.jpg](concept.jpg) remains the full approved reference, a 1536-wide JPEG.
The concept camera and true game-size camera 170 are unchanged from run 2.

## Method and run 3 changes

Design: [ithar_CD5.py](../../../../tools/blender/build_sheets/ships/ithar_CD5.py).
[Manifest](manifest.json), [feature table](feature_table.md), [inventory](inventory.md).
All geometry is hand-built in that file. Blender 4.5.14 LTS, Cycles **CPU**, 48 samples,
eight render threads. No Glasswright kit or paint stack exists yet. Materials name
glass, pearl, silver and stored-light zones; no other faction's paint is used.

- The actual cross-section has six joined lobes with deep rounded valleys. Unequal
  strand widths and gentle meanders follow a broad twist that tightens at midship.
  Raised poured edges and fine silver filaments follow each strand. This is one
  thick continuous skin, with grooves in the geometry throughout the belly and flanks.
- The 24 broad colour panes are replaced by **216 tapered light slivers**, three
  staggered lanes in each of six grooves, twelve short slivers per lane. Each is
  below the glass, with smooth light falloff and space between the ends. Amber is
  the warmer, brighter dominant stored light, with green and violet between it.
- The rounded middle is retained: the skin's depth at x=0 is **6.263** world units,
  against run 2's **6.037**. Overall mesh dimensions are **25.992 x 8.470 x 6.992**.
- The round-optic attachments use the frozen run 2 surface so reshaping the strands
  cannot silently move a lens or muzzle. Its three complete stern lenses and
  internal drive feed are also frozen. New body materials are separate from theirs.
- The shared manifest schema is retained: its parts, mass, hull compartments,
  fractures and whole-optic fields are unchanged. Only revision, design digest and
  measured cost change. The generator still runs the real standing manifest check.

[Preservation proof](preservation_check.json) builds run 2 and r3 independently and
compares all eight optical groups: world vertices, faces, hierarchy, material shaders,
features and fit records. It also compares the unchanged manifest fields and the
lance function's syntax tree. [Reproduction script](preservation_check.py).
[Lance proof](lance_preservation.json) carries forward the run 1 comparison and
extends preservation through run 3.

## Game and optic match

`data.js i_boss`, **The Unfinished**, `ithar`, **Ark**, size 1.26.
[Game match](game_match.json) checks the committed Godot rules twin too.
`godot/render/hull_table.gd`: Ark length 26.0, drawn **41.6** with SHIP_K 1.6.

| Slot | Game weapon | Built optic | Placement and arc |
|---|---|---|---|
| 0 | pulsar F, Prism lance | L1 | Port forward waveguide; +/-60 degrees |
| 1 | pulsar F, Prism lance | L2 | Starboard forward waveguide; +/-60 degrees |
| 2 | pulsar T, Prism lance | O1, amber | x=-6, centreline; 360-degree bearing |
| 3 | turret T, Needle beam | O2, violet | x=0, centreline; 360-degree bearing |
| 4 | flak T, Mirror veil | O3, green | x=+6, centreline; 360-degree bearing |
| Drive | No weapon slot | E1, E2, E3 | Three large stern lenses, aft exits |

The Board's three small points remain the secondary weapons. The stern cluster is
propulsion. The five actual muzzles match five slots; each internal turning lens
retains its pivot. Fit samples use 5-degree bearings and record clear elevations;
beams pass through their clear envelopes, never through another optic.
The shared Prism-lance validation row and its three self-test cases from run 2 are
retained because this checkout did not contain those earlier files.

## Inside and breaks

Two shaped glass decks, 15 annealed frames, three full-length braided light cores
and three optical reservoirs remain actual geometry. Shell thickness is 0.065.
Five jagged transverse paths and the fore optic's z=1.66 peel are unchanged.
Seven hull compartments retain full interiors; `whole_optics` separately records
all eight intact optical machine groups. Seven breach anchors follow Ark base 8
minus the Glasswright adjustment of 1. One core, two RCS and two boarding origins
remain. The seam audit checks whole machines against every fracture path.

## Checks and cost

[checks.json](checks.json) records current commands and results. Required checks:
[fit](fit.json) and [fit report](fit_report.md), [weapon match](weapon_match.json),
[contract](contract.json) and its [self-test](contract_selftest.json), and the real
standing [build manifest check](build_manifest_check.json).
[manifest_check.json](manifest_check.json) is only the separate local model check;
it does not stand in for the shared validator. Additional evidence:
[seam audit](audit.json), [mesh density](density_mesh.json), preservation and
[picture provenance](picture_check.json). The standing checks finish at **63 PASS, 2 existing KNOWN baselines, zero unresolved FAIL or SKIP**, after a permission retry.
The first full run exited 1 only because the sandbox denied the GPU-slot fixture's
temporary hard link. Its unchanged row passed outside the sandbox (exit 0). The
original full result and the separate retry are both preserved in checks.json.

**424,458 outside triangles + 37,312 inside = 461,770 triangles.**
**311 outside + 23 inside = 334 unjoined material surfaces/draw submissions.**
Thirteen exterior materials, fourteen unique materials including the insides.
Joining by material could reduce submissions, but pivots and break pieces affect
that count; this is no claim about Godot draw calls or frame time. Costs are reported,
not capped. The additional short light meshes increase unjoined draws over run 2.

## Limits and reproduction

The build now has actual braided grooves and narrow internal lights. Beside the
concept its glass remains smoother and more regular, and its refracted highlights
are broader and less intricate. The stern lenses retain run 2's smooth white bloom.
The camera 170 page shows the true small pixel size, without enlarging the ship.
The Board still judges the comparison; technical passes do not confer visual approval.
Paint baking, game export, installation, game captures and frame measurements are
outside this sheet job. Other ships are untouched.

Rebuild on the CPU with Blender: run the design with `-- review TEMP_OUT`, then
`python docs/ship_pipeline/build_sheets/ithar_CD5/review_layout.py TEMP_OUT`.
Run preservation in Blender with `-P preservation_check.py -- OUT.json`.
The blockout, normalized contract and studio review blend stay out of Git. Their
final copies and the review pages are saved in the runner's requested shots folder.
Scratch logs and temporary checks stay in TEMP. No commit or push is made by this run.
