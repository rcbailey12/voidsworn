# Portraits: check round after your Nov 1 picks (P stream)

## Note for Ryan

Ryan, here is the quick check on your picks before every Hullbreaker and Glasswright gets repainted. Two sheets, one per species:

- `docs/shots/portraits/bf0c13e/k64_hullbreakers.webp`
- `docs/shots/portraits/bf0c13e/k64_glasswrights.webp`

**Hullbreakers (your A1).** Row A is A1 itself, then A1 repainted toward the oil paint of the other portraits. Row B is the look every Hullbreaker gets: the same mane, hunched bulk, plated face and row of eyes, with the chest covered by the scrap harness so it never reads as a bodybuilder. No quills, tusks, mesh or helmet head. Row C shows what happens if the oil paint is pushed harder: the head turns into the long domed film-monster head, so I stop at row B's strength. Honest misses: the face plates still look a bit metallic, and the sideways-splitting jaw only shows when they snarl.

**Glasswrights (your A, made organic).** Row A shows your pick and the two tries that went wrong: describing pale skin drew an elf face under a visor, and one seed still drew lips under the gem head. Row B is the fix the repaint uses: milky living flesh with pink sinew and glass threads grown into the neck and hands, long fingers, and a faceless cut-gem head growing out of the neck. The models only keep the face away on some seeds, so the repaint renders four seeds per character and I pick only the faceless ones. Row B is still the cleaner digital finish; the repaint adds the oil-paint pass on top of each one.

The full repaint is running on the PC now: all four Hullbreaker admirals (Grax, Sable, Mott, Vesh), all four Glasswright admirals (Tamsa, Saro, Vell, Brin) and all twelve Hullbreaker and Glasswright Nemesis, then the Nemesis get their scars repainted. Say the word if either row B misses what you meant.

Also done:
- **Sunward Crusade Nemesis 2, 4 and 5:** their scar paintings are repainted with clean backgrounds, no more speckle or pixel grid (`godot/portraits/sheets/nemesis_voidsworn.webp`, commit a859ccd).
- **Lore bible:** 4.3 and 6.3 now carry your notes (commit 8e5f688).

## Vetoable calls

- Design from Qwen, finish from Z-Image: each picture is drawn by Qwen-Image-Edit (it follows the design) and then repainted by Z-Image Turbo at partial strength (`zi2i` in `tools/portraits/portrait_run.py`): 0.50 for Hullbreakers, 0.45 for Glasswrights. Z-Image alone, or at 0.65, loses the design (Hullbreaker row C; for the Glasswrights it brings faces back).
- Glasswright seeds: four seeds per character instead of seed 51, because seed 51 drew lips under the gem head in k64b.
- Crusade Nemesis scar picks (`make_edits.py` F64B_PICK): N2 burn 37, cyber 37, eye 23; N4 burn 23, cyber 37, eye 51; N5 burn 37, cyber 37, eye 37. For each Nemesis I took the healed-looking burn, the cyber plate with the fewest red vein lines, and the eye scar that whitens only one eye.

## Files

- Prompts: `tools/portraits/make_batches.py` (k64, k64b check; p64ha, p64hn, p64ga, p64gn repaint).
- Sheets: `tools/portraits/concept_sheets.py <PORTRAITS> <out> check`.
- Renders on the PC: `Downloads\voidsworn_test\comfy_io\PORTRAITS\k64`, `k64b`, `p64`.
