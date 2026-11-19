# Issue 1117 broadside aim and chip paint

## Muzzle selection

Every authored candidate must bear on the target. Turret reach uses the same target point as turret aim. Among usable
muzzles, the exact slot and weapon win, then the weapon on another slot, then another weapon on the requested slot.

A legal shot with no usable socket starts from the existing hull plating mounts chosen for the target direction.
Forward heavy weapons can use the bow, and aft shots use the top stations. If there is no plating mount, the attach
service counts the skipped effect. The battle still applies the rules result.

## Chip paint after hull damage

The hull records the original mesh, surface ranges, part transform and paint when it builds the hit BVH. A chip looks up
the ray's face number in those ranges and reads the triangle and UVs from the original mesh. This keeps the paint and UVs
paired with the geometry used by the ray, even when a dent adds triangles or a damage shader replaces a paint override.

Recording surface ranges once costs less than rebuilding the BVH after each dent. The records reference existing meshes
and materials, so they need no second copy of the triangle or UV arrays.

## Checks

- [Broadside mount check](../../../godot/fx/test/broadside_mount_check.gd) counts wrong-flank shots, verifies slot preference
  and turret reach in all three tiers, and exercises both plating and skip fallbacks.
- [Hit fragments check](../../../godot/fx/test/hit_fragments_check.gd) runs the real dent rebuild on a two-surface hull and
  checks that a later hit on the second surface keeps its paint and UV patch after the first surface gains triangles.
