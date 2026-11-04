# Station kit, issue 61

This is the proxy blockout review gate, not the finished station replacement.
The live board and `a4_props.gd` remain unchanged pending Ryan's turntable approval.

Source: `contrib/muse/research/structures_2026_11/synthesis.md`, sections 2 to 4 and 8,
and `contrib/muse/research/backdrops_2026_11/synthesis.md`, sections 4 to 6.
The latter explicitly requires owner approval before the live swap and detail pass.

Run `tools/pc/jobs/station_blockout.bat` on the PC's lane A queue. It uses Blender
4.5, the installed ComfyUI Python for Pillow, the real A4 H10_23 Battleship and
H7_23 Frigate, and the existing timeout wrapper. Outputs land in
`Downloads/voidsworn_test/board/issue-61/shots`.

- `station_kit.py` builds both variants from one spine, audits their attachment
  graphs with BVH surface checks, checks gun directions, merges static parts,
  exports four separate fleet battery meshes, and reimports each GLB to check
  triangle counts and finite positions. The refinery has no battery meshes.
  An exact Boolean union removes internal faces at static module intersections.
  `--underside-only` relights the saved blockouts for the underside review cells;
  a dedicated inspection fill makes the ventral mounts visible in those views.
- `station_sheets.py` makes both animated turntables, review sheets with real
  ships at full and compact sizes, a comparison, and nine-cell region sheets.
- `station_check.gd` imports the GLBs directly in headless Godot and checks their
  bounds, exported battery nodes, and 30/46 scaling. The batch file runs this
  automatically against a small project in `%TEMP%`.

The full cradle is 36 units long and 12 wide. The real Battleship measures 33.6
by 8.83, so it fits that opening. At the shipped compact size of 30, the cradle
shrinks to 23.48: the Battleship must overhang. Do not resize the ships or enlarge
the compact station to hide that settled scale constraint. The Frigate is 10.4
long; the full station's service berth has 12 clear units, shrinking to 7.83 at
the compact scale. The compact comparisons leave both real ships at their full
shipped sizes, so the lack of an enclosed fit is visible rather than concealed.

## Blockout geometry sweep

The retained top, side and lit underside views were inspected region by region.
These verdicts cover clean blockout geometry, not finished surface detail or
owner acceptance. Static intersections are sealed; the lower battery mounts
are visible in the underside inspection light. There is no AI body to compare
against a concept: these new silhouettes follow the structures brief.

| Variant and region | Top | Side | Below |
|---|---|---|---|
| Fleet end A | clean | clean | clean |
| Fleet spine | clean | clean | clean |
| Fleet end B | clean | clean | clean |
| Refinery end A | clean | clean | clean |
| Refinery spine | clean | clean | clean |
| Refinery end B | clean | clean | clean |

Still gated: detail, faction dressing, damage and hulk states, turret traverse
hooks, final runtime assets and board integration, and actual game screenshots.
The review images are studio blockouts and must not be described as in-game shots.
Relay and transport work in the structures synthesis also remains unimplemented.
