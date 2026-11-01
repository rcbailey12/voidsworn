# A4 ships in the game: why they looked unfinished, and the fix (Nov 1, 2026)

Ryan, after the first Godot playtest: "Painting and ship visuals looked incomplete." Every picture here was taken on Ryan's PC in
the running game (Godot 4.7, Forward+, RTX 5080): the ships drawn exactly as the battle draws them, under the battle's lights.

## What was wrong

1. **The concept art never reached a single ship.** The job that paints each ship's concept art (its livery: the Hegemony's slate
   hull and blue bands, the Crusade's ember accents, the Hullbreakers' dark plating) did all its work and then stopped on its very
   last step, every time, on every ship, because Python could not find one of its own helper files on the PC. So the game kept the
   first paint: one flat faction colour plus fine noise, which is why the Hegemony and the station read as bare grey or white clay.
   **Fixed** (53a348d) and applied to all 36 ships; the normal maps now load in the right format on all of them too.
2. **The station and the wrecks on the board are still the old grey and black lumps.** The board draws them from the old AI
   meshes with a flat grey or near-black colour, not from the painted ships. The painted replacement is ready
   (`godot/assets/ships/a4_props.gd`) and shown in `board_props.webp`, but switching it on is two lines in `godot/render/board.gd`,
   which belongs to the F1 stream. **Not live in the game yet**: `battle_station_today.jpg` is the station in the real battle now.
3. **31 of the 36 ships still carry the first bake underneath** (only H4, H7, V15, C14s and the four Eclipse ships were rebuilt with
   the newer paint and bigger textures). The concept colours now sit on top, so the gap is smaller, but the fine surface detail on
   those 31 is the older, smeared kind (the zebra streaks on V1b's sides). Rebuilding them is about 4 hours on the PC.

## What to look at

- `hegemony_ingame_before_after.webp`: the clearest change. Left is what Ryan played, right is now. H4 is slate grey with red
  stripes like its concept; H8 and H9 get the dark lower hull and blue bands.
- `board_props.webp`: the station as the board draws it today (left) and as it will look once the board uses the painted ship (right).
- `voidsworn_ingame_before_after.webp` and `corsair_ingame_before_after.webp`: Crusade gains ember accents, Hullbreakers dark plating.
- `H4_11_sweep.webp`: the hand-faired super-dreadnought, bow, middle and stern from above, the side and below.

The other sheets (`chorus_`, `ithar_`, `deathless_`, `other_`) show little change, on purpose: the approved lore colours (Oct 27)
replaced the concept colours for the Chorus, Glasswrights and Eclipse, so they only take the concept's light and dark pattern.
`battle_before_after.webp` is the real battle screen against each faction; the new turn flow opens focused on your own cruiser, so
the enemy ships are off screen there and the close views in the faction sheets are the real comparison.

## The other checks

- **H4 blob sweep** (`H4_11_sweep.webp`, 9 cells). Shape: all 9 clean. Square armoured prow with a forward spinal gun, flat deck,
  two raised tiers with the command block, four side guns in matched pairs pointing out to the sides, three engine bells, flat
  belly; no blobs, nothing floating, no naval tells. Paint: 4 cells need work. The concept's shading lands as diagonal red and
  blue smears on the side (bow and middle) and grey blotches on the deck (middle and stern), because the concept shows a stepped
  tower the faired hull no longer has. Next: H4 gets its own hand-painted livery panels (slate plates, red stripes along the
  armour belt) instead of the projection.
- **V1b deck fan** (`V1b_deck_before.jpg`, `V1b_deck_after.jpg`): the radial fan of triangles on the spine is gone; the spine is flat
  plating with its two turrets.
- **Eclipse seam glow** (`eclipse_seam_glow_before_after.jpg`, left before, right after): the white streaks over the whole hull are
  gone; the plate seams read as faint violet lines.
- **Display names** (Opus, Nov 1): the retired names the lint found were only in `godot/assets/ships/manifest.json`, a record of the
  build that the game never reads. It now carries the round 8 names from `ships.py`; ids and file names are unchanged.

## Calls I made (vetoable)

- The concept paint is applied as it was computed this morning (no new tuning), so the fix lands today. Its known flaw: where the
  concept has painted shadows, the hull gets dark smudges (H9's bow, H4's deck). Ryan can say "less concept" and I lower the share.
- Chorus, Glasswrights and Eclipse keep their lore colours over their concept colours (the Oct 27 lore ruling outranks the concepts).
- I did not rebuild the 31 older ships in this pass (about 4 hours of the shared PC queue); the concept fix gave the bigger change.

## How it was made

`tools/blender/a4/concept.py --reuse --apply` on the PC for all 36 ships (`queue/done/a4_cp2b_53a348d.bat`), a Godot re-import,
then `godot/assets/ships/test/a4_shots.tscn` (sets diag, battle, close, bare, props) and the battle scene with `--shots` for each
faction (`a4_cp2a_53a348d.bat` before, `a4_cp2c_53a348d.bat` after). Sheets: `tools/blender/a4/ingame_sheet.py`. Raw shots on the PC
in `Downloads\voidsworn_test\a4\ingame\after_cp2\` and `Downloads\voidsworn_test\shots\a4_cp2_53a348d\`.
