# Pyre-Barge repair in place, issue 129

Status: GPU evidence is pending. The PC runner is waiting while Voidsworn is open, as HANDOFF.md requires. This is not a completed five-stage visual comparison or an approved ship.

The reproducible experiment is in [tools/blender/hull_repair](../../../../tools/blender/hull_repair/README.md). Its double-click batch queues the local generation, repair, actual-game captures, studio crops and 20-ship measurements. No shipping ship or game file has been replaced.

Completed so far:

- Today's intact source was measured, with 42 large wavy panels selected. The flattening pass changes 2,572 vertices and holds every region border. It retains the original small machinery.
- Stages 1, 2, 3 and the hand-built stage 4a exported and reimported successfully. Two duplicate faces and 38 zero-area triangles are excluded from the source; there is no decimation.
- The shared trim is byte-identical to round 2. Exported per-piece colour factors and AO texture links were checked in the glTF data.
- Local Qwen and Pixal3D generated individual engine, gun, bridge and midships candidates. The first bridge cleanup invented a tall naval-looking lattice tower. One targeted retry is queued with a tighter low-bridge crop.
- The native engine contains 22.8 million triangles. An array-based packer preserves native geometry and adds shared trim UVs and normals. Its execution and game integration still need verification.
- All 25 standing checks passed with Node 22.11.0. Godot 4.7.2 rules parity passed all 54 scenarios, three 10,000-draw PRNG cases, math checks, three threat maps, threads and the hard stop. The known findings-test baseline remains present; there were no unexpected failures.

Still required: complete native part cleanup, build stages 4b and 5, inspect the mounted parts, choose the final replacements, produce the matched studio and game sheets, head-on and grazing panel crops, blob crops, final nine-cell sweep, per-stage GPU/frame figures and final recommendation. No visual winner or fleet rollout estimate has been claimed before those checks.

Scratch meshes and logs are in `%TEMP%\voidsworn_issue129`. Reviewer images, measurements and generation records are copied to `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-129\shots` when captures finish. No commit or push was made.
