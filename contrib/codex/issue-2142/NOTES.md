# Issue 2142: projectile contact

- A hit takes its position from the existing target pick. Absorbed shots meet the bubble. Hull hits end at the same point used by the wound. A shot that breaks through still gives the shield failure its existing head start.
- Torpedo, rocket and star casings stop nose first and hide with their drive on contact. Torpedo flight stays flat. The kit wake can cool behind the contact plane, and intercepted rounds keep their separate point-defense ending.
- The Acid Thorn goes away on contact instead of lodging in the hull. Bone and horn chips and a small bile splash replace it. The hull still gets its etched mark and acid spot, with no metal debris from the thorn.
- Bolt layers, pellets, flak rounds and wing ordnance share their hit's endpoint and clock. Gauss loses its head and keeps only the cooling wake. Beams, ram and the attacking craft themselves are not projectile bodies. Miss and fly-by paths stay in place.
- A blocked shot plays its own compact pop alongside the existing bubble ripple. It keeps R412's small absorbed impulse, without adding ship reactions or a torpedo camera kick on a held shield.

## Merge overlap

- PR 2043 (Build B) also edits `_shot`, `_launch`, `_launch_step`, `_projectile_body`, `update`, `_projectile_exhaust`, `_flak` and `_strafe`. Keep those looks but pass the same absolute contact time to **every** moving layer and keep the casing and drive hidden on that step.
- PR 2047 (Build F) also edits `_shot` and `_impact`. This branch leaves the beam arms and `_beam_burn` alone. Keep contact cutoffs and pops on projectile arms only.
- PR 2084 (Neon #2048) changes the shield shader. This branch does not edit the shield shader or change ripple timing or the flash ladder. In `_shield_impact` it only gates the torpedo camera kick and distortion to shield breaks. Keep the projectile pop in `_impact` separate from the shield's own response.

## Evidence

`projectile_contact_check.gd` drives 23 travelling looks against a shield and bare hull, plus two breaking-shield penetrations. It checks the packed draw endpoints and cutoff times, solid noses and visibility, cooling kit trails, contact pops, quiet shield blocks and the flat ship root. `acid_thorn_check.gd` still checks the built body and uninterrupted miss.

All 48 contact cases and 23 other focused Godot checks passed locally. The standing suite was not green on Windows. It reported temp-folder and system-query permission errors, plus a PC preflight fixture that exceeded its deadline while checking a child that holds stdout open.

No GPU capture on this run. The Board queues picture proof after review.
