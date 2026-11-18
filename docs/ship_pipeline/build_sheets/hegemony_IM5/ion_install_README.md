# Iron Mandate IM5: issue 970 install

Installed the merged Hegemony blue bow ion gun paint as `H4_11` in both PC projects:
this checkout's `godot/` and the playable `build/godot/`. Both ship caches were refreshed;
both ShipView readbacks passed with 38 hard-point and turret nodes. Installed GLB and map
hashes match the checked export on both copies. Prior files and cache records are preserved
under `board/issue-970/replaced_H4_11_20261117_041621/`, separately for each project.

[Installed bow ion gun](ion_installed_bow.jpg) and
[installed camera 170](ion_installed_cam170.jpg) are 1280 by 720, with source revision,
working-change digest and stage on each picture and in its provenance sidecar.
The bow shows the bright blue core, deeper blue edges and dark segment lines, as on the
[H10 installed proof](../hegemony_H10/ion_installed_bow.jpg).
Camera 170 is the central crop of the normal 1920 by 1080 game capture, without scaling;
its side-on view does not expose the forward-facing lens.

Method: unchanged [build sheet](README.md), [parts manifest](manifest.json) and
`tools/recipe/ships/hegemony_IM5.json` (`bake: stack`). Ran the recipe's sheet-ship helpers
directly, following PR 966's H10 route: `bake_sheet.py` with the merged shared/Hegemony
stack, `surface_check.py`, `paint_sheet.py`, `export3.py`, the solo `bench209r3.gd`,
`export7.py`, `check_export.py` and `check_export_selftest.py`. Paint used OPTIX,
4096 hull/parts maps, 2048 emission and export maps, and 64 bake samples.
Installation used `manifest_merge.py`, `build_assets.gd --ships-only` and
`installed_ship_check.gd H4_11` for each project. The bow uses the retained
[capture script](ion_install_capture.gd); camera 170 uses `a4_shots.tscn --sets cams`.

[Measured evidence](ion_install_checks.json):

- Evaluated painted geometry exactly matches the freshly built sheet: 559 mesh objects,
  113,936 triangles, the same geometry hash as issue 930. No geometry or sheet changes.
- Six-view surface check: zero bare or room pixels. Texture licence and light checks pass.
- Export readback passes. All 33 self-test cases pass, including radius and half-radius
  position faults on all six open engine bells: 12 bell faults refused.
- Authored interiors and death-seam checks: zero failures, zero split machines and zero
  interior triangles outside their broken piece.
- Stage 6 LOD export and two-repeat RTX 5080 studio bench pass. Second repeat, full-detail
  20-ship mode: 1.391 ms frame median at 1080p, 2.780 ms GPU median with 3D at 4K.
  This is LOD analysis, not a new scene-gate result.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, including 93 Windows runner checks
  and 44 stage-failure checks. Only the recorded seven findings and twelve oracle
  differences remain as known baselines.

Budget: 105,500 main mesh triangles plus 8,436 turning mesh triangles; class length 31.
Earlier concept and geometry stages were not rerun because this is the approved paint
install and the sheet is unchanged. The full stage launchers require historical shape
reference/outline records absent from this fresh checkout; the direct sheet helpers above
were used, as for H10. No export check was changed. Logs, blends and analysis output stay
in TEMP; the review pictures and sidecars are also in this run's issue-970 shots folder.
