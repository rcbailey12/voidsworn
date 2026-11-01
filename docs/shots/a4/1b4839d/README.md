# A4 ships, second pass: lighter Hegemony, H4's own livery, and the surface detail rebuilt on 28 ships (Nov 1, 2026)

Every picture here was taken on Ryan's PC in the running game (Godot 4.7, Forward+, RTX 5080), the ships drawn exactly as the battle
draws them, under the battle's lights. The code is 1b4839d (the tools) and the shots were taken after all the work below had run.

## What changed

1. **Hegemony is light grey with blue bands, like its concept art.** The concept paint had carried the concept picture's own shadows
   onto the hulls as paint, so the Hegemony came out 25 to 45% darker than its concepts ("near black navy" at the battle camera).
   Now the lightest part of each hull matches the concept's lit grey, darker trim stays charcoal (not black), the blue bands stay
   blue, and the undersides (which the concepts never show) are a mid grey instead of black.
2. **H4 (the super-dreadnought) has its own hand-painted livery** instead of the projected concept: light slate plates, a darker
   slate lower hull, a thin blue line where the two meet, a red pinstripe along each deck edge and red marks down the side armour,
   matched on both sides. The diagonal red and blue smears and the grey blotches on the deck are gone.
3. **The fine surface detail was rebuilt on the 28 ships that still had the first bake** (all of them except H4, H7, V15, C14s and the
   four Eclipse ships, which had it already): bigger, sharper texture maps and the newer paint underneath the concept colours. At
   battle distance this is a small change; it shows up close.

## What to look at

- `hegemony_as_played_vs_now.webp`: **the one to see first.** Left is the Hegemony as Ryan played it, right is now.
- `hegemony_ingame_before_after.webp`: the Hegemony against the last pass (53a348d). The hulls are lighter, the undersides grey
  instead of black, the blue bands kept; H4 shows its new livery.
- `H4_11_sweep.webp`: H4 bow, middle and stern from above, the side and below, in the game. The old one is in
  `../53a348d/H4_11_sweep.webp`.
- The other faction sheets (`voidsworn_`, `corsair_`, `chorus_`, `ithar_`, `deathless_`, `other_`) compare the last pass with now:
  the rebuild is close-up detail, so expect them to look nearly the same at this size. Nothing went missing or flat on any ship.
- `H7_23_sweep.webp` to `H10_23_sweep.webp` and `V1b_r_23_sweep.webp`: the same 9-cell check for the other Hegemony ships and V1b.

## The checks

- **H4 blob sweep, 9 cells, in the game:** all 9 clean, shape and paint. Square armoured prow with its forward spinal gun, flat deck,
  the two raised tiers with the command block, four side guns in matched pairs aimed out to the sides, three engine bells, flat
  belly. Paint: plates read as plates with no smears or blotches; the red deck-edge stripes run the full length on both sides; the
  red side marks are evenly spaced; the blue line sits where the light upper hull meets the darker lower hull. No naval tells.
- **All 36 ships after the rebuild:** all 28 rebuilt ships passed the build audit (nothing floating, no gun aimed backward, every
  weapon slot mounted) and the re-import check, and the game loads all 36 with their breach parts and wreck pieces. C13s, C15s and
  one wreck piece each on H8 and H10 were flagged for a few zero-length surface normals (no visible effect); the exporter now fixes
  those (7e283b6), so they come out clean on those ships' next build.
- **No regressions:** outside the Hegemony, the before and after views of every ship match in brightness and colour (measured on the
  sheets, within about 1% everywhere), so no ship lost its paint or textures in the rebuild.

## Calls I made (vetoable)

- The Hegemony undersides are a mid grey, lighter than the concepts' dark lower hulls, so they do not read as black holes at the
  battle camera. If Ryan wants the darker two-tone look back, say "darker belly": it is a re-mix that takes seconds per ship.
- H4 is the only ship with hand-painted livery. The other Hegemony ships keep the concept paint with the tone fix, which now looks
  right on them.
- The rebuild covered 28 ships, not 31: the brief's 31 counted three ships that had been rebuilt already.

## Also in this pass

- `godot/assets/ships/manifest.json` now records this build (sizes and checksums of every ship file, breach and skin counts; the
  previous copy was from before the breach-anchor pass). The preview pictures beside it are still the Oct 30 ones.

## How it was made

`tools/blender/a4/concept.py` (Hegemony tone curve, `--recompose`), `livery.py` (H4), then `chain.py` ran the rebuild on the PC as
one short queued job per ship (`a4\chain\rb_1e47714.txt`, about 3 minutes a ship, other streams' jobs in between), then a refresh of
the game's converted ships and the in-game captures (`godot/assets/ships/test/a4_shots.tscn`, sets battle and close). Sheets:
`tools/blender/a4/ingame_sheet.py` on the PC (headers re-lettered in the cloud). Raw shots on the PC in `Downloads\voidsworn_test\a4\ingame\after_rb_1e47714\` (before:
`after_cp2\`, as played: `before\`).
