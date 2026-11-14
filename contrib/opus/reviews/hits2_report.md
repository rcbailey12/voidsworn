# Hits pass 2, issue 538

Refs #538. Visual effects only. No rules, saves, weapon stats or faction ids changed.

## Change

- `godot/fx/fx_weapons.gd`: more and larger thrown matter for guns, rockets, torpedoes, energy weapons, beams, arcs, gauss and bio hits. Sparks cool over 0.6 to 1.6 s, debris tumbles and drifts for 5 to 10 s, gas thins over 5.5 to 9 s, embers cool over 3.5 to 7 s. The existing wounds cool into persistent hull marks.
- `godot/fx/fx_shaders.gd`, `fx.gd`: directional, ragged gas with no emitted light; hit debris has a readable plated surface, an 8 px nominal size floor and a slower cooling tail. Death shards keep their existing material and cooling.
- `godot/bench/scene_gate.gd`, `look_moments_hits2*.json`: reproducible single-hit rows at camera 170 and a film camera that follows actual arrivals and holds through deaths. The timing gate can settle for the longest new particle life before measuring, and records particle storage use.
- `godot/fx/test/hit_recipe_check.gd`: the existing visual check covers rockets, star torpedoes, doom arcs, autocannons, scatter, the needle, pulsars and flak as well as its original nine looks. Its old under-one-second spark assertion now follows the independent cooling lifetime. The flame and flash protections stay in place.

## Sizes used

Issue 710's `docs/playbooks/scale.md` is absent from this checkout. This pass uses `render/hull_table.gd`: hex corner radius 10, width 17.32 world units; class length times SHIP_K 1.6. Frigate 10.4, destroyer 15.2, cruiser 23.2, carrier 26.4, battleship 33.6, dreadnought 43.2, super-dreadnought 49.6 world units. These are displayed lengths, not physical metres.

Nominal flash rows are unchanged, in pixels at 1080 for a cruiser gun on a cruiser: las 40, heavy macro 64, lance/doom 78, torpedo/star torpedo 140, rockets 91, shield torpedo 110 with a 156 ripple. Missile impacts use the existing torpedo, rocket and star-torpedo routes; all three are shown in the captures. Gun bands remain 0.85/1/1.2 and target bands 0.8/1/1.2, selected by rendered hull length below 18, below 30, or larger. New matter also follows the square root of the firing gun's band and the existing target geometry scale; rockets retain their smaller recipe. No projectile or ship model was resized.

## Evidence and results

Baseline: `00ce0417e63cae97173decf6f8fc584459dcc84a` (current main, including PR 524). A frozen copy of its Godot source reused the same built assets. No old checkout or PC file was deleted. The look-bench comparisons were captured twice, with the second run kept. Hit strips use unscaled source pixels at 1920x1080, radius 170. Death detail crops are labelled, and the complete core cells are also supplied.

Primary evidence, mirrored in `docs/shots/look_bench/hits2/` and in the required PC handoff folder:

| File | Proof |
|---|---|
| [hits_ladder.jpg](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/hits_ladder.jpg) | The original five-step hit ladder, before above after. |
| [hits_linger_torpedo.jpg](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/hits_linger_torpedo.jpg) | Torpedo aftermath at 0.3, 4 and 8 s. |
| [deaths_core_and_wreck.jpg](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/deaths_core_and_wreck.jpg) | Capital core, gas and cruiser wreck, before above after. |
| [hits_fight_after.mp4](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/hits_fight_after.mp4) | Silent, 14 s, 1280x720, 30 fps, 20 ships. Camera follows actual arrivals and holds through three deaths; a chevron marks the followed point. |
| [hits_fight_before.mp4](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/hits_fight_before.mp4) | The same fixed-clock fleet and volley schedule before the change. |
| [hits_fight_strip.jpg](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-538/shots/hits_fight_strip.jpg) | Film crops showing the followed hit, cruiser core and wreck. |

Additional named sheets cover macro and lance lingering matter; rockets, star torpedoes and gauss; energy and bio; beams and arcs; prism and the early spray. `capital_core_full.jpg` retains both complete 640x480 core cells. All delivered sheets are at most 720 px tall. Original PNG cells, camera manifests and benchmark JSON are included in `raw/` and `measurements/`.

