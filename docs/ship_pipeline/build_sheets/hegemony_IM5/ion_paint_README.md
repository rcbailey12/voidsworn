# Iron Mandate IM5: issue 930 painted ion gun

[PR 911 sheet beside the painted bow](ion_paint_comparison.jpg),
[painted bow beside the concept's lit engines](ion_paint_concept.jpg),
[painted whole ship and native camera 170 pixels](ion_paint_cam170.jpg).
Every picture is 1280 by 720 and carries its actual source revision and stage; comparison sheets preserve both sources.
The source PR 911 picture is retained unchanged.

Method: [build sheet](README.md), [manifest](manifest.json),
`tools/recipe/ships/hegemony_IM5.json` (`bake: stack`), normal `tools/blender/r209/bake_sheet.py`,
shared `paint_stack.py` and Hegemony `stack.py`. No build-sheet or geometry changes.
Paint: 4096 hull and parts maps, 2048 shared emission map, 64 bake samples, Blender 4.5.14 OPTIX on the PC.
The shared bake reads emissive_zone before material names, including engine-map membership and hull-trim tagging.
The faction's existing mapped-glow hooks put the ion lens and contacts on the same exportable map as the nozzles.
The lens has a brighter core, deeper blue edges and dark frame lines between four segments.
Contacts and coil edges are fainter blue. Coils and muzzle retain the metal paint and geometry-driven wear;
bays receive no new light. The ion lens is the explicit PR 911/R304 bright-light exception; other mapped light values
are divided by the map strength before baking so their original effective brightness is retained, within map quantization.

Checks: [measured results](ion_paint_checks.json). Both painted ships exactly match their freshly built unpainted sheet
meshes by evaluated geometry hash. Both pass the six-view surface check (zero bare and room pixels) and check_export.py.
Sunward S8 was painted before and after at 512 maps / 8 samples: both glow lists are
`p3_frost, p3_glow, p3_vent, p3_window`; the engine emission PNG is byte-identical.
`node contrib/opus/tools/run_all_checks.js` exited 0, including the Windows runner and stage 5 tests;
only its recorded findings_tests and oracle_drift_guard baseline exceptions remain.

Budget from export7: 105,500 main mesh triangles plus 8,436 turning mesh triangles; class length
31. Export format, hard points and authored interiors are unchanged.

Not installed. The real export passes check_export.py, but check_export_selftest.py accepts the deliberately broken `bell_plane` copy. The same case fails with both paint modules loaded unchanged from HEAD (512 maps, 8 samples). The normal installation gate is therefore still blocked by this existing engine-check problem. No geometry or export check was changed to bypass it; the currently installed H4_11 was left in place.

Earlier geometry and concept-generation stages were not rerun: this job changes paint only and the evaluated sheet geometry
is unchanged. No performance claim or new scene-gate measurement is made. Logs and temporary blends remain in TEMP;
all review pictures and their provenance sidecars are also copied to the issue 930 shots folder.
