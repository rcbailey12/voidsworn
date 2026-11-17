# Issue 726 run 4: normal bake repair

This checkout started on `codex/issue-726` at main `0e9c791d`. The runner had not brought in the prior delivery files.
The issue helpers, diagnostics, normal-only proposal and stage 5 guard were recovered from local
`origin/codex/issue-726` (`dfe0baba`), without a merge, commit or push. Current main geometry, including PRs 866, 884 and
898, was kept. No faction stack, build sheet, ship geometry or fixture record was edited.

The brief's routes were tried in order. CPU OSL baked the saved A20 normal input at 4096 pixels in 41.4 seconds at one
sample, without an SVM error. A mixed GPU/CPU retry then crashed with
`LLVM ERROR: IMAGE_REL_AMD64_ADDR32NB relocation requires an ordered section layout`. That is a rejected diagnostic,
not an accepted paint bake. The Windows OSL failure also appears in
[Blender issue 152968](https://projects.blender.org/blender/blender/issues/152968).

The retained route is B. `zone_material` labels its existing scalar patchwork height term, without changing its
value or links. A hull material opts in only when its stack has an active trophy layer (`ps_height_bake`), then a normal
input above 800 reachable nodes selects the height route, a routing budget based
on the measured A20 graphs, not a shader validity rule. Each large material's patchwork height is baked separately,
through emission on the original mesh and UVs, into a single-channel Raw 16-bit PNG in TEMP. The PNG header is checked
and the file is reloaded as Non-Color before it is sampled by a small UV graph. The final normal pass bakes all materials
together. Rivets, scuffs, rust, wear and decals stay procedural. All original surface links, height links, target images
and the clear setting restore in `finally`; no height image is shipped. Materials without the trophy opt-in always use the original
full-surface bake, including every other faction, regardless of graph size. A trophy ship without large inputs also
keeps the original path. Albedo, ORM and device/shading settings are untouched.

The height split avoids SVM's large bump derivative graph and does not depend on OSL. Per-material map paths, 16-bit
encoding and bake times are recorded under `paint.normal_height_maps` in each ship JSON. Intermediates remain in TEMP;
review copies are kept with the ship's run 4 proof.

The cause predates R274: R252 added a fourth uneven trophy grid and its seam to the normal path. A controlled capital
soot-zone comparison, with current shared machinery and decals omitted equally, grows from 550 normal-input nodes at
hb682's R240 stack to 729 at R252. R274, PR 898's craft path and current main all remain at 729. The real A20 graph with
its decals reaches 916 input nodes, or 919 including the normal-only surface, output and image target. R289 changed the
modelled plates; PR 898's craft branch is inactive on capitals. Neither grew this capital shader. The reproducible
comparison is `graph_history.py`.

`normal_bake_diagnostic.py` checks linked and unlinked normals, the real bump distance with a forced height route,
an oversized graph without the trophy opt-in, mixed materials on one UV atlas, graph restoration and an injected bake failure. `ship_normal_diagnostic.py` compares
E11's real mesh and UVs with the pinned initial main revision `0e9c791d`. The masks use 4096 pixels and 64 samples; the deterministic CPU normal comparison
uses a 512-pixel target at one sample,
while production remains at 64. CPU normal passes avoid GPU bevel-ray repeat noise; GPU masks
and the rest of the normal inputs remain E11's real inputs. `guard_diagnostic.py` tests the actual stage 5 guard with
six compile-error messages, positive and negative nonzero Blender exits and a clean completion. The negative crash exit exposed the old
`if errorlevel 1` gap; native Blender exit checks now compare exactly with zero. `probe_osl.py` reproduces route A using the
run 3 normal-only function, preserved in `run3_normal_only.py` so a later branch update cannot lose the control. `probe_height.py` and `normal_look.py` compare route B with that OSL control.

The first full A20 paint bake passed its compiler and surface guards, but the helper refused stage 5 because only two
of three render calls completed. The default render entered the legacy four-piece break preview and indexed an empty
longitudinal cut list. Sheet-ship paint renders now explicitly select the required paint views and omit that legacy
fixed-cut preview. Blender Python errors now return a nonzero exit for every stage 5 invocation. Stage 7's real authored-interior and death-seam checks still run. The job helper can resume at a
named cell/stage only with passing diagnostic evidence, prior stage markers and the original before captures.

The playable build's install check also preloaded a missing `tools/ci/check_guard.gd`. The job now copies that check-only
dependency when absent, reads its hash back, and retains every gameplay script. The failed install was retried through stage 7.
The playable build also had an older `a4_shots.gd` that ignored the requested camera set and produced only close views.
The helper backs up and refreshes that test script and its scene from the source checkout, checks both hashes, and requires
the actual 1920 by 1080 camera-170 file before making the labelled review sheet. No gameplay script is replaced.

The run 4 proof is under `C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run4/`. Final results, costs,
checks and pictures are in REPORT.md. Nothing is committed or pushed.