At 4 s, the baseline is largely clear, while the new plates remain visibly separate from the star field and smoke follows the ejection direction. By 8 s much of the fast debris has drifted beyond the tight central crop; the life range is 5 to 10 s, not a promise that every piece remains beside the target. The film's followed hits are heavy battery impacts before the staged frigate, destroyer and cruiser deaths. The individual strips show the other weapon families.

## Cost

RTX 5080, Godot 4.7.2, Forward+, vsync off. Two sessions per mode; table entries are medians of the two session statistics. Both variants settle for 11 s, then warm for 120 frames and measure 720 frames. The 4K row uses a 1080p window with 3D rendering at 3840x2160 (`res_2160`, scaling 2.0).

| Mode | Frame median before / after, ms | Frame p99 | GPU median | GPU p99 |
|---|---|---|---|---|
| 1080p base | 3.51 / 3.53 | 6.83 / 7.01 | 2.45 / 2.46 | 2.80 / 2.81 |
| 1080p deaths | 3.93 / 4.07 | 8.81 / 9.32 | 2.50 / 2.53 | 2.88 / 2.94 |
| 4K base | 5.61 / 5.64 | 9.46 / 9.25 | 5.44 / 5.46 | 6.00 / 5.99 |

The 1080p frame gate remains under 12.5 ms. These small differences sit within the spread between sessions; they do not establish a zero cost. Counts were increased, with no new count cap or pool size change. Across the changed 1080p runs, including warm-up, at most 395 debris particles were emitted into 768 slots, 1,212 smoke particles into 12,288, 3,918 glow particles into 16,384, and 2,868 streaks into 16,384. Those matter pools did not wrap even over the whole run. The short distortion pool is separate.

Texture memory remains about 1,601 MB. Base video memory is about 2,490 MB both ways; deaths use about 2,494 / 2,499 MB. The existing `exterior_alpha` late-shader notice appears in both variants; no new hit shader was reported late. Early captures printed sandbox shader-cache write errors; final picture captures and 4K checks used an isolated writable runtime. The Windows root-certificate-store diagnostic also occurs on the unchanged baseline; these offline runs complete without script or shader compilation errors.

## Comfort and checks

- `node contrib/opus/tools/run_all_checks.js`, bundled Node 22: exit 0, 48 PASS and 2 KNOWN rows. The known baseline is unchanged: seven listed findings and twelve constant differences.
- `hit_recipe_check.gd` and `flash_area_check.gd`: exit 0 in the targeted runs. The extended recipe check covers 17 looks in normal and Reduce Flashing modes; the final destruction suite reruns it.
- In the changed 1080p gate, base mode refused no flash. Deaths mode softened one 100 px request in one of two sessions. The counter, its area limit and its three-per-second budget were not relaxed. Reduce Flashing keeps booking and counting no flash; flame timing and neighbour-light peaks are unchanged. Bio's existing 28 px nominal floor now also follows the gun and target bands.
- `godot/fx/test/check_destruction.bat`: exit 0. All nine headless checks and both GPU probes pass, including the 20-ship destruction fleet. `HIT_RECIPE failures=0`, `FLASH_AREA failures=0`, and `FX_SMOKE` reports `stray=0`.
- Rendered worst-case three-wave salvo, damaged ships, mass squadron deaths and a capital death (`scene_gate --flash --frames 240`): baseline and changed builds both PASS. Both show 0 whole-screen and 1 brightest-block flash event in the worst rolling second; the effect counter stays at 3 or fewer. The stressed salvo softens 44 / 50 requests before / after. This is the existing rendered probe, not an independent photosensitivity certification.
- `git diff --check`: pass. No em dashes added.

Method: `look_bench.tscn -- --part moments --moments res://bench/look_moments_hits2.json`, twice per variant, and the dedicated `look_moments_hits2_deaths.json`, also twice. Film: `scene_gate.tscn -- --still --film 2 --follow_hits`. Cost: `--sessions 2 --settle_ms 11000 --warmup 120 --frames 720 --modes base,deaths --trace`; 4K: `--modes res_2160`. The proof-camera flag changes no normal gameplay camera behavior. `capture_manifest.json` records source hashes and the evidence inventory.

Not run: the unrelated full GPU-check list, an independent blind viewer verdict, or Muse's outside review on issue 256. This is an uncommitted working-tree delivery for the runner and Board to review; no commit or push was made. The Board still owns the visual acceptance and outside review before merge.
