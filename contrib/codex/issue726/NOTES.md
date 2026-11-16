# Issue 726, run 3

The Board approved run 2's normal-bake proposal in CODEX_TASK.md. The shared `bake` change is that exact proposal:
compile the existing normal input on a temporary diffuse surface, then restore the original surface links in `finally`.
The faction stacks, sheet geometry and A16 fixture inputs are untouched.

This checkout started at main revision `225b10ae`. The earlier run files were absent, so the three paint job helpers and
the fixture diagnostic were recovered from local `origin/codex/issue-726` (`6b06fc2c`). No branch was merged or committed.
The recipe note was applied to current main, keeping its newer notes. The job checks for PRs 866, 884 and 898 before baking.

Stage 5 now refuses nonzero Blender exits and shader compile errors even when Blender exits zero and writes its completion
marker. A temporary batch fixture exercised six compile-error messages, an ordinary nonzero exit and a clean completion.

`normal_bake_diagnostic.py` compares main's bake function with the working tree on linked and unlinked normals, and injects
an operator failure to check restoration. `ship_normal_diagnostic.py` builds the real Eclipse E11 and compares both bakes on
the same 4096 x 4096 hull atlas at 64 samples. It reports the float pixels and PNG hashes and checks restored shader links.
It also repeats the original bake: the real ship's normal map varies slightly even with unchanged code. The candidate's
maximum difference must stay within that measured control range. Both diagnostics write
only to TEMP; E11 is never installed.

`HB_PAINT_726.bat` runs the checked stage 4 to 7 route. Each install backs up replaced files. The pictures helper labels
every comparison with `225b10ae+normal726-run3` and its actual stage. Game captures come from the playable build after its
stage 7 install. A successful run copies ten review pictures into `docs/shots/look_bench/hullbreaker_paint_726/`.

Run 3 stopped at A20 stage 5. The approved proposal still logged SVM stack exhaustion in five hull materials. The new
stage 5 guard returned 1 despite Blender returning 0 and writing its completion marker. Nothing reached stage 6 or an install.

`capture_normal_input.py` saves A20's actual normal graph to TEMP using the just-baked masks. `probe_normal_compile.py`
tests a stricter isolation: copied materials containing only the existing normal input's dependencies. The affected graphs
shrank to 919 nodes and still overflowed. These are compiler probes, not painted deliverables. Neither the probe's temporary
materials nor its 64-pixel map are used by the game or the recipe. The stricter copy/prune method was not applied to live code.

The recipe's current A20 blend and maps are failed output. Do not use them for stage 6 or 7. The five installed ships remain
as before this run. New painted and installed proof sheets were not produced; the picture helper runs only after stage 7.

Run 3 evidence is under `C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/`. Earlier run evidence is kept.
See REPORT.md for completed checks, costs and the remaining blocker.
