# Blender diagnostic support

Prepared October 31, 2026. **Runtime: NOT RUN.** Blender and Windows are unavailable here. Three pure geometry tests and Python syntax checks pass; this is not render acceptance.

## PC use

1. Double-click `self_test.bat` first. Choose Blender if needed. Its generated fixture must flag a backward tagged weapon, missing texture and unassigned hull faces, then produce 18 images.
2. Double-click `run_qa.bat` to choose a GLB/glTF, or drag the asset onto it. Blender's bundled Python runs the tool; no separate Python installation is needed. `VOIDSWORN_BLENDER_EXE` can identify portable Blender.
3. Open `output/qa_<timestamp>/contact_sheet.html`, `report.json` and `blender.log`. Bow/midship/stern by top/side/below are repeated with original materials and clay. Verdicts start UNREVIEWED. Print to PDF to preserve typed notes; HTML notes do not autosave.

The input is imported into a temporary factory-settings scene. Imported lamps/cameras are removed from that scene for consistent lighting. No source .blend is saved, replacement mesh exported, islands deleted, panels smoothed or geometry decimated. The primary file hash is checked before/after. External glTF dependency images are inspected but not included in that primary hash.

The default **imported Blender frame is forward +X, up +Z**. Confirm it before interpreting bow/stern or weapon flags. These are explicit assumptions, not inferred from names or equated with game coordinates. Opus can pass different signed axes using PowerShell `-Forward` and `-Up`; parallel axes are rejected. The asset is not rotated to hide its transforms.

## Observations

- Missing texture files, unassigned face materials, missing UVs on image-textured objects, nonfinite vertices, zero-area faces, negative determinants and nonuniform/zero scales are recorded. Intentional cases need review; flags never trigger automatic cleanup.
- Direction requires custom properties `qa_role = "weapon"` and `qa_forward = [x,y,z]` in local coordinates. Untagged weapons are **unverified**. This does not establish mounting contact, muzzle clearance or hull penetration.
- Pair checks require exactly two objects sharing `qa_pair`. They compare origins mirrored about the bounds center with a 1% size threshold, not geometry equality. Corsair asymmetry remains a review note.
- Organic hulls, thin sails and faction grammar require visual judgment. No automated blob/grammar pass is claimed.

The existing Gemini `contrib/gemini/tools/blender/auto_sweep.py` proposes cleanup/socket extraction. This tool supplies inspection and comparison views; it never invokes that cleanup.

## Acceptance and runner

The neutral studio rig uses Standard view transform and exposure 0. It is not production ACES/bloom calibration or proof of the game material. Muse's current desktop visual QA controls acceptance: in-game screenshots at battle zoom and faction silhouette sheets are still required. Legacy phone checks are superseded by PC-only direction.

If Opus submits this through the PC watcher, use HANDOFF.md's fresh staging, timeout wrapper and separate run.request procedure. These standalone launchers have not been staged or executed on the PC. Do not replace an active watcher job.
