# Portraits: Hullbreaker and Glasswright concept round, Crusade Nemesis fix (P stream, Nov 1)

## For Ryan: pick one picture per species

- **`c64_hullbreakers.webp`**: four takes on the "void hunters" (A to D), three pictures each.
- **`c64_glasswrights.webp`**: three takes on the "living prism" (A to C), three pictures each.

Gold frames are seed 51 renders (you lean to those). Each take lists what it gets right (+) and what it misses (-). Reply with a picture tag, for example "Hullbreakers A2, Glasswrights A1", plus anything to change. Then every Hullbreaker and Glasswright admiral and Nemesis gets repainted in that look, and each Nemesis keeps its scars.

My leans (vetoable):
- **Hullbreakers A (Scaled hunter).** It is the only take that has all of it: a fur mane only on the hump and shoulders, a bare scaled face, a row of small eyes, a jaw that opens wide, claws, and machine trophies. It reads as a heavy beast without reading as a bear.
- **Glasswrights A (Mirror face).** It has no face at all, just one mirror facet with colour moving behind it. You can see the light running through the glass flesh, and the fingers are long glass ones.

Both of those come from the second image model (Qwen), which has a cleaner, more digital finish than the oil-paint look of the other portraits. Takes C and D on the Hullbreaker sheet and take C on the Glasswright sheet are in the oil-paint style, but each misses part of the brief (noted on the sheet). If you like a digital take's design but want it to match the others, the repaint can push it toward oil paint.

Known nit the repaint will fix: Hullbreakers A2 has a beige machine pack behind the shoulder that can read like a mask at a glance.

## Also fixed: Sunward Crusade Nemesis 3

`02_nemesis_voidsworn_fixed.webp`: Nemesis 3's three scar paintings had turned the dark background into coloured block noise. They are repainted from the same portrait (burn, implant and eye scars) with clean backgrounds. While checking this I found the same fault, milder, on Crusade Nemesis 2, 4 and 5. Their repaint is running on the PC now (job f64b).

## How this round went (plain words)

- **Round 1** (not shown): both image models drew literal bears and werewolves with skull trophies on their belts, and Glasswrights with eyes, mouths and bare bodies. Writing "not a bear" or "no skulls" makes these models draw exactly that.
- **Round 2** described only what should be there. The Hullbreakers came out plainly alien but too close to a film monster (domed head, cable dreadlocks). The Glasswrights came out glassy and prismatic, though a faint face showed inside most heads.
- **Round 3** brought back the fur mane and the hump and asked for one blank mirror facet as the face. The Qwen renders got it. The oil-paint model kept drifting back to the film-monster face and the faint human face.

## Lore lines

`contrib/opus/compute/lore_bible_r8.md` 4.3 (Beings) and 6.3 (People) are rewritten to your Nov 1 rulings (commit 2a78ba3).

## Vetoable calls

- The sheets mix renders from rounds 2 and 3, because no single round produced every take.
- Hullbreaker take C has no working seed 51 (its seed 51 render had the film-monster dome), so it shows three other seeds.
- Crusade Nemesis 3 scar picks: burn seed 23, implant seed 37, eye seed 23 (`make_edits.py` F64_PICK).
- The implant ("cyber") scar is repainted for Crusade Nemesis 3 like the others. The ruling that removes it for the Crusade belongs to the rules stream (R1), and the scar list in `nemesis/scars/scars.json` is left as it is until that lands.

## Files

- Tools: `tools/portraits/make_batches.py` (c64, c64b, c64c), `tools/portraits/make_edits.py` (f64, f64b), `tools/portraits/concept_sheets.py`.
- Renders on the PC: `Downloads\voidsworn_test\comfy_io\PORTRAITS\c64`, `c64b`, `c64c` and `f64`.
