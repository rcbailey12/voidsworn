# Issue 2142: projectile contact

- A hit takes its position from the existing target pick. Absorbed shots meet the bubble. Hull hits end at the same point used by the wound. A shot that breaks through still gives the shield failure its existing head start.
- Torpedo, rocket and star casings stop nose first and hide with their drive on contact. The approach eases in the nose offset so the casing does not sit at the surface waiting for the pop. Torpedo flight stays flat. The kit wake can cool behind the contact plane, and intercepted rounds keep their separate point-defense ending.
- The Acid Thorn goes away on contact instead of lodging in the hull. Bone and horn chips and a small bile splash replace it. The hull still gets its etched mark and acid spot, with no metal debris from the thorn.
- Bolt layers, pellets, flak rounds and wing ordnance share their hit's endpoint and clock. Gauss loses its head and keeps only the cooling wake. Beams, ram and the attacking craft themselves are not projectile bodies. Miss and fly-by paths stay in place.
- A blocked shot plays its own compact pop alongside the existing bubble ripple. It keeps R412's small absorbed impulse, without adding ship reactions or a torpedo camera kick on a held shield.

## Merge overlap

- PR 2043 (Build B) also edits `_shot`, `_launch`, `_launch_step`, `_projectile_body`, `update`, `_projectile_exhaust`, `_flak` and `_strafe`. Keep those looks but pass the same absolute contact time to **every** moving layer and keep the casing and drive hidden on that step.
- PR 2047 (Build F) also edits `_shot` and `_impact`. This branch leaves the beam arms and `_beam_burn` alone. Keep contact cutoffs and pops on projectile arms only.
- PR 2084 (Neon #2048) changes the shield shader. This branch does not edit the shield shader or change ripple timing or the flash ladder. In `_shield_impact` it only gates the torpedo camera kick and distortion to shield breaks. Keep the projectile pop in `_impact` separate from the shield's own response.
- The older Acid Thorns entry in `docs/playbooks/factions.md` still describes the embedded pose. The Board can reconcile that wording when it lands the ruling.

## Acid Thorn assertions

- In `acid_thorn_check.gd`, the fixture now identifies the hit by the miss flag because there is no stuck state. The old assertions that the thorn is visible after impact, rides a moving and turning target, and disappears when that target dies required an embedded bolt. They are replaced by visibility on approach and checks that at impact the intact node is hidden, queued for deletion, and absent from the active thorn list.
- The built `chorus_bolt.glb` body check and all three miss checks are unchanged (no jump, still visible after the aim point, and keeps flying past it).
- The new contact check also verifies the existing thorn acid mark and its 2.5 s glow decay, zero plate debris, and only unheated bone and horn shatter pieces. The hull strike keeps PR 1904's target palette.

## Evidence

`projectile_contact_check.gd` drives 23 travelling looks against a shield and bare hull, plus two breaking-shield penetrations. It checks the packed draw endpoints and cutoff times, solid noses and visibility, cooling kit trails, contact pops, quiet shield blocks and the flat ship root.

The listed headless runner passed both checks and the manifest. All 48 contact cases, 11 related Godot checks, six script parse checks and load-all (454 scripts, 17 scenes) passed on this PC.

The local standing suite finished with 121 passes, 2 known results and 4 failures. The shard fixture could not use its Windows temporary path in Git Bash, and the PC preflight test timed out on the fake FFmpeg version probe. The runner and PC daemon self-tests also hit sandbox permission errors. GitHub's All checks still needs the runner's push.

No GPU capture on this run. The Board queues picture proof after review.
