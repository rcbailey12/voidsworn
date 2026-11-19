# Fighter and bomber model swap

Refs #1065. Lane D prepared the model loader and Stage 7 checks. On lane B, HF1D completed its satin bake at 4096 pixels and 64 OptiX samples. The six-view surface check found zero exposed room pixels and zero unpainted pixels.

Stage 7 gives each painted craft its own code in `godot/assets/ships/manifest.json`. The game reads that entry by faction and role. Battle wings, carrier launches, and weapon passes use the same loader. The ribbon starts at the centre of the craft's authored exhaust points. Formation spacing uses the model's fitted bounds.

| Faction and role | Approved sheet | Current state |
| --- | --- | --- |
| Navy fighter | [HF1D](../../ship_pipeline/build_sheets/hegemony_HF1D/README.md) | Satin bake and surface check passed. Export and shared install pending. |
| Sunward fighter | [SF3, low-fin build](../../ship_pipeline/build_sheets/voidsworn_SF3/README.md) | Satin bake and shared install pending |
| Sunward bomber | [SB4](../../ship_pipeline/build_sheets/voidsworn_SB4/README.md) | Satin bake and shared install pending |
| Hullbreaker bomber | [KB1CC, run 3](../../ship_pipeline/build_sheets/corsair_KB1CC/README.md) | Satin bake and shared install pending |
| Chorus spore | [CS1BA2](../../ship_pipeline/build_sheets/chorus_CS1BA2/README.md) | Procedural while issue 1058's finish awaits merge |
| Navy bomber | | Procedural. No approved build sheet exists. |

The installer and game readback passed headlessly with four temporary test GLBs. Their eight files and the shared build's existing 260 files passed the playtest manifest checker. Godot passed 484 squadron checks, 190 formation checks, and 58 model-selection and fallback checks. The standing suite passed 70 rows, recorded two known baselines, and hit two Windows hard-link permission errors. Both affected checks passed on rerun with permission to create their temporary links.

Lane B regenerated the [A16 seam fixture](../../../godot/fx/test/fixtures/C19_51_unbaked.sheet.txt) with `sheet_fixture_hash.py --bake`. The freshness check passed. Godot read the new fixture and reported zero split machines and zero interior triangles outside the wreck plating. The playtest manifest check passed for the 260 files already in the shared build. The standing suite finished with 72 passes and two known baselines.

The approved craft still need the Stage 6 benches, checked Stage 7 exports and shared readbacks, the updated playtest manifest check, solo scene 207 timing, and the four comparison sheets. Each recipe still points to its approved build sheet.
