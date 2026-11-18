# Issue 1117: broadside aim and chip paint

Owner: DeepSeek workhorse run, Nov 18 2026. Branch work/issue-1117-deepseek.

## What changed

- `godot/fx/fx_hull.gd`: `_gun_points` now applies the bearing and reachable-arc test (`_bears`) in all three
  candidate tiers: the exact slot and weapon tier, the by-weapon tier and the slot-only tier. The exact slot
  still wins among the muzzles that bear, then the right weapon, then the right slot. `analyse` also records
  `bvh_ranges`, the surface ranges of the triangles the BVH was built from.
- `godot/fx/fx_fragments.gd`: `_source_at` resolves a BVH face number through `bvh_ranges`, so it decodes the
  hit against the original mesh and surface offsets even after the damage rebuild swaps the live mesh and adds
  triangles to an earlier surface. The old live-mesh scan stays as a fallback when a hull has no range record.
- `godot/fx/test/broadside_mount_check.gd`: new headless check from the audit repro. It proves all three tiers
  bear and that the no-socket fallback never fires backward.
- `godot/fx/test/hit_fragments_check.gd`: new two-surface dent case. A hit on the second surface before and
  after the first surface gains a triangle must keep the second surface's paint and UV patch.
- `godot/tools/ci/godot_checks.txt`: lists the new broadside check and updates the hit fragment reason.

No change to `godot/fx/fx_death.gd`, the breakup code, the rules root files or the tables. No captures and no
frame timing.

## Finding 5: aim fallback

A legal rules shot can ask for a muzzle when no authored gun point bears on the target (the target is behind
the hull, or every turret that could train is outside its reach). In that case `guns` falls through to the
surface ray mounts on the target's side (`mounts_for`). That mount faces the target, so the effect still leaves
from the correct side. If the ray mounts also find no plating, the volley gets `{}` entries and the shot's
effects are skipped and counted (the existing `_took("gun", "skip")` path). No muzzle ever fires from a point
that does not bear on the target.

## Finding 9: cheaper of the two repairs

The job allowed either resolving the face against the geometry the BVH was built from, or rebuilding the BVH
and mapping together when the damage rebuild swaps the mesh. I chose the first: one recording pass at
`analyse` time, no BVH rebuild per damage event. It is cheaper because the BVH is built once and the damage
rebuild is already the expensive worker job; a second `TriangleMesh` build on every dent, ion burn or cluster
would add to that path. `bvh_ranges` keeps a reference to the original `ArrayMesh` resource (not a copy of its
arrays), so the UV triplets stay available without duplicating hull memory. It also keeps the hit ray and the
decode on the same pre-damage geometry, which is the geometry the ray actually used.

## Checks run

See the report on the pull request. The check names are:

- `godot --headless --path godot --script res://fx/test/broadside_mount_check.gd`
- `godot --headless --path godot --script res://fx/test/hit_fragments_check.gd`
- the standing checks and the Godot headless list as run by CI
