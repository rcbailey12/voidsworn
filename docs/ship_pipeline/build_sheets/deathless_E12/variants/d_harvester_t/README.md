# E12 turreted zenith: R289 armoured core

Issue 877, Nov 16 2026. Rebuilt from `deathless_E12.py` with `--variant=d_harvester_t`, including the accepted PR 829
weapon replacement. The faceted reactor, cooling bands, hot seams and shade armour are shared with the base E12.
Every non-core mesh, the insides and the hard points are unchanged from this variant's pre-877 build.

[Build sheet](sheet.jpg), [manifest](manifest.json), [weapon match](weapon_match.json), [fit report](fit_report.md).
Review: [concept / before / after at beauty camera](paint/E12_turreted_core_beauty.jpg),
[camera 170 at true pixels](paint/E12_turreted_core_cam170.jpg), [reactor close-up](paint/E12_turreted_core_close.jpg).

Method and full costs: [base revision record](../../core_revision.json). Cycles CPU sheet, 24 samples; unchanged Eclipse
colour palette, 2048 hull/parts atlases and 1024 emission map, 32 bake samples; game-light views at lift 2.2, 64 samples.
The assembled sheet has 50,402 triangles including insides. The painted exterior has 50,006 triangles and four material
surfaces if merged. The core assembly has 5,216 triangles, up from 2,200. Costs are reported without a triangle cap.

Weapon match, fit, sheet contract, recipe audit and six-view paint surface check pass. The existing variant export
self-test also passes. The base-only inventory counter is not variant-aware: it expects two null cannons and flags the
existing turreted projector's detail tag. Those six inventory rows predate this core change; the accepted weapon meshes
are unchanged. [Inventory note](inventory.md).

These are painted Blender game-light previews. No game asset was installed and frame time was not measured in this job.
