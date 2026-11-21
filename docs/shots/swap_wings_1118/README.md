# Fighter and bomber model swap

HF1D, SF3, SB4 and KB1CC are installed in the shared PC build. Each review sheet shows the previous procedural wing and the installed model at the same battle camera, a closer view of the lead craft, and a frame from the carrier launch.

| Craft | Approved build sheet | Review sheet | Triangles per craft / wing | Visible draw calls per craft / wing |
| --- | --- | --- | ---: | ---: |
| HF1D, Navy fighter | [HF1D](../../ship_pipeline/build_sheets/hegemony_HF1D/README.md) | [HF1D](HF1D.jpg) | 15,210 / 45,630 | 7 / 7 |
| SF3, Sunward fighter | [SF3, low fin](../../ship_pipeline/build_sheets/voidsworn_SF3/README.md) | [SF3](SF3.jpg) | 17,042 / 51,126 | 6 / 6 |
| SB4, Sunward bomber | [SB4](../../ship_pipeline/build_sheets/voidsworn_SB4/README.md) | [SB4](SB4.jpg) | 20,160 / 60,480 | 5 / 5 |
| KB1CC, Hullbreaker bomber | [KB1CC, run 3](../../ship_pipeline/build_sheets/corsair_KB1CC/README.md) | [KB1CC](KB1CC.jpg) | 51,592 / 154,776 | 4 / 4 |

The triangle counts come from the Stage 7 GLBs. Each full wing has three craft. The draw counts come from Godot with the craft visible at radius 170 and the ribbons hidden. Each three-craft wing used the same number of visible mesh submissions as its lead craft alone in that view.

The Chorus CS1BA2 spore wing uses procedural craft while the finish in issue 1058 awaits merge. The Navy bomber uses procedural craft and has no approved build sheet. Other roles use the faction's procedural fallback. [CS1BA2 build sheet](../../ship_pipeline/build_sheets/chorus_CS1BA2/README.md)

## Scene 207

All three 1080p medians cleared the 12.5 ms gate. All three 4K GPU medians also cleared 12.5 ms.

| Solo RTX 5080 session | 1080p frame median | 1080p p99 | 1080p worst frame | 4K GPU median |
| --- | ---: | ---: | ---: | ---: |
| 1 | 5.296 ms | 12.981 ms | 20.434 ms | 5.881 ms |
| 2 | 6.979 ms | 14.156 ms | 36.068 ms | 5.808 ms |
| 3 | 5.454 ms | 11.452 ms | 31.057 ms | 5.756 ms |

The runs used seed 4207, fitted shields, Max settings, the engagement camera, full-detail meshes and seeded volleys. Each case ran through the 2.5-second settle and 180-frame warmup, then measured at least 720 frames and eight seconds. The battle kept the 20 hulls and four stock wings, plus a Navy fighter, Navy bomber and Chorus spore wing. Each run verified all four installed model codes and the two procedural roles in the battle. [Issue 1070 baseline method](../../../contrib/codex/perf_1118/README.md)

## Build and checks

- The four approved sheets fed their faction satin stacks at 4096 pixels and 64 OptiX samples. The run resumed three saved bakes and completed KB1CC on lane B. The surface checks found zero exposed room or unpainted pixels. All four Stage 6 LOD benches finished.
- Stage 7 exported 2048 maps and verified the hard points through Godot after `INSTALL_TO`. The bomb-tube check verifies the authored opening, bore and clearance and rejects moved outlets and doubled radii. The shared playtest check returned `MANIFEST OK` for 292 files, and the previous files went to `sync_old/wings_1118/`. [Wing asset manifest](../../../godot/assets/ships/manifest.json)
- `sheet_fixture_hash.py --bake` regenerated the A16 fixture record against the current inputs. The decompressed GLB is byte-identical to the prior fixture. The Godot check found zero split machines and zero interior triangles outside the wreck plating. [A16 fixture record](../../../godot/fx/test/fixtures/C19_51_unbaked.sheet.txt)
- Godot passed 484 squadron checks and 190 formation checks. The parked formation probe now measures nested meshes and authored exhausts. The shared build passed all 58 model selection and fallback checks.
- The standing suite finished with 72 passes and two known baselines, `findings_tests` and `oracle_drift_guard`.
- The export and install used the stage scripts directly with the approved sheet bakes. Three craft had no legacy shape-reference GLB for the one-click recipe's separate outline and blink artifacts. The review sheets use the installed Godot craft.
